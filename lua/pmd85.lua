-- PMD 85: in the monitor type MGLD 00 key by key (the natural keyboard
-- types only the digits here), EOL, press play; then let it run
local keys = {"m  M", "g  G", "l  L", "d  D", "Space", "0  -", "0  -", "EOL1"}
local stage, t0, i, fld = 0, 0, 1, nil
local function field(name)
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do if n == name then return f end end
  end
end
gameflix_pmd = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if stage == 0 and t >= 4 then stage = 1; t0 = t
  elseif stage == 1 and t >= t0 + 0.15 then
    fld = field(keys[i]); if fld then fld:set_value(1) end; stage = 2; t0 = t
  elseif stage == 2 and t >= t0 + 0.08 then
    if fld then fld:clear_value() end
    i = i + 1; t0 = t
    stage = (i <= #keys) and 1 or 3
  elseif stage == 3 and t >= t0 + 1 then
    for tag, c in pairs(manager.machine.cassettes) do c:play() end; stage = 4
  end
end)
