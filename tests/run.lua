-- Unit tests for solana-flappy/lib/game.lua. Plain Lua 5.5, no dependencies.
--
--   lua tests/run.lua        (run from the repository root)
--
-- Exits non-zero if any test fails. The game logic has no badge API in it, so
-- nothing here needs the emulator.

package.path = "solana-flappy/?.lua;" .. package.path
local game = require("lib.game")

local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("ok    " .. name)
  else
    failed = failed + 1
    print("FAIL  " .. name .. "\n      " .. tostring(err))
  end
end

local function eq(got, want, what)
  if got ~= want then
    error(string.format("%s: expected %s, got %s", what or "value", tostring(want), tostring(got)), 2)
  end
end

local function near(got, want, tol, what)
  if math.abs(got - want) > tol then
    error(string.format("%s: expected %s +/- %s, got %s", what or "value", want, tol, got), 2)
  end
end

local STEP = game.STEP_MS / 1000

-- A deterministic stand-in for math.random: every gap starts at y = 60.
local function fixed_gap() return 60 end
local GAP_CENTRE = 60 + game.GAP // 2

-- Start a run (SELECT on the title screen) with a fixed gap position.
local function started()
  local s = game.new(fixed_gap)
  game.flap(s)
  s.ev_flap = false
  return s
end

------------------------------------------------------------------ physics
test("title screen: nothing moves until the first flap", function()
  local s = game.new(fixed_gap)
  local y, x = s.y, s.pipes[1].x
  game.update(s, 1000)
  eq(s.y, y, "bird y")
  eq(s.pipes[1].x, x, "pipe x")
  eq(s.phase, "ready", "phase")
end)

test("the first flap starts the run and launches the bird upward", function()
  local s = game.new(fixed_gap)
  eq(game.flap(s), true, "flap accepted")
  eq(s.phase, "play", "phase")
  eq(s.vy, game.FLAP_V, "vy")
  eq(s.ev_flap, true, "flap event")
end)

test("gravity pulls the bird down by GRAVITY*dt each step", function()
  local s = started()
  s.vy = 0
  game.update(s, game.STEP_MS)
  near(s.vy, game.GRAVITY * STEP, 1e-9, "vy after one step")
  game.update(s, game.STEP_MS)
  near(s.vy, 2 * game.GRAVITY * STEP, 1e-9, "vy after two steps")
end)

test("a flap sets the velocity, it does not add to it", function()
  local s = started()
  game.flap(s)
  game.flap(s)
  game.flap(s)
  eq(s.vy, game.FLAP_V, "vy after three flaps")
end)

test("falling speed is capped at MAX_FALL", function()
  local s = started()
  s.y = 60  -- high up, so the bird doesn't hit the ground first
  s.vy = game.MAX_FALL - 1
  for _ = 1, 3 do s.pipes[1].x = 1000; s.pipes[2].x = 1000; s.pipes[3].x = 1000; game.update(s, game.STEP_MS) end
  near(s.vy, game.MAX_FALL, 1e-9, "terminal velocity")
end)

test("free fall follows y = y0 + vy*t + g*t^2/2 within the integrator's error", function()
  local s = started()
  s.y, s.vy = 40, 0
  -- 0.3 s: the speed reaches 330 px/s, still under MAX_FALL (420), and the bird is
  -- still well above the ground
  for _ = 1, 20 do
    s.pipes[1].x, s.pipes[2].x, s.pipes[3].x = 1000, 1000, 1000
    game.update(s, game.STEP_MS)
  end
  local t = 20 * STEP
  -- semi-implicit Euler overshoots the exact parabola by about g*t*dt/2
  near(s.y, 40 + 0.5 * game.GRAVITY * t * t, game.GRAVITY * t * STEP, "y after 0.3 s")
end)

test("fixed timestep: the same elapsed time gives the same result at any tick length", function()
  local function play(tick)
    math.randomseed(5)
    local s = game.new(math.random)
    game.flap(s)
    local total = 0
    -- Flap on a schedule in game time. Total time and flap times are multiples of
    -- every tick length tried (15, 30, 45, 90 ms; 90 is the stall cap, MAX_FRAME_MS), so each run sees the same
    -- inputs at the same moments and differs only in how time is sliced.
    while total < 3150 do
      if total % 450 == 0 then game.flap(s) end
      game.update(s, tick)
      total = total + tick
    end
    return s.y, s.vy, s.pipes[1].x, s.score, s.phase
  end
  local y0, vy0, x0, sc0, ph0 = play(15)
  for _, tick in ipairs({ 30, 45, 90 }) do
    local y, vy, x, sc, ph = play(tick)
    near(y, y0, 1e-9, "y at tick " .. tick)
    near(vy, vy0, 1e-9, "vy at tick " .. tick)
    near(x, x0, 1e-9, "pipe x at tick " .. tick)
    eq(sc, sc0, "score at tick " .. tick)
    eq(ph, ph0, "phase at tick " .. tick)
  end
end)

------------------------------------------------------------------ collision
test("circle_hits_rect: a circle inside the rectangle hits", function()
  eq(game.circle_hits_rect(50, 50, 5, 40, 40, 20, 20), true)
end)

test("circle_hits_rect: a circle clearly outside misses", function()
  eq(game.circle_hits_rect(100, 50, 5, 40, 40, 20, 20), false)
end)

test("circle_hits_rect: a side overlap hits, a side gap misses", function()
  eq(game.circle_hits_rect(35, 50, 6, 40, 40, 20, 20), true, "overlapping the left side")
  eq(game.circle_hits_rect(33, 50, 6, 40, 40, 20, 20), false, "7 px from the left side")
end)

