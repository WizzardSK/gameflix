-- BBC Micro disk: SHIFT held through the power-on reset boots drive 0
-- (SHIFT+BREAK), released after 2 s
local fld, done = nil, false
local function shift()
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do
      local l = string.lower(n)
      if l == "shift" or l == "left shift" or l == "shift (left)" then return f end
    end
  end
end
gameflix_bbc = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if not fld and not done then fld = shift(); if fld then fld:set_value(1) end end
  if fld and not done and t >= 2 then fld:clear_value(); done = true end
end)
