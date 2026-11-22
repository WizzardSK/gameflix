-- rksrun.lua: a Specialist tape file (.rks: start, end address, little
-- endian, the bytes, a checksum) put straight into memory once the monitor
-- has started, and run from its start address (gameflix: -gameflix_lua rksrun, @GAME@ = the file)
local n = 0
local f = io.open("@GAME@", "rb"); local d = f and f:read("a") or ""; if f then f:close() end
emu.register_frame_done(function()
  n = n + 1
  if n == 300 and #d > 4 then
    local cpu = manager.machine.devices[":maincpu"]
    local sp = cpu.spaces["program"]
    local a = d:byte(1) + d:byte(2) * 256
    local e = d:byte(3) + d:byte(4) * 256
    local len = math.min(e - a + 1, #d - 4)
    for i = 0, len - 1 do sp:write_u8(a + i, d:byte(5 + i)) end
    cpu.state["PC"].value = a
  end
end)
