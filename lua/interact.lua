-- Interact: "DEPRESS L TO LOAD TAPE": hold L, then play the tape
local fl, stage = nil, 0
gameflix_interact = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if not fl then
    for tag, port in pairs(manager.machine.ioport.ports) do
      for n, f in pairs(port.fields) do
        local l = string.lower(n)
        if l == "l" or l:match("^l%s") then fl = f end
      end
    end
  end
  if stage == 0 and t >= 3 and fl then fl:set_value(1); stage = 1
  elseif stage == 1 and t >= 3.5 then fl:clear_value(); stage = 2
  elseif stage == 2 and t >= 4 then
    for tag, c in pairs(manager.machine.cassettes) do c:play() end
    stage = 3
  end
end)
