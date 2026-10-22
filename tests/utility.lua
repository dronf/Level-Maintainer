-- Actual timestamp helper with a simulated server clock and filesystem.
local now, epoch, opens, reads, fail = 0, 1700000000, 0, 0, false
package.preload.computer = function() return {uptime = function() return now end} end
package.preload.filesystem = function() return {lastModified = function()
    reads = reads + 1; if fail then error("filesystem unavailable") end; return (epoch + now) * 1000
end} end
io.open = function() opens = opens + 1; return {close = function() end} end
require("src.Utility")
local function expected(seconds) return os.date("%H:%M:%S", seconds) end
assert(currentTime() == expected(epoch))
local lines = {}; setLogHandler(function(line) lines[#lines + 1] = line end)
for i = 1, 100 do now = i / 100; logInfo("entry " .. i) end
assert(opens == 1 and reads == 1, "timestamps must not touch filesystem per log line")
now = 10; assert(currentTime() == expected(epoch + 10))
setTimeOffset(2); assert(currentTime() == expected(epoch + 10 + 7200))
now, epoch = 60, epoch + 5; assert(currentTime() == expected(epoch + 60 + 7200))
assert(opens == 2 and reads == 2, "periodic wall-clock correction")
now, fail = 120, true
assert(currentTime() == expected(epoch + 120 + 7200), "keep last anchor on a failed resync")
local attempts = opens; now = 121; currentTime(); assert(opens == attempts, "back off a failed clock sync")
now, fail = 1, false; assert(currentTime() == expected(epoch + 1 + 7200), "recover from uptime reset")
now, fail = 0, true; currentTime(); attempts = opens
now = 0.5; currentTime(); assert(opens == attempts, "back off failures after an uptime reset too")
assert(#lines == 100)
print("PASS: cached real-time timestamps, offsets, resync, failure backoff and uptime reset")
