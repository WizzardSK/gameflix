-- Canon X-07: LOAD"CAS:" with the quotes as Shift+2 held by field (the
-- natural keyboard types them as 2), play the tape, RUN when it ran out
local F, stage, t0, t_end = nil, 0, 0, 0
local function find(name)
  for tag, port in pairs(manager.machine.ioport.ports) do
    for n, f in pairs(port.fields) do
      local l = string.lower(n)
      if l == name or l:match("^" .. name .. "%s") then return f end
    end
  end
end
local seq = {}
local function quote() seq[#seq+1] = {"shift", 1}; seq[#seq+1] = {"2", 1}; seq[#seq+1] = {"2", 0}; seq[#seq+1] = {"shift", 0} end
local step, st = 1, 0
gameflix_x07 = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  local nk = manager.machine.natkeyboard
  if stage == 0 and t >= 6 then
    pcall(function() for _, k in pairs(nk.keyboards) do k.enabled = true end end)
    nk:post("LOAD"); stage = 1
  elseif stage == 1 and nk.empty then
    seq = {}; quote(); step = 1; st = t; stage = 2
  elseif stage == 2 then
    if seq[step] and t >= st + 0.15 then
      local f = find(seq[step][1]); if f then if seq[step][2] == 1 then f:set_value(1) else f:clear_value() end end
      step = step + 1; st = t
    elseif not seq[step] then nk:post("CAS:"); stage = 3 end
  elseif stage == 3 and nk.empty then
    seq = {}; quote(); step = 1; st = t; stage = 4
  elseif stage == 4 then
    if seq[step] and t >= st + 0.15 then
      local f = find(seq[step][1]); if f then if seq[step][2] == 1 then f:set_value(1) else f:clear_value() end end
      step = step + 1; st = t
    elseif not seq[step] then
      for tag, c in pairs(manager.machine.cassettes) do c:play() end
      t0 = t; stage = 5
    end
  elseif stage == 5 and t >= t0 + 0.5 then
    nk:post("\r"); stage = 6
  elseif stage == 6 then
    for tag, c in pairs(manager.machine.cassettes) do
      if c.length > 0 and c.position >= c.length - 0.2 then stage = 7; t_end = t end
    end
  elseif stage == 7 and t >= t_end + 2 then nk:post("RUN\r"); stage = 8 end
end)
