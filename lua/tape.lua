-- gameflix: a tape (or a disk started by a typed command). The launcher fills
-- in the @...@ fields from the platform's -gameflix_tape spec: type PRE after
-- T emulated seconds, play the tape, and once it has run out (or after WAIT s
-- when there is no tape) type POST. GAP > 0 types one character every GAP s,
-- for keyboards that drop keys at the natural keyboard's rate; BOOT is a key
-- the machine wants at power-on (SPC-1000: B for BASIC).
--
-- MODE (+-separated) lets the game itself change PRE and POST:
--   usage   the software list's usage note for the item ("Load with
--           BLOAD"",R", "Start with RUN", "CLOAD + RUN", ...)
--   cpc     Amstrad CPC disk: RUN" the program its directory starts with
--   dragon  DragonDOS disk: BOOT a boot disk, else its first program
--   coco    Disk Extended BASIC disk without a usage note: its first program
--   ml      CoCo / Dragon / MC-10 tape whose name block says machine code:
--           CLOADM and EXEC
--   mo5     Thomson MO5 .k7 whose header block says machine code:
--           LOADM"",,R instead of RUN""
-- PREFIX is typed before PRE (MSX: past the boot prompts into BASIC).
-- GAME is the image file, HASH the software list XML, ITEM the item name.
local stage, t_end = 0, 0
local pre, post = "@PRE@", "@POST@"
local boot, booted = "@BOOT@", false
local gap, q, q_t = @GAP@, {}, 0
local mode, prefix = "," .. ("@MODE@"):gsub("[+%s]", ",") .. ",", "@PREFIX@"
local game, hash, item = "@GAME@", "@HASH@", "@ITEM@"

local function readf(p, n)
  if p == "" or p:sub(1, 1) == "@" then return nil end
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read(n or "a"); f:close(); return d
end
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function has(m) return mode:find("," .. m .. ",", 1, true) ~= nil end
local function printable(s) return s ~= "" and not s:find("[^\33-\126]") end
local function u16(d, p) return d:byte(p) + d:byte(p + 1) * 256 end

