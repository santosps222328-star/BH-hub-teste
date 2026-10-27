-- Progressão automática: identifica missões válidas, caminha até NPCs
-- autorizados e delega ao CombatService. Nenhuma decisão de XP é inventada —
-- usa GameAPI.getXP / getLevel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local GameAPI = require(ReplicatedStorage.Shared.GameAPI)
local NavigationService = require(script.Parent.NavigationService)
local CombatService = require(script.Parent.CombatService)

local AutoFarmService = {}
AutoFarmService.__index = AutoFarmService

function AutoFarmService.new(player, combat)
    return setmetatable({
        player = player,
        combat = combat,
        lastXp = 0,
        xpSamples = {},
        startTime = os.time(),
        deaths = 0,
        currentTarget = nil,
    }, AutoFarmService)
end

function AutoFarmService:_findNPCTarget(cfg)
    local hrp = self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myLevel = GameAPI.getLevel(self.player)
    local best, bestScore = nil, math.huge
    local maxDist = cfg.autoFarmMaxDist or 250

    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:GetAttribute("IsNPC") == true then
            local hum = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local lvl = m:GetAttribute("Level") or 1
                local dist = Util.horizontalDist(hrp.Position, root.Position)
                if dist <= maxDist then
                    -- Prioridade: nível próximo do jogador (evita overlevel)
                    local score = dist
                    if cfg.autoFarmPriority == "Level" then
                        score = math.abs(lvl - myLevel) * 100 + dist
                    elseif cfg.autoFarmPriority == "Nearest" then
                        score = dist
                    end
                    if score < bestScore then
                        bestScore, best = score, { model = m, humanoid = hum, root = root }
                    end
                end
            end
        end
    end
    return best
end

function AutoFarmService:step(cfg)
    if not cfg.autoFarm then return end
    local char = self.player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        self.deaths = self.deaths + 1
        return
    end

    -- Encerra por tempo
    if (os.time() - self.startTime) / 60 >= cfg.limits.maxSessionMinutes then
        cfg.autoFarm = false
        return
    end
    if self.deaths > cfg.limits.maxDeaths then
        cfg.autoFarm = false
        return
    end

    -- Vida baixa → para autoFarm (deixa o autoCombat também parar)
    local res = GameAPI.getResources(self.player)
    if res.health < cfg.minHealthToFight then return end

    -- Se autoCombat estiver ativo, ele cuida do alvo próximo.
    if cfg.autoCombat and self.combat.target then return end

    local target = self:_findNPCTarget(cfg)
    if not target then return end
    self.currentTarget = target.model

    -- Ataca se próximo; senão navega.
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local dist = Util.horizontalDist(hrp.Position, target.root.Position)
    if dist > 20 then
        NavigationService.moveTo(self.player, target.root.Position)
    else
        GameAPI.attack(target.model)
    end
end

function AutoFarmService:destroy() end

return AutoFarmService
