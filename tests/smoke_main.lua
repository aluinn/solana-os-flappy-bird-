-- Smoke test for solana-flappy/main.lua against a stubbed Solana OS API.
--
--   lua tests/smoke_main.lua        (run from the repository root)
--
-- The stubs mimic the real host's strictness where it bites:
--   * `pos` and `size` and the constructors take INTEGERS. The real host calls
--     luaL_checkinteger, so a number with a fractional part raises an error and
--     stops the app.
--   * a missing `led` module and a PNG that fails to load must not stop the game.
-- This is not the emulator: it checks that main.lua runs and calls the API legally,
-- not how it looks.

package.path = "solana-flappy/?.lua;" .. package.path

local failures = 0
local function check(cond, msg)
  if not cond then failures = failures + 1; print("FAIL  " .. msg) end
end

local function int_args(fname, ...)
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    -- luaL_checkinteger accepts a float with an exact integer value (377.0) and
    -- rejects a fractional one (377.5), so the stub does the same
    if type(v) == "number" and math.tointeger(v) == nil then
      error(string.format("%s: argument %d is %s, the host needs an integer", fname, i, tostring(v)), 3)
    end
  end
end

-- Install fresh stubs and load main.lua. Returns a table of counters.
local function boot(opts)
  opts = opts or {}
  local stats = { objects = 0, text_calls = 0, storage_sets = 0, led_calls = 0 }
  local function object()
    stats.objects = stats.objects + 1
    return setmetatable({}, { __index = function(_, method)
      return function(_, ...)
        if method == "pos" or method == "size" then int_args(method, ...) end
        if method == "text" then stats.text_calls = stats.text_calls + 1 end
      end
    end })
  end
  local clock = 0
  _G.ui = {
    W = 320, H = 218,
    bg = function() end,
    hint = function() end,
    rect = function(...) int_args("ui.rect", ...); return object() end,
    label = function(x, y) int_args("ui.label", x, y); return object() end,
    image = function(x, y, src)
      int_args("ui.image", x, y)
      if opts.image_fails then error("cannot open " .. tostring(src)) end
      return object()
    end,
  }
  if opts.no_led then
    _G.led = nil
  else
    _G.led = {
      fill = function() stats.led_calls = stats.led_calls + 1 end,
      off = function() stats.led_calls = stats.led_calls + 1 end,
    }
  end
  local store = { best = opts.best }
  _G.storage = {
    get = function(k) return store[k] end,
    set = function(k, v) store[k] = v; stats.storage_sets = stats.storage_sets + 1 end,
  }
  _G.sys = { millis = function() return clock end }
  _G.on_key, _G.on_tick, _G.on_exit = nil, nil, nil
  dofile("solana-flappy/main.lua")
  stats.advance = function(ms) clock = clock + ms; on_tick(ms) end
  stats.store = store
  return stats
end

local function play(stats, seconds)
  local t = 0
  while t < seconds * 1000 do
    if t % 450 == 0 then on_key("select") end
    stats.advance(30)
    t = t + 30
  end
end

local function scenario(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("ok    " .. name)
  else
    failures = failures + 1
    print("FAIL  " .. name .. "\n      " .. tostring(err))
  end
end

scenario("loads and defines the three callbacks", function()
  boot()
  check(type(on_key) == "function", "on_key is defined")
  check(type(on_tick) == "function", "on_tick is defined")
  check(type(on_exit) == "function", "on_exit is defined")
end)

scenario("CANCEL is not handled, so the host exits the app; SELECT is handled", function()
  boot()
  check(on_key("back") == false, "on_key('back') returns false")
  check(on_key("select") == true, "on_key('select') returns true")
  check(on_key("left") == false, "other keys fall through")
end)

scenario("90 seconds of play raise no error and never pass a float to the host", function()
  local stats = boot()
  play(stats, 90)
  on_exit()
end)

scenario("the score label is only rewritten when the score changes", function()
  local stats = boot()
  play(stats, 30)
  -- ~1000 ticks ran; text() is called on screen changes and score changes only
  check(stats.text_calls < 120, "text() called " .. stats.text_calls .. " times in 1000 ticks")
end)

scenario("dying with a score above the stored best writes the new best", function()
  -- best = -1 is a valid number that any real score (even 0) beats
  local stats = boot({ best = -1 })
  play(stats, 20)   -- the bird dies within this time
  check(stats.storage_sets > 0, "storage.set was called")
  local best = stats.store.best
  check(type(best) == "number" and best >= 0, "the saved best is a score (is " .. tostring(best) .. ")")
end)

scenario("dying with a lower score leaves the stored best alone", function()
  local stats = boot({ best = 5 })
  play(stats, 20)
  on_exit()
  check(stats.store.best == 5, "stored best stays 5 (is " .. tostring(stats.store.best) .. ")")
  check(stats.storage_sets == 0, "storage was not written (" .. stats.storage_sets .. " writes)")
end)

scenario("a bad stored best score is ignored", function()
  local stats = boot({ best = "banana" })
  play(stats, 5)
  on_exit()
end)

scenario("works when the sprite PNG cannot be loaded (gold-disc fallback)", function()
  local stats = boot({ image_fails = true })
  play(stats, 10)
end)

scenario("works when the led module is missing", function()
  local stats = boot({ no_led = true })
  play(stats, 10)
  check(stats.led_calls == 0, "no led calls were made")
end)

scenario("the LEDs are driven when the module exists", function()
  local stats = boot()
  play(stats, 10)
  check(stats.led_calls > 0, "led.fill or led.off was called")
end)

if failures > 0 then
  print(string.format("\n%d check(s) failed", failures))
  os.exit(1)
end
print("\nsmoke test passed")
