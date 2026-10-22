-- Optional renderer comparison: lua tests/display-equivalence.lua /path/to/old-Display.lua
assert(arg and arg[1], "supply the pre-optimization Display.lua")
local function draw(path, mode, depth, count)
    local w, h, fg, cells = 160, 50, 0xFFFFFF, {}
    local calls = {resolution = 0, depth = 0, foreground = 0, set = 0, fill = 0}
    local function put(x, y, ch) cells[y * 1000 + x] = {ch, fg} end
    local gpu = {
        maxResolution = function() return 160, 50 end,
        getResolution = function() calls.resolution = calls.resolution + 1; return w, h end,
        setResolution = function(a, b) w, h, cells = a, b, {} end,
        getScreen = function() return "screen" end,
        getDepth = function() calls.depth = calls.depth + 1; return depth end,
        setForeground = function(color) calls.foreground = calls.foreground + 1; fg = color end,
        set = function(x, y, text)
            calls.set = calls.set + 1
            for i = 1, #text do put(x + i - 1, y, text:sub(i, i)) end
        end,
        fill = function(x, y, width, height, ch)
            calls.fill = calls.fill + 1
            for yy = y, y + height - 1 do for xx = x, x + width - 1 do put(xx, yy, ch) end end
        end,
    }
    for _, name in ipairs{"component", "term", "unicode"} do package.loaded[name] = nil end
    package.preload.component = function() return {gpu = gpu, isAvailable = function() return true end,
        invoke = function() return 2, 3 end} end
    package.preload.term = function() return {clear = function() cells = {} end, setCursorBlink = function() end} end
    package.preload.unicode = function() return {len = string.len, sub = string.sub} end
    setLogHandler = function() end
    local d = assert(loadfile(path))(); d.setLayout(mode); assert(d.start())
    d.addLog("Requested Item 1"); d.addLog("ERROR: example failure")
    local rows = {}
    for i = 1, count do
        rows[i] = {name = "Example Item " .. i, stock = tostring(i * 10), want = "1000", batch = "64",
            status = i % 2 == 0 and "stocked" or "crafting", shortStatus = "stocked",
            color = i % 2 == 0 and "green" or "blue", stockFrozen = i % 3 == 0}
    end
    for key in pairs(calls) do calls[key] = 0 end
    d.update(rows, "Maintainer", "Keys", "Short", "Tiny")
    assert(d.isActive(), d.failure())
    local full = {}; for key, value in pairs(calls) do full[key] = value end
    d.changePage(1); d.setHeader("New header"); d.addLog("New event")
    local parts = {w .. "x" .. h}
    for y = 1, h do for x = 1, w do
        local cell = cells[y * 1000 + x] or {" ", 0xFFFFFF}
        parts[#parts + 1] = cell[1] .. ":" .. cell[2]
    end end
    return table.concat(parts, "|"), full
end
local cases = 0
for _, mode in ipairs{"fit", "fixed", "columns", "tall", "wide"} do
    for _, depth in ipairs{1, 8} do for _, count in ipairs{23, 60} do
        local before, oldCalls = draw(arg[1], mode, depth, count)
        local after, newCalls = draw("src/Display.lua", mode, depth, count)
        assert(before == after, "screen mismatch: " .. mode .. "/" .. depth .. "/" .. count)
        assert(newCalls.resolution == 1 and newCalls.depth == 1)
        assert(newCalls.set == oldCalls.set and newCalls.fill == oldCalls.fill)
        assert(newCalls.foreground <= oldCalls.foreground)
        cases = cases + 1
        if mode == "fixed" and depth == 8 and count == 23 then
            print("23-row full draw metadata queries: " .. (oldCalls.resolution + oldCalls.depth) .. " -> " .. (newCalls.resolution + newCalls.depth))
            print("23-row full draw foreground changes: " .. oldCalls.foreground .. " -> " .. newCalls.foreground)
        end
    end end
end
print("PASS: identical screen characters/colors across " .. cases .. " layout/depth/page cases")
