-- gameflix: a Coleco ADAM disk (-gameflix_lua adamrun, @GAME@ = the .dsk/.ddp):
-- once it has booted (75 s), the command that starts its program is typed:
-- a CP/M disk's first .COM that is not a CP/M tool ("ZORK1"), or a SmartBASIC
-- (EOS) disk's first BASIC program ("run hangman"; EOS directory entries are
-- the name, its type letter A, 0x03)
local game = "@GAME@"
local function readf(p)
  if p == "" or p:sub(1, 1) == "@" then return nil end
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read("a"); f:close(); return d
end
local CPM_TOOLS = { PIP = 1, STAT = 1, SUBMIT = 1, DDT = 1, ED = 1, ASM = 1, LOAD = 1, XSUB = 1, DUMP = 1,
  SYSGEN = 1, MOVCPM = 1, FORMAT = 1, COPY = 1, CONFIG = 1, TERM = 1, FILES = 1, SETUP = 1 }
local EOS_SKIP = { boot = 1, hello = 1, directory = 1, ["blocks left"] = 1 }
local function cpm(d)
  local found, seen = {}, {}
  for o = 1, #d - 31, 32 do
    if d:byte(o) < 16 and d:byte(o + 12) == 0 then
      local nm, ex = "", ""
      for j = 1, 8 do nm = nm .. string.char(d:byte(o + j) & 0x7f) end
      for j = 9, 11 do ex = ex .. string.char(d:byte(o + j) & 0x7f) end
      if ex == "COM" and nm:match("^[A-Z0-9$_-]+ *$") then
        nm = nm:gsub("%s+$", "")
        if nm ~= "" and not CPM_TOOLS[nm] and not seen[nm] then seen[nm] = true; found[#found + 1] = nm end
      end
    end
  end
  -- the plain version before an 80-column one (ZORK1 before ZORK1-80)
  local function alt(n) return n:find("-", 1, true) ~= nil or n:sub(-2) == "80" end
  for _, n in ipairs(found) do if not alt(n) then return n .. "\n" end end
  return found[1] and (found[1] .. "\n") or nil
end
local function eos(d)
  d = d:sub(1, 0x2000)
  local p = 1
  while p <= #d do
    if d:sub(p, p):match("%a") then
      for k = 0, 10 do
        local c = d:byte(p + k)
        if k > 0 and (not c or c < 0x20 or c > 0x7e) then break end
        if d:sub(p + k + 1, p + k + 2) == "A\3" then
          local n = d:sub(p, p + k):gsub("^%s+", ""):gsub("%s+$", "")
          if n ~= "" and not EOS_SKIP[n:lower()] then return "run " .. n .. "\n" end
          p = p + k + 2
          break
        end
      end
    end
    p = p + 1
  end
  return nil
end
local cmd
pcall(function() local d = readf(game); if d then cmd = cpm(d) or eos(d) end end)
local plan = cmd and { { 75, "type", cmd } } or {}
-- the plan is typed key by key through the keyboard fields themselves: a
-- field named "2  \"" types 2, and " with Shift held (the natural keyboard
-- gets some of these wrong on machines with odd layouts)
local keys, shift
local function scan()
  keys = {}
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do
      local l = string.lower(n)
      if l:match("^shift") or l == "left shift" or l:match("^l%-shift") or l:match("^lshift") then shift = shift or f end
      local toks = {}
      for tk in n:gmatch("%S+") do toks[#toks + 1] = tk end
      if #toks >= 1 then
        local a = toks[1]
        if #a == 1 then
          -- a key with both cases ("v  V") wins over a lone one of the same
          -- letter (the ADAM's SmartKey "V")
          local strong = toks[2] ~= nil
          for _, ch in ipairs({ a, a:lower(), a:upper() }) do
            if not keys[ch] or (strong and not keys[ch][3]) then keys[ch] = { f, false, strong } end
          end
        end
        if toks[2] and #toks[2] == 1 and not keys["s" .. toks[2]] then keys["s" .. toks[2]] = { f, true } end
        keys["name:" .. l] = { f, false }
      end
      if l == "space" or l:match("^space") then keys[" "] = { f, false } end
      if l == "return" or l == "enter" or l:match("^return") or l:match("^enter") or l == "cr" or l:match("^cr%s") then keys["\r"] = { f, false } end
    end
  end
end
local q, qt, i = {}, 0, 1
local function push_char(c)
  local k = keys[c] or keys["s" .. c]
  if c == "\n" then k = keys["\r"] end
  if not k then return end
  local sh = (keys[c] == nil) and k[2]
  if sh and shift then q[#q + 1] = { shift, 1 } end
  q[#q + 1] = { k[1], 1 }; q[#q + 1] = { k[1], 0 }
  if sh and shift then q[#q + 1] = { shift, 0 } end
end
gameflix_typer = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if not keys then scan() end
  if #q > 0 then
    if t >= qt then
      local s = table.remove(q, 1)
      if s[2] == 1 then s[1]:set_value(1) else s[1]:clear_value() end
      qt = t + 0.08
    end
    return
  end
  local p = plan[i]
  if p and t >= p[1] then
    if p[2] == "type" then
      for c in p[3]:gmatch(".") do push_char(c) end
    elseif p[2] == "key" then
      local k = keys["name:" .. p[3]]
      if not k then for n, v in pairs(keys) do if n:match("^name:" .. p[3]) then k = v; break end end end
      if k then q[#q + 1] = { k[1], 1 }; q[#q + 1] = { k[1], 0 } end
    end
    i = i + 1
  end
end)
