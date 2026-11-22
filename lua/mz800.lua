-- mz800: type the load command and start the tape (emulated seconds)
local seq = {
  {3, nil, "C"},
  {5, "play"}
}
local idx = 1
gameflix_cass = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  while idx <= #seq and t >= seq[idx][1] do
    local s = seq[idx]
    if s[2] == "play" then
      for tag, c in pairs(manager.machine.cassettes) do c:play() end
    else
      manager.machine.natkeyboard:post(s[3])
    end
    idx = idx + 1
  end
end)
