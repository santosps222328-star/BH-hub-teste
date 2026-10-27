-- Config.lua — constantes compartilhadas, tema e defaults de configuração.
local Config = {}

Config.Version = "1.0.0"

Config.Theme = {
    Bg       = Color3.fromRGB(18, 18, 20),
    Panel    = Color3.fromRGB(28, 28, 32),
    PanelAlt = Color3.fromRGB(38, 38, 44),
    Accent   = Color3.fromRGB(210, 35, 35),
    AccentDim= Color3.fromRGB(120, 25, 25),
    Text     = Color3.fromRGB(240, 240, 240),
    SubText  = Color3.fromRGB(165, 165, 170),
    Success  = Color3.fromRGB(70, 200, 90),
    Warn     = Color3.fromRGB(240, 180, 60),
    Danger   = Color3.fromRGB(220, 70, 70),
    Border   = Color3.fromRGB(58, 58, 65),
    Font     = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

-- Defaults por jogador. ConfigStore serializa apenas esta tabela.
Config.Defaults = {
    autoFarm       = false,
    autoFarmPriority = "Level",      -- "Level" | "Loot" | "Nearest"
    autoFarmMaxDist = 250,
    autoCollect    = false,
    collectList    = {},             -- whitelist de itemIds
    autoCombat     = false,
    combatPriority = "Distance",     -- "Distance" | "Level"
    combatMaxDist  = 60,
    minHealthToFight = 0.40,         -- 0..1
    autoNavigate   = false,
    navigationDest = nil,            -- {x,y,z}
    autoRaid       = false,
    raidPriority   = {},
    autoBoss       = false,
    bossList       = {},
    masteryTarget  = "Sword",        -- "Sword" | "Melee" | "Fruit" | "Gun"
    limits = {
        maxSessionMinutes = 60,
        maxDeaths         = 3,
    },
    ui = { x = 0.02, y = 0.20, w = 520, h = 380, minimized = false },
}

-- Validação leve: impede que valores estranhos cheguem ao servidor.
function Config.sanitize(cfg)
    local d = Config.Defaults
    local out = {}
    for k, v in pairs(d) do
        if type(v) == "table" then out[k] = {} else out[k] = v end
    end
    if type(cfg) ~= "table" then return out end
    for k, v in pairs(cfg) do
        if d[k] ~= nil and type(v) == type(d[k]) then
            if type(v) == "table" then
                out[k] = v  -- tables específicas validadas nos serviços
            else
                out[k] = v
            end
        end
    end
    -- Clamp numéricos
    out.autoFarmMaxDist = math.clamp(out.autoFarmMaxDist, 50, 1000)
    out.combatMaxDist   = math.clamp(out.combatMaxDist, 10, 200)
    out.minHealthToFight= math.clamp(out.minHealthToFight, 0, 0.95)
    out.limits.maxSessionMinutes = math.clamp(out.limits.maxSessionMinutes, 1, 240)
    out.limits.maxDeaths         = math.clamp(out.limits.maxDeaths, 0, 99)
    return out
end

return Config
