--[[ A REAPER that records instead of doing, for test_place and test_ui.

     Written from the API documentation's signatures, not from what the
     scripts expect: a mock shaped by the code agrees with the code's bugs.
     (Starting Blocks learned that the hard way, with a TimeMap_GetTimeSigAtTime
     mock that had the same wrong return shape as the code that called it.)

     Anything the scripts call that is not here raises, so a call to a
     function REAPER does not have fails in the test, not in REAPER.

     The project: tracks in a list, items on tracks, notes in takes in PPQ at
     960 a quarter, one tempo (120 unless set) and one time signature.

     Copied from Midi Catalogue, which copied it from Midi Suggester (and
     added GetSelectedTrack, GetLastTouchedTrack, Master_GetTempo,
     GetResourcePath, RecursiveCreateDirectory, StuffMIDIMessage and
     time_precise, each from its documented signature). Good Idea adds
     nothing: every call it makes was already here. Re-checked against the
     REAPER API functions page (REAPER 7.79) on 2026-10-01.

     1.17 adds GetPlayPosition2, EnumProjects, GetOS, ExecProcess and
     GetUserInputs, from the REAPER API functions page (REAPER 7.79, which
     the user uploaded again on 2026-10-07), a recording state for
     GetPlayState, and two
     extension functions a script may only test for: SWS's CF_ShellExecute
     and js_ReaScriptAPI's JS_Dialog_BrowseForFolder. Those read nil (not
     installed) unless a test sets P.sws or P.js.
]]

local P = {
  tracks = {}, selected = {}, editorTake = nil,
  selTracks = {}, lastTouched = nil, stuffed = {}, now = 1000.0,
  resource = "/tmp/good-idea-test-resource",
  tempo = 120, num = 4, den = 4,
  cursor = 0, playing = false, playPos = 0, recording = false,
  project = "", os = "OSX64", execs = {}, inputs = nil, sws = false, js = false, shell = {},
  undoDepth = 0, undoNames = {}, refreshDepth = 0,
  ext = {}, calls = {},
}

local PPQ = 960
local function qnPerSec() return P.tempo / 60 end
local function barQN() return P.num * 4 / P.den end

