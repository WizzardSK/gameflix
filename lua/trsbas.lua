-- trsbas.lua: a TRS-80 Model III BASIC program run from ROM BASIC (gameflix:
-- -gameflix_lua trsbas, @GAME@ = the file). Answers Cass? and Memory Size?, then a tokenized
-- program (0xFF + lines, as Disk BASIC saves it) goes straight into memory at
-- TXTTAB with its line links recomputed for the new address, the variable
-- pointers set past its end, and RUN typed. An ASCII listing is typed instead.
local n = 0
local f = io.open("@GAME@", "rb"); local data = f and f:read("a") or ""; if f then f:close() end
emu.register_frame_done(function()
  n = n + 1
  if n == 120 or n == 240 then manager.machine.natkeyboard:post("\r") end
  if n == 480 then
    if data:byte(1) == 0xFF then
      local mem = manager.machine.devices[":maincpu"].spaces["program"]
      local a = mem:read_u16(0x40A4)
      local p = 2
      while p + 3 <= #data do
        local link = data:byte(p) + data:byte(p + 1) * 256
        if link == 0 then break end
        local q = p + 4
        while q <= #data and data:byte(q) ~= 0 do q = q + 1 end
        if q > #data then break end
        local nexta = a + (q - p + 1)
        mem:write_u16(a, nexta)
        for i = p + 2, q do mem:write_u8(a + (i - p), data:byte(i)) end
        a = nexta; p = q + 1
      end
      mem:write_u16(a, 0); a = a + 2
      mem:write_u16(0x40F9, a); mem:write_u16(0x40FB, a); mem:write_u16(0x40FD, a)
      manager.machine.natkeyboard:post("RUN\r")
    else
      local t = data:gsub("\r\n", "\r"):gsub("\n", "\r"):gsub("%z", ""):gsub("\26.*$", "")
      manager.machine.natkeyboard:post(t .. "\rRUN\r")
    end
  end
end)
