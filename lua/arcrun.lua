-- gameflix: an Archimedes floppy (-gameflix_lua arcrun, @GAME@ = the .adf):
-- at 60 s F12 and *wimptask run of the disk's !Boot or its first
-- application, as a double-click would start it once the command line is
-- left (the empty line). The root directory is ADFS E/F "Nick" or D "Hugo",
-- 26-byte entries from offset 5: name[10] load exec length indaddr[3] attr.
local game = "@GAME@"
local function readf(p)
  if p == "" or p:sub(1, 1) == "@" then return nil end
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read("a"); f:close(); return d
end
local SYSTEM = { ["!arcfs"] = 1, ["!spark"] = 1, ["!sparkplug"] = 1, ["!sparkfs"] = 1, ["!system"] = 1,
  ["!scrap"] = 1, ["!fonts"] = 1, ["!help"] = 1, ["!printers"] = 1, ["!configure"] = 1, ["!boot"] = 1,
  ["!sysmerge"] = 1, ["!fontprint"] = 1, ["!printedit"] = 1, ["!alarm"] = 1 }
local function root_entries(d)
  for _, off in ipairs({ 0x800, 0x400, 0x200 }) do
    local mk = d:sub(off + 2, off + 5)
    if mk == "Nick" or mk == "Hugo" then
      local out, p = {}, off + 5
      while p + 26 <= off + 0x800 and d:byte(p + 1) ~= 0 do
        local raw = d:sub(p + 1, p + 10)
        local nm = raw:gsub(".", function(c) return string.char(c:byte() & 0x7f) end)
        nm = nm:match("^[^\r%z]*"):gsub("^%s+", ""):gsub("%s+$", "")
        -- new directories keep the attributes in byte 25 (bit 3: directory),
        -- old ones (D format) in the top bit of the 4th name byte
        local isdir = (mk == "Nick") and (d:byte(p + 26) & 8 ~= 0) or (raw:byte(4) & 0x80 ~= 0)
        out[#out + 1] = { nm, isdir }
        p = p + 26
      end
      return out
    end
  end
  return {}
end
local app
pcall(function()
  local d = readf(game); if not d then return end
  local ents = root_entries(d)
  for _, e in ipairs(ents) do if e[1]:lower() == "!boot" then app = "!Boot"; return end end
  for _, e in ipairs(ents) do if e[1]:sub(1, 1) == "!" and e[2] and not SYSTEM[e[1]:lower()] then app = e[1]; return end end
  for _, e in ipairs(ents) do if e[1]:sub(1, 1) == "!" and not SYSTEM[e[1]:lower()] then app = e[1]; return end end
end)
local plan = {}
if app then
  plan = { { 60, "key", "f12" }, { 63, "type", "wimptask run :0." .. app .. (app:lower() == "!boot" and "" or ".!Run") .. "\n\n" } }
end
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
