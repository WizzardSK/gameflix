-- SAM Coupe: F9 at 3 s leaves the boot screen for BASIC, F9 again at 6 s
-- boots the disk in drive 1 (field presses; natkeyboard types text only)
local presses = {3, 6}; local i, down, t0, fld = 1, false, 0, nil
local function field(name)
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do if n == name then return f end end
  end
end
gameflix_sam = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if not down and i <= #presses and t >= presses[i] then
    fld = field("F9"); if fld then fld:set_value(1) end; down = true; t0 = t
  elseif down and t >= t0 + 0.2 then
    if fld then fld:clear_value() end; down = false; i = i + 1
  end
end)
