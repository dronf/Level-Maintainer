-- Run from a Level-Maintainer checkout; tests the PR #5 clipboard protocol.
-- Optional arg[1] is a file of commands emitted by BridgeCommandTest.java.
local realOpen, realLoadfile, realPrint = io.open, loadfile, print
local callback, files, reloads, failRename, logs = nil, {}, 0, false, {}
local checks = 0
local function check(ok) checks = checks + 1; assert(ok, "receiver check " .. checks) end
package.preload.event = function() return {ignore = function() end, listen = function(name, fn)
  check(name == "clipboard"); callback = fn
end} end
package.preload.shell = function() return {resolve = function(name) return "/home/" .. name end} end
package.preload.filesystem = function() return {
  exists = function(p) return files[p] ~= nil end,
  remove = function(p) files[p] = nil; return true end,
  rename = function(a,b)
    if failRename and a:match("%.tmp$") then return nil,"simulated disk failure" end
    if not files[a] then return nil,"missing" end
    files[b],files[a] = files[a],nil; return true
  end
} end
local path = "/home/nei_overrides.lua"
loadfile = function(p)
  if p:match("^/home/") then
    if not files[p] then return nil,"missing" end
    return load(files[p],"="..p,"t",{})
  end
  return realLoadfile(p)
end
io.open = function(p,mode)
  if not p:match("^/home/") then return realOpen(p,mode) end
  check(mode == "w")
  files[p] = ""
  return {write = function(self,s) files[p]=files[p]..s; return self end, flush=function(self) return self end, close=function() end}
end
print = function(s) logs[#logs+1] = s end
local bridge = assert(realLoadfile("nei_bridge.lua"))()
local merged
bridge.install(function()
  reloads = reloads + 1
  merged = bridge.merge({items={Existing={10,5},["Iron Ingot"]={1,1}}})
end)
local function send(s) callback("clipboard","keyboard-uuid",s,"TestPlayer") end
if arg and arg[1] then
  for line in io.lines(arg[1]) do send(line) end
else
  send("LM1|I|Iron Ingot|100|200|64")
  send('LM1|I|Quote " and slash \\|0|300|1')
  send("LM1|I|Caf\195\169|1|1000000000000|1")
end
check(reloads == 3)
check(merged.items["Iron Ingot"].low == 100 and merged.items.Existing[1] == 10)
check(merged.items['Quote " and slash \\'].target == 300)
check(merged.items["Caf\195\169"].target == 1000000000000)
local restarted = assert(realLoadfile("nei_bridge.lua"))()
check(restarted.merge({}).items["Iron Ingot"].batch == 64)
send("LM1|I|Iron Ingot|200|400|32")
check(merged.items["Iron Ingot"].low == 200)
local old, count = files[path], reloads
for _, command in ipairs({"ordinary clipboard", "LM1|I|Bad|300|200|1", "LM1|I|Bad|-1|200|1",
  "LM1|I|Bad|0|200|0", "LM1|I|Bad|0|1000000000001|1", "LM1|I||0|200|1",
  "LM1|I|Bad|0|200|1\n", "LM1|I|"..string.rep("x",161).."|0|200|1"}) do send(command) end
check(reloads == count and files[path] == old)
failRename = true
send("LM1|I|Iron Ingot|1|999|1")
check(reloads == count and files[path] == old)
check(logs[#logs]:match("Save failed"))
failRename = false
files[path] = "return {broken=true}"
send("LM1|I|Iron Ingot|1|999|1")
check(files[path] == "return {broken=true}" and reloads == count)
files[path] = old
bridge.install(function() error("test reload failure") end)
send("LM1|I|Iron Ingot|1|999|1")
check(logs[#logs]:match("Reload failed"))
print, io.open, loadfile = realPrint, realOpen, realLoadfile
print("PASS: PR #5 protocol receiver: "..checks.." checks; Java commands, persistence, merge, rejection, rollback, reload failure")
