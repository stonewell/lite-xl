-- mod-version:4
local syntax = require "core.syntax"

local symtable = {
  ["keyword"] = {
    "if", "else", "not", "for", "do", "in",
    "equ", "neq", "lss", "leq", "gtr", "geq",
    "nul", "con", "prn", "lpt1", "com1", "com2", "com3", "com4",
    "exist", "defined", "errorlevel", "cmdextversion",
    "goto", "call", "verify", "pause", "exit", "echo",
  },
  ["function"] = {
    "set", "setlocal", "endlocal", "enabledelayedexpansion",
    "type", "cd", "chdir", "md", "mkdir", "choice",
    "del", "rd", "rmdir", "copy", "xcopy", "robocopy",
    "move", "ren", "rename", "find", "findstr", "sort",
    "shift", "attrib", "cmd", "command", "forfiles",
  },
}

local symbols = {}
for symtype, symlist in pairs(symtable) do
  for _, symname in ipairs(symlist) do
    symbols[symname:lower()] = symtype
    symbols[symname:upper()] = symtype
  end
end

syntax.add {
  name = "Batch",
  files = { "%.bat$", "%.cmd$" },
  comment = "rem",
  patterns = {
    { pattern = "^%s*rem%s.*",                  type = "comment"  },
    { pattern = "^%s*REM%s.*",                  type = "comment"  },
    { pattern = "^%s*::.*",                     type = "comment"  },
    { pattern = "@echo%s+off",                  type = "keyword"  },
    { pattern = "@echo%s+on",                   type = "keyword"  },
    { pattern = "@ECHO%s+OFF",                  type = "keyword"  },
    { pattern = "@ECHO%s+ON",                   type = "keyword"  },
    { pattern = { '"', '"', '\\' },             type = "string"   },
    { pattern = "^%s*:[%w%-_]+",                type = "function" },
    { pattern = "%%%w+%%",                      type = "keyword2" },
    { pattern = "!%w+!",                        type = "keyword2" },
    { pattern = "%%%%?~?[%w:]+",                type = "keyword2" },
    { pattern = "%f[%w_][%d%.]+%f[^%w_]",       type = "number"   },
    { pattern = "[!=()%>&%^/\\@|]",             type = "operator" },
    { pattern = "[%a_][%w_]*",                  type = "symbol"   },
  },
  symbols = symbols,
}
