-- gameflix: a Radio-86RK family tape (Radio-86RK, Specialist, Partner,
-- Mikrosha). The monitor loads it with I; when the tape has run out, G and
-- the start address from the tape's header (the launcher reads it: @GO@)
-- runs it. Emulated seconds; @T@ is when I is typed.
local stage, t_end = 0, 0
gameflix_rk = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if stage == 0 and t >= @T@ then
    manager.machine.natkeyboard:post("I"); stage = 5
  elseif stage == 5 and t >= @T@ + 0.7 then
    manager.machine.natkeyboard:post("\r"); stage = 1
  elseif stage == 1 and t >= @T@ + 1.5 then
    for tag, c in pairs(manager.machine.cassettes) do c:play() end
    stage = 2
  elseif stage == 2 then
    for tag, c in pairs(manager.machine.cassettes) do
      if c.length > 0 and c.position >= c.length - 0.2 then stage = 3; t_end = t end
    end
  elseif stage == 3 and t >= t_end + 2 then
    manager.machine.natkeyboard:post("@GO@\r"); stage = 4
  end
end)
