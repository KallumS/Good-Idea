--[[
 * ReaScript Name: Good Idea
 * Description:    Ideas for starting a track - a motif, a phrase, a full
 *                 measure of music or a drum groove - made from the maths
 *                 of music, and put into the project as MIDI.
 *
 * About:          Choose Motif, Phrase, Measure or Drums and press New Idea. Each
 *                 idea is calculated from your settings and an idea number -
 *                 rhythms from the metric grid and Euclidean spreads, chords
 *                 from the tonic-subdominant-dominant cycle, melodies walking
 *                 a contour on the chords - so the same number always gives
 *                 the same idea. Leave any setting on Any to have it rolled.
 *                 Insert it at the edit cursor, write it out as a .mid, or
 *                 audition it.
 *
 *                 Needs ReaImGui, from the ReaTeam Extensions repository.
 * Author:         Kallum Shah
 * Links:          https://github.com/KallumS/Good-Idea
 * Version:        1.16
 * Provides:
 *   gi_theory.lua
 *   gi_idea.lua
 *   gi_midi.lua
 *   gi_place.lua
--]]

local TITLE   = "Good Idea"
local SECTION = "GoodIdea"

------------------------------------------------------------------------------
-- Dependencies
------------------------------------------------------------------------------

local imgui_path = reaper.ImGui_GetBuiltinPath and
                   (reaper.ImGui_GetBuiltinPath() .. "/imgui.lua")
if not imgui_path then
  reaper.MB("Good Idea needs the ReaImGui extension.\n\n" ..
            "Install it with ReaPack, from the ReaTeam Extensions repository.",
            "Missing dependency", 0)
  return
end
local ImGui = dofile(imgui_path)("0.9")

local HERE  = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
local T     = dofile(HERE .. "gi_theory.lua")
local I     = dofile(HERE .. "gi_idea.lua").init(T)
local Midi  = dofile(HERE .. "gi_midi.lua")
local Place = dofile(HERE .. "gi_place.lua")
Place.setMidi(Midi)

------------------------------------------------------------------------------
-- Look
--
-- The house scheme, the same as Starting Blocks, Midi Suggester, Midi
-- Variator and Midi Catalogue: a dark cool-grey ground, a light grey for the
-- controls raised off it, and one yellow for whatever is switched on.
-- docs/COLOUR.md has it all.
--
-- **Every grey here is blue-shifted** - R < G < B, all the way down the ramp.
-- A neutral grey looks correct in a diff and only reads as flat next to the
-- yellow.
------------------------------------------------------------------------------

local THEME = {
  { "Col_Text",              0xDDE1E7FF },
  { "Col_TextDisabled",      0x8A919CFF },
  { "Col_WindowBg",          0x23272EFF },   -- the chrome: dark grey, cool
  { "Col_PopupBg",           0x1B1F25FF },
  { "Col_Border",            0x14171CFF },
  { "Col_FrameBg",           0x1A1D23FF },
  { "Col_FrameBgHovered",    0x22262DFF },
  { "Col_FrameBgActive",     0x2A2F37FF },
  { "Col_TitleBg",           0x1B1F25FF },
  { "Col_TitleBgActive",     0x23272EFF },
  { "Col_TitleBgCollapsed",  0x1B1F25FF },
  { "Col_Button",            0xA9AFBAFF },   -- the controls: light grey, raised
  { "Col_ButtonHovered",     0xC0C6CFFF },
  { "Col_ButtonActive",      0x8F96A2FF },
  { "Col_CheckMark",         0xFFF200FF },
  { "Col_SliderGrab",        0xA9AFBAFF },
  { "Col_SliderGrabActive",  0xFFF200FF },
  { "Col_Separator",         0x3A404AFF },
  { "Col_ScrollbarBg",       0x1A1D23FF },
  { "Col_ScrollbarGrab",     0x585F6BFF },
  { "Col_ScrollbarGrabHovered", 0x6D7581FF },
  { "Col_ScrollbarGrabActive",  0xA9AFBAFF },
}

