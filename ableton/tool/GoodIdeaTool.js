/* Good Idea - built by ableton/kit/build.py from ableton/tool.json. Do not edit; edit the sources and rebuild. */
var DEVICE = {"generator": "good-idea", "result": "Idea", "title": "Good Idea", "tool": "generate"};
DEVICE.files = {"adapters/common.lua": "--[[ Noterator - what every generator adapter shares.\n\n     The engines in the folders beside this one are the family's own, copied\n     unchanged from their repositories. An adapter is the only thing written\n     for Noterator: it turns one engine's settings into lists the app can show\n     and its output into parts the app can drop into a score. The app speaks\n     to every adapter the same way:\n\n       A.id, A.name, A.description\n       A.input                 \"none\", or \"selection\" when it works on music\n                               the user has selected\n       A.panel                 \"generate\", \"toolbox\", or nil: not shown\n       A.newState()            a fresh table of settings\n       A.settings(st, ctx)     the settings to show now, each\n                               { id, label, names = {...}, index, hint, hints = {...}, group }\n       A.set(st, id, index)    choose the index-th value of a setting\n       A.useKey(st, root, scale)   follow the score's key (1-based ScaleView indices)\n       A.generate(st, ctx, seed, count)\n                               { results = { { title, detail, beats, parts = {\n                                   { name, drums, instrument, notes = { {start, len, pitch, vel} } } } } },\n                                 message }\n\n     Times are quarter notes from the start of the result. `ctx` is\n       { root, scale, num, den, barBeats, bpm, inst, catalogueId, bars,\n         selection = { notes, beats, drums } } ]]\n\nlocal C = {}\n\nfunction C.indexOf(list, v)\n  for i, x in ipairs(list) do if x == v then return i end end\n  return nil\nend\n\n-- A setting: `values` are what the engine stores, `names` what the window\n-- shows. `when(st)` hides it when it does nothing (no dead controls).\nfunction C.setting(id, label, values, names, opts)\n  opts = opts or {}\n  local shown = {}\n  for i, v in ipairs(values) do shown[i] = names and names[i] or tostring(v) end\n  return { id = id, label = label, values = values, names = shown, hint = opts.hint,\n           hints = opts.hints, when = opts.when, group = opts.group, dynamic = opts.dynamic }\nend\n\nfunction C.onOff(id, label, opts)\n  return C.setting(id, label, { true, false }, { \"On\", \"Off\" }, opts)\nend\n\n-- What the window draws: the settings that apply to this state.\nfunction C.describe(list, st, ctx)\n  local out = {}\n  for _, s in ipairs(list) do\n    if not s.when or s.when(st) then\n      local values, names, hints = s.values, s.names, s.hints\n      if s.dynamic then values, names, hints = s.dynamic(st, ctx) end\n      local index = C.indexOf(values, st[s.id]) or 1\n      out[#out + 1] = { id = s.id, label = s.label, names = names, index = index,\n                        hint = s.hint or \"\", hints = hints or {}, group = s.group or \"\" }\n    end\n  end\n  return out\nend\n\nfunction C.set(list, st, id, index, ctx)\n  for _, s in ipairs(list) do\n    if s.id == id then\n      local values = s.values\n      if s.dynamic then values = s.dynamic(st, ctx) end\n      if values[index] ~= nil then st[id] = values[index] end\n      return true\n    end\n  end\n  return false\nend\n\n-- Notes as the app wants them, whatever the engine called the fields.\nfunction C.notes(list, chan)\n  local out = {}\n  for _, n in ipairs(list or {}) do\n    if not chan or (n.chan or 0) == chan then\n      out[#out + 1] = { start = n.start, len = n.len, pitch = n.pitch, vel = n.vel or 100 }\n    end\n  end\n  table.sort(out, function(a, b)\n    if a.start ~= b.start then return a.start < b.start end\n    return a.pitch < b.pitch\n  end)\n  return out\nend\n\nfunction C.finish(notes)\n  local e = 0\n  for _, n in ipairs(notes) do e = math.max(e, n.start + n.len) end\n  return e\nend\n\nreturn C\n", "adapters/good_idea.lua": "--[[ Good Idea, in Noterator.\n\n     Every setting is Good Idea's own (gi_idea.lua's SETTINGS), shown the way\n     its window shows them, with \"Any\" where the engine can decide. One result\n     is one idea number: asking for six gives six neighbouring ideas, and the\n     same number with the same settings always gives the same idea back. ]]\n\nlocal C = engine(\"adapters/common.lua\")\nlocal T = engine(\"good-idea/gi_theory.lua\")\nlocal I = engine(\"good-idea/gi_idea.lua\").init(T)\n\nlocal A = {\n  id = \"good-idea\",\n  name = \"Generate Notes\",   -- Good Idea, named for what it does in the app (decision 0025)\n  description = \"A motif, a phrase, eight to sixteen bars of melody, chords and bass, or a drum groove - calculated from the rules that make music sound like music.\",\n  input = \"none\",\n  panel = \"generate\",\n}\n\nlocal LIST = {}\nfor _, s in ipairs(I.SETTINGS) do\n  if not s.hidden then\n    local values, names, hints = {}, {}, {}\n    if s.any then\n      values[1], names[1], hints[1] = \"Any\", \"Any\", \"Let each idea decide.\"\n    end\n    for _, v in ipairs(s.values) do\n      values[#values + 1] = v\n      names[#names + 1] = I.valueName(s, v)\n      hints[#hints + 1] = (s.hints and s.hints[v]) or \"\"\n    end\n    LIST[#LIST + 1] = C.setting(s.id, s.label, values, names, {\n      hints = hints, group = s.step,\n      when = function(st) return I.shows(s, st) end,\n    })\n  end\nend\n\n-- Good Idea starts its Voicing on Close; in the apps it starts on Any, so\n-- each idea picks its own and the chords sound different from one idea to\n-- the next (decision 0056). The engine is unchanged: only where it starts.\nfunction A.newState()\n  local st = I.newState()\n  st.voicing = \"Any\"\n  I.clampState(st)\n  return st\nend\nfunction A.settings(st, ctx) return C.describe(LIST, st, ctx) end\nfunction A.set(st, id, index, ctx)\n  C.set(LIST, st, id, index, ctx)\n  I.clampState(st)\nend\n\nfunction A.useKey(st, root, scale)\n  st.root, st.scale = root, scale\n  I.clampState(st)\nend\n\n-- With bars selected to generate into, a length left on Any becomes the one\n-- that fits them best: the longest that fits, else the shortest there is. The\n-- app then repeats or trims the idea to the selection exactly.\nlocal BARS_SETTING = { Motif = \"motifBars\", Phrase = \"phraseBars\", Measure = \"measureBars\", Drums = \"drumBars\" }\n\nlocal function fitBars(st, ctx)\n  local id = BARS_SETTING[st.kind]\n  if not id or not ctx.rangeBars or ctx.rangeBars <= 0 or st[id] ~= \"Any\" then return nil end\n  local best, shortest\n  for _, v in ipairs(I.BY_ID[id].values) do\n    if v <= ctx.rangeBars and (not best or v > best) then best = v end\n    if not shortest or v < shortest then shortest = v end\n  end\n  st[id] = best or shortest\n  return id\nend\n\nfunction A.generate(st, ctx, seed, count)\n  local fitted = fitBars(st, ctx)\n  local ok, out = pcall(A.make, st, ctx, seed, count)\n  if fitted then st[fitted] = \"Any\" end\n  if not ok then error(out, 0) end\n  return out\nend\n\nfunction A.make(st, ctx, seed, count)\n  local meter = I.meter(ctx.num, ctx.den)\n  local out = {}\n  for k = 0, (count or 6) - 1 do\n    local s = (seed - 1 + k) % I.MAX_SEED + 1\n    local idea = I.make(st, meter, s)\n    local parts = {}\n    for _, p in ipairs(idea.block.parts) do\n      parts[#parts + 1] = { name = p.name, drums = p.drums and true or false, notes = C.notes(p.notes) }\n    end\n    local detail = idea.summary or \"\"\n    if idea.chords and idea.chords ~= \"\" then detail = detail .. \"\\n\" .. idea.chords end\n    -- \"Good Idea 63797 - Phrase (melody), 4 bars, C Major\": the engine's\n    -- name and seed are the REAPER file name; the list wants the rest.\n    local title = idea.block.name:gsub(\"^Good Idea %d+ %- \", \"\")\n    out[#out + 1] = { title = title, detail = detail,\n                      beats = idea.block.beats, parts = parts }\n  end\n  return { results = out }\nend\n\nreturn A\n", "adapters/index.lua": "return { \"adapters/good_idea.lua\" }\n", "good-idea/gi_idea.lua": "--[[ Good Idea - the ideas.\n\n     Pure Lua: nothing here touches REAPER or ImGui. `M.make(st, meter, seed)`\n     takes the settings, the project's metre and an idea number, and returns\n     the idea - a block of MIDI notes in parts. Nothing else goes in, so the\n     same three always give the same idea\n     (docs/decisions/0002-an-idea-is-a-number.md).\n\n     How an idea is made, top to bottom:\n\n       1. resolve   every setting left on \"Any\" is rolled, each from its own\n                    draw of the dice\n       2. plan      the idea is cut into units - a basic idea, its repeat, a\n                    sequence of it, an answer, a fragment, a cadence - from a\n                    template for the kind and length (Motif, Phrase) or the\n                    form (Measure)\n       3. harmony   each unit gets its chords: a walk through the\n                    tonic-subdominant-dominant table (gi_theory) ending in\n                    the unit's cadence. A repeat reuses its source's chords,\n                    a sequence shifts them, an answer changes the ending\n       4. melody    each new unit gets a rhythm (the strongest beats, or a\n                    Euclidean spread for syncopation) and a line (a weighted\n                    walk pulled toward a contour, chord tones on the beat,\n                    leaps filled by a step back). Repeats copy, sequences\n                    shift, answers change the ending, fragments cut and fall\n       5. parts     the chords voiced and played in a pattern; for a Measure\n                    a bass line and a drum kit as well\n       6. block     notes in quarter notes, a part per instrument\n\n     Everything is worked out in sixteenth-note steps and scale positions, and\n     only turned into quarter notes and MIDI pitches at the very end.\n]]\n\nlocal M = {}\nlocal T\n\nfunction M.init(theory)\n  T = theory\n  M.buildSettings()\n  return M\nend\n\nM.MAX_SEED = 99999\nM.ACCENT = 115\n\n------------------------------------------------------------------------------\n-- The dice\n--\n-- Midi Variator's generator (Park and Miller's), so a seed always gives the\n-- same numbers on any Lua. Each part of the idea draws from its own stream,\n-- seeded from the idea number and the stream's name, so changing one setting\n-- changes only what depends on it: a different chord style leaves the melody\n-- alone, a different key moves the same tune into it.\n------------------------------------------------------------------------------\n\nfunction M.random(seed)\n  local s = math.floor(math.abs(seed or 1)) % 2147483646 + 1\n  local function nextr()\n    s = s * 48271 % 2147483647\n    return (s - 1) / 2147483646\n  end\n  -- The first few numbers from neighbouring seeds are close together; let\n  -- them go.\n  for _ = 1, 4 do nextr() end\n  return nextr\nend\n\nlocal STREAMS = { pick = 1, plan = 2, harmony = 3, rhythm = 4, melody = 5,\n                  chords = 6, bass = 7, drums = 8, borrow = 9, push = 10,\n                  pull = 11, kit = 12, colour = 13, invert = 14, applied = 15, schema = 16,\n                  tension = 17, sixnine = 18, ghost = 19, chroma = 20, passing = 21, commontone = 22 }\n\nfunction M.stream(seed, name)\n  local salt = STREAMS[name] or 0\n  return M.random((math.floor(seed or 1) * 7919 + salt * 104729 + 12345) % 2147483646)\nend\n\nlocal function between(rnd, lo, hi) return lo + (hi - lo) * rnd() end\nlocal function coin(rnd, p) return rnd() < (p or 0.5) end\nlocal function pickOne(rnd, list) return list[math.floor(rnd() * #list) + 1] end\nlocal function round(x) return math.floor(x + 0.5) end\n\n-- One of `items` in proportion to `weights` (a list, or nil for even), from\n-- one number already drawn.\nlocal function pickAt(x, items, weights)\n  local total = 0\n  for i = 1, #items do total = total + (weights and weights[i] or 1) end\n  local at = x * total\n  for i = 1, #items do\n    at = at - (weights and weights[i] or 1)\n    if at < 0 then return items[i] end\n  end\n  return items[#items]\nend\n\nlocal function weighted(rnd, items, weights) return pickAt(rnd(), items, weights) end\n\n------------------------------------------------------------------------------\n-- Metre\n--\n-- A bar is counted in sixteenths. The beat is what the time signature's\n-- bottom number says, except in 6/8, 9/8 and 12/8, where it is the dotted\n-- quarter - that is how those are felt and played.\n------------------------------------------------------------------------------\n\nfunction M.meter(num, den)\n  num = math.max(1, math.floor(tonumber(num) or 4))\n  den = math.max(1, math.floor(tonumber(den) or 4))\n  local bar = math.max(4, round(num * 16 / den))\n  local beat\n  if den == 8 and num % 3 == 0 and num >= 6 then beat = 6\n  else beat = math.max(1, math.floor(16 / den)) end\n  if bar % beat ~= 0 then beat = 1 end\n  local beats = bar // beat\n  -- The half-bar beat (beat 3 of 4/4) is stronger than the others.\n  local mid = (beats % 2 == 0 and beats >= 4) and bar // 2 or nil\n  return { num = num, den = den, bar = bar, beat = beat, beats = beats, mid = mid,\n           barBeats = bar / 4 }\nend\n\n-- How strong a step is: 3 the downbeat, 2.5 the half bar, 2 a beat, 1 an\n-- eighth, 0 a sixteenth.\nfunction M.strength(meter, step)\n  local s = step % meter.bar\n  if s == 0 then return 3 end\n  if meter.mid and s == meter.mid then return 2.5 end\n  if s % meter.beat == 0 then return 2 end\n  if s % 2 == 0 then return 1 end\n  return 0\nend\n\nlocal function snap(meter, x) return round(x / meter.beat) * meter.beat end\n\n------------------------------------------------------------------------------\n-- The settings\n--\n-- One list, and everything reads it: the window draws a row of buttons per\n-- setting, the state is clamped and saved from it, resolve rolls the ones\n-- left on \"Any\", and the UI test clicks every value of every one. A setting\n-- shows only `when` it means something for what is chosen (no dead controls).\n------------------------------------------------------------------------------\n\nM.KINDS = { \"Motif\", \"Phrase\", \"Measure\", \"Drums\" }\n\nlocal function notDrums(st) return st.kind ~= \"Drums\" end\nlocal function hasMelody(st)\n  return st.kind ~= \"Drums\" and (st.kind ~= \"Phrase\" or st.content ~= \"Chords\")\nend\nlocal function hasChords(st)\n  return st.kind == \"Measure\" or (st.kind == \"Phrase\" and st.content ~= \"Melody\")\nend\nM.hasMelody, M.hasChords = hasMelody, hasChords\n\nlocal function barsName(v) return v .. (v == 1 and \" bar\" or \" bars\") end\n-- What a value's button says, where it is not the value itself. Values are\n-- stored and never renamed; only their labels change, and a label follows\n-- Apple's title-style capitals (0030).\nlocal function barsLabel(v) return v .. (v == 1 and \" Bar\" or \" Bars\") end\nlocal function labelled(names) return function(v) return names[v] or v end end\n\nfunction M.buildSettings()\n  local rootIdx, scaleIdx = {}, {}\n  for i = 1, #T.ROOTS do rootIdx[i] = i end\n  for i = 1, #T.SCALES do scaleIdx[i] = i end\n\n  M.SETTINGS = {\n    { id = \"kind\", label = \"Kind\", step = \"Idea\", values = M.KINDS, default = \"Motif\",\n      hints = {\n        Motif = \"A short melodic hook, 1 to 4 bars, built from one small cell repeated and varied.\",\n        Phrase = \"A 1 to 4 bar phrase: a melody, a chord pattern, or both in one clip, with a proper ending.\",\n        Measure = \"8 to 16 bars of music: melody, chords and bass, laid out in a form.\",\n        Drums = \"1 to 16 bars of drums on General MIDI notes: a groove, varied, with fills where you ask for them.\",\n      } },\n    { id = \"motifBars\", label = \"Bars\", step = \"Idea\", values = { 1, 2, 3, 4 }, any = true,\n      default = \"Any\", name = barsLabel, weights = { 1, 3, 1, 2 },\n      when = function(st) return st.kind == \"Motif\" end },\n    { id = \"phraseBars\", label = \"Bars\", step = \"Idea\", values = { 1, 2, 3, 4 }, any = true,\n      default = \"Any\", name = barsLabel, weights = { 1, 3, 1, 3 },\n      when = function(st) return st.kind == \"Phrase\" end },\n    { id = \"measureBars\", label = \"Bars\", step = \"Idea\", values = { 8, 12, 16 }, any = true,\n      default = \"Any\", name = barsLabel, weights = { 3, 1, 2 },\n      when = function(st) return st.kind == \"Measure\" end },\n    { id = \"content\", label = \"Content\", step = \"Idea\", values = { \"Melody\", \"Chords\", \"Both\" },\n      any = true, default = \"Any\", weights = { 1, 1, 1.3 },\n      when = function(st) return st.kind == \"Phrase\" end,\n      hints = {\n        Melody = \"A tune on its own.\",\n        Chords = \"A chord pattern on its own, with the root in the bass.\",\n        Both = \"A tune over a chord pattern, together in one clip (tune on channel 1, chords on 2).\",\n      } },\n\n    { id = \"root\", label = \"Key\", step = \"Key\", values = rootIdx, any = true, default = 1,\n      name = function(v) return T.ROOTS[v].name end, when = notDrums,\n      -- Any rolls the twelve common spellings, not C# and Db both.\n      anyValues = { 1, 3, 4, 6, 7, 8, 9, 11, 13, 14, 16, 17 } },\n    { id = \"scale\", label = \"Scale\", step = \"Key\", values = scaleIdx, any = true, default = 1,\n      name = function(v) return T.SCALES[v].name end, when = notDrums,\n      -- Any rolls the scales a tune is usually written in; the colour scales\n      -- (blues, whole tone, diminished) are there to be chosen.\n      anyValues = { 1, 2, 5, 8, 3, 6, 7, 10, 11 },\n      anyWeights = { 3, 3, 1.5, 1.2, 1, 0.8, 0.8, 1, 1 } },\n\n    { id = \"pace\", label = \"Pace\", step = \"Feel\", values = { \"Calm\", \"Flowing\", \"Busy\" },\n      any = true, default = \"Any\", weights = { 1, 1.5, 1 },\n      hints = {\n        Calm = \"Few notes: halves, quarters and the odd eighth.\",\n        Flowing = \"Eighth notes moving.\",\n        Busy = \"Sixteenths.\",\n      } },\n    { id = \"groove\", label = \"Groove\", step = \"Feel\",\n      values = { \"Straight\", \"Syncopated\", \"Tresillo\", \"Habanera\", \"Clave\", \"3+3+3+3+2+2\" },\n      any = true, default = \"Any\",\n      -- (Any rolls the two 1.0 had; the named rhythms, 1.11, are there to\n      -- choose.)\n      anyValues = { \"Straight\", \"Syncopated\" },\n      hints = {\n        Straight = \"Notes on the strongest beats first: on the beat, then the half beat.\",\n        Syncopated = \"Notes spread evenly over the bar (a Euclidean rhythm) and turned so they fall off the beat \u00e2\u0080\u0094 the tresillo, the cinquillo.\",\n        Tresillo = \"3+3+2 eighths: 1, the \u00e2\u0080\u009cand\u00e2\u0080\u009d of 2, 4 \u00e2\u0080\u0094 the Cuban tresillo, the commonest syncopation in pop. Pulsing chords, a pulsing bass and the kick play it; the tune is syncopated. (In 4/4; syncopated elsewhere.)\",\n        Habanera = \"The habanera: 1, the \u00e2\u0080\u009cand\u00e2\u0080\u009d of 2, 3, 4 \u00e2\u0080\u0094 the tresillo with beat 3 filled in. Pulsing chords, a pulsing bass and the kick play it. (In 4/4; syncopated elsewhere.)\",\n        Clave = \"The son clave, 3-2, in a bar of sixteenths: 1, the \u00e2\u0080\u009ca\u00e2\u0080\u009d of 1, the \u00e2\u0080\u009cand\u00e2\u0080\u009d of 2, the \u00e2\u0080\u009cand\u00e2\u0080\u009d of 3, 4. Pulsing chords, a pulsing bass and the kick play it. (In 4/4; syncopated elsewhere.)\",\n        [\"3+3+3+3+2+2\"] = \"Sixteenths grouped 3+3+3+3+2+2 (\u00e2\u0080\u009cShape of You\u00e2\u0080\u009d): the pop off-beat that spans the bar. Pulsing chords, a pulsing bass and the kick play it. (In 4/4; syncopated elsewhere.)\",\n      } },\n\n    { id = \"contour\", label = \"Contour\", step = \"Melody\",\n      values = { \"Arch\", \"Rise\", \"Fall\", \"Wave\", \"Valley\" }, any = true, default = \"Any\",\n      weights = { 1.6, 1, 1, 1, 0.8 }, when = hasMelody,\n      hints = {\n        Arch = \"Up to a high point about two thirds through (the golden section), then down.\",\n        Rise = \"Climbing all the way.\",\n        Fall = \"Starting high and coming down.\",\n        Wave = \"Up and down, and up and down.\",\n        Valley = \"Down to a low point two thirds through, then back up.\",\n      } },\n    { id = \"register\", label = \"Register\", step = \"Melody\", values = { \"Low\", \"Middle\", \"High\" },\n      any = true, default = \"Middle\", weights = { 1, 2, 1 }, when = hasMelody,\n      hints = {\n        Low = \"Around G3.\",\n        Middle = \"Around G4.\",\n        High = \"Around E5.\",\n      } },\n\n    { id = \"colour\", label = \"Colour\", step = \"Chords\", values = T.COLOURS, any = true,\n      default = \"Any\", weights = { 1.5, 1, 1 }, when = hasChords,\n      hints = {\n        Triads = \"Three-note chords: C, Dm, G.\",\n        Sevenths = \"Every chord with its seventh: Cmaj7, Dm7, G7.\",\n        Mixed = \"Sevenths where they pull (ii, V), added ninths on the others: Cadd9, Dm7, G7.\",\n      } },\n    { id = \"chordPace\", label = \"Chord pace\", step = \"Chords\",\n      values = { \"Slow\", \"One a bar\", \"1.5 a bar\", \"Two a bar\", \"4 a bar\" }, any = true, default = \"Any\",\n      -- Shown as numbers (0.5, 1, 1.5, 2, 4 a bar); kept by their 1.0 names\n      -- so saved settings still load. Any rolls the three 1.0 had, with\n      -- 1.0's weights, so a 1.0 idea number still rolls the same pace; 1.5\n      -- and 4 a bar are there to choose.\n      name = labelled({ Slow = \"0.5 a Bar\", [\"One a bar\"] = \"1 a Bar\", [\"1.5 a bar\"] = \"1.5 a Bar\",\n                        [\"Two a bar\"] = \"2 a Bar\", [\"4 a bar\"] = \"4 a Bar\" }),\n      anyValues = { \"Slow\", \"One a bar\", \"Two a bar\" }, anyWeights = { 0.7, 1.6, 0.8 },\n      when = hasChords,\n      hints = {\n        Slow = \"Half a chord a bar: a chord every two bars.\",\n        [\"One a bar\"] = \"A chord a bar.\",\n        [\"1.5 a bar\"] = \"Three chords every two bars: in 4/4, three beats, three beats, two \u00e2\u0080\u0094 the 3+3+2 that pushes a progression along. (Chosen, not rolled by Any.)\",\n        [\"Two a bar\"] = \"Two chords a bar: one every half bar.\",\n        [\"4 a bar\"] = \"A chord on every beat \u00e2\u0080\u0094 four a bar in 4/4, three in 3/4. (Chosen, not rolled by Any.)\",\n      } },\n    { id = \"chordStyle\", label = \"Style\", step = \"Chords\", values = { \"Block\", \"Pulse\", \"Broken\", \"Pedal\", \"Offbeat\", \"Fill\" },\n      any = true, default = \"Any\", weights = { 1, 1.2, 1, 1, 1, 1 }, when = hasChords,\n      -- (Any rolls the three 1.0 had; the 1.11 styles are there to choose.)\n      anyValues = { \"Block\", \"Pulse\", \"Broken\" }, anyWeights = { 1, 1.2, 1 },\n      hints = {\n        Block = \"Held chords, struck again at each bar line.\",\n        Pulse = \"The chord struck in rhythm: on the beat, or syncopated, or in the groove\u00e2\u0080\u0099s named rhythm.\",\n        Broken = \"One note at a time: up, up and down, Alberti, rolling.\",\n        Pedal = \"Each chord struck once and held until the next \u00e2\u0080\u0094 a pad, an orchestra\u00e2\u0080\u0099s \u00e2\u0080\u009csustain pedal\u00e2\u0080\u009d under the tune.\",\n        Offbeat = \"Short chords on the off-beats only \u00e2\u0080\u0094 the reggae skank, the \u00e2\u0080\u009cpah\u00e2\u0080\u009d of oom-pah (afterbeats).\",\n        Fill = \"The chords answer the tune: struck where it holds a note or rests, quiet while it moves \u00e2\u0080\u0094 and always where the chord changes, if nowhere else.\",\n      } },\n\n    { id = \"form\", label = \"Form\", step = \"Arrangement\",\n      values = { \"Period\", \"Sentence\", \"Song\", \"Loop\", \"Hybrid 1\", \"Hybrid 2\", \"Hybrid 3\", \"Hybrid 4\",\n                 \"Ternary\", \"Extended\" }, any = true, default = \"Any\",\n      -- (1.13: not shown; every idea rolls one, each about one time in ten.\n      -- 0025.)\n      hidden = true,\n      when = function(st) return st.kind == \"Measure\" end,\n      hints = {\n        [\"Hybrid 1\"] = \"Antecedent + continuation (Caplin\u00e2\u0080\u0099s first hybrid): an idea and a contrasting idea to a half close, then breaking it up and speeding to a full close. (Chosen, not rolled by Any.)\",\n        [\"Hybrid 2\"] = \"Antecedent + cadential: an idea and a contrasting idea to a half close, then one long cadential phrase home. (Chosen, not rolled by Any.)\",\n        [\"Hybrid 3\"] = \"Compound basic idea + continuation: an idea and a contrasting one with no cadence between, then breaking it up to a full close. (Chosen, not rolled by Any.)\",\n        [\"Hybrid 4\"] = \"Compound basic idea + consequent: an idea and a contrasting one, then both again, the second time to a full close. (Chosen, not rolled by Any.)\",\n        Ternary = \"A B A (the small ternary): a theme closed in the key, a contrasting middle standing on the dominant, the theme again to finish. (Chosen, not rolled by Any.)\",\n        Extended = \"A sentence stretched by a deceptive cadence: it reaches V and goes to vi instead of home, so the end is played \u00e2\u0080\u009cone more time\u00e2\u0080\u009d to a full close. (Chosen, not rolled by Any.)\",\n        Period = \"A question and its answer: the same opening twice, ending open and then closed.\",\n        Sentence = \"An idea, the idea again on another chord, then breaking it up and speeding to the cadence.\",\n        Song = \"A A B A: a tune, the tune again, something different, the tune to finish.\",\n        Loop = \"One progression round and round, the tune varied over it \u00e2\u0080\u0094 a groove to build on.\",\n      } },\n    { id = \"bass\", label = \"Bass\", step = \"Arrangement\", values = { \"Held\", \"Pulse\", \"Moving\" },\n      any = true, default = \"Any\",\n      when = function(st) return st.kind == \"Measure\" end,\n      hints = {\n        Held = \"The root, held under each chord.\",\n        Pulse = \"The root, in the rhythm a kick drum would play: on 1 and 3, or syncopated.\",\n        Moving = \"On the beat: the root, then the fifth or the octave, and a step into the next chord.\",\n      } },\n    -- Retired: in 1.2 a Measure always had drums; since 1.3 it has none -\n    -- drums are the Drums kind. It stays in the list, never shown and only\n    -- ever Off, because the list is the order the dice are drawn in.\n    { id = \"drums\", label = \"Drums\", step = \"Arrangement\", values = { \"Off\" },\n      default = \"Off\", retired = true, when = function() return false end },\n    { id = \"layout\", label = \"Layout\", step = \"Out\", values = { \"Tracks\", \"One item\" },\n      name = labelled({ [\"One item\"] = \"One Item\" }),\n      default = \"Tracks\", when = function(st) return st.kind == \"Measure\" end,\n      hints = {\n        Tracks = \"A new track for each part \u00e2\u0080\u0094 Melody, Chords, Bass \u00e2\u0080\u0094 under the selected track.\",\n        [\"One item\"] = \"Every part in one item on the selected track, each on its own MIDI channel (1, 2, 3).\",\n      } },\n\n    { id = \"velocity\", label = \"Velocity\", step = \"Out\", values = { \"Flat\", \"Accents\", \"Shaped\" },\n      default = \"Shaped\",\n      hints = {\n        Flat = \"Every note at 100.\",\n        Accents = \"Every note at 100, and the downbeats and the start of each idea at \" .. M.ACCENT .. \".\",\n        Shaped = \"As a player would: the downbeat loudest, the beats a little softer, the off-beats softer still; the chords under the tune, the inner notes of a chord under its top, the bass just under the tune.\",\n      } },\n\n    -- Added in 1.1. They come last in this list because the list is also\n    -- the order the dice are drawn in: added anywhere else, they would have\n    -- changed what every 1.0 idea number rolled.\n    { id = \"figures\", label = \"Figures\", step = \"Feel\",\n      values = { \"Plain\", \"Dotted\", \"Triplets\", \"Mixed\" }, any = true, default = \"Any\",\n      weights = { 2, 1, 1, 1 },\n      hints = {\n        Plain = \"Straight eighths and sixteenths.\",\n        Dotted = \"Now and then a pair of notes becomes long-short: a dotted eighth and a sixteenth, a dotted quarter and an eighth \u00e2\u0080\u0094 in the tune, the chords and a moving bass.\",\n        Triplets = \"Now and then a beat becomes three: eighth-note triplets, or three quarter notes across two beats. The drums shuffle and broken chords roll in threes.\",\n        Mixed = \"Now and then dotted, now and then triplets.\",\n      } },\n    { id = \"push\", label = \"Push\", step = \"Feel\", values = { \"None\", \"Some\", \"Lots\" },\n      any = true, default = \"Any\", weights = { 1.5, 1.5, 1 }, when = notDrums,\n      hints = {\n        None = \"Every chord arrives on the beat.\",\n        Some = \"Some chords arrive an eighth early \u00e2\u0080\u0094 on the \u00e2\u0080\u009cand\u00e2\u0080\u009d before the beat \u00e2\u0080\u0094 and the tune and the bass come with them.\",\n        Lots = \"Most chords arrive an eighth early: a pushed, syncopated feel.\",\n      } },\n    { id = \"borrowed\", label = \"Borrowed\", step = \"Key\", values = { \"Off\", \"Rare\", \"Common\" }, default = \"Rare\",\n      when = function(st) return st.kind ~= \"Drums\" and (st.scale == \"Any\" or #T.SCALES[st.scale].iv == 7) end,\n      hints = {\n        Off = \"Every chord from the scale.\",\n        Rare = \"About one idea in four borrows one chord from another scale on the same key note \u00e2\u0080\u0094 a minor iv or a bVI in a major key, a major IV in a minor one. And now and then, before a close\u00e2\u0080\u0099s V, the ii or IV becomes a chromatic chord: the Neapolitan (Db/F in C) or an augmented sixth (Ab7 in C: Italian, French, or German, which goes through the I6/4). The window says which chord, and where it is from. Seven-note scales only.\",\n        Common = \"About two ideas in three borrow a chord, and a longer one (eight chords or more) sometimes two; about half the closes that can take a chromatic chord do.\",\n      } },\n\n    -- Added in 1.2, last for the same reason.\n    { id = \"pull\", label = \"Pull\", step = \"Feel\", values = { \"None\", \"Some\", \"Lots\" },\n      any = true, default = \"Any\", weights = { 1.5, 1.5, 1 }, when = hasChords,\n      hints = {\n        None = \"Every chord is played on the beat.\",\n        Some = \"Some chords are played an eighth late, laid back behind the beat; the tune stays on it, and the bass either stays with the tune or lies back with the chords (the idea decides).\",\n        Lots = \"Most chords lie back an eighth: a lazy, behind-the-beat feel.\",\n      } },\n    { id = \"drumBars\", label = \"Bars\", step = \"Idea\", values = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 },\n      any = true, default = \"Any\", name = function(v) return tostring(v) end,\n      weights = { 1, 3, 0.3, 3, 0.2, 0.3, 0.2, 2, 0.2, 0.2, 0.2, 0.6, 0.2, 0.2, 0.2, 1 },\n      when = function(st) return st.kind == \"Drums\" end },\n    { id = \"beat\", label = \"Beat\", step = \"Drums\",\n      values = { \"Backbeat\", \"Half-time\", \"Four on the floor\", \"Breakbeat\", \"Reggaeton\" }, any = true, default = \"Any\",\n      name = labelled({ [\"Half-time\"] = \"Half-Time\", [\"Four on the floor\"] = \"Four on the Floor\" }),\n      weights = { 2, 1, 1, 1, 1 }, when = function(st) return st.kind == \"Drums\" end,\n      hints = {\n        Backbeat = \"Kick on and around 1 and 3, snare on 2 and 4.\",\n        [\"Half-time\"] = \"The snare on 3 only: twice as slow, twice as heavy.\",\n        [\"Four on the floor\"] = \"A kick on every beat, a clap on 2 and 4, open hats on the off-beats.\",\n        Breakbeat = \"A broken kick, the snare on 2 and 4 with one knocked off it, sixteenths on the hats. (In 4/4; a backbeat elsewhere.)\",\n        Reggaeton = \"The dembow: a kick on every beat, the snare on the \u00e2\u0080\u009ca\u00e2\u0080\u009d of 1, the \u00e2\u0080\u009cand\u00e2\u0080\u009d of 2, the \u00e2\u0080\u009ca\u00e2\u0080\u009d of 3 and the \u00e2\u0080\u009cand\u00e2\u0080\u009d of 4 \u00e2\u0080\u0094 the tresillo, twice. (In 4/4; a backbeat elsewhere.)\",\n      } },\n    { id = \"fills\", label = \"Fills\", step = \"Drums\",\n      values = { \"None\", \"At the end\", \"Every 4 bars\", \"Every 2 bars\" }, any = true, default = \"Any\",\n      name = labelled({ [\"At the end\"] = \"At the End\", [\"Every 4 bars\"] = \"Every 4 Bars\",\n                        [\"Every 2 bars\"] = \"Every 2 Bars\" }),\n      weights = { 0.6, 2, 2, 1 }, when = function(st) return st.kind == \"Drums\" end,\n      hints = {\n        None = \"The groove all the way.\",\n        [\"At the end\"] = \"A fill in the last bar, leading back to the top \u00e2\u0080\u0094 and a crash when it gets there.\",\n        [\"Every 4 bars\"] = \"A fill at the end of every fourth bar, and of the last.\",\n        [\"Every 2 bars\"] = \"A fill at the end of every second bar.\",\n      } },\n    { id = \"cymbal\", label = \"Cymbal\", step = \"Drums\", values = { \"Hats\", \"Ride\" }, any = true,\n      default = \"Any\", weights = { 3, 1 }, when = function(st) return st.kind == \"Drums\" end,\n      hints = {\n        Hats = \"Time kept on the hi-hats (42), opening (46) now and then.\",\n        Ride = \"Time kept on the ride (51), the bell (53) on the beat, the hi-hat pedal (44) on the backbeat.\",\n      } },\n\n    -- Added in 1.5, last for the same reason. Off, Close and Off are the\n    -- 1.4 sound, and draw nothing from the dice.\n    { id = \"flavours\", label = \"Flavours\", step = \"Chords\", values = { \"Off\", \"Rare\", \"Common\" }, default = \"Rare\",\n      when = function(st)\n        return hasChords(st) and (st.scale == \"Any\" or #T.SCALES[st.scale].iv == 7)\n      end,\n      hints = {\n        Off = \"Every chord in the Colour chosen, and nothing else.\",\n        Rare = \"Now and then a chord takes another colour: a sus4 or sus2, an added 2nd or 9th, a 6th (or a 6/9) \u00e2\u0080\u0094 and, where the chords have sevenths, a 7sus4, a 9th, or the diminished chord on its third (G7 becomes Bm7b5). Never the first chord or the cadence. Seven-note scales only.\",\n        Common = \"The same colours, on about half the chords that can take one.\",\n      } },\n    { id = \"voicing\", label = \"Voicing\", step = \"Chords\", values = T.VOICINGS, any = true, default = \"Close\",\n      -- (Any rolls the seven 1.5 had; Power, 1.12, and Drop 4, 1.14, are there\n      -- to choose.)\n      anyValues = { \"Close\", \"Open\", \"Drop 2\", \"Drop 3\", \"Drop 2 & 4\", \"Shell\", \"Rootless\" },\n      anyWeights = { 3, 1, 1, 1, 1, 1, 1 },\n      weights = { 3, 1, 1, 1, 1, 1, 1, 1, 1 }, when = hasChords,\n      hints = {\n        Close = \"Every note once, inside an octave, each chord nearest the one before.\",\n        Open = \"Spread wide: the root, the fifth, then the third an octave up and the rest above it.\",\n        [\"Drop 2\"] = \"Four notes in close position with the second from the top dropped an octave \u00e2\u0080\u0094 the guitarist\u00e2\u0080\u0099s and arranger\u00e2\u0080\u0099s favourite.\",\n        [\"Drop 3\"] = \"Four notes with the third from the top dropped an octave: a wide gap at the bottom.\",\n        [\"Drop 2 & 4\"] = \"Four notes with the second and the fourth from the top dropped an octave: wide, like a big band\u00e2\u0080\u0099s saxes.\",\n        [\"Drop 4\"] = \"Four notes in close position with the lowest dropped an octave: three close notes over a gap. (Chosen, not rolled by Any.)\",\n        Shell = \"The root, the third and the seventh \u00e2\u0080\u0094 the notes that say what the chord is, and nothing else.\",\n        Rootless = \"No root \u00e2\u0080\u0094 the bass has it: the third, fifth, seventh and ninth, the jazz pianist\u00e2\u0080\u0099s left hand.\",\n        Power = \"The root, the fifth and the root an octave up \u00e2\u0080\u0094 no third: the rock guitarist\u00e2\u0080\u0099s power chord (C5). A chord with no perfect fifth plays its root in octaves. (Chosen, not rolled by Any.)\",\n      } },\n    { id = \"inversions\", label = \"Inversions\", step = \"Chords\", values = { \"Off\", \"Rare\", \"Common\" }, default = \"Rare\",\n      when = hasChords,\n      hints = {\n        Off = \"Every chord with its root in the bass.\",\n        Rare = \"Now and then a chord\u00e2\u0080\u0099s third, fifth or seventh in the bass, where it makes the bass move by step \u00e2\u0080\u0094 C G/B Am, a passing chord, or the I6/4 before the cadence. The bass plays it.\",\n        Common = \"The same, on more than half the chords where an inversion does its job.\",\n      } },\n\n    -- Added in 1.7, last for the same reason. Free is 1.6's part-writing,\n    -- note for note, and draws nothing from the dice.\n    { id = \"partWriting\", label = \"Part-writing\", step = \"Chords\", values = { \"By the book\", \"Free\" },\n      name = labelled({ [\"By the book\"] = \"By the Book\" }),\n      -- (1.13: not shown - always by the book; Free is kept for the tests,\n      -- which compare the two. 0025.)\n      default = \"By the book\", when = hasChords, hidden = true,\n      hints = {\n        [\"By the book\"] = \"As the harmony and orchestration books have it: an inverted chord does not double its bass note (G/B plays no B above the bass), a seventh falls a step into the next chord, a half close with Mixed is a plain V, the chords sit just under the tune, the bass no more than an octave and a fifth below the chords and never in among them, and no parallel fifths or octaves between the tune and the bass.\",\n        Free = \"As Good Idea did before 1.7: every chord note in every chord, the chords under the whole tune\u00e2\u0080\u0099s lowest note, the bass where it falls.\",\n      } },\n\n    -- Added in 1.8, last for the same reason. Off draws nothing.\n    { id = \"applied\", label = \"Applied\", step = \"Key\", values = { \"Off\", \"Rare\", \"Common\" }, default = \"Rare\",\n      when = function(st) return st.kind ~= \"Drums\" and (st.scale == \"Any\" or #T.SCALES[st.scale].iv == 7) end,\n      hints = {\n        Off = \"No chord borrowed from another key.\",\n        Rare = \"Now and then the chord before a major or minor chord becomes that chord\u00e2\u0080\u0099s own dominant \u00e2\u0080\u0094 its V (or V7), or its leading-tone chord \u00e2\u0080\u0094 borrowed from the key the next chord is home in: D7 before G in C major (V7/V), E before Am (V/vi). The most common chromatic chord there is. And where the bass climbs a tone (F to G), now and then a passing diminished seventh on the note between (F F#dim7 G); and, but with Triads, a held I or V coloured by the common-tone diminished seventh (C D#dim7/C C), its root held. The window says which, and where. Seven-note scales only.\",\n        Common = \"The same, on more of the chords that can take one, and in most ideas.\",\n      } },\n\n    -- Added in 1.9, last for the same reason. Walk draws nothing new.\n    { id = \"progression\", label = \"Progression\", step = \"Chords\",\n      values = { \"Walk\", \"Any named\", \"Doo-wop\", \"Singer-songwriter\", \"Puff\", \"Pachelbel\", \"Lament\",\n                 \"Circle\", \"Double plagal\", \"Galant\", \"Blues\", \"Do-Re-Mi\", \"Romanesca\", \"Fonte\", \"Monte\",\n                 \"Aprile\", \"Pastorella\", \"Ponte\" },\n      -- (1.13: not shown; every idea walks or plays a named progression that\n      -- suits its key, half and half. 0025.)\n      any = true, default = \"Any\", anyValues = { \"Walk\", \"Any named\" }, anyWeights = { 1, 1 },\n      name = labelled({ [\"Any named\"] = \"Any Named\", [\"Singer-songwriter\"] = \"Singer-Songwriter\",\n                        [\"Double plagal\"] = \"Double Plagal\" }),\n      hidden = true, when = hasChords,\n      hints = {\n        Walk = \"Each chord drawn from the one before, by how strongly it leads there (tonic, subdominant, dominant) \u00e2\u0080\u0094 the way Good Idea has always worked. A named progression fills the chords in order, going round, and a passage that closes still ends on its cadence, and a repeated passage carries the progression on. It is heard best in a Loop, which plays nothing else.\",\n        [\"Any named\"] = \"One of the named progressions that suits the key, chosen by the idea number.\",\n        [\"Doo-wop\"] = \"I vi IV V \u00e2\u0080\u0094 the \u00e2\u0080\u009950s doo-wop progression (Open Music Theory). Major keys.\",\n        [\"Singer-songwriter\"] = \"vi IV I V in a major key, i VI III VII in a minor one \u00e2\u0080\u0094 never quite sure which is home.\",\n        Puff = \"I iii IV I \u00e2\u0080\u0094 the \u00e2\u0080\u009cPuff\u00e2\u0080\u009d opening, the bass climbing do mi fa. Major keys.\",\n        Pachelbel = \"I V6 vi iii6 IV I6 IV V \u00e2\u0080\u0094 Pachelbel\u00e2\u0080\u0099s canon, the bass stepping down do ti la sol fa mi. Major keys.\",\n        Lament = \"i VII VI V \u00e2\u0080\u0094 the lament (the Andalusian cadence), the bass falling do te le sol. Minor keys.\",\n        Circle = \"Round the circle of fifths: I IV vii iii vi ii V I, or in minor i iv VII III VI ii V i (\u00e2\u0080\u009cI Will Survive\u00e2\u0080\u009d).\",\n        [\"Double plagal\"] = \"I bVII IV I \u00e2\u0080\u0094 two plagal steps home (the coda of \u00e2\u0080\u009cHey Jude\u00e2\u0080\u009d). Major keys.\",\n        Galant = \"The galant schemata: a Meyer (I V4/3 V6/5 I, the bass do re ti do, the tune do ti fa mi) then a Prinner (IV I6 vii6 I, the bass fa mi re do, the tune la sol fa mi) \u00e2\u0080\u0094 Gjerdingen\u00e2\u0080\u0099s stock phrases. In minor, i V4/3 V6/5 i, iv i6 vii\u00c2\u00b06 i.\",\n        Blues = \"The 12-bar blues \u00e2\u0080\u0094 I I I I IV IV I I V IV I I \u00e2\u0080\u0094 and its 8- and 16-bar cousins, a chord a bar. Measures only.\",\n        [\"Do-Re-Mi\"] = \"I V6/5 I \u00e2\u0080\u0094 the bass do ti do under a tune rising do re mi: the galant Do-Re-Mi.\",\n        Romanesca = \"I V6 vi I6 \u00e2\u0080\u0094 the bass do ti la mi: the galant Romanesca. In minor, i v6 VI i6, the bass do te le me.\",\n        Fonte = \"V7/ii ii V7 I \u00e2\u0080\u0094 a pair stepped down: the galant Fonte (\u00e2\u0080\u009cfountain\u00e2\u0080\u009d). In minor, V7/iv iv V7/III III: the minor key\u00e2\u0080\u0099s ii cannot be a key, so it falls from iv to III.\",\n        Monte = \"V7/IV IV V7/V V \u00e2\u0080\u0094 a pair stepped up: the galant Monte (\u00e2\u0080\u009cmountain\u00e2\u0080\u009d). In minor, V7/iv iv V7/V V.\",\n        Aprile = \"I V4/3 V6/5 I under a tune do ti re do: the galant Aprile.\",\n        Pastorella = \"I V7 I under a tune mi re fa mi, the V7 holding two notes of it: the galant Pastorella.\",\n        Ponte = \"The tonic, then V held (V7 with Sevenths or Mixed) \u00e2\u0080\u0094 standing on the dominant: the galant Ponte (\u00e2\u0080\u009cbridge\u00e2\u0080\u009d).\",\n      } },\n\n    -- Added in 1.10, last for the same reason. Off draws nothing, and the\n    -- tension notes have dice of their own.\n    { id = \"tension\", label = \"Tension\", step = \"Melody\", values = { \"Off\", \"Rare\", \"Common\" },\n      default = \"Rare\", when = hasMelody,\n      hints = {\n        Off = \"Every note on the beat is a note of the chord, as Good Idea\u00e2\u0080\u0099s tunes were before 1.10.\",\n        Rare = \"Now and then the tune leans on the beat and falls a step to the chord: a suspension (the note before held over the chord change, then falling), an appoggiatura (leapt up to, a step above the chord\u00e2\u0080\u0099s note), or, at a close, the last note arriving an eighth early (an anticipation).\",\n        Common = \"The same, on more of the beats where one can go.\",\n      } },\n    { id = \"secondVoice\", label = \"Second voice\", step = \"Melody\", values = { \"Off\", \"Thirds\", \"Sixths\" },\n      default = \"Off\", when = hasMelody,\n      hints = {\n        Off = \"The tune alone.\",\n        Thirds = \"A second part a third under the tune, moving with it \u00e2\u0080\u0094 a fourth or a sixth under where a third would not be a note of the chord on the beat. Its own channel (or track).\",\n        Sixths = \"A second part a sixth under the tune, moving with it \u00e2\u0080\u0094 a third or a fourth under where a sixth would not be a note of the chord on the beat. Its own channel (or track).\",\n      } },\n\n    -- Added in 1.12, last for the same reason. None draws nothing.\n    { id = \"keyChange\", label = \"Key change\", step = \"Arrangement\",\n      values = { \"None\", \"Step up\", \"Half step up\", \"Truck driver\" }, default = \"None\",\n      name = labelled({ [\"Step up\"] = \"Step Up\", [\"Half step up\"] = \"Half Step Up\", [\"Truck driver\"] = \"Truck Driver\" }),\n      when = function(st) return st.kind == \"Measure\" end,\n      hints = {\n        None = \"One key all the way.\",\n        [\"Step up\"] = \"The last section a whole tone higher \u00e2\u0080\u0094 the pop key change for a last chorus. Tune, chords and bass all go up.\",\n        [\"Half step up\"] = \"The last section a semitone higher.\",\n        [\"Truck driver\"] = \"A whole tone up, with the new key\u00e2\u0080\u0099s V7 squeezed in before it (C ... A7 | D) \u00e2\u0080\u0094 the \u00e2\u0080\u009ctruck-driver\u00e2\u0080\u009d gear change \u00e2\u0080\u0094 into the new key\u00e2\u0080\u0099s tonic: the last section that starts on it, or one made to start on it. In scales other than the seven-note ones, a plain step up.\",\n      } },\n\n    -- Added in 1.14, last for the same reason. Off draws nothing; the\n    -- ghost notes have dice of their own.\n    { id = \"ghosts\", label = \"Ghost notes\", step = \"Drums\", values = { \"Off\", \"Rare\", \"Common\" },\n      default = \"Rare\", when = function(st) return st.kind == \"Drums\" end,\n      hints = {\n        Off = \"Only the groove\u00e2\u0080\u0099s own snare.\",\n        Rare = \"Now and then a ghost note: the snare tapped very quietly on a sixteenth, mostly just before or after the backbeat \u00e2\u0080\u0094 the funk and R&B drummer\u00e2\u0080\u0099s in-between notes. The same in every bar, quiet at any Velocity.\",\n        Common = \"The same ghost notes, and more of them.\",\n      } },\n    -- (1.14: not shown - the engine decides, half and half, whether the\n    -- bass lies back with pulled chords or holds the beat with the tune.)\n    { id = \"bassPull\", label = \"Bass pull\", step = \"Arrangement\", values = { \"On the beat\", \"With the chords\" },\n      name = labelled({ [\"On the beat\"] = \"On the Beat\", [\"With the chords\"] = \"With the Chords\" }),\n      any = true, default = \"Any\", hidden = true,\n      when = function(st) return st.kind == \"Measure\" end,\n      hints = {\n        [\"On the beat\"] = \"Where the chords are pulled, the bass stays on the beat with the tune.\",\n        [\"With the chords\"] = \"Where the chords are pulled, the bass lies back with them: the new note an eighth late, the one before held to meet it.\",\n      } },\n  }\n  M.BY_ID = {}\n  for _, s in ipairs(M.SETTINGS) do M.BY_ID[s.id] = s end\nend\n\nfunction M.valueName(s, v)\n  if v == \"Any\" then return \"Any\" end\n  return s.name and s.name(v) or tostring(v)\nend\n\n-- (A `hidden` setting, 1.13, is never shown but still rolled: the engine\n-- decides it.)\nfunction M.shows(s, st) return not s.hidden and (not s.when or s.when(st)) end\n\n------------------------------------------------------------------------------\n-- State\n------------------------------------------------------------------------------\n\nfunction M.newState()\n  local st = {}\n  for _, s in ipairs(M.SETTINGS) do st[s.id] = s.default end\n  st.seed = 1\n  st.autoplay = 0\n  st.swing = 0\n  st.follow = 1            -- 1.17: play along when REAPER plays\n  st.exportTo = \"Project\"  -- 1.17: where Export writes (gi_place's exportDir)\n  return st\nend\n\n-- Puts every field back inside what exists. Saved settings come from\n-- anywhere, so nothing in them is trusted.\nfunction M.clampState(st)\n  for _, s in ipairs(M.SETTINGS) do\n    local v = st[s.id]\n    local good = (v == \"Any\" and s.any) or false\n    for _, x in ipairs(s.values) do if x == v then good = true end end\n    if not good then st[s.id] = s.default end\n  end\n  local seed = tonumber(st.seed)\n  if seed and seed >= 1 and seed <= M.MAX_SEED then st.seed = math.floor(seed) else st.seed = 1 end\n  st.autoplay = (tonumber(st.autoplay) == 1) and 1 or 0\n  local swing = tonumber(st.swing)\n  st.swing = (swing and swing >= 0 and swing <= 100) and math.floor(swing) or 0\n  st.follow = (tonumber(st.follow) == 0) and 0 or 1\n  if st.exportTo ~= \"REAPER\" and st.exportTo ~= \"Folder\" then st.exportTo = \"Project\" end\n  return st\nend\n\n------------------------------------------------------------------------------\n-- 1. Resolve\n------------------------------------------------------------------------------\n\n-- Every setting takes one draw from the \"pick\" stream whether it is on Any\n-- or not, so fixing one setting never changes what another rolls. That is\n-- what makes \"Keep\" (turning every Any into what this idea rolled) give\n-- exactly the same idea back.\nfunction M.resolve(st, seed)\n  local rnd = M.stream(seed, \"pick\")\n  local r = { rolled = {} }\n  for _, s in ipairs(M.SETTINGS) do\n    local x = rnd()\n    local v = st[s.id]\n    if v == \"Any\" and s.any then\n      v = pickAt(x, s.anyValues or s.values, s.anyWeights or (not s.anyValues and s.weights) or nil)\n      r.rolled[s.id] = true\n    end\n    r[s.id] = v\n  end\n  if r.kind == \"Motif\" then r.bars = r.motifBars\n  elseif r.kind == \"Phrase\" then r.bars = r.phraseBars\n  elseif r.kind == \"Drums\" then r.bars = r.drumBars\n  else r.bars = r.measureBars end\n  if r.kind == \"Motif\" then r.content = \"Melody\"\n  elseif r.kind == \"Measure\" then r.content = \"All\"\n  elseif r.kind == \"Drums\" then r.content = \"Melody\"; r.drumsOnly = true end\n  r.melody = r.content ~= \"Chords\" and not r.drumsOnly\n  r.chords = r.content ~= \"Melody\"\n  return r\nend\n\n-- The bars setting the kind uses.\nfunction M.barsSetting(kind)\n  return (kind == \"Motif\" and \"motifBars\") or (kind == \"Phrase\" and \"phraseBars\")\n      or (kind == \"Drums\" and \"drumBars\") or \"measureBars\"\nend\n\n------------------------------------------------------------------------------\n-- 2. The plan\n--\n-- A unit is written letter:bars[:cadence]. A letter's first appearance is new\n-- material; `a` again repeats it, `a'` answers it (the same start, a new\n-- ending), `a~` sequences it (the whole unit moved up or down, chords and\n-- all). `f` fragments the basic idea - its first half, falling - and `c` is a\n-- new cadential unit. The cadence `X` is the idea's ending, drawn for the\n-- kind. These are the shapes Open Music Theory gives for the sentence and the\n-- period, and the A A B A of a song, at the size of the idea.\n------------------------------------------------------------------------------\n\nM.PLANS = {\n  Motif = {\n    [1] = { \"a:0.5 a~:0.5:X\", \"a:0.5:open a':0.5:X\", \"a:1:X\" },\n    [2] = { \"a:1:open a':1:X\", \"a:1 a~:1:X\", \"a:1:open b:1:X\" },\n    [3] = { \"a:1 a~:1 c:1:X\", \"a:1:open b:1 a':1:X\" },\n    [4] = { \"a:1 a~:1 f:1 c:1:X\", \"a:2:open a':2:X\", \"a:1:open b:1 a:1:open b':1:X\" },\n  },\n  Phrase = {\n    [1] = { \"a:1:X\" },\n    [2] = { \"a:2:X\", \"a:1:HC a':1:X\" },\n    [3] = { \"a:2 c:1:X\", \"a:1 a~:1 c:1:X\" },\n    [4] = { \"a:4:X\", \"a:2:HC a':2:X\", \"a:1 a~:1 f:1 c:1:X\" },\n  },\n}\n\nM.FORMS = {\n  Period   = { [8] = \"a:4:HC a':4:PAC\",\n               [12] = \"a:4:HC a':4:IAC b:4:PAC\",\n               [16] = \"a:4:IAC b:4:HC a:4:IAC c:4:PAC\" },\n  Sentence = { [8] = \"a:2 a~:2 f:2 c:2:PAC\",\n               [12] = \"a:2 a~:2 f:4 c:4:PAC\",\n               [16] = \"a:4 a~:4 f:4 c:4:PAC\" },\n  Song     = { [8] = \"a:2:IAC a:2:PAC b:2:HC a:2:PAC\",\n               [12] = \"a:4:IAC a:4:PAC b:4:PAC\",\n               [16] = \"a:4:IAC a:4:PAC b:4:HC a:4:PAC\" },\n  Loop     = { [8] = \"a:4:open a':4:open\",\n               [12] = \"a:4:open a':4:open a:4:open\",\n               [16] = \"a:4:open a':4:open a:4:open a'':4:open\" },\n  -- Added in 1.8 (Caplin's hybrid themes and small ternary, and a sentence\n  -- stretched by a deceptive cadence; Open Music Theory, \"Hybrid themes\",\n  -- \"The Small Ternary\", \"Internal Expansions\").\n  [\"Hybrid 1\"] = { [8] = \"a:2 b:2:HC f:1 f:1 c:2:PAC\",\n                   [12] = \"a:3 b:3:HC f:2 f:1 c:3:PAC\",\n                   [16] = \"a:4 b:4:HC f:4 c:4:PAC\" },\n  [\"Hybrid 2\"] = { [8] = \"a:2 b:2:HC c:4:PAC\",\n                   [12] = \"a:3 b:3:HC c:6:PAC\",\n                   [16] = \"a:4 b:4:HC c:8:PAC\" },\n  [\"Hybrid 3\"] = { [8] = \"a:2 b:2 f:1 f:1 c:2:PAC\",\n                   [12] = \"a:3 b:3 f:2 f:1 c:3:PAC\",\n                   [16] = \"a:4 b:4 f:4 c:4:PAC\" },\n  [\"Hybrid 4\"] = { [8] = \"a:2 b:2 a:2 b':2:PAC\",\n                   [12] = \"a:3 b:3 a:3 b':3:PAC\",\n                   [16] = \"a:4 b:4 a:4 b':4:PAC\" },\n  Ternary  = { [8] = \"a:2:HC a':2:PAC b:2:HC a':2:PAC\",\n               [12] = \"a:4:PAC b:4:HC a:4:PAC\",\n               [16] = \"a:4:HC a':4:PAC b:4:HC a':4:PAC\" },\n  Extended = { [8] = \"a:2 a~:2 c:2:DC c:2:PAC\",\n               [12] = \"a:2 a~:2 f:2 c:2:DC f:2 c:2:PAC\",\n               [16] = \"a:4 a~:4 f:2 c:2:DC f:2 c:2:PAC\" },\n}\n\n-- How an idea that is not a Measure ends. A motif is a hook, so mostly it\n-- leaves the door open and loops; a phrase mostly closes.\nlocal ENDINGS = {\n  Motif  = { { \"open\", \"PAC\", \"IAC\" }, { 3, 2, 1 } },\n  Phrase = { { \"PAC\", \"HC\", \"IAC\", \"open\" }, { 3, 1.5, 1, 1.5 } },\n}\n\nfunction M.parsePlan(text, meter, finalCad)\n  local units, firstOf = {}, {}\n  local cum = 0\n  for tok in text:gmatch(\"%S+\") do\n    local name, bars, cad = tok:match(\"^([^:]+):([%d%.]+):?(%a*)$\")\n    local letter, mark = name:match(\"^(%a)(.*)$\")\n    bars = tonumber(bars)\n    local start = snap(meter, cum * meter.bar)\n    cum = cum + bars\n    local stop = snap(meter, cum * meter.bar)\n    local u = { letter = letter, mark = mark, bars = bars, start = start, len = stop - start,\n                cad = (cad == \"\" and \"none\") or (cad == \"X\" and finalCad) or cad }\n    if letter == \"f\" then u.kind, u.of = \"frag\", 1\n    elseif letter == \"c\" then u.kind = \"cad\"\n    elseif not firstOf[letter] then u.kind = \"new\"; firstOf[letter] = #units + 1\n    elseif mark == \"~\" then u.kind, u.of = \"seq\", firstOf[letter]\n    elseif mark:find(\"'\") then u.kind, u.of = \"answer\", firstOf[letter]\n    else u.kind, u.of = \"repeat\", firstOf[letter] end\n    -- A repeat that ends differently from its source is an answer.\n    if u.kind == \"repeat\" and units[u.of].cad ~= u.cad then u.kind = \"answer\" end\n    if u.len > 0 then units[#units + 1] = u end\n  end\n  return units, snap(meter, cum * meter.bar)\nend\n\nfunction M.plan(r, meter, rnd)\n  local text, finalCad\n  if r.kind == \"Measure\" then\n    text = M.FORMS[r.form][r.bars]\n    finalCad = \"PAC\"\n  else\n    local e = ENDINGS[r.kind]\n    finalCad = weighted(rnd, e[1], e[2])\n    text = pickOne(rnd, M.PLANS[r.kind][r.bars])\n  end\n  local units, total = M.parsePlan(text, meter, finalCad)\n  -- (1.13) Extended's stretch is a deceptive close or, half the time, an\n  -- evaded one (EC): the full close never comes, and the passage goes round\n  -- \"one more time\".\n  if r.kind == \"Measure\" and r.form == \"Extended\" and rnd() < 0.5 then\n    for _, u in ipairs(units) do if u.cad == \"DC\" then u.cad = \"EC\" end end\n  end\n  -- A sequence moves by a step up, a step down, or to the dominant (up a\n  -- fifth) - the second statement of a sentence's basic idea.\n  for _, u in ipairs(units) do\n    if u.kind == \"seq\" then u.shift = weighted(rnd, { 1, -1, 4 }, { 2, 1.5, 2 }) end\n  end\n  local shape = {}\n  for _, u in ipairs(units) do shape[#shape + 1] = u.letter .. u.mark end\n  return { units = units, total = total, text = text, ending = units[#units].cad,\n           shape = table.concat(shape, \" \") }\nend\n\n------------------------------------------------------------------------------\n-- 3. Harmony\n------------------------------------------------------------------------------\n\nlocal RATE = { Slow = 0.5, [\"One a bar\"] = 1, [\"1.5 a bar\"] = 1.5, [\"Two a bar\"] = 2, [\"4 a bar\"] = 4 }\n\n-- Where an answer stops copying its source: half way, on a beat, and\n-- always before the end (a unit one beat long copies nothing).\nfunction M.cutFor(meter, src, u)\n  local half = math.min(src.len, u.len) / 2\n  local cut = math.floor(half / meter.beat + 0.5) * meter.beat\n  return math.max(0, math.min(cut, u.len - meter.beat))\nend\n\n-- How many chords a stretch of `len` steps gets.\nlocal function countFor(meter, len, r, kind, cad, first)\n  local bars = len / meter.bar\n  local rate = RATE[r.chordPace] or 1\n  -- A continuation speeds the harmony up (Open Music Theory, the sentence).\n  -- (Never slower than the pace chosen: at four a bar it is already quick.)\n  if kind == \"frag\" then rate = math.max(rate, math.min(2, rate * 2)) end\n  local n = math.max(1, round(bars * rate))\n  local beats = len // meter.beat\n  -- An ending needs two chords: one to lead to it, and the one it lands on.\n  -- A half close is one chord, the dominant.\n  local need = (cad == \"HC\" and 1) or ((cad ~= \"none\" or kind == \"cad\") and 2) or 1\n  if beats >= 2 then n = math.max(n, need) end\n  -- The opening unit starts on the tonic, so it needs a chord before its\n  -- ending too - as long as the chords still fall evenly on the beats, line\n  -- up with the bars, and come no faster than two a bar.\n  if first and cad ~= \"none\" then\n    local tail = (cad == \"PAC\" or cad == \"IAC\" or cad == \"DC\" or cad == \"EC\") and 2 or 1\n    if n <= tail then\n      for m = tail + 1, math.max(tail + 1, round(2 * bars)) do\n        local per = beats // m\n        if beats % m == 0 and (per % meter.beats == 0 or meter.beats % per == 0) then n = m; break end\n      end\n    end\n  end\n  return math.max(1, math.min(n, beats))\nend\n\n------------------------------------------------------------------------------\n-- Named progressions (1.9; docs/decisions/0021-named-progressions.md)\n--\n-- The stock progressions of Open Music Theory's pop/rock pages, and two of\n-- Gjerdingen's galant schemata. Each chord is a degree of the key, with the\n-- scale it comes from when not the key's own (`from`, an index of\n-- T.SCALES on the same key note) and the scale degree in its bass when it\n-- is inverted (`bass`). They fill the chords a unit walks to, in order and\n-- going round; a unit that closes still ends on its cadence.\n------------------------------------------------------------------------------\n\nM.PROGRESSIONS = {\n  [\"Doo-wop\"] = { major = { { 0 }, { 5 }, { 3 }, { 4 } } },\n  [\"Singer-songwriter\"] = { major = { { 5 }, { 3 }, { 0 }, { 4 } },\n                            minor = { { 0 }, { 5, from = 2 }, { 2, from = 2 }, { 6, from = 2 } } },\n  Puff = { major = { { 0 }, { 2 }, { 3 }, { 0 } } },\n  Pachelbel = { major = { { 0 }, { 4, bass = 6 }, { 5 }, { 2, bass = 4 }, { 3 }, { 0, bass = 2 }, { 3 }, { 4 } } },\n  Lament = { minor = { { 0 }, { 6, from = 2 }, { 5, from = 2 }, { 4, from = 3 } } },\n  Circle = { major = { { 0 }, { 3 }, { 6 }, { 2 }, { 5 }, { 1 }, { 4 }, { 0 } },\n             minor = { { 0 }, { 3 }, { 6, from = 2 }, { 2, from = 2 }, { 5, from = 2 }, { 1 }, { 4, from = 3 }, { 0 } } },\n  [\"Double plagal\"] = { major = { { 0 }, { 6, from = 8 }, { 3 }, { 0 } } },\n  -- (1.16) `sing`: the scale degree the schema's tune has on that stage\n  -- (Open Music Theory, \"Galant schemata - summary\"): the Meyer do ti fa mi,\n  -- the Prinner la sol fa mi. A list, for a chord that holds two stages.\n  Galant = { major = { { 0, sing = 0 }, { 4, bass = 1, sing = 6 }, { 4, bass = 6, sing = 3 }, { 0, sing = 2 },\n                       { 3, sing = 5 }, { 0, bass = 2, sing = 4 }, { 6, bass = 1, sing = 3 }, { 0, sing = 2 } },\n             -- (1.14) In minor, \"converted directly\" (Open Music Theory):\n             -- the V and the vii\u00c2\u00b06 from the harmonic minor, the iv from the\n             -- natural.\n             minor = { { 0, sing = 0 }, { 4, from = 3, bass = 1, sing = 6 }, { 4, from = 3, bass = 6, sing = 3 },\n                       { 0, sing = 2 }, { 3, from = 2, sing = 5 }, { 0, bass = 2, sing = 4 },\n                       { 6, from = 3, bass = 1, sing = 3 }, { 0, sing = 2 } } },\n  -- (1.13) More galant schemata (Open Music Theory, \"Galant schemata\"): the\n  -- Do-Re-Mi (I V6/5 I, the bass do ti do), the Romanesca (I V6 vi I6, the\n  -- bass do ti la mi), the Fonte (V7/ii ii V7 I, a step down) and the Monte\n  -- (V7/IV IV V7/V V, a step up). `appliedTo`: the chord is that degree's own\n  -- dominant, from the home scale bent (I.appliedKey).\n  [\"Do-Re-Mi\"] = { major = { { 0, sing = 0 }, { 4, bass = 6, sing = 1 }, { 0, sing = 2 } },\n                   minor = { { 0, sing = 0 }, { 4, from = 3, bass = 6, sing = 1 }, { 0, sing = 2 } } },\n  -- (1.14) And in minor. The Romanesca's bass falls do te le me - the\n  -- natural minor's v6, as a falling line in minor takes it (the raised ti\n  -- falling to le would be an augmented second). The Monte: V7/iv iv V7/V V.\n  -- The Fonte cannot go from ii to i - the minor key's ii is diminished, and\n  -- cannot be made a key of its own - so it tonicises iv, then III a step\n  -- below (Fm, then Eb, in C minor): minor, then major, a step down, as the\n  -- major key's ii to I.\n  Romanesca = { major = { { 0 }, { 4, bass = 6 }, { 5 }, { 0, bass = 2 } },\n                minor = { { 0 }, { 4, from = 2, bass = 6 }, { 5, from = 2 }, { 0, bass = 2 } } },\n  Fonte = { major = { { 5, appliedTo = 1 }, { 1 }, { 4 }, { 0 } },\n            minor = { { 0, appliedTo = 3 }, { 3, from = 2 }, { 6, from = 2, appliedTo = 2 }, { 2, from = 2 } } },\n  Monte = { major = { { 0, appliedTo = 3 }, { 3 }, { 1, appliedTo = 4 }, { 4 } },\n            minor = { { 0, appliedTo = 3 }, { 3, from = 2 }, { 1, appliedTo = 4 }, { 4, from = 3 } } },\n  -- (1.16) The last three of Open Music Theory's schemata. The Aprile has\n  -- the Meyer's chords and bass (do re ti do) under the tune do ti re do;\n  -- the Pastorella I V7 V7 I (the bass do sol sol do) under mi re fa mi -\n  -- one V7 holding two stages; the Ponte \"holds onto\" the dominant and \"adds\n  -- a seventh\" (\"Galant Schemata - continuation patterns\"): V held, entered\n  -- from the tonic so an idea on it opens at home. (The seventh is the\n  -- Colour's: V7 with Sevenths or Mixed, V with Triads.)\n  Aprile = { major = { { 0, sing = 0 }, { 4, bass = 1, sing = 6 }, { 4, bass = 6, sing = 1 }, { 0, sing = 0 } },\n             minor = { { 0, sing = 0 }, { 4, from = 3, bass = 1, sing = 6 }, { 4, from = 3, bass = 6, sing = 1 },\n                       { 0, sing = 0 } } },\n  Pastorella = { major = { { 0, sing = 2 }, { 4, sing = { 1, 3 } }, { 0, sing = 2 } },\n                 minor = { { 0, sing = 2 }, { 4, from = 3, sing = { 1, 3 } }, { 0, sing = 2 } } },\n  Ponte = { major = { { 0 }, { 4 }, { 4 }, { 4 } },\n            minor = { { 0 }, { 4, from = 3 }, { 4, from = 3 }, { 4, from = 3 } } },\n  -- (A chord a bar, by the bar: not filled in order like the rest.)\n  Blues = { blues = { [8] = { 0, 4, 3, 3, 0, 4, 0, 0 },\n                      [12] = { 0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 0 },\n                      [16] = { 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 0 } } },\n}\nM.PROGRESSION_ORDER = { \"Doo-wop\", \"Singer-songwriter\", \"Puff\", \"Pachelbel\", \"Lament\", \"Circle\",\n                        \"Double plagal\", \"Galant\", \"Blues\", \"Do-Re-Mi\", \"Romanesca\", \"Fonte\", \"Monte\",\n                        \"Aprile\", \"Pastorella\", \"Ponte\" }\n\n-- The progression an idea plays - its chords for this key's mode - or nil\n-- (Walk, or one that does not suit the key, the kind or the length; `why`\n-- says which).\nfunction M.schemaFor(r, key, rnd)\n  local name = r.progression\n  if not name or name == \"Walk\" then return nil end\n  local seven = T.scaleLen(key) == 7\n  local q = T.degreeQuality(key, 0)\n  local mode = (q == \"major\" and \"major\") or (q == \"minor\" and \"minor\") or nil\n  local function fits(n)\n    local p = M.PROGRESSIONS[n]\n    if not seven then return false end\n    if p.blues then\n      -- (Only where I, IV and V are major or minor chords: not Lydian's\n      -- diminished IV, nor Locrian's I.)\n      for _, d in ipairs({ 0, 3, 4 }) do\n        local q = T.degreeQuality(key, d)\n        if q ~= \"major\" and q ~= \"minor\" then return false end\n      end\n      return r.kind == \"Measure\" and p.blues[r.bars] ~= nil\n    end\n    return mode ~= nil and p[mode] ~= nil\n  end\n  if name == \"Any named\" then\n    local ok = {}\n    for _, n in ipairs(M.PROGRESSION_ORDER) do if fits(n) then ok[#ok + 1] = n end end\n    local x = rnd()\n    if #ok == 0 then return nil, \"no named progression suits this key\" end\n    name = ok[math.floor(x * #ok) + 1]\n  elseif not fits(name) then\n    local p = M.PROGRESSIONS[name]\n    if not seven then return nil, name .. \" needs a seven-note scale\" end\n    if p.blues then return nil, \"the blues needs a Measure\" end\n    return nil, name .. \" needs a \" .. (p.major and \"major\" or \"minor\") .. \" key\"\n  end\n  local p = M.PROGRESSIONS[name]\n  return { name = name, chords = p[mode], blues = p.blues and p.blues[r.bars], at = 0 }\nend\n\n-- `n` chords from the progression, going on from where it got to, the last\n-- of them its cadence's (as `T.progression` would end).\nlocal function schemaDegrees(sch, key, n, cad, rnd)\n  local tail = {}\n  if cad ~= \"none\" and cad ~= \"open\" then\n    local need = (cad == \"HC\") and 1 or 2\n    tail = T.progression(key, math.min(need, n), { cadence = cad }, rnd)\n  end\n  local degs, specs = {}, {}\n  for i = 1, n - #tail do\n    local c = sch.chords[sch.at % #sch.chords + 1]\n    sch.at = sch.at + 1\n    degs[i], specs[i] = c[1], c\n  end\n  for _, d in ipairs(tail) do degs[#degs + 1] = d end\n  return degs, specs\nend\n\n-- `n` stretches of a span, as even as the beats allow.\nlocal function evenSlots(meter, from, len, n)\n  local out = {}\n  for i = 1, n do\n    local s = from + snap(meter, len * (i - 1) / n)\n    local e = (i == n) and (from + len) or (from + snap(meter, len * i / n))\n    if e > s then out[#out + 1] = { s = s, e = e } end\n  end\n  return out\nend\n\nlocal function withDegrees(slots, degrees, specs)\n  for i, sl in ipairs(slots) do\n    sl.degree = degrees[i] or degrees[#degrees]\n    sl.spec = specs and specs[i] or nil\n  end\n  return slots\nend\n\n-- A unit's chords, as { s, e, degree } from the unit's start.\n--\n--   - a repeat, or an answer or sequence to the same ending, plays its\n--     source's chords (a sequence moved by its step);\n--   - an answer (or a repeat or sequence to a different ending) plays its\n--     source's chords for the first half, by time, then walks to its own\n--     ending - so the tune's first half fits it exactly as before;\n--   - anything new walks from the chord after the last one.\nlocal function unitChords(u, units, key, r, meter, rnd, prevLast, sch)\n  -- The blues: a chord a bar, by where the bar is in the idea.\n  if sch and sch.blues then\n    local out = {}\n    local bars = math.max(1, u.len // meter.bar)\n    for i, sl in ipairs(evenSlots(meter, 0, u.len, bars)) do\n      local bar = (u.start + sl.s) // meter.bar\n      sl.degree = sch.blues[bar % #sch.blues + 1]\n      sl.spec = { sl.degree, blues = true }\n      out[i] = sl\n    end\n    return out\n  end\n  local src = (u.kind == \"repeat\" or u.kind == \"answer\" or u.kind == \"seq\") and units[u.of] or nil\n  local shift = (u.kind == \"seq\") and u.shift or 0\n  -- (A copied chord remembers the one it was copied from, `orig`, so a\n  -- flavour or an inversion comes round with it.)\n  local function moved(sl, e)\n    return { s = sl.s, e = math.min(e or sl.e, sl.e), degree = T.normDegree(key, sl.degree + shift),\n             orig = sl.orig or sl, spec = (shift == 0) and sl.spec or nil }\n  end\n  -- A named progression goes on under a repeat (the tune copied, fitted to\n  -- the chords now under it) until it has come round to where the repeat's\n  -- source began - then the repeat copies it: Pachelbel's eight chords over\n  -- two four-bar statements of a Loop, then round again.\n  if sch and not sch.blues and src and shift == 0 and src.schemaAt\n     and sch.at % #sch.chords ~= src.schemaAt % #sch.chords then\n    -- (1.14: and where an earlier passage of the same length and close\n    -- began at this point of the progression, it plays that one's chords -\n    -- the second time round a Loop is the first time again, flavours and\n    -- all.)\n    local twin\n    for _, w in ipairs(units) do\n      if w == u then break end\n      if w.rel and w.schemaAt and w.schemaAt % #sch.chords == sch.at % #sch.chords\n         and w.len == u.len and w.cad == u.cad then twin = w end\n    end\n    src = twin\n  end\n  if src and src.len == u.len and src.cad == u.cad and (u.kind ~= \"seq\" or u.cad == \"none\") then\n    local out = {}\n    for _, sl in ipairs(src.rel) do out[#out + 1] = moved(sl) end\n    if sch and src.schemaAt and shift == 0 then\n      u.schemaAt, u.schemaUsed = sch.at, src.schemaUsed\n      sch.at = sch.at + src.schemaUsed\n    end\n    return out\n  end\n  local need = (u.cad == \"PAC\" or u.cad == \"IAC\" or u.cad == \"DC\" or u.cad == \"EC\") and 2 or ((u.cad ~= \"none\") and 1 or 0)\n  local cut = src and M.cutFor(meter, src, u)\n  -- (When the second half is too short for the ending's chords - half a bar\n  -- of 4/4 has two beats, a full close needs a chord on each, and so on -\n  -- the answer's chords are all new, and its tune is fitted to them.)\n  if src and cut > 0 and (u.len - cut) // meter.beat >= need then\n    local out = {}\n    for _, sl in ipairs(src.rel) do\n      if sl.s < cut then out[#out + 1] = moved(sl, cut) end\n    end\n    local rest = u.len - cut\n    local n = countFor(meter, rest, r, \"rest\", u.cad, false)\n    local degs, specs\n    if sch then degs, specs = schemaDegrees(sch, key, n, u.cad, rnd)\n    else\n      degs = T.progression(key, n, { start = T.nextDegree(key, out[#out].degree, rnd),\n                                     cadence = u.cad, loopTo = 0 }, rnd)\n    end\n    for _, sl in ipairs(withDegrees(evenSlots(meter, cut, rest, n), degs, specs)) do out[#out + 1] = sl end\n    return out\n  end\n  local n = countFor(meter, u.len, r, u.kind, u.cad, u == units[1])\n  if sch then\n    u.schemaAt = sch.at\n    local degs, specs = schemaDegrees(sch, key, n, u.cad, rnd)\n    u.schemaUsed = sch.at - u.schemaAt\n    return withDegrees(evenSlots(meter, 0, u.len, n), degs, specs)\n  end\n  local start = prevLast and T.nextDegree(key, prevLast, rnd) or 0\n  local degs = T.progression(key, n, { start = start, cadence = u.cad, loopTo = 0 }, rnd)\n  return withDegrees(evenSlots(meter, 0, u.len, n), degs)\nend\n\n-- Each unit's chords, and one timeline of { s, e, degree, chord } for the\n-- whole idea, in steps. The same chord twice running (where one unit ends on\n-- the chord the next begins with) is one chord, held.\nfunction M.harmony(plan, key, r, meter, rnd, colour, sch, breakAt, tonicAt)\n  local timeline = {}\n  local prevLast\n  for _, u in ipairs(plan.units) do\n    u.rel = unitChords(u, plan.units, key, r, meter, rnd, prevLast, sch)\n    -- (1.14) A section the truck driver needs on the tonic starts on it -\n    -- its first chord a new one, not a copy.\n    if tonicAt and u.start == tonicAt and u.rel[1] and u.rel[1].degree ~= 0 then\n      local f = u.rel[1]\n      u.rel[1] = { s = f.s, e = f.e, degree = 0 }\n    end\n    u.degrees, u.slots = {}, {}\n    for _, rs in ipairs(u.rel) do\n      u.degrees[#u.degrees + 1] = rs.degree\n      local last = timeline[#timeline]\n      local sl\n      local spec = rs.spec\n      local k = (spec and spec.from) and T.key(key.root, spec.from) or key\n      -- (A named applied chord: the home scale bent to make it, a V7 but\n      -- with Triads.)\n      local applied = spec and spec.appliedTo and M.appliedKey(key, spec.appliedTo, \"V\")\n      if applied then k = applied end\n      -- (Not where a named progression moves the bass under the same chord:\n      -- the Meyer's V4/3 to V6/5.)\n      if last and last.degree == rs.degree and last.e == u.start + rs.s\n         and (last.spec and last.spec.bass) == (spec and spec.bass) and u.start + rs.s ~= breakAt then\n        last.e = u.start + rs.e\n        sl = last\n      else\n        sl = { s = u.start + rs.s, e = u.start + rs.e, beat = u.start + rs.s, degree = rs.degree, key = k,\n               chord = T.chord(k, rs.degree, (applied and colour ~= \"Triads\") and \"Sevenths\" or colour),\n               origin = rs.orig or rs, spec = spec }\n        if applied then sl.applied = { kind = \"V\", named = true } end\n        -- A named progression's inverted chord: the scale degree it names\n        -- in the bass (Pachelbel's V6, the Prinner's I6).\n        if spec and spec.bass then\n          local bpc = T.pc(k, spec.bass)\n          for idx, pc in ipairs(sl.chord.pcs) do\n            if pc == bpc and idx > 1 then\n              sl.bassPc, sl.bassPos = pc, sl.chord.pos[idx]\n              sl.inversion = ({ [\"3\"] = 1, [\"5\"] = 2, [\"7\"] = 3 })[T.roleOf(sl.chord, pc)]\n            end\n          end\n        end\n        timeline[#timeline + 1] = sl\n      end\n      if u.slots[#u.slots] ~= sl then u.slots[#u.slots + 1] = sl end\n      -- (An evaded close, 1.13: its tonic is I6 - the bass does not arrive\n      -- on do either.)\n      if u.cad == \"EC\" and rs == u.rel[#u.rel] and sl.degree == 0 and not sl.bassPc then\n        local third = T.pc(sl.key or key, 2)\n        if sl.chord.has[third] and third ~= sl.chord.rootPc then\n          sl.bassPc, sl.bassPos, sl.inversion = third, 2, 1\n          sl.spec = sl.spec or { 0, bass = 2 }\n          sl.evaded = true\n        end\n      end\n    end\n    prevLast = u.degrees[#u.degrees]\n  end\n  -- (A named applied chord - the Fonte's V7/ii - must lead to its chord: a\n  -- close that cuts in leaves it the plain chord of its degree.)\n  for i, sl in ipairs(timeline) do\n    local nx = timeline[i + 1]\n    if sl.applied and sl.applied.named and not (nx and nx.degree == sl.spec.appliedTo) then\n      sl.key, sl.applied = key, nil\n      sl.chord = T.chord(key, sl.degree, colour)\n    end\n  end\n  return timeline\nend\n\nfunction M.chordAt(timeline, step)\n  for i = #timeline, 1, -1 do\n    if timeline[i].s <= step then return timeline[i] end\n  end\n  return timeline[1]\nend\n\n-- The scale sounding at a step: the key's own, or under a borrowed chord the\n-- scale it was borrowed from.\nfunction M.keyAt(ctx, step)\n  return M.chordAt(ctx.timeline, step).key or ctx.key\nend\n\n------------------------------------------------------------------------------\n-- Borrowed chords (docs/decisions/0011-borrowed-chords-rarely-and-named.md)\n--\n-- Modal mixture: a chord on the same degree, taken from another scale on\n-- the same key note - Fm (iv) or Ab (bVI) in C major, from C minor; F (IV)\n-- in C minor, from C Dorian. The degree, and so the walk, is unchanged; only\n-- the chord's notes are. Under it everything - the tune, the bass's steps -\n-- reads that scale, the way a player bends to a borrowed chord.\n--\n-- Rare by design: about one idea in four, one chord, never the first or the\n-- last two (the opening tonic and the cadence stay the key's own), never a\n-- diminished or augmented chord. Seven-note scales only, borrowing from\n-- seven-note scales, so the scale positions line up note for note.\n------------------------------------------------------------------------------\n\nM.BORROW_CHANCE = { Rare = 0.25, Common = 0.65 }\n-- With Common, a second borrowed chord in an idea of eight chords or more,\n-- this often, never next to the first.\nM.BORROW_AGAIN = 0.5\n\n-- Where to borrow from, by what the home key is: the parallel minor or major\n-- most of all (the commonest mixture), the modes a step from it next.\nlocal BORROW_FROM = {\n  major = { { 2, 3 }, { 8, 1.5 }, { 5, 1 }, { 3, 0.7 }, { 6, 0.4 }, { 7, 0.4 } },\n  minor = { { 1, 3 }, { 5, 2 }, { 3, 1.5 }, { 6, 0.8 }, { 8, 0.6 }, { 7, 0.3 } },\n}\n\nlocal function sameNotes(a, b)\n  if #a.pcs ~= #b.pcs then return false end\n  for _, pc in ipairs(a.pcs) do if not b.has[pc] then return false end end\n  return true\nend\n\nfunction M.borrow(timeline, key, r, rnd, colour)\n  local chance = M.BORROW_CHANCE[r.borrowed]\n  if not chance or T.scaleLen(key) ~= 7 or #timeline < 4 then return {} end\n  if rnd() >= chance then return {} end\n  local tonic = T.degreeQuality(key, 0)\n  local from = BORROW_FROM[(tonic == \"major\") and \"major\" or \"minor\"]\n  local inKey = {}\n  for d = 0, 6 do inKey[T.pc(key, d)] = true end\n  local cands, weights = {}, {}\n  for i = 2, #timeline - 2 do\n    local sl = timeline[i]\n    -- (A named progression's chords are its own; a chord after a key\n    -- change, 1.12, is in another key.)\n    for _, f in ipairs((sl.spec or sl.moved or sl.raised) and {} or from) do\n      if T.SCALES[f[1]].iv ~= T.SCALES[key.scale].iv then\n        local other = T.key(key.root, f[1])\n        local ch = T.chord(other, sl.degree, colour)\n        local q = ch.quality\n        local outside = false\n        for _, pc in ipairs(ch.pcs) do if not inKey[pc] then outside = true end end\n        if (q == \"major\" or q == \"minor\") and outside and not sameNotes(ch, sl.chord) then\n          cands[#cands + 1] = { slot = sl, key = other, chord = ch }\n          weights[#weights + 1] = f[2]\n        end\n      end\n    end\n  end\n  if #cands == 0 then return {} end\n  local function take(c)\n    c.slot.chord, c.slot.key = c.chord, c.key\n    -- Named against the home key: Ab in C major is bVI, Fm is iv.\n    local shift = (c.chord.rootPc - T.pc(key, c.slot.degree)) % 12\n    local numeral = ((shift == 11) and \"b\" or (shift == 1) and \"#\" or \"\") ..\n                    T.degreeNumeral(c.key, c.slot.degree)\n    c.slot.borrowed = { name = c.chord.name, numeral = numeral, from = M.keyName(c.key) }\n  end\n  local c = weighted(rnd, cands, weights)\n  take(c)\n  local out = { c.slot }\n  if r.borrowed == \"Common\" and #timeline >= 8 and rnd() < M.BORROW_AGAIN then\n    local at = {}\n    for i, sl in ipairs(timeline) do at[sl] = i end\n    local more, mw = {}, {}\n    for i, d in ipairs(cands) do\n      if math.abs(at[d.slot] - at[c.slot]) > 1 then more[#more + 1] = d; mw[#mw + 1] = weights[i] end\n    end\n    if #more > 0 then\n      local d = weighted(rnd, more, mw)\n      take(d)\n      out[2] = d.slot\n      if at[d.slot] < at[c.slot] then out = { d.slot, c.slot } end\n    end\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- Push: chords that arrive an eighth early\n--\n-- A chord change on a beat moves back an eighth, onto the \"and\" before it\n-- (some, or most, by the Push setting). The chord before is cut short to\n-- make room, so the chords still follow each other with no gap. The tune's\n-- note on that beat comes early with it (`M.melody`), and so does the bass.\n-- Only where the beat is a quarter or longer, and only\n-- where the chord before is long enough to give up an eighth.\n------------------------------------------------------------------------------\n\nlocal PUSH = { None = 0, Some = 0.3, Lots = 0.65 }\nM.PULL_CHANCE = { None = 0, Some = 0.3, Lots = 0.65 }\n\nfunction M.push(timeline, meter, r, rnd)\n  local p = PUSH[r.push] or 0\n  if p == 0 or meter.beat < 4 then return end\n  for i = 2, #timeline do\n    local sl, prev = timeline[i], timeline[i - 1]\n    if sl.s % meter.beat == 0 and prev.e - prev.s >= meter.beat + 2 and rnd() < p then\n      sl.s, prev.e = sl.s - 2, prev.e - 2\n      sl.pushed = true\n    end\n  end\nend\n\n------------------------------------------------------------------------------\n-- Pull: chords that arrive an eighth late\n-- (docs/decisions/0014-pull-the-chords-lie-back.md)\n--\n-- The opposite of a push, and only for the chords part: the comping lies\n-- back behind the beat while the tune, the bass and the drums stay on it.\n-- So it is done to a copy of the timeline that only the chords part plays\n-- from (`idea.chordTimeline`); the harmony everything else hears is the one\n-- on the beat. The chord before is held an eighth longer to meet it. A\n-- pushed chord is not also pulled, and a chord must be long enough to give\n-- up an eighth at its start.\n------------------------------------------------------------------------------\n\nfunction M.pull(timeline, meter, r, rnd)\n  local out = {}\n  for i, sl in ipairs(timeline) do\n    local c = {}\n    for k, v in pairs(sl) do c[k] = v end\n    out[i] = c\n  end\n  local p = M.PULL_CHANCE[r.pull] or 0\n  if p == 0 or meter.beat < 4 then return out end\n  for i = 2, #out do\n    local sl, prev = out[i], out[i - 1]\n    if not sl.pushed and sl.s % meter.beat == 0 and sl.e - sl.s >= meter.beat + 2 and rnd() < p then\n      sl.s, prev.e = sl.s + 2, prev.e + 2\n      sl.pulled = true\n    end\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- Flavours and inversions (docs/decisions/0018-flavours-voicings-and-inversions.md)\n--\n-- Both touch single chords, never the first chord or a cadence's chords\n-- (the last chord of every unit that closes, and the chord leading to a full\n-- or imperfect close): the idea opens on the tonic and its cadences stay\n-- the textbook's. Each draws from a stream of its own, and nothing when off.\n------------------------------------------------------------------------------\n\n-- The slots that stay as they are: the first, the last, and each cadence's.\nlocal function cadenceSlots(plan, timeline)\n  local keep = { [timeline[1]] = true, [timeline[#timeline]] = true }\n  for _, u in ipairs(plan.units) do\n    if u.cad ~= \"none\" and u.slots and #u.slots > 0 then\n      keep[u.slots[#u.slots]] = true\n      if (u.cad == \"PAC\" or u.cad == \"IAC\" or u.cad == \"DC\" or u.cad == \"EC\") and #u.slots > 1 then keep[u.slots[#u.slots - 1]] = true end\n    end\n  end\n  return keep\nend\n\n------------------------------------------------------------------------------\n-- A key change (1.12; docs/decisions/0024-...)\n--\n-- The pop key change for a last section (Open Music Theory, \"Modulation\";\n-- Hutchinson, ch. 21): from the start of the last unit that begins at or\n-- after half way, on a bar line, with two bars or more to go, every chord is\n-- the same degree of the key a step (or a semitone) up, so the tune - which\n-- is positions in the scale - goes up with it. The truck driver puts the new\n-- key's V (V7 with Sevenths or Mixed) in the second half of the chord before\n-- (or in its place, if it is short).\n------------------------------------------------------------------------------\n\nM.KEY_CHANGE = { [\"Step up\"] = 2, [\"Half step up\"] = 1, [\"Truck driver\"] = 2 }\n\n-- `tonicAt(step)` (optional): whether the tonic sounds there. The truck\n-- driver wants a section that starts on it, so it takes the latest that\n-- does, if one does.\n-- (1.14) `canTonic(u)` (optional): whether a section could be made to start\n-- on the tonic. Where none starts on it, the latest that could is taken,\n-- and the second value says so: the harmony then starts it there.\nfunction M.changeAt(plan, meter, tonicAt, canTonic)\n  local best, home, made\n  for _, u in ipairs(plan.units) do\n    if u.start > 0 and u.start * 2 >= plan.total and u.start % meter.bar == 0\n       and plan.total - u.start >= 2 * meter.bar then\n      best = u.start\n      if tonicAt and tonicAt(u.start) then home = u.start end\n      if canTonic and canTonic(u) then made = u.start end\n    end\n  end\n  if not best then\n    local last = plan.units[#plan.units]\n    if last.start > 0 then best = last.start end\n  end\n  if home then return home end\n  if made then return made, true end\n  return best\nend\n\nfunction M.keyChange(plan, timeline, key, r, meter, colour, at)\n  local semis = M.KEY_CHANGE[r.keyChange]\n  if not semis or not at then return nil end\n  local newKey = T.transpose(key, semis)\n  -- (A named applied chord just before the change - its chord now in the\n  -- new key - is plain again.)\n  for i, sl in ipairs(timeline) do\n    local nx = timeline[i + 1]\n    if sl.s < at and nx and nx.s >= at and sl.applied and sl.applied.named then\n      sl.key, sl.applied = key, nil\n      sl.chord = T.chord(key, sl.degree, colour)\n    end\n  end\n  for _, sl in ipairs(timeline) do\n    if sl.s >= at then\n      local was = sl.chord\n      sl.key = T.transpose(sl.key or key, semis)\n      sl.chord = T.chord(sl.key, sl.degree, colour)\n      if sl.bassPc then sl.bassPc = (sl.bassPc + semis) % 12 end\n      sl.moved = semis\n    end\n  end\n  local truck\n  if r.keyChange == \"Truck driver\" and T.scaleLen(key) == 7 then\n    -- The new key's V: major, from harmonic minor in a minor key.\n    local K = newKey\n    if T.degreeQuality(K, 4) ~= \"major\" then\n      local HARM\n      for i, sc in ipairs(T.SCALES) do if sc.name == \"Harm Minor\" then HARM = i end end\n      K = HARM and T.transpose(T.key(key.root, HARM), semis) or nil\n      if K and T.degreeQuality(K, 4) ~= \"major\" then K = nil end\n    end\n    local idx\n    for i, sl in ipairs(timeline) do if sl.s < at then idx = i end end\n    local sl = idx and timeline[idx]\n    -- (Only where the new key's tonic arrives at the change: the V is there\n    -- \"to prepare that tonic arrival\" (Open Music Theory). Elsewhere it is\n    -- a plain step up.)\n    local arrive = idx and timeline[idx + 1]\n    if K and sl and idx > 1 and arrive and arrive.degree == 0 then\n      local V = { degree = 4, key = K, chord = T.chord(K, 4, (colour == \"Triads\") and \"Triads\" or \"Sevenths\"),\n                  spec = { 4, truck = true }, truck = true }\n      local cut = sl.s + snap(meter, (sl.e - sl.s) / 2)\n      if sl.e - sl.s >= 2 * meter.beat and cut > sl.s and cut < sl.e then\n        -- (The V is the gear change, not part of the passage before: that\n        -- passage's close stays its own - 1.13.)\n        V.s, V.e, V.beat = cut, sl.e, cut\n        sl.e = cut\n        table.insert(timeline, idx + 1, V)\n      else\n        V.s, V.e, V.beat = sl.s, sl.e, sl.beat\n        timeline[idx] = V\n        for _, u in ipairs(plan.units) do\n          for j, x in ipairs(u.slots or {}) do if x == sl then u.slots[j] = V end end\n        end\n      end\n      V.origin = V\n      truck = V\n      -- (A named applied chord the gear change cuts off from its chord - a\n      -- Monte's V7/V before the new key's V - is plain again, 1.14.)\n      for i, x in ipairs(timeline) do\n        local nx = timeline[i + 1]\n        if x.applied and x.applied.named and nx == V then\n          x.key, x.applied = key, nil\n          x.chord = T.chord(key, x.degree, colour)\n        end\n      end\n    end\n  end\n  return { at = at, semis = semis, key = newKey, truck = truck }\nend\n\n------------------------------------------------------------------------------\n-- The minor key's V (1.13)\n--\n-- In a minor key the dominant is major, its third the raised seventh - \"v\n-- ... rare; V from the harmonic minor scale\" (Hutchinson, ch. 7, Figure\n-- 7.3.1). So every V in a key on the Minor scale is the harmonic minor's,\n-- and the tune bends with it (B natural in C minor). The modes keep their\n-- own v: Aeolian, Dorian and Phrygian are what they are. A named\n-- progression's chords are as written.\n------------------------------------------------------------------------------\n\nlocal MINOR, HARM_MINOR\nfunction M.raiseDominant(timeline, key, colour)\n  if not MINOR then\n    for i, sc in ipairs(T.SCALES) do\n      if sc.name == \"Minor\" then MINOR = i elseif sc.name == \"Harm Minor\" then HARM_MINOR = i end\n    end\n  end\n  for _, sl in ipairs(timeline) do\n    local k = sl.key or key\n    if sl.degree == 4 and k.scale == MINOR and not k.iv and not sl.spec then\n      sl.key = { root = k.root, scale = HARM_MINOR, lift = k.lift }\n      sl.chord = T.chord(sl.key, 4, colour)\n      if sl.bassPc then sl.bassPc = nil; sl.bassPos = nil; sl.inversion = nil end\n      sl.raised = true\n    end\n  end\nend\n\n------------------------------------------------------------------------------\n-- Applied chords (1.8; docs/decisions/0020-applied-chords-cadences-and-forms.md)\n--\n-- The chord before a major or minor chord becomes that chord's own dominant\n-- (V, or V7 with Sevenths or Mixed) or its leading-tone chord (viio, viio7):\n-- \"a chromatically altered chord that also functions as a dominant chord in\n-- the key of the chord that follows it\" (Open Music Theory, \"Applied\n-- chords\"; Hutchinson, chs. 17-18). It is made from the home scale with the\n-- notes it needs bent a semitone - V/V in C is the C scale with F#, V/vi the\n-- C scale with G# - so the tune keeps its positions and, while the chord\n-- sounds, bends with it (`I.keyAt`). Never the tonic's (that is just V),\n-- never the first chord or a cadence's, never a borrowed or flavoured one,\n-- never two running; a copied chord does as its original did, where the\n-- chord after it is the same.\n------------------------------------------------------------------------------\n\nM.APPLIED_CHANCE = { Rare = 0.15, Common = 0.4 }\nM.APPLIED_LEADING = 0.25   -- how often it is the leading-tone chord, not V\n\n-- The home scale with the notes of the dominant (`kind` \"V\") or the\n-- leading-tone chord (\"vii\") of degree `x` bent to fit, and that chord's\n-- degree; nil if it needs more than a semitone's bend, or bends nothing.\nfunction M.appliedKey(key, x, kind)\n  local n = T.scaleLen(key)\n  if n ~= 7 then return nil end\n  local iv = {}\n  for i, v in ipairs(T.ivOf(key)) do iv[i] = v end\n  local target = T.pc(key, x)\n  local tonic = T.rootPc(key)\n  -- Each chord note: its degree, and its distance above the target's root.\n  local spec = (kind == \"V\") and { { x + 4, 7 }, { x + 6, 11 }, { x + 1, 2 }, { x + 3, 5 } }\n                              or { { x + 6, 11 }, { x + 1, 2 }, { x + 3, 5 }, { x + 5, 8 } }\n  local bent = false\n  for _, sp in ipairs(spec) do\n    local d = sp[1] % 7\n    local want = (target + sp[2] - tonic) % 12\n    if iv[d + 1] ~= want then\n      local diff = (want - iv[d + 1] + 6) % 12 - 6\n      if math.abs(diff) ~= 1 then return nil end\n      iv[d + 1] = want\n      bent = true\n    end\n  end\n  for i = 2, n do if iv[i] <= iv[i - 1] then return nil end end\n  if not bent then return nil end\n  return { root = key.root, scale = key.scale, iv = iv }, spec[1][1] % 7\nend\n\nfunction M.applied(timeline, plan, key, r, rnd, colour)\n  local chance = M.APPLIED_CHANCE[r.applied]\n  if not chance or T.scaleLen(key) ~= 7 or #timeline < 3 then return {} end\n  local keep = cadenceSlots(plan, timeline)\n  local decided = {}\n  local out = {}\n  local lastDone\n  -- (Only where the chord after is the same every time the passage comes\n  -- round - a repeat, a Loop, an answer's first half - so it does too.)\n  local nextOf, same = {}, {}\n  for i, sl in ipairs(timeline) do\n    local o = sl.origin or sl\n    local nx = timeline[i + 1] and timeline[i + 1].degree or -1\n    if nextOf[o] == nil then nextOf[o], same[o] = nx, true\n    elseif nextOf[o] ~= nx then same[o] = false end\n  end\n  -- (The first chord and the last are never changed: nor are their copies.)\n  for _, sl in ipairs({ timeline[1], timeline[#timeline] }) do decided[sl.origin or sl] = false end\n  for i = 2, #timeline - 1 do\n    local sl, before, after = timeline[i], timeline[i - 1], timeline[i + 1]\n    local was = sl.origin and decided[sl.origin]\n    local x1, x2 = rnd(), rnd()\n    local x = after.degree\n    local q = T.degreeQuality(key, x)\n    local can = not keep[sl] and not sl.borrowed and not after.borrowed and lastDone ~= i - 1 and not sl.spec\n                and not sl.moved and not after.moved and not after.truck and not sl.raised and not after.applied\n                and same[sl.origin or sl]\n                and x ~= 0 and (q == \"major\" or q == \"minor\")\n    local go, kind\n    if was ~= nil then\n      go = was ~= false and was.target == x\n      kind = go and was.kind\n    else\n      go = x1 < chance\n      kind = (x2 < M.APPLIED_LEADING) and \"vii\" or \"V\"\n    end\n    local done = false\n    if go and can then\n      local akey, deg = M.appliedKey(key, x, kind)\n      local ch = akey and T.chord(akey, deg, (colour == \"Triads\") and \"Triads\" or \"Sevenths\")\n      -- (A chord with no bent note in it - V/IV as a plain triad is I - is\n      -- not an applied chord.)\n      local bent = false\n      if ch then\n        local home = {}\n        for d = 0, 6 do home[T.pc(key, d)] = true end\n        for _, pc in ipairs(ch.pcs) do if not home[pc] then bent = true end end\n      end\n      if bent and deg ~= before.degree then\n        sl.chord, sl.key, sl.degree = ch, akey, deg\n        local numeral = (kind == \"V\" and \"V\" or \"viio\") .. ((#ch.pcs > 3) and \"7\" or \"\") .. \"/\" ..\n                        T.degreeNumeral(key, x)\n        sl.applied = { name = ch.name, numeral = numeral, to = after.chord.name, kind = kind, target = x }\n        out[#out + 1] = sl\n        lastDone, done = i, true\n      end\n    end\n    if sl.origin and was == nil then decided[sl.origin] = done and { kind = kind, target = x } or false end\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- Chromatic chords (1.15; docs/decisions/0027-...)\n--\n-- The chromatic pre-dominants: \"the most common chromatically altered\n-- subdominant chords (aside from the applied dominant of V) are the\n-- Neapolitan chord and the various augmented-sixth chords\" (Open Music\n-- Theory, \"Chromatically altered subdominant chords\"). At a close, the ii or\n-- IV before its V may become one (with Borrowed on; dice of their own):\n--\n--   N6    the Neapolitan: the major chord on the flat 2nd (ra fa le), with\n--         fa in the bass - Db/F in C. \"Being a chromatically altered ii\n--         chord, the Neapolitan has pre-dominant harmonic function\"\n--         (Hutchinson, 20.1). From the Phrygian on the same key note.\n--   It+6  le do fi: Ab C F# in C (Ab7 without its fifth, on a lead sheet).\n--   Fr+6  le do re fi: Ab C D F# (Ab7(b5)).\n--   Ger+6 le do me fi: Ab C Eb F# (Ab7). \"Almost always ... followed by a\n--         cadential 6/4\" (Open Music Theory): it takes the first half of\n--         the V for the I6/4, or is not chosen.\n--\n-- Le in the bass; le and fi move out to sol (Hutchinson, 21.1). The tune\n-- under one uses the home scale with those notes bent. Only before a major\n-- V (one with a leading tone), never on a named progression's chord, a\n-- borrowed or applied one, or after a key change. A copy does what its\n-- original did.\n------------------------------------------------------------------------------\n\nM.CHROMATIC_CHANCE = { Rare = 0.35, Common = 0.8 }\n-- (1.16) The Swiss sixth: the German's sound with ri for me - \"the Swiss\n-- chord tends to appear in major keys, with ri proceeding to mi and do\n-- carrying over into the cadential 6/4\" (Open Music Theory). In a major key\n-- it shares the German's place, half and half; in minor, the German alone\n-- (\"almost always used in minor\").\nM.CHROMATIC_WEIGHT = { N6 = 2, [\"It+6\"] = 1, [\"Fr+6\"] = 1, [\"Ger+6\"] = 1, [\"Sw+6\"] = 0.5 }\nlocal CHROMATIC_KINDS = { \"N6\", \"It+6\", \"Fr+6\", \"Ger+6\", \"Sw+6\" }\n\nlocal function scaleNamed(name)\n  for i, sc in ipairs(T.SCALES) do if sc.name == name then return i end end\nend\n\n-- The home scale with fa raised and la lowered (and mi lowered, for the\n-- German sixth): the notes the tune hears under an augmented sixth. Nil if\n-- the scale cannot take it.\nlocal function aug6Key(key, kind)\n  local iv = {}\n  for i, v in ipairs(T.ivOf(key)) do iv[i] = v end\n  iv[4], iv[6] = 6, 8\n  if kind == \"Ger+6\" then iv[3] = 3 end\n  if kind == \"Sw+6\" then iv[2] = 3 end\n  for i = 2, 7 do if iv[i] <= iv[i - 1] then return nil end end\n  return { root = key.root, scale = key.scale, iv = iv }\nend\n\n-- The augmented sixth chord, named as a lead sheet names it (Hutchinson,\n-- 21.4): the dominant seventh on le it sounds like.\nlocal function aug6Chord(k6, kind)\n  local pos = { 5, 7 }\n  if kind == \"Fr+6\" or kind == \"Sw+6\" then pos[#pos + 1] = 8 elseif kind == \"Ger+6\" then pos[#pos + 1] = 9 end\n  pos[#pos + 1] = 10\n  local ch = { degree = 5, pos = pos, pcs = {}, has = {}, colour = \"Sevenths\", quality = \"major\",\n               aug6 = kind, numeral = kind }\n  for i, p in ipairs(pos) do\n    ch.pcs[i] = T.pc(k6, p)\n    ch.has[ch.pcs[i]] = true\n  end\n  ch.rootPc = ch.pcs[1]\n  ch.name = T.noteName(k6, 5) .. ({ [\"It+6\"] = \"7(no5)\", [\"Fr+6\"] = \"7(b5)\", [\"Ger+6\"] = \"7\", [\"Sw+6\"] = \"7\" })[kind]\n  return ch\nend\n\nfunction M.chromatic(timeline, plan, key, r, rnd, meter)\n  local chance = M.CHROMATIC_CHANCE[r.borrowed]\n  if not chance or T.scaleLen(key) ~= 7 then return {} end\n  local PHRYG = scaleNamed(\"Phrygian\")\n  local out, decided = {}, {}\n  -- (A copy of an earlier chord - a Period's answer opening as its question\n  -- did - does only what its original did, and its original did nothing if\n  -- it was not before a V.)\n  local first = {}\n  for i, sl in ipairs(timeline) do\n    if sl.origin and not first[sl.origin] then first[sl.origin] = sl end\n  end\n  for _, u in ipairs(plan.units) do\n    -- (Two draws for every close, taken or not: Common keeps Rare's.)\n    local closes = u.cad == \"PAC\" or u.cad == \"IAC\" or u.cad == \"DC\" or u.cad == \"EC\" or u.cad == \"HC\"\n    local x1, x2 = 1, 0\n    if closes then x1, x2 = rnd(), rnd() end\n    local V = closes and u.slots and u.slots[#u.slots - ((u.cad == \"HC\") and 0 or 1)]\n    local at\n    for i, sl in ipairs(timeline) do if sl == V then at = i end end\n    local pre = at and timeline[at - 1]\n    -- (Where the tonic comes straight before the V, its second half may\n    -- take the chromatic chord: i N6 V, as both books show it.)\n    local split\n    if pre and pre.degree == 0 then\n      split = pre.s + snap(meter, (pre.e - pre.s) / 2)\n      if not (pre.e - pre.s >= 2 * meter.beat and split > pre.s and split < pre.e) then split = nil end\n    end\n    -- (Not a chord an applied chord leads to: it must stay its target.)\n    local led = pre and not split and timeline[at - 2] and timeline[at - 2].applied\n    if pre and not led and at - 1 > 1 and V.degree == 4 and V.chord.quality == \"major\" and not V.spec and not V.moved\n       and not V.applied and not V.borrowed and pre.e == V.s\n       and (pre.degree == 1 or pre.degree == 3 or split) and not pre.spec and not pre.borrowed and not pre.applied\n       and not pre.moved and not pre.truck and not pre.flavour and not pre.bassPc and (pre.key or key) == key then\n      local origin = pre.origin\n      local was = origin and decided[origin]\n      if was == nil and origin and first[origin] ~= pre then was = false end\n      local kinds, weights = {}, {}\n      -- (Not the same root as the chord before - VI then the augmented\n      -- sixth on le, ii then the Neapolitan's: the chord would seem to\n      -- follow itself.)\n      local before = not split and timeline[at - 2]\n      for _, k in ipairs(CHROMATIC_KINDS) do\n        local fits = (k == \"N6\" and PHRYG ~= nil) or (k ~= \"N6\" and aug6Key(key, k) ~= nil)\n        -- (With Triads, three notes: the Neapolitan and the Italian sixth.)\n        if r.colour == \"Triads\" and (k == \"Fr+6\" or k == \"Ger+6\" or k == \"Sw+6\") then fits = false end\n        if before and before.degree == ((k == \"N6\") and 1 or 5) then fits = false end\n        -- (The German sixth needs room for the I6/4: half of a V two beats\n        -- long or more, on a beat.)\n        -- (Not at a half close, whose V is its last chord: the tune comes\n        -- home on it, not on the six-four.)\n        if k == \"Ger+6\" or k == \"Sw+6\" then\n          local cut = V.s + snap(meter, (V.e - V.s) / 2)\n          fits = fits and V.e - V.s >= 2 * meter.beat and cut > V.s and cut < V.e and u.cad ~= \"HC\"\n        end\n        -- (The Swiss only in major keys: in minor, ri would be me, which\n        -- `aug6Key` refuses - the scale would not climb.)\n        local w = M.CHROMATIC_WEIGHT[k]\n        if k == \"Ger+6\" and T.degreeQuality(key, 0) == \"major\" then w = 0.5 end\n        if fits and (was == nil or was == k) then kinds[#kinds + 1] = k; weights[#weights + 1] = w end\n      end\n      local kind\n      if was ~= nil then kind = was and kinds[1] or nil\n      elseif x1 < chance and #kinds > 0 then kind = pickAt(x2, kinds, weights) end\n      if kind and split then\n        -- The tonic keeps the first half; the second is the new chord's.\n        local tonic = {}\n        for kk, v in pairs(pre) do tonic[kk] = v end\n        tonic.e = split\n        pre.s, pre.beat = split, split\n        pre.origin = { of = pre.origin }\n        table.insert(timeline, at - 1, tonic)\n        for _, w in ipairs(plan.units) do\n          for j, x in ipairs(w.slots or {}) do\n            if x == pre then w.slots[j] = tonic; table.insert(w.slots, j + 1, pre); break end\n          end\n        end\n        at = at + 1\n      end\n      if kind == \"N6\" then\n        local k = T.key(key.root, PHRYG)\n        pre.key, pre.degree = k, 1\n        pre.chord = T.chord(k, 1, \"Triads\")\n        pre.bassPc, pre.bassPos, pre.inversion = T.pc(k, 3), 3, 1\n        pre.spec = { 1, from = PHRYG, bass = 3, chromatic = true }\n      elseif kind then\n        local k = aug6Key(key, kind)\n        pre.key, pre.degree = k, 5\n        pre.chord = aug6Chord(k, kind)\n        pre.bassPc, pre.bassPos, pre.inversion = nil, nil, nil\n        pre.spec = { 5, chromatic = true }\n        if kind == \"Ger+6\" or kind == \"Sw+6\" then\n          -- The cadential six-four: the tonic over sol, then V.\n          local cut = V.s + snap(meter, (V.e - V.s) / 2)\n          local six = { s = V.s, e = cut, beat = V.beat or V.s, degree = 0, key = key,\n                        chord = T.chord(key, 0, \"Triads\"), spec = { 0, bass = 4, cadential = true } }\n          six.bassPc, six.bassPos, six.inversion = T.pc(key, 4), 4, 2\n          six.origin = six\n          V.s, V.beat = cut, cut\n          table.insert(timeline, at, six)\n          for j, x in ipairs(u.slots) do\n            if x == V then table.insert(u.slots, j, six); break end\n          end\n        end\n      end\n      if kind then\n        -- (The chord before keeps its root in the bass: an inversion there\n        -- would be judged against the chord that was.)\n        local before = timeline[at - 2]\n        if before then before.rootHeld = true end\n        pre.chromatic = { kind = kind, name = pre.chord.name ..\n                          (pre.bassPos and (\"/\" .. T.noteName(pre.key, pre.bassPos)) or \"\"),\n                          numeral = kind }\n        out[#out + 1] = pre\n      end\n      if origin and was == nil then decided[origin] = kind or false end\n    end\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- The passing diminished seventh (1.15)\n--\n-- Where the bass rises a whole tone from one chord to the next - IV to V,\n-- I to ii, V to vi - the second half of the first chord may become the\n-- diminished seventh on the note between: F F#dim7 G, the bass climbing by\n-- semitones. It is the next chord's own leading-tone seventh (viio7/V), a\n-- passing chord (\"a passing chord ... will fill in the third with stepwise\n-- motion\" - Open Music Theory, \"Harmonic syntax - prolongation\"; Hutchinson's\n-- I6 ii6 viio7/V I6/4). With Applied on; dice of their own. Only where the\n-- next chord is major or minor and in root position, the chord split is two\n-- beats or more and not a close's, and the next chord is the same each time\n-- round.\n------------------------------------------------------------------------------\n\nM.PASSING_CHANCE = { Rare = 0.25, Common = 0.6 }\n\nfunction M.passing(timeline, plan, key, r, rnd, meter)\n  local chance = M.PASSING_CHANCE[r.applied]\n  if not chance or T.scaleLen(key) ~= 7 or #timeline < 2 then return {} end\n  local keep = cadenceSlots(plan, timeline)\n  local home = {}\n  for d = 0, 6 do home[T.pc(key, d)] = true end\n  local nextOf, same = {}, {}\n  for i, sl in ipairs(timeline) do\n    local o = sl.origin or sl\n    local nx = timeline[i + 1] and timeline[i + 1].degree or -1\n    if nextOf[o] == nil then nextOf[o], same[o] = nx, true\n    elseif nextOf[o] ~= nx then same[o] = false end\n  end\n  local out, decided = {}, {}\n  local i = 1\n  while i < #timeline do\n    local sl, nx = timeline[i], timeline[i + 1]\n    local x = rnd()\n    local was = sl.origin and decided[sl.origin]\n    local q = T.degreeQuality(key, nx.degree)\n    local cut = sl.s + snap(meter, (sl.e - sl.s) / 2)\n    local can = not keep[sl] and not sl.spec and not sl.borrowed and not sl.applied and not sl.moved\n                and not sl.chromatic and not nx.spec and not nx.borrowed and not nx.applied and not nx.moved\n                and not nx.truck and not nx.chromatic and ((nx.key or key) == key or nx.raised)\n                and (q == \"major\" or q == \"minor\") and not nx.bassPc\n                and (T.pc(key, nx.degree) - M.bassPcOf(sl)) % 12 == 2\n                and sl.e - sl.s >= 2 * meter.beat and cut > sl.s and cut < sl.e and cut % meter.beat == 0\n                and same[sl.origin or sl]\n    local go\n    if was ~= nil then go = was == nx.degree else go = x < chance end\n    local done = false\n    if go and can then\n      local akey, deg = M.appliedKey(key, nx.degree, \"vii\")\n      -- (With Triads, the diminished triad: three notes, as the Colour says.)\n      local triads = r.colour == \"Triads\"\n      local ch = akey and T.chord(akey, deg, triads and \"Triads\" or \"Sevenths\")\n      local full = ch and #ch.pcs == (triads and 3 or 4)\n      if full then\n        for k = 2, #ch.pcs do if (ch.pcs[k] - ch.pcs[k - 1]) % 12 ~= 3 then full = false end end\n      end\n      local bent = false\n      if full then for _, pc in ipairs(ch.pcs) do if not home[pc] then bent = true end end end\n      if full and bent then\n        local P = { s = cut, e = sl.e, beat = cut, degree = deg, key = akey, chord = ch,\n                    spec = { deg, passing = true } }\n        P.origin = P\n        P.applied = { name = ch.name, numeral = (triads and \"viio/\" or \"viio7/\") .. T.degreeNumeral(key, nx.degree), kind = \"vii\",\n                      target = nx.degree, passing = true, to = nx.chord.name }\n        sl.e = cut\n        sl.rootHeld, nx.rootHeld = true, true\n        table.insert(timeline, i + 1, P)\n        for _, u in ipairs(plan.units) do\n          for j, y in ipairs(u.slots or {}) do\n            if y == sl then table.insert(u.slots, j + 1, P); break end\n          end\n        end\n        out[#out + 1] = P\n        done = true\n        i = i + 1\n      end\n    end\n    if sl.origin and was == nil then decided[sl.origin] = done and nx.degree or false end\n    i = i + 1\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- The common-tone diminished seventh (1.16)\n--\n-- A diminished seventh that \"progresses to a major triad or dominant\n-- seventh chords whose root is the same as one of the notes of the o7\n-- chord\" - #ii\u00c2\u00b07 to I, #vi\u00c2\u00b07 to V - an embellishment: \"the remaining three\n-- notes of the diminished seventh chord resolve to the nearest chord tone,\n-- but the diminished 7th of the chord remains unresolved as a common tone\".\n-- So a held I or V, three beats or more and not a close's, may be split I -\n-- #ii\u00c2\u00b07 - I (V - #vi\u00c2\u00b07 - V): a neighbour chord, its common tone - the\n-- chord's root - held in the bass. With Applied on, its own dice; not with\n-- Triads (it is a seventh chord); a copy does what its original did.\n------------------------------------------------------------------------------\n\nM.COMMON_TONE_CHANCE = { Rare = 0.4, Common = 0.8 }\n\n-- The scale the tune hears under it: the chord's own with its second, fourth\n-- and sixth bent to a minor third, an augmented fourth and a major sixth\n-- above the root. Nil where that takes more than a semitone.\nlocal function commonToneKey(k, x)\n  local iv = {}\n  for i, v in ipairs(T.ivOf(k)) do iv[i] = v end\n  local root = T.pc(k, x)\n  local tonic = T.rootPc(k)\n  for _, sp in ipairs({ { x + 1, 3 }, { x + 3, 6 }, { x + 5, 9 } }) do\n    local d = sp[1] % 7\n    local want = (root + sp[2] - tonic) % 12\n    if iv[d + 1] ~= want then\n      local diff = (want - iv[d + 1] + 6) % 12 - 6\n      if math.abs(diff) ~= 1 then return nil end\n      iv[d + 1] = want\n    end\n  end\n  for i = 2, 7 do if iv[i] <= iv[i - 1] then return nil end end\n  return { root = k.root, scale = k.scale, iv = iv, lift = k.lift }\nend\n\nfunction M.commonTone(timeline, plan, key, r, rnd, meter)\n  local chance = M.COMMON_TONE_CHANCE[r.applied]\n  if not chance or T.scaleLen(key) ~= 7 or r.colour == \"Triads\" then return {} end\n  local keep = cadenceSlots(plan, timeline)\n  local out, decided = {}, {}\n  local first = {}\n  for _, sl in ipairs(timeline) do\n    if sl.origin and not first[sl.origin] then first[sl.origin] = sl end\n  end\n  local i = 1\n  while i <= #timeline do\n    local sl = timeline[i]\n    local x = rnd()\n    local origin = sl.origin\n    local was = origin and decided[origin]\n    if was == nil and origin and first[origin] ~= sl then was = false end\n    -- (Counted from its beat: a chord pushed in early is split on the beats.)\n    local from = sl.beat or sl.s\n    local beats = (sl.e - from) // meter.beat\n    local k = sl.key or key\n    local can = (sl.degree == 0 or sl.degree == 4) and sl.chord.quality == \"major\" and not sl.bassPc\n                and not keep[sl] and not sl.spec and not sl.borrowed and not sl.applied and not sl.chromatic\n                and not sl.moved and not sl.truck and not sl.flavour\n                and from % meter.beat == 0 and (sl.e - from) % meter.beat == 0 and beats >= 3\n    local go\n    if was ~= nil then go = was == true else go = x < chance end\n    local done = false\n    if go and can then\n      local ck = commonToneKey(k, sl.degree)\n      local ch = ck and T.chord(ck, sl.degree + 1, \"Sevenths\")\n      local full = ch and #ch.pcs == 4 and ch.has[sl.chord.rootPc]\n      if full then for j = 2, 4 do if (ch.pcs[j] - ch.pcs[j - 1]) % 12 ~= 3 then full = false end end end\n      if full then\n        local ctLen = math.max(1, beats // 4) * meter.beat\n        local after = math.max(1, beats // 4) * meter.beat\n        local a = sl.e - after - ctLen\n        local C = { s = a, e = a + ctLen, beat = a, degree = (sl.degree + 1) % 7, key = ck, chord = ch,\n                    spec = { (sl.degree + 1) % 7, commonTone = true } }\n        C.bassPc, C.bassPos, C.inversion = sl.chord.rootPc, sl.degree, 3\n        C.origin = C\n        C.commonTone = { name = ch.name .. \"/\" .. T.noteName(ck, sl.degree),\n                         numeral = (sl.degree == 0) and \"#iio7\" or \"#vio7\", over = sl.chord.name }\n        local back = {}\n        for kk, v in pairs(sl) do back[kk] = v end\n        back.s, back.beat = a + ctLen, a + ctLen\n        sl.e = a\n        sl.rootHeld, back.rootHeld = true, true\n        table.insert(timeline, i + 1, C)\n        table.insert(timeline, i + 2, back)\n        for _, u in ipairs(plan.units) do\n          for j, y in ipairs(u.slots or {}) do\n            if y == sl then table.insert(u.slots, j + 1, C); table.insert(u.slots, j + 2, back); break end\n          end\n        end\n        out[#out + 1] = C\n        done = true\n        i = i + 2\n      end\n    end\n    if origin and was == nil then decided[origin] = done end\n    i = i + 1\n  end\n  return out\nend\n\n-- Now and then a chord takes another colour (`T.flavourChord`): about one\n-- chord in five that may. (With Mixed until 1.14; now with every colour -\n-- the diminished chord a third up, a seventh chord, not with Triads.)\nM.FLAVOUR_CHANCE = { Rare = 0.2, Common = 0.5 }\nlocal FLAVOUR_WEIGHT = { sus4 = 3, sus2 = 2, add2 = 1.5, add9 = 1.5, [\"9\"] = 2, [\"6\"] = 2, dim = 1.5 }\n\n-- A chord copied from another (a repeat, an answer's first half, a Loop\n-- going round) takes the flavour its original took, where it can, and\n-- draws nothing: the music that comes round again sounds the same.\n-- (1.12) A 6 becomes a 6/9 - the whole-tone ninth on top - half the time\n-- the ninth is there, on dice of its own, so the flavours drawn before are\n-- drawn as they were.\nM.SIXNINE_CHANCE = 0.5\n\nfunction M.flavour(timeline, plan, key, r, rnd, sixRnd)\n  local chance = M.FLAVOUR_CHANCE[r.flavours]\n  if not chance or T.scaleLen(key) ~= 7 then return end\n  local keep = cadenceSlots(plan, timeline)\n  local decided = {}\n  -- (Nor a chord whose copy is a cadence's, where the copy could not follow\n  -- it: a Period's answer opens as its question did.)\n  local blocked = {}\n  for _, sl in ipairs(timeline) do if keep[sl] and sl.origin then blocked[sl.origin] = true end end\n  for i, sl in ipairs(timeline) do\n    local was = sl.origin and decided[sl.origin]\n    local go\n    if was ~= nil then go = was ~= false\n    else go = not keep[sl] and not sl.borrowed and not (sl.origin and blocked[sl.origin]) and rnd() < chance end\n    -- (Nor the chord an applied chord leads to: it must stay the chord it\n    -- is the dominant of.)\n    local target = timeline[i - 1] and timeline[i - 1].applied\n    -- (Nor the truck driver's V: the gear change is a dominant seventh. Nor\n    -- a chromatic chord or the six-four a German sixth goes to, nor a chord\n    -- whose root a passing or chromatic chord needs where it is, 1.15.)\n    if go and not keep[sl] and not sl.borrowed and not sl.applied and not target and not sl.truck\n       and not sl.chromatic and not (sl.spec and sl.spec.cadential) and not sl.rootHeld and not sl.commonTone then\n      local seventh = false\n      for _, pc in ipairs(sl.chord.pcs) do if T.roleOf(sl.chord, pc) == \"7\" then seventh = true end end\n      local before, after = timeline[i - 1], timeline[i + 1]\n      local cands, weights = {}, {}\n      for _, f in ipairs(T.FLAVOURS) do\n        local ch = T.flavourChord(sl.key or key, sl.degree, f, seventh)\n        if f == \"dim\" and r.colour == \"Triads\" then ch = nil end\n        -- (Not one that drops a named progression's bass note: no sus4 over\n        -- Pachelbel's G/B.)\n        if ch and sl.bassPc then\n          local has = false\n          for _, pc in ipairs(ch.pcs) do if pc == sl.bassPc then has = true end end\n          if not has then ch = nil end\n        end\n        -- (Not one that sounds like the chord either side of it. An add9 has\n        -- the notes and the name of Mixed's own; it changes the voicing,\n        -- putting its ninth on top.)\n        -- (Nor one whose bass is the chord before's, on the same degree - a\n        -- Romanesca's I6 then I as D#m7b5 over D#, 1.16: the same chord on\n        -- the same bass twice.)\n        if ch and before and before.degree == sl.degree and M.bassPcOf(before) == (sl.bassPc or ch.rootPc) then ch = nil end\n        if ch and after and after.degree == sl.degree and M.bassPcOf(after) == (sl.bassPc or ch.rootPc) then ch = nil end\n        if ch and (ch.name ~= sl.chord.name or f == \"add9\") and not (before and before.chord.name == ch.name)\n           and not (after and after.chord.name == ch.name) and (was == nil or was == f or (was == \"6/9\" and f == \"6\")) then\n          cands[#cands + 1] = ch\n          weights[#weights + 1] = FLAVOUR_WEIGHT[f]\n        end\n      end\n      if #cands > 0 then\n        sl.chord = (was ~= nil) and cands[1] or weighted(rnd, cands, weights)\n        sl.flavour = sl.chord.flavour\n        if sl.flavour == \"6\" then\n          local up = T.flavourChord(sl.key or key, sl.degree, \"6/9\", false)\n          local go\n          if was ~= nil then go = was == \"6/9\" else go = sixRnd and sixRnd() < M.SIXNINE_CHANCE end\n          if up and go and not (sl.bassPc and not up.has[sl.bassPc]) then\n            sl.chord, sl.flavour = up, \"6/9\"\n          end\n        end\n      end\n    end\n    if sl.origin and was == nil then decided[sl.origin] = sl.flavour or false end\n  end\nend\n\n-- The note in the bass under a chord: its root, or the note it is inverted on.\nlocal function bassPcOf(sl) return sl.bassPc or sl.chord.rootPc end\nM.bassPcOf = bassPcOf\n\nlocal function byStep(a, b)\n  local d = (a - b) % 12\n  return d == 1 or d == 2 or d == 10 or d == 11\nend\n\n-- Inversions where they do a job (Open Music Theory, \"Harmonic syntax -\n-- prolongation\"): the bass moving by step.\n--\n--   first   the third in the bass, where the bass steps into it or out of\n--           it - C G/B Am, F C/E Dm - likeliest when it does both (a\n--           passing chord)\n--   second  the fifth in the bass only where a 6/4 belongs: over a held\n--           bass (I IV6/4 I), passing between two steps (I V6/4 I6), or\n--           the tonic's fifth before the dominant at a cadence (I6/4 V)\n--   third   the seventh in the bass, only where it can fall a step into\n--           the next chord, which then takes that note in its bass\n--           (V4/2 I6)\n--\n-- About one chord in four that could be inverted is (more than half with\n-- Common); never two running (but for the chord a third inversion resolves\n-- to), never a flavoured one.\n--\n-- Checked against the textbooks' rules for six-fours (Open Music Theory;\n-- Puget Sound's Music Theory for the 21st-Century Classroom): a cadential\n-- 6/4 comes at a cadence, right before its V, on a stronger beat; a passing\n-- 6/4 walks the bass through three notes one way and a pedal 6/4 holds it,\n-- both on a weaker beat, between two chords of the same function. And a\n-- diminished triad is most at home in first inversion (vii6): in root\n-- position its fifth is a tritone over the bass. So a diminished triad is\n-- inverted three times in four where its bass steps, and never to a 6/4.\nM.INVERT_CHANCE = { Rare = 0.25, Common = 0.6 }\nM.DIM_FIRST = 0.75\n\n-- How strong a beat is, with the odd bars of a pair stronger than the even\n-- (so a chord a bar still has strong and weak places).\nlocal function weightAt(meter, step)\n  local w = M.strength(meter, step)\n  if step % meter.bar == 0 and (step // meter.bar) % 2 == 0 then w = w + 0.5 end\n  return w\nend\nM.weightAt = weightAt\nlocal function beatAt(sl) return sl.beat or sl.s end\n\n-- As with flavours, a chord copied from another is inverted as its original\n-- was, where the bass around it still allows it, and draws nothing.\nfunction M.invert(timeline, plan, key, r, rnd, meter)\n  local chance = M.INVERT_CHANCE[r.inversions]\n  if not chance or #timeline < 3 then return end\n  local keep = cadenceSlots(plan, timeline)\n  local decided = {}\n  local i = 2\n  while i <= #timeline - 1 do\n    local sl, before, after = timeline[i], timeline[i - 1], timeline[i + 1]\n    local step = 1\n    local was = sl.origin and decided[sl.origin]\n    local dimTriad = sl.chord.quality == \"diminished\" and #sl.chord.pcs == 3 and not sl.flavour\n    local go\n    if was ~= nil then go = was ~= false\n    else\n      local x = rnd()\n      go = x < chance or (dimTriad and x < M.DIM_FIRST)\n    end\n    if sl.inversion then go = false end\n    -- (Nor either side of a passing diminished seventh, 1.15: the bass must\n    -- climb by semitones through it.)\n    if go and not keep[sl] and not sl.flavour and not sl.applied and not sl.spec and not sl.rootHeld then\n      local ch = sl.chord\n      local pb, nb = bassPcOf(before), after.chord.rootPc\n      local k = sl.key or key\n      local sameFunction = T.functionOf(k, before.degree) == T.functionOf(k, after.degree)\n      local weaker = weightAt(meter, beatAt(sl)) < weightAt(meter, beatAt(before))\n      local opts, weights = {}, {}\n      for idx, pc in ipairs(ch.pcs) do\n        local role = T.roleOf(ch, pc)\n        if role == \"3\" and (byStep(pb, pc) or byStep(pc, nb)) then\n          opts[#opts + 1] = { idx = idx, inv = 1 }\n          weights[#weights + 1] = (byStep(pb, pc) and byStep(pc, nb)) and 3 or 1\n        elseif role == \"5\" and not dimTriad then\n          local up = (pc - pb) % 12\n          local on = (nb - pc) % 12\n          local oneWay = (up >= 1 and up <= 2 and on >= 1 and on <= 2) or (up >= 10 and on >= 10)\n          local pedal = pc == pb and pc == nb and sameFunction and weaker\n          local passing = oneWay and sameFunction and weaker\n          local cadential = sl.degree == 0 and keep[after] and T.rootAbove(k, after.degree) == 7\n                            and weightAt(meter, beatAt(sl)) > weightAt(meter, beatAt(after))\n          if pedal or passing or cadential then\n            opts[#opts + 1] = { idx = idx, inv = 2 }\n            weights[#weights + 1] = 1\n          end\n        elseif role == \"7\" and not keep[after] and not after.flavour and not after.rootHeld then\n          -- (Onto the next chord's root or third - V4/2 to I6 - never its\n          -- seventh, which would want resolving in turn.)\n          for _, t in ipairs(after.chord.pcs) do\n            local d = (pc - t) % 12\n            local role = T.roleOf(after.chord, t)\n            if (d == 1 or d == 2) and (role == \"R\" or role == \"3\") then\n              opts[#opts + 1] = { idx = idx, inv = 3, to = t }\n              weights[#weights + 1] = 1\n              break\n            end\n          end\n        end\n      end\n      -- (Never the same chord on the same bass as the one beside it - a\n      -- named V6/5 next to it, say: 1.13.)\n      do\n        local keepO, keepW = {}, {}\n        for k, o in ipairs(opts) do\n          local b = ch.pcs[o.idx]\n          local twin = (before and before.degree == sl.degree and bassPcOf(before) == b)\n                       or (after and after.degree == sl.degree and bassPcOf(after) == b)\n          if not twin then keepO[#keepO + 1] = o; keepW[#keepW + 1] = weights[k] end\n        end\n        opts, weights = keepO, keepW\n      end\n      if was ~= nil then\n        local same = {}\n        for _, o in ipairs(opts) do if o.inv == was then same[1] = o; break end end\n        opts, weights = same, { 1 }\n      end\n      if #opts > 0 then\n        local o = (was ~= nil) and opts[1] or weighted(rnd, opts, weights)\n        sl.bassPc, sl.bassPos, sl.inversion = ch.pcs[o.idx], ch.pos[o.idx], o.inv\n        if o.to then\n          for idx, t in ipairs(after.chord.pcs) do\n            if t == o.to and t ~= after.chord.rootPc then\n              after.bassPc, after.bassPos = t, after.chord.pos[idx]\n              after.inversion = ({ [\"3\"] = 1, [\"5\"] = 2, [\"7\"] = 3 })[T.roleOf(after.chord, t)]\n            end\n          end\n        end\n        step = 2\n      end\n    end\n    if sl.origin and was == nil then decided[sl.origin] = sl.inversion or false end\n    i = i + step\n  end\nend\n\n------------------------------------------------------------------------------\n-- 4. Rhythm\n--\n-- Two kinds of maths, one for each groove:\n--\n--   - Straight takes the k strongest steps of the bar (the metric hierarchy:\n--     the downbeat, the half bar, the beats, then the half beats).\n--   - Syncopated spreads k notes as evenly as they will go over the bar (a\n--     Euclidean rhythm - Toussaint showed most of the world's rhythms are\n--     these: 3 in 8 is the tresillo, 5 in 8 the cinquillo) and turns it so\n--     the notes fall off the beat, keeping the first on the downbeat.\n--\n-- Pace decides the grid (eighths or sixteenths) and how full it is.\n------------------------------------------------------------------------------\n\n-- k onsets spread over n steps as evenly as they go (Bresenham's line; the\n-- same patterns as Bjorklund's algorithm, up to rotation). Starts on 0.\nfunction M.euclid(k, n)\n  local out = {}\n  if n <= 0 then return out end\n  k = math.max(0, math.min(n, k))\n  for i = 0, n - 1 do\n    if (i * k) % n < k then out[#out + 1] = i end\n  end\n  return out\nend\n\nlocal function meanStrength(meter, base, unit, slots)\n  local s = 0\n  for _, o in ipairs(slots) do s = s + M.strength(meter, base + o * unit) end\n  return s / math.max(1, #slots)\nend\n\n-- The k strongest of `slots` grid points, ties broken by the dice.\nlocal function strongest(meter, base, unit, slots, k, rnd)\n  local order = {}\n  for i = 0, slots - 1 do order[#order + 1] = { i = i, w = M.strength(meter, base + i * unit) + rnd() * 0.5 } end\n  table.sort(order, function(a, b) return a.w > b.w end)\n  local out = {}\n  for j = 1, math.min(k, #order) do out[j] = order[j].i end\n  table.sort(out)\n  if out[1] ~= 0 then\n    -- The downbeat always speaks.\n    out[#out] = nil\n    table.insert(out, 1, 0)\n    table.sort(out)\n  end\n  return out\nend\n\n-- A Euclidean rhythm turned to start on one of its own notes, the turn\n-- chosen to sit off the beat.\nlocal function syncopated(meter, base, unit, slots, k, rnd)\n  local pat = M.euclid(k, slots)\n  local turns = {}\n  for _, o in ipairs(pat) do\n    local t = {}\n    for _, x in ipairs(pat) do t[#t + 1] = (x - o) % slots end\n    table.sort(t)\n    turns[#turns + 1] = { t = t, s = meanStrength(meter, base, unit, t) }\n  end\n  -- Ties are left to the sort as 1.0 left them: the list is never longer\n  -- than a bar's sixteen steps, and Lua only varies its sort past a hundred\n  -- items, so the same turns always come out in the same order.\n  table.sort(turns, function(a, b) return a.s < b.s end)\n  -- The most off-beat turn, or the one after it.\n  return turns[(#turns > 1 and coin(rnd, 0.35)) and 2 or 1].t\nend\n\nM.PACE = {\n  Calm    = { unit = 2, lo = 0.2,  hi = 0.4,  halves = false },\n  Flowing = { unit = 2, lo = 0.45, hi = 0.75, halves = true },\n  Busy    = { unit = 1, lo = 0.4,  hi = 0.65, halves = true },\n}\n\n------------------------------------------------------------------------------\n-- Figures: dotted and triplet rhythms\n--\n-- Laid over a rhythm after it is made, a beat (or a pair of beats) at a\n-- time, by chance:\n--\n--   - two eighths in a beat become a dotted eighth and a sixteenth;\n--     two quarters in two beats, a dotted quarter and an eighth;\n--   - a beat with two or more notes becomes an eighth-note triplet; two\n--     quarters in two beats, a quarter-note triplet;\n--   - in the tune, a quarter note on the beat (with a note on the beat\n--     after) becomes a dotted eighth and a sixteenth, or an eighth-note\n--     triplet; a half note, a dotted quarter and an eighth, or a\n--     quarter-note triplet. A tune at an easy pace is mostly quarters and\n--     halves, which the shapes above never touch, so without this the\n--     chords took the figures and the tune hardly did (since 1.4).\n--\n-- Triplet notes fall between the sixteenths, so their steps are fractions\n-- (a third of a beat is 4/3 of a step). Only in metres whose beat is a\n-- quarter note: 6/8 and 12/8 are already in threes, and 7/8 has no beats to\n-- divide. With Plain nothing is drawn, so a 1.0 idea is unchanged.\n------------------------------------------------------------------------------\n\nlocal FIGURES = {\n  Dotted   = { dot = 0.5,  tri = 0,    qdot = 0.45, qtri = 0 },\n  Triplets = { dot = 0,    tri = 0.45, qdot = 0,    qtri = 0.4 },\n  Mixed    = { dot = 0.25, tri = 0.2,  qdot = 0.22, qtri = 0.18 },\n}\n\n-- `onsets` are steps from the start of a cell `len` long that begins\n-- `base` steps into the bar. `tune`: a melody's rhythm, whose quarter\n-- notes take figures too.\nfunction M.figure(meter, base, len, onsets, figures, rnd, tune)\n  local F = FIGURES[figures]\n  if not F or meter.beat ~= 4 then return onsets end\n  local function within(a, b)\n    local o = {}\n    for _, x in ipairs(onsets) do if x >= a and x < b then o[#o + 1] = x end end\n    return o\n  end\n  local function has(x)\n    for _, y in ipairs(onsets) do if y == x then return true end end\n    return false\n  end\n  local b = (4 - base % 4) % 4\n  local out = within(0, b)\n  local function add(...) for _, x in ipairs({ ... }) do out[#out + 1] = x end end\n  while b < len do\n    local step = 4\n    local pair = (b + 8 <= len) and within(b, b + 8) or {}\n    if #pair == 2 and pair[1] == b and pair[2] == b + 4 then\n      local x = rnd()\n      if x < F.tri / 2 then add(b, b + 8 / 3, b + 16 / 3); step = 8\n      elseif x < F.tri / 2 + F.dot then add(b, b + 6); step = 8 end\n    elseif tune and #pair == 1 and pair[1] == b and b + 8 < len and has(b + 8) then\n      -- A half note in the tune.\n      local x = rnd()\n      if x < F.qtri then add(b, b + 8 / 3, b + 16 / 3)\n      elseif x < F.qtri + F.qdot then add(b, b + 6)\n      else add(b) end\n      step = 8\n    end\n    if step == 4 then\n      local beat = within(b, math.min(len, b + 4))\n      if b + 4 <= len and #beat >= 2 and beat[1] == b then\n        local x = rnd()\n        if x < F.tri then add(b, b + 4 / 3, b + 8 / 3)\n        elseif #beat == 2 and beat[2] == b + 2 and x < F.tri + F.dot then add(b, b + 3)\n        else add(table.unpack(beat)) end\n      elseif tune and b + 4 < len and #beat == 1 and beat[1] == b and has(b + 4) then\n        local x = rnd()\n        if x < F.qtri then add(b, b + 4 / 3, b + 8 / 3)\n        elseif x < F.qtri + F.qdot then add(b, b + 3)\n        else add(b) end\n      else\n        add(table.unpack(beat))\n      end\n    end\n    b = b + step\n  end\n  table.sort(out)\n  return out\nend\n\n-- The onsets of a cell `len` steps long starting at `base` in the bar, in\n-- steps from the start of the cell.\n-- The named rhythms (1.11; docs/decisions/0023-chord-styles-and-named-rhythms.md): steps in a bar of 4/4,\n-- as Toussaint writes them over sixteen pulses. Elsewhere they play as\n-- Syncopated.\nM.RHYTHMS = {\n  Tresillo = { 0, 6, 12 },\n  Habanera = { 0, 6, 8, 12 },\n  Clave = { 0, 3, 6, 10, 12 },\n  [\"3+3+3+3+2+2\"] = { 0, 3, 6, 9, 12, 14 },\n}\n-- The named rhythm a groove plays in this metre, or nil.\nfunction M.rhythmOf(meter, groove)\n  local t = M.RHYTHMS[groove]\n  if t and meter.bar == 16 and meter.beat == 4 then return t end\nend\n-- What a named rhythm is to the tune (and elsewhere): syncopated.\nlocal function plainGroove(groove)\n  return M.RHYTHMS[groove] and \"Syncopated\" or groove\nend\nM.plainGroove = plainGroove\n\nfunction M.cell(meter, base, len, pace, groove, rnd, figures)\n  groove = plainGroove(groove)\n  local P = M.PACE[pace] or M.PACE.Flowing\n  local pieces = { { 0, len } }\n  -- Busy and straight rhythms are made a half bar at a time, for variety;\n  -- a syncopation needs the whole bar to spread over (3 in 8 is a tresillo,\n  -- 3 in 4 twice is not).\n  if P.halves and (groove ~= \"Syncopated\" or pace == \"Busy\") and len >= 2 * meter.beat then\n    local h = snap(meter, len / 2)\n    if h > 0 and h < len then pieces = { { 0, h }, { h, len } } end\n  end\n  local out = {}\n  for _, pc in ipairs(pieces) do\n    local slots = (pc[2] - pc[1]) // P.unit\n    if slots >= 1 then\n      local k = math.max(1, math.min(slots, round(slots * between(rnd, P.lo, P.hi))))\n      local pat\n      if groove == \"Syncopated\" and k > 1 and k < slots then\n        pat = syncopated(meter, base + pc[1], P.unit, slots, k, rnd)\n      else\n        pat = strongest(meter, base + pc[1], P.unit, slots, k, rnd)\n      end\n      for _, o in ipairs(pat) do out[#out + 1] = pc[1] + o * P.unit end\n    end\n  end\n  return M.figure(meter, base, len, out, figures, rnd, true)\nend\n\n-- The rhythm of a whole unit: a cell a bar, the first bar's cell often\n-- coming back, so the unit has a rhythm of its own. A unit that closes holds\n-- its last note from the half bar.\nfunction M.unitRhythm(u, meter, r, rnd)\n  local out = {}\n  local cellLen = math.min(meter.bar, u.len)\n  local first\n  local at = 0\n  while at < u.len do\n    local len = math.min(cellLen, u.len - at)\n    local cell\n    if first and len == cellLen and coin(rnd, r.pace == \"Busy\" and 0.5 or 0.6) then cell = first\n    else cell = M.cell(meter, (u.start + at) % meter.bar, len, r.pace, r.groove, rnd, r.figures) end\n    first = first or cell\n    for _, o in ipairs(cell) do out[#out + 1] = at + o end\n    at = at + len\n  end\n  if u.cad ~= \"none\" and u.cad ~= \"open\" then\n    -- The last note lands half way through the last bar, or where the last\n    -- chord arrives if that is later: the tune comes home with the harmony.\n    local region = math.min(meter.bar, u.len)\n    local from = u.len - region\n    local h = from + snap(meter, region / 2)\n    if h >= u.len then h = from end\n    if u.rel and u.rel[#u.rel].s > h and u.rel[#u.rel].s < u.len then h = u.rel[#u.rel].s end\n    local kept = {}\n    for _, o in ipairs(out) do if o < h then kept[#kept + 1] = o end end\n    kept[#kept + 1] = h\n    out = kept\n  end\n  table.sort(out)\n  -- An ending is a note to land on, not the middle of a triplet: a unit\n  -- with a cadence (open ones too) ends on a step of its own.\n  if u.cad ~= \"none\" then\n    while #out > 1 and M.offGrid(out[#out]) do out[#out] = nil end\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- 5. Melody\n--\n-- A walk through scale positions. Each next note is drawn from the notes up\n-- to a sixth either side, weighted:\n--\n--   - by size: a step is most likely, a third about half as likely, leaps\n--     rare (the shape of real melodies: mostly steps);\n--   - toward the contour, a bell curve around where the contour is now;\n--   - on the beat, only chord tones;\n--   - after a leap of a fourth or more, only a step or a third back the\n--     other way (the gap is filled);\n--   - a note off the chord moves on by step (a passing or neighbour note);\n--   - no tritone leaps, no augmented seconds, no note three times running,\n--     and a step back to the note before last only now and then (once is a\n--     neighbour note; again and again is a trill).\n--\n-- A unit that ends on a cadence ends on its goal - the tonic for a full\n-- close, the third or fifth for an imperfect one, a note of the dominant for\n-- a half close - and the note before it is pulled to a step away.\n------------------------------------------------------------------------------\n\nlocal IV_WEIGHT = { [0] = 0.15, [1] = 1, [2] = 0.6, [3] = 0.22, [4] = 0.18, [5] = 0.07 }\nlocal PULL = 2.3   -- how far from the contour a note wanders, in scale steps\n\nlocal CONTOURS = {\n  Arch = function(t)\n    local g = 0.618\n    if t < g then return 0.2 + 0.8 * math.sin(math.pi / 2 * t / g) end\n    return 0.15 + 0.85 * math.cos(math.pi / 2 * (t - g) / (1 - g))\n  end,\n  Valley = function(t)\n    local g = 0.618\n    if t < g then return 0.8 - 0.8 * math.sin(math.pi / 2 * t / g) end\n    return 0.85 * math.sin(math.pi / 2 * (t - g) / (1 - g))\n  end,\n  Rise = function(t) return 0.1 + 0.8 * t end,\n  Fall = function(t) return 0.9 - 0.8 * t end,\n  Wave = function(t) return 0.5 + 0.4 * math.sin(2 * math.pi * 1.5 * t) end,\n}\nM.CONTOURS = CONTOURS\n\nlocal REGISTER = { Low = 55, Middle = 67, High = 76 }\n\n-- The positions a tune may use: about a ninth, centred on the fifth above\n-- the tonic nearest the register. Counted from the tonic rather than from a\n-- pitch, so the same idea in another key is the same tune, moved.\nfunction M.melodyRange(key, register)\n  local n = T.scaleLen(key)\n  local want = (REGISTER[register] or 67) - 7\n  local tonic = math.floor((want - T.rootPc(key)) / 12 + 0.5) * n\n  local centre = tonic + round(n * 4 / 7)\n  local span = n + 2\n  local lo = centre - span // 2\n  return lo, lo + span\nend\n\n-- `key` everywhere below is the scale sounding at that moment\n-- (`M.keyAt`): the key's own, or a borrowed chord's.\nlocal function nearestOn(ctx, key, ch, target, avoid)\n  local best\n  for p = ctx.lo, ctx.hi do\n    if T.onChord(key, ch, p) and p ~= avoid then\n      if not best or math.abs(p - target) < math.abs(best - target) then best = p end\n    end\n  end\n  return best or math.max(ctx.lo, math.min(ctx.hi, round(target)))\nend\n\n-- (1.13) Do three pitches outline a consonant triad - major or minor, in\n-- any position and spacing (E C G is C major)? \"No consecutive leaps in the\n-- same direction\" but where they do (Open Music Theory, \"Composing a cantus\n-- firmus\").\nfunction M.outlinesTriad(a, b, c)\n  local pcs, seen = {}, {}\n  for _, x in ipairs({ a, b, c }) do\n    local pc = x % 12\n    if not seen[pc] then seen[pc] = true; pcs[#pcs + 1] = pc end\n  end\n  if #pcs ~= 3 then return false end\n  for _, root in ipairs(pcs) do\n    for _, third in ipairs({ 3, 4 }) do\n      if seen[(root + third) % 12] and seen[(root + 7) % 12] then return true end\n    end\n  end\n  return false\nend\n\n-- Three notes running (each { pos, pitch, first }): two leaps the same way\n-- that do not outline a triad? Not across a statement's start.\nfunction M.leapsBad(x, y, z)\n  if not (x and y and z) or y.first or z.first then return false end\n  local i1, i2 = y.pos - x.pos, z.pos - y.pos\n  return math.abs(i1) >= 2 and math.abs(i2) >= 2 and i1 * i2 > 0 and not M.outlinesTriad(x.pitch, y.pitch, z.pitch)\nend\n\nlocal function choose(ctx, key, prev, prevIv, prevNct, reps, target, ch, strong, rnd, goal, before)\n  for relax = 0, 2 do\n    local cands, ws = {}, {}\n    for iv = -5, 5 do\n      local p = prev + iv\n      if p >= ctx.lo and p <= ctx.hi then\n        local w = IV_WEIGHT[math.abs(iv)]\n        local on = T.onChord(key, ch, p)\n        if strong and not on then w = 0 end\n        if relax < 2 and prevIv and math.abs(prevIv) >= 3 and (iv * prevIv >= 0 or math.abs(iv) > 2) then w = 0 end\n        -- (A leap after a leap the same way only if the three outline a triad.)\n        if relax < 2 and prevIv and before and math.abs(prevIv) >= 2 and math.abs(iv) >= 2 and iv * prevIv > 0\n           and not M.outlinesTriad(T.pitch(key, before), T.pitch(key, prev), T.pitch(key, p)) then w = 0 end\n        if relax < 1 and prevNct and math.abs(iv) ~= 1 then w = 0 end\n        if iv == 0 and reps >= 1 then w = 0 end\n        if math.abs(iv) >= 2 and not on then w = w * 0.15 end\n        if before and p == before and math.abs(iv) <= 2 then w = w * 0.25 end\n        local semis = math.abs(T.pitch(key, p) - T.pitch(key, prev))\n        if semis == 6 then w = 0 end\n        if math.abs(iv) == 1 and semis == 3 then w = 0 end\n        local d = p - target\n        w = w * math.exp(-(d * d) / (2 * PULL * PULL))\n        if goal then\n          if math.abs(T.pitch(key, p) - T.pitch(key, goal)) == 6 then w = 0 end\n          local g = math.abs(p - goal)\n          w = w * ((g == 1 and 4) or (g == 2 and 1.5) or (g == 0 and 0.3) or 0.2)\n        end\n        if w > 0 then cands[#cands + 1] = p; ws[#ws + 1] = w end\n      end\n    end\n    if #cands > 0 then return weighted(rnd, cands, ws) end\n  end\n  return nearestOn(ctx, key, ch, target)\nend\n\n-- Where a closing unit lands: its last note, at `step`.\nlocal function goalFor(ctx, u, prev, target, step)\n  local key = M.keyAt(ctx, step)\n  local n = T.scaleLen(key)\n  local ch = M.chordAt(ctx.timeline, step).chord\n  -- (The tonic of the key sounding there: after a key change, 1.12, the new\n  -- one's.)\n  local tonic = T.chord(key, 0, \"Triads\")\n  local ok\n  -- (A close whose chord is not the tonic - the blues, which plays its own\n  -- changes bar by bar - lands on a note of the chord it has.)\n  local home = ch.rootPc == tonic.rootPc\n  if u.cad == \"PAC\" and home then ok = function(p) return p % n == 0 end\n  elseif u.cad == \"IAC\" and home then ok = function(p) return T.onChord(key, tonic, p) and p % n ~= 0 end\n  elseif u.cad == \"HC\" or u.cad == \"PAC\" or u.cad == \"IAC\" then ok = function(p) return T.onChord(key, ch, p) end\n  elseif u.cad == \"EC\" then\n    -- An evaded close (1.13): the leading note does not resolve - the tune\n    -- leaps up instead, to a note of the chord that is not do.\n    local best, bestCost\n    for p = ctx.lo - 2, ctx.hi + 2 do\n      if T.onChord(key, ch, p) and p % n ~= 0 then\n        local up = T.pitch(key, p) - T.pitch(key, prev)\n        local cost = math.abs(p - target) * 0.4 + ((up >= 5 and up <= 9) and 0 or (up > 9 and up <= 12) and 3 or 40)\n        if up ~= 6 and (not bestCost or cost < bestCost) then best, bestCost = p, cost end\n      end\n    end\n    return best\n  elseif u.cad == \"DC\" then\n    -- The tune lands where the tonic was due - do, which vi also has - and\n    -- the harmony goes elsewhere under it.\n    ok = function(p) return T.onChord(key, ch, p) end\n    local okBase = ok\n    local best, bestCost\n    for p = ctx.lo - 2, ctx.hi + 2 do\n      if okBase(p) then\n        local cost = math.abs(p - prev) + 0.4 * math.abs(p - target) + ((p % n == 0) and 0 or 3)\n        if not bestCost or cost < bestCost then best, bestCost = p, cost end\n      end\n    end\n    return best\n  elseif u.cad == \"open\" then\n    -- Back toward where the idea started, without landing on it, so it\n    -- loops.\n    target = ctx.firstPos or target\n    ok = function(p) return T.onChord(key, ch, p) and p ~= ctx.firstPos end\n  else return nil end\n  local best, bestCost\n  for p = ctx.lo - 2, ctx.hi + 2 do\n    if ok(p) then\n      local cost = math.abs(p - prev) + 0.4 * math.abs(p - target)\n      if not bestCost or cost < bestCost then best, bestCost = p, cost end\n    end\n  end\n  return best\nend\n\n-- New notes for a unit at the given onsets (steps from the unit's start).\n-- (1.16) A named schema's tune: the stage a step falls in, if its chord\n-- names a degree to sing there (`spec.sing`, a degree or a list of two for\n-- a chord holding two stages), as { at = where the stage starts, degree }.\nlocal function stageAt(ctx, sl, step)\n  local sing = sl.spec and sl.spec.sing\n  if not sing then return nil end\n  if type(sing) == \"number\" then return { at = sl.s, degree = sing, key = sl } end\n  local mid = sl.s + snap(ctx.meter, (sl.e - sl.s) / 2)\n  if step < mid or mid <= sl.s then return { at = sl.s, degree = sing[1], key = sl } end\n  return { at = mid, degree = sing[2], key = sl, second = true }\nend\n\n-- The note a stage sings: that degree, a note of the chord, the nearest to\n-- the note before (within a fifth, no tritone, no augmented second, not a\n-- third time), or nil.\nlocal function singNote(ctx, key, ch, prev, reps, degree, target)\n  local want = T.pc(key, degree)\n  local best, bestCost\n  for p = ctx.lo, ctx.hi do\n    if T.pc(key, p) == want and T.onChord(key, ch, p) then\n      local ok = true\n      if prev then\n        local iv = p - prev\n        local semis = math.abs(T.pitch(key, p) - T.pitch(key, prev))\n        if math.abs(iv) > 4 or semis == 6 or (math.abs(iv) == 1 and semis == 3) or (iv == 0 and reps >= 1) then ok = false end\n      end\n      if ok then\n        local cost = (prev and math.abs(p - prev) or 0) * 10 + math.abs(p - target)\n        if not bestCost or cost < bestCost then best, bestCost = p, cost end\n      end\n    end\n  end\n  return best\nend\n\nlocal function walkUnit(ctx, u, onsets, rnd, state)\n  local out = {}\n  state.sung = state.sung or {}\n  local reps = state.reps or 0\n  local closing = u.cad ~= \"none\"\n  for i, o in ipairs(onsets) do\n    local step = u.start + o\n    local sl = M.chordAt(ctx.timeline, step)\n    local ch = sl.chord\n    local key = sl.key or ctx.key\n    local strong = M.strength(ctx.meter, step) >= 2 or i == 1\n    local target = ctx.target(step)\n    local p\n    -- (1.16) The first note of a schema's stage sings its degree.\n    local stage = stageAt(ctx, sl, step)\n    local sing\n    if stage and step >= stage.at and not (closing and i >= #onsets - 1) then\n      local id = tostring(sl) .. (stage.second and \"b\" or \"a\")\n      if not state.sung[id] then\n        state.sung[id] = true\n        sing = singNote(ctx, key, ch, state.prev, reps, stage.degree, target)\n      end\n    end\n    if sing then\n      p = sing\n      if not state.prev then ctx.firstPos = p end\n    elseif not state.prev then\n      p = nearestOn(ctx, key, ch, target)\n      ctx.firstPos = p\n    elseif closing and i == #onsets then\n      p = goalFor(ctx, u, state.prev, target, step) or choose(ctx, key, state.prev, state.iv, state.nct, reps, target, ch, true, rnd)\n    elseif closing and i == #onsets - 1 then\n      local goal = goalFor(ctx, u, state.prev, target, u.start + onsets[#onsets])\n      p = choose(ctx, key, state.prev, state.iv, state.nct, reps, goal or target, ch, strong, rnd, goal, state.before)\n    else\n      p = choose(ctx, key, state.prev, state.iv, state.nct, reps, target, ch, strong, rnd, nil, state.before)\n    end\n    state.before = state.prev\n    if state.prev then\n      state.iv = p - state.prev\n      reps = (p == state.prev) and reps + 1 or 0\n      state.reps = reps\n    end\n    state.prev = p\n    state.nct = not T.onChord(key, ch, p)\n    out[#out + 1] = { at = o, pos = p }\n  end\n  return out\nend\n\n-- Notes copied from another unit, moved to this one's start, shifted by\n-- `shift` scale steps.\nlocal function copyNotes(src, from, to, shift)\n  local out = {}\n  for _, nt in ipairs(src.notes) do\n    if nt.at >= from and nt.at < to then out[#out + 1] = { at = nt.at - from, pos = nt.pos + (shift or 0) } end\n  end\n  return out\nend\n\n-- A statement moved onto new chords keeps its shape: the notes on the beat\n-- that are not on the chord now go to the nearest chord tone, the rest stay.\n-- With `ending`, the last note counts as on the beat too: it is the\n-- unit's ending (an exact repeat of a unit that closes).\nlocal function fit(ctx, u, notes, ending)\n  local sung = {}\n  for i, nt in ipairs(notes) do\n    local step = u.start + nt.at\n    -- (1.16) A copied tune sings a schema's stage too: its first note there\n    -- moves to the stage's degree, the nearest within a fifth - but for a\n    -- close's last two notes, which go where the close goes.\n    local sl = M.chordAt(ctx.timeline, step)\n    local stage = stageAt(ctx, sl, step)\n    if stage and step >= stage.at and not (ending and u.cad ~= \"none\" and i >= #notes - 1) then\n      local id = tostring(sl) .. (stage.second and \"b\" or \"a\")\n      if not sung[id] then\n        sung[id] = true\n        local key = M.keyAt(ctx, step)\n        local want = T.pc(key, stage.degree)\n        if T.pc(key, nt.pos) ~= want then\n          for d = 1, 4 do\n            local hit\n            for _, q in ipairs({ nt.pos - d, nt.pos + d }) do\n              if not hit and q >= ctx.lo and q <= ctx.hi and T.pc(key, q) == want and T.onChord(key, sl.chord, q) then hit = q end\n            end\n            if hit then nt.pos = hit; break end\n          end\n        end\n      end\n    end\n    if M.strength(ctx.meter, step) >= 2 or (ending and i == #notes and u.cad ~= \"none\") then\n      local ch = M.chordAt(ctx.timeline, step).chord\n      local key = M.keyAt(ctx, step)\n      if not T.onChord(key, ch, nt.pos) then\n        -- (Within an octave and more either way; a chord always has a note\n        -- there in its own scale, but a search must end.)\n        local up, down = nt.pos + 1, nt.pos - 1\n        while not T.onChord(key, ch, up) and up < nt.pos + 15 do up = up + 1 end\n        while not T.onChord(key, ch, down) and down > nt.pos - 15 do down = down - 1 end\n        if T.onChord(key, ch, up) or T.onChord(key, ch, down) then\n          nt.pos = (T.onChord(key, ch, up) and (not T.onChord(key, ch, down) or up - nt.pos <= nt.pos - down)) and up or down\n        end\n      end\n    end\n  end\n  return notes\nend\n\n-- The shift (of `shift` or an octave either side of it) that keeps a\n-- statement in range and nearest the note before.\nlocal function bestShift(ctx, src, from, to, shift, prev)\n  local n = T.scaleLen(ctx.key)\n  local best, bestCost\n  for _, s in ipairs({ shift, shift - n, shift + n }) do\n    local notes = copyNotes(src, from, to, s)\n    if #notes > 0 then\n      -- Out of range costs by how far out, so if every choice is out, the\n      -- least out wins.\n      local over = 0\n      for _, nt in ipairs(notes) do\n        over = math.max(over, ctx.lo - 1 - nt.pos, nt.pos - ctx.hi - 1)\n      end\n      local cost = over * 100 + (prev and math.abs(notes[1].pos - prev) or 0)\n      if not bestCost or cost < bestCost then best, bestCost = s, cost end\n    end\n  end\n  return best or shift\nend\n\nfunction M.melody(plan, ctx, r, rnd)\n  local state = {}\n  local units = plan.units\n  for _, u in ipairs(units) do\n    local src = u.of and units[u.of]\n    local notes\n    local same = src and src.len == u.len and src.cad == u.cad\n    if u.kind == \"repeat\" and same then\n      -- (Fitted too: the chords are the same degrees, but a borrowed chord\n      -- or a push may have come to one pass and not the other.)\n      notes = fit(ctx, u, copyNotes(src, 0, u.len, 0), true)\n    elseif u.kind == \"seq\" and same and u.cad == \"none\" then\n      local s = bestShift(ctx, src, 0, u.len, u.shift, state.prev)\n      notes = fit(ctx, u, copyNotes(src, 0, u.len, s))\n    elseif src and u.kind ~= \"frag\" then\n      -- The source's first half (moved, for a sequence), then a new second\n      -- half to this unit's own ending. An answer to the same ending (a loop\n      -- going round again) keeps the chords but still answers in the tune.\n      local cut = M.cutFor(ctx.meter, src, u)\n      local s = (u.kind == \"seq\") and bestShift(ctx, src, 0, cut, u.shift, state.prev) or 0\n      notes = fit(ctx, u, copyNotes(src, 0, cut, s))\n      if #notes > 0 then\n        state.prev = notes[#notes].pos\n        state.iv = #notes > 1 and (notes[#notes].pos - notes[#notes - 1].pos) or nil\n        state.nct = false\n      end\n      local rh = M.unitRhythm(u, ctx.meter, r, ctx.rhythmRnd)\n      local rest = {}\n      for _, o in ipairs(rh) do if o >= cut then rest[#rest + 1] = o - cut end end\n      if #rest == 0 then rest = { 0 } end\n      local tail = { start = u.start + cut, len = u.len - cut, cad = u.cad, slots = u.slots }\n      for _, nt in ipairs(walkUnit(ctx, tail, rest, rnd, state)) do\n        notes[#notes + 1] = { at = nt.at + cut, pos = nt.pos }\n      end\n    elseif u.kind == \"frag\" then\n      -- The basic idea's first half, again and again, each a step lower.\n      local basic = units[1]\n      local half = snap(ctx.meter, basic.len / 2)\n      if half <= 0 then half = basic.len end\n      notes = {}\n      local at, k = 0, 0\n      while at < u.len do\n        local s = bestShift(ctx, basic, 0, half, -k, state.prev)\n        for j, nt in ipairs(copyNotes(basic, 0, math.min(half, u.len - at), s)) do\n          -- Each fragment is a statement of its own.\n          notes[#notes + 1] = { at = nt.at + at, pos = nt.pos, fresh = (j == 1) }\n        end\n        if #notes > 0 then state.prev = notes[#notes].pos end\n        at, k = at + half, k + 1\n      end\n      notes = fit(ctx, u, notes)\n    else\n      notes = walkUnit(ctx, u, M.unitRhythm(u, ctx.meter, r, ctx.rhythmRnd), rnd, state)\n    end\n    u.notes = notes\n    if #notes > 0 then\n      state.prev = notes[#notes].pos\n      state.iv = #notes > 1 and (notes[#notes].pos - notes[#notes - 1].pos) or state.iv\n      local at = u.start + notes[#notes].at\n      state.nct = not T.onChord(M.keyAt(ctx, at), M.chordAt(ctx.timeline, at).chord, notes[#notes].pos)\n    end\n  end\n\n  -- Into the timeline: each note lasts until the next (never longer than a\n  -- half note, unless it is the last of its unit, which is held).\n  local all = {}\n  -- (Where each note came from: an exact repeat's notes are its source's,\n  -- so a tension decided once comes round again.)\n  local origin = {}\n  for ui, u in ipairs(units) do\n    local src = u.of and units[u.of]\n    origin[ui] = (u.kind == \"repeat\" and src and src.len == u.len and src.cad == u.cad) and origin[u.of] or ui\n  end\n  for ui, u in ipairs(units) do\n    for i, nt in ipairs(u.notes) do\n      all[#all + 1] = { order = #all, step = u.start + nt.at, pos = nt.pos, last = (i == #u.notes),\n                        from = origin[ui] .. \":\" .. nt.at,\n                        closes = (i == #u.notes) and u.cad ~= \"none\" and u.cad,\n                        unitEnd = u.start + u.len, first = (i == 1) or nt.fresh or false }\n    end\n  end\n  table.sort(all, function(a, b)\n    if a.step ~= b.step then return a.step < b.step end\n    return a.order < b.order\n  end)\n  -- Two notes on one step (a copied cell meeting the next unit): keep the later.\n  local notes = {}\n  for i, nt in ipairs(all) do\n    if not all[i + 1] or all[i + 1].step ~= nt.step then notes[#notes + 1] = nt end\n  end\n  notes = M.wholeTriplets(notes)\n  M.untangle(ctx, notes)\n  -- A pushed chord takes the tune's note on its beat with it, an eighth\n  -- early - as long as nothing else is sounding in that eighth, and the\n  -- note does not begin a triplet (which would leave the other two behind).\n  for _, sl in ipairs(ctx.timeline) do\n    if sl.pushed then\n      for i, nt in ipairs(notes) do\n        local before, after = notes[i - 1], notes[i + 1]\n        if nt.step == sl.s + 2 and i > 1 and before.step < sl.s and not (after and M.offGrid(after.step)) then\n          nt.step, nt.pushed = sl.s, true\n        end\n      end\n    end\n  end\n  if ctx.bassPcAt then M.noParallels(ctx, notes, ctx.bassPcAt) end\n  notes = M.tension(ctx, notes, r, ctx.tensionRnd, plan.total)\n  for i, nt in ipairs(notes) do\n    local nextStep = notes[i + 1] and notes[i + 1].step or plan.total\n    local len = nextStep - nt.step\n    if not nt.last and not nt.held then len = math.min(len, 8) end\n    nt.len = math.max(1, len)\n    nt.pitch = T.pitch(M.keyAt(ctx, nt.step), nt.pos)\n    nt.accent = nt.first or nt.pushed or nt.step % ctx.meter.bar == 0\n  end\n  -- (What each dissonance falls to: the note after it.)\n  for i, nt in ipairs(notes) do\n    if nt.dissonance and notes[i + 1] then\n      nt.dissonance.res = notes[i + 1].pitch % 12\n      nt.dissonance.root = M.chordAt(ctx.timeline, nt.dissonance.s).chord.rootPc\n    end\n  end\n  return notes\nend\n\n------------------------------------------------------------------------------\n-- Tension (1.10; docs/decisions/0022-tension-and-a-second-voice.md)\n--\n-- The accented non-chord tones the books teach\n-- (Hutchinson, ch. 10; Open Music Theory, \"Embellishing tones\"):\n--\n--   - a suspension: the note before a chord change, a step above a note of\n--     the new chord, is held over the change and falls to it - prepared,\n--     dissonant on the beat, resolved down a step (4-3, 9-8, 7-6);\n--   - an appoggiatura: on the beat, a note a step above the chord's note,\n--     leapt up to, falling to it;\n--   - an anticipation: a close's last note arriving an eighth early, over\n--     the chord before, and struck again on the beat.\n--\n-- The note on the beat must last a quarter (in 4/4) or more, so the\n-- dissonance can have its eighth (or quarter) and the chord's note the\n-- rest; the chord must stay put until then. Never a minor ninth against the\n-- bass, nor a note that falls onto the bass's own note but for the root\n-- (the 9-8). Never on a pushed note, in a triplet, or on a close's goal\n-- (but for the anticipation, which is the goal early). An exact repeat does\n-- what its source did, and draws nothing.\n------------------------------------------------------------------------------\n\n-- (The suspension needs the tune to step down over a chord change, which\n-- is rarer than a leap up to a beat, so it is taken more often when it can be.)\nM.TENSION_CHANCE = { Rare = 0.1, Common = 0.25 }\nM.SUSPEND_CHANCE = { Rare = 0.35, Common = 0.7 }\nM.ANTICIPATE_CHANCE = { Rare = 0.25, Common = 0.5 }\n\nfunction M.tension(ctx, notes, r, rnd, total)\n  local chance = M.TENSION_CHANCE[r.tension]\n  if not chance or not rnd then return notes end\n  local meter = ctx.meter\n  local function P(step, pos) return T.pitch(M.keyAt(ctx, step), pos) end\n  local function chordOf(step) return M.chordAt(ctx.timeline, step) end\n  -- (By the book, the bass the tune keeps clear of; free, the chord's root,\n  -- so an inversion still leaves the tune alone.)\n  local function bassAt(step)\n    if ctx.bassPcAt then return ctx.bassPcAt(step) end\n    local sl = chordOf(step)\n    return sl and sl.chord.rootPc\n  end\n  -- The dissonance at `step` (pitch `d`) falling to `res` (a note of the\n  -- chord there, pitch `rp`): not a minor ninth on the bass, and not onto\n  -- the bass's own note unless it is the root.\n  local function againstBass(step, d, rp)\n    local b = bassAt(step)\n    if not b then return true end\n    local sl = chordOf(step)\n    if (d - b) % 12 == 1 then return false end\n    if rp % 12 == b and b ~= sl.chord.rootPc then return false end\n    return true\n  end\n  local decided = {}\n  local out = {}\n  local i = 1\n  while i <= #notes do\n    local a, b, c = out[#out], notes[i], notes[i + 1]\n    local nextStep = c and c.step or total\n    local len = nextStep - b.step\n    local strong = not M.offGrid(b.step) and M.strength(meter, b.step) >= 2\n    local kind\n    if a and strong and not b.pushed and not M.offGrid(a.step) and not (c and M.offGrid(c.step)) then\n      local was = decided[b.from]\n      local x = (was == nil) and rnd() or nil\n      local sl = chordOf(b.step)\n      local delay = (len >= 8) and 4 or 2\n      local still = len >= 4 and chordOf(b.step + delay) == sl\n      local key = M.keyAt(ctx, b.step)\n      local onIt = T.onChord(key, sl.chord, b.pos)\n      local goal = b.closes == \"PAC\" or b.closes == \"IAC\" or b.closes == \"DC\" or b.closes == \"EC\"\n      local pa, pb = P(a.step, a.pos), P(b.step, b.pos)\n      -- By the book, no parallels with the bass from the notes in their new\n      -- places: a suspension does not hide parallel octaves (C held over\n      -- into Bb and falling to it, the bass C to Bb), nor a pulled chord's\n      -- bass under a late resolution.\n      local late = { step = b.step + delay, pos = b.pos }\n      local function clear(list)\n        if not ctx.bassPcAt then return true end\n        for k = 2, #list do\n          if list[k - 1] and list[k] and M.parallel(ctx, ctx.bassPcAt, list[k - 1], nil, list[k], nil) then return false end\n        end\n        return true\n      end\n      -- An anticipation: a close's goal, an eighth early.\n      local antic = b.closes and b.last and pa ~= pb and not (c and P(c.step, c.pos) == pb)\n                    and b.step - 2 > a.step and P(b.step - 2, b.pos) == pb\n                    and not M.offGrid(b.step - 2) and M.strength(meter, b.step - 2) < 2\n                    and clear({ a, { step = b.step - 2, pos = b.pos } })\n                    and not M.leapsBad(out[#out - 1] and { pos = out[#out - 1].pos, pitch = P(out[#out - 1].step, out[#out - 1].pos), first = out[#out - 1].first },\n                                       { pos = a.pos, pitch = pa, first = a.first }, { pos = b.pos, pitch = pb })\n      -- A suspension: the note before, a step above, held over a change.\n      local before = chordOf(a.step)\n      local sus = not goal and still and onIt and before ~= sl and a.pos == b.pos + 1\n                  and P(b.step, a.pos) == pa and not T.onChord(key, sl.chord, a.pos)\n                  and T.onChord(M.keyAt(ctx, a.step), before.chord, a.pos)\n                  and againstBass(b.step, pa, pb) and againstBass(b.step + delay - 1e-3, pa, pb) and againstBass(b.step + delay, pa, pb)\n                  and clear({ a, late, c })\n      -- An appoggiatura: leapt up to, a step above the chord's note.\n      local app = b.pos + 1\n      local pApp = P(b.step, app)\n      local appo = not goal and still and onIt and a.pos <= app - 2 and app <= ctx.hi + 1\n                   and not T.onChord(key, sl.chord, app) and math.abs(pApp - pa) ~= 6\n                   and math.abs(pApp - pa) <= 12 and againstBass(b.step, pApp, pb)\n                   and againstBass(b.step + delay - 1e-3, pApp, pb) and againstBass(b.step + delay, pApp, pb)\n                   and clear({ a, { step = b.step, pos = app }, late, c })\n                   and not M.leapsBad(out[#out - 1] and { pos = out[#out - 1].pos, pitch = P(out[#out - 1].step, out[#out - 1].pos), first = out[#out - 1].first },\n                                      { pos = a.pos, pitch = pa, first = a.first }, { pos = app, pitch = pApp })\n      if was ~= nil then\n        kind = (was == \"anticipation\" and antic and was) or (was == \"suspension\" and sus and was)\n               or (was == \"appoggiatura\" and appo and was) or nil\n      elseif antic and x < M.ANTICIPATE_CHANCE[r.tension] then kind = \"anticipation\"\n      elseif sus and x < M.SUSPEND_CHANCE[r.tension] then kind = \"suspension\"\n      elseif appo and x < chance then kind = \"appoggiatura\" end\n      if was == nil then decided[b.from] = kind or false end\n      if kind == \"anticipation\" then\n        out[#out + 1] = { step = b.step - 2, pos = b.pos, tension = \"anticipation\", from = b.from .. \"^\" }\n      elseif kind == \"suspension\" then\n        -- (The note before rings on over the change; the chord's note comes\n        -- in late.)\n        a.held, a.tension = true, \"suspension\"\n        a.dissonance = { s = b.step, e = b.step + delay }\n        b.step, b.resolves = b.step + delay, true\n      elseif kind == \"appoggiatura\" then\n        out[#out + 1] = { step = b.step, pos = app, tension = \"appoggiatura\", first = b.first, from = b.from .. \"^\",\n                          dissonance = { s = b.step, e = b.step + delay } }\n        b.first = false\n        b.step, b.resolves = b.step + delay, true\n      end\n    elseif decided[b.from] == nil then\n      -- (Nothing can lean here - the idea's first note, say - so nothing\n      -- does when it comes round again either.)\n      decided[b.from] = false\n    end\n    out[#out + 1] = b\n    i = i + 1\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- The second voice (1.10): the tune harmonised a third or a sixth under -\n-- \"melodies in octaves, double octaves, in thirds and sixths\"\n-- (Rimsky-Korsakov), \"parallel doubling in thirds or sixths, adjusted to\n-- the harmony\" (Belkin). Each note of the tune gets one under it, in the\n-- scale sounding then: on the beat a note of the chord (the third or sixth\n-- if it is one, else a fourth, else the nearest note of the chord a third\n-- to a sixth under, a fifth at the last), off the beat the interval as it\n-- comes. Under a tension note it moves with the tune.\n------------------------------------------------------------------------------\n\nM.SECOND = { Thirds = { -2, -3, -5 }, Sixths = { -5, -2, -3 } }\nlocal SWEET = { [3] = true, [4] = true, [5] = true, [8] = true, [9] = true }\n\nfunction M.secondVoice(ctx, melody, r)\n  local order = M.SECOND[r.secondVoice]\n  if not order then return nil end\n  local out = {}\n  for _, nt in ipairs(melody) do\n    local key = M.keyAt(ctx, nt.step)\n    local ch = M.chordAt(ctx.timeline, nt.step).chord\n    local strong = not M.offGrid(nt.step) and M.strength(ctx.meter, nt.step) >= 2\n    local free = not strong or nt.tension\n    local function gap(p) return nt.pitch - T.pitch(key, p) end\n    local pick\n    for _, d in ipairs(order) do\n      local p = nt.pos + d\n      if SWEET[gap(p)] and (free or T.onChord(key, ch, p)) then pick = p; break end\n    end\n    if not pick then\n      for _, want in ipairs({ SWEET, { [7] = true } }) do\n        for p = nt.pos - 1, nt.pos - 6, -1 do\n          if not pick and want[gap(p)] and T.onChord(key, ch, p) then pick = p end\n        end\n      end\n    end\n    -- (Where no note of the chord is consonant under it - fi over an\n    -- Italian sixth has only the augmented sixth and the tritone, 1.15 - a\n    -- consonant note of the scale.)\n    if not pick then\n      for p = nt.pos - 1, nt.pos - 6, -1 do\n        if not pick and SWEET[gap(p)] then pick = p end\n      end\n    end\n    pick = pick or (nt.pos + order[1])\n    out[#out + 1] = { step = nt.step, len = nt.len, pos = pick, pitch = T.pitch(key, pick), accent = nt.accent }\n  end\n  return out\nend\n\n-- Is a step between the sixteenths (part of a triplet)?\nfunction M.offGrid(step) return math.abs(step - math.floor(step + 0.5)) > 1e-6 end\n\n-- Every triplet in the tune whole. Copying half a statement, holding a\n-- closing note, or cutting at a cadence can take the end off a triplet\n-- that began before it; what is left is not a triplet but a stumble. So a\n-- note between the sixteenths stays only if it is one of a whole\n-- eighth-note triplet (three in a beat) or quarter-note triplet (three in\n-- two beats) starting on a beat; otherwise it goes, and the note before it\n-- simply lasts longer.\nfunction M.wholeTriplets(notes)\n  local at = {}\n  local function key(x) return (\"%.4f\"):format(x) end\n  for _, n in ipairs(notes) do at[key(n.step)] = true end\n  local function has(x) return at[key(x)] end\n  local out = {}\n  for _, n in ipairs(notes) do\n    local keep = not M.offGrid(n.step)\n    if not keep then\n      for _, span in ipairs({ 4 / 3, 8 / 3 }) do\n        for k = 1, 2 do\n          local g = n.step - k * span\n          if not M.offGrid(g / 4) and has(g) and has(g + span) and has(g + 2 * span) then keep = true end\n        end\n      end\n    end\n    if keep then out[#out + 1] = n end\n  end\n  return out\nend\n\n-- The last pass over the whole tune. Copying a statement onto new chords\n-- can land two or three of its notes on the same chord tone, and a copy can\n-- start a tritone, or more than an octave, from where the tune was. So:\n--\n--   - a note that would be the third the same in a row moves;\n--   - a note a tritone from the one before moves - or, if it cannot (or it\n--     is the last note, which stays put), the one before it does;\n--   - a leap of more than an octave inside a statement is brought an\n--     octave closer.\n--\n-- A note on the beat moves to another chord tone, one off the beat to the\n-- note a step away - whichever is nearest, in range, and makes no tritone\n-- with either neighbour.\nfunction M.untangle(ctx, notes)\n  local n = T.scaleLen(ctx.key)\n  -- A note's pitch at a position, read in the scale sounding at its step.\n  local function P(note, pos) return T.pitch(M.keyAt(ctx, note.step), pos or note.pos) end\n  local function apart(x, px, y, py) return math.abs(P(x, px) - P(y, py)) end\n  local NEAR, WIDE = { 1, -1, 2, -2, 3, -3, 4, -4 }, { 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6 }\n  -- `wide` looks further, and a little outside the range, when nothing\n  -- near will do.\n  local function move(i, strict, wide)\n    local a, b, c = notes[i - 1], notes[i], notes[i + 1]\n    if not b then return false end\n    local ch = M.chordAt(ctx.timeline, b.step).chord\n    local key = M.keyAt(ctx, b.step)\n    local strong = M.strength(ctx.meter, b.step) >= 2\n    local slack = wide and 3 or 1\n    for _, d in ipairs(wide and WIDE or NEAR) do\n      local p = b.pos + d\n      local inRange = p >= ctx.lo - slack and p <= ctx.hi + slack\n      local fits = (strong and T.onChord(key, ch, p)) or (not strong and (math.abs(d) == 1 or wide))\n      local clash = strict and ((a and apart(a, nil, b, p) == 6) or (c and apart(b, p, c, nil) == 6))\n      -- A repeat is fine; three of a kind is not.\n      local z, y = notes[i - 2], notes[i + 2]\n      local same = function(x) return x and apart(x, nil, b, p) == 0 end\n      local triple = (same(a) and same(z)) or (same(a) and same(c)) or (same(c) and same(y))\n      -- (Nor two leaps the same way that outline no triad.)\n      local function at(x, pos) return x and { pos = pos or x.pos, pitch = P(x, pos), first = x.first } end\n      local nb = at(b, p)\n      local leaps = strict and (M.leapsBad(at(z), at(a), nb) or M.leapsBad(at(a), nb, at(c)) or M.leapsBad(nb, at(c), at(y)))\n      -- (Nor a leap wider than an octave inside a statement.)\n      local wide12 = (a and not b.first and apart(a, nil, b, p) > 12) or (c and not c.first and apart(b, p, c, nil) > 12)\n      if fits and inRange and not clash and not triple and not leaps and not wide12 and p ~= b.pos then\n        b.pos = p\n        return true\n      end\n    end\n    return false\n  end\n  local function tryMove(i, allowTritone)\n    return move(i, true, false) or move(i, true, true) or (allowTritone and move(i, false, true))\n  end\n  -- Twice over, so a note moved to mend one thing is checked again.\n  for _ = 1, 2 do\n    for i = 2, #notes do\n      local a, b, c = notes[i - 1], notes[i], notes[i + 1]\n      if c and P(a) == P(b) and P(b) == P(c) then\n        -- (In the diminished and whole-tone scales every way out may be a\n        -- tritone; a tritone is better there than a note three times.)\n        tryMove(i, true)\n      end\n      if apart(a, nil, b, nil) == 6 then\n        if i == #notes or not tryMove(i, false) then tryMove(i - 1, false) end\n      end\n      if not b.first and apart(a, nil, b, nil) > 12 then\n        local p = b.pos + ((a.pos > b.pos) and n or -n)\n        if apart(a, nil, b, p) ~= 6 and not (c and apart(b, p, c, nil) == 6)\n           and p >= ctx.lo - 3 and p <= ctx.hi + 3 then b.pos = p end\n      end\n      -- Two leaps the same way that outline no triad (after the octave fix,\n      -- which can make one): the middle note moves, or the last, or the first.\n      local function at(x) return x and { pos = x.pos, pitch = P(x), first = x.first } end\n      if c and M.leapsBad(at(a), at(b), at(c)) then\n        -- (Not a close's goal, nor the idea's last note: they stay.)\n        local function free(k)\n          local x = notes[k]\n          return x and k < #notes and not (x.closes == \"PAC\" or x.closes == \"IAC\" or x.closes == \"DC\" or x.closes == \"EC\")\n        end\n        if not ((free(i) and tryMove(i, false)) or (free(i + 1) and tryMove(i + 1, false)))\n           and not a.first and free(i - 1) then tryMove(i - 1, false) end\n      end\n    end\n  end\nend\n\n-- By the book (1.7): no parallel fifths or octaves between the tune and\n-- the bass - the outer voices, where the books are strictest (Hutchinson,\n-- ch. 26; Open Music Theory, first-species counterpoint and basso\n-- continuo). Two notes running in which both the tune and the bass move,\n-- and stand a fifth (or an octave, or a unison) apart both times, contrary\n-- motion included. `bassPcAt(step)` is the bass sounding at a step.\n--\n-- Of the two, the later note moves (a full or imperfect close's last note\n-- stays; the idea's first note moves only as a last resort); failing that, the earlier one. A note on\n-- the beat moves to another chord tone, one off it a step - whichever is\n-- nearest and keeps every rule `untangle` keeps.\nfunction M.parallel(ctx, bassPcAt, a, ap, b, bp)\n  local ba, bb = bassPcAt(a.step), bassPcAt(b.step)\n  if not ba or not bb or ba == bb then return false end\n  local pa, pb = T.pitch(M.keyAt(ctx, a.step), ap or a.pos), T.pitch(M.keyAt(ctx, b.step), bp or b.pos)\n  if pa == pb then return false end\n  local ia, ib = (pa - ba) % 12, (pb - bb) % 12\n  return ia == ib and (ia == 0 or ia == 7)\nend\n\nfunction M.noParallels(ctx, notes, bassPcAt)\n  local function P(note, pos) return T.pitch(M.keyAt(ctx, note.step), pos or note.pos) end\n  local function try(i, wide, first, iac)\n    local a, b, c = notes[i - 1], notes[i], notes[i + 1]\n    -- (A full or imperfect close's last note is its goal and stays; a half\n    -- close's or an open ending's may move to another note of its chord.\n    -- As a last resort, `iac`, an imperfect close's goal may move between\n    -- the tonic's third and fifth: the same close. 1.13.)\n    local goal = b and (b.closes == \"PAC\" or b.closes == \"IAC\" or b.closes == \"DC\" or b.closes == \"EC\")\n    if b and iac then goal = b.closes ~= \"IAC\" end\n    if not b or goal or (i == 1 and not first) or (i == #notes and not b.closes) then return false end\n    local ch = M.chordAt(ctx.timeline, b.step).chord\n    local key = M.keyAt(ctx, b.step)\n    local strong = M.strength(ctx.meter, b.step) >= 2 or b.closes\n    -- (`wide` looks further, and a little further outside the range, when\n    -- nothing near will do.)\n    local slack = wide and 3 or 1\n    for _, d in ipairs(wide and { 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6 } or { 1, -1, 2, -2, 3, -3, 4, -4 }) do\n      local p = b.pos + d\n      local fits = (strong and T.onChord(key, ch, p)) or (not strong and (math.abs(d) == 1 or wide))\n      if iac then fits = T.onChord(key, T.chord(key, 0, \"Triads\"), p) and p % T.scaleLen(key) ~= 0 end\n      local good = fits and p >= ctx.lo - slack and p <= ctx.hi + slack\n      if good then\n        local pp = P(b, p)\n        -- (Not ipairs: with no note before, `a` is nil and ipairs would stop.)\n        for k = 1, 2 do\n          local x = (k == 1) and a or c\n          if x then\n            local gap = math.abs(P(x) - pp)\n            if gap == 6 or (gap > 12 and not (x == c and c.first) and not (x == a and b.first)) then good = false end\n          end\n        end\n        local z, y = notes[i - 2], notes[i + 2]\n        if (z and a and P(z) == P(a) and P(a) == pp) or (c and y and P(c) == pp and P(y) == pp)\n           or (a and c and P(a) == pp and P(c) == pp) then good = false end\n        if good and a and M.parallel(ctx, bassPcAt, a, nil, b, p) then good = false end\n        -- (Nor two leaps the same way that outline no triad, 1.13.)\n        if good then\n          local function at(x, pos) return x and { pos = pos or x.pos, pitch = P(x, pos), first = x.first } end\n          local nb = at(b, p)\n          if M.leapsBad(at(z), at(a), nb) or M.leapsBad(at(a), nb, at(c)) or M.leapsBad(nb, at(c), at(y)) then good = false end\n        end\n        if good and c and M.parallel(ctx, bassPcAt, b, p, c, nil) then good = false end\n      end\n      if good then b.pos = p; return true end\n    end\n    return false\n  end\n  for _ = 1, 2 do\n    for i = 2, #notes do\n      if M.parallel(ctx, bassPcAt, notes[i - 1], nil, notes[i], nil) then\n        if not (try(i) or try(i - 1) or try(i, true) or try(i - 1, true)) and i > 3 then\n          -- (Boxed in - the way out would be a third note the same: the\n          -- note before that moves first, then this one.)\n          local keep = notes[i - 2].pos\n          if (try(i - 2) or try(i - 2, true)) and not (try(i - 1) or try(i - 1, true)) then notes[i - 2].pos = keep end\n          if M.parallel(ctx, bassPcAt, notes[i - 1], nil, notes[i], nil) then try(i, true, nil, true) end\n        elseif i == 2 and M.parallel(ctx, bassPcAt, notes[1], nil, notes[2], nil) then\n          -- (At the very start, the idea's first note may move as a last resort.)\n          try(1, true, true)\n        end\n        if M.parallel(ctx, bassPcAt, notes[i - 1], nil, notes[i], nil) and notes[i + 1] then\n          -- (Boxed in from the other side - the note before is a close's\n          -- goal, and every way out would be a tritone with the note after:\n          -- the note after moves, then this one.)\n          local keep = notes[i + 1].pos\n          if not ((try(i + 1) or try(i + 1, true)) and (try(i) or try(i, true))) then notes[i + 1].pos = keep end\n        end\n      end\n    end\n  end\nend\n\n------------------------------------------------------------------------------\n-- 6. Chords, bass and drums\n------------------------------------------------------------------------------\n\nlocal ARPEGGIOS = {\n  { name = \"up\",          order = { 1, 2, 3, 4 } },\n  { name = \"up and down\", order = { 1, 2, 3, 4, 3, 2 } },\n  { name = \"Alberti\",     order = { 1, 3, 2, 3 } },\n  { name = \"rolling\",     order = { 1, 2, 3, 2 } },\n}\n\n-- Bar lines inside [s, e), and s itself.\nlocal function barStarts(meter, s, e)\n  local out = { s }\n  local b = (s // meter.bar + 1) * meter.bar\n  while b < e do out[#out + 1] = b; b = b + meter.bar end\n  return out\nend\n\n-- A pushed chord is played as if it began on its beat, with its first\n-- stroke moved back onto the push: so it is struck on the \"and\", and not\n-- struck again an eighth later on the beat.\n-- Every chord keeps the beat it belongs to (`sl.beat`), even when it is\n-- pushed an eighth early or pulled an eighth late. A chord's strokes are\n-- laid out on the grid from its beat, then its first stroke moves to where\n-- the chord really arrives (`onShift`): onto the push, so it is not struck\n-- again on the beat, or back to the pull, so nothing is struck before it.\nlocal function beatOf(sl) return sl.beat or sl.s end\nlocal function gridStart(sl) return beatOf(sl) end\nlocal function onShift(sl, onsets)\n  local beat = beatOf(sl)\n  if sl.s == beat then return onsets end\n  if sl.s < beat then\n    if onsets[1] == beat then onsets[1] = sl.s else table.insert(onsets, 1, sl.s) end\n    return onsets\n  end\n  -- Pulled: nothing before it, and nothing crowding in less than a\n  -- sixteenth after it (a triplet grid can put a stroke two thirds of a\n  -- sixteenth behind).\n  local out = { sl.s }\n  for _, o in ipairs(onsets) do if o >= sl.s + 1 then out[#out + 1] = o end end\n  return out\nend\nlocal onPush = onShift\n\n-- The onsets of a pulse inside [s, e), with dotted and triplet figures laid\n-- over it bar by bar.\nlocal function pulseOnsets(meter, s, e, pace, groove, rnd, pattern, figures)\n  -- A named rhythm: its steps in each bar, and where the chord comes.\n  local named = M.rhythmOf(meter, groove)\n  if named then\n    local out, seen = { s }, { [s] = true }\n    for _, b in ipairs(barStarts(meter, s, e)) do\n      local bar = (b // meter.bar) * meter.bar\n      for _, t in ipairs(named) do\n        local st = bar + t\n        if st >= s and st < e and not seen[st] then seen[st] = true; out[#out + 1] = st end\n      end\n    end\n    table.sort(out)\n    return out\n  end\n  groove = plainGroove(groove)\n  -- Straight is on the beat (eighths when busy); syncopated is spread over\n  -- the eighths.\n  local unit = (pace == \"Busy\" or groove == \"Syncopated\") and 2 or meter.beat\n  if pace == \"Calm\" then unit = meter.beat end\n  local out = {}\n  for _, b in ipairs(barStarts(meter, s, e)) do\n    local stop = math.min(e, (b // meter.bar + 1) * meter.bar)\n    local slots = (stop - b) // unit\n    local pat\n    if groove == \"Syncopated\" and slots >= 4 then\n      pattern[slots] = pattern[slots] or syncopated(meter, b % meter.bar, unit, slots,\n        math.max(2, round(slots * 3 / 8)), rnd)\n      pat = pattern[slots]\n    else\n      pat = {}\n      for i = 0, slots - 1 do pat[#pat + 1] = i end\n    end\n    local rel = {}\n    for i, o in ipairs(pat) do rel[i] = o * unit end\n    for _, o in ipairs(M.figure(meter, b % meter.bar, stop - b, rel, figures, rnd)) do out[#out + 1] = b + o end\n  end\n  return out\nend\n\nlocal function addNote(list, step, len, pitch, accent)\n  if pitch and pitch >= 0 and pitch <= 127 and len > 0 then\n    list[#list + 1] = { step = step, len = len, pitch = pitch, accent = accent or false }\n  end\nend\n\n-- A held (Block) chord takes the figures as stabs: now and then struck\n-- again a dotted quarter in (the Charleston, 1 and the \"and\" of 2), or\n-- three times across the first two beats (a quarter-note triplet).\nlocal function blockFigures(meter, onsets, to, figures, rnd)\n  local F = FIGURES[figures]\n  if not F or meter.beat ~= 4 then return onsets end\n  local out = {}\n  for i, o in ipairs(onsets) do\n    out[#out + 1] = o\n    local stop = onsets[i + 1] or to\n    if o % 4 == 0 and stop - o >= 8 then\n      local x = rnd()\n      if x < F.tri then out[#out + 1] = o + 8 / 3; out[#out + 1] = o + 16 / 3\n      elseif x < F.tri + F.dot then out[#out + 1] = o + 6 end\n    end\n  end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- Part-writing by the book (1.7; docs/decisions/0019-part-writing-by-the-book.md)\n------------------------------------------------------------------------------\n\n-- An inverted chord does not double its bass note above it (Hutchinson,\n-- ch. 26; Rimsky-Korsakov, ch. III). In close position a chord of four\n-- notes or more simply leaves it out; otherwise the note takes the root's\n-- place, or the fifth's - the nearest one free, so a voicing keeps its\n-- number of notes (a rootless voicing takes the fifth or the ninth, never\n-- the root). A diminished triad in first inversion doubles\n-- its bass, as the books say: it is the one exception.\nfunction M.undouble(v, ch, bassPc, style)\n  local others = 0\n  for _, p in ipairs(v) do if p % 12 ~= bassPc then others = others + 1 end end\n  if others == #v then return v end\n  local out, used = {}, {}\n  for _, p in ipairs(v) do if p % 12 ~= bassPc then out[#out + 1] = p; used[p] = true end end\n  if others >= 3 and (style == \"Close\" or not style) then return out end\n  local fifth, nine\n  for _, pc in ipairs(ch.pcs) do\n    local role = T.roleOf(ch, pc)\n    if role == \"5\" and pc ~= bassPc then fifth = pc end\n    if role == \"9\" and pc ~= bassPc then nine = pc end\n  end\n  nine = nine or ch.nine\n  local want = (style == \"Rootless\") and { fifth, nine } or { ch.rootPc ~= bassPc and ch.rootPc or nil, fifth }\n  local top = v[#v]\n  for _, p in ipairs(v) do\n    if p % 12 == bassPc then\n      -- (The top note's place goes to a note at or above it, so a spread\n      -- voicing keeps its span.)\n      local function cost(q) return math.abs(q - p) + ((p == top and q < p) and 12 or 0) end\n      local best\n      for k = 1, 2 do\n        local pc = want[k]\n        if pc then\n          for q = p - 12, p + 12 do\n            -- (Never under the chords' floor, G2, that the voicings keep:\n            -- the bass must have room under it.)\n            if q % 12 == pc and not used[q] and q >= math.min(43, p) and (not best or cost(q) < cost(best)) then best = q end\n          end\n        end\n        if best then break end\n      end\n      if best then out[#out + 1] = best; used[best] = true end\n    end\n  end\n  table.sort(out)\n  -- (A two-note chord - a pentatonic scale's - keeps what it has.)\n  if #out < 2 then return v end\n  return out\nend\n\n-- A seventh falls a step into the next chord (Hutchinson, ch. 27; Open Music\n-- Theory, \"Tendency tones\"): if the chord before had its seventh at `p7`,\n-- and this chord has a note a semitone or a tone below it, the voicing that\n-- puts that note there is wanted - unless this chord keeps the seventh's\n-- note, which may then be held. Returns the wanted pitch, or nil.\nfunction M.seventhTarget(ch, prevV, prevCh)\n  if not prevV or not prevCh then return nil end\n  local s7\n  for _, pc in ipairs(prevCh.pcs) do if T.roleOf(prevCh, pc) == \"7\" then s7 = pc end end\n  if not s7 or ch.has[s7] then return nil end\n  local p7\n  for _, p in ipairs(prevV) do if p % 12 == s7 then p7 = p end end\n  if not p7 then return nil end\n  -- (An augmented sixth's \"seventh\" is fi, which rises to sol: 1.15.)\n  if prevCh.aug6 then return ch.has[(p7 + 1) % 12] and p7 + 1 or nil end\n  for _, t in ipairs({ p7 - 1, p7 - 2 }) do\n    if ch.has[t % 12] then return t end\n  end\nend\n\n-- The lowest note of the tune sounding in [s, e), or nil.\nlocal function tuneLowIn(tune, s, e)\n  local low\n  for _, n in ipairs(tune) do\n    if n.step < e and n.step + n.len > s then low = math.min(low or 127, n.pitch) end\n  end\n  return low\nend\n\n-- Fill (1.11): the chords answer the tune - struck on the eighths where it\n-- has held a note a beat or more, or is resting, a beat apart at most, and\n-- held until it moves again; struck where the chord comes only if nowhere\n-- else (or if the tune is silent there).\nfunction M.fillOnsets(meter, sl, tune, to)\n  local starts, sounding = {}, {}\n  for _, n in ipairs(tune) do starts[#starts + 1] = n end\n  local function lastBefore(st)\n    local best\n    for _, n in ipairs(tune) do if n.step <= st + 1e-9 then best = n end end\n    return best\n  end\n  local function nextAfter(st)\n    for _, n in ipairs(tune) do if n.step > st + 1e-9 then return n.step end end\n  end\n  local out, stops = {}, {}\n  local last = -99\n  for st = math.ceil(sl.s / 2) * 2, (to or sl.e) - 1, 2 do\n    local n = lastBefore(st)\n    local moving = n and math.abs(n.step - st) < 1e-9\n    local rest = not n or n.step + n.len <= st + 1e-9\n    local held = n and not moving and st - n.step >= meter.beat\n    if not moving and (rest or held) and st - last >= meter.beat then\n      out[#out + 1] = st\n      stops[#stops + 1] = nextAfter(st) or sl.e\n      last = st\n    end\n  end\n  if #out == 0 or out[1] > sl.s then\n    -- (The chord is heard where it comes, if the tune is not answering then.)\n    if #out == 0 then\n      table.insert(out, 1, sl.s)\n      table.insert(stops, 1, nextAfter(sl.s) or sl.e)\n    end\n  end\n  out.stops = stops\n  return out\nend\n\nfunction M.chordsPart(ctx, timeline, r, rnd, win)\n  local notes = {}\n  local meter = ctx.meter\n  local prev, prevBass, prevCh\n  local arp = pickOne(rnd, ARPEGGIOS)\n  local pattern = {}\n  local lows = {}\n  local book = win.book\n  local lastHi = win.hi\n  for idx, sl in ipairs(timeline) do\n    local lo, hi = win.lo, win.hi\n    if book and win.tune then\n      -- By the book the chords sit just under the tune notes over them -\n      -- reaching a step or two into the lowest, if they must - not under\n      -- the whole tune's lowest note.\n      -- (Over the chord's span on the beat: a pull does not move it.)\n      local span = win.beatTl and win.beatTl[idx] or sl\n      local low = tuneLowIn(win.tune, span.s, span.e)\n      hi = low and math.max(57, math.min(76, low + 2)) or lastHi\n      lastHi = hi\n      lo = math.max(43, hi - ((r.voicing == \"Close\") and 12 or 24))\n    end\n    -- A spread voicing may reach down to G2 for its root.\n    -- A voicing that will not fit under the tune may reach an octave over\n    -- the top before it gives up and plays close position.\n    local want = book and M.seventhTarget(sl.chord, prev, prevCh) or nil\n    -- (A seventh's step down matters more than where the tune has gone:\n    -- the window stretches to take it - a little over the top, if it must.)\n    if want then\n      if want < lo and want >= 43 then lo = want end\n      if want > hi and want <= hi + 3 then hi = want end\n    end\n    local v = T.voiceAs(sl.chord, r.voicing, prev, lo, hi, 43, want)\n    if #v == 0 then v = T.voiceAs(sl.chord, r.voicing, nil, lo, hi + 12, 43, want) end\n    if #v == 0 then v = T.voiceAs(sl.chord, \"Close\", nil, lo, hi + 12, nil, want) end\n    if book then\n      local dimTriad = sl.chord.quality == \"diminished\" and #sl.chord.pcs == 3\n      -- (Not a six-four: \"when a triad is in second inversion, double the\n      -- fifth (the bass note)\" - Hutchinson, 26.9 and 26.12. 1.13.)\n      -- (Nor the Neapolitan: \"double the bass (the third)\" - Hutchinson,\n      -- 29.3; Open Music Theory likewise. 1.15.)\n      local n6 = sl.chromatic and sl.chromatic.kind == \"N6\"\n      if sl.inversion and sl.inversion ~= 2 and not dimTriad and not n6 then v = M.undouble(v, sl.chord, sl.bassPc, r.voicing) end\n    end\n    prev, prevCh = v, sl.chord\n    lows[idx] = v[1]\n    local onsets, perNote = {}, false\n    -- The grid runs from this chord's beat to the next chord's beat (or to\n    -- where this one ends, if the next is pushed in front of it).\n    local from = gridStart(sl)\n    local nextSl = timeline[idx + 1]\n    local to = nextSl and math.min(sl.e, beatOf(nextSl)) or sl.e\n    local short\n    if r.chordStyle == \"Pulse\" then\n      onsets = onShift(sl, pulseOnsets(meter, from, to, r.pace, r.groove, rnd, pattern, r.figures))\n    elseif r.chordStyle == \"Pedal\" then\n      -- (Struck once, where the chord comes, and held.)\n      onsets = { sl.s }\n    elseif r.chordStyle == \"Offbeat\" then\n      -- The eighths between the beats, from where the chord comes to where\n      -- it goes; short.\n      -- (Struck no later than the next chord's beat, as every style is: a\n      -- pulled chord only holds into the eighth after it.)\n      local first = math.ceil(sl.s / 2) * 2\n      for st = first, to - 1, 2 do\n        if M.strength(meter, st) < 2 then onsets[#onsets + 1] = st end\n      end\n      if #onsets == 0 then onsets = { sl.s } end\n      short = 1\n    elseif r.chordStyle == \"Fill\" and win.melody then\n      onsets = M.fillOnsets(meter, sl, win.melody, to)\n    elseif r.chordStyle == \"Broken\" then\n      local unit = (r.pace == \"Calm\") and meter.beat or (r.pace == \"Busy\" and 1 or 2)\n      -- In triplets, an arpeggio rolls in eighth-note triplets.\n      if r.pace ~= \"Calm\" and meter.beat == 4 and (r.figures == \"Triplets\" or\n         (r.figures == \"Mixed\" and coin(rnd, 0.4))) then unit = 4 / 3 end\n      for st = from, to - 1e-6, unit do onsets[#onsets + 1] = st end\n      if unit ~= 4 / 3 then\n        -- Otherwise the figures fall on the arpeggio: long-short pairs, or\n        -- a beat in three.\n        local rel = {}\n        for i, o in ipairs(onsets) do rel[i] = o - from end\n        onsets = {}\n        for _, o in ipairs(M.figure(meter, from % meter.bar, to - from, rel, r.figures, rnd)) do\n          onsets[#onsets + 1] = from + o\n        end\n      end\n      onsets = onShift(sl, onsets)\n      perNote = true\n    else\n      onsets = onShift(sl, blockFigures(meter, barStarts(meter, from, to), to, r.figures, rnd))\n    end\n    for i, o in ipairs(onsets) do\n      local stop = onsets[i + 1] or sl.e\n      if short then stop = math.min(stop, o + short) end\n      if type(onsets.stops) == \"table\" and onsets.stops[i] then stop = math.min(stop, onsets.stops[i]) end\n      local accent = o % meter.bar == 0\n      if perNote then\n        local k = arp.order[(i - 1) % #arp.order + 1]\n        local pitch = (k <= #v) and v[k] or (v[(k - 1) % #v + 1] + 12 * ((k - 1) // #v))\n        addNote(notes, o, stop - o, pitch, accent)\n      else\n        for _, p in ipairs(v) do addNote(notes, o, stop - o, p, accent) end\n      end\n    end\n    if win.bass then\n      local b = T.bassNote(bassPcOf(sl), prevBass, 36, 47)\n      -- (Under any voicing but Close - which is as it always was - the bass\n      -- goes under the chord's lowest note, down to E1 if it has to.)\n      if r.voicing ~= \"Close\" and v[1] and b >= v[1] then b = T.bassNote(bassPcOf(sl), prevBass, 28, v[1] - 1) end\n      -- By the book: under the chord, and no more than an octave and a fifth\n      -- under it.\n      if book and v[1] then b = T.bassNote(bassPcOf(sl), prevBass, math.max(28, v[1] - 19), v[1] - 1) end\n      prevBass = b\n      local bars = onShift(sl, barStarts(meter, gridStart(sl), to))\n      for i, o in ipairs(bars) do addNote(notes, o, (bars[i + 1] or sl.e) - o, b, o % meter.bar == 0) end\n    end\n  end\n  return notes, arp.name, lows\nend\n\n-- By the book, a Measure's bass is put in the octave that keeps it under\n-- the chords and no more than an octave and a fifth under them (Rimsky-\n-- Korsakov: \"rarely more than an octave\"; Belkin: no hole in the middle),\n-- inside the bass's range, each note the octave nearest the one before.\n-- Only octaves move: the notes are the same.\n-- By the book, while a suspension or an appoggiatura sounds, the chords do\n-- not play the note it falls to: \"with the exception of 9-8, the pitch\n-- class of the resolution tone should never sound in another voice\n-- simultaneous with the suspended tone\" (Open Music Theory, \"Embellishing\n-- tones\"; the appoggiatura is treated alike) - the tune brings it. So not\n-- when it falls to the chord's root (the 9-8). A chord struck then\n-- leaves it out (but keeps two notes, and a Phrase's own bass).\nfunction M.clearResolutions(list, tune, keepBass)\n  local spans = {}\n  for _, nt in ipairs(tune or {}) do\n    local d = nt.dissonance\n    if d and d.res and d.res ~= d.root then spans[#spans + 1] = d end\n  end\n  if #spans == 0 then return list end\n  local at, low = {}, {}\n  for _, n in ipairs(list) do\n    at[n.step] = (at[n.step] or 0) + 1\n    low[n.step] = math.min(low[n.step] or 999, n.pitch)\n  end\n  local out = {}\n  for _, n in ipairs(list) do\n    local drop = false\n    for _, d in ipairs(spans) do\n      if n.step < d.e and n.step + n.len > d.s and n.pitch % 12 == d.res then drop = true end\n    end\n    if drop and (at[n.step] <= 2 or (keepBass and n.pitch == low[n.step])) then drop = false end\n    if drop then at[n.step] = at[n.step] - 1 else out[#out + 1] = n end\n  end\n  return out\nend\n\nfunction M.spaceBass(bass, timeline, lows)\n  local function slotOf(step)\n    local idx = 1\n    for i, sl in ipairs(timeline) do if step >= sl.s then idx = i end end\n    return idx\n  end\n  -- The octave of `n` nearest `ref` in [lo, hi], or nil.\n  local function pick(n, ref, lo, hi)\n    local best\n    for q = n.pitch - 36, n.pitch + 36, 12 do\n      if q >= lo and q <= hi and (not best or math.abs(q - ref) < math.abs(best - ref)) then best = q end\n    end\n    return best\n  end\n  local orig, starts = {}, {}\n  for i, n in ipairs(bass) do\n    orig[i] = n.pitch\n    local sl = timeline[slotOf(n.step)]\n    starts[i] = math.abs(n.step - sl.s) < 1e-9\n  end\n  -- First the note each chord stands on, the octave nearest where the\n  -- line was going (the same interval from the last one as it had)...\n  local prevI\n  for i, n in ipairs(bass) do\n    local low = lows[slotOf(n.step)]\n    if starts[i] and low then\n      local ref = prevI and (bass[prevI].pitch + orig[i] - orig[prevI]) or n.pitch\n      -- (And where the note leading into it can still step into it from\n      -- under the chord before.)\n      local before = bass[i - 1]\n      local lowBefore = before and not starts[i - 1] and lows[slotOf(before.step)]\n      local best, bestCost\n      -- (A walking bass's step into the chord matters more than the gap,\n      -- which matters more than where the line was going.)\n      for wi, w in ipairs({ { math.max(28, low - 19), math.min(55, low - 1) }, { 28, math.min(55, low - 1) } }) do\n        for q = n.pitch - 36, n.pitch + 36, 12 do\n          if q >= w[1] and q <= w[2] then\n            local cost = math.abs(q - ref) + (wi == 2 and 50 or 0)\n            if lowBefore then\n              local into = q + orig[i - 1] - orig[i]\n              if into < 28 or into > math.min(55, lowBefore - 1) then cost = cost + 100 end\n            end\n            if not bestCost or cost < bestCost then best, bestCost = q, cost end\n          end\n        end\n      end\n      n.pitch = best or n.pitch\n      prevI = i\n    end\n  end\n  -- ...then the notes between, each as far from the next chord's note as it\n  -- was (so a walking bass still steps into it), or from the note before.\n  for i, n in ipairs(bass) do\n    local low = lows[slotOf(n.step)]\n    if not starts[i] and low then\n      local nx = bass[i + 1]\n      local ref\n      if nx and starts[i + 1] then ref = nx.pitch + orig[i] - orig[i + 1]\n      elseif i > 1 then ref = bass[i - 1].pitch + orig[i] - orig[i - 1]\n      else ref = n.pitch end\n      local q = pick(n, ref, math.max(28, low - 19), math.min(55, low - 1))\n      if not q or math.abs(q - ref) > 2 then q = pick(n, ref, 28, math.min(55, low - 1)) or q end\n      n.pitch = q or n.pitch\n    end\n  end\n  return bass\nend\n\n-- (1.14) The bass lying back with the chords: where a chord is pulled, the\n-- bass's note on its beat comes an eighth late, with the chord, and the\n-- note before is held to meet it. (Anything the bass played inside that\n-- eighth goes: it changes where the chords do.) `chordTl` is the pulled\n-- copy of `timeline`, slot for slot.\nfunction M.pullBass(list, timeline, chordTl)\n  local eps = 1e-9\n  for i, csl in ipairs(chordTl) do\n    if csl.pulled then\n      local at, to = timeline[i].s, csl.s\n      local pitch, onTo\n      for k = #list, 1, -1 do\n        local n = list[k]\n        if math.abs(n.step - at) < eps then pitch = n.pitch end\n        if math.abs(n.step - to) < eps then onTo = true end\n        if n.step > at - eps and n.step < to - eps then table.remove(list, k) end\n      end\n      if pitch and not onTo then\n        local nextAt = csl.e\n        for _, n in ipairs(list) do if n.step > to + eps and n.step < nextAt then nextAt = n.step end end\n        list[#list + 1] = { step = to, len = nextAt - to, pitch = pitch, accent = false }\n      end\n      for _, p in ipairs(list) do\n        if p.step < at - eps and math.abs(p.step + p.len - at) < eps then p.len = to - p.step end\n      end\n      table.sort(list, function(a, b) if a.step ~= b.step then return a.step < b.step end return a.pitch < b.pitch end)\n    end\n  end\nend\n\n-- The kick drum's places in a bar, which the bass can follow.\nfunction M.kickPattern(meter, r, rnd)\n  -- (A named rhythm, 1.11, is the kick's pattern, as it is; drawn nothing.)\n  local named = M.rhythmOf(meter, r.groove)\n  if named then\n    local out = {}\n    for i, t in ipairs(named) do out[i] = t end\n    return out\n  end\n  local slots = meter.bar // 2\n  local k = ({ Calm = 1, Flowing = 2, Busy = 3 })[r.pace] or 2\n  k = math.max(1, round(k * slots / 8))\n  if plainGroove(r.groove) == \"Syncopated\" then\n    local kk = math.max(2, round(slots * ({ Calm = 0.38, Flowing = 0.38, Busy = 0.62 })[r.pace]))\n    local pat = syncopated(meter, 0, 2, slots, math.min(kk, slots - 1), rnd)\n    local out = {}\n    for i, o in ipairs(pat) do out[i] = o * 2 end\n    return out\n  end\n  local pat = strongest(meter, 0, 2, slots, k, rnd)\n  local out = {}\n  for i, o in ipairs(pat) do out[i] = o * 2 end\n  return out\nend\n\n-- The tune's pitch sounding at a step, or nil.\nlocal function tuneAt(tune, step)\n  for _, n in ipairs(tune) do\n    if n.step <= step + 1e-9 and n.step + n.len > step + 1e-9 then return n.pitch end\n  end\nend\n\nfunction M.bassPart(ctx, timeline, r, rnd, kick, tune)\n  local notes = {}\n  local meter = ctx.meter\n  local prev\n  local prevStep, prevP\n  -- Parallel fifths or octaves with the tune, from the bass note before to `q` at `st`.\n  local function parallelAt(st, q, fromStep, fromP)\n    if not (tune and fromStep) then return false end\n    local tA, tB = tuneAt(tune, fromStep), tuneAt(tune, st)\n    if not (tA and tB) or tA == tB or q % 12 == fromP % 12 then return false end\n    local ia, ib = (tA - fromP) % 12, (tB - q) % 12\n    return ia == ib and (ib == 0 or ib == 7)\n  end\n  for idx, sl in ipairs(timeline) do\n    -- (The root, or the note an inverted chord stands on.)\n    local root = T.bassNote(bassPcOf(sl), prev, 31, 50)\n    prev = root\n    local nextSl = timeline[idx + 1]\n    local key = sl.key or ctx.key\n    if r.bass == \"Pulse\" then\n      local on = {}\n      for _, b in ipairs(barStarts(meter, sl.s, sl.e)) do\n        local barStart = (b // meter.bar) * meter.bar\n        for _, k in ipairs(kick) do\n          local st = barStart + k\n          -- (A pushed chord's bass comes on the push, not again on the beat.)\n          if st >= sl.s and st < sl.e and not (sl.pushed and st == sl.s + 2) then on[#on + 1] = st end\n        end\n      end\n      local seen, list = {}, {}\n      table.insert(on, 1, sl.s)\n      for _, st in ipairs(on) do if not seen[st] then seen[st] = true; list[#list + 1] = st end end\n      table.sort(list)\n      for i, st in ipairs(list) do\n        addNote(notes, st, math.min((list[i + 1] or sl.e) - st, 8), root, st % meter.bar == 0)\n      end\n    elseif r.bass == \"Moving\" then\n      local unit = meter.beat\n      if r.pace == \"Calm\" and (meter.bar // 2) % meter.beat == 0 and meter.beats % 2 == 0 then unit = meter.bar // 2 end\n      local beats = {}\n      local from = gridStart(sl)\n      for st = from, sl.e - 1, unit do beats[#beats + 1] = st - from end\n      -- Dotted and triplet figures fall on a walking bass too.\n      local figured = M.figure(meter, from % meter.bar, sl.e - from, beats, r.figures, rnd)\n      beats = {}\n      for i, o in ipairs(figured) do beats[i] = from + o end\n      beats = onPush(sl, beats)\n      for i, st in ipairs(beats) do\n        local p\n        if i == 1 then p = root\n        elseif i == #beats and nextSl then\n          -- A step into the next chord's root, from the scale sounding now:\n          -- the scale note a semitone or a tone from it, nearer the root\n          -- being left.\n          local nr = T.bassNote(bassPcOf(nextSl), root, 31, 50)\n          local best, bestBad\n          for q = nr - 2, nr + 2 do\n            local d = math.abs(q - nr)\n            if d >= 1 and T.posOf(key, q) then\n              -- (By the book, one that makes no parallels with the tune,\n              -- going in or coming out, is preferred.)\n              local bad = (parallelAt(st, q, prevStep, prevP) or parallelAt(nextSl.s, nr, st, q)) and 1 or 0\n              if not best or bad < bestBad or (bad == bestBad and math.abs(q - root) < math.abs(best - root)) then\n                best, bestBad = q, bad\n              end\n            end\n          end\n          p = best or root\n        else\n          local fifth = T.bassNote(sl.chord.pcs[3] or sl.chord.pcs[2] or sl.chord.rootPc, root, 31, 52)\n          local choices = { fifth, root + 12 <= 52 and root + 12 or root, T.bassNote(sl.chord.pcs[2] or sl.chord.rootPc, root, 31, 52) }\n          local ws = { 3, 2, 1 }\n          -- By the book, no passing note that makes parallel fifths or\n          -- octaves with the tune (if another will do).\n          if tune and prevStep then\n            local any = false\n            local w2 = {}\n            for k, q in ipairs(choices) do\n              local par = parallelAt(st, q, prevStep, prevP)\n              w2[k] = par and 0 or ws[k]\n              if not par then any = true end\n            end\n            if any then ws = w2\n            else\n              -- (Every one would: the bass holds its note - oblique motion.)\n              choices, ws = { prevP, prevP, prevP }, ws\n            end\n          end\n          p = weighted(rnd, choices, ws)\n        end\n        prevStep, prevP = st, p\n        addNote(notes, st, (beats[i + 1] or sl.e) - st, p, st % meter.bar == 0)\n      end\n    else\n      local bars = onPush(sl, barStarts(meter, gridStart(sl), sl.e))\n      for i, st in ipairs(bars) do addNote(notes, st, (bars[i + 1] or sl.e) - st, root, st % meter.bar == 0) end\n    end\n  end\n  return notes\nend\n\nM.DRUM = { kick = 36, snare = 38, hat = 42, open = 46, crash = 49, tomHi = 50, tomMid = 47, tomLo = 45,\n           clap = 39, pedal = 44, ride = 51, bell = 53, tomHiMid = 48, tomFloor = 43, tomFloorLo = 41 }\n\n-- Which beats the snare plays: the backbeat (2 and 4), or the half-time\n-- beat 3 when the pace is calm.\nlocal function backbeats(meter, pace)\n  local out = {}\n  if pace == \"Calm\" and meter.mid then return { meter.mid } end\n  if meter.beats == 1 then return { meter.bar // 2 } end\n  if meter.beats == 3 then return { 2 * meter.beat } end\n  for b = 1, meter.beats - 1, 2 do out[#out + 1] = b * meter.beat end\n  return out\nend\n\n------------------------------------------------------------------------------\n-- Drums on their own (docs/decisions/0013-drums-are-a-kind-of-idea.md)\n--\n-- A groove a bar long, made for the beat style from the same pieces 1.0's\n-- Measures had for their drums (the kick's metric or Euclidean pattern, the\n-- backbeat),\n-- played in pairs of bars where the second answers the first with one\n-- small change; then fills where the Fills setting asks, each a beat or two\n-- of snare, toms, or both (in triplets when the figures are), with a crash\n-- on the downbeat it leads to - the top of the idea, for the last one, since\n-- a drum idea is made to loop. General MIDI notes throughout, channel 10.\n------------------------------------------------------------------------------\n\nlocal TOMS = { 50, 48, 47, 45, 43, 41 }   -- high to floor\n\n-- The bar of groove: kick, snare and cymbal steps, and what plays them.\nlocal function drumGroove(meter, r, rnd)\n  local D = M.DRUM\n  local bar, beat = meter.bar, meter.beat\n  local style = r.beat\n  if (style == \"Breakbeat\" or style == \"Reggaeton\") and not (bar == 16 and beat == 4) then style = \"Backbeat\" end\n  local g = { kick = {}, snare = {}, snarePitch = D.snare, open = {}, style = style }\n  if style == \"Four on the floor\" then\n    for b = 0, bar - 1, beat do g.kick[#g.kick + 1] = b end\n    g.snare = backbeats(meter, \"Flowing\")\n    g.snarePitch = D.clap\n    if beat % 2 == 0 then\n      for b = 0, bar - 1, beat do g.open[#g.open + 1] = b + beat // 2 end\n    end\n  elseif style == \"Half-time\" then\n    g.snare = { meter.mid or (meter.beats - 1) * beat }\n    local calm = {}\n    for k, v in pairs(r) do calm[k] = v end\n    calm.pace = \"Calm\"\n    g.kick = M.kickPattern(meter, calm, rnd)\n  elseif style == \"Reggaeton\" then\n    -- The dembow (1.13): four on the floor under the tresillo, twice.\n    for b = 0, bar - 1, beat do g.kick[#g.kick + 1] = b end\n    g.snare = { 3, 6, 11, 14 }\n  elseif style == \"Breakbeat\" then\n    g.kick = pickOne(rnd, { { 0, 10 }, { 0, 2, 10 }, { 0, 6, 10 }, { 0, 10, 11 } })\n    g.snare = { 4, 12 }\n    -- One snare knocked off the backbeat: a sixteenth or an eighth either\n    -- side of beat 4, or the \"a\" of 3.\n    if coin(rnd, 0.75) then table.insert(g.snare, pickOne(rnd, { 7, 9, 14, 15 })) end\n  else\n    g.kick = M.kickPattern(meter, r, rnd)\n    g.snare = backbeats(meter, \"Flowing\")\n  end\n  -- Dotted and triplet figures fall on the kick - but four on the floor is\n  -- four on the floor.\n  -- (Nor on a named rhythm, which is that rhythm.)\n  if style ~= \"Four on the floor\" and style ~= \"Reggaeton\" and not (M.rhythmOf(meter, r.groove) and (style == \"Backbeat\" or style == \"Half-time\")) then\n    g.kick = M.figure(meter, 0, bar, g.kick, r.figures, rnd)\n  end\n  if style ~= \"Four on the floor\" then\n    local onSnare = {}\n    for _, x in ipairs(g.snare) do onSnare[x] = true end\n    local k = {}\n    for _, x in ipairs(g.kick) do if not onSnare[x] then k[#k + 1] = x end end\n    g.kick = k\n  end\n  table.sort(g.snare)\n\n  -- Time: quarters when calm, eighths when flowing, sixteenths when busy (a\n  -- breakbeat is sixteenths at any pace but calm); eighths in 6/8 rather\n  -- than dotted quarters; in triplets, the shuffle.\n  local unit = ({ Calm = beat, Flowing = 2, Busy = 1 })[r.pace] or 2\n  if style == \"Breakbeat\" and r.pace ~= \"Calm\" then unit = 1 end\n  if beat % 4 ~= 0 and r.pace == \"Calm\" then unit = 2 end\n  g.time = {}\n  if r.figures == \"Triplets\" and r.pace ~= \"Calm\" and beat == 4 then\n    for b = 0, bar - 1, 4 do\n      g.time[#g.time + 1] = b\n      if r.pace == \"Busy\" then g.time[#g.time + 1] = b + 4 / 3 end\n      g.time[#g.time + 1] = b + 8 / 3\n    end\n  else\n    for t = 0, bar - 1, unit do g.time[#g.time + 1] = t end\n  end\n  g.timePitch = (r.cymbal == \"Ride\") and D.ride or D.hat\n  return g\nend\n\n-- A fill over [from, to) of a bar starting at `base`.\nlocal function drumFill(meter, r, rnd, base, from, to)\n  local D = M.DRUM\n  local out = {}\n  local unit = (r.pace == \"Calm\") and 2 or 1\n  local kinds = { \"roll\", \"toms\", \"snare and toms\" }\n  if meter.beat == 4 and (r.figures == \"Triplets\" or r.figures == \"Mixed\") then kinds[#kinds + 1] = \"triplets\" end\n  local kind = pickOne(rnd, kinds)\n  local steps = {}\n  if kind == \"triplets\" then\n    for t = from, to - 1e-6, 4 / 3 do steps[#steps + 1] = t end\n  else\n    for t = from, to - 1, unit do steps[#steps + 1] = t end\n  end\n  for i, t in ipairs(steps) do\n    local pitch\n    if kind == \"roll\" then pitch = D.snare\n    elseif kind == \"snare and toms\" then\n      pitch = (i <= #steps // 2) and D.snare or TOMS[math.min(#TOMS, 1 + (i - #steps // 2 - 1) * #TOMS // math.max(1, #steps - #steps // 2))]\n    else\n      pitch = TOMS[math.min(#TOMS, 1 + (i - 1) * #TOMS // #steps)]\n    end\n    out[#out + 1] = { step = base + t, len = 1, pitch = pitch, accent = (i == 1) }\n  end\n  -- The kick under the fill's first note, so it lands with weight.\n  out[#out + 1] = { step = base + from, len = 1, pitch = D.kick, accent = true }\n  return out, kind\nend\n\n-- (1.14) Ghost notes: the snare tapped very quietly (`M.GHOST_VELOCITY`,\n-- at any Velocity) on the weakest places in the bar - the sixteenths between\n-- the eighths, or the middle of a triplet - most often just before or after\n-- the backbeat. Chosen once for the idea, so every bar has the same; never\n-- where the snare or the kick already plays, nor in a fill. One draw per\n-- place, so Common keeps Rare's and adds.\nM.GHOST_CHANCE = { Rare = 0.35, Common = 0.8 }\nM.GHOST_AWAY = 0.35     -- a place not next to the backbeat: this much as likely\nM.GHOST_VELOCITY = 38\n\nfunction M.ghostSteps(meter, g, r, rnd)\n  local chance = M.GHOST_CHANCE[r.ghosts]\n  if not chance or not rnd then return {} end\n  -- (Places by the third of a sixteenth: a triplet kick at 9 1/3 is the\n  -- same place however it was reached.)\n  local function at(x) return math.floor(x * 3 + 0.5) end\n  local taken = {}\n  for _, x in ipairs(g.kick) do taken[at(x)] = true end\n  for _, x in ipairs(g.snare) do taken[at(x)] = true end\n  local places = {}\n  if r.figures == \"Triplets\" and r.pace ~= \"Calm\" and meter.beat == 4 then\n    -- (In a shuffle, the middle note of the triplet, which the hats skip.)\n    for b = 0, meter.bar - 1, 4 do places[#places + 1] = b + 4 / 3 end\n  else\n    for t = 1, meter.bar - 1, 2 do places[#places + 1] = t end\n  end\n  local out = {}\n  for _, t in ipairs(places) do\n    local x = rnd()\n    local nearIt = false\n    for _, y in ipairs(g.snare) do if math.abs(t - y) <= 2 then nearIt = true end end\n    if not taken[at(t)] and x < chance * (nearIt and 1 or M.GHOST_AWAY) then out[#out + 1] = t end\n  end\n  return out\nend\n\nfunction M.drumIdea(meter, r, rnd, ghostRnd)\n  local D = M.DRUM\n  local bar, bars = meter.bar, r.bars\n  local g = drumGroove(meter, r, rnd)\n  local ghosts = M.ghostSteps(meter, g, r, ghostRnd)\n  -- The answering bar: one small change, chosen once for the whole idea.\n  local change = pickOne(rnd, { \"pickup\", \"double\", \"open\" })\n\n  local fills = {}\n  for b = 0, bars - 1 do\n    local last = (b == bars - 1)\n    if (r.fills == \"At the end\" and last) or\n       (r.fills == \"Every 4 bars\" and ((b + 1) % 4 == 0 or last)) or\n       (r.fills == \"Every 2 bars\" and ((b + 1) % 2 == 0 or last)) then fills[b] = true end\n  end\n  local crashes = {}\n  for b in pairs(fills) do crashes[(b + 1) % bars] = true end\n\n  local notes, fillKinds = {}, {}\n  local total = bars * bar\n  -- (An open hat or a crash near the end stops at the end.)\n  local function add(step, len, pitch, accent)\n    notes[#notes + 1] = { step = step, len = math.min(len, total - step), pitch = pitch, accent = accent or false }\n  end\n  for b = 0, bars - 1 do\n    local base = b * bar\n    -- A fill takes a beat - two when busy, or at the end of the idea or a\n    -- four-bar phrase when flowing - never the whole bar.\n    local fillBeats = (r.pace == \"Busy\" or (r.pace == \"Flowing\" and (b == bars - 1 or (b + 1) % 4 == 0))) and 2 or 1\n    local fillFrom = fills[b] and math.max(meter.beat, bar - fillBeats * meter.beat) or bar\n    local answer = (b % 2 == 1)\n    local kick = {}\n    for _, k in ipairs(g.kick) do kick[#kick + 1] = k end\n    local open = {}\n    for _, o in ipairs(g.open) do open[o] = true end\n    if answer then\n      local snareAt = {}\n      for _, x in ipairs(g.snare) do snareAt[x] = true end\n      -- (A pickup kick on the \"and\" of 4 - or on its \"a\", where the snare\n      -- has the \"and\", as in the dembow.)\n      -- (And an open hat only where there is a closed one to open: on the\n      -- ride, or with the hats in quarters, the pickup instead.)\n      local hatAt = false\n      for _, t in ipairs(g.time) do if t == bar - 2 then hatAt = true end end\n      local how = change\n      if how == \"open\" and not (g.timePitch == D.hat and hatAt) then how = \"pickup\" end\n      if how == \"pickup\" and not snareAt[bar - 2] then kick[#kick + 1] = bar - 2\n      elseif how == \"pickup\" and not snareAt[bar - 1] then kick[#kick + 1] = bar - 1\n      elseif how == \"double\" and g.snare[#g.snare] and g.snare[#g.snare] - 1 > 0 then kick[#kick + 1] = g.snare[#g.snare] - 1\n      elseif how == \"open\" then open[bar - 2] = true end\n    end\n    for _, k in ipairs(kick) do if k < fillFrom then add(base + k, 1, D.kick, k == 0) end end\n    for _, x in ipairs(g.snare) do if x < fillFrom then add(base + x, 1, g.snarePitch, true) end end\n    local kickAt = {}\n    for _, k in ipairs(kick) do kickAt[math.floor(k * 3 + 0.5)] = true end\n    for _, x in ipairs(ghosts) do\n      if x < fillFrom and not kickAt[math.floor(x * 3 + 0.5)] then\n        add(base + x, 1, D.snare, false)\n        notes[#notes].ghost = true\n      end\n    end\n    for _, t in ipairs(g.time) do\n      if t < fillFrom and not (crashes[b] and t == 0) then\n        if open[t] and g.timePitch == D.hat then add(base + t, 2, D.open, false)\n        else\n          local bell = g.timePitch == D.ride and t % meter.beat == 0 and t == 0\n          add(base + t, 1, bell and D.bell or g.timePitch, false)\n        end\n      end\n    end\n    if g.timePitch == D.ride then\n      for _, x in ipairs(g.snare) do if x < fillFrom then add(base + x, 1, D.pedal, false) end end\n    end\n    if crashes[b] then add(base, 4, D.crash, true) end\n    if fills[b] then\n      local f, kind = drumFill(meter, r, rnd, base, fillFrom, bar)\n      for _, n in ipairs(f) do notes[#notes + 1] = n end\n      fillKinds[#fillKinds + 1] = kind\n    end\n  end\n  table.sort(notes, function(a, c)\n    if a.step ~= c.step then return a.step < c.step end\n    return a.pitch < c.pitch\n  end)\n  local fillBars = {}\n  for b = 0, bars - 1 do if fills[b] then fillBars[#fillBars + 1] = tostring(b + 1) end end\n  return notes, { style = g.style, fills = fillBars, fillKinds = fillKinds, change = change, ghosts = #ghosts }\nend\n\n------------------------------------------------------------------------------\n-- 7. The idea\n------------------------------------------------------------------------------\n\nfunction M.keyName(key)\n  return T.ROOTS[key.root].name .. \" \" .. T.SCALES[key.scale].name\nend\n\n------------------------------------------------------------------------------\n-- Swing\n--\n-- The last thing done to an idea, after every note is placed: each quarter\n-- note's grid is stretched so its off-beat eighth lands later - at 100% two\n-- thirds of the way through the beat, where a triplet would be - and the\n-- sixteenths either side move with it in proportion. Beats themselves never\n-- move. Triplet notes are already in threes and are left alone. Only in\n-- metres whose beat is a quarter or a half note: 6/8 and 12/8 swing by\n-- being in threes, and 7/8 has no quarter notes to swing.\n------------------------------------------------------------------------------\n\nfunction M.swings(meter) return meter.beat % 4 == 0 end\n\nfunction M.swingWarp(meter, amount)\n  amount = tonumber(amount) or 0\n  if amount <= 0 or not M.swings(meter) then return nil end\n  local d = math.min(amount, 100) / 100 / 6      -- of a beat: 1/6 is triplet swing\n  return function(step)\n    local q = math.floor(step / 4) * 4\n    local f = (step - q) / 4\n    if f <= 0.5 then f = f * (0.5 + d) / 0.5\n    else f = 0.5 + d + (f - 0.5) * (0.5 - d) / 0.5 end\n    return q + f * 4\n  end\nend\n\nlocal function whole(x) return math.abs(x - math.floor(x + 0.5)) < 1e-9 end\n\n-- Shaped velocity (1.7): by how strong the beat is - the downbeat loudest,\n-- an off-beat or a triplet note softest - and by the part: the chords under\n-- the tune (their inner notes under their top), the bass just under it. An\n-- accented note (a push, the start of a statement) leans in a little.\nM.SHAPE = { [3] = 104, [2.5] = 98, [2] = 94, [1] = 86, [0] = 80 }\nM.SHAPE_PART = { Melody = 0, Chords = -10, Bass = -4, Drums = 0, [\"Second voice\"] = -6 }\nM.SHAPE_INNER, M.SHAPE_ACCENT = -4, 6\n\nfunction M.shapedVelocity(meter, step, part, accent, inner)\n  local v = M.SHAPE[M.strength(meter, step)] or 80\n  v = v + (M.SHAPE_PART[part] or 0) + (accent and M.SHAPE_ACCENT or 0) + (inner and M.SHAPE_INNER or 0)\n  return math.max(1, math.min(127, v))\nend\n\nlocal function toBlockNotes(list, chan, vel, warp, meter, part)\n  local out = {}\n  -- (The top note of everything struck together, for the inner notes.)\n  local top = {}\n  if vel == \"Shaped\" and part == \"Chords\" then\n    for _, n in ipairs(list) do top[n.step] = math.max(top[n.step] or 0, n.pitch) end\n  end\n  for _, n in ipairs(list) do\n    local s, e = n.step, n.step + n.len\n    if warp then\n      if whole(s) then s = warp(s) end\n      if whole(e) then e = warp(e) end\n    end\n    local v = (vel == \"Accents\" and n.accent) and M.ACCENT or 100\n    if vel == \"Shaped\" then\n      v = M.shapedVelocity(meter, n.step, part, n.accent, top[n.step] and n.pitch < top[n.step])\n    end\n    if n.ghost then v = M.GHOST_VELOCITY end\n    out[#out + 1] = { start = s / 4, len = (e - s) / 4, pitch = n.pitch, chan = chan,\n                      accent = n.accent, vel = v, tension = n.tension, ghost = n.ghost }\n  end\n  table.sort(out, function(a, b)\n    if a.start ~= b.start then return a.start < b.start end\n    if a.pitch ~= b.pitch then return a.pitch < b.pitch end\n    return a.len < b.len\n  end)\n  return out\nend\n\n-- The chords as a musician reads them: bar by bar, | C G | Am F |. A chord\n-- is shown in the bar its beat is in: pushed an eighth early it is marked\n-- ^, pulled an eighth late _, borrowed *.\nfunction M.chordLine(timeline, meter)\n  local bars = {}\n  for _, sl in ipairs(timeline) do\n    local b = beatOf(sl) // meter.bar + 1\n    bars[b] = bars[b] or {}\n    -- An inverted chord is written over its bass note: C/E.\n    local slash = sl.bassPos and (\"/\" .. T.noteName(sl.key, sl.bassPos)) or \"\"\n    table.insert(bars[b], (sl.pushed and \"^\" or \"\") .. (sl.pulled and \"_\" or \"\") .. sl.chord.name .. slash ..\n                          ((sl.borrowed or sl.chromatic) and \"*\" or \"\") .. ((sl.applied or sl.commonTone) and \">\" or \"\"))\n    -- A chord held over bar lines shows in each bar it sounds in, as \"-\".\n    for x = b + 1, (sl.e - 1) // meter.bar + 1 do\n      bars[x] = bars[x] or {}\n      table.insert(bars[x], \"-\")\n    end\n  end\n  local out = {}\n  for i = 1, #bars do out[#out + 1] = table.concat(bars[i] or {}, \" \") end\n  return \"| \" .. table.concat(out, \" | \") .. \" |\"\nend\n\n--[[ The idea for these settings, this metre and this number.\n\n     Returns {\n       block    = { name, beats, notes, parts = { { name, notes, chan } }, layout },\n       r        = the settings with every Any rolled,\n       key, plan, timeline, melody (steps and positions, for the tests),\n       summary  = a line saying what was rolled,\n       chords   = the chord line,\n     }\n]]\nfunction M.make(st, meter, seed)\n  seed = math.floor(tonumber(seed) or st.seed or 1)\n  local r = M.resolve(st, seed)\n  if r.kind == \"Drums\" then return M.makeDrums(st, meter, seed, r) end\n  local key = T.key(r.root, r.scale)\n  -- With no chords to play, the tune still walks over chords - plain triads,\n  -- one a bar - so its strong notes outline a harmony. The chord settings\n  -- are hidden then, and must not change it.\n  if not r.chords then\n    r.colour, r.chordPace, r.chordStyle = \"Triads\", \"One a bar\", \"Block\"\n    r.flavours, r.voicing, r.inversions = \"Off\", \"Close\", \"Off\"\n    r.partWriting = \"Free\"\n    r.progression = \"Walk\"\n  end\n  local book = r.partWriting == \"By the book\"\n  local plan = M.plan(r, meter, M.stream(seed, \"plan\"))\n  local colour = r.colour\n  local sch, schemaWhy = M.schemaFor(r, key, M.stream(seed, \"schema\"))\n  -- (1.12) Where the key changes, if it does: the timeline keeps the same\n  -- chord either side apart there.\n  local changeAt, tonicStart\n  if r.kind == \"Measure\" and M.KEY_CHANGE[r.keyChange] then\n    -- (For the truck driver, a look at the chords first - the same dice\n    -- give the same chords - to find a section that starts on the tonic.)\n    local tonicAt, canTonic, made\n    if r.keyChange == \"Truck driver\" and T.scaleLen(key) == 7 then\n      local look = M.harmony(plan, key, r, meter, M.stream(seed, \"harmony\"), colour,\n                             sch and M.schemaFor(r, key, M.stream(seed, \"schema\")))\n      tonicAt = function(step)\n        local sl = M.chordAt(look, step)\n        return sl and sl.degree == 0\n      end\n      -- (1.14) Where none starts on the tonic, one may be made to: its first\n      -- chord becomes the tonic, if that leaves its close the chords it\n      -- needs (two for a full close, one for a half).\n      canTonic = function(u)\n        local need = (u.cad == \"PAC\" or u.cad == \"IAC\" or u.cad == \"DC\" or u.cad == \"EC\") and 2\n                     or ((u.cad ~= \"none\" and u.cad ~= \"open\") and 1 or 0)\n        return u.rel and #u.rel > need\n      end\n    end\n    changeAt, made = M.changeAt(plan, meter, tonicAt, canTonic)\n    if made then tonicStart = changeAt end\n  end\n  local timeline = M.harmony(plan, key, r, meter, M.stream(seed, \"harmony\"), colour, sch, changeAt, tonicStart)\n  local keyChange = M.keyChange(plan, timeline, key, r, meter, colour, changeAt)\n  M.raiseDominant(timeline, key, colour)\n  local borrowed = M.borrow(timeline, key, r, M.stream(seed, \"borrow\"), colour)\n  local applied = M.applied(timeline, plan, key, r, M.stream(seed, \"applied\"), colour)\n  -- (1.15) At a close, the Neapolitan or an augmented sixth before the V\n  -- (with Borrowed); a passing diminished seventh where the bass climbs a\n  -- tone (with Applied).\n  local chromatic = M.chromatic(timeline, plan, key, r, M.stream(seed, \"chroma\"), meter)\n  for _, sl in ipairs(M.passing(timeline, plan, key, r, M.stream(seed, \"passing\"), meter)) do\n    applied[#applied + 1] = sl\n  end\n  -- (1.16) And the common-tone diminished seventh, colouring a held I or V.\n  local commonTones = M.commonTone(timeline, plan, key, r, M.stream(seed, \"commontone\"), meter)\n  M.flavour(timeline, plan, key, r, M.stream(seed, \"colour\"), M.stream(seed, \"sixnine\"))\n  -- By the book, a half close with Mixed stands on a plain V: \"almost\n  -- invariably a triad, rather than a seventh chord\" (Open Music Theory,\n  -- \"Classical cadence types\"). Sevenths, chosen for sevenths everywhere,\n  -- keep theirs.\n  if book and colour == \"Mixed\" then\n    for _, u in ipairs(plan.units) do\n      if u.cad == \"HC\" then\n        local sl = M.chordAt(timeline, u.start + u.len - 1)\n        if sl and #sl.chord.pcs > 3 and not sl.flavour and not sl.borrowed and not sl.applied then\n          sl.chord = T.chord(sl.key or key, sl.degree, \"Triads\")\n          sl.halfTriad = true\n        end\n      end\n    end\n  end\n  M.push(timeline, meter, r, M.stream(seed, \"push\"))\n  M.invert(timeline, plan, key, r, M.stream(seed, \"invert\"), meter)\n  -- The chords part plays from its own copy, pulled late where it is; the\n  -- tune, the bass and the drums play on the beat.\n  local chordTl = r.chords and M.pull(timeline, meter, r, M.stream(seed, \"pull\")) or timeline\n\n  local lo, hi = M.melodyRange(key, r.register)\n  local ctx = { key = key, meter = meter, lo = lo, hi = hi, timeline = timeline,\n                rhythmRnd = M.stream(seed, \"rhythm\"), tensionRnd = M.stream(seed, \"tension\") }\n  local contour = CONTOURS[r.contour] or CONTOURS.Arch\n  ctx.target = function(step)\n    local t = step / math.max(1, plan.total)\n    return lo + 1 + contour(t) * (hi - lo - 2)\n  end\n\n  -- By the book the tune keeps clear of parallels with the bass each chord\n  -- stands on (a Measure's bass on the beat, a Phrase's under its own\n  -- chords) - not with a moving bass's passing notes, which keep clear of\n  -- the tune themselves: so a different bass still leaves the tune alone.\n  if book and r.chords then\n    local tl = (r.kind == \"Measure\") and timeline or chordTl\n    ctx.bassPcAt = function(step)\n      local sl = M.chordAt(tl, step)\n      return sl and bassPcOf(sl)\n    end\n  end\n\n  local parts = {}\n  local melody\n  if r.melody then\n    melody = M.melody(plan, ctx, r, M.stream(seed, \"melody\"))\n    parts[#parts + 1] = { name = \"Melody\", list = melody }\n  end\n\n  -- The second voice (1.10), under the tune; the chords go under both.\n  local second = melody and M.secondVoice(ctx, melody, r)\n  local front = melody\n  if second then\n    front = {}\n    for _, n in ipairs(melody) do front[#front + 1] = n end\n    for _, n in ipairs(second) do front[#front + 1] = n end\n  end\n\n  local arpName, lows\n  if r.chords then\n    -- The chords sit under the tune, so a tune in a low register pushes them\n    -- down, but never into the mud below C3.\n    local top = 69\n    if front then\n      local low = 127\n      for _, n in ipairs(front) do low = math.min(low, n.pitch) end\n      top = math.max(57, math.min(69, low - 1))\n    end\n    local list\n    list, arpName, lows = M.chordsPart(ctx, chordTl, r, M.stream(seed, \"chords\"),\n                                 { lo = math.max(43, top - 16), hi = top, bass = r.kind ~= \"Measure\",\n                                   book = book, tune = front, beatTl = timeline, melody = melody })\n    if book then list = M.clearResolutions(list, melody, r.kind ~= \"Measure\") end\n    parts[#parts + 1] = { name = \"Chords\", list = list }\n  end\n\n  if r.kind == \"Measure\" then\n    -- No drums in a Measure since 1.3 (drums are their own kind), but a\n    -- pulsing bass still plays the pattern a kick drum would, drawn as it\n    -- always was so the bass is unchanged.\n    local kick = M.kickPattern(meter, r, M.stream(seed, \"drums\"))\n    local bassList = M.bassPart(ctx, timeline, r, M.stream(seed, \"bass\"), kick, book and melody)\n    if book then M.spaceBass(bassList, timeline, lows) end\n    if r.bassPull == \"With the chords\" then M.pullBass(bassList, timeline, chordTl) end\n    parts[#parts + 1] = { name = \"Bass\", list = bassList }\n  end\n  -- (Last, so the other parts keep their channels.)\n  if second then parts[#parts + 1] = { name = \"Second voice\", list = second } end\n\n  -- Channels: in one item each part has its own; on tracks of their own\n  -- every part is on 1. (A drum idea, on 10, makes its own block: makeDrums.)\n  local oneItem = r.kind ~= \"Measure\" or r.layout == \"One item\"\n  local warp = M.swingWarp(meter, st.swing)\n  local block = { parts = {}, notes = {}, beats = plan.total / 4,\n                  layout = (oneItem and \"one\") or \"tracks\" }\n  for i, p in ipairs(parts) do\n    local chan = oneItem and (i - 1) or 0\n    local notes = toBlockNotes(p.list, chan, r.velocity, warp, meter, p.name)\n    block.parts[#block.parts + 1] = { name = p.name, notes = notes, chan = chan }\n    for _, n in ipairs(notes) do block.notes[#block.notes + 1] = n end\n  end\n  -- Fully ordered: Lua's sort is not stable, and may shuffle notes that\n  -- start together differently from one run to the next.\n  table.sort(block.notes, function(a, b)\n    if a.start ~= b.start then return a.start < b.start end\n    if a.chan ~= b.chan then return a.chan < b.chan end\n    if a.pitch ~= b.pitch then return a.pitch < b.pitch end\n    return a.len < b.len\n  end)\n\n  local what = r.kind\n  if r.kind == \"Phrase\" then what = what .. \" (\" .. r.content:lower() .. \")\" end\n  if r.kind == \"Measure\" then what = what .. \" (\" .. r.form:lower() .. \")\" end\n  block.name = (\"Good Idea %d - %s, %s, %s\"):format(seed, what, barsName(r.bars), M.keyName(key))\n\n  local said = { M.keyName(key), r.pace, r.groove }\n  if r.melody then said[#said + 1] = r.contour:lower() .. \" contour\" end\n  if r.chords then\n    said[#said + 1] = r.colour:lower()\n    if r.voicing ~= \"Close\" then said[#said + 1] = r.voicing:lower() .. \" voicing\" end\n    if sch then said[#said + 1] = sch.name:lower() .. \" progression\"\n    elseif schemaWhy then said[#said + 1] = \"walked (\" .. schemaWhy .. \")\" end\n    said[#said + 1] = M.valueName(M.BY_ID.chordPace, r.chordPace):lower()\n    said[#said + 1] = r.chordStyle:lower() .. ((r.chordStyle == \"Broken\" and arpName) and (\" (\" .. arpName .. \")\") or \"\")\n  end\n  if r.kind == \"Measure\" then said[#said + 1] = r.bass:lower() .. \" bass\" end\n  if r.figures ~= \"Plain\" then said[#said + 1] = r.figures:lower() end\n  if r.push ~= \"None\" then said[#said + 1] = r.push:lower() .. \" push\" end\n  if r.chords and r.pull ~= \"None\" then said[#said + 1] = r.pull:lower() .. \" pull\" end\n  if warp then said[#said + 1] = math.floor(st.swing) .. \"% swing\" end\n  if keyChange then said[#said + 1] = r.keyChange:lower() .. \" to \" .. M.keyName(keyChange.key) end\n\n  -- Each borrowed chord, said in full for the window.\n  local notes = {}\n  for _, sl in ipairs(borrowed) do\n    local b = sl.borrowed\n    b.bar = (sl.pushed and sl.s + 2 or sl.s) // meter.bar + 1\n    b.text = (\"%s (%s) in bar %d, from %s\"):format(b.name, b.numeral, b.bar, b.from)\n    notes[#notes + 1] = b\n  end\n\n  -- Each applied chord, said in full for the window.\n  local appliedNotes = {}\n  for _, sl in ipairs(applied) do\n    local a = sl.applied\n    -- (Named as the chord after it now is: flavoured or inverted, say.)\n    for i, x in ipairs(timeline) do\n      if x == sl and timeline[i + 1] then\n        local nx = timeline[i + 1]\n        a.to = nx.chord.name .. (nx.bassPos and (\"/\" .. T.noteName(nx.key, nx.bassPos)) or \"\")\n      end\n    end\n    a.bar = (sl.pushed and sl.s + 2 or sl.s) // meter.bar + 1\n    a.text = (\"%s (%s) in bar %d, %s %s\"):format(a.name, a.numeral, a.bar,\n                                                  a.passing and \"passing to\" or \"leading to\", a.to)\n    appliedNotes[#appliedNotes + 1] = a\n  end\n\n  -- (1.15) Each chromatic chord, said in full for the window.\n  local chromaticNotes = {}\n  local CHROMATIC_SAID = { N6 = \"the Neapolitan\", [\"It+6\"] = \"an Italian augmented sixth\",\n                           [\"Fr+6\"] = \"a French augmented sixth\", [\"Ger+6\"] = \"a German augmented sixth\",\n                           [\"Sw+6\"] = \"a Swiss augmented sixth\" }\n  for _, sl in ipairs(chromatic) do\n    local c = sl.chromatic\n    c.bar = (sl.pushed and sl.s + 2 or sl.s) // meter.bar + 1\n    c.text = (\"%s (%s, %s) in bar %d, before the V\"):format(c.name, c.numeral, CHROMATIC_SAID[c.kind], c.bar)\n    chromaticNotes[#chromaticNotes + 1] = c\n  end\n\n  -- (1.16) Each common-tone diminished seventh, said with the applied\n  -- chords.\n  for _, sl in ipairs(commonTones) do\n    local c = sl.commonTone\n    c.bar = sl.s // meter.bar + 1\n    c.text = (\"%s (%s, the common-tone diminished seventh) in bar %d, colouring %s\"):format(c.name, c.numeral, c.bar, c.over)\n    appliedNotes[#appliedNotes + 1] = c\n  end\n\n  local cadNames = { PAC = \"closes on the tonic\", IAC = \"closes on the third or fifth\",\n                     DC = \"a deceptive close (V to vi)\",\n                     HC = \"ends on the dominant (open)\", open = \"ends open, to loop\", none = \"\" }\n  return {\n    seed = seed, r = r, key = key, plan = plan, timeline = timeline, melody = melody,\n    block = block,\n    summary = table.concat(said, \"  /  \"),\n    chords = M.chordLine(chordTl, meter),\n    chordTimeline = chordTl,\n    shape = plan.shape,\n    ending = cadNames[plan.ending] or \"\",\n    borrowed = notes,\n    applied = appliedNotes,\n    chromatic = chromaticNotes,\n    keyChange = keyChange and {\n      at = keyChange.at, key = keyChange.key, truck = keyChange.truck,\n      text = (\"%s to %s at bar %d%s\"):format(\n        ({ [\"Step up\"] = \"Up a whole tone\", [\"Half step up\"] = \"Up a semitone\", [\"Truck driver\"] = \"Up a whole tone\" })[r.keyChange],\n        M.keyName(keyChange.key), keyChange.at // meter.bar + 1,\n        keyChange.truck and (\", through its V (\" .. keyChange.truck.chord.name .. \") \u00e2\u0080\u0094 the truck driver\") or \"\"),\n    } or nil,\n    schema = sch and sch.name or nil,\n  }\nend\n\n-- A Drums idea: one part, on channel 10, in one item.\nfunction M.makeDrums(st, meter, seed, r)\n  local total = r.bars * meter.bar\n  local list, info = M.drumIdea(meter, r, M.stream(seed, \"kit\"),\n                                (r.ghosts ~= \"Off\") and M.stream(seed, \"ghost\") or nil)\n  local notes = toBlockNotes(list, 9, r.velocity, M.swingWarp(meter, st.swing), meter, \"Drums\")\n  local block = { parts = { { name = \"Drums\", notes = notes, chan = 9, drums = true } },\n                  notes = {}, beats = total / 4, layout = \"one\" }\n  for i, n in ipairs(notes) do block.notes[i] = n end\n  local style = info.style:lower()\n  block.name = (\"Good Idea %d - Drums (%s), %s\"):format(seed, style, barsName(r.bars))\n  local said = { info.style, r.cymbal == \"Ride\" and \"ride\" or \"hi-hats\", r.pace, r.groove }\n  if r.figures ~= \"Plain\" then said[#said + 1] = r.figures:lower() end\n  if M.swingWarp(meter, st.swing) then said[#said + 1] = math.floor(st.swing) .. \"% swing\" end\n  local fills = (#info.fills == 0) and \"no fills\"\n                or ((#info.fills == 1 and \"a fill in bar \" or \"fills in bars \") .. table.concat(info.fills, \", \"))\n  return {\n    seed = seed, r = r, key = T.key(1, 1), meter = meter,\n    plan = { units = {}, total = total, shape = \"\", ending = \"\" },\n    timeline = {}, chordTimeline = {}, melody = nil,\n    block = block, chromatic = {}, applied = {},\n    summary = table.concat(said, \"  /  \"),\n    chords = \"\",\n    shape = \"\",\n    ending = fills,\n    borrowed = {},\n    drums = info,\n  }\nend\n\n-- The settings that would give this idea back with nothing left to chance:\n-- every Any on screen replaced by what it rolled. A hidden setting does not\n-- change the idea, and is left alone so it is still Any when it shows again.\nfunction M.keep(st, idea)\n  for id in pairs(idea.r.rolled) do\n    local s = M.BY_ID[id]\n    if s and st[id] == \"Any\" and M.shows(s, st) then st[id] = idea.r[id] end\n  end\n  return st\nend\n\nreturn M\n", "good-idea/gi_theory.lua": "--[[ Good Idea - keys, chords and the order chords come in.\n\n     Pure Lua. Nothing in this file touches REAPER or ImGui: the harmony is the\n     part that has to be right, and here it can be run and checked by\n     tests/test_theory.lua rather than only by reading.\n\n     Two ways of naming a note run through the whole engine:\n\n       - a MIDI pitch, 0..127;\n       - a scale position, an integer counting scale notes from the key's root\n         in MIDI octave -1. Position 0 is the root at pitch 0..11, position n\n         (the scale's length) is the root an octave up, and so on.\n\n     Every diatonic move is integer arithmetic on positions - a third above is\n     +2, whatever the scale - and pitches only appear at the edges. Scale\n     degrees are 0-based: degree 0 is the tonic.\n\n     The keys, positions and spelling are Midi Catalogue's (and so ScaleView's\n     and Starting Blocks'), copied unchanged. The chord table is Starting\n     Blocks', copied unchanged and used here only to name chords. What is new\n     is at the bottom: chords built on a degree, and the walk that decides\n     which chord follows which.\n]]\n\nlocal M = {}\n\n------------------------------------------------------------------------------\n-- Keys\n--\n-- ScaleView for REAPER's roots and scales, unchanged, the same tables Starting\n-- Blocks copies, so all three apps agree on what a scale is and what to call\n-- its notes. test_theory.lua asserts they still match. Do not tidy them\n-- independently.\n------------------------------------------------------------------------------\n\nlocal LETTER_PC  = { 0, 2, 4, 5, 7, 9, 11 }        -- C D E F G A B\nlocal LETTERS    = { \"C\", \"D\", \"E\", \"F\", \"G\", \"A\", \"B\" }\nlocal ACCIDENTAL = { [-2] = \"bb\", [-1] = \"b\", [0] = \"\", [1] = \"#\", [2] = \"x\" }\n\nM.ROOTS = {\n  { name = \"C\",  letter = 0, acc =  0 }, { name = \"C#\", letter = 0, acc =  1 },\n  { name = \"Db\", letter = 1, acc = -1 }, { name = \"D\",  letter = 1, acc =  0 },\n  { name = \"D#\", letter = 1, acc =  1 }, { name = \"Eb\", letter = 2, acc = -1 },\n  { name = \"E\",  letter = 2, acc =  0 }, { name = \"F\",  letter = 3, acc =  0 },\n  { name = \"F#\", letter = 3, acc =  1 }, { name = \"Gb\", letter = 4, acc = -1 },\n  { name = \"G\",  letter = 4, acc =  0 }, { name = \"G#\", letter = 4, acc =  1 },\n  { name = \"Ab\", letter = 5, acc = -1 }, { name = \"A\",  letter = 5, acc =  0 },\n  { name = \"A#\", letter = 5, acc =  1 }, { name = \"Bb\", letter = 6, acc = -1 },\n  { name = \"B\",  letter = 6, acc =  0 }, { name = \"Cb\", letter = 0, acc = -1 },\n}\n\nM.SCALES = {\n  { name = \"Major\",      iv = {0,2,4,5,7,9,11},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Minor\",      iv = {0,2,3,5,7,8,10},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Harm Minor\", iv = {0,2,3,5,7,8,11},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Ionian\",     iv = {0,2,4,5,7,9,11},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Dorian\",     iv = {0,2,3,5,7,9,10},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Phrygian\",   iv = {0,1,3,5,7,8,10},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Lydian\",     iv = {0,2,4,6,7,9,11},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Mixolydian\", iv = {0,2,4,5,7,9,10},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Aeolian\",    iv = {0,2,3,5,7,8,10},   letters = {0,1,2,3,4,5,6} },\n  { name = \"Maj Pent\",   iv = {0,2,4,7,9},        letters = {0,1,2,4,5} },\n  { name = \"Min Pent\",   iv = {0,3,5,7,10},       letters = {0,2,3,4,6} },\n  { name = \"Maj Blues\",  iv = {0,2,3,4,7,9},      letters = {0,1,2,2,4,5} },\n  { name = \"Min Blues\",  iv = {0,3,5,6,7,10},     letters = {0,2,3,4,4,6} },\n  { name = \"Whole Tone\", iv = {0,2,4,6,8,10},     letters = {0,1,2,3,4,5} },\n  { name = \"Dim W-H\",    iv = {0,2,3,5,6,8,9,11}, letters = {0,1,2,3,4,5,5,6} },\n  { name = \"Dim H-W\",    iv = {0,1,3,4,6,7,9,10}, letters = {0,1,2,2,3,4,5,6} },\n}\n\nlocal NUMERALS = { \"I\", \"II\", \"III\", \"IV\", \"V\", \"VI\", \"VII\", \"VIII\" }\n\n-- A key is the pair of indices the window picks. A chord scale (M.chordKey)\n-- is a key that also carries its own intervals: the same scale with a note\n-- or two bent to the chord sounding over it.\nfunction M.key(root, scale) return { root = root or 1, scale = scale or 1 } end\n\nlocal function ivOf(key) return key.iv or M.SCALES[key.scale].iv end\n\n-- The same scale `semis` semitones up (1.12, a key change): every position\n-- sounds that much higher. Its key note is spelled the way that gives the\n-- scale the fewest sharps and flats (D, not C##; Eb, not D#), and where it\n-- passes B it is lifted an octave (B up a tone is C#, above, not below).\nfunction M.transpose(key, semis)\n  local from = M.rootPc(key) + (key.lift or 0)\n  local want = (from + semis) % 12\n  local best, bestCost\n  for i, rt in ipairs(M.ROOTS) do\n    local pc = M.rootPc({ root = i })\n    if pc == want then\n      local k = { root = i, scale = key.scale, iv = key.iv }\n      local cost = 0\n      for pos = 0, #ivOf(k) - 1 do\n        local name = M.noteName(k, pos)\n        cost = cost + #name - 1\n        if name:find(\"##\") or name:find(\"bb\") then cost = cost + 10 end\n      end\n      if not bestCost or cost < bestCost then best, bestCost = k, cost end\n    end\n  end\n  best.lift = from + semis - want\n  return best\nend\nM.ivOf = ivOf\n\nfunction M.scaleLen(key) return #ivOf(key) end\n\nfunction M.rootPc(key)\n  local rt = M.ROOTS[key.root]\n  return (LETTER_PC[rt.letter + 1] + rt.acc + 12) % 12\nend\n\n------------------------------------------------------------------------------\n-- Positions and pitches\n------------------------------------------------------------------------------\n\n-- The MIDI pitch of a scale position.\nfunction M.pitch(key, pos)\n  local iv  = ivOf(key)\n  local n   = #iv\n  local oct = math.floor(pos / n)\n  local k   = pos - oct * n\n  return M.rootPc(key) + (key.lift or 0) + iv[k + 1] + 12 * oct\nend\n\n-- The highest position at or below a pitch. Every pitch has one, because the\n-- root is in every octave.\nfunction M.floorPos(key, midi)\n  local iv   = ivOf(key)\n  local n    = #iv\n  local root = M.rootPc(key) + (key.lift or 0)\n  local oct  = math.floor((midi - root) / 12)\n  local kmax = 0\n  for k = 1, n do\n    if root + iv[k] + 12 * oct <= midi then kmax = k - 1 end\n  end\n  return oct * n + kmax\nend\n\n-- The position of a pitch that is in the scale, or nil for one that is not.\nfunction M.posOf(key, midi)\n  local s = M.floorPos(key, midi)\n  if M.pitch(key, s) == midi then return s end\n  return nil\nend\n\n-- The nearest position to any pitch. A pitch exactly between two scale notes\n-- goes the way `lean` says (+1 up, -1 down), and down when it says nothing.\nfunction M.nearestPos(key, midi, lean)\n  local lo = M.floorPos(key, midi)\n  if M.pitch(key, lo) == midi then return lo end\n  local dLo = midi - M.pitch(key, lo)\n  local dHi = M.pitch(key, lo + 1) - midi\n  if dLo < dHi then return lo end\n  if dHi < dLo then return lo + 1 end\n  return (lean or -1) > 0 and lo + 1 or lo\nend\n\nfunction M.pc(key, pos) return M.pitch(key, pos) % 12 end\n\n-- Spelled for the key: the seventh of F# major comes out E#, not F.\nfunction M.noteName(key, pos)\n  local sc  = M.SCALES[key.scale]\n  local n   = #ivOf(key)\n  local oct = math.floor(pos / n)\n  local k   = pos - oct * n\n  local letter = (M.ROOTS[key.root].letter + sc.letters[k + 1]) % 7\n  local acc = M.pitch(key, pos) % 12 - LETTER_PC[letter + 1]\n  if acc >  6 then acc = acc - 12 end\n  if acc < -6 then acc = acc + 12 end\n  return LETTERS[letter + 1] .. (ACCIDENTAL[acc] or \"?\")\nend\n\n-- A pitch named with its octave, C4 being middle C (60). Out of the key, the\n-- sharp spelling.\nlocal SHARP_NAMES = { \"C\", \"C#\", \"D\", \"D#\", \"E\", \"F\", \"F#\", \"G\", \"G#\", \"A\", \"A#\", \"B\" }\nfunction M.pitchName(midi, key)\n  local oct = math.floor(midi / 12) - 1\n  if key then\n    local s = M.posOf(key, midi)\n    if s then return M.noteName(key, s) .. oct end\n  end\n  return SHARP_NAMES[midi % 12 + 1] .. oct\nend\n\n------------------------------------------------------------------------------\n-- Degrees\n------------------------------------------------------------------------------\n\n-- Read off the scale rather than assumed, so the modes and the blues scales\n-- come out right: the vii of major is diminished, the III of minor is major.\nfunction M.degreeQuality(key, degree)\n  local p  = M.pitch(key, degree)\n  local r3 = M.pitch(key, degree + 2) - p\n  local r5 = M.pitch(key, degree + 4) - p\n  if r3 == 4 and r5 == 7 then return \"major\"      end\n  if r3 == 3 and r5 == 7 then return \"minor\"      end\n  if r3 == 3 and r5 == 6 then return \"diminished\" end\n  if r3 == 4 and r5 == 8 then return \"augmented\"  end\n  return \"other\"\nend\n\nfunction M.degreeNumeral(key, degree, ascii)\n  local q = M.degreeQuality(key, degree)\n  local n = NUMERALS[(degree % 8) + 1]\n  if q == \"minor\" or q == \"diminished\" then n = n:lower() end\n  if q == \"diminished\" then n = n .. (ascii and \"dim\" or \"\\u{00B0}\") end\n  if q == \"augmented\"  then n = n .. (ascii and \"aug\" or \"+\") end\n  return n\nend\n\nM.DEGREE_TITLES = { \"Tonic\", \"Supertonic\", \"Mediant\", \"Subdominant\",\n                    \"Dominant\", \"Submediant\", \"Leading Tone\" }\n\n-- Starting Blocks' degree names. Only the seven-note scales carry them, and\n-- the seventh is a leading tone only when it leans on the tonic a semitone up.\nfunction M.degreeTitle(key, degree)\n  if M.scaleLen(key) ~= 7 then return \"Degree \" .. (degree + 1) end\n  if degree == 6 and M.pitch(key, 7) - M.pitch(key, 6) ~= 1 then return \"Subtonic\" end\n  return M.DEGREE_TITLES[degree + 1] or (\"Degree \" .. (degree + 1))\nend\n\n-- The seventh degree leans on the tonic only when it sits a semitone under\n-- it. Only then is it a leading tone, and only then does it want resolving\n-- and not doubling.\nfunction M.leadingTonePc(key)\n  local n = M.scaleLen(key)\n  if n ~= 7 then return nil end\n  if M.pitch(key, 7) - M.pitch(key, 6) == 1 then return M.pc(key, 6) end\n  return nil\nend\n\n------------------------------------------------------------------------------\n-- Chords\n--\n-- Starting Blocks' chord tables, copied unchanged: one row per chord carrying\n-- its own name, symbol and intervals (semitones from the chord's root), in\n-- the families of Wikipedia's list of chords. Here they only name what the\n-- scale builds (Good Idea's chords are always in key). Do not tidy them\n-- independently of Starting Blocks.\n------------------------------------------------------------------------------\n\nM.FAMILIES = { \"Diatonic\", \"Triads\", \"6ths & 7ths\", \"Extended\", \"Altered\",\n               \"Sus & Add\", \"Quartal\", \"Named\" }\n\nlocal TR, S7, EX, AL, SA, QU, NA = 2, 3, 4, 5, 6, 7, 8   -- indices into FAMILIES\n\nM.CHORDS = {\n  { sym=\"maj\",  name=\"Major\",                  iv={0,4,7},          fam=TR },\n  { sym=\"m\",    name=\"Minor\",                  iv={0,3,7},          fam=TR },\n  { sym=\"dim\",  name=\"Diminished\",             iv={0,3,6},          fam=TR },\n  { sym=\"aug\",  name=\"Augmented\",              iv={0,4,8},          fam=TR },\n  { sym=\"b5\",   name=\"Flat Five\",              iv={0,4,6},          fam=TR },\n  { sym=\"5\",    name=\"Fifth (Power)\",          iv={0,7},            fam=TR },\n\n  { sym=\"6\",       name=\"Sixth\",                    iv={0,4,7,9},     fam=S7 },\n  { sym=\"m6\",      name=\"Minor Sixth\",              iv={0,3,7,9},     fam=S7 },\n  { sym=\"6/9\",     name=\"Six-Nine\",                 iv={0,4,7,9,14},  fam=S7 },\n  { sym=\"m6/9\",    name=\"Minor Six-Nine\",           iv={0,3,7,9,14},  fam=S7 },\n  { sym=\"7\",       name=\"Dominant Seventh\",         iv={0,4,7,10},    fam=S7 },\n  { sym=\"maj7\",    name=\"Major Seventh\",            iv={0,4,7,11},    fam=S7 },\n  { sym=\"m7\",      name=\"Minor Seventh\",            iv={0,3,7,10},    fam=S7 },\n  { sym=\"mMaj7\",   name=\"Minor-Major Seventh\",      iv={0,3,7,11},    fam=S7 },\n  { sym=\"m7b5\",    name=\"Half-Diminished Seventh\",  iv={0,3,6,10},    fam=S7 },\n  { sym=\"dim7\",    name=\"Diminished Seventh\",       iv={0,3,6,9},     fam=S7 },\n  { sym=\"7#5\",     name=\"Augmented Seventh\",        iv={0,4,8,10},    fam=S7 },\n  { sym=\"maj7#5\",  name=\"Augmented Major Seventh\",  iv={0,4,8,11},    fam=S7 },\n  { sym=\"7b5\",     name=\"Seventh Flat Five\",        iv={0,4,6,10},    fam=S7 },\n  { sym=\"dimMaj7\", name=\"Diminished Major Seventh\", iv={0,3,6,11},    fam=S7 },\n  { sym=\"7/6\",     name=\"Seven Six\",                iv={0,4,7,9,10},  fam=S7 },\n\n  { sym=\"9\",     name=\"Ninth\",               iv={0,4,7,10,14},       fam=EX },\n  { sym=\"maj9\",  name=\"Major Ninth\",         iv={0,4,7,11,14},       fam=EX },\n  { sym=\"m9\",    name=\"Minor Ninth\",         iv={0,3,7,10,14},       fam=EX },\n  { sym=\"mMaj9\", name=\"Minor-Major Ninth\",   iv={0,3,7,11,14},       fam=EX },\n  { sym=\"11\",    name=\"Eleventh\",            iv={0,4,7,10,14,17},    fam=EX },\n  { sym=\"maj11\", name=\"Major Eleventh\",      iv={0,4,7,11,14,17},    fam=EX },\n  { sym=\"m11\",   name=\"Minor Eleventh\",      iv={0,3,7,10,14,17},    fam=EX },\n  { sym=\"13\",    name=\"Thirteenth\",          iv={0,4,7,10,14,17,21}, fam=EX },\n  { sym=\"maj13\", name=\"Major Thirteenth\",    iv={0,4,7,11,14,17,21}, fam=EX },\n  { sym=\"m13\",   name=\"Minor Thirteenth\",    iv={0,3,7,10,14,17,21}, fam=EX },\n\n  { sym=\"7b9\",       name=\"Seventh Flat Nine\",             iv={0,4,7,10,13},    fam=AL },\n  { sym=\"7#9\",       name=\"Seventh Sharp Nine\",            iv={0,4,7,10,15},    fam=AL },\n  { sym=\"7#11\",      name=\"Seventh Sharp Eleven\",          iv={0,4,7,10,18},    fam=AL },\n  { sym=\"7b13\",      name=\"Seventh Flat Thirteen\",         iv={0,4,7,10,20},    fam=AL },\n  { sym=\"7#5b9\",     name=\"Seventh Sharp Five Flat Nine\",  iv={0,4,8,10,13},    fam=AL },\n  { sym=\"7#5#9\",     name=\"Seventh Sharp Five Sharp Nine\", iv={0,4,8,10,15},    fam=AL },\n  { sym=\"7b5b9\",     name=\"Seventh Flat Five Flat Nine\",   iv={0,4,6,10,13},    fam=AL },\n  { sym=\"7alt\",      name=\"Altered Dominant\",              iv={0,4,8,10,13,15}, fam=AL },\n  { sym=\"13b9\",      name=\"Thirteenth Flat Nine\",          iv={0,4,7,10,13,21}, fam=AL },\n  { sym=\"maj7#11\",   name=\"Major Seventh Sharp Eleven\",    iv={0,4,7,11,18},    fam=AL },\n  { sym=\"m9b5\",      name=\"Minor Ninth Flat Five\",         iv={0,3,6,10,14},    fam=AL },\n  { sym=\"9#5\",       name=\"Ninth Augmented Fifth\",         iv={0,4,8,10,14},    fam=AL },\n  { sym=\"9b5\",       name=\"Ninth Flat Fifth\",              iv={0,4,6,10,14},    fam=AL },\n  { sym=\"9#11\",      name=\"Augmented Eleventh\",            iv={0,4,7,10,14,18}, fam=AL },\n  { sym=\"maj7#5#11\", name=\"Augmented Major Seventh Sharp Eleven\", iv={0,4,8,11,18}, fam=AL },\n  { sym=\"13b9b5\",    name=\"Thirteenth Flat Nine Flat Five\", iv={0,4,6,10,13,21}, fam=AL },\n\n  { sym=\"sus2\",     name=\"Suspended Second\",             iv={0,2,7},       fam=SA },\n  { sym=\"sus4\",     name=\"Suspended Fourth\",             iv={0,5,7},       fam=SA },\n  { sym=\"7sus4\",    name=\"Seventh Suspended Fourth\",     iv={0,5,7,10},    fam=SA },\n  { sym=\"9sus4\",    name=\"Ninth Suspended Fourth\",       iv={0,5,7,10,14}, fam=SA },\n  { sym=\"maj7sus4\", name=\"Major Seventh Suspended Fourth\", iv={0,5,7,11},  fam=SA },\n  { sym=\"add9\",     name=\"Added Ninth\",                  iv={0,4,7,14},    fam=SA },\n  { sym=\"m(add9)\",  name=\"Minor Added Ninth\",            iv={0,3,7,14},    fam=SA },\n  { sym=\"add4\",     name=\"Added Fourth\",                 iv={0,4,5,7},     fam=SA },\n  { sym=\"add11\",    name=\"Added Eleventh\",               iv={0,4,7,17},    fam=SA },\n  { sym=\"add13\",    name=\"Added Thirteenth\",             iv={0,4,7,21},    fam=SA },\n  { sym=\"add2\",     name=\"Added Second\",                 iv={0,2,4,7},     fam=SA },\n  { sym=\"m(add2)\",  name=\"Minor Added Second\",           iv={0,2,3,7},     fam=SA },\n\n  { sym=\"Q4/3\",    name=\"Quartal Triad\",       iv={0,5,10},    fam=QU },\n  { sym=\"Q4/4\",    name=\"Quartal Tetrad\",      iv={0,5,10,15}, fam=QU },\n  { sym=\"Q5/3\",    name=\"Quintal Triad\",       iv={0,7,14},    fam=QU },\n  { sym=\"WT3\",     name=\"Whole-Tone Trichord\", iv={0,2,4},     fam=QU },\n  { sym=\"cluster\", name=\"Chromatic Cluster\",   iv={0,1,2},     fam=QU },\n  { sym=\"dia-cl\",  name=\"Diatonic Cluster\",    iv={0,2,4,5},   fam=QU },\n\n  -- Voiced as they stand rather than reduced to a pitch-class set: the list\n  -- gives the Tristan chord as 0 3 6 10, which makes it a half-diminished\n  -- seventh and indistinguishable from one.\n  { sym=\"Mystic\",    name=\"Mystic (Scriabin)\",   iv={0,6,10,16,21,26}, fam=NA },\n  { sym=\"Petrushka\", name=\"Petrushka\",           iv={0,4,6,7,10,13},   fam=NA },\n  { sym=\"Tristan\",   name=\"Tristan\",             iv={0,6,10,15},       fam=NA },\n  { sym=\"So What\",   name=\"So What\",             iv={0,5,10,15,19},    fam=NA },\n  { sym=\"Dream\",     name=\"Dream\",               iv={0,5,6,7},         fam=NA },\n  { sym=\"Vienna\",    name=\"Viennese Trichord\",   iv={0,1,6},           fam=NA },\n  { sym=\"Vienna II\", name=\"Viennese Trichord II\", iv={0,6,7},          fam=NA },\n  { sym=\"Napoleon\",  name=\"Ode-to-Napoleon\",     iv={0,1,4,5,8,9},     fam=NA },\n  { sym=\"Elektra\",   name=\"Elektra\",             iv={0,7,9,13,16},     fam=NA },\n  { sym=\"Farben\",    name=\"Farben\",              iv={0,8,11,16,21},    fam=NA },\n  { sym=\"It+6\",      name=\"Italian Sixth\",       iv={0,4,10},          fam=NA },\n  { sym=\"Fr+6\",      name=\"French Sixth\",        iv={0,4,6,10},        fam=NA },\n  { sym=\"Ger+6\",     name=\"German Sixth\",        iv={0,4,7,10},        fam=NA },\n}\n\n\n\n-- The symbol a set of pitch classes goes by, read off the chord tables: the\n-- first chord whose notes are exactly these, from this root. \"\" for a major\n-- triad, nil for a set with no name here.\nfunction M.symbolOf(pcs, root)\n  local want = {}\n  for _, pc in ipairs(pcs) do want[(pc - root) % 12] = true end\n  local n = 0\n  for _ in pairs(want) do n = n + 1 end\n  for _, c in ipairs(M.CHORDS) do\n    local have, m = {}, 0\n    for _, iv in ipairs(c.iv) do\n      if not have[iv % 12] then have[iv % 12] = true; m = m + 1 end\n    end\n    if m == n then\n      local same = true\n      for k in pairs(want) do if not have[k] then same = false end end\n      if same then return (c.sym == \"maj\") and \"\" or c.sym end\n    end\n  end\n  return nil\nend\n\n------------------------------------------------------------------------------\n-- Chords on a degree\n--\n-- Stacked from the scale itself - every other scale note up from the degree -\n-- so a chord is always in key, in any of the sixteen scales. A chord carries\n-- its positions (for the melody, which works in positions), its pitch\n-- classes root first (for voicing), and a set of them (`has`, for asking\n-- \"is this note on the chord?\").\n------------------------------------------------------------------------------\n\nM.COLOURS = { \"Triads\", \"Sevenths\", \"Mixed\" }\n\nlocal function norm(key, degree)\n  local n = M.scaleLen(key)\n  return ((degree % n) + n) % n\nend\nM.normDegree = norm\n\n-- The interval, in semitones, from the tonic up to a degree's root.\nfunction M.rootAbove(key, degree)\n  return (M.pc(key, norm(key, degree)) - M.pc(key, 0)) % 12\nend\n\n-- Which of tonic, subdominant and dominant a degree belongs to, read off its\n-- root's distance from the tonic rather than its number, so it means the same\n-- in every scale: the tonic and the chords a third either side of it (iii,\n-- vi) are T; the second and fourth are S; the fifth and the seventh are D.\nfunction M.functionOf(key, degree)\n  local up = M.rootAbove(key, degree)\n  if up == 0 or up == 3 or up == 4 or up == 8 or up == 9 then return \"T\" end\n  if up == 1 or up == 2 or up == 5 or up == 6 then return \"S\" end\n  return \"D\"\nend\n\n-- The scale steps above a degree that sound `semis` semitones above it, the\n-- first of the candidates the scale has, or nil.\nlocal function stepFor(key, degree, cands)\n  local n = M.scaleLen(key)\n  for _, semis in ipairs(cands) do\n    for o = 1, n do\n      if M.pitch(key, degree + o) - M.pitch(key, degree) == semis then return o end\n    end\n  end\nend\n\n-- The scale steps above the degree that make the chord.\n--\n-- In a seven-note scale, every other note: the textbook stack. A scale of\n-- another length stacks into nonsense that way (every other note of C major\n-- pentatonic is C E A), so there the chord is built by ear: a third if the\n-- scale has one, else a sus chord, then a fifth if it has one.\n--\n-- Mixed is how a player colours a progression: a seventh where it pulls (ii,\n-- V, vii, VII), an added ninth on the other major and minor chords, a plain\n-- triad elsewhere.\nfunction M.chordShape(key, degree, colour)\n  local wantSeventh = colour == \"Sevenths\"\n  local wantNinth = false\n  if colour == \"Mixed\" then\n    local q = M.degreeQuality(key, norm(key, degree))\n    local up = M.rootAbove(key, degree)\n    if up == 2 or up == 7 or up == 10 or up == 11 then wantSeventh = true\n    elseif q == \"major\" or q == \"minor\" then wantNinth = true end\n  end\n\n  local out\n  if M.scaleLen(key) == 7 then\n    out = { 0, 2, 4 }\n    if wantSeventh then out[4] = 6 end\n  else\n    out = { 0 }\n    local third = stepFor(key, degree, { 4, 3 })\n    local semis = third and (M.pitch(key, degree + third) - M.pitch(key, degree))\n    third = third or stepFor(key, degree, { 5, 2 })\n    -- A sharp fifth only over a major third (an augmented chord); over a\n    -- minor third it would be a major chord upside down.\n    local fifth = stepFor(key, degree, (semis == 4 and { 7, 8, 6 }) or (semis == 3 and { 7, 6 }) or { 7 })\n    if third then out[#out + 1] = third end\n    if fifth and fifth ~= third then out[#out + 1] = fifth end\n    if wantSeventh then\n      local sev = stepFor(key, degree, { 10, 11 })\n      if sev then out[#out + 1] = sev end\n    end\n  end\n  -- Only a whole-tone ninth is added: the flat ninth over iii is a clash.\n  if wantNinth then\n    local nine = stepFor(key, degree, { 2 })\n    if nine then out[#out + 1] = nine + M.scaleLen(key) end\n  end\n  return out\nend\n\nfunction M.chord(key, degree, colour)\n  local d = norm(key, degree)\n  local ch = { degree = d, pos = {}, pcs = {}, has = {}, colour = colour or \"Triads\" }\n  for i, o in ipairs(M.chordShape(key, d, colour)) do\n    ch.pos[i] = d + o\n    ch.pcs[i] = M.pc(key, d + o)\n    ch.has[ch.pcs[i]] = true\n  end\n  ch.rootPc = ch.pcs[1]\n  ch.quality = M.degreeQuality(key, d)\n  ch.name = M.chordName(key, ch)\n  ch.numeral = M.degreeNumeral(key, d)\n  ch.nine = M.ninthOf(key, d)\n  return ch\nend\n\n-- Named the way a player writes it: Am7, G, Bdim, Fadd9. A stack the chord\n-- table has no name for (some of the blues and pentatonic stacks) is spelled\n-- out instead.\nfunction M.chordName(key, ch)\n  local root = M.noteName(key, ch.degree)\n  local sym = M.symbolOf(ch.pcs, ch.rootPc)\n  if sym then return root .. sym end\n  -- A third and no fifth: what the pentatonic and blues scales give where\n  -- they have no fifth above a note.\n  if #ch.pcs == 2 then\n    local third = (ch.pcs[2] - ch.pcs[1]) % 12\n    if third == 3 then return root .. \"m(no5)\" end\n    if third == 4 then return root .. \"(no5)\" end\n  end\n  local names = {}\n  for _, p in ipairs(ch.pos) do names[#names + 1] = M.noteName(key, p) end\n  return root .. \"(\" .. table.concat(names, \" \") .. \")\"\nend\n\n-- Does a scale position sound a note of the chord?\nfunction M.onChord(key, ch, pos) return ch.has[M.pc(key, pos)] == true end\n\n------------------------------------------------------------------------------\n-- Flavours (docs/decisions/0018-flavours-voicings-and-inversions.md)\n--\n-- Other ways to colour a chord on a degree, every one stacked from the scale\n-- so it stays in key. Each is offered only where its interval is the real\n-- one: a sus4 needs a perfect fourth above the root (F in C major has a\n-- tritone there, so no Fsus4), a sus2 or an added 2nd a whole tone, a 6th\n-- a major sixth, a 9th a whole-tone ninth. \"dim\" is the diminished seventh\n-- chord a third above the root: the chord's upper notes without its root,\n-- the way G7 becomes Bm7b5 (G9 without the G) - offered only where that\n-- chord is diminished.\n--\n--   sus4   root, fourth, fifth (and the seventh, if the chord had one: 7sus4)\n--   sus2   root, second, fifth\n--   add2   the triad and a whole-tone 2nd, voiced inside, next to the root\n--   add9   the triad and its ninth, voiced on top (`ninthUp`)\n--   9      a seventh chord and its ninth, on top: Dm9, G9\n--   6      the triad and its major sixth: C6, Dm6\n--   dim    the diminished seventh chord a third up\n------------------------------------------------------------------------------\n\nM.FLAVOURS = { \"sus4\", \"sus2\", \"add2\", \"add9\", \"9\", \"6\", \"dim\" }\n\nlocal function semisAbove(key, degree, steps)\n  return M.pitch(key, degree + steps) - M.pitch(key, degree)\nend\n\n-- The scale steps above the degree for a flavour, or nil where it is not\n-- the real thing in this key. `seventh`: the chord it replaces had one.\nfunction M.flavourShape(key, degree, flavour, seventh)\n  if M.scaleLen(key) ~= 7 then return nil end\n  local q = M.degreeQuality(key, degree)\n  local triad = q == \"major\" or q == \"minor\"\n  if flavour == \"sus4\" then\n    if not triad or semisAbove(key, degree, 3) ~= 5 then return nil end\n    if seventh then return { 0, 3, 4, 6 } end\n    return { 0, 3, 4 }\n  elseif flavour == \"sus2\" then\n    if seventh or not triad or semisAbove(key, degree, 1) ~= 2 then return nil end\n    return { 0, 1, 4 }\n  elseif flavour == \"add2\" or flavour == \"add9\" then\n    if seventh or not triad or semisAbove(key, degree, 1) ~= 2 then return nil end\n    return (flavour == \"add2\") and { 0, 1, 2, 4 } or { 0, 2, 4, 8 }\n  elseif flavour == \"9\" then\n    if not seventh or not triad or semisAbove(key, degree, 8) ~= 14 then return nil end\n    return { 0, 2, 4, 6, 8 }\n  elseif flavour == \"6\" then\n    if not triad or semisAbove(key, degree, 5) ~= 9 then return nil end\n    return { 0, 2, 4, 5 }\n  elseif flavour == \"dim\" then\n    if M.degreeQuality(key, degree + 2) ~= \"diminished\" then return nil end\n    return { 2, 4, 6, 8 }\n  elseif flavour == \"6/9\" then\n    -- (1.12: a 6 with the whole-tone ninth on top - not in FLAVOURS, so the\n    -- flavours drawn before are drawn the same; a 6 may become one.)\n    if seventh or not triad or semisAbove(key, degree, 5) ~= 9 or semisAbove(key, degree, 1) ~= 2 then return nil end\n    return { 0, 2, 4, 5, 8 }\n  end\nend\n\n-- The chord on a degree with a flavour, or nil. It keeps the degree it\n-- stands for (`degree`), so the walk, the cadences and the tune read it as\n-- the chord it colours; `flavour` says how.\nfunction M.flavourChord(key, degree, flavour, seventh)\n  local d = norm(key, degree)\n  local shape = M.flavourShape(key, d, flavour, seventh)\n  if not shape then return nil end\n  local base = d + shape[1]\n  local ch = { degree = norm(key, base), pos = {}, pcs = {}, has = {}, colour = \"Mixed\",\n               flavour = flavour, stands = d }\n  for i, o in ipairs(shape) do\n    ch.pos[i] = d + o\n    ch.pcs[i] = M.pc(key, d + o)\n    ch.has[ch.pcs[i]] = true\n  end\n  ch.rootPc = ch.pcs[1]\n  ch.quality = M.degreeQuality(key, ch.degree)\n  ch.numeral = M.degreeNumeral(key, ch.degree)\n  ch.addInside = flavour == \"add2\" or nil\n  ch.ninthUp = (flavour == \"add9\" or flavour == \"9\" or flavour == \"6/9\") or nil\n  ch.nine = M.ninthOf(key, ch.degree)\n  ch.name = M.chordName(key, ch)\n  -- An added 2nd and an added 9th are the same notes; the name says which\n  -- way it is voiced.\n  if flavour == \"add2\" then\n    ch.name = M.noteName(key, ch.degree) .. ((ch.quality == \"minor\") and \"m(add2)\" or \"add2\")\n  elseif flavour == \"6/9\" then\n    ch.name = M.noteName(key, ch.degree) .. ((ch.quality == \"minor\") and \"m6/9\" or \"6/9\")\n  end\n  return ch\nend\n\n-- The whole-tone ninth above a degree, as a pitch class, where the scale has\n-- one: the note a rootless voicing puts in place of the root.\nfunction M.ninthOf(key, degree)\n  if M.scaleLen(key) ~= 7 then\n    local o = stepFor(key, degree, { 2 })\n    return o and M.pc(key, degree + o) or nil\n  end\n  if semisAbove(key, degree, 1) == 2 then return M.pc(key, degree + 1) end\n  return nil\nend\n\n------------------------------------------------------------------------------\n-- Which chord follows which\n--\n-- Harmony moves tonic -> subdominant -> dominant -> tonic (Open Music\n-- Theory's \"idealised phrase\"), and the weights below are that cycle written\n-- out chord by chord: from I anywhere, ii mostly to V, V mostly home or to vi\n-- (the deceptive move), vi on to ii or IV. A progression is a walk through\n-- this table, drawn by the idea's dice. The degrees are read by their root's\n-- distance from the tonic (`rootAbove`), so the same table serves every\n-- seven-note scale: in minor the V is a minor v and the VII a major VII, and\n-- the walk still makes sense.\n--\n-- Scales of other lengths (pentatonic, blues, whole tone, diminished) have no\n-- \"ii\" or \"V\" to speak of, so their chords move by root motion instead: down\n-- a fifth strongest, then by step, then by third.\n------------------------------------------------------------------------------\n\n-- Indexed by semitones above the tonic, from and to.\nlocal MOVES = {\n  [0]  = { [2] = 2,   [3] = 0.6, [4] = 0.6, [5] = 3,   [7] = 2.5, [8] = 2,   [9] = 2.5,\n           [10] = 1,  [11] = 0.3, [1] = 0.6 },\n  [1]  = { [0] = 3,   [7] = 1,   [5] = 1,   [10] = 1 },                       -- bII: home (Phrygian)\n  [2]  = { [7] = 4,   [11] = 1,  [5] = 0.8, [0] = 0.4, [9] = 0.4, [10] = 0.6 }, -- ii: to V\n  [3]  = { [8] = 2,   [5] = 2,   [10] = 2,  [2] = 0.8, [0] = 0.5 },            -- bIII\n  [4]  = { [9] = 3,   [5] = 2,   [2] = 0.8, [0] = 0.3 },                       -- iii: to vi\n  [5]  = { [7] = 3,   [0] = 2,   [2] = 1.2, [9] = 0.8, [11] = 0.4, [10] = 1, [4] = 0.3, [3] = 0.3 }, -- IV\n  [6]  = { [7] = 3,   [0] = 1 },\n  [7]  = { [0] = 5,   [9] = 2,   [8] = 1.5, [5] = 0.8, [4] = 0.2, [3] = 0.4 }, -- V: home, or deceptive\n  [8]  = { [10] = 2.5, [5] = 2,  [2] = 1.5, [7] = 1.2, [0] = 1, [3] = 1 },    -- bVI\n  [9]  = { [2] = 2,   [5] = 3,   [7] = 1.2, [4] = 0.6, [0] = 0.6 },            -- vi: to ii or IV\n  [10] = { [0] = 3,   [3] = 1.5, [8] = 1,   [5] = 1 },                         -- bVII: home, or III\n  [11] = { [0] = 4,   [4] = 1,   [9] = 0.5 },                                  -- vii: home\n}\n\nlocal ROOT_MOTION = { [5] = 3, [7] = 2, [2] = 1.5, [10] = 1.5, [3] = 1.2, [4] = 1.2,\n                      [8] = 1.2, [9] = 1.2, [1] = 0.6, [11] = 0.6, [6] = 0.2 }\n\n-- Diminished and augmented chords are colour, not furniture: they are\n-- allowed, but drawn a quarter as often.\nlocal function qualityFactor(key, degree)\n  local q = M.degreeQuality(key, norm(key, degree))\n  if q == \"diminished\" or q == \"augmented\" then return 0.25 end\n  return 1\nend\n\nfunction M.moveWeight(key, from, to)\n  from, to = norm(key, from), norm(key, to)\n  if from == to then return 0 end\n  local w\n  if M.scaleLen(key) == 7 then\n    w = (MOVES[M.rootAbove(key, from)] or {})[M.rootAbove(key, to)] or 0\n  else\n    w = ROOT_MOTION[(M.pc(key, to) - M.pc(key, from)) % 12] or 0\n  end\n  return w * qualityFactor(key, to)\nend\n\n-- The chords that can lead home at a cadence, with how strongly. V with a\n-- leading tone is the strongest; where the scale has none (minor, the modes)\n-- the subtonic VII, the minor v and, in Phrygian, the bII take its place - the\n-- cadences those scales are known for. IV is the plagal \"amen\" in any scale,\n-- but a half cadence rests on a dominant, so `half` leaves it out.\nlocal CADENCE = { [7] = 3, [11] = 0.6, [10] = 2, [1] = 2.5, [5] = 1 }\n\nfunction M.cadenceChords(key, half)\n  local out = {}\n  for d = 1, M.scaleLen(key) - 1 do\n    local w = CADENCE[M.rootAbove(key, d)]\n    if half and M.rootAbove(key, d) == 5 then w = nil end\n    if w then\n      local q = M.degreeQuality(key, d)\n      -- (v, not V - but in the Minor scale the V is harmonic minor's, 1.13.)\n      if M.rootAbove(key, d) == 7 and q ~= \"major\" and M.SCALES[key.scale].name ~= \"Minor\" then w = 2 end\n      if M.rootAbove(key, d) == 1 and q ~= \"major\" then w = 0 end   -- only a major bII\n      if q == \"diminished\" or q == \"augmented\" then w = w * 0.25 end\n      if w > 0 then out[#out + 1] = { degree = d, weight = w } end\n    end\n  end\n  if #out == 0 and half then return M.cadenceChords(key, false) end\n  if #out == 0 then\n    -- A scale with nothing a fourth, fifth or step from the tonic: whatever\n    -- moves home most strongly.\n    for d = 1, M.scaleLen(key) - 1 do\n      out[#out + 1] = { degree = d, weight = math.max(0.1, M.moveWeight(key, d, 0)) }\n    end\n  end\n  return out\nend\n\n-- One of `items` in proportion to `weight(item)`.\nlocal function draw(rnd, items, weight)\n  local total = 0\n  for _, it in ipairs(items) do total = total + weight(it) end\n  if total <= 0 then return nil end\n  local x = rnd() * total\n  for _, it in ipairs(items) do\n    x = x - weight(it)\n    if x < 0 then return it end\n  end\n  return items[#items]\nend\nM.draw = draw\n\n-- The next chord after `from`, drawn from the table.\nfunction M.nextDegree(key, from, rnd)\n  local ds = {}\n  for d = 0, M.scaleLen(key) - 1 do ds[#ds + 1] = d end\n  return draw(rnd, ds, function(d) return M.moveWeight(key, from, d) end)\n      or norm(key, from + 3)\nend\n\nlocal function rowMax(key, from)\n  local m = 0\n  for d = 0, M.scaleLen(key) - 1 do m = math.max(m, M.moveWeight(key, from, d)) end\n  return m\nend\n\n--[[ A progression of `n` chords, as degrees.\n\n     opts.start    the first chord (default the tonic)\n     opts.cadence  how it ends:\n                     \"PAC\", \"IAC\"  a cadence chord, then the tonic\n                     \"DC\"          a cadence chord, then vi (a deceptive close)\n                     \"EC\"          a cadence chord, then the tonic - which\n                                   gi_idea stands on its third (an evaded\n                                   close, 1.13)\n                     \"HC\"          on a cadence chord (a half cadence)\n                     \"open\"        on anything but the tonic that leads back\n                                   to opts.loopTo (default the first chord),\n                                   so the progression can go round again\n                     \"none\"        wherever the walk ends\n     rnd           the dice\n\n     The walk is drawn forward from the start; where it has to meet a fixed\n     ending, the join is accepted in proportion to how likely the table says\n     it is, and the walk is drawn again if not. So the ending is fixed but the\n     way into it is as likely as the table makes it.\n]]\nfunction M.progression(key, n, opts, rnd)\n  opts = opts or {}\n  if n <= 0 then return {} end\n  local start = norm(key, opts.start or 0)\n  local cad = opts.cadence or \"none\"\n  local tail = {}\n  -- A deceptive cadence (1.8): a cadence chord, then vi (VI in minor) where\n  -- the tonic was due - in a seven-note scale; elsewhere, an imperfect close.\n  if cad == \"DC\" and M.scaleLen(key) ~= 7 then cad = \"IAC\" end\n  if cad == \"DC\" then\n    if n == 1 then return { 5 } end\n    local c = draw(rnd, M.cadenceChords(key), function(x) return x.weight end)\n    tail = { c.degree, 5 }\n  elseif cad == \"PAC\" or cad == \"IAC\" or cad == \"EC\" then\n    if n == 1 then return { 0 } end\n    local c = draw(rnd, M.cadenceChords(key), function(x) return x.weight end)\n    tail = { c.degree, 0 }\n  elseif cad == \"HC\" then\n    local c = draw(rnd, M.cadenceChords(key, true), function(x) return x.weight end)\n    tail = { c.degree }\n  end\n  if n <= #tail then\n    local out = {}\n    for i = #tail - n + 1, #tail do out[#out + 1] = tail[i] end\n    return out\n  end\n\n  local free = n - #tail\n  local loopTo = norm(key, opts.loopTo or start)\n  local function join(last)\n    if #tail > 0 then return M.moveWeight(key, last, tail[1]) end\n    if cad == \"open\" and n > 1 then return (last ~= 0) and M.moveWeight(key, last, loopTo) or 0 end\n    return 1\n  end\n  for _ = 1, 80 do\n    local seq = { start }\n    for i = 2, free do seq[i] = M.nextDegree(key, seq[i - 1], rnd) end\n    local w = join(seq[free])\n    if w > 0 and (#tail == 0 and cad ~= \"open\" or rnd() * rowMax(key, seq[free]) < w) then\n      for _, d in ipairs(tail) do seq[#seq + 1] = d end\n      return seq\n    end\n  end\n  -- The dice could not reach the ending from here in eighty draws (a short\n  -- span, an awkward start): take the likeliest way there instead, trying\n  -- the other cadence chords if this one cannot be reached at all.\n  local tries = { tail[1] or false }\n  if #tail > 0 then\n    for _, c in ipairs(M.cadenceChords(key, cad == \"HC\")) do\n      if c.degree ~= tail[1] then tries[#tries + 1] = c.degree end\n    end\n  end\n  -- An open ending that cannot lead back to where it started (nothing in\n  -- the table moves to a diminished chord) settles for not ending at home.\n  local joins = { join }\n  if cad == \"open\" and n > 1 then joins[2] = function(last) return last ~= 0 and 1 or 0 end end\n  -- And if the start itself cannot get there (it is the only cadence chord\n  -- of a small scale), the ending matters more than the start.\n  for _, from in ipairs({ start, false }) do\n    for _, j in ipairs(joins) do\n      for _, first in ipairs(tries) do\n        if #tail > 0 then tail[1] = first end\n        local seq = M.likeliest(key, from or nil, free, j)\n        if seq then\n          for _, d in ipairs(tail) do seq[#seq + 1] = d end\n          return seq\n        end\n      end\n    end\n  end\n  -- Nothing at all (a one-chord span): the tonic.\n  local seq = {}\n  for i = 1, n do seq[i] = (i % 2 == 1) and 0 or norm(key, 4) end\n  return seq\nend\n\n-- The likeliest walk of `len` chords from `start` (from anywhere, if nil)\n-- whose last chord can go on (`join(last)` > 0): the path with the greatest\n-- product of weights, found by dynamic programming over the chords\n-- (Viterbi's algorithm). nil when there is none.\nfunction M.likeliest(key, start, len, join)\n  local L = M.scaleLen(key)\n  local score, back = {}, {}\n  if start then score[start] = 0 else for d = 0, L - 1 do score[d] = 0 end end\n  for i = 2, len do\n    local ns, nb = {}, {}\n    for d = 0, L - 1 do\n      if score[d] then\n        for e = 0, L - 1 do\n          local w = M.moveWeight(key, d, e)\n          if w > 0 then\n            local sc = score[d] + math.log(w)\n            if not ns[e] or sc > ns[e] then ns[e], nb[e] = sc, d end\n          end\n        end\n      end\n    end\n    score, back[i] = ns, nb\n  end\n  local best, bestScore\n  for d = 0, L - 1 do\n    local w = score[d] and join(d) or 0\n    if w > 0 then\n      local sc = score[d] + math.log(w)\n      if not bestScore or sc > bestScore then best, bestScore = d, sc end\n    end\n  end\n  if not best then return nil end\n  local seq = {}\n  seq[len] = best\n  for i = len, 2, -1 do seq[i - 1] = back[i][seq[i]] end\n  return seq\nend\n\n------------------------------------------------------------------------------\n-- Voicing\n--\n-- Close position - every chord tone once, inside an octave - with each chord\n-- the inversion nearest the one before it, so the voices move as little as\n-- they can. That is most of voice leading for an idea you are about to take\n-- into the piano roll and change anyway.\n------------------------------------------------------------------------------\n\nlocal function mean(t)\n  local s = 0\n  for _, v in ipairs(t) do s = s + v end\n  return s / math.max(1, #t)\nend\n\n-- (`want`, a pitch the voicing should have if it can - the note a seventh\n-- falls to - weighs a voicing without it down.)\nfunction M.voice(pcs, prev, lo, hi, want)\n  local best, bestCost\n  local centre = (lo + hi) / 2\n  for base = lo, hi do\n    local bpc = base % 12\n    local isTone = false\n    for _, pc in ipairs(pcs) do if pc == bpc then isTone = true end end\n    if isTone then\n      local notes, seen = { base }, { [bpc] = true }\n      for _, pc in ipairs(pcs) do\n        if not seen[pc] then\n          seen[pc] = true\n          notes[#notes + 1] = base + (pc - bpc) % 12\n        end\n      end\n      table.sort(notes)\n      if notes[#notes] <= hi then\n        local cost\n        if prev and #prev == #notes then\n          cost = 0\n          for i = 1, #notes do cost = cost + math.abs(notes[i] - prev[i]) end\n        elseif prev then\n          cost = math.abs(mean(notes) - mean(prev)) * #notes\n        else\n          cost = 0\n        end\n        cost = cost + 0.15 * math.abs(mean(notes) - centre)\n        if want then\n          local has = false\n          for _, p in ipairs(notes) do if p == want then has = true end end\n          if not has then cost = cost + 8 end\n        end\n        if not bestCost or cost < bestCost then best, bestCost = notes, cost end\n      end\n    end\n  end\n  return best or {}\nend\n\n------------------------------------------------------------------------------\n-- Voicings (docs/decisions/0018-flavours-voicings-and-inversions.md)\n--\n-- The ways a player lays a chord out, each made as a set of candidate\n-- shapes in every octave, the one nearest the chord before chosen (as close\n-- position is):\n--\n--   Close     every note once, inside an octave (`M.voice`, unchanged)\n--   Open      spread: the root, the fifth, then the third an octave up and\n--             the rest above it - 1 5 3 7 (9)\n--   Drop 2    four voices in close position, the second from the top\n--             dropped an octave; Drop 3 the third; Drop 2 & 4 the second\n--             and the fourth. A triad doubles its root to make four; a\n--             five-note chord leaves out its fifth.\n--   Shell     the root, the third and the seventh - the notes that say what\n--             the chord is (a sus chord's fourth or second stands for the\n--             third; a chord with no seventh takes its sixth, or its fifth)\n--   Rootless  no root (the bass has it): the third, fifth, seventh and the\n--             ninth in its place, with the third or the seventh at the\n--             bottom (Bill Evans' A and B shapes). A chord whose ninth is\n--             not a whole tone keeps its root.\n--\n-- No two voices closer than a fourth below C3 (the low interval limit):\n-- thirds down there are mud.\n------------------------------------------------------------------------------\n\nM.VOICINGS = { \"Close\", \"Open\", \"Drop 2\", \"Drop 3\", \"Drop 2 & 4\", \"Shell\", \"Rootless\", \"Power\", \"Drop 4\" }\n\n-- What a note is in its chord, by its distance above the root.\nlocal function roleOf(ch, pc)\n  local iv = (pc - ch.rootPc) % 12\n  if iv == 0 then return \"R\" end\n  if iv == 1 or iv == 2 then return \"9\" end\n  if iv == 3 or iv == 4 then return \"3\" end\n  if iv == 5 then return \"4\" end\n  if iv == 9 then return \"6\" end\n  if iv == 10 or iv == 11 then return \"7\" end\n  return \"5\"\nend\nM.roleOf = roleOf\n\n-- The chord's notes, each once, ordered by height above the root.\nlocal function byHeight(ch, pcs)\n  local seen, out = {}, {}\n  for _, pc in ipairs(pcs) do\n    if not seen[pc] then seen[pc] = true; out[#out + 1] = pc end\n  end\n  table.sort(out, function(a, b) return (a - ch.rootPc) % 12 < (b - ch.rootPc) % 12 end)\n  return out\nend\n\n-- Each pitch class placed the first pitch above the one before, from `base`.\nlocal function stackUp(base, pcs)\n  local out = { base }\n  for i = 2, #pcs do\n    local p = out[i - 1] + 1\n    while p % 12 ~= pcs[i] do p = p + 1 end\n    out[i] = p\n  end\n  return out\nend\n\n-- Every rotation of a cyclic order of pitch classes.\nlocal function rotations(pcs)\n  local out = {}\n  for i = 1, #pcs do\n    local r = {}\n    for j = 0, #pcs - 1 do r[#r + 1] = pcs[(i - 1 + j) % #pcs + 1] end\n    out[#out + 1] = r\n  end\n  return out\nend\n\nlocal function find(ch, pcs, role)\n  for _, pc in ipairs(pcs) do if roleOf(ch, pc) == role then return pc end end\nend\n\n-- The shapes (as orders of pitch classes from the bottom up, and how to\n-- spread them) a style can take for a chord.\nlocal function shapes(ch, style)\n  local pcs = byHeight(ch, ch.pcs)\n  local out = {}\n  if style == \"Open\" then\n    local order = { ch.rootPc }\n    local fifth = find(ch, pcs, \"5\")\n    if fifth then order[#order + 1] = fifth end\n    -- (No fifth - an Italian sixth, 1.15: the seventh next, then the third\n    -- an octave up, the root-seventh-tenth spread.)\n    local seventh = not fifth and find(ch, pcs, \"7\")\n    if seventh then order[#order + 1] = seventh end\n    for _, role in ipairs({ \"3\", \"4\", \"6\", \"7\", \"9\" }) do\n      for _, pc in ipairs(pcs) do\n        if roleOf(ch, pc) == role and pc ~= fifth and pc ~= seventh then order[#order + 1] = pc end\n      end\n    end\n    out[1] = { order = order }\n  elseif style == \"Drop 2\" or style == \"Drop 3\" or style == \"Drop 2 & 4\" or style == \"Drop 4\" then\n    -- (A two-note chord - the pentatonic scales' third without a fifth - has\n    -- nothing to drop; it stays in close position.)\n    if #pcs < 3 then return out end\n    local four = pcs\n    if #pcs == 3 then\n      -- A triad doubles its root: R 3 5 R, or 5 R 3 5 with the root inside.\n      out[#out + 1] = { order = { pcs[1], pcs[2], pcs[3], pcs[1] }, drop = style }\n      out[#out + 1] = { order = { pcs[3], pcs[1], pcs[2], pcs[3] }, drop = style }\n      return out\n    end\n    if #pcs > 4 then\n      four = {}\n      for _, pc in ipairs(pcs) do if roleOf(ch, pc) ~= \"5\" then four[#four + 1] = pc end end\n      while #four > 4 do table.remove(four) end\n    end\n    for _, r in ipairs(rotations(four)) do out[#out + 1] = { order = r, drop = style } end\n  elseif style == \"Shell\" then\n    local third = find(ch, pcs, \"3\") or find(ch, pcs, \"4\") or find(ch, pcs, \"9\")\n    local top = find(ch, pcs, \"7\") or find(ch, pcs, \"6\") or find(ch, pcs, \"5\")\n    if third and top then\n      out[1] = { order = { ch.rootPc, third, top } }\n      out[2] = { order = { ch.rootPc, top, third } }\n    end\n  elseif style == \"Power\" then\n    -- (1.12) The root, the fifth over it and the root again: no third. A\n    -- chord with no perfect fifth (diminished, augmented) plays its root in\n    -- octaves.\n    local fifth\n    for _, pc in ipairs(ch.pcs) do if (pc - ch.rootPc) % 12 == 7 then fifth = pc end end\n    out[1] = { order = fifth and { ch.rootPc, fifth, ch.rootPc } or { ch.rootPc, ch.rootPc } }\n  elseif style == \"Rootless\" then\n    local set = {}\n    for _, pc in ipairs(pcs) do if pc ~= ch.rootPc then set[#set + 1] = pc end end\n    if ch.nine and not ch.has[ch.nine] then set[#set + 1] = ch.nine end\n    if #set >= 3 then\n      set = byHeight(ch, set)\n      for _, r in ipairs(rotations(set)) do\n        local bottom = roleOf(ch, r[1])\n        if bottom == \"3\" or bottom == \"7\" or bottom == \"4\" then out[#out + 1] = { order = r } end\n      end\n      if #out == 0 then for _, r in ipairs(rotations(set)) do out[#out + 1] = { order = r } end end\n    end\n  end\n  return out\nend\n\n-- (1.14) Drop 4: the lowest of four close notes dropped an octave - three\n-- close notes over a gap.\nlocal DROPS = { [\"Drop 2\"] = { 2 }, [\"Drop 3\"] = { 3 }, [\"Drop 2 & 4\"] = { 2, 4 }, [\"Drop 4\"] = { 4 } }\n\nlocal function muddy(notes)\n  for i = 2, #notes do\n    if notes[i] - notes[i - 1] <= 4 and notes[i - 1] < 48 then return true end\n  end\n  return false\nend\n\n-- Close position for a flavoured chord: an added 2nd sits inside, between\n-- the root and the third; an added 9th goes on top, above the rest.\nlocal function closeFlavoured(ch, prev, lo, hi)\n  if ch.addInside then\n    local best, bestCost\n    local order = byHeight(ch, ch.pcs)\n    for base = lo, hi do\n      if base % 12 == ch.rootPc then\n        local notes = stackUp(base, order)\n        if notes[#notes] <= hi then\n          local cost = prev and math.abs(mean(notes) - mean(prev)) * #notes or 0\n          cost = cost + 0.15 * math.abs(mean(notes) - (lo + hi) / 2)\n          if not bestCost or cost < bestCost then best, bestCost = notes, cost end\n        end\n      end\n    end\n    return best\n  end\n  local rest, nine = {}, nil\n  for _, pc in ipairs(ch.pcs) do\n    if roleOf(ch, pc) == \"9\" then nine = pc else rest[#rest + 1] = pc end\n  end\n  local v = M.voice(rest, prev, lo, hi - 3)\n  if #v == 0 or not nine then return nil end\n  local p = v[#v] + 1\n  while p % 12 ~= nine do p = p + 1 end\n  v[#v + 1] = p\n  return v\nend\n\nlocal function spread(list, prev, lo, hi, want)\n  local best, bestCost\n  local centre = (lo + hi) / 2\n  for _, sh in ipairs(list) do\n    for base = lo - 24, hi do\n      if base % 12 == sh.order[1] then\n        local notes = stackUp(base, sh.order)\n        if sh.drop then\n          for _, k in ipairs(DROPS[sh.drop]) do\n            local i = #notes - k + 1\n            notes[i] = notes[i] - 12\n          end\n          table.sort(notes)\n        end\n        if notes[1] >= lo and notes[#notes] <= hi and not muddy(notes) then\n          local cost\n          if prev and #prev == #notes then\n            cost = 0\n            for i = 1, #notes do cost = cost + math.abs(notes[i] - prev[i]) end\n          elseif prev then\n            cost = math.abs(mean(notes) - mean(prev)) * #notes\n          else\n            cost = 0\n          end\n          cost = cost + 0.15 * math.abs(mean(notes) - centre)\n          if want then\n            local has = false\n            for _, p in ipairs(notes) do if p == want then has = true end end\n            if not has then cost = cost + 8 end\n          end\n          if not bestCost or cost < bestCost then best, bestCost = notes, cost end\n        end\n      end\n    end\n  end\n  return best\nend\n\n-- The chord voiced in a style, nearest the voicing before. A spread\n-- voicing needs about two octaves, so where it does not fit between lo and\n-- hi it may reach down an octave (not below `floor`), then up a fifth;\n-- failing that it is {} and the caller decides. A chord the style has no\n-- shape for (a two-note chord in a drop voicing) is played in close\n-- position.\nfunction M.voiceAs(ch, style, prev, lo, hi, floor, want)\n  if style == \"Close\" or not style then\n    if ch.addInside or ch.ninthUp then\n      local v = closeFlavoured(ch, prev, lo, hi)\n      if v then return v end\n    end\n    return M.voice(ch.pcs, prev, lo, hi, want)\n  end\n  local list = shapes(ch, style)\n  if #list > 0 then\n    local down = math.max(floor or lo, lo - 12)\n    for _, w in ipairs({ { lo, hi }, { down, hi }, { down, hi + 7 } }) do\n      local v = spread(list, prev, w[1], w[2], want)\n      if v then return v end\n    end\n    return {}\n  end\n  -- (Close position, then, but above C3 where it can be: no muddy thirds.)\n  local v = M.voice(ch.pcs, prev, math.max(lo, 48), hi, want)\n  if #v > 0 then return v end\n  return M.voice(ch.pcs, prev, lo, hi, want)\nend\n\n-- A root in the bass: the octave of `pc` inside [lo, hi] nearest the last\n-- bass note (or the middle of the range for the first).\nfunction M.bassNote(pc, prev, lo, hi)\n  local want = prev or math.floor((lo + hi) / 2)\n  local best\n  for p = lo, hi do\n    if p % 12 == pc and (not best or math.abs(p - want) < math.abs(best - want)) then best = p end\n  end\n  return best or (lo + (pc - lo) % 12)\nend\n\nreturn M\n"};

/* ---- ../kit/palette.js ---- */
/* The devices' colours in Live: after Ableton Live 8's default theme.
 *
 * The scheme is Starting Blocks' own experiment of 18 September 2026
 * (commit 2765b0a3, "theme the window after Live 8"): a neutral grey chrome
 * meant to sit quietly under brightly coloured clips, controls raised off it,
 * and one warm amber spent where Live spends its accent, on what is switched
 * on. It was built from the theme's described character, not Live's own
 * files, so it is a likeness, not a match.
 *
 * Two changes from that experiment, both for the family's rules (every word
 * 7:1 on what it sits on, ink on every button, marks and edges 3:1):
 *   - the chrome is #3E3E3E, a step darker than its #4A4A4A, because on
 *     #4A4A4A a secondary word cannot reach 7:1 and still look secondary;
 *   - buttons are a light grey with dark ink, as the house scheme's are,
 *     because light words on its #5E5E5E buttons reach only 5:1.
 * The greys are neutral (R = G = B), as Live's are: the house rule that
 * every grey leans blue is the yellow scheme's, and Live's look is not that.
 *
 * Palette.tone(r, g, b) is how the REAPER windows (the JSFX and Lua scripts,
 * drawn through gfx.js) take the scheme without a line of theirs changing:
 *   - the house scheme's own colours map one for one (HOUSE below), each
 *     chosen so the pairs the scripts rely on stay 7:1 for words and 3:1
 *     for edges;
 *   - the house yellow, and the shades the scripts make of it, become the
 *     amber, shaded the same way;
 *   - any other grey loses its tint at the same brightness, so a script
 *     with a palette of its own keeps every contrast it had;
 *   - every other colour (a material, an engine, a part) is left alone.
 */
var Palette = (function () {
  'use strict';
  var C = {
    ground: 0x3E3E3E,     // the chrome: Live 8's #4A4A4A, a step darker (see above)
    raised: 0x484848,     // a control that is off
    sunken: 0x2E2E2E,     // lists, fields, a roll or a page: Live 8's roll ground
    deep: 0x262626,       // a roll's own ground under a sunken frame
    popup: 0x333333,      // menus
    rule: 0x555555,       // separators: they group, they do not act
    edge: 0x8C8C8C,       // the edge of anything that acts: 3.2:1 on the chrome
    control: 0xB4B4B4,    // buttons, with ink on them
    controlHover: 0xC4C4C4,
    controlHeld: 0xAAAAAA,
    accent: 0xD7A93C,     // Live 8's warm amber: what is on
    accentHeld: 0xCDA139,  // held: ink on it still 7.2:1
    ink: 0x1A1A1A,        // words on a button, grey or amber; also a window's darkest ground
                          // (AutoCC paints its window in the ink), so words are 7:1 on it too
    text: 0xF0F0F0,       // 9.4:1 on the chrome
    label: 0xD8D8D8,      // 7.5:1
    dim: 0xD4D4D4,        // secondary words, 7.2:1
    mark: 0xA8A8A8,       // a mark that is not a word, or a control that is off
    note: 0xA8D8E8,       // Live 8's cool note colour, for a roll
    ring: 0xFAFAFA,       // the keyboard's place
    warn: 0xF0605A,       // a warning's mark, never its words: 3.3:1 on the chrome
    warnText: 0xFFC8C2    // a warning's words, 7.3:1
  };
  // The house scheme (HousePalette, every family repo's docs/COLOUR.md) to this one.
  var HOUSE = {
    0x111419: C.deep, 0x14171C: C.ink, 0x1A1D23: C.sunken, 0x1B1F25: C.popup, 0x1E2228: 0x343434,
    0x22262D: 0x363636, 0x23272E: C.ground, 0x2A2F37: C.raised, 0x3A404A: C.rule, 0x585F6B: 0x707070,
    0x646B77: 0x7A7A7A, 0x6D7581: C.edge, 0x8A919C: C.mark, 0x8F96A2: C.controlHeld, 0xA9AFBA: C.control,
    0xB0B6C0: C.dim, 0xB6BCC6: C.dim, 0xBFC5CE: C.label, 0xC0C6CF: C.controlHover, 0xDDE1E7: C.text,
    0xF2F4F7: C.ring, 0xFFF200: C.accent, 0xD1C600: C.accentHeld, 0xFF9E96: C.warnText, 0xFFA6A0: C.warnText, 0xD2483F: C.warn
  };
  function rgb(hex, a) {
    return [((hex >> 16) & 255) / 255, ((hex >> 8) & 255) / 255, (hex & 255) / 255, a === undefined ? 1 : a];
  }
  function lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
  function unlin(l) { return l <= 0.0031308 ? l * 12.92 : 1.055 * Math.pow(l, 1 / 2.4) - 0.055; }
  function luminance(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b); }
  function contrast(a, b) {
    var la = luminance(a[0], a[1], a[2]), lb = luminance(b[0], b[1], b[2]);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }
  function clamp(x) { return x < 0 ? 0 : x > 1 ? 1 : x; }
  var AMBER = rgb(C.accent);
  // r, g, b from 0 to 1; returns [r, g, b].
  function tone(r, g, b) {
    r = clamp(r); g = clamp(g); b = clamp(b);
    var R = Math.round(r * 255), G = Math.round(g * 255), B = Math.round(b * 255);
    var hex = (R << 16) | (G << 8) | B;
    if (HOUSE[hex] !== undefined) { var t = rgb(HOUSE[hex]); return [t[0], t[1], t[2]]; }
    // The house yellow and its shades: lighter ones mix in white (blue rises
    // from 0), darker ones scale down (red and green fall together).
    if (R >= 120 && G >= 110 && Math.abs(R - G) <= 40 && B <= Math.min(R, G) - 90) {
      var w = B / 255, k = Math.max(R, G) / 255;
      return [0, 1, 2].map(function (i) { return clamp(AMBER[i] * k + (1 - AMBER[i] * k) * w); });
    }
    // A grey with a tint, from any palette: neutral at the same brightness.
    var hi = Math.max(R, G, B), lo = Math.min(R, G, B);
    if (hi - lo <= 28) { var n = unlin(luminance(r, g, b)); return [n, n, n]; }
    return [r, g, b];
  }
  return { C: C, HOUSE: HOUSE, rgb: rgb, tone: tone, luminance: luminance, contrast: contrast };
})();


/* ---- ../kit/runtime/polyfill.js ---- */
/* What JavaScriptCore lacks and the Lua runtime uses: TextEncoder and
 * TextDecoder, UTF-8 only, as the web defines them (an invalid byte decodes
 * to U+FFFD and decoding goes on). Installed only where they are missing, so
 * Node and browsers keep their own; MiddawUTF8 is the same code, always, for
 * the tests to hold against the real thing.
 */
(function (G) {
  'use strict';
  function encode(str) {
    var out = [];
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i);
      if (c >= 0xD800 && c <= 0xDBFF && i + 1 < str.length) {
        var d = str.charCodeAt(i + 1);
        if (d >= 0xDC00 && d <= 0xDFFF) { c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00); i++; }
        else c = 0xFFFD;
      } else if (c >= 0xD800 && c <= 0xDFFF) c = 0xFFFD;
      if (c < 0x80) out.push(c);
      else if (c < 0x800) out.push(0xC0 | (c >> 6), 0x80 | (c & 63));
      else if (c < 0x10000) out.push(0xE0 | (c >> 12), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
      else out.push(0xF0 | (c >> 18), 0x80 | ((c >> 12) & 63), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
    }
    return new Uint8Array(out);
  }
  function decode(bytes) {
    var b = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes || []);
    var out = '', i = 0, n = b.length;
    while (i < n) {
      var c = b[i], need = 0, cp = 0, min = 0;
      if (c < 0x80) { out += String.fromCharCode(c); i++; continue; }
      else if (c >= 0xC2 && c <= 0xDF) { need = 1; cp = c & 0x1F; min = 0x80; }
      else if (c >= 0xE0 && c <= 0xEF) { need = 2; cp = c & 0x0F; min = 0x800; }
      else if (c >= 0xF0 && c <= 0xF4) { need = 3; cp = c & 0x07; min = 0x10000; }
      else { out += '�'; i++; continue; }
      var j = 1, ok = true;
      for (; j <= need; j++) {
        if (i + j >= n) { ok = false; break; }
        var x = b[i + j];
        // the second byte's range is narrower for a few leads (no overlongs, no surrogates)
        var lo = 0x80, hi = 0xBF;
        if (j === 1) {
          if (c === 0xE0) lo = 0xA0; else if (c === 0xED) hi = 0x9F;
          else if (c === 0xF0) lo = 0x90; else if (c === 0xF4) hi = 0x8F;
        }
        if (x < lo || x > hi) { ok = false; break; }
        cp = (cp << 6) | (x & 0x3F);
      }
      if (!ok || cp < min) { out += '�'; i += Math.max(1, j); continue; }
      if (cp >= 0x10000) { cp -= 0x10000; out += String.fromCharCode(0xD800 + (cp >> 10), 0xDC00 + (cp & 0x3FF)); }
      else out += String.fromCharCode(cp);
      i += need + 1;
    }
    return out;
  }
  function Enc() {}
  Enc.prototype.encode = function (s) { return encode(String(s === undefined ? '' : s)); };
  function Dec() {}
  Dec.prototype.decode = function (b) { return decode(b); };
  G.MiddawUTF8 = { TextEncoder: Enc, TextDecoder: Dec };
  if (typeof G.TextEncoder === 'undefined') G.TextEncoder = Enc;
  if (typeof G.TextDecoder === 'undefined') G.TextDecoder = Dec;
})(typeof globalThis !== 'undefined' ? globalThis : this);


/* ---- ../kit/runtime/lua_parse.js ---- */
/* Middaw's Lua 5.4, part 1 of 3: the lexer and the parser.
 *
 * Middaw runs the family's Lua engines (Good Idea, Midi Suggester, Midi
 * Variator, Midi Catalogue, Starting Blocks, DAW Battle Pass...) unchanged, in
 * the browser, with no third-party code: this file reads Lua source into a
 * syntax tree, lua_compile.js turns the tree into JavaScript, lua_runtime.js
 * supplies the values and the standard library. tests/js/test_lua.js holds
 * all three to what the real Lua 5.4 prints for the same programs.
 *
 * Source is a "byte string": one JS character per byte of the file, which is
 * how Lua itself sees a string, so `#s` and string.sub count bytes as Lua does.
 */
(function (NS) {
  'use strict';

  var KEYWORDS = {};
  ('and break do else elseif end false for function goto if in local nil not ' +
   'or repeat return then true until while').split(' ').forEach(function (k) { KEYWORDS[k] = true; });

  function LuaSyntaxError(message, chunk, line) {
    this.message = chunk + ':' + line + ': ' + message;
    this.line = line;
  }
  LuaSyntaxError.prototype = Object.create(Error.prototype);
  LuaSyntaxError.prototype.name = 'LuaSyntaxError';

  function isDigit(c) { return c >= 48 && c <= 57; }
  function isHex(c) { return isDigit(c) || (c >= 97 && c <= 102) || (c >= 65 && c <= 70); }
  function isAlpha(c) { return (c >= 97 && c <= 122) || (c >= 65 && c <= 90) || c === 95; }
  function isSpace(c) { return c === 32 || (c >= 9 && c <= 13); }

  // ---------------------------------------------------------------- lexer --
  function lex(src, chunk) {
    var toks = [];
    var i = 0, n = src.length, line = 1;
    function err(msg) { throw new LuaSyntaxError(msg, chunk, line); }
    function longBracketLevel(at) {   // at points to '['; returns level or -1
      var j = at + 1, level = 0;
      while (src.charCodeAt(j) === 61) { level++; j++; }
      return src.charCodeAt(j) === 91 ? level : -1;
    }
    function readLong(at, level) {    // returns [content, end index]
      var start = at + level + 2;
      // a newline straight after the opening bracket is skipped
      if (src[start] === '\r') { start++; if (src[start] === '\n') start++; }
      else if (src[start] === '\n') { start++; if (src[start] === '\r') start++; }
      var close = ']' + '='.repeat(level) + ']';
      var end = src.indexOf(close, start);
      if (end < 0) err('unfinished long string');
      var body = src.slice(start, end);
      for (var k = at; k < end + close.length; k++) if (src.charCodeAt(k) === 10) line++;
      return [body, end + close.length];
    }
    while (i < n) {
      var c = src.charCodeAt(i);
      if (c === 10) { line++; i++; continue; }
      if (isSpace(c)) { i++; continue; }
      if (c === 45 && src.charCodeAt(i + 1) === 45) {           // comment
        i += 2;
        if (src.charCodeAt(i) === 91) {
          var lvl = longBracketLevel(i);
          if (lvl >= 0) { i = readLong(i, lvl)[1]; continue; }
        }
        while (i < n && src.charCodeAt(i) !== 10) i++;
        continue;
      }
      var tline = line;
      if (isAlpha(c)) {
        var j = i + 1;
        while (j < n && (isAlpha(src.charCodeAt(j)) || isDigit(src.charCodeAt(j)))) j++;
        var word = src.slice(i, j);
        toks.push(KEYWORDS[word] ? { t: word, line: tline } : { t: 'name', v: word, line: tline });
        i = j; continue;
      }
      if (isDigit(c) || (c === 46 && isDigit(src.charCodeAt(i + 1)))) {
        var j2 = i, isFloat = false, text;
        if (c === 48 && (src[i + 1] === 'x' || src[i + 1] === 'X')) {
          j2 = i + 2;
          while (j2 < n) {
            var d = src.charCodeAt(j2);
            if (isHex(d) || d === 46) { if (d === 46) isFloat = true; j2++; }
            else if ((d === 112 || d === 80)) {
              isFloat = true; j2++;
              if (src[j2] === '+' || src[j2] === '-') j2++;
            } else break;
          }
        } else {
          while (j2 < n) {
            var e = src.charCodeAt(j2);
            if (isDigit(e) || e === 46) { if (e === 46) isFloat = true; j2++; }
            else if (e === 101 || e === 69) {
              isFloat = true; j2++;
              if (src[j2] === '+' || src[j2] === '-') j2++;
            } else break;
          }
        }
        text = src.slice(i, j2);
        if (j2 < n && (isAlpha(src.charCodeAt(j2)))) err("malformed number near '" + text + src[j2] + "'");
        toks.push({ t: 'number', v: text, line: tline });
        i = j2; continue;
      }
      if (c === 34 || c === 39) {                                // short string
        var q = c, out = [], k = i + 1;
        for (;;) {
          if (k >= n) err('unfinished string');
          var ch = src.charCodeAt(k);
          if (ch === q) { k++; break; }
          if (ch === 10) err('unfinished string');
          if (ch === 92) {
            var x = src[k + 1];
            k += 2;
            switch (x) {
              case 'n': out.push('\n'); break;
              case 't': out.push('\t'); break;
              case 'r': out.push('\r'); break;
              case 'a': out.push('\x07'); break;
              case 'b': out.push('\b'); break;
              case 'f': out.push('\f'); break;
              case 'v': out.push('\v'); break;
              case '\\': out.push('\\'); break;
              case '"': out.push('"'); break;
              case "'": out.push("'"); break;
              case '\n': line++; out.push('\n'); break;
              case 'x': {
                var hx = src.slice(k, k + 2);
                if (!/^[0-9a-fA-F]{2}$/.test(hx)) err('hexadecimal digit expected');
                out.push(String.fromCharCode(parseInt(hx, 16))); k += 2; break;
              }
              case 'z': {
                while (k < n && isSpace(src.charCodeAt(k))) { if (src.charCodeAt(k) === 10) line++; k++; }
                break;
              }
              case 'u': {
                if (src[k] !== '{') err("missing '{' in \\u{xxxx}");
                var close = src.indexOf('}', k);
                var cp = parseInt(src.slice(k + 1, close), 16);
                k = close + 1;
                out.push(utf8Bytes(cp)); break;
              }
              default: {
                if (x !== undefined && isDigit(x.charCodeAt(0))) {
                  var digits = x; var m = 0;
                  while (m < 2 && isDigit(src.charCodeAt(k))) { digits += src[k]; k++; m++; }
                  var val = parseInt(digits, 10);
                  if (val > 255) err('decimal escape too large');
                  out.push(String.fromCharCode(val));
                } else err('invalid escape sequence');
              }
            }
            continue;
          }
          out.push(src[k]); k++;
        }
        toks.push({ t: 'string', v: out.join(''), line: tline });
        i = k; continue;
      }
      if (c === 91) {
        var lv = longBracketLevel(i);
        if (lv >= 0) {
          var r = readLong(i, lv);
          toks.push({ t: 'string', v: r[0], line: tline });
          i = r[1]; continue;
        }
      }
      var three = src.substr(i, 3), two = src.substr(i, 2);
      if (three === '...') { toks.push({ t: '...', line: tline }); i += 3; continue; }
      if (two === '==' || two === '~=' || two === '<=' || two === '>=' || two === '//' ||
          two === '::' || two === '<<' || two === '>>' || two === '..') {
        toks.push({ t: two, line: tline }); i += 2; continue;
      }
      var one = src[i];
      if ('+-*/%^#&~|<>=(){}[];:,.'.indexOf(one) >= 0) { toks.push({ t: one, line: tline }); i++; continue; }
      err("unexpected symbol near '" + one + "'");
    }
    toks.push({ t: '<eof>', line: line });
    return toks;
  }

  function utf8Bytes(cp) {
    if (cp < 0x80) return String.fromCharCode(cp);
    if (cp < 0x800) return String.fromCharCode(0xC0 | (cp >> 6), 0x80 | (cp & 63));
    if (cp < 0x10000) return String.fromCharCode(0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63));
    return String.fromCharCode(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 63), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63));
  }

  // --------------------------------------------------------------- parser --
  // Binary priorities exactly as lparser.c has them: { left, right }.
  var BINARY = {
    '+': [10, 10], '-': [10, 10], '*': [11, 11], '%': [11, 11], '^': [14, 13],
    '/': [11, 11], '//': [11, 11], '&': [6, 6], '|': [4, 4], '~': [5, 5],
    '<<': [7, 7], '>>': [7, 7], '..': [9, 8],
    '==': [3, 3], '<': [3, 3], '<=': [3, 3], '~=': [3, 3], '>': [3, 3], '>=': [3, 3],
    'and': [2, 2], 'or': [1, 1]
  };
  var UNARY_PRIORITY = 12;

  function parse(src, chunk) {
    chunk = chunk || '?';
    var toks = lex(src, chunk);
    var p = 0;
    function peek() { return toks[p]; }
    function next() { return toks[p++]; }
    function check(t) { return toks[p].t === t; }
    function err(msg, tok) {
      tok = tok || toks[p];
      var near = tok.t === '<eof>' ? '<eof>' : (tok.v !== undefined ? tok.v : tok.t);
      throw new LuaSyntaxError(msg + " near '" + near + "'", chunk, tok.line);
    }
    function expect(t, what) {
      if (toks[p].t !== t) err("'" + t + "' expected" + (what ? ' (to close ' + what + ')' : ''));
      return toks[p++];
    }
    function accept(t) { if (toks[p].t === t) { p++; return true; } return false; }
    function name() {
      if (toks[p].t !== 'name') err('<name> expected');
      return toks[p++].v;
    }

    function blockFollow(withUntil) {
      var t = toks[p].t;
      return t === 'else' || t === 'elseif' || t === 'end' || t === '<eof>' || (withUntil && t === 'until');
    }

    function block() {
      var body = [];
      while (!blockFollow(true)) {
        if (check('return')) { body.push(retstat()); break; }
        var s = statement();
        if (s) body.push(s);
      }
      return body;
    }

    function retstat() {
      var tok = next();
      var exprs = [];
      if (!blockFollow(true) && !check(';')) exprs = exprlist();
      accept(';');
      return { k: 'Return', exprs: exprs, line: tok.line };
    }

    function statement() {
      var tok = peek(), line = tok.line;
      switch (tok.t) {
        case ';': next(); return null;
        case 'if': return ifstat();
        case 'while': {
          next(); var cond = expr(); expect('do'); var b = block(); expect('end', 'while');
          return { k: 'While', cond: cond, body: b, line: line };
        }
        case 'do': { next(); var b2 = block(); expect('end', 'do'); return { k: 'Do', body: b2, line: line }; }
        case 'for': return forstat();
        case 'repeat': {
          next(); var b3 = block(); expect('until', 'repeat'); var c3 = expr();
          return { k: 'Repeat', body: b3, cond: c3, line: line };
        }
        case 'function': {
          next();
          var target = { k: 'Name', name: name(), line: line }, isMethod = false;
          while (check('.') || check(':')) {
            var sep = next().t;
            var key = name();
            target = { k: 'Index', obj: target, key: { k: 'String', v: key }, line: line };
            if (sep === ':') { isMethod = true; break; }
          }
          var f = funcbody(isMethod, line);
          return { k: 'Assign', targets: [target], exprs: [f], line: line };
        }
        case 'local': {
          next();
          if (accept('function')) {
            var nm = name();
            return { k: 'LocalFunction', name: nm, func: funcbody(false, line), line: line };
          }
          var names = [], attribs = [];
          do {
            names.push(name());
            if (accept('<')) { attribs.push(name()); expect('>'); } else attribs.push(null);
          } while (accept(','));
          var exprs = accept('=') ? exprlist() : [];
          return { k: 'Local', names: names, attribs: attribs, exprs: exprs, line: line };
        }
        case '::': { next(); var label = name(); expect('::'); return { k: 'Label', name: label, line: line }; }
        case 'return': return retstat();
        case 'break': next(); return { k: 'Break', line: line };
        case 'goto': next(); return { k: 'Goto', name: name(), line: line };
        default: return exprstat();
      }
    }

    function ifstat() {
      var line = next().line;
      var clauses = [];
      var cond = expr(); expect('then');
      clauses.push({ cond: cond, body: block() });
      var orelse = null;
      for (;;) {
        if (accept('elseif')) { var c = expr(); expect('then'); clauses.push({ cond: c, body: block() }); }
        else if (accept('else')) { orelse = block(); expect('end', 'if'); break; }
        else { expect('end', 'if'); break; }
      }
      return { k: 'If', clauses: clauses, orelse: orelse, line: line };
    }

    function forstat() {
      var line = next().line;
      var n1 = name();
      if (accept('=')) {
        var start = expr(); expect(',');
        var limit = expr();
        var step = accept(',') ? expr() : null;
        expect('do'); var b = block(); expect('end', 'for');
        return { k: 'NumFor', name: n1, start: start, limit: limit, step: step, body: b, line: line };
      }
      var names = [n1];
      while (accept(',')) names.push(name());
      expect('in');
      var exprs = exprlist();
      expect('do'); var body = block(); expect('end', 'for');
      return { k: 'GenFor', names: names, exprs: exprs, body: body, line: line };
    }

    function exprstat() {
      var line = peek().line;
      var e = suffixedexp();
      if (check('=') || check(',')) {
        var targets = [e];
        while (accept(',')) targets.push(suffixedexp());
        expect('=');
        var exprs = exprlist();
        targets.forEach(function (t) { if (t.k !== 'Name' && t.k !== 'Index') err('syntax error'); });
        return { k: 'Assign', targets: targets, exprs: exprs, line: line };
      }
      if (e.k !== 'Call' && e.k !== 'Method') err('syntax error');
      return { k: 'ExprStat', expr: e, line: line };
    }

    function exprlist() {
      var list = [expr()];
      while (accept(',')) list.push(expr());
      return list;
    }

    function funcbody(isMethod, line) {
      var params = isMethod ? ['self'] : [], vararg = false;
      expect('(');
      if (!check(')')) {
        do {
          if (accept('...')) { vararg = true; break; }
          params.push(name());
        } while (accept(','));
      }
      expect(')');
      var b = block();
      var endTok = expect('end', 'function');
      return { k: 'Function', params: params, vararg: vararg, body: b, line: line, endLine: endTok.line };
    }

    function primaryexp() {
      var tok = peek();
      if (tok.t === 'name') { next(); return { k: 'Name', name: tok.v, line: tok.line }; }
      if (tok.t === '(') {
        next(); var e = expr(); expect(')');
        return { k: 'Paren', expr: e, line: tok.line };
      }
      err('unexpected symbol');
    }

    function suffixedexp() {
      var e = primaryexp();
      for (;;) {
        var tok = peek();
        switch (tok.t) {
          case '.': next(); e = { k: 'Index', obj: e, key: { k: 'String', v: name() }, line: tok.line }; break;
          case '[': next(); var key = expr(); expect(']'); e = { k: 'Index', obj: e, key: key, line: tok.line }; break;
          case ':': next(); var m = name(); e = { k: 'Method', obj: e, name: m, args: callargs(), line: tok.line }; break;
          case '(': case 'string': case '{': e = { k: 'Call', fn: e, args: callargs(), line: tok.line }; break;
          default: return e;
        }
      }
    }

    function callargs() {
      var tok = peek();
      if (tok.t === 'string') { next(); return [{ k: 'String', v: tok.v }]; }
      if (tok.t === '{') return [tablecons()];
      expect('(');
      if (accept(')')) return [];
      var args = exprlist();
      expect(')');
      return args;
    }

    function tablecons() {
      var line = expect('{').line;
      var items = [];   // { kind: 'pos'|'named'|'keyed', key, value }
      while (!check('}')) {
        if (check('name') && toks[p + 1].t === '=') {
          var key = next().v; next();
          items.push({ kind: 'keyed', key: { k: 'String', v: key }, value: expr() });
        } else if (check('[')) {
          next(); var k = expr(); expect(']'); expect('=');
          items.push({ kind: 'keyed', key: k, value: expr() });
        } else {
          items.push({ kind: 'pos', value: expr() });
        }
        if (!accept(',') && !accept(';')) break;
      }
      expect('}', 'table');
      return { k: 'Table', items: items, line: line };
    }

    function simpleexp() {
      var tok = peek();
      switch (tok.t) {
        case 'number': next(); return { k: 'Number', v: tok.v, line: tok.line };
        case 'string': next(); return { k: 'String', v: tok.v };
        case 'nil': next(); return { k: 'Nil' };
        case 'true': next(); return { k: 'True' };
        case 'false': next(); return { k: 'False' };
        case '...': next(); return { k: 'Vararg', line: tok.line };
        case '{': return tablecons();
        case 'function': next(); return funcbody(false, tok.line);
        default: return suffixedexp();
      }
    }

    function expr(limit) {
      limit = limit || 0;
      var left, tok = peek();
      if (tok.t === 'not' || tok.t === '-' || tok.t === '#' || tok.t === '~') {
        next();
        left = { k: 'Unop', op: tok.t, expr: expr(UNARY_PRIORITY), line: tok.line };
      } else {
        left = simpleexp();
      }
      for (;;) {
        var op = peek().t, pr = BINARY[op];
        if (!pr || pr[0] <= limit) break;
        var line = next().line;
        var right = expr(pr[1]);
        left = { k: 'Binop', op: op, left: left, right: right, line: line };
      }
      return left;
    }

    var body = block();
    if (!check('<eof>')) err("'<eof>' expected");
    return { k: 'Chunk', body: body };
  }

  NS.lex = lex;
  NS.parse = parse;
  NS.LuaSyntaxError = LuaSyntaxError;
  NS.utf8Bytes = utf8Bytes;
})(typeof module === 'object' && module.exports
  ? (module.exports = (globalThis.MiddawLua = globalThis.MiddawLua || {}))
  : (globalThis.MiddawLua = globalThis.MiddawLua || {}));


/* ---- ../kit/runtime/lua_runtime.js ---- */
/* Middaw's Lua 5.4, part 3 of 3: values, operators and the standard library.
 *
 * Values, as JavaScript sees them:
 *   nil      undefined
 *   boolean  true / false
 *   number   a JS number. An integral JS number is a Lua *integer*; a
 *            non-integral one (or inf, nan) is a Lua *float*. A float whose
 *            value happens to be integral (4.0, 2/2) is an LFloat, so that it
 *            still prints "4.0" and math.type still says "float".
 *   string   a JS string with one character per byte (0-255)
 *   table    LuaTable
 *   function a JS function: Lua arguments in, and undefined, one value, or a
 *            Multi for two or more results.
 *
 * Wherever the result has to match the real Lua byte for byte - table.sort
 * with ties, the pattern matcher, math.random, number formatting - the code
 * is a port of Lua 5.4's own C, not a lookalike.
 */
(function (NS) {
  'use strict';

  // ------------------------------------------------------------ values ----
  function LFloat(n) { this.n = n; }
  LFloat.prototype.valueOf = function () { return this.n; };

  function mkf(x) { return Number.isInteger(x) ? new LFloat(x) : x; }
  function isNum(v) { return typeof v === 'number' || v instanceof LFloat; }
  function num(v) { return typeof v === 'number' ? v : v.n; }
  function isFloatVal(v) { return v instanceof LFloat || (typeof v === 'number' && !Number.isInteger(v)); }

  function Multi(a) { this.a = a; }
  function first(v) { return v instanceof Multi ? v.a[0] : v; }
  // `return` with no values gives NONE; a bare undefined is one nil.
  var NONE = new Multi([]);
  var NIL1 = Object.freeze([undefined]);
  function sp(v) {
    if (v instanceof Multi) return v.a;
    return v === undefined ? NIL1 : [v];
  }
  function ret(list) {
    if (list.length === 0) return NONE;
    if (list.length === 1) return list[0];
    return new Multi(list);
  }

  var tableIds = 0;
  function LuaTable() { this.arr = []; this.hash = null; this.mt = null; this.id = 0; this.hver = 0; }
  LuaTable.prototype.get = function (k) {
    if (typeof k === 'number') {
      var a = this.arr;
      if (k > 0 && k <= a.length && Number.isInteger(k)) return a[k - 1];
    } else if (typeof k === 'string') {
      return this.hash === null ? undefined : this.hash.get(k);
    } else if (k instanceof LFloat) {
      return this.get(k.n);
    }
    return this.hash === null ? undefined : this.hash.get(k);
  };
  LuaTable.prototype.set = function (k, v) {
    if (typeof k === 'number') {
      if (Number.isInteger(k) && k > 0) {
        var a = this.arr, n = a.length;
        if (k <= n) {
          a[k - 1] = v;
          if (v === undefined && k === n) { while (a.length && a[a.length - 1] === undefined) a.pop(); }
          return;
        }
        if (k === n + 1) {
          if (v === undefined) { if (this.hash !== null) this.hash.delete(k); return; }
          a.push(v);
          if (this.hash !== null && this.hash.size) {
            var h = this.hash;
            while (h.has(a.length + 1)) { var nk = a.length + 1; a.push(h.get(nk)); h.delete(nk); }
          }
          return;
        }
      } else if (k !== k) {
        throw rterror('table index is NaN');
      }
    } else if (k instanceof LFloat) {
      return this.set(k.n, v);
    } else if (k === undefined) {
      throw rterror('table index is nil');
    }
    if (v === undefined) { if (this.hash !== null) this.hash.delete(k); return; }
    if (this.hash === null) this.hash = new Map();
    if (!this.hash.has(k)) this.hver++;
    this.hash.set(k, v);
  };
  LuaTable.prototype.length = function () { return this.arr.length; };

  // ------------------------------------------------------------ errors ----
  // Compiled chunks register their line maps here, so an error can say
  // "gi_idea.lua:1234:" as the real Lua would.
  var lineMaps = {};
  function luaPosition(level) {
    var stack = new Error().stack || '';
    var re = /lua:([^:\s()]+):(\d+):\d+/g, m, found = 0;
    while ((m = re.exec(stack)) !== null) {
      found++;
      if (found >= level) {
        var map = lineMaps[m[1]];
        var line = map ? map[Number(m[2]) - 1] : undefined;
        if (line) return m[1] + ':' + line + ': ';
        return m[1] + ': ';
      }
    }
    return '';
  }
  function LuaError(value, traceback) {
    this.value = value;
    this.message = typeof value === 'string' ? value : tostring(value);
    this.luaTraceback = traceback;
    this.stack = new Error().stack;
  }
  LuaError.prototype = Object.create(Error.prototype);
  LuaError.prototype.name = 'LuaError';
  function rterror(msg) { return new LuaError(luaPosition(1) + msg); }

  function typeName(v) {
    if (v === undefined || v === null) return 'nil';
    switch (typeof v) {
      case 'boolean': return 'boolean';
      case 'number': return 'number';
      case 'string': return 'string';
      case 'function': return 'function';
    }
    if (v instanceof LFloat) return 'number';
    if (v instanceof LuaTable) return 'table';
    return 'userdata';
  }

  // --------------------------------------------------------- numbers ----
  // Exact decimal expansion of a double: x = D * 10^-s, D a BigInt.
  var F64 = new Float64Array(1), U32 = new Uint32Array(F64.buffer);
  function exactDecimal(x) {
    F64[0] = x;
    var hi = U32[1], lo = U32[0];
    var exp = (hi >>> 20) & 0x7ff;
    var mant = (BigInt(hi & 0xfffff) << 32n) | BigInt(lo);
    if (exp === 0) exp = 1; else mant |= 1n << 52n;
    var e = exp - 1075;
    if (e >= 0) return { D: mant << BigInt(e), s: 0 };
    return { D: mant * (5n ** BigInt(-e)), s: -e };
  }
  function roundDiv(N, div) {      // round N/div half to even
    var q = N / div, r = N % div;
    var twice = r * 2n;
    if (twice > div || (twice === div && (q & 1n) === 1n)) q += 1n;
    return q;
  }
  function fixedDigits(x, f) {     // |x| to f decimals, C-exact; returns string
    var ex = exactDecimal(Math.abs(x));
    var q;
    if (f >= ex.s) q = ex.D * (10n ** BigInt(f - ex.s));
    else q = roundDiv(ex.D, 10n ** BigInt(ex.s - f));
    var s = q.toString();
    if (f === 0) return s;
    while (s.length <= f) s = '0' + s;
    return s.slice(0, s.length - f) + '.' + s.slice(s.length - f);
  }
  function expDigits(x, prec) {    // |x| as d.ddd with prec decimals; returns [mantissa, exponent]
    if (x === 0) return [prec > 0 ? '0.' + '0'.repeat(prec) : '0', 0];
    var ex = exactDecimal(Math.abs(x));
    var D = ex.D.toString();
    var X = D.length - 1 - ex.s;
    var P = prec + 1, q;
    if (D.length > P) {
      q = roundDiv(ex.D, 10n ** BigInt(D.length - P)).toString();
      if (q.length > P) { q = q.slice(0, P); X++; }
    } else q = D + '0'.repeat(P - D.length);
    return [prec > 0 ? q[0] + '.' + q.slice(1) : q, X];
  }
  function fmtExp(x, prec, upper) {
    var r = expDigits(x, prec);
    var X = r[1];
    var s = r[0] + (upper ? 'E' : 'e') + (X < 0 ? '-' : '+') + (Math.abs(X) < 10 ? '0' : '') + Math.abs(X);
    return s;
  }
  function stripZeros(s) {
    if (s.indexOf('.') < 0) return s;
    s = s.replace(/0+$/, '');
    return s.replace(/\.$/, '');
  }
  function fmtG(x, P, upper, alt) {   // C's %g of |x|
    if (P === 0) P = 1;
    if (x === 0) return '0';
    var X = expDigits(x, P - 1)[1];
    var s;
    if (X < -4 || X >= P) {
      var r = expDigits(x, P - 1);
      var m = alt ? r[0] : stripZeros(r[0]);
      s = m + (upper ? 'E' : 'e') + (r[1] < 0 ? '-' : '+') + (Math.abs(r[1]) < 10 ? '0' : '') + Math.abs(r[1]);
    } else {
      s = fixedDigits(x, P - 1 - X);
      if (!alt) s = stripZeros(s);
    }
    return s;
  }
  function floatStr(x) {
    if (x === Infinity) return 'inf';
    if (x === -Infinity) return '-inf';
    if (x !== x) return (1 / x) < 0 ? 'nan' : '-nan';
    var neg = x < 0 || (x === 0 && 1 / x < 0);
    var s = (neg ? '-' : '') + fmtG(x, 14, false, false);
    if (/^-?\d+$/.test(s)) s += '.0';
    return s;
  }
  function intStr(n) {
    if (Math.abs(n) <= 9007199254740992) return String(n === 0 ? 0 : n);
    return BigInt(n).toString();
  }
  // io.write prints a float with LUA_NUMBER_FMT alone: 1.0 is "1".
  function writeNum(v) {
    if (!isNum(v)) throw rterror('bad argument to \'write\' (string expected, got ' + typeName(v) + ')');
    if (typeof v === 'number' && Number.isInteger(v)) return intStr(v);
    var x = num(v);
    if (x === Infinity) return 'inf';
    if (x === -Infinity) return '-inf';
    if (x !== x) return '-nan';
    return (x < 0 || (x === 0 && 1 / x < 0) ? '-' : '') + fmtG(Math.abs(x), 14, false, false);
  }
  function numStr(v) {
    if (typeof v === 'number') return Number.isInteger(v) ? intStr(v) : floatStr(v);
    return floatStr(v.n);
  }

  // lua_stringtonumber: a whole numeral, spaces either side, or undefined.
  function str2num(s) {
    var t = s.replace(/^[ \f\n\r\t\v]+|[ \f\n\r\t\v]+$/g, '');
    var m;
    if ((m = /^([+-])?0[xX]([0-9a-fA-F]*)(?:\.([0-9a-fA-F]*))?(?:[pP]([+-]?\d+))?$/.exec(t))) {
      var ip = m[2], fp = m[3], ex = m[4];
      if (!ip && !fp) return undefined;
      var neg = m[1] === '-';
      if (fp === undefined && ex === undefined) {
        var big = BigInt.asIntN(64, BigInt('0x' + ip));
        var n = Number(big);
        return neg ? 0 - n : n;
      }
      var val = 0;
      for (var i = 0; i < ip.length; i++) val = val * 16 + parseInt(ip[i], 16);
      var scale = 1 / 16;
      fp = fp || '';
      for (var j = 0; j < fp.length; j++) { val += parseInt(fp[j], 16) * scale; scale /= 16; }
      if (ex) val *= Math.pow(2, Number(ex));
      return mkf(neg ? -val : val);
    }
    if ((m = /^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.exec(t))) {
      var isInt = m[1].indexOf('.') < 0 && !m[2];
      var v = Number(t);
      if (isInt) {
        if (Math.abs(v) <= 9223372036854775807) return v;
        return mkf(v);
      }
      return mkf(v);
    }
    return undefined;
  }

  function toNumberArith(v, op) {
    if (typeof v === 'number') return v;
    if (v instanceof LFloat) return v;
    if (typeof v === 'string') { var n = str2num(v); if (n !== undefined) return n; }
    return null;
  }
  function arithError(op, a, b) {
    var bad = (isNum(a) || (typeof a === 'string' && str2num(a) !== undefined)) ? b : a;
    if (op === 'concat') return rterror('attempt to concatenate a ' + typeName(bad) + ' value');
    if (op === 'bit') return rterror('attempt to perform bitwise operation on a ' + typeName(bad) + ' value');
    return rterror('attempt to perform arithmetic on a ' + typeName(bad) + ' value');
  }
  function metaOf(v) {
    if (v instanceof LuaTable) return v.mt;
    if (typeof v === 'string') return stringMeta;
    return null;
  }
  function metaBin(ev, a, b) {
    var mt = metaOf(a), h = mt && mt.get(ev);
    if (h === undefined) { mt = metaOf(b); h = mt && mt.get(ev); }
    if (h === undefined || h === null) return NOMETA;
    return first(call(h)(a, b));
  }
  var NOMETA = {};

  function arithSlow(op, a, b, ev) {
    var x = toNumberArith(a), y = toNumberArith(b);
    if (x === null || y === null) {
      var r = metaBin(ev, a, b);
      if (r !== NOMETA) return r;
      throw arithError(op, a, b);
    }
    switch (op) {
      case 'add': return add(x, y);
      case 'sub': return sub(x, y);
      case 'mul': return mul(x, y);
      case 'div': return div(x, y);
      case 'mod': return mod(x, y);
      case 'idiv': return idiv(x, y);
      case 'pow': return pow(x, y);
    }
  }
  function add(a, b) {
    if (typeof a === 'number' && typeof b === 'number') {
      var r = a + b;
      return (Number.isInteger(a) && Number.isInteger(b)) ? r : mkf(r);
    }
    if (isNum(a) && isNum(b)) return mkf(num(a) + num(b));
    return arithSlow('add', a, b, '__add');
  }
  function sub(a, b) {
    if (typeof a === 'number' && typeof b === 'number') {
      var r = a - b;
      return (Number.isInteger(a) && Number.isInteger(b)) ? r : mkf(r);
    }
    if (isNum(a) && isNum(b)) return mkf(num(a) - num(b));
    return arithSlow('sub', a, b, '__sub');
  }
  function mul(a, b) {
    if (typeof a === 'number' && typeof b === 'number') {
      var r = a * b;
      if (Number.isInteger(a) && Number.isInteger(b)) return r === 0 ? 0 : r;
      return mkf(r);
    }
    if (isNum(a) && isNum(b)) return mkf(num(a) * num(b));
    return arithSlow('mul', a, b, '__mul');
  }
  function div(a, b) {
    if (isNum(a) && isNum(b)) return mkf(num(a) / num(b));
    return arithSlow('div', a, b, '__div');
  }
  function idiv(a, b) {
    if (typeof a === 'number' && typeof b === 'number' && Number.isInteger(a) && Number.isInteger(b)) {
      if (b === 0) throw rterror("attempt to perform 'n//0'");
      var q = Math.floor(a / b);
      return q === 0 ? 0 : q;
    }
    if (isNum(a) && isNum(b)) return mkf(Math.floor(num(a) / num(b)));
    return arithSlow('idiv', a, b, '__idiv');
  }
  function mod(a, b) {
    if (typeof a === 'number' && typeof b === 'number' && Number.isInteger(a) && Number.isInteger(b)) {
      if (b === 0) throw rterror("attempt to perform 'n%%0'");
      var r = a % b;
      if (r !== 0 && (r < 0) !== (b < 0)) r += b;
      return r === 0 ? 0 : r;
    }
    if (isNum(a) && isNum(b)) {
      var x = num(a), y = num(b);
      var m;
      if (y === Infinity || y === -Infinity) m = x;
      else m = x % y;
      if ((m > 0) ? y < 0 : (m < 0 && y !== m)) m += y;
      return mkf(m);
    }
    return arithSlow('mod', a, b, '__mod');
  }
  function pow(a, b) {
    if (isNum(a) && isNum(b)) return mkf(Math.pow(num(a), num(b)));
    return arithSlow('pow', a, b, '__pow');
  }
  function unm(a) {
    if (typeof a === 'number') return Number.isInteger(a) ? 0 - a : -a;
    if (a instanceof LFloat) return new LFloat(-a.n);
    var x = toNumberArith(a);
    if (x !== null) return unm(x);
    var mt = metaOf(a), h = mt && mt.get('__unm');
    if (h !== undefined && h !== null) return first(call(h)(a, a));
    throw rterror('attempt to perform arithmetic on a ' + typeName(a) + ' value');
  }

  // Bitwise operations work on 64-bit integers.
  function toInt64(v, a, b) {
    var x = typeof v === 'string' ? str2num(v) : v;
    if (typeof x === 'number' && Number.isInteger(x)) return BigInt(x);
    if (x instanceof LFloat) return BigInt(x.n);
    if (typeof x === 'number') throw rterror('number has no integer representation');
    throw arithError('bit', a, b);
  }
  function fromInt64(big) { return Number(BigInt.asIntN(64, big)); }
  function small(a, b) {
    return typeof a === 'number' && typeof b === 'number' && (a | 0) === a && (b | 0) === b;
  }
  function band(a, b) { if (small(a, b)) return a & b; return bitSlow('__band', a, b, function (x, y) { return x & y; }); }
  function bor(a, b) { if (small(a, b)) return a | b; return bitSlow('__bor', a, b, function (x, y) { return x | y; }); }
  function bxor(a, b) { if (small(a, b)) return a ^ b; return bitSlow('__bxor', a, b, function (x, y) { return x ^ y; }); }
  function shiftLeft(x, n) {
    if (n <= -64n || n >= 64n) return 0n;
    if (n >= 0n) return BigInt.asUintN(64, x << n);
    return BigInt.asUintN(64, x) >> (-n);
  }
  function shl(a, b) { return bitSlow('__shl', a, b, function (x, y) { return shiftLeft(x, y); }); }
  function shr(a, b) { return bitSlow('__shr', a, b, function (x, y) { return shiftLeft(x, -y); }); }
  function bnot(a) {
    if (typeof a === 'number' && (a | 0) === a) return ~a;
    var mt = metaOf(a), h = mt && mt.get('__bnot');
    if (h !== undefined && h !== null && !isNum(a)) return first(call(h)(a, a));
    return fromInt64(~toInt64(a, a, a));
  }
  function bitSlow(ev, a, b, f) {
    if (!((isNum(a) || typeof a === 'string') && (isNum(b) || typeof b === 'string'))) {
      var r = metaBin(ev, a, b);
      if (r !== NOMETA) return r;
    }
    return fromInt64(f(toInt64(a, a, b), toInt64(b, a, b)));
  }

  function concat(a, b) {
    var ta = typeof a, tb = typeof b;
    if (ta === 'string' && tb === 'string') return a + b;
    if ((ta === 'string' || isNum(a)) && (tb === 'string' || isNum(b))) {
      return (ta === 'string' ? a : numStr(a)) + (tb === 'string' ? b : numStr(b));
    }
    var r = metaBin('__concat', a, b);
    if (r !== NOMETA) return r;
    throw arithError('concat', a, b);
  }

  function len(v) {
    if (typeof v === 'string') return v.length;
    if (v instanceof LuaTable) {
      if (v.mt !== null) {
        var h = v.mt.get('__len');
        if (h !== undefined) return first(call(h)(v));
      }
      return v.arr.length;
    }
    var mt = metaOf(v), h2 = mt && mt.get('__len');
    if (h2 !== undefined && h2 !== null) return first(call(h2)(v));
    throw rterror('attempt to get length of a ' + typeName(v) + ' value');
  }

  function eq(a, b) {
    if (a === b) return true;
    var ta = typeof a, tb = typeof b;
    if (ta === 'object' || tb === 'object') {
      if (isNum(a) && isNum(b)) return num(a) === num(b);
      if (a instanceof LuaTable && b instanceof LuaTable) {
        var h = (a.mt && a.mt.get('__eq')) || (b.mt && b.mt.get('__eq'));
        if (h) return truthy(first(call(h)(a, b)));
      }
    }
    return false;
  }
  function lt(a, b) {
    if (typeof a === 'number' && typeof b === 'number') return a < b;
    if (isNum(a) && isNum(b)) return num(a) < num(b);
    if (typeof a === 'string' && typeof b === 'string') return a < b;
    var r = metaBin('__lt', a, b);
    if (r !== NOMETA) return truthy(r);
    throw compareError(a, b);
  }
  function le(a, b) {
    if (typeof a === 'number' && typeof b === 'number') return a <= b;
    if (isNum(a) && isNum(b)) return num(a) <= num(b);
    if (typeof a === 'string' && typeof b === 'string') return a <= b;
    var r = metaBin('__le', a, b);
    if (r !== NOMETA) return truthy(r);
    throw compareError(a, b);
  }
  function gt(a, b) { return lt(b, a); }
  function ge(a, b) { return le(b, a); }
  function compareError(a, b) {
    var t1 = typeName(a), t2 = typeName(b);
    if (t1 === t2) return rterror('attempt to compare two ' + t1 + ' values');
    return rterror('attempt to compare ' + t1 + ' with ' + t2);
  }
  function truthy(v) { return v !== undefined && v !== false && v !== null; }

  // ------------------------------------------------------- indexing ----
  function index(o, k, desc) {
    if (o instanceof LuaTable) {
      var v = o.get(k);
      if (v !== undefined || o.mt === null) return v;
      return metaIndex(o, k, desc);
    }
    if (typeof o === 'string') return stringLib.get(k);
    return metaIndex(o, k, desc);
  }
  function metaIndex(o, k, desc) {
    for (var loop = 0; loop < 100; loop++) {
      var h;
      if (o instanceof LuaTable) {
        var v = o.get(k);
        if (v !== undefined) return v;
        if (o.mt === null) return undefined;
        h = o.mt.get('__index');
        if (h === undefined) return undefined;
      } else {
        var mt = metaOf(o);
        h = mt && mt.get('__index');
        if (h === undefined || h === null) {
          throw rterror('attempt to index a ' + typeName(o) + ' value' + (desc ? ' (' + desc + ')' : ''));
        }
      }
      if (typeof h === 'function') return first(h(o, k));
      o = h;
    }
    throw rterror("'__index' chain too long; possible loop");
  }
  function setindex(o, k, v, desc) {
    if (o instanceof LuaTable) {
      if (o.mt === null) { o.set(k, v); return; }
      var h = o.mt.get('__newindex');
      if (h === undefined || o.get(k) !== undefined) { o.set(k, v); return; }
      if (typeof h === 'function') { h(o, k, v); return; }
      return setindex(h, k, v);
    }
    throw rterror('attempt to index a ' + typeName(o) + ' value' + (desc ? ' (' + desc + ')' : ''));
  }

  function call(f, desc) {
    if (typeof f === 'function') return f;
    var mt = metaOf(f), h = mt && mt.get('__call');
    if (typeof h === 'function') return function () {
      var args = [f];
      for (var i = 0; i < arguments.length; i++) args.push(arguments[i]);
      return h.apply(null, args);
    };
    throw rterror('attempt to call a ' + typeName(f) + ' value' + (desc ? ' (' + desc + ')' : ''));
  }
  function method(o, name) {
    var f = index(o, name, 'method \'' + name + '\'');
    if (typeof f !== 'function') f = call(f, "method '" + name + "'");
    var args = [o];
    for (var i = 2; i < arguments.length; i++) args.push(arguments[i]);
    return f.apply(null, args);
  }

  function tbl(list, keyed) {
    var t = new LuaTable();
    if (list.length) {
      var a = list.slice();
      while (a.length && a[a.length - 1] === undefined) a.pop();
      t.arr = a;
    }
    if (keyed) {
      for (var i = 0; i < keyed.length; i += 2) {
        if (keyed[i] === undefined) throw rterror('table index is nil');
        if (keyed[i + 1] !== undefined) t.set(keyed[i], keyed[i + 1]);
      }
    }
    return t;
  }

  // ------------------------------------------------------- iteration ----
  function IpairsIter(t) { this.t = t; this.i = 0; this.a = undefined; this.b = undefined; }
  IpairsIter.prototype.step = function () {
    var i = this.i + 1, v = this.t.get(i);
    if (v === undefined) return false;
    this.i = i; this.a = i; this.b = v; return true;
  };
  function PairsIter(t) { this.t = t; this.i = 0; this.it = null; this.a = undefined; this.b = undefined; }
  PairsIter.prototype.step = function () {
    var arr = this.t.arr;
    while (this.it === null && this.i < arr.length) {
      var v = arr[this.i++];
      if (v !== undefined) { this.a = this.i; this.b = v; return true; }
    }
    if (this.it === null) {
      if (this.t.hash === null) return false;
      this.it = this.t.hash.entries();
    }
    var n = this.it.next();
    if (n.done) return false;
    this.a = n.value[0]; this.b = n.value[1];
    return true;
  };
  function GenIter(f, s, c) { this.f = call(f, 'for iterator'); this.s = s; this.c = c; this.a = undefined; this.b = undefined; this.v = NONE; }
  GenIter.prototype.step = function () {
    var r = this.f(this.s, this.c);
    var v = r instanceof Multi ? r.a : [r];
    if (v[0] === undefined) return false;
    this.c = v[0]; this.a = v[0]; this.b = v[1]; this.v = v;
    return true;
  };
  function iter(f, s, c) {
    if (f === ipairsAux && s instanceof LuaTable && s.mt === null) return new IpairsIter(s);
    if (f === luaNext && s instanceof LuaTable && c === undefined && s.mt === null) return new PairsIter(s);
    return new GenIter(f, s, c);
  }

  function forprep(a, b, c) {
    if (c === undefined) c = 1;
    if (!isNum(a)) throw rterror("'for' initial value must be a number");
    if (!isNum(b)) throw rterror("'for' limit must be a number");
    if (!isNum(c)) throw rterror("'for' step must be a number");
    var x = num(a), lim = num(b), st = num(c);
    if (st === 0) throw rterror("'for' step is zero");
    var intLoop = typeof a === 'number' && Number.isInteger(a) && typeof c === 'number' && Number.isInteger(c);
    if (intLoop) {
      if (!(typeof b === 'number' && Number.isInteger(b))) {
        if (lim !== lim) return [1, 0, 1, false];
        lim = st > 0 ? Math.floor(lim) : Math.ceil(lim);
      }
      return [x, lim, st, false];
    }
    return [x, lim, st, true];
  }

  // ------------------------------------------------------- tostring ----
  function tostring(v) {
    if (v === undefined || v === null) return 'nil';
    switch (typeof v) {
      case 'string': return v;
      case 'number': return numStr(v);
      case 'boolean': return v ? 'true' : 'false';
      case 'function': return 'function: ' + addressOf(v);
    }
    if (v instanceof LFloat) return floatStr(v.n);
    if (v instanceof LuaTable) {
      if (v.mt !== null) {
        var h = v.mt.get('__tostring');
        if (h !== undefined) {
          var s = first(call(h)(v));
          if (typeof s !== 'string') throw rterror("'__tostring' must return a string");
          return s;
        }
        var nm = v.mt.get('__name');
        if (typeof nm === 'string') return nm + ': ' + addressOf(v);
      }
      return 'table: ' + addressOf(v);
    }
    return 'userdata: ' + addressOf(v);
  }
  var addresses = new WeakMap(), nextAddress = 0x55d0c0de0000;
  function addressOf(o) {
    var a = addresses.get(o);
    if (a === undefined) { a = nextAddress; nextAddress += 0x40; addresses.set(o, a); }
    return '0x' + a.toString(16).padStart(14, '0');
  }

  // ===================================================== the library ======
  function argError(n, fname, msg) { return rterror("bad argument #" + n + " to '" + fname + "' (" + msg + ')'); }
  function checkTable(v, n, fname) {
    if (!(v instanceof LuaTable)) throw argError(n, fname, 'table expected, got ' + typeNameArg(v));
    return v;
  }
  function typeNameArg(v) { return v === undefined ? 'no value' : typeName(v); }
  function checkInt(v, n, fname) {
    if (typeof v === 'number' && Number.isInteger(v)) return v;
    if (v instanceof LFloat) return v.n;
    if (typeof v === 'string') { var x = str2num(v); if (x !== undefined) return checkInt(x, n, fname); }
    if (typeof v === 'number') throw argError(n, fname, 'number has no integer representation');
    throw argError(n, fname, 'number expected, got ' + typeNameArg(v));
  }
  function optInt(v, n, fname, d) { return v === undefined ? d : checkInt(v, n, fname); }
  function checkNum(v, n, fname) {
    if (typeof v === 'number') return v;
    if (v instanceof LFloat) return v.n;
    if (typeof v === 'string') { var x = str2num(v); if (x !== undefined) return num(x); }
    throw argError(n, fname, 'number expected, got ' + typeNameArg(v));
  }
  function checkStr(v, n, fname) {
    if (typeof v === 'string') return v;
    if (isNum(v)) return numStr(v);
    throw argError(n, fname, 'string expected, got ' + typeNameArg(v));
  }

  function rawLen(t) { return t instanceof LuaTable ? t.arr.length : (typeof t === 'string' ? t.length : 0); }

  // ---------------------------------------------------------- base ------
  function luaNext(t, k) {
    checkTable(t, 1, 'next');
    var arr = t.arr, i = 0;
    if (k !== undefined) {
      if (typeof k === 'number' && Number.isInteger(k) && k >= 1 && k <= arr.length) i = k;
      else if (k instanceof LFloat && k.n >= 1 && k.n <= arr.length) i = k.n;
      else i = -1;
    }
    if (i >= 0) {
      for (; i < arr.length; i++) if (arr[i] !== undefined) return new Multi([i + 1, arr[i]]);
      if (t.hash === null) return undefined;
      var it = t.hash.entries().next();
      return it.done ? undefined : new Multi([it.value[0], it.value[1]]);
    }
    if (t.hash === null) throw rterror("invalid key to 'next'");
    if (t._nkver !== t.hver || !t._nk) {
      t._nk = Array.from(t.hash.keys());
      t._nki = new Map();
      for (var j = 0; j < t._nk.length; j++) t._nki.set(t._nk[j], j);
      t._nkver = t.hver;
    }
    var key = k instanceof LFloat ? k.n : k;
    var pos = t._nki.get(key);
    if (pos === undefined) throw rterror("invalid key to 'next'");
    for (pos++; pos < t._nk.length; pos++) {
      var kk = t._nk[pos];
      if (t.hash.has(kk)) return new Multi([kk, t.hash.get(kk)]);
    }
    return undefined;
  }
  function ipairsAux(t, i) {
    i = i + 1;
    var v = index(t, i);
    return v === undefined ? undefined : new Multi([i, v]);
  }

  function makeEnv(host) {
    host = host || {};
    var G = new LuaTable();
    function reg(t, name, f) { t.set(name, f); }

    reg(G, 'print', function () {
      var parts = [];
      for (var i = 0; i < arguments.length; i++) parts.push(tostring(arguments[i]));
      (host.print || function (s) { console.log(s); })(parts.join('\t'));
      return NONE;
    });
    reg(G, 'type', function (v) {
      if (arguments.length === 0) throw argError(1, 'type', 'value expected');
      return typeName(v);
    });
    reg(G, 'tostring', function (v) { return tostring(v); });
    reg(G, 'tonumber', function (v, base) {
      if (base === undefined) {
        if (isNum(v)) return v;
        if (typeof v === 'string') return str2num(v);
        if (arguments.length === 0) throw argError(1, 'tonumber', 'value expected');
        return undefined;
      }
      var b = checkInt(base, 2, 'tonumber');
      var s = checkStr(v, 1, 'tonumber').replace(/^\s+|\s+$/g, '').toLowerCase();
      var neg = false;
      if (s[0] === '-') { neg = true; s = s.slice(1); }
      if (!s.length) return undefined;
      var n = 0;
      for (var i = 0; i < s.length; i++) {
        var c = s.charCodeAt(i);
        var d = c >= 48 && c <= 57 ? c - 48 : (c >= 97 && c <= 122 ? c - 87 : 99);
        if (d >= b) return undefined;
        n = n * b + d;
      }
      return neg ? -n : n;
    });
    reg(G, 'ipairs', function (t) {
      if (arguments.length === 0) throw argError(1, 'ipairs', 'table expected, got no value');
      return new Multi([ipairsAux, t, 0]);
    });
    reg(G, 'pairs', function (t) {
      if (t instanceof LuaTable && t.mt !== null) {
        var h = t.mt.get('__pairs');
        if (h !== undefined) { var r = sp(call(h)(t)); return new Multi([r[0], r[1], r[2]]); }
      }
      checkTable(t, 1, 'pairs');
      return new Multi([luaNext, t, undefined]);
    });
    reg(G, 'next', luaNext);
    reg(G, 'select', function (n) {
      var count = arguments.length - 1;
      if (n === '#') return count;
      var i = checkInt(n, 1, 'select');
      if (i < 0) i = count + i; else if (i === 0) throw argError(1, 'select', 'index out of range');
      else i = i - 1;
      if (i < 0) throw argError(1, 'select', 'index out of range');
      var out = [];
      for (var j = i + 1; j < arguments.length; j++) out.push(arguments[j]);
      return ret(out);
    });
    reg(G, 'rawget', function (t, k) { checkTable(t, 1, 'rawget'); return t.get(k); });
    reg(G, 'rawset', function (t, k, v) { checkTable(t, 1, 'rawset'); t.set(k, v); return t; });
    reg(G, 'rawequal', function (a, b) { return a === b || (isNum(a) && isNum(b) && num(a) === num(b)); });
    reg(G, 'rawlen', function (t) { return rawLen(t); });
    reg(G, 'setmetatable', function (t, mt) {
      checkTable(t, 1, 'setmetatable');
      if (t.mt && t.mt.get('__metatable') !== undefined) throw rterror('cannot change a protected metatable');
      t.mt = mt === undefined ? null : mt;
      return t;
    });
    reg(G, 'getmetatable', function (v) {
      var mt = metaOf(v);
      if (!mt) return undefined;
      var p = mt.get('__metatable');
      return p !== undefined ? p : mt;
    });
    reg(G, 'assert', function (v, msg) {
      if (truthy(v)) { return ret(Array.prototype.slice.call(arguments)); }
      if (arguments.length < 1) throw argError(1, 'assert', 'value expected');
      throw new LuaError(arguments.length >= 2 ? msg : 'assertion failed!');
    });
    reg(G, 'error', function (v, level) {
      var lv = level === undefined ? 1 : num(level);
      if (typeof v === 'string' && lv > 0) v = luaPosition(lv + 1) + v;
      throw new LuaError(v);
    });
    reg(G, 'pcall', function (f) {
      var args = Array.prototype.slice.call(arguments, 1);
      try {
        var r = call(f).apply(null, args);
        return new Multi([true].concat(sp(r)));
      } catch (e) {
        return new Multi([false, errorValue(e)]);
      }
    });
    reg(G, 'xpcall', function (f, handler) {
      var args = Array.prototype.slice.call(arguments, 2);
      try {
        var r = call(f).apply(null, args);
        return new Multi([true].concat(sp(r)));
      } catch (e) {
        return new Multi([false].concat(sp(call(handler)(errorValue(e)))));
      }
    });
    reg(G, 'collectgarbage', function (opt) { return opt === 'count' ? mkf(1024) : 0; });
    reg(G, 'load', function (chunk, name, mode, env) {
      var src = chunk;
      if (typeof chunk === 'function') {
        var pieces = [], piece;
        while ((piece = first(chunk())) !== undefined && piece !== '') pieces.push(piece);
        src = pieces.join('');
      }
      try {
        return NS.load(src, typeof name === 'string' ? name.replace(/^[=@]/, '') : 'chunk', env || G);
      } catch (e) {
        return new Multi([undefined, errorValue(e)]);
      }
    });
    reg(G, 'loadfile', function (path, mode, env) {
      var src = host.readFile ? host.readFile(path) : null;
      if (src === null || src === undefined) return new Multi([undefined, 'cannot open ' + path]);
      try { return NS.load(src, path, env || G); }
      catch (e) { return new Multi([undefined, errorValue(e)]); }
    });
    reg(G, 'dofile', function (path) {
      var src = host.readFile ? host.readFile(path) : null;
      if (src === null || src === undefined) throw rterror('cannot open ' + path);
      return NS.load(src, path, G)();
    });
    reg(G, 'require', function (name) {
      var loaded = G.get('package').get('loaded');
      var v = loaded.get(name);
      if (v !== undefined) return v;
      if (!host.require) throw rterror("module '" + name + "' not found");
      v = host.require(name);
      loaded.set(name, v === undefined ? true : v);
      return v === undefined ? true : v;
    });
    var pkg = new LuaTable(); pkg.set('loaded', new LuaTable()); pkg.set('path', './?.lua');
    G.set('package', pkg);
    G.set('_G', G);
    G.set('_VERSION', 'Lua 5.4');

    G.set('string', stringLib);
    G.set('table', makeTableLib());
    G.set('math', makeMathLib());
    G.set('os', makeOsLib(host));
    G.set('io', makeIoLib(host));
    G.set('utf8', makeUtf8Lib());
    pkg.get('loaded').set('string', stringLib);
    pkg.get('loaded').set('_G', G);
    return G;
  }
  function errorValue(e) {
    if (e instanceof LuaError) return e.value;
    if (e instanceof RangeError) return 'stack overflow';
    if (e && e.name === 'LuaSyntaxError') return e.message;
    return String(e && e.message ? e.message : e);
  }

  // --------------------------------------------------------- table ------
  function makeTableLib() {
    var T = new LuaTable();
    T.set('insert', function (t, a, b) {
      checkTable(t, 1, 'insert');
      var e = len(t) + 1;
      if (arguments.length === 2) { setindex(t, e, a); return NONE; }
      if (arguments.length !== 3) throw rterror("wrong number of arguments to 'insert'");
      var pos = checkInt(a, 2, 'insert');
      if (pos < 1 || pos > e) throw argError(2, 'insert', 'position out of bounds');
      if (t.mt === null && e - 1 === t.arr.length) {
        t.arr.splice(pos - 1, 0, b);
        if (b === undefined) { while (t.arr.length && t.arr[t.arr.length - 1] === undefined) t.arr.pop(); }
        return NONE;
      }
      for (var i = e; i > pos; i--) setindex(t, i, index(t, i - 1));
      setindex(t, pos, b);
      return NONE;
    });
    T.set('remove', function (t, p) {
      checkTable(t, 1, 'remove');
      var size = len(t);
      var pos = p === undefined ? size : checkInt(p, 2, 'remove');
      if (p !== undefined && pos !== size && (pos < 1 || pos > size + 1)) throw argError(2, 'remove', 'position out of bounds');
      var result = index(t, pos);
      if (t.mt === null && size === t.arr.length && pos >= 1 && pos <= size) {
        t.arr.splice(pos - 1, 1);
        while (t.arr.length && t.arr[t.arr.length - 1] === undefined) t.arr.pop();
        return result;
      }
      for (; pos < size; pos++) setindex(t, pos, index(t, pos + 1));
      setindex(t, pos, undefined);
      return result;
    });
    T.set('concat', function (t, sep, i, j) {
      checkTable(t, 1, 'concat');
      sep = sep === undefined ? '' : checkStr(sep, 2, 'concat');
      var a = optInt(i, 3, 'concat', 1), b = j === undefined ? len(t) : checkInt(j, 4, 'concat');
      var parts = [];
      for (var k = a; k <= b; k++) {
        var v = index(t, k);
        if (typeof v === 'string') parts.push(v);
        else if (isNum(v)) parts.push(numStr(v));
        else throw rterror("invalid value (at index " + k + ") in table for 'concat'");
      }
      return parts.join(sep);
    });
    T.set('unpack', function (t, i, j) {
      var a = optInt(i, 2, 'unpack', 1), b = j === undefined ? len(t) : checkInt(j, 3, 'unpack');
      var out = [];
      for (var k = a; k <= b; k++) out.push(index(t, k));
      return ret(out);
    });
    T.set('pack', function () {
      var t = tbl(Array.prototype.slice.call(arguments));
      t.set('n', arguments.length);
      return t;
    });
    T.set('move', function (a1, f, e, t, a2) {
      if (a2 === undefined) a2 = a1;
      f = checkInt(f, 2, 'move'); e = checkInt(e, 3, 'move'); t = checkInt(t, 4, 'move');
      if (e >= f) {
        if (t > e || t <= f || a1 !== a2) for (var i = 0; i <= e - f; i++) setindex(a2, t + i, index(a1, f + i));
        else for (var k = e - f; k >= 0; k--) setindex(a2, t + k, index(a1, f + k));
      }
      return a2;
    });
    T.set('sort', function (t, comp) {
      checkTable(t, 1, 'sort');
      var n = len(t);
      if (n > 1) {
        var a = new Array(n + 1);
        for (var i = 1; i <= n; i++) a[i] = index(t, i);
        var less;
        if (comp !== undefined) {
          var cf = call(comp);
          less = function (x, y) { return truthy(first(cf(x, y))); };
        } else less = lt;
        auxsort(a, 1, n, 0, less);
        for (var j = 1; j <= n; j++) setindex(t, j, a[j]);
      }
      return NONE;
    });
    return T;
  }

  // Lua 5.4's ltablib.c sort, line for line: ties come out in the same
  // order as in the real Lua, which matters to engines that sort with them.
  var RANLIMIT = 100;
  function auxsort(a, lo, up, rnd, less) {
    var t;
    while (lo < up) {
      if (less(a[up], a[lo])) { t = a[lo]; a[lo] = a[up]; a[up] = t; }
      if (up - lo === 1) break;
      var p;
      if (up - lo < RANLIMIT || rnd === 0) p = Math.floor((lo + up) / 2);
      else { var r4 = Math.floor((up - lo) / 4); p = rnd % (r4 * 2) + (lo + r4); }
      if (less(a[p], a[lo])) { t = a[p]; a[p] = a[lo]; a[lo] = t; }
      else if (less(a[up], a[p])) { t = a[p]; a[p] = a[up]; a[up] = t; }
      if (up - lo === 2) break;
      var P = a[p];
      t = a[p]; a[p] = a[up - 1]; a[up - 1] = t;
      // partition
      var i = lo, j = up - 1;
      for (;;) {
        while (less(a[++i], P)) {
          if (i === up - 1) throw rterror('invalid order function for sorting');
        }
        while (less(P, a[--j])) {
          if (j < i) throw rterror('invalid order function for sorting');
        }
        if (j < i) { t = a[up - 1]; a[up - 1] = a[i]; a[i] = t; break; }
        t = a[i]; a[i] = a[j]; a[j] = t;
      }
      p = i;
      var n;
      if (p - lo < up - p) { auxsort(a, lo, p - 1, rnd, less); n = p - lo; lo = p + 1; }
      else { auxsort(a, p + 1, up, rnd, less); n = up - p; up = p - 1; }
      if ((up - lo) / 128 > n) rnd = 0x5bd1e995;   // real Lua randomises here
    }
  }

  // ---------------------------------------------------------- math ------
  function makeMathLib() {
    var M = new LuaTable();
    M.set('pi', Math.PI);
    M.set('huge', Infinity);
    M.set('maxinteger', 9223372036854775807);
    M.set('mininteger', -9223372036854775808);
    M.set('abs', function (x) {
      if (typeof x === 'number') return Number.isInteger(x) ? (x < 0 ? 0 - x : x) : Math.abs(x);
      if (x instanceof LFloat) return new LFloat(Math.abs(x.n));
      return mkfOrInt(Math.abs(checkNum(x, 1, 'abs')), x);
    });
    M.set('floor', function (x) {
      if (typeof x === 'number' && Number.isInteger(x)) return x;
      var r = Math.floor(checkNum(x, 1, 'floor'));
      return r === 0 ? 0 : r;
    });
    M.set('ceil', function (x) {
      if (typeof x === 'number' && Number.isInteger(x)) return x;
      var r = Math.ceil(checkNum(x, 1, 'ceil'));
      return r === 0 ? 0 : r;
    });
    function minmax(isMax, name) {
      return function () {
        if (arguments.length === 0) throw argError(1, name, 'number expected, got no value');
        var best = arguments[0]; checkNum(best, 1, name);
        for (var i = 1; i < arguments.length; i++) {
          var v = arguments[i]; checkNum(v, i + 1, name);
          if (isMax ? lt(best, v) : lt(v, best)) best = v;
        }
        return best;
      };
    }
    M.set('max', minmax(true, 'max'));
    M.set('min', minmax(false, 'min'));
    function fl(f, name) { return function (x) { return mkf(f(checkNum(x, 1, name))); }; }
    M.set('sqrt', fl(Math.sqrt, 'sqrt'));
    M.set('sin', fl(Math.sin, 'sin'));
    M.set('cos', fl(Math.cos, 'cos'));
    M.set('tan', fl(Math.tan, 'tan'));
    M.set('asin', fl(Math.asin, 'asin'));
    M.set('acos', fl(Math.acos, 'acos'));
    M.set('exp', fl(Math.exp, 'exp'));
    M.set('atan', function (y, x) { return mkf(Math.atan2(checkNum(y, 1, 'atan'), x === undefined ? 1 : checkNum(x, 2, 'atan'))); });
    M.set('log', function (x, base) {
      var v = checkNum(x, 1, 'log');
      if (base === undefined) return mkf(Math.log(v));
      var b = checkNum(base, 2, 'log');
      if (b === 2) return mkf(Math.log2(v));
      if (b === 10) return mkf(Math.log10(v));
      return mkf(Math.log(v) / Math.log(b));
    });
    M.set('fmod', function (a, b) {
      if (typeof a === 'number' && typeof b === 'number' && Number.isInteger(a) && Number.isInteger(b)) {
        if (b === 0) throw argError(2, 'fmod', 'zero');
        return a % b === 0 ? 0 : a % b;
      }
      return mkf(checkNum(a, 1, 'fmod') % checkNum(b, 2, 'fmod'));
    });
    M.set('modf', function (x) {
      var v = checkNum(x, 1, 'modf');
      var ip = v >= 0 ? Math.floor(v) : Math.ceil(v);
      var fp = (v === Infinity || v === -Infinity) ? 0 : v - ip;
      return new Multi([mkf(ip), mkf(fp)]);
    });
    M.set('tointeger', function (x) {
      if (typeof x === 'number' && Number.isInteger(x)) return x;
      if (x instanceof LFloat) return x.n;
      if (typeof x === 'string') { var n = str2num(x); return n === undefined ? undefined : (typeof n === 'number' && Number.isInteger(n) ? n : (n instanceof LFloat ? n.n : undefined)); }
      return undefined;
    });
    M.set('type', function (x) {
      if (arguments.length === 0) throw argError(1, 'type', 'value expected');
      if (typeof x === 'number') return Number.isInteger(x) ? 'integer' : 'float';
      if (x instanceof LFloat) return 'float';
      return undefined;
    });
    M.set('ult', function (a, b) {
      return BigInt.asUintN(64, BigInt(checkInt(a, 1, 'ult'))) < BigInt.asUintN(64, BigInt(checkInt(b, 2, 'ult')));
    });

    // xoshiro256**, as lmathlib.c has it, on 64-bit BigInts.
    var MASK = (1n << 64n) - 1n;
    var state = [0n, 0n, 0n, 0n];
    function rotl(x, n) { return ((x << BigInt(n)) | (x >> BigInt(64 - n))) & MASK; }
    function nextrand() {
      var s0 = state[0], s1 = state[1], s2 = state[2] ^ s0, s3 = state[3] ^ s1;
      var res = (rotl((s1 * 5n) & MASK, 7) * 9n) & MASK;
      state[0] = s0 ^ s3;
      state[1] = s1 ^ s2;
      state[2] = s2 ^ ((s1 << 17n) & MASK);
      state[3] = rotl(s3, 45);
      return res;
    }
    function setseed(n1, n2) {
      state = [BigInt.asUintN(64, n1), 0xffn, BigInt.asUintN(64, n2), 0n];
      for (var i = 0; i < 16; i++) nextrand();
    }
    setseed(BigInt(Date.now()), 0n);
    function project(ran, n) {
      if ((n & (n + 1n)) === 0n) return ran & n;
      var lim = n;
      lim |= lim >> 1n; lim |= lim >> 2n; lim |= lim >> 4n; lim |= lim >> 8n;
      lim |= lim >> 16n; lim |= lim >> 32n;
      while ((ran &= lim) > n) ran = nextrand();
      return ran;
    }
    M.set('random', function (m, n) {
      var rv = nextrand();
      var low, up;
      switch (arguments.length) {
        case 0: return mkf(Number(rv >> 11n) * Math.pow(2, -53));
        case 1:
          low = 1n; up = BigInt(checkInt(m, 1, 'random'));
          if (up === 0n) return fromInt64(rv);
          break;
        case 2:
          low = BigInt(checkInt(m, 1, 'random')); up = BigInt(checkInt(n, 2, 'random'));
          break;
        default: throw rterror('wrong number of arguments');
      }
      if (!(low <= up)) throw argError(1, 'random', 'interval is empty');
      var p = project(rv, BigInt.asUintN(64, up - low));
      return fromInt64(p + BigInt.asUintN(64, low));
    });
    M.set('randomseed', function (a, b) {
      if (arguments.length === 0) { setseed(BigInt(Date.now()), 0n); return; }
      var n1 = isFloatVal(a) ? BigInt(Math.trunc(num(a))) : BigInt(checkInt(a, 1, 'randomseed'));
      var n2 = b === undefined ? 0n : BigInt(checkInt(b, 2, 'randomseed'));
      setseed(n1, n2);
      return new Multi([fromInt64(n1), fromInt64(n2)]);
    });
    return M;
  }
  function mkfOrInt(r, orig) { return isFloatVal(orig) ? mkf(r) : r; }

  // ------------------------------------------------------------ os ------
  function makeOsLib(host) {
    var O = new LuaTable();
    var now = host.now || function () { return Date.now(); };
    O.set('time', function (t) {
      if (t === undefined) return Math.floor(now() / 1000);
      checkTable(t, 1, 'time');
      function field(k, d) {
        var v = t.get(k);
        if (v === undefined) { if (d === undefined) throw rterror("field '" + k + "' missing in date table"); return d; }
        return num(v);
      }
      var d = new Date(field('year'), field('month') - 1, field('day'), field('hour', 12), field('min', 0), field('sec', 0));
      return Math.floor(d.getTime() / 1000);
    });
    O.set('clock', function () {
      var p = (typeof performance !== 'undefined') ? performance.now() : Date.now();
      return mkf(p / 1000);
    });
    O.set('date', function (fmt, t) {
      fmt = fmt === undefined ? '%c' : checkStr(fmt, 1, 'date');
      var ms = t === undefined ? now() : num(t) * 1000;
      var utc = fmt[0] === '!';
      if (utc) fmt = fmt.slice(1);
      var d = new Date(ms);
      var g = utc
        ? { Y: d.getUTCFullYear(), m: d.getUTCMonth(), d: d.getUTCDate(), H: d.getUTCHours(), M: d.getUTCMinutes(), S: d.getUTCSeconds(), w: d.getUTCDay() }
        : { Y: d.getFullYear(), m: d.getMonth(), d: d.getDate(), H: d.getHours(), M: d.getMinutes(), S: d.getSeconds(), w: d.getDay() };
      var start = utc ? Date.UTC(g.Y, 0, 1) : new Date(g.Y, 0, 1).getTime();
      var cur = utc ? Date.UTC(g.Y, g.m, g.d) : new Date(g.Y, g.m, g.d).getTime();
      var yday = Math.round((cur - start) / 86400000) + 1;
      if (fmt.slice(0, 2) === '*t') {
        var r = new LuaTable();
        r.set('year', g.Y); r.set('month', g.m + 1); r.set('day', g.d);
        r.set('hour', g.H); r.set('min', g.M); r.set('sec', g.S);
        r.set('wday', g.w + 1); r.set('yday', yday); r.set('isdst', false);
        return r;
      }
      var DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      var MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      function p2(n) { return (n < 10 ? '0' : '') + n; }
      return fmt.replace(/%(.)/g, function (_, c) {
        switch (c) {
          case 'Y': return String(g.Y);
          case 'y': return p2(g.Y % 100);
          case 'm': return p2(g.m + 1);
          case 'd': return p2(g.d);
          case 'e': return (g.d < 10 ? ' ' : '') + g.d;
          case 'H': return p2(g.H);
          case 'I': return p2(((g.H + 11) % 12) + 1);
          case 'M': return p2(g.M);
          case 'S': return p2(g.S);
          case 'p': return g.H < 12 ? 'AM' : 'PM';
          case 'A': return DAYS[g.w];
          case 'a': return DAYS[g.w].slice(0, 3);
          case 'B': return MONTHS[g.m];
          case 'b': return MONTHS[g.m].slice(0, 3);
          case 'j': return String(yday).padStart(3, '0');
          case 'w': return String(g.w);
          case 'u': return String(g.w === 0 ? 7 : g.w);
          case 'x': return p2(g.m + 1) + '/' + p2(g.d) + '/' + p2(g.Y % 100);
          case 'X': return p2(g.H) + ':' + p2(g.M) + ':' + p2(g.S);
          case 'c': return DAYS[g.w].slice(0, 3) + ' ' + MONTHS[g.m].slice(0, 3) + ' ' + (g.d < 10 ? ' ' : '') + g.d + ' ' + p2(g.H) + ':' + p2(g.M) + ':' + p2(g.S) + ' ' + g.Y;
          case '%': return '%';
          default: return '%' + c;
        }
      });
    });
    O.set('getenv', function () { return undefined; });
    O.set('remove', function (path) {
      if (host.removeFile && host.removeFile(path)) return true;
      return new Multi([undefined, path + ': No such file or directory', 2]);
    });
    O.set('rename', function (a, b) {
      if (host.renameFile && host.renameFile(a, b)) return true;
      return new Multi([undefined, a + ': No such file or directory', 2]);
    });
    O.set('exit', function () { throw new LuaError('os.exit called'); });
    O.set('tmpname', function () { return '/tmp/lua_' + Math.random().toString(36).slice(2); });
    return O;
  }

  // ------------------------------------------------------------ io ------
  // Files live wherever the host keeps them (host.readFile / host.writeFile):
  // Battle Pass keeps its save file this way.
  function makeIoLib(host) {
    var IO = new LuaTable();
    var fileMeta = new LuaTable();
    var fileMethods = new LuaTable();
    fileMeta.set('__index', fileMethods);
    fileMeta.set('__name', 'FILE*');
    function newFile(path, mode, data) {
      var f = new LuaTable();
      f.mt = fileMeta;
      f._path = path; f._mode = mode; f._data = data; f._pos = 0; f._closed = false;
      return f;
    }
    IO.set('open', function (path, mode) {
      path = checkStr(path, 1, 'open');
      mode = mode === undefined ? 'r' : checkStr(mode, 2, 'open');
      var m = mode.replace('b', '');
      if (m[0] === 'r') {
        var data = host.readFile ? host.readFile(path) : null;
        if (data === null || data === undefined) return new Multi([undefined, path + ': No such file or directory', 2]);
        return newFile(path, m, data);
      }
      if (m[0] === 'w') return newFile(path, m, '');
      if (m[0] === 'a') {
        var old = host.readFile ? host.readFile(path) : null;
        var f = newFile(path, m, old || '');
        f._pos = f._data.length;
        return f;
      }
      throw argError(2, 'open', 'invalid mode');
    });
    fileMethods.set('read', function (f) {
      var fmts = Array.prototype.slice.call(arguments, 1);
      if (!fmts.length) fmts = ['l'];
      var out = [];
      for (var i = 0; i < fmts.length; i++) {
        var fm = fmts[i];
        if (isNum(fm)) {
          var n = num(fm);
          if (f._pos >= f._data.length && n > 0) { out.push(undefined); break; }
          out.push(f._data.substr(f._pos, n)); f._pos += n; continue;
        }
        fm = String(fm).replace(/^\*/, '');
        if (fm[0] === 'a') { out.push(f._data.slice(f._pos)); f._pos = f._data.length; continue; }
        if (fm[0] === 'l' || fm[0] === 'L') {
          if (f._pos >= f._data.length) { out.push(undefined); break; }
          var e = f._data.indexOf('\n', f._pos);
          var line = e < 0 ? f._data.slice(f._pos) : f._data.slice(f._pos, fm[0] === 'L' ? e + 1 : e);
          f._pos = e < 0 ? f._data.length : e + 1;
          out.push(line); continue;
        }
        if (fm[0] === 'n') {
          var m = /^\s*[-+]?(0[xX][0-9a-fA-F.]+|\d*\.?\d+(?:[eE][-+]?\d+)?)/.exec(f._data.slice(f._pos));
          if (!m) { out.push(undefined); break; }
          f._pos += m[0].length; out.push(str2num(m[0])); continue;
        }
      }
      return ret(out);
    });
    fileMethods.set('write', function (f) {
      for (var i = 1; i < arguments.length; i++) {
        var v = arguments[i];
        var s = typeof v === 'string' ? v : writeNum(v);
        f._data = f._data.slice(0, f._pos) + s + f._data.slice(f._pos + s.length);
        f._pos += s.length;
      }
      return f;
    });
    fileMethods.set('lines', function (f) {
      return function () { return first(fileMethods.get('read')(f, 'l')); };
    });
    fileMethods.set('seek', function (f, whence, off) {
      whence = whence || 'cur'; off = off === undefined ? 0 : num(off);
      if (whence === 'set') f._pos = off;
      else if (whence === 'end') f._pos = f._data.length + off;
      else f._pos += off;
      return f._pos;
    });
    fileMethods.set('flush', function (f) {
      if (f._mode[0] !== 'r' && host.writeFile) host.writeFile(f._path, f._data);
      return f;
    });
    fileMethods.set('close', function (f) {
      if (!f._closed && f._mode[0] !== 'r' && host.writeFile) host.writeFile(f._path, f._data);
      f._closed = true;
      return true;
    });
    fileMethods.set('setvbuf', function () { return true; });
    IO.set('write', function () {
      var s = '';
      for (var i = 0; i < arguments.length; i++) s += typeof arguments[i] === 'string' ? arguments[i] : writeNum(arguments[i]);
      (host.write || host.print || function (x) { if (typeof process !== 'undefined') process.stdout.write(x); })(s);
      return NONE;
    });
    IO.set('lines', function (path) {
      var data = host.readFile ? host.readFile(path) : null;
      if (data === null || data === undefined) throw rterror(path + ': No such file or directory');
      var f = newFile(path, 'r', data);
      return function () { return first(fileMethods.get('read')(f, 'l')); };
    });
    return IO;
  }

  // ---------------------------------------------------------- utf8 ------
  function makeUtf8Lib() {
    var U = new LuaTable();
    U.set('char', function () {
      var s = '';
      for (var i = 0; i < arguments.length; i++) s += NS.utf8Bytes(checkInt(arguments[i], i + 1, 'char'));
      return s;
    });
    U.set('charpattern', '[\x00-\x7F\xC2-\xFD][\x80-\xBF]*');
    function decodeAt(s, i) {   // i 0-based; returns [codepoint, length] or null
      var c = s.charCodeAt(i);
      if (c < 0x80) return [c, 1];
      var n = c >= 0xF0 ? 4 : c >= 0xE0 ? 3 : c >= 0xC0 ? 2 : 0;
      if (!n) return null;
      var cp = c & (0x7F >> n);
      for (var k = 1; k < n; k++) {
        var cc = s.charCodeAt(i + k);
        if ((cc & 0xC0) !== 0x80) return null;
        cp = (cp << 6) | (cc & 0x3F);
      }
      return [cp, n];
    }
    U.set('len', function (s, i, j) {
      s = checkStr(s, 1, 'len');
      var a = (i === undefined ? 1 : num(i)) - 1, b = j === undefined ? s.length : num(j);
      var n = 0;
      while (a < b) {
        var d = decodeAt(s, a);
        if (!d) return new Multi([undefined, a + 1]);
        a += d[1]; n++;
      }
      return n;
    });
    U.set('codepoint', function (s, i, j) {
      s = checkStr(s, 1, 'codepoint');
      var a = (i === undefined ? 1 : num(i)), b = j === undefined ? a : num(j);
      var out = [], p = a - 1;
      while (p < b) {
        var d = decodeAt(s, p);
        if (!d) throw rterror('invalid UTF-8 code');
        out.push(d[0]); p += d[1];
      }
      return ret(out);
    });
    U.set('offset', function (s, n, i) {
      s = checkStr(s, 1, 'offset');
      n = num(n);
      var p = i === undefined ? (n >= 0 ? 1 : s.length + 1) : num(i);
      p -= 1;
      function cont(k) { return (s.charCodeAt(k) & 0xC0) === 0x80; }
      if (n === 0) { while (p > 0 && cont(p)) p--; return p + 1; }
      if (n > 0) { n--; while (n > 0 && p < s.length) { p++; while (cont(p)) p++; n--; } return n === 0 ? p + 1 : undefined; }
      while (n < 0 && p > 0) { p--; while (p > 0 && cont(p)) p--; n++; }
      return n === 0 ? p + 1 : undefined;
    });
    U.set('codes', function (s) {
      s = checkStr(s, 1, 'codes');
      return new Multi([function (str, i) {
        var p = num(i);
        if (p > 0) { var d0 = decodeAt(str, p - 1); p += d0 ? d0[1] - 1 : 0; }
        if (p >= str.length) return undefined;
        var d = decodeAt(str, p);
        if (!d) throw rterror('invalid UTF-8 code');
        return new Multi([p + 1, d[0]]);
      }, s, 0]);
    });
    return U;
  }

  // ======================================================== strings =======
  var stringLib = new LuaTable();
  var stringMeta = new LuaTable();
  stringMeta.set('__index', stringLib);

  function posrelatI(pos, l) {
    if (pos > 0) return pos;
    if (pos === 0) return 1;
    if (pos < -l) return 1;
    return l + pos + 1;
  }
  function getendpos(pos, l) {
    if (pos > l) return l;
    if (pos >= 0) return pos;
    if (pos < -l) return 0;
    return l + pos + 1;
  }
  stringLib.set('len', function (s) { return checkStr(s, 1, 'len').length; });
  stringLib.set('sub', function (s, i, j) {
    s = checkStr(s, 1, 'sub');
    var l = s.length;
    var st = posrelatI(checkInt(i === undefined ? 1 : i, 2, 'sub'), l);
    var en = getendpos(j === undefined ? -1 : checkInt(j, 3, 'sub'), l);
    if (st < 1) st = 1;
    if (en > l) en = l;
    return st <= en ? s.slice(st - 1, en) : '';
  });
  stringLib.set('upper', function (s) {
    s = checkStr(s, 1, 'upper');
    return s.replace(/[a-z]+/g, function (m) { return m.toUpperCase(); });
  });
  stringLib.set('lower', function (s) {
    s = checkStr(s, 1, 'lower');
    return s.replace(/[A-Z]+/g, function (m) { return m.toLowerCase(); });
  });
  stringLib.set('rep', function (s, n, sep) {
    s = checkStr(s, 1, 'rep'); n = checkInt(n, 2, 'rep');
    if (n <= 0) return '';
    if (sep === undefined || sep === '') return s.repeat(n);
    sep = checkStr(sep, 3, 'rep');
    return Array(n).fill(s).join(sep);
  });
  stringLib.set('reverse', function (s) { return checkStr(s, 1, 'reverse').split('').reverse().join(''); });
  stringLib.set('byte', function (s, i, j) {
    s = checkStr(s, 1, 'byte');
    var l = s.length;
    var pi = posrelatI(optInt(i, 2, 'byte', 1), l);
    var pe = getendpos(j === undefined ? pi : checkInt(j, 3, 'byte'), l);
    if (pi > pe) return undefined;
    var out = [];
    for (var k = pi; k <= pe; k++) out.push(s.charCodeAt(k - 1));
    return ret(out);
  });
  stringLib.set('char', function () {
    var out = '';
    for (var i = 0; i < arguments.length; i++) {
      var c = checkInt(arguments[i], i + 1, 'char');
      if (c < 0 || c > 255) throw argError(i + 1, 'char', 'value out of range');
      out += String.fromCharCode(c);
    }
    return out;
  });

  // string.format, with C's own rounding.
  stringLib.set('format', function (fmt) {
    fmt = checkStr(fmt, 1, 'format');
    var args = arguments, argi = 1;
    var out = '', i = 0, n = fmt.length;
    while (i < n) {
      var c = fmt[i++];
      if (c !== '%') { out += c; continue; }
      if (fmt[i] === '%') { out += '%'; i++; continue; }
      var m = /^([-+ #0]*)(\d*)(?:\.(\d*))?([a-zA-Z])/.exec(fmt.slice(i));
      if (!m) throw rterror("invalid conversion '%" + fmt.slice(i, i + 5) + "' to 'format'");
      i += m[0].length;
      var flags = m[1], width = m[2] ? Number(m[2]) : 0, prec = m[3] === undefined ? undefined : Number(m[3] || 0);
      var conv = m[4];
      var argn = ++argi;
      if (argn > args.length - 1 + 1 && conv !== '%') {
        if (args[argn - 1] === undefined && argn > args.length) throw argError(argn, 'format', 'no value');
      }
      var v = args[argn - 1], body, sign = '';
      switch (conv) {
        case 'd': case 'i': {
          var iv = checkInt(v, argn, 'format');
          body = String(Math.abs(iv) < 1e21 ? Math.abs(iv) : BigInt(iv) * (iv < 0 ? -1n : 1n));
          if (prec !== undefined) { body = body.padStart(prec, '0'); if (prec === 0 && iv === 0) body = ''; }
          sign = iv < 0 ? '-' : (flags.indexOf('+') >= 0 ? '+' : (flags.indexOf(' ') >= 0 ? ' ' : ''));
          out += pad(sign, body, width, flags, prec === undefined);
          break;
        }
        case 'u': {
          var uv = checkInt(v, argn, 'format');
          body = BigInt.asUintN(64, BigInt(uv)).toString();
          out += pad('', body, width, flags, true);
          break;
        }
        case 'c': out += pad('', String.fromCharCode(checkInt(v, argn, 'format')), width, flags.replace('0', ''), false); break;
        case 'x': case 'X': case 'o': {
          var xv = BigInt.asUintN(64, BigInt(checkInt(v, argn, 'format')));
          body = xv.toString(conv === 'o' ? 8 : 16);
          if (conv === 'X') body = body.toUpperCase();
          if (prec !== undefined) body = body.padStart(prec, '0');
          var pre = (flags.indexOf('#') >= 0 && xv !== 0n) ? (conv === 'o' ? '0' : (conv === 'x' ? '0x' : '0X')) : '';
          out += pad(pre, body, width, flags, prec === undefined);
          break;
        }
        case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A': {
          var fv = checkNum(v, argn, 'format');
          var neg = fv < 0 || (fv === 0 && 1 / fv < 0);
          var ax = Math.abs(fv);
          var up = conv === 'E' || conv === 'G' || conv === 'F' || conv === 'A';
          if (ax === Infinity || fv !== fv) {
            body = fv !== fv ? 'nan' : 'inf';
            if (up) body = body.toUpperCase();
            sign = neg && fv === fv ? '-' : (flags.indexOf('+') >= 0 ? '+' : (flags.indexOf(' ') >= 0 ? ' ' : ''));
            out += pad(sign, body, width, flags.replace('0', ''), false);
            break;
          }
          var p = prec === undefined ? 6 : prec;
          var alt = flags.indexOf('#') >= 0;
          if (conv === 'f' || conv === 'F') { body = fixedDigits(ax, p); if (alt && p === 0) body += '.'; }
          else if (conv === 'e' || conv === 'E') body = fmtExp(ax, p, up);
          else if (conv === 'g' || conv === 'G') body = fmtG(ax, p, up, alt);
          else body = hexFloat(ax, prec, up);
          sign = neg ? '-' : (flags.indexOf('+') >= 0 ? '+' : (flags.indexOf(' ') >= 0 ? ' ' : ''));
          out += pad(sign, body, width, flags, true);
          break;
        }
        case 's': {
          var sv = tostring(v);
          if (args.length < argn) throw argError(argn, 'format', 'no value');
          if (prec !== undefined) sv = sv.slice(0, prec);
          out += pad('', sv, width, flags.replace('0', ''), false);
          break;
        }
        case 'q': out += quoteString(v); break;
        default:
          throw rterror("invalid conversion '%" + m[0] + "' to 'format'");
      }
    }
    return out;
  });
  function pad(sign, body, width, flags, zeroOk) {
    var total = sign.length + body.length;
    if (total >= width) return sign + body;
    if (flags.indexOf('-') >= 0) return sign + body + ' '.repeat(width - total);
    if (zeroOk && flags.indexOf('0') >= 0) return sign + '0'.repeat(width - total) + body;
    return ' '.repeat(width - total) + sign + body;
  }
  function hexFloat(x, prec, up) {
    if (x === 0) return up ? '0X0P+0' : '0x0p+0';
    var e = Math.floor(Math.log2(x)), m = x / Math.pow(2, e);
    if (m >= 2) { m /= 2; e++; } else if (m < 1) { m *= 2; e--; }
    var frac = (m - 1).toString(16).slice(2);
    if (prec !== undefined) frac = frac.slice(0, prec).padEnd(prec, '0');
    var s = '0x1' + (frac ? '.' + frac : '') + 'p' + (e >= 0 ? '+' : '') + e;
    return up ? s.toUpperCase() : s;
  }
  function quoteString(v) {
    if (typeof v === 'string') {
      var o = '"';
      for (var i = 0; i < v.length; i++) {
        var c = v.charCodeAt(i), ch = v[i];
        if (ch === '"' || ch === '\\') o += '\\' + ch;
        else if (ch === '\n') o += '\\\n';
        else if (ch === '\r') o += '\\r';
        else if (c === 0) o += (i + 1 < v.length && /\d/.test(v[i + 1])) ? '\\000' : '\\0';
        else if (c < 32 || c === 127) o += '\\' + ((i + 1 < v.length && /\d/.test(v[i + 1])) ? String(c).padStart(3, '0') : c);
        else o += ch;
      }
      return o + '"';
    }
    if (typeof v === 'number' && Number.isInteger(v)) return intStr(v);
    if (isNum(v)) {
      var x = num(v);
      if (x === Infinity) return '1e9999';
      if (x === -Infinity) return '-1e9999';
      if (x !== x) return '(0/0)';
      if (x === Math.floor(x)) return (x < 0 ? '-' : '') + hexFloat(Math.abs(x)) ;
      return (x < 0 ? '-' : '') + hexFloat(Math.abs(x));
    }
    if (v === undefined || typeof v === 'boolean') return tostring(v);
    throw rterror("bad argument to 'format' (value has no literal form)");
  }

  // ----------------------------------------------------- patterns ------
  // lstrlib.c's matcher, ported line for line.
  var L_ESC = 37, CAP_UNFINISHED = -1, CAP_POSITION = -2, MAXCCALLS = 200, MAXCAPTURES = 32;
  function MatchState(src, pat) {
    this.src = src; this.pat = pat; this.level = 0; this.matchdepth = MAXCCALLS;
    this.capInit = new Array(MAXCAPTURES); this.capLen = new Array(MAXCAPTURES);
  }
  function classEnd(ms, p) {
    var pat = ms.pat, pe = pat.length;
    var c = pat.charCodeAt(p++);
    if (c === L_ESC) {
      if (p >= pe) throw rterror("malformed pattern (ends with '%')");
      return p + 1;
    }
    if (c === 91) {   // '['
      if (pat.charCodeAt(p) === 94) p++;
      do {
        if (p >= pe) throw rterror("malformed pattern (missing ']')");
        if (pat.charCodeAt(p++) === L_ESC && p < pe) p++;
      } while (pat.charCodeAt(p) !== 93);
      return p + 1;
    }
    return p;
  }
  function isalpha(c) { return (c >= 65 && c <= 90) || (c >= 97 && c <= 122); }
  function isdigit(c) { return c >= 48 && c <= 57; }
  function islower(c) { return c >= 97 && c <= 122; }
  function isupper(c) { return c >= 65 && c <= 90; }
  function isspace(c) { return c === 32 || (c >= 9 && c <= 13); }
  function iscntrl(c) { return c < 32 || c === 127; }
  function ispunct(c) { return c >= 33 && c <= 126 && !isalpha(c) && !isdigit(c); }
  function isxdigit(c) { return isdigit(c) || (c >= 97 && c <= 102) || (c >= 65 && c <= 70); }
  function matchClass(c, cl) {
    var res;
    var low = cl >= 65 && cl <= 90 ? cl + 32 : cl;
    switch (low) {
      case 97: res = isalpha(c); break;            // a
      case 99: res = iscntrl(c); break;            // c
      case 100: res = isdigit(c); break;           // d
      case 103: res = c >= 33 && c <= 126; break;  // g
      case 108: res = islower(c); break;           // l
      case 112: res = ispunct(c); break;           // p
      case 115: res = isspace(c); break;           // s
      case 117: res = isupper(c); break;           // u
      case 119: res = isalpha(c) || isdigit(c); break; // w
      case 120: res = isxdigit(c); break;          // x
      default: return cl === c;
    }
    if (isupper(cl)) res = !res;
    return res;
  }
  function matchBracketClass(ms, c, p, ec) {
    var pat = ms.pat, sig = true;
    if (pat.charCodeAt(p + 1) === 94) { sig = false; p++; }
    while (++p < ec) {
      var pc = pat.charCodeAt(p);
      if (pc === L_ESC) {
        p++;
        if (matchClass(c, pat.charCodeAt(p))) return sig;
      } else if (pat.charCodeAt(p + 1) === 45 && p + 2 < ec) {
        p += 2;
        if (pat.charCodeAt(p - 2) <= c && c <= pat.charCodeAt(p)) return sig;
      } else if (pc === c) return sig;
    }
    return !sig;
  }
  function singleMatch(ms, s, p, ep) {
    if (s >= ms.src.length) return false;
    var c = ms.src.charCodeAt(s);
    var pc = ms.pat.charCodeAt(p);
    switch (pc) {
      case 46: return true;                                  // '.'
      case L_ESC: return matchClass(c, ms.pat.charCodeAt(p + 1));
      case 91: return matchBracketClass(ms, c, p, ep - 1);
      default: return pc === c;
    }
  }
  function matchBalance(ms, s, p) {
    if (p >= ms.pat.length - 1) throw rterror("malformed pattern (missing arguments to '%b')");
    var src = ms.src;
    if (src.charCodeAt(s) !== ms.pat.charCodeAt(p)) return -1;
    var b = ms.pat.charCodeAt(p), e = ms.pat.charCodeAt(p + 1), cont = 1;
    while (++s < src.length) {
      var c = src.charCodeAt(s);
      if (c === e) { if (--cont === 0) return s + 1; }
      else if (c === b) cont++;
    }
    return -1;
  }
  function maxExpand(ms, s, p, ep) {
    var i = 0;
    while (singleMatch(ms, s + i, p, ep)) i++;
    while (i >= 0) {
      var res = doMatch(ms, s + i, ep + 1);
      if (res !== -1) return res;
      i--;
    }
    return -1;
  }
  function minExpand(ms, s, p, ep) {
    for (;;) {
      var res = doMatch(ms, s, ep + 1);
      if (res !== -1) return res;
      else if (singleMatch(ms, s, p, ep)) s++;
      else return -1;
    }
  }
  function startCapture(ms, s, p, what) {
    var level = ms.level;
    if (level >= MAXCAPTURES) throw rterror('too many captures');
    ms.capInit[level] = s; ms.capLen[level] = what;
    ms.level = level + 1;
    var res = doMatch(ms, s, p);
    if (res === -1) ms.level--;
    return res;
  }
  function captureToClose(ms) {
    var level = ms.level;
    for (level--; level >= 0; level--) if (ms.capLen[level] === CAP_UNFINISHED) return level;
    throw rterror('invalid pattern capture');
  }
  function endCapture(ms, s, p) {
    var l = captureToClose(ms);
    ms.capLen[l] = s - ms.capInit[l];
    var res = doMatch(ms, s, p);
    if (res === -1) ms.capLen[l] = CAP_UNFINISHED;
    return res;
  }
  function checkCapture(ms, l) {
    l -= 49;
    if (l < 0 || l >= ms.level || ms.capLen[l] === CAP_UNFINISHED) throw rterror('invalid capture index %' + (l + 1));
    return l;
  }
  function matchCapture(ms, s, l) {
    l = checkCapture(ms, l);
    var len = ms.capLen[l];
    var cap = ms.src.substr(ms.capInit[l], len);
    if (ms.src.length - s >= len && ms.src.substr(s, len) === cap) return s + len;
    return -1;
  }
  function doMatch(ms, s, p) {
    if (ms.matchdepth-- === 0) throw rterror('pattern too complex');
    var pat = ms.pat, pe = pat.length;
    for (;;) {
      if (p === pe) break;
      var pc = pat.charCodeAt(p);
      if (pc === 40) {                                     // '('
        if (pat.charCodeAt(p + 1) === 41) s = startCapture(ms, s, p + 2, CAP_POSITION);
        else s = startCapture(ms, s, p + 1, CAP_UNFINISHED);
        break;
      }
      if (pc === 41) { s = endCapture(ms, s, p + 1); break; }   // ')'
      if (pc === 36 && p + 1 === pe) {                     // '$' at the end
        s = (s === ms.src.length) ? s : -1;
        break;
      }
      if (pc === L_ESC) {
        var nx = pat.charCodeAt(p + 1);
        if (nx === 98) {                                   // %b
          s = matchBalance(ms, s, p + 2);
          if (s !== -1) { p += 4; continue; }
          break;
        }
        if (nx === 102) {                                  // %f
          p += 2;
          if (pat.charCodeAt(p) !== 91) throw rterror("missing '[' after '%f' in pattern");
          var ep0 = classEnd(ms, p);
          var prev = (s === 0) ? 0 : ms.src.charCodeAt(s - 1);
          var cur = s < ms.src.length ? ms.src.charCodeAt(s) : 0;
          if (!matchBracketClass(ms, prev, p, ep0 - 1) && matchBracketClass(ms, cur, p, ep0 - 1)) { p = ep0; continue; }
          s = -1; break;
        }
        if (nx >= 48 && nx <= 57) {                        // %0-%9
          s = matchCapture(ms, s, nx);
          if (s !== -1) { p += 2; continue; }
          break;
        }
      }
      // default: a single class with an optional suffix
      var ep = classEnd(ms, p);
      var epc = pat.charCodeAt(ep);
      if (!singleMatch(ms, s, p, ep)) {
        if (epc === 42 || epc === 63 || epc === 45) { p = ep + 1; continue; }   // * ? -
        s = -1; break;
      }
      if (epc === 63) {                                    // ?
        var res = doMatch(ms, s + 1, ep + 1);
        if (res !== -1) { s = res; break; }
        p = ep + 1; continue;
      }
      if (epc === 43) { s = maxExpand(ms, s + 1, p, ep); break; }   // +
      if (epc === 42) { s = maxExpand(ms, s, p, ep); break; }       // *
      if (epc === 45) { s = minExpand(ms, s, p, ep); break; }       // -
      s++; p = ep;
    }
    ms.matchdepth++;
    return s;
  }
  function getCapture(ms, i, s, e) {
    if (i >= ms.level) {
      if (i !== 0) throw rterror('invalid capture index %' + (i + 1));
      return ms.src.slice(s, e);
    }
    var l = ms.capLen[i];
    if (l === CAP_UNFINISHED) throw rterror('unfinished capture');
    if (l === CAP_POSITION) return ms.capInit[i] + 1;
    return ms.src.substr(ms.capInit[i], l);
  }
  function captures(ms, s, e, wholeIfNone) {
    var n = (ms.level === 0 && wholeIfNone) ? 1 : ms.level;
    var out = [];
    for (var i = 0; i < n; i++) out.push(getCapture(ms, i, s, e));
    return out;
  }
  var SPECIALS = /[\^$*+?.()[\]%-]/;
  function strFindAux(find, s, p, init, plain, fname) {
    s = checkStr(s, 1, fname); p = checkStr(p, 2, fname);
    var ls = s.length;
    var st = posrelatI(optInt(init, 3, fname, 1), ls) - 1;
    if (st > ls) return undefined;
    if (find && (truthy(plain) || !SPECIALS.test(p))) {
      var idx = s.indexOf(p, st);
      if (idx >= 0) return new Multi([idx + 1, idx + p.length]);
      return undefined;
    }
    var anchor = p.charCodeAt(0) === 94;
    var pp = anchor ? p.slice(1) : p;
    var ms = new MatchState(s, pp);
    var s1 = st;
    do {
      ms.level = 0; ms.matchdepth = MAXCCALLS;
      var res = doMatch(ms, s1, 0);
      if (res !== -1) {
        if (find) return new Multi([s1 + 1, res].concat(captures(ms, -1, 0, false)));
        return ret(captures(ms, s1, res, true));
      }
    } while (s1++ < ls && !anchor);
    return undefined;
  }
  stringLib.set('find', function (s, p, init, plain) { return strFindAux(true, s, p, init, plain, 'find'); });
  stringLib.set('match', function (s, p, init) { return strFindAux(false, s, p, init, false, 'match'); });
  stringLib.set('gmatch', function (s, p, init) {
    s = checkStr(s, 1, 'gmatch'); p = checkStr(p, 2, 'gmatch');
    var ls = s.length;
    var src = posrelatI(optInt(init, 3, 'gmatch', 1), ls) - 1;
    if (src > ls) src = ls + 1;
    var ms = new MatchState(s, p), lastmatch = -1;
    return function () {
      for (; src <= ls; src++) {
        ms.level = 0; ms.matchdepth = MAXCCALLS;
        var e = doMatch(ms, src, 0);
        if (e !== -1 && e !== lastmatch) {
          var start = src;
          src = lastmatch = e;
          return ret(captures(ms, start, e, true));
        }
      }
      return undefined;
    };
  });
  stringLib.set('gsub', function (s, p, repl, maxn) {
    s = checkStr(s, 1, 'gsub'); p = checkStr(p, 2, 'gsub');
    var tr = typeName(repl);
    if (!(tr === 'number' || tr === 'string' || tr === 'table' || tr === 'function')) {
      throw argError(3, 'gsub', 'string/function/table expected, got ' + typeNameArg(repl));
    }
    var maxS = maxn === undefined ? s.length + 1 : checkInt(maxn, 4, 'gsub');
    var anchor = p.charCodeAt(0) === 94;
    var pp = anchor ? p.slice(1) : p;
    var ms = new MatchState(s, pp);
    var src = 0, lastmatch = -1, n = 0, out = '';
    var rs = tr === 'string' || tr === 'number' ? (typeof repl === 'string' ? repl : numStr(repl)) : null;
    while (n < maxS) {
      ms.level = 0; ms.matchdepth = MAXCCALLS;
      var e = doMatch(ms, src, 0);
      if (e !== -1 && e !== lastmatch) {
        n++;
        out += addValue(ms, src, e, repl, rs, tr);
        src = lastmatch = e;
      } else if (src < s.length) out += s[src++];
      else break;
      if (anchor) break;
    }
    if (src < s.length) out += s.slice(src);
    return new Multi([out, n]);
  });
  function addValue(ms, s, e, repl, rs, tr) {
    var whole = ms.src.slice(s, e), v;
    if (rs !== null) {
      var o = '';
      for (var i = 0; i < rs.length; i++) {
        var c = rs[i];
        if (c !== '%') { o += c; continue; }
        i++;
        var d = rs[i];
        if (d === '%') o += '%';
        else if (d !== undefined && d >= '0' && d <= '9') {
          var cap = d === '0' ? whole : getCapture(ms, d.charCodeAt(0) - 49, s, e);
          o += typeof cap === 'string' ? cap : numStr(cap);
        } else throw rterror("invalid use of '%' in replacement string");
      }
      return o;
    }
    var caps = captures(ms, s, e, true);
    if (tr === 'table') v = index(repl, caps[0]);
    else v = first(call(repl).apply(null, caps));
    if (v === undefined || v === false) return whole;
    if (typeof v === 'string') return v;
    if (isNum(v)) return numStr(v);
    throw rterror('invalid replacement value (a ' + typeName(v) + ')');
  }

  // ===================================================== conversion =======
  // Between JS values (UTF-16 strings, arrays, objects) and Lua values.
  var encoder = typeof TextEncoder !== 'undefined' ? new TextEncoder() : null;
  var decoder = typeof TextDecoder !== 'undefined' ? new TextDecoder('utf-8') : null;
  function toBytes(str) {        // JS string -> Lua byte string
    if (/^[\x00-\x7f]*$/.test(str)) return str;
    var b = encoder.encode(str), s = '';
    for (var i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
    return s;
  }
  function fromBytes(s) {        // Lua byte string -> JS string
    if (/^[\x00-\x7f]*$/.test(s)) return s;
    var b = new Uint8Array(s.length);
    for (var i = 0; i < s.length; i++) b[i] = s.charCodeAt(i);
    return decoder.decode(b);
  }
  function toLua(v) {
    if (v === null || v === undefined) return undefined;
    if (typeof v === 'string') return toBytes(v);
    if (typeof v === 'number' || typeof v === 'boolean' || typeof v === 'function') return v;
    if (v instanceof LuaTable || v instanceof LFloat) return v;
    var t = new LuaTable();
    if (Array.isArray(v)) { for (var i = 0; i < v.length; i++) t.set(i + 1, toLua(v[i])); return t; }
    Object.keys(v).forEach(function (k) { t.set(toBytes(k), toLua(v[k])); });
    return t;
  }
  function toJS(v, seen) {
    if (v instanceof LFloat) return v.n;
    if (typeof v === 'string') return fromBytes(v);
    if (!(v instanceof LuaTable)) return v;
    seen = seen || new Map();
    if (seen.has(v)) return seen.get(v);
    var n = v.arr.length, hashSize = v.hash ? v.hash.size : 0;
    if (hashSize === 0) {
      var a = [];
      seen.set(v, a);
      for (var i = 0; i < n; i++) a.push(toJS(v.arr[i], seen));
      return a;
    }
    var o = {};
    seen.set(v, o);
    for (var j = 0; j < n; j++) if (v.arr[j] !== undefined) o[j + 1] = toJS(v.arr[j], seen);
    v.hash.forEach(function (val, key) {
      var k = typeof key === 'string' ? fromBytes(key) : (isNum(key) ? numStr(key) : tostring(key));
      o[k] = toJS(val, seen);
    });
    return o;
  }

  NS.LFloat = LFloat; NS.mkf = mkf; NS.Multi = Multi; NS.first = first; NS.sp = sp; NS.ret = ret;
  NS.LuaTable = LuaTable; NS.NONE = NONE; NS.LuaError = LuaError; NS.lineMaps = lineMaps;
  NS.add = add; NS.sub = sub; NS.mul = mul; NS.div = div; NS.idiv = idiv; NS.mod = mod; NS.pow = pow;
  NS.unm = unm; NS.band = band; NS.bor = bor; NS.bxor = bxor; NS.shl = shl; NS.shr = shr; NS.bnot = bnot;
  NS.concat = concat; NS.len = len; NS.eq = eq; NS.lt = lt; NS.le = le; NS.gt = gt; NS.ge = ge;
  NS.T = truthy; NS.index = index; NS.setindex = setindex; NS.call = call; NS.method = method;
  NS.tbl = tbl; NS.iter = iter; NS.forprep = forprep; NS.tostring = tostring; NS.typeName = typeName;
  NS.makeEnv = makeEnv; NS.toLua = toLua; NS.toJS = toJS; NS.toBytes = toBytes; NS.fromBytes = fromBytes;
  NS.numStr = numStr; NS.str2num = str2num; NS.errorValue = errorValue; NS.rterror = rterror;
})(typeof module === 'object' && module.exports
  ? (module.exports = (globalThis.MiddawLua = globalThis.MiddawLua || {}))
  : (globalThis.MiddawLua = globalThis.MiddawLua || {}));


/* ---- ../kit/runtime/lua_compile.js ---- */
/* Middaw's Lua 5.4, part 2 of 3: syntax tree in, JavaScript out.
 *
 * Every Lua local becomes a JS `let` with a name of its own ($x, $x$2...), so
 * shadowing and closures behave as in Lua: a fresh binding per declaration,
 * and per loop iteration. Every operator goes through the runtime, so the
 * integer/float distinction and the error messages are Lua's. Each statement
 * starts a new line carrying a marker with its Lua line number, which is how
 * an error raised in the generated code is reported at the Lua line.
 */
(function (NS) {
  'use strict';

  var ARITH = { '+': 'add', '-': 'sub', '*': 'mul', '/': 'div', '%': 'mod', '^': 'pow', '//': 'idiv',
                '&': 'band', '|': 'bor', '~': 'bxor', '<<': 'shl', '>>': 'shr', '..': 'concat' };
  var COMPARE = { '==': 'eq', '<': 'lt', '<=': 'le', '>': 'gt', '>=': 'ge' };

  function compile(ast, chunk) {
    var consts = [];
    var nameCounts = Object.create(null);

    function uniqueName(luaName) {
      var n = (nameCounts[luaName] || 0) + 1;
      nameCounts[luaName] = n;
      return n === 1 ? '$' + luaName : '$' + luaName + '$' + n;
    }

    function FuncState(parent, vararg) {
      this.parent = parent; this.vararg = vararg; this.temps = 0; this.scopes = [];
    }
    var fs = null;
    var stmtUid = 0;

    function newTemp() { fs.temps++; return '$$' + fs.temps; }
    function lookup(name) {
      for (var f = fs; f; f = f.parent) {
        for (var i = f.scopes.length - 1; i >= 0; i--) {
          var js = f.scopes[i][name];
          if (js !== undefined) return js;
        }
      }
      return null;
    }
    function declare(name) {
      var js = uniqueName(name);
      fs.scopes[fs.scopes.length - 1][name] = js;
      return js;
    }
    function openScope() { fs.scopes.push(Object.create(null)); }
    function closeScope() { fs.scopes.pop(); }

    function err(msg, line) {
      throw new NS.LuaSyntaxError(msg, chunk, line || 0);
    }

    function str(s) { return JSON.stringify(s); }

    function numberLiteral(text) {
      var v;
      if (/^0[xX]/.test(text)) {
        if (/[.pP]/.test(text)) v = NS.str2num(text);
        else {
          var big = BigInt.asIntN(64, BigInt('0x' + text.slice(2)));
          return String(Number(big));
        }
      } else if (/[.eE]/.test(text)) {
        v = NS.mkf(Number(text));
      } else {
        var n = Number(text);
        if (Math.abs(n) > 9223372036854775807) v = NS.mkf(n);
        else return String(n);
      }
      if (v instanceof NS.LFloat) {
        var idx = consts.length;
        consts.push(v);
        return '$$K[' + idx + ']';
      }
      var s = String(v);
      return s === 'Infinity' ? 'Infinity' : (s === 'NaN' ? 'NaN' : (v < 0 ? '(' + s + ')' : s));
    }

    function describe(e) {
      if (e.k === 'Name') return lookup(e.name) ? "local '" + e.name + "'" : "global '" + e.name + "'";
      if (e.k === 'Index' && e.key.k === 'String') return "field '" + e.key.v + "'";
      if (e.k === 'Method') return "method '" + e.name + "'";
      return '';
    }

    function isMultiExpr(e) { return e.k === 'Call' || e.k === 'Method' || e.k === 'Vararg'; }

    // A JS expression for the raw result of a call: possibly a Multi.
    function callRaw(e) {
      if (e.k === 'Method') {
        var o = ex(e.obj);
        var args = argList(e.args);
        return 'L.method(' + o + ', ' + str(e.name) + (args ? ', ' + args : '') + ')';
      }
      var fn = ex(e.fn), a = argList(e.args), d = describe(e.fn);
      if (/^\$[A-Za-z_][\w$]*$/.test(fn)) {
        return '(typeof ' + fn + " === 'function' ? " + fn + ' : L.call(' + fn + ', ' + str(d) + '))(' + a + ')';
      }
      var t = newTemp();
      return '(typeof (' + t + ' = ' + fn + ") === 'function' ? " + t + ' : L.call(' + t + ', ' + str(d) + '))(' + a + ')';
    }

    function argList(exprs) {
      var out = [];
      for (var i = 0; i < exprs.length; i++) {
        var e = exprs[i], last = i === exprs.length - 1;
        if (last && (e.k === 'Call' || e.k === 'Method')) out.push('...L.sp(' + callRaw(e) + ')');
        else if (last && e.k === 'Vararg') { checkVararg(e); out.push('...$$va'); }
        else out.push(ex(e));
      }
      return out.join(', ');
    }
    function checkVararg(e) {
      if (!fs.vararg) err("cannot use '...' outside a vararg function", e.line);
    }

    // A JS expression for exactly one Lua value.
    function ex(e) {
      switch (e.k) {
        case 'Nil': return 'undefined';
        case 'True': return 'true';
        case 'False': return 'false';
        case 'Number': return numberLiteral(e.v);
        case 'String': return str(e.v);
        case 'Vararg': checkVararg(e); return '$$va[0]';
        case 'Function': return funcExpr(e);
        case 'Paren': return ex(e.expr);
        case 'Name': {
          var js = lookup(e.name);
          if (js) return js;
          return 'L.index($$G, ' + str(e.name) + ')';
        }
        case 'Index':
          return 'L.index(' + ex(e.obj) + ', ' + ex(e.key) + ', ' + str(describe(e.obj)) + ')';
        case 'Call': case 'Method':
          return 'L.first(' + callRaw(e) + ')';
        case 'Table': return tableExpr(e);
        case 'Unop': {
          if (e.op === 'not') return '!' + cond(e.expr);
          if (e.op === '-') {
            if (e.expr.k === 'Number') {
              var lit = numberLiteral(e.expr.v);
              if (/^\d+$/.test(lit)) return lit === '0' ? '0' : '(-' + lit + ')';
              if (/^[\d.e+-]+$/.test(lit)) return '(-' + lit + ')';
            }
            return 'L.unm(' + ex(e.expr) + ')';
          }
          if (e.op === '#') return 'L.len(' + ex(e.expr) + ')';
          if (e.op === '~') return 'L.bnot(' + ex(e.expr) + ')';
          break;
        }
        case 'Binop': {
          if (e.op === 'and') {
            var t = newTemp();
            return '(L.T(' + t + ' = ' + ex(e.left) + ') ? ' + ex(e.right) + ' : ' + t + ')';
          }
          if (e.op === 'or') {
            var t2 = newTemp();
            return '(L.T(' + t2 + ' = ' + ex(e.left) + ') ? ' + t2 + ' : ' + ex(e.right) + ')';
          }
          if (e.op === '~=') return '!L.eq(' + ex(e.left) + ', ' + ex(e.right) + ')';
          if (COMPARE[e.op]) return 'L.' + COMPARE[e.op] + '(' + ex(e.left) + ', ' + ex(e.right) + ')';
          return 'L.' + ARITH[e.op] + '(' + ex(e.left) + ', ' + ex(e.right) + ')';
        }
      }
      err('cannot compile expression ' + e.k, e.line);
    }

    // A JS boolean expression for Lua truth, without building a Lua value.
    function cond(e) {
      switch (e.k) {
        case 'True': return 'true';
        case 'False': case 'Nil': return 'false';
        case 'Paren': return cond(e.expr);
        case 'Unop': if (e.op === 'not') return '!' + cond(e.expr); break;
        case 'Binop':
          if (e.op === 'and') return '(' + cond(e.left) + ' && ' + cond(e.right) + ')';
          if (e.op === 'or') return '(' + cond(e.left) + ' || ' + cond(e.right) + ')';
          if (e.op === '~=' || COMPARE[e.op]) return ex(e);
          break;
      }
      return 'L.T(' + ex(e) + ')';
    }

    function tableExpr(e) {
      var pos = [], keyed = [];
      for (var i = 0; i < e.items.length; i++) {
        var it = e.items[i];
        if (it.kind === 'pos') {
          var lastPos = true;
          for (var j = i + 1; j < e.items.length; j++) if (e.items[j].kind === 'pos') { lastPos = false; break; }
          if (lastPos && (it.value.k === 'Call' || it.value.k === 'Method')) pos.push('...L.sp(' + callRaw(it.value) + ')');
          else if (lastPos && it.value.k === 'Vararg') { checkVararg(it.value); pos.push('...$$va'); }
          else pos.push(ex(it.value));
        } else {
          keyed.push(ex(it.key), ex(it.value));
        }
      }
      if (!keyed.length) return 'L.tbl([' + pos.join(', ') + '])';
      return 'L.tbl([' + pos.join(', ') + '], [' + keyed.join(', ') + '])';
    }

    function funcExpr(f) {
      var saved = fs;
      fs = new FuncState(saved, f.vararg);
      openScope();
      var params = f.params.map(function (p) { return declare(p); });
      if (f.vararg) params.push('...$$va');
      var body = block(f.body);
      closeScope();
      var temps = '';
      if (fs.temps) {
        var names = [];
        for (var i = 1; i <= fs.temps; i++) names.push('$$' + i);
        temps = 'let ' + names.join(', ') + ';';
      }
      fs = saved;
      return 'function (' + params.join(', ') + ') {' + temps + body + '\n/*@' + (f.endLine || f.line) + '*/return L.NONE;}';
    }

    function block(stmts) {
      var out = '';
      for (var i = 0; i < stmts.length; i++) out += statement(stmts[i]);
      return out;
    }
    function scoped(stmts) {
      openScope();
      var b = block(stmts);
      closeScope();
      return b;
    }

    function assignTo(target, value) {
      if (target.k === 'Name') {
        var js = lookup(target.name);
        if (js) return js + ' = ' + value + ';';
        return 'L.setindex($$G, ' + str(target.name) + ', ' + value + ');';
      }
      return 'L.setindex(' + ex(target.obj) + ', ' + ex(target.key) + ', ' + value + ', ' + str(describe(target.obj)) + ');';
    }

    function valuesArray(exprs) { return '[' + argList(exprs) + ']'; }

    function statement(s) {
      var mark = '\n/*@' + (s.line || 0) + '*/';
      switch (s.k) {
        case 'Local': {
          var attrs = s.attribs || [];
          attrs.forEach(function (a) {
            if (a && a !== 'const' && a !== 'close') err("unknown attribute '" + a + "'", s.line);
          });
          if (s.names.length === 1 && s.exprs.length <= 1) {
            var v = s.exprs.length ? ex(s.exprs[0]) : 'undefined';
            return mark + 'let ' + declare(s.names[0]) + ' = ' + v + ';';
          }
          if (s.exprs.length === s.names.length && !s.exprs.some(isMultiExpr)) {
            var vals = s.exprs.map(ex);
            var tmpNames = vals.map(function () { return '$$l' + (++stmtUid); });
            var pre = 'const ' + tmpNames.map(function (t, i) { return t + ' = ' + vals[i]; }).join(', ') + ';';
            var decl = s.names.map(function (n, i) { return declare(n) + ' = ' + tmpNames[i]; });
            return mark + pre + ' let ' + decl.join(', ') + ';';
          }
          var r = '$$r' + (++stmtUid);
          var code = 'const ' + r + ' = ' + valuesArray(s.exprs) + ';';
          var decls = s.names.map(function (n, i) { return declare(n) + ' = ' + r + '[' + i + ']'; });
          return mark + code + ' let ' + decls.join(', ') + ';';
        }
        case 'LocalFunction': {
          var name = declare(s.name);
          return mark + 'let ' + name + '; ' + name + ' = ' + funcExpr(s.func) + ';';
        }
        case 'Assign': {
          if (s.targets.length === 1 && s.exprs.length === 1) {
            return mark + assignTo(s.targets[0], ex(s.exprs[0]));
          }
          var rr = '$$r' + (++stmtUid);
          var c2 = 'const ' + rr + ' = ' + valuesArray(s.exprs) + ';';
          s.targets.forEach(function (t, i) { c2 += ' ' + assignTo(t, rr + '[' + i + ']'); });
          return mark + c2;
        }
        case 'ExprStat':
          return mark + callRaw(s.expr) + ';';
        case 'Do':
          return mark + '{' + scoped(s.body) + '\n}';
        case 'While':
          return mark + 'while (' + cond(s.cond) + ') {' + scoped(s.body) + '\n}';
        case 'Repeat': {
          openScope();
          var body = block(s.body);
          var cnd = cond(s.cond);
          closeScope();
          return mark + 'for (;;) {' + body + '\nif (' + cnd + ') break;\n}';
        }
        case 'If': {
          var o = mark;
          s.clauses.forEach(function (c, i) {
            o += (i ? ' else if (' : 'if (') + cond(c.cond) + ') {' + scoped(c.body) + '\n}';
          });
          if (s.orelse) o += ' else {' + scoped(s.orelse) + '\n}';
          return o;
        }
        case 'NumFor': {
          var u = ++stmtUid;
          var I = '$$i' + u, LIM = '$$m' + u, ST = '$$s' + u, FL = '$$f' + u;
          var start = ex(s.start), limit = ex(s.limit);
          var stepLit = !s.step ? 1 : (s.step.k === 'Number' && /^\d+$/.test(s.step.v) ? Number(s.step.v) : null);
          var step = s.step ? ex(s.step) : '1';
          var intStart = s.start.k === 'Number' && /^\d+$/.test(s.start.v);
          var test = stepLit !== null && stepLit > 0 ? I + ' <= ' + LIM : '(' + ST + ' > 0 ? ' + I + ' <= ' + LIM + ' : ' + I + ' >= ' + LIM + ')';
          openScope();
          var v2 = declare(s.name);
          var bindVal = (intStart && stepLit !== null) ? I : FL + ' ? L.mkf(' + I + ') : ' + I;
          var bd = block(s.body);
          closeScope();
          return mark + 'for (let [' + I + ', ' + LIM + ', ' + ST + ', ' + FL + '] = L.forprep(' + start + ', ' + limit + ', ' + step + '); ' +
                 test + '; ' + I + ' += ' + ST + ') { let ' + v2 + ' = ' + bindVal + ';' + bd + '\n}';
        }
        case 'GenFor': {
          var it = '$$it' + (++stmtUid);
          var head = 'const ' + it + ' = L.iter(' + argList(s.exprs) + ');';
          openScope();
          var binds = s.names.map(function (n, i) {
            var src = i === 0 ? it + '.a' : (i === 1 ? it + '.b' : it + '.v[' + i + ']');
            return declare(n) + ' = ' + src;
          });
          var gb = block(s.body);
          closeScope();
          return mark + '{' + head + ' while (' + it + '.step()) { let ' + binds.join(', ') + ';' + gb + '\n}}';
        }
        case 'Return': {
          var ex0 = s.exprs;
          if (!ex0.length) return mark + 'return L.NONE;';
          if (ex0.length === 1) {
            if (ex0[0].k === 'Call' || ex0[0].k === 'Method') return mark + 'return ' + callRaw(ex0[0]) + ';';
            if (ex0[0].k === 'Vararg') { checkVararg(ex0[0]); return mark + 'return L.ret($$va);'; }
            return mark + 'return ' + ex(ex0[0]) + ';';
          }
          return mark + 'return L.ret(' + valuesArray(ex0) + ');';
        }
        case 'Break': return mark + 'break;';
        case 'Goto': case 'Label':
          err('goto and labels are not supported by Middaw\'s Lua', s.line);
      }
      err('cannot compile statement ' + s.k, s.line);
    }

    fs = new FuncState(null, true);
    openScope();
    var body = block(ast.body);
    closeScope();
    var temps = '';
    if (fs.temps) {
      var names = [];
      for (var i = 1; i <= fs.temps; i++) names.push('$$' + i);
      temps = 'let ' + names.join(', ') + ';';
    }
    return { body: temps + body, consts: consts };
  }

  // The line the first line of a `new Function` body is reported as.
  var lineOffset = null;
  function probeOffset() {
    if (lineOffset !== null) return lineOffset;
    try {
      new Function('throw new Error("probe");\n//# sourceURL=lua:__probe__')();
    } catch (e) {
      var m = /lua:__probe__:(\d+)/.exec(e.stack || '');
      lineOffset = m ? Number(m[1]) - 1 : 0;
    }
    return lineOffset;
  }

  var chunkUid = 0;
  // Lua source (a byte string) -> a JS function, as `load` gives it.
  function load(src, chunkname, env) {
    var name = String(chunkname || 'chunk').replace(/[^A-Za-z0-9_.\/-]/g, '_');
    if (NS.lineMaps[name]) name = name + '#' + (++chunkUid);
    var ast = NS.parse(src, name);
    var out = compile(ast, name);
    var code = 'return function (...$$va) {' + out.body + '\nreturn L.NONE;\n};';
    var offset = probeOffset();
    var lines = code.split('\n'), map = [], cur = 0;
    for (var i = 0; i < offset; i++) map.push(0);
    for (var j = 0; j < lines.length; j++) {
      var m = /^\/\*@(\d+)\*\//.exec(lines[j]);
      if (m) cur = Number(m[1]);
      map.push(cur);
    }
    NS.lineMaps[name.replace(/#/g, '_')] = map;
    var factory = new Function('L', '$$G', '$$K', code + '\n//# sourceURL=lua:' + name.replace(/#/g, '_'));
    return factory(NS, env || NS.defaultEnv(), out.consts);
  }

  var sharedEnv = null;
  NS.defaultEnv = function () { return sharedEnv || (sharedEnv = NS.makeEnv()); };
  NS.compile = compile;
  NS.load = load;
})(typeof module === 'object' && module.exports
  ? (module.exports = (globalThis.MiddawLua = globalThis.MiddawLua || {}))
  : (globalThis.MiddawLua = globalThis.MiddawLua || {}));


/* ---- ../kit/runtime/host.js ---- */
/* The family's Lua engines, spoken to in JSON.
 *
 * The native app runs this in JavaScriptCore, after the Lua runtime
 * (runtime/lua/), and calls `MiddawHost.call(method, argsJSON)`; the tests run
 * it in Node. It knows no browser and no files: the host hands it a
 * `readFile(path)` that returns the file's bytes as a string, one character
 * per byte, which is how Middaw's Lua keeps its strings.
 *
 * The adapters (Noterator's) are how the generators are spoken to - settings
 * in, notes out - the same protocol Miderator and Noterator use.
 */
(function (G) {
  'use strict';
  var L = G.MiddawLua;

  var FILES = [
    'good-idea/gi_theory.lua', 'good-idea/gi_idea.lua',
    'midi-catalogue/mc_theory.lua', 'midi-catalogue/mc_orchestra.lua', 'midi-catalogue/mc_catalogue.lua',
    'midi-suggester/ms_theory.lua', 'midi-suggester/ms_read.lua', 'midi-suggester/ms_harmony.lua', 'midi-suggester/ms_melody.lua',
    'midi-variator/mv_theory.lua', 'midi-variator/mv_vary.lua',
    'starting-blocks/sb_engine.lua',
    'adapters/common.lua', 'adapters/index.lua', 'adapters/good_idea.lua', 'adapters/midi_suggester.lua',
    'adapters/midi_variator.lua', 'adapters/starting_blocks.lua', 'adapters/midi_catalogue.lua',
    'notation/sb_notate.lua', 'notation/sb_draw.lua', 'notation/sb_glyphs.lua',
    'battle-pass/bp_theory.lua', 'battle-pass/bp_loot.lua', 'battle-pass/bp_game.lua',
    'orchestration/orchestration_data.lua', 'orchestration/orchestration_composers.lua'
  ];

  var readFile = null, modules = {}, env = null, log = function () {};

  function engine(name) {
    if (modules[name] === undefined) {
      var src = readFile(name);
      if (src === null || src === undefined) throw new Error("engine '" + name + "' is not there");
      var r = L.first(L.load(src, name, env)());
      modules[name] = r === undefined ? false : r;
    }
    return modules[name];
  }

  function init(reader, logger) {
    readFile = reader;
    if (logger) log = logger;
    modules = {};
    env = L.makeEnv({
      print: function (s) { log('[lua] ' + L.fromBytes(s)); },
      readFile: function () { return null; },
      writeFile: function () {}
    });
    env.set('engine', function (name) { return engine(name); });
    env.set('dofile', function (name) { return L.first(engine(String(name).replace(/^.*engines\//, ''))); });
    return true;
  }

  function call(mod, fname) {
    var m = typeof mod === 'string' ? engine(mod) : mod;
    var f = L.index(m, fname);
    var args = [];
    for (var i = 2; i < arguments.length; i++) {
      var a = arguments[i];
      args.push(a instanceof L.LuaTable ? a : L.toLua(a));
    }
    return L.first(L.call(f).apply(null, args));
  }
  function js(v) { return L.toJS(v); }
  function list(x) { return !x ? [] : Array.isArray(x) ? x : Object.keys(x).map(function (k) { return x[k]; }); }

  // --------------------------------------------------------- generators --
  var adapters = null;
  function gens() {
    if (adapters) return adapters;
    adapters = list(js(engine('adapters/index.lua'))).map(function (path) {
      var A = engine(path);
      return { id: js(L.index(A, 'id')), name: js(L.index(A, 'name')), description: js(L.index(A, 'description')) || '',
               input: js(L.index(A, 'input')), panel: js(L.index(A, 'panel')) || null, A: A, path: path };
    });
    return adapters;
  }
  function gen(id) {
    var l = gens();
    for (var i = 0; i < l.length; i++) if (l[i].id === id) return l[i];
    throw new Error('no generator ' + id);
  }

  // A generator's settings live in Lua, as the engine left them.
  var sessions = {}, nextSession = 1;
  function session(id) { var s = sessions[id]; if (!s) throw new Error('no session ' + id); return s; }
  function normalise(r) {
    r = r || { results: [] };
    r.results = list(r.results);
    r.results.forEach(function (res) {
      res.parts = list(res.parts);
      res.parts.forEach(function (p) { p.notes = list(p.notes); });
    });
    return r;
  }

  // ------------------------------------------------------------- theory --
  // Chord names are ScaleView's, read by Midi Variator's port of it.
  // mv_theory knows the seven-note scales; anything else names chords
  // against the parallel major or minor. Indexed by ScaleView's scale (1-16).
  var MV_SCALE = [1, 2, 3, 1, 4, 5, 6, 7, 2, 1, 2, 1, 2, 1, 2, 1];
  var keyCache = {};
  function luaKey(key) {
    var k = key.root + ':' + key.scale;
    if (!keyCache[k]) keyCache[k] = call('midi-variator/mv_theory.lua', 'key', key.root, MV_SCALE[key.scale - 1] || 1);
    return keyCache[k];
  }

  // -------------------------------------------------------- orchestra ----
  // Noterator's instruments beyond the orchestra (Source/Core/Instruments.cpp).
  var EXTRA = [
    { id: 'asax', name: 'Alto Saxophone', family: 'Woodwind', low: 49, high: 80, sweet: [53, 76], poly: 1, fast: 0.09, leap: 12 },
    { id: 'tsax', name: 'Tenor Saxophone', family: 'Woodwind', low: 44, high: 75, sweet: [48, 70], poly: 1, fast: 0.09, leap: 12 },
    { id: 'bsax', name: 'Baritone Saxophone', family: 'Woodwind', low: 36, high: 69, sweet: [40, 62], poly: 1, fast: 0.10, leap: 12 },
    { id: 'vib', name: 'Vibraphone', family: 'Percussion', low: 53, high: 89, sweet: [55, 84], poly: 4, fast: 0.09, leap: 12 },
    { id: 'sop', name: 'Soprano', family: 'Voices', low: 60, high: 81, sweet: [64, 77], poly: 1, fast: 0.15, leap: 9 },
    { id: 'alto', name: 'Alto', family: 'Voices', low: 53, high: 74, sweet: [57, 69], poly: 1, fast: 0.15, leap: 9 },
    { id: 'ten', name: 'Tenor', family: 'Voices', low: 48, high: 69, sweet: [50, 65], poly: 1, fast: 0.15, leap: 9 },
    { id: 'bass', name: 'Bass', family: 'Voices', low: 40, high: 64, sweet: [43, 60], poly: 1, fast: 0.15, leap: 9 },
    { id: 'gtr', name: 'Guitar', family: 'Band', low: 40, high: 83, sweet: [45, 76], poly: 6, fast: 0.08, leap: 12 },
    { id: 'ebass', name: 'Bass Guitar', family: 'Band', low: 28, high: 67, sweet: [28, 55], poly: 1, fast: 0.09, leap: 12 },
    { id: 'ubass', name: 'Upright Bass', family: 'Band', low: 28, high: 67, sweet: [28, 55], poly: 1, fast: 0.10, leap: 12 },
    { id: 'synth', name: 'Synth', family: 'Band', low: 24, high: 108, sweet: [36, 96], poly: 16, fast: 0.03, leap: 48 },
    { id: 'kit', name: 'Drum Kit', family: 'Band', low: 35, high: 81, sweet: [35, 81], poly: 4, fast: 0.05, leap: 127, drums: true }
  ];

  // ----------------------------------------------------------- notation --
  var notate = null;
  function notation() {
    if (notate) return notate;
    var N = engine('notation/sb_notate.lua'), D = engine('notation/sb_draw.lua'), Gl = engine('notation/sb_glyphs.lua');
    L.call(L.index(D, 'setNotate'))(N);
    L.call(L.index(D, 'setGlyphs'))(Gl);
    notate = { N: N, D: D, E: engine('starting-blocks/sb_engine.lua') };
    return notate;
  }
  // A pen that records what Starting Blocks Notation draws, for the native
  // side to replay. sb_draw.lua uses four calls; colours arrive as the ids
  // given to it (1 ink, 2 staff, 3 ground, 4 accent):
  //   ["line", x1, y1, x2, y2, colour, thickness]
  //   ["poly", [x, y, x, y, ...], colour]
  //   ["circle", x, y, r, colour, filled]
  //   ["text", x, y, colour, text, size, centred]
  function num(v) { return v instanceof L.LFloat ? v.n : +v; }
  function colour(c) { return c instanceof L.LuaTable ? js(c) : num(c); }
  function recordingPen(ops) {
    var pen = new L.LuaTable();
    pen.set('line', function (x1, y1, x2, y2, col, th) {
      ops.push(['line', num(x1), num(y1), num(x2), num(y2), colour(col), th === undefined ? 1 : num(th)]); return L.NONE;
    });
    pen.set('poly', function (pts, col) {
      ops.push(['poly', pts.arr.map(num), colour(col)]); return L.NONE;
    });
    pen.set('circle', function (x, y, r, col, filled) {
      ops.push(['circle', num(x), num(y), num(r), colour(col), !!L.T(filled)]); return L.NONE;
    });
    pen.set('text', function (x, y, col, str, size, center) {
      ops.push(['text', num(x), num(y), colour(col), L.fromBytes(L.tostring(str)), num(size), !!L.T(center)]); return L.NONE;
    });
    return pen;
  }

  // ---------------------------------------------------------- the pass ---
  var pass = null, passState = null, passSession = null;
  function battlePass() {
    if (pass) return pass;
    var T = engine('battle-pass/bp_theory.lua');
    var Lt = L.first(L.call(L.index(engine('battle-pass/bp_loot.lua'), 'init'))(T));
    var Gm = L.first(L.call(L.index(engine('battle-pass/bp_game.lua'), 'init'))(Lt));
    pass = { G: Gm, L: Lt, T: T };
    return pass;
  }

  // ------------------------------------------------------------- methods -
  var M = {
    generators: function () {
      return gens().map(function (g) { return { id: g.id, name: g.name, description: g.description, input: g.input, panel: g.panel }; });
    },
    newSession: function (a) {
      var g = gen(a.generator), id = nextSession++;
      sessions[id] = { g: g, st: L.first(L.call(L.index(g.A, 'newState'))()) };
      return id;
    },
    useKey: function (a) { var s = session(a.session); call(s.g.A, 'useKey', s.st, a.key.root, a.key.scale); return true; },
    settings: function (a) { var s = session(a.session); return list(js(call(s.g.A, 'settings', s.st, L.toLua(a.context || {})))); },
    set: function (a) { var s = session(a.session); call(s.g.A, 'set', s.st, a.setting, a.index, L.toLua(a.context || {})); return true; },
    generate: function (a) {
      var s = session(a.session);
      return normalise(js(call(s.g.A, 'generate', s.st, L.toLua(a.context || {}), a.seed || 1, a.count || 6)));
    },
    snapshot: function (a) { return js(session(a.session).st); },
    restore: function (a) {
      var s = session(a.session);
      Object.keys(a.state || {}).forEach(function (k) { L.setindex(s.st, L.toBytes(k), L.toLua(a.state[k])); });
      return true;
    },
    closeSession: function (a) { delete sessions[a.session]; return true; },

    nameChord: function (a) {
      if (!a.pitches || a.pitches.length < 2) return '';
      var r = L.call(L.index(engine('midi-variator/mv_theory.lua'), 'nameChord'))(L.toLua(a.pitches), luaKey(a.key));
      return js(L.first(r)) || '';
    },
    noteNames: function (a) {
      var k = js(L.index(luaKey(a.key), 'names')), out = [];
      for (var pc = 0; pc < 12; pc++) out.push(k[pc] || k[String(pc)] || '');
      return out;
    },
    // Midi Variator's key finder (ScaleView's), as Miderator's key lane uses it.
    detectKey: function (a) {
      var notes = (a.notes || []).slice().sort(function (x, y) { return x.start - y.start; });
      if (!notes.length) return null;
      var r = list(js(call('midi-variator/mv_theory.lua', 'detectKey',
        notes.map(function (n) { return { pitch: n.pitch, start: n.start, len: n.len }; }),
        notes[0].pitch % 12, notes[notes.length - 1].pitch % 12)));
      if (!r.length) return null;
      return { root: r[0].root, scale: r[0].scale === 2 ? 2 : 1 };
    },
    // Midi Catalogue's orchestra, plus Noterator's band and voices.
    instruments: function () {
      return list(js(L.index(engine('midi-catalogue/mc_orchestra.lua'), 'INSTRUMENTS'))).concat(EXTRA);
    },
    orchestration: function () {
      var A = js(engine('orchestration/orchestration_data.lua'));
      var B = js(engine('orchestration/orchestration_composers.lua'));
      return { entries: list(A.ENTRIES).concat(list(B && B.ENTRIES)),
               sources: Object.assign({}, (B && B.SOURCES) || {}, A.SOURCES || {}) };
    },

    // A part engraved by Starting Blocks Notation: its height and the drawing,
    // as a list of pen calls in staff spaces of `space` points.
    engrave: function (a) {
      var nt = notation();
      var st = L.first(L.call(L.index(nt.E, 'newState'))());
      st.set('root', a.key.root); st.set('scale', a.key.scale); st.set('barBeats', a.barBeats);
      var ctx = L.first(L.call(L.index(nt.N, 'context'))(nt.E, st));
      var block = L.toLua({ notes: a.notes, beats: a.beats, name: a.name || '' });
      var opts = L.toLua({ barBeats: a.barBeats, tsNum: a.meter[0], tsDen: a.meter[1], width: a.width,
                           drums: !!a.drums, grid: a.drums ? 0.25 : undefined,
                           // a clip is as played, so its silences are rests (Starting Blocks Notation 0019)
                           rests: !a.drums });
      opts.set('ctx', ctx);
      var doc = L.first(L.call(L.index(nt.N, 'layout'))(block, opts));
      var height = +L.first(L.call(L.index(nt.D, 'height'))(doc, a.space));
      var ops = [];
      var colours = L.toLua({ ink: 1, staff: 2, ground: 3, accent: 4 });
      var popts = new L.LuaTable();
      if (a.highlight !== undefined && a.highlight >= 0) {
        var at = a.highlight * 960;
        popts.set('highlight', function (el) {
          var abs = L.index(el, 'abs'), ticks = L.index(el, 'ticks');
          return abs !== undefined && at >= +abs && at < +abs + +ticks;
        });
      }
      L.call(L.index(nt.D, 'page'))(recordingPen(ops), doc, 0, 0, a.space, colours, popts);
      return { height: height, ops: ops };
    },

    // The Battle Pass, unchanged: its state is the game's own text.
    // `clock` is seconds of activity time, `epoch` the wall clock in seconds.
    passStart: function (a) {
      var Gm = battlePass().G;
      passState = a.saved ? L.first(L.call(L.index(Gm, 'deserialize'))(L.toBytes(a.saved))) : undefined;
      if (!passState) passState = L.first(L.call(L.index(Gm, 'newState'))(a.epoch));
      L.call(L.index(Gm, 'clampState'))(passState, a.epoch);
      passSession = L.first(L.call(L.index(Gm, 'newSession'))(passState, a.clock, a.epoch));
      L.call(L.index(Gm, 'refresh'))(passState, passSession, a.epoch, new L.LuaTable());
      return true;
    },
    // Any bp_game function; "$state" and "$session" in `args` stand for the
    // game's own tables.
    passCall: function (a) {
      var args = (a.args || []).map(function (x) {
        return x === '$state' ? passState : x === '$session' ? passSession : L.toLua(x);
      });
      return js(L.first(L.call(L.index(battlePass().G, a.fn)).apply(null, args)));
    },
    // What the game wants celebrated since last asked, then forgotten.
    passNotices: function () {
      var l = L.index(passSession, 'notices');
      if (!l || !l.arr || !l.arr.length) return [];
      var out = l.arr.map(function (n) { return js(n); });
      l.arr.length = 0;
      return out;
    },
    passGet: function (a) {
      var v = passState;
      String(a.path).split('.').forEach(function (k) { v = v === undefined ? undefined : L.index(v, isNaN(+k) ? k : +k); });
      return v instanceof L.LFloat ? v.n : js(v);
    },
    // Middaw's composer (runtime/composer/, the port of middaw/): a sentence
    // in, the song's five parts out, exactly as `python3 -m middaw --json`
    // answers. composerLoad takes data/vocab/tags.json and drums.json as text.
    composerLoad: function (a) {
      if (!G.MiddawComposer || !G.MiddawComposer.load) throw new Error('the composer is not loaded');
      G.MiddawComposer.load(JSON.parse(a.tags), JSON.parse(a.drums));
      return true;
    },
    compose: function (a) {
      var C = G.MiddawComposer;
      if (!C || !C.vocabulary) throw new Error('the composer has no vocabulary');
      return C.compose(String(a.prompt || ''), a.seed === undefined || a.seed === null ? undefined : a.seed);
    },

    // The game's own tables that are not state: the shop, the check-in
    // calendar, the rarities (module 'loot').
    passConst: function (a) {
      var P = battlePass();
      var v = L.index(a.module === 'loot' ? P.L : P.G, String(a.name));
      // a list that is also indexed by name (G.SHOP[id]) is its list
      if (v instanceof L.LuaTable && L.index(v, 1) != null) {
        var out = [];
        for (var i = 1; L.index(v, i) != null; i++) out.push(js(L.index(v, i)));
        return out;
      }
      return js(v);
    },
    passSave: function () { return L.fromBytes(L.first(L.call(L.index(battlePass().G, 'serialize'))(passState))); },

    // AutoCC (the JSFX, unchanged) run over a clip's notes: the curves it
    // would play, as controller lanes {number: [[beat, value], ...]}. Only a
    // point where the value turns is kept, not every step.
    autoCC: function (a) {
      var J = G.MiddawJSFX;
      if (!J) throw new Error('the JSFX runtime is not loaded');
      var fx = new J.JSFX(a.source, {});
      Object.keys(a.sliders || {}).forEach(function (k) { fx.setSliderByIndex(Number(k), a.sliders[k]); });
      var sr = 48000, bs = 256;
      fx.init(sr);
      fx.setTime({ tempo: a.tempo, playState: 1, num: a.meter[0], den: a.meter[1] });
      var ev = [];
      (a.notes || []).forEach(function (n) {
        ev.push([n.start, [0x90, n.pitch, n.vel]]);
        ev.push([n.start + n.len, [0x80, n.pitch, 0]]);
      });
      ev.sort(function (x, y) { return x[0] - y[0]; });
      var spb = sr * 60 / a.tempo, total = Math.ceil(a.length * spb / bs) + 8, k = 0, lanes = {};
      for (var b = 0; b < total; b++) {
        var midi = [];
        while (k < ev.length && ev[k][0] * spb < (b + 1) * bs) {
          midi.push({ offset: Math.max(0, Math.round(ev[k][0] * spb - b * bs)), data: ev[k][1] }); k++;
        }
        fx.setTime({ beat: b * bs / spb, seconds: b * bs / sr });
        fx.process(bs, null, null, midi).forEach(function (m) {
          if ((m.data[0] & 0xF0) !== 0xB0) return;
          var beat = (b * bs + m.offset) / spb;
          if (beat > a.length) return;
          (lanes[m.data[1]] = lanes[m.data[1]] || []).push([Math.round(beat * 1000) / 1000, m.data[2]]);
        });
      }
      Object.keys(lanes).forEach(function (num) {
        var pts = lanes[num], out = [];
        pts.forEach(function (pt, i) {
          var prev = out[out.length - 1];
          if (!prev || i === pts.length - 1 || Math.abs(pt[1] - prev[1]) >= 2) out.push(pt);
        });
        lanes[num] = out;
      });
      return lanes;
    }
  };

  G.MiddawHost = {
    FILES: FILES,
    init: init,
    // The one entry point the native side uses: JSON in, JSON out, errors
    // returned rather than thrown so they cross the bridge as text.
    call: function (method, argsJSON) {
      try {
        if (!M[method]) throw new Error('no method ' + method);
        var r = M[method](argsJSON ? JSON.parse(argsJSON) : {});
        return JSON.stringify({ ok: true, value: r === undefined ? null : r });
      } catch (e) {
        var msg = e && (e.message || (e.value !== undefined ? String(L.tostring ? L.tostring(e.value) : e.value) : String(e)));
        return JSON.stringify({ ok: false, error: msg || 'error' });
      }
    },
    methods: M
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);


/* ---- ../kit/ui.js ---- */
/* The family's look, drawn with Max's mgraphics in a [v8ui].
 *
 * Colours are Palette's (palette.js), after Ableton Live 8: neutral greys,
 * the amber accent for what is on, every word 7:1 on its surface. A control
 * registers its rectangle while it is painted, so a click goes to whatever
 * was drawn under it last paint - no layout is kept twice.
 */
var UI = (function () {
  'use strict';
  function rgb(hex, a) {
    return [((hex >> 16) & 255) / 255, ((hex >> 8) & 255) / 255, (hex & 255) / 255, a === undefined ? 1 : a];
  }
  // The colours are Palette's (palette.js): Live 8's neutral greys and amber.
  var P = Palette.C;
  var C = {
    accent: rgb(P.accent), accentHeld: rgb(P.accentHeld), control: rgb(P.control), controlHeld: rgb(P.controlHeld),
    ground: rgb(P.ground), raised: rgb(P.raised), sunken: rgb(P.sunken), rule: rgb(P.rule),
    edge: rgb(P.edge), ink: rgb(P.ink), text: rgb(P.text), dim: rgb(P.dim),
    label: rgb(P.label), warn: rgb(P.warn), warnText: rgb(P.warnText), mark: rgb(P.mark), note: rgb(P.note)
  };

  var g = null, hits = [], drag = null, FONT = 'Arial';

  function begin(graphics) {
    g = graphics;
    hits = [];
    g.select_font_face(FONT);
  }
  function fill(c) { g.set_source_rgba(c[0], c[1], c[2], c[3]); }
  function rect(x, y, w, h, c) { fill(c); g.rectangle(x, y, w, h); g.fill(); }
  function round(x, y, w, h, r, c) { fill(c); g.rectangle_rounded(x, y, w, h, r, r); g.fill(); }
  function frame(x, y, w, h, c) { fill(c); g.set_line_width(1); g.rectangle(x + 0.5, y + 0.5, w - 1, h - 1); g.stroke(); }
  function measure(s, size) { g.set_font_size(size || 10); var m = g.text_measure(String(s)); return m[0]; }

  // Text cut to fit, with an ellipsis, so a long name never runs into the next control.
  function fit(s, w, size) {
    s = String(s);
    if (measure(s, size) <= w) return s;
    while (s.length > 1 && measure(s + '…', size) > w) s = s.slice(0, -1);
    return s + '…';
  }
  // align: 0 left, 1 centre, 2 right; y is the box top, h its height.
  function text(s, x, y, w, h, c, size, align, bold) {
    size = size || 10;
    g.select_font_face(FONT, 'normal', bold ? 'bold' : 'normal');
    g.set_font_size(size);
    var t = fit(s, w, size), tw = measure(t, size);
    var tx = align === 1 ? x + (w - tw) / 2 : align === 2 ? x + w - tw : x;
    fill(c);
    g.move_to(tx, y + h / 2 + size * 0.36);
    g.show_text(t);
    g.select_font_face(FONT, 'normal', 'normal');
  }

  function hit(x, y, w, h, handler) { hits.push({ x: x, y: y, w: w, h: h, fn: handler }); }
  function find(px, py) {
    for (var i = hits.length - 1; i >= 0; i--) {
      var r = hits[i];
      if (px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h) return r;
    }
    return null;
  }

  // A push button: title-style words, ink on the control grey, accent when on.
  function button(label, x, y, w, h, on, handler, enabled) {
    var off = enabled === false;
    round(x, y, w, h, 3, off ? C.raised : on ? C.accent : C.control);
    text(label, x + 4, y, w - 8, h, off ? C.dim : C.ink, 10, 1, true);
    if (!off) hit(x, y, w, h, { click: handler });
  }

  // A value chosen from a list: click the left third for the one before, the
  // rest for the one after, or drag up and down through them.
  function stepper(label, names, index, x, y, w, onChange) {
    text(label, x, y, w, 12, C.label, 9, 0);
    var by = y + 13, bh = 18;
    round(x, by, w, bh, 3, C.sunken);
    frame(x, by, w, bh, C.rule);
    text('‹', x + 3, by, 8, bh, C.dim, 11, 1);
    text('›', x + w - 11, by, 8, bh, C.dim, 11, 1);
    text(names[index - 1] === undefined ? '' : names[index - 1], x + 12, by, w - 24, bh, C.text, 10, 1);
    var n = names.length;
    var last = index;
    function to(i) { i = Math.max(1, Math.min(n, i)); if (i !== last) { last = i; onChange(i); } }
    hit(x, by, w, bh, {
      click: function (px) { to(px < x + w / 3 ? index - 1 : index + 1); },
      drag: function (dy) { to(index - Math.round(dy / 8)); }
    });
  }

  // The same, in one line for a small panel (a MIDI Tool's): the label at
  // the left, the value at the right, the arrows at the ends.
  function row(label, names, index, x, y, w, h, onChange) {
    round(x, y, w, h, 3, C.sunken);
    frame(x, y, w, h, C.rule);
    text('‹', x + 1, y, 8, h, C.dim, 10, 1);
    text('›', x + w - 9, y, 8, h, C.dim, 10, 1);
    var lw = Math.round((w - 18) * 0.42);
    text(label, x + 10, y, lw - 2, h, C.label, 9, 0);
    text(names[index - 1] === undefined ? '' : names[index - 1], x + 10 + lw, y, w - 20 - lw, h, C.text, 9, 2);
    var n = names.length, last = index;
    function to(i) { i = Math.max(1, Math.min(n, i)); if (i !== last) { last = i; onChange(i); } }
    hit(x, y, w, h, {
      click: function (px) { to(px < x + w / 3 ? index - 1 : index + 1); },
      drag: function (dy) { to(index - Math.round(dy / 8)); }
    });
  }

  function toggle(label, on, x, y, w, h, onChange) {
    round(x, y, w, h, 3, on ? C.accent : C.control);
    text(label, x + 4, y, w - 8, h, C.ink, 10, 1, true);
    hit(x, y, w, h, { click: function () { onChange(!on); } });
  }

  // Mouse, as [v8ui] delivers it: onclick then ondrag until the button is up.
  function click(px, py) {
    var r = find(px, py);
    drag = null;
    if (!r) return false;
    if (r.fn.drag) drag = { r: r, y0: py, moved: false };
    else if (r.fn.click) r.fn.click(px, py);
    return true;
  }
  function dragTo(px, py, down) {
    if (!drag) return;
    var dy = drag.y0 - py;
    if (down) {
      if (Math.abs(dy) >= 4) drag.moved = true;
      if (drag.moved) drag.r.fn.drag(dy);
    } else {
      if (!drag.moved && drag.r.fn.click) drag.r.fn.click(px, py);
      drag = null;
    }
  }

  return { C: C, begin: begin, rect: rect, round: round, frame: frame, text: text, fit: fit, measure: measure,
           hit: hit, button: button, stepper: stepper, row: row, toggle: toggle, click: click, dragTo: dragTo, find: find };
})();


/* ---- ../kit/live.js ---- */
/* The Live set, as the family's devices need it: the song's tempo, meter and
 * scale, the notes of the clip being edited, somewhere to put new notes, and
 * a way to hear notes before they are used.
 *
 * Everything goes through the Live Object Model (LiveAPI). Times are beats,
 * which in Live are quarter notes - the unit every family engine already
 * speaks - so nothing is converted but the field names.
 */
var Live = (function () {
  'use strict';
  function api(path) { return new LiveAPI(null, path); }
  function one(a, prop) { var v = a.get(prop); return Array.isArray(v) ? v[0] : v; }
  function exists(a) { return a && Number(a.id) !== 0; }
  function json(v) {
    if (typeof v === 'string') return JSON.parse(v);
    if (Array.isArray(v) && typeof v[0] === 'string' && v.length === 1) return JSON.parse(v[0]);
    return v;
  }

  // Live 12's scale names, as ScaleView numbers its scales (1-16). A scale
  // ScaleView has no name for is left out: the device keeps its own key.
  var SCALE = {
    'Major': 1, 'Minor': 2, 'Harmonic Minor': 3, 'Dorian': 5, 'Phrygian': 6, 'Lydian': 7,
    'Mixolydian': 8, 'Major Pentatonic': 10, 'Minor Pentatonic': 11, 'Minor Blues': 13,
    'Whole Tone': 14, 'Whole-half Dim.': 15, 'Half-whole Dim.': 16
  };
  // ScaleView's eighteen roots, and the spelling a key on each pitch class
  // takes: flats for the major side, sharps where a minor key has them.
  var ROOTS = ['C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B', 'Cb'];
  var MAJOR_SIDE = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
  var MINOR_SIDE = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];
  var MINORISH = { 2: 1, 3: 1, 5: 1, 6: 1, 11: 1, 13: 1 };
  var SCALE_NAMES = ['Major', 'Minor (Natural)', 'Harmonic Minor', 'Ionian', 'Dorian', 'Phrygian', 'Lydian',
                     'Mixolydian', 'Aeolian', 'Major Pentatonic', 'Minor Pentatonic', 'Major Blues', 'Minor Blues',
                     'Whole Tone', 'Diminished Whole-Half', 'Diminished Half-Whole'];

  // Live's scale (a root pitch class and a name) as the family's key, or
  // null for a scale ScaleView does not have.
  function keyOf(pc, name) {
    var sc = SCALE[String(name)];
    if (!sc) return null;
    return { root: ROOTS.indexOf((MINORISH[sc] ? MINOR_SIDE : MAJOR_SIDE)[((+pc % 12) + 12) % 12]) + 1, scale: sc };
  }

  function song() {
    var s = api('live_set');
    var out = { tempo: +one(s, 'tempo') || 120, num: +one(s, 'signature_numerator') || 4,
                den: +one(s, 'signature_denominator') || 4, playing: !!+one(s, 'is_playing'),
                position: +one(s, 'current_song_time') || 0, key: null };
    var mode = s.get('scale_mode');
    if (mode !== undefined && mode !== null) {
      var name = String(one(s, 'scale_name')), pc = +one(s, 'root_note');
      out.liveScale = { on: !!+(Array.isArray(mode) ? mode[0] : mode), name: name, root: pc };
      out.key = keyOf(pc, name);
    }
    return out;
  }

  function detailClip() {
    var c = api('live_set view detail_clip');
    if (!exists(c) || !+one(c, 'is_midi_clip')) return null;
    return c;
  }

  // The clip being edited: its selected notes if any are selected, else every
  // note in its loop. Starts are from the start of what was taken.
  function clipNotes() {
    var c = detailClip();
    if (!c) return null;
    var from = +one(c, 'loop_start') || 0, to = +one(c, 'loop_end') || 0;
    var raw = null, selected = false;
    try { raw = json(c.call('get_selected_notes_extended')); selected = raw && raw.notes && raw.notes.length > 0; } catch (e) { raw = null; }
    if (!selected) raw = json(c.call('get_notes_extended', 0, 128, from, Math.max(0, to - from)));
    var notes = ((raw && raw.notes) || []).filter(function (n) { return !n.mute; }).map(function (n) {
      return { start: n.start_time, len: n.duration, pitch: n.pitch, vel: Math.round(n.velocity) };
    });
    var first = selected && notes.length ? Math.min.apply(null, notes.map(function (n) { return n.start; })) : from;
    var beats = to - from;
    if (selected) {
      var bar = 4, end = 0;
      notes.forEach(function (n) { end = Math.max(end, n.start + n.len); });
      first = Math.floor(first / bar) * bar;
      beats = Math.ceil((end - first) / bar) * bar;
    }
    notes.forEach(function (n) { n.start -= first; });
    notes.sort(function (a, b) { return a.start - b.start || a.pitch - b.pitch; });
    return { notes: notes, beats: beats, name: String(one(c, 'name') || ''), selected: selected, drums: drumTrack() };
  }

  // A track whose instrument is a Drum Rack plays drums: its note numbers name
  // drums, not pitches, and the engines treat them that way.
  function drumTrack() {
    try {
      var track = api('this_device canonical_parent'), n = track.getcount('devices');
      for (var i = 0; i < n; i++) if (+one(api(track.unquotedpath + ' devices ' + i), 'can_have_drum_pads')) return true;
    } catch (e) { /* not known: not drums */ }
    return false;
  }

  function liveNotes(notes) {
    return { notes: notes.map(function (n) {
      return { pitch: Math.max(0, Math.min(127, Math.round(n.pitch))), start_time: Math.max(0, n.start),
               duration: Math.max(1 / 128, n.len), velocity: Math.max(1, Math.min(127, Math.round(n.vel || 100))), mute: 0 };
    }) };
  }

  function undoable(fn) {
    var s = api('live_set');
    try { s.call('begin_undo_step'); } catch (e) { /* Live before 11.1 */ }
    try { return fn(); } finally { try { s.call('end_undo_step'); } catch (e2) { /* as above */ } }
  }

  function show(clip) {
    try { api('live_set view').set('detail_clip', 'id', Number(clip.id)); } catch (e) { /* the clip is made either way */ }
  }

  function selectedScene() {
    var scene = api('live_set view selected_scene'), n = api('live_set').getcount('scenes');
    for (var i = 0; i < n; i++) if (Number(api('live_set scenes ' + i).id) === Number(scene.id)) return i;
    return 0;
  }
  function thisTrack() {
    var track = api('this_device canonical_parent');
    if (!exists(track) || !+one(track, 'has_midi_input')) return null;
    return track;
  }
  // Where this device's track is in the set, for putting new tracks beside it.
  function trackIndex(track) {
    var n = api('live_set').getcount('tracks');
    for (var i = 0; i < n; i++) if (Number(api('live_set tracks ' + i).id) === Number(track.id)) return i;
    return n - 1;
  }
  function clipInSlot(slot, notes, beats, name) {
    slot.call('create_clip', Math.max(1, beats));
    var clip = api(slot.unquotedpath + ' clip');
    if (name) clip.set('name', name);
    clip.call('add_new_notes', liveNotes(notes));
    return clip;
  }
  function freeSlot(track, from) {
    var n = track.getcount('clip_slots');
    for (var k = 0; k < n; k++) {
      var at = (from + k) % n, slot = api(track.unquotedpath + ' clip_slots ' + at);
      if (!+one(slot, 'has_clip')) return { slot: slot, at: at };
    }
    return null;
  }
  function arrangementClipOn(track, notes, beats, name, at) {
    var before = track.getcount('arrangement_clips');
    try { track.call('create_midi_clip', at, Math.max(1, beats)); } catch (e) { /* checked below */ }
    var count = track.getcount('arrangement_clips');
    if (!(count > before)) return false;
    for (var i = 0; i < count; i++) {
      var clip = api(track.unquotedpath + ' arrangement_clips ' + i);
      if (Math.abs((+one(clip, 'start_time') || 0) - at) < 1e-6) {
        if (name) clip.set('name', name);
        clip.call('add_new_notes', liveNotes(notes));
        return true;
      }
    }
    return false;
  }

  // New notes, as a new clip in the first free slot on this device's track,
  // from the selected scene down. `more` are further parts ({name, notes}),
  // each on a new MIDI track after this one, in the same scene. Returns what
  // happened, for the status line.
  function newClip(notes, beats, name, more) {
    var track = thisTrack();
    if (!track) return { ok: false, message: 'This device needs to be on a MIDI track.' };
    var free = freeSlot(track, selectedScene());
    if (!free) return { ok: false, message: 'Every clip slot on this track is full. Add a scene, then try again.' };
    return undoable(function () {
      var clip = clipInSlot(free.slot, notes, beats, name);
      var made = newTracks(track, more, function (t) {
        clipInSlot(api(t.unquotedpath + ' clip_slots ' + free.at), this.notes, beats, this.name);
      });
      show(clip);
      return { ok: true, message: 'Added a clip in scene ' + (free.at + 1) + (made ? ', and ' + made + ' on new tracks beside it.' : '.') };
    });
  }

  // New notes on a new MIDI track beside this one, in the selected scene:
  // a suggestion goes with the music it was made for, not over it.
  function newTrackClip(notes, beats, name, more) {
    var track = thisTrack();
    if (!track) return { ok: false, message: 'This device needs to be on a MIDI track.' };
    var scene = selectedScene();
    return undoable(function () {
      var parts = [{ name: name, notes: notes }].concat(more || []);
      newTracks(track, parts, function (t) { show(clipInSlot(api(t.unquotedpath + ' clip_slots ' + scene), this.notes, beats, this.name)); });
      return { ok: true, message: parts.length === 1 ? 'Added a track beside this one, with the clip in scene ' + (scene + 1) + '.'
                                                     : 'Added ' + parts.length + ' tracks beside this one, with the clips in scene ' + (scene + 1) + '.' };
    });
  }

  // Each further part on a new MIDI track, in order, after this one.
  function newTracks(track, more, put) {
    if (!more || !more.length) return '';
    var at = trackIndex(track), song = api('live_set');
    more.forEach(function (part, k) {
      song.call('create_midi_track', at + 1 + k);
      var t = api('live_set tracks ' + (at + 1 + k));
      t.set('name', part.name);
      put.call(part, t);
    });
    return more.length === 1 ? 'one more part' : more.length + ' more parts';
  }

  // New notes in place of the notes of the clip being edited, from its loop start.
  function replaceInClip(notes, beats) {
    var c = detailClip();
    if (!c) return { ok: false, message: 'No MIDI clip is open. Open one in Detail View, then try again.' };
    var from = +one(c, 'loop_start') || 0;
    return undoable(function () {
      var span = Math.max(beats, (+one(c, 'loop_end') || 0) - from);
      c.call('remove_notes_extended', 0, 128, from, span);
      c.call('add_new_notes', liveNotes(notes.map(function (n) {
        return { start: n.start + from, len: n.len, pitch: n.pitch, vel: n.vel };
      })));
      if ((+one(c, 'loop_end') || 0) < from + beats) c.set('loop_end', from + beats);
      return { ok: true, message: 'Replaced the notes in “' + (String(one(c, 'name') || '') || 'the clip') + '”.' };
    });
  }

  // New notes in the Arrangement at the insert marker, on this device's track
  // (Track.create_midi_clip, Live 12.2 and later); further parts as above.
  function arrangementClip(notes, beats, name, more) {
    var track = thisTrack();
    if (!track) return { ok: false, message: 'This device needs to be on a MIDI track.' };
    var at = +one(api('live_set'), 'current_song_time') || 0;
    return undoable(function () {
      if (!arrangementClipOn(track, notes, beats, name, at)) {
        return { ok: false, message: 'This version of Live can\u2019t add Arrangement clips from a device. Choose New Clip instead.' };
      }
      var made = newTracks(track, more, function (t) { arrangementClipOn(t, this.notes, beats, this.name, at); });
      return { ok: true, message: 'Added a clip to the Arrangement at beat ' + (Math.round(at * 100) / 100 + 1) +
               (made ? ', and ' + made + ' on new tracks beside it.' : '.') };
    });
  }

  // ------------------------------------------------------------ player ---
  // Notes heard through this device's MIDI out: the instrument after it on
  // the track plays them. A Task ticks every few milliseconds and sends what
  // is due; nothing waits on the transport.
  function Player(send) {
    this.send = send; this.events = []; this.pos = 0; this.t0 = 0; this.task = null; this.sounding = {};
    this.onEnd = null;
  }
  Player.prototype.play = function (notes, tempo, onEnd) {
    this.stop();
    var ms = 60000 / (tempo || 120), ev = [];
    notes.forEach(function (n) {
      ev.push({ t: n.start * ms, on: true, pitch: n.pitch, vel: n.vel || 100 });
      ev.push({ t: (n.start + n.len) * ms - 1, on: false, pitch: n.pitch });
    });
    ev.sort(function (a, b) { return a.t - b.t || (a.on === b.on ? 0 : a.on ? 1 : -1); });
    this.events = ev; this.pos = 0; this.t0 = Date.now(); this.onEnd = onEnd || null;
    var self = this;
    this.task = new Task(function () { self.tick(); }, this);
    this.task.interval = 4;
    this.task.repeat();
    this.tick();
  };
  Player.prototype.tick = function () {
    var now = Date.now() - this.t0;
    while (this.pos < this.events.length && this.events[this.pos].t <= now) {
      var e = this.events[this.pos++];
      if (e.on) { this.sounding[e.pitch] = (this.sounding[e.pitch] || 0) + 1; this.send([0x90, e.pitch, Math.max(1, Math.min(127, Math.round(e.vel)))]); }
      else if (this.sounding[e.pitch]) { this.sounding[e.pitch]--; this.send([0x80, e.pitch, 0]); }
    }
    if (this.pos >= this.events.length) {
      var end = this.onEnd;
      this.stop();
      if (end) end();
    }
  };
  Player.prototype.playing = function () { return !!this.task; };
  Player.prototype.stop = function () {
    if (this.task) { this.task.cancel(); this.task.freepeer && this.task.freepeer(); this.task = null; }
    var self = this;
    Object.keys(this.sounding).forEach(function (p) {
      for (var i = 0; i < self.sounding[p]; i++) self.send([0x80, +p, 0]);
    });
    this.sounding = {};
    this.onEnd = null;
  };

  return { song: song, clipNotes: clipNotes, newClip: newClip, newTrackClip: newTrackClip, replaceInClip: replaceInClip,
           arrangementClip: arrangementClip, drumTrack: drumTrack, Player: Player, ROOTS: ROOTS, SCALE_NAMES: SCALE_NAMES,
           keyOf: keyOf };
})();


/* ---- ../kit/miditool.js ---- */
/* A family engine as a Live 12 MIDI Tool: in the clip view's Generate or
 * Transform panel, beside Live's own.
 *
 * Live hands the tool the clip's notes and a context (the time selection,
 * the clip's scale, the grid, a seed for this apply) through
 * [live.miditool.in]; [dict.join] makes them one dictionary, and this answers
 * at once with the notes to write, through [live.miditool.out]:
 *   - a Generator (DEVICE.tool 'generate') writes the chosen result into the
 *     time selection, repeated to fill it; Live adds it to what is there;
 *   - a Transformation ('transform') replaces the notes it was given: with a
 *     variation of them, or (DEVICE.beside) with them and a suggestion that
 *     goes with them.
 * The key is the clip's scale when the clip has one ScaleView knows, else the
 * tool's own Key and Scale. The engine is the repository's own Lua, run
 * unchanged by Middaw's Lua runtime, spoken to through Noterator's adapter,
 * exactly as in the MIDI effect (generator.js).
 *
 * Changing a setting asks Live for the notes again (a bang to
 * [live.miditool.in], a moment later: from inside an apply it would nest).
 *
 * Expects, before it: Palette, UI, Live, MiddawHost, and DEVICE = { generator,
 * tool, files }. Outlets: 0 the notes to [live.miditool.out], 1 the saved
 * state to [pattr], 2 a bang to [live.miditool.in].
 */
inlets = 1;
outlets = 3;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var H = MiddawHost;
H.init(function (p) { return DEVICE.files[p] === undefined ? null : DEVICE.files[p]; },
       function (s) { post(s + '\n'); });

function call(method, args) {
  var r = JSON.parse(H.call(method, args === undefined ? '' : JSON.stringify(args)));
  if (!r.ok) throw new Error(r.error);
  return r.value;
}

var GEN = null;
call('generators').forEach(function (g) { if (g.id === DEVICE.generator) GEN = g; });
var TRANSFORM = DEVICE.tool === 'transform';

var T = {
  session: call('newSession', { generator: DEVICE.generator }),
  key: { root: 1, scale: 1 },   // the tool's own, for a clip with no scale
  clipKey: null,                // the clip's, from the last apply
  song: { tempo: 120, num: 4, den: 4 },
  settings: [], results: [], pick: 1, part: 0, inst: 'pno', page: 0,
  input: null, applied: false, wrote: 0, status: '', warn: false, ready: false, pending: null
};

function say(msg, warn) { T.status = msg || ''; T.warn = !!warn; }
function keyName(k) { return Live.ROOTS[k.root - 1] + ' ' + Live.SCALE_NAMES[k.scale - 1]; }
function barBeats() { return T.song.num * 4 / T.song.den; }
function key() { return T.clipKey || T.key; }

function context() {
  var sel = T.input || { notes: [], beats: 0 };
  var k = key();
  return { root: k.root, scale: k.scale, num: T.song.num, den: T.song.den, barBeats: barBeats(), bpm: T.song.tempo,
           inst: T.inst, catalogueId: T.inst, bars: 4,
           selection: { notes: sel.notes, beats: sel.beats, drums: false } };
}

// The settings a tool shows: which result, the engine's own, then the parts
// and the instrument where the engine has them, then the key (only when the
// clip has none of its own, or it would be a control that does nothing).
var OWN_KEY = { root: 1, scale: 1, key: 1 };
var EXTRA = { asax: 1, tsax: 1, bsax: 1, vib: 1, sop: 1, alto: 1, ten: 1, bass: 1, gtr: 1, ebass: 1, ubass: 1, synth: 1, kit: 1 };
var INSTRUMENTS = DEVICE.instrument ? call('instruments').filter(function (i) { return !EXTRA[i.id]; }) : [];
function partNames() {
  var most = [];
  T.results.forEach(function (r) { if (r.parts.length > most.length) most = r.parts; });
  return most.length > 1 ? ['All Parts'].concat(most.map(function (p, i) { return p.name || ('Part ' + (i + 1)); })) : null;
}
function rows() {
  var out = [];
  // DEVICE.short: a result is named by what comes before its first wide gap
  // (Starting Blocks' numeral: "IV  C Major IV Chord Triad" is IV).
  var names = T.results.length ? T.results.map(function (r, i) {
    var t = r.title || String(i + 1);
    return DEVICE.short ? t.split('  ')[0] : t;
  }) : ['1'];
  if (T.pick > names.length) T.pick = 1;
  out.push({ id: '$pick', label: DEVICE.result || 'Result', names: names, index: T.pick });
  if (INSTRUMENTS.length) {
    var at = 0;
    INSTRUMENTS.forEach(function (x, i) { if (x.id === T.inst) at = i; });
    out.push({ id: '$inst', label: 'Instrument', names: INSTRUMENTS.map(function (x) { return x.name; }), index: at + 1 });
  }
  T.settings.forEach(function (s) { out.push(s); });
  var parts = partNames();
  if (parts) {
    if (T.part >= parts.length) T.part = 0;
    out.push({ id: '$part', label: 'Part', names: parts, index: T.part + 1 });
  }
  if (!DEVICE.keyless && !T.clipKey) {
    out.push({ id: '$root', label: 'Key', names: Live.ROOTS, index: T.key.root });
    out.push({ id: '$scale', label: 'Scale', names: Live.SCALE_NAMES, index: T.key.scale });
  }
  return out;
}

function refresh() {
  call('useKey', { session: T.session, key: key() });
  T.settings = call('settings', { session: T.session, context: context() }).filter(function (s) { return !OWN_KEY[s.id]; });
}

// Before Live has asked for anything, a generator lists what it would write
// in the tool's own key, so Result names something.
function preview() {
  if (TRANSFORM || T.applied) return;
  T.results = call('generate', { session: T.session, context: context(), seed: 1, count: 8 }).results || [];
}

function readSong() {
  try { var s = Live.song(); T.song = { tempo: s.tempo, num: s.num, den: s.den }; } catch (e) { /* not in Live */ }
}

// ------------------------------------------------------------ the apply --
// Live's notes (start_time, duration...) as the engines' (start, len...),
// from the start of what the tool was given.
function fromLive(notes, base) {
  return notes.filter(function (n) { return !+n.mute; }).map(function (n) {
    return { start: +n.start_time - base, len: +n.duration, pitch: +n.pitch, vel: Math.round(+n.velocity || 100) };
  }).sort(function (a, b) { return a.start - b.start || a.pitch - b.pitch; });
}
function toLive(n, base) {
  return { pitch: Math.max(0, Math.min(127, Math.round(n.pitch))), start_time: base + n.start,
           duration: Math.max(1 / 64, n.len), velocity: Math.max(1, Math.min(127, Math.round(n.vel || 100))) };
}
// Where the tool writes: the time selection, else (a transformation) the
// bars the notes it was given cover, else (a generator) four bars.
function span(d, notes) {
  var c = d.clip || d;
  var a = +c.time_selection_start, b = +c.time_selection_end;
  if (b > a) return { base: a, beats: b - a };
  var bar = barBeats();
  if (!TRANSFORM || !notes.length) return { base: a > 0 ? a : 0, beats: bar * 4 };
  var lo = Infinity, hi = 0;
  notes.forEach(function (n) { lo = Math.min(lo, +n.start_time); hi = Math.max(hi, +n.start_time + +n.duration); });
  var base = Math.floor(lo / bar) * bar;
  return { base: base, beats: Math.max(bar, Math.ceil((hi - base) / bar) * bar) };
}
function clipScale(d) {
  var s = d.scale || {};
  var on = Array.isArray(s.scale_mode) ? s.scale_mode[0] : s.scale_mode;
  return +on ? Live.keyOf(s.root_note, s.scale_name) : null;
}
function chosen() {
  var r = T.results[T.pick - 1];
  if (!r) return null;
  var parts = T.part > 0 && r.parts[T.part - 1] ? [r.parts[T.part - 1]] : r.parts;
  var all = [];
  parts.forEach(function (p) { p.notes.forEach(function (n) { all.push(n); }); });
  return { notes: all, beats: r.beats || 4, title: r.title || GEN.name };
}

// What the tool writes for one apply. Returns Live's notes.
function compute(d) {
  readSong();
  var given = (d.notes || []).slice();
  var at = span(d, given);
  var ck = clipScale(d);
  T.clipKey = ck;
  T.input = TRANSFORM ? { notes: fromLive(given, at.base), beats: at.beats } : { notes: [], beats: at.beats };
  var keep = TRANSFORM ? given : [];   // what a transformation leaves if it has nothing to say
  if (TRANSFORM && !T.input.notes.length) { say('Select notes to change first.'); return keep; }
  var seed = 1 + Math.abs(Math.round(+d.seed || 0)) % 99999;
  refresh();
  var r = call('generate', { session: T.session, context: context(), seed: seed, count: 8 });
  T.results = r.results || [];
  var c = chosen();
  if (!c || !c.notes.length) { say(r.message || 'Nothing fits these settings. Change one, then try again.', !r.message); return keep; }
  var out = [];
  if (TRANSFORM) {
    // A variation replaces what it was given; a suggestion goes with it.
    if (DEVICE.beside) given.forEach(function (n) { out.push(n); });
    c.notes.forEach(function (n) {
      if (n.start < at.beats) out.push(toLive({ start: n.start, len: Math.min(n.len, at.beats - n.start), pitch: n.pitch, vel: n.vel }, at.base));
    });
  } else {
    // A block fills the time selection, repeated as a pattern is.
    var len = c.beats > 0 ? c.beats : at.beats;
    for (var k = 0; k * len < at.beats; k++) {
      c.notes.forEach(function (n) {
        var st = k * len + n.start;
        if (st < at.beats - 1e-9) out.push(toLive({ start: st, len: Math.min(n.len, at.beats - st), pitch: n.pitch, vel: n.vel }, at.base));
      });
    }
  }
  T.wrote = out.length - (DEVICE.beside ? given.length : 0);
  say(c.title);
  return out;
}

function send(notes) {
  var body = { notes: notes };
  if (typeof outlet_dictionary === 'function') { outlet_dictionary(0, body); return; }
  var dct = new Dict();
  dct.parse(JSON.stringify(body));
  outlet(0, 'dictionary', dct.name);
}

// The joined notes and context. v8 hands a dictionary to msg_dictionary as an
// object when the function exists; dictionary(name) is the older route.
function msg_dictionary(d) { applyFrom(d); }
function dictionary(name) {
  var d = null;
  try { d = JSON.parse(new Dict(String(name)).stringify()); } catch (e) { d = null; }
  if (d) applyFrom(d);
}
function applyFrom(d) {
  var notes;
  try { notes = compute(d); } catch (e) { say(String(e.message || e), true); notes = TRANSFORM ? (d.notes || []) : []; }
  T.applied = true;
  send(notes);
  mgraphics.redraw();
}

// Ask Live to apply again, after this message is done.
var again = new Task(function () { outlet(2, 'bang'); });
function reapply() { if (T.applied) again.schedule(1); }

// ------------------------------------------------------------ messages --
function bang() {
  T.ready = true;
  if (T.pending) { restoreFrom(T.pending); T.pending = null; }
  readSong();
  try { refresh(); preview(); }
  catch (e) { say(String(e.message || e), true); }
  if (!T.status) say(TRANSFORM ? 'Select notes, then Transform.' : 'Choose, then click Generate.');
  mgraphics.redraw();
}
function save() {
  outlet(1, 'set', JSON.stringify({ v: 1, st: call('snapshot', { session: T.session }), key: T.key,
                                    pick: T.pick, part: T.part, inst: T.inst }));
}
function restore(text) {
  var st = null;
  try { st = JSON.parse(String(text)); } catch (e) { return; }
  if (!T.ready) { T.pending = st; return; }
  restoreFrom(st);
  mgraphics.redraw();
}
function restoreFrom(st) {
  if (!st || st.v !== 1) return;
  if (st.st) call('restore', { session: T.session, state: st.st });
  if (st.key) T.key = st.key;
  T.pick = st.pick || 1;
  T.part = st.part || 0;
  if (st.inst) T.inst = st.inst;
  refresh();
  preview();
}
function choose(id, index) {
  if (id === '$pick') T.pick = index;
  else if (id === '$part') T.part = index - 1;
  else if (id === '$inst') T.inst = INSTRUMENTS[index - 1].id;
  else if (id === '$root') T.key = { root: index, scale: T.key.scale };
  else if (id === '$scale') T.key = { root: T.key.root, scale: index };
  else call('set', { session: T.session, setting: id, index: index, context: context() });
  try {
    refresh();
    preview();
  } catch (e) { say(String(e.message || e), true); }
  save();
  reapply();
  mgraphics.redraw();
}

// --------------------------------------------------------------- paint --
var ROW_H = 17, GAP = 1, TOP = 16;
function size() {
  var r = (typeof box !== 'undefined' && box.rect) ? box.rect : [0, 0, 152, 147];
  return [r[2] - r[0], r[3] - r[1]];
}
function paint() {
  var g = mgraphics, sz = size(), W = sz[0], Ht = sz[1];
  UI.begin(g);
  UI.rect(0, 0, W, Ht, UI.C.ground);
  UI.text(T.status || GEN.name, 3, 0, W - 6, TOP - 2, T.warn ? UI.C.warnText : UI.C.dim, 9, 0);
  var all = rows();
  var per = Math.max(1, Math.floor((Ht - TOP - ROW_H - GAP) / (ROW_H + GAP)));
  if (all.length <= per + 1) per = all.length;
  var pages = Math.max(1, Math.ceil(all.length / per));
  if (T.page >= pages) T.page = 0;
  all.slice(T.page * per, (T.page + 1) * per).forEach(function (s, i) {
    UI.row(s.label, s.names, s.index, 2, TOP + i * (ROW_H + GAP), W - 4, ROW_H, function (k) { choose(s.id, k); });
  });
  if (pages > 1) {
    var y = Ht - ROW_H - 1, bw = 22;
    UI.button('‹', 2, y, bw, ROW_H, false, function () { T.page = (T.page + pages - 1) % pages; mgraphics.redraw(); });
    UI.text('Settings ' + (T.page + 1) + ' of ' + pages, 2 + bw, y, W - 4 - 2 * bw, ROW_H, UI.C.dim, 9, 1);
    UI.button('›', W - 2 - bw, y, bw, ROW_H, false, function () { T.page = (T.page + 1) % pages; mgraphics.redraw(); });
  }
}
function onclick(x, y) { if (UI.click(x, y)) mgraphics.redraw(); }
function ondrag(x, y, but) { UI.dragTo(x, y, !!but); }

