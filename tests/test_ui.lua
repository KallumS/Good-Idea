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
local HIG          -- the shared HIG checks, loaded below
local function resetFrame()
  g.idDepth, g.colDepth, g.colStack, g.idStack, g.paths = 0, 0, {}, {}, {}
  g.buttons, g.ink, g.texts, g.checkboxes, g.headings, g.tooltips = {}, {}, {}, {}, {}, {}
  g.inputs, g.sliders, g.ticked = {}, {}, {}
  g.rects, g.bgAlpha, g.windowBg = {}, nil, nil
  g.theme, g.begun, g.varStack, g.edges, g.newLines, g.menuButtons = {}, false, {}, {}, 0, {}
  g.lineX, g.same, g.sameGap, g.overflow = 0, false, 0, nil
end
resetFrame()

local ImGui = {}
local consts = { "Col_Text", "Col_TextDisabled", "Col_WindowBg", "Col_PopupBg", "Col_Border",
  "Col_FrameBg", "Col_FrameBgHovered", "Col_FrameBgActive", "Col_TitleBg", "Col_TitleBgActive",
  "Col_TitleBgCollapsed", "Col_Button", "Col_ButtonHovered", "Col_ButtonActive", "Col_CheckMark",
  "Col_SliderGrab", "Col_SliderGrabActive", "Col_Separator", "Col_ScrollbarBg", "Col_ScrollbarGrab",
  "Col_ScrollbarGrabHovered", "Col_ScrollbarGrabActive", "Cond_FirstUseEver", "Key_Escape",
  -- The final HIG sweep (16 October 2026).
  "Col_MenuBarBg", "Col_Header", "Col_HeaderHovered", "Col_HeaderActive", "Col_ResizeGrip",
  "Col_ResizeGripHovered", "Col_ResizeGripActive", "StyleVar_FrameBorderSize" }
for i, k in ipairs(consts) do ImGui[k] = i end
-- Flags are bits, as in ReaImGui.
ImGui.PopupFlags_AnyPopupId, ImGui.PopupFlags_AnyPopupLevel = 128, 256

local function effective(idx)
  for i = #g.colStack, 1, -1 do if g.colStack[i].idx == idx then return g.colStack[i].col end end
end

function ImGui.CreateContext(name) return { name = name } end
function ImGui.SetNextWindowSize() end
function ImGui.SetNextWindowBgAlpha(_, a)
  if type(a) ~= "number" or a < 0 or a > 1 then error("window alpha " .. tostring(a)) end
  g.bgAlpha = a
end
function ImGui.Begin(_, name) g.title = name; g.begun = true; g.windowBg = effective(ImGui.Col_WindowBg); return not g.collapsed, true end
-- SetNextWindowSizeConstraints(ctx, size_min_w, size_min_h, size_max_w, size_max_h)
function ImGui.SetNextWindowSizeConstraints(_, a, b, c, d)
  for _, v in ipairs({ a, b, c, d }) do if type(v) ~= "number" then error("size constraint " .. tostring(v)) end end
  g.minSize = { a, b }
end
-- Where the keyboard is, as the script asks at the end of a frame.
function ImGui.IsAnyItemFocused() return g.focused == true end
function ImGui.IsAnyItemActive() return g.active == true end
function ImGui.IsPopupOpen(_, id, flags)
  if type(id) ~= "string" or (flags ~= nil and math.type(flags) ~= "integer") then error("IsPopupOpen(ctx, str_id, flags)") end
  return g.popup == true
