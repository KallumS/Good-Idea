--[[ Good Idea - getting an idea into the project.

     Everything here talks to REAPER, and nothing here touches ImGui, so
     tests/test_place.lua can run it against a mocked reaper and check what it
     asks REAPER to do. The mock is written from the API documentation's
     signatures, not from what this file expects.

     Midi Catalogue's placement, with one change: an idea laid out in one
     item keeps each part on its own MIDI channel (drums on 10), and an idea
     laid out on tracks gets a new track per part, named for it - Melody,
     Chords, Bass, Drums.
]]

local M = {}

M.OK, M.NO_TRACK, M.WRITE_FAILED, M.NOTHING = 0, 1, 2, 3

local SEP = package.config:sub(1, 1)

function M.setMidi(midi) M.midi = midi end

------------------------------------------------------------------------------
-- What the project is doing
------------------------------------------------------------------------------

function M.tempo() return reaper.Master_GetTempo() end

-- Three return values, numerator first: there is no retval in front of them.
function M.timeSig(at)
  local num, den = reaper.TimeMap_GetTimeSigAtTime(0, at or 0)
  if not num or num <= 0 or not den or den <= 0 then return 4, 4 end
  return num, den
end

-- The time signature at the edit cursor, where an idea will go.
function M.timeSigNow() return M.timeSig(reaper.GetCursorPosition()) end

------------------------------------------------------------------------------
-- Putting an idea on tracks
------------------------------------------------------------------------------

-- A selected track wins, because that is the one being pointed at.
function M.defaultTrack()
  return reaper.GetSelectedTrack(0, 0) or reaper.GetLastTouchedTrack()
end

-- One MIDI item on a track, holding these notes, each on its own channel.
local function writeItem(track, time, startQN, beats, notes, name)
  local endTime = reaper.TimeMap2_QNToTime(0, startQN + beats)
  local item = reaper.CreateNewMIDIItemInProj(track, time, endTime, false)
  if not item then return false end
  local take = reaper.GetActiveTake(item)
  for _, nt in ipairs(notes) do
    local sp = reaper.MIDI_GetPPQPosFromProjQN(take, startQN + nt.start)
    local ep = reaper.MIDI_GetPPQPosFromProjQN(take, startQN + nt.start + nt.len)
    reaper.MIDI_InsertNote(take, false, false, sp, ep, nt.chan or 0, nt.pitch, nt.vel or 100, true)
  end
  reaper.MIDI_Sort(take)
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
  return true
end

-- An idea in one item goes on the selected track at the edit cursor. An idea
-- laid out on tracks gets a new track for each part, named for it, under the
-- selected track (or at the end of the project when nothing is selected), all
-- at the edit cursor, as one undo step.
function M.insert(block, track, time)
  if #block.notes == 0 then return M.NOTHING end
  time = time or reaper.GetCursorPosition()
  local startQN = reaper.TimeMap2_timeToQN(0, time)

  if block.layout ~= "tracks" or #block.parts == 1 then
    track = track or M.defaultTrack()
    if not track then return M.NO_TRACK end
    reaper.Undo_BeginBlock()
    local ok = writeItem(track, time, startQN, block.beats, block.notes, block.name)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Good Idea: " .. block.name, -1)
    return ok and M.OK or M.NO_TRACK
  end

  local anchor = track or M.defaultTrack()
  local idx = anchor and math.floor(reaper.GetMediaTrackInfo_Value(anchor, "IP_TRACKNUMBER")) or 0
  if idx <= 0 then idx = reaper.CountTracks(0) end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local ok = true
  for k, part in ipairs(block.parts) do
    reaper.InsertTrackAtIndex(idx + k - 1, true)
    local tr = reaper.GetTrack(0, idx + k - 1)
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", part.name, true)
    ok = writeItem(tr, time, startQN, block.beats, part.notes, block.name .. " - " .. part.name) and ok
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Good Idea: " .. block.name, -1)
  return ok and M.OK or M.NO_TRACK
end

