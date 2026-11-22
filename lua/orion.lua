-- Orion-128 + ROM disk, tape game: CH4$ (tape loader) from panel A, A at its
-- ВВОД box, play; after the tape a second ВВОД box, F4 closes the loader; the
-- file is then in panel B: Tab, Down, Enter (emulated seconds)
-- the keyboard's own key: another device may have a field of the same name
local function field(n)
  for tag,port in pairs(manager.machine.ioport.ports) do
    if tag:match("LINE") then local f=port.fields[n]; if f then return f end end
  end
  for tag,port in pairs(manager.machine.ioport.ports) do local f=port.fields[n]; if f then return f end end
end
local plan = {{3,"Down"},{3.5,"Down"},{4,"Down"},{4.5,"Enter"},{7,"A"},{8,"play"},{0,"wait"},
  {8,"F4"},{12,"Right"},{14,"Down"},{16,"Enter"}}
local held, t_rel, idx, base = nil, 0, 1, 0
gameflix_orion = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if held and t >= t_rel then held:clear_value(); held=nil end
  if held or idx > #plan then return end
  local s = plan[idx]
  if s[2] == "wait" then
    for tag,c in pairs(manager.machine.cassettes) do
      if c.length > 0 and c.position >= c.length - 0.2 then base = t; idx = idx + 1 end
    end
    return
  end
  if t < base + s[1] then return end
  if s[2] == "play" then for tag,c in pairs(manager.machine.cassettes) do c:play() end
  else held = field(s[2]); if held then held:set_value(1) end; t_rel = t + 0.06 end
  idx = idx + 1
end)
