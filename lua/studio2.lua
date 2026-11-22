-- Studio II: a cartridge waits for Clear and a choice on the keypads (the
-- softlist's usage notes): Clear, then A 1 (game 1), A 5 (start in the
-- homebrew games), B 0 (start or fire). Emulated seconds, held 0.4 s.
local seq = {{2.0, ":CLEAR", "Clear"}, {6.0, ":A", "A 5"}}
local held, t_rel, idx = nil, 0, 1
gameflix_s2 = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if held and t >= t_rel then held:clear_value(); held = nil end
  if not held and idx <= #seq and t >= seq[idx][1] then
    local p = manager.machine.ioport.ports[seq[idx][2]]
    held = p and p.fields[seq[idx][3]]
    if held then held:set_value(1) end
    t_rel = t + 0.4; idx = idx + 1
  end
end)
