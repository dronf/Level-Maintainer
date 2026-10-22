-- Uses unmodified buffer.lua and core/full_buffer.lua extracted from the actual
-- OpenComputers JAR. Usage: lua tests/nei-openos-io.lua /path/to/extracted/lib
local realOpen,realLoadfile,realPrint=io.open,loadfile,print
local directory=assert(arg and arg[1],"Pass the extracted OpenOS lib directory")
local files,callback,failFlush,failClose={},nil,false,false
local reloads,checks,logs=0,0,{}
local path="/home/nei_overrides.lua"
local function check(ok) checks=checks+1;assert(ok,"OpenOS IO check "..checks.." ("..tostring(logs[#logs])..")") end
checkArg=function(_,value,expected)assert(type(value)==expected)end
package.preload.computer=function()return {freeMemory=function()return 65536 end,uptime=function()return 0 end}end
package.preload.unicode=function()return {len=string.len,sub=string.sub}end
package.delay=function()end
local buffer=assert(realLoadfile(directory.."/buffer.lua"))()
package.loaded.buffer=buffer
assert(realLoadfile(directory.."/full_buffer.lua"))()
package.preload.shell=function()return {resolve=function(n)return "/home/"..n end}end
package.preload.event=function()return {listen=function(_,fn)callback=fn end,ignore=function()end}end
package.preload.filesystem=function()return {
  exists=function(p)return files[p]~=nil end,remove=function(p)files[p]=nil;return true end,
  rename=function(a,b)if not files[a]then return nil,"missing"end;files[b],files[a]=files[a],nil;return true end
}end
io.open=function(p,mode)
  if p:sub(1,6)~="/home/"then return realOpen(p,mode)end
  files[p]=""
  return buffer.new(mode,{
    write=function(_,s)
      if failFlush then return nil,"disk full" end
      files[p]=files[p]..s;return true
    end,
    close=function()if failClose then return nil,"close error"end end -- real OC success: nil, nil
  })
end
loadfile=function(p)
  if p==path then return files[p] and load(files[p],"=overrides","t",{}) or nil end
  return realLoadfile(p)
end
print=function(s)logs[#logs+1]=s end
local bridge=assert(realLoadfile("nei_bridge.lua"))()
bridge.install(function()reloads=reloads+1 end)
local function send(s)callback("clipboard","keyboard",s,"Player")end
send("LM1|I|Palladium Dust|100000|120000|100")
check(reloads==1 and logs[#logs]=="[NEI LM] Updated Palladium Dust")
local data=assert(load(files[path],"=saved","t",{}))()
check(data.items["Palladium Dust"].target==120000)
check(bridge.merge({items={}}).items["Palladium Dust"].batch==100)
send("LM2|P|I|Palladium Dust|1")
check(reloads==2 and bridge.merge({}).items["Palladium Dust"].paused==true)
send("LM2|P|I|Palladium Dust|0")
check(reloads==3 and bridge.merge({}).items["Palladium Dust"].paused==false)
local old=files[path]
failFlush=true;send("LM1|I|Palladium Dust|100000|150000|100")
check(files[path]==old and reloads==3)
check(logs[#logs]:find("Save failed",1,true) and logs[#logs]:find("disk full",1,true))
check(files[path..".tmp"]==nil)
failFlush=false;failClose=true;send("LM2|D|I|Palladium Dust")
check(files[path]==old and reloads==3 and logs[#logs]:find("close error",1,true))
failClose=false;send("LM2|D|I|Palladium Dust")
check(reloads==4 and bridge.merge({items={["Palladium Dust"]={1,1}}}).items["Palladium Dust"]==nil)
send("LM1|I|Palladium Dust|10|64|16")
check(reloads==5 and bridge.merge({}).items["Palladium Dust"].target==64)
print,io.open,loadfile=realPrint,realOpen,realLoadfile
print("PASS: real OpenOS buffered IO "..checks.." checks: nil close success, flush failure, close failure, preservation, removal and re-add")
