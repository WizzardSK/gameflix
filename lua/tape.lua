-- gameflix: a tape (or a disk started by a typed command). The launcher fills
-- in the @...@ fields from the platform's -gameflix_tape spec: type PRE after
-- T emulated seconds, play the tape, and once it has run out (or after WAIT s
-- when there is no tape) type POST. GAP > 0 types one character every GAP s,
-- for keyboards that drop keys at the natural keyboard's rate; BOOT is a key
-- the machine wants at power-on (SPC-1000: B for BASIC).
local stage, t_end = 0, 0
local pre, post = "@PRE@", "@POST@"
local boot, booted = "@BOOT@", false
local gap, q, q_t = @GAP@, {}, 0
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
