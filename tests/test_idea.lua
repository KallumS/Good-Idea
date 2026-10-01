--[[ The ideas: thousands of them, every one checked rule by rule, then
     particular things by name.

       lua5.4 tests/test_idea.lua

     The sweep tallies each rule over every note it applies to and reports a
     broken rule once, with a count and the first idea that broke it, so a
     broken rule is one readable line rather than a thousand.
]]

local HERE = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local C = dofile(HERE .. "/check.lua")
local ok, eq, eqList = C.ok, C.eq, C.eqList
local T = dofile(C.SCRIPTS .. "gi_theory.lua")
local I = dofile(C.SCRIPTS .. "gi_idea.lua").init(T)

local M44 = I.meter(4, 4)

local function make(settings, seed, meter)
  local st = I.newState()
  for k, v in pairs(settings or {}) do st[k] = v end
  I.clampState(st)
  return I.make(st, meter or M44, seed or 1), st
end

local function part(idea, name)
  for _, p in ipairs(idea.block.parts) do if p.name == name then return p end end
end

local function fingerprint(notes)
  local out = {}
  for _, n in ipairs(notes or {}) do out[#out + 1] = ("%g:%g:%d:%d"):format(n.start, n.len, n.pitch, n.chan or 0) end
  return table.concat(out, " ")
end

------------------------------------------------------------------------------
-- The pieces
------------------------------------------------------------------------------

eqList(I.euclid(3, 8), { 0, 3, 6 }, "3 in 8 is the tresillo")
eqList(I.euclid(5, 8), { 0, 2, 4, 5, 7 }, "5 in 8 is the cinquillo, turned")
eqList(I.euclid(4, 16), { 0, 4, 8, 12 }, "4 in 16 is four on the floor")
eq(#I.euclid(7, 12), 7, "k in n has k notes")

local m34, m68, m78 = I.meter(3, 4), I.meter(6, 8), I.meter(7, 8)
eq(M44.bar, 16, "a bar of 4/4 is sixteen sixteenths")
eq(M44.beat, 4, "its beat a quarter")
eq(M44.mid, 8, "its half bar beat 3")
eq(m34.bar, 12, "3/4 is twelve")
eq(m34.mid, nil, "and has no half bar")
eq(m68.bar, 12, "6/8 is twelve too")
eq(m68.beat, 6, "but its beat is the dotted quarter")
eq(m78.bar, 14, "7/8 is fourteen")
eq(m78.beat, 2, "counted in eighths")
eq(I.strength(M44, 0), 3, "the downbeat is the strongest")
eq(I.strength(M44, 8), 2.5, "then beat 3")
eq(I.strength(M44, 4), 2, "then the other beats")
eq(I.strength(M44, 2), 1, "then the eighths")
eq(I.strength(M44, 1), 0, "then the sixteenths")

-- The dice: the same seed, the same numbers.
do
  local a, b = I.random(42), I.random(42)
  local same = true
  for _ = 1, 100 do if a() ~= b() then same = false end end
  ok(same, "a seed always gives the same numbers")
  local c = I.random(43)
  ok(I.random(42)() ~= c(), "and the next seed different ones")
  local lo, hi = 1, 0
  local r = I.random(5)
  for _ = 1, 10000 do local x = r(); lo, hi = math.min(lo, x), math.max(hi, x) end
  ok(lo >= 0 and hi < 1 and lo < 0.01 and hi > 0.99, "between 0 and 1, across the range")
end

------------------------------------------------------------------------------
-- The sweep
------------------------------------------------------------------------------

local tally = {}
local function rule(name, good, example)
  local t = tally[name]
  if not t then t = { n = 0, bad = 0 }; tally[name] = t end
  t.n = t.n + 1
  if not good then
    t.bad = t.bad + 1
    t.example = t.example or example
  end
end

local function scalePcs(key)
  local s = {}
  for p = 0, 20 do s[T.pc(key, p)] = true end
  return s
end

local CADENCE_PCS = function(key, half)
  local s = {}
  for _, c in ipairs(T.cadenceChords(key, half)) do s[c.degree] = true end
  return s
end

local function audit(idea, tag)
  local b, r, key, meter = idea.block, idea.r, idea.key, nil
  meter = idea.meter
  local inKey = scalePcs(key)
  local barsWanted = r.bars

  rule("an idea is as long as its bars", math.abs(b.beats - barsWanted * meter.barBeats) < 1e-9, tag)
  rule("an idea has notes", #b.notes > 0, tag)

  for _, p in ipairs(b.parts) do
    for _, n in ipairs(p.notes) do
      rule("every note is a MIDI note", n.pitch >= 0 and n.pitch <= 127, tag)
      rule("every note has length", n.len > 0, tag)
      rule("every note is inside the idea", n.start >= -1e-9 and n.start + n.len <= b.beats + 1e-9, tag)
      rule("velocity is 100, or 115 when accented",
           n.vel == 100 or (r.velocity == "Accents" and n.vel == I.ACCENT), tag)
      if not p.drums then
        rule("every pitched note is in the key", inKey[n.pitch % 12] == true,
             tag .. " " .. p.name .. " " .. T.pitchName(n.pitch))
      end
      if p.drums then rule("the drums are on channel 10", n.chan == 9, tag) end
    end
  end

  -- What the parts are.
  if r.kind == "Motif" then
    rule("a motif is a tune only", #b.parts == 1 and b.parts[1].name == "Melody", tag)
  elseif r.kind == "Phrase" then
    local want = ({ Melody = "Melody", Chords = "Chords", Both = "Melody Chords" })[r.content]
    local got = {}
    for _, p in ipairs(b.parts) do got[#got + 1] = p.name end
    rule("a phrase is what its content says", table.concat(got, " ") == want, tag)
    rule("a phrase is one item", b.layout == "one", tag)
  else
    local want = r.drums == "On" and "Melody Chords Bass Drums" or "Melody Chords Bass"
    local got = {}
    for _, p in ipairs(b.parts) do got[#got + 1] = p.name end
    rule("a measure is melody, chords, bass (and drums)", table.concat(got, " ") == want, tag)
    rule("a measure's layout is what it says",
         b.layout == (r.layout == "Tracks" and "tracks" or "one"), tag)
  end

  -- The chords: the timeline covers the idea, and its ending is the plan's.
  local tl = idea.timeline
  rule("the chords start at the start", tl[1].s == 0, tag)
  rule("and end at the end", tl[#tl].e == b.beats * 4, tag)
  for i = 2, #tl do
    rule("each chord starts where the last ended", tl[i].s == tl[i - 1].e, tag)
    rule("no chord follows itself", tl[i].degree ~= tl[i - 1].degree, tag .. " " .. idea.chords)
    rule("chords change on a beat", tl[i].s % meter.beat == 0, tag)
  end
  -- (Unless the opening unit only has room for its ending: a one-bar phrase
  -- that closes is V-I.)
  local u1 = idea.plan.units[1]
  local tailLen = (u1.cad == "PAC" or u1.cad == "IAC") and 2 or 1
  rule("an idea opens on the tonic chord", tl[1].degree == 0 or #u1.rel <= tailLen, tag .. " " .. idea.chords)
  local last = tl[#tl]
  local ending = idea.plan.ending
  if ending == "PAC" or ending == "IAC" then
    rule("a full or imperfect close ends on the tonic chord", last.degree == 0, tag .. " " .. idea.chords)
    if #tl >= 2 then
      rule("led home by a cadence chord", CADENCE_PCS(key)[tl[#tl - 1].degree] == true, tag .. " " .. idea.chords)
    end
  elseif ending == "HC" then
    rule("a half close ends on a dominant", CADENCE_PCS(key, true)[last.degree] == true, tag .. " " .. idea.chords)
  end

  -- The tune.
  local mel = idea.melody
  if mel then
    local steps, moves, leaps, run = 0, 0, 0, 1
    local lo, hi = 127, 0
    for i, n in ipairs(mel) do
      lo, hi = math.min(lo, n.pitch), math.max(hi, n.pitch)
      if I.strength(meter, n.step) >= 2 then
        local ch = I.chordAt(tl, n.step).chord
        rule("a note on the beat is on the chord", T.onChord(key, ch, n.pos),
             ("%s step %d %s over %s"):format(tag, n.step, T.pitchName(n.pitch, key), ch.name))
      end
      if i > 1 then
        local p = mel[i - 1]
        local iv = n.pos - p.pos
        local semis = math.abs(n.pitch - p.pitch)
        moves = moves + 1
        if math.abs(iv) <= 1 then steps = steps + 1 end
        if math.abs(iv) >= 3 then leaps = leaps + 1 end
        -- (The whole-tone and diminished scales are built of tritones; a
        -- tune in them is allowed theirs.)
        if r.scale < 14 then
          rule("no tritone leap", semis ~= 6, ("%s %s-%s"):format(tag, T.pitchName(p.pitch), T.pitchName(n.pitch)))
        end
        -- A repeat can go back to where its source began, from wherever
        -- the tune got to; inside a statement, nothing wider than an octave.
        if not n.first then rule("no leap wider than an octave inside a statement", semis <= 12, tag) end
        run = (n.pitch == p.pitch) and run + 1 or 1
        rule("no note three times running", run < 3, tag)
      end
    end
    rule("a tune stays within two octaves", hi - lo <= 24, tag)
    if moves >= 4 then
      tally._steps = (tally._steps or 0) + steps
      tally._moves = (tally._moves or 0) + moves
      tally._leaps = (tally._leaps or 0) + leaps
    end
    local final = mel[#mel]
    if ending == "PAC" then
      rule("a full close ends the tune on the tonic", final.pos % T.scaleLen(key) == 0, tag)
    elseif ending == "IAC" then
      local tonic = T.chord(key, 0, "Triads")
      rule("an imperfect close ends on the tonic chord's third or fifth",
           T.onChord(key, tonic, final.pos) and final.pos % T.scaleLen(key) ~= 0, tag)
    elseif ending == "HC" then
      rule("a half close ends the tune on the dominant chord", T.onChord(key, last.chord, final.pos), tag)
    elseif ending == "open" then
      rule("an open ending lands on the chord under it",
           T.onChord(key, I.chordAt(tl, final.step).chord, final.pos), tag)
    end
  end

  -- The chords part: every note a chord tone of the chord it sounds over.
  local cp = part(idea, "Chords")
  if cp then
    for _, n in ipairs(cp.notes) do
      local ch = I.chordAt(tl, math.floor(n.start * 4 + 0.5)).chord
      rule("every note of the chords part is on its chord", ch.has[n.pitch % 12] == true, tag)
    end
  end
  local bp = part(idea, "Bass")
  if bp then
    for _, n in ipairs(bp.notes) do
      rule("the bass stays in the bass", n.pitch >= 28 and n.pitch <= 55, tag)
    end
    -- The bass plays the root on every chord change.
    for _, sl in ipairs(tl) do
      local found = false
      for _, n in ipairs(bp.notes) do
        if math.abs(n.start * 4 - sl.s) < 1e-6 and n.pitch % 12 == sl.chord.rootPc then found = true end
      end
      rule("the bass plays the root where the chord changes", found, tag)
    end
  end
end

-- GOOD_IDEA_SWEEP=10 tools/test.sh sweeps ten times as many ideas.
local DEPTH = tonumber(os.getenv("GOOD_IDEA_SWEEP") or "") or 1
local METERS = { { 4, 4 }, { 3, 4 }, { 6, 8 }, { 7, 8 }, { 2, 4 }, { 12, 8 } }
local SCALES = { 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16 }
local count = 0
for mi, sig in ipairs(METERS) do
  local meter = I.meter(sig[1], sig[2])
  for _, kind in ipairs(I.KINDS) do
    local seeds = ((mi == 1) and 120 or 25) * DEPTH
    for seed = 1, seeds do
      local st = { kind = kind, velocity = (seed % 4 == 0) and "Accents" or "Flat",
                   drums = (seed % 5 == 0) and "Off" or "On",
                   layout = (seed % 3 == 0) and "One item" or "Tracks",
                   register = (seed % 7 == 0) and "Any" or "Middle" }
      -- Every seventh idea in a scale other than major, all sixteen covered.
      if seed % 2 == 0 then st.scale = SCALES[(seed // 2) % #SCALES + 1] end
      if seed % 3 == 1 then st.root = "Any" end
      local idea = make(st, seed * 13 + mi, meter)
      idea.meter = meter
      count = count + 1
      audit(idea, ("%s %d/%d seed %d"):format(kind, sig[1], sig[2], seed * 13 + mi))
    end
  end
end

local names = {}
for k in pairs(tally) do if k:sub(1, 1) ~= "_" then names[#names + 1] = k end end
table.sort(names)
for _, name in ipairs(names) do
  local t = tally[name]
  ok(t.bad == 0, ("%s (%d of %d broke it; first: %s)"):format(name, t.bad, t.n, tostring(t.example)))
  -- Each rule counts as many checks as the notes and chords it was applied to.
  C.checks = C.checks + t.n - 1
end
ok(count >= 600, "the sweep made " .. count .. " ideas")
local stepShare = tally._steps / tally._moves
ok(stepShare >= 0.5, ("tunes move mostly by step or repeat: %.0f%%"):format(stepShare * 100))
ok(tally._leaps / tally._moves <= 0.2, ("and leap a fourth or more rarely: %.0f%%"):format(100 * tally._leaps / tally._moves))

------------------------------------------------------------------------------
-- An idea is a number (0002)
------------------------------------------------------------------------------

-- The same settings and number, the same idea.
do
  local same = true
  for seed = 1, 30 do
    for _, kind in ipairs(I.KINDS) do
      local a = make({ kind = kind }, seed)
      local b = make({ kind = kind }, seed)
      if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then same = false end
    end
  end
  ok(same, "the same settings and number always give the same idea")
end

-- Different numbers, different ideas.
do
  for _, kind in ipairs(I.KINDS) do
    local seen, n = {}, 0
    for seed = 1, 100 do
      local f = fingerprint(make({ kind = kind }, seed).block.notes)
      if not seen[f] then seen[f] = true; n = n + 1 end
    end
    ok(n >= 97, kind .. ": a hundred numbers give a hundred ideas (" .. n .. ")")
  end
  -- Even with every setting fixed, the music itself still varies.
  local seen, n = {}, 0
  for seed = 1, 100 do
    local f = fingerprint(make({ kind = "Motif", motifBars = 2, pace = "Flowing", groove = "Straight",
                                 contour = "Arch" }, seed).block.notes)
    if not seen[f] then seen[f] = true; n = n + 1 end
  end
  ok(n >= 90, "with nothing left to chance but the music, still " .. n .. " different motifs in 100")
end

-- Keep turns every Any into what was rolled, and gives the same idea back.
do
  local bad, anyLeft = 0, 0
  for seed = 1, 60 do
    for _, kind in ipairs(I.KINDS) do
      local idea, st = make({ kind = kind, root = "Any", scale = "Any", register = "Any" }, seed)
      I.keep(st, idea)
      for _, s in ipairs(I.SETTINGS) do
        if I.shows(s, st) and st[s.id] == "Any" then anyLeft = anyLeft + 1 end
      end
      local again = I.make(st, M44, seed)
      if fingerprint(again.block.notes) ~= fingerprint(idea.block.notes) then bad = bad + 1 end
    end
  end
  eq(anyLeft, 0, "Keep leaves nothing on screen on Any")
  eq(bad, 0, "and gives exactly the same idea back")
end

-- A hidden setting never changes the idea: the chord settings under a
-- motif, the tune settings under a chords-only phrase.
do
  local bad = 0
  for seed = 1, 40 do
    local a = make({ kind = "Motif", colour = "Triads", chordPace = "Slow", chordStyle = "Block" }, seed)
    local b = make({ kind = "Motif", colour = "Sevenths", chordPace = "Two a bar", chordStyle = "Broken" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then bad = bad + 1 end
    local c = make({ kind = "Phrase", content = "Chords", contour = "Rise", register = "Low" }, seed)
    local d = make({ kind = "Phrase", content = "Chords", contour = "Fall", register = "High" }, seed)
    if fingerprint(c.block.notes) ~= fingerprint(d.block.notes) then bad = bad + 1 end
  end
  eq(bad, 0, "settings that are not on screen do not change the idea")
end

-- Each part draws its own dice: a different chord style leaves the tune
-- alone, and so does turning the drums off.
do
  local bad = 0
  for seed = 1, 40 do
    local a = make({ kind = "Phrase", content = "Both", chordStyle = "Block" }, seed)
    local b = make({ kind = "Phrase", content = "Both", chordStyle = "Broken" }, seed)
    if fingerprint(part(a, "Melody").notes) ~= fingerprint(part(b, "Melody").notes) then bad = bad + 1 end
    local e = make({ kind = "Measure", chordStyle = "Pulse", groove = "Syncopated" }, seed)
    local f = make({ kind = "Measure", chordStyle = "Broken", groove = "Syncopated" }, seed)
    if fingerprint(part(e, "Bass").notes) ~= fingerprint(part(f, "Bass").notes) then bad = bad + 1 end
    if fingerprint(part(e, "Drums").notes) ~= fingerprint(part(f, "Drums").notes) then bad = bad + 1 end
    local c = make({ kind = "Measure", drums = "On" }, seed)
    local d = make({ kind = "Measure", drums = "Off" }, seed)
    if fingerprint(part(c, "Melody").notes) ~= fingerprint(part(d, "Melody").notes) then bad = bad + 1 end
    if fingerprint(part(c, "Bass").notes) ~= fingerprint(part(d, "Bass").notes) then bad = bad + 1 end
  end
  eq(bad, 0, "changing how the chords are played, or the drums, leaves the tune and bass alone")
end

-- The same idea in another key is the same tune, moved.
do
  local bad = 0
  for seed = 1, 40 do
    local a = make({ kind = "Motif", root = 1, scale = 1 }, seed)
    for _, root in ipairs({ 4, 9, 13, 16 }) do
      local b = make({ kind = "Motif", root = root, scale = 1 }, seed)
      local ma, mb = part(a, "Melody").notes, part(b, "Melody").notes
      if #ma ~= #mb then bad = bad + 1
      else
        local shift = mb[1].pitch - ma[1].pitch
        for i = 1, #ma do
          if ma[i].start ~= mb[i].start or ma[i].len ~= mb[i].len or mb[i].pitch - ma[i].pitch ~= shift then
            bad = bad + 1; break
          end
        end
      end
    end
  end
  eq(bad, 0, "a motif in D, F#, Ab and Bb major is the C major motif, moved")
  -- And into another scale the same tune keeps its rhythm, in the new scale's
  -- notes.
  local a = make({ kind = "Motif", root = 1, scale = 1 }, 3)
  local b = make({ kind = "Motif", root = 1, scale = 5 }, 3)
  local same = #part(a, "Melody").notes == #part(b, "Melody").notes
  for i, n in ipairs(part(a, "Melody").notes) do
    local m = part(b, "Melody").notes[i]
    if not m or m.start ~= n.start then same = false end
  end
  ok(same, "in Dorian the same motif keeps its rhythm")
end

------------------------------------------------------------------------------
-- Any, and settings that are fixed
------------------------------------------------------------------------------

do
  local seen = {}
  for seed = 1, 400 do
    local kind = I.KINDS[seed % 3 + 1]
    local idea = make({ kind = kind, root = "Any", scale = "Any", register = "Any" }, seed)
    for id in pairs(idea.r.rolled) do
      seen[id] = seen[id] or {}
      seen[id][tostring(idea.r[id])] = true
    end
  end
  local missing = {}
  for _, s in ipairs(I.SETTINGS) do
    if s.any then
      for _, v in ipairs(s.anyValues or s.values) do
        if not (seen[s.id] and seen[s.id][tostring(v)]) then missing[#missing + 1] = s.id .. "=" .. tostring(v) end
      end
    end
  end
  eq(#missing, 0, "Any rolls every value it offers, given 400 ideas: " .. table.concat(missing, ", "))
end

-- Fixing one setting to what it rolled leaves every other roll alone: each
-- setting has its own draw of the dice, used or not.
do
  local bad = 0
  for seed = 1, 60 do
    local a = make({ kind = "Measure" }, seed)
    local b = make({ kind = "Measure", pace = a.r.pace }, seed)
    for _, s in ipairs(I.SETTINGS) do
      if a.r[s.id] ~= b.r[s.id] then bad = bad + 1 end
    end
    local c = make({ kind = "Measure", pace = (a.r.pace == "Busy") and "Calm" or "Busy" }, seed)
    for _, s in ipairs(I.SETTINGS) do
      if s.id ~= "pace" and a.r[s.id] ~= c.r[s.id] then bad = bad + 1 end
    end
  end
  eq(bad, 0, "fixing one setting, to anything, does not change what the others roll")
end

do
  local bad = 0
  for seed = 1, 30 do
    local r = make({ kind = "Measure", measureBars = 12, pace = "Busy", groove = "Syncopated",
                     form = "Song", bass = "Moving", colour = "Sevenths", root = 6, scale = 2 }, seed).r
    if r.bars ~= 12 or r.pace ~= "Busy" or r.groove ~= "Syncopated" or r.form ~= "Song"
       or r.bass ~= "Moving" or r.colour ~= "Sevenths" or r.root ~= 6 or r.scale ~= 2 then bad = bad + 1 end
  end
  eq(bad, 0, "a setting that is not Any is never rolled")
end

------------------------------------------------------------------------------
-- The settings do what they say
------------------------------------------------------------------------------

local function average(settings, fn, seeds)
  local total, n = 0, 0
  for seed = 1, seeds or 60 do
    local v = fn(make(settings, seed))
    if v then total, n = total + v, n + 1 end
  end
  return total / math.max(1, n)
end

do
  local function perBar(idea) return #idea.melody / idea.r.bars end
  local calm = average({ kind = "Phrase", content = "Melody", pace = "Calm" }, perBar)
  local flowing = average({ kind = "Phrase", content = "Melody", pace = "Flowing" }, perBar)
  local busy = average({ kind = "Phrase", content = "Melody", pace = "Busy" }, perBar)
  ok(calm < flowing and flowing < busy, ("Calm < Flowing < Busy notes a bar: %.1f, %.1f, %.1f"):format(calm, flowing, busy))
end

do
  local function offBeat(idea)
    local off = 0
    for _, n in ipairs(idea.melody) do if I.strength(M44, n.step) < 2 then off = off + 1 end end
    return off / #idea.melody
  end
  local straight = average({ kind = "Phrase", content = "Melody", groove = "Straight", pace = "Flowing" }, offBeat)
  local synco = average({ kind = "Phrase", content = "Melody", groove = "Syncopated", pace = "Flowing" }, offBeat)
  ok(synco > straight + 0.1, ("Syncopated puts more notes off the beat: %.0f%% against %.0f%%"):format(synco * 100, straight * 100))
end

do
  local function rise(idea)
    local m = idea.melody
    local third = math.max(1, #m // 3)
    local a, b = 0, 0
    for i = 1, third do a = a + m[i].pitch end
    for i = #m - third + 1, #m do b = b + m[i].pitch end
    return (b - a) / third
  end
  local up = average({ kind = "Phrase", content = "Melody", phraseBars = 4, contour = "Rise" }, rise)
  local down = average({ kind = "Phrase", content = "Melody", phraseBars = 4, contour = "Fall" }, rise)
  ok(up > 2, ("a Rise ends higher than it starts: %+.1f semitones on average"):format(up))
  ok(down < -2, ("a Fall ends lower: %+.1f"):format(down))
  local function peakAt(idea)
    local m, best = idea.melody, 1
    for i = 2, #m do if m[i].pitch > m[best].pitch then best = i end end
    return m[best].step / (idea.block.beats * 4)
  end
  local arch = average({ kind = "Phrase", content = "Melody", phraseBars = 4, contour = "Arch" }, peakAt)
  ok(arch > 0.3 and arch < 0.8, ("an Arch peaks in the middle-to-late part: %.0f%% of the way"):format(arch * 100))
  local function mean(idea) local s = 0; for _, n in ipairs(idea.melody) do s = s + n.pitch end; return s / #idea.melody end
  local low = average({ kind = "Motif", register = "Low" }, mean)
  local high = average({ kind = "Motif", register = "High" }, mean)
  ok(high - low >= 15, ("High sits well above Low: %.0f against %.0f"):format(high, low))
end

do
  local function chordsPerBar(idea) return #idea.timeline / idea.r.bars end
  local slow = average({ kind = "Measure", form = "Loop", chordPace = "Slow" }, chordsPerBar)
  local one = average({ kind = "Measure", form = "Loop", chordPace = "One a bar" }, chordsPerBar)
  local two = average({ kind = "Measure", form = "Loop", chordPace = "Two a bar" }, chordsPerBar)
  ok(slow < one and one < two, ("chord pace: %.2f, %.2f, %.2f chords a bar"):format(slow, one, two))
end

do
  local bad = 0
  for seed = 1, 20 do
    local i7 = make({ kind = "Phrase", content = "Chords", colour = "Sevenths", chordStyle = "Block" }, seed)
    for _, sl in ipairs(i7.timeline) do if #sl.chord.pcs ~= 4 then bad = bad + 1 end end
    local it = make({ kind = "Phrase", content = "Chords", colour = "Triads", chordStyle = "Block" }, seed)
    for _, sl in ipairs(it.timeline) do if #sl.chord.pcs ~= 3 then bad = bad + 1 end end
  end
  eq(bad, 0, "Sevenths are four-note chords, Triads three")
  -- Block holds; Broken plays one note at a time; Pulse strikes again.
  local block = make({ kind = "Phrase", content = "Chords", chordStyle = "Block", chordPace = "One a bar",
                       colour = "Triads", phraseBars = 2 }, 4)
  local broken = make({ kind = "Phrase", content = "Chords", chordStyle = "Broken", chordPace = "One a bar",
                        colour = "Triads", phraseBars = 2 }, 4)
  local starts = {}
  for _, n in ipairs(broken.block.notes) do starts[n.start] = (starts[n.start] or 0) + 1 end
  local most = 0
  for _, c in pairs(starts) do most = math.max(most, c) end
  ok(most <= 2, "Broken never sounds more than a note and the bass at once")
  local bstarts = {}
  for _, n in ipairs(block.block.notes) do bstarts[n.start] = true end
  local nstarts = 0
  for _ in pairs(bstarts) do nstarts = nstarts + 1 end
  eq(nstarts, #block.timeline, "Block strikes each chord once")
end

------------------------------------------------------------------------------
-- The forms
------------------------------------------------------------------------------

local function unitNotes(u, from, to)
  local out = {}
  for _, n in ipairs(u.notes) do
    if n.at >= from and n.at < to then out[#out + 1] = n.at .. ":" .. n.pos end
  end
  return table.concat(out, " ")
end

do
  local bad = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", form = "Period", measureBars = 8 }, seed)
    local a, a2 = idea.plan.units[1], idea.plan.units[2]
    if a.cad ~= "HC" or a2.cad ~= "PAC" then bad = bad + 1 end
    local half = a.len // 2
    if unitNotes(a, 0, half) ~= unitNotes(a2, 0, half) then bad = bad + 1 end
  end
  eq(bad, 0, "a Period asks (ends open) and answers (ends home) with the same opening")
end

do
  local bad = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", form = "Loop", measureBars = 16 }, seed)
    local first = table.concat(idea.plan.units[1].degrees, ",")
    for _, u in ipairs(idea.plan.units) do
      if table.concat(u.degrees, ",") ~= first then bad = bad + 1 end
    end
    if idea.timeline[#idea.timeline].degree == 0 then bad = bad + 1 end
  end
  eq(bad, 0, "a Loop plays the same chords each time round, ending away from home so it goes round again")
end

do
  local faster = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", form = "Sentence", measureBars = 8, chordPace = "One a bar" }, seed)
    local a, f = idea.plan.units[1], idea.plan.units[3]
    if f.kind == "frag" and #f.slots / f.bars > #a.slots / a.bars then faster = faster + 1 end
  end
  eq(faster, 30, "a Sentence's continuation changes chord faster than its opening")
end

do
  local bad = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", form = "Song", measureBars = 16 }, seed)
    local u = idea.plan.units
    if u[1].letter ~= "a" or u[2].letter ~= "a" or u[3].letter ~= "b" or u[4].letter ~= "a" then bad = bad + 1 end
    local half = u[1].len // 2
    if unitNotes(u[1], 0, half) ~= unitNotes(u[4], 0, half) then bad = bad + 1 end
  end
  eq(bad, 0, "a Song is A A B A, and the last A starts as the first did")
end

------------------------------------------------------------------------------
-- Bass and drums
------------------------------------------------------------------------------

do
  local idea = make({ kind = "Measure", measureBars = 8, pace = "Flowing", groove = "Straight", drums = "On",
                      form = "Period" }, 9)
  local dr = part(idea, "Drums").notes
  local D = I.DRUM
  local at = {}
  for _, n in ipairs(dr) do at[("%g:%d"):format(n.start, n.pitch)] = true end
  ok(at["0:" .. D.crash], "a crash on the first downbeat")
  ok(at["1:" .. D.snare] and at["3:" .. D.snare], "the snare on 2 and 4")
  ok(at["0:" .. D.kick], "the kick on 1")
  ok(at["0.5:" .. D.hat], "eighth-note hats when the pace flows")
  local lastBar = (idea.r.bars - 1) * 4
  local toms = 0
  for _, n in ipairs(dr) do
    if n.start >= lastBar + 3 and (n.pitch == D.tomHi or n.pitch == D.tomMid or n.pitch == D.tomLo) then toms = toms + 1 end
  end
  ok(toms >= 2, "a fill in the last beat: " .. toms .. " tom hits")
  local calm = make({ kind = "Measure", measureBars = 8, pace = "Calm", groove = "Straight" }, 9)
  local snares = {}
  for _, n in ipairs(part(calm, "Drums").notes) do
    if n.pitch == D.snare and n.start < 4 then snares[#snares + 1] = ("%g"):format(n.start) end
  end
  eqList(snares, { 2 }, "a calm groove is half-time: the snare on 3")
end

do
  local bad = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", bass = "Pulse", drums = "On" }, seed)
    local changes, pattern = {}, {}
    for _, sl in ipairs(idea.timeline) do changes[sl.s / 4] = true end
    -- The kick's pattern, drawn as the idea drew it. (In the drum part the
    -- snare takes the kick's place on the backbeat and fills replace it;
    -- the bass keeps to the pattern.)
    for _, k in ipairs(I.kickPattern(M44, idea.r, I.stream(seed, "drums"))) do pattern[k / 4] = true end
    local kicks = 0
    for _, n in ipairs(part(idea, "Drums").notes) do
      if n.pitch == I.DRUM.kick then
        kicks = kicks + 1
        if not pattern[n.start % 4] then bad = bad + 1 end
      end
    end
    if kicks == 0 then bad = bad + 1 end
    for _, n in ipairs(part(idea, "Bass").notes) do
      if not (pattern[n.start % 4] or changes[n.start]) then bad = bad + 1 end
    end
  end
  eq(bad, 0, "a Pulse bass plays with the kick drum (or where the chord changes)")
end

do
  local bad = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", bass = "Moving", chordPace = "One a bar", pace = "Flowing" }, seed)
    local bp = part(idea, "Bass").notes
    for i, sl in ipairs(idea.timeline) do
      local nextSl = idea.timeline[i + 1]
      if nextSl and (nextSl.s - sl.s) >= 2 * M44.beat then
        -- The note before the change is a step from where the bass goes.
        local before
        for _, n in ipairs(bp) do if n.start * 4 < nextSl.s then before = n end end
        local root
        for _, n in ipairs(bp) do if n.start * 4 == nextSl.s then root = n end end
        if before and root and math.abs(before.pitch - root.pitch) > 2 then bad = bad + 1 end
      end
    end
  end
  eq(bad, 0, "a Moving bass steps into each new chord")
end

------------------------------------------------------------------------------
-- Settings from anywhere
------------------------------------------------------------------------------

do
  local st = { kind = "Poem", motifBars = 9, phraseBars = "Lots", measureBars = 10, content = "Words",
               root = 99, scale = -1, pace = "Sideways", groove = 3, contour = "Spiral", register = "Basement",
               colour = "Plaid", chordPace = "Never", chordStyle = "Jazz hands", form = "Sonnet",
               bass = "Slap", drums = "Any", layout = "Heap", velocity = "Loud", seed = -4, autoplay = "yes" }
  I.clampState(st)
  local fresh = I.newState()
  local bad = {}
  for _, s in ipairs(I.SETTINGS) do
    if st[s.id] ~= fresh[s.id] then bad[#bad + 1] = s.id end
  end
  eq(#bad, 0, "nonsense settings go back to their defaults: " .. table.concat(bad, ", "))
  eq(st.seed, 1, "and a nonsense idea number to 1")
  eq(st.autoplay, 0, "and autoplay off")
  ok(pcall(I.make, st, M44, st.seed), "and the idea still makes")
  local st2 = I.newState()
  st2.seed = 123456789
  I.clampState(st2)
  eq(st2.seed, 1, "an idea number past the last goes back to 1")
end

C.done()
