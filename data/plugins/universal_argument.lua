-- mod-version:4
--
-- Emacs-style universal argument prefix.
--
-- Default bindings:
--   ctrl+u  begin / stack (multiply count by 4)
--   ctrl+g  cancel
--   escape  always cancels (hardcoded)
--
-- Users may rebind via their user/init.lua:
--   keymap.unbind("ctrl+u", "universal-argument:begin")
--   keymap.add { ["alt+u"] = "universal-argument:begin" }
--
-- The keymap wrapper uses keymap.get_bindings() to resolve whatever
-- the user has bound, so any rebinding is respected automatically.

local core    = require "core"
local command = require "core.command"
local keymap  = require "core.keymap"

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local ua = {
  active     = false,
  count      = 4,
  digit_mode = false,  -- true once the user has typed at least one digit
  negative   = false,
}

-- When a key has no keymap command (plain text input is coming), we store the
-- desired repeat count here so the core.on_event wrapper can act on it.
local text_repeat_count = nil

local function ua_reset()
  ua.active     = false
  ua.count      = 4
  ua.digit_mode = false
  ua.negative   = false
end

local function ua_show()
  local sign = ua.negative and "-" or ""
  if ua.digit_mode then
    core.log_quiet("C-u %s%d", sign, ua.count)
  else
    core.log_quiet("C-u (%s%d)", sign, ua.count)
  end
end

-- ---------------------------------------------------------------------------
-- Stroke helpers
-- ---------------------------------------------------------------------------

-- Modifier order must match the sorted order used by keymap.normalize_stroke
-- (modkeys-generic.lua lists them in this order and normalize_stroke gives
-- each modkey priority over the base key).
local MODKEY_ORDER = { "ctrl", "shift", "alt", "altgr", "super" }

-- Reconstruct the normalized stroke string for the key currently being
-- pressed (using live keymap.modkeys state).
local function current_stroke(k)
  local parts = {}
  for _, mod in ipairs(MODKEY_ORDER) do
    if keymap.modkeys[mod] then
      table.insert(parts, mod)
    end
  end
  table.insert(parts, k)
  return table.concat(parts, "+")
end

-- Return true when `stroke` is among the bindings for `cmd_name`.
local function stroke_matches(stroke, cmd_name)
  for _, b in ipairs(keymap.get_bindings(cmd_name) or {}) do
    if b == stroke then return true end
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------

command.add(nil, {
  ["universal-argument:begin"] = function()
    if not ua.active then
      ua.active     = true
      ua.count      = 4
      ua.digit_mode = false
      ua.negative   = false
    else
      -- Each additional begin multiplies by 4; digit_mode resets so the
      -- next digit key will start a fresh accumulation.
      ua.count      = ua.count * 4
      ua.digit_mode = false
    end
    ua_show()
  end,
})

-- The cancel command uses a predicate so it only "fires" when ua is active.
-- This is critical: ctrl+g is also bound to "doc:go-to-line". perform_sequence
-- stops at the first command that succeeds, so if cancel ran unconditionally
-- it would prevent go-to-line from ever executing. With the predicate, cancel
-- is skipped when ua is idle and go-to-line falls through normally.
command.add(function() return ua.active end, {
  ["universal-argument:cancel"] = function()
    ua_reset()
    core.log_quiet("Universal argument cancelled")
  end,
})

-- ---------------------------------------------------------------------------
-- keymap.on_key_pressed wrapper
-- ---------------------------------------------------------------------------

local original_on_key_pressed = keymap.on_key_pressed

function keymap.on_key_pressed(k, ...)
  if not ua.active then
    return original_on_key_pressed(k, ...)
  end

  local stroke = current_stroke(k)

  -- Begin key while active: stack another multiply-by-4 via the command.
  if stroke_matches(stroke, "universal-argument:begin") then
    return original_on_key_pressed(k, ...)
  end

  -- Escape is always a cancel; pass it through so its normal bindings fire.
  if k == "escape" then
    ua_reset()
    return original_on_key_pressed(k, ...)
  end

  -- Cancel key: reset and pass through (command will also call ua_reset,
  -- which is idempotent).
  if stroke_matches(stroke, "universal-argument:cancel") then
    ua_reset()
    return original_on_key_pressed(k, ...)
  end

  -- Digit keys (0-9) with no modifier: accumulate numeric argument.
  -- The first digit replaces the default-4; subsequent digits append.
  if not keymap.modkeys["ctrl"]  and not keymap.modkeys["shift"]
  and not keymap.modkeys["alt"]  and not keymap.modkeys["altgr"]
  and not keymap.modkeys["super"] then
    local digit = k:match("^(%d)$")
    if digit then
      digit = tonumber(digit)
      if not ua.digit_mode then
        ua.count      = digit
        ua.digit_mode = true
      else
        ua.count = ua.count * 10 + digit
      end
      ua_show()
      -- Return true so the event loop suppresses the subsequent textinput
      -- for this digit key (we don't want "3" inserted into the document).
      return true
    end

    -- Minus sign before any digit toggles negative.
    if k == "-" and not ua.digit_mode then
      ua.negative = not ua.negative
      ua_show()
      return true
    end
  end

  -- Any other key: execute with the accumulated count, then reset.
  local n = math.max(1, math.min(math.abs(ua.count), 1024))
  ua_reset()

  local result = original_on_key_pressed(k, ...)
  if result then
    -- A command was matched; repeat it n-1 more times.
    for i = 2, n do
      original_on_key_pressed(k, ...)
    end
    return true
  else
    -- No command matched; a textinput event will follow.  Flag it.
    if n > 1 then
      text_repeat_count = n
    end
    return false
  end
end

-- ---------------------------------------------------------------------------
-- core.on_event wrapper (handles text-input repetition)
-- ---------------------------------------------------------------------------

local original_on_event = core.on_event

core.on_event = function(type, ...)
  if type == "textinput" and text_repeat_count then
    local n    = text_repeat_count
    local text = (...)
    text_repeat_count = nil
    -- Insert the character n times (first insertion is the normal path,
    -- so we call on_text_input n times total).
    for i = 1, n do
      core.root_view:on_text_input(text)
    end
    return true
  end
  return original_on_event(type, ...)
end

keymap.add {
  ["ctrl+u"] = "universal-argument:begin",
  ["ctrl+g"] = "universal-argument:cancel",
}
