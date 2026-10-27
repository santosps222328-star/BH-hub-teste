-- Cria (idempotente) a árvore de remotes em ReplicatedStorage.
-- Cliente e servidor chamam .ensure() no boot.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}
local FOLDER_NAME = "_AutomationRemotes"

local EVENT_NAMES = { "SetState", "Command" }
local FUNC_NAMES  = { "GetState" }

local function getOrCreate(class, name, parent)
    local obj = parent:FindFirstChild(name)
    if obj and obj.ClassName == class then return obj end
    obj = Instance.new(class)
    obj.Name = name
    obj.Parent = parent
    return obj
end

function Remotes.ensure()
    local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end
    local events, funcs = {}, {}
    for _, n in ipairs(EVENT_NAMES) do
        events[n] = getOrCreate("RemoteEvent", n, folder)
    end
    for _, n in ipairs(FUNC_NAMES) do
        funcs[n] = getOrCreate("RemoteFunction", n, folder)
    end
    return { folder = folder, events = events, funcs = funcs }
end

function Remotes.get()
    local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    assert(folder, "Remotes não criados (servidor deve rodar ensure() primeiro)")
    return folder
end

function Remotes.wait()
    -- Cliente: aguarda criação pelo servidor.
    return ReplicatedStorage:WaitForChild(FOLDER_NAME, 10)
end

return Remotes
