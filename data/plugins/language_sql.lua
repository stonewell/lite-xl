-- mod-version:4
local syntax = require "core.syntax"

local keywords = {
  "CREATE", "SELECT", "ADD", "INSERT", "INTO", "UPDATE",
  "DELETE", "TABLE", "DROP", "VALUES", "NOT",
  "NULL", "PRIMARY", "KEY", "REFERENCES",
  "DEFAULT", "UNIQUE", "CONSTRAINT", "CHECK",
  "ON", "EXCLUDE", "WITH", "USING", "WHERE",
  "GROUP", "BY", "HAVING", "DISTINCT", "LIMIT",
  "OFFSET", "ONLY", "CROSS", "JOIN", "INNER",
  "LEFT", "RIGHT", "FULL", "OUTER", "NATURAL",
  "AND", "OR", "AS", "ORDER", "ORDINALITY",
  "UNNEST", "FROM", "VIEW", "RETURNS", "SETOF",
  "LANGUAGE", "SQL", "LIKE", "ILIKE", "LATERAL",
  "INTERVAL", "PARTITION", "UNION", "INTERSECT",
  "EXCEPT", "ALL", "ASC", "DESC", "NULLS",
  "FIRST", "LAST", "IN", "RECURSIVE", "ARRAY",
  "RETURNING", "SET", "ALSO", "INSTEAD",
  "ALTER", "SEQUENCE", "OWNED", "AT", "ZONE",
  "WITHOUT", "TO", "TIMEZONE", "TYPE", "ENUM",
  "DOCUMENT", "INDEX", "ANY", "ALL",
  "EXTENSION", "ISNULL", "NOTNULL", "UNKNOWN",
  "CASE", "THEN", "WHEN", "ELSE", "END",
  "EXISTS", "SOME", "TRIGGER", "BEFORE", "AFTER",
  "EACH", "ROW", "EXECUTE", "PROCEDURE",
  "FUNCTION", "DECLARE", "BEGIN", "COMMIT", "ROLLBACK",
  "TRANSACTION", "GRANT", "REVOKE", "TRUNCATE",
}

local types = {
  "BIGINT", "INT8", "BIGSERIAL", "SERIAL8",
  "BIT", "VARBIT", "BOOLEAN", "BOOL",
  "BYTEA", "CHARACTER", "CHAR", "VARCHAR",
  "DATE", "DOUBLE", "PRECISION", "FLOAT8", "FLOAT",
  "INTEGER", "INT", "INT4", "JSON", "JSONB",
  "NUMERIC", "DECIMAL", "REAL", "FLOAT4", "INT2",
  "SMALLINT", "SERIAL", "TEXT", "TIME", "TIMESTAMP",
  "UUID", "XML", "BLOB", "CLOB", "VARCHAR2", "NUMBER",
}

local literals = {
  "FALSE", "TRUE", "NULL",
  "CURRENT_TIMESTAMP", "CURRENT_TIME", "CURRENT_DATE",
  "LOCALTIME", "LOCALTIMESTAMP",
}

local symbols = {}
for _, keyword in ipairs(keywords) do
  symbols[keyword:lower()] = "keyword"
  symbols[keyword] = "keyword"
end

for _, type_name in ipairs(types) do
  symbols[type_name:lower()] = "keyword2"
  symbols[type_name] = "keyword2"
end

for _, literal in ipairs(literals) do
  symbols[literal:lower()] = "literal"
  symbols[literal] = "literal"
end

syntax.add {
  name = "SQL",
  files = { "%.sql$", "%.psql$", "%.pgsql$" },
  comment = "--",
  block_comment = { "/*", "*/" },
  patterns = {
    { pattern = "%-%-.*",                  type = "comment"  },
    { pattern = { "/%*", "%*/" },          type = "comment"  },
    { pattern = { "'", "'", '\\' },        type = "string"   },
    { pattern = { '"', '"', '\\' },        type = "string"   },
    { pattern = { '`', '`', '\\' },        type = "string"   },
    { pattern = "-?0x%x+",                 type = "number"   },
    { pattern = "-?%d+[%d%.eE]*",          type = "number"   },
    { pattern = "-?%.?%d+",                type = "number"   },
    { pattern = "[%+%-=/%*%%<>!~|&@%?$#]", type = "operator" },
    { pattern = "[%a_][%w_]*%f[(]",        type = "function" },
    { pattern = "[%a_][%w_]*",             type = "symbol"   },
  },
  symbols = symbols,
}
