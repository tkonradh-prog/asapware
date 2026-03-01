--- START OF FILE Paste ASAPWARE V20 (THE PINNACLE - PIXEL PERFECT DESIGN) ---

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local origLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd
}

-- ==========================================
-- 1. KONFIGURACJA
-- ==========================================
local config = {
    esp_enabled = true,
    teamCheck = false,
    whitelist = {}, 
    toggles = {
        boxes = true, healthbars = true, healthtext = true, names = true, 
        weapons = true, distances = true, skeletons = true, tracers = false, 
        chams = false, head_dots = false, look_tracers = false, offscreen_arrows = false,
        world_enabled = false, fog_enabled = false, shadows_enabled = true,
        time_changer = false, fov_changer = false, third_person = false,
        aim_enabled = false, aim_showFov = true, aim_crosshair = true, 
        aim_wallCheck = true, aim_predict = false,
        rainbow_ui = false, bhop = false, fly = false, noclip = false, godmode = false, watermark = true
    },
    sliders = {
        aim_distance = 1500, aim_fov = 100, aim_smooth = 5, aim_offsetX = 0, aim_offsetY = 0, aim_pred_amt = 10,
        esp_distance = 1500, boxThickness = 1, arrow_radius = 200, arrow_size = 15,
        custom_time = 12, custom_fov = 90, brightness = 20, exposure = 0, fog_start = 0, fog_end = 1000,
        fly_speed = 50, tp_speed = 150
    },
    colors = {
        enemy_esp = Color3.fromRGB(255, 75, 75),
        chams_fill = Color3.fromRGB(255, 0, 0),
        chams_outline = Color3.fromRGB(255, 255, 255),
        ui_accent = Color3.fromRGB(0, 150, 255),
        ambient_color = Color3.fromRGB(100, 100, 100),
        outdoor_ambient = Color3.fromRGB(120, 120, 120),
        fog_color = Color3.fromRGB(200, 200, 200)
    },
    selectors = { aim_part = 1, aim_method = 1, tracer_origin = 1, fly_method = 1 },
    keybinds = { aimbot = Enum.UserInputType.MouseButton2, fly = Enum.KeyCode.F, menu = Enum.KeyCode.Insert },
    selectedPlayer = nil
}

local ESP_COLORS = { Outline = Color3.fromRGB(10, 10, 12), Skeleton = Color3.fromRGB(255, 255, 255), Arrow = Color3.fromRGB(255, 75, 75) }
local flyPlatform = nil
local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true
local ScriptLoaded = true

local function GetHealth(player)
    if player and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then return hum.Health, hum.MaxHealth end
    end
    return 0, 100
end

-- ==========================================
-- 2. MOTYW UI - PIXEL PERFECT
-- ==========================================
local TargetGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Asapware_V20"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = TargetGui end)

local Theme = {
    MainBg = Color3.fromRGB(10, 10, 13),
    SidebarBg = Color3.fromRGB(14, 14, 18),
    CardBg = Color3.fromRGB(17, 17, 21),
    ItemBg = Color3.fromRGB(22, 22, 27),
    ItemHover = Color3.fromRGB(28, 28, 34),
    Border = Color3.fromRGB(32, 32, 38),
    Text = Color3.fromRGB(250, 250, 250),
    SubText = Color3.fromRGB(135, 140, 150),
    ToggleOff = Color3.fromRGB(36, 36, 44),
    Danger = Color3.fromRGB(255, 60, 60),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontCode = Enum.Font.RobotoMono
}

local function Tween(obj, props, time)
    local t = time or 0.15 -- Szybsze, bardziej responsywne animacje
    pcall(function() TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play() end)
end

local DragContainer = Instance.new("Frame", ScreenGui)
DragContainer.Size = UDim2.new(0, 860, 0, 600)
DragContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
DragContainer.AnchorPoint = Vector2.new(0.5, 0.5)
DragContainer.BackgroundColor3 = Theme.MainBg
DragContainer.BorderSizePixel = 0
Instance.new("UICorner", DragContainer).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", DragContainer)
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1
DragContainer.ClipsDescendants = true

local dragging, dragInput, dragStart, startPos
DragContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true dragStart = input.Position startPos = DragContainer.Position
    end
end)
DragContainer.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        DragContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local UpdatePreviewEvent = Instance.new("BindableEvent")
local UIThemeObjects = {}
local function ApplyAccent(obj, property)
    table.insert(UIThemeObjects, {Obj = obj, Prop = property})
    obj[property] = config.colors.ui_accent
end
local function UpdateAccents()
    for _, item in ipairs(UIThemeObjects) do pcall(function() Tween(item.Obj, {[item.Prop] = config.colors.ui_accent}) end) end
end

-- ================== -- WATERMARK -- ==================
local Watermark = Instance.new("Frame", ScreenGui)
Watermark.Size = UDim2.new(0, 250, 0, 28)
Watermark.Position = UDim2.new(0, 20, 0, 20)
Watermark.BackgroundColor3 = Theme.CardBg
Watermark.BorderSizePixel = 0
Watermark.Visible = config.toggles.watermark
Instance.new("UICorner", Watermark).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", Watermark).Color = Theme.Border

local WatermarkLine = Instance.new("Frame", Watermark)
WatermarkLine.Size = UDim2.new(1, 0, 0, 2)
WatermarkLine.Position = UDim2.new(0, 0, 0, 0)
WatermarkLine.BorderSizePixel = 0
Instance.new("UICorner", WatermarkLine).CornerRadius = UDim.new(0, 6)
ApplyAccent(WatermarkLine, "BackgroundColor3")

local WatermarkText = Instance.new("TextLabel", Watermark)
WatermarkText.Size = UDim2.new(1, -20, 1, 0)
WatermarkText.Position = UDim2.new(0, 10, 0, 1)
WatermarkText.BackgroundTransparency = 1
WatermarkText.RichText = true
WatermarkText.Font = Theme.FontBold
WatermarkText.TextSize = 12
WatermarkText.TextColor3 = Theme.Text
WatermarkText.TextXAlignment = Enum.TextXAlignment.Left

local frameCount, lastTick, currentFPS = 0, tick(), 60
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastTick >= 1 then
        currentFPS = math.floor(frameCount / (now - lastTick))
        frameCount, lastTick = 0, now
    end
    if config.toggles.watermark then
        Watermark.Visible = true
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local hex = string.format("#%02X%02X%02X", config.colors.ui_accent.R*255, config.colors.ui_accent.G*255, config.colors.ui_accent.B*255)
        WatermarkText.Text = "A S A P W A R E <font color='"..hex.."'>|</font> FPS: " .. tostring(currentFPS) .. " <font color='"..hex.."'>|</font> " .. tostring(ping) .. "ms"
    else Watermark.Visible = false end
end)

-- ================== -- STRUKTURA GŁÓWNA -- ==================
local Sidebar = Instance.new("Frame", DragContainer)
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
local SidebarLine = Instance.new("Frame", Sidebar)
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, 0, 0, 0)
SidebarLine.BackgroundColor3 = Theme.Border
SidebarLine.BorderSizePixel = 0

local TopBar = Instance.new("Frame", DragContainer)
TopBar.Size = UDim2.new(1, -200, 0, 50)
TopBar.Position = UDim2.new(0, 200, 0, 0)
TopBar.BackgroundTransparency = 1
local TopLine = Instance.new("Frame", TopBar)
TopLine.Size = UDim2.new(1, 0, 0, 1)
TopLine.Position = UDim2.new(0, 0, 1, 0)
TopLine.BackgroundColor3 = Theme.Border
TopLine.BorderSizePixel = 0

