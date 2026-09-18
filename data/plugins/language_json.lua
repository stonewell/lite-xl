-- mod-version:4
local syntax = require "core.syntax"

syntax.add {
  name = "JSON",
  files = {
    "%.json$",
    "%.cjson$",
    "%.jsonc$",
    "%.json5$",
    "%.ipynb$",
  },
  comment = "//",
  block_comment = { "/*", "*/" },
  patterns = {
    { pattern = "//.*",             type = "comment" },
    { pattern = { "/%*", "%*/" },   type = "comment" },
    { regex = [["(?:[^"\\]|\\.)*"()\s*:]], type = { "keyword2", "normal" } },
    { pattern = { '"', '"', '\\' }, type = "string" },
    { pattern = { "'", "'", '\\' }, type = "string" },
    { pattern = "0x[%da-fA-F]+",    type = "number" },
    { pattern = "-?%d+[%d%.eE]*",   type = "number" },
    { pattern = "-?%.?%d+",         type = "number" },
    { pattern = "[%[%]{}:,]",       type = "operator" },
  },
  symbols = {
    ["null"]  = "literal",
    ["true"]  = "literal",
    ["false"] = "literal",
  }
}
