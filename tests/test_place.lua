--[[ Inserting, exporting and auditioning, against a mocked REAPER.

     The mock (tests/reaper_mock.lua) is written from the API documentation's
     signatures and raises on anything it does not have, so a call REAPER does
     not have fails here rather than in REAPER.

       lua5.4 tests/test_place.lua
]]

local HERE = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local C = dofile(HERE .. "/check.lua")
local ok, eq = C.ok, C.eq
local P = dofile(HERE .. "/reaper_mock.lua")
P.install()

local T = dofile(C.SCRIPTS .. "gi_theory.lua")
local I = dofile(C.SCRIPTS .. "gi_idea.lua").init(T)
local Midi = dofile(C.SCRIPTS .. "gi_midi.lua")
local Place = dofile(C.SCRIPTS .. "gi_place.lua")
Place.setMidi(Midi)

local function idea(settings, seed)
  local st = I.newState()
  for k, v in pairs(settings) do st[k] = v end
  I.clampState(st)
  return I.make(st, I.meter(4, 4), seed or 1).block
end

------------------------------------------------------------------------------
-- What the project says
------------------------------------------------------------------------------

P.reset()
P.num, P.den = 6, 8
local n, d = Place.timeSigNow()
eq(n .. "/" .. d, "6/8", "the time signature is the project's, numerator first")
P.num, P.den = 0, 0
n, d = Place.timeSigNow()
eq(n .. "/" .. d, "4/4", "and 4/4 when the project says nothing sensible")
P.tempo = 96
eq(Place.tempo(), 96, "the tempo is the project's")

------------------------------------------------------------------------------
-- One item: on the selected track
------------------------------------------------------------------------------

