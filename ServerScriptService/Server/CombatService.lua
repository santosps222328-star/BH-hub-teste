-- Combate PvE com autoridade total no servidor.
-- Regras rígidas:
--   * Somente Models com atributo IsNPC == true.
--   * Jogadores NUNCA são alvo (filtro explícito).
--   * Se vida abaixo do limiar → desliga autoCombat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Util   = require(ReplicatedStorage.Shared.Util)
local GameAPI = require(ReplicatedStorage.Shared.GameAPI)

local CombatService = {}
CombatService.__index = CombatService

local ATTACK_COOLDOWN = 0.45
local SEARCH_RADIUS_DEFAULT = 60

local function isPlayerCharacter(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return true end
    end
    return false
end

function CombatService.new(player)
    return setmetatable({
        player = player,
        lastAttack = 0,
        active = false,
        target = nil,
    }, CombatService)
end

function CombatService:_getChar()
    local c = self.player.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then return c, hrp, hum end
    return nil
end

function CombatService:_pickTarget(hrp, cfg)
    if not hrp then return nil end
    local radius = cfg.combatMaxDist or SEARCH_RADIUS_DEFAULT
    local candidates = {}
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:GetAttribute("IsNPC") == true then
            local hum = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root
               and not isPlayerCharacter(m)  -- trava PvP
               and Util.horizontalDist(hrp.Position, root.Position) <= radius
            then
                local lvl = m:GetAttribute("Level") or 1
                local dist = Util.horizontalDist(hrp.Position, root.Position)
                table.insert(candidates, { model = m, humanoid = hum, dist = dist, level = lvl })
            end
        end
    end
    if #candidates == 0 then return nil end

    if cfg.combatPriority == "Level" then
        table.sort(candidates, function(a, b)
            if a.level == b.level then return a.dist < b.dist end
            return a.level < b.level
        end)
    else
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
    end
    return candidates[1]
end

function CombatService:step(cfg)
    if not cfg.autoCombat then self.active = false; return end
    local char, hrp, hum = self:_getChar()
    if not char then self.active = false; return end

    local res = GameAPI.getResources(self.player)
    if res.health < (cfg.minHealthToFight or 0.4) then
        self.active = false
        return  -- recuo (o AutoFarm também verifica isso)
    end

    local now = os.clock()
    if now - self.lastAttack < ATTACK_COOLDOWN then return end

    local chosen = self:_pickTarget(hrp, cfg)
    if not chosen then self.target = nil; return end
    self.target = chosen.model

    local ok = GameAPI.attack(chosen.model)
    if ok then
        self.lastAttack = now
        self.active = true
    end
end

function CombatService:destroy()
    self.active = false
    self.target = nil
end

return CombatService
