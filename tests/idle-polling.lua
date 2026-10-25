-- Run the actual scheduler and AE2 adapter; count calls across idle and active passes.
local realLoadfile = loadfile
local function simulate(mode)
    local now, snapshots, outputs, stocks, requests = 0, 0, 0, 0, 0
    local callback, changed, headers = nil, false, {}
    local paused = mode == "paused" or mode == "resume"
    local function config()
        local items = {}
        if mode ~= "empty" then
            for i = 1, 23 do
                items["Item" .. i] = {low = 100, target = 200, batch = 10, paused = paused}
            end
        end
        return {items = items}
    end
    local me = {
        getCpus = function()
            snapshots = snapshots + 1
            return {{busy = false, name = "free"}, {busy = true, name = "busy", cpu = {
                finalOutput = function()
                    outputs = outputs + 1
                    return {label = mode == "active" and "Item1" or "Unrelated job"}
                end}}}
        end,
        getCraftables = function(filter)
            return {{getStack = function() return {name = filter.label, label = filter.label, damage = 0} end,
                request = function()
                    requests = requests + 1
                    return {isComputing = function() return false end, hasFailed = function() return false end}
                end}}
        end,
        getItemInNetwork = function() stocks = stocks + 1; return {size = mode == "resume" and 0 or 1000} end,
    }
    for _, module in ipairs{"component", "computer", "event", "filesystem", "shell", "nei_bridge"} do
        package.loaded[module] = nil
    end
    package.preload.component = function() return {isAvailable = function() return true end, me_interface = me} end
    package.preload.computer = function() return {uptime = function() return now end} end
    package.preload.filesystem = function() return {lastModified = function() return 1 end} end
    package.preload.shell = function() return {resolve = function(p) return p end} end
    package.preload.nei_bridge = function() return {
        merge = function(cfg) return cfg end, install = function(fn) callback = fn end,
        paint = function() end, uninstall = function() end,
    } end
    local function header(parts)
        if type(parts) == "table" then
            for _, part in ipairs(parts) do
                if part.text:find("CPUs", 1, true) then headers[#headers + 1] = part.text end
            end
        end
    end
    package.preload["src.Display"] = function() return setmetatable({
        isActive = function() return true end, setHeader = header,
        update = function(_, parts) header(parts) end,
    }, {__index = function() return function() end end}) end
    package.preload["src.Utility"] = function()
        logInfo, setTimeOffset, currentTime = function() end, function() end, function() return "" end
        return {}
    end
    package.preload.event = function() return {pull = function(wait)
        now = now + wait
        if now >= (mode == "resume" and 21 or 300) then error("interrupted", 0) end
        if mode == "resume" and not changed and now >= 5 then
            paused, changed = false, true
            callback()
        end
    end} end
    os.sleep = function(dt) now = now + dt end
    loadfile = function(p)
        if p:match("config.lua$") then return config end
        if p:match("settings.lua$") then return function() return {sleep = 10, display = "table",
            thresholdIntervals = {15, 30, 60, 120, 300}} end end
        return realLoadfile(p)
    end
    assert(realLoadfile("Maintainer.lua"))()
    loadfile = realLoadfile
    return snapshots, outputs, stocks, requests, table.concat(headers, "\n")
end
for _, mode in ipairs{"empty", "paused"} do
    local snapshots, outputs, stocks, requests, headers = simulate(mode)
    assert(snapshots == 0 and outputs == 0 and stocks == 0 and requests == 0, mode)
    assert(headers:find("CPUs: not polled", 1, true), "unknown CPU count must not appear as 0 free")
end
local snapshots, outputs, stocks, requests, headers = simulate("stocked")
assert(snapshots == 1 and outputs == 1 and stocks == 23 and requests == 0)
assert(headers:find("(cached)", 1, true), "skipped CPU snapshots must be labelled")
snapshots, outputs, stocks, requests = simulate("active")
assert(snapshots == 30 and outputs == 30 and stocks == 22 and requests == 0,
    "active jobs must retain ordinary snapshot cadence without duplicate requests")
snapshots, outputs, stocks, requests = simulate("resume")
assert(snapshots == 2 and requests == 2, "resume must restore polling and requests on the next ordinary pass")
print("PASS: 23-entry / 300s scenario: stocked CPU snapshots 30 -> 1; empty/paused 30 -> 0; active jobs remain 30; resume and cached CPU display")
