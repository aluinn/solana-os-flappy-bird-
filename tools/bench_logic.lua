-- Benchmarks solana-flappy/lib/game.lua under plain desktop Lua 5.5.
--
--   lua tools/bench_logic.lua [steps]    (run from the repository root; default 2,000,000)
--
-- Two things are measured:
--   1. Allocation: with the garbage collector stopped, how much does the heap
--      grow over N simulation steps? A flat ~0.1 KB, the same for 20 thousand
--      steps as for 20 million, is the measurement's own overhead: stepping
--      allocates nothing.
--   2. Time: CPU nanoseconds per fixed step, and per 30 ms badge tick (2 steps).
--
-- These are DESKTOP numbers. The badge's CPU and its 32-bit Lua are different,
-- so use them to compare changes against each other, not to predict the badge.
-- For on-badge-firmware figures (heap, VM instructions) see docs/PERFORMANCE.md.

package.path = "solana-flappy/?.lua;" .. package.path
local game = require("lib.game")

local N = tonumber(arg and arg[1]) or 2000000

math.randomseed(1)
local s = game.new()

-- A cheap bot (no pipe lookups, so its own cost stays small). It dies often;
-- when dead it presses SELECT, which restarts once the restart delay is over.
local function bot()
  if s.phase == "dead" or s.phase == "ready" then
    game.flap(s)
  elseif s.y > 110 and s.vy > 0 then
    game.flap(s)
  end
  s.ev_flap, s.ev_score, s.ev_die = false, false, false
end

local function run(steps, ms)
  for _ = 1, steps do
    bot()
    game.update(s, ms)
  end
end

run(10000, game.STEP_MS)  -- warm up

-- 1. Allocation ------------------------------------------------------------
collectgarbage("collect")
collectgarbage("stop")
local before = collectgarbage("count")
run(N, game.STEP_MS)
local grown = collectgarbage("count") - before
collectgarbage("restart")

-- 2. Time ------------------------------------------------------------------
local function time_it(ms)
  local t0 = os.clock()
  run(N, ms)
  return (os.clock() - t0)
end

local step_s = time_it(game.STEP_MS)    -- one fixed step per call
local tick_s = time_it(30)              -- a badge tick: two fixed steps per call
local bot_t0 = os.clock()
for _ = 1, N do bot() end
local bot_s = os.clock() - bot_t0

print(_VERSION)
print(string.format("steps per measurement:           %d", N))
print(string.format("heap growth with GC stopped:     %.3f KB over %d steps (bot included)", grown, N))
print(string.format("update(15 ms), 1 step, + bot:    %.0f ns", step_s / N * 1e9))
print(string.format("update(30 ms), 2 steps, + bot:   %.0f ns", tick_s / N * 1e9))
print(string.format("bot alone:                       %.0f ns", bot_s / N * 1e9))
print(string.format("-> game.update(30 ms) alone ~    %.0f ns", (tick_s - bot_s) / N * 1e9))
