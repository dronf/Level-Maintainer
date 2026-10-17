local Settings = require("src.Settings")
local function read(text) return assert(load(text, "=test settings", "t", {}))() end
local template = [[local settings = {}
-- new explanations
settings.sleep = 10
settings.retryDelay = 60
settings.requireFreeCpu = true
settings.thresholdIntervals = {15, 30, 60, 120, 300}
settings.cpuName = nil
settings.layout = "fit"
return settings
]]
local old = [[local settings = {}
settings.sleep = 25
settings.retryDelay = 0
settings.requireFreeCpu = false
settings.thresholdIntervals = {0, 10, 20, 30, 40}
settings.cpuName = "CPU -- one"
settings.layout = "tall"
settings.custom = {nested = {"one", false, 3}}
return settings
]]
local merged, missing = Settings.merge(old, template)
local values = read(merged)
assert(values.sleep == 25 and values.retryDelay == 0 and values.requireFreeCpu == false)
assert(values.cpuName == "CPU -- one" and values.layout == "tall")
assert(values.thresholdIntervals[1] == 0 and values.thresholdIntervals[5] == 40)
assert(values.custom.nested[2] == false)
assert(merged:find("new explanations", 1, true))
assert(#missing == 0)
assert(Settings.merge(template, template) == template)
local changedValuesOnly = template:gsub("settings.sleep = 10", "settings.sleep = 25")
assert(Settings.merge(changedValuesOnly, template) == changedValuesOnly)
local changed, added = Settings.merge("return {sleep = 5}", template)
assert(read(changed).sleep == 5 and #added > 0)
assert(not pcall(Settings.merge, "invalid syntax", template))
assert(not pcall(Settings.merge, "return 5", template))
assert(not pcall(Settings.merge, "return {custom = function() end}", template))
assert(not pcall(Settings.merge, "local x = {}; x.x = x; return x", template))
print("PASS: settings refresh preserves scalar/table/custom values, adds defaults and rejects invalid settings")
