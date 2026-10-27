-- Persistência por jogador. Usa DataStore com fallback em memória.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)

local ConfigStore = {}
local cache = {}          -- [userId] = sanitizedConfig
local store
do
    local ok, s = pcall(function() return DataStoreService:GetDataStore("AutoCfg_v1") end)
    if ok then store = s else warn("[ConfigStore] DataStore indisponível; usando memória.") end
end

local KEY = function(uid) return "u_" .. tostring(uid) end

local function loadRemote(uid)
    if not store then return nil end
    local ok, data = pcall(function() return store:GetAsync(KEY(uid)) end)
    return ok and data or nil
end

function ConfigStore.load(player)
    local uid = player.UserId
    if cache[uid] then return cache[uid] end
    local stored = loadRemote(uid)
    cache[uid] = Config.sanitize(stored or Config.Defaults)
    return cache[uid]
end

function ConfigStore.save(player)
    local uid = player.UserId
    local data = cache[uid]
    if not data or not store then return end
    task.spawn(function()
        pcall(function() store:SetAsync(KEY(uid), data) end)
    end)
end

function ConfigStore.get(player) return cache[player.UserId] end

function ConfigStore.update(player, patch)
    local cur = ConfigStore.load(player)
    if type(patch) ~= "table" then return cur end
    for k, v in pairs(patch) do
        if Config.Defaults[k] ~= nil and type(v) == type(Config.Defaults[k]) then
            cur[k] = v
        end
    end
    ConfigStore.save(player)
    return cur
end

Players.PlayerRemoving:Connect(function(p)
    ConfigStore.save(p)
    cache[p.UserId] = nil
end)

return ConfigStore
