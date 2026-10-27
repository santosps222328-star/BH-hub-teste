local Util = {}

function Util.dist2(a, b)
    local dx, dy, dz = a.X-b.X, a.Y-b.Y, a.Z-b.Z
    return dx*dx + dy*dy + dz*dz
end

function Util.horizontalDist(a, b)
    local dx, dz = a.X-b.X, a.Z-b.Z
    return math.sqrt(dx*dx + dz*dz)
end

function Util.isAlive(humanoid)
    return humanoid and humanoid.Parent and humanoid.Health > 0
end

-- Retorna todos os Humanoids hostis ao longo de um container, com filtro de tag.
function Util.collectNPCs(container, tagFilter)
    local out = {}
    for _, m in ipairs(container:GetDescendants()) do
        if m:IsA("Humanoid") and Util.isAlive(m) then
            local model = m.Parent
            if model and model:FindFirstChild("IsNPC") then
                if not tagFilter or model:GetAttribute(tagFilter) then
                    table.insert(out, { model = model, humanoid = m })
                end
            end
        end
    end
    return out
end

function Util.truncate(str, n)
    str = tostring(str or "")
    if #str <= n then return str end
    return str:sub(1, n-1) .. "…"
end

function Util.uuid()
    return string.format("%x-%x-%x", math.random(1e9), os.time(), math.random(1e9))
end

return Util
