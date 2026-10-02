--[[ Good Idea - the ideas.

     Pure Lua: nothing here touches REAPER or ImGui. `M.make(st, meter, seed)`
     takes the settings, the project's metre and an idea number, and returns
     the idea - a block of MIDI notes in parts. Nothing else goes in, so the
     same three always give the same idea
     (docs/decisions/0002-an-idea-is-a-number.md).

     How an idea is made, top to bottom:

       1. resolve   every setting left on "Any" is rolled, each from its own
                    draw of the dice
       2. plan      the idea is cut into units - a basic idea, its repeat, a
                    sequence of it, an answer, a fragment, a cadence - from a
                    template for the kind and length (Motif, Phrase) or the
                    form (Measure)
       3. harmony   each unit gets its chords: a walk through the
                    tonic-subdominant-dominant table (gi_theory) ending in
                    the unit's cadence. A repeat reuses its source's chords,
                    a sequence shifts them, an answer changes the ending
       4. melody    each new unit gets a rhythm (the strongest beats, or a
                    Euclidean spread for syncopation) and a line (a weighted
                    walk pulled toward a contour, chord tones on the beat,
                    leaps filled by a step back). Repeats copy, sequences
                    shift, answers change the ending, fragments cut and fall
       5. parts     the chords voiced and played in a pattern; for a Measure
                    a bass line and a drum kit as well
       6. block     notes in quarter notes, a part per instrument

     Everything is worked out in sixteenth-note steps and scale positions, and
     only turned into quarter notes and MIDI pitches at the very end.
]]

local M = {}
local T

function M.init(theory)
  T = theory
  M.buildSettings()
  return M
end

M.MAX_SEED = 99999
M.ACCENT = 115

------------------------------------------------------------------------------
-- The dice
--
-- Midi Variator's generator (Park and Miller's), so a seed always gives the
-- same numbers on any Lua. Each part of the idea draws from its own stream,
-- seeded from the idea number and the stream's name, so changing one setting
-- changes only what depends on it: a different chord style leaves the melody
-- alone, a different key moves the same tune into it.
------------------------------------------------------------------------------

function M.random(seed)
  local s = math.floor(math.abs(seed or 1)) % 2147483646 + 1
  local function nextr()
    s = s * 48271 % 2147483647
    return (s - 1) / 2147483646
  end
  -- The first few numbers from neighbouring seeds are close together; let
  -- them go.
  for _ = 1, 4 do nextr() end
  return nextr
end

local STREAMS = { pick = 1, plan = 2, harmony = 3, rhythm = 4, melody = 5,
                  chords = 6, bass = 7, drums = 8, borrow = 9, push = 10,
                  pull = 11, kit = 12, colour = 13, invert = 14, applied = 15 }

function M.stream(seed, name)
  local salt = STREAMS[name] or 0
  return M.random((math.floor(seed or 1) * 7919 + salt * 104729 + 12345) % 2147483646)
end

