-- Painel principal: arrastável, responsivo, com busca e categorias.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Components = require(script.Parent.Components)
local T = Config.Theme

local MainPanel = {}
MainPanel.__index = MainPanel

local CATEGORIES = {
    { key = "Progress",  label = "Progressão",  sections = {
        { title = "Auto Farm Level", toggles = {
            { id = "autoFarm", label = "Ativar Auto Farm" },
        }, sliders = {
            { id = "autoFarmMaxDist", label = "Raio (studs)", min = 50, max = 800, default = 250 },
        }},
    }},
    { key = "Combat", label = "Combate PvE", sections = {
        { title = "Auto Combat", toggles = {
            { id = "autoCombat", label = "Ativar Combate PvE" },
        }, sliders = {
            { id = "combatMaxDist", label = "Alcance (studs)", min = 10, max = 150, default = 60 },
            { id = "minHealthToFight", label = "Vida mínima (%)", min = 0, max = 0.9, default = 0.4 },
        }},
    }},
    { key = "Collect", label = "Coleta & Itens", sections = {
        { title = "Auto Collect", toggles = {
            { id = "autoCollect", label = "Ativar Coleta" },
        }},
    }},
    { key = "Raid", label = "Raids", sections = {
        { title = "Auto Raid", toggles = {
            { id = "autoRaid", label = "Ativar Auto Raid" },
        }},
    }},
    { key = "Boss", label = "Chefes", sections = {
        { title = "Auto Boss", toggles = {
            { id = "autoBoss", label = "Ativar Auto Boss" },
        }},
    }},
    { key = "Nav", label = "Navegação", sections = {
        { title = "Auto Navigate", toggles = {
            { id = "autoNavigate", label = "Navegar até destino" },
        }},
    }},
    { key = "Settings", label = "Configurações", sections = {
        { title = "Limites", sliders = {
            { id = "limits.maxSessionMinutes", label = "Sessão (min)", min = 5, max = 240, default = 60 },
            { id = "limits.maxDeaths", label = "Mortes máx.", min = 0, max = 20, default = 3 },
        }},
    }},
}

function MainPanel.new(state, onPatch, onCommand)
    local self = setmetatable({}, MainPanel)
    self.state = state
    self.onPatch = onPatch
    self.onCommand = onCommand
    self.widgets = {}  -- [id] = { set = fn, get = fn }

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutomationUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.gui = gui

    self:_build()
    return self
end

function MainPanel:_build()
    local theme = T
    local win = Instance.new("Frame")
    win.Name = "Window"
    win.BackgroundColor3 = theme.Bg
    win.BorderSizePixel = 0
    local ui = self.state.ui or Config.Defaults.ui
    win.Position = UDim2.new(ui.x, 0, ui.y, 0)
    win.Size = UDim2.fromOffset(ui.w, ui.h)
    win.ClipsDescendants = true
    win.Parent = self.gui
    local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 10); uc.Parent = win
    local us = Instance.new("UIStroke"); us.Color = theme.Border; us.Parent = win
    self.win = win

    -- Barra de título arrastável
    local title = Instance.new("Frame")
    title.Size = UDim2.new(1, 0, 0, 34)
    title.BackgroundColor3 = theme.Panel
    title.BorderSizePixel = 0
    title.Parent = win
    local tcorner = Instance.new("UICorner"); tcorner.CornerRadius = UDim.new(0, 10); tcorner.Parent = title

    local tlabel = Instance.new("TextLabel")
    tlabel.Size = UDim2.new(1, -120, 1, 0)
    tlabel.Position = UDim2.fromOffset(12, 0)
    tlabel.BackgroundTransparency = 1
    tlabel.Text = "◈ AUTOMAÇÃO PvE"
    tlabel.TextColor3 = theme.Text
    tlabel.Font = theme.FontBold
    tlabel.TextSize = 13
    tlabel.TextXAlignment = Enum.TextXAlignment.Left
    tlabel.Parent = title

    local minBtn = Components.button(title, {
        text = "–", size = UDim2.fromOffset(28, 22), position = UDim2.new(1, -88, 0.5, -11),
        color = theme.PanelAlt,
    })
    local closeBtn = Components.button(title, {
        text = "✕", size = UDim2.fromOffset(28, 22), position = UDim2.new(1, -56, 0.5, -11),
        color = theme.Danger,
    })
    local stopBtn = Components.button(title, {
        text = "STOP", size = UDim2.fromOffset(60, 22), position = UDim2.new(1, -152, 0.5, -11),
        color = theme.AccentDim,
    })
    self.minBtn, self.closeBtn, self.stopBtn = minBtn, closeBtn, stopBtn

    -- Sidebar
    local side = Instance.new("Frame")
    side.Size = UDim2.new(0, 140, 1, -34)
    side.Position = UDim2.fromOffset(0, 34)
    side.BackgroundColor3 = theme.Panel
    side.BorderSizePixel = 0
    side.Parent = win
    self.side = side

    -- Content
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -150, 1, -44)
    content.Position = UDim2.fromOffset(145, 38)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.CanvasSize = UDim2.new()
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = win
    self.content = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    -- Search bar
    local search = Instance.new("TextBox")
    search.Size = UDim2.new(1, -150, 0, 26)
    search.Position = UDim2.fromOffset(145, 6)
    search.BackgroundColor3 = theme.PanelAlt
    search.PlaceholderText = "🔍 Buscar função…"
    search.Text = ""
    search.TextColor3 = theme.Text
    search.PlaceholderColor3 = theme.SubText
    search.Font = theme.Font
    search.TextSize = 13
    search.ClearTextOnFocus = false
    search.Parent = win
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 6); sc.Parent = search
    local ss = Instance.new("UIStroke"); ss.Color = theme.Border; ss.Parent = search
    self.search = search

    -- Categorias na sidebar
    local function selectCategory(cat)
        self:_renderCategory(cat)
    end

    for i, cat in ipairs(CATEGORIES) do
        local btn = Components.button(side, {
            text = cat.label,
            size = UDim2.new(1, -12, 0, 30),
            position = UDim2.fromOffset(6, 6 + (i-1)*34),
            color = theme.PanelAlt,
        })
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.MouseButton1Click:Connect(function() selectCategory(cat) end)
    end

    self:_renderCategory(CATEGORIES[1])

    -- Busca
    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q = search.Text:lower()
        self:_applySearch(q)
    end)

    -- Arrastar
    local dragging, dragStart, startPos = false, nil, nil
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = win.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dragStart
            local nx = math.max(0, math.min(1, startPos.X.Scale + delta.X / workspace.CurrentCamera.ViewportSize.X))
            win.Position = UDim2.new(nx, 0, startPos.Y.Scale + delta.Y / workspace.CurrentCamera.ViewportSize.Y, 0)
        end
    end)

    -- Botões
    minBtn.MouseButton1Click:Connect(function()
        ui.minimized = not ui.minimized
        TweenService:Create(win, TweenInfo.new(0.2), {
            Size = ui.minimized and UDim2.fromOffset(ui.w, 34) or UDim2.fromOffset(ui.w, ui.h)
        }):Play()
        self.onPatch({ ui = ui })
    end)
    closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)
    stopBtn.MouseButton1Click:Connect(function()
        if self.onCommand then self.onCommand("stopAll") end
    end)

    -- Responsividade em toque: adapta tamanho mínimo
    if UserInputService.TouchEnabled then
        win.Size = UDim2.fromOffset(math.min(ui.w, workspace.CurrentCamera.ViewportSize.X - 20),
                                    math.min(ui.h, workspace.CurrentCamera.ViewportSize.Y - 40))
    end
