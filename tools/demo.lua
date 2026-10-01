--[[ What Good Idea makes, printed as note names, so it can be read and judged
     without REAPER.

       lua5.4 tools/demo.lua                      ten ideas of each kind, 4/4
       lua5.4 tools/demo.lua Measure 3 6         three Measures from idea 6 on
       lua5.4 tools/demo.lua Phrase 5 1 3 4      ... in 3/4

     Settings left on Any are rolled, as in the window. To fix one, add
     id=value: lua5.4 tools/demo.lua Motif 4 1 4 4 scale=2 pace=Busy
]]

local HERE = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local R = HERE .. "/../reascripts/"
local T = dofile(R .. "gi_theory.lua")
local I = dofile(R .. "gi_idea.lua").init(T)

local kinds = arg[1] and { arg[1] } or I.KINDS
local count, from = tonumber(arg[2]) or 10, tonumber(arg[3]) or 1
local meter = I.meter(tonumber(arg[4]) or 4, tonumber(arg[5]) or 4)
local fixed = {}
for i = 6, #arg do
  local k, v = arg[i]:match("^(%w+)=(.*)$")
  if k then fixed[k] = tonumber(v) or v end
end

local function show(idea)
  print(("== %s"):format(idea.block.name))
  print(("   %s  /  shape %s, %s"):format(idea.summary, idea.plan.shape, idea.ending))
  print("   " .. idea.chords)
  for _, b in ipairs(idea.borrowed) do print("   borrowed: " .. b.text) end
  for _, part in ipairs(idea.block.parts) do
    local out, lastBar = {}, -1
    for _, n in ipairs(part.notes) do
      local bar = math.floor(n.start / meter.barBeats + 1e-9)
      if bar ~= lastBar then out[#out + 1] = "|"; lastBar = bar end
      local name = part.drums and tostring(n.pitch) or T.pitchName(n.pitch, idea.key)
      -- Anything off the eighth-note grid shows where it falls in the bar,
      -- in beats from 1: a triplet at @1.33, a dotted eighth's sixteenth
      -- at @1.75, a push at @4.5.
      local at = n.start - bar * meter.barBeats
      local grid = math.abs(at * 2 - math.floor(at * 2 + 0.5)) > 1e-6
      out[#out + 1] = name .. (grid and ("@%.2f"):format(at + 1) or "") .. (n.vel > 100 and ">" or "")
    end
    print(("   %-7s %s"):format(part.name, table.concat(out, " ")))
  end
end

for _, kind in ipairs(kinds) do
  for seed = from, from + count - 1 do
    local st = I.newState()
    st.kind = kind
    for k, v in pairs(fixed) do st[k] = v end
    I.clampState(st)
    show(I.make(st, meter, seed))
  end
end
