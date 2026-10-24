-- Clipboard requests; replies travel through OC's existing synchronized screen.
local event,fs,shell=require("event"),require("filesystem"),require("shell")
local M={}
local path=shell.resolve("nei_overrides.lua")
local session
local function now() return require("computer").uptime() end
local function read()
  local chunk=loadfile(path)
  if not chunk then
    if fs.exists(path) then return nil,"invalid overrides syntax" end
    return {items={},fluids={}}
  end
  local ok,data=pcall(chunk)
  if not ok or type(data)~="table" or type(data.items)~="table" or type(data.fluids)~="table" then return nil,"invalid overrides" end
  return data
end
function M.merge(cfg)
  local data,err=read(); if not data then error(err) end
  for _,section in ipairs({"items","fluids"}) do
    cfg[section]=cfg[section] or {}
    for name,spec in pairs(data[section]) do cfg[section][name]=spec~=false and spec or nil end
  end
  return cfg
end
local function finite(n) return type(n)=="number" and n==n and n<math.huge and n>-math.huge end
local function nameOK(n) return type(n)=="string" and #n>0 and #n<=160 and not n:find("[|%c]") end
local function save(data)
  local tmp=path..".tmp"
  local file,err=io.open(tmp,"w"); if not file then return false,err end
  local ok,why=pcall(function()
    assert(file:write("return {"))
    for _,section in ipairs({"items","fluids"}) do
      assert(file:write(section.."={\n"))
      for name,spec in pairs(data[section]) do
        assert(file:write(string.format("[%q]=",name)))
        if spec==false then assert(file:write("false,\n"))
        else
          assert(type(spec)=="table","invalid override entry")
          assert(file:write("{"))
          local values={low=spec.low or spec[1],target=spec.target,batch=spec.batch or spec[2],refillInterval=spec.refillInterval}
          for key,value in pairs(values) do
            assert(finite(value),"invalid override number")
            assert(file:write(string.format("%s=%.17g,",key,value)))
          end
          if spec.paused~=nil then
            assert(type(spec.paused)=="boolean","invalid pause flag")
            assert(file:write("paused="..tostring(spec.paused)..","))
          end
          local fluidName=spec.fluidName or spec[3]
          if fluidName then assert(file:write(string.format("fluidName=%q,",fluidName))) end
          assert(file:write("},\n"))
        end
      end
      assert(file:write("},"))
    end
    assert(file:write("}\n"))
    -- OpenOS close() need not return true and can discard a flush error.
    -- Flush explicitly while its return value can still be checked.
    assert(file:flush())
  end)
  local closeOK,closed,closeErr=pcall(file.close,file)
  if not ok or not closeOK or closed==false or closeErr~=nil then
    fs.remove(tmp)
    return false,why or (not closeOK and closed) or closeErr or "close failed"
  end
  local backup=path..".bak"
  if fs.exists(backup) then fs.remove(backup) end
  if fs.exists(path) then
    local moved,reason=fs.rename(path,backup)
    if not moved then fs.remove(tmp); return false,reason end
  end
  local moved,reason=fs.rename(tmp,path)
  if not moved then if fs.exists(backup) then fs.rename(backup,path) end; fs.remove(tmp) end
  return moved,reason
end
local function hex(s) return (s:gsub(".",function(c) return string.format("%02x",string.byte(c)) end)) end
local function number(n) return finite(n) and string.format("%.17g",n) or "" end
local function frame(body)
  local a,b=1,0
  for i=1,#body do a=(a+body:byte(i))%65521; b=(b+a)%65521 end
  return body.."|"..string.format("%04x%04x",b,a).."|END"