P.reset()
local tr = P.track("Keys")
P.selTracks = { tr }
P.cursor = 2          -- seconds: four beats in at 120
local b = idea({ kind = "Phrase", content = "Both", phraseBars = 2 })
eq(b.layout, "one", "a phrase is one item")
eq(#b.parts, 2, "with a tune and chords")
eq(Place.insert(b), Place.OK, "inserting it works")
eq(#P.tracks, 1, "no new tracks")
eq(#tr.items, 1, "one item")
local item = tr.items[1]
eq(item.pos, 2, "at the edit cursor")
eq(item.len, b.beats / 2, "as long as the idea")
eq(#item.take.notes, #b.notes, "with every note of both parts")
eq(item.take.name, b.name, "named for the idea")
ok(item.take.sorted, "sorted once, after the batch")
for _, nt in ipairs(item.take.notes) do ok(nt.noSort, "each note inserted with noSort") end
local chans = {}
for _, nt in ipairs(item.take.notes) do chans[nt.chan] = (chans[nt.chan] or 0) + 1 end
ok(chans[0] and chans[1], "the tune on channel 1 and the chords on channel 2 (0 and 1 to REAPER)")
eq(P.undoDepth, 0, "the undo block is closed")
ok(P.undoNames[1]:find("^Good Idea: "), "and named")

-- The first note lands where the idea says, measured from the item's start.
eq(item.take.notes[1].sp, b.notes[1].start * 960, "note times are measured from the item's start")

-- No track, no insert, and the undo block is still closed.
P.reset()
eq(Place.insert(b), Place.NO_TRACK, "no selected track, nothing inserted")
eq(P.undoDepth, 0, "and no undo block left open")
P.lastTouched = P.track("Last")
eq(Place.insert(b), Place.OK, "the last touched track is used when none is selected")

-- A track that refuses the item closes its undo block too.
P.reset()
local refuses = P.track("Refuses")
refuses.refuses = true
P.selTracks = { refuses }
eq(Place.insert(b), Place.NO_TRACK, "a refused item is reported")
eq(P.undoDepth, 0, "and the undo block closed")

-- Nothing to insert.
eq(Place.insert({ notes = {}, parts = {}, beats = 4, name = "x" }), Place.NOTHING, "an empty idea inserts nothing")

------------------------------------------------------------------------------
-- A Measure on tracks: a new track per part, under the selected track
------------------------------------------------------------------------------

P.reset()
local top = P.track("Top")
local sel = P.track("Selected")
local bottom = P.track("Bottom")
P.selTracks = { sel }
local m = idea({ kind = "Measure", measureBars = 8, layout = "Tracks" })
eq(m.layout, "tracks", "a Measure on tracks")
eq(#m.parts, 3, "melody, chords and bass - no drums")
eq(Place.insert(m), Place.OK, "inserting it works")
eq(#P.tracks, 6, "three new tracks")
eq(P.tracks[1], top, "the track above stays where it was")
eq(P.tracks[2], sel, "and the selected one")
eq(P.tracks[3].name, "Melody", "the tune first, under the selected track")
eq(P.tracks[4].name, "Chords", "then the chords")
eq(P.tracks[5].name, "Bass", "the bass")
eq(P.tracks[6], bottom, "and the track below is pushed down")
for i = 3, 5 do
  eq(#P.tracks[i].items, 1, P.tracks[i].name .. " has one item")
  eq(#P.tracks[i].items[1].take.notes, #m.parts[i - 2].notes, P.tracks[i].name .. " has its part's notes")
end
for i = 3, 5 do
  for _, nt in ipairs(P.tracks[i].items[1].take.notes) do
    if nt.chan ~= 0 then ok(false, "on its own track every part is on channel 1"); break end
  end
end
eq(P.undoDepth, 0, "one undo block, closed")
eq(#P.undoNames, 1, "just one")
eq(P.refreshDepth, 0, "and the UI refresh is let go")

-- Nothing selected: the new tracks go at the end.
P.reset()
P.track("Only")
eq(Place.insert(m), Place.OK, "with nothing selected it still inserts")
eq(#P.tracks, 4, "three new tracks")
eq(P.tracks[2].name, "Melody", "at the end of the project")

-- A Measure in one item: every part on the selected track, on its own channel.
P.reset()
tr = P.track("One")
P.selTracks = { tr }
local one = idea({ kind = "Measure", measureBars = 8, layout = "One item" })
eq(one.layout, "one", "a Measure in one item")
eq(Place.insert(one), Place.OK, "inserts")
eq(#P.tracks, 1, "no new tracks")
chans = {}
for _, nt in ipairs(tr.items[1].take.notes) do chans[nt.chan] = true end
ok(chans[0] and chans[1] and chans[2] and not chans[9], "channels 1, 2 and 3 (0, 1, 2 to REAPER), and no drums")

-- A drum idea: one item on the selected track, every note on channel 10.
P.reset()
tr = P.track("Drums")
P.selTracks = { tr }
local kit = idea({ kind = "Drums", drumBars = 4 })
eq(kit.layout, "one", "a drum idea is one item")
eq(Place.insert(kit), Place.OK, "inserts")
eq(#P.tracks, 1, "on the selected track")
local allTen = #tr.items[1].take.notes > 0
for _, nt in ipairs(tr.items[1].take.notes) do if nt.chan ~= 9 then allTen = false end end
ok(allTen, "every drum note on channel 10")

------------------------------------------------------------------------------
-- Export
------------------------------------------------------------------------------

P.reset()
os.execute('rm -rf "' .. P.resource .. '"')
local res, path = Place.export(b)
eq(res, Place.OK, "export works")
ok(path and path:find("Good Idea", 1, true), "into the Good Idea folder: " .. tostring(path))
local f = io.open(path, "rb")
ok(f, "the file is there")
local data = f and f:read("a") or ""
if f then f:close() end
eq(data:sub(1, 4), "MThd", "and is a MIDI file")
eq(data:byte(10), 0, "one item is format 0")
local res2, path2 = Place.export(b)
eq(res2, Place.OK, "exporting again works")
ok(path2 ~= path and path2:find(" 2.mid", 1, true), "into a second file, not over the first")

local _, mpath = Place.export(m)
f = io.open(mpath, "rb")
data = f and f:read("a") or ""
if f then f:close() end
eq(data:byte(10), 1, "a Measure on tracks is format 1")
eq(data:byte(12), 4, "a tempo track and one per part")
eq(Place.export({ notes = {}, parts = {}, beats = 4, name = "x" }), Place.NOTHING, "an empty idea writes nothing")

------------------------------------------------------------------------------
-- Audition
------------------------------------------------------------------------------

P.reset()
ok(Place.previewStart(one, 120, 0), "audition starts")
ok(Place.previewRunning(), "and is running")
local at = Place.previewTick(0.01)
ok(at and at >= 0, "the first tick says where it is")
local sawBass, sawMelody = false, false
for _, msg in ipairs(P.stuffed) do
  eq(msg.mode, 0, "to the virtual keyboard")
  if msg.a == 0x92 then sawBass = true end
  if msg.a == 0x90 then sawMelody = true end
end
ok(sawBass, "the bass plays on channel 3")
ok(sawMelody, "the tune on channel 1")
-- Halfway, then past the end.
Place.previewTick(one.beats * 0.5 / 2)
local done = Place.previewTick(one.beats / 2 + 1)
eq(done, nil, "past the end, it stops")
ok(not Place.previewRunning(), "and says so")
local ons, offs = {}, {}
for _, msg in ipairs(P.stuffed) do
  local k = (msg.a % 16) * 128 + msg.b
  if msg.a >= 0x90 then ons[k] = (ons[k] or 0) + 1 else offs[k] = (offs[k] or 0) + 1 end
end
local hanging = 0
for k in pairs(ons) do if not offs[k] then hanging = hanging + 1 end end
eq(hanging, 0, "every note that started was stopped, on its own channel")

-- A drum idea auditions on channel 10.
P.reset()
Place.previewStart(kit, 120, 0)
Place.previewTick(0.01)
local sawDrum = false
for _, msg in ipairs(P.stuffed) do if msg.a == 0x99 then sawDrum = true end end
ok(sawDrum, "the drums play on channel 10")
Place.previewStop()

-- Looping goes round again.
P.reset()
Place.previewStart(b, 120, 0)
local again = Place.previewTick(b.beats / 2 + 0.01, true)
ok(again and again < 0.01, "with Loop on, the end starts it again, keeping time: " .. tostring(again))
-- A second later (two beats at 120) it is 2.02 beats in: the round kept the
-- time it went round at, not the time the wake-up came.
local later = Place.previewTick(b.beats / 2 + 1.01, true)
ok(later and math.abs(later * b.beats - 2.02) < 1e-6, "and keeps time after it: " .. tostring(later and later * b.beats))
ok(Place.previewRunning(), "and it keeps running")
Place.previewStop()
ok(not Place.previewRunning(), "until stopped")

------------------------------------------------------------------------------
-- 1.17: playing with REAPER
--
-- At 120 a quarter note is half a second: the project's quarter note is the
-- time times two.
------------------------------------------------------------------------------

-- The note-ons sent since `from`, as "channel:pitch" keys.
local function onsSince(from)
  local out = {}
  for i = from + 1, #P.stuffed do
    local m = P.stuffed[i]
    if m.a >= 0x90 then out[#out + 1] = (m.a - 0x90) .. ":" .. m.b end
  end
  table.sort(out)
  return table.concat(out, " ")
end
-- The notes of a block that start in (lo, hi], or that sound across `lo`
-- when `across`, as the same keys.
local function notesIn(block, lo, hi, across)
  local out = {}
  for _, n in ipairs(block.notes) do
    local hit = across and (n.start <= lo and n.start + n.len > lo) or (n.start > lo and n.start <= hi)
    if hit then out[#out + 1] = (n.chan or 0) .. ":" .. n.pitch end
  end
  table.sort(out)
  return table.concat(out, " ")
end
local function hangingNotes()
  local on = {}
  for _, m in ipairs(P.stuffed) do
    local k = (m.a % 16) * 128 + m.b
    on[k] = (on[k] or 0) + ((m.a >= 0x90) and 1 or -1)
  end
  local n = 0
  for _, v in pairs(on) do if v > 0 then n = n + 1 end end
  return n
end

P.reset()
Place.previewStop()
Place.follow(b, true)
ok(not Place.previewRunning(), "with REAPER stopped, nothing plays")
P.cursor = 5          -- quarter note 10: two beats into the third bar, which starts on 8
P.playing, P.playPos = true, 5
Place.follow(b, true)
ok(Place.previewWithReaper(), "REAPER plays: the idea plays with it")
eq(Place.anchorQN(), 8, "from the start of the bar the edit cursor is in")
local where = Place.previewTick(nil, false)
eq(where, 2 / b.beats, "two beats in, where REAPER is")
ok(notesIn(b, 2, 2, true) ~= "", "(something sounds across beat 2)")
eq(onsSince(0), notesIn(b, 2, 2, true), "the notes held across beat 2 are struck, so a chord is heard")
local mark = #P.stuffed
P.playPos = 5.25
Place.previewTick(nil, false)
eq(onsSince(mark), notesIn(b, 2, 2.5), "half a beat on, the notes due in that half beat")
mark = #P.stuffed
P.playPos = 3         -- before the bar the idea starts on
eq(Place.previewTick(nil, false), nil, "before its bar, nothing")
eq(hangingNotes(), 0, "and nothing left sounding")
P.playPos = (8 + b.beats + 0.5) / 2
eq(Place.previewTick(nil, false), nil, "after its end with Loop off, nothing")
eq(hangingNotes(), 0, "and silent")
mark = #P.stuffed
local round = Place.previewTick(nil, true)
eq(round, 0.5 / b.beats, "with Loop on it goes round, in time with the project")
eq(onsSince(mark), notesIn(b, 0.5, 0.5, true), "playing what sounds half a beat in")
P.playing = false
Place.follow(b, true)
ok(not Place.previewRunning(), "REAPER stops: so does the idea")
eq(hangingNotes(), 0, "with every note stopped")

-- Never while recording: the take would record it.
P.reset()
P.playing, P.recording = true, true
Place.follow(b, true)
ok(not Place.previewRunning(), "never while REAPER records")
P.recording = false

-- The switch: off, REAPER's play is ignored; on while it plays, it joins in.
P.reset()
Place.follow(b, false)
P.playing = true
Place.follow(b, false)
ok(not Place.previewRunning(), "Play with REAPER off: play is ignored")
Place.follow(b, true)
ok(Place.previewWithReaper(), "ticked while REAPER plays, it joins in")
Place.follow(b, false)
ok(not Place.previewRunning(), "unticked, it stops")

-- Stopped by hand, it stays quiet until REAPER's next play.
P.reset()
Place.follow(b, true)
P.playing = true
Place.follow(b, true)
Place.previewStop()
Place.follow(b, true)
ok(not Place.previewRunning(), "stopped by hand, it does not start again while REAPER plays")
P.playing = false
Place.follow(b, true)
P.playing = true
Place.follow(b, true)
ok(Place.previewWithReaper(), "until REAPER plays again")

-- A new idea while REAPER plays takes over where the old one was.
P.reset()
P.playing = false
Place.follow(b, true)
P.cursor, P.playing, P.playPos = 4, true, 5
Place.follow(b, true)
Place.previewTick(nil, false)
local c2 = idea({ kind = "Phrase", content = "Both", phraseBars = 2 }, 7)
ok(Place.previewSwap(c2), "a new idea swaps in")
mark = #P.stuffed
Place.previewTick(nil, false)
eq(onsSince(mark), notesIn(c2, 2, 2, true), "and is heard from the same beat, in time")
ok(Place.previewWithReaper(), "still with REAPER")

-- A click on the roll: with REAPER playing, REAPER goes there.
P.reset()
P.playing = false
Place.follow(b, true)
P.cursor, P.playing, P.playPos = 4, true, 4
Place.follow(b, true)
Place.previewFrom(b, 4, 120, false)
eq(P.cursor, 6, "REAPER's play position moves to beat 4 of the idea (quarter note 12)")
eq(P.playPos, 6, "and playback with it")
P.playPos = (8 + b.beats + 1) / 2   -- the second time round, with Loop on
Place.previewTick(nil, true)
Place.previewFrom(b, 4, 120, true)
eq(P.cursor, (8 + b.beats + 4) / 2, "the second time round, to beat 4 of the second time round")

-- Without REAPER playing, Audition plays from there.
P.reset()
P.playing = false
Place.follow(b, true)
Place.previewFrom(b, 4, 120, false)
ok(Place.previewRunning() and not Place.previewWithReaper(), "with REAPER stopped, a click auditions")
P.now = P.now + 0.001
mark = #P.stuffed
Place.previewTick(nil, false)
eq(onsSince(mark), notesIn(b, 4, 4, true), "from beat 4, with what sounds across it")
Place.previewStop()

------------------------------------------------------------------------------
-- 1.17: where Export writes
------------------------------------------------------------------------------

P.reset()
local reaperDir = P.resource .. "/Good Idea"
local d0, asked = Place.exportDir("Project", "")
eq(d0, reaperDir, "an unsaved project: REAPER's Good Idea folder")
eq(asked, false, "and says it is not the one asked for")
P.project = "/music/My Song/My Song.rpp"
eq(Place.exportDir("Project", ""), "/music/My Song/Good Idea", "a saved one: a Good Idea folder beside it")
P.project = "C:\\Music\\Song.rpp"
eq(Place.exportDir("Project", ""), "C:\\Music/Good Idea", "a Windows path too")
eq(Place.exportDir("REAPER", "/x"), reaperDir, "REAPER: the resource path's")
eq(select(2, Place.exportDir("Folder", "")), false, "a folder not chosen yet: REAPER's, and said")
eq(Place.exportDir("Folder", "/somewhere"), "/somewhere", "a chosen folder")

local out = os.tmpname()
os.remove(out)
local res3, path3 = Place.export(b, out .. "/")
eq(res3, Place.OK, "export into a chosen folder")
ok(path3 and path3:sub(1, #out + 1) == out .. "/" and not path3:find("//", 1, true), "into it: " .. tostring(path3))
local f3 = path3 and io.open(path3, "rb")
ok(f3, "the file is there")
if f3 then f3:close() end
os.execute('rm -rf "' .. out .. '"')

-- Open folder: SWS's CF_ShellExecute, or the system's own command.
P.reset()
P.sws = true
Place.openFolder("/music/Good Idea")
eq(P.shell[1], "/music/Good Idea", "with SWS, CF_ShellExecute opens it")
P.sws = false
Place.openFolder("/music/Good Idea")
eq(P.execs[1] and P.execs[1].cmd, 'open "/music/Good Idea"', "on a Mac, open")
eq(P.execs[1] and P.execs[1].timeout, -1, "without waiting")
P.os = "macOS-arm64"      -- the 7.79 page's name for an Apple-silicon Mac
Place.openFolder("/music/Good Idea")
eq(P.execs[#P.execs] and P.execs[#P.execs].cmd, 'open "/music/Good Idea"', "on an Apple-silicon Mac, open too")
P.execs = { P.execs[1] }
P.os = "Win64"
Place.openFolder("C:\\Music\\Good Idea")
eq(P.execs[2] and P.execs[2].cmd, 'explorer "C:\\Music\\Good Idea"', "on Windows, Explorer")
P.os = "Other"
Place.openFolder("/music")
eq(P.execs[3] and P.execs[3].cmd, 'xdg-open "/music"', "elsewhere, xdg-open")

-- Choosing one: the folder chooser with js_ReaScriptAPI, a box without.
P.reset()
P.js, P.jsFolder = true, "/chosen"
eq(Place.chooseFolder("/start"), "/chosen", "js_ReaScriptAPI's folder chooser")
P.jsFolder = nil
eq(Place.chooseFolder("/start"), nil, "cancelled, nothing")
P.js = false
P.inputs = '  "/a b/c"  '
eq(Place.chooseFolder("/start"), "/a b/c", "without it, a pasted path, quotes and spaces taken off")
eq(P.asked and P.asked.values, "/start", "the box starts with the folder now")
P.inputs = nil
eq(Place.chooseFolder("/start"), nil, "cancelled, nothing")
P.inputs = "   "
eq(Place.chooseFolder("/start"), nil, "an empty box, nothing")

C.done()
