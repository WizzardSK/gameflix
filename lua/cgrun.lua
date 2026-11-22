-- cgrun.lua: a Colour Genie tape file (.cas) put straight into memory
-- (gameflix: -gameflix_lua cgrun, @GAME@ = the file), as for the TRS-80 it descends from. After the
-- optional "Colour Genie - Virtual Tape File" header and the leader, 0x66
-- starts the file: 0x55 + 6-byte name is a SYSTEM (machine code) file of
-- 0x3C blocks (length, address, data, checksum) ending in 0x78 + entry
-- address; anything else is a one-letter name and a BASIC program, whose
-- lines are relinked from TXTTAB (40A4h) with the variable pointers set past
-- them before RUN. MEM SIZE? is answered first.
local n = 0
local f = io.open("@GAME@", "rb"); local d = f and f:read("a") or ""; if f then f:close() end
local function u16(p) return d:byte(p) + d:byte(p + 1) * 256 end
emu.register_frame_done(function()
  n = n + 1
  if n == 120 then manager.machine.natkeyboard:post("\r") end
  if n == 480 and #d > 4 then
    local cpu = manager.machine.devices[":maincpu"]
    local sp = cpu.spaces["program"]
    local p = 1
    if d:sub(1, 12) == "Colour Genie" then
      local e = d:find("\26", 1, true); p = e and e + 1 or 1
      if d:byte(p) == 0 then p = p + 1 end
    end
    while p <= #d and d:byte(p) ~= 0x66 do p = p + 1 end
    p = p + 1
    if d:byte(p) == 0x55 then
      p = p + 7
      while p <= #d do
        local t = d:byte(p)
        if t == 0x3C then
          local len = d:byte(p + 1); if len == 0 then len = 256 end
          local a = u16(p + 2)
          for i = 0, len - 1 do sp:write_u8(a + i, d:byte(p + 4 + i) or 0) end
          p = p + 4 + len + 1
        elseif t == 0x78 then
          cpu.state["PC"].value = u16(p + 1)
          break
        else
          break
        end
      end
    else
      p = p + 1
      local a = sp:read_u16(0x40A4)
      while p + 3 <= #d do
        local link = u16(p)
        if link == 0 then break end
        local q = p + 4
        while q <= #d and d:byte(q) ~= 0 do q = q + 1 end
        if q > #d then break end
        local nexta = a + (q - p + 1)
        sp:write_u16(a, nexta)
        for i = p + 2, q do sp:write_u8(a + (i - p), d:byte(i)) end
        a = nexta; p = q + 1
      end
      sp:write_u16(a, 0); a = a + 2
      sp:write_u16(0x40F9, a); sp:write_u16(0x40FB, a); sp:write_u16(0x40FD, a)
      manager.machine.natkeyboard:post("RUN\r")
    end
  end
end)