local TabContainer = Instance.new("Frame", DragContainer)
TabContainer.Size = UDim2.new(1, -200, 1, -50)
TabContainer.Position = UDim2.new(0, 200, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.ClipsDescendants = true

local Logo = Instance.new("TextLabel", Sidebar)
Logo.Size = UDim2.new(1, 0, 0, 70)
Logo.BackgroundTransparency = 1
Logo.Text = "A S A P W A R E"
Logo.TextColor3 = Theme.Text
Logo.Font = Enum.Font.GothamBlack
Logo.TextSize = 17
Logo.TextXAlignment = Enum.TextXAlignment.Center

local SidebarScroll = Instance.new("ScrollingFrame", Sidebar)
SidebarScroll.Size = UDim2.new(1, 0, 1, -140)
SidebarScroll.Position = UDim2.new(0, 0, 0, 70)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 0
local SidebarLayout = Instance.new("UIListLayout", SidebarScroll)
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ProfileArea = Instance.new("Frame", Sidebar)
ProfileArea.Size = UDim2.new(1, 0, 0, 70)
ProfileArea.Position = UDim2.new(0, 0, 1, -70)
ProfileArea.BackgroundTransparency = 1
local ProfLine = Instance.new("Frame", ProfileArea)
ProfLine.Size = UDim2.new(1, 0, 0, 1)
ProfLine.BackgroundColor3 = Theme.Border
ProfLine.BorderSizePixel = 0

local Avatar = Instance.new("ImageLabel", ProfileArea)
Avatar.Size = UDim2.new(0, 38, 0, 38)
Avatar.Position = UDim2.new(0, 20, 0.5, -19)
Avatar.BackgroundColor3 = Theme.Border
Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)
task.spawn(function() pcall(function() Avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end) end)

local Username = Instance.new("TextLabel", ProfileArea)
Username.Size = UDim2.new(1, -75, 0, 16)
Username.Position = UDim2.new(0, 68, 0.5, -14)
Username.BackgroundTransparency = 1
Username.Text = LocalPlayer.Name
Username.TextColor3 = Theme.Text
Username.Font = Theme.FontBold
Username.TextSize = 13
Username.TextXAlignment = Enum.TextXAlignment.Left

local SubText = Instance.new("TextLabel", ProfileArea)
SubText.Size = UDim2.new(1, -75, 0, 14)
SubText.Position = UDim2.new(0, 68, 0.5, 4)
SubText.BackgroundTransparency = 1
SubText.RichText = true
SubText.Text = "Till: <font color='#00a0ff'>Lifetime</font>"
SubText.Font = Theme.Font
SubText.TextSize = 11
SubText.TextXAlignment = Enum.TextXAlignment.Left

local Tabs = {}
local globalLayoutOrder = 0

local function CreateCategory(name)
    globalLayoutOrder = globalLayoutOrder + 10
    local lbl = Instance.new("TextLabel", SidebarScroll)
    lbl.Size = UDim2.new(1, -40, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(name)
    lbl.TextColor3 = Theme.SubText
    lbl.Font = Theme.FontBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = globalLayoutOrder
end

local function CreateTab(name, isFirst)
    globalLayoutOrder = globalLayoutOrder + 1
    local btnContainer = Instance.new("Frame", SidebarScroll)
    btnContainer.Size = UDim2.new(1, -24, 0, 32)
    btnContainer.BackgroundTransparency = 1
    btnContainer.LayoutOrder = globalLayoutOrder

    local btn = Instance.new("TextButton", btnContainer)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = isFirst and 0 or 1
    btn.BackgroundColor3 = Theme.ItemBg
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.new(0, 15, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = name
    txt.TextColor3 = isFirst and Theme.Text or Theme.SubText
    txt.Font = Theme.FontBold
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 3, isFirst and 0.4 or 0, 0)
    indicator.Position = UDim2.new(0, -8, 0.3, 0)
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    if isFirst then ApplyAccent(indicator, "BackgroundColor3") end

    local page = Instance.new("ScrollingFrame", TabContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = isFirst and UDim2.new(0,0,0,0) or UDim2.new(0,0,0,50)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Border
    page.Visible = isFirst
    page.BorderSizePixel = 0

    local pagePadding = Instance.new("UIPadding", page)
    pagePadding.PaddingTop = UDim.new(0, 15)
    pagePadding.PaddingBottom = UDim.new(0, 15)
    pagePadding.PaddingLeft = UDim.new(0, 20)
    pagePadding.PaddingRight = UDim.new(0, 15)

    local colLeft = Instance.new("Frame", page)
    colLeft.Size = UDim2.new(0.48, 0, 0, 0)
    colLeft.BackgroundTransparency = 1
    local lLayout = Instance.new("UIListLayout", colLeft)
    lLayout.Padding = UDim.new(0, 15)

    local colRight = Instance.new("Frame", page)
    colRight.Size = UDim2.new(0.48, 0, 0, 0)
    colRight.Position = UDim2.new(0.52, 0, 0, 0)
    colRight.BackgroundTransparency = 1
    local rLayout = Instance.new("UIListLayout", colRight)
    rLayout.Padding = UDim.new(0, 15)

    local function UpdateCanvas()
        local hL = lLayout.AbsoluteContentSize.Y
        local hR = rLayout.AbsoluteContentSize.Y
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(hL, hR) + 30)
        colLeft.Size = UDim2.new(0.48, 0, 0, hL)
        colRight.Size = UDim2.new(0.48, 0, 0, hR)
    end
    lLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

    table.insert(Tabs, {Btn = btn, Txt = txt, Ind = indicator, Page = page})

    btn.MouseEnter:Connect(function() if not page.Visible then Tween(btn, {BackgroundTransparency = 0.5}) end end)
    btn.MouseLeave:Connect(function() if not page.Visible then Tween(btn, {BackgroundTransparency = 1}) end end)

    btn.MouseButton1Click:Connect(function()
        if page.Visible then return end
        for _, t in ipairs(Tabs) do
            Tween(t.Txt, {TextColor3 = Theme.SubText})
            Tween(t.Btn, {BackgroundTransparency = 1})
            Tween(t.Ind, {Size = UDim2.new(0, 3, 0, 0)})
            if t.Page.Visible then
                Tween(t.Page, {Position = UDim2.new(0, 0, 0, 20)})
                task.delay(0.15, function() t.Page.Visible = false end)
            end
        end
        Tween(txt, {TextColor3 = Theme.Text})
        Tween(btn, {BackgroundTransparency = 0})
        Tween(indicator, {Size = UDim2.new(0, 3, 0.4, 0)})
        
        page.Visible = true
        page.Position = UDim2.new(0, 0, 0, 20)
        Tween(page, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
        UpdateCanvas()
    end)
    
    return {Left = colLeft, Right = colRight}
end

-- ================== -- KONTROLKI UI -- ==================
local function CreateSection(col, title)
    local sec = Instance.new("Frame", col)
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.BackgroundColor3 = Theme.CardBg
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 6)
    local str = Instance.new("UIStroke", sec)
    str.Color = Theme.Border
    str.Thickness = 1

    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, -30, 0, 36)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.FontBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", sec)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, 36)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0

    local content = Instance.new("Frame", sec)
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 37)
    content.BackgroundTransparency = 1
    
    local cPadding = Instance.new("UIPadding", content)
    cPadding.PaddingTop = UDim.new(0, 12)
    cPadding.PaddingBottom = UDim.new(0, 15)
    cPadding.PaddingLeft = UDim.new(0, 15)
    cPadding.PaddingRight = UDim.new(0, 15)
    
    local cLayout = Instance.new("UIListLayout", content)
    cLayout.Padding = UDim.new(0, 8)
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder

    cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.Size = UDim2.new(1, 0, 0, cLayout.AbsoluteContentSize.Y + 27)
        sec.Size = UDim2.new(1, 0, 0, content.Size.Y.Offset + 37)
    end)

    return content
end

local elementLayoutCounter = 0
local function GetNextLayoutOrder()
    elementLayoutCounter = elementLayoutCounter + 1
    return elementLayoutCounter
end

local function CreateToggle(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = GetNextLayoutOrder()

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 34, 0, 18)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.BackgroundColor3 = tbl[key] and config.colors.ui_accent or Theme.ToggleOff
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame", btn)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, tbl[key] and 18 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local shadow = Instance.new("UIStroke", circle)
    shadow.Color = Color3.new(0,0,0)
    shadow.Transparency = 0.8

    if tbl[key] then ApplyAccent(btn, "BackgroundColor3") end

    local function updateVisual()
        if tbl[key] then
            ApplyAccent(btn, "BackgroundColor3")
            Tween(circle, {Position = UDim2.new(0, 18, 0.5, -7)})
        else
            for i, item in ipairs(UIThemeObjects) do
                if item.Obj == btn then table.remove(UIThemeObjects, i) break end
            end
            Tween(btn, {BackgroundColor3 = Theme.ToggleOff})
            Tween(circle, {Position = UDim2.new(0, 2, 0.5, -7)})
        end
    end
    UpdatePreviewEvent.Event:Connect(updateVisual)

    btn.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        updateVisual()
        UpdatePreviewEvent:Fire()
    end)
