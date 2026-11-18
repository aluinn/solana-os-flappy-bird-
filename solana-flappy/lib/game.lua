-- Pure game logic for Solana Flappy: physics, pipes, collision, scoring.
-- No badge API in here (no ui, led, storage, sys), so tests/ can run it with
-- plain Lua 5.5. main.lua owns the drawing and the input.
--
-- Units: pixels and seconds. The simulation advances in fixed steps of STEP_MS
-- whatever the tick length, so the game plays the same at any frame rate.
-- Everything is preallocated in new(): stepping creates no tables or strings.

local M = {}

-- Playfield (the badge's app area is 320 x 218; the bottom 28 px are ground and hint bar)
M.W = 320
M.PLAY_H = 190          -- y of the ground's top edge

-- Bird
M.BIRD_X = 72           -- centre x, fixed
M.BIRD_R = 9            -- collision radius (the sprite is 24 x 24, a little forgiving)
M.READY_Y = 150         -- where the bird waits on the title screen (below the title card)
M.GRAVITY = 1100        -- px/s^2
M.FLAP_V = -280         -- px/s, set (not added) on each flap
M.MAX_FALL = 420        -- px/s terminal velocity

-- Pipes
M.PIPE_W = 36
M.GAP = 84
M.GAP_MARGIN = 24       -- the gap never gets closer than this to the ceiling or ground
M.SPACING = 150         -- px between consecutive pipes
M.SPEED = 100           -- px/s
M.NPIPES = 3

-- Timing
M.STEP_MS = 15          -- fixed step: two per 30 ms badge tick
M.MAX_FRAME_MS = 90     -- a long stall is clamped instead of replayed
M.RESTART_DELAY_MS = 600 -- after dying, ignore SELECT briefly so a flap spam doesn't skip the result

local STEP = M.STEP_MS / 1000

-- phase: "ready" (title), "play", "dead"
function M.new(rand)
  local s = {
    rand = rand or math.random,
    phase = "ready",
    y = M.READY_Y, vy = 0,
    score = 0,
    acc = 0,            -- ms carried between ticks
    dead_ms = 0,        -- time since dying
    pipes = {},
    -- one-shot events for the caller; it clears them after reading
    ev_flap = false, ev_score = false, ev_die = false,
  }
  for i = 1, M.NPIPES do s.pipes[i] = { x = 0, gap_y = 0, scored = false } end
  M.reset(s)
  return s
end

local function place(s, p, x)
  p.x = x
  p.gap_y = s.rand(M.GAP_MARGIN, M.PLAY_H - M.GAP_MARGIN - M.GAP)
  p.scored = false
end

-- Back to the title screen, ready for a new run.
function M.reset(s)
  s.phase = "ready"
  s.y, s.vy = M.READY_Y, 0
  s.score, s.acc, s.dead_ms = 0, 0, 0
  for i = 1, M.NPIPES do
    place(s, s.pipes[i], M.W + 60 + (i - 1) * M.SPACING)
  end
end

local function die(s)
  if s.phase ~= "play" then return end
  s.phase = "dead"
  s.dead_ms = 0
  s.ev_die = true
end

-- SELECT. Starts a run from the title, flaps in play, restarts after the
-- restart delay when dead. Returns true if the press did something.
function M.flap(s)
  if s.phase == "ready" then
    s.phase = "play"
  elseif s.phase == "dead" then
    if s.dead_ms < M.RESTART_DELAY_MS then return false end
    M.reset(s)
    s.phase = "play"
  end
  s.vy = M.FLAP_V
  s.ev_flap = true
  return true
end

-- Does the circle (cx, cy, r) touch the rectangle (rx, ry, rw, rh)?
function M.circle_hits_rect(cx, cy, r, rx, ry, rw, rh)
  local nx = cx < rx and rx or (cx > rx + rw and rx + rw or cx)
  local ny = cy < ry and ry or (cy > ry + rh and ry + rh or cy)
  local dx, dy = cx - nx, cy - ny
  return dx * dx + dy * dy < r * r
end

local function hits_pipe(s, p)
  local bx, by, r = M.BIRD_X, s.y, M.BIRD_R
  if bx + r <= p.x or bx - r >= p.x + M.PIPE_W then return false end
  return M.circle_hits_rect(bx, by, r, p.x, 0, M.PIPE_W, p.gap_y)
      or M.circle_hits_rect(bx, by, r, p.x, p.gap_y + M.GAP, M.PIPE_W, M.PLAY_H)
end

local function step(s)
  if s.phase == "ready" then return end

  -- bird
  s.vy = s.vy + M.GRAVITY * STEP
  if s.vy > M.MAX_FALL then s.vy = M.MAX_FALL end
  s.y = s.y + s.vy * STEP

  if s.phase == "dead" then
    s.dead_ms = s.dead_ms + M.STEP_MS
    if s.y > M.PLAY_H - M.BIRD_R then s.y, s.vy = M.PLAY_H - M.BIRD_R, 0 end
    return
  end

  -- ceiling is a soft wall: you bump it, it doesn't kill you
  if s.y < M.BIRD_R then s.y, s.vy = M.BIRD_R, 0 end

  -- pipes scroll left; the one that leaves is recycled behind the last
  local far = 0
  for i = 1, M.NPIPES do
    local p = s.pipes[i]
    p.x = p.x - M.SPEED * STEP
    if p.x > far then far = p.x end
  end
  for i = 1, M.NPIPES do
    local p = s.pipes[i]
    if p.x + M.PIPE_W < 0 then
      place(s, p, far + M.SPACING)
      far = p.x
    elseif not p.scored and p.x + M.PIPE_W < M.BIRD_X - M.BIRD_R then
      p.scored = true
      s.score = s.score + 1
      s.ev_score = true
    end
  end

  -- collisions
  if s.y + M.BIRD_R >= M.PLAY_H then
    s.y = M.PLAY_H - M.BIRD_R
    die(s)
    return
  end
  for i = 1, M.NPIPES do
    if hits_pipe(s, s.pipes[i]) then
      die(s)
      return
    end
  end
end

-- Advance by `ms` of real time (the on_tick argument). Runs 0..n fixed steps.
function M.update(s, ms)
  if ms > M.MAX_FRAME_MS then ms = M.MAX_FRAME_MS end
  s.acc = s.acc + ms
  while s.acc >= M.STEP_MS do
    s.acc = s.acc - M.STEP_MS
    step(s)
  end
end

return M
