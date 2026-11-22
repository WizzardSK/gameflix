-- Compucolor II: the AUTO key at 6 s (boots the disk, emulated seconds)
local plan = {{6, "key", "auto"}}
local keys, shift, ctrl = nil, nil, nil
local function scan()
  keys = {}
  local out = nil
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do
      if out then out:write(tag .. " | " .. n .. "\n") end
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
          for _, ch in ipairs({a, a:lower(), a:upper()}) do
            if not keys[ch] or (strong and not keys[ch][3]) then keys[ch] = {f, false, strong} end
          end
        end
        if toks[2] and #toks[2] == 1 and not keys["s" .. toks[2]] then keys["s" .. toks[2]] = {f, true} end
        keys["name:" .. l] = {f, false}
      end
      if l == "space" or l:match("^space") then keys[" "] = {f, false} end
      if l == "return" or l == "enter" or l:match("^return") or l:match("^enter") or l == "cr" or l:match("^cr%s") then keys["\r"] = {f, false} end
    end
  end
  if out then out:close() end
end
local q, qt, i = {}, 0, 1
local function push_char(c)
  local k = keys[c] or keys["s" .. c]
  if c == "\n" then k = keys["\r"] end
  if not k then return end
  local sh = (keys[c] == nil) and k[2]
  if sh and shift then q[#q + 1] = {shift, 1} end
  q[#q + 1] = {k[1], 1}; q[#q + 1] = {k[1], 0}
  if sh and shift then q[#q + 1] = {shift, 0} end
end
gameflix_typer = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if not keys then scan() end
  if #q > 0 then
    if t >= qt then local s = table.remove(q, 1); if s[2] == 1 then s[1]:set_value(1) else s[1]:clear_value() end; qt = t + 0.08 end
    return
  end
  local p = plan[i]
  if p and t >= p[1] then
    if p[2] == "type" then for c in p[3]:gmatch(".") do push_char(c) end
    elseif p[2] == "key" then local k = keys["name:" .. p[3]]; if not k then for n, v in pairs(keys) do if n:match("^name:" .. p[3]) then k = v; break end end end; if k then q[#q + 1] = {k[1], 1}; q[#q + 1] = {k[1], 0} end
    elseif p[2] == "nat" then
      pcall(function() for _, k in pairs(manager.machine.natkeyboard.keyboards) do k.enabled = true end end)
      manager.machine.natkeyboard:post(p[3])
    elseif p[2] == "play" then for tag, c in pairs(manager.machine.cassettes) do c:play() end
    end
    i = i + 1
  end
end)
