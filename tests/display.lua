local width, height = 80, 25
local drawn = {}
local gpu = {
    maxResolution = function() return 160, 50 end,
    getResolution = function() return width, height end,
    setResolution = function(w, h) width, height = w, h end,
    getScreen = function() return "screen" end,
    set = function(x, y, text) drawn[#drawn + 1] = text end,
    fill = function() end,
    getDepth = function() return 8 end,
    setForeground = function() end,
    setBackground = function() end,
}
package.preload.component = function() return {
    gpu = gpu, isAvailable = function() return true end,
    invoke = function() return 2, 3 end,
} end
package.preload.term = function() return {clear = function() end, setCursorBlink = function() end} end
package.preload.unicode = function() return {len = string.len, sub = string.sub} end
setLogHandler = function() end
local display = require("src.Display")
assert(display.start())
local name = "Very Long Naquadah Chemical Name"
local row = {name = name, stock = "100", want = "200", batch = "50",
    status = "waiting for CPU", shortStatus = "no CPU", color = "orange"}
drawn = {}
display.update({row}, "Test", "Keys")
assert(display.isActive(), display.failure())
local fitWidth = width
display.setLayout("wide")
assert(display.isActive(), display.failure())
assert(width > fitWidth)
local fullName = false
for _, text in ipairs(drawn) do if text:find(name, 1, true) then fullName = true end end
assert(fullName, "wide layout should preserve the full name on a portrait screen")
display.setLayout("tall")
assert(width == fitWidth)
display.stop()
assert(width == 80 and height == 25)
print("PASS: portrait fit/wide/tall layouts and original resolution restoration")