end

local function CreateSlider(parent, text, tbl, key, min, max)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = GetNextLayoutOrder()

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -30, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0, 30, 0, 14)
    valLbl.Position = UDim2.new(1, -30, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(tbl[key])
    valLbl.TextColor3 = Theme.SubText
    valLbl.Font = Theme.FontCode
    valLbl.TextSize = 11
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 1, -6)
    track.BackgroundColor3 = Theme.ToggleOff
    track.Text = ""
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((tbl[key]-min)/(max-min), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    ApplyAccent(fill, "BackgroundColor3")

    local knob = Instance.new("Frame", fill)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(1, -5, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", knob).Color = Theme.Border

    local dragging = false
    local function update(i)
        local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pct))
        tbl[key] = val
        valLbl.Text = tostring(val)
        Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
        UpdatePreviewEvent:Fire()
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true 
            Tween(knob, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7)})
            update(i) 
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false 
            Tween(knob, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -5, 0.5, -5)})
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end
    end)
end

local function CreateDropdown(parent, text, tbl, key, options)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false -- WAŻNE ABY LISTA WYCHODZIŁA POZA RAMKE
    frame.ZIndex = 50 -- WYSOKI Z-INDEX
    frame.LayoutOrder = GetNextLayoutOrder()

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.Position = UDim2.new(0, 0, 1, -24)
    btn.BackgroundColor3 = Theme.ItemBg
    btn.Text = "   " .. options[tbl[key]]
    btn.TextColor3 = Theme.SubText
    btn.Font = Theme.Font
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 51
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", btn).Color = Theme.Border

    local arrow = Instance.new("TextLabel", btn)
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.SubText
    arrow.TextSize = 10
    arrow.ZIndex = 51

    local listFrame = Instance.new("Frame", frame)
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.Position = UDim2.new(0, 0, 0, 48)
    listFrame.BackgroundColor3 = Theme.ItemBg
    listFrame.ClipsDescendants = true
    listFrame.ZIndex = 52
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)
    local listStr = Instance.new("UIStroke", listFrame)
    listStr.Color = Theme.Border
    listStr.Transparency = 1
    
    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local isOpen = false

    -- FIX Z-INDEXÓW DLA INNYCH ELEMENTÓW KIEDY OTWARTE
    local function setZIndex(val)
        frame.ZIndex = val
        btn.ZIndex = val + 1
        arrow.ZIndex = val + 1
        listFrame.ZIndex = val + 2
        for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c.ZIndex = val + 3 end end
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            setZIndex(100)
            listStr.Transparency = 0
            Tween(listFrame, {Size = UDim2.new(1, 0, 0, #options * 24)})
            Tween(arrow, {Rotation = 180})
        else
            Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
            Tween(arrow, {Rotation = 0})
            task.delay(0.2, function() listStr.Transparency = 1 setZIndex(50) end)
        end
    end)

    for i, optionText in ipairs(options) do
        local optBtn = Instance.new("TextButton", listFrame)
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = "   " .. optionText
        optBtn.TextColor3 = (tbl[key] == i) and config.colors.ui_accent or Theme.SubText
        optBtn.Font = Theme.Font
        optBtn.TextSize = 11
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.LayoutOrder = i
        
        if tbl[key] == i then ApplyAccent(optBtn, "TextColor3") end

        optBtn.MouseEnter:Connect(function() if tbl[key] ~= i then Tween(optBtn, {TextColor3 = Theme.Text}, 0.1) end end)
        optBtn.MouseLeave:Connect(function() if tbl[key] ~= i then Tween(optBtn, {TextColor3 = Theme.SubText}, 0.1) end end)

        optBtn.MouseButton1Click:Connect(function()
            tbl[key] = i
            btn.Text = "   " .. optionText
            
            for _, b in ipairs(listFrame:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextColor3 = Theme.SubText
                    for idx, item in ipairs(UIThemeObjects) do
                        if item.Obj == b then table.remove(UIThemeObjects, idx) break end
                    end
                end
            end
            optBtn.TextColor3 = config.colors.ui_accent
            ApplyAccent(optBtn, "TextColor3")
            
            isOpen = false
            Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
            Tween(arrow, {Rotation = 0})
            task.delay(0.2, function() listStr.Transparency = 1 setZIndex(50) end)
            UpdatePreviewEvent:Fire()
        end)
    end
end

local function CreateColorPicker(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false
    frame.ZIndex = 50
    frame.LayoutOrder = GetNextLayoutOrder()
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -40, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local colorBtn = Instance.new("TextButton", frame)
    colorBtn.Size = UDim2.new(0, 30, 0, 16)
    colorBtn.AnchorPoint = Vector2.new(1, 0.5)
    colorBtn.Position = UDim2.new(1, 0, 0.5, 0)
    colorBtn.BackgroundColor3 = tbl[key]
    colorBtn.Text = ""
    colorBtn.ZIndex = 51
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", colorBtn).Color = Theme.Border
    
    local pickerBox = Instance.new("Frame", frame)
    pickerBox.Size = UDim2.new(1, 0, 0, 0)
    pickerBox.Position = UDim2.new(0, 0, 0, 30)
    pickerBox.BackgroundColor3 = Theme.ItemBg
    pickerBox.ClipsDescendants = true
    pickerBox.ZIndex = 52
    Instance.new("UICorner", pickerBox).CornerRadius = UDim.new(0, 4)
    local pStr = Instance.new("UIStroke", pickerBox)
    pStr.Color = Theme.Border
    pStr.Transparency = 1
    
    local svMap = Instance.new("TextButton", pickerBox)
    svMap.Size = UDim2.new(1, -25, 1, -10)
    svMap.Position = UDim2.new(0, 5, 0, 5)
    svMap.AutoButtonColor = false
    svMap.Text = ""
    svMap.ZIndex = 53
    Instance.new("UICorner", svMap).CornerRadius = UDim.new(0, 4)
    
    local svWhite = Instance.new("Frame", svMap)
    svWhite.Size = UDim2.new(1,0,1,0)
    svWhite.BackgroundColor3 = Color3.new(1,1,1)
    svWhite.ZIndex = 54
    Instance.new("UICorner", svWhite).CornerRadius = UDim.new(0, 4)
    local uigW = Instance.new("UIGradient", svWhite)
    uigW.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}
    
    local svBlack = Instance.new("Frame", svMap)
    svBlack.Size = UDim2.new(1,0,1,0)
    svBlack.BackgroundColor3 = Color3.new(0,0,0)
    svBlack.ZIndex = 55
    Instance.new("UICorner", svBlack).CornerRadius = UDim.new(0, 4)
    local uigB = Instance.new("UIGradient", svBlack)
    uigB.Rotation = 90
    uigB.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}
    
    local cursorSV = Instance.new("Frame", svMap)
    cursorSV.Size = UDim2.new(0, 4, 0, 4)
    cursorSV.BackgroundColor3 = Color3.new(1,1,1)
    cursorSV.ZIndex = 56
    Instance.new("UICorner", cursorSV).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", cursorSV).Color = Color3.new(0,0,0)

    local hueBar = Instance.new("TextButton", pickerBox)
    hueBar.Size = UDim2.new(0, 10, 1, -10)
    hueBar.Position = UDim2.new(1, -15, 0, 5)
    hueBar.BackgroundColor3 = Color3.new(1,1,1)
    hueBar.AutoButtonColor = false
    hueBar.Text = ""
    hueBar.ZIndex = 53
    Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 4)
    
    local uigH = Instance.new("UIGradient", hueBar)
    uigH.Rotation = 90
    uigH.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
    }
    
    local cursorH = Instance.new("Frame", hueBar)
    cursorH.Size = UDim2.new(1, 2, 0, 2)
    cursorH.Position = UDim2.new(0, -1, 0, 0)
    cursorH.BackgroundColor3 = Color3.new(1,1,1)
    cursorH.ZIndex = 56
    Instance.new("UIStroke", cursorH).Color = Color3.new(0,0,0)

    local h, s, v = tbl[key]:ToHSV()
    svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    cursorSV.Position = UDim2.new(s, -2, 1 - v, -2)
    cursorH.Position = UDim2.new(0, -1, 1 - h, -1)

    local isOpen = false
    colorBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            frame.ZIndex = 100
            pStr.Transparency = 0
            Tween(pickerBox, {Size = UDim2.new(1, 0, 0, 120)})
            Tween(frame, {Size = UDim2.new(1, 0, 0, 155)}) -- Rozszerza rodzica żeby layout zadziałał
        else
            Tween(pickerBox, {Size = UDim2.new(1, 0, 0, 0)})
            Tween(frame, {Size = UDim2.new(1, 0, 0, 24)})
            task.delay(0.2, function() pStr.Transparency = 1 frame.ZIndex = 50 end)
        end
    end)
    
    local function apply()
        local c = Color3.fromHSV(h, s, v)
        tbl[key] = c
        colorBtn.BackgroundColor3 = c
        svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        if key == "ui_accent" then UpdateAccents() end
        UpdatePreviewEvent:Fire()
    end
    
    local draggingSV, draggingH = false, false
    
    svMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true end end)
    hueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingH = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = false draggingH = false end end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if draggingSV then
                local mx = math.clamp(input.Position.X - svMap.AbsolutePosition.X, 0, svMap.AbsoluteSize.X)
                local my = math.clamp(input.Position.Y - svMap.AbsolutePosition.Y, 0, svMap.AbsoluteSize.Y)
                s = mx / svMap.AbsoluteSize.X
                v = 1 - (my / svMap.AbsoluteSize.Y)
                cursorSV.Position = UDim2.new(0, mx - 2, 0, my - 2)
                apply()
            end
            if draggingH then
                local my = math.clamp(input.Position.Y - hueBar.AbsolutePosition.Y, 0, hueBar.AbsoluteSize.Y)
                h = 1 - (my / hueBar.AbsoluteSize.Y)
                cursorH.Position = UDim2.new(0, -1, 0, my - 1)
                apply()
            end
        end
    end)
