-- spc1500: ROM BASIC, LOAD, then start the tape (emulated seconds).
-- The boot menu ignores the natural keyboard, so the keys are pressed on the
-- ioport fields directly. The cassette system (C) loads only the tape's
-- header and drops back to the menu; ROM BASIC (R) and LOAD run the tapes
-- (demo, demoa, Lode Runner; Galaga stops at its BORAM splash).
local fields = {}
for _, port in pairs(manager.machine.ioport.ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local seq = {}
local function key(t, name)
  seq[#seq + 1] = {t, name, true}
  seq[#seq + 1] = {t + 0.15, name, false}
end
key(2, "R")
for i, c in ipairs({"L", "O", "A", "D", "Return"}) do key(6 + (i - 1) * 0.4, c) end
seq[#seq + 1] = {9, "play"}
table.sort(seq, function(a, b) return a[1] < b[1] end)
local idx = 1
gameflix_cass = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  while idx <= #seq and t >= seq[idx][1] do
    local s = seq[idx]
    if s[2] == "play" then
      for _, c in pairs(manager.machine.cassettes) do c:play() end
    elseif fields[s[2]] then
      if s[3] then fields[s[2]]:set_value(1) else fields[s[2]]:clear_value() end
    end
    idx = idx + 1
  end
end)
