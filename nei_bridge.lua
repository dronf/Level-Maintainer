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
local function snapshot(cfg)
  local rows={}
  for _,section in ipairs({"items","fluids"}) do
    for name,spec in pairs(cfg[section] or {}) do
      if nameOK(name) and type(spec)=="table" then
        rows[#rows+1]={kind=section=="items" and "I" or "F",name=name,
          wire=table.concat({section=="items" and "I" or "F",hex(name),number(spec.low or spec[1]),
            number(spec.target),number(spec.batch or spec[2]),number(spec.refillInterval)},"|")}
      end
    end
  end
  table.sort(rows,function(a,b) return a.kind..a.name<b.kind..b.name end)
  return rows
end
function M.paint(gpu)
  if not session or now()>session.untilTime then session=nil; return false end
  if gpu.getScreen()~=session.screen then return false end
  local w,h=gpu.getResolution()
  local frame=session.frame
  if #frame>w*h then frame=M.errorFrame(session.token) end
  if #frame>w*h then return false end
  gpu.fill(1,1,w,h," ")
  for y=1,math.ceil(#frame/w) do gpu.set(1,y,frame:sub((y-1)*w+1,y*w)) end
  return true
end
function M.errorFrame(token) return frame("LM2R|"..token.."|ERR|Screen too small") end
function M.install(reload,getConfig)
  M.uninstall()
  M.listener=function(_,keyboard,message,player)
    if type(message)~="string" then return end
    if message:sub(1,4)=="LM2|" then
      local token,screen,index=message:match("^LM2|Q|(%x+)|([%x%-]+)|(%d+)$")
      if token and #token==16 and #screen==36 and getConfig then
        index=tonumber(index)
        if index==0 then
          local ok,cfg=pcall(getConfig)
          if not ok or type(cfg)~="table" then return end
          session={token=token,screen=screen,rows=snapshot(cfg)}
        end
        if session and session.token==token and session.screen==screen and index<=#session.rows then
          session.untilTime=now()+5
          local row=index>0 and session.rows[index]
          session.frame=frame("LM2R|"..token.."|"..index.."|"..#session.rows.."|"..(row and row.wire or ""))
          pcall(function() M.paint(require("component").gpu) end)
        end
        return
      end
      local done=message:match("^LM2|END|(%x+)$")
      if done then if session and session.token==done then session=nil end; return end
    end
    local kind,name,low,target,batch=message:match("^LM1|([IF])|([^|]+)|(%d+)|(%d+)|(%d+)$")
    local deleteKind,deleteName=message:match("^LM2|D|([IF])|([^|]+)$")
    local deleting=deleteKind~=nil
    if deleting then kind,name=deleteKind,deleteName end
    if message:sub(1,4)~="LM1|" and not deleting then return end
    low,target,batch=tonumber(low),tonumber(target),tonumber(batch)
    if not kind or not nameOK(name) or (not deleting and
      (not low or not target or not batch or low>target or batch<1 or target>1e12 or batch>1e12
        or low~=math.floor(low) or target~=math.floor(target) or batch~=math.floor(batch))) then
      print("[NEI LM] Rejected invalid request from "..tostring(player)); return
    end
    local data,err=read()
    if not data then print("[NEI LM] "..tostring(err)); return end
    local section=kind=="I" and "items" or "fluids"
    if deleting then data[section][name]=false
    else
      local spec={low=low,target=target,batch=batch}
      if getConfig then
        local ok,cfg=pcall(getConfig)
        local old=ok and cfg and cfg[section] and cfg[section][name]
        if type(old)=="table" then spec.refillInterval=old.refillInterval; spec.fluidName=old.fluidName or old[3] end
      end
      data[section][name]=spec
    end
    local ok,why=save(data)
    if not ok then print("[NEI LM] Save failed: "..tostring(why)); return end
    session=nil
    local applied,reason=pcall(reload)
    if applied then print("[NEI LM] "..(deleting and "Removed " or "Updated ")..name)
    else print("[NEI LM] Reload failed: "..tostring(reason)) end
  end
  event.listen("clipboard",M.listener)
end
function M.uninstall()
  if M.listener then event.ignore("clipboard",M.listener) end
  M.listener=nil;session=nil
end
return M
