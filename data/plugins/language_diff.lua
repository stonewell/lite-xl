-- mod-version:4
local syntax = require "core.syntax"
local style = require "core.style"
local common = require "core.common"

if style and style.syntax then
  style.syntax["diff_add"] = style.syntax["diff_add"] or { common.color "#72b886" }
  style.syntax["diff_del"] = style.syntax["diff_del"] or { common.color "#f36161" }
end

syntax.add {
  name = "Diff",
  files = { "%.diff$", "%.patch$", "%.rej$" },
  headers = "^diff %-",
  patterns = {
    { regex = "^diff .+",                    type = "function" },
    { regex = "^new .+",                     type = "comment"  },
    { regex = "^index .+",                   type = "comment"  },
    { pattern = "@@.-@@ ().+",               type = { "number", "string" } },
    { regex = "^@@ [\\d,\\-\\+ ]+ @@",       type = "number"   },
    { regex = "^\\-{3} [\\d]+,[\\d]+ \\-{4}", type = "number"  },
    { regex = "^\\*{3} [\\d]+,[\\d]+ \\*{4}", type = "number"  },
    { regex = "^\\-{3} .+",                  type = "keyword"  },
    { regex = "^\\+{3} .+",                  type = "keyword"  },
    { regex = "^\\*{3} .+",                  type = "keyword"  },
    { regex = "^\\-{3}$",                    type = "normal"   },
    { regex = "^\\-.*",                      type = "diff_del" },
    { regex = "^\\+.*",                      type = "diff_add" },
    { regex = "^<.*",                        type = "diff_del" },
    { regex = "^>.*",                        type = "diff_add" },
    { regex = "^!.*",                        type = "number"   },
    { pattern = "From ()[a-fA-F0-9]+ ().+",  type = { "keyword", "number", "string" } },
    { regex = "^[a-zA-Z\\-]+: ",             type = "keyword" },
    { regex = "^ [\\d]+ files? changed",     type = "function" },
    { regex = "[\\d]+ insertions?\\(\\+\\)", type = "diff_add" },
    { regex = "[\\d]+ deletions?\\(\\-\\)",  type = "diff_del" },
  },
  symbols = {},
}
