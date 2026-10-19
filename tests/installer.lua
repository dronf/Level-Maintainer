-- Run the real installer with an in-memory OpenOS filesystem and download service.
local realOpen, realRead, realWrite = io.open, io.read, io.write
local realPrint, realGetenv, realSleep = print, os.getenv, os.sleep
local function readSource(path)
    local f = assert(realOpen(path, "r")); local text = f:read("*a"); f:close(); return text
end
local installer = readSource("installer.lua")
local template = readSource("settings.lua")
local helper = readSource("src/Settings.lua")
local old = template
old = old:gsub("-- Seconds to wait between cycles%.", "-- Earlier explanation.")
old = old:gsub("settings.thresholdIntervals = {15, 30, 60, 120, 300}", "settings.thresholdIntervals = {0, 5, 10, 20, 30}")
old = old:gsub("settings.requireFreeCpu = true", "settings.requireFreeCpu = false")
local function run(settingsText, answer, failDownload, failRename)
    local files = {["/home/config.lua"] = "my config", ["/home/.shrc"] = "Maintainer\n"}
    if settingsText then files["/home/settings.lua"] = settingsText end
    local prompts, rebooted = 0, false
    package.loaded.shell, package.loaded.filesystem, package.loaded.component = nil, nil, nil
    package.loaded.internet, package.loaded["src.Settings"] = nil, nil
    package.preload.shell = function() return {
        getWorkingDirectory = function() return "/home" end,
        execute = function(command)
            if command == "reboot" then rebooted = true; return true end
            local source, destination = command:match("wget %-f (%S+) (%S+)$")
            assert(source and source:find("dronf/Level%-Maintainer"))
            local name = source:match("/[0-9a-f]+/(.+)$")
            if name == failDownload then return false end
            files[destination] = name == "settings.lua" and template or name == "src/Settings.lua" and helper or "new script"
            return true
        end,
    } end
    package.preload.filesystem = function() return {
        exists = function(p) return files[p] ~= nil or p == "/home/src" end,
        size = function(p) return #(files[p] or "") end,
        makeDirectory = function() end,
        remove = function(p) files[p] = nil; return true end,
        rename = function(a, b)
            if failRename and a == "/home/settings.lua.merged" then return nil, "simulated disk failure" end
            if not files[a] then return nil, "missing" end
            files[b], files[a] = files[a], nil; return true
        end,
    } end
    package.preload.component = function() return {isAvailable = function() return false end} end
    package.preload.internet = function() return {request = function()
        local sent = false
        return function() if not sent then sent = true; return '{"sha":"abcdef"}' end end
    end} end
    package.preload["src.Settings"] = function() return assert(load(helper, "=Settings", "t"))() end
    io.open = function(p, mode)
        if mode == "r" then
            if not files[p] then return nil end
            return {read = function() return files[p] end, close = function() return true end}
        end
        files[p] = ""
        return {write = function(self, text) files[p] = files[p] .. text; return self end,
            flush = function(self) return self end, close = function() end}
    end
    io.read = function() prompts = prompts + 1; return answer or "n" end
    io.write, print, os.sleep = function() end, function() end, function() end
    os.getenv = function() return "/home" end
    assert(load(installer, "=installer.lua", "t"))()
    io.open, io.read, io.write = realOpen, realRead, realWrite
    print, os.getenv, os.sleep = realPrint, realGetenv, realSleep
    return files, prompts, rebooted
end
local files, prompts, rebooted = run(old, "y")
assert(prompts == 1 and rebooted)
assert(files["/home/config.lua"] == "my config")
assert(files["/home/nei_bridge.lua"] == "new script", "bridge must be installed")
assert(files["/home/settings.lua.old"] == old)
local values = assert(load(files["/home/settings.lua"], "=merged", "t", {}))()
assert(values.thresholdIntervals[2] == 5 and values.requireFreeCpu == false)
files, prompts = run(template:gsub("settings.sleep = 10", "settings.sleep = 25"), "y")
assert(prompts == 0, "values-only differences must not prompt")
files = run(old, "n")
assert(files["/home/settings.lua"] == old and not files["/home/settings.lua.old"])
files, prompts, rebooted = run(old, "y", "src/Settings.lua")
assert(files["/home/settings.lua"] == old and not rebooted and prompts == 0)
files = run(old, "y", nil, true)
assert(files["/home/settings.lua"] == old, "failed replacement must roll back")
files, prompts = run("not valid Lua", "y")
assert(prompts == 0 and files["/home/settings.lua"] == "not valid Lua")
files, prompts = run(nil, "y")
assert(files["/home/settings.lua"] == template and prompts == 0)
assert(files["/home/nei_bridge.lua"] == "new script", "fresh install must include bridge")
files, prompts, rebooted = run(old, "y", "nei_bridge.lua")
assert(not rebooted and prompts == 0, "bridge download failure must abort install")
assert(files["/home/config.lua"] == "my config" and files["/home/settings.lua"] == old)
assert(not files["/home/Maintainer.lua"] and not files["/home/nei_bridge.lua"], "no partial install")
for name in pairs(files) do assert(not name:match("%.download$"), "staged downloads must be cleaned up") end
print("PASS: real installer refresh/decline, values-only updates, failed downloads, rollback, malformed settings and fresh installs")
