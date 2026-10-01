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
local m = idea({ kind = "Measure", measureBars = 8, drums = "On", layout = "Tracks" })
eq(m.layout, "tracks", "a Measure on tracks")
eq(#m.parts, 4, "melody, chords, bass and drums")
eq(Place.insert(m), Place.OK, "inserting it works")
eq(#P.tracks, 7, "four new tracks")
eq(P.tracks[1], top, "the track above stays where it was")
eq(P.tracks[2], sel, "and the selected one")
eq(P.tracks[3].name, "Melody", "the tune first, under the selected track")
eq(P.tracks[4].name, "Chords", "then the chords")
eq(P.tracks[5].name, "Bass", "the bass")
eq(P.tracks[6].name, "Drums", "the drums")
eq(P.tracks[7], bottom, "and the track below is pushed down")
for i = 3, 6 do
  eq(#P.tracks[i].items, 1, P.tracks[i].name .. " has one item")
  eq(#P.tracks[i].items[1].take.notes, #m.parts[i - 2].notes, P.tracks[i].name .. " has its part's notes")
end
for _, nt in ipairs(P.tracks[6].items[1].take.notes) do
  if nt.chan ~= 9 then ok(false, "every drum note is on channel 10"); break end
end
for _, nt in ipairs(P.tracks[3].items[1].take.notes) do
  if nt.chan ~= 0 then ok(false, "on its own track the tune is on channel 1"); break end
end
eq(P.undoDepth, 0, "one undo block, closed")
eq(#P.undoNames, 1, "just one")
eq(P.refreshDepth, 0, "and the UI refresh is let go")

-- Nothing selected: the new tracks go at the end.
P.reset()
P.track("Only")
eq(Place.insert(m), Place.OK, "with nothing selected it still inserts")
eq(#P.tracks, 5, "four new tracks")
eq(P.tracks[2].name, "Melody", "at the end of the project")

-- A Measure in one item: every part on the selected track, on its own channel.
P.reset()
tr = P.track("One")
P.selTracks = { tr }
local one = idea({ kind = "Measure", measureBars = 8, drums = "On", layout = "One item" })
eq(one.layout, "one", "a Measure in one item")
eq(Place.insert(one), Place.OK, "inserts")
eq(#P.tracks, 1, "no new tracks")
chans = {}
for _, nt in ipairs(tr.items[1].take.notes) do chans[nt.chan] = true end
ok(chans[0] and chans[1] and chans[2] and chans[9], "channels 1, 2, 3 and 10 (0, 1, 2, 9 to REAPER)")

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
eq(data:byte(12), 5, "a tempo track and one per part")
eq(Place.export({ notes = {}, parts = {}, beats = 4, name = "x" }), Place.NOTHING, "an empty idea writes nothing")

------------------------------------------------------------------------------
-- Audition
------------------------------------------------------------------------------

P.reset()
ok(Place.previewStart(one, 120, 0), "audition starts")
ok(Place.previewRunning(), "and is running")
local at = Place.previewTick(0.01)
ok(at and at >= 0, "the first tick says where it is")
local sawDrum, sawMelody = false, false
for _, msg in ipairs(P.stuffed) do
  eq(msg.mode, 0, "to the virtual keyboard")
  if msg.a == 0x99 then sawDrum = true end
  if msg.a == 0x90 then sawMelody = true end
end
ok(sawDrum, "the drums play on channel 10")
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

-- Looping goes round again.
P.reset()
Place.previewStart(b, 120, 0)
local again = Place.previewTick(b.beats / 2 + 0.01, true)
eq(again, 0, "with Loop on, the end starts it again")
ok(Place.previewRunning(), "and it keeps running")
Place.previewStop()
ok(not Place.previewRunning(), "until stopped")

C.done()