end

local function CreateKeybind(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = GetNextLayoutOrder()
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local function formatKey(v)
        if not v then return "NONE" end
        if v == Enum.UserInputType.MouseButton1 then return "MB1" end
        if v == Enum.UserInputType.MouseButton2 then return "MB2" end
        return v.Name
    end

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 50, 0, 18)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.BackgroundColor3 = Theme.ItemBg
    btn.Text = formatKey(tbl[key])
    btn.TextColor3 = Theme.SubText
    btn.Font = Theme.FontCode
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local str = Instance.new("UIStroke", btn)
    str.Color = Theme.Border
    
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ItemHover}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ItemBg}) end)

    local listening = false
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
        str.Color = config.colors.ui_accent
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        local valid, bindVal = false, nil
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            bindVal = input.KeyCode; valid = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            bindVal = input.UserInputType; valid = true
        end
        if valid then
            if bindVal == Enum.KeyCode.Escape then tbl[key] = nil else tbl[key] = bindVal end
            btn.Text = formatKey(tbl[key])
            listening = false
            str.Color = Theme.Border
        end
    end)
end

local function CreateButton(parent, text, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = color or Theme.ItemBg
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Theme.FontBold
    btn.TextSize = 12
    btn.LayoutOrder = GetNextLayoutOrder()
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", btn).Color = Theme.Border
    
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.2}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0}) end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn, {BackgroundTransparency = 0.5}, 0.1)
        task.wait(0.1)
        Tween(btn, {BackgroundTransparency = 0}, 0.1)
        if callback then callback() end
    end)
    return btn
end

-- ================== -- NOWY 2D PREVIEW ESP (IDEALNE PROPORCJE) -- ==================
local function Build2DPreview(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 260)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", frame).Color = Theme.Border
    frame.ClipsDescendants = true
    frame.LayoutOrder = GetNextLayoutOrder()

    local grid = Instance.new("ImageLabel", frame)
    grid.Size = UDim2.new(1, 0, 1, 0)
    grid.BackgroundTransparency = 1
    grid.Image = "rbxassetid://4508731118"
    grid.ImageTransparency = 0.8
    grid.TileSize = UDim2.new(0, 40, 0, 40)

    local Center = Vector2.new(140, 130)

    local dummy = Instance.new("Frame", frame)
    dummy.BackgroundTransparency = 1
    dummy.Size = UDim2.new(1,0,1,0)
    
    local dCol = Color3.fromRGB(65, 70, 80)
    -- Proporcje R6
    local head = Instance.new("Frame", dummy)
    head.Size = UDim2.new(0, 24, 0, 24)
    head.Position = UDim2.new(0, Center.X, 0, Center.Y - 38)
    head.AnchorPoint = Vector2.new(0.5, 0.5)
    head.BackgroundColor3 = dCol
    Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)
    
    local torso = Instance.new("Frame", dummy)
    torso.Size = UDim2.new(0, 48, 0, 48)
    torso.Position = UDim2.new(0, Center.X, 0, Center.Y)
    torso.AnchorPoint = Vector2.new(0.5, 0.5)
    torso.BackgroundColor3 = dCol
    
    local lArm = Instance.new("Frame", dummy)
    lArm.Size = UDim2.new(0, 24, 0, 48)
    lArm.Position = UDim2.new(0, Center.X - 38, 0, Center.Y)
    lArm.AnchorPoint = Vector2.new(0.5, 0.5)
    lArm.BackgroundColor3 = dCol
    
    local rArm = Instance.new("Frame", dummy)
    rArm.Size = UDim2.new(0, 24, 0, 48)
    rArm.Position = UDim2.new(0, Center.X + 38, 0, Center.Y)
    rArm.AnchorPoint = Vector2.new(0.5, 0.5)
    rArm.BackgroundColor3 = dCol
    
    local lLeg = Instance.new("Frame", dummy)
    lLeg.Size = UDim2.new(0, 24, 0, 48)
    lLeg.Position = UDim2.new(0, Center.X - 12, 0, Center.Y + 50)
    lLeg.AnchorPoint = Vector2.new(0.5, 0.5)
    lLeg.BackgroundColor3 = dCol
    
    local rLeg = Instance.new("Frame", dummy)
    rLeg.Size = UDim2.new(0, 24, 0, 48)
    rLeg.Position = UDim2.new(0, Center.X + 12, 0, Center.Y + 50)
    rLeg.AnchorPoint = Vector2.new(0.5, 0.5)
    rLeg.BackgroundColor3 = dCol

    local esp = Instance.new("Frame", frame)
    esp.Size = UDim2.new(1,0,1,0)
    esp.BackgroundTransparency = 1

    local chams = Instance.new("Frame", esp)
    chams.Size = UDim2.new(0, 104, 0, 130)
    chams.Position = UDim2.new(0, Center.X, 0, Center.Y + 6)
    chams.AnchorPoint = Vector2.new(0.5, 0.5)
    chams.BackgroundColor3 = config.colors.chams_fill
    chams.BackgroundTransparency = 0.5
    Instance.new("UICorner", chams).CornerRadius = UDim.new(0, 6)

    local box = Instance.new("Frame", esp)
    box.Size = UDim2.new(0, 114, 0, 140)
    box.Position = UDim2.new(0, Center.X, 0, Center.Y + 6)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    local boxStr = Instance.new("UIStroke", box)
    boxStr.Thickness = 1

    local hpBg = Instance.new("Frame", box)
    hpBg.Size = UDim2.new(0, 3, 1, 0)
    hpBg.Position = UDim2.new(0, -6, 0, 0)
    hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hpBg.BorderSizePixel = 0
    local hpFill = Instance.new("Frame", hpBg)
    hpFill.Size = UDim2.new(1, 0, 0.8, 0)
    hpFill.Position = UDim2.new(0, 0, 0.2, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpFill.BorderSizePixel = 0

    local name = Instance.new("TextLabel", box)
    name.Size = UDim2.new(1, 0, 0, 15)
    name.Position = UDim2.new(0, 0, 0, -16)
    name.BackgroundTransparency = 1
    name.Text = "Enemy"
    name.TextColor3 = Color3.new(1,1,1)
    name.Font = Theme.FontBold
    name.TextSize = 11

    local wep = Instance.new("TextLabel", box)
    wep.Size = UDim2.new(1, 0, 0, 15)
    wep.Position = UDim2.new(0, 0, 1, 2)
    wep.BackgroundTransparency = 1
    wep.Text = "Weapon"
    wep.TextColor3 = Theme.SubText
    wep.Font = Theme.FontCode
    wep.TextSize = 10

    local tracer = Instance.new("Frame", esp)
    tracer.Size = UDim2.new(0, 1, 0, 100)
    tracer.Position = UDim2.new(0, Center.X, 0, 260)
    tracer.AnchorPoint = Vector2.new(0.5, 1)
    tracer.BorderSizePixel = 0

    local headDot = Instance.new("Frame", esp)
    headDot.Size = UDim2.new(0, 6, 0, 6)
    headDot.Position = head.Position
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)

    UpdatePreviewEvent.Event:Connect(function()
        box.Visible = config.toggles.boxes
        hpBg.Visible = config.toggles.healthbars
        name.Visible = config.toggles.names
        wep.Visible = config.toggles.weapons
        tracer.Visible = config.toggles.tracers
        headDot.Visible = config.toggles.head_dots
        chams.Visible = config.toggles.chams
        
        boxStr.Color = config.colors.enemy_esp
        tracer.BackgroundColor3 = config.colors.enemy_esp
        headDot.BackgroundColor3 = config.colors.enemy_esp
        chams.BackgroundColor3 = config.colors.chams_fill
    end)
    
    return frame
