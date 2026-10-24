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
local scriptNames = {"src/AE2.lua", "src/Display.lua", "src/Utility.lua", "src/Settings.lua", "nei_bridge.lua", "Maintainer.lua"}
local function run(settingsText, answer, failDownload, failRename, options)
    options = options or {}
    local files = {["/home/config.lua"] = "my config", ["/home/.shrc"] = "Maintainer\n"}
    if options.existing then
        for _, name in ipairs(scriptNames) do files["/home/" .. name] = "old " .. name end
    end
    if options.leftover then files["/home/nei_bridge.lua.install-backup"] = "precious backup" end
    if settingsText then files["/home/settings.lua"] = settingsText end
    local prompts, rebooted, requestedURL = 0, false, nil
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
            files[destination] = name == options.invalid and "<html>gateway error</html>"
                or name == options.truncated and "local x = {"
                or name == "settings.lua" and template or name == "src/Settings.lua" and helper or "return {}"
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
            if a == "/home/" .. (options.failInstall or "NONE") .. ".download" then return nil, "install failure" end
            if b == "/home/" .. (options.failBackup or "NONE") .. ".install-backup" then return nil, "backup failure" end
            if a == "/home/" .. (options.failRestore or "NONE") .. ".install-backup" then return nil, "restore failure" end
            if not files[a] then return nil, "missing" end
            if files[b] then return nil, "destination exists" end
            files[b], files[a] = files[a], nil; return true
        end,
    } end
    package.preload.component = function() return {isAvailable = function() return false end} end
    package.preload.internet = function() return {request = function(url)
        requestedURL = url
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
    assert(load(installer, "=installer.lua", "t"))(options.ref)
    io.open, io.read, io.write = realOpen, realRead, realWrite
    print, os.getenv, os.sleep = realPrint, realGetenv, realSleep
    return files, prompts, rebooted, requestedURL
end
local files, prompts, rebooted = run(old, "y")
assert(prompts == 1 and rebooted)
assert(files["/home/config.lua"] == "my config")
assert(files["/home/nei_bridge.lua"] == "return {}", "bridge must be installed")
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
assert(files["/home/nei_bridge.lua"] == "return {}", "fresh install must include bridge")
files, prompts, rebooted = run(old, "y", "nei_bridge.lua")
assert(not rebooted and prompts == 0, "bridge download failure must abort install")
assert(files["/home/config.lua"] == "my config" and files["/home/settings.lua"] == old)
assert(not files["/home/Maintainer.lua"] and not files["/home/nei_bridge.lua"], "no partial install")
for name in pairs(files) do assert(not name:match("%.download$"), "staged downloads must be cleaned up") end
print("PASS: real installer refresh/decline, values-only updates, failed downloads, rollback, malformed settings and fresh installs")

local function oldScriptsIntact(actual)
    for _, name in ipairs(scriptNames) do
        assert(actual["/home/" .. name] == "old " .. name, "lost original: " .. name)
        assert(not actual["/home/" .. name .. ".install-backup"], "unneeded backup: " .. name)
        assert(not actual["/home/" .. name .. ".download"], "leftover download: " .. name)
    end
end
for _, name in ipairs(scriptNames) do
    for _, failure in ipairs{"failInstall", "failBackup"} do
        local options = {existing = true}; options[failure] = name
        files, prompts, rebooted = run(old, "y", nil, nil, options)
        assert(not rebooted and prompts == 0, "failed script transaction must stop before prompts/reboot")
        oldScriptsIntact(files)
        assert(files["/home/config.lua"] == "my config" and files["/home/settings.lua"] == old)
    end
end
for _, invalid in ipairs{"invalid", "truncated"} do
    local options = {existing = true}; options[invalid] = "nei_bridge.lua"
    files, prompts, rebooted = run(old, "y", nil, nil, options)
    assert(not rebooted and prompts == 0)
    oldScriptsIntact(files)
end
files, prompts, rebooted = run(old, "y", nil, nil, {failInstall = "nei_bridge.lua"})
assert(not rebooted and prompts == 0)
for _, name in ipairs(scriptNames) do assert(not files["/home/" .. name], "failed fresh install left a partial script") end
files, prompts, rebooted = run(old, "y", nil, nil,
    {existing = true, failInstall = "nei_bridge.lua", failRestore = "src/AE2.lua"})
assert(not rebooted and files["/home/src/AE2.lua.install-backup"] == "old src/AE2.lua",
    "failed rollback must preserve the recoverable original")
files, prompts, rebooted = run(old, "y", nil, nil, {existing = true, leftover = true})
assert(not rebooted and prompts == 0 and files["/home/nei_bridge.lua.install-backup"] == "precious backup")
assert(files["/home/nei_bridge.lua"] == "old nei_bridge.lua")
files, prompts, rebooted = run(template, "n", nil, nil, {existing = true})
assert(rebooted)
for _, name in ipairs(scriptNames) do
    assert(files["/home/" .. name] and not files["/home/" .. name .. ".install-backup"])
end
print("PASS: all script backup/replacement failure positions, fresh-install rollback, invalid/truncated downloads, recovery preservation and successful cleanup")
local requestedURL
files, prompts, rebooted, requestedURL = run(template, "n", nil, nil, {ref = "nei-level-maintainer-1.3.2"})
assert(rebooted and requestedURL:match("/commits/nei%-level%-maintainer%-1%.3%.2$"))
files, prompts, rebooted, requestedURL = run(template, "n", nil, nil, {ref = "bad;command"})
assert(not rebooted and prompts == 0 and requestedURL == nil)
print("PASS: version-pinned installation and invalid-ref rejection before any download")
