-- Solana Flappy: Flappy Bird for the Solana Breakpoint 2026 badge.
-- SELECT flaps, CANCEL leaves. Game rules live in lib/game.lua (no badge API
-- there, so tests/ runs them with plain Lua); this file draws and handles input.

local game = require("lib.game")

local W, PLAY_H = game.W, game.PLAY_H
local PIPE_W, GAP = game.PIPE_W, game.GAP
local floor = math.floor

local COL_BG     = 0x0D0B1A
local COL_PIPE   = 0x9945FF   -- Solana purple
local COL_CAP    = 0xB77BFF
local COL_GROUND = 0x14F195   -- Solana green
local COL_DIRT   = 0x1B1631

local best = storage.get("best")
if type(best) ~= "number" then best = 0 end

local s = game.new()

------------------------------------------------------------------ scene
-- Objects are drawn in the order they are made: back to front.
ui.bg(COL_BG)

local pipe_ui = {}            -- per pipe: top body, top cap, bottom body, bottom cap
for i = 1, game.NPIPES do
  pipe_ui[i] = {
    top  = ui.rect(W, 0, PIPE_W, 0, {color = COL_PIPE}),
    topc = ui.rect(W, 0, PIPE_W + 6, 10, {color = COL_CAP, radius = 2}),
    bot  = ui.rect(W, 0, PIPE_W, 0, {color = COL_PIPE}),
    botc = ui.rect(W, 0, PIPE_W + 6, 10, {color = COL_CAP, radius = 2}),
  }
end

ui.rect(0, PLAY_H, W, ui.H - PLAY_H, {color = COL_DIRT})
ui.rect(0, PLAY_H, W, 4, {color = COL_GROUND})

-- The bird: the Solana coin sprite (24 x 24). If the image can't load, fall back
-- to a gold disc so the game still plays.
local SPR = 24
local bird
do
  local ok, img = pcall(ui.image, 0, 0, "art/coin.png")
  bird = ok and img or ui.rect(0, 0, SPR, SPR, {color = 0xFFC21A, radius = SPR // 2})
end

local score_lbl = ui.label(0, 8, "0", {size = 32, w = W, align = "center", color = 0xFFFFFF})

-- Title and game-over overlays (made last so they sit on top)
local panel = ui.rect(60, 40, 200, 110, {color = 0x1B1631, radius = 8, border = COL_PIPE})
local head  = ui.label(60, 50, "Solana Flappy", {size = 20, w = 200, align = "center", color = COL_GROUND})
local line1 = ui.label(60, 86, "", {size = 14, w = 200, align = "center", color = 0xFFFFFF})
local line2 = ui.label(60, 108, "", {size = 14, w = 200, align = "center", color = "dim"})
local line3 = ui.label(60, 128, "", {size = 14, w = 200, align = "center", color = 0xFFFFFF})

ui.hint("SELECT flap   CANCEL exit")

local function overlay(visible)
  panel:show(visible); head:show(visible)
  line1:show(visible); line2:show(visible); line3:show(visible)
end

local function show_title()
  head:text("Solana Flappy")
  line1:text("Best " .. best)
  line2:text("")
  line3:text("SELECT to start")
  overlay(true)
end

local function show_game_over()
  head:text("Game over")
  line1:text("Score " .. s.score)
  line2:text("Best " .. best)
  line3:text("SELECT to retry")
  overlay(true)
end

------------------------------------------------------------------ LEDs
-- Flash the 8 RGB LEDs briefly on flap, score and crash. Counted down in
-- on_tick rather than with timers (the badge allows only 8).
local led_ms = 0
local function flash(r, g, b, ms)
  if not led then return end
  led.fill(r, g, b)
  led_ms = ms
end

------------------------------------------------------------------ drawing
local shown_score = -1
local last_phase

local function draw(ms)
  -- bird: bobs on the title screen, otherwise follows the simulation
  local by = s.y
  if s.phase == "ready" then by = by + 5 * math.sin(sys.millis() / 180) end
  bird:pos(game.BIRD_X - SPR // 2, floor(by - SPR // 2))

  for i = 1, game.NPIPES do
    local p, u = s.pipes[i], pipe_ui[i]
    local x = floor(p.x)
    local gap_y = p.gap_y
    local bot_y = gap_y + GAP
    u.top:pos(x, 0);            u.top:size(PIPE_W, gap_y)
    u.topc:pos(x - 3, gap_y - 10)
    u.bot:pos(x, bot_y);        u.bot:size(PIPE_W, PLAY_H - bot_y)
    u.botc:pos(x - 3, bot_y)
  end

  if s.score ~= shown_score then
    shown_score = s.score
    score_lbl:text(tostring(s.score))
  end

  if s.phase ~= last_phase then
    last_phase = s.phase
    if s.phase == "play" then overlay(false)
    elseif s.phase == "ready" then show_title()
    else show_game_over() end
  end
end

------------------------------------------------------------------ callbacks
local function save_best()
  if s.score > best then
    best = s.score
    storage.set("best", best)
  end
end

function on_key(key)
  if key == "select" then
    game.flap(s)
    return true
  end
  return false  -- "back" (CANCEL) exits to the launcher
end

function on_tick(ms)
  game.update(s, ms)

  if s.ev_flap then s.ev_flap = false; flash(0x14, 0xF1, 0x95, 60) end
  if s.ev_score then s.ev_score = false; flash(0x99, 0x45, 0xFF, 120) end
  if s.ev_die then
    s.ev_die = false
    flash(0xFF, 0x20, 0x20, 300)
    save_best()
  end

  if led_ms > 0 then
    led_ms = led_ms - ms
    if led_ms <= 0 and led then led.off() end
  end

  draw(ms)
end

function on_exit()
  save_best()
end

show_title()
draw(0)