end

-- ================== -- MENU TABS SETUP -- ==================
CreateCategory("Combat")
local colsAim = CreateTab("Legitbot", true)
CreateCategory("Visuals")
local colsVis = CreateTab("ESP Setup", false)
local colsWorld = CreateTab("World", false)
CreateCategory("Players")
local colsPlayers = CreateTab("Player List", false)
CreateCategory("Miscellaneous")
local colsMisc = CreateTab("Movement", false)
local colsSet = CreateTab("Settings", false)

-- ZAKŁADKA AIMBOT
local aSec1 = CreateSection(colsAim.Left, "Main")
CreateToggle(aSec1, "Enable Aimbot", config.toggles, "aim_enabled")
CreateKeybind(aSec1, "Hotkey", config.keybinds, "aimbot")
CreateToggle(aSec1, "Draw FOV", config.toggles, "aim_showFov")
CreateToggle(aSec1, "Wall Check", config.toggles, "aim_wallCheck")
CreateToggle(aSec1, "Prediction", config.toggles, "aim_predict")

local aSec2 = CreateSection(colsAim.Right, "Configuration")
CreateDropdown(aSec2, "Hitbox", config.selectors, "aim_part", {"Head", "Torso", "Root"})
CreateDropdown(aSec2, "Method", config.selectors, "aim_method", {"Mouse Movement", "Camera Snap"})
CreateSlider(aSec2, "FOV Radius", config.sliders, "aim_fov", 10, 500)
CreateSlider(aSec2, "Smoothness", config.sliders, "aim_smooth", 1, 20)
CreateSlider(aSec2, "Aim Offset X", config.sliders, "aim_offsetX", -100, 100)
CreateSlider(aSec2, "Aim Offset Y", config.sliders, "aim_offsetY", -100, 100)

-- ZAKŁADKA VISUALS (ESP)
local vSecPreview = CreateSection(colsVis.Left, "2D ESP Preview")
Build2DPreview(vSecPreview)

local vSecToggle = CreateSection(colsVis.Right, "Elements")
CreateToggle(vSecToggle, "Master Switch", config, "esp_enabled")
CreateSlider(vSecToggle, "Max Render Distance", config.sliders, "esp_distance", 50, 5000)
CreateToggle(vSecToggle, "Bounding Box", config.toggles, "boxes")
CreateToggle(vSecToggle, "Health Bar", config.toggles, "healthbars")
CreateToggle(vSecToggle, "Name", config.toggles, "names")
CreateToggle(vSecToggle, "Weapon", config.toggles, "weapons")
CreateToggle(vSecToggle, "Snaplines", config.toggles, "tracers")
CreateDropdown(vSecToggle, "Snapline Origin", config.selectors, "tracer_origin", {"Bottom", "Center", "Mouse"})
CreateToggle(vSecToggle, "Head Dot", config.toggles, "head_dots")
CreateToggle(vSecToggle, "Highlight Chams", config.toggles, "chams")

local vSecColors = CreateSection(colsVis.Right, "Colors")
CreateColorPicker(vSecColors, "Enemy ESP Box", config.colors, "enemy_esp")
CreateColorPicker(vSecColors, "Chams Fill", config.colors, "chams_fill")

-- ZAKŁADKA WORLD 
local wSec1 = CreateSection(colsWorld.Left, "Lighting & Atmosphere")
CreateToggle(wSec1, "Override Environment", config.toggles, "world_enabled")
CreateSlider(wSec1, "Brightness (Scale)", config.sliders, "brightness", 0, 100)
CreateSlider(wSec1, "Exposure (Scale)", config.sliders, "exposure", -50, 50)
CreateToggle(wSec1, "Global Shadows", config.toggles, "shadows_enabled")
CreateColorPicker(wSec1, "Ambient Color", config.colors, "ambient_color")
CreateColorPicker(wSec1, "Outdoor Ambient", config.colors, "outdoor_ambient")

local wSec2 = CreateSection(colsWorld.Right, "Fog Settings")
CreateToggle(wSec2, "Override Fog", config.toggles, "fog_enabled")
CreateColorPicker(wSec2, "Fog Color", config.colors, "fog_color")
CreateSlider(wSec2, "Fog Start", config.sliders, "fog_start", 0, 1000)
CreateSlider(wSec2, "Fog End", config.sliders, "fog_end", 0, 10000)

local wSec3 = CreateSection(colsWorld.Right, "Time & Camera")
CreateToggle(wSec3, "Custom Time", config.toggles, "time_changer")
CreateSlider(wSec3, "Time of Day", config.sliders, "custom_time", 0, 24)
CreateToggle(wSec3, "Custom FOV", config.toggles, "fov_changer")
CreateSlider(wSec3, "Camera FOV", config.sliders, "custom_fov", 60, 120)
CreateToggle(wSec3, "Force Third Person", config.toggles, "third_person")

-- ZAKŁADKA PLAYERS (Z WYSZUKIWARKĄ)
local pSec1 = CreateSection(colsPlayers.Left, "Select Player")

local SearchBarContainer = Instance.new("Frame", pSec1)
SearchBarContainer.Size = UDim2.new(1, 0, 0, 26)
SearchBarContainer.BackgroundColor3 = Theme.ItemBg
SearchBarContainer.LayoutOrder = GetNextLayoutOrder()
Instance.new("UICorner", SearchBarContainer).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", SearchBarContainer).Color = Theme.Border

local SearchBar = Instance.new("TextBox", SearchBarContainer)
SearchBar.Size = UDim2.new(1, -10, 1, 0)
SearchBar.Position = UDim2.new(0, 5, 0, 0)
SearchBar.BackgroundTransparency = 1
SearchBar.Text = ""
SearchBar.PlaceholderText = "Search Player..."
SearchBar.TextColor3 = Theme.Text
SearchBar.PlaceholderColor3 = Theme.SubText
SearchBar.Font = Theme.Font
SearchBar.TextSize = 11
SearchBar.TextXAlignment = Enum.TextXAlignment.Left

local PlayerListContainer = Instance.new("Frame", pSec1)
PlayerListContainer.Size = UDim2.new(1, 0, 0, 300)
PlayerListContainer.BackgroundColor3 = Theme.ItemBg
PlayerListContainer.LayoutOrder = GetNextLayoutOrder()
Instance.new("UICorner", PlayerListContainer).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", PlayerListContainer).Color = Theme.Border

local PlayerScroll = Instance.new("ScrollingFrame", PlayerListContainer)
PlayerScroll.Size = UDim2.new(1, -10, 1, -10)
PlayerScroll.Position = UDim2.new(0, 5, 0, 5)
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.ScrollBarThickness = 2
PlayerScroll.ScrollBarImageColor3 = Theme.Border
local PLayout = Instance.new("UIListLayout", PlayerScroll)
PLayout.Padding = UDim.new(0, 4)
PLayout.SortOrder = Enum.SortOrder.Name

