local shell = require("shell")
local filesystem = require("filesystem")
local component = require("component")
local scripts = {"src/AE2.lua", "src/Display.lua", "src/Utility.lua", "src/Settings.lua", "nei_bridge.lua", "Maintainer.lua"}

local repo = "https://raw.githubusercontent.com/dronf/Level-Maintainer/";
local api = "https://api.github.com/repos/dronf/Level-Maintainer/commits/";
-- Optional branch, tag or commit lets a release be installed as one matching set.
local branch = ...
branch = branch or "master"
if type(branch) ~= "string" or not branch:match("^[%w_./-]+$") or branch:find("..", 1, true) then
    print("Invalid version. Pass a branch, tag or commit, or omit it for master.")
    return
end
local dir = shell.getWorkingDirectory()

-- GitHub caches each file on a branch for up to 5 minutes, so right after an update
-- some downloads could be old and others new. Downloading from the latest commit's
-- id instead always gives one matching set. Returns nil if it can't be looked up.
local function latestCommit()
    local ok, sha = pcall(function()
        local internet = require("internet")
        local body = ""
        for chunk in internet.request(api .. branch, nil, {["User-Agent"] = "Level-Maintainer installer"}) do
            body = body .. chunk
            if #body > 2048 then
                break -- the commit id is at the start of the response
            end
        end
        return body:match('"sha"%s*:%s*"(%x+)"')
    end)
    return ok and sha or nil
end

local ref = latestCommit()
if ref then
    print("Installing version " .. ref:sub(1, 7))
else
    ref = branch
    print("Could not look up the latest version; downloading from " .. branch .. " (may be a few minutes behind).")
end

local function path(filename)
    return dir .. "/" .. filename
end

-- Files are downloaded to a temporary name first, and only put in place once every
-- download worked: a failed download (no internet card, GitHub down) leaves the
-- existing install untouched instead of a mix of old and new scripts.
-- (wget leaves an empty file behind when a download fails.)
local function temp(filename)
    return path(filename .. ".download")
end

local function download(filename)
    filesystem.remove(temp(filename))
    shell.execute(string.format("wget -f %s%s/%s %s", repo, ref, filename, temp(filename)))
    return filesystem.exists(temp(filename)) and filesystem.size(temp(filename)) > 0
end

local function readFile(filePath)
    local file = io.open(filePath, "r")
    if not file then return nil end
    local text = file:read("*a")
    file:close()
    return text
end
local oldSettings = readFile(path("settings.lua"))

if not filesystem.exists(path("src")) then
    filesystem.makeDirectory(path("src"))
end

local wanted = {}
for _, file in ipairs(scripts) do
    table.insert(wanted, file)
end
-- config.lua and settings.lua are yours; only fetched when missing
for _, file in ipairs({"config.lua", "settings.lua"}) do
    if not filesystem.exists(path(file)) then
        table.insert(wanted, file)
    end
end

local downloads = {}
for _, file in ipairs(wanted) do table.insert(downloads, file) end
if oldSettings then table.insert(downloads, "settings.lua") end
local failed = {}
for _, file in ipairs(downloads) do
    if not download(file) then
        table.insert(failed, file)
    else
        -- Compile only: an HTML error page or truncated Lua must never replace
        -- a working installation. Do not execute downloaded code to validate it.
        local text = readFile(temp(file))
        local chunk = text and load(text, "@" .. file, "t", {})
        if not chunk then table.insert(failed, file .. " (invalid Lua)") end
    end
end

if #failed > 0 then
    for _, file in ipairs(downloads) do
        filesystem.remove(temp(file))
    end
    print()
    print("Could not download or validate: " .. table.concat(failed, ", "))
    print("Nothing was changed. Check that the computer has an internet card and")
    print("try again. Not rebooting.")
    return
end

local function cleanupDownloads()
    for _, file in ipairs(downloads) do filesystem.remove(temp(file)) end
end
local function backup(file) return path(file .. ".install-backup") end
-- A leftover backup can be the only good copy after a disk failure. Never
-- overwrite it on a later run; report its path for recovery instead.
for _, file in ipairs(wanted) do
    if filesystem.exists(backup(file)) then
        cleanupDownloads()
        print("Unfinished update backup: " .. backup(file))
        print("Recover that file before updating again. Not rebooting.")
        return
    end
end

local backedUp, installed = {}, {}
local function rollback(reason)
    print("Could not install scripts: " .. tostring(reason))
    local restored = true
    for i = #wanted, 1, -1 do
        local file = wanted[i]
        if installed[file] then
            local removed = filesystem.remove(path(file))
            if not removed then restored = false end
        end
        if backedUp[file] then
            local ok = filesystem.rename(backup(file), path(file))
            if not ok then
                restored = false
                print("Restore manually from " .. backup(file))
            end
        end
    end
    cleanupDownloads()
    print(restored and "Previous installation restored. Not rebooting."
        or "Recovery is incomplete; keep the backups above. Not rebooting.")