end

function MainPanel:_renderCategory(cat)
    for _, c in ipairs(self.content:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for _, section in ipairs(cat.sections) do
        local header = Components.section(self.content, section.title)
        header.LayoutOrder = 1

        if section.toggles then
            for _, t in ipairs(section.toggles) do
                local initial = self:_getValue(t.id)
                local container, setOn, getState = Components.toggle(self.content, t.label, initial, function(v)
                    self:_setValue(t.id, v)
                end)
                container.LayoutOrder = 2
                self.widgets[t.id] = { set = setOn, get = getState }
            end
        end

        if section.sliders then
            for _, s in ipairs(section.sliders) do
                local initial = self:_getValue(s.id) or s.default
                local wrap = Components.slider(self.content, s.label, s.min, s.max, initial, function(v)
                    self:_setValue(s.id, v)
                end)
                wrap.LayoutOrder = 3
            end
        end
    end
end

function MainPanel:_applySearch(q)
    for _, c in ipairs(self.content:GetChildren()) do
        if c:IsA("Frame") then
            local found = false
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:lower():find(q, 1, true) then
                    found = true; break
                end
            end
            c.Visible = (q == "" or found)
        end
    end
end

function MainPanel:_getValue(id)
    -- suporta "limits.maxSessionMinutes"
    local parts = {}
    for p in id:gmatch("[^%.]+") do table.insert(parts, p) end
    local cur = self.state
    for i = 1, #parts - 1 do
        if type(cur[parts[i]]) ~= "table" then return nil end
        cur = cur[parts[i]]
    end
    return cur[parts[#parts]]
end

function MainPanel:_setValue(id, v)
    local parts = {}
    for p in id:gmatch("[^%.]+") do table.insert(parts, p) end
    local cur = self.state
    for i = 1, #parts - 1 do
        if type(cur[parts[i]]) ~= "table" then cur[parts[i]] = {} end
        cur = cur[parts[i]]
    end
    cur[parts[#parts]] = v

    local patch = {}
    if #parts == 1 then
        patch[parts[1]] = v
    else
        patch[parts[1]] = self.state[parts[1]]
    end
    if self.onPatch then self.onPatch(patch) end
end

function MainPanel:updateState(newState)
    self.state = newState
    -- Atualiza toggles visíveis sem recriar
    for id, w in pairs(self.widgets) do
        local v = self:_getValue(id)
        if type(v) == "boolean" and w.set then
            w.set(v, true)  -- silencioso
        end
    end
end

return MainPanel