local SelectedLabel = nil
local WhitelistBtn = nil

local function FilterPlayers()
    local query = string.lower(SearchBar.Text)
    local count = 0
    for _, child in ipairs(PlayerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            if query == "" or string.find(string.lower(child.Name), query) then
                child.Visible = true
                count = count + 1
            else
                child.Visible = false
            end
        end
    end
    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28)
end
SearchBar:GetPropertyChangedSignal("Text"):Connect(FilterPlayers)

local function RefreshPlayerList()
    for _, child in ipairs(PlayerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local btn = Instance.new("TextButton", PlayerScroll)
        btn.Name = p.Name
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = config.selectedPlayer == p and config.colors.ui_accent or Theme.CardBg
        btn.Text = "  " .. p.Name .. (config.whitelist[p.Name] and " [WHITELISTED]" or "")
        btn.TextColor3 = config.selectedPlayer == p and Color3.new(1,1,1) or Theme.Text
        btn.Font = Theme.Font
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        if config.selectedPlayer == p then ApplyAccent(btn, "BackgroundColor3") end

        btn.MouseButton1Click:Connect(function()
            config.selectedPlayer = p
            RefreshPlayerList()
            if SelectedLabel then SelectedLabel.Text = "Target: " .. p.Name end
            if WhitelistBtn then
                WhitelistBtn.Text = config.whitelist[p.Name] and "Remove from Whitelist" or "Add to Whitelist"
            end
        end)
    end
    FilterPlayers()
end
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(p) if config.selectedPlayer == p then config.selectedPlayer = nil end RefreshPlayerList() end)

local pSec2 = CreateSection(colsPlayers.Right, "Actions")
SelectedLabel = Instance.new("TextLabel", pSec2)
SelectedLabel.Size = UDim2.new(1, 0, 0, 20)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Target: None"
SelectedLabel.TextColor3 = Theme.SubText
SelectedLabel.Font = Theme.FontCode
SelectedLabel.TextSize = 11
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.LayoutOrder = GetNextLayoutOrder()

WhitelistBtn = CreateButton(pSec2, "Toggle Whitelist (Aimbot Ignore)", Theme.ItemBg, function()
    if config.selectedPlayer then
        if config.whitelist[config.selectedPlayer.Name] then
            config.whitelist[config.selectedPlayer.Name] = nil
        else
            config.whitelist[config.selectedPlayer.Name] = true
        end
        RefreshPlayerList()
        WhitelistBtn.Text = config.whitelist[config.selectedPlayer.Name] and "Remove from Whitelist" or "Add to Whitelist"
    end
end)

CreateButton(pSec2, "Teleport Behind Player", Theme.ItemBg, function()
    if config.selectedPlayer and config.selectedPlayer.Character and config.selectedPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetCFrame = config.selectedPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 4)
    end
end)
RefreshPlayerList()

-- ZAKŁADKA MOVEMENT
local mSec2 = CreateSection(colsMisc.Left, "Movement")
CreateToggle(mSec2, "Bunny Hop", config.toggles, "bhop")
CreateDropdown(mSec2, "Fly Method", config.selectors, "fly_method", {"Platform", "CFrame", "Velocity"})
CreateToggle(mSec2, "Enable Fly", config.toggles, "fly")
CreateKeybind(mSec2, "Fly Bind", config.keybinds, "fly")
CreateSlider(mSec2, "Fly Speed", config.sliders, "fly_speed", 10, 150)
CreateToggle(mSec2, "Noclip", config.toggles, "noclip")

-- ZAKŁADKA SETTINGS & UNLOAD
local sSec1 = CreateSection(colsSet.Left, "Interface")
CreateKeybind(sSec1, "Menu Bind", config.keybinds, "menu")
CreateToggle(sSec1, "Show Watermark", config.toggles, "watermark")
CreateColorPicker(sSec1, "Menu Accent Color", config.colors, "ui_accent")

local sSec2 = CreateSection(colsSet.Right, "System")
CreateButton(sSec2, "UNLOAD ASAPWARE", Theme.Danger, function()
    if _G.AsapwareUnload then _G.AsapwareUnload() end
end)

UpdatePreviewEvent:Fire()
UpdateAccents()

-- MENU OPEN/CLOSE ANIMATION
local UIScale = Instance.new("UIScale", DragContainer)
UIScale.Scale = 0
local menuOpen = true
DragContainer.Visible = true
Tween(UIScale, {Scale = 1}, 0.3)

local function ToggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        DragContainer.Visible = true
        Tween(UIScale, {Scale = 1}, 0.3)
    else
        local tw = TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 0})
        tw:Play()
        tw.Completed:Connect(function() if not menuOpen then DragContainer.Visible = false end end)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == config.keybinds.menu then ToggleMenu() end
    if config.keybinds.fly and (input.KeyCode == config.keybinds.fly or input.UserInputType == config.keybinds.fly) then
        config.toggles.fly = not config.toggles.fly
    end
end)

-- ==========================================
-- 7. LOGIKA ESP, CROSSHAIR, NOCLIP & DRAWING
-- ==========================================
local DrawingSupported = pcall(function() Drawing.new("Line"):Remove() end)
local ESP_Data = {}
local AllDrawings = {}
local HighlightInstances = {}
local ChamsSupported = pcall(function() local test = Instance.new("Highlight") test:Destroy() end)

local function CreateDraw(Type, Properties)
    if not DrawingSupported then return {Visible = false, Remove = function() end} end
    local obj = Drawing.new(Type)
    for k, v in pairs(Properties) do pcall(function() obj[k] = v end) end
    table.insert(AllDrawings, obj)
    return obj
end

local FOV_Circle = CreateDraw("Circle", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Filled = false})
local CrossTop = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossBot = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossLeft = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossRight = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
table.insert(UIThemeObjects, {Obj = CrossTop, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossBot, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossLeft, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossRight, Prop = "Color"})

local function SetupESP(player)
    if ESP_Data[player] then return end
    if ChamsSupported then
        local chams = Instance.new("Highlight")
        chams.Name = player.Name .. "_Chams"
        chams.Enabled = false
        pcall(function() chams.Parent = TargetGui end)
        HighlightInstances[player] = chams
    end
    ESP_Data[player] = {
        BoxOutline = CreateDraw("Square", {Filled = false, Color = ESP_COLORS.Outline}),
        Box = CreateDraw("Square", {Filled = false}),
        HealthOutline = CreateDraw("Square", {Filled = true, Color = ESP_COLORS.Outline}),
        HealthBar = CreateDraw("Square", {Filled = true}),
        HealthText = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = Color3.fromRGB(255, 255, 255)}),
        Name = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255, 255, 255)}),
        Distance = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 11, Color = Theme.SubText}),
        Weapon = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 11, Color = Color3.fromRGB(180, 180, 220)}),
        Tracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.5}),
        HeadDot = CreateDraw("Circle", {Filled = true, Transparency = 1, Radius = 3}),
        ViewTracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.8}),
        OffscreenArrow = CreateDraw("Triangle", {Filled = true, Transparency = 0.8, Color = ESP_COLORS.Arrow}),
        SkeletonLines = {}
    }
end

local function RemoveESP(player) 
    if ESP_Data[player] then 
        for k, v in pairs(ESP_Data[player]) do
            if k == "SkeletonLines" then for _, l in ipairs(v) do pcall(function() l.Visible = false l:Remove() end) end
            else pcall(function() v.Visible = false v:Remove() end) end
        end
        ESP_Data[player] = nil 
    end 
    if HighlightInstances[player] then pcall(function() HighlightInstances[player]:Destroy() end) HighlightInstances[player] = nil end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
Players.PlayerAdded:Connect(SetupESP)
Players.PlayerRemoving:Connect(RemoveESP)

local NoclipConnection = RunService.Stepped:Connect(function()
    if config.toggles.noclip and LocalPlayer.Character and ScriptLoaded then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
end)

local function GetAimPart(char)
    local sel = config.selectors.aim_part
    if sel == 1 then return char:FindFirstChild("Head")
    elseif sel == 2 then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    else return char:FindFirstChild("HumanoidRootPart") end
end

