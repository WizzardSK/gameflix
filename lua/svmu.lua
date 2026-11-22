-- VMU: the BIOS starts in the clock setup. Seven A presses step through
-- year, date and time to "OK?", Left picks Yes, A confirms; MODE goes to
-- GAME and A starts the program. Times are emulated seconds.
local port = manager.machine.ioport.ports[":P3"]
local seq = {}
for i = 0, 6 do seq[#seq+1] = {2.0 + i, "Button A"} end
seq[#seq+1] = {9.0, "Left"}; seq[#seq+1] = {10.0, "Button A"}
seq[#seq+1] = {12.0, "MODE"}; seq[#seq+1] = {14.0, "Button A"}
local held, t_rel, idx = nil, 0, 1
gameflix_vmu = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if held and t >= t_rel then held:set_value(0); held = nil end
  if idx <= #seq and t >= seq[idx][1] then
    held = port.fields[seq[idx][2]]; held:set_value(1); t_rel = t + 0.15; idx = idx + 1
  end
end)
