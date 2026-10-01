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
  g.inputs = {}
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
local function frame(click, toggle, typeSeed)
  resetFrame()
  g.clickTarget, g.clicked, g.toggle, g.typeSeed = click, nil, toggle, typeSeed
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
-- The button labelled `label` in the row of setting `row`.
local function clickIn(row, label)
  frame()
  local idx
  for i, b in ipairs(g.buttons) do if b == label and g.paths[i] == row then idx = i end end
  if not idx then error("no button " .. label .. " in the " .. row .. " row") end
  frame(idx)
  frame()
end
local function chosenIn(row)
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


local T = dofile(C.SCRIPTS .. "gi_theory.lua")
local I = dofile(C.SCRIPTS .. "gi_idea.lua").init(T)

local function heading() return g.headings[#g.headings] or "" end
local function ideaNumber() return tonumber(heading():match("^Good Idea (%d+)")) end

------------------------------------------------------------------------------
-- It starts, and draws
------------------------------------------------------------------------------

local tr = fresh()
ok(#g.buttons > 30, "the first frame draws its buttons: " .. #g.buttons)
ok(#g.rects > 1, "and the roll, with notes in it")
eq(g.bgAlpha, 1.0, "the window is solid")
eq(g.windowBg, 0x23272EFF, "on the house ground")
for _, step in ipairs({ "Idea", "Key", "Feel", "Melody" }) do
  ok(has(g.headings, step), "a motif shows the " .. step .. " step")
end
ok(not has(g.headings, "Chords"), "but no Chords step - a motif is a tune")
ok(not has(g.headings, "Arrangement"), "and no Arrangement")
ok(heading():find("^Good Idea 1 %- Motif"), "the first idea is number 1, a motif: " .. heading())
ok(has(g.texts, "C  D  E  F  G  A  B"), "the key's notes are spelled out")
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
    frame()
    for i, b in ipairs(g.buttons) do
      shown[g.paths[i] .. "=" .. b] = true
    end
  end
  for _, s in ipairs(I.SETTINGS) do
    local values = {}
    if s.any then values[1] = "Any" end
    for _, v in ipairs(s.values) do values[#values + 1] = I.valueName(s, v) end
    for _, v in ipairs(values) do
      if not shown[s.id .. "=" .. v] then missing[#missing + 1] = s.id .. "=" .. v end
    end
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
  sweep("a " .. kind)
end
for _, content in ipairs({ "Melody", "Chords", "Both" }) do
  fresh()
  clickIn("kind", "Phrase")
  clickIn("content", content)
  sweep("a phrase of " .. content)
end

-- Every value of every setting, for every kind, makes an idea that draws.
do
  local failures = {}
  for _, kind in ipairs(I.KINDS) do
    fresh()
    clickIn("kind", kind)
    if kind == "Phrase" then clickIn("content", "Both") end
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
ok(has(g.headings, "Melody") and has(g.headings, "Chords"), "a phrase on Any shows Melody and Chords")
clickIn("content", "Chords")
ok(not has(g.headings, "Melody"), "a chords-only phrase hides the Melody step")
ok(has(g.headings, "Chords"), "and shows Chords")
clickIn("content", "Melody")
ok(not has(g.headings, "Chords"), "a melody-only phrase hides the Chords step")
clickIn("kind", "Measure")
ok(has(g.headings, "Arrangement"), "a Measure shows the Arrangement")
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
local allHundred = true
for _, n in ipairs(tr.items[1].take.notes) do if n.vel ~= 100 then allHundred = false end end
ok(allHundred, "every one at velocity 100")
ok(has(g.texts, "Inserted at the edit cursor"), "and says so")

-- Accents are the only thing that moves a velocity off 100.
clickIn("velocity", "Accents")
click("Insert at cursor")
local sawAccent = false
for _, n in ipairs(tr.items[2].take.notes) do
  ok(n.vel == 100 or n.vel == 115, "an accented idea is 100 and 115 only")
  if n.vel == 115 then sawAccent = true end
end
ok(sawAccent, "and does accent something")

-- A Measure inserts four tracks.
fresh()
clickIn("kind", "Measure")
clickIn("drums", "On")
clickIn("layout", "Tracks")
click("Insert on new tracks")
eq(#P.tracks, 5, "a Measure: four new tracks under the selected one")
eq(P.tracks[2].name, "Melody", "named Melody")
eq(P.tracks[5].name, "Drums", "to Drums")
ok(has(g.texts, "Inserted 4 tracks"), "and says so")
clickIn("drums", "Off")
click("Insert on new tracks")
eq(#P.tracks, 8, "without drums, three")
clickIn("layout", "One item")
eq(count("Insert at cursor"), 1, "in one item it inserts at the cursor")
click("Insert at cursor")
eq(#P.tracks, 8, "with no new tracks")

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
