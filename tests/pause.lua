-- Run actual Maintainer + AE2 + clipboard receiver with deterministic jobs.
local realLoadfile, realOpen = loadfile, io.open
local checks = 0
local function check(ok, why) checks=checks+1;assert(ok,why or ("pause check "..checks)) end
local function simulate(options)
    local now, amount, callback, job = 0, 90, nil, nil
    local requests, reads, displayed, cpuReads = {}, {}, {}, {}
    local files = { ["nei_overrides.lua"] = options.saved }
    local commands = options.noCommands and {} or {{time=0.5,value="1"},{time=8,value="0"}}
    local nextCommand=1
    local function finish()
        if job and now>=job.finish then amount=amount+job.count;job=nil end
    end
    local me={}
    me.getCraftables=function(filter)
        return {{getStack=function()
            return options.fluid and {label="Test",name="testfluid",amount=1} or {label="Test",name="testitem",damage=0}
        end,request=function(count)
            check(not job,"must not overlap jobs")
            requests[#requests+1]={time=now,count=count}
            job={finish=now+(options.duration or 0),count=count};finish()
            return {isComputing=function()return false end,hasFailed=function()return false end}
        end}}
    end
    local function stock() finish();reads[#reads+1]=now;return {size=amount,amount=amount} end
    me.getItemInNetwork,me.getFluidInNetwork=stock,stock
    me.getCpus=function()
        finish();cpuReads[#cpuReads+1]=now
        return {{name="test",busy=job~=nil,cpu={finalOutput=function()return job and {label="Test"} or nil end}}}
    end
    for _,name in ipairs{"component","computer","event","filesystem","shell","nei_bridge"} do package.loaded[name]=nil end
    package.preload.component=function()return {isAvailable=function()return true end,me_interface=me}end
    package.preload.computer=function()return {uptime=function()return now end}end
    package.preload.event=function()return {listen=function(_,fn)callback=fn end,ignore=function()end,pull=function(timeout)
        local command=commands[nextCommand]
        local stop=options.stop or 12
        local wake=command and math.min(command.time,now+timeout) or now+timeout
        if wake>=stop then now=stop;finish();error("interrupted",0) end
        if command and command.time<=now+timeout then
            now=command.time;finish();nextCommand=nextCommand+1
            callback("clipboard","keyboard","LM2|P|"..(options.fluid and "F" or "I").."|Test|"..command.value,"Player")
        else now=now+timeout;finish() end
    end}end
    package.preload.filesystem=function()return {lastModified=function()return 1 end,
        exists=function(p)return files[p]~=nil end,remove=function(p)files[p]=nil;return true end,
        rename=function(a,b)files[b],files[a]=files[a],nil;return true end}end
    package.preload.shell=function()return {resolve=function(p)return p end}end
    package.preload["src.Display"]=function()
        return setmetatable({isActive=function()return true end,update=function(rows)
            for _,row in ipairs(rows)do displayed[#displayed+1]={time=now,status=row.status,color=row.color}end
        end},{__index=function()return function()end end})
    end
    package.preload["src.Utility"]=function()
        logInfo,setTimeOffset,currentTime=function()end,function()end,function()return ""end
        return {}
    end
    os.sleep=function(dt)now=now+dt;finish()end
    io.open=function(p,mode)
        if not p:find("nei_overrides.lua",1,true)then return realOpen(p,mode)end
        files[p]="";return {write=function(self,text)files[p]=files[p]..text;return self end,
            flush=function(self)return self end,close=function()end}
    end
    loadfile=function(p)
        if p=="nei_overrides.lua"then return files[p] and load(files[p],"=saved","t",{}) or nil end
        if p:match("settings.lua$")then return function()return {sleep=10,display="table"}end end
        if p:match("config.lua$")then return function()
            local spec={low=100,target=150,batch=40,refillInterval=1,paused=options.initiallyPaused or false}
            return options.fluid and {fluids={Test=spec}} or {items={Test=spec}}
        end end
        return realLoadfile(p)
    end
    assert(realLoadfile("Maintainer.lua"))()
    io.open,loadfile=realOpen,realLoadfile
    return requests,reads,displayed,files["nei_overrides.lua"],cpuReads
end
for _,fluid in ipairs{false,true}do
    for _,duration in ipairs{0,5}do
        local requests,reads,rows,_,cpus=simulate{fluid=fluid,duration=duration}
        check(#requests==2 and requests[1].time==0 and requests[2].time==10,"resume must retain active refill above Low")
        check(requests[2].count==20,"keep capped final batch")
        for _,time in ipairs(reads)do check(time<0.5 or time>=8,"paused entries must not query inventory") end
        local paused=false
        for _,row in ipairs(rows)do
            if row.time==0.5 then check(row.status=="paused" and row.color=="purple");paused=true end
        end
        check(paused,"pause must repaint immediately")
        check(#cpus==3 and cpus[1]==0 and cpus[2]==10 and cpus[3]==11,"unexpected CPU cadence: "..table.concat(cpus,","))
    end
end
local requests,reads,rows,_,cpus=simulate{initiallyPaused=true,noCommands=true}
check(#requests==0 and #reads==0 and #cpus==0 and rows[1].status=="paused",
    "an entirely paused list must not query AE2 CPUs or stock")
local _,_,_,saved=simulate{noCommands=false,stop=7}
requests,reads,rows=simulate{noCommands=true,saved=saved}
check(#requests==0 and #reads==0 and rows[1].status=="paused","pause must survive process restart")
print("PASS: live item/fluid pause, running-job completion, refill resume, screen color, persistence and CPU cadence: "..checks.." checks")
