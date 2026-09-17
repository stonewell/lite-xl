local core = require "core"
local common = require "core.common"
local config = require "core.config"
local tokenizer = require "core.tokenizer"
local Object = require "core.object"


local Highlighter = Object:extend()

function Highlighter:__tostring() return "Highlighter" end

function Highlighter:new(doc)
  self.doc = doc
  self.running = false
  self.cache_order = {}
  self.cache_idx = 1
  self.max_cache = config.highlighter_cache_size or 1000
  self:reset()
end

-- init incremental syntax highlighting
function Highlighter:start()
  if self.running then return end
  if self.doc.large_file or not self.doc.syntax or #self.doc.syntax.patterns == 0 then
    return
  end
  self.running = true
  core.add_thread(function()
    while self.first_invalid_line <= self.max_wanted_line do
      local max = math.min(self.first_invalid_line + 40, self.max_wanted_line)
      local retokenized_from
      for i = self.first_invalid_line, max do
        local prev = (i > 1) and self.lines[i - 1]
        local state = (type(prev) == "table") and prev.state or nil
        local line = self.lines[i]
        if line and line.resume and (line.init_state ~= state or line.text ~= self.doc.lines[i]) then
          -- Reset the progress if no longer valid
          line.resume = nil
        end
        if not (line and line.init_state == state and line.text == self.doc.lines[i] and not line.resume) then
          retokenized_from = retokenized_from or i
          self.lines[i] = self:tokenize_line(i, state, line and line.resume)
          if self.lines[i].resume then
            self.first_invalid_line = i
            goto yield
          end
        elseif retokenized_from then
          self:update_notify(retokenized_from, i - retokenized_from - 1)
          retokenized_from = nil
        end
      end

      self.first_invalid_line = max + 1
      ::yield::
      if retokenized_from then
        self:update_notify(retokenized_from, max - retokenized_from)
      end
      -- Only trigger UI redraw if the retokenized range is visible in an active view
      local views = core.get_views_referencing_doc(self.doc)
      for _, v in ipairs(views) do
        local minline, maxline = v:get_visible_line_range()
        if max >= minline and (retokenized_from or self.first_invalid_line) <= maxline then
          core.redraw = true
          break
        end
      end
      coroutine.yield(0)
    end
    self.max_wanted_line = 0
    self.running = false
  end, self)
end

local function set_max_wanted_lines(self, amount)
  self.max_wanted_line = amount
  if self.first_invalid_line <= self.max_wanted_line then
    self:start()
  end
end


function Highlighter:reset()
  self.lines = {}
  self.cache_order = {}
  self.cache_idx = 1
  self:soft_reset()
end

function Highlighter:soft_reset()
  self.lines = {}
  self.cache_order = {}
  self.cache_idx = 1
  self.first_invalid_line = 1
  self.max_wanted_line = 0
end

function Highlighter:invalidate(idx)
  self.first_invalid_line = math.min(self.first_invalid_line, idx)
  if not self.doc.large_file and self.doc.syntax and #self.doc.syntax.patterns > 0 then
    set_max_wanted_lines(self, math.min(self.max_wanted_line, #self.doc.lines))
  end
end

function Highlighter:insert_notify(line, n)
  self:soft_reset()
  self:invalidate(line)
end

function Highlighter:remove_notify(line, n)
  self:soft_reset()
  self:invalidate(line)
end

function Highlighter:update_notify(line, n)
  -- plugins can hook here to be notified that lines have been retokenized
end


function Highlighter:tokenize_line(idx, state, resume)
  local res = {}
  res.init_state = state
  res.text = self.doc.lines[idx]
  res.tokens, res.state, res.resume = tokenizer.tokenize(self.doc.syntax, res.text, state, resume)
  return res
end


function Highlighter:get_line(idx)
  local line = self.lines[idx]
  if not line or line.text ~= self.doc.lines[idx] then
    local prev = (idx > 1) and self.lines[idx - 1]
    local state = (type(prev) == "table") and prev.state or nil
    line = self:tokenize_line(idx, state)

    if self.doc.large_file or #self.doc.lines > (config.highlighter_cache_size or 1000) then
      -- Evict oldest entry if cache exceeds maximum allowed lines
      local old_idx = self.cache_order[self.cache_idx]
      if old_idx and old_idx ~= idx then
        self.lines[old_idx] = nil
      end
      self.cache_order[self.cache_idx] = idx
      self.cache_idx = (self.cache_idx % self.max_cache) + 1
    end
    self.lines[idx] = line

    self:update_notify(idx, 0)
  end
  if not self.doc.large_file and self.doc.syntax and #self.doc.syntax.patterns > 0 then
    -- Restrict eager lookahead to at most 80 lines ahead of requested line
    set_max_wanted_lines(self, math.min(math.max(self.max_wanted_line, idx + 80), #self.doc.lines))
  end
  return line
end


function Highlighter:each_token(idx)
  return tokenizer.each_token(self:get_line(idx).tokens)
end

return Highlighter
