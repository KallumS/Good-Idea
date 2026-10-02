--[[ The whole script, headless.

     ReaImGui only exists inside REAPER, so a mock stands in its place and
     the real "Good Idea.lua" is run against it and the mocked REAPER.
     It cannot say the window looks right. It can say that nothing raises,
     that no call reaches a ReaImGui function that does not exist, that every
     push is popped, that every button wears the dark ink, and that clicking
     every button in every state leaves the script working.

       lua5.4 tests/test_ui.lua
]]

local HERE = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local C = dofile(HERE .. "/check.lua")
local ok, eq = C.ok, C.eq
local P = dofile(HERE .. "/reaper_mock.lua")
local SCRIPT = C.SCRIPTS .. "Good Idea.lua"

------------------------------------------------------------------------------
-- A ReaImGui that records
------------------------------------------------------------------------------

local g = {}
local function resetFrame()
  g.idDepth, g.colDepth, g.colStack, g.idStack, g.paths = 0, 0, {}, {}, {}
  g.buttons, g.ink, g.texts, g.checkboxes, g.headings, g.tooltips = {}, {}, {}, {}, {}, {}
  g.inputs, g.sliders = {}, {}
  g.rects, g.bgAlpha, g.windowBg = {}, nil, nil
end
resetFrame()

local ImGui = {}
local consts = { "Col_Text", "Col_TextDisabled", "Col_WindowBg", "Col_PopupBg", "Col_Border",
  "Col_FrameBg", "Col_FrameBgHovered", "Col_FrameBgActive", "Col_TitleBg", "Col_TitleBgActive",
  "Col_TitleBgCollapsed", "Col_Button", "Col_ButtonHovered", "Col_ButtonActive", "Col_CheckMark",
  "Col_SliderGrab", "Col_SliderGrabActive", "Col_Separator", "Col_ScrollbarBg", "Col_ScrollbarGrab",
  "Col_ScrollbarGrabHovered", "Col_ScrollbarGrabActive", "Cond_FirstUseEver", "Key_Escape" }
for i, k in ipairs(consts) do ImGui[k] = i end

local function effective(idx)
  for i = #g.colStack, 1, -1 do if g.colStack[i].idx == idx then return g.colStack[i].col end end
end

function ImGui.CreateContext(name) return { name = name } end
function ImGui.SetNextWindowSize() end
function ImGui.SetNextWindowBgAlpha(_, a)
  if type(a) ~= "number" or a < 0 or a > 1 then error("window alpha " .. tostring(a)) end
  g.bgAlpha = a
