-- Oric: CLOAD"" through the natural keyboard (its Return never arrives), then
-- the Return key pressed as a field, then the tape played (emulated seconds)
local function field(pat)
  for tag,port in pairs(manager.machine.ioport.ports) do
    for name,f in pairs(port.fields) do if name:lower():match(pat) then return f end end
  end
end
local stage, held, t_rel = 0, nil, 0
gameflix_oric = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if held and t >= t_rel then held:clear_value(); held = nil end
  if stage == 0 and t >= 4 then manager.machine.natkeyboard:post('CLOAD""'); stage = 1
  elseif stage == 1 and t >= 6 and manager.machine.natkeyboard.empty then
    held = field("^return") or field("^enter"); if held then held:set_value(1) end; t_rel = t + 0.1; stage = 2
  elseif stage == 2 and t >= 7 then
    for tag,c in pairs(manager.machine.cassettes) do c:play() end; stage = 3
  end
end)