------------------------------------------------------------------------------
-- Writing one out
--
-- Where (1.17): "Project" is a Good Idea folder beside the saved project (or
-- REAPER's, until the project has been saved), "REAPER" the Good Idea
-- folder in REAPER's resource path (1.0 to 1.16 wrote there - a folder the
-- Mac's Finder and Windows' Explorer hide), "Folder" one chosen.
------------------------------------------------------------------------------

function M.binPath()
  return reaper.GetResourcePath() .. SEP .. "Good Idea"
end

-- The folder the current project is saved in, or nil if it has not been.
function M.projectFolder()
  local _, fn = reaper.EnumProjects(-1)
  if not fn or fn == "" then return nil end
  return fn:match("^(.*)[/\\]")
end

-- The folder Export writes to, and whether it is the one asked for (false
-- when "Project" falls back to REAPER's for an unsaved project, or no
-- folder has been chosen yet).
function M.exportDir(where, chosen)
  if where == "Folder" then
    if chosen and chosen ~= "" then return chosen, true end
    return M.binPath(), false
  end
  if where == "Project" then
    local p = M.projectFolder()
    if p then return p .. SEP .. "Good Idea", true end
    return M.binPath(), false
  end
  return M.binPath(), true
end

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

-- Exporting the same idea twice gives two files, not one.
function M.uniquePath(dir, base)
  local path = dir .. SEP .. base .. ".mid"
  local n = 2
  while exists(path) do
    path = dir .. SEP .. base .. " " .. n .. ".mid"
    n = n + 1
    if n > 999 then return nil end
  end
  return path
end

function M.export(block, dir)
  if #block.notes == 0 then return M.NOTHING end
  dir = (dir and dir ~= "") and dir:gsub("[/\\]+$", "") or M.binPath()
  reaper.RecursiveCreateDirectory(dir, 0)

  local path = M.uniquePath(dir, M.midi.sanitise(block.name))
  if not path then return M.WRITE_FAILED end

  local num, den = M.timeSigNow()
  local bytes
  if block.layout == "tracks" then
    bytes = M.midi.buildParts(block.parts, block.beats, block.name, M.tempo(), num, den)
  else
    bytes = M.midi.build(block.notes, block.beats, block.name, M.tempo(), num, den)
  end
  local f = io.open(path, "wb")
  if not f then return M.WRITE_FAILED end
  f:write(bytes)
  f:close()
  return M.OK, path
end

-- Opens a folder in the Finder or Explorer, making it first if need be.
-- SWS's CF_ShellExecute where it is installed; otherwise the system's own
-- command, without waiting for it.
function M.openFolder(dir)
  reaper.RecursiveCreateDirectory(dir, 0)
  if reaper.CF_ShellExecute then return reaper.CF_ShellExecute(dir) end
  local system = reaper.GetOS()
  local cmd
  if system:find("Win") then cmd = 'explorer "' .. dir .. '"'
  elseif system:find("OSX") or system:find("mac") then cmd = 'open "' .. dir .. '"'
  else cmd = 'xdg-open "' .. dir .. '"' end
  return reaper.ExecProcess(cmd, -1) ~= nil
end

