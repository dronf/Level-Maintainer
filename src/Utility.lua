local filesystem = require("filesystem")
local computer = require("computer")

local timeOffset = 0 -- seconds added to UTC for log timestamps
local CLOCK_FILE = "/tmp/.maintainer_clock"
local CLOCK_SYNC = 60
local clockEpoch, clockUptime, nextClockSync, lastUptime = nil, nil, 0, nil

function setTimeOffset(hours)
    timeOffset = (tonumber(hours) or 0) * 3600
end

-- Anchor to the server filesystem clock, then advance using uptime. Touch the
-- file at most once a minute, rather than for every header or log timestamp.
local function timestamp()
    local now = computer.uptime()
    if lastUptime and now < lastUptime then
        clockEpoch, clockUptime, nextClockSync = nil, nil, 0
    end
    lastUptime = now
    if now >= nextClockSync then
        nextClockSync = now + CLOCK_SYNC
        local ok, modified = pcall(function()
            local file = io.open(CLOCK_FILE, "w")
            if not file then return nil end
            file:close()
            return filesystem.lastModified(CLOCK_FILE)
        end)
        if ok and type(modified) == "number" and modified > 0 then
            clockEpoch, clockUptime = modified / 1000, now
        end
    end
    if clockEpoch then
        return os.date("%H:%M:%S", math.floor(clockEpoch + now - clockUptime + timeOffset))
    end
    return os.date("%H:%M:%S") -- in-game time if the real clock is unavailable
end

-- Current real time as HH:MM:SS
function currentTime()
    return timestamp()
end

local logHandler = nil

-- Sends log lines to handler(line) instead of printing them (nil = print again)
function setLogHandler(handler)
    logHandler = handler
end

function logInfo(message)
    if type(message) == "string" then
        local line = "[" .. timestamp() .. "] " .. message
        if logHandler then
            logHandler(line)
        else
            print(line)
        end
    end
end