end
function ImGui.Begin() g.windowBg = effective(ImGui.Col_WindowBg); return not g.collapsed, true end
function ImGui.End() end
function ImGui.IsKeyPressed() return false end
function ImGui.SeparatorText(_, s)
  if type(s) ~= "string" then error("SeparatorText got a " .. type(s)) end
  g.headings[#g.headings + 1] = s
end
function ImGui.Text(_, s)
  if type(s) ~= "string" then error("Text got a " .. type(s)) end
  g.texts[#g.texts + 1] = s
end
function ImGui.SameLine() end
function ImGui.Dummy() end
function ImGui.PushID(_, v)
  if v == nil then error("PushID with nil") end
  g.idDepth = g.idDepth + 1
  g.idStack[#g.idStack + 1] = tostring(v)
end
function ImGui.PopID()
  g.idStack[#g.idStack] = nil
  g.idDepth = g.idDepth - 1
  if g.idDepth < 0 then error("PopID without a push") end
end
function ImGui.PushStyleColor(_, idx, col)
  if type(idx) ~= "number" then error("PushStyleColor with a " .. type(idx) .. " index") end
  if type(col) ~= "number" or col % 256 == 0 then error("style colour must be an opaque 0xRRGGBBAA") end
  g.colStack[#g.colStack + 1] = { idx = idx, col = col }
  g.colDepth = g.colDepth + 1
end
function ImGui.PopStyleColor(_, n)
  for _ = 1, (n or 1) do g.colStack[#g.colStack] = nil end
  g.colDepth = g.colDepth - (n or 1)
  if g.colDepth < 0 then error("PopStyleColor without a push") end
end
function ImGui.Button(_, label, w, h)
  if type(label) ~= "string" then error("Button label is a " .. type(label)) end
  if w ~= nil and type(w) ~= "number" then error("Button width is a " .. type(w)) end
  g.buttons[#g.buttons + 1] = label
  -- Where the button is: the row it was drawn in, from the ID stack.
  g.paths[#g.buttons] = g.idStack[1] or ""
  -- Recorded per button: a scheme can ink the chosen button alone and leave
  -- every other one unreadable, and a frame-wide tally cannot see that.
  g.ink[#g.buttons] = { bg = effective(ImGui.Col_Button), text = effective(ImGui.Col_Text) }
  if g.clickTarget == #g.buttons then g.clicked = label; return true end
  return false
end
function ImGui.TextWrapped(_, s)
  if type(s) ~= "string" then error("TextWrapped got a " .. type(s)) end
  g.texts[#g.texts + 1] = s
end
function ImGui.Checkbox(_, label, v)
  if type(v) ~= "boolean" then error("Checkbox value is a " .. type(v)) end
  g.checkboxes[#g.checkboxes + 1] = label
  if g.toggle == label then return true, not v end
  return false, v
end
-- ReaImGui's InputInt(ctx, label, v, step, step_fast) returns whether it
-- changed and the value.
function ImGui.InputInt(_, label, v, step, fast)
  if type(label) ~= "string" then error("InputInt label is a " .. type(label)) end
  if math.type(v) ~= "integer" then error("InputInt value is not an integer: " .. tostring(v)) end
  g.inputs[#g.inputs + 1] = { label = label, v = v }
  if g.typeSeed then return true, g.typeSeed end
  return false, v
end
-- ReaImGui's SliderInt(ctx, label, v, v_min, v_max, format) returns whether
-- it changed and the value.
function ImGui.SliderInt(_, label, v, lo, hi, fmt)
  if type(label) ~= "string" then error("SliderInt label is a " .. type(label)) end
  if math.type(v) ~= "integer" or math.type(lo) ~= "integer" or math.type(hi) ~= "integer" then
    error("SliderInt takes integers: " .. tostring(v) .. " " .. tostring(lo) .. " " .. tostring(hi))
  end
  if type(fmt) ~= "string" then error("SliderInt format is a " .. type(fmt)) end
  g.sliders[#g.sliders + 1] = { label = label, v = v, lo = lo, hi = hi }
  if g.slide then return true, g.slide end
  return false, v
end
function ImGui.SetNextItemWidth(_, w)
  if type(w) ~= "number" then error("SetNextItemWidth with a " .. type(w)) end
end
function ImGui.IsItemHovered() return true end
function ImGui.SetTooltip(_, s)
  if type(s) ~= "string" then error("tooltip is a " .. type(s)) end
  g.tooltips[#g.tooltips + 1] = s
end
-- ReaImGui's CalcTextSize(ctx, text) returns width and height. The mock's
-- font is a fixed seven pixels a character.
function ImGui.CalcTextSize(_, s)
  if type(s) ~= "string" then error("CalcTextSize got a " .. type(s)) end
  return #s * 7, 13
end
function ImGui.GetContentRegionAvail() return 1000, 400 end
function ImGui.GetWindowDrawList() return {} end
function ImGui.GetCursorScreenPos() return 0, 0 end
function ImGui.InvisibleButton() return false end
function ImGui.DrawList_AddRectFilled(_, x1, y1, x2, y2, col)
  for _, v in ipairs({ x1, y1, x2, y2, col }) do
    if type(v) ~= "number" or v ~= v then error("rect argument is " .. tostring(v)) end
  end
  if x2 < x1 or y2 < y1 then error("rect is inside out") end
  g.rects[#g.rects + 1] = col
end
function ImGui.DrawList_AddLine(_, x1, y1, x2, y2, col)
  for _, v in ipairs({ x1, y1, x2, y2, col }) do
    if type(v) ~= "number" or v ~= v then error("line argument is " .. tostring(v)) end
  end
end
setmetatable(ImGui, { __index = function(_, k)
  error("the script called ImGui." .. tostring(k) .. ", which the mock does not have")
end })

------------------------------------------------------------------------------
-- REAPER, and running the script
------------------------------------------------------------------------------

local tmp = os.tmpname()
os.remove(tmp)
os.execute('mkdir -p "' .. tmp .. '"')
local shim = assert(io.open(tmp .. "/imgui.lua", "w"))
shim:write("return function(version) return _G.__MOCK_IMGUI end\n")
shim:close()
_G.__MOCK_IMGUI = ImGui

P.install()
P.resource = tmp .. "/resource"
local deferred, atexitFn
local function absolute(path)
  if path:match("^/") then return path end
  return (os.getenv("PWD") or ".") .. "/" .. path
end
reaper.ImGui_GetBuiltinPath = function() return tmp end
reaper.MB = function(msg) error("the script gave up: " .. tostring(msg)) end
reaper.get_action_context = function() return true, absolute(SCRIPT), 0, 1, 0, 0, 0 end
reaper.defer = function(f) deferred = f end
reaper.atexit = function(f) atexitFn = f end
reaper.set_action_options = function() end
reaper.SetToggleCommandState = function() end
reaper.RefreshToolbar2 = function() end

local function start()
  deferred, atexitFn = nil, nil
  dofile(SCRIPT)
end

-- One frame, optionally clicking the n-th button drawn in it.
local function frame(click, toggle, typeSeed, slide)
  resetFrame()
  g.clickTarget, g.clicked, g.toggle, g.typeSeed, g.slide = click, nil, toggle, typeSeed, slide
  local f = deferred
  deferred = nil
  if not f then error("the script stopped deferring") end
  f()
  if g.idDepth ~= 0 then error("PushID left unbalanced: " .. g.idDepth) end
  if g.colDepth ~= 0 then error("PushStyleColor left unbalanced: " .. g.colDepth) end
  return g.clicked
end

local function has(list, text)
  for _, t in ipairs(list) do if t:find(text, 1, true) then return true end end
  return false
end
local function buttonIndex(label, nth)
  local seen = 0
  for i, b in ipairs(g.buttons) do
    if b == label then
      seen = seen + 1
      if seen == (nth or 1) then return i end
    end
  end
end
local function click(label, nth)
  frame()
  local i = buttonIndex(label, nth)
  if not i then error("no button called " .. label) end
  frame(i)
  frame()
end
local T = dofile(C.SCRIPTS .. "gi_theory.lua")
local I = dofile(C.SCRIPTS .. "gi_idea.lua").init(T)

-- The steps fold away. Their buttons sit inside PushID("open:" .. name) and
-- read "Name  +" closed, "Name  -" open.
local function foldButton(name)
  for i, b in ipairs(g.buttons) do
    if g.paths[i] == "open:" .. name then return i, b:sub(-1) == "-" end
  end
end
local function stepShown(name) return foldButton(name) ~= nil end
local function openStep(name)
  frame()
  local i, isOpen = foldButton(name)
  if i and not isOpen then frame(i); frame() end
end
local function foldStep(name)
  frame()
  local i, isOpen = foldButton(name)
  if i and isOpen then frame(i); frame() end
end
local function openAll()
  for _ = 1, 10 do
    frame()
    local any
    for i, b in ipairs(g.buttons) do
      if g.paths[i]:sub(1, 5) == "open:" and b:sub(-1) == "+" then any = i; break end
    end
    if not any then return end
    frame(any)
  end
  frame()
end
local function rowShown(row)
  for i in ipairs(g.buttons) do if g.paths[i] == row then return true end end
  return false
end
-- Opens the step a setting's row is in, if it is folded.
local function reach(row)
  frame()
  if not rowShown(row) and I.BY_ID[row] then openStep(I.BY_ID[row].step) end
end

-- The button labelled `label` in the row of setting `row`.
local function clickIn(row, label)
  reach(row)
  frame()
  local idx
  for i, b in ipairs(g.buttons) do if b == label and g.paths[i] == row then idx = i end end
  if not idx then error("no button " .. label .. " in the " .. row .. " row") end
  frame(idx)
  frame()
end
local function chosenIn(row)
  reach(row)
  frame()
  for i, b in ipairs(g.buttons) do
    if g.paths[i] == row and g.ink[i].bg == 0xFFF200FF then return b end
  end
end
local function count(label)
  local n = 0
  for _, b in ipairs(g.buttons) do if b == label then n = n + 1 end end
  return n
end

local function fresh()
  P.reset()
  P.ext = {}
  local tr = P.track("Track 1")
  P.selTracks = { tr }
  start()
  frame()
  return tr
end


local function heading() return g.headings[#g.headings] or "" end
local function ideaNumber() return tonumber(heading():match("^Good Idea (%d+)")) end

------------------------------------------------------------------------------
-- It starts, and draws
------------------------------------------------------------------------------

local tr = fresh()
ok(#g.buttons >= 12 and #g.buttons <= 30,
   "the first frame is short, the steps folded: " .. #g.buttons .. " buttons")
ok(#g.rects > 1, "and the roll, with notes in it")
eq(g.bgAlpha, 1.0, "the window is solid")
eq(g.windowBg, 0x23272EFF, "on the house ground")
ok(has(g.headings, "Idea"), "a motif shows the Idea step, open")
for _, step in ipairs({ "Key", "Feel", "Melody" }) do
  ok(stepShown(step), "a motif shows the " .. step .. " step")
  ok(not select(2, foldButton(step)), "folded at first")
end
ok(not stepShown("Chords"), "but no Chords step - a motif is a tune")
ok(not stepShown("Arrangement"), "and no Arrangement")
ok(not stepShown("Drums"), "and no Drums")
ok(heading():find("^Good Idea 1 %- Motif"), "the first idea is number 1, a motif: " .. heading())
ok(has(g.texts, "C Major"), "the folded Key step says what is chosen")
ok(has(g.texts, "pace Any  /  groove Any"), "and so does the folded Feel step")
openStep("Key")
ok(has(g.texts, "C  D  E  F  G  A  B"), "opened, the key's notes are spelled out")
eq(chosenIn("kind"), "Motif", "Motif is chosen")
eq(chosenIn("root"), "C", "in C")
eq(chosenIn("scale"), "Major", "major")
eq(chosenIn("pace"), "Any", "and the feel left to chance")
eq(count("New Idea"), 1, "one New Idea button")
eq(#g.inputs, 1, "and a box for the idea number")

-- Every button wears the dark ink, chosen or not.
local function allInked(what)
  local bad
  for i, ink in ipairs(g.ink) do
    if ink.text ~= 0x14171CFF then bad = g.buttons[i]; break end
  end
  ok(not bad, what .. ": every button has dark ink (" .. tostring(bad) .. " does not)")
end
allInked("the first frame")

------------------------------------------------------------------------------
-- Every setting is in the window
------------------------------------------------------------------------------

-- Each setting shows, for at least one kind, a button for every value it has
-- (and Any, where it can be left to chance). Nothing is settable only in
-- the code.
do
  local missing = {}
  local shown = {}
  for _, kind in ipairs(I.KINDS) do
    fresh()
    clickIn("kind", kind)
    if kind == "Phrase" then clickIn("content", "Both") end
    openAll()
    for i, b in ipairs(g.buttons) do
      shown[g.paths[i] .. "=" .. b] = true
    end
  end
  for _, s in ipairs(I.SETTINGS) do
    -- (A retired setting is kept in the list only for the order of the
    -- dice, and is never shown.)
    if s.retired then goto continue end
    local values = {}
    if s.any then values[1] = "Any" end
    for _, v in ipairs(s.values) do values[#values + 1] = I.valueName(s, v) end
    for _, v in ipairs(values) do
      if not shown[s.id .. "=" .. v] then missing[#missing + 1] = s.id .. "=" .. v end
    end
    ::continue::
  end
  eq(#missing, 0, "every value of every setting has a button: " .. table.concat(missing, ", "))
end

------------------------------------------------------------------------------
-- The sweep: every button, in every kind, clicked
------------------------------------------------------------------------------

local function sweep(label)
  frame()
  local n = #g.buttons
  local i = 1
  local failures = 0
  while i <= n do
    frame()
    if i > #g.buttons then break end
    local name = g.buttons[i]
    local good, err = pcall(frame, i)
    if not good then
      failures = failures + 1
      ok(false, label .. ": clicking \"" .. tostring(name) .. "\" raised: " .. tostring(err))
    else
      local g2, e2 = pcall(frame)
      if not g2 then
        failures = failures + 1
        ok(false, label .. ": the frame after \"" .. tostring(name) .. "\" raised: " .. tostring(e2))
      end
      allInked(label .. " after " .. tostring(name))
    end
    if failures > 5 then break end
    i = i + 1
  end
  ok(failures == 0, label .. ": the sweep clicked every button without raising")
end

for _, kind in ipairs(I.KINDS) do
  fresh()
  clickIn("kind", kind)
  sweep("a " .. kind .. ", folded")
  fresh()
  clickIn("kind", kind)
  openAll()
  sweep("a " .. kind .. ", open")
end
for _, content in ipairs({ "Melody", "Chords", "Both" }) do
  fresh()
  clickIn("kind", "Phrase")
  clickIn("content", content)
  openAll()
  sweep("a phrase of " .. content)
end

-- Every value of every setting, for every kind, makes an idea that draws.
do
  local failures = {}
  for _, kind in ipairs(I.KINDS) do
    fresh()
    clickIn("kind", kind)
    if kind == "Phrase" then clickIn("content", "Both") end
    openAll()
    for _, s in ipairs(I.SETTINGS) do
      frame()
      local present = false
      for i in ipairs(g.buttons) do if g.paths[i] == s.id then present = true end end
      if present then
        local values = {}
        if s.any then values[1] = "Any" end
        for _, v in ipairs(s.values) do values[#values + 1] = I.valueName(s, v) end
        for _, v in ipairs(values) do
          local good, err = pcall(clickIn, s.id, v)
          if not good then failures[#failures + 1] = kind .. "/" .. s.id .. "=" .. v .. ": " .. tostring(err)
          elseif s.id ~= "kind" and chosenIn(s.id) ~= v then
            failures[#failures + 1] = kind .. "/" .. s.id .. "=" .. v .. " did not stay chosen"
          end
        end
        if s.id == "kind" then clickIn("kind", kind) end
        if s.id == "content" then clickIn("content", "Both") end
      end
    end
  end
  ok(#failures == 0, "every value of every setting can be chosen: " .. table.concat(failures, "; "))
end

------------------------------------------------------------------------------
-- What shows when
------------------------------------------------------------------------------

fresh()
clickIn("kind", "Phrase")
ok(stepShown("Melody") and stepShown("Chords"), "a phrase on Any shows Melody and Chords")
clickIn("content", "Chords")
ok(not stepShown("Melody"), "a chords-only phrase hides the Melody step")
ok(stepShown("Chords"), "and shows Chords")
clickIn("content", "Melody")
ok(not stepShown("Chords"), "a melody-only phrase hides the Chords step")
clickIn("kind", "Measure")
ok(stepShown("Arrangement"), "a Measure shows the Arrangement")
eq(count("Insert on new tracks"), 1, "and inserts on new tracks")
local bars = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "measureBars" then bars[#bars + 1] = b end end
eq(table.concat(bars, ","), "Any,8 bars,12 bars,16 bars", "a Measure is 8, 12 or 16 bars")
clickIn("kind", "Motif")
bars = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "motifBars" then bars[#bars + 1] = b end end
eq(table.concat(bars, ","), "Any,1 bar,2 bars,3 bars,4 bars", "a Motif is 1 to 4")

-- The steps are numbered as they show.
fresh()
local numbers = {}
for _, t in ipairs(g.texts) do if t:match("^%d$") then numbers[#numbers + 1] = t end end
eq(table.concat(numbers, ""), "1234", "a motif's steps are 1 to 4")
clickIn("kind", "Measure")
numbers = {}
for _, t in ipairs(g.texts) do if t:match("^%d$") then numbers[#numbers + 1] = t end end
eq(table.concat(numbers, ""), "123456", "a Measure's 1 to 6")

------------------------------------------------------------------------------
-- 1.2: folding steps, Drums, pull, 1.5 a bar, the layout by the buttons
------------------------------------------------------------------------------

-- A step opens and folds again, and what was chosen stays chosen.
fresh()
local closed = #g.buttons
openStep("Feel")
ok(#g.buttons > closed, "opening Feel shows its rows")
ok(rowShown("pace") and rowShown("figures") and rowShown("push") and rowShown("pull") == false,
   "pace, figures and push (no pull: a motif has no chords to lie back)")
clickIn("pace", "Busy")
foldStep("Feel")
ok(not rowShown("pace"), "folding it hides them again")
ok(has(g.texts, "pace Busy"), "and its line says what is chosen")
eq(#g.buttons, closed, "and the window is as short as before")
openAll()
local all = #g.buttons
ok(all > closed * 2, "every step open, the window is long again: " .. all .. " buttons")

-- Drums sit beside Motif, Phrase and Measure.
fresh()
local kinds = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "kind" then kinds[#kinds + 1] = b end end
eq(table.concat(kinds, ","), "Motif,Phrase,Measure,Drums", "four kinds of idea")
clickIn("kind", "Drums")
ok(heading():find("Drums", 1, true), "a drum idea: " .. heading())
ok(not stepShown("Key") and not stepShown("Melody") and not stepShown("Chords"), "with no key, tune or chords")
ok(stepShown("Feel") and stepShown("Drums"), "but a Feel and a Drums step")
local nums = {}
for _, x in ipairs(g.texts) do if x:match("^%d$") then nums[#nums + 1] = x end end
eq(table.concat(nums, ""), "123", "numbered 1 to 3")
local dbars = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "drumBars" then dbars[#dbars + 1] = b end end
eq(#dbars, 17, "Any and 1 to 16 bars")
clickIn("drumBars", "4")
clickIn("fills", "Every 2 bars")
ok(has(g.texts, "fills in bars 2, 4"), "the fills are said: " .. tostring(g.texts[#g.texts]))
ok(#g.rects > 10, "the roll draws the drums")
ok(not rowShown("layout"), "a drum idea is one item: no layout to choose")
tr = P.selTracks[1]
click("Insert at cursor")
eq(#P.tracks, 1, "it goes on the selected track")
local drumOnTen = #tr.items[1].take.notes > 0
for _, n in ipairs(tr.items[1].take.notes) do if n.chan ~= 9 then drumOnTen = false end end
ok(drumOnTen, "every note on channel 10")

-- Pull, and one and a half chords a bar.
fresh()
clickIn("kind", "Phrase")
clickIn("content", "Both")
ok(rowShown("pull") or (function() openStep("Feel"); return rowShown("pull") end)(), "a phrase with chords can pull them")
clickIn("pull", "Lots")
local pulled = false
for seed = 1, 12 do
  frame(nil, nil, seed)
  frame()
  if has(g.texts, "_ pulled an eighth late") then pulled = true; break end
end
ok(pulled, "a pulled chord is marked _ in the chord line, and the mark explained")
clickIn("chordPace", "1.5 a bar")
eq(chosenIn("chordPace"), "1.5 a bar", "1.5 a bar can be chosen")

-- 1.3: the chord paces in numbers, 0.5 to 4 a bar.
local paces = {}
reach("chordPace")
frame()
for i, b in ipairs(g.buttons) do if g.paths[i] == "chordPace" then paces[#paces + 1] = b end end
eq(table.concat(paces, ","), "Any,0.5 a bar,1 a bar,1.5 a bar,2 a bar,4 a bar", "the chord paces read as numbers")
clickIn("chordPace", "4 a bar")
eq(chosenIn("chordPace"), "4 a bar", "4 a bar can be chosen")

-- 1.5: flavours, voicing and inversions, in the Chords step.
eq(I.BY_ID.flavours.step .. I.BY_ID.voicing.step .. I.BY_ID.inversions.step, "ChordsChordsChords",
   "flavours, voicing and inversions live in the Chords step")
clickIn("colour", "Mixed")
ok(rowShown("flavours"), "Flavours shows with Mixed")
clickIn("flavours", "Off")
eq(chosenIn("flavours"), "Off", "and can be turned off")
clickIn("colour", "Triads")
ok(not rowShown("flavours"), "and is hidden with Triads, where it would do nothing")
clickIn("voicing", "Drop 2 & 4")
eq(chosenIn("voicing"), "Drop 2 & 4", "a voicing can be chosen")
local voicings = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "voicing" then voicings[#voicings + 1] = b end end
eq(table.concat(voicings, ","), "Any,Close,Open,Drop 2,Drop 3,Drop 2 & 4,Shell,Rootless,Power", "eight voicings (Power since 1.12), and Any")
clickIn("inversions", "Off")
eq(chosenIn("inversions"), "Off", "inversions can be turned off")

------------------------------------------------------------------------------
-- New Idea, back and forward, the number, Keep
------------------------------------------------------------------------------

fresh()
eq(count("<"), 0, "no way back from the first idea")
local first = heading()
click("New Idea")
local second = heading()
ok(second ~= first, "New Idea makes a new idea: " .. second)
ok(ideaNumber() and ideaNumber() ~= 1, "with a new number")
eq(count("<"), 1, "and now there is a way back")
eq(count(">"), 0, "but none forward")
click("<")
eq(heading(), first, "back goes to the idea before")
eq(count(">"), 1, "and forward is offered")
click(">")
eq(heading(), second, "forward comes back")
click("<")
click("New Idea")
eq(count(">"), 0, "a new idea after going back drops the ones ahead")

-- Typing a number goes to that idea.
fresh()
frame(nil, nil, 4321)
frame()
eq(ideaNumber(), 4321, "typing a number shows that idea")
frame(nil, nil, 999999)
frame()
eq(ideaNumber(), I.MAX_SEED, "and a number past the last is the last")

-- The same number, the same idea; a setting changed, the same number.
fresh()
frame(nil, nil, 77)
frame()
local roll77 = #g.rects
clickIn("pace", "Busy")
eq(ideaNumber(), 77, "changing a setting keeps the idea number")
clickIn("pace", "Any")
eq(#g.rects, roll77, "and changing it back gives the same idea")

-- Any says what it rolled.
fresh()
local tipFound = false
for _, t in ipairs(g.tooltips) do if t:find("This idea rolled: ", 1, true) then tipFound = true end end
ok(tipFound, "hovering Any says what this idea rolled")

-- Keep turns every Any into what was rolled, without changing the idea.
fresh()
clickIn("kind", "Measure")
frame(nil, nil, 2024)
frame()
local before = heading()
local rectsBefore = #g.rects
click("Keep")
eq(heading(), before, "Keep leaves the idea as it was")
eq(#g.rects, rectsBefore, "note for note")
local anyLeft = 0
for i, b in ipairs(g.buttons) do
  if b == "Any" and g.ink[i].bg == 0xFFF200FF then anyLeft = anyLeft + 1 end
end
eq(anyLeft, 0, "and nothing on screen is left on Any")
ok(has(g.texts, "Kept"), "and says so")

------------------------------------------------------------------------------
-- Getting it out
------------------------------------------------------------------------------

-- A motif inserts one item on the selected track.
tr = fresh()
click("Insert at cursor")
eq(#tr.items, 1, "Insert at cursor makes one item")
ok(#tr.items[1].take.notes > 0, "with notes in it")
-- Shaped by default (1.7): the downbeats loudest, every velocity a real one.
local shapes, inRange = {}, true
for _, n in ipairs(tr.items[1].take.notes) do
  shapes[n.vel] = true
  if n.vel < 1 or n.vel > 127 then inRange = false end
end
local kinds = 0
for _ in pairs(shapes) do kinds = kinds + 1 end
ok(inRange and kinds >= 2, "shaped: more than one velocity, every one between 1 and 127")
ok(has(g.texts, "Inserted at the edit cursor"), "and says so")

-- Flat is every note at 100.
clickIn("velocity", "Flat")
click("Insert at cursor")
local allHundred = true
for _, n in ipairs(tr.items[2].take.notes) do if n.vel ~= 100 then allHundred = false end end
ok(allHundred, "Flat: every one at velocity 100")

-- Accents are 100 and 115.
clickIn("velocity", "Accents")
click("Insert at cursor")
local sawAccent = false
for _, n in ipairs(tr.items[3].take.notes) do
  ok(n.vel == 100 or n.vel == 115, "an accented idea is 100 and 115 only")
  if n.vel == 115 then sawAccent = true end
end
ok(sawAccent, "and does accent something")

-- A Measure inserts three tracks: it has no drums (since 1.3).
fresh()
clickIn("kind", "Measure")
ok(not rowShown("drums"), "there is no drums switch")
ok(rowShown("layout"), "the layout is down by the output buttons, with no step to open")
clickIn("layout", "Tracks")
click("Insert on new tracks")
eq(#P.tracks, 4, "a Measure: three new tracks under the selected one")
eq(P.tracks[2].name, "Melody", "named Melody")
eq(P.tracks[3].name, "Chords", "Chords")
eq(P.tracks[4].name, "Bass", "and Bass")
ok(has(g.texts, "Inserted 3 tracks"), "and says so")
clickIn("layout", "One item")
eq(count("Insert at cursor"), 1, "in one item it inserts at the cursor")
click("Insert at cursor")
eq(#P.tracks, 4, "with no new tracks")

-- Export writes a file.
click("Export .mid")
ok(has(g.texts, "Wrote "), "Export .mid writes a file")

-- Audition sends notes and stops them.
fresh()
click("Audition")
eq(count("Stop"), 1, "Audition turns into Stop")
P.now = P.now + 100
frame()
ok(#P.stuffed > 0, "notes went to the virtual keyboard")
local ons, offs = 0, 0
for _, m in ipairs(P.stuffed) do
  if m.a >= 0x90 then ons = ons + 1 else offs = offs + 1 end
end
ok(ons > 0 and offs >= 1, "on and off")

-- Play new ideas plays each new idea as it is made.
fresh()
frame(nil, "Play new ideas")
frame()
click("New Idea")
eq(count("Stop"), 1, "with Play new ideas ticked, a new idea starts playing")

-- No track selected: said, in red, and nothing breaks.
fresh()
P.selTracks = {}
click("Insert at cursor")
ok(has(g.texts, "No track selected"), "no track selected is said")

------------------------------------------------------------------------------
-- The project
------------------------------------------------------------------------------

fresh()
P.num, P.den = 3, 4
frame()
frame()
ok(has(g.texts, "3/4"), "a change of time signature in the project is picked up")
P.num, P.den = 6, 8
frame()
frame()
ok(has(g.texts, "6/8"), "6/8 too")
ok(#g.rects > 1, "and the idea still draws")

------------------------------------------------------------------------------
-- 1.1: swing, figures, push, borrowed chords
------------------------------------------------------------------------------

-- The swing slider: in 4/4 a slider, and moving it swings the idea.
fresh()
clickIn("kind", "Phrase")
clickIn("content", "Melody")
clickIn("pace", "Flowing")
clickIn("figures", "Plain")
openStep("Feel")
eq(#g.sliders, 1, "a swing slider in 4/4")
eq(g.sliders[1].v, 0, "starting straight")
eq(g.sliders[1].lo .. "-" .. g.sliders[1].hi, "0-100", "from 0 to 100")
tr = P.selTracks[1]
click("Insert at cursor")
local straight = {}
for _, n in ipairs(tr.items[1].take.notes) do straight[#straight + 1] = n.sp end
frame(nil, nil, nil, 100)
frame()
eq(g.sliders[1].v, 100, "the slider moves")
ok(has(g.texts, "100% swing"), "and the idea says it is swung")
click("Insert at cursor")
local later, earlier = 0, 0
for i, n in ipairs(tr.items[2].take.notes) do
  if straight[i] and n.sp > straight[i] + 1 then later = later + 1 end
  if straight[i] and n.sp < straight[i] - 1 then earlier = earlier + 1 end
end
ok(later > 0, "inserted notes off the beat land later: " .. later)
eq(earlier, 0, "and none earlier")
atexitFn()
ok(P.ext["GoodIdea:state"]:find("swing=100", 1, true), "the swing is saved")
start()
frame()
openStep("Feel")
eq(g.sliders[1].v, 100, "and comes back")

-- In 6/8 there is nothing to swing, and the window says so.
fresh()
openStep("Feel")
P.num, P.den = 6, 8
frame()
frame()
eq(#g.sliders, 0, "no swing slider in 6/8")
ok(has(g.texts, "in threes already"), "it says 6/8 is in threes already")
P.num, P.den = 7, 8
frame()
frame()
ok(has(g.texts, "no quarter-note beats to swing"), "and that 7/8 has no quarter-note beats to swing")
P.num, P.den = 4, 4

-- The new rows are there, and Borrowed only for scales that can borrow.
fresh()
openAll()
for _, row in ipairs({ "figures", "push", "borrowed" }) do
  local n = 0
  for i in ipairs(g.buttons) do if g.paths[i] == row then n = n + 1 end end
  ok(n > 0, "the " .. row .. " row is in the window")
end
eq(chosenIn("borrowed"), "Rare", "borrowing starts on Rare")
clickIn("scale", "Maj Pent")
local nb = 0
for i in ipairs(g.buttons) do if g.paths[i] == "borrowed" then nb = nb + 1 end end
eq(nb, 0, "a pentatonic scale hides the Borrowed row: it has nothing to borrow")
clickIn("scale", "Any")
nb = 0
for i in ipairs(g.buttons) do if g.paths[i] == "borrowed" then nb = nb + 1 end end
ok(nb > 0, "and Any shows it again")

-- An idea with a borrowed chord flags it: which chord, where, from where.
do
  local found
  for seed = 1, 400 do
    local st = I.newState()
    st.kind = "Phrase"
    st.content = "Both"
    I.clampState(st)
    local idea = I.make(st, I.meter(4, 4), seed)
    if #idea.borrowed > 0 then found = { seed = seed, b = idea.borrowed[1] }; break end
  end
  ok(found, "some idea in the first 400 borrows a chord")
  fresh()
  clickIn("kind", "Phrase")
  clickIn("content", "Both")
  frame(nil, nil, found.seed)
  frame()
  ok(has(g.texts, "Borrowed chord: " .. found.b.text), "the window says: Borrowed chord: " .. found.b.text)
  ok(has(g.texts, "* borrowed"), "and the chord line marks it")
  clickIn("borrowed", "Off")
  ok(not has(g.texts, "Borrowed chord:"), "with Borrowed off, nothing is flagged")
end

-- Pushed chords are marked in the chord line.
fresh()
clickIn("kind", "Measure")
clickIn("push", "Lots")
local marked = false
for s = 1, 10 do
  frame(nil, nil, s)
  frame()
  if has(g.texts, "^ pushed an eighth early") then marked = true; break end
end
ok(marked, "a pushed chord is marked ^ in the chord line, and the mark is explained")

------------------------------------------------------------------------------
-- Settings survive, and bad ones are put right
------------------------------------------------------------------------------

fresh()
clickIn("kind", "Phrase")
clickIn("phraseBars", "3 bars")
clickIn("root", "D")
clickIn("scale", "Dorian")
clickIn("content", "Both")
frame(nil, nil, 555)
frame()
atexitFn()
local saved = P.ext["GoodIdea:state"]
ok(saved and saved:find("seed=555", 1, true), "the idea number is saved")
start()
frame()
ok(heading():find("Good Idea 555 - Phrase (both), 3 bars, D Dorian", 1, true), "a reload comes back to it: " .. heading())

-- Settings from nowhere in particular are clamped rather than trusted.
P.ext["GoodIdea:state"] = "seed=-9;autoplay=7;kind=Sonnet;motifBars=99;root=0;scale=40;pace=Fast;" ..
  "groove=;contour=Spiral;register=Attic;colour=Plaid;chordPace=Never;chordStyle=Mosh;form=Haiku;" ..
  "bass=Slap;drums=Maybe;layout=Pile;velocity=Loud;content=Words"
start()
local good, err = pcall(frame)
ok(good, "a nonsense saved state still draws: " .. tostring(err))
ok(heading():find("^Good Idea 1 %- Motif"), "as the first motif: " .. heading())

C.done()
