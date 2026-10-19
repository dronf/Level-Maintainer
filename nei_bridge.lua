-- NEI clipboard bridge. Commands are received through an authorized OC keyboard.
local event = require("event")
local fs = require("filesystem")
local shell = require("shell")
local M = {}
local path = shell.resolve("nei_overrides.lua")

local function read()
  local chunk = loadfile(path)
  if not chunk then return {items={}, fluids={}} end
  local ok, data = pcall(chunk)
  if not ok or type(data) ~= "table" then return nil, "invalid overrides" end
  if type(data.items) ~= "table" or type(data.fluids) ~= "table" then return nil, "invalid override sections" end
  return data
end

function M.merge(cfg)
  local data, err = read()
  if not data then error(err) end
  cfg.items = cfg.items or {}
  cfg.fluids = cfg.fluids or {}
  for name, spec in pairs(data.items) do cfg.items[name] = spec end
  for name, spec in pairs(data.fluids) do cfg.fluids[name] = spec end
  return cfg
end

local function save(data)
  local tmp = path .. ".tmp"
  local file, err = io.open(tmp, "w")
  if not file then return false, err end
  file:write("return {items={\n")
  for name, spec in pairs(data.items) do
    file:write(string.format("[%q]={low=%d,target=%d,batch=%d},\n", name, spec.low, spec.target, spec.batch))
  end
  file:write("},fluids={\n")
  for name, spec in pairs(data.fluids) do
    file:write(string.format("[%q]={low=%d,target=%d,batch=%d},\n", name, spec.low, spec.target, spec.batch))
  end
  file:write("}}\n")
  file:close()
  local backup = path .. ".bak"
  if fs.exists(backup) then fs.remove(backup) end
  if fs.exists(path) then
    local ok, why = fs.rename(path, backup)
    if not ok then fs.remove(tmp); return false, why end
  end
  local ok, why = fs.rename(tmp, path)
  if not ok and fs.exists(backup) then fs.rename(backup, path) end
  return ok, why
end

function M.install(reload)
  event.listen("clipboard", function(_, keyboard, message, player)
    if type(message) ~= "string" or message:sub(1, 4) ~= "LM1|" then return end
    local kind, name, low, target, batch = message:match("^LM1|([IF])|([^|]+)|(%d+)|(%d+)|(%d+)$")
    low, target, batch = tonumber(low), tonumber(target), tonumber(batch)
    if not kind or #name > 160 or not low or not target or not batch
       or low > target or batch < 1 or target > 1000000000000
       or low ~= math.floor(low) or target ~= math.floor(target) or batch ~= math.floor(batch) then
      print("[NEI LM] Rejected invalid request from " .. tostring(player))
      return
    end
    local data, err = read()
    if not data then print("[NEI LM] " .. tostring(err)); return end
    local dest = kind == "I" and data.items or data.fluids
    dest[name] = {low=low, target=target, batch=batch}
    local ok, why = save(data)
    if not ok then print("[NEI LM] Save failed: " .. tostring(why)); return end
    local applied, reason = pcall(reload)
    if applied then
      print("[NEI LM] Updated " .. name)
    else
      print("[NEI LM] Reload failed: " .. tostring(reason))
    end
  end)
end
return M