test("circle_hits_rect: corners use the real distance, not the bounding box", function()
  -- the circle's bounding box touches the rectangle but the circle itself doesn't:
  -- centre (36, 36), r = 5; nearest rectangle point is (40, 40), distance sqrt(32) = 5.66
  eq(game.circle_hits_rect(36, 36, 5, 40, 40, 20, 20), false, "near corner, outside")
  eq(game.circle_hits_rect(37, 37, 5, 40, 40, 20, 20), true, "near corner, inside (distance 4.24)")
end)

test("circle_hits_rect: merely touching is not a hit", function()
  eq(game.circle_hits_rect(35, 50, 5, 40, 40, 20, 20), false)
end)

test("hitting the ground ends the run", function()
  local s = started()
  s.y = game.PLAY_H - game.BIRD_R - 0.1
  s.vy = 200
  for i = 1, 3 do s.pipes[i].x = 1000 end
  game.update(s, game.STEP_MS)
  eq(s.phase, "dead", "phase")
  eq(s.y, game.PLAY_H - game.BIRD_R, "bird rests on the ground")
  eq(s.ev_die, true, "die event")
end)

test("flying into a pipe's top section ends the run", function()
  local s = started()
  s.pipes[1].x = game.BIRD_X - game.PIPE_W / 2   -- pipe directly over the bird
  s.y, s.vy = 30, 0                              -- above the gap (gap_y = 60)
  game.update(s, game.STEP_MS)
  eq(s.phase, "dead", "phase")
end)

test("flying into a pipe's bottom section ends the run", function()
  local s = started()
  s.pipes[1].x = game.BIRD_X - game.PIPE_W / 2
  s.y, s.vy = 60 + game.GAP + 15, 0              -- below the gap
  game.update(s, game.STEP_MS)
  eq(s.phase, "dead", "phase")
end)

test("flying through the middle of the gap is safe", function()
  local s = started()
  s.pipes[1].x = game.BIRD_X - game.PIPE_W / 2
  for _ = 1, 40 do                               -- cross the whole pipe
    s.y, s.vy = GAP_CENTRE, 0
    game.update(s, game.STEP_MS)
  end
  eq(s.phase, "play", "phase")
end)

test("the gap is exactly GAP pixels tall: just inside survives, just outside dies", function()
  local function through(y)
    local s = started()
    s.pipes[1].x = game.BIRD_X - game.PIPE_W / 2
    s.y, s.vy = y, 0
    game.update(s, game.STEP_MS)
    return s.phase
  end
  -- gap_y = 60, so the free span is 60 .. 60+GAP; the bird needs BIRD_R of clearance
  eq(through(60 + game.BIRD_R + 1), "play", "1 px inside the top edge")
  eq(through(60 + game.BIRD_R - 2), "dead", "2 px into the top pipe")
  eq(through(60 + game.GAP - game.BIRD_R - 1), "play", "1 px inside the bottom edge")
  eq(through(60 + game.GAP - game.BIRD_R + 2), "dead", "2 px into the bottom pipe")
end)

test("a dead bird no longer collides or scores, and the die event fires once", function()
  local s = started()
  s.pipes[1].x = game.BIRD_X - game.PIPE_W / 2
  s.y, s.vy = 20, 0
  game.update(s, game.STEP_MS)
  eq(s.phase, "dead")
  s.ev_die = false
  for _ = 1, 100 do game.update(s, game.STEP_MS) end
  eq(s.ev_die, false, "no second die event")
  eq(s.score, 0, "score")
end)

------------------------------------------------------------------ scoring
-- Keep the bird in the middle of the gap so only scoring is exercised.
local function run_in_gap(seconds)
  local s = started()
  local steps = math.floor(seconds * 1000 / game.STEP_MS + 0.5)
  for _ = 1, steps do
    s.y, s.vy = GAP_CENTRE, 0
    game.update(s, game.STEP_MS)
  end
  return s
end

test("the score is 0 until the first pipe is fully behind the bird", function()
  -- first pipe starts at W+60 and passes when its right edge clears BIRD_X - BIRD_R
  local distance = (game.W + 60) - (game.BIRD_X - game.BIRD_R - game.PIPE_W)
  local pass_time = distance / game.SPEED
  eq(run_in_gap(pass_time - 0.1).score, 0, "just before")
  eq(run_in_gap(pass_time + 0.1).score, 1, "just after")
end)

test("scoring pipes arrive one every SPACING / SPEED seconds", function()
  local distance = (game.W + 60) - (game.BIRD_X - game.BIRD_R - game.PIPE_W)
  local first = distance / game.SPEED
  local every = game.SPACING / game.SPEED
  for n = 1, 4 do
    local t = first + (n - 1) * every + 0.1
    eq(run_in_gap(t).score, n, "score after " .. n .. " pipes")
  end
end)

test("scoring raises the score event", function()
  local s = started()
  local seen = false
  for _ = 1, 400 do
    s.y, s.vy = GAP_CENTRE, 0
    game.update(s, game.STEP_MS)
    if s.ev_score then seen = true; break end
  end
  eq(seen, true, "score event")
  eq(s.score, 1, "score")
end)

test("reset returns to the title with a zero score", function()
  local s = run_in_gap(6)
  assert(s.score > 0, "setup should have scored")
  game.reset(s)
  eq(s.phase, "ready", "phase")
  eq(s.score, 0, "score")
  eq(s.vy, 0, "vy")
  eq(s.y, game.READY_Y, "y")
end)

------------------------------------------------------------------ determinism
test("the same random function gives the same run", function()
  local function seq()
    math.randomseed(99)
    local s = game.new(math.random)
    local out = {}
    for i = 1, game.NPIPES do out[i] = s.pipes[i].gap_y end
    return table.concat(out, ",")
  end
  eq(seq(), seq(), "gap positions")
end)

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
