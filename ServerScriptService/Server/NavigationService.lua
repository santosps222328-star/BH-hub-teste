-- Navegação PvE legítima: PathfindingService, sem teleporte.
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local NavigationService = {}

local function getChar(player)
    local c = player.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then return c, hrp, hum end
    return nil
end

-- Retorna true se iniciou deslocamento; false em falha.
function NavigationService.moveTo(player, destVector3, opts)
    opts = opts or {}
    local char, hrp, hum = getChar(player)
    if not char then return false, "sem personagem vivo" end

    local path = PathfindingService:CreatePath({
        AgentRadius = opts.agentRadius or 2,
        AgentHeight = opts.agentHeight or 5,
        AgentCanJump = true,
        AgentCanClimb = false,
    })

    local ok, err = pcall(function()
        path:ComputeAsync(hrp.Position, destVector3)
    end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        return false, "sem rota"
    end

    local waypoints = path:GetWaypoints()
    if #waypoints == 0 then return false, "rota vazia" end

    -- Cancela movimentos anteriores
    if char:GetAttribute("_navToken") then
        char:SetAttribute("_navToken", char:GetAttribute("_navToken") + 1)
    else
        char:SetAttribute("_navToken", 1)
    end
    local myToken = char:GetAttribute("_navToken")

    task.spawn(function()
        for i = 2, #waypoints do
            if char:GetAttribute("_navToken") ~= myToken then return end
            local wp = waypoints[i]
            hum:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end
            -- Aguarda chegar ou timeout
            local deadline = os.clock() + 4
            while os.clock() < deadline do
                if char:GetAttribute("_navToken") ~= myToken then return end
                local d = (hrp.Position - wp.Position).Magnitude
                if d < 3 then break end
                task.wait(0.1)
            end
        end
        hum:MoveTo(hrp.Position) -- parar
    end)

    return true
end

function NavigationService.cancel(player)
    local char = player.Character
    if not char then return end
    local t = char:GetAttribute("_navToken") or 0
    char:SetAttribute("_navToken", t + 1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:MoveTo(char.HumanoidRootPart.Position) end
end

return NavigationService