end
local function snapshot(cfg,withPause)
  local rows={}
  for _,section in ipairs({"items","fluids"}) do
    for name,spec in pairs(cfg[section] or {}) do
      if nameOK(name) and type(spec)=="table" then
        local fields={section=="items" and "I" or "F",hex(name),number(spec.low or spec[1]),
            number(spec.target),number(spec.batch or spec[2]),number(spec.refillInterval)}
        if withPause then fields[#fields+1]=spec.paused==true and "1" or "0" end
        rows[#rows+1]={kind=fields[1],name=name,wire=table.concat(fields,"|")}
      end
    end
  end
  table.sort(rows,function(a,b) return a.kind..a.name<b.kind..b.name end)
  return rows
end
-- One bounded page per round trip. Hex names contain neither ';' nor '|'.
local function batchFrame(w,h)
  local prefix="LM4R|"..session.token.."|"..session.index.."|"..#session.rows.."|"
  local capacity=math.min(w*h,4096)
  local used=#prefix+3+13 -- count (up to 64), separator, checksum and END
  local rows={}
  for i=session.index+1,math.min(#session.rows,session.index+64) do
    local row=session.rows[i].wire
    local added=#row+(#rows>0 and 1 or 0)
    if used+added>capacity then break end
    rows[#rows+1]=row;used=used+added
  end
  if #rows==0 and session.index<#session.rows then
    return frame("LM4R|"..session.token.."|ERR|Screen too small")
  end
  return frame(prefix..#rows.."|"..table.concat(rows,";"))
end
function M.paint(gpu)
  if not session or now()>session.untilTime then session=nil; return false end
  if gpu.getScreen()~=session.screen then return false end
  local w,h=gpu.getResolution()
  if session.version=="4" and (session.width~=w or session.height~=h or not session.frame) then
    session.frame=batchFrame(w,h);session.width=w;session.height=h
  end
  local frame=session.frame
  if #frame>w*h then frame=M.errorFrame(session.token) end
  if #frame>w*h then return false end
  if session.version~="4" then gpu.fill(1,1,w,h," ") end
  for y=1,math.ceil(#frame/w) do
    local line=frame:sub((y-1)*w+1,y*w)
    gpu.set(1,y,line..string.rep(" ",w-#line))
  end
  return true
end
function M.errorFrame(token) return frame("LM2R|"..token.."|ERR|Screen too small") end
function M.install(reload,getConfig,onSyncEnd)
  M.uninstall()
  M.listener=function(_,keyboard,message,player)
    if type(message)~="string" then return end
    local bulkToken,bulkScreen,offset=message:match("^LM4|Q|(%x+)|([%x%-]+)|(%d+)$")
    if bulkToken and #bulkToken==16 and #bulkScreen==36 and getConfig then
      offset=tonumber(offset)
      if session and now()>session.untilTime then session=nil end
      local matches=session and session.token==bulkToken and session.screen==bulkScreen and session.version=="4"
      if offset==0 and not matches then
        local ok,cfg=pcall(getConfig)
        if not ok or type(cfg)~="table" then return end
        session={token=bulkToken,screen=bulkScreen,version="4",rows=snapshot(cfg,true)}
        matches=true
      end
      if matches and offset<=#session.rows then
        session.untilTime=now()+5
        if session.index~=offset then session.frame=nil end
        session.index=offset
        pcall(function() M.paint(require("component").gpu) end)
      end
      return
    end
    if message:sub(1,4)=="LM2|" or message:sub(1,4)=="LM3|" then
      local version,token,screen,index=message:match("^LM([23])|Q|(%x+)|([%x%-]+)|(%d+)$")
      if token and #token==16 and #screen==36 and getConfig then
        index=tonumber(index)
        if index==0 then
          local ok,cfg=pcall(getConfig)
          if not ok or type(cfg)~="table" then return end
          session={token=token,screen=screen,version=version,rows=snapshot(cfg,version=="3")}
        end
        if session and session.token==token and session.screen==screen and session.version==version and index<=#session.rows then
          session.untilTime=now()+5
          local row=index>0 and session.rows[index]
          session.frame=frame("LM"..version.."R|"..token.."|"..index.."|"..#session.rows.."|"..(row and row.wire or ""))
          pcall(function() M.paint(require("component").gpu) end)
        end
        return
      end
      local done=message:match("^LM2|END|(%x+)$")
      if done then
        if session and session.token==done then session=nil;if onSyncEnd then pcall(onSyncEnd) end end
        return
      end
    end
    local kind,name,low,target,batch=message:match("^LM1|([IF])|([^|]+)|(%d+)|(%d+)|(%d+)$")
    local previousKind,newKind,newName,newLow,newTarget,newBatch=message:match("^LM2|T|([IF])|([IF])|([^|]+)|(%d+)|(%d+)|(%d+)$")
    if previousKind then kind,name,low,target,batch=newKind,newName,newLow,newTarget,newBatch end
    local pauseKind,pauseName,pauseValue=message:match("^LM2|P|([IF])|([^|]+)|([01])$")
    local pausing=pauseKind~=nil
    local deleteKind,deleteName=message:match("^LM2|D|([IF])|([^|]+)$")
    local deleting=deleteKind~=nil
    if deleting then kind,name=deleteKind,deleteName end
    if pausing then kind,name=pauseKind,pauseName end
    if message:sub(1,4)~="LM1|" and not deleting and not previousKind and not pausing then return end
    low,target,batch=tonumber(low),tonumber(target),tonumber(batch)
    if not kind or not nameOK(name) or (not deleting and not pausing and
      (not low or not target or not batch or low>target or batch<1 or target>1e12 or batch>1e12
        or low~=math.floor(low) or target~=math.floor(target) or batch~=math.floor(batch))) then
      print("[NEI LM] Rejected invalid request from "..tostring(player)); return
    end
    local data,err=read()
    if not data then print("[NEI LM] "..tostring(err)); return end
    local section=kind=="I" and "items" or "fluids"
    local oldSection=previousKind and (previousKind=="I" and "items" or "fluids") or section
    local old=data[oldSection][name]
    if getConfig then
      local ok,cfg=pcall(getConfig)
      if not ok then print("[NEI LM] Cannot read current configuration"); return end
      old=cfg and cfg[oldSection] and cfg[oldSection][name]
    end
    if deleting then data[section][name]=false
    elseif pausing then
      if type(old)~="table" then print("[NEI LM] Entry no longer exists: "..name); return end
      local spec={}; for key,value in pairs(old) do spec[key]=value end
      spec.paused=pauseValue=="1"
      data[section][name]=spec
    else
      local spec={low=low,target=target,batch=batch}
      if type(old)=="table" then
        spec.refillInterval=old.refillInterval; spec.fluidName=old.fluidName or old[3]; spec.paused=old.paused
      end
      data[section][name]=spec
    end
    if previousKind and previousKind~=kind then data[previousKind=="I" and "items" or "fluids"][name]=false end
    local ok,why=save(data)
    if not ok then print("[NEI LM] Save failed: "..tostring(why)); return end
    session=nil
    local applied,reason=pcall(reload)
    if applied then print("[NEI LM] "..(deleting and "Removed " or pausing and (pauseValue=="1" and "Paused " or "Resumed ") or "Updated ")..name)
    else print("[NEI LM] Reload failed: "..tostring(reason)) end
  end
  event.listen("clipboard",M.listener)
end
function M.uninstall()
  if M.listener then event.ignore("clipboard",M.listener) end
  M.listener=nil;session=nil
end
return M
