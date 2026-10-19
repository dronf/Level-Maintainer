-- Actual main loop + AE2 adapter, with a deterministic network and screen.
local realLoadfile = loadfile
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why or ("CPU check " .. checks)) end
local function simulate(options)
    local now, reads, monitors = 0, 0, 0
    local stock, jobs, requests, headers, rows = {}, {}, {}, {}, {}
    for name, amount in pairs(options.stock or {}) do stock[name] = amount end
    local function finish()
        for name, job in pairs(jobs) do
            if now >= job.finish then stock[name] = (stock[name] or 0) + job.count; jobs[name] = nil end
        end
    end
    local me = {}
    me.getCraftables = function(filter)
        local name = filter.label
        return {{getStack = function() return {label = name, name = name, damage = 0} end,
            request = function(count)
                finish(); check(next(jobs) == nil, "submitted onto occupied CPU")
                requests[#requests + 1] = {name = name, count = count, time = now}
                jobs[name] = {finish = now + (options.duration or 0), count = count}
                return {isComputing = function() return false end, hasFailed = function() finish(); return false end}
            end}}
    end
    me.getItemInNetwork = function(item) return {size = stock[item.name] or 0} end
    me.getCpus = function()
        finish(); reads = reads + 1
        local busy = next(jobs) ~= nil or (options.busy and options.busy(now, reads)) or false
        local result = {{name = "target", busy = busy, cpu = {finalOutput = function()
            monitors = monitors + 1
            local name = next(jobs) or options.externalLabel; return name and {label = name} or nil
        end}}}
        if options.spare then result[#result + 1] = {name = "spare", busy = false} end
        return result
    end
    for _, name in ipairs{"component", "computer", "event", "filesystem", "shell", "nei_bridge"} do package.loaded[name] = nil end
    package.preload.component = function() return {isAvailable = function() return true end, me_interface = me} end
    package.preload.computer = function() return {uptime = function() return now end} end
    package.preload.event = function() return {listen = function() end, ignore = function() end, pull = function(timeout)
        now = now + timeout; finish()
        if now >= (options.stop or 5) then error("interrupted", 0) end
    end} end
    package.preload.filesystem = function() return {lastModified = function() return 1 end, exists = function() return false end} end
    package.preload.shell = function() return {resolve = function(path) return path end} end
    package.preload.nei_bridge = function() return {install = function() end, uninstall = function() end, merge = function(cfg) return cfg end} end
    local function header(parts)
        for _, part in ipairs(parts or {}) do
            if part.text:match("^CPUs") then headers[#headers + 1] = {time = now, text = part.text} end
        end
    end
    package.preload["src.Display"] = function()
        return setmetatable({isActive = function() return true end, setHeader = header,
            update = function(values, parts) rows = values; header(parts) end},
            {__index = function() return function() end end})
    end
    package.preload["src.Utility"] = function()
        logInfo, setTimeOffset, currentTime = function() end, function() end, function() return "" end
        return {}
    end
    loadfile = function(path)
        if path:match("settings.lua$") then return function() return {sleep = 10, display = "table", cpuName = options.named and "target" or nil} end end
        if path:match("config.lua$") then return function() return {items = options.items} end end
        return realLoadfile(path)
    end
    assert(realLoadfile("Maintainer.lua"))()
    return requests, headers, rows, monitors
end
local policy = {low = 1, target = 1, batch = 1}
local requests, headers, rows = simulate{items = {A = policy, B = policy}}
check(#requests == 2, "fast completed jobs must release CPU within a pass")
check(headers[1].text == "CPUs free: 1/1", "header must not subtract completed requests")
requests, headers, rows = simulate{items = {A = policy}, stock = {A = 100}, busy = function() return true end}
check(#requests == 0 and rows[1].status == "stocked", "stocked entry must not wait for a CPU")
requests, headers, rows = simulate{items = {A = policy}, busy = function() return true end}
check(#requests == 0 and rows[1].status == "waiting for CPU", "empty entry should wait on busy CPU")
requests = simulate{items = {A = policy}, busy = function(_, read) return read == 1 end}
check(#requests == 1, "preflight must retry a stale busy snapshot")
local monitors
requests, headers, rows, monitors = simulate{items = {A = policy}, duration = 2}
check(#requests == 1 and headers[1].text == "CPUs free: 0/1")
local observedIdle = false
for _, value in ipairs(headers) do
    if value.time >= 2 and value.time < 5 and value.text == "CPUs free: 1/1" then observedIdle = true end
end
check(observedIdle, "countdown must refresh CPU count before next maintenance cycle")
check(monitors == 1, "idle counts should not query every busy CPU's output")
requests, headers, rows = simulate{items = {A = policy}, externalLabel = "A", busy = function(_, read) return read > 1 end}
check(#requests == 0 and rows[1].status == "crafting", "preflight must catch an externally started job")
requests, headers, rows = simulate{items = {A = policy}, named = true, spare = true, busy = function() return true end}
check(#requests == 0 and rows[1].status == "waiting for CPU", "respect named CPU when a different CPU is idle")
check(headers[1].text == "CPUs free: 1/2")
loadfile = realLoadfile
print("PASS: CPU observations, stock-before-capacity gating, fresh preflight and named CPUs: " .. checks .. " checks")
