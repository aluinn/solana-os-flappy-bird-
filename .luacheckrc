-- luacheck configuration. Run from the repository root: luacheck solana-flappy tests tools
--
-- "lua54" is the closest standard luacheck ships. Solana OS runs Lua 5.5; the
-- difference that matters (the `global` keyword) isn't used in this code.
std = "lua54"
max_line_length = 120

-- The badge's own modules, from Solana OS's docs/LUA_API.md. Only main.lua may
-- use them: lib/game.lua gets the plain standard, so luacheck flags any badge
-- API that leaks into the testable game logic.
local badge_modules = {
  "ui", "led", "timer", "sys", "badge", "json", "storage", "fs",
  "wifi", "mesh", "ble", "lamps", "items", "profile", "quest",
  "http", "ws", "rpc", "crypto", "solana",
}

files["solana-flappy/main.lua"] = {
  read_globals = badge_modules,
  -- the callbacks Solana OS looks up by name
  globals = { "on_key", "on_tick", "on_mesh", "on_meet", "on_exit" },
}

-- The smoke test installs stand-ins for the badge's globals and calls the
-- callbacks main.lua defines, so it may set and read them.
files["tests/smoke_main.lua"] = {
  globals = { "ui", "led", "storage", "sys", "on_key", "on_tick", "on_exit" },
}
