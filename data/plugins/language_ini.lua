-- mod-version:4
local syntax = require "core.syntax"

syntax.add {
  name = "INI",
  files = {
    "%.ini$", "%.inf$", "%.cfg$", "%.conf$",
    "^%.editorconfig$", "[/\\\\]%.editorconfig$",
    "%.theme$", "%.desktop$",
  },
  comment = ";",
  patterns = {
    { pattern = ";.*",                             type = "comment"  },
    { pattern = "#.*",                             type = "comment"  },
    { pattern = { "^%s*%[", "%]" },                type = "keyword"  },
    { pattern = { '"""', '"""', '\\' },            type = "string"   },
    { pattern = { '"', '"', '\\' },                type = "string"   },
    { pattern = { "'''", "'''" },                  type = "string"   },
    { pattern = { "'", "'" },                      type = "string"   },
    { pattern = "[%w_%.%-]+%s*%f[=:]",             type = "function" },
    { pattern = "%f[%w_][%d%.]+%f[^%w_]",          type = "number"   },
    { pattern = "[=:]",                            type = "operator" },
    { pattern = "[%a_][%w_]*",                     type = "symbol"   },
  },
  symbols = {
    ["true"]  = "literal",
    ["false"] = "literal",
    ["on"]    = "literal",
    ["off"]   = "literal",
    ["yes"]   = "literal",
    ["no"]    = "literal",
  },
}
