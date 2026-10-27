-- Componentes reutilizáveis da UI.
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local C = {}
local T = Config.Theme

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end
local function stroke(inst, col)
    local s = Instance.new("UIStroke"); s.Color = col or T.Border; s.Thickness = 1; s.Parent = inst
end

function C.button(parent, opts)
    opts = opts or {}
    local btn = Instance.new("TextButton")
    btn.Size = opts.size or UDim2.fromOffset(120, 32)
    btn.Position = opts.position or UDim2.fromOffset(0, 0)
    btn.BackgroundColor3 = opts.color or T.PanelAlt
    btn.Text = opts.text or "Button"
    btn.TextColor3 = T.Text
    btn.Font = T.Font
    btn.TextSize = 14
    btn.AutoButtonColor = true
    btn.BorderSizePixel = 0
    btn.Parent = parent
    corner(btn, 6)
    stroke(btn, T.Border)
    return btn
end

-- Toggle estilo switch. Retorna (container, setOn, getState).
function C.toggle(parent, label, initial, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 1, 0)
    text.Position = UDim2.fromOffset(0, 0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = T.Text
    text.Font = T.Font
    text.TextSize = 14
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(44, 22)
    track.Position = UDim2.new(1, -44, 0.5, -11)
    track.BackgroundColor3 = initial and T.Accent or T.PanelAlt
    track.Parent = container
    corner(track, 11)
    stroke(track, T.Border)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = initial and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.Parent = track
    corner(knob, 9)

    local state = initial

    local function setOn(v, silent)
        state = v and true or false
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state and T.Accent or T.PanelAlt
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
        }):Play()
        if not silent and onChange then onChange(state) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            setOn(not state)
        end
    end)

    return container, setOn, function() return state end
end

function C.slider(parent, label, min, max, initial, onChanged)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 52)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(initial)
    lbl.TextColor3 = T.SubText
    lbl.Font = T.Font
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.fromOffset(0, 28)
    bar.BackgroundColor3 = T.PanelAlt
    bar.Parent = wrap
    corner(bar, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.Parent = bar
    corner(fill, 4)

    local dragging = false
    local function setFromX(x)
        local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * p
        v = math.floor(v * 100 + 0.5) / 100
        fill.Size = UDim2.new(p, 0, 1, 0)
        lbl.Text = label .. ": " .. tostring(v)
        if onChanged then onChanged(v) end
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(i.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)

    return wrap
end

function C.section(parent, title)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 24)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title:upper()
    lbl.TextColor3 = T.Accent
    lbl.Font = T.FontBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap
    return wrap
end

return C
