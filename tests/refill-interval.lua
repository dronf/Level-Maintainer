-- Run the actual scheduler and AE2 adapter with deterministic time and craft jobs.
local realLoadfile = loadfile
local function simulate(options)
    local now, stop = 0, options.stop or 25
    local amounts = {Fast = options.stock or 90, Other = 1000}
    local reads, requests, jobs, snapshots = {}, {}, {}, {}
    local settings = {sleep = 10, display = "log", retryDelay = 60,
        cpuName = options.named and "test" or nil, reloadCheck = options.reloadCheck or 0}
    local policy = options.policy or {low = 100, target = 250, batch = 40, refillInterval = 3}
    local config = {items = {Other = {100, 10}, Passive = {nil, 1}}}
    if options.fluid then config.fluids = {Fast = policy} else config.items.Fast = policy end
    local edited, timestamp = false, 1
    local function update()
        for name, job in pairs(jobs) do
            if now >= job.finish then
                amounts[name] = (amounts[name] or 0) + job.count
                jobs[name] = nil
            end
        end
        if options.withdraw and now >= 1 then amounts.Fast = math.min(amounts.Fast, 90) end
    end
    local me = {}
    me.getCraftables = function(filter)
        local name = filter.label
        return {{getStack = function()
            if options.fluid and name == "Fast" then return {label = name, name = name, amount = 1} end
            return {label = name, name = name, damage = 0}
        end, request = function(count)
            update()
            assert(not jobs[name], "duplicate overlapping job for " .. name)
            local failed = options.fail and name == "Fast" and now == 0
            requests[#requests + 1] = {name = name, time = now, count = count, failed = failed}
            if not failed then
                jobs[name] = {finish = now + (name == "Fast" and options.duration or 0), count = count}
                update()
            end
            local polls = name == "Fast" and (options.computePolls or 0) or 0
            return {isComputing = function()
                if polls > 0 then polls = polls - 1; return true end
                return false
            end, hasFailed = function() return failed, "test failure" end}
        end}}
    end
    local function stock(name)
        update()
        reads[name] = reads[name] or {}
        reads[name][#reads[name] + 1] = now
        return {size = amounts[name] or 0, amount = amounts[name] or 0}
    end
    me.getItemInNetwork = function(item) return stock(type(item) == "table" and item.name or item) end
    me.getFluidInNetwork = stock
    me.getCpus = function()
        update()
        snapshots[#snapshots + 1] = now
        if options.networkError and now == 2 then error("network unavailable") end
        local cpus = {}
        for name in pairs(jobs) do
            local label = name
            cpus[#cpus + 1] = {busy = true, name = "busy", cpu = {finalOutput = function() return {label = label} end}}
        end
        local blocked = options.cpuBlocked and now >= 2 and now < 7
        cpus[#cpus + 1] = {busy = blocked or false, name = "test", cpu = {finalOutput = function() return nil end}}
        if not options.named and not blocked then
            for i = 1, 3 do cpus[#cpus + 1] = {busy = false, name = "spare" .. i} end
        end
        return cpus
    end
    package.loaded.component, package.loaded.computer = nil, nil
    package.loaded.event, package.loaded.filesystem, package.loaded.shell = nil, nil, nil
    package.preload.component = function() return {isAvailable = function() return true end, me_interface = me} end
    package.preload.computer = function() return {uptime = function() return now end} end
    package.preload.event = function() return {listen = function() end, pull = function(timeout)
        if options.reload and not edited and now + timeout >= 1 then
            now, edited, timestamp = 1, true, timestamp + 1
            if options.change then
                policy = {low = 100, target = 300, batch = 40, refillInterval = 4}
            else
                local copy = {}; for k, v in pairs(policy) do copy[k] = v end; policy = copy
            end
            local items = {}; for k, v in pairs(config.items) do items[k] = v end
            config = {items = items, fluids = options.fluid and {Fast = policy} or nil}
            if not options.fluid then config.items.Fast = policy end
            return "key_down", nil, string.byte("r"), 0
        end
        now = now + timeout
        update()
        if now >= stop then error("interrupted", 0) end
    end} end
    package.preload.filesystem = function() return {lastModified = function() return timestamp end, exists = function() return false end} end
    package.preload.shell = function() return {resolve = function(p) return p end} end
    package.preload["src.Display"] = function()
        return setmetatable({isActive = function() return false end}, {__index = function() return function() end end})
    end
    package.preload["src.Utility"] = function()
        logInfo, setTimeOffset, currentTime = function() end, function() end, function() return "" end
        return {}
    end
    os.sleep = function(seconds) now = now + seconds; update() end
    loadfile = function(path)
        if path:match("settings.lua$") then return function() return settings end end
        if path:match("config.lua$") then return function() return config end end
        return realLoadfile(path)
    end
    assert(realLoadfile("Maintainer.lua"))()
    local fast, passive = {}, {}
    for _, req in ipairs(requests) do
        if req.name == "Fast" then fast[#fast + 1] = req end
        if req.name == "Passive" then passive[#passive + 1] = req.time end
    end
    return fast, passive, reads, snapshots
end
local function times(requests, expected)
    assert(#requests == #expected, "unexpected request count: " .. #requests)
    for i, time in ipairs(expected) do assert(requests[i].time == time, "unexpected time at " .. i .. ": " .. requests[i].time) end
end
for _, fluid in ipairs{false, true} do
    local fast, passive, reads, snapshots = simulate{fluid = fluid, duration = 0}
    times(fast, {0, 3, 6, 9})
    assert(fast[4].count == 40)
    assert(#reads.Other == 1 and reads.Other[1] == 0)
    assert(#passive == 3 and passive[1] == 0 and passive[2] == 10 and passive[3] == 20)
    for _, t in ipairs(snapshots) do assert(t ~= 15 and t ~= 18, "timer should stop at target") end
    fast = simulate{fluid = fluid, duration = 5,
        policy = {low = 100, target = 190, batch = 40, refillInterval = 2}}
    times(fast, {0, 6, 12})
    assert(fast[3].count == 20)
end
times(simulate{duration = 0, fail = true, stop = 65,
    policy = {low = 100, target = 150, batch = 40, refillInterval = 2}}, {0, 60, 62})
times(simulate{duration = 0, cpuBlocked = true, stop = 13,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 2}}, {0, 8, 10})
times(simulate{duration = 0, cpuBlocked = true, named = true, stop = 13,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 2}}, {0, 8, 12})
times(simulate{duration = 0, stock = 120, withdraw = true, stop = 25,
    policy = {low = 100, target = 250, batch = 40, refillInterval = 2}}, {20, 22, 24})
times(simulate{duration = 0, stop = 3,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 0.5}}, {0, 0.5, 1})
times(simulate{duration = 0, reloadCheck = 30, stop = 7,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 2}}, {0, 2, 4})
times(simulate{duration = 0, computePolls = 3, stop = 11,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 0.5}}, {0, 3.5, 7})
times(simulate{duration = 0, reload = true, stop = 7,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 2}}, {0, 2, 4})
times(simulate{duration = 0, reload = true, change = true, stop = 7,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 2}}, {0})
times(simulate{duration = 0, networkError = true, stop = 9,
    policy = {low = 100, target = 210, batch = 40, refillInterval = 2}}, {0, 4, 6})
for _, invalid in ipairs{0, -1, "2", math.huge, 0/0} do
    times(simulate{duration = 0, policy = {low = 100, target = 200, batch = 40, refillInterval = invalid}}, {})
end
times(simulate{duration = 0, policy = {100, 40, refillInterval = 2}}, {})
print("PASS: item/fluid refill timers, independent ordinary/idle schedules, busy jobs/CPUs,")
print("cooldowns, fractional intervals, target caps, reloads, network errors and validation")
