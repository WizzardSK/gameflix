-- Mac Finder: open the boot disk and the first item in it from the keyboard
-- (Tab selects the first icon alphabetically, Command-O opens it), twice.
local keys = {}
local function scan()
  local out = nil
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do
      if out then out:write(tag .. " | " .. n .. "\n") end
      local l = string.lower(n)
      if l == "tab" then keys.tab = f end
      if l == "a" or l:match("^a%s") then keys.a = f end
      if l == "o" or l:match("^o%s") then keys.o = f end
      if l:match("^command") then keys.cmd = f end
    end
  end
  if out then out:close() end
end
local plan = {
  {30, "tab", true}, {30.3, "tab", false},
  {31, "cmd", true}, {31.2, "o", true}, {31.5, "o", false}, {31.6, "cmd", false},
  {38, "cmd", true}, {38.2, "a", true}, {38.5, "a", false}, {38.6, "cmd", false},
  {39, "cmd", true}, {39.2, "o", true}, {39.5, "o", false}, {39.6, "cmd", false},
}
local i, scanned = 1, false
gameflix_mac = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if not scanned and t > 2 then scan(); scanned = true end
  while scanned and plan[i] and t >= plan[i][1] do
    local f = keys[plan[i][2]]
    if f then if plan[i][3] then f:set_value(1) else f:clear_value() end end
    i = i + 1
  end
end)