local function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    GlobalRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(origin, (targetPart.Position - origin), GlobalRaycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- ==========================================
-- 8. GŁÓWNA PĘTLA (RENDERING & LOGIC)
-- ==========================================
RunService:BindToRenderStep("AsapwareMain", Enum.RenderPriority.Camera.Value + 1, function()
    if not ScriptLoaded then return end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    
    pcall(function()
        if config.toggles.time_changer then Lighting.ClockTime = config.sliders.custom_time else Lighting.ClockTime = origLighting.ClockTime end
        if config.toggles.fov_changer then Camera.FieldOfView = config.sliders.custom_fov end
        
        if config.toggles.world_enabled then
            Lighting.Brightness = config.sliders.brightness / 10
            Lighting.ExposureCompensation = config.sliders.exposure / 10
            Lighting.GlobalShadows = config.toggles.shadows_enabled
            Lighting.Ambient = config.colors.ambient_color
            Lighting.OutdoorAmbient = config.colors.outdoor_ambient
        else
            Lighting.Brightness = origLighting.Brightness
            Lighting.ExposureCompensation = origLighting.ExposureCompensation
            Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.Ambient = origLighting.Ambient
            Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        end
        
        if config.toggles.fog_enabled then
            Lighting.FogColor = config.colors.fog_color
            Lighting.FogStart = config.sliders.fog_start
            Lighting.FogEnd = config.sliders.fog_end
        else
            Lighting.FogColor = origLighting.FogColor
            Lighting.FogStart = origLighting.FogStart
            Lighting.FogEnd = origLighting.FogEnd
        end
    end)
    
    if config.toggles.third_person then
        LocalPlayer.CameraMaxZoomDistance = 12
        LocalPlayer.CameraMinZoomDistance = 12
    else
        LocalPlayer.CameraMaxZoomDistance = 400
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
    
    if config.toggles.bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not config.toggles.fly then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
    end
    
    if config.toggles.fly then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local moveDir = Vector3.zero
            local camLook = Camera.CFrame.LookVector
            local camRight = Camera.CFrame.RightVector
            local forward = Vector3.new(camLook.X, 0, camLook.Z).Unit
            local right = Vector3.new(camRight.X, 0, camRight.Z).Unit
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            
            local method = config.selectors.fly_method
            if method == 1 then
                if not flyPlatform then
                    flyPlatform = Instance.new("Part", Workspace)
                    flyPlatform.Name = "AntiAC_Platform_Fly"
                    flyPlatform.Size = Vector3.new(6, 1, 6)
                    flyPlatform.Transparency = 1
                    flyPlatform.Anchored = true
                end
                hrp.CFrame = hrp.CFrame + (moveDir * (config.sliders.fly_speed / 20))
                hrp.Velocity = Vector3.zero
                flyPlatform.CFrame = hrp.CFrame * CFrame.new(0, -3.2, 0)
            elseif method == 2 then
                if flyPlatform then flyPlatform:Destroy() flyPlatform = nil end
                hrp.Anchored = true
                hrp.CFrame = hrp.CFrame + (moveDir * (config.sliders.fly_speed / 20))
            elseif method == 3 then
                if flyPlatform then flyPlatform:Destroy() flyPlatform = nil end
                hrp.Anchored = false
                hrp.Velocity = moveDir * config.sliders.fly_speed
            end
        end
    else
        if flyPlatform then flyPlatform:Destroy() flyPlatform = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end

    pcall(function()
        FOV_Circle.Position = mouseLoc
        FOV_Circle.Radius = config.sliders.aim_fov
        FOV_Circle.Visible = config.toggles.aim_showFov and config.toggles.aim_enabled

        local cSize, cGap = 6, 4
        CrossTop.From, CrossTop.To = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap), Vector2.new(mouseLoc.X, mouseLoc.Y - cGap - cSize)
        CrossBot.From, CrossBot.To = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap), Vector2.new(mouseLoc.X, mouseLoc.Y + cGap + cSize)
        CrossLeft.From, CrossLeft.To = Vector2.new(mouseLoc.X - cGap, mouseLoc.Y), Vector2.new(mouseLoc.X - cGap - cSize, mouseLoc.Y)
        CrossRight.From, CrossRight.To = Vector2.new(mouseLoc.X + cGap, mouseLoc.Y), Vector2.new(mouseLoc.X + cGap + cSize, mouseLoc.Y)
        
        local showCross = config.toggles.aim_crosshair
        CrossTop.Visible = showCross CrossBot.Visible = showCross CrossLeft.Visible = showCross CrossRight.Visible = showCross
    end)

    local isAiming = false
    local aBind = config.keybinds.aimbot
    if aBind and typeof(aBind) == "EnumItem" then
        if aBind.EnumType == Enum.KeyCode then isAiming = UserInputService:IsKeyDown(aBind)
        elseif aBind.EnumType == Enum.UserInputType then isAiming = UserInputService:IsMouseButtonPressed(aBind) end
    end

    local closestTarget = nil
    local shortestDist = math.huge
    
    if config.toggles.aim_enabled and isAiming then
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if config.teamCheck and player.Team == LocalPlayer.Team then continue end
            if config.whitelist[player.Name] then continue end
            
            if player.Character then
                local hp = GetHealth(player)
                if hp > 0 then
                    local aimPart = GetAimPart(player.Character)
                    if aimPart and (Camera.CFrame.Position - aimPart.Position).Magnitude <= config.sliders.aim_distance then
                        local targetPos = aimPart.Position
                        if config.toggles.aim_predict and aimPart.AssemblyLinearVelocity then
                            targetPos = targetPos + (aimPart.AssemblyLinearVelocity * (config.sliders.aim_pred_amt / 100))
                        end
                        local pos, onScreen = Camera:WorldToScreenPoint(targetPos)
                        if onScreen then
                            local finalTargetX = pos.X + config.sliders.aim_offsetX
                            local finalTargetY = pos.Y + config.sliders.aim_offsetY
                            
                            local dist = (Vector2.new(finalTargetX, finalTargetY) - mouseLoc).Magnitude
                            if dist <= config.sliders.aim_fov and dist < shortestDist then
                                if not config.toggles.aim_wallCheck or IsVisible(aimPart) then
                                    shortestDist = dist
                                    closestTarget = targetPos
                                end
                            end
                        end
                    end
                end
            end
        end
        if closestTarget then
            local smooth = config.sliders.aim_smooth
            if config.selectors.aim_method == 1 and mousemoverel then
                local pos = Camera:WorldToScreenPoint(closestTarget)
                local finalX = pos.X + config.sliders.aim_offsetX
                local finalY = pos.Y + config.sliders.aim_offsetY
                mousemoverel((finalX - mouseLoc.X) / smooth, (finalY - mouseLoc.Y) / smooth)
            else 
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), 1 / smooth) 
            end
        end
    end

    local t_Thick = config.sliders.boxThickness
    for player, esp in pairs(ESP_Data) do
        local isValidTarget = false
        local onScreen = false
        local pos, root, head, dist, hp, maxHp, char

        if config.esp_enabled and player and player.Parent and player ~= LocalPlayer and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
            char = player.Character
            if char then
                hp, maxHp = GetHealth(player)
                if hp > 0 then
                    root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
                    head = char:FindFirstChild("Head")
                    if root and head then
                        isValidTarget = true
                        pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        dist = (Camera.CFrame.Position - root.Position).Magnitude
                    end
                end
            end
        end

        if isValidTarget then
            -- 1. CHAMSY (HIGHLIGHT)
            if HighlightInstances[player] then
                if config.toggles.chams and dist <= config.sliders.esp_distance then
                    pcall(function()
                        HighlightInstances[player].Adornee = char
                        HighlightInstances[player].FillColor = config.colors.chams_fill
                        HighlightInstances[player].OutlineColor = config.colors.chams_outline
                        HighlightInstances[player].Enabled = true
                    end)
                else
                    pcall(function() HighlightInstances[player].Enabled = false end)
                end
            end

            -- 2. STRZAŁKI POZA EKRANEM (OFFSCREEN ARROWS)
            if not onScreen and config.toggles.offscreen_arrows and dist <= config.sliders.esp_distance then
                local targetVec = (root.Position - Camera.CFrame.Position).Unit
                local camYRot = math.atan2(Camera.CFrame.LookVector.X, Camera.CFrame.LookVector.Z)
                local targYRot = math.atan2(targetVec.X, targetVec.Z)
                local finalAngle = camYRot - targYRot
                
                local radius = config.sliders.arrow_radius
                local size = config.sliders.arrow_size
                
                local cX = screenCenter.X + math.sin(finalAngle) * radius
                local cY = screenCenter.Y - math.cos(finalAngle) * radius
                
                pcall(function()
                    esp.OffscreenArrow.PointA = Vector2.new(cX + math.sin(finalAngle) * size, cY - math.cos(finalAngle) * size)
                    esp.OffscreenArrow.PointB = Vector2.new(cX + math.sin(finalAngle + 2.5) * (size*0.8), cY - math.cos(finalAngle + 2.5) * (size*0.8))
                    esp.OffscreenArrow.PointC = Vector2.new(cX + math.sin(finalAngle - 2.5) * (size*0.8), cY - math.cos(finalAngle - 2.5) * (size*0.8))
                    esp.OffscreenArrow.Visible = true
                end)
            else
                pcall(function() esp.OffscreenArrow.Visible = false end)
            end

            -- 3. GŁÓWNE ESP 2D (NA EKRANIE)
            if onScreen and pos.Z > 0 and dist <= config.sliders.esp_distance then
                local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
                local botPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                local headPos = Camera:WorldToViewportPoint(head.Position)
                
                local boxH = botPos.Y - topPos.Y
                local boxW = boxH / 1.8
                local boxX = pos.X - (boxW / 2)
                local boxY = topPos.Y

                pcall(function()
                    if config.toggles.boxes then
                        esp.BoxOutline.Thickness = t_Thick + 2
                        esp.BoxOutline.Size, esp.BoxOutline.Position = Vector2.new(boxW, boxH), Vector2.new(boxX, boxY)
                        esp.Box.Thickness = t_Thick
                        esp.Box.Size, esp.Box.Position = Vector2.new(boxW, boxH), Vector2.new(boxX, boxY)
                        esp.Box.Color = config.whitelist[player.Name] and Color3.fromRGB(50, 255, 50) or config.colors.enemy_esp
                        esp.BoxOutline.Visible, esp.Box.Visible = true, true
                    else esp.BoxOutline.Visible, esp.Box.Visible = false, false end

                    if config.toggles.head_dots then
                        esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                        esp.HeadDot.Color = config.whitelist[player.Name] and Color3.fromRGB(50, 255, 50) or config.colors.enemy_esp
                        esp.HeadDot.Visible = true
                    else esp.HeadDot.Visible = false end

                    if config.toggles.healthbars then
                        local hpPct = math.clamp(hp / maxHp, 0, 1)
                        local barH = boxH * hpPct
                        esp.HealthOutline.Size, esp.HealthOutline.Position = Vector2.new(4, boxH + 2), Vector2.new(boxX - 7, boxY - 1)
                        esp.HealthBar.Size, esp.HealthBar.Position = Vector2.new(2, barH), Vector2.new(boxX - 6, boxY + (boxH - barH))
                        esp.HealthBar.Color = Color3.fromRGB(255 - (hpPct * 255), hpPct * 255, 30)
                        esp.HealthOutline.Visible, esp.HealthBar.Visible = true, true
                        
                        if config.toggles.healthtext and hp < maxHp then
                            esp.HealthText.Text = tostring(math.floor(hp))
                            esp.HealthText.Position = Vector2.new(boxX - 18, boxY + (boxH - barH) - 6)
                            esp.HealthText.Visible = true
                        else esp.HealthText.Visible = false end
                    else esp.HealthOutline.Visible, esp.HealthBar.Visible, esp.HealthText.Visible = false, false, false end

                    if config.toggles.names then
                        esp.Name.Text, esp.Name.Position = player.Name .. (config.whitelist[player.Name] and " [W]" or ""), Vector2.new(pos.X, boxY - 18)
                        esp.Name.Color = config.whitelist[player.Name] and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
                        esp.Name.Visible = true
                    else esp.Name.Visible = false end
                    
                    local bottomY = boxY + boxH + 3
                    if config.toggles.distances then
                        esp.Distance.Text, esp.Distance.Position = "[" .. math.floor(dist) .. "m]", Vector2.new(pos.X, bottomY)
                        esp.Distance.Visible = true
                        bottomY = bottomY + 14
                    else esp.Distance.Visible = false end
                    
                    if config.toggles.weapons then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            esp.Weapon.Text, esp.Weapon.Position = tool.Name, Vector2.new(pos.X, bottomY)
                            esp.Weapon.Visible = true
                        else
                            esp.Weapon.Visible = false
                        end
                    else esp.Weapon.Visible = false end
                    
                    if config.toggles.tracers then
                        esp.Tracer.From = screenBottom
                        if config.selectors.tracer_origin == 2 then esp.Tracer.From = screenCenter elseif config.selectors.tracer_origin == 3 then esp.Tracer.From = mouseLoc end
                        esp.Tracer.To = Vector2.new(pos.X, botPos.Y)
                        esp.Tracer.Color = config.whitelist[player.Name] and Color3.fromRGB(50, 255, 50) or config.colors.enemy_esp
                        esp.Tracer.Visible = true
                    else esp.Tracer.Visible = false end
                end)
            else
                -- Gracz żyje ale jest za plecami lub za daleko -> Ukrywamy tylko ESP 2D
                pcall(function()
                    esp.BoxOutline.Visible = false esp.Box.Visible = false esp.HealthOutline.Visible = false
                    esp.HealthBar.Visible = false esp.Name.Visible = false esp.Distance.Visible = false 
                    esp.Tracer.Visible = false esp.HeadDot.Visible = false esp.HealthText.Visible = false
                    esp.Weapon.Visible = false
                end)
            end
        else
            -- 4. GRACZ UMARŁ, WYSZEDŁ LUB ESP JEST WYŁĄCZONE
            pcall(function()
                esp.BoxOutline.Visible = false
                esp.Box.Visible = false
                esp.HealthOutline.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthText.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
                esp.Tracer.Visible = false
                esp.HeadDot.Visible = false
                esp.ViewTracer.Visible = false
                esp.OffscreenArrow.Visible = false
                if esp.SkeletonLines then
                    for _, l in ipairs(esp.SkeletonLines) do l.Visible = false end
                end
            end)
            if HighlightInstances[player] then 
                pcall(function() HighlightInstances[player].Enabled = false end) 
            end
        end
    end
