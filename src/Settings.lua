-- Preserve user values while refreshing the settings template and its explanations.
local Settings = {}
local function read(text, name)
    local chunk, err = load(text, "=" .. name, "t", {})
    if not chunk then error(err, 0) end
    local values = chunk()
    if type(values) ~= "table" then error(name .. " must return a table", 0) end
    return values
end
local function serialize(value, seen)
    local kind = type(value)
    if kind == "string" then return string.format("%q", value) end
    if kind == "boolean" or kind == "nil" then return tostring(value) end
    if kind == "number" and value == value and value > -math.huge and value < math.huge then
        return string.format("%.17g", value)
    end
    if kind ~= "table" then error("unsupported setting value: " .. kind, 0) end
    seen = seen or {}
    if seen[value] then error("cyclic settings table", 0) end
    seen[value] = true
    local keys, parts = {}, {}
    for key in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then error("unsupported setting key", 0) end
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) < type(b)
    end)
    for _, key in ipairs(keys) do
        parts[#parts + 1] = "[" .. serialize(key, seen) .. "] = " .. serialize(value[key], seen)
    end
    seen[value] = nil
    return "{" .. table.concat(parts, ", ") .. "}"
end
local function equal(a, b)
    return serialize(a) == serialize(b)
end
function Settings.merge(oldText, template)
    local old, defaults = read(oldText, "settings.lua"), read(template, "new settings.lua")
    local known, missing = {}, {}
    local merged = template:gsub("[^\r\n]+", function(line)
        local key = line:match("^settings%.([%w_]+)%s*=")
        if not key then return line end
        known[key] = true
        if old[key] == nil then
            if defaults[key] ~= nil then missing[#missing + 1] = key end
            return line
        end
        -- Leave default-valued assignments byte-for-byte unchanged, including tables.
        if equal(old[key], defaults[key]) then return line end
        -- Template assignments are single-line; find inline comments outside strings.
        local quote, escaped, comment = nil, false, nil
        for i = 1, #line do
            local c = line:sub(i, i)
            if escaped then escaped = false
            elseif quote and c == "\\" then escaped = true
            elseif quote and c == quote then quote = nil
            elseif not quote and (c == '"' or c == "'") then quote = c
            elseif not quote and line:sub(i, i + 1) == "--" then comment = line:sub(i); break end
        end
        return "settings." .. key .. " = " .. serialize(old[key]) .. (comment and " " .. comment or "")
    end)
    -- Keep custom keys rather than silently discarding them during a template refresh.
    local extra = {}
    for key, value in pairs(old) do
        if not known[key] then
            extra[#extra + 1] = "settings[" .. serialize(key) .. "] = " .. serialize(value)
        end
    end
    table.sort(extra)
    if #extra > 0 then
        local count
        merged, count = merged:gsub("return settings", function()
            return "-- Preserved custom settings\n" .. table.concat(extra, "\n") .. "\n\nreturn settings"
        end, 1)
        if count == 0 then error("settings template has no return settings", 0) end
    end
    read(merged, "merged settings.lua") -- verify before offering to replace anything
    return merged, missing
end
return Settings
