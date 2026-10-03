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
  -- (1.13: an idea walks or plays a named progression, half and half. A
  -- test that does not say walks, so it tests what it means to; the sweep
  -- says, and plays both.)
  st.progression = "Walk"
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
      if r.velocity == "Shaped" then
        rule("a shaped velocity is a real one, 1 to 127", n.vel >= 1 and n.vel <= 127, tag)
      else
        rule("velocity is 100, or 115 when accented",
             n.vel == 100 or (r.velocity == "Accents" and n.vel == I.ACCENT), tag)
      end
      if not p.drums then
        rule("every pitched note is in the scale sounding under it", inKeyAt(n.start * 4, n.pitch % 12),
             tag .. " " .. p.name .. " " .. T.pitchName(n.pitch))
      end
      if p.drums then rule("the drums are on channel 10", n.chan == 9, tag) end
    end
  end

  if r.kind == "Drums" then return auditDrums(idea, tag) end

  -- What the parts are (and a second voice, last, when there is a tune and
  -- one is asked for: 1.10).
  local sv2 = (r.secondVoice ~= "Off" and r.melody) and " Second voice" or ""
  local got = {}
  for _, p in ipairs(b.parts) do got[#got + 1] = p.name end
  got = table.concat(got, " ")
  if r.kind == "Motif" then
    rule("a motif is a tune only", got == "Melody" .. sv2, tag)
  elseif r.kind == "Phrase" then
    local want = ({ Melody = "Melody", Chords = "Chords", Both = "Melody Chords" })[r.content]
    rule("a phrase is what its content says", got == want .. sv2, tag)
    rule("a phrase is one item", b.layout == "one", tag)
  else
    rule("a measure is melody, chords and bass", got == "Melody Chords Bass" .. sv2, tag)
    rule("a measure's layout is what it says",
         b.layout == (r.layout == "Tracks" and "tracks" or "one"), tag)
  end

  -- The chords: the timeline covers the idea, and its ending is the plan's.
  local tl = idea.timeline
  rule("the chords start at the start", tl[1].s == 0, tag)
  rule("and end at the end", tl[#tl].e == b.beats * 4, tag)
  for i = 2, #tl do
    rule("each chord starts where the last ended", tl[i].s == tl[i - 1].e, tag)
    -- (But for the same chord with its bass moving, as the galant Meyer's
    -- V4/3 to V6/5.)
    rule("no chord follows itself", tl[i].degree ~= tl[i - 1].degree
         or I.bassPcOf(tl[i]) ~= I.bassPcOf(tl[i - 1]), tag .. " " .. idea.chords)
    rule("chords change on a beat, or an eighth before one when pushed",
         tl[i].s % meter.beat == 0 or (tl[i].pushed and (tl[i].s + 2) % meter.beat == 0), tag)
  end
  -- (Unless the opening unit only has room for its ending: a one-bar phrase
  -- that closes is V-I.)
  local u1 = idea.plan.units[1]
  local tailLen = (u1.cad == "PAC" or u1.cad == "IAC") and 2 or 1
  -- (A named progression opens where it opens: the singer-songwriter on vi.)
  rule("an idea opens on the tonic chord", tl[1].degree == 0 or #u1.rel <= tailLen
       or (idea.schema and tl[1].spec ~= nil), tag .. " " .. idea.chords)
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

  -- Applied chords (1.8): each the dominant or the leading-tone chord of
  -- the chord after it, and never two running.
  for i, sl in ipairs(tl) do
    if sl.applied then
      local nx = tl[i + 1]
      rule("an applied chord leads to another chord", nx ~= nil, tag)
      if nx then
        local up = (nx.chord.rootPc - sl.chord.rootPc) % 12
        if sl.applied.kind == "V" then
          rule("an applied V is major, a fifth above the chord it leads to",
               up == 5 and sl.chord.quality == "major", tag .. " " .. idea.chords)
        else
          rule("an applied leading-tone chord is diminished, a semitone under the chord it leads to",
               up == 1 and sl.chord.quality == "diminished", tag .. " " .. idea.chords)
        end
        rule("never two applied chords running", not (tl[i - 1] and tl[i - 1].applied), tag)
      end
    end
  end
  -- In a key on the Minor scale the V is major, its third the raised
  -- seventh (1.13; Hutchinson, Figure 7.3.1) - but for a named chord.
  if T.SCALES[key.scale].name == "Minor" then
    for _, sl in ipairs(tl) do
      if sl.degree == 4 and not sl.spec and not sl.moved and not sl.applied and not sl.borrowed and not sl.flavour then
        rule("in a minor key the V is major", sl.chord.has[(T.pc(key, 6) + 1) % 12] == true, tag .. " " .. idea.chords)
      end
    end
  end
  -- An evaded close (1.13): a cadence chord, then I6 - and the tune does
  -- not land on do.
  for _, u in ipairs(idea.plan.units) do
    if u.cad == "EC" and u.slots and #u.slots >= 2 and idea.schema ~= "Blues" then
      local last = u.slots[#u.slots]
      rule("an evaded close ends on the tonic", last.degree == 0, tag .. " " .. idea.chords)
      if u.notes and #u.notes > 0 and idea.schema ~= "Blues" then
        local n = u.notes[#u.notes]
        rule("at an evaded close the tune does not land on do", n.pos % T.scaleLen(key) ~= 0, tag)
      end
    end
  end
  -- A deceptive close (1.8): a cadence chord, then vi. (Not in the blues,
  -- which plays its own changes bar by bar.)
  for _, u in ipairs(idea.plan.units) do
    if u.cad == "DC" and T.scaleLen(key) == 7 and u.slots and #u.slots >= 2 and idea.schema ~= "Blues" then
      local last, before = u.slots[#u.slots], u.slots[#u.slots - 1]
      rule("a deceptive close goes from a cadence chord to vi",
           last.degree == 5 and CADENCE_PCS(key)[before.degree] == true, tag .. " " .. idea.chords)
    end
  end

  -- The tune.
  local mel = idea.melody
  if mel then
    local steps, moves, leaps, run = 0, 0, 0, 1
    local lo, hi = 127, 0
    for i, n in ipairs(mel) do
      lo, hi = math.min(lo, n.pitch), math.max(hi, n.pitch)
      -- (But for an appoggiatura, which is off the chord on purpose: 1.10.)
      if I.strength(meter, n.step) >= 2 and n.tension ~= "appoggiatura" then
        local ch = I.chordAt(tl, n.step).chord
        rule("a note on the beat is on the chord", T.onChord(I.keyAt(tlctx, n.step), ch, n.pos),
             ("%s step %d %s over %s"):format(tag, n.step, T.pitchName(n.pitch, key), ch.name))
      end
      -- Tension (1.10): each does what the books say it does.
      if n.tension then
        local nx, pv = mel[i + 1], mel[i - 1]
        local what = ("%s step %g %s %s"):format(tag, n.step, n.tension, idea.chords)
        rule("a tension note is not the tune's last", nx ~= nil, what)
        if nx then
          local nsl = I.chordAt(tl, nx.step)
          local nkey = I.keyAt(tlctx, nx.step)
          if n.tension == "anticipation" then
            rule("an anticipation is a close's last note early, struck again on the beat",
                 nx.pitch == n.pitch and nx.closes and I.strength(meter, nx.step) >= 2
                 and I.strength(meter, n.step) < 2 and nx.step - n.step == 2, what)
          else
            rule("a suspension or an appoggiatura falls a step to a note of the chord",
                 nx.pos == n.pos - 1 and T.onChord(nkey, nsl.chord, nx.pos), what)
            rule("a suspension or an appoggiatura is a dissonance", not T.onChord(nkey, nsl.chord, n.pos), what)
            local bass = nsl.chord.rootPc
            if r.partWriting == "By the book" and r.chords then
              bass = I.bassPcOf(I.chordAt((r.kind == "Measure") and tl or idea.chordTimeline, nx.step))
            end
            rule("a tension note is never a minor ninth over the bass", (n.pitch - bass) % 12 ~= 1, what)
            rule("a tension note falls onto the bass's note only for the root (9-8)",
                 nx.pitch % 12 ~= bass or bass == nsl.chord.rootPc, what)
          end
          if n.tension == "appoggiatura" then
            rule("an appoggiatura is on the beat, leapt up to",
                 I.strength(meter, n.step) >= 2 and pv ~= nil and n.pos - pv.pos >= 2, what)
          elseif n.tension == "suspension" then
            local here = I.chordAt(tl, n.step)
            rule("a suspension is prepared: a note of the chord before, held over the change",
                 here ~= nsl and T.onChord(I.keyAt(tlctx, n.step), here.chord, n.pos)
                 and nsl.s < nx.step and n.step + n.len >= nx.step - 1e-9, what)
          end
        end
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
        -- Two leaps the same way outline a consonant triad (1.13; inside a
        -- statement).
        local q = mel[i - 2]
        if q and not n.first and not p.first then
          local i1, i2 = p.pos - q.pos, n.pos - p.pos
          if math.abs(i1) >= 2 and math.abs(i2) >= 2 and i1 * i2 > 0 then
            rule("two leaps the same way outline a triad", I.outlinesTriad(q.pitch, p.pitch, n.pitch),
                 ("%s %s %s %s"):format(tag, T.pitchName(q.pitch), T.pitchName(p.pitch), T.pitchName(n.pitch)))
          end
        end
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

  -- The second voice (1.10): under every note of the tune, a third, a fourth
  -- or a sixth (a fifth at most rarely), on the chord on the beat.
  local sv = part(idea, "Second voice")
  rule("a second voice is there only when asked for", (sv ~= nil) == (r.secondVoice ~= "Off" and mel ~= nil), tag)
  if sv and mel then
    local mp = part(idea, "Melody")
    rule("the second voice has a note under each of the tune's", #sv.notes == #mp.notes, tag)
    if #sv.notes == #mp.notes then
      for i, n in ipairs(sv.notes) do
        local t = mp.notes[i]
        local gap = t.pitch - n.pitch
        rule("the second voice is a third to a sixth under the tune",
             n.start == t.start and (gap == 3 or gap == 4 or gap == 5 or gap == 7 or gap == 8 or gap == 9), tag)
      end
    end
    for _, t in ipairs(mel) do
      if I.strength(meter, t.step) >= 2 and not t.tension and not I.offGrid(t.step) then
        for _, n in ipairs(sv.notes) do
          if math.abs(n.start * 4 - t.step) < 1e-6 then
            rule("on the beat the second voice is on the chord",
                 I.chordAt(tl, t.step).chord.has[n.pitch % 12] == true, tag .. " " .. idea.chords)
          end
        end
      end
    end
  end

  local cp = part(idea, "Chords")
  -- The 1.11 chord styles and named rhythms, in a Measure (a Phrase's own
  -- bass is struck at the bar lines in every style).
  if r.kind == "Measure" and cp then
    local ctl = idea.chordTimeline
    local onsets = {}
    for _, n in ipairs(cp.notes) do onsets[n.start * 4] = n end
    local arrive = {}
    for _, sl in ipairs(ctl) do arrive[sl.s] = true end
    local named = I.rhythmOf(meter, r.groove)
    local inBar = {}
    for _, t in ipairs(named or {}) do inBar[t] = true end
    for st, n in pairs(onsets) do
      if r.chordStyle == "Pedal" then
        rule("a pedal chord is struck only where its chord comes", arrive[st] == true, tag)
      elseif r.chordStyle == "Offbeat" then
        rule("an offbeat chord is struck off the beat, short",
             (I.strength(meter, st) < 2 or arrive[st]) and n.len <= 0.25 + 1e-9, tag)
      elseif r.chordStyle == "Pulse" and named and (st % 1 == 0) then
        rule("a pulse in a named rhythm is struck on its steps, or where a chord comes",
             inBar[st % meter.bar] or arrive[st], tag .. " " .. r.groove)
      end
    end
    if r.chordStyle == "Fill" and mel then
      local tuneAt = {}
      for _, t in ipairs(mel) do tuneAt[t.step] = true end
      for st in pairs(onsets) do
        rule("fill chords are struck where the tune is not moving, or where a chord comes",
             not tuneAt[st] or arrive[st], tag)
      end
    end
    local bp = part(idea, "Bass")
    if named and r.bass == "Pulse" and bp then
      for _, n in ipairs(bp.notes) do
        local st = n.start * 4
        local arr = false
        for _, sl in ipairs(tl) do if math.abs(sl.s - st) < 1e-6 then arr = true end end
        rule("a pulsing bass in a named rhythm plays its steps, or where a chord comes",
             inBar[st % meter.bar] or arr, tag .. " " .. r.groove)
      end
    end
  end

  -- A chord is struck only where the tune and the bass hear that chord: a
  -- pulled chord's last eighth is held, never struck (1.11).
  if cp then
    for _, n in ipairs(cp.notes) do
      local st = n.start * 4
      local a, b = I.chordAt(idea.chordTimeline, st + 1e-6), I.chordAt(tl, st + 1e-6)
      rule("a chord is struck only where the tune and the bass hear it",
           a and b and a.degree == b.degree and a.chord.rootPc == b.chord.rootPc, tag .. " " .. r.chordStyle)
    end
  end

  -- The chords part: every note a chord tone of the chord it sounds over.
  if cp then
    for _, n in ipairs(cp.notes) do
      -- (Against the chords part's own timeline: a pulled chord comes late.)
      local ch = I.chordAt(idea.chordTimeline, math.floor(n.start * 4 + 0.5)).chord
      -- (A rootless voicing puts the chord's ninth where its root was.)
      rule("every note of the chords part is on its chord",
           ch.has[n.pitch % 12] == true or (r.voicing == "Rootless" and n.pitch % 12 == ch.nine), tag)
    end
  end
  -- A chord's bass note is one of its notes (an inversion, a named
  -- progression's G/B: no sus4 over a B).
  if r.chords then
    for _, sl in ipairs(idea.timeline) do
      if sl.bassPc then rule("a chord's bass note is a note of the chord", sl.chord.has[sl.bassPc] == true, tag .. " " .. idea.chords) end
    end
  end
  -- Part-writing by the book (1.7).
  if r.partWriting == "By the book" and cp then
    local ctl = idea.chordTimeline
    -- An inverted chord does not double its bass note above it (but for a
    -- diminished triad, which does); a Phrase's own bass is its lowest note.
    if r.chordStyle ~= "Broken" then
      for _, sl in ipairs(ctl) do
        -- (A two-note chord - a pentatonic scale's - keeps what it has.)
        -- (Nor a six-four, which doubles its bass: Hutchinson, 26.12.)
        if sl.inversion and sl.inversion ~= 2 and #sl.chord.pcs >= 3 and not (sl.chord.quality == "diminished" and #sl.chord.pcs == 3) then
          local v = {}
          for _, n in ipairs(cp.notes) do if math.abs(n.start * 4 - sl.s) < 1e-6 then v[#v + 1] = n.pitch end end
          table.sort(v)
          if r.kind ~= "Measure" then table.remove(v, 1) end
          local dbl = false
          for _, p in ipairs(v) do if p % 12 == sl.bassPc then dbl = true end end
          if #v > 0 then rule("by the book, an inverted chord does not double its bass", not dbl, tag .. " " .. idea.chords) end
        end
      end
    end
    -- While a suspension or an appoggiatura sounds, the chords leave out
    -- the note it falls to (1.10), but keep two notes, and a Phrase's bass.
    if idea.melody then
      local at, low = {}, {}
      for _, n in ipairs(cp.notes) do
        at[n.start] = (at[n.start] or 0) + 1
        low[n.start] = math.min(low[n.start] or 999, n.pitch)
      end
      for _, t in ipairs(idea.melody) do
        local d = t.dissonance
        if d and d.res and d.res ~= d.root then
          for _, n in ipairs(cp.notes) do
            local s, e = n.start * 4, (n.start + n.len) * 4
            if s < d.e and e > d.s and n.pitch % 12 == d.res and at[n.start] > 2
               and not (r.kind ~= "Measure" and n.pitch == low[n.start]) then
              rule("by the book, the chords do not double a suspension's resolution", false, tag .. " " .. idea.chords)
            end
          end
          rule("by the book, the chords do not double a suspension's resolution", true, tag)
        end
      end
    end
    -- A half close with Mixed stands on a plain triad.
    if r.colour == "Mixed" then
      for _, u in ipairs(idea.plan.units) do
        if u.cad == "HC" then
          local sl
          for _, x in ipairs(idea.timeline) do if (x.beat or x.s) < u.start + u.len and x.e >= u.start + u.len - 1e-9 then sl = x end end
          if sl and not sl.borrowed and not sl.flavour then
            rule("by the book, a half close with Mixed is a plain triad", #sl.chord.pcs <= 3, tag .. " " .. idea.chords)
          end
        end
      end
    end
    -- No parallel fifths or octaves between the tune and the bass each
    -- chord stands on (the first note of the idea and a unit's last note,
    -- which stay, excepted).
    -- (In the whole-tone and diminished scales every way out of one can
    -- be another, or a tritone: those are left to themselves.)
    if mel and r.scale < 14 then
      local tl2 = (r.kind == "Measure") and tl or ctl
      for i = 2, #mel do
        local a, b = mel[i - 1], mel[i]
        local ba, bb = I.bassPcOf(I.chordAt(tl2, a.step)), I.bassPcOf(I.chordAt(tl2, b.step))
        if ba ~= bb and a.pitch ~= b.pitch and not (i == 2 and b.last) then
          local ia, ib = (a.pitch - ba) % 12, (b.pitch - bb) % 12
          rule("by the book, no parallel fifths or octaves between the tune and the bass",
               not (ia == ib and (ia == 0 or ia == 7)), tag .. " " .. idea.chords)
        end
      end
    end
  end
  local bp = part(idea, "Bass")
  if bp and r.partWriting == "By the book" and r.chordStyle ~= "Broken" then
    -- The bass never meets the chords or goes in among them.
    local lowAt = {}
    for _, n in ipairs(cp.notes) do lowAt[n.start] = math.min(lowAt[n.start] or 127, n.pitch) end
    for t, low in pairs(lowAt) do
      for _, n in ipairs(bp.notes) do
        if n.start <= t + 1e-9 and n.start + n.len > t + 1e-9 then
          rule("by the book, the bass stays under the chords", n.pitch < low, tag)
        end
      end
    end
  end
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
      local st = { kind = kind, velocity = ({ "Shaped", "Flat", "Shaped", "Accents" })[seed % 4 + 1],
                   partWriting = (seed % 5 == 3) and "Free" or "By the book",
                   layout = (seed % 3 == 0) and "One item" or "Tracks",
                   register = (seed % 7 == 0) and "Any" or "Middle",
                   voicing = T.VOICINGS[seed % #T.VOICINGS + 1],
                   colour = (seed % 5 == 0) and "Mixed" or "Any",
                   -- (The engine's own choice, 1.13: walk or named, half and half.)
                   progression = "Any" }
      -- Every third idea borrows, flavours and inverts on Common.
      if seed % 3 == 2 then st.borrowed, st.flavours, st.inversions, st.applied = "Common", "Common", "Common", "Common" end
      -- Tension (1.10) on Common with the others, off now and then; a
      -- second voice every fourth idea.
      if seed % 3 == 2 then st.tension = "Common" elseif seed % 7 == 3 then st.tension = "Off" end
      if seed % 4 == 3 then st.secondVoice = (seed % 8 == 3) and "Thirds" or "Sixths" end
      -- The 1.11 chord styles every sixth idea, a named rhythm every fifth.
      if seed % 6 == 5 then st.chordStyle = ({ "Pedal", "Offbeat", "Fill" })[(seed // 6) % 3 + 1] end
      if seed % 5 == 4 then st.groove = ({ "Tresillo", "Habanera", "Clave", "3+3+3+3+2+2" })[(seed // 5) % 4 + 1] end
      -- A key change every seventh Measure (1.12).
      if seed % 7 == 6 then st.keyChange = ({ "Step up", "Half step up", "Truck driver" })[(seed // 7) % 3 + 1] end
      -- Every fourth Measure in one of the 1.8 forms (Any rolls only 1.0's).
      local NEWFORMS = { "Hybrid 1", "Hybrid 2", "Hybrid 3", "Hybrid 4", "Ternary", "Extended" }
      if seed % 4 == 1 then st.form = NEWFORMS[(seed // 4) % #NEWFORMS + 1] end
      -- Every third idea plays a named progression (1.9), or Any named.
      if seed % 3 == 0 then
        local names = { "Any named" }
        for _, n in ipairs(I.PROGRESSION_ORDER) do names[#names + 1] = n end
        st.progression = names[(seed // 3) % #names + 1]
      end
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
    local idea = make({ kind = kind, root = "Any", scale = "Any", register = "Any", voicing = "Any", progression = "Any" }, seed)
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
-- (1.0's ideas were held unchanged by thirty fingerprints until 1.13, when
-- the user, with no one using the script yet, let old idea numbers go:
-- docs/decisions/0025-the-engine-decides-more.md.)

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
      -- (An appoggiatura is off the chord on purpose: 1.10.)
      if I.strength(idea.meter or M44, n.step) >= 2 and not n.tension
         and not T.onChord(I.keyAt(tl, n.step), I.chordAt(idea.timeline, n.step).chord, n.pos) then
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
      -- (Tension off: by the book a chord struck under a suspension leaves
      -- out the note it falls to, which the 1.10 tests check.)
      local idea = make({ kind = "Measure", voicing = style, chordStyle = "Block", figures = "Plain", tension = "Off",
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
        elseif style == "Power" then
          local only = v[1] % 12 == ch.rootPc
          for _, p in ipairs(v) do if p % 12 ~= ch.rootPc and (p - ch.rootPc) % 12 ~= 7 then only = false end end
          check(only, tag .. " root and fifth only")
        elseif (style == "Drop 2" or style == "Drop 3" or style == "Drop 2 & 4") and #ch.pcs >= 3 then check(#v == 4, tag .. " four voices") end
      end
    end
  end
  eq(#bad, 0, "every voicing is laid out as it says, in real ideas: " .. table.concat(bad, "; "))
  -- The voicing changes the chords' notes, never the tune or the bass -
  -- but for the bass's octave, by the book, which keeps it under the
  -- chords: its rhythm and its notes stay.
  local moved = 0
  local function pcs(notes)
    local out = {}
    for _, n in ipairs(notes) do out[#out + 1] = ("%g:%g:%d"):format(n.start, n.len, n.pitch % 12) end
    return table.concat(out, " ")
  end
  for seed = 1, 30 do
    local a = make({ kind = "Measure", voicing = "Close" }, seed)
    local b = make({ kind = "Measure", voicing = "Drop 2 & 4" }, seed)
    if fingerprint(part(a, "Melody").notes) ~= fingerprint(part(b, "Melody").notes)
       or pcs(part(a, "Bass").notes) ~= pcs(part(b, "Bass").notes) then moved = moved + 1 end
    local c = make({ kind = "Measure", voicing = "Close", partWriting = "Free" }, seed)
    local d = make({ kind = "Measure", voicing = "Drop 2 & 4", partWriting = "Free" }, seed)
    if fingerprint(part(c, "Melody").notes) ~= fingerprint(part(d, "Melody").notes)
       or fingerprint(part(c, "Bass").notes) ~= fingerprint(part(d, "Bass").notes) then moved = moved + 1 end
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
      if sl.inversion and not sl.spec then
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
          -- The textbook six-fours: cadential (at a cadence, before its V,
          -- on a stronger beat), passing (the bass through three notes one
          -- way) or pedal (the bass held), those two on a weaker beat
          -- between chords of the same function.
          local m = I.meter(4, 4)
          local w = function(x) return I.weightAt(m, x.beat or x.s) end
          local same = T.functionOf(sl.key, before.degree) == T.functionOf(sl.key, after.degree)
          local up, on = (b - pb) % 12, (nb - b) % 12
          local oneWay = (up >= 1 and up <= 2 and on >= 1 and on <= 2) or (up >= 10 and on >= 10)
          local pedal = b == pb and b == nb and same and w(sl) < w(before)
          local passing = oneWay and same and w(sl) < w(before)
          local cadential = sl.degree == 0 and keep[after] and T.rootAbove(sl.key, after.degree) == 7 and w(sl) > w(after)
          local resolved = before.inversion == 3 and byStep(pb, b)
          if not (pedal or passing or cadential or resolved) then wrong[#wrong + 1] = "second, no 6/4 " .. tag end
          if sl.chord.quality == "diminished" and #sl.chord.pcs == 3 then wrong[#wrong + 1] = "a diminished 6/4 " .. tag end
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
    for _, sl in ipairs(o.timeline) do if sl.inversion and not sl.spec then off = off + 1 end end
    -- (Free: by the book, the tune keeps clear of parallels with the bass,
    -- which an inversion moves.)
    local fi = make({ kind = "Measure", inversions = "Rare", partWriting = "Free" }, seed)
    local fo = make({ kind = "Measure", inversions = "Off", partWriting = "Free" }, seed)
    if fingerprint(part(fo, "Melody").notes) ~= fingerprint(part(fi, "Melody").notes) then tuned = tuned + 1 end
  end
  ok(kinds[1] and kinds[2] and kinds[3], "Inversions on Rare brings first, second and third inversions")
  ok(with >= n * 0.15 and with <= n * 0.7, ("now and then: in %d of %d Measures"):format(with, n))
  eq(owned, 0, "never the first chord, the last, or a cadence's")
  eq(#wrong, 0, "each where it does its job - the bass by step, a 6/4 cadential, passing or held, a seventh falling: " ..
     table.concat(wrong, "; "))
  eq(slash, 0, "and written over its bass note: C/E")
  eq(off, 0, "with Inversions off, none")
  eq(tuned, 0, "an inversion moves the bass, never the tune (with free part-writing)")
  -- A diminished triad is most at home in first inversion: inverted far
  -- more often than other chords are.
  local dim, dimInv, other, otherInv = 0, 0, 0, 0
  for seed = 1, 300 do
    local idea = make({ kind = "Measure", colour = "Triads", scale = 1, inversions = "Rare", applied = "Off" }, seed)
    local keep = cadenceOwned(idea)
    for i, sl in ipairs(idea.timeline) do
      if not keep[sl] and i > 1 and i < #idea.timeline then
        if sl.chord.quality == "diminished" then dim = dim + 1; if sl.inversion and not sl.spec then dimInv = dimInv + 1 end
        else other = other + 1; if sl.inversion and not sl.spec then otherInv = otherInv + 1 end end
      end
    end
  end
  ok(dim > 0 and dimInv / dim > 2 * otherInv / other,
     ("a diminished triad is inverted far more often than the rest: %d of %d, against %d of %d"):format(dimInv, dim, otherInv, other))
end

-- Common: more than Rare, the same rules. Borrowed on Common borrows in most
-- ideas, sometimes two chords, never side by side, never the first or the
-- last two.
do
  local counts = { Rare = { b = 0, f = 0, i = 0 }, Common = { b = 0, f = 0, i = 0 } }
  local two, apart, edge, more = 0, 0, 0, 0
  for seed = 1, 200 do
    for _, lvl in ipairs({ "Rare", "Common" }) do
      local idea = make({ kind = "Measure", colour = "Mixed", scale = 1, borrowed = lvl, flavours = lvl, inversions = lvl }, seed)
      local c = counts[lvl]
      c.b = c.b + #idea.borrowed
      for _, sl in ipairs(idea.timeline) do
        if sl.flavour then c.f = c.f + 1 end
        if sl.inversion and not sl.spec then c.i = c.i + 1 end
      end
      if lvl == "Common" then
        local at = {}
        for i, sl in ipairs(idea.timeline) do at[sl] = i end
        local slots = {}
        for i, sl in ipairs(idea.timeline) do
          if sl.borrowed then
            slots[#slots + 1] = i
            if i == 1 or i >= #idea.timeline - 1 then edge = edge + 1 end
          end
        end
        if #slots == 2 then two = two + 1; if slots[2] - slots[1] < 2 then apart = apart + 1 end end
        if #slots > 2 then more = more + 1 end
        if #slots ~= #idea.borrowed then more = more + 1 end
      end
    end
  end
  for _, k in ipairs({ "b", "f", "i" }) do
    ok(counts.Common[k] >= 1.5 * counts.Rare[k],
       ("Common is more than Rare (%s): %d against %d"):format(({ b = "borrowed", f = "flavours", i = "inversions" })[k],
       counts.Common[k], counts.Rare[k]))
  end
  ok(two > 0, "Borrowed on Common sometimes borrows two chords: " .. two .. " of 200 Measures")
  eq(apart, 0, "never side by side")
  eq(edge, 0, "never the first chord or the last two")
  eq(more, 0, "never more than two, and the window lists each")
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

------------------------------------------------------------------------------
-- 1.7: part-writing by the book, shaped velocity
------------------------------------------------------------------------------

do
  -- What sounds at a time in a part's notes, low to high.
  local function at(notes, t)
    local out = {}
    for _, n in ipairs(notes or {}) do
      if n.start <= t + 1e-9 and n.start + n.len > t + 1e-9 then out[#out + 1] = n.pitch end
    end
    table.sort(out)
    return out
  end
  local function tally(pw, n)
    local c = { inv = 0, dbl = 0, sev = 0, sevOk = 0, strokes = 0, cross = 0, wide = 0, tuneN = 0, close = 0,
                pairs = 0, par = 0, hc = 0, hc7 = 0 }
    for seed = 1, n do
      local idea = make({ kind = "Measure", chordStyle = "Block", colour = "Mixed", partWriting = pw,
                          push = "None", pull = "None" }, seed)
      local ch, bs, mel = part(idea, "Chords").notes, part(idea, "Bass").notes, part(idea, "Melody").notes
      local prevV, prevCh
      for _, sl in ipairs(idea.chordTimeline) do
        local v = {}
        for _, x in ipairs(ch) do if math.abs(x.start * 4 - sl.s) < 1e-6 then v[#v + 1] = x.pitch end end
        table.sort(v)
        if sl.inversion and sl.inversion ~= 2 and not (sl.chord.quality == "diminished" and #sl.chord.pcs == 3) and #sl.chord.pcs >= 3 then
          c.inv = c.inv + 1
          for _, p in ipairs(v) do if p % 12 == sl.bassPc then c.dbl = c.dbl + 1; break end end
        end
        if prevV then
          local s7
          for _, pc in ipairs(prevCh.pcs) do if T.roleOf(prevCh, pc) == "7" then s7 = pc end end
          local p7
          if s7 and not sl.chord.has[s7] then for _, p in ipairs(prevV) do if p % 12 == s7 then p7 = p end end end
          if p7 and (sl.chord.has[(p7 - 1) % 12] or sl.chord.has[(p7 - 2) % 12]) then
            c.sev = c.sev + 1
            for _, p in ipairs(v) do if p == p7 - 1 or p == p7 - 2 then c.sevOk = c.sevOk + 1; break end end
          end
        end
        prevV, prevCh = v, sl.chord
      end
      local times = {}
      for _, x in ipairs(ch) do times[x.start] = true end
      for t in pairs(times) do
        local v, b, m = at(ch, t), at(bs, t)[1], at(mel, t)[1]
        if v[1] and b then
          c.strokes = c.strokes + 1
          if b >= v[1] then c.cross = c.cross + 1 elseif v[1] - b > 19 then c.wide = c.wide + 1 end
        end
        if v[1] and m then
          c.tuneN = c.tuneN + 1
          if m - v[#v] >= -2 and m - v[#v] <= 7 then c.close = c.close + 1 end
        end
      end
      local ts, seen = {}, {}
      for _, x in ipairs(mel) do if not seen[x.start] then seen[x.start] = true; ts[#ts + 1] = x.start end end
      for _, x in ipairs(bs) do if not seen[x.start] then seen[x.start] = true; ts[#ts + 1] = x.start end end
      table.sort(ts)
      local pm, pb
      for _, t in ipairs(ts) do
        local m, b = at(mel, t)[1], at(bs, t)[1]
        if m and b then
          if pm and pm ~= m and pb % 12 ~= b % 12 then
            c.pairs = c.pairs + 1
            local ia, ib = (pm - pb) % 12, (m - b) % 12
            if ia == ib and (ia == 0 or ia == 7) then c.par = c.par + 1 end
          end
          pm, pb = m, b
        end
      end
      for _, u in ipairs(idea.plan.units) do
        if u.cad == "HC" then
          local sl = I.chordAt(idea.timeline, u.start + u.len - 1)
          if not sl.borrowed and not sl.flavour then
            c.hc = c.hc + 1
            if #sl.chord.pcs > 3 then c.hc7 = c.hc7 + 1 end
          end
        end
      end
    end
    return c
  end
  local book, free = tally("By the book", 200), tally("Free", 200)
  local function pct(a, b) return 100 * a / math.max(1, b) end
  ok(free.dbl > free.inv * 0.5 and book.dbl == 0,
     ("an inverted chord does not double its bass by the book: %d of %d (free %d of %d)"):format(book.dbl, book.inv, free.dbl, free.inv))
  ok(pct(book.sevOk, book.sev) >= 90,
     ("a seventh falls a step into the next chord: %.0f%% of %d"):format(pct(book.sevOk, book.sev), book.sev))
  ok(book.cross == 0 and free.cross > free.strokes * 0.05,
     ("the bass never meets the chords by the book: %d of %d (free %.0f%%)"):format(book.cross, book.strokes, pct(free.cross, free.strokes)))
  ok(pct(book.wide, book.strokes) <= 5,
     ("and is no more than an octave and a fifth under them: %.1f%% wider"):format(pct(book.wide, book.strokes)))
  ok(pct(book.close, book.tuneN) >= 80 and pct(free.close, free.tuneN) <= 40,
     ("the chords sit just under the tune, a fifth at most (a step or two over, at most): %.0f%% (free %.0f%%)"):format(
       pct(book.close, book.tuneN), pct(free.close, free.tuneN)))
  ok(pct(book.par, book.pairs) <= 2 and pct(free.par, free.pairs) >= 5,
     ("parallel fifths and octaves between tune and bass: %.1f%% of moves (free %.1f%%)"):format(
       pct(book.par, book.pairs), pct(free.par, free.pairs)))
  ok(book.hc7 == 0 and free.hc7 > 0,
     ("a half close with Mixed is a plain V by the book: %d sevenths in %d (free %d)"):format(book.hc7, book.hc, free.hc7))
  -- With Sevenths, chosen for sevenths everywhere, the V7 stays.
  local kept = 0
  for seed = 1, 100 do
    local idea = make({ kind = "Measure", colour = "Sevenths", partWriting = "By the book" }, seed)
    for _, u in ipairs(idea.plan.units) do
      if u.cad == "HC" and #I.chordAt(idea.timeline, u.start + u.len - 1).chord.pcs > 3 then kept = kept + 1 end
    end
  end
  ok(kept > 0, "with Sevenths a half close keeps its V7: " .. kept)
  -- Free is 1.6, note for note: hidden, under a Motif, it changes nothing.
  local bad = 0
  for seed = 1, 30 do
    local a = make({ kind = "Motif", partWriting = "Free" }, seed)
    local b = make({ kind = "Motif", partWriting = "By the book" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then bad = bad + 1 end
  end
  eq(bad, 0, "Part-writing, hidden under a Motif, changes nothing")
end

-- Shaped velocity: the downbeat loudest, the off-beats softest; the chords
-- under the tune, a chord's inner notes under its top.
do
  local down, off, mel, chords, inner, top = {}, {}, {}, {}, {}, {}
  local function mean(t) local s = 0 for _, x in ipairs(t) do s = s + x end return s / math.max(1, #t) end
  for seed = 1, 60 do
    local idea = make({ kind = "Measure", velocity = "Shaped", chordStyle = "Block", swing = 0 }, seed)
    for _, p in ipairs(idea.block.parts) do
      local byStart = {}
      for _, n in ipairs(p.notes) do
        local step = n.start * 4
        if p.name == "Melody" then
          mel[#mel + 1] = n.vel
          if step % 16 == 0 then down[#down + 1] = n.vel elseif step % 2 ~= 0 then off[#off + 1] = n.vel end
        elseif p.name == "Chords" then
          chords[#chords + 1] = n.vel
          byStart[n.start] = byStart[n.start] or {}
          table.insert(byStart[n.start], n)
        end
      end
      for _, list in pairs(byStart) do
        table.sort(list, function(a, b) return a.pitch < b.pitch end)
        top[#top + 1] = list[#list].vel
        for i = 1, #list - 1 do inner[#inner + 1] = list[i].vel end
      end
    end
  end
  ok(mean(down) > mean(off) + 10, ("the downbeat louder than the sixteenths: %.0f against %.0f"):format(mean(down), mean(off)))
  ok(mean(mel) > mean(chords) + 5, ("the tune over the chords: %.0f against %.0f"):format(mean(mel), mean(chords)))
  ok(mean(top) > mean(inner), ("a chord's top over its inner notes: %.0f against %.0f"):format(mean(top), mean(inner)))
end

------------------------------------------------------------------------------
-- 1.8: applied chords, the deceptive cadence, more forms
------------------------------------------------------------------------------

do
  local count = { Off = 0, Rare = 0, Common = 0 }
  local ideas = { Off = 0, Rare = 0, Common = 0 }
  local outside, edge, said, kinds = 0, 0, 0, {}
  local n = 200
  for seed = 1, n do
    for _, lvl in ipairs({ "Off", "Rare", "Common" }) do
      local idea = make({ kind = "Measure", applied = lvl, borrowed = "Off", scale = 1,
                          colour = ({ "Triads", "Sevenths", "Mixed" })[seed % 3 + 1] }, seed)
      local tl = idea.timeline
      local any = false
      for i, sl in ipairs(tl) do
        if sl.applied then
          count[lvl] = count[lvl] + 1
          any = true
          kinds[sl.applied.numeral:gsub("7", "")] = true
          local out = false
          for _, pc in ipairs(sl.chord.pcs) do if not ({ [0]=1, [2]=1, [4]=1, [5]=1, [7]=1, [9]=1, [11]=1 })[pc] then out = true end end
          if out then outside = outside + 1 end
          if i == 1 or i == #tl then edge = edge + 1 end
        end
      end
      if any then ideas[lvl] = ideas[lvl] + 1 end
      if lvl ~= "Off" and #idea.applied == (function() local k = 0 for _, sl in ipairs(tl) do if sl.applied then k = k + 1 end end return k end)() then said = said + 1 end
    end
  end
  eq(count.Off, 0, "with Applied off, no applied chords")
  ok(ideas.Rare >= n * 0.2 and ideas.Rare <= n * 0.8,
     ("with Rare, some Measures have an applied chord: %d of %d"):format(ideas.Rare, n))
  ok(count.Common >= 1.5 * count.Rare, ("Common more than Rare: %d against %d"):format(count.Common, count.Rare))
  eq(outside, count.Rare + count.Common, "every applied chord has a note from outside the key")
  eq(edge, 0, "never the first chord or the last")
  eq(said, 2 * n, "the window lists every one")
  ok(kinds["V/V"] and kinds["V/vi"] and kinds["viio/V"], "V/V, V/vi and the leading-tone chords among them")
  -- In C major, V7/V is D7, with F#: and the tune bends with it.
  local found, bent = false, 0
  for seed = 1, 300 do
    local idea = make({ kind = "Measure", applied = "Common", colour = "Sevenths", root = 1, scale = 1, borrowed = "Off" }, seed)
    for _, sl in ipairs(idea.timeline) do
      if sl.applied and sl.applied.numeral == "V7/V" then
        found = found or sl.chord.name == "D7"
        for _, nt in ipairs(idea.melody) do
          if nt.step >= sl.s and nt.step < sl.e and nt.pitch % 12 == 5 then bent = bent + 1 end
        end
      end
    end
  end
  ok(found, "V7/V in C is D7")
  eq(bent, 0, "and under it the tune plays F#, never F")
  -- The same each time round a Loop.
  local bad = 0
  for seed = 1, 60 do
    local idea = make({ kind = "Measure", form = "Loop", measureBars = 16, applied = "Common", borrowed = "Off" }, seed)
    local units = idea.plan.units
    local function names(u)
      local out = {}
      for i = 1, #u.slots - 1 do out[i] = u.slots[i].chord.name end
      return table.concat(out, " ")
    end
    for _, u in ipairs(units) do if names(u) ~= names(units[1]) then bad = bad + 1 end end
  end
  eq(bad, 0, "a Loop plays the same applied chords each time round")
  -- Hidden, it changes nothing.
  local PENT
  for i, sc in ipairs(T.SCALES) do if sc.name == "Maj Pent" then PENT = i end end
  local hidden = 0
  for seed = 1, 30 do
    local a = make({ kind = "Drums", applied = "Off" }, seed)
    local b = make({ kind = "Drums", applied = "Common" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then hidden = hidden + 1 end
    local c = make({ kind = "Measure", scale = PENT, applied = "Off" }, seed)
    local d = make({ kind = "Measure", scale = PENT, applied = "Common" }, seed)
    if fingerprint(c.block.notes) ~= fingerprint(d.block.notes) then hidden = hidden + 1 end
  end
  eq(hidden, 0, "Applied, hidden (Drums, a pentatonic scale), changes nothing")
end

-- The deceptive cadence and the 1.8 forms.
do
  local want = {
    ["Hybrid 1"] = { "HC", "PAC" }, ["Hybrid 2"] = { "HC", "PAC" }, ["Hybrid 3"] = { "PAC" },
    ["Hybrid 4"] = { "PAC" }, Ternary = { "HC", "PAC" }, Extended = { "PAC" },
  }
  local bad, dcTonic, dcs = {}, 0, 0
  for form, cads in pairs(want) do
    for _, bars in ipairs({ 8, 12, 16 }) do
      for seed = 1, 20 do
        local idea = make({ kind = "Measure", form = form, measureBars = bars, scale = 1 }, seed)
        local got = {}
        for _, u in ipairs(idea.plan.units) do if u.cad ~= "none" then got[#got + 1] = u.cad end end
        local seen = {}
        for _, c in ipairs(got) do seen[c] = true end
        for _, c in ipairs(cads) do if not seen[c] then bad[#bad + 1] = form .. " " .. bars .. " lacks " .. c end end
        -- (Extended's stretch: a deceptive close, or an evaded one, 1.13.)
        if form == "Extended" and not (seen.DC or seen.EC) then bad[#bad + 1] = "Extended " .. bars .. " lacks DC or EC" end
        if got[#got] ~= "PAC" then bad[#bad + 1] = form .. " " .. bars .. " does not close" end
        if idea.block.beats ~= bars * 4 then bad[#bad + 1] = form .. " " .. bars .. " is " .. idea.block.beats .. " beats" end
        for _, u in ipairs(idea.plan.units) do
          if u.cad == "DC" then
            dcs = dcs + 1
            local last = u.notes[#u.notes]
            if last and last.pos % 7 == 0 then dcTonic = dcTonic + 1 end
          end
        end
      end
    end
  end
  eq(#bad, 0, "the 1.8 forms are as they say: " .. table.concat(bad, "; "))
  ok(dcs > 0 and dcTonic >= dcs * 0.5,
     ("at a deceptive cadence the tune mostly holds do over vi: %d of %d"):format(dcTonic, dcs))
  -- (1.13) Every idea rolls its form, each about one time in ten.
  local count, n = {}, 1000
  for seed = 1, n do
    local f = make({ kind = "Measure" }, seed).r.form
    count[f] = (count[f] or 0) + 1
  end
  local off = {}
  for _, f in ipairs(I.BY_ID.form.values) do
    local c = count[f] or 0
    if c < n * 0.06 or c > n * 0.14 then off[#off + 1] = f .. " " .. c end
  end
  eq(#off, 0, "every form about one idea in ten (of 1000): " .. table.concat(off, ", "))
end

------------------------------------------------------------------------------
-- 1.9: named progressions
------------------------------------------------------------------------------

do
  -- In a Loop at a chord a bar, a named progression is played as written,
  -- from its first chord.
  local want = {
    ["Doo-wop"] = { 1, "C Am F G" }, ["Singer-songwriter"] = { 1, "Am F C G" }, Puff = { 1, "C Em F" },
    Pachelbel = { 1, "C G/B Am Em/G" }, Lament = { 2, "Cm Bb Ab G" }, Circle = { 1, "C F Bdim Em" },
    ["Double plagal"] = { 1, "C Bb F" }, Galant = { 1, "C G/D G/B C" },
  }
  local bad = {}
  for name, w in pairs(want) do
    for seed = 1, 10 do
      local idea = make({ kind = "Measure", form = "Loop", measureBars = 8, chordPace = "One a bar",
                          progression = name, scale = w[1], root = 1, colour = "Triads",
                          push = "None", pull = "None", flavours = "Off" }, seed)
      local got = {}
      for _, sl in ipairs(idea.timeline) do
        got[#got + 1] = sl.chord.name .. (sl.bassPos and ("/" .. T.noteName(sl.key, sl.bassPos)) or "")
      end
      local line = table.concat(got, " ")
      if line:sub(1, #w[2]) ~= w[2] then bad[#bad + 1] = name .. ": " .. line end
      if idea.schema ~= name then bad[#bad + 1] = name .. " not named" end
    end
  end
  eq(#bad, 0, "each named progression is played as written: " .. table.concat(bad, "; "))
  -- A repeat carries the progression on: all eight of Pachelbel's chords
  -- over a sixteen-bar Loop of four-bar statements, and doo-wop's four over
  -- a Loop at a chord every two bars.
  local short = {}
  for seed = 1, 10 do
    for _, c in ipairs({ { "Pachelbel", "One a bar", "C G/B Am Em/G F C/E F G C G/B Am Em/G F C/E F G" },
                         { "Doo-wop", "Slow", "C Am F G" } }) do
      local idea = make({ kind = "Measure", form = "Loop", measureBars = 16, chordPace = c[2],
                          progression = c[1], scale = 1, root = 1, colour = "Triads",
                          push = "None", pull = "None" }, seed)
      local got = {}
      for _, sl in ipairs(idea.timeline) do
        got[#got + 1] = sl.chord.name .. (sl.bassPos and ("/" .. T.noteName(sl.key, sl.bassPos)) or "")
      end
      local line = table.concat(got, " ")
      if line:sub(1, #c[3]) ~= c[3] then short[#short + 1] = c[1] .. ": " .. line end
    end
  end
  eq(#short, 0, "a Loop's repeats carry a named progression on: " .. table.concat(short, "; "))
  -- Flavoured, a named chord keeps its bass note: G(add9)/B, never Gsus4/B.
  local lost, flavoured = 0, 0
  for _, name in ipairs({ "Pachelbel", "Galant" }) do
    for seed = 1, 40 do
      local idea = make({ kind = "Measure", form = "Loop", progression = name, scale = 1, colour = "Mixed",
                          flavours = "Common" }, seed)
      for _, sl in ipairs(idea.timeline) do
        if sl.bassPc then
          if sl.flavour then flavoured = flavoured + 1 end
          if not sl.chord.has[sl.bassPc] then lost = lost + 1 end
        end
      end
    end
  end
  ok(lost == 0 and flavoured > 0, ("a flavoured named chord keeps its bass note (%d flavoured)"):format(flavoured))
  -- The blues: a chord a bar, I I I I IV IV I I V IV I I.
  local blues = make({ kind = "Measure", measureBars = 12, progression = "Blues", root = 1, scale = 1,
                       push = "None", pull = "None", colour = "Triads" }, 3)
  local per = {}
  for b = 0, 11 do per[#per + 1] = I.chordAt(blues.timeline, b * 16).chord.name end
  eq(table.concat(per, " "), "C C C C F F C C G F C C", "the 12-bar blues, bar by bar")
  -- The blues plays its own changes, so a close the form asks for may fall
  -- on IV or V: the tune lands on a note of the chord there.
  local offChord, closes = 0, 0
  for seed = 1, 60 do
    local idea = make({ kind = "Measure", progression = "Blues", scale = 1,
                        measureBars = ({ 8, 12, 16 })[seed % 3 + 1],
                        form = ({ "Period", "Sentence", "Song", "Extended", "Hybrid 1" })[seed % 5 + 1] }, seed)
    for _, n in ipairs(idea.melody) do
      if n.closes then
        closes = closes + 1
        local sl = I.chordAt(idea.timeline, n.step)
        if not T.onChord(I.keyAt({ timeline = idea.timeline, key = idea.key }, n.step), sl.chord, n.pos) then
          offChord = offChord + 1
        end
      end
    end
  end
  ok(offChord == 0 and closes > 60, ("in the blues every close lands on its chord (%d of %d off)"):format(offChord, closes))
  -- A progression that does not suit the key is not played: the chords walk,
  -- and the summary says why.
  local idea = make({ kind = "Measure", progression = "Lament", scale = 1 }, 1)
  ok(idea.schema == nil and idea.summary:find("needs a minor key", 1, true), "a lament in a major key walks, and says why")
  local ph = make({ kind = "Phrase", content = "Chords", progression = "Blues" }, 1)
  ok(ph.schema == nil and ph.summary:find("needs a Measure", 1, true), "the blues needs a Measure")
  -- Any named picks one that suits the key.
  local seen, wrong = {}, 0
  for seed = 1, 120 do
    local x = make({ kind = "Measure", progression = "Any named", scale = (seed % 2 == 0) and 2 or 1 }, seed)
    if x.schema then
      seen[x.schema] = true
      local p = I.PROGRESSIONS[x.schema]
      local minor = seed % 2 == 0
      if not p.blues and ((minor and not p.minor) or (not minor and not p.major)) then wrong = wrong + 1 end
    end
  end
  local n = 0
  for _ in pairs(seen) do n = n + 1 end
  ok(n >= 6 and wrong == 0, ("Any named plays %d different ones, each suiting the key"):format(n))
  -- Walk is 1.8, and hidden it changes nothing.
  local hidden = 0
  for seed = 1, 30 do
    local a = make({ kind = "Motif", progression = "Walk" }, seed)
    local b = make({ kind = "Motif", progression = "Doo-wop" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then hidden = hidden + 1 end
  end
  eq(hidden, 0, "Progression, hidden under a Motif, changes nothing")
end

------------------------------------------------------------------------------
-- 1.10: tension, and a second voice
------------------------------------------------------------------------------

do
  local function tally(t, kind)
    local c, with = { suspension = 0, appoggiatura = 0, anticipation = 0 }, 0
    for seed = 1, 200 do
      local idea = make({ kind = kind or "Measure", tension = t }, seed)
      local has = false
      for _, n in ipairs(idea.melody or {}) do
        if n.tension then c[n.tension] = c[n.tension] + 1; has = true end
      end
      if has then with = with + 1 end
    end
    return c, with
  end
  local off, offWith = tally("Off")
  eq(offWith, 0, "Tension Off: every note on the beat is a note of the chord")
  local rare, rareWith = tally("Rare")
  local common, commonWith = tally("Common")
  ok(rareWith >= 40 and rareWith <= 110, ("Tension Rare leans in some ideas, not most: %d of 200 Measures"):format(rareWith))
  ok(commonWith > rareWith * 1.3, ("Common, in more: %d of 200 against %d"):format(commonWith, rareWith))
  ok(rare.suspension > 0 and rare.appoggiatura > 0 and rare.anticipation > 0,
     ("all three on Rare: %d suspensions, %d appoggiaturas, %d anticipations"):format(
       rare.suspension, rare.appoggiatura, rare.anticipation))
  -- Common only adds to Rare: every tension Rare makes, Common makes too.
  local lost, made = 0, 0
  for seed = 1, 60 do
    local a = make({ kind = "Measure", tension = "Rare" }, seed)
    local b = make({ kind = "Measure", tension = "Common" }, seed)
    local at = {}
    for _, n in ipairs(b.melody) do if n.tension then at[n.tension .. n.step] = true end end
    for _, n in ipairs(a.melody) do
      if n.tension then made = made + 1 end
      if n.tension and not at[n.tension .. n.step] then lost = lost + 1 end
    end
  end
  -- (A few go where Common has leant on the note before instead.)
  ok(made > 20 and lost <= made / 6, ("Common keeps Rare's tension notes (%d of %d lost to an earlier change)"):format(lost, made))
  -- An exact repeat leans where its source did: a Loop's first and last
  -- statements alike.
  local differ, seen = 0, 0
  for seed = 1, 300 do
    local idea = make({ kind = "Measure", form = "Loop", tension = "Common", borrowed = "Off",
                        applied = "Off", push = "None", pull = "None" }, seed)
    local units = idea.plan.units
    local u1, u3 = units[1], units[#units]
    if u3.kind == "repeat" then
      local function marks(u)
        local out = {}
        for _, n in ipairs(idea.melody) do
          if n.tension and n.step >= u.start and n.step < u.start + u.len then
            out[#out + 1] = n.tension .. ":" .. (n.step - u.start)
          end
        end
        return table.concat(out, " ")
      end
      if marks(u1) ~= "" then seen = seen + 1 end
      if marks(u1) ~= marks(u3) then differ = differ + 1 end
    end
  end
  ok(seen >= 10 and differ <= seen / 10, ("a Loop leans the same way each time round (%d of %d differ)"):format(differ, seen))
  -- By the book the chords leave out what a suspension falls to; free, they
  -- may sound it against it.
  local function doubled(pw)
    local n = 0
    for seed = 1, 120 do
      local idea = make({ kind = "Measure", tension = "Common", partWriting = pw, chordStyle = "Block" }, seed)
      local cp = part(idea, "Chords")
      for _, t in ipairs(idea.melody) do
        local d = t.dissonance
        if d and d.res and d.res ~= d.root then
          for _, c in ipairs(cp.notes) do
            if c.start * 4 < d.e and (c.start + c.len) * 4 > d.s and c.pitch % 12 == d.res then n = n + 1 end
          end
        end
      end
    end
    return n
  end
  -- (But for the 9-8, where the note it falls to is the chord's root,
  -- which the chords keep.)
  local nineEight, kept = 0, 0
  for seed = 1, 200 do
    local idea = make({ kind = "Measure", tension = "Common", chordStyle = "Block" }, seed)
    local cp = part(idea, "Chords")
    for _, t in ipairs(idea.melody) do
      local d = t.dissonance
      if d and d.res and d.res == d.root then
        nineEight = nineEight + 1
        for _, c in ipairs(cp.notes) do
          if c.start * 4 < d.e and (c.start + c.len) * 4 > d.s and c.pitch % 12 == d.res then kept = kept + 1; break end
        end
      end
    end
  end
  ok(nineEight > 5 and kept >= nineEight * 0.8, ("under a 9-8 the chords keep the root: %d of %d"):format(kept, nineEight))
  local book, free = doubled("By the book"), doubled("Free")
  ok(free > 20 and book < free / 4, ("the chords leave out a suspension's resolution by the book: %d against %d free"):format(book, free))
  -- Hidden (no tune), Tension and Second voice change nothing.
  local hidden = 0
  for seed = 1, 20 do
    local a = make({ kind = "Phrase", content = "Chords", tension = "Off", secondVoice = "Off" }, seed)
    local b = make({ kind = "Phrase", content = "Chords", tension = "Common", secondVoice = "Thirds" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then hidden = hidden + 1 end
    local c = make({ kind = "Drums", tension = "Off", secondVoice = "Off" }, seed)
    local d = make({ kind = "Drums", tension = "Common", secondVoice = "Sixths" }, seed)
    if fingerprint(c.block.notes) ~= fingerprint(d.block.notes) then hidden = hidden + 1 end
  end
  eq(hidden, 0, "Tension and Second voice, hidden, change nothing")
end

do
  -- A second voice: under the tune, on its own channel or track, and the
  -- tune itself is unchanged.
  local thirds, sixths, n3, n6, tuneMoved = 0, 0, 0, 0, 0
  for seed = 1, 60 do
    local plain = make({ kind = "Measure", secondVoice = "Off" }, seed)
    for _, sv in ipairs({ "Thirds", "Sixths" }) do
      local idea = make({ kind = "Measure", secondVoice = sv, layout = "One item" }, seed)
      if fingerprint(part(idea, "Melody").notes) ~= fingerprint(part(plain, "Melody").notes) then tuneMoved = tuneMoved + 1 end
      local mp, vp = part(idea, "Melody"), part(idea, "Second voice")
      for i, v in ipairs(vp.notes) do
        local gap = mp.notes[i].pitch - v.pitch
        if sv == "Thirds" then n3 = n3 + 1; if gap == 3 or gap == 4 then thirds = thirds + 1 end
        else n6 = n6 + 1; if gap == 8 or gap == 9 then sixths = sixths + 1 end end
      end
    end
  end
  eq(tuneMoved, 0, "a second voice leaves the tune as it was")
  ok(thirds / n3 > 0.7, ("Thirds is mostly thirds: %.0f%%"):format(100 * thirds / n3))
  ok(sixths / n6 > 0.7, ("Sixths is mostly sixths: %.0f%%"):format(100 * sixths / n6))
  local one = make({ kind = "Measure", secondVoice = "Thirds", layout = "One item" }, 7)
  local chans = {}
  for _, p in ipairs(one.block.parts) do chans[#chans + 1] = p.name .. "=" .. (p.chan + 1) end
  eq(table.concat(chans, " "), "Melody=1 Chords=2 Bass=3 Second voice=4",
     "in one item the second voice is on channel 4, the others where they were")
  local tracks = make({ kind = "Measure", secondVoice = "Thirds", layout = "Tracks" }, 7)
  ok(#tracks.block.parts == 4 and tracks.block.layout == "tracks", "on tracks, a fourth track")
  local motif = make({ kind = "Motif", secondVoice = "Sixths" }, 7)
  ok(#motif.block.parts == 2 and motif.block.parts[2].chan == 1, "a Motif with a second voice: channel 2")
end

------------------------------------------------------------------------------
-- 1.11: chord styles and named rhythms
------------------------------------------------------------------------------

do
  local function onsetsOf(notes)
    local at, list = {}, {}
    for _, n in ipairs(notes) do
      local st = n.start * 4
      if not at[st] then at[st] = true; list[#list + 1] = st end
    end
    table.sort(list)
    return list
  end
  -- Each named rhythm, bar by bar, in the pulsing chords (one chord a bar),
  -- the pulsing bass and the kick.
  local want = { Tresillo = "0 6 12", Habanera = "0 6 8 12", Clave = "0 3 6 10 12", ["3+3+3+3+2+2"] = "0 3 6 9 12 14" }
  local bad = {}
  for name, w in pairs(want) do
    for seed = 1, 6 do
      local idea = make({ kind = "Measure", groove = name, chordStyle = "Pulse", bass = "Pulse", chordPace = "One a bar",
                          push = "None", pull = "None", figures = "Plain" }, seed)
      -- (In the first bar after the first that holds one chord all through.)
      local from
      for b = 1, idea.block.beats / 4 - 1 do
        local sl = I.chordAt(idea.timeline, b * 16)
        if not from and sl.s == b * 16 and sl.e >= b * 16 + 16 then from = b * 16 end
      end
      for _, pn in ipairs({ "Chords", "Bass" }) do
        local bar = {}
        for _, st in ipairs(onsetsOf(part(idea, pn).notes)) do
          if from and st >= from and st < from + 16 then bar[#bar + 1] = tostring(math.floor(st - from)) end
        end
        if from and table.concat(bar, " ") ~= w then bad[#bad + 1] = name .. " " .. pn .. ": " .. table.concat(bar, " ") end
      end
      -- (Dotted figures asked for: a named rhythm's kick takes none.)
      local drums = make({ kind = "Drums", groove = name, beat = "Backbeat", fills = "None", figures = "Dotted" }, seed)
      local kicks = {}
      for _, n in ipairs(drums.block.notes) do
        if n.pitch == I.DRUM.kick and n.start < 4 then kicks[#kicks + 1] = n.start * 4 end
      end
      local inW = {}
      for x in w:gmatch("%d+") do inW[tonumber(x)] = true end
      for _, k in ipairs(kicks) do if not inW[k] then bad[#bad + 1] = name .. " kick " .. k end end
    end
  end
  eq(#bad, 0, "each named rhythm in the chords, the bass and the kick: " .. table.concat(bad, "; "))
  -- Elsewhere a named rhythm plays as Syncopated; and Any never rolls one.
  local same = 0
  for seed = 1, 20 do
    local a = make({ kind = "Measure", groove = "Clave" }, seed, I.meter(3, 4))
    local b = make({ kind = "Measure", groove = "Syncopated" }, seed, I.meter(3, 4))
    if fingerprint(a.block.notes) == fingerprint(b.block.notes) then same = same + 1 end
  end
  eq(same, 20, "in 3/4 a named rhythm is Syncopated")
  local rolled, styles = false, false
  for seed = 1, 300 do
    local x = make({ kind = "Measure" }, seed)
    if I.RHYTHMS[x.r.groove] then rolled = true end
    if x.r.chordStyle == "Pedal" or x.r.chordStyle == "Offbeat" or x.r.chordStyle == "Fill" then styles = true end
  end
  ok(not rolled and not styles, "Any never rolls a named rhythm or a 1.11 chord style")
  -- The tune is the same in a named rhythm as syncopated.
  local moved = 0
  for seed = 1, 20 do
    local a = make({ kind = "Motif", groove = "Tresillo" }, seed)
    local b = make({ kind = "Motif", groove = "Syncopated" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then moved = moved + 1 end
  end
  eq(moved, 0, "the tune plays a named rhythm as Syncopated")
end

do
  -- Pedal: struck once a chord. Offbeat: off the beat, short. Fill: where
  -- the tune holds or rests.
  local pedalExtra, offOn, offLong, fillOnTune, fillStrokes, fillHeld = 0, 0, 0, 0, 0, 0
  for seed = 1, 40 do
    local p = make({ kind = "Measure", chordStyle = "Pedal" }, seed)
    local count = {}
    for _, n in ipairs(part(p, "Chords").notes) do
      local sl = I.chordAt(p.chordTimeline, n.start * 4 + 1e-6)
      count[sl] = count[sl] or {}
      count[sl][n.start] = true
    end
    for _, starts in pairs(count) do
      local k = 0
      for _ in pairs(starts) do k = k + 1 end
      if k > 1 then pedalExtra = pedalExtra + 1 end
    end
    local o = make({ kind = "Measure", chordStyle = "Offbeat", push = "None", pull = "None" }, seed)
    for _, n in ipairs(part(o, "Chords").notes) do
      if I.strength(I.meter(4, 4), n.start * 4) >= 2 then offOn = offOn + 1 end
      if n.len > 0.25 then offLong = offLong + 1 end
    end
    local f = make({ kind = "Measure", chordStyle = "Fill", push = "None", pull = "None" }, seed)
    local tuneAt = {}
    for _, t in ipairs(f.melody) do tuneAt[t.step] = t end
    local arrive = {}
    for _, sl in ipairs(f.chordTimeline) do arrive[sl.s] = true end
    local seen = {}
    for _, n in ipairs(part(f, "Chords").notes) do
      local st = n.start * 4
      if not seen[st] then
        seen[st] = true
        fillStrokes = fillStrokes + 1
        if tuneAt[st] and not arrive[st] then fillOnTune = fillOnTune + 1 end
        if not tuneAt[st] then fillHeld = fillHeld + 1 end
      end
    end
  end
  eq(pedalExtra, 0, "a Pedal chord is struck once")
  ok(offOn == 0 and offLong == 0, ("Offbeat chords are off the beat and short (%d on, %d long)"):format(offOn, offLong))
  ok(fillOnTune == 0 and fillHeld > fillStrokes * 0.4,
     ("Fill chords come where the tune holds or rests: %d of %d strokes, %d on a moving note"):format(fillHeld, fillStrokes, fillOnTune))
end

------------------------------------------------------------------------------
-- 1.12: the 6/9, power chords, a key change
------------------------------------------------------------------------------

do
  -- Half the 6 chords are 6/9, and a Loop plays the same each time round.
  local six, sixNine, loopsDiffer = 0, 0, 0
  for seed = 1, 150 do
    local idea = make({ kind = "Measure", colour = "Mixed", flavours = "Common", scale = 1, form = "Loop",
                        borrowed = "Off", applied = "Off" }, seed)
    for _, sl in ipairs(idea.timeline) do
      if sl.flavour == "6" then six = six + 1 elseif sl.flavour == "6/9" then sixNine = sixNine + 1 end
    end
    local units = idea.plan.units
    local function names(u)
      local out = {}
      for _, sl in ipairs(u.slots) do out[#out + 1] = sl.chord.name end
      return table.concat(out, " ")
    end
    if units[#units].kind == "repeat" and names(units[1]) ~= names(units[#units]) then loopsDiffer = loopsDiffer + 1 end
  end
  ok(sixNine > 10 and six > 10 and sixNine < six * 2, ("about half the 6 chords are 6/9: %d 6/9 and %d 6"):format(sixNine, six))
  eq(loopsDiffer, 0, "a Loop plays its 6/9s each time round")
  -- Flavours drawn before 1.12 are drawn the same: with the 6/9s put back
  -- to 6, the chords are 1.11's.
  local moved = 0
  for seed = 1, 60 do
    local idea = make({ kind = "Measure", colour = "Mixed", flavours = "Common" }, seed)
    for _, sl in ipairs(idea.timeline) do
      if sl.flavour and sl.flavour ~= "6/9" and not T.flavourChord(sl.key or idea.key, sl.degree, sl.flavour, false)
         and not T.flavourChord(sl.key or idea.key, sl.degree, sl.flavour, true) then moved = moved + 1 end
    end
  end
  eq(moved, 0, "every flavour is one its chord can take")
  -- Power: root and fifth only, the root at the bottom; Any never rolls it.
  local bad, rolled = 0, false
  for seed = 1, 40 do
    local idea = make({ kind = "Measure", voicing = "Power", chordStyle = "Block", tension = "Off" }, seed)
    local stacks = {}
    for _, n in ipairs(part(idea, "Chords").notes) do
      stacks[n.start] = stacks[n.start] or {}
      table.insert(stacks[n.start], n.pitch)
    end
    for at, v in pairs(stacks) do
      table.sort(v)
      local ch = I.chordAt(idea.chordTimeline, at * 4).chord
      if v[1] % 12 ~= ch.rootPc then bad = bad + 1 end
      for _, p in ipairs(v) do if p % 12 ~= ch.rootPc and (p - ch.rootPc) % 12 ~= 7 then bad = bad + 1 end end
    end
  end
  -- (Voicing is Close unless left to Any.)
  local anyRolled = {}
  for seed = 1, 300 do
    local v = make({ kind = "Measure", voicing = "Any" }, seed).r.voicing
    anyRolled[v] = true
    if v == "Power" then rolled = true end
  end
  rolled = rolled or not anyRolled.Rootless
  ok(bad == 0 and not rolled, ("power chords are root and fifth on the root (%d not), and only when chosen"):format(bad))
end

do
  -- A key change: the last section the same degrees a step (or a semitone)
  -- up, the tune with them.
  local wrong, moved, seen = 0, 0, 0
  for _, kc in ipairs({ { "Step up", 2 }, { "Half step up", 1 } }) do
    for seed = 1, 30 do
      local plain = make({ kind = "Measure", form = "Song", tension = "Off", borrowed = "Off", applied = "Off",
                           push = "None", pull = "None", keyChange = "None" }, seed)
      local up = make({ kind = "Measure", form = "Song", tension = "Off", borrowed = "Off", applied = "Off",
                        push = "None", pull = "None", keyChange = kc[1] }, seed)
      local at = up.keyChange and up.keyChange.at
      if at then
        seen = seen + 1
        for i, sl in ipairs(up.timeline) do
          local p = plain.timeline[i]
          if sl.s >= at then
            if not (p and p.degree == sl.degree and (sl.chord.rootPc - p.chord.rootPc) % 12 == kc[2]) then wrong = wrong + 1 end
          elseif not (p and p.chord.name == sl.chord.name) then wrong = wrong + 1 end
        end
        local mp, mu = plain.melody, up.melody
        for i, n in ipairs(mu) do
          if n.step >= at and mp[i] and mp[i].step == n.step and n.pitch - mp[i].pitch ~= kc[2] then moved = moved + 1 end
        end
      end
    end
  end
  ok(seen >= 50 and wrong == 0, ("the last section's chords are the same degrees, moved up (%d of %d ideas wrong)"):format(wrong, seen))
  -- The chord at the change is in the new key - even where the section
  -- before ended on the tonic and the new one starts on it (never one
  -- chord held across).
  local stuck, closes = 0, 0
  for seed = 1, 60 do
    -- (Puff - I iii IV I - ends each time round on the I it starts on.)
    local idea = make({ kind = "Measure", form = "Loop", keyChange = "Step up", scale = 1,
                        progression = (seed % 2 == 0) and "Puff" or "Walk" }, seed)
    local kc = idea.keyChange
    if kc then
      local sl = I.chordAt(idea.timeline, kc.at)
      if sl.degree == 0 then closes = closes + 1 end
      -- (Pushed in an eighth early, it comes just before.)
      local starts = sl.s == kc.at or (sl.pushed and sl.s == kc.at - 2)
      if not starts or (sl.chord.rootPc - T.pc(kc.key, sl.degree)) % 12 ~= 0 then stuck = stuck + 1 end
    end
  end
  ok(closes > 10 and stuck == 0, ("the new key starts at the change (%d held over from the old key; %d start on the tonic)"):format(stuck, closes))
  ok(moved <= seen, ("and the tune moves with them: %d notes not moved, in %d ideas"):format(moved, seen))
  -- From B the new key note wraps round to C#: still a tone higher, not
  -- a seventh lower.
  local wrapped, checked = 0, 0
  local B
  for i, rt in ipairs(T.ROOTS) do if rt.name == "B" then B = i end end
  for seed = 1, 10 do
    local base = { kind = "Measure", form = "Loop", root = B, scale = 1, tension = "Off", borrowed = "Off",
                   applied = "Off", push = "None", pull = "None" }
    local plain = make(base, seed)
    base.keyChange = "Step up"
    local up = make(base, seed)
    local at = up.keyChange.at
    for i, n in ipairs(up.melody) do
      local p = plain.melody[i]
      if n.step >= at and p and p.step == n.step then
        checked = checked + 1
        if n.pitch - p.pitch ~= 2 then wrapped = wrapped + 1 end
      end
    end
  end
  ok(checked > 50 and wrapped <= checked / 20, ("from B, up a tone is C# above: %d of %d notes not a tone up"):format(wrapped, checked))
  -- The truck driver: the new key's V just before the change.
  local trucks, good = 0, 0
  for seed = 1, 40 do
    local idea = make({ kind = "Measure", keyChange = "Truck driver", scale = (seed % 2 == 0) and 2 or 1 }, seed)
    local kc = idea.keyChange
    if kc and kc.truck then
      trucks = trucks + 1
      local V = kc.truck
      -- (Up to the change - or to where its first chord is pushed in.)
      local nx = I.chordAt(idea.timeline, V.e)
      if (V.e == kc.at or (nx.pushed and V.e == kc.at - 2)) and V.chord.quality == "major"
         and (V.chord.rootPc - T.pc(kc.key, 0)) % 12 == 7 then good = good + 1 end
    end
  end
  -- (Not where no section in the second half starts on the tonic.)
  ok(trucks >= 20 and good == trucks, ("the truck driver puts the new key's V just before the change: %d of %d"):format(good, trucks))
  -- And never a V into anything but the new key's tonic.
  local intoTonic, vs = 0, 0
  for seed = 1, 80 do
    local idea = make({ kind = "Measure", keyChange = "Truck driver" }, seed)
    local kc = idea.keyChange
    if kc and kc.truck then
      vs = vs + 1
      local after = I.chordAt(idea.timeline, kc.truck.e)
      if after.degree == 0 then intoTonic = intoTonic + 1 end
    end
  end
  eq(intoTonic, vs, "the truck driver's V always leads to the new key's tonic")
  -- None, or hidden (not a Measure), changes nothing.
  local hidden = 0
  for seed = 1, 20 do
    local a = make({ kind = "Phrase", keyChange = "None" }, seed)
    local b = make({ kind = "Phrase", keyChange = "Truck driver" }, seed)
    if fingerprint(a.block.notes) ~= fingerprint(b.block.notes) then hidden = hidden + 1 end
  end
  eq(hidden, 0, "Key change, hidden under a Phrase, changes nothing")
  local said = make({ kind = "Measure", keyChange = "Step up", scale = 1, root = 1 }, 3)
  ok(said.keyChange and said.keyChange.text:find("D Major", 1, true), "the window says where the key changes, and to what: " ..
     tostring(said.keyChange and said.keyChange.text))
end

------------------------------------------------------------------------------
-- 1.13: the engine decides more; leaps, the minor V, the evaded close, more
-- galant schemata, the dembow, the six-four's bass
------------------------------------------------------------------------------

do
  -- Progression, Part-writing and Form are never shown, but every idea has
  -- them: walked or named half and half, by the book, a form rolled.
  local st = I.newState()
  st.kind = "Measure"
  for _, id in ipairs({ "progression", "partWriting", "form" }) do
    ok(not I.shows(I.BY_ID[id], st), id .. " is not shown")
  end
  eq(st.partWriting, "By the book", "part-writing is by the book")
  local named, n = 0, 400
  for seed = 1, n do
    local idea = make({ kind = "Measure", progression = "Any", scale = 1 }, seed)
    if idea.r.progression == "Any named" then named = named + 1 end
  end
  ok(named > n * 0.4 and named < n * 0.6, ("half the ideas look for a named progression: %d of %d"):format(named, n))
  -- And Keep leaves them be.
  local kept = I.keep(I.newState(), make({ kind = "Measure" }, 3))
  ok(kept.progression == "Any" and kept.form == "Any", "Keep leaves the hidden settings to the engine")
end

do
  -- What outlines a triad: C E G, E G C, A C E; not B D F (diminished),
  -- C E B, nor C F A# (no triad at all).
  ok(I.outlinesTriad(60, 64, 67) and I.outlinesTriad(64, 67, 72) and I.outlinesTriad(57, 60, 64)
     and not I.outlinesTriad(59, 62, 65) and not I.outlinesTriad(60, 64, 71) and not I.outlinesTriad(60, 65, 70),
     "two leaps the same way may outline C E G, E G C or A C E - not B D F or C E B")
end

do
  -- The minor key's V: major, the tune bending to its leading note; the
  -- Aeolian mode keeps its v.
  local minorV, raisedTune, aeolV = 0, 0, 0
  local AEO
  for i, sc in ipairs(T.SCALES) do if sc.name == "Aeolian" then AEO = i end end
  for seed = 1, 60 do
    local m = make({ kind = "Measure", scale = 2, root = 1, borrowed = "Off", applied = "Off" }, seed)
    for _, sl in ipairs(m.timeline) do
      -- (A sus4 has no third to raise.)
      if sl.degree == 4 and not sl.flavour and not sl.chord.has[11] then minorV = minorV + 1 end
    end
    for _, nt in ipairs(m.melody) do
      local sl = I.chordAt(m.timeline, nt.step)
      if sl.degree == 4 and nt.pitch % 12 == 11 then raisedTune = raisedTune + 1 end
    end
    local a = make({ kind = "Measure", scale = AEO, root = 1, borrowed = "Off", applied = "Off" }, seed)
    for _, sl in ipairs(a.timeline) do if sl.degree == 4 and not sl.flavour and not sl.chord.has[11] then aeolV = aeolV + 1 end end
  end
  ok(minorV == 0 and raisedTune > 20 and aeolV > 20,
     ("in C minor the V is G with B natural, and the tune takes B (%d); Aeolian keeps Gm (%d)"):format(raisedTune, aeolV))
end

do
  -- The evaded close: Extended stretches by it half the time; V then I6,
  -- the tune leaping up instead of landing on do.
  local ec, dc, i6, leapt, n = 0, 0, 0, 0, 0
  for seed = 1, 200 do
    local idea = make({ kind = "Measure", form = "Extended", scale = 1 }, seed)
    for _, u in ipairs(idea.plan.units) do
      if u.cad == "EC" then
        ec = ec + 1
        local last = u.slots[#u.slots]
        if last.degree == 0 and last.inversion == 1 then i6 = i6 + 1 end
      elseif u.cad == "DC" then dc = dc + 1 end
    end
    for k, nt in ipairs(idea.melody) do
      if nt.closes == "EC" and idea.melody[k - 1] then
        n = n + 1
        if nt.pitch - idea.melody[k - 1].pitch >= 5 then leapt = leapt + 1 end
      end
    end
  end
  ok(ec > 60 and dc > 60, ("Extended stretches by an evaded close or a deceptive one: %d and %d"):format(ec, dc))
  ok(i6 >= ec * 0.85, ("the evaded close's tonic stands on its third: %d of %d"):format(i6, ec))
  ok(leapt >= n * 0.6, ("and the tune leaps up a fourth or more instead of resolving: %d of %d"):format(leapt, n))
end

do
  -- More galant schemata, as written in a Loop at a chord a bar.
  local want = { ["Do-Re-Mi"] = "C G/B C", Romanesca = "C G/B Am C/E", Fonte = "A7 Dm7 G7 Cmaj7",
                 Monte = "C7 Fmaj7 D7 G7" }
  local bad = {}
  for name, w in pairs(want) do
    for seed = 1, 6 do
      local idea = make({ kind = "Measure", form = "Loop", measureBars = 8, chordPace = "One a bar", progression = name,
                          scale = 1, root = 1, colour = (name == "Fonte" or name == "Monte") and "Sevenths" or "Triads",
                          push = "None", pull = "None", flavours = "Off" }, seed)
      local got = {}
      for _, sl in ipairs(idea.timeline) do
        got[#got + 1] = sl.chord.name .. (sl.bassPos and ("/" .. T.noteName(sl.key, sl.bassPos)) or "")
      end
      local line = table.concat(got, " ")
      if line:sub(1, #w) ~= w then bad[#bad + 1] = name .. ": " .. line end
    end
  end
  eq(#bad, 0, "the Do-Re-Mi, the Romanesca, the Fonte and the Monte, as written: " .. table.concat(bad, "; "))
end

do
  -- The dembow: a kick on every beat, the snare on 3 6 11 14; a backbeat
  -- in 3/4.
  local bad = 0
  for seed = 1, 20 do
    local idea = make({ kind = "Drums", beat = "Reggaeton", fills = "None", drumBars = 2 }, seed)
    local kicks, snares = {}, {}
    for _, nt in ipairs(idea.block.notes) do
      if nt.start < 4 then
        if nt.pitch == I.DRUM.kick then kicks[#kicks + 1] = ("%g"):format(nt.start * 4) end
        if nt.pitch == I.DRUM.snare then snares[#snares + 1] = ("%g"):format(nt.start * 4) end
      end
    end
    table.sort(kicks, function(x, y) return tonumber(x) < tonumber(y) end)
    table.sort(snares, function(x, y) return tonumber(x) < tonumber(y) end)
    if table.concat(kicks, " ") ~= "0 4 8 12" or table.concat(snares, " ") ~= "3 6 11 14" then bad = bad + 1 end
  end
  eq(bad, 0, "Reggaeton: the kick on every beat, the snare on the dembow")
  local three = make({ kind = "Drums", beat = "Reggaeton" }, 1, I.meter(3, 4))
  ok(three.drums.style == "Backbeat", "a Reggaeton in 3/4 is played as a backbeat")
end

do
  -- By the book a six-four doubles its bass (Hutchinson, 26.12); a first
  -- inversion does not.
  local sixFour, doubled = 0, 0
  for seed = 1, 300 do
    local idea = make({ kind = "Measure", inversions = "Common", chordStyle = "Block", voicing = "Close",
                        push = "None", pull = "None", tension = "Off" }, seed)
    for _, sl in ipairs(idea.chordTimeline) do
      if sl.inversion == 2 and not sl.spec then
        sixFour = sixFour + 1
        for _, x in ipairs(part(idea, "Chords").notes) do
          if math.abs(x.start * 4 - sl.s) < 1e-6 and x.pitch % 12 == sl.bassPc then doubled = doubled + 1; break end
        end
      end
    end
  end
  ok(sixFour > 10 and doubled >= sixFour * 0.9, ("a six-four keeps its doubled bass: %d of %d"):format(doubled, sixFour))
end

C.done()