end)

-- ==========================================
-- 9. SYSTEM WYŁĄCZANIA (UNLOAD)
-- ==========================================
_G.AsapwareUnload = function()
    ScriptLoaded = false
    RunService:UnbindFromRenderStep("AsapwareMain")
    if NoclipConnection then NoclipConnection:Disconnect() end
    if ScreenGui then ScreenGui:Destroy() end
    if flyPlatform then flyPlatform:Destroy() end
    
    pcall(function()
        Lighting.ClockTime = origLighting.ClockTime
        Lighting.Brightness = origLighting.Brightness
        Lighting.ExposureCompensation = origLighting.ExposureCompensation
        Lighting.GlobalShadows = origLighting.GlobalShadows
        Lighting.Ambient = origLighting.Ambient
        Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        Lighting.FogColor = origLighting.FogColor
        Lighting.FogStart = origLighting.FogStart
        Lighting.FogEnd = origLighting.FogEnd
    end)
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        LocalPlayer.Character.HumanoidRootPart.Anchored = false 
    end
    
    for _, esp in pairs(ESP_Data) do
        for k, v in pairs(esp) do
            if k == "SkeletonLines" then for _, l in ipairs(v) do pcall(function() l:Remove() end) end
            else pcall(function() v:Remove() end) end
        end
    end
    for _, hl in pairs(HighlightInstances) do pcall(function() hl:Destroy() end) end
    table.clear(ESP_Data)
    table.clear(HighlightInstances)
    
    for _, obj in ipairs(AllDrawings) do if obj.Remove then pcall(function() obj:Remove() end) end end
    table.clear(AllDrawings)
    _G.AsapwareUnload = nil
    print("ASAPWARE: Successfully Unloaded.")
end

print("ASAPWARE V20 THE PINNACLE LOADED.")
