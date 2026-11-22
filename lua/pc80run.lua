-- gameflix: a PC-8001 disk that boots into BASIC without starting its program
-- (-gameflix_lua pc80run): RUN"name" with the first file of the disk's
-- directory, or the password the software list notes for a disk that asks
-- for one. @GAME@ = the D88 image, @HASH@ / @ITEM@ = its list entry.
-- The directory is cylinder 18, head 1, 16-byte entries (name 6 +
-- extension 3, attribute, first cluster), 0xFF = unused.
local game, hash, item = "@GAME@", "@HASH@", "@ITEM@"
local function readf(p)
  if p == "" or p:sub(1, 1) == "@" then return nil end
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read("a"); f:close(); return d
end
local function u16(d, p) return d:byte(p) + d:byte(p + 1) * 256 end
local function u32(d, p) return u16(d, p) + u16(d, p + 2) * 65536 end

local function first_file(d)
  if not d or #d < 0x2C0 then return nil end
  local secs = {}
  for t = 0, 163 do
    local o = u32(d, 0x21 + 4 * t)
    if o ~= 0 and o + 16 <= #d then
      local p, cnt = o, 0
      while p + 16 <= #d do
        local c, h, r = d:byte(p + 1), d:byte(p + 2), d:byte(p + 3)
        local nsec, size = u16(d, p + 5), u16(d, p + 15)
        secs[c .. ":" .. h .. ":" .. r] = d:sub(p + 17, p + 16 + size)
        p = p + 16 + size; cnt = cnt + 1
        if cnt >= nsec then break end
      end
    end
  end
  for r = 1, 12 do
    local sec = secs["18:1:" .. r]
    if sec then
      for i = 1, #sec - 15, 16 do
        local b = sec:byte(i)
        if b ~= 0 and b ~= 0xFF and not sec:sub(i, i + 8):find("[^\32-\126]") then
          local name = sec:sub(i, i + 5):gsub("%s+$", "")
          local ext = sec:sub(i + 6, i + 8):gsub("%s+$", "")
          if name ~= "" then return name .. (ext ~= "" and ("." .. ext) or "") end
        end
      end
    end
  end
  return nil
end

local function password()
  local x = readf(hash); if not x then return nil end
  local s = x:find('<software name="' .. item .. '"', 1, true); if not s then return nil end
  local e = x:find("</software>", s, true) or #x
  local b = x:sub(s, e)
  return b:match('password[^"]-Insert (%w+)') or b:match("Insert (%w+) then ENTER when prompted for password")
end

local name, pass = "", ""
pcall(function() name = (first_file(readf(game)) or ""):gsub('"', "") end)
pcall(function() pass = password() or "" end)
local n = 0
gameflix_pc80 = emu.add_machine_frame_notifier(function()
  n = n + 1
  if n == 900 then
    if pass ~= "" then
      manager.machine.natkeyboard:post(pass .. "\r")
    elseif name ~= "" then
      manager.machine.natkeyboard:post('run"' .. name .. '"\r')
    end
  end
end)