local SELECTED  = 0xFFF200FF   -- the accent: what is switched on, and the tune
local INK       = 0x14171CFF   -- the text on every button, grey or yellow
local STEP      = 0xBFC5CEFF   -- the step numbers: neutral
local NOTE_COL  = SELECTED     -- the melody in the roll
local PART_COL  = 0xA9AFBAFF   -- chords and bass in the roll: the controls' grey
local ROLL_BG   = 0x111419FF
local ROLL_BAR  = 0x3A404AFF
local ROLL_BEAT = 0x1E2228FF
local PLAYHEAD  = 0xF2F4F7FF
local DIM       = 0x8A919CFF
local WARN      = 0xD2483FFF

-- Shifts a colour towards white or black, so the chosen state needs one colour
-- rather than three. Arithmetic rather than bit operators, and it keeps the
-- alpha byte, or ReaImGui is handed a fully transparent colour.
local function shade(col, amount)
  local a = col % 256
  local b = math.floor(col / 256) % 256
  local g = math.floor(col / 65536) % 256
  local r = math.floor(col / 16777216) % 256
  local function mix(c)
    if amount >= 0 then return math.floor(c + (255 - c) * amount + 0.5) end
    return math.floor(c * (1 + amount) + 0.5)
  end
  return mix(r) * 16777216 + mix(g) * 65536 + mix(b) * 256 + a
end

------------------------------------------------------------------------------
-- State
------------------------------------------------------------------------------

local st = I.newState()
local ui = {
  loop = false, status = "", warn = false,
  idea = nil, meter = nil, sig = "",
  dirty = true, playhead = nil, playNext = false,
  history = {}, at = 0,     -- the ideas made this session, and where we are in them
  open = {},                -- which folded steps are open: the view, not saved
}

local ctx

local function touched() ui.dirty = true end
local function say(text, warn) ui.status, ui.warn = text, warn or false end

-- The idea for the settings and the idea number. Made when something
-- changes, never per frame.
local function rebuild()
  I.clampState(st)
  local num, den = Place.timeSigNow()
  ui.sig = num .. "/" .. den
  ui.meter = I.meter(num, den)
  ui.idea = I.make(st, ui.meter, st.seed)
  ui.dirty = false
  if ui.playNext then
    ui.playNext = false
    Place.previewStart(ui.idea.block, Place.tempo())
  end
end

-- The idea number for New Idea: from the clock, never the one showing.
local function newSeed()
  local s = (math.floor(os.time()) * 7 + math.floor(os.clock() * 1000) + st.seed * 31) % I.MAX_SEED + 1
  if s == st.seed then s = s % I.MAX_SEED + 1 end
  return s
end

local function go(seed, remember)
  st.seed = seed
  if remember then
    -- Like a browser: a new idea after going back drops the ones ahead.
    for i = #ui.history, ui.at + 1, -1 do ui.history[i] = nil end
    ui.history[#ui.history + 1] = seed
    ui.at = #ui.history
  end
  if st.autoplay == 1 then ui.playNext = true end
  touched()
end

------------------------------------------------------------------------------
-- Settings that outlive the window
------------------------------------------------------------------------------

local SAVED = { "seed", "autoplay", "swing" }
for _, s in ipairs(I.SETTINGS) do SAVED[#SAVED + 1] = s.id end

local function saveState()
  local out = {}
  for _, k in ipairs(SAVED) do out[#out + 1] = k .. "=" .. tostring(st[k]) end
  reaper.SetExtState(SECTION, "state", table.concat(out, ";"), true)
end

local function loadState()
  local blob = reaper.GetExtState(SECTION, "state")
  if not blob or blob == "" then return end
  local got = {}
  for pair in blob:gmatch("[^;]+") do
    local k, v = pair:match("^(%w+)=(.*)$")
    if k then got[k] = v end
  end
  -- Numbers come back as numbers (bars, the key, the idea number); names
  -- stay names.
  for _, k in ipairs(SAVED) do
    if got[k] then st[k] = tonumber(got[k]) or got[k] end
  end
  I.clampState(st)
end

------------------------------------------------------------------------------
-- Widgets
------------------------------------------------------------------------------

local function pushTheme()
  for _, c in ipairs(THEME) do ImGui.PushStyleColor(ctx, ImGui[c[1]], c[2]) end
end
local function popTheme() ImGui.PopStyleColor(ctx, #THEME) end

-- An unchosen button wears the theme's grey, a chosen one the accent. Either
-- way the text on it goes to INK: both are far lighter than the chrome.
local function pick(label, selected, width, height)
  local pushed = 1
  if selected then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, SELECTED)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, shade(SELECTED, 0.18))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, shade(SELECTED, -0.18))
    pushed = 4
  end
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, INK)
  local hit = ImGui.Button(ctx, label, width or 0, height or 0)
  ImGui.PopStyleColor(ctx, pushed)
  return hit
