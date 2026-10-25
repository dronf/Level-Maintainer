-- Exercise the real scheduler with missing settings, shipped defaults and saved overrides.
local realLoadfile = loadfile
local shipped = assert(realLoadfile("settings.lua"))()
local empty = assert(realLoadfile("config.lua"))()
assert(next(empty.items) == nil and next(empty.fluids) == nil, "fresh config must be idle")
local function simulate(options)
    local now, captured = 0, nil
    local snapshots, stocks, requests, headers, polls = {}, {}, {}, {}, {}
    local cfg = options.empty and {items = {}} or {items = {Test = options.continuous and {nil, 2} or {100, 2}}}
    cfg.sleep = options.legacySleep
    local me = {
        getCpus = function() snapshots[#snapshots + 1] = now; return {{name = "free", busy = false}} end,
        getItemInNetwork = function() stocks[#stocks + 1] = now; return {size = options.amount or 0} end,
        getCraftables = function() return {{getStack = function() return {name = "test", label = "Test", damage = 0} end,
            request = function()
                requests[#requests + 1] = now
                local left = options.computePolls or 0
                return {isComputing = function()
                    polls[#polls + 1] = now
                    if left > 0 then left = left - 1; return true end
                    return false
                end, hasFailed = function() return options.failed or false, "test failure" end}
            end}} end,
    }
    for _, name in ipairs{"component", "computer", "event", "filesystem", "shell", "nei_bridge"} do package.loaded[name] = nil end
    package.preload.component = function() return {isAvailable = function() return true end, me_interface = me} end
    package.preload.computer = function() return {uptime = function() return now end} end
    package.preload.filesystem = function() return {lastModified = function() return 1 end} end
    package.preload.shell = function() return {resolve = function(p) return p end} end
    package.preload.nei_bridge = function() return {merge = function(c) return c end,
        install = function() end, uninstall = function() end, paint = function() end} end
    package.preload["src.AE2"] = function()
        local module = assert(realLoadfile("src/AE2.lua"))()
        local configure = module.configure
        module.configure = function(s) captured = s; configure(s) end
        return module
    end
    package.preload["src.Display"] = function() return setmetatable({
        isActive = function() return true end, setHeader = function() headers[#headers + 1] = now end,
    }, {__index = function() return function() end end}) end
    package.preload["src.Utility"] = function()
        logInfo, setTimeOffset, currentTime = function() end, function() end, function() return "" end
        return {}
    end
    package.preload.event = function() return {pull = function(dt)
        now = now + dt
        if now >= (options.stop or 121) then error("interrupted", 0) end
    end} end
    os.sleep = function(dt) now = now + dt end
    loadfile = function(p)
        if p:match("settings.lua$") then
            if options.settings then return function() return options.settings end end
            return nil, "settings file missing"
        end
        if p:match("config.lua$") then return function() return cfg end end
        return realLoadfile(p)
    end
    assert(realLoadfile("Maintainer.lua"))()
    loadfile = realLoadfile
    return captured, snapshots, stocks, requests, headers, polls
end
local function same(actual, expected)
    assert(#actual == #expected, "unexpected count: " .. #actual .. " vs " .. #expected)
    for i, value in ipairs(expected) do assert(actual[i] == value, "unexpected deadline at " .. i) end
end
for _, settings in ipairs{false, shipped} do
    local chosen = settings or nil
    local effective, cpus, stocks, requests, headers = simulate{settings = chosen, continuous = true}
    for key, value in pairs(shipped) do
        if type(value) == "table" then same(effective[key], value)
        else assert(effective[key] == value, "shipped/fallback mismatch: " .. key) end
    end
    same(requests, {0, 60, 120}); same(cpus, {0, 60, 120}); same(stocks, {}); same(headers, {60, 120})
    _, cpus, stocks = simulate{settings = chosen, amount = 110, stop = 601}
    same(cpus, {0, 300, 600}); same(stocks, {0, 300, 600})
    _, cpus, stocks = simulate{settings = chosen, amount = 1000, stop = 3601}
    same(cpus, {0, 3600}); same(stocks, {0, 3600})
    _, cpus, stocks, requests = simulate{settings = chosen, failed = true, stop = 601}
    same(requests, {0, 300, 600}); same(cpus, requests)
    local polls
    _, _, _, requests, _, polls = simulate{settings = chosen, continuous = true, computePolls = 2, stop = 131}
    same(requests, {0, 70}); same(polls, {0, 5, 10, 70, 75, 80})
    _, cpus, stocks, requests = simulate{settings = chosen, empty = true, stop = 3601}
    same(cpus, {}); same(stocks, {}); same(requests, {})
end
local effective, cpus, stocks, requests = simulate{continuous = true, legacySleep = 7, stop = 22}
same(requests, {0, 7, 14, 21}); assert(effective.sleep == 7, "retain legacy cfg.sleep")
effective, cpus, stocks, requests = simulate{continuous = true,
    settings = {sleep = 10, headerInterval = 1, retryDelay = 60, cacheDuration = 600,
        pollInterval = 1, logSkips = true, thresholdIntervals = {15, 30, 60, 120, 300}}, stop = 21}
same(requests, {0, 10, 20})
assert(effective.headerInterval == 1 and effective.retryDelay == 60 and effective.logSkips == true)
local _, fallbackCpus, _, _, fallbackHeaders = simulate{amount = 110, stop = 601,
    settings = {headerInterval = 0, thresholdIntervals = {"bad"}}}
same(fallbackCpus, {0, 300, 600})
assert(#fallbackHeaders == 10 and fallbackHeaders[1] == 60 and fallbackHeaders[10] == 600,
    "invalid intervals must use slow fallbacks, not the old fast values")
print("PASS: shipped/missing settings parity; empty config idle; 60s cycle/header, 5-60min stock delays, 5min retry, 5s computation polling; explicit/legacy timings preserved")