end
-- Retain every original until all replacements succeed. A failed rename must
-- not silently reboot into a mixture of old and new modules.
for _, file in ipairs(wanted) do
    if filesystem.exists(path(file)) then
        local ok, err = filesystem.rename(path(file), backup(file))
        if not ok then rollback(file .. ": " .. tostring(err)); return end
        backedUp[file] = true
    end
end
for _, file in ipairs(wanted) do
    local ok, err = filesystem.rename(temp(file), path(file))
    if not ok then rollback(file .. ": " .. tostring(err)); return end
    installed[file] = true
end
for _, file in ipairs(wanted) do
    if backedUp[file] then filesystem.remove(backup(file)) end
end

local function ask(question)
    io.write(question .. " [y/N] ")
    local answer = io.read()
    return answer ~= nil and answer:lower():sub(1, 1) == "y"
end

-- Use the newly installed helper even if an earlier installer run cached it.
package.loaded["src.Settings"] = nil
if oldSettings then
    local ok, merged, missing = pcall(function()
        return require("src.Settings").merge(oldSettings, readFile(temp("settings.lua")))
    end)
    local function normalized(text) return text:gsub("\r\n", "\n") end
    if not ok then
        print("Could not update settings.lua: " .. tostring(merged) .. ". Your file was kept.")
    elseif normalized(merged) ~= normalized(oldSettings) then
        if #missing > 0 then
            print("New settings available: " .. table.concat(missing, ", "))
        else
            print("Updated settings explanations are available.")
        end
        if ask("Refresh settings.lua, keeping your values? The old file will be saved as settings.lua.old.") then
            -- Stage and close the replacement before moving the existing file.
            local staged = path("settings.lua.merged")
            local file, err = io.open(staged, "w")
            local written = nil
            if file then
                written, err = file:write(merged)
                if written then written, err = file:flush() end
                local closeOK, closed, closeErr = pcall(file.close, file)
                if not closeOK or closed == false or closeErr ~= nil then
                    written, err = nil, (not closeOK and closed) or closeErr or "close failed"
                end
            end
            if not written then
                filesystem.remove(staged)
                print("Could not write refreshed settings: " .. tostring(err) .. ". Your file was kept.")
            else
                filesystem.remove(path("settings.lua.old"))
                local backedUp, backupErr = filesystem.rename(path("settings.lua"), path("settings.lua.old"))
                if not backedUp then
                    filesystem.remove(staged)
                    print("Could not back up settings.lua: " .. tostring(backupErr) .. ". Your file was kept.")
                else
                    local replaced, replaceErr = filesystem.rename(staged, path("settings.lua"))
                    if replaced then
                        print("Refreshed settings.lua; your values, including polling intervals, were kept.")
                    else
                        local restored = filesystem.rename(path("settings.lua.old"), path("settings.lua"))
                        filesystem.remove(staged)
                        print("Could not replace settings.lua: " .. tostring(replaceErr))
                        if not restored then
                            print("Restore settings.lua.old before restarting. Not rebooting.")
                            filesystem.remove(temp("settings.lua"))
                            return
                        end
                    end
                end
            end
        end
    end
end
filesystem.remove(temp("settings.lua"))

-- Auto-start: OpenOS runs every line of /home/.shrc when the shell starts
local shrc = (os.getenv("HOME") or "/home") .. "/.shrc"
local function autostartEnabled()
    local file = io.open(shrc, "r")
    if not file then
        return false
    end
    local content = file:read("*a")
    file:close()
    return content:find("Maintainer", 1, true) ~= nil
end

print()
if autostartEnabled() then
    print("Auto-start is already on (" .. shrc .. "). Delete the Maintainer line there to turn it off.")
elseif ask("Start Maintainer automatically when the computer boots?") then
    local file = io.open(shrc, "a")
    file:write(string.format('cd "%s" && Maintainer\n', shell.getWorkingDirectory()))
    file:close()
    print("Auto-start on. Delete the Maintainer line in " .. shrc .. " to turn it off.")
end

-- Wake-on-redstone: with a redstone card, a rising redstone signal turns the computer on
-- (a running computer ignores it), so a slow redstone clock restarts it after a power loss
if component.isAvailable("redstone") then
    local redstone = component.redstone
    if redstone.getWakeThreshold() > 0 then
        print("Wake-on-redstone is already on (threshold " .. redstone.getWakeThreshold() .. ").")
    elseif ask("Turn the computer on when it receives a redstone signal (for a watchdog clock)?") then
        redstone.setWakeThreshold(1)
        print("Wake-on-redstone on. A redstone pulse into the computer now starts it if it is off.")
    end
end

print("Rebooting...")
os.sleep(2)
shell.execute("reboot");