end

local function heading(n, text)
  if n then
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, STEP)
    ImGui.Text(ctx, tostring(n))
    ImGui.PopStyleColor(ctx, 1)
    ImGui.SameLine(ctx, 0, 10)
  end
  ImGui.SeparatorText(ctx, text)
end

-- The space between one numbered step and the next. A gap, not an arrow.
local STEP_GAP = 6
local function stepGap() ImGui.Dummy(ctx, 16, STEP_GAP) end

local function tip(text)
  if text and ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, text) end
end

local function dim(text)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, DIM)
  ImGui.Text(ctx, text)
  ImGui.PopStyleColor(ctx, 1)
end

local function dimWrapped(text)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, DIM)
  ImGui.TextWrapped(ctx, text)
  ImGui.PopStyleColor(ctx, 1)
end

-- A row of choices that wraps where the window does. `label` and `hint` name
-- each item; returns the index clicked, or nil.
local PAD = 18
local function flow(id, items, isChosen, label, hint, minWidth)
  local chosen
  local avail = select(1, ImGui.GetContentRegionAvail(ctx))
  local x = 0
  ImGui.PushID(ctx, id)
  for i, item in ipairs(items) do
    local text = label and label(item, i) or tostring(item)
    local w = math.max(minWidth or 0, select(1, ImGui.CalcTextSize(ctx, text)) + PAD)
    if i > 1 then
      if x + 8 + w <= avail then ImGui.SameLine(ctx); x = x + 8 else x = 0 end
    end
    x = x + w
    ImGui.PushID(ctx, i)
    if pick(text, isChosen(item, i), w) then chosen = i end
    if hint then tip(hint(item, i)) end
    ImGui.PopID(ctx)
  end
  ImGui.PopID(ctx)
  return chosen
end

-- What a setting's button says when hovered. "Any" says what it rolled for
-- the idea showing.
local function hintFor(s, v)
  if v == "Any" then
    local rolled = ui.idea and ui.idea.r[s.id]
    return "Left to chance: rolled again for every idea." ..
           (rolled ~= nil and ("\nThis idea rolled: " .. I.valueName(s, rolled)) or "")
  end
  return s.hints and s.hints[v] or nil
end

