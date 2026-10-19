-- Real receiver, mocked OpenOS storage/GPU. Optional arg[1]: emit screen frames
-- for the Java ScreenReply parser's cross-language integration test.
local realOpen,realLoadfile,realPrint=io.open,loadfile,print
local files,callback,clock,failRename,failWrite={},nil,0,false,false
local checks,reloads,logs=0,0,{}
local function check(x) checks=checks+1;assert(x,"manager check "..checks) end
local path="/home/nei_overrides.lua"
local screen="2ba877c7-82c0-42df-96e6-27c880772f9d"
local token="0123456789abcdef"
local w,h=50,16
local pixels={}
local gpu={getScreen=function()return screen end,getResolution=function()return w,h end,
  fill=function() pixels={};for i=1,w*h do pixels[i]=" " end end,
  set=function(x,y,s) for i=1,#s do pixels[(y-1)*w+x+i-1]=s:sub(i,i) end end}
package.preload.component=function()return {gpu=gpu}end
package.preload.computer=function()return {uptime=function()return clock end}end
package.preload.shell=function()return {resolve=function(n)return "/home/"..n end}end
package.preload.event=function()return {listen=function(_,fn)callback=fn end,ignore=function(_,fn)if callback==fn then callback=nil end end}end
package.preload.filesystem=function()return {
  exists=function(p)return files[p]~=nil end,remove=function(p)files[p]=nil;return true end,
  rename=function(a,b)
    if failRename and a:match("%.tmp$")then return nil,"disk failure"end
    if not files[a]then return nil,"missing"end
    files[b],files[a]=files[a],nil;return true
  end}end
loadfile=function(p)
  if p==path then return files[p] and load(files[p],"=overrides","t",{}) or nil end
  return realLoadfile(p)
end
io.open=function(p,mode)
  if p:sub(1,6)~="/home/"then return realOpen(p,mode)end
  files[p]="";return {write=function(self,s)if failWrite then return nil,"disk full" end;files[p]=files[p]..s;return self end,flush=function(self)return self end,close=function()end}
end
print=function(s)logs[#logs+1]=s end
local bridge=assert(realLoadfile("nei_bridge.lua"))()
local extra=false
local function base()
  local cfg={items={Iron={low=100,target=200,batch=64,refillInterval=1.5},Legacy={nil,64},
    ["Caf\195\169"]={low=1,target=1e12,batch=1}},
    fluids={Water={low=1,target=2,batch=3,fluidName="water",refillInterval=2.5}}}
  if extra then cfg.items.New={1,1} end
  return cfg
end
local function config()return bridge.merge(base())end
bridge.install(function()reloads=reloads+1;config()end,config)
local function send(s)callback("clipboard","keyboard",s,"Player")end
local function query(i,t)
  send("LM2|Q|"..(t or token).."|"..screen.."|"..i)
  return table.concat(pixels):gsub(" +$","")
end
local frame=query(0)
check(frame:match("^LM2R|"..token.."|0|4||%x%x%x%x%x%x%x%x|END$"))
local frames={frame}
for i=1,4 do frames[#frames+1]=query(i)end
check(frames[2]:find("|F|5761746572|1|2|3|2.5|",1,true))
check(frames[3]:find("|I|436166c3a9|1|1000000000000|1||",1,true))
check(frames[5]:find("|I|4c6567616379|||64||",1,true))
if arg and arg[1]then local f=assert(realOpen(arg[1],"w"));f:write(table.concat(frames,"\n").."\n");f:close()end
send("LM2|END|"..token);check(not bridge.paint(gpu))
query(0);clock=6;check(not bridge.paint(gpu))
clock=0;query(0);query(2);w,h=8,2;check(not bridge.paint(gpu)) -- even error frame cannot fit
w,h=12,5;check(bridge.paint(gpu));check(table.concat(pixels):find("|ERR|Screen too small|",1,true))
w,h=50,16
send("LM1|I|Iron|110|250|32")
check(config().items.Iron.refillInterval==1.5 and config().items.Iron.batch==32)
send("LM1|F|Water|10|20|4")
check(config().fluids.Water.fluidName=="water" and config().fluids.Water.refillInterval==2.5)
send("LM2|D|I|Iron")
check(config().items.Iron==nil and config().items.Legacy[2]==64)
check(assert(load(files[path],"=saved","t",{}))().items.Iron==false)
local restarted=assert(realLoadfile("nei_bridge.lua"))()
check(restarted.merge(base()).items.Iron==nil)
send("LM2|D|F|Water");check(config().fluids.Water==nil)
send("LM1|I|Iron|1|2|1");check(config().items.Iron.low==1)
local old,count=files[path],reloads
send("LM2|D|X|Iron");send("LM2|D|I|Bad\nName");send("LM1|I|Iron|0|1|1000000000001")
check(files[path]==old and reloads==count)
failRename=true;send("LM2|D|I|Iron")
check(files[path]==old and reloads==count and logs[#logs]:find("Save failed",1,true))
failRename=false;failWrite=true;send("LM2|D|I|Iron")
check(files[path]==old and reloads==count and not files[path..".tmp"])
failWrite=false;files[path]="this is not Lua!"
send("LM2|D|I|Iron");check(files[path]=="this is not Lua!")
files[path]=old;query(0);local original=query(1)
extra=true -- base configuration changes while the frozen snapshot is being read
check(query(1)==original)
query(2,"ffffffffffffffff");check(table.concat(pixels):gsub(" +$","")==original)
check(query(0):find("|0|4||",1,true)) -- the next snapshot includes the external edit
bridge.uninstall();check(callback==nil and not bridge.paint(gpu))
print,io.open,loadfile=realPrint,realOpen,realLoadfile
print("PASS: NEI manager "..checks.." checks: real screen frames, UTF-8, legacy entries, snapshots, expiry, delete tombstones, re-add, metadata, rollback, corrupt-file protection")
