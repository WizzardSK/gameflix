-- gameflix: an Apple I tape (-gameflix_lua apple1): the Woz monitor loads it
-- through the ACI (C100R, then the load range), and enters it once the tape
-- has run out. The range comes from the software list's usage note ("load at
-- 0280.0FFFR, enter at 0280R") or a TOSEC name's brackets ("[0280.0FFFR,
-- 0280R]"). Programs that need Integer BASIC loaded first are left alone:
-- gameflix has no BASIC tape to load.
local hash, item = "@HASH@", "@ITEM@"
local function readf(p)
  if p == "" or p:sub(1, 1) == "@" then return nil end
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read("a"); f:close(); return d
end
local load, enter
pcall(function()
  local x = readf(hash)
  local s = x and x:find('<software name="' .. item .. '"', 1, true)
  if s then
    local b = x:sub(s, x:find("</software>", s, true) or #x)
    local u = (b:match('<info name="usage" value="([^"]*)"') or ""):upper()
    if not u:find("BASIC", 1, true) then load, enter = u:match("LOAD AT ([%x%.R]+), ENTER AT (%x+R)") end
  elseif not item:upper():find("REQ BASIC", 1, true) then
    load, enter = item:upper():match("%[([%x%.R]+)[,%._ ]+(%x+)R?%]")
    if enter then enter = enter .. "R" end
  end
end)
local stage, t1, cass = 0, 0, nil
local function post(s) manager.machine.natkeyboard:post(s) end
gameflix_a1 = emu.add_machine_frame_notifier(function()
  if not load then return end
  local t = manager.machine.time:as_double()
  if stage == 0 and t >= 3 then
    for tag, c in pairs(manager.machine.cassettes) do cass = c end
    if not cass then stage = 9; return end
    post("C100R\r" .. load .. "\r"); stage = 1; t1 = t
  elseif stage == 1 and t >= t1 + 4 then
    cass:play(); stage = 2; t1 = t
  elseif stage == 2 and t >= t1 + 2 and cass.position >= cass.length - 0.05 then
    cass:stop(); post(enter .. "\r"); stage = 3
  end
end)