end
-- A stack of style variables, so a widget can be asked what it was drawn with.
function ImGui.PushStyleVar(_, idx, a, b) g.varStack[#g.varStack + 1] = { idx = idx, a = a, b = b } end
function ImGui.PopStyleVar(_, n) for _ = 1, (n or 1) do g.varStack[#g.varStack] = nil end end
local function effectiveVar(idx)
  for i = #g.varStack, 1, -1 do if g.varStack[i].idx == idx then return g.varStack[i].a end end
end
local function edgeOf(label)
  g.edges[label] = { size = effectiveVar(ImGui.StyleVar_FrameBorderSize) or 0, col = effective(ImGui.Col_Border) }
end
-- Where each item would sit, to catch a row that runs off the window's edge:
-- the window is g.avail wide (1000 unless a test narrows it), and what is
-- left of a line after SameLine shrinks, as in ImGui. Wrapped text and
-- headings take what is left; anything else must fit in it.
local function avail() return g.avail or 1000 end
local function lineStart() return g.same and (g.lineX + g.sameGap) or 0 end
local function layout(label, w, wraps)
  local x = lineStart()
  g.same = false
  if wraps then w = math.min(w, avail() - x) end
  g.lineX = x + w
  if x + w > avail() + 0.5 or (wraps and x > avail() - 1) then g.overflow = g.overflow or label end
end
local function measure(s) return (ImGui.CalcTextSize(nil, s)) end
local function frameH() return (HIG.font and HIG.font.size or 13) + 2 * (HIG.framePad or 0) end
function ImGui.NewLine() g.newLines = g.newLines + 1; g.same = false end
function ImGui.End() end
function ImGui.IsKeyPressed() return false end
function ImGui.SeparatorText(_, s)
  if type(s) ~= "string" then error("SeparatorText got a " .. type(s)) end
  layout(s, measure(s), true)
  g.headings[#g.headings + 1] = s
end
function ImGui.Text(_, s)
  if type(s) ~= "string" then error("Text got a " .. type(s)) end
  layout(s, measure(s))
  g.texts[#g.texts + 1] = s
end
function ImGui.SameLine(_, _, spacing)
  g.same = true
  g.sameGap = (spacing and spacing >= 0) and spacing or (HIG.spacing or 8)
end
function ImGui.Dummy(_, w) layout("a gap", w or 0) end
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
  -- The theme: what is pushed before the window begins.
  if not g.begun then g.theme[idx] = col end
end
function ImGui.PopStyleColor(_, n)
  for _ = 1, (n or 1) do g.colStack[#g.colStack] = nil end
  g.colDepth = g.colDepth - (n or 1)
  if g.colDepth < 0 then error("PopStyleColor without a push") end
end
function ImGui.Button(_, label, w, h)
  if type(label) ~= "string" then error("Button label is a " .. type(label)) end
  if w ~= nil and type(w) ~= "number" then error("Button width is a " .. type(w)) end
  layout(label, (w and w > 0) and w or (measure((label:gsub("##.*$", ""))) + 16))
  g.buttons[#g.buttons + 1] = label
  if HIG and HIG.inMenuBar then g.menuButtons[#g.menuButtons + 1] = label end
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
  layout(s, measure(s), true)
  g.texts[#g.texts + 1] = s
end
function ImGui.Checkbox(_, label, v)
  if type(v) ~= "boolean" then error("Checkbox value is a " .. type(v)) end
  layout(label, frameH() + (HIG.spacing or 8) * 2 / 3 + measure(label))
  edgeOf(label)
  g.checkboxes[#g.checkboxes + 1] = label
  g.ticked[label] = v
  if g.toggle == label then return true, not v end
  return false, v
end
-- ReaImGui's InputInt(ctx, label, v, step, step_fast) returns whether it
-- changed and the value.
function ImGui.InputInt(_, label, v, step, fast)
  if type(label) ~= "string" then error("InputInt label is a " .. type(label)) end
  if math.type(v) ~= "integer" then error("InputInt value is not an integer: " .. tostring(v)) end
  g.inputs[#g.inputs + 1] = { label = label, v = v }
  layout(label, g.nextWidth or 100)
  edgeOf(label)
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
  layout(label, g.nextWidth or 100)
  edgeOf(label)
  if g.slide then return true, g.slide end
  return false, v
end
function ImGui.SetNextItemWidth(_, w)
  if type(w) ~= "number" then error("SetNextItemWidth with a " .. type(w)) end
  g.nextWidth = w
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
function ImGui.GetContentRegionAvail() return avail() - lineStart(), 400 end
function ImGui.GetWindowDrawList() return {} end
function ImGui.GetCursorScreenPos() return 0, 0 end
-- The roll is an InvisibleButton; g.rollAt, an x in pixels, clicks it there.
function ImGui.InvisibleButton(_, id, w, h)
  if type(id) ~= "string" or type(w) ~= "number" or type(h) ~= "number" then
    error("InvisibleButton(ctx, str_id, size_w, size_h)")
  end
  layout(id, w)
  return g.rollAt ~= nil or g.rollKey == true
end
-- ReaImGui's GetMousePos(ctx) returns x and y. g.rollKey presses the roll
-- from the keyboard, with the pointer somewhere else - here off to its
-- right, where a click's sums would land on the last beat.
function ImGui.GetMousePos() if g.rollKey then return 5000, 5000 end return g.rollAt or 0, 0 end
function ImGui.DrawList_AddRectFilled(_, x1, y1, x2, y2, col)
  for _, v in ipairs({ x1, y1, x2, y2, col }) do
    if type(v) ~= "number" or v ~= v then error("rect argument is " .. tostring(v)) end
  end
  if x2 < x1 or y2 < y1 then error("rect is inside out") end
  -- The ink bars under chosen buttons (decision 0031) are not the roll.
  if col ~= 0x14171CFF then g.rects[#g.rects + 1] = col end
end
function ImGui.DrawList_AddLine(_, x1, y1, x2, y2, col)
  for _, v in ipairs({ x1, y1, x2, y2, col }) do
    if type(v) ~= "number" or v ~= v then error("line argument is " .. tostring(v)) end
  end
end
HIG = dofile(HERE .. "/hig_mock.lua")(ImGui)
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
local function frame(click, toggle, typeSeed, slide, rollAt)
  resetFrame()
  g.clickTarget, g.clicked, g.toggle, g.typeSeed, g.slide = click, nil, toggle, typeSeed, slide
  g.rollAt = rollAt
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
    -- (Nor is a hidden one, 1.13: the engine decides it.)
    if s.retired or s.hidden then goto continue end
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
eq(count("Insert on New Tracks"), 1, "and inserts on new tracks")
local bars = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "measureBars" then bars[#bars + 1] = b end end
eq(table.concat(bars, ","), "Any,8 Bars,12 Bars,16 Bars", "a Measure is 8, 12 or 16 bars")
clickIn("kind", "Motif")
bars = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "motifBars" then bars[#bars + 1] = b end end
eq(table.concat(bars, ","), "Any,1 Bar,2 Bars,3 Bars,4 Bars", "a Motif is 1 to 4")

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
clickIn("fills", "Every 2 Bars")
ok(has(g.texts, "fills in bars 2, 4"), "the fills are said: " .. tostring(g.texts[#g.texts]))
ok(#g.rects > 10, "the roll draws the drums")
ok(not rowShown("layout"), "a drum idea is one item: no layout to choose")
tr = P.selTracks[1]
click("Insert at Cursor")
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
clickIn("chordPace", "1.5 a Bar")
eq(chosenIn("chordPace"), "1.5 a Bar", "1.5 a bar can be chosen")

-- 1.3: the chord paces in numbers, 0.5 to 4 a bar.
local paces = {}
reach("chordPace")
frame()
for i, b in ipairs(g.buttons) do if g.paths[i] == "chordPace" then paces[#paces + 1] = b end end
eq(table.concat(paces, ","), "Any,0.5 a Bar,1 a Bar,1.5 a Bar,2 a Bar,4 a Bar", "the chord paces read as numbers")
clickIn("chordPace", "4 a Bar")
eq(chosenIn("chordPace"), "4 a Bar", "4 a bar can be chosen")

-- 1.5: flavours, voicing and inversions, in the Chords step.
eq(I.BY_ID.flavours.step .. I.BY_ID.voicing.step .. I.BY_ID.inversions.step, "ChordsChordsChords",
   "flavours, voicing and inversions live in the Chords step")
clickIn("colour", "Mixed")
ok(rowShown("flavours"), "Flavours shows with Mixed")
clickIn("flavours", "Off")
eq(chosenIn("flavours"), "Off", "and can be turned off")
clickIn("colour", "Triads")
ok(rowShown("flavours"), "and with Triads (1.14): a sus, an added 2nd or 9th, a 6th")
clickIn("colour", "Sevenths")
ok(rowShown("flavours"), "and with Sevenths: a 7sus4, a 9th, a 6th, a diminished chord")
-- 1.13: the engine decides the progression, the part-writing and the form.
clickIn("kind", "Measure")
openAll()
ok(rowShown("bass") and not rowShown("progression") and not rowShown("partWriting") and not rowShown("form"),
   "a Measure's steps open: Progression, Part-writing and Form are not shown")
clickIn("voicing", "Drop 2 & 4")
eq(chosenIn("voicing"), "Drop 2 & 4", "a voicing can be chosen")
local voicings = {}
for i, b in ipairs(g.buttons) do if g.paths[i] == "voicing" then voicings[#voicings + 1] = b end end
eq(table.concat(voicings, ","), "Any,Close,Open,Drop 2,Drop 3,Drop 2 & 4,Shell,Rootless,Power,Drop 4",
   "nine voicings (Power since 1.12, Drop 4 since 1.14), and Any")
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
click("Insert at Cursor")
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
click("Insert at Cursor")
local allHundred = true
for _, n in ipairs(tr.items[2].take.notes) do if n.vel ~= 100 then allHundred = false end end
ok(allHundred, "Flat: every one at velocity 100")

-- Accents are 100 and 115.
clickIn("velocity", "Accents")
click("Insert at Cursor")
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
click("Insert on New Tracks")
eq(#P.tracks, 4, "a Measure: three new tracks under the selected one")
eq(P.tracks[2].name, "Melody", "named Melody")
eq(P.tracks[3].name, "Chords", "Chords")
eq(P.tracks[4].name, "Bass", "and Bass")
ok(has(g.texts, "Inserted 3 tracks"), "and says so")
clickIn("layout", "One Item")
eq(count("Insert at Cursor"), 1, "in one item it inserts at the cursor")
click("Insert at Cursor")
eq(#P.tracks, 4, "with no new tracks")

-- Export writes a file.
click("Export MIDI File")
ok(has(g.texts, "Saved “"), "Export .mid writes a file")

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
frame(nil, "Play New Ideas")
frame()
click("New Idea")
eq(count("Stop"), 1, "with Play new ideas ticked, a new idea starts playing")

------------------------------------------------------------------------------
-- 1.17: playing with REAPER, the roll, where Export writes
------------------------------------------------------------------------------

local function checked(label) return g.ticked[label] == true end

fresh()
ok(checked("Play with REAPER"), "there is a Play with REAPER switch, ticked")
eq(count("Audition"), 1, "REAPER stopped: Audition")
P.cursor, P.playing, P.playPos = 0, true, 0.01
frame()
frame()
eq(count("Stop"), 1, "REAPER plays: so does the idea, and Audition reads Stop")
ok(#P.stuffed > 0, "notes went to the virtual keyboard")
local before = ideaNumber()
click("New Idea")
ok(ideaNumber() ~= before, "a new idea while REAPER plays")
eq(count("Stop"), 1, "comes straight in, still playing with REAPER")
P.playing = false
frame()
frame()
eq(count("Audition"), 1, "REAPER stops: so does the idea")

-- With Play new ideas ticked too, a new idea still comes in with REAPER.
fresh()
frame(nil, "Play New Ideas")
P.cursor, P.playing, P.playPos = 0, true, 0.01
frame()
click("New Idea")
P.playing = false
frame()
frame()
eq(count("Audition"), 1, "with Play new ideas, a new idea still plays with REAPER, and stops with it")

-- Stopped by hand while REAPER plays, Audition joins REAPER again.
fresh()
P.cursor, P.playing, P.playPos = 0, true, 0.01
frame()
click("Stop")
eq(count("Audition"), 1, "stopped by hand")
P.now = P.now + 1
frame()
eq(count("Audition"), 1, "and stays stopped while REAPER plays")
click("Audition")
eq(count("Stop"), 1, "Audition starts it again")
P.playing = false
frame()
frame()
eq(count("Audition"), 1, "with REAPER: it stops when REAPER does")

-- Unticked, REAPER's play button is ignored, and that is saved.
fresh()
frame(nil, "Play with REAPER")
P.playing, P.playPos = true, 0.01
local sent = #P.stuffed
frame()
frame()
eq(count("Audition"), 1, "unticked, REAPER's play is ignored")
eq(#P.stuffed, sent, "and nothing is sent")
atexitFn()
ok(P.ext["GoodIdea:state"]:find("follow=0", 1, true), "the switch is saved")
start()
frame()
frame()
eq(count("Audition"), 1, "and comes back off")
ok(not checked("Play with REAPER"), "unticked")

-- A click on the roll plays from there.
fresh()
frame(nil, nil, nil, nil, 500)
frame()
eq(count("Stop"), 1, "a click on the roll auditions")
ok(has(g.texts, "Playing from bar"), "and says where from")
-- With REAPER playing, it moves REAPER there.
fresh()
P.cursor, P.playing, P.playPos = 0, true, 0
frame()
frame(nil, nil, nil, nil, 999)
ok(P.cursor > 0, "with REAPER playing, a click moves REAPER's play position: " .. P.cursor)

-- Save MIDI files to: the project's folder, REAPER's, or one chosen; and Open Folder.
fresh()
eq(chosenIn("exportTo"), "Project Folder", "Export goes beside the project unless told otherwise")
ok(has(g.texts, "the project isn’t saved yet"), "an unsaved project says where it goes instead")
local proj = os.tmpname()
os.remove(proj)
os.execute('mkdir -p "' .. proj .. '"')
P.project = proj .. "/Song.rpp"
click("Export MIDI File")
local inProject = io.open(proj .. "/Good Idea/" .. (heading():gsub("[^%w%s%-%+#&%.]", "_"):gsub("#", "sharp")) .. ".mid", "rb")
ok(inProject, "a saved project: into a Good Idea folder beside it")
if inProject then inProject:close() end
ok(has(g.texts, proj .. "/Good Idea"), "and the folder is shown")
click("Open Folder")
eq(P.execs[#P.execs] and P.execs[#P.execs].cmd, 'open "' .. proj .. '/Good Idea"', "Open folder opens it")
clickIn("exportTo", "REAPER Folder")
ok(has(g.texts, P.resource .. "/Good Idea"), "REAPER's folder, shown")
P.js, P.jsFolder = true, proj .. "/Chosen"
clickIn("exportTo", "Choose Folder…")
eq(chosenIn("exportTo"), "Choose Folder…", "a folder chosen")
click("Export MIDI File")
local chosenFiles = io.popen('ls "' .. proj .. '/Chosen"'):read("a")
ok(chosenFiles:find("%.mid"), "Export writes into it")
eq(P.ext["GoodIdea:exportDir"], proj .. "/Chosen", "and it is saved")
atexitFn()
start()
frame()
eq(chosenIn("exportTo"), "Choose Folder…", "it comes back after a restart")
ok(has(g.texts, proj .. "/Chosen"), "the folder itself too")
P.jsFolder = nil
clickIn("exportTo", "REAPER Folder")
clickIn("exportTo", "Choose Folder…")
eq(chosenIn("exportTo"), "REAPER Folder", "cancelling the chooser changes nothing")
atexitFn()
start()
frame()
eq(chosenIn("exportTo"), "REAPER Folder", "the choice comes back")
os.execute('rm -rf "' .. proj .. '"')

-- No track selected: said, in red, and nothing breaks.
fresh()
P.selTracks = {}
click("Insert at Cursor")
ok(has(g.texts, "No track is selected."), "no track selected is said")

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
click("Insert at Cursor")
local straight = {}
for _, n in ipairs(tr.items[1].take.notes) do straight[#straight + 1] = n.sp end
frame(nil, nil, nil, 100)
frame()
eq(g.sliders[1].v, 100, "the slider moves")
ok(has(g.texts, "100% swing"), "and the idea says it is swung")
click("Insert at Cursor")
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
  ok(has(g.texts, "* from outside the key"), "and the chord line marks it")
  clickIn("borrowed", "Off")
  ok(not has(g.texts, "Borrowed chord:"), "with Borrowed off, nothing is flagged")
end

-- (1.15) A Measure with a chromatic chord flags it too.
do
  local found
  for seed = 1, 400 do
    local st = I.newState()
    st.kind = "Measure"
    I.clampState(st)
    local idea = I.make(st, I.meter(4, 4), seed)
    if #idea.chromatic > 0 then found = { seed = seed, c = idea.chromatic[1] }; break end
  end
  ok(found, "some Measure in the first 400 has a chromatic chord")
  fresh()
  clickIn("kind", "Measure")
  frame(nil, nil, found.seed)
  frame()
  ok(has(g.texts, "Chromatic chord: " .. found.c.text), "the window says: Chromatic chord: " .. found.c.text)
  clickIn("borrowed", "Off")
  ok(not has(g.texts, "Chromatic chord:"), "with Borrowed off, none")
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
clickIn("phraseBars", "3 Bars")
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
  "bass=Slap;drums=Maybe;layout=Pile;velocity=Loud;content=Words;follow=Sometimes;exportTo=Moon"
start()
local good, err = pcall(frame)
ok(good, "a nonsense saved state still draws: " .. tostring(err))
ok(heading():find("^Good Idea 1 %- Motif"), "as the first motif: " .. heading())
eq(chosenIn("exportTo"), "Project Folder", "a nonsense export folder: the project's")
frame()
ok(checked("Play with REAPER"), "and a nonsense switch: on")


------------------------------------------------------------------------------
-- Apple's HIG Foundations, the final sweep (16 October 2026, decision 0031)
------------------------------------------------------------------------------

local function rgb(col)
  return math.floor(col / 16777216) % 256, math.floor(col / 65536) % 256, math.floor(col / 256) % 256
end
local function lum(col) return HIG.contrast(col, 0x000000FF) end   -- lighter is larger
local GROUND = 0x23272EFF

fresh()
local th = g.theme
ok(lum(th[ImGui.Col_PopupBg]) > lum(th[ImGui.Col_WindowBg]),
   "Dark Mode: menus and tooltips are lighter than the window they sit in front of")
ok(lum(th[ImGui.Col_Border]) > lum(th[ImGui.Col_PopupBg]), "with an edge lighter still")
for _, name in ipairs({ "Col_PopupBg", "Col_MenuBarBg", "Col_HeaderHovered", "Col_HeaderActive", "Col_Header" }) do
  local c = th[ImGui[name]] and HIG.contrast(th[ImGui.Col_Text], th[ImGui[name]]) or 0
  ok(c >= 7, ("words are 7:1 on %s too (%.2f)"):format(name, c))
end
local keysOnMenu = HIG.contrast(th[ImGui.Col_TextDisabled], th[ImGui.Col_PopupBg])
ok(keysOnMenu >= 7, ("a menu item's keys (Cmd+=) are 7:1 on the menu (%.2f)"):format(keysOnMenu))
for _, name in ipairs({ "Col_ScrollbarGrab", "Col_ResizeGrip" }) do
  local c = math.min(HIG.contrast(th[ImGui[name]], GROUND), HIG.contrast(th[ImGui[name]], th[ImGui.Col_ScrollbarBg]))
  ok(c >= 3, ("%s can be seen: 3:1 on what it sits on (%.2f)"):format(name, c))
end
local flat
for idx, col in pairs(th) do
  local r, gg, b = rgb(col)
  if col ~= 0xFFF200FF and not (r < gg and gg < b) then flat = flat or idx end
end
ok(not flat, "every grey in the theme is still blue-shifted, R < G < B: " .. tostring(flat))

-- Tick boxes, the idea number and the swing slider have an edge that can be seen.
openStep("Feel")
frame()
for _, label in ipairs({ "Loop", "Play New Ideas", "Play with REAPER", "##seed", "##swing" }) do
  local e = g.edges[label]
  ok(e and e.size >= 1 and HIG.contrast(e.col, GROUND) >= 4.5,
     ("%s has an edge 4.5:1 on the ground (%s)"):format(label, e and ("%.2f"):format(HIG.contrast(e.col, GROUND)) or "none"))
end

-- Esc lets go of what has it before it closes the window.
local function esc()
  HIG.keys = { [ImGui.Key_Escape] = true }
  frame()
  HIG.keys = {}
  return deferred ~= nil
end
fresh()
ok(not esc(), "Esc with nothing else to let go of closes the window")
for _, what in ipairs({ "focused", "active", "popup" }) do
  fresh()
  g[what] = true
  frame()
  g[what] = false
  ok(esc(), "Esc lets go of " .. ({ focused = "the control the keyboard is on", active = "the idea number being typed",
                                   popup = "an open menu" })[what] .. ", and the window stays")
  ok(not esc(), "the next Esc closes it")
end

-- Anything playing has a Stop that cannot scroll away: in the menu bar.
fresh()
eq(#g.menuButtons, 0, "nothing playing: no Stop in the menu bar")
click("Audition")
ok(has(g.menuButtons, "Stop"), "auditioning: a Stop in the menu bar")
if count("Stop##menu") == 1 then click("Stop##menu") end
eq(count("Audition"), 1, "which stops it")
eq(#g.menuButtons, 0, "and goes away")
fresh()
frame(nil, "Play New Ideas")
frame()
click("New Idea")
ok(has(g.menuButtons, "Stop"), "a new idea playing by itself: a Stop in the menu bar")
fresh()
P.cursor, P.playing, P.playPos = 0, true, 0.01
frame()
frame()
ok(has(g.menuButtons, "Stop"), "playing with REAPER: a Stop in the menu bar")
P.playing = false
frame()
frame()
-- Both switches that make it play by itself are remembered.
fresh()
frame(nil, "Play New Ideas")
frame()
atexitFn()
ok(P.ext["GoodIdea:state"]:find("autoplay=1", 1, true), "Play New Ideas is remembered")

-- The roll pressed from the keyboard plays from the top.
fresh()
g.rollKey = true
frame()
g.rollKey = nil
frame()
eq(count("Stop"), 1, "Space on the roll auditions")
ok(has(g.texts, "Playing from bar 1, beat 1"), "from the top")

-- Keep can be undone.
local function anys()
  openAll()
  local n = 0
  for i, b in ipairs(g.buttons) do if b == "Any" and g.ink[i].bg == 0xFFF200FF then n = n + 1 end end
  return n
end
fresh()
local before = anys()
ok(before > 0, "some settings are on Any: " .. before)
click("Keep")
eq(anys(), 0, "Keep turns every Any into what the idea rolled")
eq(count("Undo"), 1, "and leaves an Undo beside its message")
if count("Undo") == 1 then click("Undo") end
eq(anys(), before, "which puts every Any back")
click("Keep")
clickIn("kind", "Phrase")
eq(count("Undo"), 0, "another change to a setting takes the Undo away, so it cannot undo that too")

-- Tooltips are broken into lines a reader can follow.
local longest, which = 0, nil
local function tips()
  frame()
  for _, t in ipairs(g.tooltips) do
    for line in (t .. "\n"):gmatch("(.-)\n") do
      local n = utf8.len(line) or #line
      if n > longest then longest, which = n, line end
    end
  end
end
for _, kind in ipairs({ "Motif", "Measure", "Drums" }) do
  fresh(); clickIn("kind", kind); openAll(); tips()
end
ok(longest > 0 and longest <= 64, ("no tooltip line is longer than 64 characters (%d: %s)"):format(longest, tostring(which)))

-- The title names the idea, and stays one window.
fresh()
frame()
ok(g.title and g.title:find("^Good Idea — Good Idea %d+") and g.title:find("###Good Idea$"),
   "the title names the idea: " .. tostring(g.title))
ok(g.minSize and g.minSize[1] >= 300 and g.minSize[2] >= 200, "the window has a smallest size")

-- Nothing runs off the window's edge, at 100% or 200%, in any state, and
-- at the window's smallest.
local function noOverflow(what)
  frame()
  ok(not g.overflow, what .. ": nothing runs off the window's edge: " .. tostring(g.overflow))
end
for _, size in ipairs({ "Text Size 100%", "Text Size 200%" }) do
  local big = size:find("200") and 2 or 1
  for _, kind in ipairs({ "Motif", "Phrase", "Measure", "Drums" }) do
    fresh()
    HIG.menuFrame({ frame = function() frame() end }, size)
    clickIn("kind", kind)
    noOverflow(size .. ", " .. kind .. ", folded")
    openAll(); noOverflow(size .. ", " .. kind .. ", every step open")
    click("New Idea"); click("New Idea"); click("<"); noOverflow(size .. ", " .. kind .. ", back and forward")
    click("Keep"); noOverflow(size .. ", " .. kind .. ", a message with Undo")
    click("Audition"); noOverflow(size .. ", " .. kind .. ", playing")
    click("Export MIDI File"); noOverflow(size .. ", " .. kind .. ", a saved file's name")
    P.selTracks = {}
    click(count("Insert on New Tracks") > 0 and "Insert on New Tracks" or "Insert at Cursor")
    noOverflow(size .. ", " .. kind .. ", a warning")
    -- The smallest window, 400 wide, less ImGui's padding either side.
    g.avail = 384 * big
    noOverflow(size .. ", " .. kind .. ", the window at its smallest")
    g.avail = nil
    atexitFn()
  end
end
P.ext["GoodIdea:view"] = nil

------------------------------------------------------------------------------
-- Apple's Human Interface Guidelines (decision 0031)
------------------------------------------------------------------------------

HIG.check({
  ok = ok, eq = eq, frame = function() frame() end,
  loaded = function() fresh(); frame() end,
  warned = function()
    fresh()
    P.selTracks = {}
    click("Insert at Cursor")
    return "No track is selected."
  end,
  dismiss = function() click("Dismiss") end,
  quit = function() atexitFn() end,
  restart = function() start(); frame() end,
  saved = function() return P.ext["GoodIdea:view"] end,
  setSaved = function(v) P.ext["GoodIdea:view"] = v end,
  sizeKey = "textSize",
})

C.done()