function P.track(name, fxCount)
  local t = { kind = "track", name = name or "", items = {}, fx = fxCount or 0, ext = {}, alive = true }
  P.tracks[#P.tracks + 1] = t
  return t
end

-- An item of notes given in quarter notes from its own start.
function P.item(track, posQN, lenQN, notes, name)
  local take = { kind = "take", midi = true, notes = {}, name = name or "", sorted = true }
  local item = { kind = "item", track = track, pos = posQN / qnPerSec(), len = lenQN / qnPerSec(), take = take }
  take.item = item
  for _, n in ipairs(notes or {}) do
    take.notes[#take.notes + 1] = {
      sp = (n.start) * PPQ, ep = (n.start + n.len) * PPQ, pitch = n.pitch,
      vel = n.vel or 100, muted = n.muted or false, chan = 0,
    }
  end
  track.items[#track.items + 1] = item
  return item
end

local function indexOf(track)
  for i, t in ipairs(P.tracks) do if t == track then return i end end
end

local function takeStartQN(take) return take.item.pos * qnPerSec() end

local api = {
  -- Selection and takes
  CountSelectedMediaItems = function(_) return #P.selected end,
  GetSelectedMediaItem = function(_, i) return P.selected[i + 1] end,
  GetActiveTake = function(item) return item.take end,
  TakeIsMIDI = function(take) return take.midi end,
  MIDIEditor_GetActive = function() return P.editorTake and "editor" or nil end,
  MIDIEditor_GetTake = function(_) return P.editorTake end,
  GetMediaItemTake_Item = function(take) return take.item end,
  GetMediaItem_Track = function(item) return item.track end,
  GetTakeName = function(take) return take.name end,
  GetMediaItemInfo_Value = function(item, parm)
    if parm == "D_POSITION" then return item.pos end
    if parm == "D_LENGTH" then return item.len end
    error("mock has no item parm " .. parm)
  end,

  -- Time
  TimeMap2_timeToQN = function(_, t) return t * qnPerSec() end,
  TimeMap2_QNToTime = function(_, qn) return qn / qnPerSec() end,
  -- integer retval, optional number qnMeasureStart, optional number qnMeasureEnd
  TimeMap_QNToMeasures = function(_, qn)
    local b = barQN()
    local idx = math.floor(qn / b + 1e-9)
    return idx + 1, idx * b, (idx + 1) * b
  end,
  -- integer timesig_num, integer timesig_denom, number tempo: no retval first.
  TimeMap_GetTimeSigAtTime = function(_, _) return P.num, P.den, P.tempo end,

  -- MIDI
  -- integer retval, integer notecnt, integer ccevtcnt, integer textsyxevtcnt
  MIDI_CountEvts = function(take) return 1, #take.notes, 0, 0 end,
  -- boolean retval, boolean selected, boolean muted, number startppqpos,
  -- number endppqpos, integer chan, integer pitch, integer vel
  MIDI_GetNote = function(take, i)
    local n = take.notes[i + 1]
    if not n then return false end
    return true, false, n.muted, n.sp, n.ep, n.chan, n.pitch, n.vel
  end,
  MIDI_GetProjQNFromPPQPos = function(take, ppq) return takeStartQN(take) + ppq / PPQ end,
  MIDI_GetPPQPosFromProjQN = function(take, qn) return (qn - takeStartQN(take)) * PPQ end,
  MIDI_InsertNote = function(take, sel, muted, sp, ep, chan, pitch, vel, noSort)
    take.notes[#take.notes + 1] = { sp = sp, ep = ep, pitch = pitch, vel = vel, chan = chan,
                                    muted = muted, noSort = noSort }
    take.sorted = false
    return true
  end,
  MIDI_Sort = function(take) take.sorted = true end,
  GetSetMediaItemTakeInfo_String = function(take, parm, value, set)
    if parm ~= "P_NAME" then error("mock has no take string " .. parm) end
    if set then take.name = value end
    return true, take.name
  end,
  CreateNewMIDIItemInProj = function(track, t0, t1, qnIn)
    if qnIn then error("the scripts pass seconds") end
    if track.refuses then return nil end
    local take = { kind = "take", midi = true, notes = {}, name = "", sorted = true }
    local item = { kind = "item", track = track, pos = t0, len = t1 - t0, take = take }
    take.item = item
    track.items[#track.items + 1] = item
    return item
  end,

  -- Tracks
  -- MediaTrack GetSelectedTrack(ReaProject proj, integer seltrackidx)
  GetSelectedTrack = function(_, i) return P.selTracks[i + 1] end,
  -- MediaTrack GetLastTouchedTrack()
  GetLastTouchedTrack = function() return P.lastTouched end,
  CountTracks = function(_) return #P.tracks end,
  GetTrack = function(_, i) return P.tracks[i + 1] end,
  InsertTrackAtIndex = function(idx, defaults)
    local t = { kind = "track", name = "", items = {}, fx = 0, ext = {}, alive = true }
    table.insert(P.tracks, idx + 1, t)
  end,
  DeleteTrack = function(track)
    local i = indexOf(track)
    if not i then error("deleting a track that is not in the project") end
    table.remove(P.tracks, i)
    track.alive = false
  end,
  ValidatePtr2 = function(_, ptr, kind)
    if kind ~= "MediaTrack*" then error("mock validates tracks only") end
    return ptr ~= nil and ptr.alive == true and indexOf(ptr) ~= nil
  end,
  GetMediaTrackInfo_Value = function(track, parm)
    if parm == "IP_TRACKNUMBER" then return indexOf(track) or 0 end
    error("mock has no track parm " .. parm)
  end,
  GetSetMediaTrackInfo_String = function(track, parm, value, set)
    if parm == "P_NAME" then
      if set then track.name = value end
      return true, track.name
    end
    local key = parm:match("^P_EXT:(.+)$")
    if key then
      if set then track.ext[key] = value end
      return true, track.ext[key] or ""
    end
    error("mock has no track string " .. parm)
  end,
  TrackFX_GetCount = function(track) return track.fx end,
  TrackFX_CopyToTrack = function(src, fx, dest, destFx, move)
    if move then error("the scripts copy FX, never move them") end
    if fx >= src.fx then error("copying an FX the source does not have") end
    dest.fx = dest.fx + 1
    dest.copiedFrom = src
  end,

  -- Transport
  -- number Master_GetTempo()
  Master_GetTempo = function() return P.tempo end,
  -- number time_precise()
  time_precise = function() return P.now end,
  -- StuffMIDIMessage(integer mode, integer msg1, integer msg2, integer msg3)
  StuffMIDIMessage = function(mode, a, b, c)
    P.stuffed[#P.stuffed + 1] = { mode = mode, a = a, b = b, c = c }
  end,
  GetCursorPosition = function() return P.cursor end,
  SetEditCurPos = function(t, moveview, seekplay)
    P.cursor = t
    if seekplay and P.playing then P.playPos = t end
  end,
  OnPlayButton = function() P.playing = true; P.playPos = P.cursor; P.calls.play = (P.calls.play or 0) + 1 end,
  OnStopButton = function() P.playing = false; P.calls.stop = (P.calls.stop or 0) + 1 end,
  -- integer GetPlayState(): &1 playing, &2 paused, &4 recording
  GetPlayState = function() return (P.playing and 1 or 0) + (P.recording and 4 or 0) end,
  GetPlayPosition = function() return P.playPos end,
  -- number GetPlayPosition2(): the next audio block being processed
  GetPlayPosition2 = function() return P.playPos end,

  -- Housekeeping
  Undo_BeginBlock = function() P.undoDepth = P.undoDepth + 1 end,
  Undo_EndBlock = function(name, flags)
    P.undoDepth = P.undoDepth - 1
    if P.undoDepth < 0 then error("Undo_EndBlock without a begin") end
    if type(name) ~= "string" or name == "" then error("an undo block needs a name") end
    P.undoNames[#P.undoNames + 1] = name
  end,
  PreventUIRefresh = function(n)
    P.refreshDepth = P.refreshDepth + n
    if P.refreshDepth < 0 then error("PreventUIRefresh went negative") end
  end,
  TrackList_AdjustWindows = function() end,
  UpdateArrange = function() end,

  -- Files
  -- string GetResourcePath()
  GetResourcePath = function() return P.resource end,
  -- integer RecursiveCreateDirectory(string path, integer ignored)
  RecursiveCreateDirectory = function(path, _)
    os.execute('mkdir -p "' .. path .. '"')
    return 1
  end,

  -- ReaProject retval, optional string projfn = EnumProjects(integer idx)
  EnumProjects = function(idx)
    if idx ~= -1 then error("the scripts ask for the current project, -1") end
    return { kind = "project" }, P.project
  end,
  -- string GetOS(): "Win32", "Win64", "OSX32", "OSX64", "macOS-arm64", or "Other"
  GetOS = function() return P.os end,
  -- string ExecProcess(string cmdline, integer timeoutmsec): -1 is no wait
  ExecProcess = function(cmd, timeout)
    if type(cmd) ~= "string" or math.type(timeout) ~= "integer" then error("ExecProcess(cmdline, timeoutmsec)") end
    P.execs[#P.execs + 1] = { cmd = cmd, timeout = timeout }
    return "0\n"
  end,
  -- boolean retval, string retvals_csv = GetUserInputs(string title,
  -- integer num_inputs, string captions_csv, string retvals_csv)
  GetUserInputs = function(title, n, captions, values)
    if type(title) ~= "string" or math.type(n) ~= "integer" or type(captions) ~= "string"
       or type(values) ~= "string" then error("GetUserInputs(title, num_inputs, captions_csv, retvals_csv)") end
    P.asked = { title = title, n = n, captions = captions, values = values }
    if P.inputs == nil then return false, values end
    return true, P.inputs
  end,

  -- Settings
  GetExtState = function(s, k) return P.ext[s .. ":" .. k] or "" end,
  SetExtState = function(s, k, v, persist) P.ext[s .. ":" .. k] = v end,
}

-- Extension functions: there when the extension is installed, nil when not.
local extensions = {
  -- boolean CF_ShellExecute(string file)  (SWS)
  CF_ShellExecute = function()
    if not P.sws then return nil end
    return function(file) P.shell[#P.shell + 1] = file; return true end
  end,
  -- integer retval, string folder = JS_Dialog_BrowseForFolder(string caption,
  -- string initialFolder)  (js_ReaScriptAPI): 1 chosen, 0 cancelled, -1 error
  JS_Dialog_BrowseForFolder = function()
    if not P.js then return nil end
    return function(caption, initial)
      if type(caption) ~= "string" or type(initial) ~= "string" then error("JS_Dialog_BrowseForFolder(caption, initialFolder)") end
      if P.jsFolder then return 1, P.jsFolder end
      return 0, ""
    end
  end,
}

function P.install()
  reaper = setmetatable({}, {
    __index = function(_, k)
      if extensions[k] then return extensions[k]() end
      local f = api[k]
      if f == nil then error("the script called reaper." .. tostring(k) .. ", which the mock does not have") end
      return f
    end,
    __newindex = function(_, k, v) api[k] = v end,
  })
  return reaper
end

function P.reset()
  P.tracks, P.selected, P.editorTake = {}, {}, nil
  P.selTracks, P.lastTouched, P.stuffed, P.now = {}, nil, {}, 1000.0
  P.tempo, P.num, P.den = 120, 4, 4
  P.cursor, P.playing, P.playPos, P.recording = 0, false, 0, false
  P.project, P.os, P.execs, P.inputs, P.asked = "", "OSX64", {}, nil, nil
  P.sws, P.js, P.jsFolder, P.shell = false, false, nil, {}
  P.undoDepth, P.undoNames, P.refreshDepth = 0, {}, 0
  P.calls = {}
end

return P
