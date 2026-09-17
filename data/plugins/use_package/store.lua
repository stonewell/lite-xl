local common = require 'core.common'
local json   = require 'plugins.use_package.json'
local util   = require 'plugins.use_package.util'

local STORE_FILE = USERDIR .. '/.use-package-store'

-- in-memory manifests keyed by hex-encoded repo URL (without tag)
local manifests = {}

local data = {
  plugins = {},
  repos   = {},
}

local M = {}

function M.init()
  if util.fileExists(STORE_FILE) then
    local ok, loaded = pcall(dofile, STORE_FILE)
    if ok and loaded then
      data = loaded
      -- Reload any previously cached manifest JSON
      for hex, entry in pairs(data.repos or {}) do
        if entry.manifest_json then
          local ok2, decoded = pcall(json.decode, entry.manifest_json)
          if ok2 then manifests[hex] = decoded end
        end
      end
    end
  end
end

function M.write()
  local f = io.open(STORE_FILE, 'w+')
  if not f then return end
  f:write('return ' .. common.serialize(data))
  f:close()
end

function M.addPlugin(spec)
  data.plugins[spec.plugin] = spec
  M.write()
end

function M.getPlugin(id)
  return data.plugins[id]
end

function M.removePlugin(id)
  data.plugins[id] = nil
  M.write()
end

-- Cache a parsed manifest for a repo. `hex` is the hex-encoded URL without tag.
-- `manifest_text` is the raw JSON string (stored so it survives restarts).
function M.addRepo(hex, manifest_text)
  if not data.repos then data.repos = {} end
  local ok, decoded = pcall(json.decode, manifest_text)
  if not ok then return end
  data.repos[hex] = { manifest_json = manifest_text }
  manifests[hex] = decoded
  M.write()
end

-- Returns all in-memory parsed manifests keyed by hex.
function M.manifests()
  return manifests
end

return M
