-- ZX Spectrum 48K: LOAD "" typed as key presses (the natural keyboard does not
-- reach it): J (LOAD in keyword mode), SYMBOL SHIFT+P twice ("), ENTER, then
-- the tape played (emulated seconds)
local function field(pat)
  for tag,port in pairs(manager.machine.ioport.ports) do
    for name,f in pairs(port.fields) do if name:lower():match(pat) then return f end end
  end
end
local plan = {{4,{"^j"}},{4.6,{"symbol shift","^p"}},{5.2,{"symbol shift","^p"}},{5.8,{"^enter"}},{6.5,"play"}}
local held, t_rel, idx = {}, 0, 1
gameflix_spec = emu.add_machine_frame_notifier(function()
  local t = manager.machine.time:as_double()
  if #held > 0 and t >= t_rel then for _,f in ipairs(held) do f:clear_value() end; held = {} end
  if #held > 0 or idx > #plan then return end
  local s = plan[idx]
  if t < s[1] then return end
  if s[2] == "play" then for tag,c in pairs(manager.machine.cassettes) do c:play() end
  else
    for _,p in ipairs(s[2]) do local f = field(p); if f then f:set_value(1); held[#held+1] = f end end
    t_rel = t + 0.15
  end
  idx = idx + 1
end)