local function between(rnd, lo, hi) return lo + (hi - lo) * rnd() end
local function coin(rnd, p) return rnd() < (p or 0.5) end
local function pickOne(rnd, list) return list[math.floor(rnd() * #list) + 1] end
local function round(x) return math.floor(x + 0.5) end

-- One of `items` in proportion to `weights` (a list, or nil for even), from
-- one number already drawn.
local function pickAt(x, items, weights)
  local total = 0
  for i = 1, #items do total = total + (weights and weights[i] or 1) end
  local at = x * total
  for i = 1, #items do
    at = at - (weights and weights[i] or 1)
    if at < 0 then return items[i] end
  end
  return items[#items]
end

local function weighted(rnd, items, weights) return pickAt(rnd(), items, weights) end

------------------------------------------------------------------------------
-- Metre
--
-- A bar is counted in sixteenths. The beat is what the time signature's
-- bottom number says, except in 6/8, 9/8 and 12/8, where it is the dotted
-- quarter - that is how those are felt and played.
------------------------------------------------------------------------------

function M.meter(num, den)
  num = math.max(1, math.floor(tonumber(num) or 4))
  den = math.max(1, math.floor(tonumber(den) or 4))
  local bar = math.max(4, round(num * 16 / den))
  local beat
  if den == 8 and num % 3 == 0 and num >= 6 then beat = 6
  else beat = math.max(1, math.floor(16 / den)) end
  if bar % beat ~= 0 then beat = 1 end
  local beats = bar // beat
  -- The half-bar beat (beat 3 of 4/4) is stronger than the others.
  local mid = (beats % 2 == 0 and beats >= 4) and bar // 2 or nil
  return { num = num, den = den, bar = bar, beat = beat, beats = beats, mid = mid,
           barBeats = bar / 4 }
end

-- How strong a step is: 3 the downbeat, 2.5 the half bar, 2 a beat, 1 an
-- eighth, 0 a sixteenth.
function M.strength(meter, step)
  local s = step % meter.bar
  if s == 0 then return 3 end
  if meter.mid and s == meter.mid then return 2.5 end
  if s % meter.beat == 0 then return 2 end
  if s % 2 == 0 then return 1 end
  return 0
end

local function snap(meter, x) return round(x / meter.beat) * meter.beat end

------------------------------------------------------------------------------
-- The settings
--
-- One list, and everything reads it: the window draws a row of buttons per
-- setting, the state is clamped and saved from it, resolve rolls the ones
-- left on "Any", and the UI test clicks every value of every one. A setting
-- shows only `when` it means something for what is chosen (no dead controls).
------------------------------------------------------------------------------

M.KINDS = { "Motif", "Phrase", "Measure", "Drums" }

local function notDrums(st) return st.kind ~= "Drums" end
local function hasMelody(st)
  return st.kind ~= "Drums" and (st.kind ~= "Phrase" or st.content ~= "Chords")
end
local function hasChords(st)
  return st.kind == "Measure" or (st.kind == "Phrase" and st.content ~= "Melody")
end
M.hasMelody, M.hasChords = hasMelody, hasChords

local function barsName(v) return v .. (v == 1 and " bar" or " bars") end

function M.buildSettings()
  local rootIdx, scaleIdx = {}, {}
  for i = 1, #T.ROOTS do rootIdx[i] = i end
  for i = 1, #T.SCALES do scaleIdx[i] = i end

  M.SETTINGS = {
    { id = "kind", label = "Make a", step = "Idea", values = M.KINDS, default = "Motif",
      hints = {
        Motif = "A short melodic hook, 1 to 4 bars, built from one small cell repeated and varied.",
        Phrase = "A 1 to 4 bar phrase: a melody, a chord pattern, or both in one clip, with a proper ending.",
        Measure = "8 to 16 bars of music: melody, chords and bass, laid out in a form.",
        Drums = "1 to 16 bars of drums on General MIDI notes: a groove, varied, with fills where you ask for them.",
      } },
    { id = "motifBars", label = "Bars", step = "Idea", values = { 1, 2, 3, 4 }, any = true,
      default = "Any", name = barsName, weights = { 1, 3, 1, 2 },
      when = function(st) return st.kind == "Motif" end },
    { id = "phraseBars", label = "Bars", step = "Idea", values = { 1, 2, 3, 4 }, any = true,
      default = "Any", name = barsName, weights = { 1, 3, 1, 3 },
      when = function(st) return st.kind == "Phrase" end },
    { id = "measureBars", label = "Bars", step = "Idea", values = { 8, 12, 16 }, any = true,
      default = "Any", name = barsName, weights = { 3, 1, 2 },
      when = function(st) return st.kind == "Measure" end },
    { id = "content", label = "Content", step = "Idea", values = { "Melody", "Chords", "Both" },
      any = true, default = "Any", weights = { 1, 1, 1.3 },
      when = function(st) return st.kind == "Phrase" end,
      hints = {
        Melody = "A tune on its own.",
        Chords = "A chord pattern on its own, with the root in the bass.",
        Both = "A tune over a chord pattern, together in one clip (tune on channel 1, chords on 2).",
      } },

    { id = "root", label = "Key", step = "Key", values = rootIdx, any = true, default = 1,
      name = function(v) return T.ROOTS[v].name end, when = notDrums,
      -- Any rolls the twelve common spellings, not C# and Db both.
      anyValues = { 1, 3, 4, 6, 7, 8, 9, 11, 13, 14, 16, 17 } },
    { id = "scale", label = "Scale", step = "Key", values = scaleIdx, any = true, default = 1,
      name = function(v) return T.SCALES[v].name end, when = notDrums,
      -- Any rolls the scales a tune is usually written in; the colour scales
      -- (blues, whole tone, diminished) are there to be chosen.
      anyValues = { 1, 2, 5, 8, 3, 6, 7, 10, 11 },
      anyWeights = { 3, 3, 1.5, 1.2, 1, 0.8, 0.8, 1, 1 } },

    { id = "pace", label = "Pace", step = "Feel", values = { "Calm", "Flowing", "Busy" },
      any = true, default = "Any", weights = { 1, 1.5, 1 },
      hints = {
        Calm = "Few notes: halves, quarters and the odd eighth.",
        Flowing = "Eighth notes moving.",
        Busy = "Sixteenths.",
      } },
    { id = "groove", label = "Groove", step = "Feel", values = { "Straight", "Syncopated" },
      any = true, default = "Any",
      hints = {
        Straight = "Notes on the strongest beats first: on the beat, then the half beat.",
        Syncopated = "Notes spread evenly over the bar (a Euclidean rhythm) and turned so they fall off the beat - the tresillo, the cinquillo.",
      } },

    { id = "contour", label = "Contour", step = "Melody",
      values = { "Arch", "Rise", "Fall", "Wave", "Valley" }, any = true, default = "Any",
      weights = { 1.6, 1, 1, 1, 0.8 }, when = hasMelody,
      hints = {
        Arch = "Up to a high point about two thirds through (the golden section), then down.",
        Rise = "Climbing all the way.",
        Fall = "Starting high and coming down.",
        Wave = "Up and down, and up and down.",
        Valley = "Down to a low point two thirds through, then back up.",
      } },
    { id = "register", label = "Register", step = "Melody", values = { "Low", "Middle", "High" },
      any = true, default = "Middle", weights = { 1, 2, 1 }, when = hasMelody,
      hints = {
        Low = "Around G3.",
        Middle = "Around G4.",
        High = "Around E5.",
      } },

    { id = "colour", label = "Colour", step = "Chords", values = T.COLOURS, any = true,
      default = "Any", weights = { 1.5, 1, 1 }, when = hasChords,
      hints = {
        Triads = "Three-note chords: C, Dm, G.",
        Sevenths = "Every chord with its seventh: Cmaj7, Dm7, G7.",
        Mixed = "Sevenths where they pull (ii, V), added ninths on the others: Cadd9, Dm7, G7 - and, with Flavours on Rare, now and then a sus, a 6th, a 9th or a diminished chord.",
      } },
    { id = "chordPace", label = "Chord pace", step = "Chords",
      values = { "Slow", "One a bar", "1.5 a bar", "Two a bar", "4 a bar" }, any = true, default = "Any",
      -- Shown as numbers (0.5, 1, 1.5, 2, 4 a bar); kept by their 1.0 names
      -- so saved settings still load. Any rolls the three 1.0 had, with
      -- 1.0's weights, so a 1.0 idea number still rolls the same pace; 1.5
      -- and 4 a bar are there to choose.
      name = function(v)
        return ({ Slow = "0.5 a bar", ["One a bar"] = "1 a bar", ["Two a bar"] = "2 a bar" })[v] or v
      end,
      anyValues = { "Slow", "One a bar", "Two a bar" }, anyWeights = { 0.7, 1.6, 0.8 },
      when = hasChords,
      hints = {
        Slow = "Half a chord a bar: a chord every two bars.",
        ["One a bar"] = "A chord a bar.",
        ["1.5 a bar"] = "Three chords every two bars: in 4/4, three beats, three beats, two - the 3+3+2 that pushes a progression along. (Chosen, not rolled by Any.)",
        ["Two a bar"] = "Two chords a bar: one every half bar.",
        ["4 a bar"] = "A chord on every beat - four a bar in 4/4, three in 3/4. (Chosen, not rolled by Any.)",
      } },
    { id = "chordStyle", label = "Style", step = "Chords", values = { "Block", "Pulse", "Broken" },
      any = true, default = "Any", weights = { 1, 1.2, 1 }, when = hasChords,
      hints = {
        Block = "Held chords, struck again at each bar line.",
        Pulse = "The chord struck in rhythm: on the beat, or syncopated.",
        Broken = "One note at a time: up, up and down, Alberti, rolling.",
      } },

    { id = "form", label = "Form", step = "Arrangement",
      values = { "Period", "Sentence", "Song", "Loop", "Hybrid 1", "Hybrid 2", "Hybrid 3", "Hybrid 4",
                 "Ternary", "Extended" }, any = true, default = "Any",
      -- (Any rolls the four 1.0 had, so a 1.0 idea number keeps its form;
      -- the 1.8 forms are there to choose.)
      anyValues = { "Period", "Sentence", "Song", "Loop" },
      when = function(st) return st.kind == "Measure" end,
      hints = {
        ["Hybrid 1"] = "Antecedent + continuation (Caplin's first hybrid): an idea and a contrasting idea to a half close, then breaking it up and speeding to a full close. (Chosen, not rolled by Any.)",
        ["Hybrid 2"] = "Antecedent + cadential: an idea and a contrasting idea to a half close, then one long cadential phrase home. (Chosen, not rolled by Any.)",
        ["Hybrid 3"] = "Compound basic idea + continuation: an idea and a contrasting one with no cadence between, then breaking it up to a full close. (Chosen, not rolled by Any.)",
        ["Hybrid 4"] = "Compound basic idea + consequent: an idea and a contrasting one, then both again, the second time to a full close. (Chosen, not rolled by Any.)",
        Ternary = "A B A (the small ternary): a theme closed in the key, a contrasting middle standing on the dominant, the theme again to finish. (Chosen, not rolled by Any.)",
        Extended = "A sentence stretched by a deceptive cadence: it reaches V and goes to vi instead of home, so the end is played 'one more time' to a full close. (Chosen, not rolled by Any.)",
        Period = "A question and its answer: the same opening twice, ending open and then closed.",
        Sentence = "An idea, the idea again on another chord, then breaking it up and speeding to the cadence.",
        Song = "A A B A: a tune, the tune again, something different, the tune to finish.",
        Loop = "One progression round and round, the tune varied over it - a groove to build on.",
      } },
    { id = "bass", label = "Bass", step = "Arrangement", values = { "Held", "Pulse", "Moving" },
      any = true, default = "Any",
      when = function(st) return st.kind == "Measure" end,
      hints = {
        Held = "The root, held under each chord.",
        Pulse = "The root, in the rhythm a kick drum would play: on 1 and 3, or syncopated.",
        Moving = "On the beat: the root, then the fifth or the octave, and a step into the next chord.",
      } },
    -- Retired: in 1.2 a Measure always had drums; since 1.3 it has none -
    -- drums are the Drums kind. It stays in the list, never shown and only
    -- ever Off, because the list is the order the dice are drawn in.
    { id = "drums", label = "Drums", step = "Arrangement", values = { "Off" },
      default = "Off", retired = true, when = function() return false end },
    { id = "layout", label = "Layout", step = "Out", values = { "Tracks", "One item" },
      default = "Tracks", when = function(st) return st.kind == "Measure" end,
      hints = {
        Tracks = "A new track for each part - Melody, Chords, Bass - under the selected track.",
        ["One item"] = "Every part in one item on the selected track, each on its own MIDI channel (1, 2, 3).",
      } },

    { id = "velocity", label = "Velocity", step = "Out", values = { "Flat", "Accents", "Shaped" },
      default = "Shaped",
      hints = {
        Flat = "Every note at 100.",
        Accents = "Every note at 100, and the downbeats and the start of each idea at " .. M.ACCENT .. ".",
        Shaped = "As a player would: the downbeat loudest, the beats a little softer, the off-beats softer still; the chords under the tune, the inner notes of a chord under its top, the bass just under the tune.",
      } },

    -- Added in 1.1. They come last in this list because the list is also
    -- the order the dice are drawn in: added anywhere else, they would have
    -- changed what every 1.0 idea number rolled.
    { id = "figures", label = "Figures", step = "Feel",
      values = { "Plain", "Dotted", "Triplets", "Mixed" }, any = true, default = "Any",
      weights = { 2, 1, 1, 1 },
      hints = {
        Plain = "Straight eighths and sixteenths.",
        Dotted = "Now and then a pair of notes becomes long-short: a dotted eighth and a sixteenth, a dotted quarter and an eighth - in the tune, the chords and a moving bass.",
        Triplets = "Now and then a beat becomes three: eighth-note triplets, or three quarter notes across two beats. The drums shuffle and broken chords roll in threes.",
        Mixed = "Now and then dotted, now and then triplets.",
      } },
    { id = "push", label = "Push", step = "Feel", values = { "None", "Some", "Lots" },
      any = true, default = "Any", weights = { 1.5, 1.5, 1 }, when = notDrums,
      hints = {
        None = "Every chord arrives on the beat.",
        Some = "Some chords arrive an eighth early - on the 'and' before the beat - and the tune and the bass come with them.",
        Lots = "Most chords arrive an eighth early: a pushed, syncopated feel.",
      } },
    { id = "borrowed", label = "Borrowed", step = "Key", values = { "Off", "Rare", "Common" }, default = "Rare",
      when = function(st) return st.kind ~= "Drums" and (st.scale == "Any" or #T.SCALES[st.scale].iv == 7) end,
      hints = {
        Off = "Every chord from the scale.",
        Rare = "About one idea in four borrows one chord from another scale on the same key note - a minor iv or a bVI in a major key, a major IV in a minor one. The window says which chord, and where it is from. Seven-note scales only.",
        Common = "About two ideas in three borrow a chord, and a longer one (eight chords or more) sometimes two.",
      } },

    -- Added in 1.2, last for the same reason.
    { id = "pull", label = "Pull", step = "Feel", values = { "None", "Some", "Lots" },
      any = true, default = "Any", weights = { 1.5, 1.5, 1 }, when = hasChords,
      hints = {
        None = "Every chord is played on the beat.",
        Some = "Some chords are played an eighth late, laid back behind the beat; the tune and the bass stay on it.",
        Lots = "Most chords lie back an eighth: a lazy, behind-the-beat feel.",
      } },
    { id = "drumBars", label = "Bars", step = "Idea", values = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 },
      any = true, default = "Any", name = function(v) return tostring(v) end,
      weights = { 1, 3, 0.3, 3, 0.2, 0.3, 0.2, 2, 0.2, 0.2, 0.2, 0.6, 0.2, 0.2, 0.2, 1 },
      when = function(st) return st.kind == "Drums" end },
    { id = "beat", label = "Beat", step = "Drums",
      values = { "Backbeat", "Half-time", "Four on the floor", "Breakbeat" }, any = true, default = "Any",
      weights = { 2, 1, 1, 1 }, when = function(st) return st.kind == "Drums" end,
      hints = {
        Backbeat = "Kick on and around 1 and 3, snare on 2 and 4.",
        ["Half-time"] = "The snare on 3 only: twice as slow, twice as heavy.",
        ["Four on the floor"] = "A kick on every beat, a clap on 2 and 4, open hats on the off-beats.",
        Breakbeat = "A broken kick, the snare on 2 and 4 with one knocked off it, sixteenths on the hats. (In 4/4; a backbeat elsewhere.)",
      } },
    { id = "fills", label = "Fills", step = "Drums",
      values = { "None", "At the end", "Every 4 bars", "Every 2 bars" }, any = true, default = "Any",
      weights = { 0.6, 2, 2, 1 }, when = function(st) return st.kind == "Drums" end,
      hints = {
        None = "The groove all the way.",
        ["At the end"] = "A fill in the last bar, leading back to the top - and a crash when it gets there.",
        ["Every 4 bars"] = "A fill at the end of every fourth bar, and of the last.",
        ["Every 2 bars"] = "A fill at the end of every second bar.",
      } },
    { id = "cymbal", label = "Cymbal", step = "Drums", values = { "Hats", "Ride" }, any = true,
      default = "Any", weights = { 3, 1 }, when = function(st) return st.kind == "Drums" end,
      hints = {
        Hats = "Time kept on the hi-hats (42), opening (46) now and then.",
        Ride = "Time kept on the ride (51), the bell (53) on the beat, the hi-hat pedal (44) on the backbeat.",
      } },

    -- Added in 1.5, last for the same reason. Off, Close and Off are the
    -- 1.4 sound, and draw nothing from the dice.
    { id = "flavours", label = "Flavours", step = "Chords", values = { "Off", "Rare", "Common" }, default = "Rare",
      when = function(st)
        return hasChords(st) and (st.colour == "Mixed" or st.colour == "Any")
           and (st.scale == "Any" or #T.SCALES[st.scale].iv == 7)
      end,
      hints = {
        Off = "Mixed is sevenths and added ninths only.",
        Rare = "With Mixed, now and then a chord takes another colour: a sus4 or sus2, an added 2nd, a 6th, a 9th, or the diminished chord on its third (G7 becomes Bm7b5). Never the first chord or the cadence. Seven-note scales only.",
        Common = "The same colours, on about half the chords that can take one.",
      } },
    { id = "voicing", label = "Voicing", step = "Chords", values = T.VOICINGS, any = true, default = "Close",
      weights = { 3, 1, 1, 1, 1, 1, 1 }, when = hasChords,
      hints = {
        Close = "Every note once, inside an octave, each chord nearest the one before.",
        Open = "Spread wide: the root, the fifth, then the third an octave up and the rest above it.",
        ["Drop 2"] = "Four notes in close position with the second from the top dropped an octave - the guitarist's and arranger's favourite.",
        ["Drop 3"] = "Four notes with the third from the top dropped an octave: a wide gap at the bottom.",
        ["Drop 2 & 4"] = "Four notes with the second and the fourth from the top dropped an octave: wide, like a big band's saxes.",
        Shell = "The root, the third and the seventh - the notes that say what the chord is, and nothing else.",
        Rootless = "No root - the bass has it: the third, fifth, seventh and ninth, the jazz pianist's left hand.",
      } },
    { id = "inversions", label = "Inversions", step = "Chords", values = { "Off", "Rare", "Common" }, default = "Rare",
      when = hasChords,
      hints = {
        Off = "Every chord with its root in the bass.",
        Rare = "Now and then a chord's third, fifth or seventh in the bass, where it makes the bass move by step - C G/B Am, a passing chord, or the I6/4 before the cadence. The bass plays it.",
        Common = "The same, on more than half the chords where an inversion does its job.",
      } },

    -- Added in 1.7, last for the same reason. Free is 1.6's part-writing,
    -- note for note, and draws nothing from the dice.
    { id = "partWriting", label = "Part-writing", step = "Chords", values = { "By the book", "Free" },
      default = "By the book", when = hasChords,
      hints = {
        ["By the book"] = "As the harmony and orchestration books have it: an inverted chord does not double its bass note (G/B plays no B above the bass), a seventh falls a step into the next chord, a half close with Mixed is a plain V, the chords sit just under the tune, the bass no more than an octave and a fifth below the chords and never in among them, and no parallel fifths or octaves between the tune and the bass.",
        Free = "As Good Idea did before 1.7: every chord note in every chord, the chords under the whole tune's lowest note, the bass where it falls.",
      } },

    -- Added in 1.8, last for the same reason. Off draws nothing.
    { id = "applied", label = "Applied", step = "Key", values = { "Off", "Rare", "Common" }, default = "Rare",
      when = function(st) return st.kind ~= "Drums" and (st.scale == "Any" or #T.SCALES[st.scale].iv == 7) end,
      hints = {
        Off = "No chord borrowed from another key.",
        Rare = "Now and then the chord before a major or minor chord becomes that chord's own dominant - its V (or V7), or its leading-tone chord - borrowed from the key the next chord is home in: D7 before G in C major (V7/V), E before Am (V/vi). The most common chromatic chord there is. The window says which, and where. Seven-note scales only.",
        Common = "The same, on more of the chords that can take one, and in most ideas.",
      } },
  }
  M.BY_ID = {}
  for _, s in ipairs(M.SETTINGS) do M.BY_ID[s.id] = s end
end

function M.valueName(s, v)
  if v == "Any" then return "Any" end
  return s.name and s.name(v) or tostring(v)
end

function M.shows(s, st) return not s.when or s.when(st) end

------------------------------------------------------------------------------
-- State
------------------------------------------------------------------------------

function M.newState()
  local st = {}
  for _, s in ipairs(M.SETTINGS) do st[s.id] = s.default end
  st.seed = 1
  st.autoplay = 0
  st.swing = 0
  return st
end

-- Puts every field back inside what exists. Saved settings come from
-- anywhere, so nothing in them is trusted.
function M.clampState(st)
  for _, s in ipairs(M.SETTINGS) do
    local v = st[s.id]
    local good = (v == "Any" and s.any) or false
    for _, x in ipairs(s.values) do if x == v then good = true end end
    if not good then st[s.id] = s.default end
  end
  local seed = tonumber(st.seed)
  if seed and seed >= 1 and seed <= M.MAX_SEED then st.seed = math.floor(seed) else st.seed = 1 end
  st.autoplay = (tonumber(st.autoplay) == 1) and 1 or 0
  local swing = tonumber(st.swing)
  st.swing = (swing and swing >= 0 and swing <= 100) and math.floor(swing) or 0
  return st
end

------------------------------------------------------------------------------
-- 1. Resolve
------------------------------------------------------------------------------

-- Every setting takes one draw from the "pick" stream whether it is on Any
-- or not, so fixing one setting never changes what another rolls. That is
-- what makes "Keep" (turning every Any into what this idea rolled) give
-- exactly the same idea back.
function M.resolve(st, seed)
  local rnd = M.stream(seed, "pick")
  local r = { rolled = {} }
  for _, s in ipairs(M.SETTINGS) do
    local x = rnd()
    local v = st[s.id]
    if v == "Any" and s.any then
      v = pickAt(x, s.anyValues or s.values, s.anyWeights or (not s.anyValues and s.weights) or nil)
      r.rolled[s.id] = true
    end
    r[s.id] = v
  end
  if r.kind == "Motif" then r.bars = r.motifBars
  elseif r.kind == "Phrase" then r.bars = r.phraseBars
  elseif r.kind == "Drums" then r.bars = r.drumBars
  else r.bars = r.measureBars end
  if r.kind == "Motif" then r.content = "Melody"
  elseif r.kind == "Measure" then r.content = "All"
  elseif r.kind == "Drums" then r.content = "Melody"; r.drumsOnly = true end
  r.melody = r.content ~= "Chords" and not r.drumsOnly
  r.chords = r.content ~= "Melody"
  return r
end

-- The bars setting the kind uses.
function M.barsSetting(kind)
  return (kind == "Motif" and "motifBars") or (kind == "Phrase" and "phraseBars")
      or (kind == "Drums" and "drumBars") or "measureBars"
end

------------------------------------------------------------------------------
-- 2. The plan
--
-- A unit is written letter:bars[:cadence]. A letter's first appearance is new
-- material; `a` again repeats it, `a'` answers it (the same start, a new
-- ending), `a~` sequences it (the whole unit moved up or down, chords and
-- all). `f` fragments the basic idea - its first half, falling - and `c` is a
-- new cadential unit. The cadence `X` is the idea's ending, drawn for the
-- kind. These are the shapes Open Music Theory gives for the sentence and the
-- period, and the A A B A of a song, at the size of the idea.
------------------------------------------------------------------------------

M.PLANS = {
  Motif = {
    [1] = { "a:0.5 a~:0.5:X", "a:0.5:open a':0.5:X", "a:1:X" },
    [2] = { "a:1:open a':1:X", "a:1 a~:1:X", "a:1:open b:1:X" },
    [3] = { "a:1 a~:1 c:1:X", "a:1:open b:1 a':1:X" },
    [4] = { "a:1 a~:1 f:1 c:1:X", "a:2:open a':2:X", "a:1:open b:1 a:1:open b':1:X" },
  },
  Phrase = {
    [1] = { "a:1:X" },
    [2] = { "a:2:X", "a:1:HC a':1:X" },
    [3] = { "a:2 c:1:X", "a:1 a~:1 c:1:X" },
    [4] = { "a:4:X", "a:2:HC a':2:X", "a:1 a~:1 f:1 c:1:X" },
  },
}

M.FORMS = {
  Period   = { [8] = "a:4:HC a':4:PAC",
               [12] = "a:4:HC a':4:IAC b:4:PAC",
               [16] = "a:4:IAC b:4:HC a:4:IAC c:4:PAC" },
  Sentence = { [8] = "a:2 a~:2 f:2 c:2:PAC",
               [12] = "a:2 a~:2 f:4 c:4:PAC",
               [16] = "a:4 a~:4 f:4 c:4:PAC" },
  Song     = { [8] = "a:2:IAC a:2:PAC b:2:HC a:2:PAC",
               [12] = "a:4:IAC a:4:PAC b:4:PAC",
               [16] = "a:4:IAC a:4:PAC b:4:HC a:4:PAC" },
  Loop     = { [8] = "a:4:open a':4:open",
               [12] = "a:4:open a':4:open a:4:open",
               [16] = "a:4:open a':4:open a:4:open a'':4:open" },
  -- Added in 1.8 (Caplin's hybrid themes and small ternary, and a sentence
  -- stretched by a deceptive cadence; Open Music Theory, "Hybrid themes",
  -- "The Small Ternary", "Internal Expansions").
  ["Hybrid 1"] = { [8] = "a:2 b:2:HC f:1 f:1 c:2:PAC",
                   [12] = "a:3 b:3:HC f:2 f:1 c:3:PAC",
                   [16] = "a:4 b:4:HC f:4 c:4:PAC" },
  ["Hybrid 2"] = { [8] = "a:2 b:2:HC c:4:PAC",
                   [12] = "a:3 b:3:HC c:6:PAC",
                   [16] = "a:4 b:4:HC c:8:PAC" },
  ["Hybrid 3"] = { [8] = "a:2 b:2 f:1 f:1 c:2:PAC",
                   [12] = "a:3 b:3 f:2 f:1 c:3:PAC",
                   [16] = "a:4 b:4 f:4 c:4:PAC" },
  ["Hybrid 4"] = { [8] = "a:2 b:2 a:2 b':2:PAC",
                   [12] = "a:3 b:3 a:3 b':3:PAC",
                   [16] = "a:4 b:4 a:4 b':4:PAC" },
  Ternary  = { [8] = "a:2:HC a':2:PAC b:2:HC a':2:PAC",
               [12] = "a:4:PAC b:4:HC a:4:PAC",
               [16] = "a:4:HC a':4:PAC b:4:HC a':4:PAC" },
  Extended = { [8] = "a:2 a~:2 c:2:DC c:2:PAC",
               [12] = "a:2 a~:2 f:2 c:2:DC f:2 c:2:PAC",
               [16] = "a:4 a~:4 f:2 c:2:DC f:2 c:2:PAC" },
}

-- How an idea that is not a Measure ends. A motif is a hook, so mostly it
-- leaves the door open and loops; a phrase mostly closes.
local ENDINGS = {
  Motif  = { { "open", "PAC", "IAC" }, { 3, 2, 1 } },
  Phrase = { { "PAC", "HC", "IAC", "open" }, { 3, 1.5, 1, 1.5 } },
}

function M.parsePlan(text, meter, finalCad)
  local units, firstOf = {}, {}
  local cum = 0
  for tok in text:gmatch("%S+") do
    local name, bars, cad = tok:match("^([^:]+):([%d%.]+):?(%a*)$")
    local letter, mark = name:match("^(%a)(.*)$")
    bars = tonumber(bars)
    local start = snap(meter, cum * meter.bar)
    cum = cum + bars
    local stop = snap(meter, cum * meter.bar)
    local u = { letter = letter, mark = mark, bars = bars, start = start, len = stop - start,
                cad = (cad == "" and "none") or (cad == "X" and finalCad) or cad }
    if letter == "f" then u.kind, u.of = "frag", 1
    elseif letter == "c" then u.kind = "cad"
    elseif not firstOf[letter] then u.kind = "new"; firstOf[letter] = #units + 1
    elseif mark == "~" then u.kind, u.of = "seq", firstOf[letter]
    elseif mark:find("'") then u.kind, u.of = "answer", firstOf[letter]
    else u.kind, u.of = "repeat", firstOf[letter] end
    -- A repeat that ends differently from its source is an answer.
    if u.kind == "repeat" and units[u.of].cad ~= u.cad then u.kind = "answer" end
    if u.len > 0 then units[#units + 1] = u end
  end
  return units, snap(meter, cum * meter.bar)
end

function M.plan(r, meter, rnd)
  local text, finalCad
  if r.kind == "Measure" then
    text = M.FORMS[r.form][r.bars]
    finalCad = "PAC"
  else
    local e = ENDINGS[r.kind]
    finalCad = weighted(rnd, e[1], e[2])
    text = pickOne(rnd, M.PLANS[r.kind][r.bars])
  end
  local units, total = M.parsePlan(text, meter, finalCad)
  -- A sequence moves by a step up, a step down, or to the dominant (up a
  -- fifth) - the second statement of a sentence's basic idea.
  for _, u in ipairs(units) do
    if u.kind == "seq" then u.shift = weighted(rnd, { 1, -1, 4 }, { 2, 1.5, 2 }) end
  end
  local shape = {}
  for _, u in ipairs(units) do shape[#shape + 1] = u.letter .. u.mark end
  return { units = units, total = total, text = text, ending = units[#units].cad,
           shape = table.concat(shape, " ") }
end

------------------------------------------------------------------------------
-- 3. Harmony
------------------------------------------------------------------------------

local RATE = { Slow = 0.5, ["One a bar"] = 1, ["1.5 a bar"] = 1.5, ["Two a bar"] = 2, ["4 a bar"] = 4 }

-- Where an answer stops copying its source: half way, on a beat, and
-- always before the end (a unit one beat long copies nothing).
function M.cutFor(meter, src, u)
  local half = math.min(src.len, u.len) / 2
  local cut = math.floor(half / meter.beat + 0.5) * meter.beat
  return math.max(0, math.min(cut, u.len - meter.beat))
end

-- How many chords a stretch of `len` steps gets.
local function countFor(meter, len, r, kind, cad, first)
  local bars = len / meter.bar
  local rate = RATE[r.chordPace] or 1
  -- A continuation speeds the harmony up (Open Music Theory, the sentence).
  -- (Never slower than the pace chosen: at four a bar it is already quick.)
  if kind == "frag" then rate = math.max(rate, math.min(2, rate * 2)) end
  local n = math.max(1, round(bars * rate))
  local beats = len // meter.beat
  -- An ending needs two chords: one to lead to it, and the one it lands on.
  -- A half close is one chord, the dominant.
  local need = (cad == "HC" and 1) or ((cad ~= "none" or kind == "cad") and 2) or 1
  if beats >= 2 then n = math.max(n, need) end
  -- The opening unit starts on the tonic, so it needs a chord before its
  -- ending too - as long as the chords still fall evenly on the beats, line
  -- up with the bars, and come no faster than two a bar.
  if first and cad ~= "none" then
    local tail = (cad == "PAC" or cad == "IAC" or cad == "DC") and 2 or 1
    if n <= tail then
      for m = tail + 1, math.max(tail + 1, round(2 * bars)) do
        local per = beats // m
        if beats % m == 0 and (per % meter.beats == 0 or meter.beats % per == 0) then n = m; break end
      end
    end
  end
  return math.max(1, math.min(n, beats))
end

-- `n` stretches of a span, as even as the beats allow.
local function evenSlots(meter, from, len, n)
  local out = {}
  for i = 1, n do
    local s = from + snap(meter, len * (i - 1) / n)
    local e = (i == n) and (from + len) or (from + snap(meter, len * i / n))
    if e > s then out[#out + 1] = { s = s, e = e } end
  end
  return out
end

local function withDegrees(slots, degrees)
  for i, sl in ipairs(slots) do sl.degree = degrees[i] or degrees[#degrees] end
  return slots
end

-- A unit's chords, as { s, e, degree } from the unit's start.
--
--   - a repeat, or an answer or sequence to the same ending, plays its
--     source's chords (a sequence moved by its step);
--   - an answer (or a repeat or sequence to a different ending) plays its
--     source's chords for the first half, by time, then walks to its own
--     ending - so the tune's first half fits it exactly as before;
--   - anything new walks from the chord after the last one.
local function unitChords(u, units, key, r, meter, rnd, prevLast)
  local src = (u.kind == "repeat" or u.kind == "answer" or u.kind == "seq") and units[u.of] or nil
  local shift = (u.kind == "seq") and u.shift or 0
  -- (A copied chord remembers the one it was copied from, `orig`, so a
  -- flavour or an inversion comes round with it.)
  local function moved(sl, e)
    return { s = sl.s, e = math.min(e or sl.e, sl.e), degree = T.normDegree(key, sl.degree + shift),
             orig = sl.orig or sl }
  end
  if src and src.len == u.len and src.cad == u.cad and (u.kind ~= "seq" or u.cad == "none") then
    local out = {}
    for _, sl in ipairs(src.rel) do out[#out + 1] = moved(sl) end
    return out
  end
  local need = (u.cad == "PAC" or u.cad == "IAC" or u.cad == "DC") and 2 or ((u.cad ~= "none") and 1 or 0)
  local cut = src and M.cutFor(meter, src, u)
  -- (When the second half is too short for the ending's chords - half a bar
  -- of 4/4 has two beats, a full close needs a chord on each, and so on -
  -- the answer's chords are all new, and its tune is fitted to them.)
  if src and cut > 0 and (u.len - cut) // meter.beat >= need then
    local out = {}
    for _, sl in ipairs(src.rel) do
      if sl.s < cut then out[#out + 1] = moved(sl, cut) end
    end
    local rest = u.len - cut
    local n = countFor(meter, rest, r, "rest", u.cad, false)
    local degs = T.progression(key, n, { start = T.nextDegree(key, out[#out].degree, rnd),
                                          cadence = u.cad, loopTo = 0 }, rnd)
    for _, sl in ipairs(withDegrees(evenSlots(meter, cut, rest, n), degs)) do out[#out + 1] = sl end
    return out
  end
  local n = countFor(meter, u.len, r, u.kind, u.cad, u == units[1])
  local start = prevLast and T.nextDegree(key, prevLast, rnd) or 0
  local degs = T.progression(key, n, { start = start, cadence = u.cad, loopTo = 0 }, rnd)
  return withDegrees(evenSlots(meter, 0, u.len, n), degs)
end

-- Each unit's chords, and one timeline of { s, e, degree, chord } for the
-- whole idea, in steps. The same chord twice running (where one unit ends on
-- the chord the next begins with) is one chord, held.
function M.harmony(plan, key, r, meter, rnd, colour)
  local timeline = {}
  local prevLast
  for _, u in ipairs(plan.units) do
    u.rel = unitChords(u, plan.units, key, r, meter, rnd, prevLast)
    u.degrees, u.slots = {}, {}
    for _, rs in ipairs(u.rel) do
      u.degrees[#u.degrees + 1] = rs.degree
      local last = timeline[#timeline]
      local sl
      if last and last.degree == rs.degree and last.e == u.start + rs.s then
        last.e = u.start + rs.e
        sl = last
      else
        sl = { s = u.start + rs.s, e = u.start + rs.e, beat = u.start + rs.s, degree = rs.degree, key = key,
               chord = T.chord(key, rs.degree, colour), origin = rs.orig or rs }
        timeline[#timeline + 1] = sl
      end
      if u.slots[#u.slots] ~= sl then u.slots[#u.slots + 1] = sl end
    end
    prevLast = u.degrees[#u.degrees]
  end
  return timeline
end

function M.chordAt(timeline, step)
  for i = #timeline, 1, -1 do
    if timeline[i].s <= step then return timeline[i] end
  end
  return timeline[1]
end

-- The scale sounding at a step: the key's own, or under a borrowed chord the
-- scale it was borrowed from.
function M.keyAt(ctx, step)
  return M.chordAt(ctx.timeline, step).key or ctx.key
end

------------------------------------------------------------------------------
-- Borrowed chords (docs/decisions/0011-borrowed-chords-rarely-and-named.md)
--
-- Modal mixture: a chord on the same degree, taken from another scale on
-- the same key note - Fm (iv) or Ab (bVI) in C major, from C minor; F (IV)
-- in C minor, from C Dorian. The degree, and so the walk, is unchanged; only
-- the chord's notes are. Under it everything - the tune, the bass's steps -
-- reads that scale, the way a player bends to a borrowed chord.
--
-- Rare by design: about one idea in four, one chord, never the first or the
-- last two (the opening tonic and the cadence stay the key's own), never a
-- diminished or augmented chord. Seven-note scales only, borrowing from
-- seven-note scales, so the scale positions line up note for note.
------------------------------------------------------------------------------

M.BORROW_CHANCE = { Rare = 0.25, Common = 0.65 }
-- With Common, a second borrowed chord in an idea of eight chords or more,
-- this often, never next to the first.
M.BORROW_AGAIN = 0.5

-- Where to borrow from, by what the home key is: the parallel minor or major
-- most of all (the commonest mixture), the modes a step from it next.
local BORROW_FROM = {
  major = { { 2, 3 }, { 8, 1.5 }, { 5, 1 }, { 3, 0.7 }, { 6, 0.4 }, { 7, 0.4 } },
  minor = { { 1, 3 }, { 5, 2 }, { 3, 1.5 }, { 6, 0.8 }, { 8, 0.6 }, { 7, 0.3 } },
}

local function sameNotes(a, b)
  if #a.pcs ~= #b.pcs then return false end
  for _, pc in ipairs(a.pcs) do if not b.has[pc] then return false end end
  return true
end

function M.borrow(timeline, key, r, rnd, colour)
  local chance = M.BORROW_CHANCE[r.borrowed]
  if not chance or T.scaleLen(key) ~= 7 or #timeline < 4 then return {} end
  if rnd() >= chance then return {} end
  local tonic = T.degreeQuality(key, 0)
  local from = BORROW_FROM[(tonic == "major") and "major" or "minor"]
  local inKey = {}
  for d = 0, 6 do inKey[T.pc(key, d)] = true end
  local cands, weights = {}, {}
  for i = 2, #timeline - 2 do
    local sl = timeline[i]
    for _, f in ipairs(from) do
      if T.SCALES[f[1]].iv ~= T.SCALES[key.scale].iv then
        local other = T.key(key.root, f[1])
        local ch = T.chord(other, sl.degree, colour)
        local q = ch.quality
        local outside = false
        for _, pc in ipairs(ch.pcs) do if not inKey[pc] then outside = true end end
        if (q == "major" or q == "minor") and outside and not sameNotes(ch, sl.chord) then
          cands[#cands + 1] = { slot = sl, key = other, chord = ch }
          weights[#weights + 1] = f[2]
        end
      end
    end
  end
  if #cands == 0 then return {} end
  local function take(c)
    c.slot.chord, c.slot.key = c.chord, c.key
    -- Named against the home key: Ab in C major is bVI, Fm is iv.
    local shift = (c.chord.rootPc - T.pc(key, c.slot.degree)) % 12
    local numeral = ((shift == 11) and "b" or (shift == 1) and "#" or "") ..
                    T.degreeNumeral(c.key, c.slot.degree)
    c.slot.borrowed = { name = c.chord.name, numeral = numeral, from = M.keyName(c.key) }
  end
  local c = weighted(rnd, cands, weights)
  take(c)
  local out = { c.slot }
  if r.borrowed == "Common" and #timeline >= 8 and rnd() < M.BORROW_AGAIN then
    local at = {}
    for i, sl in ipairs(timeline) do at[sl] = i end
    local more, mw = {}, {}
    for i, d in ipairs(cands) do
      if math.abs(at[d.slot] - at[c.slot]) > 1 then more[#more + 1] = d; mw[#mw + 1] = weights[i] end
    end
    if #more > 0 then
      local d = weighted(rnd, more, mw)
      take(d)
      out[2] = d.slot
      if at[d.slot] < at[c.slot] then out = { d.slot, c.slot } end
    end
  end
  return out
end

------------------------------------------------------------------------------
-- Push: chords that arrive an eighth early
--
-- A chord change on a beat moves back an eighth, onto the "and" before it
-- (some, or most, by the Push setting). The chord before is cut short to
-- make room, so the chords still follow each other with no gap. The tune's
-- note on that beat comes early with it (`M.melody`), and so does the bass.
-- Only where the beat is a quarter or longer, and only
-- where the chord before is long enough to give up an eighth.
------------------------------------------------------------------------------

local PUSH = { None = 0, Some = 0.3, Lots = 0.65 }
M.PULL_CHANCE = { None = 0, Some = 0.3, Lots = 0.65 }

function M.push(timeline, meter, r, rnd)
  local p = PUSH[r.push] or 0
  if p == 0 or meter.beat < 4 then return end
  for i = 2, #timeline do
    local sl, prev = timeline[i], timeline[i - 1]
    if sl.s % meter.beat == 0 and prev.e - prev.s >= meter.beat + 2 and rnd() < p then
      sl.s, prev.e = sl.s - 2, prev.e - 2
      sl.pushed = true
    end
  end
end

------------------------------------------------------------------------------
-- Pull: chords that arrive an eighth late
-- (docs/decisions/0014-pull-the-chords-lie-back.md)
--
-- The opposite of a push, and only for the chords part: the comping lies
-- back behind the beat while the tune, the bass and the drums stay on it.
-- So it is done to a copy of the timeline that only the chords part plays
-- from (`idea.chordTimeline`); the harmony everything else hears is the one
-- on the beat. The chord before is held an eighth longer to meet it. A
-- pushed chord is not also pulled, and a chord must be long enough to give
-- up an eighth at its start.
------------------------------------------------------------------------------

function M.pull(timeline, meter, r, rnd)
  local out = {}
  for i, sl in ipairs(timeline) do
    local c = {}
    for k, v in pairs(sl) do c[k] = v end
    out[i] = c
  end
  local p = M.PULL_CHANCE[r.pull] or 0
  if p == 0 or meter.beat < 4 then return out end
  for i = 2, #out do
    local sl, prev = out[i], out[i - 1]
    if not sl.pushed and sl.s % meter.beat == 0 and sl.e - sl.s >= meter.beat + 2 and rnd() < p then
      sl.s, prev.e = sl.s + 2, prev.e + 2
      sl.pulled = true
    end
  end
  return out
end

------------------------------------------------------------------------------
-- Flavours and inversions (docs/decisions/0018-flavours-voicings-and-inversions.md)
--
-- Both touch single chords, never the first chord or a cadence's chords
-- (the last chord of every unit that closes, and the chord leading to a full
-- or imperfect close): the idea opens on the tonic and its cadences stay
-- the textbook's. Each draws from a stream of its own, and nothing when off.
------------------------------------------------------------------------------

-- The slots that stay as they are: the first, the last, and each cadence's.
local function cadenceSlots(plan, timeline)
  local keep = { [timeline[1]] = true, [timeline[#timeline]] = true }
  for _, u in ipairs(plan.units) do
    if u.cad ~= "none" and u.slots and #u.slots > 0 then
      keep[u.slots[#u.slots]] = true
      if (u.cad == "PAC" or u.cad == "IAC" or u.cad == "DC") and #u.slots > 1 then keep[u.slots[#u.slots - 1]] = true end
    end
  end
  return keep
end

------------------------------------------------------------------------------
-- Applied chords (1.8; docs/decisions/0020-applied-chords-cadences-and-forms.md)
--
-- The chord before a major or minor chord becomes that chord's own dominant
-- (V, or V7 with Sevenths or Mixed) or its leading-tone chord (viio, viio7):
-- "a chromatically altered chord that also functions as a dominant chord in
-- the key of the chord that follows it" (Open Music Theory, "Applied
-- chords"; Hutchinson, chs. 17-18). It is made from the home scale with the
-- notes it needs bent a semitone - V/V in C is the C scale with F#, V/vi the
-- C scale with G# - so the tune keeps its positions and, while the chord
-- sounds, bends with it (`I.keyAt`). Never the tonic's (that is just V),
-- never the first chord or a cadence's, never a borrowed or flavoured one,
-- never two running; a copied chord does as its original did, where the
-- chord after it is the same.
------------------------------------------------------------------------------

M.APPLIED_CHANCE = { Rare = 0.15, Common = 0.4 }
M.APPLIED_LEADING = 0.25   -- how often it is the leading-tone chord, not V

-- The home scale with the notes of the dominant (`kind` "V") or the
-- leading-tone chord ("vii") of degree `x` bent to fit, and that chord's
-- degree; nil if it needs more than a semitone's bend, or bends nothing.
function M.appliedKey(key, x, kind)
  local n = T.scaleLen(key)
  if n ~= 7 then return nil end
  local iv = {}
  for i, v in ipairs(T.ivOf(key)) do iv[i] = v end
  local target = T.pc(key, x)
  local tonic = T.rootPc(key)
  -- Each chord note: its degree, and its distance above the target's root.
  local spec = (kind == "V") and { { x + 4, 7 }, { x + 6, 11 }, { x + 1, 2 }, { x + 3, 5 } }
                              or { { x + 6, 11 }, { x + 1, 2 }, { x + 3, 5 }, { x + 5, 8 } }
  local bent = false
  for _, sp in ipairs(spec) do
    local d = sp[1] % 7
    local want = (target + sp[2] - tonic) % 12
    if iv[d + 1] ~= want then
      local diff = (want - iv[d + 1] + 6) % 12 - 6
      if math.abs(diff) ~= 1 then return nil end
      iv[d + 1] = want
      bent = true
    end
  end
  for i = 2, n do if iv[i] <= iv[i - 1] then return nil end end
  if not bent then return nil end
  return { root = key.root, scale = key.scale, iv = iv }, spec[1][1] % 7
end

function M.applied(timeline, plan, key, r, rnd, colour)
  local chance = M.APPLIED_CHANCE[r.applied]
  if not chance or T.scaleLen(key) ~= 7 or #timeline < 3 then return {} end
  local keep = cadenceSlots(plan, timeline)
  local decided = {}
  local out = {}
  local lastDone
  -- (Only where the chord after is the same every time the passage comes
  -- round - a repeat, a Loop, an answer's first half - so it does too.)
  local nextOf, same = {}, {}
  for i, sl in ipairs(timeline) do
    local o = sl.origin or sl
    local nx = timeline[i + 1] and timeline[i + 1].degree or -1
    if nextOf[o] == nil then nextOf[o], same[o] = nx, true
    elseif nextOf[o] ~= nx then same[o] = false end
  end
  -- (The first chord and the last are never changed: nor are their copies.)
  for _, sl in ipairs({ timeline[1], timeline[#timeline] }) do decided[sl.origin or sl] = false end
  for i = 2, #timeline - 1 do
    local sl, before, after = timeline[i], timeline[i - 1], timeline[i + 1]
    local was = sl.origin and decided[sl.origin]
    local x1, x2 = rnd(), rnd()
    local x = after.degree
    local q = T.degreeQuality(key, x)
    local can = not keep[sl] and not sl.borrowed and not after.borrowed and lastDone ~= i - 1
                and same[sl.origin or sl]
                and x ~= 0 and (q == "major" or q == "minor")
    local go, kind
    if was ~= nil then
      go = was ~= false and was.target == x
      kind = go and was.kind
    else
      go = x1 < chance
      kind = (x2 < M.APPLIED_LEADING) and "vii" or "V"
    end
    local done = false
    if go and can then
      local akey, deg = M.appliedKey(key, x, kind)
      local ch = akey and T.chord(akey, deg, (colour == "Triads") and "Triads" or "Sevenths")
      -- (A chord with no bent note in it - V/IV as a plain triad is I - is
      -- not an applied chord.)
      local bent = false
      if ch then
        local home = {}
        for d = 0, 6 do home[T.pc(key, d)] = true end
        for _, pc in ipairs(ch.pcs) do if not home[pc] then bent = true end end
      end
      if bent and deg ~= before.degree then
        sl.chord, sl.key, sl.degree = ch, akey, deg
        local numeral = (kind == "V" and "V" or "viio") .. ((#ch.pcs > 3) and "7" or "") .. "/" ..
                        T.degreeNumeral(key, x)
        sl.applied = { name = ch.name, numeral = numeral, to = after.chord.name, kind = kind, target = x }
        out[#out + 1] = sl
        lastDone, done = i, true
      end
    end
    if sl.origin and was == nil then decided[sl.origin] = done and { kind = kind, target = x } or false end
  end
  return out
end

-- With Mixed, now and then a chord takes another colour (`T.flavourChord`):
-- about one chord in five that may.
M.FLAVOUR_CHANCE = { Rare = 0.2, Common = 0.5 }
local FLAVOUR_WEIGHT = { sus4 = 3, sus2 = 2, add2 = 1.5, add9 = 1.5, ["9"] = 2, ["6"] = 2, dim = 1.5 }

-- A chord copied from another (a repeat, an answer's first half, a Loop
-- going round) takes the flavour its original took, where it can, and
-- draws nothing: the music that comes round again sounds the same.
function M.flavour(timeline, plan, key, r, rnd)
  local chance = M.FLAVOUR_CHANCE[r.flavours]
  if not chance or r.colour ~= "Mixed" or T.scaleLen(key) ~= 7 then return end
  local keep = cadenceSlots(plan, timeline)
  local decided = {}
  for i, sl in ipairs(timeline) do
    local was = sl.origin and decided[sl.origin]
    local go
    if was ~= nil then go = was ~= false
    else go = not keep[sl] and not sl.borrowed and rnd() < chance end
    -- (Nor the chord an applied chord leads to: it must stay the chord it
    -- is the dominant of.)
    local target = timeline[i - 1] and timeline[i - 1].applied
    if go and not keep[sl] and not sl.borrowed and not sl.applied and not target then
      local seventh = false
      for _, pc in ipairs(sl.chord.pcs) do if T.roleOf(sl.chord, pc) == "7" then seventh = true end end
      local before, after = timeline[i - 1], timeline[i + 1]
      local cands, weights = {}, {}
      for _, f in ipairs(T.FLAVOURS) do
        local ch = T.flavourChord(sl.key or key, sl.degree, f, seventh)
        -- (Not one that sounds like the chord either side of it. An add9 has
        -- the notes and the name of Mixed's own; it changes the voicing,
        -- putting its ninth on top.)
        if ch and (ch.name ~= sl.chord.name or f == "add9") and not (before and before.chord.name == ch.name)
           and not (after and after.chord.name == ch.name) and (was == nil or was == f) then
          cands[#cands + 1] = ch
          weights[#weights + 1] = FLAVOUR_WEIGHT[f]
        end
      end
      if #cands > 0 then
        sl.chord = (was ~= nil) and cands[1] or weighted(rnd, cands, weights)
        sl.flavour = sl.chord.flavour
      end
    end
    if sl.origin and was == nil then decided[sl.origin] = sl.flavour or false end
  end
end

-- The note in the bass under a chord: its root, or the note it is inverted on.
local function bassPcOf(sl) return sl.bassPc or sl.chord.rootPc end
M.bassPcOf = bassPcOf

local function byStep(a, b)
  local d = (a - b) % 12
  return d == 1 or d == 2 or d == 10 or d == 11
end

-- Inversions where they do a job (Open Music Theory, "Harmonic syntax -
-- prolongation"): the bass moving by step.
--
--   first   the third in the bass, where the bass steps into it or out of
--           it - C G/B Am, F C/E Dm - likeliest when it does both (a
--           passing chord)
--   second  the fifth in the bass only where a 6/4 belongs: over a held
--           bass (I IV6/4 I), passing between two steps (I V6/4 I6), or
--           the tonic's fifth before the dominant at a cadence (I6/4 V)
--   third   the seventh in the bass, only where it can fall a step into
--           the next chord, which then takes that note in its bass
--           (V4/2 I6)
--
-- About one chord in four that could be inverted is (more than half with
-- Common); never two running (but for the chord a third inversion resolves
-- to), never a flavoured one.
--
-- Checked against the textbooks' rules for six-fours (Open Music Theory;
-- Puget Sound's Music Theory for the 21st-Century Classroom): a cadential
-- 6/4 comes at a cadence, right before its V, on a stronger beat; a passing
-- 6/4 walks the bass through three notes one way and a pedal 6/4 holds it,
-- both on a weaker beat, between two chords of the same function. And a
-- diminished triad is most at home in first inversion (vii6): in root
-- position its fifth is a tritone over the bass. So a diminished triad is
-- inverted three times in four where its bass steps, and never to a 6/4.
M.INVERT_CHANCE = { Rare = 0.25, Common = 0.6 }
M.DIM_FIRST = 0.75

-- How strong a beat is, with the odd bars of a pair stronger than the even
-- (so a chord a bar still has strong and weak places).
local function weightAt(meter, step)
  local w = M.strength(meter, step)
  if step % meter.bar == 0 and (step // meter.bar) % 2 == 0 then w = w + 0.5 end
  return w
end
M.weightAt = weightAt
local function beatAt(sl) return sl.beat or sl.s end

-- As with flavours, a chord copied from another is inverted as its original
-- was, where the bass around it still allows it, and draws nothing.
function M.invert(timeline, plan, key, r, rnd, meter)
  local chance = M.INVERT_CHANCE[r.inversions]
  if not chance or #timeline < 3 then return end
  local keep = cadenceSlots(plan, timeline)
  local decided = {}
  local i = 2
  while i <= #timeline - 1 do
    local sl, before, after = timeline[i], timeline[i - 1], timeline[i + 1]
    local step = 1
    local was = sl.origin and decided[sl.origin]
    local dimTriad = sl.chord.quality == "diminished" and #sl.chord.pcs == 3 and not sl.flavour
    local go
    if was ~= nil then go = was ~= false
    else
      local x = rnd()
      go = x < chance or (dimTriad and x < M.DIM_FIRST)
    end
    if sl.inversion then go = false end
    if go and not keep[sl] and not sl.flavour and not sl.applied then
      local ch = sl.chord
      local pb, nb = bassPcOf(before), after.chord.rootPc
      local k = sl.key or key
      local sameFunction = T.functionOf(k, before.degree) == T.functionOf(k, after.degree)
      local weaker = weightAt(meter, beatAt(sl)) < weightAt(meter, beatAt(before))
      local opts, weights = {}, {}
      for idx, pc in ipairs(ch.pcs) do
        local role = T.roleOf(ch, pc)
        if role == "3" and (byStep(pb, pc) or byStep(pc, nb)) then
          opts[#opts + 1] = { idx = idx, inv = 1 }
          weights[#weights + 1] = (byStep(pb, pc) and byStep(pc, nb)) and 3 or 1
        elseif role == "5" and not dimTriad then
          local up = (pc - pb) % 12
          local on = (nb - pc) % 12
          local oneWay = (up >= 1 and up <= 2 and on >= 1 and on <= 2) or (up >= 10 and on >= 10)
          local pedal = pc == pb and pc == nb and sameFunction and weaker
          local passing = oneWay and sameFunction and weaker
          local cadential = sl.degree == 0 and keep[after] and T.rootAbove(k, after.degree) == 7
                            and weightAt(meter, beatAt(sl)) > weightAt(meter, beatAt(after))
          if pedal or passing or cadential then
            opts[#opts + 1] = { idx = idx, inv = 2 }
            weights[#weights + 1] = 1
          end
        elseif role == "7" and not keep[after] and not after.flavour then
          -- (Onto the next chord's root or third - V4/2 to I6 - never its
          -- seventh, which would want resolving in turn.)
          for _, t in ipairs(after.chord.pcs) do
            local d = (pc - t) % 12
            local role = T.roleOf(after.chord, t)
            if (d == 1 or d == 2) and (role == "R" or role == "3") then
              opts[#opts + 1] = { idx = idx, inv = 3, to = t }
              weights[#weights + 1] = 1
              break
            end
          end
        end
      end
      if was ~= nil then
        local same = {}
        for _, o in ipairs(opts) do if o.inv == was then same[1] = o; break end end
        opts, weights = same, { 1 }
      end
      if #opts > 0 then
        local o = (was ~= nil) and opts[1] or weighted(rnd, opts, weights)
        sl.bassPc, sl.bassPos, sl.inversion = ch.pcs[o.idx], ch.pos[o.idx], o.inv
        if o.to then
          for idx, t in ipairs(after.chord.pcs) do
            if t == o.to and t ~= after.chord.rootPc then
              after.bassPc, after.bassPos = t, after.chord.pos[idx]
              after.inversion = ({ ["3"] = 1, ["5"] = 2, ["7"] = 3 })[T.roleOf(after.chord, t)]
            end
          end
        end
        step = 2
      end
    end
    if sl.origin and was == nil then decided[sl.origin] = sl.inversion or false end
    i = i + step
  end
end

------------------------------------------------------------------------------
-- 4. Rhythm
--
-- Two kinds of maths, one for each groove:
--
--   - Straight takes the k strongest steps of the bar (the metric hierarchy:
--     the downbeat, the half bar, the beats, then the half beats).
--   - Syncopated spreads k notes as evenly as they will go over the bar (a
--     Euclidean rhythm - Toussaint showed most of the world's rhythms are
--     these: 3 in 8 is the tresillo, 5 in 8 the cinquillo) and turns it so
--     the notes fall off the beat, keeping the first on the downbeat.
--
-- Pace decides the grid (eighths or sixteenths) and how full it is.
------------------------------------------------------------------------------

-- k onsets spread over n steps as evenly as they go (Bresenham's line; the
-- same patterns as Bjorklund's algorithm, up to rotation). Starts on 0.
function M.euclid(k, n)
  local out = {}
  if n <= 0 then return out end
  k = math.max(0, math.min(n, k))
  for i = 0, n - 1 do
    if (i * k) % n < k then out[#out + 1] = i end
  end
  return out
end

local function meanStrength(meter, base, unit, slots)
  local s = 0
  for _, o in ipairs(slots) do s = s + M.strength(meter, base + o * unit) end
  return s / math.max(1, #slots)
end

-- The k strongest of `slots` grid points, ties broken by the dice.
local function strongest(meter, base, unit, slots, k, rnd)
  local order = {}
  for i = 0, slots - 1 do order[#order + 1] = { i = i, w = M.strength(meter, base + i * unit) + rnd() * 0.5 } end
  table.sort(order, function(a, b) return a.w > b.w end)
  local out = {}
  for j = 1, math.min(k, #order) do out[j] = order[j].i end
  table.sort(out)
  if out[1] ~= 0 then
    -- The downbeat always speaks.
    out[#out] = nil
    table.insert(out, 1, 0)
    table.sort(out)
  end
  return out
end

-- A Euclidean rhythm turned to start on one of its own notes, the turn
-- chosen to sit off the beat.
local function syncopated(meter, base, unit, slots, k, rnd)
  local pat = M.euclid(k, slots)
  local turns = {}
  for _, o in ipairs(pat) do
    local t = {}
    for _, x in ipairs(pat) do t[#t + 1] = (x - o) % slots end
    table.sort(t)
    turns[#turns + 1] = { t = t, s = meanStrength(meter, base, unit, t) }
  end
  -- Ties are left to the sort as 1.0 left them: the list is never longer
  -- than a bar's sixteen steps, and Lua only varies its sort past a hundred
  -- items, so the same turns always come out in the same order.
  table.sort(turns, function(a, b) return a.s < b.s end)
  -- The most off-beat turn, or the one after it.
  return turns[(#turns > 1 and coin(rnd, 0.35)) and 2 or 1].t
end

M.PACE = {
  Calm    = { unit = 2, lo = 0.2,  hi = 0.4,  halves = false },
  Flowing = { unit = 2, lo = 0.45, hi = 0.75, halves = true },
  Busy    = { unit = 1, lo = 0.4,  hi = 0.65, halves = true },
}

------------------------------------------------------------------------------
-- Figures: dotted and triplet rhythms
--
-- Laid over a rhythm after it is made, a beat (or a pair of beats) at a
-- time, by chance:
--
--   - two eighths in a beat become a dotted eighth and a sixteenth;
--     two quarters in two beats, a dotted quarter and an eighth;
--   - a beat with two or more notes becomes an eighth-note triplet; two
--     quarters in two beats, a quarter-note triplet;
--   - in the tune, a quarter note on the beat (with a note on the beat
--     after) becomes a dotted eighth and a sixteenth, or an eighth-note
--     triplet; a half note, a dotted quarter and an eighth, or a
--     quarter-note triplet. A tune at an easy pace is mostly quarters and
--     halves, which the shapes above never touch, so without this the
--     chords took the figures and the tune hardly did (since 1.4).
--
-- Triplet notes fall between the sixteenths, so their steps are fractions
-- (a third of a beat is 4/3 of a step). Only in metres whose beat is a
-- quarter note: 6/8 and 12/8 are already in threes, and 7/8 has no beats to
-- divide. With Plain nothing is drawn, so a 1.0 idea is unchanged.
------------------------------------------------------------------------------

local FIGURES = {
  Dotted   = { dot = 0.5,  tri = 0,    qdot = 0.45, qtri = 0 },
  Triplets = { dot = 0,    tri = 0.45, qdot = 0,    qtri = 0.4 },
  Mixed    = { dot = 0.25, tri = 0.2,  qdot = 0.22, qtri = 0.18 },
}

-- `onsets` are steps from the start of a cell `len` long that begins
-- `base` steps into the bar. `tune`: a melody's rhythm, whose quarter
-- notes take figures too.
function M.figure(meter, base, len, onsets, figures, rnd, tune)
  local F = FIGURES[figures]
  if not F or meter.beat ~= 4 then return onsets end
  local function within(a, b)
    local o = {}
    for _, x in ipairs(onsets) do if x >= a and x < b then o[#o + 1] = x end end
    return o
  end
  local function has(x)
    for _, y in ipairs(onsets) do if y == x then return true end end
    return false
  end
  local b = (4 - base % 4) % 4
  local out = within(0, b)
  local function add(...) for _, x in ipairs({ ... }) do out[#out + 1] = x end end
  while b < len do
    local step = 4
    local pair = (b + 8 <= len) and within(b, b + 8) or {}
    if #pair == 2 and pair[1] == b and pair[2] == b + 4 then
      local x = rnd()
      if x < F.tri / 2 then add(b, b + 8 / 3, b + 16 / 3); step = 8
      elseif x < F.tri / 2 + F.dot then add(b, b + 6); step = 8 end
    elseif tune and #pair == 1 and pair[1] == b and b + 8 < len and has(b + 8) then
      -- A half note in the tune.
      local x = rnd()
      if x < F.qtri then add(b, b + 8 / 3, b + 16 / 3)
      elseif x < F.qtri + F.qdot then add(b, b + 6)
      else add(b) end
      step = 8
    end
    if step == 4 then
      local beat = within(b, math.min(len, b + 4))
      if b + 4 <= len and #beat >= 2 and beat[1] == b then
        local x = rnd()
        if x < F.tri then add(b, b + 4 / 3, b + 8 / 3)
        elseif #beat == 2 and beat[2] == b + 2 and x < F.tri + F.dot then add(b, b + 3)
        else add(table.unpack(beat)) end
      elseif tune and b + 4 < len and #beat == 1 and beat[1] == b and has(b + 4) then
        local x = rnd()
        if x < F.qtri then add(b, b + 4 / 3, b + 8 / 3)
        elseif x < F.qtri + F.qdot then add(b, b + 3)
        else add(b) end
      else
        add(table.unpack(beat))
      end
    end
    b = b + step
  end
  table.sort(out)
  return out
end

-- The onsets of a cell `len` steps long starting at `base` in the bar, in
-- steps from the start of the cell.
function M.cell(meter, base, len, pace, groove, rnd, figures)
  local P = M.PACE[pace] or M.PACE.Flowing
  local pieces = { { 0, len } }
  -- Busy and straight rhythms are made a half bar at a time, for variety;
  -- a syncopation needs the whole bar to spread over (3 in 8 is a tresillo,
  -- 3 in 4 twice is not).
  if P.halves and (groove ~= "Syncopated" or pace == "Busy") and len >= 2 * meter.beat then
    local h = snap(meter, len / 2)
    if h > 0 and h < len then pieces = { { 0, h }, { h, len } } end
  end
  local out = {}
  for _, pc in ipairs(pieces) do
    local slots = (pc[2] - pc[1]) // P.unit
    if slots >= 1 then
      local k = math.max(1, math.min(slots, round(slots * between(rnd, P.lo, P.hi))))
      local pat
      if groove == "Syncopated" and k > 1 and k < slots then
        pat = syncopated(meter, base + pc[1], P.unit, slots, k, rnd)
      else
        pat = strongest(meter, base + pc[1], P.unit, slots, k, rnd)
      end
      for _, o in ipairs(pat) do out[#out + 1] = pc[1] + o * P.unit end
    end
  end
  return M.figure(meter, base, len, out, figures, rnd, true)
end

-- The rhythm of a whole unit: a cell a bar, the first bar's cell often
-- coming back, so the unit has a rhythm of its own. A unit that closes holds
-- its last note from the half bar.
function M.unitRhythm(u, meter, r, rnd)
  local out = {}
  local cellLen = math.min(meter.bar, u.len)
  local first
  local at = 0
  while at < u.len do
    local len = math.min(cellLen, u.len - at)
    local cell
    if first and len == cellLen and coin(rnd, r.pace == "Busy" and 0.5 or 0.6) then cell = first
    else cell = M.cell(meter, (u.start + at) % meter.bar, len, r.pace, r.groove, rnd, r.figures) end
    first = first or cell
    for _, o in ipairs(cell) do out[#out + 1] = at + o end
    at = at + len
  end
  if u.cad ~= "none" and u.cad ~= "open" then
    -- The last note lands half way through the last bar, or where the last
    -- chord arrives if that is later: the tune comes home with the harmony.
    local region = math.min(meter.bar, u.len)
    local from = u.len - region
    local h = from + snap(meter, region / 2)
    if h >= u.len then h = from end
    if u.rel and u.rel[#u.rel].s > h and u.rel[#u.rel].s < u.len then h = u.rel[#u.rel].s end
    local kept = {}
    for _, o in ipairs(out) do if o < h then kept[#kept + 1] = o end end
    kept[#kept + 1] = h
    out = kept
  end
  table.sort(out)
  -- An ending is a note to land on, not the middle of a triplet: a unit
  -- with a cadence (open ones too) ends on a step of its own.
  if u.cad ~= "none" then
    while #out > 1 and M.offGrid(out[#out]) do out[#out] = nil end
  end
  return out
end

------------------------------------------------------------------------------
-- 5. Melody
--
-- A walk through scale positions. Each next note is drawn from the notes up
-- to a sixth either side, weighted:
--
--   - by size: a step is most likely, a third about half as likely, leaps
--     rare (the shape of real melodies: mostly steps);
--   - toward the contour, a bell curve around where the contour is now;
--   - on the beat, only chord tones;
--   - after a leap of a fourth or more, only a step or a third back the
--     other way (the gap is filled);
--   - a note off the chord moves on by step (a passing or neighbour note);
--   - no tritone leaps, no augmented seconds, no note three times running,
--     and a step back to the note before last only now and then (once is a
--     neighbour note; again and again is a trill).
--
-- A unit that ends on a cadence ends on its goal - the tonic for a full
-- close, the third or fifth for an imperfect one, a note of the dominant for
-- a half close - and the note before it is pulled to a step away.
------------------------------------------------------------------------------

local IV_WEIGHT = { [0] = 0.15, [1] = 1, [2] = 0.6, [3] = 0.22, [4] = 0.18, [5] = 0.07 }
local PULL = 2.3   -- how far from the contour a note wanders, in scale steps

local CONTOURS = {
  Arch = function(t)
    local g = 0.618
    if t < g then return 0.2 + 0.8 * math.sin(math.pi / 2 * t / g) end
    return 0.15 + 0.85 * math.cos(math.pi / 2 * (t - g) / (1 - g))
  end,
  Valley = function(t)
    local g = 0.618
    if t < g then return 0.8 - 0.8 * math.sin(math.pi / 2 * t / g) end
    return 0.85 * math.sin(math.pi / 2 * (t - g) / (1 - g))
  end,
  Rise = function(t) return 0.1 + 0.8 * t end,
  Fall = function(t) return 0.9 - 0.8 * t end,
  Wave = function(t) return 0.5 + 0.4 * math.sin(2 * math.pi * 1.5 * t) end,
}
M.CONTOURS = CONTOURS

local REGISTER = { Low = 55, Middle = 67, High = 76 }

-- The positions a tune may use: about a ninth, centred on the fifth above
-- the tonic nearest the register. Counted from the tonic rather than from a
-- pitch, so the same idea in another key is the same tune, moved.
function M.melodyRange(key, register)
  local n = T.scaleLen(key)
  local want = (REGISTER[register] or 67) - 7
  local tonic = math.floor((want - T.rootPc(key)) / 12 + 0.5) * n
  local centre = tonic + round(n * 4 / 7)
  local span = n + 2
  local lo = centre - span // 2
  return lo, lo + span
end

-- `key` everywhere below is the scale sounding at that moment
-- (`M.keyAt`): the key's own, or a borrowed chord's.
local function nearestOn(ctx, key, ch, target, avoid)
  local best
  for p = ctx.lo, ctx.hi do
    if T.onChord(key, ch, p) and p ~= avoid then
      if not best or math.abs(p - target) < math.abs(best - target) then best = p end
    end
  end
  return best or math.max(ctx.lo, math.min(ctx.hi, round(target)))
end

local function choose(ctx, key, prev, prevIv, prevNct, reps, target, ch, strong, rnd, goal, before)
  for relax = 0, 2 do
    local cands, ws = {}, {}
    for iv = -5, 5 do
      local p = prev + iv
      if p >= ctx.lo and p <= ctx.hi then
        local w = IV_WEIGHT[math.abs(iv)]
        local on = T.onChord(key, ch, p)
        if strong and not on then w = 0 end
        if relax < 2 and prevIv and math.abs(prevIv) >= 3 and (iv * prevIv >= 0 or math.abs(iv) > 2) then w = 0 end
        if relax < 1 and prevNct and math.abs(iv) ~= 1 then w = 0 end
        if iv == 0 and reps >= 1 then w = 0 end
        if math.abs(iv) >= 2 and not on then w = w * 0.15 end
        if before and p == before and math.abs(iv) <= 2 then w = w * 0.25 end
        local semis = math.abs(T.pitch(key, p) - T.pitch(key, prev))
        if semis == 6 then w = 0 end
        if math.abs(iv) == 1 and semis == 3 then w = 0 end
        local d = p - target
        w = w * math.exp(-(d * d) / (2 * PULL * PULL))
        if goal then
          if math.abs(T.pitch(key, p) - T.pitch(key, goal)) == 6 then w = 0 end
          local g = math.abs(p - goal)
          w = w * ((g == 1 and 4) or (g == 2 and 1.5) or (g == 0 and 0.3) or 0.2)
        end
        if w > 0 then cands[#cands + 1] = p; ws[#ws + 1] = w end
      end
    end
    if #cands > 0 then return weighted(rnd, cands, ws) end
  end
  return nearestOn(ctx, key, ch, target)
end

-- Where a closing unit lands: its last note, at `step`.
local function goalFor(ctx, u, prev, target, step)
  local key = M.keyAt(ctx, step)
  local n = T.scaleLen(key)
  local ch = M.chordAt(ctx.timeline, step).chord
  local tonic = T.chord(ctx.key, 0, "Triads")
  local ok
  if u.cad == "PAC" then ok = function(p) return p % n == 0 end
  elseif u.cad == "IAC" then ok = function(p) return T.onChord(key, tonic, p) and p % n ~= 0 end
  elseif u.cad == "HC" then ok = function(p) return T.onChord(key, ch, p) end
  elseif u.cad == "DC" then
    -- The tune lands where the tonic was due - do, which vi also has - and
    -- the harmony goes elsewhere under it.
    ok = function(p) return T.onChord(key, ch, p) end
    local okBase = ok
    local best, bestCost
    for p = ctx.lo - 2, ctx.hi + 2 do
      if okBase(p) then
        local cost = math.abs(p - prev) + 0.4 * math.abs(p - target) + ((p % n == 0) and 0 or 3)
        if not bestCost or cost < bestCost then best, bestCost = p, cost end
      end
    end
    return best
  elseif u.cad == "open" then
    -- Back toward where the idea started, without landing on it, so it
    -- loops.
    target = ctx.firstPos or target
    ok = function(p) return T.onChord(key, ch, p) and p ~= ctx.firstPos end
  else return nil end
  local best, bestCost
  for p = ctx.lo - 2, ctx.hi + 2 do
    if ok(p) then
      local cost = math.abs(p - prev) + 0.4 * math.abs(p - target)
      if not bestCost or cost < bestCost then best, bestCost = p, cost end
    end
  end
  return best
end

-- New notes for a unit at the given onsets (steps from the unit's start).
local function walkUnit(ctx, u, onsets, rnd, state)
  local out = {}
  local reps = state.reps or 0
  local closing = u.cad ~= "none"
  for i, o in ipairs(onsets) do
    local step = u.start + o
    local sl = M.chordAt(ctx.timeline, step)
    local ch = sl.chord
    local key = sl.key or ctx.key
    local strong = M.strength(ctx.meter, step) >= 2 or i == 1
    local target = ctx.target(step)
    local p
    if not state.prev then
      p = nearestOn(ctx, key, ch, target)
      ctx.firstPos = p
    elseif closing and i == #onsets then
      p = goalFor(ctx, u, state.prev, target, step) or choose(ctx, key, state.prev, state.iv, state.nct, reps, target, ch, true, rnd)
    elseif closing and i == #onsets - 1 then
      local goal = goalFor(ctx, u, state.prev, target, u.start + onsets[#onsets])
      p = choose(ctx, key, state.prev, state.iv, state.nct, reps, goal or target, ch, strong, rnd, goal, state.before)
    else
      p = choose(ctx, key, state.prev, state.iv, state.nct, reps, target, ch, strong, rnd, nil, state.before)
    end
    state.before = state.prev
    if state.prev then
      state.iv = p - state.prev
      reps = (p == state.prev) and reps + 1 or 0
      state.reps = reps
    end
    state.prev = p
    state.nct = not T.onChord(key, ch, p)
    out[#out + 1] = { at = o, pos = p }
  end
  return out
end

-- Notes copied from another unit, moved to this one's start, shifted by
-- `shift` scale steps.
local function copyNotes(src, from, to, shift)
  local out = {}
  for _, nt in ipairs(src.notes) do
    if nt.at >= from and nt.at < to then out[#out + 1] = { at = nt.at - from, pos = nt.pos + (shift or 0) } end
  end
  return out
end

-- A statement moved onto new chords keeps its shape: the notes on the beat
-- that are not on the chord now go to the nearest chord tone, the rest stay.
-- With `ending`, the last note counts as on the beat too: it is the
-- unit's ending (an exact repeat of a unit that closes).
local function fit(ctx, u, notes, ending)
  for i, nt in ipairs(notes) do
    local step = u.start + nt.at
    if M.strength(ctx.meter, step) >= 2 or (ending and i == #notes and u.cad ~= "none") then
      local ch = M.chordAt(ctx.timeline, step).chord
      local key = M.keyAt(ctx, step)
      if not T.onChord(key, ch, nt.pos) then
        local up, down = nt.pos + 1, nt.pos - 1
        while not T.onChord(key, ch, up) do up = up + 1 end
        while not T.onChord(key, ch, down) do down = down - 1 end
        nt.pos = (up - nt.pos <= nt.pos - down) and up or down
      end
    end
  end
  return notes
end

-- The shift (of `shift` or an octave either side of it) that keeps a
-- statement in range and nearest the note before.
local function bestShift(ctx, src, from, to, shift, prev)
  local n = T.scaleLen(ctx.key)
  local best, bestCost
  for _, s in ipairs({ shift, shift - n, shift + n }) do
    local notes = copyNotes(src, from, to, s)
    if #notes > 0 then
      -- Out of range costs by how far out, so if every choice is out, the
      -- least out wins.
      local over = 0
      for _, nt in ipairs(notes) do
        over = math.max(over, ctx.lo - 1 - nt.pos, nt.pos - ctx.hi - 1)
      end
      local cost = over * 100 + (prev and math.abs(notes[1].pos - prev) or 0)
      if not bestCost or cost < bestCost then best, bestCost = s, cost end
    end
  end
  return best or shift
end

function M.melody(plan, ctx, r, rnd)
  local state = {}
  local units = plan.units
  for _, u in ipairs(units) do
    local src = u.of and units[u.of]
    local notes
    local same = src and src.len == u.len and src.cad == u.cad
    if u.kind == "repeat" and same then
      -- (Fitted too: the chords are the same degrees, but a borrowed chord
      -- or a push may have come to one pass and not the other.)
      notes = fit(ctx, u, copyNotes(src, 0, u.len, 0), true)
    elseif u.kind == "seq" and same and u.cad == "none" then
      local s = bestShift(ctx, src, 0, u.len, u.shift, state.prev)
      notes = fit(ctx, u, copyNotes(src, 0, u.len, s))
    elseif src and u.kind ~= "frag" then
      -- The source's first half (moved, for a sequence), then a new second
      -- half to this unit's own ending. An answer to the same ending (a loop
      -- going round again) keeps the chords but still answers in the tune.
      local cut = M.cutFor(ctx.meter, src, u)
      local s = (u.kind == "seq") and bestShift(ctx, src, 0, cut, u.shift, state.prev) or 0
      notes = fit(ctx, u, copyNotes(src, 0, cut, s))
      if #notes > 0 then
        state.prev = notes[#notes].pos
        state.iv = #notes > 1 and (notes[#notes].pos - notes[#notes - 1].pos) or nil
        state.nct = false
      end
      local rh = M.unitRhythm(u, ctx.meter, r, ctx.rhythmRnd)
      local rest = {}
      for _, o in ipairs(rh) do if o >= cut then rest[#rest + 1] = o - cut end end
      if #rest == 0 then rest = { 0 } end
      local tail = { start = u.start + cut, len = u.len - cut, cad = u.cad, slots = u.slots }
      for _, nt in ipairs(walkUnit(ctx, tail, rest, rnd, state)) do
        notes[#notes + 1] = { at = nt.at + cut, pos = nt.pos }
      end
    elseif u.kind == "frag" then
      -- The basic idea's first half, again and again, each a step lower.
      local basic = units[1]
      local half = snap(ctx.meter, basic.len / 2)
      if half <= 0 then half = basic.len end
      notes = {}
      local at, k = 0, 0
      while at < u.len do
        local s = bestShift(ctx, basic, 0, half, -k, state.prev)
        for j, nt in ipairs(copyNotes(basic, 0, math.min(half, u.len - at), s)) do
          -- Each fragment is a statement of its own.
          notes[#notes + 1] = { at = nt.at + at, pos = nt.pos, fresh = (j == 1) }
        end
        if #notes > 0 then state.prev = notes[#notes].pos end
        at, k = at + half, k + 1
      end
      notes = fit(ctx, u, notes)
    else
      notes = walkUnit(ctx, u, M.unitRhythm(u, ctx.meter, r, ctx.rhythmRnd), rnd, state)
    end
    u.notes = notes
    if #notes > 0 then
      state.prev = notes[#notes].pos
      state.iv = #notes > 1 and (notes[#notes].pos - notes[#notes - 1].pos) or state.iv
      local at = u.start + notes[#notes].at
      state.nct = not T.onChord(M.keyAt(ctx, at), M.chordAt(ctx.timeline, at).chord, notes[#notes].pos)
    end
  end

  -- Into the timeline: each note lasts until the next (never longer than a
  -- half note, unless it is the last of its unit, which is held).
  local all = {}
  for _, u in ipairs(units) do
    for i, nt in ipairs(u.notes) do
      all[#all + 1] = { order = #all, step = u.start + nt.at, pos = nt.pos, last = (i == #u.notes),
                        closes = (i == #u.notes) and u.cad ~= "none" and u.cad,
                        unitEnd = u.start + u.len, first = (i == 1) or nt.fresh or false }
    end
  end
  table.sort(all, function(a, b)
    if a.step ~= b.step then return a.step < b.step end
    return a.order < b.order
  end)
  -- Two notes on one step (a copied cell meeting the next unit): keep the later.
  local notes = {}
  for i, nt in ipairs(all) do
    if not all[i + 1] or all[i + 1].step ~= nt.step then notes[#notes + 1] = nt end
  end
  notes = M.wholeTriplets(notes)
  M.untangle(ctx, notes)
  -- A pushed chord takes the tune's note on its beat with it, an eighth
  -- early - as long as nothing else is sounding in that eighth, and the
  -- note does not begin a triplet (which would leave the other two behind).
  for _, sl in ipairs(ctx.timeline) do
    if sl.pushed then
      for i, nt in ipairs(notes) do
        local before, after = notes[i - 1], notes[i + 1]
        if nt.step == sl.s + 2 and i > 1 and before.step < sl.s and not (after and M.offGrid(after.step)) then
          nt.step, nt.pushed = sl.s, true
        end
      end
    end
  end
  if ctx.bassPcAt then M.noParallels(ctx, notes, ctx.bassPcAt) end
  for i, nt in ipairs(notes) do
    local nextStep = notes[i + 1] and notes[i + 1].step or plan.total
    local len = nextStep - nt.step
    if not nt.last then len = math.min(len, 8) end
    nt.len = math.max(1, len)
    nt.pitch = T.pitch(M.keyAt(ctx, nt.step), nt.pos)
    nt.accent = nt.first or nt.pushed or nt.step % ctx.meter.bar == 0
  end
  return notes
end

-- Is a step between the sixteenths (part of a triplet)?
function M.offGrid(step) return math.abs(step - math.floor(step + 0.5)) > 1e-6 end

-- Every triplet in the tune whole. Copying half a statement, holding a
-- closing note, or cutting at a cadence can take the end off a triplet
-- that began before it; what is left is not a triplet but a stumble. So a
-- note between the sixteenths stays only if it is one of a whole
-- eighth-note triplet (three in a beat) or quarter-note triplet (three in
-- two beats) starting on a beat; otherwise it goes, and the note before it
-- simply lasts longer.
function M.wholeTriplets(notes)
  local at = {}
  local function key(x) return ("%.4f"):format(x) end
  for _, n in ipairs(notes) do at[key(n.step)] = true end
  local function has(x) return at[key(x)] end
  local out = {}
  for _, n in ipairs(notes) do
    local keep = not M.offGrid(n.step)
    if not keep then
      for _, span in ipairs({ 4 / 3, 8 / 3 }) do
        for k = 1, 2 do
          local g = n.step - k * span
          if not M.offGrid(g / 4) and has(g) and has(g + span) and has(g + 2 * span) then keep = true end
        end
      end
    end
    if keep then out[#out + 1] = n end
  end
  return out
end

-- The last pass over the whole tune. Copying a statement onto new chords
-- can land two or three of its notes on the same chord tone, and a copy can
-- start a tritone, or more than an octave, from where the tune was. So:
--
--   - a note that would be the third the same in a row moves;
--   - a note a tritone from the one before moves - or, if it cannot (or it
--     is the last note, which stays put), the one before it does;
--   - a leap of more than an octave inside a statement is brought an
--     octave closer.
--
-- A note on the beat moves to another chord tone, one off the beat to the
-- note a step away - whichever is nearest, in range, and makes no tritone
-- with either neighbour.
function M.untangle(ctx, notes)
  local n = T.scaleLen(ctx.key)
  -- A note's pitch at a position, read in the scale sounding at its step.
  local function P(note, pos) return T.pitch(M.keyAt(ctx, note.step), pos or note.pos) end
  local function apart(x, px, y, py) return math.abs(P(x, px) - P(y, py)) end
  local NEAR, WIDE = { 1, -1, 2, -2, 3, -3, 4, -4 }, { 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6 }
  -- `wide` looks further, and a little outside the range, when nothing
  -- near will do.
  local function move(i, strict, wide)
    local a, b, c = notes[i - 1], notes[i], notes[i + 1]
    if not b then return false end
    local ch = M.chordAt(ctx.timeline, b.step).chord
    local key = M.keyAt(ctx, b.step)
    local strong = M.strength(ctx.meter, b.step) >= 2
    local slack = wide and 3 or 1
    for _, d in ipairs(wide and WIDE or NEAR) do
      local p = b.pos + d
      local inRange = p >= ctx.lo - slack and p <= ctx.hi + slack
      local fits = (strong and T.onChord(key, ch, p)) or (not strong and (math.abs(d) == 1 or wide))
      local clash = strict and ((a and apart(a, nil, b, p) == 6) or (c and apart(b, p, c, nil) == 6))
      -- A repeat is fine; three of a kind is not.
      local z, y = notes[i - 2], notes[i + 2]
      local same = function(x) return x and apart(x, nil, b, p) == 0 end
      local triple = (same(a) and same(z)) or (same(a) and same(c)) or (same(c) and same(y))
      if fits and inRange and not clash and not triple and p ~= b.pos then
        b.pos = p
        return true
      end
    end
    return false
  end
  local function tryMove(i, allowTritone)
    return move(i, true, false) or move(i, true, true) or (allowTritone and move(i, false, true))
  end
  -- Twice over, so a note moved to mend one thing is checked again.
  for _ = 1, 2 do
    for i = 2, #notes do
      local a, b, c = notes[i - 1], notes[i], notes[i + 1]
      if c and P(a) == P(b) and P(b) == P(c) then
        -- (In the diminished and whole-tone scales every way out may be a
        -- tritone; a tritone is better there than a note three times.)
        tryMove(i, true)
      end
      if apart(a, nil, b, nil) == 6 then
        if i == #notes or not tryMove(i, false) then tryMove(i - 1, false) end
      end
      if not b.first and apart(a, nil, b, nil) > 12 then
        local p = b.pos + ((a.pos > b.pos) and n or -n)
        if apart(a, nil, b, p) ~= 6 and not (c and apart(b, p, c, nil) == 6)
           and p >= ctx.lo - 3 and p <= ctx.hi + 3 then b.pos = p end
      end
    end
  end
end

-- By the book (1.7): no parallel fifths or octaves between the tune and
-- the bass - the outer voices, where the books are strictest (Hutchinson,
-- ch. 26; Open Music Theory, first-species counterpoint and basso
-- continuo). Two notes running in which both the tune and the bass move,
-- and stand a fifth (or an octave, or a unison) apart both times, contrary
-- motion included. `bassPcAt(step)` is the bass sounding at a step.
--
-- Of the two, the later note moves (a full or imperfect close's last note
-- stays; the idea's first note moves only as a last resort); failing that, the earlier one. A note on
-- the beat moves to another chord tone, one off it a step - whichever is
-- nearest and keeps every rule `untangle` keeps.
function M.parallel(ctx, bassPcAt, a, ap, b, bp)
  local ba, bb = bassPcAt(a.step), bassPcAt(b.step)
  if not ba or not bb or ba == bb then return false end
  local pa, pb = T.pitch(M.keyAt(ctx, a.step), ap or a.pos), T.pitch(M.keyAt(ctx, b.step), bp or b.pos)
  if pa == pb then return false end
  local ia, ib = (pa - ba) % 12, (pb - bb) % 12
  return ia == ib and (ia == 0 or ia == 7)
end

function M.noParallels(ctx, notes, bassPcAt)
  local function P(note, pos) return T.pitch(M.keyAt(ctx, note.step), pos or note.pos) end
  local function try(i, wide, first)
    local a, b, c = notes[i - 1], notes[i], notes[i + 1]
    -- (A full or imperfect close's last note is its goal and stays; a half
    -- close's or an open ending's may move to another note of its chord.)
    local goal = b and (b.closes == "PAC" or b.closes == "IAC" or b.closes == "DC")
    if not b or goal or (i == 1 and not first) or (i == #notes and not b.closes) then return false end
    local ch = M.chordAt(ctx.timeline, b.step).chord
    local key = M.keyAt(ctx, b.step)
    local strong = M.strength(ctx.meter, b.step) >= 2 or b.closes
    -- (`wide` looks further, and a little further outside the range, when
    -- nothing near will do.)
    local slack = wide and 3 or 1
    for _, d in ipairs(wide and { 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6 } or { 1, -1, 2, -2, 3, -3, 4, -4 }) do
      local p = b.pos + d
      local fits = (strong and T.onChord(key, ch, p)) or (not strong and (math.abs(d) == 1 or wide))
      local good = fits and p >= ctx.lo - slack and p <= ctx.hi + slack
      if good then
        local pp = P(b, p)
        -- (Not ipairs: with no note before, `a` is nil and ipairs would stop.)
        for k = 1, 2 do
          local x = (k == 1) and a or c
          if x then
            local gap = math.abs(P(x) - pp)
            if gap == 6 or (gap > 12 and not (x == c and c.first) and not (x == a and b.first)) then good = false end
          end
        end
        local z, y = notes[i - 2], notes[i + 2]
        if (z and a and P(z) == P(a) and P(a) == pp) or (c and y and P(c) == pp and P(y) == pp)
           or (a and c and P(a) == pp and P(c) == pp) then good = false end
        if good and a and M.parallel(ctx, bassPcAt, a, nil, b, p) then good = false end
        if good and c and M.parallel(ctx, bassPcAt, b, p, c, nil) then good = false end
      end
      if good then b.pos = p; return true end
    end
    return false
  end
  for _ = 1, 2 do
    for i = 2, #notes do
      if M.parallel(ctx, bassPcAt, notes[i - 1], nil, notes[i], nil) then
        if not (try(i) or try(i - 1) or try(i, true) or try(i - 1, true)) and i > 3 then
          -- (Boxed in - the way out would be a third note the same: the
          -- note before that moves first, then this one.)
          local keep = notes[i - 2].pos
          if try(i - 2) and not (try(i - 1) or try(i - 1, true)) then notes[i - 2].pos = keep end
        elseif i == 2 and M.parallel(ctx, bassPcAt, notes[1], nil, notes[2], nil) then
          -- (At the very start, the idea's first note may move as a last resort.)
          try(1, true, true)
        end
      end
    end
  end
end

------------------------------------------------------------------------------
-- 6. Chords, bass and drums
------------------------------------------------------------------------------

local ARPEGGIOS = {
  { name = "up",          order = { 1, 2, 3, 4 } },
  { name = "up and down", order = { 1, 2, 3, 4, 3, 2 } },
  { name = "Alberti",     order = { 1, 3, 2, 3 } },
  { name = "rolling",     order = { 1, 2, 3, 2 } },
}

-- Bar lines inside [s, e), and s itself.
local function barStarts(meter, s, e)
  local out = { s }
  local b = (s // meter.bar + 1) * meter.bar
  while b < e do out[#out + 1] = b; b = b + meter.bar end
  return out
end

-- A pushed chord is played as if it began on its beat, with its first
-- stroke moved back onto the push: so it is struck on the "and", and not
-- struck again an eighth later on the beat.
-- Every chord keeps the beat it belongs to (`sl.beat`), even when it is
-- pushed an eighth early or pulled an eighth late. A chord's strokes are
-- laid out on the grid from its beat, then its first stroke moves to where
-- the chord really arrives (`onShift`): onto the push, so it is not struck
-- again on the beat, or back to the pull, so nothing is struck before it.
local function beatOf(sl) return sl.beat or sl.s end
local function gridStart(sl) return beatOf(sl) end
local function onShift(sl, onsets)
  local beat = beatOf(sl)
  if sl.s == beat then return onsets end
  if sl.s < beat then
    if onsets[1] == beat then onsets[1] = sl.s else table.insert(onsets, 1, sl.s) end
    return onsets
  end
  -- Pulled: nothing before it, and nothing crowding in less than a
  -- sixteenth after it (a triplet grid can put a stroke two thirds of a
  -- sixteenth behind).
  local out = { sl.s }
  for _, o in ipairs(onsets) do if o >= sl.s + 1 then out[#out + 1] = o end end
  return out
end
local onPush = onShift

-- The onsets of a pulse inside [s, e), with dotted and triplet figures laid
-- over it bar by bar.
local function pulseOnsets(meter, s, e, pace, groove, rnd, pattern, figures)
  -- Straight is on the beat (eighths when busy); syncopated is spread over
  -- the eighths.
  local unit = (pace == "Busy" or groove == "Syncopated") and 2 or meter.beat
  if pace == "Calm" then unit = meter.beat end
  local out = {}
  for _, b in ipairs(barStarts(meter, s, e)) do
    local stop = math.min(e, (b // meter.bar + 1) * meter.bar)
    local slots = (stop - b) // unit
    local pat
    if groove == "Syncopated" and slots >= 4 then
      pattern[slots] = pattern[slots] or syncopated(meter, b % meter.bar, unit, slots,
        math.max(2, round(slots * 3 / 8)), rnd)
      pat = pattern[slots]
    else
      pat = {}
      for i = 0, slots - 1 do pat[#pat + 1] = i end
    end
    local rel = {}
    for i, o in ipairs(pat) do rel[i] = o * unit end
    for _, o in ipairs(M.figure(meter, b % meter.bar, stop - b, rel, figures, rnd)) do out[#out + 1] = b + o end
  end
  return out
end

local function addNote(list, step, len, pitch, accent)
  if pitch and pitch >= 0 and pitch <= 127 and len > 0 then
    list[#list + 1] = { step = step, len = len, pitch = pitch, accent = accent or false }
  end
end

-- A held (Block) chord takes the figures as stabs: now and then struck
-- again a dotted quarter in (the Charleston, 1 and the "and" of 2), or
-- three times across the first two beats (a quarter-note triplet).
local function blockFigures(meter, onsets, to, figures, rnd)
  local F = FIGURES[figures]
  if not F or meter.beat ~= 4 then return onsets end
  local out = {}
  for i, o in ipairs(onsets) do
    out[#out + 1] = o
    local stop = onsets[i + 1] or to
    if o % 4 == 0 and stop - o >= 8 then
      local x = rnd()
      if x < F.tri then out[#out + 1] = o + 8 / 3; out[#out + 1] = o + 16 / 3
      elseif x < F.tri + F.dot then out[#out + 1] = o + 6 end
    end
  end
  return out
end

------------------------------------------------------------------------------
-- Part-writing by the book (1.7; docs/decisions/0019-part-writing-by-the-book.md)
------------------------------------------------------------------------------

-- An inverted chord does not double its bass note above it (Hutchinson,
-- ch. 26; Rimsky-Korsakov, ch. III). In close position a chord of four
-- notes or more simply leaves it out; otherwise the note takes the root's
-- place, or the fifth's - the nearest one free, so a voicing keeps its
-- number of notes (a rootless voicing takes the fifth or the ninth, never
-- the root). A diminished triad in first inversion doubles
-- its bass, as the books say: it is the one exception.
function M.undouble(v, ch, bassPc, style)
  local others = 0
  for _, p in ipairs(v) do if p % 12 ~= bassPc then others = others + 1 end end
  if others == #v then return v end
  local out, used = {}, {}
  for _, p in ipairs(v) do if p % 12 ~= bassPc then out[#out + 1] = p; used[p] = true end end
  if others >= 3 and (style == "Close" or not style) then return out end
  local fifth, nine
  for _, pc in ipairs(ch.pcs) do
    local role = T.roleOf(ch, pc)
    if role == "5" and pc ~= bassPc then fifth = pc end
    if role == "9" and pc ~= bassPc then nine = pc end
  end
  nine = nine or ch.nine
  local want = (style == "Rootless") and { fifth, nine } or { ch.rootPc ~= bassPc and ch.rootPc or nil, fifth }
  local top = v[#v]
  for _, p in ipairs(v) do
    if p % 12 == bassPc then
      -- (The top note's place goes to a note at or above it, so a spread
      -- voicing keeps its span.)
      local function cost(q) return math.abs(q - p) + ((p == top and q < p) and 12 or 0) end
      local best
      for k = 1, 2 do
        local pc = want[k]
        if pc then
          for q = p - 12, p + 12 do
            if q % 12 == pc and not used[q] and (not best or cost(q) < cost(best)) then best = q end
          end
        end
        if best then break end
      end
      if best then out[#out + 1] = best; used[best] = true end
    end
  end
  table.sort(out)
  -- (A two-note chord - a pentatonic scale's - keeps what it has.)
  if #out < 2 then return v end
  return out
end

-- A seventh falls a step into the next chord (Hutchinson, ch. 27; Open Music
-- Theory, "Tendency tones"): if the chord before had its seventh at `p7`,
-- and this chord has a note a semitone or a tone below it, the voicing that
-- puts that note there is wanted - unless this chord keeps the seventh's
-- note, which may then be held. Returns the wanted pitch, or nil.
function M.seventhTarget(ch, prevV, prevCh)
  if not prevV or not prevCh then return nil end
  local s7
  for _, pc in ipairs(prevCh.pcs) do if T.roleOf(prevCh, pc) == "7" then s7 = pc end end
  if not s7 or ch.has[s7] then return nil end
  local p7
  for _, p in ipairs(prevV) do if p % 12 == s7 then p7 = p end end
  if not p7 then return nil end
  for _, t in ipairs({ p7 - 1, p7 - 2 }) do
    if ch.has[t % 12] then return t end
  end
end

-- The lowest note of the tune sounding in [s, e), or nil.
local function tuneLowIn(tune, s, e)
  local low
  for _, n in ipairs(tune) do
    if n.step < e and n.step + n.len > s then low = math.min(low or 127, n.pitch) end
  end
  return low
end

function M.chordsPart(ctx, timeline, r, rnd, win)
  local notes = {}
  local meter = ctx.meter
  local prev, prevBass, prevCh
  local arp = pickOne(rnd, ARPEGGIOS)
  local pattern = {}
  local lows = {}
  local book = win.book
  local lastHi = win.hi
  for idx, sl in ipairs(timeline) do
    local lo, hi = win.lo, win.hi
    if book and win.tune then
      -- By the book the chords sit just under the tune notes over them -
      -- reaching a step or two into the lowest, if they must - not under
      -- the whole tune's lowest note.
      -- (Over the chord's span on the beat: a pull does not move it.)
      local span = win.beatTl and win.beatTl[idx] or sl
      local low = tuneLowIn(win.tune, span.s, span.e)
      hi = low and math.max(57, math.min(76, low + 2)) or lastHi
      lastHi = hi
      lo = math.max(43, hi - ((r.voicing == "Close") and 12 or 24))
    end
    -- A spread voicing may reach down to G2 for its root.
    -- A voicing that will not fit under the tune may reach an octave over
    -- the top before it gives up and plays close position.
    local want = book and M.seventhTarget(sl.chord, prev, prevCh) or nil
    -- (A seventh's step down matters more than where the tune has gone:
    -- the window stretches to take it - a little over the top, if it must.)
    if want then
      if want < lo and want >= 43 then lo = want end
      if want > hi and want <= hi + 3 then hi = want end
    end
    local v = T.voiceAs(sl.chord, r.voicing, prev, lo, hi, 43, want)
    if #v == 0 then v = T.voiceAs(sl.chord, r.voicing, nil, lo, hi + 12, 43, want) end
    if #v == 0 then v = T.voiceAs(sl.chord, "Close", nil, lo, hi + 12, nil, want) end
    if book then
      local dimTriad = sl.chord.quality == "diminished" and #sl.chord.pcs == 3
      if sl.inversion and not dimTriad then v = M.undouble(v, sl.chord, sl.bassPc, r.voicing) end
    end
    prev, prevCh = v, sl.chord
    lows[idx] = v[1]
    local onsets, perNote = {}, false
    -- The grid runs from this chord's beat to the next chord's beat (or to
    -- where this one ends, if the next is pushed in front of it).
    local from = gridStart(sl)
    local nextSl = timeline[idx + 1]
    local to = nextSl and math.min(sl.e, beatOf(nextSl)) or sl.e
    if r.chordStyle == "Pulse" then
      onsets = onShift(sl, pulseOnsets(meter, from, to, r.pace, r.groove, rnd, pattern, r.figures))
    elseif r.chordStyle == "Broken" then
      local unit = (r.pace == "Calm") and meter.beat or (r.pace == "Busy" and 1 or 2)
      -- In triplets, an arpeggio rolls in eighth-note triplets.
      if r.pace ~= "Calm" and meter.beat == 4 and (r.figures == "Triplets" or
         (r.figures == "Mixed" and coin(rnd, 0.4))) then unit = 4 / 3 end
      for st = from, to - 1e-6, unit do onsets[#onsets + 1] = st end
      if unit ~= 4 / 3 then
        -- Otherwise the figures fall on the arpeggio: long-short pairs, or
        -- a beat in three.
        local rel = {}
        for i, o in ipairs(onsets) do rel[i] = o - from end
        onsets = {}
        for _, o in ipairs(M.figure(meter, from % meter.bar, to - from, rel, r.figures, rnd)) do
          onsets[#onsets + 1] = from + o
        end
      end
      onsets = onShift(sl, onsets)
      perNote = true
    else
      onsets = onShift(sl, blockFigures(meter, barStarts(meter, from, to), to, r.figures, rnd))
    end
    for i, o in ipairs(onsets) do
      local stop = onsets[i + 1] or sl.e
      local accent = o % meter.bar == 0
      if perNote then
        local k = arp.order[(i - 1) % #arp.order + 1]
        local pitch = (k <= #v) and v[k] or (v[(k - 1) % #v + 1] + 12 * ((k - 1) // #v))
        addNote(notes, o, stop - o, pitch, accent)
      else
        for _, p in ipairs(v) do addNote(notes, o, stop - o, p, accent) end
      end
    end
    if win.bass then
      local b = T.bassNote(bassPcOf(sl), prevBass, 36, 47)
      -- (Under any voicing but Close - which is as it always was - the bass
      -- goes under the chord's lowest note, down to E1 if it has to.)
      if r.voicing ~= "Close" and v[1] and b >= v[1] then b = T.bassNote(bassPcOf(sl), prevBass, 28, v[1] - 1) end
      -- By the book: under the chord, and no more than an octave and a fifth
      -- under it.
      if book and v[1] then b = T.bassNote(bassPcOf(sl), prevBass, math.max(28, v[1] - 19), v[1] - 1) end
      prevBass = b
      local bars = onShift(sl, barStarts(meter, gridStart(sl), to))
      for i, o in ipairs(bars) do addNote(notes, o, (bars[i + 1] or sl.e) - o, b, o % meter.bar == 0) end
    end
  end
  return notes, arp.name, lows
end

-- By the book, a Measure's bass is put in the octave that keeps it under
-- the chords and no more than an octave and a fifth under them (Rimsky-
-- Korsakov: "rarely more than an octave"; Belkin: no hole in the middle),
-- inside the bass's range, each note the octave nearest the one before.
-- Only octaves move: the notes are the same.
function M.spaceBass(bass, timeline, lows)
  local function slotOf(step)
    local idx = 1
    for i, sl in ipairs(timeline) do if step >= sl.s then idx = i end end
    return idx
  end
  -- The octave of `n` nearest `ref` in [lo, hi], or nil.
  local function pick(n, ref, lo, hi)
    local best
    for q = n.pitch - 36, n.pitch + 36, 12 do
      if q >= lo and q <= hi and (not best or math.abs(q - ref) < math.abs(best - ref)) then best = q end
    end
    return best
  end
  local orig, starts = {}, {}
  for i, n in ipairs(bass) do
    orig[i] = n.pitch
    local sl = timeline[slotOf(n.step)]
    starts[i] = math.abs(n.step - sl.s) < 1e-9
  end
  -- First the note each chord stands on, the octave nearest where the
  -- line was going (the same interval from the last one as it had)...
  local prevI
  for i, n in ipairs(bass) do
    local low = lows[slotOf(n.step)]
    if starts[i] and low then
      local ref = prevI and (bass[prevI].pitch + orig[i] - orig[prevI]) or n.pitch
      -- (And where the note leading into it can still step into it from
      -- under the chord before.)
      local before = bass[i - 1]
      local lowBefore = before and not starts[i - 1] and lows[slotOf(before.step)]
      local best, bestCost
      -- (A walking bass's step into the chord matters more than the gap,
      -- which matters more than where the line was going.)
      for wi, w in ipairs({ { math.max(28, low - 19), math.min(55, low - 1) }, { 28, math.min(55, low - 1) } }) do
        for q = n.pitch - 36, n.pitch + 36, 12 do
          if q >= w[1] and q <= w[2] then
            local cost = math.abs(q - ref) + (wi == 2 and 50 or 0)
            if lowBefore then
              local into = q + orig[i - 1] - orig[i]
              if into < 28 or into > math.min(55, lowBefore - 1) then cost = cost + 100 end
            end
            if not bestCost or cost < bestCost then best, bestCost = q, cost end
          end
        end
      end
      n.pitch = best or n.pitch
      prevI = i
    end
  end
  -- ...then the notes between, each as far from the next chord's note as it
  -- was (so a walking bass still steps into it), or from the note before.
  for i, n in ipairs(bass) do
    local low = lows[slotOf(n.step)]
    if not starts[i] and low then
      local nx = bass[i + 1]
      local ref
      if nx and starts[i + 1] then ref = nx.pitch + orig[i] - orig[i + 1]
      elseif i > 1 then ref = bass[i - 1].pitch + orig[i] - orig[i - 1]
      else ref = n.pitch end
      local q = pick(n, ref, math.max(28, low - 19), math.min(55, low - 1))
      if not q or math.abs(q - ref) > 2 then q = pick(n, ref, 28, math.min(55, low - 1)) or q end
      n.pitch = q or n.pitch
    end
  end
  return bass
end

-- The kick drum's places in a bar, which the bass can follow.
function M.kickPattern(meter, r, rnd)
  local slots = meter.bar // 2
  local k = ({ Calm = 1, Flowing = 2, Busy = 3 })[r.pace] or 2
  k = math.max(1, round(k * slots / 8))
  if r.groove == "Syncopated" then
    local kk = math.max(2, round(slots * ({ Calm = 0.38, Flowing = 0.38, Busy = 0.62 })[r.pace]))
    local pat = syncopated(meter, 0, 2, slots, math.min(kk, slots - 1), rnd)
    local out = {}
    for i, o in ipairs(pat) do out[i] = o * 2 end
    return out
  end
  local pat = strongest(meter, 0, 2, slots, k, rnd)
  local out = {}
  for i, o in ipairs(pat) do out[i] = o * 2 end
  return out
end

-- The tune's pitch sounding at a step, or nil.
local function tuneAt(tune, step)
  for _, n in ipairs(tune) do
    if n.step <= step + 1e-9 and n.step + n.len > step + 1e-9 then return n.pitch end
  end
end

function M.bassPart(ctx, timeline, r, rnd, kick, tune)
  local notes = {}
  local meter = ctx.meter
  local prev
  local prevStep, prevP
  -- Parallel fifths or octaves with the tune, from the bass note before to `q` at `st`.
  local function parallelAt(st, q, fromStep, fromP)
    if not (tune and fromStep) then return false end
    local tA, tB = tuneAt(tune, fromStep), tuneAt(tune, st)
    if not (tA and tB) or tA == tB or q % 12 == fromP % 12 then return false end
    local ia, ib = (tA - fromP) % 12, (tB - q) % 12
    return ia == ib and (ib == 0 or ib == 7)
  end
  for idx, sl in ipairs(timeline) do
    -- (The root, or the note an inverted chord stands on.)
    local root = T.bassNote(bassPcOf(sl), prev, 31, 50)
    prev = root
    local nextSl = timeline[idx + 1]
    local key = sl.key or ctx.key
    if r.bass == "Pulse" then
      local on = {}
      for _, b in ipairs(barStarts(meter, sl.s, sl.e)) do
        local barStart = (b // meter.bar) * meter.bar
        for _, k in ipairs(kick) do
          local st = barStart + k
          -- (A pushed chord's bass comes on the push, not again on the beat.)
          if st >= sl.s and st < sl.e and not (sl.pushed and st == sl.s + 2) then on[#on + 1] = st end
        end
      end
      local seen, list = {}, {}
      table.insert(on, 1, sl.s)
      for _, st in ipairs(on) do if not seen[st] then seen[st] = true; list[#list + 1] = st end end
      table.sort(list)
      for i, st in ipairs(list) do
        addNote(notes, st, math.min((list[i + 1] or sl.e) - st, 8), root, st % meter.bar == 0)
      end
    elseif r.bass == "Moving" then
      local unit = meter.beat
      if r.pace == "Calm" and (meter.bar // 2) % meter.beat == 0 and meter.beats % 2 == 0 then unit = meter.bar // 2 end
      local beats = {}
      local from = gridStart(sl)
      for st = from, sl.e - 1, unit do beats[#beats + 1] = st - from end
      -- Dotted and triplet figures fall on a walking bass too.
      local figured = M.figure(meter, from % meter.bar, sl.e - from, beats, r.figures, rnd)
      beats = {}
      for i, o in ipairs(figured) do beats[i] = from + o end
      beats = onPush(sl, beats)
      for i, st in ipairs(beats) do
        local p
        if i == 1 then p = root
        elseif i == #beats and nextSl then
          -- A step into the next chord's root, from the scale sounding now:
          -- the scale note a semitone or a tone from it, nearer the root
          -- being left.
          local nr = T.bassNote(bassPcOf(nextSl), root, 31, 50)
          local best, bestBad
          for q = nr - 2, nr + 2 do
            local d = math.abs(q - nr)
            if d >= 1 and T.posOf(key, q) then
              -- (By the book, one that makes no parallels with the tune,
              -- going in or coming out, is preferred.)
              local bad = (parallelAt(st, q, prevStep, prevP) or parallelAt(nextSl.s, nr, st, q)) and 1 or 0
              if not best or bad < bestBad or (bad == bestBad and math.abs(q - root) < math.abs(best - root)) then
                best, bestBad = q, bad
              end
            end
          end
          p = best or root
        else
          local fifth = T.bassNote(sl.chord.pcs[3] or sl.chord.pcs[2] or sl.chord.rootPc, root, 31, 52)
          local choices = { fifth, root + 12 <= 52 and root + 12 or root, T.bassNote(sl.chord.pcs[2] or sl.chord.rootPc, root, 31, 52) }
          local ws = { 3, 2, 1 }
          -- By the book, no passing note that makes parallel fifths or
          -- octaves with the tune (if another will do).
          if tune and prevStep then
            local any = false
            local w2 = {}
            for k, q in ipairs(choices) do
              local par = parallelAt(st, q, prevStep, prevP)
              w2[k] = par and 0 or ws[k]
              if not par then any = true end
            end
            if any then ws = w2
            else
              -- (Every one would: the bass holds its note - oblique motion.)
              choices, ws = { prevP, prevP, prevP }, ws
            end
          end
          p = weighted(rnd, choices, ws)
        end
        prevStep, prevP = st, p
        addNote(notes, st, (beats[i + 1] or sl.e) - st, p, st % meter.bar == 0)
      end
    else
      local bars = onPush(sl, barStarts(meter, gridStart(sl), sl.e))
      for i, st in ipairs(bars) do addNote(notes, st, (bars[i + 1] or sl.e) - st, root, st % meter.bar == 0) end
    end
  end
  return notes
end

M.DRUM = { kick = 36, snare = 38, hat = 42, open = 46, crash = 49, tomHi = 50, tomMid = 47, tomLo = 45,
           clap = 39, pedal = 44, ride = 51, bell = 53, tomHiMid = 48, tomFloor = 43, tomFloorLo = 41 }

-- Which beats the snare plays: the backbeat (2 and 4), or the half-time
-- beat 3 when the pace is calm.
local function backbeats(meter, pace)
  local out = {}
  if pace == "Calm" and meter.mid then return { meter.mid } end
  if meter.beats == 1 then return { meter.bar // 2 } end
  if meter.beats == 3 then return { 2 * meter.beat } end
  for b = 1, meter.beats - 1, 2 do out[#out + 1] = b * meter.beat end
  return out
end

------------------------------------------------------------------------------
-- Drums on their own (docs/decisions/0013-drums-are-a-kind-of-idea.md)
--
-- A groove a bar long, made for the beat style from the same pieces 1.0's
-- Measures had for their drums (the kick's metric or Euclidean pattern, the
-- backbeat),
-- played in pairs of bars where the second answers the first with one
-- small change; then fills where the Fills setting asks, each a beat or two
-- of snare, toms, or both (in triplets when the figures are), with a crash
-- on the downbeat it leads to - the top of the idea, for the last one, since
-- a drum idea is made to loop. General MIDI notes throughout, channel 10.
------------------------------------------------------------------------------

local TOMS = { 50, 48, 47, 45, 43, 41 }   -- high to floor

-- The bar of groove: kick, snare and cymbal steps, and what plays them.
local function drumGroove(meter, r, rnd)
  local D = M.DRUM
  local bar, beat = meter.bar, meter.beat
  local style = r.beat
  if style == "Breakbeat" and not (bar == 16 and beat == 4) then style = "Backbeat" end
  local g = { kick = {}, snare = {}, snarePitch = D.snare, open = {}, style = style }
  if style == "Four on the floor" then
    for b = 0, bar - 1, beat do g.kick[#g.kick + 1] = b end
    g.snare = backbeats(meter, "Flowing")
    g.snarePitch = D.clap
    if beat % 2 == 0 then
      for b = 0, bar - 1, beat do g.open[#g.open + 1] = b + beat // 2 end
    end
  elseif style == "Half-time" then
    g.snare = { meter.mid or (meter.beats - 1) * beat }
    local calm = {}
    for k, v in pairs(r) do calm[k] = v end
    calm.pace = "Calm"
    g.kick = M.kickPattern(meter, calm, rnd)
  elseif style == "Breakbeat" then
    g.kick = pickOne(rnd, { { 0, 10 }, { 0, 2, 10 }, { 0, 6, 10 }, { 0, 10, 11 } })
    g.snare = { 4, 12 }
    -- One snare knocked off the backbeat: a sixteenth or an eighth either
    -- side of beat 4, or the "a" of 3.
    if coin(rnd, 0.75) then table.insert(g.snare, pickOne(rnd, { 7, 9, 14, 15 })) end
  else
    g.kick = M.kickPattern(meter, r, rnd)
    g.snare = backbeats(meter, "Flowing")
  end
  -- Dotted and triplet figures fall on the kick - but four on the floor is
  -- four on the floor.
  if style ~= "Four on the floor" then g.kick = M.figure(meter, 0, bar, g.kick, r.figures, rnd) end
  if style ~= "Four on the floor" then
    local onSnare = {}
    for _, x in ipairs(g.snare) do onSnare[x] = true end
    local k = {}
    for _, x in ipairs(g.kick) do if not onSnare[x] then k[#k + 1] = x end end
    g.kick = k
  end
  table.sort(g.snare)

  -- Time: quarters when calm, eighths when flowing, sixteenths when busy (a
  -- breakbeat is sixteenths at any pace but calm); eighths in 6/8 rather
  -- than dotted quarters; in triplets, the shuffle.
  local unit = ({ Calm = beat, Flowing = 2, Busy = 1 })[r.pace] or 2
  if style == "Breakbeat" and r.pace ~= "Calm" then unit = 1 end
  if beat % 4 ~= 0 and r.pace == "Calm" then unit = 2 end
  g.time = {}
  if r.figures == "Triplets" and r.pace ~= "Calm" and beat == 4 then
    for b = 0, bar - 1, 4 do
      g.time[#g.time + 1] = b
      if r.pace == "Busy" then g.time[#g.time + 1] = b + 4 / 3 end
      g.time[#g.time + 1] = b + 8 / 3
    end
  else
    for t = 0, bar - 1, unit do g.time[#g.time + 1] = t end
  end
  g.timePitch = (r.cymbal == "Ride") and D.ride or D.hat
  return g
end

-- A fill over [from, to) of a bar starting at `base`.
local function drumFill(meter, r, rnd, base, from, to)
  local D = M.DRUM
  local out = {}
  local unit = (r.pace == "Calm") and 2 or 1
  local kinds = { "roll", "toms", "snare and toms" }
  if meter.beat == 4 and (r.figures == "Triplets" or r.figures == "Mixed") then kinds[#kinds + 1] = "triplets" end
  local kind = pickOne(rnd, kinds)
  local steps = {}
  if kind == "triplets" then
    for t = from, to - 1e-6, 4 / 3 do steps[#steps + 1] = t end
  else
    for t = from, to - 1, unit do steps[#steps + 1] = t end
  end
  for i, t in ipairs(steps) do
    local pitch
    if kind == "roll" then pitch = D.snare
    elseif kind == "snare and toms" then
      pitch = (i <= #steps // 2) and D.snare or TOMS[math.min(#TOMS, 1 + (i - #steps // 2 - 1) * #TOMS // math.max(1, #steps - #steps // 2))]
    else
      pitch = TOMS[math.min(#TOMS, 1 + (i - 1) * #TOMS // #steps)]
    end
    out[#out + 1] = { step = base + t, len = 1, pitch = pitch, accent = (i == 1) }
  end
  -- The kick under the fill's first note, so it lands with weight.
  out[#out + 1] = { step = base + from, len = 1, pitch = D.kick, accent = true }
  return out, kind
end

function M.drumIdea(meter, r, rnd)
  local D = M.DRUM
  local bar, bars = meter.bar, r.bars
  local g = drumGroove(meter, r, rnd)
  -- The answering bar: one small change, chosen once for the whole idea.
  local change = pickOne(rnd, { "pickup", "double", "open" })

  local fills = {}
  for b = 0, bars - 1 do
    local last = (b == bars - 1)
    if (r.fills == "At the end" and last) or
       (r.fills == "Every 4 bars" and ((b + 1) % 4 == 0 or last)) or
       (r.fills == "Every 2 bars" and ((b + 1) % 2 == 0 or last)) then fills[b] = true end
  end
  local crashes = {}
  for b in pairs(fills) do crashes[(b + 1) % bars] = true end

  local notes, fillKinds = {}, {}
  local total = bars * bar
  -- (An open hat or a crash near the end stops at the end.)
  local function add(step, len, pitch, accent)
    notes[#notes + 1] = { step = step, len = math.min(len, total - step), pitch = pitch, accent = accent or false }
  end
  for b = 0, bars - 1 do
    local base = b * bar
    -- A fill takes a beat - two when busy, or at the end of the idea or a
    -- four-bar phrase when flowing - never the whole bar.
    local fillBeats = (r.pace == "Busy" or (r.pace == "Flowing" and (b == bars - 1 or (b + 1) % 4 == 0))) and 2 or 1
    local fillFrom = fills[b] and math.max(meter.beat, bar - fillBeats * meter.beat) or bar
    local answer = (b % 2 == 1)
    local kick = {}
    for _, k in ipairs(g.kick) do kick[#kick + 1] = k end
    local open = {}
    for _, o in ipairs(g.open) do open[o] = true end
    if answer then
      local snareAt = {}
      for _, x in ipairs(g.snare) do snareAt[x] = true end
      if change == "pickup" and not snareAt[bar - 2] then kick[#kick + 1] = bar - 2
      elseif change == "double" and g.snare[#g.snare] and g.snare[#g.snare] - 1 > 0 then kick[#kick + 1] = g.snare[#g.snare] - 1
      elseif change == "open" then open[bar - 2] = true end
    end
    for _, k in ipairs(kick) do if k < fillFrom then add(base + k, 1, D.kick, k == 0) end end
    for _, x in ipairs(g.snare) do if x < fillFrom then add(base + x, 1, g.snarePitch, true) end end
    for _, t in ipairs(g.time) do
      if t < fillFrom and not (crashes[b] and t == 0) then
        if open[t] and g.timePitch == D.hat then add(base + t, 2, D.open, false)
        else
          local bell = g.timePitch == D.ride and t % meter.beat == 0 and t == 0
          add(base + t, 1, bell and D.bell or g.timePitch, false)
        end
      end
    end
    if g.timePitch == D.ride then
      for _, x in ipairs(g.snare) do if x < fillFrom then add(base + x, 1, D.pedal, false) end end
    end
    if crashes[b] then add(base, 4, D.crash, true) end
    if fills[b] then
      local f, kind = drumFill(meter, r, rnd, base, fillFrom, bar)
      for _, n in ipairs(f) do notes[#notes + 1] = n end
      fillKinds[#fillKinds + 1] = kind
    end
  end
  table.sort(notes, function(a, c)
    if a.step ~= c.step then return a.step < c.step end
    return a.pitch < c.pitch
  end)
  local fillBars = {}
  for b = 0, bars - 1 do if fills[b] then fillBars[#fillBars + 1] = tostring(b + 1) end end
  return notes, { style = g.style, fills = fillBars, fillKinds = fillKinds, change = change }
end

------------------------------------------------------------------------------
-- 7. The idea
------------------------------------------------------------------------------

function M.keyName(key)
  return T.ROOTS[key.root].name .. " " .. T.SCALES[key.scale].name
end

------------------------------------------------------------------------------
-- Swing
--
-- The last thing done to an idea, after every note is placed: each quarter
-- note's grid is stretched so its off-beat eighth lands later - at 100% two
-- thirds of the way through the beat, where a triplet would be - and the
-- sixteenths either side move with it in proportion. Beats themselves never
-- move. Triplet notes are already in threes and are left alone. Only in
-- metres whose beat is a quarter or a half note: 6/8 and 12/8 swing by
-- being in threes, and 7/8 has no quarter notes to swing.
------------------------------------------------------------------------------

function M.swings(meter) return meter.beat % 4 == 0 end

function M.swingWarp(meter, amount)
  amount = tonumber(amount) or 0
  if amount <= 0 or not M.swings(meter) then return nil end
  local d = math.min(amount, 100) / 100 / 6      -- of a beat: 1/6 is triplet swing
  return function(step)
    local q = math.floor(step / 4) * 4
    local f = (step - q) / 4
    if f <= 0.5 then f = f * (0.5 + d) / 0.5
    else f = 0.5 + d + (f - 0.5) * (0.5 - d) / 0.5 end
    return q + f * 4
  end
end

local function whole(x) return math.abs(x - math.floor(x + 0.5)) < 1e-9 end

-- Shaped velocity (1.7): by how strong the beat is - the downbeat loudest,
-- an off-beat or a triplet note softest - and by the part: the chords under
-- the tune (their inner notes under their top), the bass just under it. An
-- accented note (a push, the start of a statement) leans in a little.
M.SHAPE = { [3] = 104, [2.5] = 98, [2] = 94, [1] = 86, [0] = 80 }
M.SHAPE_PART = { Melody = 0, Chords = -10, Bass = -4, Drums = 0 }
M.SHAPE_INNER, M.SHAPE_ACCENT = -4, 6

function M.shapedVelocity(meter, step, part, accent, inner)
  local v = M.SHAPE[M.strength(meter, step)] or 80
  v = v + (M.SHAPE_PART[part] or 0) + (accent and M.SHAPE_ACCENT or 0) + (inner and M.SHAPE_INNER or 0)
  return math.max(1, math.min(127, v))
end

local function toBlockNotes(list, chan, vel, warp, meter, part)
  local out = {}
  -- (The top note of everything struck together, for the inner notes.)
  local top = {}
  if vel == "Shaped" and part == "Chords" then
    for _, n in ipairs(list) do top[n.step] = math.max(top[n.step] or 0, n.pitch) end
  end
  for _, n in ipairs(list) do
    local s, e = n.step, n.step + n.len
    if warp then
      if whole(s) then s = warp(s) end
      if whole(e) then e = warp(e) end
    end
    local v = (vel == "Accents" and n.accent) and M.ACCENT or 100
    if vel == "Shaped" then
      v = M.shapedVelocity(meter, n.step, part, n.accent, top[n.step] and n.pitch < top[n.step])
    end
    out[#out + 1] = { start = s / 4, len = (e - s) / 4, pitch = n.pitch, chan = chan,
                      accent = n.accent, vel = v }
  end
  table.sort(out, function(a, b)
    if a.start ~= b.start then return a.start < b.start end
    if a.pitch ~= b.pitch then return a.pitch < b.pitch end
    return a.len < b.len
  end)
  return out
end

-- The chords as a musician reads them: bar by bar, | C G | Am F |. A chord
-- is shown in the bar its beat is in: pushed an eighth early it is marked
-- ^, pulled an eighth late _, borrowed *.
function M.chordLine(timeline, meter)
  local bars = {}
  for _, sl in ipairs(timeline) do
    local b = beatOf(sl) // meter.bar + 1
    bars[b] = bars[b] or {}
    -- An inverted chord is written over its bass note: C/E.
    local slash = sl.bassPos and ("/" .. T.noteName(sl.key, sl.bassPos)) or ""
    table.insert(bars[b], (sl.pushed and "^" or "") .. (sl.pulled and "_" or "") .. sl.chord.name .. slash ..
                          (sl.borrowed and "*" or "") .. (sl.applied and ">" or ""))
    -- A chord held over bar lines shows in each bar it sounds in, as "-".
    for x = b + 1, (sl.e - 1) // meter.bar + 1 do
      bars[x] = bars[x] or {}
      table.insert(bars[x], "-")
    end
  end
  local out = {}
  for i = 1, #bars do out[#out + 1] = table.concat(bars[i] or {}, " ") end
  return "| " .. table.concat(out, " | ") .. " |"
end

--[[ The idea for these settings, this metre and this number.

     Returns {
       block    = { name, beats, notes, parts = { { name, notes, chan } }, layout },
       r        = the settings with every Any rolled,
       key, plan, timeline, melody (steps and positions, for the tests),
       summary  = a line saying what was rolled,
       chords   = the chord line,
     }
]]
function M.make(st, meter, seed)
  seed = math.floor(tonumber(seed) or st.seed or 1)
  local r = M.resolve(st, seed)
  if r.kind == "Drums" then return M.makeDrums(st, meter, seed, r) end
  local key = T.key(r.root, r.scale)
  -- With no chords to play, the tune still walks over chords - plain triads,
  -- one a bar - so its strong notes outline a harmony. The chord settings
  -- are hidden then, and must not change it.
  if not r.chords then
    r.colour, r.chordPace, r.chordStyle = "Triads", "One a bar", "Block"
    r.flavours, r.voicing, r.inversions = "Off", "Close", "Off"
    r.partWriting = "Free"
  end
  local book = r.partWriting == "By the book"
  local plan = M.plan(r, meter, M.stream(seed, "plan"))
  local colour = r.colour
  local timeline = M.harmony(plan, key, r, meter, M.stream(seed, "harmony"), colour)
  local borrowed = M.borrow(timeline, key, r, M.stream(seed, "borrow"), colour)
  local applied = M.applied(timeline, plan, key, r, M.stream(seed, "applied"), colour)
  M.flavour(timeline, plan, key, r, M.stream(seed, "colour"))
  -- By the book, a half close with Mixed stands on a plain V: "almost
  -- invariably a triad, rather than a seventh chord" (Open Music Theory,
  -- "Classical cadence types"). Sevenths, chosen for sevenths everywhere,
  -- keep theirs.
  if book and colour == "Mixed" then
    for _, u in ipairs(plan.units) do
      if u.cad == "HC" then
        local sl = M.chordAt(timeline, u.start + u.len - 1)
        if sl and #sl.chord.pcs > 3 and not sl.flavour and not sl.borrowed and not sl.applied then
          sl.chord = T.chord(sl.key or key, sl.degree, "Triads")
          sl.halfTriad = true
        end
      end
    end
  end
  M.push(timeline, meter, r, M.stream(seed, "push"))
  M.invert(timeline, plan, key, r, M.stream(seed, "invert"), meter)
  -- The chords part plays from its own copy, pulled late where it is; the
  -- tune, the bass and the drums play on the beat.
  local chordTl = r.chords and M.pull(timeline, meter, r, M.stream(seed, "pull")) or timeline

  local lo, hi = M.melodyRange(key, r.register)
  local ctx = { key = key, meter = meter, lo = lo, hi = hi, timeline = timeline,
                rhythmRnd = M.stream(seed, "rhythm") }
  local contour = CONTOURS[r.contour] or CONTOURS.Arch
  ctx.target = function(step)
    local t = step / math.max(1, plan.total)
    return lo + 1 + contour(t) * (hi - lo - 2)
  end

  -- By the book the tune keeps clear of parallels with the bass each chord
  -- stands on (a Measure's bass on the beat, a Phrase's under its own
  -- chords) - not with a moving bass's passing notes, which keep clear of
  -- the tune themselves: so a different bass still leaves the tune alone.
  if book and r.chords then
    local tl = (r.kind == "Measure") and timeline or chordTl
    ctx.bassPcAt = function(step)
      local sl = M.chordAt(tl, step)
      return sl and bassPcOf(sl)
    end
  end

  local parts = {}
  local melody
  if r.melody then
    melody = M.melody(plan, ctx, r, M.stream(seed, "melody"))
    parts[#parts + 1] = { name = "Melody", list = melody }
  end

  local arpName, lows
  if r.chords then
    -- The chords sit under the tune, so a tune in a low register pushes them
    -- down, but never into the mud below C3.
    local top = 69
    if melody then
      local low = 127
      for _, n in ipairs(melody) do low = math.min(low, n.pitch) end
      top = math.max(57, math.min(69, low - 1))
    end
    local list
    list, arpName, lows = M.chordsPart(ctx, chordTl, r, M.stream(seed, "chords"),
                                 { lo = math.max(43, top - 16), hi = top, bass = r.kind ~= "Measure",
                                   book = book, tune = melody, beatTl = timeline })
    parts[#parts + 1] = { name = "Chords", list = list }
  end

  if r.kind == "Measure" then
    -- No drums in a Measure since 1.3 (drums are their own kind), but a
    -- pulsing bass still plays the pattern a kick drum would, drawn as it
    -- always was so the bass is unchanged.
    local kick = M.kickPattern(meter, r, M.stream(seed, "drums"))
    local bassList = M.bassPart(ctx, timeline, r, M.stream(seed, "bass"), kick, book and melody)
    if book then M.spaceBass(bassList, timeline, lows) end
    parts[#parts + 1] = { name = "Bass", list = bassList }
  end

  -- Channels: in one item each part has its own; on tracks of their own
  -- every part is on 1. (A drum idea, on 10, makes its own block: makeDrums.)
  local oneItem = r.kind ~= "Measure" or r.layout == "One item"
  local warp = M.swingWarp(meter, st.swing)
  local block = { parts = {}, notes = {}, beats = plan.total / 4,
                  layout = (oneItem and "one") or "tracks" }
  for i, p in ipairs(parts) do
    local chan = oneItem and (i - 1) or 0
    local notes = toBlockNotes(p.list, chan, r.velocity, warp, meter, p.name)
    block.parts[#block.parts + 1] = { name = p.name, notes = notes, chan = chan }
    for _, n in ipairs(notes) do block.notes[#block.notes + 1] = n end
  end
  -- Fully ordered: Lua's sort is not stable, and may shuffle notes that
  -- start together differently from one run to the next.
  table.sort(block.notes, function(a, b)
    if a.start ~= b.start then return a.start < b.start end
    if a.chan ~= b.chan then return a.chan < b.chan end
    if a.pitch ~= b.pitch then return a.pitch < b.pitch end
    return a.len < b.len
  end)

  local what = r.kind
  if r.kind == "Phrase" then what = what .. " (" .. r.content:lower() .. ")" end
  if r.kind == "Measure" then what = what .. " (" .. r.form:lower() .. ")" end
  block.name = ("Good Idea %d - %s, %s, %s"):format(seed, what, barsName(r.bars), M.keyName(key))

  local said = { M.keyName(key), r.pace, r.groove }
  if r.melody then said[#said + 1] = r.contour:lower() .. " contour" end
  if r.chords then
    said[#said + 1] = r.colour:lower()
    if r.voicing ~= "Close" then said[#said + 1] = r.voicing:lower() .. " voicing" end
    said[#said + 1] = M.valueName(M.BY_ID.chordPace, r.chordPace)
    said[#said + 1] = r.chordStyle:lower() .. ((r.chordStyle == "Broken" and arpName) and (" (" .. arpName .. ")") or "")
  end
  if r.kind == "Measure" then said[#said + 1] = r.bass:lower() .. " bass" end
  if r.figures ~= "Plain" then said[#said + 1] = r.figures:lower() end
  if r.push ~= "None" then said[#said + 1] = r.push:lower() .. " push" end
  if r.chords and r.pull ~= "None" then said[#said + 1] = r.pull:lower() .. " pull" end
  if warp then said[#said + 1] = math.floor(st.swing) .. "% swing" end

  -- Each borrowed chord, said in full for the window.
  local notes = {}
  for _, sl in ipairs(borrowed) do
    local b = sl.borrowed
    b.bar = (sl.pushed and sl.s + 2 or sl.s) // meter.bar + 1
    b.text = ("%s (%s) in bar %d, from %s"):format(b.name, b.numeral, b.bar, b.from)
    notes[#notes + 1] = b
  end

  -- Each applied chord, said in full for the window.
  local appliedNotes = {}
  for _, sl in ipairs(applied) do
    local a = sl.applied
    -- (Named as the chord after it now is: flavoured or inverted, say.)
    for i, x in ipairs(timeline) do
      if x == sl and timeline[i + 1] then
        local nx = timeline[i + 1]
        a.to = nx.chord.name .. (nx.bassPos and ("/" .. T.noteName(nx.key, nx.bassPos)) or "")
      end
    end
    a.bar = (sl.pushed and sl.s + 2 or sl.s) // meter.bar + 1
    a.text = ("%s (%s) in bar %d, leading to %s"):format(a.name, a.numeral, a.bar, a.to)
    appliedNotes[#appliedNotes + 1] = a
  end

  local cadNames = { PAC = "closes on the tonic", IAC = "closes on the third or fifth",
                     DC = "a deceptive close (V to vi)",
                     HC = "ends on the dominant (open)", open = "ends open, to loop", none = "" }
  return {
    seed = seed, r = r, key = key, plan = plan, timeline = timeline, melody = melody,
    block = block,
    summary = table.concat(said, "  /  "),
    chords = M.chordLine(chordTl, meter),
    chordTimeline = chordTl,
    shape = plan.shape,
    ending = cadNames[plan.ending] or "",
    borrowed = notes,
    applied = appliedNotes,
  }
end

-- A Drums idea: one part, on channel 10, in one item.
function M.makeDrums(st, meter, seed, r)
  local total = r.bars * meter.bar
  local list, info = M.drumIdea(meter, r, M.stream(seed, "kit"))
  local notes = toBlockNotes(list, 9, r.velocity, M.swingWarp(meter, st.swing), meter, "Drums")
  local block = { parts = { { name = "Drums", notes = notes, chan = 9, drums = true } },
                  notes = {}, beats = total / 4, layout = "one" }
  for i, n in ipairs(notes) do block.notes[i] = n end
  local style = info.style:lower()
  block.name = ("Good Idea %d - Drums (%s), %s"):format(seed, style, barsName(r.bars))
  local said = { info.style, r.cymbal == "Ride" and "ride" or "hi-hats", r.pace, r.groove }
  if r.figures ~= "Plain" then said[#said + 1] = r.figures:lower() end
  if M.swingWarp(meter, st.swing) then said[#said + 1] = math.floor(st.swing) .. "% swing" end
  local fills = (#info.fills == 0) and "no fills"
                or ((#info.fills == 1 and "a fill in bar " or "fills in bars ") .. table.concat(info.fills, ", "))
  return {
    seed = seed, r = r, key = T.key(1, 1), meter = meter,
    plan = { units = {}, total = total, shape = "", ending = "" },
    timeline = {}, chordTimeline = {}, melody = nil,
    block = block,
    summary = table.concat(said, "  /  "),
    chords = "",
    shape = "",
    ending = fills,
    borrowed = {},
    drums = info,
  }
end

-- The settings that would give this idea back with nothing left to chance:
-- every Any on screen replaced by what it rolled. A hidden setting does not
-- change the idea, and is left alone so it is still Any when it shows again.
function M.keep(st, idea)
  for id in pairs(idea.r.rolled) do
    local s = M.BY_ID[id]
    if s and st[id] == "Any" and M.shows(s, st) then st[id] = idea.r[id] end
  end
  return st
end

return M
