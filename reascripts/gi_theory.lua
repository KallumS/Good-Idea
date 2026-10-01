--[[ Good Idea - keys, chords and the order chords come in.

     Pure Lua. Nothing in this file touches REAPER or ImGui: the harmony is the
     part that has to be right, and here it can be run and checked by
     tests/test_theory.lua rather than only by reading.

     Two ways of naming a note run through the whole engine:

       - a MIDI pitch, 0..127;
       - a scale position, an integer counting scale notes from the key's root
         in MIDI octave -1. Position 0 is the root at pitch 0..11, position n
         (the scale's length) is the root an octave up, and so on.

     Every diatonic move is integer arithmetic on positions - a third above is
     +2, whatever the scale - and pitches only appear at the edges. Scale
     degrees are 0-based: degree 0 is the tonic.

     The keys, positions and spelling are Midi Catalogue's (and so ScaleView's
     and Starting Blocks'), copied unchanged. The chord table is Starting
     Blocks', copied unchanged and used here only to name chords. What is new
     is at the bottom: chords built on a degree, and the walk that decides
     which chord follows which.
]]

local M = {}

------------------------------------------------------------------------------
-- Keys
--
-- ScaleView for REAPER's roots and scales, unchanged, the same tables Starting
-- Blocks copies, so all three apps agree on what a scale is and what to call
-- its notes. test_theory.lua asserts they still match. Do not tidy them
-- independently.
------------------------------------------------------------------------------

local LETTER_PC  = { 0, 2, 4, 5, 7, 9, 11 }        -- C D E F G A B
local LETTERS    = { "C", "D", "E", "F", "G", "A", "B" }
local ACCIDENTAL = { [-2] = "bb", [-1] = "b", [0] = "", [1] = "#", [2] = "x" }

M.ROOTS = {
  { name = "C",  letter = 0, acc =  0 }, { name = "C#", letter = 0, acc =  1 },
  { name = "Db", letter = 1, acc = -1 }, { name = "D",  letter = 1, acc =  0 },
  { name = "D#", letter = 1, acc =  1 }, { name = "Eb", letter = 2, acc = -1 },
  { name = "E",  letter = 2, acc =  0 }, { name = "F",  letter = 3, acc =  0 },
  { name = "F#", letter = 3, acc =  1 }, { name = "Gb", letter = 4, acc = -1 },
  { name = "G",  letter = 4, acc =  0 }, { name = "G#", letter = 4, acc =  1 },
  { name = "Ab", letter = 5, acc = -1 }, { name = "A",  letter = 5, acc =  0 },
  { name = "A#", letter = 5, acc =  1 }, { name = "Bb", letter = 6, acc = -1 },
  { name = "B",  letter = 6, acc =  0 }, { name = "Cb", letter = 0, acc = -1 },
}

M.SCALES = {
  { name = "Major",      iv = {0,2,4,5,7,9,11},   letters = {0,1,2,3,4,5,6} },
  { name = "Minor",      iv = {0,2,3,5,7,8,10},   letters = {0,1,2,3,4,5,6} },
  { name = "Harm Minor", iv = {0,2,3,5,7,8,11},   letters = {0,1,2,3,4,5,6} },
  { name = "Ionian",     iv = {0,2,4,5,7,9,11},   letters = {0,1,2,3,4,5,6} },
  { name = "Dorian",     iv = {0,2,3,5,7,9,10},   letters = {0,1,2,3,4,5,6} },
  { name = "Phrygian",   iv = {0,1,3,5,7,8,10},   letters = {0,1,2,3,4,5,6} },
  { name = "Lydian",     iv = {0,2,4,6,7,9,11},   letters = {0,1,2,3,4,5,6} },
  { name = "Mixolydian", iv = {0,2,4,5,7,9,10},   letters = {0,1,2,3,4,5,6} },
  { name = "Aeolian",    iv = {0,2,3,5,7,8,10},   letters = {0,1,2,3,4,5,6} },
  { name = "Maj Pent",   iv = {0,2,4,7,9},        letters = {0,1,2,4,5} },
  { name = "Min Pent",   iv = {0,3,5,7,10},       letters = {0,2,3,4,6} },
  { name = "Maj Blues",  iv = {0,2,3,4,7,9},      letters = {0,1,2,2,4,5} },
  { name = "Min Blues",  iv = {0,3,5,6,7,10},     letters = {0,2,3,4,4,6} },
  { name = "Whole Tone", iv = {0,2,4,6,8,10},     letters = {0,1,2,3,4,5} },
  { name = "Dim W-H",    iv = {0,2,3,5,6,8,9,11}, letters = {0,1,2,3,4,5,5,6} },
  { name = "Dim H-W",    iv = {0,1,3,4,6,7,9,10}, letters = {0,1,2,2,3,4,5,6} },
}

local NUMERALS = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII" }

-- A key is the pair of indices the window picks. A chord scale (M.chordKey)
-- is a key that also carries its own intervals: the same scale with a note
-- or two bent to the chord sounding over it.
function M.key(root, scale) return { root = root or 1, scale = scale or 1 } end

local function ivOf(key) return key.iv or M.SCALES[key.scale].iv end
M.ivOf = ivOf

function M.scaleLen(key) return #ivOf(key) end

function M.rootPc(key)
  local rt = M.ROOTS[key.root]
  return (LETTER_PC[rt.letter + 1] + rt.acc + 12) % 12
end

------------------------------------------------------------------------------
-- Positions and pitches
------------------------------------------------------------------------------

-- The MIDI pitch of a scale position.
function M.pitch(key, pos)
  local iv  = ivOf(key)
  local n   = #iv
  local oct = math.floor(pos / n)
  local k   = pos - oct * n
  return M.rootPc(key) + iv[k + 1] + 12 * oct
end

-- The highest position at or below a pitch. Every pitch has one, because the
-- root is in every octave.
function M.floorPos(key, midi)
  local iv   = ivOf(key)
  local n    = #iv
  local root = M.rootPc(key)
  local oct  = math.floor((midi - root) / 12)
  local kmax = 0
  for k = 1, n do
    if root + iv[k] + 12 * oct <= midi then kmax = k - 1 end
  end
  return oct * n + kmax
end

-- The position of a pitch that is in the scale, or nil for one that is not.
function M.posOf(key, midi)
  local s = M.floorPos(key, midi)
  if M.pitch(key, s) == midi then return s end
  return nil
end

-- The nearest position to any pitch. A pitch exactly between two scale notes
-- goes the way `lean` says (+1 up, -1 down), and down when it says nothing.
function M.nearestPos(key, midi, lean)
  local lo = M.floorPos(key, midi)
  if M.pitch(key, lo) == midi then return lo end
  local dLo = midi - M.pitch(key, lo)
  local dHi = M.pitch(key, lo + 1) - midi
  if dLo < dHi then return lo end
  if dHi < dLo then return lo + 1 end
  return (lean or -1) > 0 and lo + 1 or lo
end

function M.pc(key, pos) return M.pitch(key, pos) % 12 end

-- Spelled for the key: the seventh of F# major comes out E#, not F.
function M.noteName(key, pos)
  local sc  = M.SCALES[key.scale]
  local n   = #ivOf(key)
  local oct = math.floor(pos / n)
  local k   = pos - oct * n
  local letter = (M.ROOTS[key.root].letter + sc.letters[k + 1]) % 7
  local acc = M.pitch(key, pos) % 12 - LETTER_PC[letter + 1]
  if acc >  6 then acc = acc - 12 end
  if acc < -6 then acc = acc + 12 end
  return LETTERS[letter + 1] .. (ACCIDENTAL[acc] or "?")
end

-- A pitch named with its octave, C4 being middle C (60). Out of the key, the
-- sharp spelling.
local SHARP_NAMES = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
function M.pitchName(midi, key)
  local oct = math.floor(midi / 12) - 1
  if key then
    local s = M.posOf(key, midi)
    if s then return M.noteName(key, s) .. oct end
  end
  return SHARP_NAMES[midi % 12 + 1] .. oct
end

------------------------------------------------------------------------------
-- Degrees
------------------------------------------------------------------------------

-- Read off the scale rather than assumed, so the modes and the blues scales
-- come out right: the vii of major is diminished, the III of minor is major.
function M.degreeQuality(key, degree)
  local p  = M.pitch(key, degree)
  local r3 = M.pitch(key, degree + 2) - p
  local r5 = M.pitch(key, degree + 4) - p
  if r3 == 4 and r5 == 7 then return "major"      end
  if r3 == 3 and r5 == 7 then return "minor"      end
  if r3 == 3 and r5 == 6 then return "diminished" end
  if r3 == 4 and r5 == 8 then return "augmented"  end
  return "other"
end

function M.degreeNumeral(key, degree, ascii)
  local q = M.degreeQuality(key, degree)
  local n = NUMERALS[(degree % 8) + 1]
  if q == "minor" or q == "diminished" then n = n:lower() end
  if q == "diminished" then n = n .. (ascii and "dim" or "\u{00B0}") end
  if q == "augmented"  then n = n .. (ascii and "aug" or "+") end
  return n
end

M.DEGREE_TITLES = { "Tonic", "Supertonic", "Mediant", "Subdominant",
                    "Dominant", "Submediant", "Leading Tone" }

-- Starting Blocks' degree names. Only the seven-note scales carry them, and
-- the seventh is a leading tone only when it leans on the tonic a semitone up.
function M.degreeTitle(key, degree)
  if M.scaleLen(key) ~= 7 then return "Degree " .. (degree + 1) end
  if degree == 6 and M.pitch(key, 7) - M.pitch(key, 6) ~= 1 then return "Subtonic" end
  return M.DEGREE_TITLES[degree + 1] or ("Degree " .. (degree + 1))
end

-- The seventh degree leans on the tonic only when it sits a semitone under
-- it. Only then is it a leading tone, and only then does it want resolving
-- and not doubling.
function M.leadingTonePc(key)
  local n = M.scaleLen(key)
  if n ~= 7 then return nil end
  if M.pitch(key, 7) - M.pitch(key, 6) == 1 then return M.pc(key, 6) end
  return nil
end

------------------------------------------------------------------------------
-- Chords
--
-- Starting Blocks' chord tables, copied unchanged: one row per chord carrying
-- its own name, symbol and intervals (semitones from the chord's root), in
-- the families of Wikipedia's list of chords. Here they only name what the
-- scale builds (Good Idea's chords are always in key). Do not tidy them
-- independently of Starting Blocks.
------------------------------------------------------------------------------

M.FAMILIES = { "Diatonic", "Triads", "6ths & 7ths", "Extended", "Altered",
               "Sus & Add", "Quartal", "Named" }

local TR, S7, EX, AL, SA, QU, NA = 2, 3, 4, 5, 6, 7, 8   -- indices into FAMILIES

M.CHORDS = {
  { sym="maj",  name="Major",                  iv={0,4,7},          fam=TR },
  { sym="m",    name="Minor",                  iv={0,3,7},          fam=TR },
  { sym="dim",  name="Diminished",             iv={0,3,6},          fam=TR },
  { sym="aug",  name="Augmented",              iv={0,4,8},          fam=TR },
  { sym="b5",   name="Flat Five",              iv={0,4,6},          fam=TR },
  { sym="5",    name="Fifth (Power)",          iv={0,7},            fam=TR },

  { sym="6",       name="Sixth",                    iv={0,4,7,9},     fam=S7 },
  { sym="m6",      name="Minor Sixth",              iv={0,3,7,9},     fam=S7 },
  { sym="6/9",     name="Six-Nine",                 iv={0,4,7,9,14},  fam=S7 },
  { sym="m6/9",    name="Minor Six-Nine",           iv={0,3,7,9,14},  fam=S7 },
  { sym="7",       name="Dominant Seventh",         iv={0,4,7,10},    fam=S7 },
  { sym="maj7",    name="Major Seventh",            iv={0,4,7,11},    fam=S7 },
  { sym="m7",      name="Minor Seventh",            iv={0,3,7,10},    fam=S7 },
  { sym="mMaj7",   name="Minor-Major Seventh",      iv={0,3,7,11},    fam=S7 },
  { sym="m7b5",    name="Half-Diminished Seventh",  iv={0,3,6,10},    fam=S7 },
  { sym="dim7",    name="Diminished Seventh",       iv={0,3,6,9},     fam=S7 },
  { sym="7#5",     name="Augmented Seventh",        iv={0,4,8,10},    fam=S7 },
  { sym="maj7#5",  name="Augmented Major Seventh",  iv={0,4,8,11},    fam=S7 },
  { sym="7b5",     name="Seventh Flat Five",        iv={0,4,6,10},    fam=S7 },
  { sym="dimMaj7", name="Diminished Major Seventh", iv={0,3,6,11},    fam=S7 },
  { sym="7/6",     name="Seven Six",                iv={0,4,7,9,10},  fam=S7 },

  { sym="9",     name="Ninth",               iv={0,4,7,10,14},       fam=EX },
  { sym="maj9",  name="Major Ninth",         iv={0,4,7,11,14},       fam=EX },
  { sym="m9",    name="Minor Ninth",         iv={0,3,7,10,14},       fam=EX },
  { sym="mMaj9", name="Minor-Major Ninth",   iv={0,3,7,11,14},       fam=EX },
  { sym="11",    name="Eleventh",            iv={0,4,7,10,14,17},    fam=EX },
  { sym="maj11", name="Major Eleventh",      iv={0,4,7,11,14,17},    fam=EX },
  { sym="m11",   name="Minor Eleventh",      iv={0,3,7,10,14,17},    fam=EX },
  { sym="13",    name="Thirteenth",          iv={0,4,7,10,14,17,21}, fam=EX },
  { sym="maj13", name="Major Thirteenth",    iv={0,4,7,11,14,17,21}, fam=EX },
  { sym="m13",   name="Minor Thirteenth",    iv={0,3,7,10,14,17,21}, fam=EX },

  { sym="7b9",       name="Seventh Flat Nine",             iv={0,4,7,10,13},    fam=AL },
  { sym="7#9",       name="Seventh Sharp Nine",            iv={0,4,7,10,15},    fam=AL },
  { sym="7#11",      name="Seventh Sharp Eleven",          iv={0,4,7,10,18},    fam=AL },
  { sym="7b13",      name="Seventh Flat Thirteen",         iv={0,4,7,10,20},    fam=AL },
  { sym="7#5b9",     name="Seventh Sharp Five Flat Nine",  iv={0,4,8,10,13},    fam=AL },
  { sym="7#5#9",     name="Seventh Sharp Five Sharp Nine", iv={0,4,8,10,15},    fam=AL },
  { sym="7b5b9",     name="Seventh Flat Five Flat Nine",   iv={0,4,6,10,13},    fam=AL },
  { sym="7alt",      name="Altered Dominant",              iv={0,4,8,10,13,15}, fam=AL },
  { sym="13b9",      name="Thirteenth Flat Nine",          iv={0,4,7,10,13,21}, fam=AL },
  { sym="maj7#11",   name="Major Seventh Sharp Eleven",    iv={0,4,7,11,18},    fam=AL },
  { sym="m9b5",      name="Minor Ninth Flat Five",         iv={0,3,6,10,14},    fam=AL },
  { sym="9#5",       name="Ninth Augmented Fifth",         iv={0,4,8,10,14},    fam=AL },
  { sym="9b5",       name="Ninth Flat Fifth",              iv={0,4,6,10,14},    fam=AL },
  { sym="9#11",      name="Augmented Eleventh",            iv={0,4,7,10,14,18}, fam=AL },
  { sym="maj7#5#11", name="Augmented Major Seventh Sharp Eleven", iv={0,4,8,11,18}, fam=AL },
  { sym="13b9b5",    name="Thirteenth Flat Nine Flat Five", iv={0,4,6,10,13,21}, fam=AL },

  { sym="sus2",     name="Suspended Second",             iv={0,2,7},       fam=SA },
  { sym="sus4",     name="Suspended Fourth",             iv={0,5,7},       fam=SA },
  { sym="7sus4",    name="Seventh Suspended Fourth",     iv={0,5,7,10},    fam=SA },
  { sym="9sus4",    name="Ninth Suspended Fourth",       iv={0,5,7,10,14}, fam=SA },
  { sym="maj7sus4", name="Major Seventh Suspended Fourth", iv={0,5,7,11},  fam=SA },
  { sym="add9",     name="Added Ninth",                  iv={0,4,7,14},    fam=SA },
  { sym="m(add9)",  name="Minor Added Ninth",            iv={0,3,7,14},    fam=SA },
  { sym="add4",     name="Added Fourth",                 iv={0,4,5,7},     fam=SA },
  { sym="add11",    name="Added Eleventh",               iv={0,4,7,17},    fam=SA },
  { sym="add13",    name="Added Thirteenth",             iv={0,4,7,21},    fam=SA },
  { sym="add2",     name="Added Second",                 iv={0,2,4,7},     fam=SA },
  { sym="m(add2)",  name="Minor Added Second",           iv={0,2,3,7},     fam=SA },

  { sym="Q4/3",    name="Quartal Triad",       iv={0,5,10},    fam=QU },
  { sym="Q4/4",    name="Quartal Tetrad",      iv={0,5,10,15}, fam=QU },
  { sym="Q5/3",    name="Quintal Triad",       iv={0,7,14},    fam=QU },
  { sym="WT3",     name="Whole-Tone Trichord", iv={0,2,4},     fam=QU },
  { sym="cluster", name="Chromatic Cluster",   iv={0,1,2},     fam=QU },
  { sym="dia-cl",  name="Diatonic Cluster",    iv={0,2,4,5},   fam=QU },

  -- Voiced as they stand rather than reduced to a pitch-class set: the list
  -- gives the Tristan chord as 0 3 6 10, which makes it a half-diminished
  -- seventh and indistinguishable from one.
  { sym="Mystic",    name="Mystic (Scriabin)",   iv={0,6,10,16,21,26}, fam=NA },
  { sym="Petrushka", name="Petrushka",           iv={0,4,6,7,10,13},   fam=NA },
  { sym="Tristan",   name="Tristan",             iv={0,6,10,15},       fam=NA },
  { sym="So What",   name="So What",             iv={0,5,10,15,19},    fam=NA },
  { sym="Dream",     name="Dream",               iv={0,5,6,7},         fam=NA },
  { sym="Vienna",    name="Viennese Trichord",   iv={0,1,6},           fam=NA },
  { sym="Vienna II", name="Viennese Trichord II", iv={0,6,7},          fam=NA },
  { sym="Napoleon",  name="Ode-to-Napoleon",     iv={0,1,4,5,8,9},     fam=NA },
  { sym="Elektra",   name="Elektra",             iv={0,7,9,13,16},     fam=NA },
  { sym="Farben",    name="Farben",              iv={0,8,11,16,21},    fam=NA },
  { sym="It+6",      name="Italian Sixth",       iv={0,4,10},          fam=NA },
  { sym="Fr+6",      name="French Sixth",        iv={0,4,6,10},        fam=NA },
  { sym="Ger+6",     name="German Sixth",        iv={0,4,7,10},        fam=NA },
}



-- The symbol a set of pitch classes goes by, read off the chord tables: the
-- first chord whose notes are exactly these, from this root. "" for a major
-- triad, nil for a set with no name here.
function M.symbolOf(pcs, root)
  local want = {}
  for _, pc in ipairs(pcs) do want[(pc - root) % 12] = true end
  local n = 0
  for _ in pairs(want) do n = n + 1 end
  for _, c in ipairs(M.CHORDS) do
    local have, m = {}, 0
    for _, iv in ipairs(c.iv) do
      if not have[iv % 12] then have[iv % 12] = true; m = m + 1 end
    end
    if m == n then
      local same = true
      for k in pairs(want) do if not have[k] then same = false end end
      if same then return (c.sym == "maj") and "" or c.sym end
    end
  end
  return nil
end

------------------------------------------------------------------------------
-- Chords on a degree
--
-- Stacked from the scale itself - every other scale note up from the degree -
-- so a chord is always in key, in any of the sixteen scales. A chord carries
-- its positions (for the melody, which works in positions), its pitch
-- classes root first (for voicing), and a set of them (`has`, for asking
-- "is this note on the chord?").
------------------------------------------------------------------------------

M.COLOURS = { "Triads", "Sevenths", "Mixed" }

local function norm(key, degree)
  local n = M.scaleLen(key)
  return ((degree % n) + n) % n
end
M.normDegree = norm

-- The interval, in semitones, from the tonic up to a degree's root.
function M.rootAbove(key, degree)
  return (M.pc(key, norm(key, degree)) - M.pc(key, 0)) % 12
end

-- Which of tonic, subdominant and dominant a degree belongs to, read off its
-- root's distance from the tonic rather than its number, so it means the same
-- in every scale: the tonic and the chords a third either side of it (iii,
-- vi) are T; the second and fourth are S; the fifth and the seventh are D.
function M.functionOf(key, degree)
  local up = M.rootAbove(key, degree)
  if up == 0 or up == 3 or up == 4 or up == 8 or up == 9 then return "T" end
  if up == 1 or up == 2 or up == 5 or up == 6 then return "S" end
  return "D"
end

-- The scale steps above a degree that sound `semis` semitones above it, the
-- first of the candidates the scale has, or nil.
local function stepFor(key, degree, cands)
  local n = M.scaleLen(key)
  for _, semis in ipairs(cands) do
    for o = 1, n do
      if M.pitch(key, degree + o) - M.pitch(key, degree) == semis then return o end
    end
  end
end

-- The scale steps above the degree that make the chord.
--
-- In a seven-note scale, every other note: the textbook stack. A scale of
-- another length stacks into nonsense that way (every other note of C major
-- pentatonic is C E A), so there the chord is built by ear: a third if the
-- scale has one, else a sus chord, then a fifth if it has one.
--
-- Mixed is how a player colours a progression: a seventh where it pulls (ii,
-- V, vii, VII), an added ninth on the other major and minor chords, a plain
-- triad elsewhere.
function M.chordShape(key, degree, colour)
  local wantSeventh = colour == "Sevenths"
  local wantNinth = false
  if colour == "Mixed" then
    local q = M.degreeQuality(key, norm(key, degree))
    local up = M.rootAbove(key, degree)
    if up == 2 or up == 7 or up == 10 or up == 11 then wantSeventh = true
    elseif q == "major" or q == "minor" then wantNinth = true end
  end

  local out
  if M.scaleLen(key) == 7 then
    out = { 0, 2, 4 }
    if wantSeventh then out[4] = 6 end
  else
    out = { 0 }
    local third = stepFor(key, degree, { 4, 3 })
    local semis = third and (M.pitch(key, degree + third) - M.pitch(key, degree))
    third = third or stepFor(key, degree, { 5, 2 })
    -- A sharp fifth only over a major third (an augmented chord); over a
    -- minor third it would be a major chord upside down.
    local fifth = stepFor(key, degree, (semis == 4 and { 7, 8, 6 }) or (semis == 3 and { 7, 6 }) or { 7 })
    if third then out[#out + 1] = third end
    if fifth and fifth ~= third then out[#out + 1] = fifth end
    if wantSeventh then
      local sev = stepFor(key, degree, { 10, 11 })
      if sev then out[#out + 1] = sev end
    end
  end
  -- Only a whole-tone ninth is added: the flat ninth over iii is a clash.
  if wantNinth then
    local nine = stepFor(key, degree, { 2 })
    if nine then out[#out + 1] = nine + M.scaleLen(key) end
  end
  return out
end

function M.chord(key, degree, colour)
  local d = norm(key, degree)
  local ch = { degree = d, pos = {}, pcs = {}, has = {}, colour = colour or "Triads" }
  for i, o in ipairs(M.chordShape(key, d, colour)) do
    ch.pos[i] = d + o
    ch.pcs[i] = M.pc(key, d + o)
    ch.has[ch.pcs[i]] = true
  end
  ch.rootPc = ch.pcs[1]
  ch.quality = M.degreeQuality(key, d)
  ch.name = M.chordName(key, ch)
  ch.numeral = M.degreeNumeral(key, d)
  return ch
end

-- Named the way a player writes it: Am7, G, Bdim, Fadd9. A stack the chord
-- table has no name for (some of the blues and pentatonic stacks) is spelled
-- out instead.
function M.chordName(key, ch)
  local root = M.noteName(key, ch.degree)
  local sym = M.symbolOf(ch.pcs, ch.rootPc)
  if sym then return root .. sym end
  -- A third and no fifth: what the pentatonic and blues scales give where
  -- they have no fifth above a note.
  if #ch.pcs == 2 then
    local third = (ch.pcs[2] - ch.pcs[1]) % 12
    if third == 3 then return root .. "m(no5)" end
    if third == 4 then return root .. "(no5)" end
  end
  local names = {}
  for _, p in ipairs(ch.pos) do names[#names + 1] = M.noteName(key, p) end
  return root .. "(" .. table.concat(names, " ") .. ")"
end

-- Does a scale position sound a note of the chord?
function M.onChord(key, ch, pos) return ch.has[M.pc(key, pos)] == true end

------------------------------------------------------------------------------
-- Which chord follows which
--
-- Harmony moves tonic -> subdominant -> dominant -> tonic (Open Music
-- Theory's "idealised phrase"), and the weights below are that cycle written
-- out chord by chord: from I anywhere, ii mostly to V, V mostly home or to vi
-- (the deceptive move), vi on to ii or IV. A progression is a walk through
-- this table, drawn by the idea's dice. The degrees are read by their root's
-- distance from the tonic (`rootAbove`), so the same table serves every
-- seven-note scale: in minor the V is a minor v and the VII a major VII, and
-- the walk still makes sense.
--
-- Scales of other lengths (pentatonic, blues, whole tone, diminished) have no
-- "ii" or "V" to speak of, so their chords move by root motion instead: down
-- a fifth strongest, then by step, then by third.
------------------------------------------------------------------------------

-- Indexed by semitones above the tonic, from and to.
local MOVES = {
  [0]  = { [2] = 2,   [3] = 0.6, [4] = 0.6, [5] = 3,   [7] = 2.5, [8] = 2,   [9] = 2.5,
           [10] = 1,  [11] = 0.3, [1] = 0.6 },
  [1]  = { [0] = 3,   [7] = 1,   [5] = 1,   [10] = 1 },                       -- bII: home (Phrygian)
  [2]  = { [7] = 4,   [11] = 1,  [5] = 0.8, [0] = 0.4, [9] = 0.4, [10] = 0.6 }, -- ii: to V
  [3]  = { [8] = 2,   [5] = 2,   [10] = 2,  [2] = 0.8, [0] = 0.5 },            -- bIII
  [4]  = { [9] = 3,   [5] = 2,   [2] = 0.8, [0] = 0.3 },                       -- iii: to vi
  [5]  = { [7] = 3,   [0] = 2,   [2] = 1.2, [9] = 0.8, [11] = 0.4, [10] = 1, [4] = 0.3, [3] = 0.3 }, -- IV
  [6]  = { [7] = 3,   [0] = 1 },
  [7]  = { [0] = 5,   [9] = 2,   [8] = 1.5, [5] = 0.8, [4] = 0.2, [3] = 0.4 }, -- V: home, or deceptive
  [8]  = { [10] = 2.5, [5] = 2,  [2] = 1.5, [7] = 1.2, [0] = 1, [3] = 1 },    -- bVI
  [9]  = { [2] = 2,   [5] = 3,   [7] = 1.2, [4] = 0.6, [0] = 0.6 },            -- vi: to ii or IV
  [10] = { [0] = 3,   [3] = 1.5, [8] = 1,   [5] = 1 },                         -- bVII: home, or III
  [11] = { [0] = 4,   [4] = 1,   [9] = 0.5 },                                  -- vii: home
}

local ROOT_MOTION = { [5] = 3, [7] = 2, [2] = 1.5, [10] = 1.5, [3] = 1.2, [4] = 1.2,
                      [8] = 1.2, [9] = 1.2, [1] = 0.6, [11] = 0.6, [6] = 0.2 }

-- Diminished and augmented chords are colour, not furniture: they are
-- allowed, but drawn a quarter as often.
local function qualityFactor(key, degree)
  local q = M.degreeQuality(key, norm(key, degree))
  if q == "diminished" or q == "augmented" then return 0.25 end
  return 1
end

function M.moveWeight(key, from, to)
  from, to = norm(key, from), norm(key, to)
  if from == to then return 0 end
  local w
  if M.scaleLen(key) == 7 then
    w = (MOVES[M.rootAbove(key, from)] or {})[M.rootAbove(key, to)] or 0
  else
    w = ROOT_MOTION[(M.pc(key, to) - M.pc(key, from)) % 12] or 0
  end
  return w * qualityFactor(key, to)
end

-- The chords that can lead home at a cadence, with how strongly. V with a
-- leading tone is the strongest; where the scale has none (minor, the modes)
-- the subtonic VII, the minor v and, in Phrygian, the bII take its place - the
-- cadences those scales are known for. IV is the plagal "amen" in any scale,
-- but a half cadence rests on a dominant, so `half` leaves it out.
local CADENCE = { [7] = 3, [11] = 0.6, [10] = 2, [1] = 2.5, [5] = 1 }

function M.cadenceChords(key, half)
  local out = {}
  for d = 1, M.scaleLen(key) - 1 do
    local w = CADENCE[M.rootAbove(key, d)]
    if half and M.rootAbove(key, d) == 5 then w = nil end
    if w then
      local q = M.degreeQuality(key, d)
      if M.rootAbove(key, d) == 7 and q ~= "major" then w = 2 end   -- v, not V
      if M.rootAbove(key, d) == 1 and q ~= "major" then w = 0 end   -- only a major bII
      if q == "diminished" or q == "augmented" then w = w * 0.25 end
      if w > 0 then out[#out + 1] = { degree = d, weight = w } end
    end
  end
  if #out == 0 and half then return M.cadenceChords(key, false) end
  if #out == 0 then
    -- A scale with nothing a fourth, fifth or step from the tonic: whatever
    -- moves home most strongly.
    for d = 1, M.scaleLen(key) - 1 do
      out[#out + 1] = { degree = d, weight = math.max(0.1, M.moveWeight(key, d, 0)) }
    end
  end
  return out
end

-- One of `items` in proportion to `weight(item)`.
local function draw(rnd, items, weight)
  local total = 0
  for _, it in ipairs(items) do total = total + weight(it) end
  if total <= 0 then return nil end
  local x = rnd() * total
  for _, it in ipairs(items) do
    x = x - weight(it)
    if x < 0 then return it end
  end
  return items[#items]
end
M.draw = draw

-- The next chord after `from`, drawn from the table.
function M.nextDegree(key, from, rnd)
  local ds = {}
  for d = 0, M.scaleLen(key) - 1 do ds[#ds + 1] = d end
  return draw(rnd, ds, function(d) return M.moveWeight(key, from, d) end)
      or norm(key, from + 3)
end

local function rowMax(key, from)
  local m = 0
  for d = 0, M.scaleLen(key) - 1 do m = math.max(m, M.moveWeight(key, from, d)) end
  return m
end

--[[ A progression of `n` chords, as degrees.

     opts.start    the first chord (default the tonic)
     opts.cadence  how it ends:
                     "PAC", "IAC"  a cadence chord, then the tonic
                     "HC"          on a cadence chord (a half cadence)
                     "open"        on anything but the tonic that leads back
                                   to opts.loopTo (default the first chord),
                                   so the progression can go round again
                     "none"        wherever the walk ends
     rnd           the dice

     The walk is drawn forward from the start; where it has to meet a fixed
     ending, the join is accepted in proportion to how likely the table says
     it is, and the walk is drawn again if not. So the ending is fixed but the
     way into it is as likely as the table makes it.
]]
function M.progression(key, n, opts, rnd)
  opts = opts or {}
  if n <= 0 then return {} end
  local start = norm(key, opts.start or 0)
  local cad = opts.cadence or "none"
  local tail = {}
  if cad == "PAC" or cad == "IAC" then
    if n == 1 then return { 0 } end
    local c = draw(rnd, M.cadenceChords(key), function(x) return x.weight end)
    tail = { c.degree, 0 }
  elseif cad == "HC" then
    local c = draw(rnd, M.cadenceChords(key, true), function(x) return x.weight end)
    tail = { c.degree }
  end
  if n <= #tail then
    local out = {}
    for i = #tail - n + 1, #tail do out[#out + 1] = tail[i] end
    return out
  end

  local free = n - #tail
  local loopTo = norm(key, opts.loopTo or start)
  local function join(last)
    if #tail > 0 then return M.moveWeight(key, last, tail[1]) end
    if cad == "open" and n > 1 then return (last ~= 0) and M.moveWeight(key, last, loopTo) or 0 end
    return 1
  end
  for _ = 1, 80 do
    local seq = { start }
    for i = 2, free do seq[i] = M.nextDegree(key, seq[i - 1], rnd) end
    local w = join(seq[free])
    if w > 0 and (#tail == 0 and cad ~= "open" or rnd() * rowMax(key, seq[free]) < w) then
      for _, d in ipairs(tail) do seq[#seq + 1] = d end
      return seq
    end
  end
  -- The dice could not reach the ending from here in eighty draws (a short
  -- span, an awkward start): take the likeliest way there instead, trying
  -- the other cadence chords if this one cannot be reached at all.
  local tries = { tail[1] or false }
  if #tail > 0 then
    for _, c in ipairs(M.cadenceChords(key, cad == "HC")) do
      if c.degree ~= tail[1] then tries[#tries + 1] = c.degree end
    end
  end
  -- An open ending that cannot lead back to where it started (nothing in
  -- the table moves to a diminished chord) settles for not ending at home.
  local joins = { join }
  if cad == "open" and n > 1 then joins[2] = function(last) return last ~= 0 and 1 or 0 end end
  -- And if the start itself cannot get there (it is the only cadence chord
  -- of a small scale), the ending matters more than the start.
  for _, from in ipairs({ start, false }) do
    for _, j in ipairs(joins) do
      for _, first in ipairs(tries) do
        if #tail > 0 then tail[1] = first end
        local seq = M.likeliest(key, from or nil, free, j)
        if seq then
          for _, d in ipairs(tail) do seq[#seq + 1] = d end
          return seq
        end
      end
    end
  end
  -- Nothing at all (a one-chord span): the tonic.
  local seq = {}
  for i = 1, n do seq[i] = (i % 2 == 1) and 0 or norm(key, 4) end
  return seq
end

-- The likeliest walk of `len` chords from `start` (from anywhere, if nil)
-- whose last chord can go on (`join(last)` > 0): the path with the greatest
-- product of weights, found by dynamic programming over the chords
-- (Viterbi's algorithm). nil when there is none.
function M.likeliest(key, start, len, join)
  local L = M.scaleLen(key)
  local score, back = {}, {}
  if start then score[start] = 0 else for d = 0, L - 1 do score[d] = 0 end end
  for i = 2, len do
    local ns, nb = {}, {}
    for d = 0, L - 1 do
      if score[d] then
        for e = 0, L - 1 do
          local w = M.moveWeight(key, d, e)
          if w > 0 then
            local sc = score[d] + math.log(w)
            if not ns[e] or sc > ns[e] then ns[e], nb[e] = sc, d end
          end
        end
      end
    end
    score, back[i] = ns, nb
  end
  local best, bestScore
  for d = 0, L - 1 do
    local w = score[d] and join(d) or 0
    if w > 0 then
      local sc = score[d] + math.log(w)
      if not bestScore or sc > bestScore then best, bestScore = d, sc end
    end
  end
  if not best then return nil end
  local seq = {}
  seq[len] = best
  for i = len, 2, -1 do seq[i - 1] = back[i][seq[i]] end
  return seq
end

------------------------------------------------------------------------------
-- Voicing
--
-- Close position - every chord tone once, inside an octave - with each chord
-- the inversion nearest the one before it, so the voices move as little as
-- they can. That is most of voice leading for an idea you are about to take
-- into the piano roll and change anyway.
------------------------------------------------------------------------------

local function mean(t)
  local s = 0
  for _, v in ipairs(t) do s = s + v end
  return s / math.max(1, #t)
end

function M.voice(pcs, prev, lo, hi)
  local best, bestCost
  local centre = (lo + hi) / 2
  for base = lo, hi do
    local bpc = base % 12
    local isTone = false
    for _, pc in ipairs(pcs) do if pc == bpc then isTone = true end end
    if isTone then
      local notes, seen = { base }, { [bpc] = true }
      for _, pc in ipairs(pcs) do
        if not seen[pc] then
          seen[pc] = true
          notes[#notes + 1] = base + (pc - bpc) % 12
        end
      end
      table.sort(notes)
      if notes[#notes] <= hi then
        local cost
        if prev and #prev == #notes then
          cost = 0
          for i = 1, #notes do cost = cost + math.abs(notes[i] - prev[i]) end
        elseif prev then
          cost = math.abs(mean(notes) - mean(prev)) * #notes
        else
          cost = 0
        end
        cost = cost + 0.15 * math.abs(mean(notes) - centre)
        if not bestCost or cost < bestCost then best, bestCost = notes, cost end
      end
    end
  end
  return best or {}
end

-- A root in the bass: the octave of `pc` inside [lo, hi] nearest the last
-- bass note (or the middle of the range for the first).
function M.bassNote(pc, prev, lo, hi)
  local want = prev or math.floor((lo + hi) / 2)
  local best
  for p = lo, hi do
    if p % 12 == pc and (not best or math.abs(p - want) < math.abs(best - want)) then best = p end
  end
  return best or (lo + (pc - lo) % 12)
end

return M
