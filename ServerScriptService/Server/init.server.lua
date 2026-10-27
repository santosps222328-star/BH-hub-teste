-- Bootstrap: cria remotes, instancia serviços por jogador, expõe estado ao cliente.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes     = require(ReplicatedStorage.Shared.Remotes)
local Config      = require(ReplicatedStorage.Shared.Config)
local GameAPI     = require(ReplicatedStorage.Shared.GameAPI)

local ConfigStore = require(script.Parent.ConfigStore)
local CombatService     = require(script.Parent.CombatService)
local AutoFarmService   = require(script.Parent.AutoFarmService)
local NavigationService = require(script.Parent.NavigationService)
local InventoryService  = require(script.Parent.InventoryService)

local R = Remotes.ensure()

-- Sessões ativas
local sessions = {}  -- [player] = { combat, farm, inv, lastStateSent }

local function buildState(p, s, cfg)
    return {
        cfg = cfg,
        level = GameAPI.getLevel(p),
        xp    = GameAPI.getXP(p),
        resources = GameAPI.getResources(p),
        mastery = GameAPI.getMastery(p),
        inventory = GameAPI.getInventory(p),
        space = GameAPI.inventorySpace(p),
        raid = GameAPI.raidStatus(p),
        combatTarget = s.combat.target and s.combat.target.Name or nil,
        farmTarget = s.farm.currentTarget and s.farm.currentTarget.Name or nil,
        online = true,
    }
end

Players.PlayerAdded:Connect(function(p)
    local cfg = ConfigStore.load(p)
    local session = {
        combat = CombatService.new(p),
        farm   = AutoFarmService.new(p, nil),
        inv    = InventoryService.new(p),
        cfg    = cfg,
    }
    session.farm.combat = session.combat
    sessions[p] = session

    R.funcs.GetState.OnServerInvoke = function(plr)
        if plr ~= p then return nil end
        return buildState(p, session, session.cfg)
    end

    R.events.SetState.OnServerEvent:Connect(function(plr, patch)
        if plr ~= p or type(patch) ~= "table" then return end
        ConfigStore.update(p, patch)
        session.cfg = ConfigStore.get(p)
    end)

    R.events.Command.OnServerEvent:Connect(function(plr, cmd, arg)
        if plr ~= p or type(cmd) ~= "string" then return end
        if cmd == "stopAll" then
            session.cfg.autoFarm, session.cfg.autoCombat = false, false
            session.cfg.autoCollect, session.cfg.autoRaid = false, false
            NavigationService.cancel(p)
            ConfigStore.save(p)
        elseif cmd == "navigateTo" and type(arg) == "table" and arg.x then
            NavigationService.moveTo(p, Vector3.new(arg.x, arg.y, arg.z))
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    local s = sessions[p]
    if s then
        s.combat:destroy()
        s.farm:destroy()
    end
    sessions[p] = nil
end)

-- Loop global (250 ms)
task.spawn(function()
    while true do
        task.wait(0.25)
        for p, s in pairs(sessions) do
            pcall(function()
                s.combat:step(s.cfg)
                s.farm:step(s.cfg)
                s.inv:step(s.cfg)
            end)
            -- Broadcast de estado (a 4 Hz)
            local ok, state = pcall(buildState, p, s, s.cfg)
            if ok and state then
                R.events.SetState:FireClient(p, state)  -- canal de saída (unidirecional)
            end
        end
    end
end)
