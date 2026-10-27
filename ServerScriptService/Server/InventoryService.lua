-- Espelha o inventário (fonte da verdade = GameAPI) e dispara auto-coleta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameAPI = require(ReplicatedStorage.Shared.GameAPI)
local NavigationService = require(script.Parent.NavigationService)

local InventoryService = {}
InventoryService.__index = InventoryService

function InventoryService.new(player)
    return setmetatable({
        player = player,
        lastSnapshot = nil,
        collectCooldown = 0,
    }, InventoryService)
end

function InventoryService:snapshot()
    local inv = GameAPI.getInventory(self.player)
    self.lastSnapshot = inv
    return inv
end

function InventoryService:step(cfg)
    if not cfg.autoCollect then return end
    local now = os.clock()
    if now - self.collectCooldown < 0.5 then return end
    self.collectCooldown = now

    local char = self.player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local allow = {}
    for _, id in ipairs(cfg.collectList or {}) do allow[id] = true end

    local best, bestD = nil, math.huge
    for _, item in ipairs(GameAPI.listCollectibles(self.player)) do
        if allow[item.id] then
            local d = (hrp.Position - item.position).Magnitude
            if d < bestD then bestD, best = d, item end
        end
    end
    if not best then return end

    if bestD > 15 then
        NavigationService.moveTo(self.player, best.position)
    else
        GameAPI.tryCollect(self.player, best.id)
    end
end

return InventoryService