-- the usage notes of ITEM in HASH
local function usage_notes()
  local x = readf(hash); if not x then return {} end
  local s = x:find('<software name="' .. item .. '"', 1, true); if not s then return {} end
  local e = x:find("</software>", s, true) or #x
  local out = {}
  for v in x:sub(s, e):gmatch('<info name="usage" value="([^"]*)"') do
    v = v:gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&lt;", "<"):gsub("&gt;", ">")
    v = v:gsub("&#(%d+);", function(n) return utf8.char(tonumber(n)) end):gsub("&amp;", "&")
    out[#out + 1] = v
  end
  return out
end

local function apply_usage()
  local sys = manager.machine.system.name
  for _, u in ipairs(usage_notes()) do
    u = trim(u):gsub("%.+$", "")
    local l = u:lower()
    local function cut(a, b) return u:sub(a, b - 1) end
    -- two-step notes: 'Load with CLOAD, enter RUN to start' / 'In Basic, CLOAD then RUN'
    for _, verb in ipairs({ "enter", "type" }) do
      local a, b, c, d = l:match("^load with ()[^,]+(), " .. verb .. " ()%S+() to ")
      if a and (l:sub(d + 4, d + 8) == "start" or l:sub(d + 4, d + 6) == "run") then
        pre, post = trim(cut(a, b)) .. "\n", cut(c, d) .. "\n"; return
      end
    end
    local a, b, c, d = l:match("^in basic, ()%S+() then ()%S+()%.?$")
    if a then pre, post = cut(a, b) .. "\n", cut(c, d) .. "\n"; return end
    -- Super-80: BASIC (in ROM at D000) for 'LOAD while in BASIC, then RUN';
    -- 'L to load, G100 to run' from the monitor
    if sys:sub(1, 7) == "super80" then
      if l:sub(1, 19) == "load while in basic" then pre, post = "GD000\n\n\n\nLOAD\n", "RUN\n"; return end
      local g = l:match("^l to load, (g%x+) to run") or l:match("^l to load, then (g%x+) to run")
      if g then pre, post = "L\n", g:upper() .. "\n"; return end
    end
    -- Jupiter Ace (Forth): the whole note is one command line typed before
    -- the tape plays; key help after a full stop is left out
    if sys == "jupace" then
      local line = trim((u .. ". "):match("^(.-)%. "))
      local ll = line:lower()
      if ll:match("^load ") or ll:match("^%d+ %d+ bload ") then pre, post = line .. "\n", ""; return end
    end
    -- 'load chess run' (Forth: load the file, then its word)
    local f1, f2 = u:match("^load (%S+) (%S+)$")
    if not f1 then f1 = u:match("^load (%S+)$") end
    if f1 and f1 ~= "with" then pre, post = "load " .. f1 .. "\n", f2 and (f2 .. "\n") or ""; return end
    -- BK-0010: 'Load file ALJUR .COD inside the Monitor'
    a, b = l:match("^load file ()().- inside the monitor$")
    if a then
      local e2 = l:find(" inside the monitor$")
      pre, post = "MONIT\nM" .. trim(u:sub(a, e2 - 1)) .. "\n", "S\n"; return
    end
    -- Sorcerer: 'Boot to Monitor, LOG'
    a, b = l:match("^boot to monitor, ()%S+()$")
    if a then pre, post = cut(a, b) .. "\n", ""; return end
    local lm = l:match("^load with ()")
    local sm = l:match("^start with ()") or l:match("^run with ()")
    local uc = lm and u:sub(lm) or nil
    -- "xx" is a placeholder, not a command
    if uc and (" " .. uc:lower() .. " "):find("[^%w_]xx[^%w_]") then uc = nil end
    if uc then
      -- the command ends at the note's first sentence ("Load with
      -- RUN"CAS:". This software was designed for ...")
      uc = trim((uc .. ". "):match("^(.-)%. "))
      local x, y = uc:match("^(.-) %+ (.*)$")
      if x then
        pre, post = trim(x) .. "\n", trim(y) .. "\n"
      else
        pre = uc .. "\n"
        -- a load that runs the program itself (",R") needs nothing after it
        if uc:match(",%s*[Rr]%s*$") then post = "" end
      end
    elseif sm then
      post = trim(u:sub(sm)):gsub('^"+', ""):gsub('"+$', "") .. "\n"
    end
  end
end

-- Amstrad CPC .dsk: the directory (track 0 C1-C4, 2 41-44 or 1 01-04);
-- RUN"DISC, a loader, the first BASIC or binary file, else |CPM
local function cpc_run(d)
  local ext = d:sub(1, 8) == "EXTENDED"
  local ntr, sides = d:byte(0x31), d:byte(0x32); if sides == 0 then sides = 1 end
  local off, secs = 0x100, {}
  for t = 0, ntr * sides - 1 do
    local tsz = ext and d:byte(0x35 + t) * 256 or u16(d, 0x33)
    if tsz ~= 0 then
      if d:sub(off + 1, off + 10) ~= "Track-Info" then break end
      local trk, ns, p = d:byte(off + 0x11), d:byte(off + 0x16), off + 0x100
      for i = 0, ns - 1 do
        local si = off + 0x18 + 8 * i
        local R, N = d:byte(si + 3), d:byte(si + 4)
        local ln = ext and u16(d, si + 7) or (128 << N)
        local k = trk .. ":" .. R
        if not secs[k] then secs[k] = d:sub(p + 1, p + ln) end
        p = p + ln
      end
      off = off + tsz
    end
  end
  local dirb = ""
  for _, tb in ipairs({ { 0, 0xC1 }, { 2, 0x41 }, { 1, 0x01 } }) do
    if secs[tb[1] .. ":" .. tb[2]] then
      for i = 0, 3 do dirb = dirb .. (secs[tb[1] .. ":" .. (tb[2] + i)] or "") end
      break
    end
  end
  local files, seen = {}, {}
  for i = 1, #dirb - 31, 32 do
    if dirb:byte(i) == 0 and dirb:byte(i + 12) == 0 then
      local nm, ex = "", ""
      for j = 1, 8 do nm = nm .. string.char(dirb:byte(i + j) & 0x7f) end
      for j = 9, 11 do ex = ex .. string.char(dirb:byte(i + j) & 0x7f) end
      nm, ex = trim(nm), trim(ex)
      if printable(nm .. ex) and not seen[nm .. "." .. ex] then
        seen[nm .. "." .. ex] = true; files[#files + 1] = { nm, ex }
      end
    end
  end
  if #files == 0 then return "|CPM" end
  local pref = { DISC = 1, DISK = 1, LOADER = 1, MENU = 1, START = 1, RUN = 1, GO = 1 }
  for _, f in ipairs(files) do
    local e = f[2]:upper()
    if pref[f[1]:upper()] and (e == "" or e == "BAS" or e == "BIN") then return 'RUN"' .. f[1] end
  end
  for _, want in ipairs({ "BAS", "", "BIN" }) do
    for _, f in ipairs(files) do
      if f[2]:upper() == want then return 'RUN"' .. f[1] .. (f[2] ~= "" and ("." .. f[2]) or "") end
    end
  end
  return "|CPM"
end

local LOADERS = { MENU = 1, START = 1, BOOT = 1, LOADER = 1, RUN = 1, GO = 1, INTRO = 1, TITLE = 1, AUTO = 1 }

-- DragonDOS (.vdk or raw): BOOT when track 0 sector 3 starts with "OS",
-- else the directory (track 20, sectors 3-18, 25-byte entries): a
-- loader-like BASIC name, the first BASIC file, else the first binary
local function dragon_run(d)
  local off = d:sub(1, 2) == "dk" and u16(d, 3) or 0
  if d:sub(off + 513, off + 514) == "OS" then return "BOOT" end
  local base, files = off + 20 * 18 * 256, {}
  for sct = 2, 17 do
    local sec = d:sub(base + sct * 256 + 1, base + sct * 256 + 250)
    local stop = false
    for i = 1, #sec - 24, 25 do
      local fl = sec:byte(i)
      if fl & 0x08 ~= 0 then stop = true; break end
      if fl & 0xA1 == 0 then
        local nm = trim((sec:sub(i + 1, i + 8) .. "\0"):match("^(.-)%z"))
        local ex = trim((sec:sub(i + 9, i + 11) .. "\0"):match("^(.-)%z")):upper()
        if printable(nm .. ex) then files[#files + 1] = { nm, ex } end
      end
    end
  end
  if #files == 0 then return "BOOT" end
  for _, f in ipairs(files) do if f[2] == "BAS" and LOADERS[f[1]:upper()] then return 'RUN"' .. f[1] .. '"' end end
  for _, f in ipairs(files) do if f[2] == "BAS" then return 'RUN"' .. f[1] .. '"' end end
  for _, f in ipairs(files) do if f[2] == "BIN" then return 'LOAD"' .. f[1] .. '.BIN":EXEC' end end
  return "BOOT"
end

-- Disk Extended BASIC (.dsk, 18x256 per track): the directory on track 17
-- sectors 3-11, 32-byte entries (name 8, ext 3, type: 0 BASIC, 2 machine
-- code); no directory: DOS (OS-9 boot track)
local function coco_run(d)
  local off = d:sub(1, 2) == "dk" and u16(d, 3) or (#d % 256)
  local base, files = off + 17 * 18 * 256, {}
  for sct = 2, 10 do
    local sec = d:sub(base + sct * 256 + 1, base + sct * 256 + 256)
    for i = 1, 225, 32 do
      if #sec < i + 31 or sec:byte(i) == 0xFF then break end
      if sec:byte(i) ~= 0 then
        local nm, ex = trim(sec:sub(i, i + 7)), trim(sec:sub(i + 8, i + 10)):upper()
        if printable(nm .. ex) then files[#files + 1] = { nm, ex, sec:byte(i + 11) } end
      end
    end
  end
  if #files == 0 then return "DOS" end
  for _, f in ipairs(files) do if f[3] == 0 and LOADERS[f[1]:upper()] then return 'RUN"' .. f[1] .. '"' end end
  for _, f in ipairs(files) do if f[3] == 0 and f[2] == "BAS" then return 'RUN"' .. f[1] .. '"' end end
  for _, f in ipairs(files) do
    if f[3] == 2 then return 'LOADM"' .. f[1] .. (f[2] ~= "" and ("." .. f[2]) or "") .. '":EXEC' end
  end
  return "DOS"
end

pcall(function()
  local pre0 = pre
  if has("usage") then apply_usage() end
  local lg = game:lower()
  if has("cpc") and lg:match("%.dsk$") then
    local d = readf(game); if d and #d > 0x200 then pre = cpc_run(d) .. "\n" end
  end
  if has("dragon") and (lg:match("%.vdk$") or lg:match("%.dsk$") or lg:match("%.dmk$")) then
    local d = readf(game); if d and #d > 0x400 then pre = dragon_run(d) .. "\n" end
  end
  if has("coco") and pre == pre0 and (lg:match("%.dsk$") or lg:match("%.vdk$") or lg:match("%.dmk$")) then
    local d = readf(game); if d and #d > 0x400 then pre = coco_run(d) .. "\n" end
  end
  pre = prefix .. pre
  if has("ml") and (lg:match("%.cas$") or lg:match("%.c10$")) then
    -- the name block: 55 3C 00 len, 8-byte name, then the type (2 = code)
    local b = readf(game, 4096) or ""
    local i = b:find("\60\0", 1, true)
    if i and #b >= i + 11 and b:byte(i + 11) == 2 then pre, post = "CLOADM\n", "EXEC\n" end
  end
  if has("mo5") and lg:match("%.k7$") and pre == prefix .. 'RUN""\n' then
    -- the header block: 3C 5A 00 len, 8-byte name, 3-byte extension, then
    -- the type (2 = machine code, which RUN"" refuses with Error 51)
    local b = readf(game, 16384) or ""
    local i = b:find("\60\90\0", 1, true)
    if i and #b >= i + 15 and b:byte(i + 15) == 2 then pre = prefix .. 'LOADM"",,R\n' end
  end
end)

local function type_text(s)
  if gap <= 0 then manager.machine.natkeyboard:post(s); return end
  for ch in s:gmatch(".") do q[#q + 1] = ch end
end
gameflix_tape = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if #q > 0 and t >= q_t and manager.machine.natkeyboard.empty then
    manager.machine.natkeyboard:post(table.remove(q, 1)); q_t = t + gap
  end
  if not booted and boot ~= "" and t >= 2 then manager.machine.natkeyboard:post(boot); booted = true end
  if stage == 0 and t >= @T@ then
    -- a machine with several keyboard devices (TVC) has natural keyboard input off on them
    pcall(function() for _, k in pairs(manager.machine.natkeyboard.keyboards) do k.enabled = true end end)
    if pre ~= "" then type_text(pre) end
    stage = 1
  elseif stage == 1 and t >= @T@ + 1.5 and #q == 0 and manager.machine.natkeyboard.empty then
    -- only once the command is typed: with a slow keyboard the tape would run
    -- ahead of a long command (Jupiter Ace)
    for tag, c in pairs(manager.machine.cassettes) do c:play() end
    stage = 2
  elseif stage == 2 then
    if @WAIT@ > 0 and t >= @T@ + @WAIT@ then stage = 3; t_end = t end
    for tag, c in pairs(manager.machine.cassettes) do
      if c.length > 0 and c.position >= c.length - 0.2 then stage = 3; t_end = t end
    end
  elseif stage == 3 and t >= t_end + 2 then
    if post ~= "" then type_text(post) end
    stage = 4
  end
end)
