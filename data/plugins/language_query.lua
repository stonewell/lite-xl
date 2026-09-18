-- mod-version:4
local syntax = require "core.syntax"

syntax.add {
  name = "Tree-sitter Query",
  files = { "%.scm$" },
  comment = ";",
  patterns = {
    { pattern = ";.*",                      type = "comment"  },
    { pattern = { '"', '"', '\\' },         type = "string"   },
    { pattern = "@[%a_][%w_.]*",            type = "keyword2" },
    { pattern = "#[%a_][%w_.-]*",           type = "keyword"  },
    { pattern = "[%f[%w_][%d%.]+%f[^%w_]]", type = "number"   },
    { pattern = "[%(%)%[%]{}%?%+%*!]",      type = "operator" },
    { pattern = "[%a_][%w_.-]*",            type = "symbol"   },
  },
  symbols = {
    ["_"]            = "keyword",
  },
}
