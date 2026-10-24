-- Real LM4 receiver and screen output, deterministic OC components.
local clock,callback,snapshots,ended=0,nil,0,0
local w,h=80,25
local pixels={}
local sets,fills=0,0
local function clear()pixels={};for i=1,w*h do pixels[i]=" " end end
clear()
local screen="2ba877c7-82c0-42df-96e6-27c880772f9d"
local token="0123456789abcdef"
local gpu={getScreen=function()return screen end,getResolution=function()return w,h end,
  fill=function()fills=fills+1;clear()end,
  set=function(x,y,s)sets=sets+1;assert(x+#s-1<=w and y<=h);for i=1,#s do pixels[(y-1)*w+x+i-1]=s:sub(i,i) end end}
package.preload.component=function()return {gpu=gpu}end
package.preload.computer=function()return {uptime=function()return clock end}end
package.preload.event=function()return {listen=function(_,fn)callback=fn end,ignore=function()end}end
package.preload.filesystem=function()return {}end
package.preload.shell=function()return {resolve=function(n)return n end}end
local bridge=require("nei_bridge")
local cfg={items={},fluids={}}
for i=1,23 do
  local name=string.format("Maintained Item %02d",i)
  local section=i%3==0 and cfg.fluids or cfg.items
  section[name]={low=100000,target=120000,batch=100,paused=i%4==0,refillInterval=i%2==0 and 1.5 or nil}
end
cfg.items["Maintained Item 01"]=nil
cfg.items["Caf\195\169; Dust"]={nil,64,paused=true}
bridge.install(function()end,function()snapshots=snapshots+1;return cfg end,function()ended=ended+1 end)
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg or ("batch check "..checks))end
local function send(s)callback("clipboard","keyboard",s,"Player")end
local function text()return table.concat(pixels):match("^(.-|END)")end
local function query(offset)
  send("LM4|Q|"..token.."|"..screen.."|"..offset)
  return text()
end
local function fields(frame)
  local offset,total,count=frame:match("^LM4R|"..token.."|(%d+)|(%d+)|(%d+)|")
  return tonumber(offset),tonumber(total),tonumber(count)
end
local function transfer(width,height,path)
  send("LM2|END|"..token);w,h=width,height;clear();sets,fills=0,0
  for i=0,23 do send("LM3|Q|"..token.."|"..screen.."|"..i) end
  local oldSets,oldFills=sets,fills
  send("LM2|END|"..token);sets,fills=0,0
  local offset,frames=0,{}
  repeat
    local response=query(offset);frames[#frames+1]=response
    check(response and #response<=math.min(w*h,4096),"bounded screen frame")
    local index,total,count=fields(response)
    check(index==offset and total==23 and count>0 and count<=64,"valid forward progress")
    offset=offset+count
  until offset==23
  check(fills==0,"bulk sync must not clear the whole GPU screen")
  check(#frames<24,"batching must reduce exchanges")
  if path then local f=assert(io.open(path,"w"));f:write(table.concat(frames,"\n").."\n");f:close() end
  print(string.format("23 entries at %dx%d: 24 -> %d listing exchanges; GPU sets %d -> %d, fills %d -> %d",w,h,#frames,oldSets,sets,oldFills,fills))
  return frames
end
local frames=transfer(80,25,arg and arg[1])
check(#frames==1,"23 representative entries should fit a single 80x25 reply")
transfer(50,16,arg and arg[2])
transfer(160,50)
-- Retries at offset zero must reuse the same frozen snapshot.
send("LM2|END|"..token);w,h=80,25;clear()
local first=query(0);local prior=snapshots
cfg.items.New={1,2}
check(query(0)==first and snapshots==prior,"retry must not re-read configuration")
local _,total=fields(query(1));check(total==23,"later pages must retain snapshot")
send("LM2|END|ffffffffffffffff");check(bridge.paint(gpu),"other nonce must not end session")
send("LM2|END|"..token);check(not bridge.paint(gpu) and ended>=1,"END restores dashboard callback")
local _,freshTotal=fields(query(0));check(freshTotal==24,"new transfer sees external edits")
-- Resize while a reply is pending; rebuild the page to fit its new dimensions.
w,h=30,10;clear();check(bridge.paint(gpu));local offset,_,count=fields(text())
check(offset==0 and count>0 and #text()<=300)
clock=6;check(not bridge.paint(gpu),"expired session must release screen")
query(1);check(not bridge.paint(gpu),"expired nonzero offset must not restart transfer")
clock=7;query(0);check(snapshots==prior+2,"new initial query after expiry creates snapshot")
-- Empty and small-screen error cases cannot stall a client at offset zero.
send("LM2|END|"..token);cfg={items={},fluids={}};w,h=80,25;clear()
local _,emptyTotal,emptyCount=fields(query(0));check(emptyTotal==0 and emptyCount==0)
send("LM2|END|"..token);cfg.items[string.rep("X",160)]={1,2};w,h=20,5;clear()
check(query(0):find("|ERR|Screen too small|",1,true)~=nil)
-- Large screens still obey the record and byte caps.
send("LM2|END|"..token);cfg={items={},fluids={}}
for i=1,100 do cfg.items[string.format("X%03d",i)]={1,2}end
w,h=160,50;clear();local response=query(0);local _,_,c=fields(response)
check(c==64 and #response<=4096)
local o,t,c2=fields(query(c));check(o==64 and t==100 and c2==36)
bridge.uninstall()
print("PASS: batched listings, snapshot retries, resize, expiry, bounds, empty/error frames and cleanup: "..checks.." checks")