-- One or more settings on a line, each a dim label and its buttons. A setting
-- that means nothing for what is chosen is not drawn at all.
local function settingRow(ids, minWidth)
  local first = true
  for _, id in ipairs(ids) do
    local s = I.BY_ID[id]
    if I.shows(s, st) then
      if not first then ImGui.SameLine(ctx, 0, 24) end
      first = false
      dim(s.label)
      ImGui.SameLine(ctx)
      local items = {}
      if s.any then items[1] = "Any" end
      for _, v in ipairs(s.values) do items[#items + 1] = v end
      local c = flow(id, items, function(x) return st[id] == x end,
                     function(x) return I.valueName(s, x) end,
                     function(x) return hintFor(s, x) end, minWidth or 44)
      if c then st[id] = items[c]; touched() end
    end
  end
end

------------------------------------------------------------------------------
-- The preview roll
--
-- The tune in the accent, the chords and bass in the controls' grey; a drum
-- idea in lanes.
------------------------------------------------------------------------------

local function pianoRoll(block, width, height, playhead)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x, y = ImGui.GetCursorScreenPos(ctx)
  ImGui.InvisibleButton(ctx, "##roll", width, height)

  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, ROLL_BG, 3)
  if not block or #block.notes == 0 then return end

  local beats = math.max(block.beats, 1e-9)
  local bar = math.max(ui.meter and ui.meter.barBeats or 4, 1e-9)
  local beat = ui.meter and (ui.meter.beat / 4) or 1
  local b = 0
  while b <= beats + 1e-9 do
    local gx = x + width * (b / beats)
    local onBar = math.abs(b / bar - math.floor(b / bar + 0.5)) < 1e-6
    ImGui.DrawList_AddLine(dl, gx, y, gx, y + height, onBar and ROLL_BAR or ROLL_BEAT, 1)
    b = b + beat
  end

  local drums = false
  local lo, hi = 200, -1
  for _, p in ipairs(block.parts) do
    if p.drums then drums = #p.notes > 0
    else for _, n in ipairs(p.notes) do lo, hi = math.min(lo, n.pitch), math.max(hi, n.pitch) end end
  end
  -- A drum idea has nothing else to show, so its drums fill the roll, a
  -- lane for each drum, in the accent: they are the idea.
  if drums and hi < lo then
    local lanes, order = {}, {}
    for _, p in ipairs(block.parts) do
      for _, n in ipairs(p.notes) do
        if not lanes[n.pitch] then lanes[n.pitch] = true; order[#order + 1] = n.pitch end
      end
    end
    table.sort(order)
    local row = {}
    for i, pitch in ipairs(order) do row[pitch] = i end
    local laneh = height / #order
    for _, p in ipairs(block.parts) do
      for _, n in ipairs(p.notes) do
        local nx = x + width * (n.start / beats)
        local ny = y + height - row[n.pitch] * laneh
        ImGui.DrawList_AddRectFilled(dl, nx, ny + 1, nx + math.max(3, width * (n.len / beats) - 1),
                                     ny + math.max(2, laneh - 1), NOTE_COL, 1)
      end
    end
  end
  local tonal = height
  if hi >= lo then
    -- A repeated single note would fill the whole box, so always show at
    -- least an octave of context around it.
    if hi - lo < 11 then
      lo = math.max(0, math.floor((lo + hi) / 2) - 6)
      hi = lo + 12
    end
    local rowh = tonal / (hi - lo + 1)
    for _, p in ipairs(block.parts) do
      if not p.drums then
        local col = (p.name == "Melody") and NOTE_COL or PART_COL
        for _, n in ipairs(p.notes) do
          local nx = x + width * (n.start / beats)
          local nw = math.max(2, width * (n.len / beats) - 1)
          local ny = y + tonal - (n.pitch - lo + 1) * rowh
          ImGui.DrawList_AddRectFilled(dl, nx, ny, nx + nw, ny + math.max(2, rowh - 1), col, 1)
        end
      end
    end
  end
  if playhead then
    local px = x + width * math.min(1, playhead)
    ImGui.DrawList_AddLine(dl, px, y, px, y + height, PLAYHEAD, 2)
  end
end

------------------------------------------------------------------------------
-- The steps
------------------------------------------------------------------------------

-- What a folded step has chosen, on one dim line: "pace Any  /  groove
-- Syncopated  /  ...". Only the settings that show.
local function summaryOf(ids)
  local out = {}
  for _, id in ipairs(ids) do
    local s = I.BY_ID[id]
    if I.shows(s, st) then out[#out + 1] = s.label:lower() .. " " .. I.valueName(s, st[id]) end
  end
  return table.concat(out, "  /  ")
end

-- A step that folds away: its number, then a button with its name that opens
-- and closes it. Closed, a dim line says what is chosen in it; open, its
-- rows. Small until asked, like Midi Catalogue's chords and instruments.
local function fold(n, name, summary, draw)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, STEP)
  ImGui.Text(ctx, tostring(n))
  ImGui.PopStyleColor(ctx, 1)
  ImGui.SameLine(ctx, 0, 10)
  local isOpen = ui.open[name]
  ImGui.PushID(ctx, "open:" .. name)
  if pick(name .. (isOpen and "  -" or "  +"), false, 128) then
    isOpen = not isOpen
    ui.open[name] = isOpen
  end
  ImGui.PopID(ctx)
  tip(isOpen and "Fold this step away" or "Open this step")
  if isOpen then
    draw()
  else
    ImGui.SameLine(ctx, 0, 14)
    dim(summary)
  end
end

local function drawIdea(n)
  heading(n, "Idea")
  settingRow({ "kind" }, 84)
  ImGui.SameLine(ctx, 0, 24)
  settingRow({ I.barsSetting(st.kind) }, st.kind == "Drums" and 30 or 52)
  settingRow({ "content" }, 64)
end

local function drawKey(n)
  local key = ui.idea and ui.idea.key or T.key(1, 1)
  local rootName = (st.root == "Any") and "any key" or T.ROOTS[st.root].name
  local scaleName = (st.scale == "Any") and "any scale" or T.SCALES[st.scale].name
  local rolled = ui.idea and (ui.idea.r.rolled.root or ui.idea.r.rolled.scale)
  local summary = rootName .. " " .. scaleName .. (rolled and ("  (this idea: " .. I.keyName(key) .. ")") or "")
  if I.shows(I.BY_ID.borrowed, st) then summary = summary .. "  /  borrowed " .. st.borrowed end
  if I.shows(I.BY_ID.applied, st) then summary = summary .. "  /  applied " .. st.applied end
  fold(n, "Key", summary, function()
    settingRow({ "root" }, 36)
    settingRow({ "scale" }, 84)
    local names = {}
    for d = 0, T.scaleLen(key) - 1 do names[#names + 1] = T.noteName(key, d) end
    dim((rolled and ("This idea: " .. I.keyName(key) .. "  -  ") or "") .. table.concat(names, "  "))
    settingRow({ "borrowed" }, 52)
    settingRow({ "applied" }, 52)
  end)
end

local function drawSwing()
  dim("Swing")
  ImGui.SameLine(ctx)
  -- Swing stretches the eighths inside a quarter-note beat; a metre without
  -- one has nothing to swing, so it says so instead of offering a slider
  -- that would do nothing.
  if ui.meter and I.swings(ui.meter) then
    ImGui.SetNextItemWidth(ctx, 240)
    local changed, v = ImGui.SliderInt(ctx, "##swing", st.swing, 0, 100, "%d%%")
    if changed and v then
      st.swing = math.max(0, math.min(100, math.floor(v)))
      touched()
    end
    tip("0 is straight. 100 is a full triplet swing: the off-beat eighth lands two thirds of the way " ..
        "through the beat. Every part swings, and what is inserted and exported swings too.")
  elseif ui.meter and ui.meter.beat == 6 then
    dim(("none in %s: it is in threes already"):format(ui.sig))
  else
    dim(("none in %s: there are no quarter-note beats to swing"):format(ui.sig))
  end
end

local FEEL = { "pace", "groove", "figures", "push", "pull" }

local function drawFeel(n)
  local swing = (ui.meter and I.swings(ui.meter)) and ("  /  swing " .. st.swing .. "%") or ""
  fold(n, "Feel", summaryOf(FEEL) .. swing, function()
    settingRow({ "pace", "groove" }, 60)
    settingRow({ "figures" }, 60)
    settingRow({ "push", "pull" }, 52)
    drawSwing()
  end)
end

local function drawMelody(n)
  fold(n, "Melody", summaryOf({ "contour", "register", "tension", "secondVoice" }), function()
    settingRow({ "contour", "register" }, 56)
    settingRow({ "tension", "secondVoice" }, 84)
  end)
end

local function drawChords(n)
  -- (The progression and the part-writing are the engine's to decide, 1.13:
  -- not shown.)
  fold(n, "Chords", summaryOf({ "colour", "flavours", "chordPace", "chordStyle", "voicing", "inversions" }), function()
    settingRow({ "colour", "flavours" }, 60)
    settingRow({ "chordPace" }, 60)
    settingRow({ "chordStyle" }, 60)
    settingRow({ "voicing" }, 60)
    settingRow({ "inversions" }, 60)
  end)
end
local function drawArrangement(n)
  -- (The form is rolled for every idea, 1.13: not shown.)
  fold(n, "Arrangement", summaryOf({ "bass", "keyChange" }), function()
    settingRow({ "bass" }, 60)
    settingRow({ "keyChange" }, 84)
  end)
end

local function drawDrums(n)
  fold(n, "Drums", summaryOf({ "beat", "fills", "cymbal", "ghosts" }), function()
    settingRow({ "beat" }, 60)
    settingRow({ "fills" }, 60)
    settingRow({ "cymbal" }, 52)
    settingRow({ "ghosts" }, 52)
  end)
end

local function drawNew()
  ImGui.Dummy(ctx, 0, 4)
  if pick("New Idea", false, 160, 34) then go(newSeed(), true) end
  tip("A new idea of the kind chosen, with every Any rolled again")
  ImGui.SameLine(ctx, 0, 16)
  if ui.at > 1 then
    if pick("<", false, 30, 34) then ui.at = ui.at - 1; go(ui.history[ui.at], false) end
    tip("Back to the idea before")
    ImGui.SameLine(ctx)
  end
  if ui.at < #ui.history then
    if pick(">", false, 30, 34) then ui.at = ui.at + 1; go(ui.history[ui.at], false) end
    tip("Forward again")
    ImGui.SameLine(ctx)
  end
  ImGui.SameLine(ctx, 0, 16)
  dim("Idea number")
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 110)
  local changed, v = ImGui.InputInt(ctx, "##seed", st.seed, 1, 100)
  if changed and v then
    st.seed = math.max(1, math.min(I.MAX_SEED, math.floor(v)))
    touched()
  end
  tip("Every idea has a number. The same number with the same settings is always the same idea - "
      .. "write one down to come back to it, or change a setting to hear the same idea another way.")
  ImGui.SameLine(ctx, 0, 16)
  if pick("Keep", false, 60) then
    I.keep(st, ui.idea)
    touched()
    say("Kept: every Any is now what this idea rolled")
  end
  tip("Turns every Any above into what this idea rolled, so the next New Idea keeps the "
      .. "key, length and feel and changes only the music.")
  ImGui.SameLine(ctx, 0, 16)
  local _, play = ImGui.Checkbox(ctx, "Play new ideas", st.autoplay == 1)
  st.autoplay = play and 1 or 0
  tip("Audition each new idea as soon as it is made")
end

local function drawResult()
  local idea = ui.idea
  local block = idea and idea.block
  ImGui.Dummy(ctx, 0, 6)
  heading(nil, block and block.name or "")

  local w = select(1, ImGui.GetContentRegionAvail(ctx))
  pianoRoll(block, math.max(120, w), 130, Place.previewRunning() and ui.playhead or nil)

  if idea then
    dimWrapped(idea.summary)
    local marks = {}
    if idea.chords:find("^", 1, true) then marks[#marks + 1] = "^ pushed an eighth early" end
    if idea.chords:find("_", 1, true) then marks[#marks + 1] = "_ pulled an eighth late" end
    if idea.chords:find("*", 1, true) then marks[#marks + 1] = "* from outside the key" end
    if idea.chords:find(">", 1, true) then marks[#marks + 1] = "> applied" end
    if idea.chords ~= "" then
      dimWrapped((idea.r.chords and "Chords  " or "Under the tune  ") .. idea.chords ..
                 (#marks > 0 and ("   (" .. table.concat(marks, ", ") .. ")") or ""))
    end
    -- A borrowed chord is said in full, in the body text rather than the
    -- dim, so it is noticed: which chord, where, and from which scale.
    for _, b in ipairs(idea.borrowed) do
      ImGui.TextWrapped(ctx, "Borrowed chord: " .. b.text)
      tip("A chord from another scale on the same key note. While it sounds, the tune and the bass " ..
          "use that scale's notes, the way a player bends to a borrowed chord.")
    end
    -- (1.15) And a chromatic chord before a close's V.
    for _, c in ipairs(idea.chromatic or {}) do
      ImGui.TextWrapped(ctx, "Chromatic chord: " .. c.text)
      tip("A chord from outside the key that leads to the V: the Neapolitan (the major chord on the flat 2nd, " ..
          "over its third) or an augmented sixth (le in the bass, fi above it, both moving out to sol).")
    end
    -- So is an applied chord: which, where, and the chord it leads to.
    for _, a in ipairs(idea.applied or {}) do
      ImGui.TextWrapped(ctx, "Applied chord: " .. a.text)
      tip("The next chord's own dominant (or leading-tone chord), borrowed from the key that chord " ..
          "is home in. While it sounds, the tune bends with it.")
    end
    -- And a key change: where, and to what.
    if idea.keyChange then
      ImGui.TextWrapped(ctx, "Key change: " .. idea.keyChange.text)
      tip("The last section, tune, chords and bass, in a key a step higher - the pop key change.")
    end
    local parts = {}
    for _, p in ipairs(block.parts) do parts[#parts + 1] = p.name end
    if idea.plan.shape ~= "" then
      dim(("Shape  %s, %s  /  %d notes  /  %s  /  %s, %g bpm"):format(idea.plan.shape, idea.ending,
        #block.notes, table.concat(parts, ", "), ui.sig, Place.tempo()))
    else
      dim(("%s  /  %d notes  /  %s, %g bpm"):format(idea.ending, #block.notes, ui.sig, Place.tempo()))
    end
  end
end

local function drawActions()
  local block = ui.idea and ui.idea.block
  ImGui.Dummy(ctx, 0, 4)
  -- How it goes out: the velocity, and for a Measure whether it lands as a
  -- track per part or one item - beside the buttons that send it.
  settingRow({ "velocity", "layout" }, 64)
  ImGui.Dummy(ctx, 0, 2)
  if not block then return end

  local many = block.layout == "tracks" and #block.parts > 1
  if pick(many and "Insert on new tracks" or "Insert at cursor", false, 170) then
    local res = Place.insert(block)
    if res == Place.OK then say(many and ("Inserted " .. #block.parts .. " tracks at the edit cursor")
                                      or "Inserted at the edit cursor")
    elseif res == Place.NOTHING then say("Nothing to insert", true)
    else say("No track selected", true) end
  end
  tip(many and "One new track per part - Melody, Chords, Bass - under the selected track"
           or "As one item on the selected track, at the edit cursor")

  ImGui.SameLine(ctx)
  if pick("Export .mid", false, 120) then
    local res, path = Place.export(block)
    if res == Place.OK then say("Wrote " .. tostring(path))
    elseif res == Place.NOTHING then say("Nothing to write", true)
    else say("Could not write the file", true) end
  end
  tip("Into the Good Idea folder in REAPER's resource path" ..
      (many and ", one track per part" or ""))

  ImGui.SameLine(ctx, 0, 16)
  if pick(Place.previewRunning() and "Stop" or "Audition", Place.previewRunning(), 96) then
    if Place.previewRunning() then Place.previewStop()
    else Place.previewStart(block, Place.tempo()) end
  end
  tip("Plays through the virtual keyboard, so a record-armed monitored track " ..
      "will sound it. Timing is a preview, not a performance.")

  ImGui.SameLine(ctx)
  local _
  _, ui.loop = ImGui.Checkbox(ctx, "Loop", ui.loop)

  if ui.status ~= "" then
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, ui.warn and WARN or DIM)
    ImGui.Text(ctx, ui.status)
    ImGui.PopStyleColor(ctx, 1)
  end
end

local function frame()
  -- A change of time signature in the project changes the idea's bars.
  local num, den = Place.timeSigNow()
  if num .. "/" .. den ~= ui.sig then touched() end
  if ui.dirty then rebuild() end
  ui.playhead = Place.previewTick(nil, ui.loop)

  -- The steps are numbered as they are shown: a Motif has no Chords step,
  -- only a Measure has an Arrangement, and Drums have no key. All but the
  -- first fold away.
  local n = 0
  local function step(draw) n = n + 1; draw(n); stepGap() end
  step(drawIdea)
  if st.kind ~= "Drums" then step(drawKey) end
  step(drawFeel)
  if I.hasMelody(st) then step(drawMelody) end
  if I.hasChords(st) then step(drawChords) end
  if st.kind == "Measure" then step(drawArrangement) end
  if st.kind == "Drums" then step(drawDrums) end
  drawNew()
  drawResult()
  drawActions()
end

------------------------------------------------------------------------------
-- Running
------------------------------------------------------------------------------

local sectionID, cmdID

local function loop()
  ImGui.SetNextWindowSize(ctx, 1000, 900, ImGui.Cond_FirstUseEver)
  -- Solid rather than the half-transparent window ReaImGui opens by default.
  ImGui.SetNextWindowBgAlpha(ctx, 1.0)
  pushTheme()
  local visible, open = ImGui.Begin(ctx, TITLE, true)
  if visible then
    frame()
    ImGui.End(ctx)
  end
  popTheme()   -- outside the visible test: a push always needs its pop
  if open and not ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
    reaper.defer(loop)
  end
end

local function shutdown()
  Place.previewStop()
  saveState()
  if sectionID then
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
  end
end

local function main()
  loadState()
  ui.history, ui.at = { st.seed }, 1
  local _, _, sid, cid = reaper.get_action_context()
  sectionID, cmdID = sid, cid
  reaper.SetToggleCommandState(sectionID, cmdID, 1)
  reaper.RefreshToolbar2(sectionID, cmdID)
  reaper.atexit(shutdown)
  reaper.set_action_options(1)
  ctx = ImGui.CreateContext(TITLE)
  reaper.defer(loop)
end

main()
