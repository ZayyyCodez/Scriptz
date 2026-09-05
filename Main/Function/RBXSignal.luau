-- version 0.09 [beta]
--[[
-- Quick Example:
hook_connection, restore_connection, is_connection_hooked, get_hook_connections = loadstring(game:HttpGet("https://github.com/Backlostunking/Open-Source/raw/refs/heads/main/Function/RBXSignal.luau"))()
for i, r in pairs(game:GetDescendants()) do
    if r:IsA('RemoteEvent') then
        local TargetSignal, signal = r.OnClientEvent, 'OnClientEvent'
        local already_hook = is_connection_hooked(r, signal)
        -- if already_hook then continue end
        print("Found:", i, r:GetFullName(), "Already Hook:", already_hook)
        local signal, state = hook_connection(r, signal, TargetSignal, function(...)
            print(r.Name, "Was Called with arg Passed:", ...)
        end)
        print(`Hook: {signal}, Success: {state}`)
        -- local success = restore_connection(r, signal)
        -- print("Restore:", signal, state, success)
    end
end
]]
local t, f = true, false
local genv = (type(getgenv) == "function" and getgenv()) or _G
genv._connection_hooks = genv._connection_hooks or {}
function get_hook_connections()
    return genv._connection_hooks
end
function is_connection_hooked(obj: Instance?, k: string?): boolean
    if typeof(obj) ~= "Instance" or type(k) ~= "string" then return f end
    local od = genv._connection_hooks[obj]
    if not od then return f end
    local sd = od[k]
    if not sd or not sd.connections then return f end
    return #sd.connections > 0
end
function restore_connection(obj: Instance, k: string): boolean
    if not is_connection_hooked(obj, k) then return f end
    local od = genv._connection_hooks[obj]
    local sd = od[k]
    if not sd then return f end
    local s = true
    for _, c in pairs(sd.connections) do
        local su = pcall(function()
            local s = pcall(c.Disconnect, c)
            if not s then s = pcall(c.disconnect, c) end
            return s
        end)
        if not su then
            s = false
        end
    end
    od[k] = nil
    if next(od) == nil then
        genv._connection_hooks[obj] = nil
    end
    return s
end
function hook_connection(obj: Instance, k: string, signal: RBXScriptSignal, func: (...any) -> (), usingOnce: boolean?, autoRestore: boolean?): any?
    if typeof(obj) ~= "Instance" or type(k) ~= "string" or typeof(signal) ~= "RBXScriptSignal" then return nil end
    if autoRestore then restore_connection(obj, k) end
    if type(func) ~= "function" then return nil end
    local od = genv._connection_hooks[obj]
    if not od then
        od = {}
        genv._connection_hooks[obj] = od
    end
    local sd = od[k]
    if not sd then
        sd = {connections = {}}
        od[k] = sd
    end
    if #sd.connections > 0 then return nil end
    local conn
    local callback = function(...)
        pcall(func, ...)
        if usingOnce then restore_connection(obj, k) end
    end
    local ss = pcall(function()
        if usingOnce then
            s, c = pcall(signal.Once, signal, callback)
        else
            s, c = pcall(signal.Connect, signal, callback)
        end
        return s
    end)
    if not ss then
        ss = pcall(function()
            if usingOnce then
                s, c = pcall(signal.once, signal, callback)
            else
                s, c = pcall(signal.connect, signal, callback)
            end
            return s
        end)
    end
    if not (s or c) then return nil end
    conn = c
    table.insert(sd.connections, conn)
    return signal, s
end
return hook_connection, restore_connection, is_connection_hooked, get_hook_connections
