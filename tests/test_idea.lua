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

-- A drum idea: General MIDI drums only, a kick on every downbeat, a snare
-- (or clap) or a fill in every bar, fills where the idea says and nowhere
-- else, and a crash on the downbeat each fill leads to.
local GM = {}
for _, v in pairs(I.DRUM) do GM[v] = true end
local TOM = { [50] = true, [48] = true, [47] = true, [45] = true, [43] = true, [41] = true }

local function auditDrums(idea, tag)
  local b, r, meter = idea.block, idea.r, idea.meter
  rule("a drum idea is one part, one item", #b.parts == 1 and b.parts[1].name == "Drums" and b.layout == "one", tag)
  local bar = meter.bar
  local kickOn, backed, toms, crashOn = {}, {}, {}, {}
  for _, n in ipairs(b.notes) do
    local step = n.start * 4
    local bi = math.floor(step / bar + 1e-9)
    rule("every drum is a General MIDI drum the generator knows", GM[n.pitch] == true, tag .. " " .. n.pitch)
    if n.pitch == I.DRUM.kick and math.abs(step - bi * bar) < 1e-6 then kickOn[bi] = true end
    if n.pitch == I.DRUM.snare or n.pitch == I.DRUM.clap then backed[bi] = true end
    if TOM[n.pitch] then toms[bi] = true end
    if n.pitch == I.DRUM.crash then crashOn[bi] = (math.abs(step - bi * bar) < 1e-6) end
  end
  local fills = {}
  for _, f in ipairs(idea.drums.fills) do fills[tonumber(f) - 1] = true end
  local wantFills = 0
  for x = 0, r.bars - 1 do
    local last = (x == r.bars - 1)
    local want = (r.fills == "At the end" and last) or (r.fills == "Every 4 bars" and ((x + 1) % 4 == 0 or last))
                 or (r.fills == "Every 2 bars" and ((x + 1) % 2 == 0 or last))
    if want then wantFills = wantFills + 1 end
    rule("fills are where the Fills setting puts them", (fills[x] == true) == (want == true), tag)
    rule("every bar starts with a kick", kickOn[x] == true, tag .. " bar " .. (x + 1))
    rule("every bar has a snare, a clap or a fill", backed[x] or fills[x] or toms[x], tag)
    if not fills[x] then rule("toms only in fills", not toms[x], tag .. " bar " .. (x + 1)) end
    local after = (x + 1) % r.bars
    if fills[x] then rule("a crash on the downbeat a fill leads to", crashOn[after] == true, tag .. " bar " .. (after + 1)) end
  end
  if wantFills == 0 then
    local any = false
    for x = 0, r.bars - 1 do if crashOn[x] ~= nil then any = true end end
    rule("no fills, no crashes", not any, tag)
  end
end

local function audit(idea, tag)
  local b, r, key, meter = idea.block, idea.r, idea.key, nil
  meter = idea.meter
  -- The scale sounding at a step: the key's, or a borrowed chord's.
  local tlctx = { timeline = idea.timeline, key = key }
  local function inKeyAt(step, pc) return scalePcs(I.keyAt(tlctx, step))[pc] == true end
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
        rule("every pitched note is in the scale sounding under it", inKeyAt(n.start * 4, n.pitch % 12),
             tag .. " " .. p.name .. " " .. T.pitchName(n.pitch))
      end
      if p.drums then rule("the drums are on channel 10", n.chan == 9, tag) end
    end
  end

  if r.kind == "Drums" then return auditDrums(idea, tag) end

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
    local got = {}
    for _, p in ipairs(b.parts) do got[#got + 1] = p.name end
    rule("a measure is melody, chords and bass", table.concat(got, " ") == "Melody Chords Bass", tag)
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
    rule("chords change on a beat, or an eighth before one when pushed",
         tl[i].s % meter.beat == 0 or (tl[i].pushed and (tl[i].s + 2) % meter.beat == 0), tag)
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
        rule("a note on the beat is on the chord", T.onChord(I.keyAt(tlctx, n.step), ch, n.pos),
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
      rule("a half close ends the tune on the dominant chord", T.onChord(I.keyAt(tlctx, final.step), last.chord, final.pos), tag)
    elseif ending == "open" then
      rule("an open ending lands on the chord under it",
           T.onChord(I.keyAt(tlctx, final.step), I.chordAt(tl, final.step).chord, final.pos), tag)
    end
  end

  -- The chords part: every note a chord tone of the chord it sounds over.
  local cp = part(idea, "Chords")
  if cp then
    for _, n in ipairs(cp.notes) do
      -- (Against the chords part's own timeline: a pulled chord comes late.)
      local ch = I.chordAt(idea.chordTimeline, math.floor(n.start * 4 + 0.5)).chord
      -- (A rootless voicing puts the chord's ninth where its root was.)
      rule("every note of the chords part is on its chord",
           ch.has[n.pitch % 12] == true or (r.voicing == "Rootless" and n.pitch % 12 == ch.nine), tag)
    end
  end
  local bp = part(idea, "Bass")
  if bp then
    for _, n in ipairs(bp.notes) do
      rule("the bass stays in the bass", n.pitch >= 28 and n.pitch <= 55, tag)
    end
    -- The bass plays the root on every chord change (or the note an
    -- inverted chord stands on).
    for _, sl in ipairs(tl) do
      local found = false
      for _, n in ipairs(bp.notes) do
        if math.abs(n.start * 4 - sl.s) < 1e-6 and n.pitch % 12 == I.bassPcOf(sl) then found = true end
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
                   layout = (seed % 3 == 0) and "One item" or "Tracks",
                   register = (seed % 7 == 0) and "Any" or "Middle",
                   voicing = T.VOICINGS[seed % #T.VOICINGS + 1],
                   colour = (seed % 5 == 0) and "Mixed" or "Any" }
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
-- and the bass alone, and so does a different bass the tune and chords.
do
  local bad = 0
  for seed = 1, 40 do
    local a = make({ kind = "Phrase", content = "Both", chordStyle = "Block" }, seed)
    local b = make({ kind = "Phrase", content = "Both", chordStyle = "Broken" }, seed)
    if fingerprint(part(a, "Melody").notes) ~= fingerprint(part(b, "Melody").notes) then bad = bad + 1 end
    local e = make({ kind = "Measure", chordStyle = "Pulse", groove = "Syncopated" }, seed)
    local f = make({ kind = "Measure", chordStyle = "Broken", groove = "Syncopated" }, seed)
    if fingerprint(part(e, "Bass").notes) ~= fingerprint(part(f, "Bass").notes) then bad = bad + 1 end
    if fingerprint(part(e, "Melody").notes) ~= fingerprint(part(f, "Melody").notes) then bad = bad + 1 end
    local c = make({ kind = "Measure", bass = "Held" }, seed)
    local d = make({ kind = "Measure", bass = "Moving" }, seed)
    if fingerprint(part(c, "Melody").notes) ~= fingerprint(part(d, "Melody").notes) then bad = bad + 1 end
    if fingerprint(part(c, "Chords").notes) ~= fingerprint(part(d, "Chords").notes) then bad = bad + 1 end
  end
  eq(bad, 0, "changing how the chords are played leaves the tune and bass alone, and the bass the tune and chords")
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
    local idea = make({ kind = kind, root = "Any", scale = "Any", register = "Any", voicing = "Any" }, seed)
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
  local onehalf = average({ kind = "Measure", form = "Loop", chordPace = "1.5 a bar" }, chordsPerBar)
  local two = average({ kind = "Measure", form = "Loop", chordPace = "Two a bar" }, chordsPerBar)
  local four = average({ kind = "Measure", form = "Loop", chordPace = "4 a bar" }, chordsPerBar)
  ok(slow < one and one < onehalf and onehalf < two and two < four,
     ("chord pace: %.2f, %.2f, %.2f, %.2f, %.2f chords a bar"):format(slow, one, onehalf, two, four))
  -- 4 a bar is a chord on every beat: every chord the plan lays out is one
  -- beat long, in 4/4 and in 3/4 alike.
  local long, slots = 0, 0
  for seed = 1, 40 do
    for _, m in ipairs({ M44, m34 }) do
      for _, kind in ipairs({ "Phrase", "Measure" }) do
        local idea = make({ kind = kind, content = "Both", chordPace = "4 a bar", push = "None" }, seed, m)
        for _, u in ipairs(idea.plan.units) do
          for _, sl in ipairs(u.rel) do
            slots = slots + 1
            if sl.e - sl.s ~= m.beat then long = long + 1 end
          end
        end
      end
    end
  end
  ok(slots > 0 and long == 0, ("4 a bar changes chord on every beat: %d of %d chords longer than a beat"):format(long, slots))
  eq(I.valueName(I.BY_ID.chordPace, "Slow"), "0.5 a bar", "Slow is shown as 0.5 a bar")
  eq(I.valueName(I.BY_ID.chordPace, "Two a bar"), "2 a bar", "and Two a bar as 2 a bar")
  -- 1.5 a bar in 4/4 is three chords to two bars, laid 3+3+2 beats.
  local shaped, all = 0, 0
  for seed = 1, 40 do
    local idea = make({ kind = "Measure", form = "Loop", chordPace = "1.5 a bar", push = "None" }, seed)
    local u = idea.plan.units[1]
    if #u.rel >= 3 then
      all = all + 1
      local beats = {}
      for i = 1, 3 do beats[i] = (u.rel[i].e - u.rel[i].s) // 4 end
      if beats[1] == 3 and beats[2] == 2 and beats[3] == 3 or beats[1] == 3 and beats[2] == 3 and beats[3] == 2 then
        shaped = shaped + 1
      end
    end
  end
  ok(all > 0 and shaped == all, ("1.5 a bar lays three chords over two bars as 3+3+2 (or 3+2+3): %d of %d"):format(shaped, all))
  local rolled = false
  for seed = 1, 400 do
    local pace = make({ kind = "Measure" }, seed).r.chordPace
    if pace == "1.5 a bar" or pace == "4 a bar" then rolled = true end
  end
  ok(not rolled, "Any never rolls 1.5 or 4 a bar: they are there to be chosen, so 1.0's numbers keep their pace")
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

-- A Measure has no drums (since 1.3): melody, chords and bass.
do
  local drums = 0
  for seed = 1, 20 do
    local idea = make({ kind = "Measure" }, seed)
    for _, p in ipairs(idea.block.parts) do if p.name == "Drums" or p.drums then drums = drums + 1 end end
    for _, n in ipairs(idea.block.notes) do if n.chan == 9 then drums = drums + 1 end end
  end
  eq(drums, 0, "a Measure has no drum part and nothing on channel 10")
end

do
  local bad = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Measure", bass = "Pulse", push = "None" }, seed)
    local changes, pattern = {}, {}
    for _, sl in ipairs(idea.timeline) do changes[sl.s / 4] = true end
    -- The kick's pattern, drawn as the idea draws it (from the stream the
    -- Measure's drums drew from before 1.3, so the bass is unchanged).
    for _, k in ipairs(I.kickPattern(M44, idea.r, I.stream(seed, "drums"))) do pattern[k / 4] = true end
    if #part(idea, "Bass").notes == 0 then bad = bad + 1 end
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
-- 1.1: figures, push, swing and borrowed chords
------------------------------------------------------------------------------

-- With the 1.1 and 1.2 settings plain, every 1.0 idea number gives exactly
-- the 1.0 idea: the new settings draw last, and draw nothing when plain. These are
-- 1.0's own notes, hashed in sorted order (so the order notes that start
-- together are listed in does not matter), made by the 1.0 code itself.
-- A Measure is compared without its 1.0 drums (since 1.3 it has none):
-- its tune, chords and bass are 1.0's, note for note.
do
  local V10 = {
  { "Motif", 1, 646483193 },
  { "Motif", 7, 966472226 },
  { "Motif", 42, 1627035517 },
  { "Motif", 300, 871023702 },
  { "Motif", 999, 2564792285 },
  { "Motif", 4821, 360913389 },
  { "Motif", 12345, 3876152090 },
  { "Motif", 31337, 3193821783 },
  { "Motif", 77777, 3326774625 },
  { "Motif", 99999, 1577570922 },
  { "Phrase", 1, 2725931372 },
  { "Phrase", 7, 3949182337 },
  { "Phrase", 42, 1127454063 },
  { "Phrase", 300, 2740318878 },
  { "Phrase", 999, 79680367 },
  { "Phrase", 4821, 3652951295 },
  { "Phrase", 12345, 2973240363 },
  { "Phrase", 31337, 3216165730 },
  { "Phrase", 77777, 555389959 },
  { "Phrase", 99999, 1649638166 },
  { "Measure", 1, 3937425089 },
  { "Measure", 7, 1342217707 },
  { "Measure", 42, 699456568 },
  { "Measure", 300, 508197405 },
  { "Measure", 999, 2162486200 },
  { "Measure", 4821, 397537260 },
  { "Measure", 12345, 642620913 },
  { "Measure", 31337, 419754361 },
  { "Measure", 77777, 135430041 },
  { "Measure", 99999, 4245207203 },
  }
  local function hash(s)
    local h = 2166136261
    for i = 1, #s do h = ((h ~ s:byte(i)) * 16777619) % 4294967296 end
    return h
  end
  local bad = {}
  for _, v in ipairs(V10) do
    local b = make({ kind = v[1], figures = "Plain", push = "None", pull = "None", borrowed = "Off", swing = 0,
                     flavours = "Off", inversions = "Off" }, v[2]).block
    local f = {}
    for _, n in ipairs(b.notes) do f[#f + 1] = ("%g:%g:%d:%d:%d"):format(n.start, n.len, n.pitch, n.chan, n.vel) end
    table.sort(f)
    if hash(table.concat(f, " ")) ~= v[3] then bad[#bad + 1] = v[1] .. " " .. v[2] end
  end
  eq(#bad, 0, "with figures plain, no push, no borrowing and no swing, 1.0's ideas are unchanged: " ..
     table.concat(bad, ", "))
end

local function offGrid(x) return math.abs(x * 4 - math.floor(x * 4 + 0.5)) > 1e-6 end

-- Figures.
do
  local plainOff, triIdeas, dotIdeas, dotOff, compoundOff, threes = 0, 0, 0, 0, 0, 0
  for seed = 1, 60 do
    for _, kind in ipairs(I.KINDS) do
      local plain = make({ kind = kind, figures = "Plain", pace = "Flowing" }, seed)
      for _, n in ipairs(plain.block.notes) do if offGrid(n.start) then plainOff = plainOff + 1 end end
      local tri = make({ kind = kind, figures = "Triplets", pace = "Flowing" }, seed)
      local found = false
      for _, n in ipairs(tri.block.notes) do if offGrid(n.start) then found = true end end
      if found then triIdeas = triIdeas + 1 end
      -- Triplets come in threes: a note between the sixteenths belongs to a
      -- whole eighth-note triplet (three in a beat) or quarter-note triplet
      -- (three in two beats) starting on a beat.
      if tri.melody then
        local at = {}
        local function has(x) return at[("%.4f"):format(x)] end
        for _, n in ipairs(tri.melody) do at[("%.4f"):format(n.step)] = true end
        for _, n in ipairs(tri.melody) do
          if offGrid(n.step / 4) then
            local whole = false
            for _, span in ipairs({ 4 / 3, 8 / 3 }) do
              for k = 1, 2 do
                local g = n.step - k * span
                if math.abs(g / 4 - math.floor(g / 4 + 0.5)) < 1e-6 and has(g) and has(g + span) and has(g + 2 * span) then
                  whole = true
                end
              end
            end
            if not whole then threes = threes + 1 end
          end
        end
      end
      local dot = make({ kind = kind, figures = "Dotted", pace = "Flowing" }, seed)
      for _, n in ipairs(dot.block.notes) do if offGrid(n.start) then dotOff = dotOff + 1 end end
      if dot.melody then
        for i = 2, #dot.melody do
          local a, b = dot.melody[i - 1], dot.melody[i]
          if (a.step % 4 == 0 and b.step == a.step + 3) or (a.step % 4 == 0 and b.step == a.step + 6) then
            dotIdeas = dotIdeas + 1
            break
          end
        end
      end
      local six = make({ kind = kind, figures = "Triplets" }, seed, I.meter(6, 8))
      for _, n in ipairs(six.block.notes) do if offGrid(n.start) then compoundOff = compoundOff + 1 end end
    end
  end
  eq(plainOff, 0, "Plain puts nothing between the sixteenths")
  ok(triIdeas >= 90, "Triplets put triplets in most ideas: " .. triIdeas .. " of 180")
  eq(threes, 0, "and a melody's triplets come in threes")
  eq(dotOff, 0, "Dotted puts nothing between the sixteenths")
  ok(dotIdeas >= 40, "but dotted long-shorts into many tunes: " .. dotIdeas .. " of 120")
  eq(compoundOff, 0, "6/8 is already in threes: no triplets are laid over it")
end

-- Push.
do
  local noneP, lotsIdeas, early, kicks, restruck, tuneEarly, tuneTwice = 0, 0, 0, 0, 0, 0, 0
  for seed = 1, 60 do
    local none = make({ kind = "Measure", push = "None" }, seed)
    for _, sl in ipairs(none.timeline) do if sl.pushed or sl.s % 4 ~= 0 then noneP = noneP + 1 end end
    local lots = make({ kind = "Measure", push = "Lots", chordStyle = "Block" }, seed)
    local any = false
    local bassAt, chordAt, tuneAt = {}, {}, {}
    for _, n in ipairs(part(lots, "Bass").notes) do bassAt[n.start * 4] = true end
    for _, n in ipairs(part(lots, "Chords").notes) do chordAt[n.start * 4] = true end
    for _, n in ipairs(lots.melody) do tuneAt[n.step] = n end
    for _, sl in ipairs(lots.timeline) do
      if sl.pushed then
        any = true
        if (sl.s + 2) % 4 ~= 0 then early = early + 1 end
        if not bassAt[sl.s] then kicks = kicks + 1 end
        if chordAt[sl.s + 2] then restruck = restruck + 1 end
        if tuneAt[sl.s] and tuneAt[sl.s].pushed then tuneEarly = tuneEarly + 1 end
        if tuneAt[sl.s] and tuneAt[sl.s].pushed and tuneAt[sl.s + 2] then tuneTwice = tuneTwice + 1 end
      end
    end
    if any then lotsIdeas = lotsIdeas + 1 end
  end
  eq(noneP, 0, "with no push every chord arrives on the beat")
  ok(lotsIdeas >= 50, "with Lots, most Measures push chords: " .. lotsIdeas .. " of 60")
  eq(early, 0, "a pushed chord arrives exactly an eighth before its beat")
  eq(kicks, 0, "and the bass comes with it")
  eq(restruck, 0, "and a Block chord is not struck again on the beat it was pushed from")
  ok(tuneEarly > 20, "the tune's note on that beat often comes early too: " .. tuneEarly)
  eq(tuneTwice, 0, "and is not also played on the beat")
end

-- Swing.
do
  local moved, beats, sixteen, same, order, threes = 0, 0, 0, 0, 0, 0
  for seed = 1, 40 do
    local st = { kind = "Phrase", content = "Both", pace = "Busy", figures = "Mixed" }
    local straight = make(st, seed)
    st.swing = 100
    local swung = make(st, seed)
    for pi, sp in ipairs(swung.block.parts) do
    local a, b = straight.block.parts[pi].notes, sp.notes
    if #a ~= #b then order = order + 1 end
    for i = 1, math.min(#a, #b) do
      local x, y = a[i].start * 4, b[i].start * 4
      if a[i].pitch ~= b[i].pitch then order = order + 1 end
      local f = x % 4
      if offGrid(a[i].start) then
        if math.abs(x - y) > 1e-6 then threes = threes + 1 end
      elseif f == 0 then
        if math.abs(x - y) > 1e-6 then beats = beats + 1 end
      elseif f == 2 then
        if math.abs((y % 4) - 8 / 3) > 1e-6 then moved = moved + 1 end
      elseif f == 1 then
        if math.abs((y % 4) - 4 / 3) > 1e-6 then sixteen = sixteen + 1 end
      end
      if b[i].start + b[i].len > swung.block.beats + 1e-9 or b[i].len <= 0 then order = order + 1 end
    end
    end
    st.swing = 0
    if fingerprint(make(st, seed).block.notes) ~= fingerprint(straight.block.notes) then same = same + 1 end
  end
  eq(moved, 0, "at 100% swing every off-beat eighth lands two thirds of the way through its beat")
  eq(sixteen, 0, "the sixteenth before it moves in proportion")
  eq(beats, 0, "no note on a beat moves")
  eq(threes, 0, "triplets are left alone")
  eq(order, 0, "and nothing is reordered, lost, or pushed past the end")
  eq(same, 0, "0% swing is no swing")
  local six = make({ kind = "Motif", swing = 0 }, 5, I.meter(6, 8))
  local sixSwung = make({ kind = "Motif", swing = 100 }, 5, I.meter(6, 8))
  eq(fingerprint(sixSwung.block.notes), fingerprint(six.block.notes), "6/8 does not swing: it is in threes already")
  ok(not I.swings(I.meter(7, 8)), "nor 7/8")
  ok(I.swings(I.meter(2, 2)), "but 2/2 does")
end

-- Borrowed chords.
do
  local offAny, withOne, more, edge, inKey, sameScale, said, pent = 0, 0, 0, 0, 0, 0, 0, 0
  local n = 400
  for seed = 1, n do
    local kind = I.KINDS[seed % 3 + 1]
    local off = make({ kind = kind, borrowed = "Off", scale = "Any" }, seed)
    if #off.borrowed > 0 then offAny = offAny + 1 end
    for _, sl in ipairs(off.timeline) do if sl.borrowed then offAny = offAny + 1 end end
    local idea = make({ kind = kind, borrowed = "Rare", scale = "Any" }, seed)
    local count = 0
    for i, sl in ipairs(idea.timeline) do
      if sl.borrowed then
        count = count + 1
        if i == 1 or i >= #idea.timeline - 1 then edge = edge + 1 end
        -- It really is from outside the key.
        local home = scalePcs(idea.key)
        local outside = false
        for _, pc in ipairs(sl.chord.pcs) do if not home[pc] then outside = true end end
        if not outside then inKey = inKey + 1 end
        if sl.key.scale == idea.key.scale or sl.key.root ~= idea.key.root then sameScale = sameScale + 1 end
        local b = idea.borrowed[1]
        if not (b and b.text:find(sl.chord.name, 1, true) and b.text:find("from " .. I.keyName(sl.key), 1, true)
                and idea.chords:find(sl.chord.name .. (sl.bassPos and ("/" .. T.noteName(sl.key, sl.bassPos)) or "") .. "*", 1, true)) then
          said = said + 1
        end
      end
    end
    if count == 1 then withOne = withOne + 1 elseif count > 1 then more = more + 1 end
    if count ~= #idea.borrowed then said = said + 1 end
    local p = make({ kind = kind, borrowed = "Rare", scale = 10 }, seed)
    pent = pent + #p.borrowed
  end
  eq(offAny, 0, "with Borrowed off, nothing is borrowed")
  ok(withOne >= n * 0.1 and withOne <= n * 0.35,
     ("Rare is rare: %d of %d ideas borrow a chord"):format(withOne, n))
  eq(more, 0, "never more than one")
  eq(edge, 0, "never the first chord, nor the last two (the cadence stays the key's own)")
  eq(inKey, 0, "a borrowed chord always has a note from outside the key")
  eq(sameScale, 0, "from another scale on the same key note")
  eq(said, 0, "and the idea says which chord, where, and from which scale, and marks it *")
  eq(pent, 0, "a pentatonic scale borrows nothing")
end

-- Borrowing and pushing touch one pass of the harmony, so a unit that repeats
-- exactly must still sit on the chords under it - its ending included.
do
  local off, ends = 0, 0
  for seed = 1, 500 do
    local idea = make({ kind = "Measure", form = (seed % 2 == 0) and "Loop" or "Song",
                        borrowed = "Rare", push = "Lots" }, seed)
    local tl = { timeline = idea.timeline, key = idea.key }
    for _, n in ipairs(idea.melody) do
      if I.strength(idea.meter or M44, n.step) >= 2 and not T.onChord(I.keyAt(tl, n.step), I.chordAt(idea.timeline, n.step).chord, n.pos) then
        off = off + 1
      end
    end
    local f = idea.melody[#idea.melody]
    if not T.onChord(I.keyAt(tl, f.step), I.chordAt(idea.timeline, f.step).chord, f.pos) then ends = ends + 1 end
  end
  eq(off, 0, "a repeated unit's notes on the beat sit on the chords under them, borrowed or pushed")
  eq(ends, 0, "and its last note on the chord it ends over")
end

-- What it borrows is what a player would: in C major, from C minor, the iv,
-- bVI, bVII and bIII; in A minor, the major IV from Dorian.
do
  local seen = {}
  for seed = 1, 3000 do
    local idea = make({ kind = "Measure", borrowed = "Rare", root = 1, scale = 1, colour = "Triads" }, seed)
    for _, b in ipairs(idea.borrowed) do seen[b.name .. " " .. b.numeral .. " " .. b.from] = true end
  end
  ok(seen["Fm iv C Minor"], "Fm, the iv of C minor")
  ok(seen["Ab bVI C Minor"], "Ab, its bVI")
  ok(seen["Bb bVII C Minor"] or seen["Bb bVII C Mixolydian"], "Bb, the bVII")
  ok(seen["Eb bIII C Minor"], "Eb, the bIII")
  local minor = {}
  for seed = 1, 3000 do
    local idea = make({ kind = "Measure", borrowed = "Rare", root = 14, scale = 2, colour = "Triads" }, seed)
    for _, b in ipairs(idea.borrowed) do minor[b.name .. " " .. b.numeral .. " " .. b.from] = true end
  end
  ok(minor["D IV A Dorian"], "and D, the IV of A Dorian, in A minor")
end

-- The tune bends to a borrowed chord: under Ab in C major it plays Ab and
-- Eb, not A and E.
do
  local bent, wrong = 0, 0
  for seed = 1, 2000 do
    local idea = make({ kind = "Phrase", content = "Both", borrowed = "Rare", root = 1, scale = 1 }, seed)
    for _, sl in ipairs(idea.timeline) do
      if sl.borrowed and sl.key.scale == 2 then
        for _, nt in ipairs(idea.melody) do
          if nt.step >= sl.s and nt.step < sl.e then
            local pc = nt.pitch % 12
            if pc == 8 or pc == 3 or pc == 10 then bent = bent + 1 end
            if pc == 9 or pc == 4 or pc == 11 then wrong = wrong + 1 end
          end
        end
      end
    end
  end
  ok(bent > 0, "the tune plays the borrowed scale's notes under a chord borrowed from C minor: " .. bent)
  eq(wrong, 0, "and never the key's own A, E or B against it")
end

------------------------------------------------------------------------------
-- 1.2: pull, figures in the chords and bass, drums on their own
------------------------------------------------------------------------------

-- Pull: the chords part lies back an eighth; the tune, bass and drums stay.
do
  local nonePulled, lotsIdeas, late, early, held, tuneMoved, motif = 0, 0, 0, 0, 0, 0, 0
  for seed = 1, 60 do
    local none = make({ kind = "Measure", pull = "None" }, seed)
    for _, sl in ipairs(none.chordTimeline) do if sl.pulled then nonePulled = nonePulled + 1 end end
    local lots = make({ kind = "Measure", pull = "Lots", push = "None", chordStyle = "Block" }, seed)
    local plain = make({ kind = "Measure", pull = "None", push = "None", chordStyle = "Block" }, seed)
    if fingerprint(part(lots, "Melody").notes) ~= fingerprint(part(plain, "Melody").notes)
       or fingerprint(part(lots, "Bass").notes) ~= fingerprint(part(plain, "Bass").notes) then
      tuneMoved = tuneMoved + 1
    end
    for _, sl in ipairs(lots.timeline) do if sl.pulled then tuneMoved = tuneMoved + 1 end end
    local any = false
    local starts = {}
    for _, n in ipairs(part(lots, "Chords").notes) do starts[#starts + 1] = n end
    for i, sl in ipairs(lots.chordTimeline) do
      if sl.pulled then
        any = true
        if sl.s - sl.beat ~= 2 or sl.beat % 4 ~= 0 then late = late + 1 end
        local prev = lots.chordTimeline[i - 1]
        for _, n in ipairs(starts) do
          local x = n.start * 4
          -- Nothing is struck between the beat and the pull...
          if x >= sl.beat - 1e-6 and x < sl.s - 1e-6 then early = early + 1 end
        end
        -- ...and the chord before is still sounding there.
        local sounding = false
        for _, n in ipairs(starts) do
          local x, e = n.start * 4, (n.start + n.len) * 4
          if x < sl.beat and e >= sl.s - 1e-6 and prev.chord.has[n.pitch % 12] then sounding = true end
        end
        if not sounding then held = held + 1 end
      end
    end
    if any then lotsIdeas = lotsIdeas + 1 end
    local m = make({ kind = "Motif", pull = "Lots" }, seed)
    for _, sl in ipairs(m.chordTimeline) do if sl.pulled then motif = motif + 1 end end
  end
  eq(nonePulled, 0, "with no pull every chord is played on its beat")
  ok(lotsIdeas >= 50, "with Lots, most Measures pull chords: " .. lotsIdeas .. " of 60")
  eq(late, 0, "a pulled chord arrives exactly an eighth after its beat")
  eq(early, 0, "nothing is struck between the beat and the pull")
  eq(held, 0, "the chord before is held to meet it")
  eq(tuneMoved, 0, "the tune, the bass and the drums stay on the beat")
  eq(motif, 0, "a motif has no chords to pull")
end

-- Figures reach the chords, and a moving bass.
do
  local function count(settings, part_, test)
    local n = 0
    for seed = 1, 60 do
      local idea = make(settings, seed)
      for _, x in ipairs(part(idea, part_).notes) do if test(x.start * 4, idea) then n = n + 1 end end
    end
    return n
  end
  local function stab(x) return math.abs(x % 16 - 6) < 1e-6 end
  local function third(x) return offGrid(x / 4) end
  local base = { kind = "Phrase", content = "Chords", chordPace = "One a bar", push = "None", pull = "None" }
  local function with(extra)
    local s = {}
    for k, v in pairs(base) do s[k] = v end
    for k, v in pairs(extra) do s[k] = v end
    return s
  end
  ok(count(with({ chordStyle = "Block", figures = "Dotted" }), "Chords", stab) > 0,
     "Dotted: a held chord is struck again a dotted quarter in, now and then")
  eq(count(with({ chordStyle = "Block", figures = "Plain" }), "Chords", stab), 0, "never when Plain")
  ok(count(with({ chordStyle = "Block", figures = "Triplets" }), "Chords", third) > 0,
     "Triplets: quarter-note triplet stabs")
  local function dotted16(x) return math.abs(x % 4 - 3) < 1e-6 end
  ok(count(with({ chordStyle = "Broken", figures = "Dotted", pace = "Flowing" }), "Chords", dotted16) > 0,
     "Dotted: an arpeggio goes long-short")
  eq(count(with({ chordStyle = "Broken", figures = "Plain", pace = "Flowing" }), "Chords", dotted16), 0,
     "and not when Plain")
  local function dottedQuarter(x) return math.abs(x % 8 - 6) < 1e-6 end
  ok(count({ kind = "Measure", bass = "Moving", figures = "Dotted", pace = "Flowing", push = "None" }, "Bass", dottedQuarter) > 0,
     "Dotted: a moving bass goes dotted quarter and eighth")
  eq(count({ kind = "Measure", bass = "Moving", figures = "Plain", pace = "Flowing", push = "None" }, "Bass", dottedQuarter), 0,
     "and walks straight when Plain")
end

-- 1.4: the tune's quarters and halves take figures too, so the tune and the
-- chords are figured together.
do
  local function zero() return 0 end
  local function show(list)
    local o = {}
    for i, x in ipairs(list) do o[i] = ("%.2f"):format(x) end
    return table.concat(o, " ")
  end
  eq(show(I.figure(M44, 0, 16, { 0, 8 }, "Triplets", zero, true)), "0.00 2.67 5.33 8.00",
     "in the tune a half note becomes a quarter-note triplet")
  eq(show(I.figure(M44, 0, 16, { 0, 4, 6, 8, 12 }, "Dotted", zero, true)), "0.00 3.00 4.00 7.00 8.00 14.00",
     "and a quarter a dotted eighth and a sixteenth")
  eq(show(I.figure(M44, 0, 16, { 0, 4, 6, 8, 12 }, "Dotted", zero)), "0.00 4.00 7.00 8.00 14.00",
     "but not in the chords, which play on every beat already")
  eq(show(I.figure(M44, 0, 16, { 0, 8 }, "Plain", zero, true)), "0.00 8.00", "and never when Plain")
  local function triBeats(notes, get)
    local beats, n = {}, 0
    for _, x in ipairs(notes) do
      local s = get(x)
      if offGrid(s) and not beats[math.floor(s + 1e-9)] then beats[math.floor(s + 1e-9)] = true; n = n + 1 end
    end
    return n
  end
  local both, tuneBeats, beats = 0, 0, 0
  for seed = 1, 60 do
    local idea = make({ kind = "Phrase", content = "Both", figures = "Triplets", push = "None", pull = "None" }, seed)
    local t = triBeats(part(idea, "Melody").notes, function(n) return n.start end)
    local c = triBeats(part(idea, "Chords").notes, function(n) return n.start end)
    if t > 0 and c > 0 then both = both + 1 end
    tuneBeats, beats = tuneBeats + t, beats + idea.block.beats
  end
  ok(both >= 34, ("with Triplets, most phrases have triplets in the tune and the chords at once: %d of 60"):format(both))
  ok(tuneBeats / beats >= 0.2, ("and a fifth or more of the tune's beats are triplets: %.0f%%"):format(100 * tuneBeats / beats))
end

-- The Measure's drums switch is retired: in 1.2 a Measure always had drums,
-- and since 1.3 it has none.
do
  local st = I.newState()
  st.drums = "On"
  I.clampState(st)
  eq(st.drums, "Off", "an old saved drums=On comes back Off")
  local noDrums = true
  for seed = 1, 20 do if part(make({ kind = "Measure" }, seed), "Drums") then noDrums = false end end
  ok(noDrums, "and no Measure has drums")
end

-- Drums on their own.
do
  local D = I.DRUM
  local styleOk, halfOk, fourOk, breakFallback, rideOk, shuffle, calmHats, answers, same = 0, 0, 0, 0, 0, 0, 0, 0, 0
  for seed = 1, 40 do
    local four = make({ kind = "Drums", beat = "Four on the floor", fills = "None", drumBars = 2 }, seed)
    local kicks = {}
    for _, n in ipairs(four.block.notes) do if n.pitch == D.kick then kicks[n.start] = true end end
    local every = true
    for b = 0, 7 do if not kicks[b] then every = false end end
    if every then fourOk = fourOk + 1 end
    local half = make({ kind = "Drums", beat = "Half-time", fills = "None", drumBars = 2 }, seed)
    local snares = {}
    for _, n in ipairs(half.block.notes) do if n.pitch == D.snare then snares[#snares + 1] = n.start % 4 end end
    local only3 = #snares > 0
    for _, x in ipairs(snares) do if x ~= 2 then only3 = false end end
    if only3 then halfOk = halfOk + 1 end
    local br = make({ kind = "Drums", beat = "Breakbeat" }, seed, I.meter(3, 4))
    if br.drums.style == "Backbeat" then breakFallback = breakFallback + 1 end
    local ride = make({ kind = "Drums", cymbal = "Ride", pace = "Flowing" }, seed)
    local r51, h42 = 0, 0
    for _, n in ipairs(ride.block.notes) do
      if n.pitch == D.ride then r51 = r51 + 1 end
      if n.pitch == D.hat then h42 = h42 + 1 end
    end
    if r51 > 0 and h42 == 0 then rideOk = rideOk + 1 end
    local tri = make({ kind = "Drums", figures = "Triplets", pace = "Flowing", cymbal = "Hats" }, seed)
    for _, n in ipairs(tri.block.notes) do if n.pitch == D.hat and offGrid(n.start) then shuffle = shuffle + 1; break end end
    local calm = make({ kind = "Drums", pace = "Calm", cymbal = "Hats", figures = "Plain", fills = "None" }, seed)
    local quarters = true
    for _, n in ipairs(calm.block.notes) do if n.pitch == D.hat and n.start % 1 ~= 0 then quarters = false end end
    if quarters then calmHats = calmHats + 1 end
    -- The second bar answers the first: not the same bar twice.
    local two = make({ kind = "Drums", drumBars = 2, fills = "None" }, seed)
    local bars = { {}, {} }
    for _, n in ipairs(two.block.notes) do
      local b = n.start < 4 and 1 or 2
      bars[b][#bars[b] + 1] = ("%g:%d"):format(n.start % 4, n.pitch)
    end
    table.sort(bars[1]); table.sort(bars[2])
    if table.concat(bars[1], " ") ~= table.concat(bars[2], " ") then answers = answers + 1 end
    -- Settings that do not show for drums do not change them.
    local a = make({ kind = "Drums", root = 1, scale = 1, contour = "Arch", chordStyle = "Block", form = "Loop" }, seed)
    local b = make({ kind = "Drums", root = 4, scale = 2, contour = "Fall", chordStyle = "Broken", form = "Song" }, seed)
    if fingerprint(a.block.notes) == fingerprint(b.block.notes) then same = same + 1 end
  end
  eq(fourOk, 40, "Four on the floor: a kick on every beat")
  eq(halfOk, 40, "Half-time: the snare on 3 only")
  eq(breakFallback, 40, "a Breakbeat in 3/4 is played as a backbeat, and says so")
  eq(rideOk, 40, "on the ride, the time is on the ride, not the hats")
  ok(shuffle >= 35, "in triplets the hats shuffle: " .. shuffle .. " of 40")
  eq(calmHats, 40, "a calm groove keeps time in quarters")
  ok(answers >= 30, "the second bar answers the first, mostly: " .. answers .. " of 40")
  eq(same, 40, "the key, the tune and the chords settings do not touch a drum idea")
  -- Every length from 1 to 16 bars.
  local lengths = true
  for bars = 1, 16 do
    local idea = make({ kind = "Drums", drumBars = bars }, bars)
    if math.abs(idea.block.beats - bars * 4) > 1e-9 then lengths = false end
  end
  ok(lengths, "drum ideas from 1 to 16 bars")
  -- Fills: where they are asked for (the sweep checks every idea), and of
  -- every kind.
  local kinds = {}
  for seed = 1, 200 do
    local idea = make({ kind = "Drums", fills = "Every 2 bars", figures = "Mixed" }, seed)
    for _, k in ipairs(idea.drums.fillKinds) do kinds[k] = true end
  end
  ok(kinds.roll and kinds.toms and kinds["snare and toms"] and kinds.triplets,
     "fills come as snare rolls, tom runs, both, and triplets")
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

------------------------------------------------------------------------------
-- 1.5: flavours, voicings and inversions
------------------------------------------------------------------------------

-- The slots a cadence owns: each closing unit's last chord, and the one
-- leading to a full or imperfect close.
local function cadenceOwned(idea)
  local tl, keep = idea.timeline, {}
  keep[tl[1]], keep[tl[#tl]] = true, true
  for _, u in ipairs(idea.plan.units) do
    if u.cad ~= "none" then
      keep[u.slots[#u.slots]] = true
      if (u.cad == "PAC" or u.cad == "IAC") and #u.slots > 1 then keep[u.slots[#u.slots - 1]] = true end
    end
  end
  return keep
end

-- Flavours: with Mixed on Rare, every kind turns up, now and then, and
-- never on the first chord or a cadence's; with Off, or another colour, or a
-- scale without seven notes, none.
do
  local seen, owned, off, with, n = {}, 0, 0, 0, 200
  for seed = 1, n do
    local idea = make({ kind = "Measure", colour = "Mixed", flavours = "Rare", scale = 1 }, seed)
    local keep = cadenceOwned(idea)
    local any = false
    for _, sl in ipairs(idea.timeline) do
      if sl.flavour then
        any = true
        seen[sl.flavour] = true
        if keep[sl] then owned = owned + 1 end
      end
    end
    if any then with = with + 1 end
    for _, st in ipairs({ { colour = "Mixed", flavours = "Off" }, { colour = "Sevenths" }, { colour = "Triads" },
                          { colour = "Mixed", scale = 10 } }) do
      st.kind = "Measure"
      for _, sl in ipairs(make(st, seed).timeline) do if sl.flavour then off = off + 1 end end
    end
  end
  for _, f in ipairs(T.FLAVOURS) do ok(seen[f], "with Mixed and Flavours on Rare, " .. f .. " turns up") end
  ok(with >= n * 0.2 and with <= n * 0.75, ("now and then: in %d of %d Measures"):format(with, n))
  eq(owned, 0, "never the first chord, the last, or a cadence's")
  eq(off, 0, "and never with Flavours off, with Triads or Sevenths, or in a pentatonic scale")
end

-- A Loop's flavours come round with it: each time round, the same chords
-- (but for each round's last, which the last round's cadence keeps plain).
do
  local bad, flavoured = 0, 0
  for seed = 1, 60 do
    local idea = make({ kind = "Measure", form = "Loop", colour = "Mixed", flavours = "Rare", measureBars = 16,
                        borrowed = "Off" }, seed)
    local units = idea.plan.units
    local function names(u)
      local out = {}
      for i = 1, #u.slots - 1 do out[i] = u.slots[i].chord.name end
      return table.concat(out, " ")
    end
    for _, u in ipairs(units) do
      for _, sl in ipairs(u.slots) do if sl.flavour then flavoured = flavoured + 1 end end
      if names(u) ~= names(units[1]) then bad = bad + 1 end
    end
  end
  ok(flavoured > 0, "Loops take flavours")
  eq(bad, 0, "and play the same flavoured chords each time round")
end

-- Voicings: in a Measure, held chords, each stack is the voicing it says.
do
  local bad = {}
  local function check(good, what) if not good then bad[#bad + 1] = what end end
  for _, style in ipairs(T.VOICINGS) do
    for seed = 1, 12 do
      local idea = make({ kind = "Measure", voicing = style, chordStyle = "Block", figures = "Plain",
                          push = "None", pull = "None", colour = (seed % 2 == 0) and "Sevenths" or "Triads" }, seed)
      local stacks = {}
      for _, n in ipairs(part(idea, "Chords").notes) do
        local k = n.start
        stacks[k] = stacks[k] or {}
        table.insert(stacks[k], n.pitch)
      end
      for at, v in pairs(stacks) do
        table.sort(v)
        local ch = I.chordAt(idea.timeline, math.floor(at * 4 + 0.5)).chord
        local tag = ("%s seed %d %s"):format(style, seed, ch.name)
        local root = false
        for _, p in ipairs(v) do if p % 12 == ch.rootPc then root = true end end
        if style == "Open" and #v >= 3 then check(v[1] % 12 == ch.rootPc and v[#v] - v[1] > 12, tag .. " spread from its root")
        elseif style == "Shell" and #ch.pcs >= 3 then check(#v == 3 and v[1] % 12 == ch.rootPc, tag .. " three notes on its root")
        elseif style == "Rootless" and ch.nine and #ch.pcs >= 3 then check(not root, tag .. " has no root")
        elseif (style == "Drop 2" or style == "Drop 3" or style == "Drop 2 & 4") and #ch.pcs >= 3 then check(#v == 4, tag .. " four voices") end
      end
    end
  end
  eq(#bad, 0, "every voicing is laid out as it says, in real ideas: " .. table.concat(bad, "; "))
  -- The voicing changes the chords' notes, never the tune or the bass.
  local moved = 0
  for seed = 1, 30 do
    local a = make({ kind = "Measure", voicing = "Close" }, seed)
    local b = make({ kind = "Measure", voicing = "Drop 2 & 4" }, seed)
    if fingerprint(part(a, "Melody").notes) ~= fingerprint(part(b, "Melody").notes)
       or fingerprint(part(a, "Bass").notes) ~= fingerprint(part(b, "Bass").notes) then moved = moved + 1 end
  end
  eq(moved, 0, "the voicing leaves the tune and the bass alone")
  -- Under a Phrase, the chords' own bass note is under the voicing.
  local over = 0
  for seed = 1, 30 do
    local idea = make({ kind = "Phrase", content = "Chords", voicing = "Open", chordStyle = "Block",
                        figures = "Plain", push = "None", pull = "None" }, seed)
    local at = {}
    for _, n in ipairs(part(idea, "Chords").notes) do
      at[n.start] = at[n.start] or {}
      table.insert(at[n.start], n.pitch)
    end
    for t, v in pairs(at) do
      table.sort(v)
      local sl = I.chordAt(idea.chordTimeline, math.floor(t * 4 + 0.5))
      if v[1] % 12 ~= I.bassPcOf(sl) or (v[2] and v[2] <= v[1]) then over = over + 1 end
    end
  end
  eq(over, 0, "a Phrase's bass note stays under a spread voicing")
end

-- Inversions: rare, all three kinds, each where it does its job.
do
  local kinds, owned, wrong, off, with, tuned, slash, n = {}, 0, {}, 0, 0, 0, 0, 200
  local function byStep(a, b) local d = (a - b) % 12; return d == 1 or d == 2 or d == 10 or d == 11 end
  for seed = 1, n do
    local idea = make({ kind = "Measure", inversions = "Rare" }, seed)
    local tl, keep = idea.timeline, cadenceOwned(idea)
    local any = false
    for i, sl in ipairs(tl) do
      if sl.inversion then
        any = true
        kinds[sl.inversion] = true
        local before, after = tl[i - 1], tl[i + 1]
        if keep[sl] then owned = owned + 1 end
        local b, pb, nb = I.bassPcOf(sl), before and I.bassPcOf(before), after and I.bassPcOf(after)
        local tag = ("seed %d %s"):format(seed, idea.chords)
        if not (pb and nb) then wrong[#wrong + 1] = "an end " .. tag
        elseif sl.inversion == 1 and not (byStep(pb, b) or byStep(b, nb)) then
          -- (Unless it is the chord a third inversion resolved to.)
          if not (before.inversion == 3 and byStep(pb, b)) then wrong[#wrong + 1] = "first, no step " .. tag end
        elseif sl.inversion == 2 then
          local pedal = b == pb and b == nb
          local passing = byStep(pb, b) and byStep(b, nb) and pb ~= nb
          local cadential = sl.degree == 0 and T.rootAbove(sl.key, after.degree) == 7
          local resolved = before.inversion == 3 and byStep(pb, b)
          if not (pedal or passing or cadential or resolved) then wrong[#wrong + 1] = "second, no 6/4 " .. tag end
        elseif sl.inversion == 3 then
          local d = (b - nb) % 12
          if d ~= 1 and d ~= 2 then wrong[#wrong + 1] = "third, seventh not falling a step " .. tag end
        end
        local name = sl.chord.name .. "/" .. T.noteName(sl.key, sl.bassPos)
        if not idea.chords:find(name, 1, true) then slash = slash + 1 end
      end
    end
    if any then with = with + 1 end
    local o = make({ kind = "Measure", inversions = "Off" }, seed)
    for _, sl in ipairs(o.timeline) do if sl.inversion then off = off + 1 end end
    if fingerprint(part(o, "Melody").notes) ~= fingerprint(part(idea, "Melody").notes) then tuned = tuned + 1 end
  end
  ok(kinds[1] and kinds[2] and kinds[3], "Inversions on Rare brings first, second and third inversions")
  ok(with >= n * 0.15 and with <= n * 0.7, ("now and then: in %d of %d Measures"):format(with, n))
  eq(owned, 0, "never the first chord, the last, or a cadence's")
  eq(#wrong, 0, "each where it does its job - the bass by step, a 6/4 cadential, passing or held, a seventh falling: " ..
     table.concat(wrong, "; "))
  eq(slash, 0, "and written over its bass note: C/E")
  eq(off, 0, "with Inversions off, none")
  eq(tuned, 0, "an inversion moves the bass, never the tune")
end

-- Hidden, they change nothing: no chords, no flavours, voicing or
-- inversions; no Mixed, no flavours.
do
  local bad = 0
  for seed = 1, 30 do
    local a = make({ kind = "Motif", flavours = "Off", voicing = "Close", inversions = "Off" }, seed)
    local b = make({ kind = "Motif", flavours = "Rare", voicing = "Rootless", inversions = "Rare" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then bad = bad + 1 end
    local c = make({ kind = "Measure", colour = "Triads", flavours = "Off" }, seed)
    local d = make({ kind = "Measure", colour = "Triads", flavours = "Rare" }, seed)
    if fingerprint(c.block.notes) ~= fingerprint(d.block.notes) then bad = bad + 1 end
  end
  eq(bad, 0, "the new chord settings, hidden, change nothing")
end

C.done()
