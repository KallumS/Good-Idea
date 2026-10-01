--[[ Keys, chords and the order chords come in, by running them.

       lua5.4 tests/test_theory.lua
]]

local HERE = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local C = dofile(HERE .. "/check.lua")
local ok, eq, eqList = C.ok, C.eq, C.eqList
local T = dofile(C.SCRIPTS .. "gi_theory.lua")

local I = dofile(C.SCRIPTS .. "gi_idea.lua").init(T)
local function dice(seed) return I.random(seed) end

------------------------------------------------------------------------------
-- The tables are ScaleView's, and have to stay that way
------------------------------------------------------------------------------

do
  local SCALEVIEW = {
    Major = {0,2,4,5,7,9,11}, Minor = {0,2,3,5,7,8,10},
    ["Harm Minor"] = {0,2,3,5,7,8,11}, Ionian = {0,2,4,5,7,9,11},
    Dorian = {0,2,3,5,7,9,10}, Phrygian = {0,1,3,5,7,8,10},
    Lydian = {0,2,4,6,7,9,11}, Mixolydian = {0,2,4,5,7,9,10},
    Aeolian = {0,2,3,5,7,8,10}, ["Maj Pent"] = {0,2,4,7,9},
    ["Min Pent"] = {0,3,5,7,10}, ["Maj Blues"] = {0,2,3,4,7,9},
    ["Min Blues"] = {0,3,5,6,7,10}, ["Whole Tone"] = {0,2,4,6,8,10},
    ["Dim W-H"] = {0,2,3,5,6,8,9,11}, ["Dim H-W"] = {0,1,3,4,6,7,9,10},
  }
  eq(#T.SCALES, 16, "sixteen scales")
  for _, sc in ipairs(T.SCALES) do
    eqList(sc.iv, SCALEVIEW[sc.name] or {}, "scale " .. sc.name .. " matches ScaleView")
    eq(#sc.letters, #sc.iv, "scale " .. sc.name .. " spells every degree")
  end
  local L, A = {"C","D","E","F","G","A","B"}, {[-1]="b", [0]="", [1]="#"}
  eq(#T.ROOTS, 18, "eighteen roots")
  for _, r in ipairs(T.ROOTS) do
    eq(r.name, L[r.letter + 1] .. A[r.acc], "root " .. r.name .. " spells itself")
  end
  eq(#T.CHORDS, 78, "Starting Blocks' 78 chords, for naming")
end

------------------------------------------------------------------------------
-- Positions and pitches
------------------------------------------------------------------------------

local Cmaj = T.key(1, 1)
local Amin = T.key(14, 2)
eq(T.pitch(Cmaj, 7 * 5), 60, "five octaves of positions up is middle C")
eq(T.pitch(Cmaj, 7 * 5 + 4), 67, "and four steps above it G")
eq(T.noteName(T.key(9, 1), 6), "E#", "the seventh of F# major is E#, not F")
eq(T.pitchName(61, T.key(3, 1)), "Db4", "named in the key")

do
  local bad = 0
  for root = 1, #T.ROOTS do
    for scale = 1, #T.SCALES do
      local key = T.key(root, scale)
      for pos = 0, 80 do
        local p = T.pitch(key, pos)
        if T.posOf(key, p) ~= pos then bad = bad + 1 end
        if T.floorPos(key, p) ~= pos then bad = bad + 1 end
      end
    end
  end
  eq(bad, 0, "every position of every key goes to a pitch and back")
end

------------------------------------------------------------------------------
-- Chords on a degree
------------------------------------------------------------------------------

local function names(key, colour)
  local out = {}
  for d = 0, T.scaleLen(key) - 1 do out[#out + 1] = T.chord(key, d, colour).name end
  return out
end

eqList(names(Cmaj, "Triads"), { "C", "Dm", "Em", "F", "G", "Am", "Bdim" }, "C major's triads")
eqList(names(Cmaj, "Sevenths"), { "Cmaj7", "Dm7", "Em7", "Fmaj7", "G7", "Am7", "Bm7b5" }, "and its sevenths")
eqList(names(Amin, "Triads"), { "Am", "Bdim", "C", "Dm", "Em", "F", "G" }, "A minor's triads")
eqList(names(T.key(1, 3), "Triads"), { "Cm", "Ddim", "Ebaug", "Fm", "G", "Ab", "Bdim" },
       "C harmonic minor's: a major V")
eqList(names(Cmaj, "Mixed"), { "Cadd9", "Dm7", "Em", "Fadd9", "G7", "Am(add9)", "Bm7b5" },
       "Mixed: sevenths on ii, V, vii; whole-tone ninths on the rest; no flat ninth on iii")
eqList(names(T.key(1, 10), "Triads"), { "C", "Dsus4", "Em(no5)", "Gsus4", "Am" },
       "C major pentatonic, built by ear: thirds where there are thirds, sus where not")
eqList(names(T.key(1, 14), "Triads"), { "Caug", "Daug", "Eaug", "F#aug", "G#aug", "A#aug" },
       "the whole-tone scale is augmented throughout")

-- Every chord of every scale in every colour is in the key, has a root, and
-- is named.
do
  local outside, small, unnamed, total = 0, 0, 0, 0
  for root = 1, #T.ROOTS do
    for scale = 1, #T.SCALES do
      local key = T.key(root, scale)
      local inKey = {}
      for p = 0, 11 do inKey[T.pc(key, p)] = true end
      for d = 0, T.scaleLen(key) - 1 do
        for _, colour in ipairs(T.COLOURS) do
          local ch = T.chord(key, d, colour)
          total = total + 1
          for _, pc in ipairs(ch.pcs) do if not inKey[pc] then outside = outside + 1 end end
          if #ch.pcs < 2 then small = small + 1 end
          if not ch.name or ch.name == "" then unnamed = unnamed + 1 end
          if ch.rootPc ~= T.pc(key, d) then outside = outside + 1 end
        end
      end
    end
  end
  eq(outside, 0, ("every note of all %d chords is in its key, on its root"):format(total))
  eq(small, 0, "every chord has at least a root and a third (or a sus note)")
  eq(unnamed, 0, "and a name")
end

-- In a seven-note scale, Triads are three notes, Sevenths four, Mixed never
-- has a flat ninth.
do
  local bad = 0
  for scale = 1, 9 do
    local key = T.key(1, scale)
    for d = 0, 6 do
      if #T.chord(key, d, "Triads").pcs ~= 3 then bad = bad + 1 end
      if #T.chord(key, d, "Sevenths").pcs ~= 4 then bad = bad + 1 end
      local mx = T.chord(key, d, "Mixed")
      for _, pc in ipairs(mx.pcs) do
        if (pc - mx.rootPc) % 12 == 1 then bad = bad + 1 end
      end
    end
  end
  eq(bad, 0, "triads are three notes, sevenths four, and Mixed adds no flat ninth")
end

------------------------------------------------------------------------------
-- Function and the walk
------------------------------------------------------------------------------

eqList((function() local o = {}; for d = 0, 6 do o[#o + 1] = T.functionOf(Cmaj, d) end; return o end)(),
       { "T", "S", "T", "S", "D", "T", "D" }, "I ii iii IV V vi vii are T S T S D T D")

eq(T.moveWeight(Cmaj, 4, 4), 0, "a chord never follows itself")
do
  local best, bestW = nil, -1
  for d = 0, 6 do
    if T.moveWeight(Cmaj, 4, d) > bestW then best, bestW = d, T.moveWeight(Cmaj, 4, d) end
  end
  eq(best, 0, "V goes home most of all")
  best, bestW = nil, -1
  for d = 0, 6 do
    if T.moveWeight(Cmaj, 1, d) > bestW then best, bestW = d, T.moveWeight(Cmaj, 1, d) end
  end
  eq(best, 4, "ii goes to V most of all")
  ok(T.moveWeight(Cmaj, 0, 6) < T.moveWeight(Cmaj, 0, 3), "the diminished vii is drawn less than IV")
end

-- No dead ends: from every chord of every scale there is somewhere to go.
do
  local dead = 0
  for scale = 1, #T.SCALES do
    local key = T.key(1, scale)
    for d = 0, T.scaleLen(key) - 1 do
      local sum = 0
      for e = 0, T.scaleLen(key) - 1 do sum = sum + T.moveWeight(key, d, e) end
      if sum <= 0 then dead = dead + 1 end
    end
  end
  eq(dead, 0, "every chord of every scale can move on")
end

-- Over many walks in C major, what follows V is mostly I, and what follows
-- ii is mostly V: the table's tendencies show in what it draws.
do
  local after = { [4] = {}, [1] = {} }
  local r = dice(7)
  for _ = 1, 4000 do
    for from in pairs(after) do
      local d = T.nextDegree(Cmaj, from, r)
      after[from][d] = (after[from][d] or 0) + 1
    end
  end
  ok((after[4][0] or 0) > 1600, "V -> I in more than 40% of draws: " .. tostring(after[4][0]))
  ok((after[1][4] or 0) > 1800, "ii -> V in more than 45%: " .. tostring(after[1][4]))
end

-- Cadences read off the scale.
do
  local function cad(key)
    local out = {}
    for _, c in ipairs(T.cadenceChords(key)) do out[c.degree] = c.weight end
    return out
  end
  local maj = cad(Cmaj)
  ok(maj[4] and maj[4] >= 3, "in major the V leads home strongest")
  local har = cad(T.key(1, 3))
  ok(har[4] and har[4] >= 3, "so does harmonic minor's, with its leading tone")
  local nat = cad(T.key(1, 2))
  ok(nat[6] and nat[6] >= 2, "natural minor has the subtonic VII")
  ok(nat[4] and nat[4] < 3, "and a weaker minor v")
  local phr = cad(T.key(1, 6))
  ok(phr[1] and phr[1] >= 2.5, "Phrygian has its bII")
  local half = {}
  for _, c in ipairs(T.cadenceChords(Cmaj, true)) do half[c.degree] = true end
  ok(half[4] and not half[3], "a half cadence rests on V, never IV")
  local mix = cad(T.key(1, 8))
  ok(mix[6] and mix[6] >= 2, "Mixolydian its bVII")
  for scale = 1, #T.SCALES do
    ok(#T.cadenceChords(T.key(1, scale)) > 0, T.SCALES[scale].name .. " has a way home")
  end
end

------------------------------------------------------------------------------
-- Progressions: every scale, every length, every ending, many draws
------------------------------------------------------------------------------

do
  local fails = {}
  local function bad(what) if #fails < 8 then fails[#fails + 1] = what end end
  local count, moved = 0, 0
  for scale = 1, #T.SCALES do
    local key = T.key(1, scale)
    local cads, halves = {}, {}
    for _, c in ipairs(T.cadenceChords(key)) do cads[c.degree] = true end
    for _, c in ipairs(T.cadenceChords(key, true)) do halves[c.degree] = true end
    for n = 1, 8 do
      for _, ending in ipairs({ "PAC", "IAC", "HC", "open", "none" }) do
        for seed = 1, 12 do
          local start = (seed % 3 == 0) and 3 or 0
          local p = T.progression(key, n, { start = start, cadence = ending }, dice(seed * 31 + n))
          count = count + 1
          local tag = ("%s n=%d %s seed %d: %s"):format(T.SCALES[scale].name, n, ending, seed, table.concat(p, ","))
          if #p ~= n then bad("length " .. tag) end
          for i = 2, #p do if p[i] == p[i - 1] then bad("a chord twice running " .. tag) end end
          for _, d in ipairs(p) do if d < 0 or d >= T.scaleLen(key) then bad("off the scale " .. tag) end end
          if ending == "PAC" or ending == "IAC" then
            if p[n] ~= 0 then bad("does not end home " .. tag) end
            if n >= 2 and not cads[p[n - 1]] then bad("not led home by a cadence chord " .. tag) end
          elseif ending == "HC" then
            if not halves[p[n]] then bad("a half cadence not on a dominant " .. tag) end
          elseif ending == "open" and n > 1 then
            if p[n] == 0 then bad("an open ending on the tonic " .. tag) end
          end
          local tail = (ending == "PAC" or ending == "IAC") and 2 or (ending == "HC" and 1 or 0)
          if n > tail and p[1] ~= start then moved = moved + 1 end
        end
      end
    end
  end
  ok(#fails == 0, ("all %d progressions keep their shape: %s"):format(count, table.concat(fails, "; ")))
  -- The start gives way only where it cannot reach the ending at all (the
  -- only cadence chord of a pentatonic scale, asked to move to itself).
  ok(moved < count / 100, "and start where asked, all but " .. moved .. " of them")
end

-- The fallback (when the table cannot reach the ending) is rare, not the
-- usual path: drawn progressions differ from one another.
do
  local seen, n = {}, 0
  for seed = 1, 200 do
    local s = table.concat(T.progression(Cmaj, 4, { cadence = "PAC" }, dice(seed)), ",")
    if not seen[s] then seen[s] = true; n = n + 1 end
  end
  ok(n >= 8, "four-chord progressions ending on a full cadence come in many shapes: " .. n)
end

------------------------------------------------------------------------------
-- Voicing
------------------------------------------------------------------------------

do
  local prev
  local moves, bad = 0, 0
  local prog = { 0, 5, 3, 4, 0, 1, 4, 0 }
  for _, d in ipairs(prog) do
    local ch = T.chord(Cmaj, d, "Sevenths")
    local v = T.voice(ch.pcs, prev, 52, 70)
    if #v ~= 4 then bad = bad + 1 end
    if v[#v] > 70 or v[1] < 52 then bad = bad + 1 end
    if v[#v] - v[1] >= 12 then bad = bad + 1 end
    local pcs = {}
    for _, p in ipairs(v) do pcs[p % 12] = true end
    for _, pc in ipairs(ch.pcs) do if not pcs[pc] then bad = bad + 1 end end
    if prev then
      local m = 0
      for i = 1, 4 do m = m + math.abs(v[i] - prev[i]) end
      moves = math.max(moves, m)
    end
    prev = v
  end
  eq(bad, 0, "every voicing holds every chord tone once, in range, inside an octave")
  ok(moves <= 8, "and the voices move by eight semitones or fewer in all from chord to chord: " .. moves)
end

eq(T.bassNote(7, nil, 36, 47), 43, "a G in the bass range, nearest its middle")
eq(T.bassNote(0, 43, 36, 47), 36, "C after G goes down a fifth")
eq(T.bassNote(9, 36, 31, 50), 33, "A after C goes down a third, not up a sixth")

C.done()
