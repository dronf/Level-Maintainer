-- Run from the repository root with Lua 5.2+.
local realLoadfile = loadfile
local now, amount, stockReads, requests, cpuReads = 0, 0, 0, {}, 0
local fail, stack, config, stopAt, onCycle = false, nil, nil, 0, nil
local fileTime, edit = 1, nil
local craftable = {
    getStack = function() return stack end,
    request = function(count)
        requests[#requests + 1] = count
        if not fail then amount = amount + count end
        return {isComputing = function() return false end,
            hasFailed = function() return fail, "test failure" end}
    end
}
local me = {
    getCraftables = function() return {craftable} end,
    getItemInNetwork = function()
        stockReads = stockReads + 1
        return amount > 0 and {size = amount} or nil
    end,
    getFluidInNetwork = function()
        stockReads = stockReads + 1
        return amount > 0 and {amount = amount} or nil
    end,
    getCpus = function()
        cpuReads = cpuReads + 1
        if onCycle then onCycle(math.floor(now / 10) + 1) end
        return {{busy = false, name = "test"}}
    end
}
package.preload.component = function()
    return {isAvailable = function() return true end, me_interface = me}
end
package.preload.computer = function() return {uptime = function() return now end} end
os.sleep = function(seconds) now = now + seconds end
local ae2 = require("src.AE2")
ae2.connect()
ae2.configure{cacheDuration = 600, pollInterval = 1}
local function reset(fluid)
    now, amount, stockReads, requests, cpuReads, fail = 0, 0, 0, {}, 0, false
    stack = fluid and {label = "Test", name = "testfluid", amount = 1}
        or {label = "Test", name = "test:item", damage = 0}
    ae2.clearCache()
end
for _, fluid in ipairs{false, true} do
    reset(fluid)
    local request = fluid and ae2.requestFluid or ae2.requestItem
    local policy = {target = 150, state = {}}
    amount = 120
    assert(select(3, request("Test", 100, 40, nil, policy)) == "stocked")
    amount = 90
    assert(request("Test", 100, 40, nil, policy))
    assert(amount == 130 and policy.state.refilling)
    assert(request("Test", 100, 40, nil, policy))
    assert(requests[2] == 20 and amount == 150)
    assert(select(3, request("Test", 100, 40, nil, policy)) == "stocked")
    assert(not policy.state.refilling)
    amount = 90
    fail = true
    assert(select(3, request("Test", 100, 40, nil, policy)) == "failed")
    assert(policy.state.refilling)
    fail = false
    amount = 110
    assert(request("Test", 100, 40, nil, policy))
    -- Legacy batches remain fixed, including their original overshoot.
    amount = 99
    assert(request("Test", 100, 40))
    assert(requests[#requests] == 40)
    assert(select(3, request("Test", 100, 40)) == "stocked")
    amount = 0
    assert(select(3, request("Test", 0, 40)) == "stocked")
    assert(request("Test", nil, 40))
end

-- Execute the actual main loop with a deterministic clock and mocked display.
package.preload.event = function()
    return {listen = function() end, ignore = function() end, pull = function(timeout)
        now = now + timeout
        if now >= stopAt then error("interrupted", 0) end
        if edit then
            local fn = edit
            edit = nil
            fn()
            fileTime = fileTime + 1
            return "key_down", nil, string.byte("r"), 0
        end
    end}
end
package.preload.filesystem = function() return {lastModified = function() return fileTime end, exists = function() return false end} end
package.preload.shell = function() return {resolve = function(path) return path end} end
package.preload["src.Display"] = function()
    local d = {isActive = function() return false end}
    setmetatable(d, {__index = function() return function() end end})
    return d
end
package.preload["src.Utility"] = function()
    logInfo = function() end
    setTimeOffset = function() end
    currentTime = function() return "" end
    return {}
end
loadfile = function(path)
    if path:match("settings.lua$") then return function()
        return {sleep = 10, display = "log"}
    end end
    if path:match("config.lua$") then return function() return config end end
    return realLoadfile(path)
end
local function run(conf, initial, duration, hook)
    reset(false)
    amount, config, stopAt, onCycle = initial, {items = {Test = conf}}, duration, hook
    assert(realLoadfile("Maintainer.lua"))()
end
run({100, 40}, 1000, 300)
assert(stockReads == 1 and #requests == 0 and cpuReads == 60)
run({100, 40}, 110, 50)
assert(stockReads == 3 and #requests == 0) -- t=0,20,40
run({low = 100, target = 150, batch = 40}, 90, 30)
assert(#requests == 2 and requests[1] == 40 and requests[2] == 20)
run({nil, 40}, 0, 30)
assert(stockReads == 0 and #requests == 3)
run({low = 100, target = 50, batch = 40}, 0, 30)
assert(stockReads == 0 and #requests == 0) -- invalid config skipped
run({100, 40}, 0, 70, function(cycle) fail = cycle == 1 end)
assert(#requests == 2) -- failure at t=0, retry at t=60
edit = function()
    config = {items = {Test = {low = 100, target = 150, batch = 40}}}
end
run({low = 100, target = 150, batch = 40}, 90, 30)
assert(#requests == 2 and requests[2] == 20) -- unchanged reload retains refilling
edit = function()
    config = {items = {Test = {low = 100, target = 200, batch = 40}}}
end
run({low = 100, target = 150, batch = 40}, 90, 30)
assert(#requests == 1) -- changed entry resets state; 130 is above low
print("PASS: item/fluid hysteresis, capped requests, legacy configs, zero stock,")
print("adaptive polling, passive production, validation, retries, and config reloads")

-- Exercise clipboard delivery during the real main loop's filtered key_down wait.
-- No Enter key and no config-file timestamp change is involved.
local bridgeListener, overrideText, pasted = nil, nil, false
local realOpen, previousLoadfile = io.open, loadfile
local memory = {}
local fs = require("filesystem")
fs.exists = function(p) return memory[p] ~= nil end
fs.remove = function(p) memory[p] = nil; return true end
fs.rename = function(a,b) memory[b],memory[a] = memory[a],nil; return true end
io.open = function(p,mode)
    if not p:find("nei_overrides.lua",1,true) then return realOpen(p,mode) end
    memory[p] = ""
    return {write=function(self,s) memory[p]=memory[p]..s; return self end, flush=function(self) return self end, close=function() end}
end
loadfile = function(p)
    if p == "nei_overrides.lua" then return memory[p] and load(memory[p],"=overrides","t",{}) or nil end
    return previousLoadfile(p)
end
local ev = require("event")
ev.listen = function(name,fn) assert(name == "clipboard"); bridgeListener = fn end
local command = "LM2|D|I|Test"
ev.pull = function(timeout)
    now = now + timeout
    if now >= stopAt then error("interrupted",0) end
    if not pasted then pasted = true; bridgeListener("clipboard","keyboard",command,"Player") end
end
run({100,40},0,30)
assert(#requests == 1, "clipboard delete must stop live maintenance without Enter")
assert(assert(load(memory["nei_overrides.lua"],"=overrides","t",{}))().items.Test == false)
pasted = false; command = "LM1|I|Test|100|150|40"
run({100,40},0,30)
assert(#requests == 2, "clipboard add must reactivate a removed base-config entry during idle")
io.open, loadfile = realOpen, previousLoadfile
print("PASS: live Maintainer clipboard remove/re-add while waiting, without Enter or manual reload")