-- Asks for a folder: the system's folder chooser where the js_ReaScriptAPI
-- extension is installed, otherwise a box to paste a folder's path into.
-- Returns the folder, or nil if cancelled.
function M.chooseFolder(current)
  local title = "Good Idea: save .mid files in"
  if reaper.JS_Dialog_BrowseForFolder then
    local rv, folder = reaper.JS_Dialog_BrowseForFolder(title, current or "")
    if rv == 1 and folder and folder ~= "" then return folder end
    return nil
  end
  local done, got = reaper.GetUserInputs(title, 1, "Folder (paste its path):,extrawidth=420,separator=\n",
                                         current or "")
  if not done then return nil end
  got = (got or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub('^"(.*)"$', "%1")
  if got == "" then return nil end
  return got
end

------------------------------------------------------------------------------
-- Hearing one
--
-- Notes go to the virtual keyboard, so a record-armed and monitored track
-- plays them. A deferred script wakes about thirty times a second, so this is
-- a preview rather than a performance: a note lands on the nearest wake-up,
-- not on the sample. Anything that needs to be exact wants the idea in the
-- project, where REAPER plays it properly.
--
-- Two clocks (1.17). Audition keeps its own, from the moment it starts.
-- Playing with REAPER takes REAPER's: when the transport plays, the idea
-- plays along from the bar the edit cursor is in, in the project's tempo, so
-- it sounds where Insert would put it. Either way the preview is a position
-- in the idea, in quarter notes; each wake-up plays what is due up to it.
-- When the position jumps (a loop going round, REAPER's play position moved,
-- a click on the roll), what was sounding stops and the notes held across the
-- new position are struck again, so a chord in the middle is heard.
------------------------------------------------------------------------------

local preview = {
  on = false, mode = "free", notes = nil, beats = 0, idx = 1, sounding = {},
  at = nil,                     -- where it last played up to, in quarter notes
  t0 = 0, spb = 0.5,            -- Audition's own clock
  anchor = 0,                   -- with REAPER: the project's quarter note the idea starts on
  wasPlaying = false, wasOn = false,
}
M.preview = preview

-- A jump forward of more than this is a jump, not a late wake-up: the notes
-- skipped are not played all at once.
local JUMP = 1

-- A sounding note is keyed by channel and pitch: the chords and the tune can
-- hold the same pitch at once on different channels.
local function noteKey(chan, pitch) return chan * 128 + pitch end

local function allNotesOff()
  for k in pairs(preview.sounding) do
    reaper.StuffMIDIMessage(0, 0x80 + k // 128, k % 128, 0)
  end
  preview.sounding = {}
end

local function strike(n)
  local chan = n.chan or 0
  reaper.StuffMIDIMessage(0, 0x90 + chan, n.pitch, n.vel or 100)
  local k = noteKey(chan, n.pitch)
  preview.sounding[k] = math.max(preview.sounding[k] or 0, n.start + n.len)
end

-- Sorted by start, so the loop only ever looks at the next one due.
local function sorted(block)
  local notes = {}
  for i, n in ipairs(block.notes) do notes[i] = n end
  table.sort(notes, function(a, b)
    if a.start ~= b.start then return a.start < b.start end
    if a.pitch ~= b.pitch then return a.pitch < b.pitch end
    return (a.chan or 0) < (b.chan or 0)
  end)
  return notes
end

local function load(block)
  preview.notes, preview.beats = sorted(block), block.beats
  preview.idx, preview.at = 1, nil
end

-- Starts again from `at`: everything off, then every note due by then that
-- is still sounding at it struck, and the next one due found.
local function seek(at)
  allNotesOff()
  local notes, i = preview.notes, 1
  while i <= #notes and notes[i].start <= at do
    if notes[i].start + notes[i].len > at then strike(notes[i]) end
    i = i + 1
  end
  preview.idx, preview.at = i, at
end

-- Plays the idea up to `at`.
local function playTo(at)
  if preview.at == nil or at < preview.at - 1e-6 or at > preview.at + JUMP then
    seek(at)
  else
    for k, until_ in pairs(preview.sounding) do
      if at >= until_ then
        reaper.StuffMIDIMessage(0, 0x80 + k // 128, k % 128, 0)
        preview.sounding[k] = nil
      end
    end
    while preview.idx <= #preview.notes and preview.notes[preview.idx].start <= at do
      strike(preview.notes[preview.idx])
      preview.idx = preview.idx + 1
    end
    preview.at = at
  end
end

-- Outside the idea (before it, or after it with Loop off, with REAPER
-- playing): silent, and ready to come back in.
local function rest()
  allNotesOff()
  preview.at = nil
end

-- Audition: the idea on its own clock, from quarter note `from` (the top
-- unless a click on the roll says otherwise).
function M.previewStart(block, tempo, now, from)
  M.previewStop()
  if #block.notes == 0 then return false end
  load(block)
  preview.on, preview.mode = true, "free"
  preview.spb = 60 / math.max(tempo or 120, 1)
  preview.t0 = (now or reaper.time_precise()) - (from or 0) * preview.spb
  return true
end

function M.previewStop()
  if preview.on then allNotesOff() end
  preview.on, preview.notes, preview.at = false, nil, nil
end

function M.previewRunning() return preview.on end
function M.previewWithReaper() return preview.on and preview.mode == "reaper" end

-- A new idea while one is playing: it takes over where the old one was, so
-- with REAPER playing a new idea comes in in time.
function M.previewSwap(block)
  if not preview.on then return false end
  allNotesOff()
  if #block.notes == 0 then M.previewStop(); return false end
  load(block)
  return true
end

------------------------------------------------------------------------------
-- Playing with REAPER
------------------------------------------------------------------------------

-- Playing, and not recording: a monitored track recording its input would
-- record the preview into the take.
function M.reaperPlaying()
  local state = reaper.GetPlayState()
  return state & 1 == 1 and state & 4 == 0
end

-- The project's quarter note REAPER is playing. GetPlayPosition2 is the
-- audio block being worked on now, which is the one a note stuffed now joins.
local function reaperQN() return reaper.TimeMap2_timeToQN(0, reaper.GetPlayPosition2()) end

-- The start of the bar the edit cursor is in: where the idea starts.
function M.anchorQN()
  local qn = reaper.TimeMap2_timeToQN(0, reaper.GetCursorPosition())
  local _, barStart = reaper.TimeMap_QNToMeasures(0, qn)
  return barStart or qn
end

function M.previewWithReaperStart(block)
  M.previewStop()
  if #block.notes == 0 then return false end
  load(block)
  preview.on, preview.mode = true, "reaper"
  preview.anchor = M.anchorQN()
  return true
end

-- Called once a frame: starts the idea when REAPER starts playing, stops it
-- when REAPER stops. `on` is the Play with REAPER switch; ticking it while
-- REAPER plays joins in. Stopping the preview by hand while REAPER plays
-- keeps it quiet until REAPER's next play.
function M.follow(block, on)
  local playing = M.reaperPlaying()
  local started = playing and not preview.wasPlaying
  local stopped = preview.wasPlaying and not playing
  local turnedOn = on and not preview.wasOn
  preview.wasPlaying, preview.wasOn = playing, on
  if not on then
    if M.previewWithReaper() then M.previewStop() end
    return
  end
  if playing and (started or turnedOn) and block then
    M.previewWithReaperStart(block)
  elseif stopped and M.previewWithReaper() then
    M.previewStop()
  end
end

-- A click on the roll, at quarter note `at` of the idea. With REAPER playing
-- along, REAPER's play position moves there (and the edit cursor with it,
-- as a click on REAPER's ruler would); otherwise Audition plays from there.
function M.previewFrom(block, at, tempo, loop)
  if M.previewWithReaper() and M.reaperPlaying() then
    local base = preview.anchor
    local qn = reaperQN()
    if loop and qn > base and preview.beats > 0 then
      base = base + math.floor((qn - base) / preview.beats) * preview.beats
    end
    reaper.SetEditCurPos(reaper.TimeMap2_QNToTime(0, base + at), false, true)
    return true
  end
  return M.previewStart(block, tempo, nil, at)
end

-- Returns how far through the idea the preview is, 0 to 1, or nil when it is
-- not running (or, with REAPER, is outside the idea). Called once per defer.
function M.previewTick(now, loop)
  if not preview.on then return nil end
  local beats = math.max(preview.beats, 1e-9)
  local at
  if preview.mode == "reaper" then
    at = reaperQN() - preview.anchor
    if at < 0 then rest(); return nil end
    if loop then at = at % beats
    elseif at >= beats then rest(); return nil end
  else
    now = now or reaper.time_precise()
    at = (now - preview.t0) / preview.spb
    if at >= beats then
      if not loop then M.previewStop(); return nil end
      -- Round again, keeping time: the clock moves on by the idea's length.
      local rounds = math.floor(at / beats)
      preview.t0 = preview.t0 + rounds * beats * preview.spb
      at = at - rounds * beats
    end
  end
  playTo(at)
  return at / beats
end

return M
