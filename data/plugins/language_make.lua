-- mod-version:4
local syntax = require "core.syntax"

syntax.add {
  name = "Makefile",
  files = {
    "^[Mm]akefile$", "^GNUmakefile$",
    "[/\\\\][Mm]akefile$", "[/\\\\]GNUmakefile$",
    "%.mk$", "%.mak$",
  },
  comment = "#",
  patterns = {
    { pattern = "#.*",                    type = "comment"  },
    { pattern = [[\.]],                   type = "normal"   },
    { pattern = "$$[@^<%%?+|*]",          type = "keyword2" },
    { pattern = "$[@^<%%?+|*]",           type = "keyword2" },
    { pattern = "$%b()",                  type = "keyword2" },
    { pattern = "$%b{}",                  type = "keyword2" },
    { pattern = { '"', '"', '\\' },       type = "string"   },
    { pattern = { "'", "'", '\\' },       type = "string"   },
    { pattern = "%f[%w_][%d%.]+%f[^%w_]", type = "number"   },
    { pattern = "%..*:",                  type = "keyword2" },
    { pattern = "^[%a_][%w_.-]*%s*:",    type = "function" },
    { pattern = "[%+:%?]?=",              type = "operator" },
    { pattern = "[%a_][%w_]*",            type = "symbol"   },
  },
  symbols = {
    ["include"]   = "keyword",
    ["-include"]  = "keyword",
    ["sinclude"]  = "keyword",
    ["ifeq"]      = "keyword",
    ["ifneq"]     = "keyword",
    ["ifdef"]     = "keyword",
    ["ifndef"]    = "keyword",
    ["else"]      = "keyword",
    ["endif"]     = "keyword",
    ["export"]    = "keyword",
    ["unexport"]  = "keyword",
    ["override"]  = "keyword",
    ["define"]    = "keyword",
    ["endef"]     = "keyword",
  },
}
