-- pro128: typed text and tape start (emulated seconds)
local seq = {
  {8, nil, "1"},
  {10, nil, "RUN\"CASS:\"\r"},
  {13, "play"}
}
local idx = 1
gameflix_seq = emu.add_machine_frame_notifier(function()
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
