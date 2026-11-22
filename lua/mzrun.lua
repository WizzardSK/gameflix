-- mzrun.lua: a Sharp MZ-700 tape file (.mzf) started (gameflix: -gameflix_lua mzrun, @GAME@ = the file).
-- A machine code file (type 1) is written to its load address and started
-- at its exec address. A BASIC program (type 5) needs S-BASIC 1Z-013B: the
-- interpreter is written to memory and started the same way, then LOAD
-- reads the program from the tape (the .mzf as cassette) and RUN starts it.
local n = 0
local function readf(p) local f = io.open(p, "rb"); if not f then return "" end; local d = f:read("a"); f:close(); return d end
local game = readf("@GAME@")
-- S-BASIC is not among the files gameflix fetches: a BASIC program is
-- left at the monitor
local basic = ""
local cass, loaded
local function run_mzf(d)
  local cpu = manager.machine.devices[":maincpu"]
  local sp = cpu.spaces["program"]
  local size = d:byte(0x13) + d:byte(0x14) * 256
  local load = d:byte(0x15) + d:byte(0x16) * 256
  local exec = d:byte(0x17) + d:byte(0x18) * 256
  size = math.min(size, #d - 128)
  for i = 0, size - 1 do sp:write_u8(load + i, d:byte(129 + i)) end
  cpu.state["PC"].value = exec
end
emu.register_frame_done(function()
  n = n + 1
  if #game < 129 then return end
  local t = game:byte(1)
  if n == 240 then
    if t == 1 then run_mzf(game) elseif #basic > 128 then run_mzf(basic) end
  end
  if t ~= 1 and #basic > 128 then
    if n == 420 then manager.machine.natkeyboard:post("LOAD\r") end
    if n == 480 then
      for _, c in pairs(manager.machine.cassettes) do cass = c end
      if cass then cass:play() end
    end
    if cass and not loaded and n > 500 and cass.position >= cass.length - 0.05 then
      loaded = n
      manager.machine.natkeyboard:post("RUN\r")
    end
  end
end)
