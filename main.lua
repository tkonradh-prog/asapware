--- ASAPWARE V22 - ELITE MONOLITH EDITION
--- Professional Dark Architecture, Zero-Garbage Render Pipeline & Stealth Anti-Detection Engine

-- ==========================================
-- 1. BEZPIECZNE ŚRODOWISKO & SERWISY (ANTI-DETECTION)
-- ==========================================
local function safeService(name)
    local s = game:GetService(name)
    if cloneref then
        local ok, ref = pcall(cloneref, s)
        if ok and ref then return ref end
    end
    return s
end

local Players = safeService("Players")
local RunService = safeService("RunService")
local Workspace = safeService("Workspace")
local UserInputService = safeService("UserInputService")
local Lighting = safeService("Lighting")
local CoreGui = safeService("CoreGui")
local TweenService = safeService("TweenService")
local Stats = safeService("Stats")
local HttpService = safeService("HttpService")
local SoundService = safeService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Funkcja generowania losowych nazw instancji
local function generateRandomName(length)
    length = length or 14
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local r = math.random(1, #chars)
        result[i] = string.sub(chars, r, r)
    end
    return table.concat(result)
end

-- Bezpieczny kontener GUI (priorytet gethui > syn.protect_gui > CoreGui)
local function GetSafeParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        elseif syn and syn.protect_gui then
            return CoreGui
        else
            return CoreGui:FindFirstChild("RobloxGui") or CoreGui
        end
    end)
    return (success and result) or CoreGui
end

-- Bufor oryginalnego oświetlenia
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
-- 2. KONFIGURACJA ARCHITEKTURY
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
        aim_wallCheck = false, aim_predict = true, aim_autoSnapClose = false,
        triggerbot = false, trigger_wallCheck = true,
        rainbow_ui = false, bhop = false, fly = false, noclip = false, godmode = false, watermark = true,
        walkspeed_enabled = false, jumppower_enabled = false, inf_jump = false, spinbot = false,
        keybinds_hud = true,
        ui_sounds = true,
        zoom_enabled = false,
        rainbow_crosshair = false,
        crosshair_dot = true,
        crosshair_outline = true,
        esp_hp_dynamic = true,
        esp_box_fill = false,
        esp_box_outline = true,
        esp_flags = true,
        esp_head_outline = true,
        aim_lock_indicator = true,
        aim_fov_shadow = true,
        aim_fov_ticks = true,
        aim_target_info = true
    },
    sliders = {
        aim_distance = 1500, aim_fov = 100, aim_smooth = 1, aim_offsetX = 0, aim_offsetY = 59, aim_pred_amt = 10,
        aim_snapDistance = 15,
        trigger_delay = 0,
        esp_distance = 1500, boxThickness = 1, arrow_radius = 200, arrow_size = 15, esp_fill_alpha = 15,
        custom_time = 12, custom_fov = 90, brightness = 20, exposure = 0, fog_start = 0, fog_end = 1000,
        fly_speed = 50, tp_speed = 150,
        walkspeed_val = 100, jumppower_val = 100, spinbot_speed = 20,
        zoom_fov = 30,
        crosshair_size = 6,
        crosshair_gap = 4,
        crosshair_thick = 2
    },
    colors = {
        enemy_esp = Color3.fromRGB(230, 46, 67),
        chams_fill = Color3.fromRGB(230, 46, 67),
        chams_outline = Color3.fromRGB(255, 255, 255),
        ui_accent = Color3.fromRGB(230, 46, 67), -- Industrial Crimson Default
        ambient_color = Color3.fromRGB(100, 100, 100),
        outdoor_ambient = Color3.fromRGB(120, 120, 120),
        fog_color = Color3.fromRGB(200, 200, 200)
    },
    selectors = { 
        aim_part = 1, aim_method = 1, tracer_origin = 1, fly_method = 1,
        crosshair_style = 1,
        box_style = 1,
        esp_dist_metric = 1
    },
    keybinds = { 
        aimbot = Enum.UserInputType.MouseButton2, 
        fly = nil, 
        menu = Enum.KeyCode.Insert,
        zoom = Enum.KeyCode.C
    },
    selectedPlayer = nil
}

local THEME_PRESETS = {
    {Name = "Obsidian Crimson", Color = Color3.fromRGB(230, 46, 67)},
    {Name = "Cyber Electric", Color = Color3.fromRGB(0, 180, 216)},
    {Name = "Neon Purple", Color = Color3.fromRGB(138, 43, 226)},
    {Name = "Emerald Matrix", Color = Color3.fromRGB(16, 185, 129)},
    {Name = "Amber Fire", Color = Color3.fromRGB(245, 158, 11)},
    {Name = "Monochrome Steel", Color = Color3.fromRGB(207, 211, 220)}
}

local ESP_COLORS = { 
    Outline = Color3.fromRGB(8, 9, 13), 
    Skeleton = Color3.fromRGB(240, 242, 255), 
    Arrow = Color3.fromRGB(230, 46, 67) 
}

local flyPlatform = nil
local flyPlatformName = generateRandomName(16)
local ScriptLoaded = true

-- Zoptymalizowany RaycastParams (zbuforowany filtr)
local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true
local RaycastFilterCache = {nil, Camera}

local function UpdateRaycastFilter()
    if LocalPlayer.Character then
        RaycastFilterCache[1] = LocalPlayer.Character
        GlobalRaycastParams.FilterDescendantsInstances = RaycastFilterCache
    end
end
LocalPlayer.CharacterAdded:Connect(UpdateRaycastFilter)
UpdateRaycastFilter()

-- Statyczne tabele szkieletów (Zero-Garbage)
local SKELETON_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local SKELETON_R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function GetHealth(player)
    if not player then return 0, 100 end
    local char = player.Character
    if not char then return 0, 100 end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hp, maxHp = 0, 100
    
    if hum then 
        hp, maxHp = hum.Health, hum.MaxHealth 
    end
    
    local aHp = char:GetAttribute("Health")
    if aHp then hp = aHp end
    local aMaxHp = char:GetAttribute("MaxHealth")
    if aMaxHp then maxHp = aMaxHp end
    
    local hpVal = char:FindFirstChild("Health")
    if hpVal and hpVal:IsA("ValueBase") and typeof(hpVal.Value) == "number" then 
        hp = hpVal.Value 
    end
    
    local maxHpVal = char:FindFirstChild("MaxHealth")
    if maxHpVal and maxHpVal:IsA("ValueBase") and typeof(maxHpVal.Value) == "number" then 
        maxHp = maxHpVal.Value 
    end

    return hp, maxHp
end

-- ==========================================
-- 3. DESIGN SYSTEM - ELITE MONOLITH (PROFESSIONAL INDUSTRIAL)
-- ==========================================
local Theme = {
    MainBg = Color3.fromRGB(13, 15, 20),
    SidebarBg = Color3.fromRGB(10, 12, 16),
    HeaderBg = Color3.fromRGB(16, 18, 24),
    GroupboxBg = Color3.fromRGB(17, 20, 27),
    GroupboxHeader = Color3.fromRGB(21, 24, 33),
    ItemBg = Color3.fromRGB(24, 27, 37),
    ItemHover = Color3.fromRGB(32, 36, 50),
    Border = Color3.fromRGB(34, 39, 53),
    BorderLight = Color3.fromRGB(48, 54, 74),
    Text = Color3.fromRGB(240, 243, 252),
    SubText = Color3.fromRGB(132, 140, 162),
    MutedText = Color3.fromRGB(75, 82, 102),
    ToggleOff = Color3.fromRGB(25, 28, 38),
    Success = Color3.fromRGB(76, 209, 55),
    Danger = Color3.fromRGB(235, 77, 75),
    Warning = Color3.fromRGB(240, 147, 43),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontBlack = Enum.Font.GothamBlack,
    FontCode = Enum.Font.RobotoMono
}

-- Płynny silnik animacji TweenService
local function Tween(obj, props, time, style, dir)
    local t = time or 0.18
    local s = style or Enum.EasingStyle.Quart
    local d = dir or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(t, s, d), props)
    tw:Play()
    return tw
end

-- Dźwięk interfejsu (Subtle Mechanical Clicks)
local function PlayUiSound(soundType)
    if not config.toggles.ui_sounds then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.Volume = 0.3
        if soundType == "click" then
            sound.SoundId = "rbxassetid://6895079853"
            sound.PlaybackSpeed = 1.0
        elseif soundType == "toggle" then
            sound.SoundId = "rbxassetid://6895079853"
            sound.PlaybackSpeed = 1.2
        elseif soundType == "tab" then
            sound.SoundId = "rbxassetid://6895079853"
            sound.PlaybackSpeed = 0.95
        end
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end)
end

local TargetGui = GetSafeParent()
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = generateRandomName(15)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    pcall(function() syn.protect_gui(ScreenGui) end)
end
pcall(function() ScreenGui.Parent = TargetGui end)

local UpdatePreviewEvent = Instance.new("BindableEvent")
local UIThemeObjects = {}
local UIThemeGlows = {}

local function ApplyAccent(obj, property)
    table.insert(UIThemeObjects, {Obj = obj, Prop = property})
    obj[property] = config.colors.ui_accent
end

local function ApplyAccentGlow(obj, property, transparency)
    table.insert(UIThemeGlows, {Obj = obj, Prop = property, Trans = transparency or 0})
    obj[property] = config.colors.ui_accent
    if obj:IsA("UIStroke") then obj.Transparency = transparency or 0 end
end

local function UpdateAccents()
    for _, item in ipairs(UIThemeObjects) do 
        pcall(function() Tween(item.Obj, {[item.Prop] = config.colors.ui_accent}, 0.15) end) 
    end
    for _, item in ipairs(UIThemeGlows) do 
        pcall(function() Tween(item.Obj, {[item.Prop] = config.colors.ui_accent}, 0.15) end) 
    end
end

-- ==========================================
-- 4. RAMA GŁÓWNA (MONOLITH 940x620 - 4px CORNERS)
-- ==========================================
local DragContainer = Instance.new("CanvasGroup", ScreenGui)
DragContainer.Name = generateRandomName(10)
DragContainer.Size = UDim2.new(0, 940, 0, 620)
DragContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
DragContainer.AnchorPoint = Vector2.new(0.5, 0.5)
DragContainer.BackgroundColor3 = Theme.MainBg
DragContainer.BorderSizePixel = 0
DragContainer.GroupTransparency = 0
Instance.new("UICorner", DragContainer).CornerRadius = UDim.new(0, 4)

local MainStroke = Instance.new("UIStroke", DragContainer)
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1

local InnerBevel = Instance.new("Frame", DragContainer)
InnerBevel.Name = "InnerBevel"
InnerBevel.Size = UDim2.new(1, -2, 1, -2)
InnerBevel.Position = UDim2.new(0, 1, 0, 1)
InnerBevel.BackgroundTransparency = 1
InnerBevel.BorderSizePixel = 0
InnerBevel.ZIndex = 2
local InnerStroke = Instance.new("UIStroke", InnerBevel)
InnerStroke.Color = Color3.fromRGB(48, 55, 75)
InnerStroke.Transparency = 0.55
InnerStroke.Thickness = 1
Instance.new("UICorner", InnerBevel).CornerRadius = UDim.new(0, 3)

local DropShadow = Instance.new("ImageLabel", DragContainer)
DropShadow.Name = generateRandomName(8)
DropShadow.Size = UDim2.new(1, 140, 1, 140)
DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
DropShadow.BackgroundTransparency = 1
DropShadow.Image = "rbxassetid://6015897843"
DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
DropShadow.ImageTransparency = 0.45
DropShadow.ZIndex = -1

-- Precyzyjna linia akcentu na szczycie okna (Illuminated Accent Line)
local TopAccentLine = Instance.new("Frame", DragContainer)
TopAccentLine.Size = UDim2.new(1, 0, 0, 2)
TopAccentLine.Position = UDim2.new(0, 0, 0, 0)
TopAccentLine.BackgroundColor3 = config.colors.ui_accent
TopAccentLine.BorderSizePixel = 0
TopAccentLine.ZIndex = 25
ApplyAccent(TopAccentLine, "BackgroundColor3")

local TopAccentGrad = Instance.new("UIGradient", TopAccentLine)
TopAccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(0.5, Color3.new(0.85, 0.85, 0.95)),
    ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
})
TopAccentGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.35),
    NumberSequenceKeypoint.new(0.2, 0),
    NumberSequenceKeypoint.new(0.8, 0),
    NumberSequenceKeypoint.new(1, 0.35)
})

local function RefreshAccentGradient()
    TopAccentLine.BackgroundColor3 = config.colors.ui_accent
end

-- Płynne przeciąganie okna
local dragToggle, dragStart, startPos = false, nil, nil
DragContainer.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragToggle = true
        dragStart = input.Position
        startPos = DragContainer.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
        local delta = input.Position - dragStart
        DragContainer.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X, 
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================
-- 5. STATUS WATERMARK & KEYBINDS HUD (SKEET-GRADE)
-- ==========================================
local Watermark = Instance.new("Frame", ScreenGui)
Watermark.Name = generateRandomName(8)
Watermark.Size = UDim2.new(0, 280, 0, 26)
Watermark.Position = UDim2.new(0, 20, 0, 20)
Watermark.BackgroundColor3 = Theme.HeaderBg
Watermark.BackgroundTransparency = 0.05
Watermark.BorderSizePixel = 0
Watermark.Visible = config.toggles.watermark
Instance.new("UICorner", Watermark).CornerRadius = UDim.new(0, 3)

local WmStroke = Instance.new("UIStroke", Watermark)
WmStroke.Color = Theme.Border
WmStroke.Thickness = 1

local WmTopLine = Instance.new("Frame", Watermark)
WmTopLine.Size = UDim2.new(1, 0, 0, 2)
WmTopLine.Position = UDim2.new(0, 0, 0, 0)
WmTopLine.BorderSizePixel = 0
WmTopLine.BackgroundColor3 = config.colors.ui_accent
ApplyAccent(WmTopLine, "BackgroundColor3")

local WmText = Instance.new("TextLabel", Watermark)
WmText.Size = UDim2.new(1, -16, 1, 0)
WmText.Position = UDim2.new(0, 10, 0, 1)
WmText.BackgroundTransparency = 1
WmText.RichText = true
WmText.Font = Theme.FontCode
WmText.TextSize = 10.5
WmText.TextColor3 = Theme.Text
WmText.TextXAlignment = Enum.TextXAlignment.Left

-- Pływający Widget: Active Keybinds HUD
local KeybindsHUD = Instance.new("Frame", ScreenGui)
KeybindsHUD.Name = generateRandomName(8)
KeybindsHUD.Size = UDim2.new(0, 190, 0, 126)
KeybindsHUD.Position = UDim2.new(0, 20, 0.45, 0)
KeybindsHUD.BackgroundColor3 = Theme.HeaderBg
KeybindsHUD.BackgroundTransparency = 0.08
KeybindsHUD.BorderSizePixel = 0
KeybindsHUD.Visible = config.toggles.keybinds_hud
Instance.new("UICorner", KeybindsHUD).CornerRadius = UDim.new(0, 3)

local KhStroke = Instance.new("UIStroke", KeybindsHUD)
KhStroke.Color = Theme.Border
KhStroke.Thickness = 1

local KhTopLine = Instance.new("Frame", KeybindsHUD)
KhTopLine.Size = UDim2.new(1, 0, 0, 2)
KhTopLine.Position = UDim2.new(0, 0, 0, 0)
KhTopLine.BorderSizePixel = 0
KhTopLine.BackgroundColor3 = config.colors.ui_accent
ApplyAccent(KhTopLine, "BackgroundColor3")

local KhTitle = Instance.new("TextLabel", KeybindsHUD)
KhTitle.Size = UDim2.new(1, -16, 0, 22)
KhTitle.Position = UDim2.new(0, 10, 0, 2)
KhTitle.BackgroundTransparency = 1
KhTitle.Text = "KEYBINDS"
KhTitle.TextColor3 = Theme.Text
KhTitle.Font = Theme.FontCode
KhTitle.TextSize = 10
KhTitle.TextXAlignment = Enum.TextXAlignment.Left

local KhContainer = Instance.new("Frame", KeybindsHUD)
KhContainer.Size = UDim2.new(1, -16, 1, -28)
KhContainer.Position = UDim2.new(0, 8, 0, 26)
KhContainer.BackgroundTransparency = 1
local KhLayout = Instance.new("UIListLayout", KhContainer)
KhLayout.Padding = UDim.new(0, 2)
KhLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createKhRow(name)
    local row = Instance.new("Frame", KhContainer)
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    
    local rName = Instance.new("TextLabel", row)
    rName.Size = UDim2.new(0.65, 0, 1, 0)
    rName.BackgroundTransparency = 1
    rName.Text = name
    rName.TextColor3 = Theme.SubText
    rName.Font = Theme.FontCode
    rName.TextSize = 10
    rName.TextXAlignment = Enum.TextXAlignment.Left

    local rStatus = Instance.new("TextLabel", row)
    rStatus.Size = UDim2.new(0.35, 0, 1, 0)
    rStatus.Position = UDim2.new(0.65, 0, 0, 0)
    rStatus.BackgroundTransparency = 1
    rStatus.Text = "[IDLE]"
    rStatus.TextColor3 = Theme.MutedText
    rStatus.Font = Theme.FontCode
    rStatus.TextSize = 9
    rStatus.TextXAlignment = Enum.TextXAlignment.Right
    return {Row = row, Name = rName, Status = rStatus}
end

local KhRows = {
    Aimbot = createKhRow("Aimbot"),
    Fly = createKhRow("Fly Mode"),
    Zoom = createKhRow("Scope Zoom"),
    Noclip = createKhRow("Noclip"),
    Menu = createKhRow("Interface")
}

local khDragging, khStart, khPos = false, nil, nil
KeybindsHUD.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        khDragging = true
        khStart = input.Position
        khPos = KeybindsHUD.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                khDragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and khDragging then
        local delta = input.Position - khStart
        KeybindsHUD.Position = UDim2.new(
            khPos.X.Scale, khPos.X.Offset + delta.X, 
            khPos.Y.Scale, khPos.Y.Offset + delta.Y
        )
    end
end)

local frameCount, lastTick, currentFPS = 0, tick(), 60
local lastWatermarkUpdate = 0
local lastKhUpdate = 0

-- ==========================================
-- 6. TOP BAR (TECHNICAL INDUSTRIAL HEADER)
-- ==========================================
local TopBar = Instance.new("Frame", DragContainer)
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Theme.HeaderBg
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 20

local TopBarDivider = Instance.new("Frame", TopBar)
TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
TopBarDivider.Position = UDim2.new(0, 0, 1, -1)
TopBarDivider.BackgroundColor3 = Theme.Border
TopBarDivider.BorderSizePixel = 0

-- Monogram Tag [AW]
local BrandBadge = Instance.new("Frame", TopBar)
BrandBadge.Size = UDim2.new(0, 26, 0, 26)
BrandBadge.Position = UDim2.new(0, 14, 0.5, -13)
BrandBadge.BackgroundColor3 = Theme.ItemBg
Instance.new("UICorner", BrandBadge).CornerRadius = UDim.new(0, 3)
local BrandBadgeStroke = Instance.new("UIStroke", BrandBadge)
BrandBadgeStroke.Color = config.colors.ui_accent
BrandBadgeStroke.Thickness = 1
ApplyAccentGlow(BrandBadgeStroke, "Color", 0.3)

local BrandBadgeText = Instance.new("TextLabel", BrandBadge)
BrandBadgeText.Size = UDim2.new(1, 0, 1, 0)
BrandBadgeText.BackgroundTransparency = 1
BrandBadgeText.Text = "AW"
BrandBadgeText.TextColor3 = config.colors.ui_accent
BrandBadgeText.Font = Theme.FontCode
BrandBadgeText.TextSize = 11
ApplyAccent(BrandBadgeText, "TextColor3")

-- Technical Title & Breadcrumb
local BreadcrumbLabel = Instance.new("TextLabel", TopBar)
BreadcrumbLabel.Size = UDim2.new(0, 320, 1, 0)
BreadcrumbLabel.Position = UDim2.new(0, 48, 0, 0)
BreadcrumbLabel.BackgroundTransparency = 1
BreadcrumbLabel.RichText = true
BreadcrumbLabel.Text = "<b>ASAPWARE</b> <font color='#3b4154'>//</font> <font color='#8c93a8'>LEGITBOT</font>"
BreadcrumbLabel.TextColor3 = Theme.Text
BreadcrumbLabel.Font = Theme.FontBold
BreadcrumbLabel.TextSize = 12.5
BreadcrumbLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Telemetry bar in monospace (FPS | PING | TIME)
local TelemetryBadge = Instance.new("Frame", TopBar)
TelemetryBadge.Size = UDim2.new(0, 260, 0, 26)
TelemetryBadge.Position = UDim2.new(1, -330, 0.5, -13)
TelemetryBadge.BackgroundColor3 = Theme.ItemBg
Instance.new("UICorner", TelemetryBadge).CornerRadius = UDim.new(0, 3)
local tbStr = Instance.new("UIStroke", TelemetryBadge)
tbStr.Color = Theme.Border
tbStr.Thickness = 1

local TelemetryText = Instance.new("TextLabel", TelemetryBadge)
TelemetryText.Size = UDim2.new(1, -12, 1, 0)
TelemetryText.Position = UDim2.new(0, 6, 0, 0)
TelemetryText.BackgroundTransparency = 1
TelemetryText.RichText = true
TelemetryText.Text = "<font color='#4cd137'>SECURE</font> | 60 fps | 15ms | " .. os.date("%H:%M:%S")
TelemetryText.TextColor3 = Theme.SubText
TelemetryText.Font = Theme.FontCode
TelemetryText.TextSize = 10
TelemetryText.TextXAlignment = Enum.TextXAlignment.Center

task.spawn(function()
    while ScriptLoaded do
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        TelemetryText.Text = "<font color='#4cd137'>SECURE</font> | " .. tostring(currentFPS) .. " fps | " .. tostring(ping) .. "ms | " .. os.date("%H:%M:%S")
        task.wait(1)
    end
end)

-- Window Controls (Minimalist Square Buttons)
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -62, 0.5, -13)
MinBtn.BackgroundColor3 = Theme.ItemBg
MinBtn.Text = "_"
MinBtn.TextColor3 = Theme.SubText
MinBtn.Font = Theme.FontCode
MinBtn.TextSize = 12
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 3)
local minStr = Instance.new("UIStroke", MinBtn)
minStr.Color = Theme.Border

MinBtn.MouseEnter:Connect(function() 
    Tween(MinBtn, {BackgroundColor3 = Theme.ItemHover, TextColor3 = Theme.Text}, 0.12) 
end)
MinBtn.MouseLeave:Connect(function() 
    Tween(MinBtn, {BackgroundColor3 = Theme.ItemBg, TextColor3 = Theme.SubText}, 0.12) 
end)

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
CloseBtn.BackgroundColor3 = Theme.ItemBg
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Theme.FontBold
CloseBtn.TextSize = 14
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 3)
local closeStr = Instance.new("UIStroke", CloseBtn)
closeStr.Color = Theme.Border

CloseBtn.MouseEnter:Connect(function() 
    Tween(CloseBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Color3.new(1,1,1)}, 0.12)
    closeStr.Color = Theme.Danger
end)
CloseBtn.MouseLeave:Connect(function() 
    Tween(CloseBtn, {BackgroundColor3 = Theme.ItemBg, TextColor3 = Theme.SubText}, 0.12)
    closeStr.Color = Theme.Border
end)

-- ==========================================
-- 7. SIDEBAR (190px) & TECHNICAL USER CARD
-- ==========================================
local Sidebar = Instance.new("Frame", DragContainer)
Sidebar.Size = UDim2.new(0, 190, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BorderSizePixel = 0

local SidebarDivider = Instance.new("Frame", Sidebar)
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, 0, 0, 0)
SidebarDivider.BackgroundColor3 = Theme.Border
SidebarDivider.BorderSizePixel = 0

local SidebarScroll = Instance.new("ScrollingFrame", Sidebar)
SidebarScroll.Size = UDim2.new(1, 0, 1, -68)
SidebarScroll.Position = UDim2.new(0, 0, 0, 8)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 0
local SidebarLayout = Instance.new("UIListLayout", SidebarScroll)
SidebarLayout.Padding = UDim.new(0, 3)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Dolna Karta Profilu (Compact Technical Card)
local ProfileArea = Instance.new("Frame", Sidebar)
ProfileArea.Size = UDim2.new(1, 0, 0, 68)
ProfileArea.Position = UDim2.new(0, 0, 1, -68)
ProfileArea.BackgroundColor3 = Theme.HeaderBg
ProfileArea.BackgroundTransparency = 0.5
ProfileArea.BorderSizePixel = 0

local ProfLine = Instance.new("Frame", ProfileArea)
ProfLine.Size = UDim2.new(1, 0, 0, 1)
ProfLine.BackgroundColor3 = Theme.Border
ProfLine.BorderSizePixel = 0

local Avatar = Instance.new("ImageLabel", ProfileArea)
Avatar.Size = UDim2.new(0, 36, 0, 36)
Avatar.Position = UDim2.new(0, 12, 0.5, -18)
Avatar.BackgroundColor3 = Theme.ItemBg
Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 3)
local AvatarRing = Instance.new("UIStroke", Avatar)
AvatarRing.Thickness = 1
AvatarRing.Color = Theme.Border

task.spawn(function()
    pcall(function()
        Avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
end)

local OnlineDot = Instance.new("Frame", ProfileArea)
OnlineDot.Size = UDim2.new(0, 6, 0, 6)
OnlineDot.Position = UDim2.new(0, 42, 0.5, 10)
OnlineDot.BackgroundColor3 = Theme.Success
OnlineDot.BorderSizePixel = 0
Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(0, 1)
local OnlineStroke = Instance.new("UIStroke", OnlineDot)
OnlineStroke.Thickness = 1
OnlineStroke.Color = Theme.SidebarBg

local Username = Instance.new("TextLabel", ProfileArea)
Username.Size = UDim2.new(1, -60, 0, 15)
Username.Position = UDim2.new(0, 56, 0.5, -16)
Username.BackgroundTransparency = 1
Username.Text = LocalPlayer.Name
Username.TextColor3 = Theme.Text
Username.Font = Theme.FontBold
Username.TextSize = 11
Username.TextXAlignment = Enum.TextXAlignment.Left

local SubBadge = Instance.new("Frame", ProfileArea)
SubBadge.Size = UDim2.new(0, 76, 0, 15)
SubBadge.Position = UDim2.new(0, 56, 0.5, 2)
SubBadge.BackgroundColor3 = Theme.ItemBg
Instance.new("UICorner", SubBadge).CornerRadius = UDim.new(0, 2)
local SubBadgeStroke = Instance.new("UIStroke", SubBadge)
SubBadgeStroke.Thickness = 1
SubBadgeStroke.Color = config.colors.ui_accent
ApplyAccent(SubBadgeStroke, "Color")

local SubText = Instance.new("TextLabel", SubBadge)
SubText.Size = UDim2.new(1, 0, 1, 0)
SubText.BackgroundTransparency = 1
SubText.Text = "LIFETIME"
SubText.TextColor3 = config.colors.ui_accent
SubText.Font = Theme.FontCode
SubText.TextSize = 8.5
SubText.TextXAlignment = Enum.TextXAlignment.Center
ApplyAccent(SubText, "TextColor3")

-- ==========================================
-- 8. SYSTEM ZAKŁADEK (NO EMOJIS - PURE INDUSTRIAL)
-- ==========================================
local TabContainer = Instance.new("Frame", DragContainer)
TabContainer.Size = UDim2.new(1, -190, 1, -44)
TabContainer.Position = UDim2.new(0, 190, 0, 44)
TabContainer.BackgroundTransparency = 1
TabContainer.ClipsDescendants = true

local Tabs = {}
local globalLayoutOrder = 0

local function CreateCategory(name)
    globalLayoutOrder = globalLayoutOrder + 10
    local catFrame = Instance.new("Frame", SidebarScroll)
    catFrame.Size = UDim2.new(1, -20, 0, 20)
    catFrame.BackgroundTransparency = 1
    catFrame.LayoutOrder = globalLayoutOrder

    local lbl = Instance.new("TextLabel", catFrame)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "// " .. string.upper(name)
    lbl.TextColor3 = Theme.MutedText
    lbl.Font = Theme.FontCode
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function CreateTab(name, indexStr, isFirst)
    globalLayoutOrder = globalLayoutOrder + 1

    local btnContainer = Instance.new("Frame", SidebarScroll)
    btnContainer.Size = UDim2.new(1, -14, 0, 32)
    btnContainer.BackgroundTransparency = 1
    btnContainer.LayoutOrder = globalLayoutOrder

    local btn = Instance.new("TextButton", btnContainer)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = isFirst and Theme.ItemHover or Theme.ItemBg
    btn.BackgroundTransparency = isFirst and 0 or 1
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = isFirst and Theme.BorderLight or Theme.Border
    btnStroke.Thickness = 1
    btnStroke.Transparency = isFirst and 0 or 1

    local tabGlow = Instance.new("Frame", btn)
    tabGlow.Size = UDim2.new(1, 0, 1, 0)
    tabGlow.BackgroundTransparency = isFirst and 0.88 or 1
    tabGlow.BackgroundColor3 = config.colors.ui_accent
    tabGlow.BorderSizePixel = 0
    tabGlow.ZIndex = 1
    Instance.new("UICorner", tabGlow).CornerRadius = UDim.new(0, 3)
    local tgGrad = Instance.new("UIGradient", tabGlow)
    tgGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    ApplyAccent(tabGlow, "BackgroundColor3")

    -- Pionowy wskaźnik na krawędzi (Surgical Accent Bar)
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 2.5, isFirst and 0.65 or 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.175, 0)
    indicator.BackgroundColor3 = config.colors.ui_accent
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 2
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 1)
    if isFirst then ApplyAccent(indicator, "BackgroundColor3") end

    -- Indeks numeryczny
    local idxLbl = Instance.new("TextLabel", btn)
    idxLbl.Size = UDim2.new(0, 18, 1, 0)
    idxLbl.Position = UDim2.new(0, 10, 0, 0)
    idxLbl.BackgroundTransparency = 1
    idxLbl.ZIndex = 2
    idxLbl.Text = indexStr or "00"
    idxLbl.TextColor3 = isFirst and config.colors.ui_accent or Theme.MutedText
    idxLbl.Font = Theme.FontCode
    idxLbl.TextSize = 9.5
    idxLbl.TextXAlignment = Enum.TextXAlignment.Left
    if isFirst then ApplyAccent(idxLbl, "TextColor3") end

    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1, -34, 1, 0)
    txt.Position = UDim2.new(0, 32, 0, 0)
    txt.BackgroundTransparency = 1
    txt.ZIndex = 2
    txt.Text = string.upper(name)
    txt.TextColor3 = isFirst and Theme.Text or Theme.SubText
    txt.Font = Theme.FontBold
    txt.TextSize = 10.5
    txt.TextXAlignment = Enum.TextXAlignment.Left

    -- Strona zawartości
    local page = Instance.new("ScrollingFrame", TabContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = isFirst and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 0, 15)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2.5
    page.ScrollBarImageColor3 = Theme.BorderLight
    page.Visible = isFirst
    page.BorderSizePixel = 0

    local pagePadding = Instance.new("UIPadding", page)
    pagePadding.PaddingTop = UDim.new(0, 12)
    pagePadding.PaddingBottom = UDim.new(0, 16)
    pagePadding.PaddingLeft = UDim.new(0, 16)
    pagePadding.PaddingRight = UDim.new(0, 16)

    local colLeft = Instance.new("Frame", page)
    colLeft.Size = UDim2.new(0.488, 0, 0, 0)
    colLeft.BackgroundTransparency = 1
    local lLayout = Instance.new("UIListLayout", colLeft)
    lLayout.Padding = UDim.new(0, 12)
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local colRight = Instance.new("Frame", page)
    colRight.Size = UDim2.new(0.488, 0, 0, 0)
    colRight.Position = UDim2.new(0.512, 0, 0, 0)
    colRight.BackgroundTransparency = 1
    local rLayout = Instance.new("UIListLayout", colRight)
    rLayout.Padding = UDim.new(0, 12)
    rLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function UpdateCanvas()
        local hL = lLayout.AbsoluteContentSize.Y
        local hR = rLayout.AbsoluteContentSize.Y
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(hL, hR) + 32)
        colLeft.Size = UDim2.new(0.488, 0, 0, hL)
        colRight.Size = UDim2.new(0.488, 0, 0, hR)
    end
    lLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

    table.insert(Tabs, {
        Btn = btn, Stroke = btnStroke, Txt = txt, Idx = idxLbl,
        Ind = indicator, Glow = tabGlow, Page = page, Name = name
    })

    btn.MouseEnter:Connect(function()
        if not page.Visible then
            btn.BackgroundTransparency = 0.5
            btn.BackgroundColor3 = Theme.ItemHover
            Tween(txt, {TextColor3 = Theme.Text}, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if not page.Visible then
            btn.BackgroundTransparency = 1
            Tween(txt, {TextColor3 = Theme.SubText}, 0.12)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if page.Visible then return end
        PlayUiSound("tab")
        
        BreadcrumbLabel.Text = "<b>ASAPWARE</b> <font color='#3b4154'>//</font> <font color='#8c93a8'>" .. string.upper(name) .. "</font>"

        for _, t in ipairs(Tabs) do
            Tween(t.Txt, {TextColor3 = Theme.SubText}, 0.12)
            Tween(t.Idx, {TextColor3 = Theme.MutedText}, 0.12)
            t.Btn.BackgroundTransparency = 1
            t.Stroke.Transparency = 1
            if t.Glow then Tween(t.Glow, {BackgroundTransparency = 1}, 0.12) end
            Tween(t.Ind, {Size = UDim2.new(0, 2.5, 0, 0)}, 0.12)
            if t.Page.Visible then
                Tween(t.Page, {Position = UDim2.new(0, 0, 0, 12)}, 0.12)
                task.delay(0.12, function() t.Page.Visible = false end)
            end
        end

        Tween(txt, {TextColor3 = Theme.Text}, 0.15)
        btn.BackgroundColor3 = Theme.ItemHover
        btn.BackgroundTransparency = 0
        btnStroke.Color = Theme.BorderLight
        btnStroke.Transparency = 0
        if tabGlow then Tween(tabGlow, {BackgroundTransparency = 0.88}, 0.15) end
        Tween(indicator, {Size = UDim2.new(0, 2.5, 0.65, 0)}, 0.18, Enum.EasingStyle.Quart)
        ApplyAccent(indicator, "BackgroundColor3")
        ApplyAccent(idxLbl, "TextColor3")

        page.Visible = true
        page.Position = UDim2.new(0, 0, 0, 12)
        Tween(page, {Position = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart)
        UpdateCanvas()
    end)

    return {Left = colLeft, Right = colRight}
end

-- ==========================================
-- 9. GROUPBOXY I PRZEMYSŁOWE KONTROLKI (SKEET STYLE)
-- ==========================================
local sectionCounter = 1

local function CreateSection(col, title)
    local sec = Instance.new("Frame", col)
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.BackgroundColor3 = Theme.GroupboxBg
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 4)
    local str = Instance.new("UIStroke", sec)
    str.Color = Theme.Border
    str.Thickness = 1

    local secIdxStr = string.format("0%d", sectionCounter)
    sectionCounter = sectionCounter + 1

    local header = Instance.new("Frame", sec)
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = Theme.GroupboxHeader
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)

    local flatBottom = Instance.new("Frame", header)
    flatBottom.Size = UDim2.new(1, 0, 0, 6)
    flatBottom.Position = UDim2.new(0, 0, 1, -6)
    flatBottom.BackgroundColor3 = Theme.GroupboxHeader
    flatBottom.BorderSizePixel = 0

    local pip = Instance.new("Frame", header)
    pip.Size = UDim2.new(0, 2.5, 0, 12)
    pip.Position = UDim2.new(0, 10, 0.5, -6)
    pip.BackgroundColor3 = config.colors.ui_accent
    pip.BorderSizePixel = 0
    Instance.new("UICorner", pip).CornerRadius = UDim.new(0, 1)
    ApplyAccent(pip, "BackgroundColor3")

    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(title)
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.FontBold
    lbl.TextSize = 10.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local numLbl = Instance.new("TextLabel", header)
    numLbl.Size = UDim2.new(0, 30, 1, 0)
    numLbl.Position = UDim2.new(1, -36, 0, 0)
    numLbl.BackgroundTransparency = 1
    numLbl.Text = "[" .. secIdxStr .. "]"
    numLbl.TextColor3 = Theme.MutedText
    numLbl.Font = Theme.FontCode
    numLbl.TextSize = 9
    numLbl.TextXAlignment = Enum.TextXAlignment.Right

    local line = Instance.new("Frame", sec)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, 28)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0

    local content = Instance.new("Frame", sec)
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 29)
    content.BackgroundTransparency = 1
    
    local cPadding = Instance.new("UIPadding", content)
    cPadding.PaddingTop = UDim.new(0, 10)
    cPadding.PaddingBottom = UDim.new(0, 12)
    cPadding.PaddingLeft = UDim.new(0, 12)
    cPadding.PaddingRight = UDim.new(0, 12)
    
    local cLayout = Instance.new("UIListLayout", content)
    cLayout.Padding = UDim.new(0, 8)
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder

    cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.Size = UDim2.new(1, 0, 0, cLayout.AbsoluteContentSize.Y + 22)
        sec.Size = UDim2.new(1, 0, 0, content.Size.Y.Offset + 29)
    end)

    return content
end

local elementLayoutCounter = 0
local function GetNextLayoutOrder()
    elementLayoutCounter = elementLayoutCounter + 1
    return elementLayoutCounter
end

-- 1. PRECYZYJNY PRZEŁĄCZNIK (INDUSTRIAL RECTANGULAR TOGGLE)
local function CreateToggle(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = GetNextLayoutOrder()

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = tbl[key] and Theme.Text or Theme.SubText
    lbl.Font = Theme.Font
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 30, 0, 16)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.BackgroundColor3 = tbl[key] and config.colors.ui_accent or Theme.ToggleOff
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
    
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 1
    btnStroke.Color = tbl[key] and config.colors.ui_accent or Theme.Border

    local thumb = Instance.new("Frame", btn)
    thumb.Size = UDim2.new(0, 10, 0, 10)
    thumb.Position = UDim2.new(0, tbl[key] and 17 or 3, 0.5, -5)
    thumb.BackgroundColor3 = Color3.fromRGB(240, 243, 252)
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 2)

    local thumbLed = Instance.new("Frame", thumb)
    thumbLed.Size = UDim2.new(0, 4, 0, 4)
    thumbLed.Position = UDim2.new(0.5, -2, 0.5, -2)
    thumbLed.BackgroundColor3 = tbl[key] and config.colors.ui_accent or Color3.fromRGB(150, 155, 175)
    thumbLed.BorderSizePixel = 0
    Instance.new("UICorner", thumbLed).CornerRadius = UDim.new(0, 1)

    if tbl[key] then 
        ApplyAccent(btn, "BackgroundColor3") 
        ApplyAccent(thumbLed, "BackgroundColor3")
        ApplyAccentGlow(btnStroke, "Color", 0.4)
    end

    local function updateVisual()
        if tbl[key] then
            ApplyAccent(btn, "BackgroundColor3")
            ApplyAccent(thumbLed, "BackgroundColor3")
            ApplyAccentGlow(btnStroke, "Color", 0.4)
            Tween(thumb, {Position = UDim2.new(0, 17, 0.5, -5)}, 0.12)
            Tween(lbl, {TextColor3 = Theme.Text}, 0.12)
        else
            for i, item in ipairs(UIThemeObjects) do
                if item.Obj == btn or item.Obj == thumbLed then table.remove(UIThemeObjects, i) break end
            end
            for i, item in ipairs(UIThemeGlows) do
                if item.Obj == btnStroke then table.remove(UIThemeGlows, i) break end
            end
            Tween(btn, {BackgroundColor3 = Theme.ToggleOff}, 0.12)
            thumbLed.BackgroundColor3 = Color3.fromRGB(150, 155, 175)
            btnStroke.Color = Theme.Border
            Tween(thumb, {Position = UDim2.new(0, 3, 0.5, -5)}, 0.12)
            Tween(lbl, {TextColor3 = Theme.SubText}, 0.12)
        end
    end
    UpdatePreviewEvent.Event:Connect(updateVisual)

    btn.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        PlayUiSound("toggle")
        updateVisual()
        UpdatePreviewEvent:Fire()
    end)
end

-- 2. SUWAK PRECYZYJNY Z NUMERYCZNYM POLEM MONOSPACE
local function CreateSlider(parent, text, tbl, key, min, max)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = GetNextLayoutOrder()

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -50, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valBg = Instance.new("Frame", frame)
    valBg.Size = UDim2.new(0, 44, 0, 16)
    valBg.Position = UDim2.new(1, -44, 0, -1)
    valBg.BackgroundColor3 = Theme.ItemBg
    Instance.new("UICorner", valBg).CornerRadius = UDim.new(0, 3)
    local valStr = Instance.new("UIStroke", valBg)
    valStr.Color = Theme.Border
    valStr.Thickness = 1

    local valLbl = Instance.new("TextBox", valBg)
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(tbl[key])
    valLbl.TextColor3 = Theme.Text
    valLbl.Font = Theme.FontCode
    valLbl.TextSize = 9.5
    valLbl.TextXAlignment = Enum.TextXAlignment.Center
    valLbl.ClearTextOnFocus = false

    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 1, -5)
    track.BackgroundColor3 = Theme.ToggleOff
    track.Text = ""
    track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(math.clamp((tbl[key]-min)/(max-min), 0, 1), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
    fill.BackgroundColor3 = config.colors.ui_accent
    ApplyAccent(fill, "BackgroundColor3")

    local knob = Instance.new("Frame", fill)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(1, -5, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(240, 243, 252)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 2)
    local kStroke = Instance.new("UIStroke", knob)
    kStroke.Color = Theme.Border
    kStroke.Thickness = 1

    valLbl.FocusLost:Connect(function()
        local num = tonumber(valLbl.Text)
        if num then
            num = math.clamp(math.floor(num), min, max)
            tbl[key] = num
            valLbl.Text = tostring(num)
            local pct = (num - min) / (max - min)
            Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1)
            UpdatePreviewEvent:Fire()
        else
            valLbl.Text = tostring(tbl[key])
        end
    end)

    local dragging = false
    local function update(i)
        local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pct))
        tbl[key] = val
        valLbl.Text = tostring(val)
        Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.04)
        UpdatePreviewEvent:Fire()
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            dragging = true 
            Tween(valBg, {BackgroundColor3 = Theme.ItemHover}, 0.1)
            update(i) 
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            dragging = false 
            Tween(valBg, {BackgroundColor3 = Theme.ItemBg}, 0.12)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
            update(i) 
        end
    end)
end

-- 3. INDUSTRIAL DROPDOWN MENU
local function CreateDropdown(parent, text, tbl, key, options)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false
    frame.ZIndex = 50
    frame.LayoutOrder = GetNextLayoutOrder()

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.Position = UDim2.new(0, 0, 1, -24)
    btn.BackgroundColor3 = Theme.ItemBg
    btn.Text = "  " .. options[tbl[key]]
    btn.TextColor3 = Theme.SubText
    btn.Font = Theme.Font
    btn.TextSize = 10.5
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 51
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Theme.Border
    btnStroke.Thickness = 1

    local arrow = Instance.new("TextLabel", btn)
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = Theme.MutedText
    arrow.Font = Theme.FontCode
    arrow.TextSize = 10
    arrow.ZIndex = 51

    local listFrame = Instance.new("Frame", frame)
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.Position = UDim2.new(0, 0, 0, 46)
    listFrame.BackgroundColor3 = Theme.HeaderBg
    listFrame.ClipsDescendants = true
    listFrame.ZIndex = 52
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 3)
    local listStr = Instance.new("UIStroke", listFrame)
    listStr.Color = Theme.Border
    listStr.Transparency = 1
    
    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local isOpen = false

    local function setZIndex(val)
        frame.ZIndex = val
        btn.ZIndex = val + 1
        arrow.ZIndex = val + 1
        listFrame.ZIndex = val + 2
        for _, c in ipairs(listFrame:GetChildren()) do 
            if c:IsA("TextButton") or c:IsA("Frame") then c.ZIndex = val + 3 end 
        end
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        PlayUiSound("click")
        if isOpen then
            setZIndex(100)
            listStr.Transparency = 0
            btnStroke.Color = config.colors.ui_accent
            ApplyAccent(btnStroke, "Color")
            Tween(listFrame, {Size = UDim2.new(1, 0, 0, #options * 24)}, 0.16)
            arrow.Text = "^"
        else
            btnStroke.Color = Theme.Border
            for i, item in ipairs(UIThemeObjects) do
                if item.Obj == btnStroke then table.remove(UIThemeObjects, i) break end
            end
            Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.14)
            arrow.Text = "v"
            task.delay(0.14, function() listStr.Transparency = 1 setZIndex(50) end)
        end
    end)

    for i, optionText in ipairs(options) do
        local optBtn = Instance.new("TextButton", listFrame)
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = "    " .. optionText
        optBtn.TextColor3 = (tbl[key] == i) and config.colors.ui_accent or Theme.SubText
        optBtn.Font = Theme.Font
        optBtn.TextSize = 10
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.LayoutOrder = i
        
        if tbl[key] == i then 
            ApplyAccent(optBtn, "TextColor3") 
        end

        optBtn.MouseEnter:Connect(function() 
            Tween(optBtn, {BackgroundTransparency = 0.8}, 0.1) 
            if tbl[key] ~= i then Tween(optBtn, {TextColor3 = Theme.Text}, 0.1) end 
        end)
        optBtn.MouseLeave:Connect(function() 
            Tween(optBtn, {BackgroundTransparency = 1}, 0.1) 
            if tbl[key] ~= i then Tween(optBtn, {TextColor3 = Theme.SubText}, 0.1) end 
        end)

        optBtn.MouseButton1Click:Connect(function()
            tbl[key] = i
            btn.Text = "  " .. optionText
            PlayUiSound("click")
            
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
            btnStroke.Color = Theme.Border
            for idx, item in ipairs(UIThemeObjects) do
                if item.Obj == btnStroke then table.remove(UIThemeObjects, idx) break end
            end
            Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.14)
            arrow.Text = "v"
            task.delay(0.14, function() listStr.Transparency = 1 setZIndex(50) end)
            UpdatePreviewEvent:Fire()
        end)
    end
end

-- 4. COLOR PICKER (INDUSTRIAL COMPACT)
local function CreateColorPicker(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false
    frame.ZIndex = 50
    frame.LayoutOrder = GetNextLayoutOrder()
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -45, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local colorBtn = Instance.new("TextButton", frame)
    colorBtn.Size = UDim2.new(0, 30, 0, 16)
    colorBtn.AnchorPoint = Vector2.new(1, 0.5)
    colorBtn.Position = UDim2.new(1, 0, 0.5, 0)
    colorBtn.BackgroundColor3 = tbl[key]
    colorBtn.Text = ""
    colorBtn.ZIndex = 51
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 3)
    local btnStroke = Instance.new("UIStroke", colorBtn)
    btnStroke.Color = Theme.Border
    btnStroke.Thickness = 1
    
    local pickerBox = Instance.new("Frame", frame)
    pickerBox.Size = UDim2.new(1, 0, 0, 0)
    pickerBox.Position = UDim2.new(0, 0, 0, 24)
    pickerBox.BackgroundColor3 = Theme.ItemBg
    pickerBox.ClipsDescendants = true
    pickerBox.ZIndex = 52
    Instance.new("UICorner", pickerBox).CornerRadius = UDim.new(0, 4)
    local pStr = Instance.new("UIStroke", pickerBox)
    pStr.Color = Theme.Border
    pStr.Transparency = 1
    
    local svMap = Instance.new("TextButton", pickerBox)
    svMap.Size = UDim2.new(1, -24, 0, 75)
    svMap.Position = UDim2.new(0, 5, 0, 5)
    svMap.AutoButtonColor = false
    svMap.Text = ""
    svMap.ZIndex = 53
    Instance.new("UICorner", svMap).CornerRadius = UDim.new(0, 3)
    
    local svWhite = Instance.new("Frame", svMap)
    svWhite.Size = UDim2.new(1, 0, 1, 0)
    svWhite.BackgroundColor3 = Color3.new(1,1,1)
    svWhite.ZIndex = 54
    Instance.new("UICorner", svWhite).CornerRadius = UDim.new(0, 3)
    local uigW = Instance.new("UIGradient", svWhite)
    uigW.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}
    
    local svBlack = Instance.new("Frame", svMap)
    svBlack.Size = UDim2.new(1, 0, 1, 0)
    svBlack.BackgroundColor3 = Color3.new(0,0,0)
    svBlack.ZIndex = 55
    Instance.new("UICorner", svBlack).CornerRadius = UDim.new(0, 3)
    local uigB = Instance.new("UIGradient", svBlack)
    uigB.Rotation = 90
    uigB.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}
    
    local cursorSV = Instance.new("Frame", svMap)
    cursorSV.Size = UDim2.new(0, 6, 0, 6)
    cursorSV.BackgroundColor3 = Color3.new(1,1,1)
    cursorSV.ZIndex = 56
    Instance.new("UICorner", cursorSV).CornerRadius = UDim.new(0, 2)
    Instance.new("UIStroke", cursorSV).Color = Color3.new(0,0,0)

    local hueBar = Instance.new("TextButton", pickerBox)
    hueBar.Size = UDim2.new(0, 10, 0, 75)
    hueBar.Position = UDim2.new(1, -15, 0, 5)
    hueBar.BackgroundColor3 = Color3.new(1,1,1)
    hueBar.AutoButtonColor = false
    hueBar.Text = ""
    hueBar.ZIndex = 53
    Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 3)
    
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
    cursorH.Size = UDim2.new(1, 4, 0, 4)
    cursorH.Position = UDim2.new(0, -2, 0, 0)
    cursorH.BackgroundColor3 = Color3.new(1,1,1)
    cursorH.ZIndex = 56
    Instance.new("UICorner", cursorH).CornerRadius = UDim.new(0, 1)
    Instance.new("UIStroke", cursorH).Color = Color3.new(0,0,0)

    local h, s, v = tbl[key]:ToHSV()
    svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    cursorSV.Position = UDim2.new(s, -3, 1 - v, -3)
    cursorH.Position = UDim2.new(0, -2, 1 - h, -2)

    local isOpen = false
    colorBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        PlayUiSound("click")
        if isOpen then
            frame.ZIndex = 100
            pStr.Transparency = 0
            Tween(pickerBox, {Size = UDim2.new(1, 0, 0, 85)}, 0.18)
            Tween(frame, {Size = UDim2.new(1, 0, 0, 110)}, 0.18)
            btnStroke.Color = config.colors.ui_accent
            ApplyAccent(btnStroke, "Color")
        else
            Tween(pickerBox, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
            Tween(frame, {Size = UDim2.new(1, 0, 0, 20)}, 0.15)
            btnStroke.Color = Theme.Border
            for idx, item in ipairs(UIThemeObjects) do
                if item.Obj == btnStroke then table.remove(UIThemeObjects, idx) break end
            end
            task.delay(0.15, function() pStr.Transparency = 1 frame.ZIndex = 50 end)
        end
    end)
    
    local function apply()
        local c = Color3.fromHSV(h, s, v)
        tbl[key] = c
        colorBtn.BackgroundColor3 = c
        svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        if key == "ui_accent" then 
            UpdateAccents() 
            RefreshAccentGradient()
        end
        UpdatePreviewEvent:Fire()
    end
    
    local draggingSV, draggingH = false, false
    svMap.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            draggingSV = true 
        end 
    end)
    hueBar.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            draggingH = true 
        end 
    end)
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            draggingSV = false 
            draggingH = false 
        end 
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if draggingSV then
                local mx = math.clamp(input.Position.X - svMap.AbsolutePosition.X, 0, svMap.AbsoluteSize.X)
                local my = math.clamp(input.Position.Y - svMap.AbsolutePosition.Y, 0, svMap.AbsoluteSize.Y)
                s = mx / svMap.AbsoluteSize.X
                v = 1 - (my / svMap.AbsoluteSize.Y)
                cursorSV.Position = UDim2.new(0, mx - 3, 0, my - 3)
                apply()
            end
            if draggingH then
                local my = math.clamp(input.Position.Y - hueBar.AbsolutePosition.Y, 0, hueBar.AbsoluteSize.Y)
                h = 1 - (my / hueBar.AbsoluteSize.Y)
                cursorH.Position = UDim2.new(0, -2, 0, my - 2)
                apply()
            end
        end
    end)
end

-- 5. KEYBIND BADGE (MONOSPACE RECTANGULAR)
local function CreateKeybind(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = GetNextLayoutOrder()
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -65, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Theme.Font
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local function formatKey(v)
        if not v then return "NONE" end
        if v == Enum.UserInputType.MouseButton1 then return "MB1" end
        if v == Enum.UserInputType.MouseButton2 then return "MB2" end
        return v.Name
    end

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 56, 0, 18)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.BackgroundColor3 = Theme.ItemBg
    btn.Text = "[" .. formatKey(tbl[key]) .. "]"
    btn.TextColor3 = Theme.SubText
    btn.Font = Theme.FontCode
    btn.TextSize = 9.5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
    local str = Instance.new("UIStroke", btn)
    str.Color = Theme.Border
    str.Thickness = 1
    
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ItemHover}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ItemBg}) end)

    local listening = false
    btn.MouseButton1Click:Connect(function()
        listening = true
        PlayUiSound("click")
        btn.Text = "[ ... ]"
        str.Color = config.colors.ui_accent
        ApplyAccent(str, "Color")
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
            if bindVal == Enum.KeyCode.Escape then 
                tbl[key] = nil 
            else 
                tbl[key] = bindVal 
            end
            btn.Text = "[" .. formatKey(tbl[key]) .. "]"
            listening = false
            str.Color = Theme.Border
            for idx, item in ipairs(UIThemeObjects) do
                if item.Obj == str then table.remove(UIThemeObjects, idx) break end
            end
            PlayUiSound("toggle")
        end
    end)
end

-- 6. ACTION BUTTON (INDUSTRIAL SKEET STYLE)
local function CreateButton(parent, text, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = color or Theme.ItemBg
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 243, 252)
    btn.Font = Theme.FontBold
    btn.TextSize = 10.5
    btn.LayoutOrder = GetNextLayoutOrder()
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
    local str = Instance.new("UIStroke", btn)
    str.Color = Theme.Border
    str.Thickness = 1
    
    if color == Theme.Danger then
        str.Color = Theme.Danger
        str.Transparency = 0.4
    end

    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.3}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0}) end)
    btn.MouseButton1Click:Connect(function()
        PlayUiSound("click")
        Tween(btn, {BackgroundTransparency = 0.5}, 0.06)
        task.wait(0.06)
        Tween(btn, {BackgroundTransparency = 0}, 0.08)
        if callback then callback() end
    end)
    return btn
end

-- ==========================================
-- 10. TAKTYCZNY PODGLĄD 2D ESP (HUD RADAR)
-- ==========================================
local function Build2DPreview(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 300)
    frame.BackgroundColor3 = Color3.fromRGB(11, 12, 17)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    local frameStr = Instance.new("UIStroke", frame)
    frameStr.Color = Theme.Border
    frameStr.Thickness = 1
    frame.ClipsDescendants = true
    frame.LayoutOrder = GetNextLayoutOrder()

    local grid = Instance.new("ImageLabel", frame)
    grid.Size = UDim2.new(1, 0, 1, 0)
    grid.BackgroundTransparency = 1
    grid.Image = "rbxassetid://4508731118"
    grid.ImageTransparency = 0.92
    grid.TileSize = UDim2.new(0, 30, 0, 30)

    local function createCrosshair(x, y)
        local ch = Instance.new("TextLabel", frame)
        ch.Size = UDim2.new(0, 14, 0, 14)
        ch.Position = UDim2.new(x, x == 1 and -16 or 4, y, y == 1 and -16 or 4)
        ch.BackgroundTransparency = 1
        ch.Text = "+"
        ch.TextColor3 = Theme.MutedText
        ch.Font = Theme.FontCode
        ch.TextSize = 10
    end
    createCrosshair(0, 0)
    createCrosshair(1, 0)
    createCrosshair(0, 1)
    createCrosshair(1, 1)

    local previewTag = Instance.new("TextLabel", frame)
    previewTag.Size = UDim2.new(1, -20, 0, 20)
    previewTag.Position = UDim2.new(0, 12, 0, 4)
    previewTag.BackgroundTransparency = 1
    previewTag.Text = "TARGET SIMULATION RADAR"
    previewTag.TextColor3 = Theme.MutedText
    previewTag.Font = Theme.FontCode
    previewTag.TextSize = 9
    previewTag.TextXAlignment = Enum.TextXAlignment.Left

    local centerAnchor = Instance.new("Frame", frame)
    centerAnchor.Size = UDim2.new(0, 0, 0, 0)
    centerAnchor.Position = UDim2.new(0.5, 0, 0.54, 0)
    centerAnchor.BackgroundTransparency = 1

    local dummy = Instance.new("Frame", centerAnchor)
    dummy.BackgroundTransparency = 1
    dummy.Size = UDim2.new(1, 0, 1, 0)
    
    local dCol = Color3.fromRGB(42, 46, 58)
    local head = Instance.new("Frame", dummy)
    head.Size = UDim2.new(0, 24, 0, 24)
    head.Position = UDim2.new(0, 0, 0, -45)
    head.AnchorPoint = Vector2.new(0.5, 0.5)
    head.BackgroundColor3 = dCol
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 3)
    
    local torso = Instance.new("Frame", dummy)
    torso.Size = UDim2.new(0, 48, 0, 48)
    torso.Position = UDim2.new(0, 0, 0, -3)
    torso.AnchorPoint = Vector2.new(0.5, 0.5)
    torso.BackgroundColor3 = dCol
    Instance.new("UICorner", torso).CornerRadius = UDim.new(0, 2)
    
    local lArm = Instance.new("Frame", dummy)
    lArm.Size = UDim2.new(0, 20, 0, 48)
    lArm.Position = UDim2.new(0, -38, 0, -3)
    lArm.AnchorPoint = Vector2.new(0.5, 0.5)
    lArm.BackgroundColor3 = dCol
    Instance.new("UICorner", lArm).CornerRadius = UDim.new(0, 2)
    
    local rArm = Instance.new("Frame", dummy)
    rArm.Size = UDim2.new(0, 20, 0, 48)
    rArm.Position = UDim2.new(0, 38, 0, -3)
    rArm.AnchorPoint = Vector2.new(0.5, 0.5)
    rArm.BackgroundColor3 = dCol
    Instance.new("UICorner", rArm).CornerRadius = UDim.new(0, 2)
    
    local lLeg = Instance.new("Frame", dummy)
    lLeg.Size = UDim2.new(0, 22, 0, 52)
    lLeg.Position = UDim2.new(0, -13, 0, 52)
    lLeg.AnchorPoint = Vector2.new(0.5, 0.5)
    lLeg.BackgroundColor3 = dCol
    Instance.new("UICorner", lLeg).CornerRadius = UDim.new(0, 2)
    
    local rLeg = Instance.new("Frame", dummy)
    rLeg.Size = UDim2.new(0, 22, 0, 52)
    rLeg.Position = UDim2.new(0, 13, 0, 52)
    rLeg.AnchorPoint = Vector2.new(0.5, 0.5)
    rLeg.BackgroundColor3 = dCol
    Instance.new("UICorner", rLeg).CornerRadius = UDim.new(0, 2)

    local esp = Instance.new("Frame", centerAnchor)
    esp.Size = UDim2.new(1, 0, 1, 0)
    esp.BackgroundTransparency = 1

    local chams = Instance.new("Frame", esp)
    chams.Size = UDim2.new(0, 108, 0, 150)
    chams.Position = UDim2.new(0, 0, 0, 6)
    chams.AnchorPoint = Vector2.new(0.5, 0.5)
    chams.BackgroundColor3 = config.colors.chams_fill
    chams.BackgroundTransparency = 0.65
    Instance.new("UICorner", chams).CornerRadius = UDim.new(0, 3)

    local function drawLine(parent, p1, p2)
        local ln = Instance.new("Frame", parent)
        ln.BackgroundColor3 = Color3.new(1,1,1)
        ln.BorderSizePixel = 0
        local dist = (p1 - p2).Magnitude
        ln.Size = UDim2.new(0, dist, 0, 1.5)
        local center = (p1 + p2) / 2
        ln.Position = UDim2.new(0, center.X, 0, center.Y)
        ln.AnchorPoint = Vector2.new(0.5, 0.5)
        ln.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
        return ln
    end
    
    local skeletonLines = Instance.new("Frame", esp)
    skeletonLines.BackgroundTransparency = 1
    skeletonLines.Size = UDim2.new(1, 0, 1, 0)

    local hC = Vector2.new(0, -45)
    local tTopC = Vector2.new(0, -24)
    local tBotC = Vector2.new(0, 20)
    local lAC = Vector2.new(-38, -3)
    local rAC = Vector2.new(38, -3)
    local lLC = Vector2.new(-13, 52)
    local rLC = Vector2.new(13, 52)

    local skelParts = {
        drawLine(skeletonLines, hC, tTopC),
        drawLine(skeletonLines, tTopC, tBotC),
        drawLine(skeletonLines, tTopC, lAC),
        drawLine(skeletonLines, tTopC, rAC),
        drawLine(skeletonLines, tBotC, lLC),
        drawLine(skeletonLines, tBotC, rLC)
    }

    local box = Instance.new("Frame", esp)
    box.Size = UDim2.new(0, 118, 0, 156)
    box.Position = UDim2.new(0, 0, 0, 6)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    local boxStr = Instance.new("UIStroke", box)
    boxStr.Thickness = 1

    local boxFill = Instance.new("Frame", box)
    boxFill.Size = UDim2.new(1, 0, 1, 0)
    boxFill.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    boxFill.BackgroundTransparency = 0.85
    boxFill.BorderSizePixel = 0
    boxFill.ZIndex = 0

    local hpBg = Instance.new("Frame", box)
    hpBg.Size = UDim2.new(0, 3, 1, 0)
    hpBg.Position = UDim2.new(0, -7, 0, 0)
    hpBg.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    hpBg.BorderSizePixel = 0

    local hpFill = Instance.new("Frame", hpBg)
    hpFill.Size = UDim2.new(1, 0, 0.85, 0)
    hpFill.Position = UDim2.new(0, 0, 0.15, 0)
    hpFill.BackgroundColor3 = Theme.Success
    hpFill.BorderSizePixel = 0

    local name = Instance.new("TextLabel", box)
    name.Size = UDim2.new(1, 0, 0, 15)
    name.Position = UDim2.new(0, 0, 0, -18)
    name.BackgroundTransparency = 1
    name.Text = "ENEMY TARGET"
    name.TextColor3 = Color3.new(1,1,1)
    name.Font = Theme.FontBold
    name.TextSize = 10.5
    name.TextStrokeTransparency = 0.5

    local wep = Instance.new("TextLabel", box)
    wep.Size = UDim2.new(1, 0, 0, 15)
    wep.Position = UDim2.new(0, 0, 1, 2)
    wep.BackgroundTransparency = 1
    wep.Text = "[RIFLE_AK47]"
    wep.TextColor3 = Theme.SubText
    wep.Font = Theme.FontCode
    wep.TextSize = 9.5
    wep.TextStrokeTransparency = 0.5

    local flagDist = Instance.new("TextLabel", box)
    flagDist.Size = UDim2.new(0, 40, 0, 12)
    flagDist.Position = UDim2.new(1, 6, 0, 0)
    flagDist.BackgroundTransparency = 1
    flagDist.Text = "14M"
    flagDist.TextColor3 = Theme.SubText
    flagDist.Font = Theme.FontCode
    flagDist.TextSize = 9.5
    flagDist.TextXAlignment = Enum.TextXAlignment.Left

    local flagHP = Instance.new("TextLabel", box)
    flagHP.Size = UDim2.new(0, 40, 0, 12)
    flagHP.Position = UDim2.new(1, 6, 0, 13)
    flagHP.BackgroundTransparency = 1
    flagHP.Text = "85HP"
    flagHP.TextColor3 = Theme.Success
    flagHP.Font = Theme.FontCode
    flagHP.TextSize = 9.5
    flagHP.TextXAlignment = Enum.TextXAlignment.Left

    local flagAct = Instance.new("TextLabel", box)
    flagAct.Size = UDim2.new(0, 40, 0, 12)
    flagAct.Position = UDim2.new(1, 6, 0, 26)
    flagAct.BackgroundTransparency = 1
    flagAct.Text = "ARMOR"
    flagAct.TextColor3 = Color3.fromRGB(245, 158, 11)
    flagAct.Font = Theme.FontCode
    flagAct.TextSize = 9.5
    flagAct.TextXAlignment = Enum.TextXAlignment.Left

    local tracer = Instance.new("Frame", esp)
    tracer.Size = UDim2.new(0, 1, 0, 80)
    tracer.Position = UDim2.new(0, 0, 0, 155)
    tracer.AnchorPoint = Vector2.new(0.5, 1)
    tracer.BorderSizePixel = 0

    local headDotOut = Instance.new("Frame", esp)
    headDotOut.Size = UDim2.new(0, 7, 0, 7)
    headDotOut.Position = head.Position
    headDotOut.AnchorPoint = Vector2.new(0.5, 0.5)
    headDotOut.BackgroundColor3 = Color3.new(0, 0, 0)
    headDotOut.BorderSizePixel = 0
    Instance.new("UICorner", headDotOut).CornerRadius = UDim.new(0, 2)

    local headDot = Instance.new("Frame", esp)
    headDot.Size = UDim2.new(0, 5, 0, 5)
    headDot.Position = head.Position
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.ZIndex = 2
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(0, 1)

    UpdatePreviewEvent.Event:Connect(function()
        box.Visible = config.toggles.boxes
        boxFill.Visible = config.toggles.esp_box_fill and config.toggles.boxes
        boxFill.BackgroundTransparency = (100 - (config.sliders.esp_fill_alpha or 15)) / 100
        hpBg.Visible = config.toggles.healthbars
        name.Visible = config.toggles.names
        wep.Visible = config.toggles.weapons
        tracer.Visible = config.toggles.tracers
        headDot.Visible = config.toggles.head_dots
        headDotOut.Visible = config.toggles.head_dots and config.toggles.esp_head_outline
        chams.Visible = config.toggles.chams
        skeletonLines.Visible = config.toggles.skeletons
        
        flagDist.Visible = config.toggles.esp_flags and config.toggles.distances
        flagHP.Visible = config.toggles.esp_flags and config.toggles.healthtext
        flagAct.Visible = config.toggles.esp_flags

        boxStr.Color = config.colors.enemy_esp
        tracer.BackgroundColor3 = config.colors.enemy_esp
        headDot.BackgroundColor3 = config.colors.enemy_esp
        chams.BackgroundColor3 = config.colors.chams_fill
        for _, l in ipairs(skelParts) do l.BackgroundColor3 = ESP_COLORS.Skeleton end
    end)
    
    return frame
end

-- ==========================================
-- 11. INICJALIZACJA ZAKŁADEK I OPCJI MENU
-- ==========================================
CreateCategory("Targeting")
local colsAim = CreateTab("Legitbot", "01", true)

CreateCategory("Visuals")
local colsVis = CreateTab("ESP Overlay", "02", false)
local colsWorld = CreateTab("World & Cam", "03", false)

CreateCategory("Entities")
local colsPlayers = CreateTab("Player List", "04", false)

CreateCategory("Movement")
local colsMisc = CreateTab("Locomotion", "05", false)

CreateCategory("Customization")
local colsThemes = CreateTab("Visual Themes", "06", false)

CreateCategory("System")
local colsSet = CreateTab("Configuration", "07", false)

-- 1. ZAKŁADKA COMBAT (AIMBOT)
local aSec1 = CreateSection(colsAim.Left, "Target Acquisition")
CreateToggle(aSec1, "Enable Aimbot", config.toggles, "aim_enabled")
CreateKeybind(aSec1, "Activation Key", config.keybinds, "aimbot")
CreateToggle(aSec1, "Draw FOV Circle", config.toggles, "aim_showFov")
CreateSlider(aSec1, "Field Of View", config.sliders, "aim_fov", 10, 500)
CreateToggle(aSec1, "Raycast Wall Check", config.toggles, "aim_wallCheck")
CreateToggle(aSec1, "Linear Prediction", config.toggles, "aim_predict")
CreateSlider(aSec1, "Prediction Multiplier", config.sliders, "aim_pred_amt", 1, 30)

local aSec3 = CreateSection(colsAim.Left, "Triggerbot Automation")
CreateToggle(aSec3, "Enable Triggerbot", config.toggles, "triggerbot")
CreateToggle(aSec3, "Wall Verification", config.toggles, "trigger_wallCheck")
CreateSlider(aSec3, "Reaction Delay (ms)", config.sliders, "trigger_delay", 0, 500)

local aSecOptics = CreateSection(colsAim.Left, "Optics & Target HUD")
CreateToggle(aSecOptics, "Dual-Ring FOV Lens", config.toggles, "aim_fov_shadow")
CreateToggle(aSecOptics, "FOV Calibration Ticks", config.toggles, "aim_fov_ticks")
CreateToggle(aSecOptics, "Target Lock Reticle", config.toggles, "aim_lock_indicator")
CreateToggle(aSecOptics, "Target Telemetry Chip", config.toggles, "aim_target_info")

local aSec2 = CreateSection(colsAim.Right, "Hitbox & Interpolation")
CreateDropdown(aSec2, "Target Hitbox", config.selectors, "aim_part", {"Head", "Torso", "Root"})
CreateDropdown(aSec2, "Aim Vector Mode", config.selectors, "aim_method", {"Mouse Movement", "Camera Snap"})
CreateSlider(aSec2, "Smooth Interpolation", config.sliders, "aim_smooth", 1, 20)
CreateSlider(aSec2, "Crosshair Offset X", config.sliders, "aim_offsetX", -100, 100)
CreateSlider(aSec2, "Crosshair Offset Y", config.sliders, "aim_offsetY", -100, 100)
CreateToggle(aSec2, "Point Blank Snap", config.toggles, "aim_autoSnapClose")
CreateSlider(aSec2, "Snap Radius (Studs)", config.sliders, "aim_snapDistance", 5, 50)

local aSec4 = CreateSection(colsAim.Right, "Entity Filtering")
CreateToggle(aSec4, "Ignore Friendly Team", config, "teamCheck")
CreateSlider(aSec4, "Maximum Range", config.sliders, "aim_distance", 100, 4000)

-- 2. ZAKŁADKA VISUALS (ESP)
local vSecPreview = CreateSection(colsVis.Left, "Simulation Radar")
Build2DPreview(vSecPreview)

local vSecStyles = CreateSection(colsVis.Left, "Geometry Formatting")
CreateDropdown(vSecStyles, "Box Geometry", config.selectors, "box_style", {"Corner Box", "Full Box"})
CreateToggle(vSecStyles, "Outlined Box Stroke", config.toggles, "esp_box_outline")
CreateToggle(vSecStyles, "Glass Box Tint Fill", config.toggles, "esp_box_fill")
CreateSlider(vSecStyles, "Tint Opacity (%)", config.sliders, "esp_fill_alpha", 5, 50)
CreateToggle(vSecStyles, "Tactical Side Flags", config.toggles, "esp_flags")
CreateToggle(vSecStyles, "Outlined Head Dot", config.toggles, "esp_head_outline")
CreateToggle(vSecStyles, "Dynamic Health Gradient", config.toggles, "esp_hp_dynamic")
CreateDropdown(vSecStyles, "Distance Metric", config.selectors, "esp_dist_metric", {"Meters (m)", "Studs"})

local vSecToggle = CreateSection(colsVis.Right, "Render Components")
CreateToggle(vSecToggle, "Master ESP Switch", config, "esp_enabled")
CreateSlider(vSecToggle, "Max Render Distance", config.sliders, "esp_distance", 50, 5000)
CreateToggle(vSecToggle, "Bounding Box", config.toggles, "boxes")
CreateToggle(vSecToggle, "Health Bar Indicator", config.toggles, "healthbars")
CreateToggle(vSecToggle, "Health Digits", config.toggles, "healthtext")
CreateToggle(vSecToggle, "Entity Tag", config.toggles, "names")
CreateToggle(vSecToggle, "Equipped Weapon", config.toggles, "weapons")
CreateToggle(vSecToggle, "Distance Meter", config.toggles, "distances")
CreateToggle(vSecToggle, "Bones / Skeletal Mesh", config.toggles, "skeletons")
CreateToggle(vSecToggle, "Snapline Tracers", config.toggles, "tracers")
CreateDropdown(vSecToggle, "Snapline Anchor", config.selectors, "tracer_origin", {"Bottom", "Center", "Mouse"})
CreateToggle(vSecToggle, "Head Dot Reticle", config.toggles, "head_dots")
CreateToggle(vSecToggle, "Chams Occlusion", config.toggles, "chams")
CreateToggle(vSecToggle, "Offscreen Arrows", config.toggles, "offscreen_arrows")

local vSecColors = CreateSection(colsVis.Right, "Palette Config")
CreateColorPicker(vSecColors, "Enemy ESP Stroke", config.colors, "enemy_esp")
CreateColorPicker(vSecColors, "Chams Fill Tone", config.colors, "chams_fill")
CreateColorPicker(vSecColors, "Chams Outer Wire", config.colors, "chams_outline")

-- 3. ZAKŁADKA WORLD & CAMERA
local wSec1 = CreateSection(colsWorld.Left, "Atmosphere Modulation")
CreateToggle(wSec1, "Override Environment", config.toggles, "world_enabled")
CreateSlider(wSec1, "Luminance Scale", config.sliders, "brightness", 0, 100)
CreateSlider(wSec1, "Exposure Bias", config.sliders, "exposure", -50, 50)
CreateToggle(wSec1, "Global Dynamic Shadows", config.toggles, "shadows_enabled")
CreateColorPicker(wSec1, "Ambient Lighting", config.colors, "ambient_color")
CreateColorPicker(wSec1, "Outdoor Ambient", config.colors, "outdoor_ambient")

local wSecCam = CreateSection(colsWorld.Left, "Optics & Perspective")
CreateToggle(wSecCam, "Custom Viewport FOV", config.toggles, "fov_changer")
CreateSlider(wSecCam, "Field Of View", config.sliders, "custom_fov", 60, 120)
CreateToggle(wSecCam, "Force Third Person", config.toggles, "third_person")
CreateToggle(wSecCam, "Smooth Scope Zoom", config.toggles, "zoom_enabled")
CreateKeybind(wSecCam, "Zoom Trigger Key", config.keybinds, "zoom")
CreateSlider(wSecCam, "Magnified FOV", config.sliders, "zoom_fov", 10, 60)

local wSec2 = CreateSection(colsWorld.Right, "Volumetric Fog")
CreateToggle(wSec2, "Override Fog Engine", config.toggles, "fog_enabled")
CreateColorPicker(wSec2, "Fog Tint", config.colors, "fog_color")
CreateSlider(wSec2, "Fog Start Distance", config.sliders, "fog_start", 0, 1000)
CreateSlider(wSec2, "Fog Falloff End", config.sliders, "fog_end", 0, 10000)

local wSec3 = CreateSection(colsWorld.Right, "Celestial Simulation")
CreateToggle(wSec3, "Custom Clock Time", config.toggles, "time_changer")
CreateSlider(wSec3, "Solar Hour", config.sliders, "custom_time", 0, 24)

-- 4. ZAKŁADKA PLAYERS
local pSec1 = CreateSection(colsPlayers.Left, "Entity Directory")

local SearchBarContainer = Instance.new("Frame", pSec1)
SearchBarContainer.Size = UDim2.new(1, 0, 0, 28)
SearchBarContainer.BackgroundColor3 = Theme.ItemBg
SearchBarContainer.LayoutOrder = GetNextLayoutOrder()
Instance.new("UICorner", SearchBarContainer).CornerRadius = UDim.new(0, 3)
local sbStroke = Instance.new("UIStroke", SearchBarContainer)
sbStroke.Color = Theme.Border

local SearchBar = Instance.new("TextBox", SearchBarContainer)
SearchBar.Size = UDim2.new(1, -16, 1, 0)
SearchBar.Position = UDim2.new(0, 8, 0, 0)
SearchBar.BackgroundTransparency = 1
SearchBar.Text = ""
SearchBar.PlaceholderText = "Search player identity..."
SearchBar.TextColor3 = Theme.Text
SearchBar.PlaceholderColor3 = Theme.MutedText
SearchBar.Font = Theme.FontCode
SearchBar.TextSize = 10.5
SearchBar.TextXAlignment = Enum.TextXAlignment.Left

local PlayerListContainer = Instance.new("Frame", pSec1)
PlayerListContainer.Size = UDim2.new(1, 0, 0, 270)
PlayerListContainer.BackgroundColor3 = Theme.ItemBg
PlayerListContainer.LayoutOrder = GetNextLayoutOrder()
Instance.new("UICorner", PlayerListContainer).CornerRadius = UDim.new(0, 4)
local plStroke = Instance.new("UIStroke", PlayerListContainer)
plStroke.Color = Theme.Border

local PlayerScroll = Instance.new("ScrollingFrame", PlayerListContainer)
PlayerScroll.Size = UDim2.new(1, -8, 1, -8)
PlayerScroll.Position = UDim2.new(0, 4, 0, 4)
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.ScrollBarThickness = 2
PlayerScroll.ScrollBarImageColor3 = Theme.BorderLight
local PLayout = Instance.new("UIListLayout", PlayerScroll)
PLayout.Padding = UDim.new(0, 3)
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
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3 = config.selectedPlayer == p and Theme.ItemHover or Theme.GroupboxBg
        btn.Text = "  " .. p.Name .. (config.whitelist[p.Name] and " [WHITELIST]" or "")
        btn.TextColor3 = config.selectedPlayer == p and config.colors.ui_accent or Theme.Text
        btn.Font = Theme.FontCode
        btn.TextSize = 10.5
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
        local bStr = Instance.new("UIStroke", btn)
        bStr.Color = config.selectedPlayer == p and config.colors.ui_accent or Theme.Border
        bStr.Thickness = 1
        
        if config.selectedPlayer == p then 
            ApplyAccent(btn, "TextColor3") 
            ApplyAccent(bStr, "Color")
        end

        btn.MouseButton1Click:Connect(function()
            config.selectedPlayer = p
            RefreshPlayerList()
            if SelectedLabel then SelectedLabel.Text = "TARGET: " .. string.upper(p.Name) end
            if WhitelistBtn then
                WhitelistBtn.Text = config.whitelist[p.Name] and "REVOKE WHITELIST" or "GRANT WHITELIST"
            end
        end)
    end
    FilterPlayers()
end
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(p) 
    if config.selectedPlayer == p then config.selectedPlayer = nil end 
    RefreshPlayerList() 
end)

local pSec2 = CreateSection(colsPlayers.Right, "Entity Interactions")
SelectedLabel = Instance.new("TextLabel", pSec2)
SelectedLabel.Size = UDim2.new(1, 0, 0, 18)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "TARGET: NONE"
SelectedLabel.TextColor3 = Theme.SubText
SelectedLabel.Font = Theme.FontCode
SelectedLabel.TextSize = 10.5
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.LayoutOrder = GetNextLayoutOrder()

WhitelistBtn = CreateButton(pSec2, "TOGGLE WHITELIST", Theme.ItemBg, function()
    if config.selectedPlayer then
        if config.whitelist[config.selectedPlayer.Name] then
            config.whitelist[config.selectedPlayer.Name] = nil
        else
            config.whitelist[config.selectedPlayer.Name] = true
        end
        RefreshPlayerList()
        WhitelistBtn.Text = config.whitelist[config.selectedPlayer.Name] and "REVOKE WHITELIST" or "GRANT WHITELIST"
    end
end)

CreateButton(pSec2, "TELEPORT BEHIND TARGET", Theme.ItemBg, function()
    if config.selectedPlayer and config.selectedPlayer.Character and config.selectedPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetCFrame = config.selectedPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 4)
    end
end)

CreateButton(pSec2, "SPECTATE TARGET", Theme.ItemBg, function()
    if config.selectedPlayer and config.selectedPlayer.Character and config.selectedPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = config.selectedPlayer.Character.Humanoid
    end
end)

CreateButton(pSec2, "RESTORE SELF VIEW", Theme.ItemBg, function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end)

RefreshPlayerList()

-- 5. ZAKŁADKA MOVEMENT
local mSec2 = CreateSection(colsMisc.Left, "Kinetic Alterations")
CreateToggle(mSec2, "Continuous Bunny Hop", config.toggles, "bhop")
CreateDropdown(mSec2, "Flight Propulsion Mode", config.selectors, "fly_method", {"Platform", "CFrame", "Velocity"})
CreateToggle(mSec2, "Activate Flight", config.toggles, "fly")
CreateKeybind(mSec2, "Flight Hotkey", config.keybinds, "fly")
CreateSlider(mSec2, "Propulsion Velocity", config.sliders, "fly_speed", 10, 200)
CreateToggle(mSec2, "Geometry Passthrough (Noclip)", config.toggles, "noclip")

local mSec3 = CreateSection(colsMisc.Right, "Entity Physics")
CreateToggle(mSec3, "Custom Velocity Multiplier", config.toggles, "walkspeed_enabled")
CreateSlider(mSec3, "WalkSpeed Limit", config.sliders, "walkspeed_val", 16, 250)
CreateToggle(mSec3, "Custom Jump Impulse", config.toggles, "jumppower_enabled")
CreateSlider(mSec3, "JumpPower Limit", config.sliders, "jumppower_val", 50, 300)
CreateToggle(mSec3, "Infinite Vertical Jump", config.toggles, "inf_jump")
CreateToggle(mSec3, "Angular Desync (Spinbot)", config.toggles, "spinbot")
CreateSlider(mSec3, "Rotation Speed", config.sliders, "spinbot_speed", 1, 50)

-- 6. ZAKŁADKA CUSTOMIZATION (THEMES & HUD)
local tSecPresets = CreateSection(colsThemes.Left, "Curated Color Themes")
for _, preset in ipairs(THEME_PRESETS) do
    local pBtn = Instance.new("TextButton", tSecPresets)
    pBtn.Size = UDim2.new(1, 0, 0, 26)
    pBtn.BackgroundColor3 = Theme.ItemBg
    pBtn.Text = "      " .. string.upper(preset.Name)
    pBtn.TextColor3 = Theme.Text
    pBtn.Font = Theme.FontCode
    pBtn.TextSize = 10
    pBtn.TextXAlignment = Enum.TextXAlignment.Left
    pBtn.LayoutOrder = GetNextLayoutOrder()
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 3)
    local pStr = Instance.new("UIStroke", pBtn)
    pStr.Color = Theme.Border
    pStr.Thickness = 1
    
    local swatch = Instance.new("Frame", pBtn)
    swatch.Size = UDim2.new(0, 10, 0, 10)
    swatch.Position = UDim2.new(0, 10, 0.5, -5)
    swatch.BackgroundColor3 = preset.Color
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 2)
    
    pBtn.MouseEnter:Connect(function() Tween(pBtn, {BackgroundColor3 = Theme.ItemHover}) end)
    pBtn.MouseLeave:Connect(function() Tween(pBtn, {BackgroundColor3 = Theme.ItemBg}) end)
    pBtn.MouseButton1Click:Connect(function()
        config.colors.ui_accent = preset.Color
        UpdateAccents()
        RefreshAccentGradient()
        UpdatePreviewEvent:Fire()
        PlayUiSound("click")
    end)
end
CreateColorPicker(tSecPresets, "Custom Accent Tone", config.colors, "ui_accent")

local tSecHud = CreateSection(colsThemes.Left, "Viewport Telemetry & HUD")
CreateToggle(tSecHud, "Watermark Capsule", config.toggles, "watermark")
CreateToggle(tSecHud, "Active Keybinds HUD", config.toggles, "keybinds_hud")
CreateToggle(tSecHud, "Mechanical Audio Feedback", config.toggles, "ui_sounds")

local tSecCross = CreateSection(colsThemes.Right, "Crosshair Geometry")
CreateToggle(tSecCross, "Hardware Crosshair", config.toggles, "aim_crosshair")
CreateDropdown(tSecCross, "Reticle Style", config.selectors, "crosshair_style", {"Classic Plus", "Dot Only", "T-Shape", "Circle Reticle"})
CreateSlider(tSecCross, "Reticle Size", config.sliders, "crosshair_size", 2, 25)
CreateSlider(tSecCross, "Reticle Gap", config.sliders, "crosshair_gap", 0, 20)
CreateSlider(tSecCross, "Line Thickness", config.sliders, "crosshair_thick", 1, 5)
CreateToggle(tSecCross, "Rainbow Chromatic Cycle", config.toggles, "rainbow_crosshair")
CreateToggle(tSecCross, "Center Point Dot", config.toggles, "crosshair_dot")
CreateToggle(tSecCross, "Contrast Black Outline", config.toggles, "crosshair_outline")

-- 7. ZAKŁADKA SETTINGS
local sSec1 = CreateSection(colsSet.Left, "Keybinds & Layout")
CreateKeybind(sSec1, "Interface Hotkey", config.keybinds, "menu")
CreateButton(sSec1, "RESET VIEWPORT POSITION", Theme.ItemBg, function()
    DragContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    KeybindsHUD.Position = UDim2.new(0, 20, 0.45, 0)
end)

local sSec2 = CreateSection(colsSet.Right, "System Management")
CreateButton(sSec2, "COPY CONFIGURATION (JSON)", Theme.ItemBg, function()
    pcall(function()
        local data = {
            toggles = config.toggles,
            sliders = config.sliders,
            selectors = config.selectors
        }
        local json = HttpService:JSONEncode(data)
        if setclipboard then 
            setclipboard(json) 
            print("ASAPWARE: Configuration dumped to clipboard.")
        else
            print("ASAPWARE DUMP: " .. json)
        end
    end)
end)

CreateButton(sSec2, "TERMINATE INSTANCE (UNLOAD)", Theme.Danger, function()
    local genv = (getgenv and getgenv()) or _G
    if genv.AsapwareUnload then genv.AsapwareUnload() end
end)

UpdatePreviewEvent:Fire()
UpdateAccents()

-- ==========================================
-- 12. PŁYNNA ANIMACJA OTWIERANIA / ZAMYKANIA
-- ==========================================
local UIScale = Instance.new("UIScale", DragContainer)
UIScale.Scale = 1
local menuOpen = true
DragContainer.Visible = true
DragContainer.GroupTransparency = 0
DragContainer.Interactable = true

local function ToggleMenu()
    menuOpen = not menuOpen
    PlayUiSound("click")
    if menuOpen then
        DragContainer.Visible = true
        DragContainer.Interactable = true
        UIScale.Scale = 0.94
        Tween(UIScale, {Scale = 1}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        Tween(DragContainer, {GroupTransparency = 0}, 0.16)
    else
        DragContainer.Interactable = false
        Tween(UIScale, {Scale = 0.96}, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Tween(DragContainer, {GroupTransparency = 1}, 0.15)
        task.delay(0.15, function() 
            if not menuOpen then 
                DragContainer.Visible = false 
            end 
        end)
    end
end

CloseBtn.MouseButton1Click:Connect(ToggleMenu)
MinBtn.MouseButton1Click:Connect(ToggleMenu)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == config.keybinds.menu then ToggleMenu() end
    if config.keybinds.fly and (input.KeyCode == config.keybinds.fly or input.UserInputType == config.keybinds.fly) then
        config.toggles.fly = not config.toggles.fly
        PlayUiSound("toggle")
    end
end)

-- ==========================================
-- 13. LOGIKA ESP, DRAWING & CROSSHAIR ENGINE
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

-- Dual-Ring FOV Optical Lens & Calibration Ticks
local FOV_Shadow = CreateDraw("Circle", {Thickness = 2.8, Color = Color3.fromRGB(10, 12, 16), Filled = false, Transparency = 0.5})
local FOV_Circle = CreateDraw("Circle", {Thickness = 1.2, Color = config.colors.ui_accent, Filled = false})
local FOV_TickTop = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local FOV_TickBot = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local FOV_TickLeft = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local FOV_TickRight = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})

-- Target Lock-On HUD Brackets & Telemetry Tag
local AimLock1 = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local AimLock2 = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local AimLock3 = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local AimLock4 = CreateDraw("Line", {Thickness = 1.5, Color = config.colors.ui_accent})
local AimLockTag = CreateDraw("Text", {Center = true, Outline = true, Font = 3, Size = 11, Color = Color3.fromRGB(240, 243, 252)})

-- Outlined Crosshair Shadow Lines
local CrossTop_O = CreateDraw("Line", {Thickness = 4, Color = Color3.new(0, 0, 0)})
local CrossBot_O = CreateDraw("Line", {Thickness = 4, Color = Color3.new(0, 0, 0)})
local CrossLeft_O = CreateDraw("Line", {Thickness = 4, Color = Color3.new(0, 0, 0)})
local CrossRight_O = CreateDraw("Line", {Thickness = 4, Color = Color3.new(0, 0, 0)})
local CrossCircle_O = CreateDraw("Circle", {Filled = false, Thickness = 3.5, Radius = 10, Color = Color3.new(0, 0, 0)})
local CrossDot_O = CreateDraw("Circle", {Filled = true, Radius = 3.5, Color = Color3.new(0, 0, 0)})

local CrossTop = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossBot = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossLeft = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossRight = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossDot = CreateDraw("Circle", {Filled = true, Radius = 2, Color = config.colors.ui_accent})
local CrossCircle = CreateDraw("Circle", {Filled = false, Thickness = 1.5, Radius = 10, Color = config.colors.ui_accent})

table.insert(UIThemeObjects, {Obj = FOV_Circle, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = FOV_TickTop, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = FOV_TickBot, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = FOV_TickLeft, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = FOV_TickRight, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = AimLock1, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = AimLock2, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = AimLock3, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = AimLock4, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossTop, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossBot, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossLeft, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossRight, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossDot, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossCircle, Prop = "Color"})

local function SetupESP(player)
    if ESP_Data[player] then return end
    if ChamsSupported then
        local chams = Instance.new("Highlight")
        chams.Name = generateRandomName(12)
        chams.Enabled = false
        pcall(function() chams.Parent = TargetGui end)
        HighlightInstances[player] = chams
    end
    ESP_Data[player] = {
        BoxFill = CreateDraw("Square", {Filled = true, Transparency = 0.85, Color = Color3.fromRGB(8, 9, 13)}),
        TopLeft1 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        TopLeft2 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        TopRight1 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        TopRight2 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        BottomLeft1 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        BottomLeft2 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        BottomRight1 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        BottomRight2 = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Outline}),
        TopLeft1_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        TopLeft2_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        TopRight1_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        TopRight2_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        BottomLeft1_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        BottomLeft2_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        BottomRight1_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        BottomRight2_O = CreateDraw("Line", {Thickness = 3, Color = Color3.new(0, 0, 0)}),
        HealthOutline = CreateDraw("Square", {Filled = true, Color = ESP_COLORS.Outline}),
        HealthBar = CreateDraw("Square", {Filled = true}),
        HealthText = CreateDraw("Text", {Center = true, Outline = true, Font = 3, Size = 11, Color = Color3.fromRGB(240, 243, 252)}),
        Name = CreateDraw("Text", {Center = true, Outline = true, Font = 3, Size = 12, Color = Color3.fromRGB(240, 243, 252)}),
        Distance = CreateDraw("Text", {Center = true, Outline = true, Font = 3, Size = 11, Color = Theme.SubText}),
        Weapon = CreateDraw("Text", {Center = true, Outline = true, Font = 3, Size = 11, Color = Color3.fromRGB(180, 185, 205)}),
        Tracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.5}),
        HeadDot_O = CreateDraw("Circle", {Filled = true, Transparency = 0.8, Radius = 4, Color = Color3.new(0, 0, 0)}),
        HeadDot = CreateDraw("Circle", {Filled = true, Transparency = 1, Radius = 2.5}),
        ViewTracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.8}),
        OffscreenArrow = CreateDraw("Triangle", {Filled = true, Transparency = 0.8, Color = ESP_COLORS.Arrow}),
        FlagDist = CreateDraw("Text", {Center = false, Outline = true, Font = 3, Size = 11, Color = Theme.SubText}),
        FlagHP = CreateDraw("Text", {Center = false, Outline = true, Font = 3, Size = 11, Color = Theme.Success}),
        FlagAction = CreateDraw("Text", {Center = false, Outline = true, Font = 3, Size = 11, Color = Color3.fromRGB(245, 158, 11)}),
        FlagState = CreateDraw("Text", {Center = false, Outline = true, Font = 3, Size = 11, Color = Color3.fromRGB(230, 46, 67)}),
        SkeletonLines = {}
    }
    for i = 1, 15 do
        table.insert(ESP_Data[player].SkeletonLines, CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Skeleton, Transparency = 1}))
    end
end

local function RemoveESP(player) 
    if ESP_Data[player] then 
        for k, v in pairs(ESP_Data[player]) do
            if k == "SkeletonLines" then 
                for _, l in ipairs(v) do pcall(function() l.Visible = false l:Remove() end) end
            else 
                pcall(function() v.Visible = false v:Remove() end) 
            end
        end
        ESP_Data[player] = nil 
    end 
    if HighlightInstances[player] then 
        pcall(function() HighlightInstances[player]:Destroy() end) 
        HighlightInstances[player] = nil 
    end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
Players.PlayerAdded:Connect(SetupESP)
Players.PlayerRemoving:Connect(RemoveESP)

local NoclipConnection = RunService.Stepped:Connect(function()
    if config.toggles.noclip and LocalPlayer.Character and ScriptLoaded then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then 
                part.CanCollide = false 
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if config.toggles.inf_jump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
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
    local result = Workspace:Raycast(origin, (targetPart.Position - origin), GlobalRaycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- ==========================================
-- 14. GŁÓWNA PĘTLA RENDEROWANIA (ZERO-GARBAGE)
-- ==========================================
local lastTrigger = 0
local lastHrpCheck = 0

local cachedLighting = {
    ClockTime = -1, Brightness = -1, Exposure = -1, Shadows = nil,
    Ambient = nil, Outdoor = nil, FogColor = nil, FogStart = -1, FogEnd = -1
}

local function UpdateLighting()
    local targetTime = config.toggles.time_changer and config.sliders.custom_time or origLighting.ClockTime
    if cachedLighting.ClockTime ~= targetTime then
        cachedLighting.ClockTime = targetTime
        Lighting.ClockTime = targetTime
    end

    if config.toggles.world_enabled then
        local b = config.sliders.brightness / 10
        if cachedLighting.Brightness ~= b then cachedLighting.Brightness = b; Lighting.Brightness = b end
        local exp = config.sliders.exposure / 10
        if cachedLighting.Exposure ~= exp then cachedLighting.Exposure = exp; Lighting.ExposureCompensation = exp end
        if cachedLighting.Shadows ~= config.toggles.shadows_enabled then 
            cachedLighting.Shadows = config.toggles.shadows_enabled
            Lighting.GlobalShadows = config.toggles.shadows_enabled 
        end
        if cachedLighting.Ambient ~= config.colors.ambient_color then
            cachedLighting.Ambient = config.colors.ambient_color
            Lighting.Ambient = config.colors.ambient_color
        end
        if cachedLighting.Outdoor ~= config.colors.outdoor_ambient then
            cachedLighting.Outdoor = config.colors.outdoor_ambient
            Lighting.OutdoorAmbient = config.colors.outdoor_ambient
        end
    else
        if cachedLighting.Brightness ~= origLighting.Brightness then
            cachedLighting.Brightness = origLighting.Brightness; Lighting.Brightness = origLighting.Brightness
        end
        if cachedLighting.Exposure ~= origLighting.ExposureCompensation then
            cachedLighting.Exposure = origLighting.ExposureCompensation; Lighting.ExposureCompensation = origLighting.ExposureCompensation
        end
        if cachedLighting.Shadows ~= origLighting.GlobalShadows then
            cachedLighting.Shadows = origLighting.GlobalShadows; Lighting.GlobalShadows = origLighting.GlobalShadows
        end
        if cachedLighting.Ambient ~= origLighting.Ambient then
            cachedLighting.Ambient = origLighting.Ambient; Lighting.Ambient = origLighting.Ambient
        end
        if cachedLighting.Outdoor ~= origLighting.OutdoorAmbient then
            cachedLighting.Outdoor = origLighting.OutdoorAmbient; Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        end
    end

    if config.toggles.fog_enabled then
        if cachedLighting.FogColor ~= config.colors.fog_color then
            cachedLighting.FogColor = config.colors.fog_color; Lighting.FogColor = config.colors.fog_color
        end
        if cachedLighting.FogStart ~= config.sliders.fog_start then
            cachedLighting.FogStart = config.sliders.fog_start; Lighting.FogStart = config.sliders.fog_start
        end
        if cachedLighting.FogEnd ~= config.sliders.fog_end then
            cachedLighting.FogEnd = config.sliders.fog_end; Lighting.FogEnd = config.sliders.fog_end
        end
    else
        if cachedLighting.FogColor ~= origLighting.FogColor then
            cachedLighting.FogColor = origLighting.FogColor; Lighting.FogColor = origLighting.FogColor
        end
        if cachedLighting.FogStart ~= origLighting.FogStart then
            cachedLighting.FogStart = origLighting.FogStart; Lighting.FogStart = origLighting.FogStart
        end
        if cachedLighting.FogEnd ~= origLighting.FogEnd then
            cachedLighting.FogEnd = origLighting.FogEnd; Lighting.FogEnd = origLighting.FogEnd
        end
    end
end

RunService:BindToRenderStep("AsapwareMain", Enum.RenderPriority.Camera.Value + 1, function()
    if not ScriptLoaded then return end

    local viewportSize = Camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
    local screenBottom = Vector2.new(viewportSize.X * 0.5, viewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    local camPos = Camera.CFrame.Position
    local nowTime = tick()

    UpdateLighting()

    -- Kamera i Płynny Zoom Optyczny
    local isZooming = false
    if config.toggles.zoom_enabled and config.keybinds.zoom then
        local zBind = config.keybinds.zoom
        if zBind.EnumType == Enum.KeyCode then
            isZooming = UserInputService:IsKeyDown(zBind)
        elseif zBind.EnumType == Enum.UserInputType then
            isZooming = UserInputService:IsMouseButtonPressed(zBind)
        end
    end

    if isZooming then
        Camera.FieldOfView = Camera.FieldOfView + (config.sliders.zoom_fov - Camera.FieldOfView) * 0.25
    else
        local targetFov = config.toggles.fov_changer and config.sliders.custom_fov or 70
        if math.abs(Camera.FieldOfView - targetFov) > 0.1 then
            Camera.FieldOfView = Camera.FieldOfView + (targetFov - Camera.FieldOfView) * 0.25
        end
    end

    if config.toggles.third_person then
        if LocalPlayer.CameraMaxZoomDistance ~= 12 then
            LocalPlayer.CameraMaxZoomDistance = 12
            LocalPlayer.CameraMinZoomDistance = 12
        end
    else
        if LocalPlayer.CameraMaxZoomDistance ~= 400 then
            LocalPlayer.CameraMaxZoomDistance = 400
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end

    if config.toggles.bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not config.toggles.fly then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
    end

    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if config.toggles.walkspeed_enabled then
                if hum.WalkSpeed ~= config.sliders.walkspeed_val then
                    hum.WalkSpeed = config.sliders.walkspeed_val
                end
            end
            if config.toggles.jumppower_enabled then
                if hum.UseJumpPower then
                    if hum.JumpPower ~= config.sliders.jumppower_val then
                        hum.JumpPower = config.sliders.jumppower_val
                    end
                else
                    local targetH = config.sliders.jumppower_val * 0.5
                    if hum.JumpHeight ~= targetH then
                        hum.JumpHeight = targetH
                    end
                end
            end
        end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and config.toggles.spinbot then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(config.sliders.spinbot_speed), 0)
        end
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
                    flyPlatform = Instance.new("Part")
                    flyPlatform.Name = flyPlatformName
                    flyPlatform.Size = Vector3.new(6, 1, 6)
                    flyPlatform.Transparency = 1
                    flyPlatform.Anchored = true
                    flyPlatform.CanCollide = true
                    pcall(function() flyPlatform.Parent = Workspace end)
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

    local fovRadius = config.sliders.aim_fov
    local showFov = config.toggles.aim_showFov and config.toggles.aim_enabled
    if FOV_Circle then
        FOV_Circle.Position = mouseLoc
        FOV_Circle.Radius = fovRadius
        FOV_Circle.Visible = showFov
    end
    if FOV_Shadow then
        FOV_Shadow.Position = mouseLoc
        FOV_Shadow.Radius = fovRadius
        FOV_Shadow.Visible = showFov and config.toggles.aim_fov_shadow
    end
    if FOV_TickTop then
        local showTicks = showFov and config.toggles.aim_fov_ticks
        FOV_TickTop.From = Vector2.new(mouseLoc.X, mouseLoc.Y - fovRadius - 5)
        FOV_TickTop.To = Vector2.new(mouseLoc.X, mouseLoc.Y - fovRadius + 4)
        FOV_TickBot.From = Vector2.new(mouseLoc.X, mouseLoc.Y + fovRadius - 4)
        FOV_TickBot.To = Vector2.new(mouseLoc.X, mouseLoc.Y + fovRadius + 5)
        FOV_TickLeft.From = Vector2.new(mouseLoc.X - fovRadius - 5, mouseLoc.Y)
        FOV_TickLeft.To = Vector2.new(mouseLoc.X - fovRadius + 4, mouseLoc.Y)
        FOV_TickRight.From = Vector2.new(mouseLoc.X + fovRadius - 4, mouseLoc.Y)
        FOV_TickRight.To = Vector2.new(mouseLoc.X + fovRadius + 5, mouseLoc.Y)
        FOV_TickTop.Visible = showTicks; FOV_TickBot.Visible = showTicks
        FOV_TickLeft.Visible = showTicks; FOV_TickRight.Visible = showTicks
    end

    -- Crosshair Engine Rendering (Outlined Precision)
    local showCross = config.toggles.aim_crosshair
    local crossClr = config.colors.ui_accent
    if config.toggles.rainbow_crosshair then
        crossClr = Color3.fromHSV((tick() * 0.4) % 1, 0.9, 1)
    end

    if CrossTop then
        local cSize = config.sliders.crosshair_size or 6
        local cGap = config.sliders.crosshair_gap or 4
        local cThick = config.sliders.crosshair_thick or 2
        local style = config.selectors.crosshair_style or 1
        local showOutline = config.toggles.crosshair_outline
        
        CrossTop.Thickness = cThick
        CrossBot.Thickness = cThick
        CrossLeft.Thickness = cThick
        CrossRight.Thickness = cThick
        CrossTop.Color = crossClr
        CrossBot.Color = crossClr
        CrossLeft.Color = crossClr
        CrossRight.Color = crossClr

        CrossTop.From = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap)
        CrossTop.To = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap - cSize)
        CrossBot.From = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap)
        CrossBot.To = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap + cSize)
        CrossLeft.From = Vector2.new(mouseLoc.X - cGap, mouseLoc.Y)
        CrossLeft.To = Vector2.new(mouseLoc.X - cGap - cSize, mouseLoc.Y)
        CrossRight.From = Vector2.new(mouseLoc.X + cGap, mouseLoc.Y)
        CrossRight.To = Vector2.new(mouseLoc.X + cGap + cSize, mouseLoc.Y)

        if CrossTop_O then
            CrossTop_O.From = CrossTop.From; CrossTop_O.To = CrossTop.To; CrossTop_O.Thickness = cThick + 2
            CrossBot_O.From = CrossBot.From; CrossBot_O.To = CrossBot.To; CrossBot_O.Thickness = cThick + 2
            CrossLeft_O.From = CrossLeft.From; CrossLeft_O.To = CrossLeft.To; CrossLeft_O.Thickness = cThick + 2
            CrossRight_O.From = CrossRight.From; CrossRight_O.To = CrossRight.To; CrossRight_O.Thickness = cThick + 2
        end

        if showCross then
            if style == 1 then -- Classic Plus
                CrossTop.Visible = true; CrossBot.Visible = true; CrossLeft.Visible = true; CrossRight.Visible = true
                CrossCircle.Visible = false
                if CrossTop_O then
                    CrossTop_O.Visible = showOutline; CrossBot_O.Visible = showOutline
                    CrossLeft_O.Visible = showOutline; CrossRight_O.Visible = showOutline
                    CrossCircle_O.Visible = false
                end
            elseif style == 2 then -- Dot Only
                CrossTop.Visible = false; CrossBot.Visible = false; CrossLeft.Visible = false; CrossRight.Visible = false
                CrossCircle.Visible = false
                if CrossTop_O then
                    CrossTop_O.Visible = false; CrossBot_O.Visible = false
                    CrossLeft_O.Visible = false; CrossRight_O.Visible = false
                    CrossCircle_O.Visible = false
                end
            elseif style == 3 then -- T-Shape
                CrossTop.Visible = false; CrossBot.Visible = true; CrossLeft.Visible = true; CrossRight.Visible = true
                CrossCircle.Visible = false
                if CrossTop_O then
                    CrossTop_O.Visible = false; CrossBot_O.Visible = showOutline
                    CrossLeft_O.Visible = showOutline; CrossRight_O.Visible = showOutline
                    CrossCircle_O.Visible = false
                end
            elseif style == 4 then -- Circle Reticle
                CrossTop.Visible = false; CrossBot.Visible = false; CrossLeft.Visible = false; CrossRight.Visible = false
                CrossCircle.Visible = true
                CrossCircle.Position = mouseLoc
                CrossCircle.Radius = cSize + cGap
                CrossCircle.Thickness = cThick
                CrossCircle.Color = crossClr
                if CrossTop_O then
                    CrossTop_O.Visible = false; CrossBot_O.Visible = false
                    CrossLeft_O.Visible = false; CrossRight_O.Visible = false
                    CrossCircle_O.Visible = showOutline
                    CrossCircle_O.Position = mouseLoc
                    CrossCircle_O.Radius = cSize + cGap
                    CrossCircle_O.Thickness = cThick + 2
                end
            end
            if CrossDot then
                CrossDot.Position = mouseLoc
                CrossDot.Radius = math.max(cThick, 2)
                CrossDot.Color = crossClr
                local dotVis = (style == 2 or config.toggles.crosshair_dot)
                CrossDot.Visible = dotVis
                if CrossDot_O then
                    CrossDot_O.Position = mouseLoc
                    CrossDot_O.Radius = math.max(cThick, 2) + 1
                    CrossDot_O.Visible = dotVis and showOutline
                end
            end
        else
            CrossTop.Visible = false; CrossBot.Visible = false; CrossLeft.Visible = false; CrossRight.Visible = false
            if CrossDot then CrossDot.Visible = false end
            if CrossCircle then CrossCircle.Visible = false end
            if CrossTop_O then
                CrossTop_O.Visible = false; CrossBot_O.Visible = false
                CrossLeft_O.Visible = false; CrossRight_O.Visible = false
                CrossCircle_O.Visible = false
                if CrossDot_O then CrossDot_O.Visible = false end
            end
        end
    end

    local isAiming = false
    local aBind = config.keybinds.aimbot
    if aBind and typeof(aBind) == "EnumItem" then
        if aBind.EnumType == Enum.KeyCode then isAiming = UserInputService:IsKeyDown(aBind)
        elseif aBind.EnumType == Enum.UserInputType then isAiming = UserInputService:IsMouseButtonPressed(aBind) end
    end

    local closestTarget = nil
    local closestPlayer = nil
    local shortestDist = math.huge
    local targetPhysicalDist = math.huge 

    if config.toggles.aim_enabled and isAiming then
        local playersList = Players:GetPlayers()
        for i = 1, #playersList do
            local player = playersList[i]
            if player == LocalPlayer then continue end
            if config.teamCheck and player.Team == LocalPlayer.Team then continue end
            if config.whitelist[player.Name] then continue end
            
            if player.Character then
                local hp = GetHealth(player)
                if hp > 0 then
                    local aimPart = GetAimPart(player.Character)
                    if aimPart then
                        local pDist = (camPos - aimPart.Position).Magnitude
                        if pDist <= config.sliders.aim_distance then
                            local targetPos = aimPart.Position
                            if config.toggles.aim_predict and aimPart.AssemblyLinearVelocity then
                                targetPos = targetPos + (aimPart.AssemblyLinearVelocity * (config.sliders.aim_pred_amt / 100))
                            end
                            local pos, onScreen = Camera:WorldToScreenPoint(targetPos)
                            if onScreen then
                                local finalTargetX = pos.X + config.sliders.aim_offsetX
                                local finalTargetY = pos.Y + config.sliders.aim_offsetY
                                
                                local sDist = (Vector2.new(finalTargetX, finalTargetY) - mouseLoc).Magnitude
                                if sDist <= config.sliders.aim_fov and sDist < shortestDist then
                                    if not config.toggles.aim_wallCheck or IsVisible(aimPart) then
                                        shortestDist = sDist
                                        closestTarget = targetPos
                                        closestPlayer = player
                                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                            targetPhysicalDist = (LocalPlayer.Character.HumanoidRootPart.Position - aimPart.Position).Magnitude
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if closestTarget then
            local smooth = config.sliders.aim_smooth
            if config.toggles.aim_autoSnapClose and targetPhysicalDist <= config.sliders.aim_snapDistance then
                smooth = 1
            end
            if config.selectors.aim_method == 1 and mousemoverel then
                local pos = Camera:WorldToScreenPoint(closestTarget)
                local finalX = pos.X + config.sliders.aim_offsetX
                local finalY = pos.Y + config.sliders.aim_offsetY
                mousemoverel((finalX - mouseLoc.X) / smooth, (finalY - mouseLoc.Y) / smooth)
            else 
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, closestTarget), 1 / smooth) 
            end
        end
    end

    -- Visual Target Acquisition Lock Reticle
    if closestTarget and config.toggles.aim_lock_indicator then
        local tPos, tOnScreen = Camera:WorldToViewportPoint(closestTarget)
        if tOnScreen and tPos.Z > 0 then
            local bSize = 12
            local bX, bY = tPos.X, tPos.Y
            AimLock1.From = Vector2.new(bX - bSize, bY - bSize); AimLock1.To = Vector2.new(bX - bSize + 5, bY - bSize)
            AimLock2.From = Vector2.new(bX + bSize, bY - bSize); AimLock2.To = Vector2.new(bX + bSize - 5, bY - bSize)
            AimLock3.From = Vector2.new(bX - bSize, bY + bSize); AimLock3.To = Vector2.new(bX - bSize + 5, bY + bSize)
            AimLock4.From = Vector2.new(bX + bSize, bY + bSize); AimLock4.To = Vector2.new(bX + bSize - 5, bY + bSize)
            AimLock1.Visible = true; AimLock2.Visible = true; AimLock3.Visible = true; AimLock4.Visible = true

            if config.toggles.aim_target_info and closestPlayer then
                local pDistStr = (config.selectors.esp_dist_metric == 2) and (math.floor(targetPhysicalDist) .. "S") or (math.floor(targetPhysicalDist * 0.28) .. "M")
                AimLockTag.Text = "[LOCK: " .. string.upper(closestPlayer.Name) .. " // " .. pDistStr .. "]"
                AimLockTag.Position = Vector2.new(bX, bY - bSize - 16)
                AimLockTag.Visible = true
            else
                AimLockTag.Visible = false
            end
        else
            AimLock1.Visible = false; AimLock2.Visible = false; AimLock3.Visible = false; AimLock4.Visible = false
            AimLockTag.Visible = false
        end
    else
        AimLock1.Visible = false; AimLock2.Visible = false; AimLock3.Visible = false; AimLock4.Visible = false
        AimLockTag.Visible = false
    end

    if config.toggles.triggerbot then
        local target = Mouse.Target
        if target and target.Parent then
            local player = Players:GetPlayerFromCharacter(target.Parent) or Players:GetPlayerFromCharacter(target.Parent.Parent)
            if player and player ~= LocalPlayer then
                local hp = GetHealth(player)
                local isEnemy = not config.teamCheck or player.Team ~= LocalPlayer.Team
                local notWhitelisted = not config.whitelist[player.Name]
                
                if hp > 0 and isEnemy and notWhitelisted then
                    local passWallCheck = true
                    if config.toggles.trigger_wallCheck then
                        local aimPart = GetAimPart(player.Character)
                        if aimPart then passWallCheck = IsVisible(aimPart) end
                    end
                    if passWallCheck then
                        if tick() - lastTrigger >= (config.sliders.trigger_delay / 1000) then
                            if mouse1click then mouse1click() end
                            lastTrigger = tick()
                        end
                    end
                end
            end
        end
    end

    if nowTime - lastHrpCheck >= 0.5 then
        lastHrpCheck = nowTime
        local pList = Players:GetPlayers()
        for i = 1, #pList do
            local p = pList[i]
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Size.X > 3 then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end

    -- Telemetria i HUD Keybinds
    frameCount = frameCount + 1
    if nowTime - lastTick >= 1 then
        currentFPS = math.floor(frameCount / (nowTime - lastTick))
        frameCount, lastTick = 0, nowTime
    end

    if nowTime - lastWatermarkUpdate > 0.4 then
        lastWatermarkUpdate = nowTime
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        
        if config.toggles.watermark then
            Watermark.Visible = true
            WmText.Text = "asapware.cc <font color='#4f5567'>|</font> " .. tostring(currentFPS) .. " fps <font color='#4f5567'>|</font> " .. tostring(ping) .. "ms <font color='#4f5567'>|</font> <font color='#4cd137'>release</font>"
        else 
            Watermark.Visible = false 
        end
    end

    if config.toggles.keybinds_hud then
        KeybindsHUD.Visible = true
        if nowTime - lastKhUpdate > 0.2 then
            lastKhUpdate = nowTime
            if KhRows.Aimbot then
                KhRows.Aimbot.Status.Text = isAiming and "[ACTIVE]" or "[IDLE]"
                KhRows.Aimbot.Status.TextColor3 = isAiming and config.colors.ui_accent or Theme.MutedText
            end
            if KhRows.Fly then
                KhRows.Fly.Status.Text = config.toggles.fly and "[ACTIVE]" or "[OFF]"
                KhRows.Fly.Status.TextColor3 = config.toggles.fly and Theme.Success or Theme.MutedText
            end
            if KhRows.Zoom then
                KhRows.Zoom.Status.Text = isZooming and "[ACTIVE]" or "[IDLE]"
                KhRows.Zoom.Status.TextColor3 = isZooming and config.colors.ui_accent or Theme.MutedText
            end
            if KhRows.Noclip then
                KhRows.Noclip.Status.Text = config.toggles.noclip and "[ACTIVE]" or "[OFF]"
                KhRows.Noclip.Status.TextColor3 = config.toggles.noclip and Theme.Success or Theme.MutedText
            end
            if KhRows.Menu then
                KhRows.Menu.Status.Text = menuOpen and "[OPEN]" or "[CLOSED]"
                KhRows.Menu.Status.TextColor3 = menuOpen and Theme.Text or Theme.MutedText
            end
        end
    else
        KeybindsHUD.Visible = false
    end

    local t_Thick = config.sliders.boxThickness
    local maxEspDist = config.sliders.esp_distance

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
                        dist = (camPos - root.Position).Magnitude
                    end
                end
            end
        end

        if isValidTarget then
            if HighlightInstances[player] then
                if config.toggles.chams and dist <= maxEspDist then
                    HighlightInstances[player].Adornee = char
                    HighlightInstances[player].FillColor = config.colors.chams_fill
                    HighlightInstances[player].OutlineColor = config.colors.chams_outline
                    HighlightInstances[player].Enabled = true
                else
                    HighlightInstances[player].Enabled = false
                end
            end

            if not onScreen and config.toggles.offscreen_arrows and dist <= maxEspDist then
                local targetVec = (root.Position - camPos).Unit
                local camYRot = math.atan2(Camera.CFrame.LookVector.X, Camera.CFrame.LookVector.Z)
                local targYRot = math.atan2(targetVec.X, targetVec.Z)
                local finalAngle = camYRot - targYRot
                local radius = config.sliders.arrow_radius
                local size = config.sliders.arrow_size
                local cX = screenCenter.X + math.sin(finalAngle) * radius
                local cY = screenCenter.Y - math.cos(finalAngle) * radius
                
                esp.OffscreenArrow.PointA = Vector2.new(cX + math.sin(finalAngle) * size, cY - math.cos(finalAngle) * size)
                esp.OffscreenArrow.PointB = Vector2.new(cX + math.sin(finalAngle + 2.5) * (size * 0.8), cY - math.cos(finalAngle + 2.5) * (size * 0.8))
                esp.OffscreenArrow.PointC = Vector2.new(cX + math.sin(finalAngle - 2.5) * (size * 0.8), cY - math.cos(finalAngle - 2.5) * (size * 0.8))
                esp.OffscreenArrow.Visible = true
            else
                esp.OffscreenArrow.Visible = false
            end

            if onScreen and pos.Z > 0 and dist <= maxEspDist then
                local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
                local botPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                local headPos = Camera:WorldToViewportPoint(head.Position)
                
                local boxH = botPos.Y - topPos.Y
                local boxW = boxH / 1.8
                local boxX = pos.X - (boxW * 0.5)
                local boxY = topPos.Y

                local isWhitelisted = config.whitelist[player.Name]
                local mainClr = isWhitelisted and Color3.fromRGB(50, 255, 50) or config.colors.enemy_esp

                if config.toggles.boxes then
                    local isFull = (config.selectors.box_style == 2)
                    if isFull then
                        esp.TopLeft1.Thickness = t_Thick esp.TopLeft1.Color = mainClr
                        esp.TopLeft1.From = Vector2.new(boxX, boxY) esp.TopLeft1.To = Vector2.new(boxX + boxW, boxY)
                        esp.BottomLeft1.Thickness = t_Thick esp.BottomLeft1.Color = mainClr
                        esp.BottomLeft1.From = Vector2.new(boxX, boxY + boxH) esp.BottomLeft1.To = Vector2.new(boxX + boxW, boxY + boxH)
                        esp.TopLeft2.Thickness = t_Thick esp.TopLeft2.Color = mainClr
                        esp.TopLeft2.From = Vector2.new(boxX, boxY) esp.TopLeft2.To = Vector2.new(boxX, boxY + boxH)
                        esp.TopRight2.Thickness = t_Thick esp.TopRight2.Color = mainClr
                        esp.TopRight2.From = Vector2.new(boxX + boxW, boxY) esp.TopRight2.To = Vector2.new(boxX + boxW, boxY + boxH)
                        
                        esp.TopLeft1.Visible = true; esp.BottomLeft1.Visible = true
                        esp.TopLeft2.Visible = true; esp.TopRight2.Visible = true
                        esp.TopRight1.Visible = false; esp.BottomLeft2.Visible = false
                        esp.BottomRight1.Visible = false; esp.BottomRight2.Visible = false
                    else
                        local length = math.max(boxW * 0.25, 3)
                        esp.TopLeft1.Thickness = t_Thick esp.TopLeft1.Color = mainClr
                        esp.TopLeft1.From = Vector2.new(boxX, boxY) esp.TopLeft1.To = Vector2.new(boxX + length, boxY)
                        esp.TopLeft2.Thickness = t_Thick esp.TopLeft2.Color = mainClr
                        esp.TopLeft2.From = Vector2.new(boxX, boxY) esp.TopLeft2.To = Vector2.new(boxX, boxY + length)
                        
                        esp.TopRight1.Thickness = t_Thick esp.TopRight1.Color = mainClr
                        esp.TopRight1.From = Vector2.new(boxX + boxW, boxY) esp.TopRight1.To = Vector2.new(boxX + boxW - length, boxY)
                        esp.TopRight2.Thickness = t_Thick esp.TopRight2.Color = mainClr
                        esp.TopRight2.From = Vector2.new(boxX + boxW, boxY) esp.TopRight2.To = Vector2.new(boxX + boxW, boxY + length)
                        
                        esp.BottomLeft1.Thickness = t_Thick esp.BottomLeft1.Color = mainClr
                        esp.BottomLeft1.From = Vector2.new(boxX, boxY + boxH) esp.BottomLeft1.To = Vector2.new(boxX + length, boxY + boxH)
                        esp.BottomLeft2.Thickness = t_Thick esp.BottomLeft2.Color = mainClr
                        esp.BottomLeft2.From = Vector2.new(boxX, boxY + boxH) esp.BottomLeft2.To = Vector2.new(boxX, boxY + boxH - length)
                        
                        esp.BottomRight1.Thickness = t_Thick esp.BottomRight1.Color = mainClr
                        esp.BottomRight1.From = Vector2.new(boxX + boxW, boxY + boxH) esp.BottomRight1.To = Vector2.new(boxX + boxW - length, boxY + boxH)
                        esp.BottomRight2.Thickness = t_Thick esp.BottomRight2.Color = mainClr
                        esp.BottomRight2.From = Vector2.new(boxX + boxW, boxY + boxH) esp.BottomRight2.To = Vector2.new(boxX + boxW, boxY + boxH - length)
                        
                        esp.TopLeft1.Visible = true; esp.TopLeft2.Visible = true
                        esp.TopRight1.Visible = true; esp.TopRight2.Visible = true
                        esp.BottomLeft1.Visible = true; esp.BottomLeft2.Visible = true
                        esp.BottomRight1.Visible = true; esp.BottomRight2.Visible = true
                    end

                    -- Box Glass Fill
                    if config.toggles.esp_box_fill and esp.BoxFill then
                        esp.BoxFill.Position = Vector2.new(boxX, boxY)
                        esp.BoxFill.Size = Vector2.new(boxW, boxH)
                        esp.BoxFill.Transparency = (100 - (config.sliders.esp_fill_alpha or 15)) / 100
                        esp.BoxFill.Visible = true
                    elseif esp.BoxFill then
                        esp.BoxFill.Visible = false
                    end

                    -- Box Outlines
                    if config.toggles.esp_box_outline and esp.TopLeft1_O then
                        local oThick = t_Thick + 2
                        esp.TopLeft1_O.From = esp.TopLeft1.From; esp.TopLeft1_O.To = esp.TopLeft1.To; esp.TopLeft1_O.Thickness = oThick; esp.TopLeft1_O.Visible = esp.TopLeft1.Visible
                        esp.TopLeft2_O.From = esp.TopLeft2.From; esp.TopLeft2_O.To = esp.TopLeft2.To; esp.TopLeft2_O.Thickness = oThick; esp.TopLeft2_O.Visible = esp.TopLeft2.Visible
                        esp.TopRight1_O.From = esp.TopRight1.From; esp.TopRight1_O.To = esp.TopRight1.To; esp.TopRight1_O.Thickness = oThick; esp.TopRight1_O.Visible = esp.TopRight1.Visible
                        esp.TopRight2_O.From = esp.TopRight2.From; esp.TopRight2_O.To = esp.TopRight2.To; esp.TopRight2_O.Thickness = oThick; esp.TopRight2_O.Visible = esp.TopRight2.Visible
                        esp.BottomLeft1_O.From = esp.BottomLeft1.From; esp.BottomLeft1_O.To = esp.BottomLeft1.To; esp.BottomLeft1_O.Thickness = oThick; esp.BottomLeft1_O.Visible = esp.BottomLeft1.Visible
                        esp.BottomLeft2_O.From = esp.BottomLeft2.From; esp.BottomLeft2_O.To = esp.BottomLeft2.To; esp.BottomLeft2_O.Thickness = oThick; esp.BottomLeft2_O.Visible = esp.BottomLeft2.Visible
                        esp.BottomRight1_O.From = esp.BottomRight1.From; esp.BottomRight1_O.To = esp.BottomRight1.To; esp.BottomRight1_O.Thickness = oThick; esp.BottomRight1_O.Visible = esp.BottomRight1.Visible
                        esp.BottomRight2_O.From = esp.BottomRight2.From; esp.BottomRight2_O.To = esp.BottomRight2.To; esp.BottomRight2_O.Thickness = oThick; esp.BottomRight2_O.Visible = esp.BottomRight2.Visible
                    elseif esp.TopLeft1_O then
                        esp.TopLeft1_O.Visible = false; esp.TopLeft2_O.Visible = false
                        esp.TopRight1_O.Visible = false; esp.TopRight2_O.Visible = false
                        esp.BottomLeft1_O.Visible = false; esp.BottomLeft2_O.Visible = false
                        esp.BottomRight1_O.Visible = false; esp.BottomRight2_O.Visible = false
                    end
                else 
                    esp.TopLeft1.Visible = false esp.TopLeft2.Visible = false
                    esp.TopRight1.Visible = false esp.TopRight2.Visible = false
                    esp.BottomLeft1.Visible = false esp.BottomLeft2.Visible = false
                    esp.BottomRight1.Visible = false esp.BottomRight2.Visible = false
                    if esp.BoxFill then esp.BoxFill.Visible = false end
                    if esp.TopLeft1_O then
                        esp.TopLeft1_O.Visible = false; esp.TopLeft2_O.Visible = false
                        esp.TopRight1_O.Visible = false; esp.TopRight2_O.Visible = false
                        esp.BottomLeft1_O.Visible = false; esp.BottomLeft2_O.Visible = false
                        esp.BottomRight1_O.Visible = false; esp.BottomRight2_O.Visible = false
                    end
                end

                if config.toggles.head_dots then
                    esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                    esp.HeadDot.Color = mainClr
                    esp.HeadDot.Visible = true
                    if config.toggles.esp_head_outline and esp.HeadDot_O then
                        esp.HeadDot_O.Position = Vector2.new(headPos.X, headPos.Y)
                        esp.HeadDot_O.Visible = true
                    elseif esp.HeadDot_O then
                        esp.HeadDot_O.Visible = false
                    end
                else 
                    esp.HeadDot.Visible = false 
                    if esp.HeadDot_O then esp.HeadDot_O.Visible = false end
                end

                if config.toggles.healthbars then
                    local hpPct = math.clamp(hp / maxHp, 0, 1)
                    local barH = boxH * hpPct
                    esp.HealthOutline.Size = Vector2.new(4, boxH + 2)
                    esp.HealthOutline.Position = Vector2.new(boxX - 7, boxY - 1)
                    esp.HealthBar.Size = Vector2.new(2, barH)
                    esp.HealthBar.Position = Vector2.new(boxX - 6, boxY + (boxH - barH))
                    
                    if config.toggles.esp_hp_dynamic then
                        esp.HealthBar.Color = Color3.fromRGB(math.floor(255 - (hpPct * 255)), math.floor(hpPct * 255), 30)
                    else
                        esp.HealthBar.Color = config.colors.ui_accent
                    end

                    esp.HealthOutline.Visible = true
                    esp.HealthBar.Visible = true
                    
                    if config.toggles.healthtext and not config.toggles.esp_flags and hp < maxHp then
                        esp.HealthText.Text = tostring(math.floor(hp))
                        esp.HealthText.Position = Vector2.new(boxX - 18, boxY + (boxH - barH) - 6)
                        esp.HealthText.Visible = true
                    else 
                        esp.HealthText.Visible = false 
                    end
                else 
                    esp.HealthOutline.Visible = false
                    esp.HealthBar.Visible = false
                    esp.HealthText.Visible = false 
                end

                if config.toggles.names then
                    esp.Name.Text = string.upper(player.Name) .. (isWhitelisted and " [W]" or "")
                    esp.Name.Position = Vector2.new(pos.X, boxY - 18)
                    esp.Name.Color = isWhitelisted and Color3.fromRGB(50, 255, 50) or Color3.new(1, 1, 1)
                    esp.Name.Visible = true
                else 
                    esp.Name.Visible = false 
                end

                -- Tactical Right-Side Flags Stack (Skeet / Neverlose Flag Engine)
                local flagX = boxX + boxW + 4
                local flagY = boxY
                if config.toggles.esp_flags and esp.FlagDist then
                    if config.toggles.distances then
                        local dStr = (config.selectors.esp_dist_metric == 2) and (math.floor(dist) .. "S") or (math.floor(dist * 0.28) .. "M")
                        esp.FlagDist.Text = dStr
                        esp.FlagDist.Position = Vector2.new(flagX, flagY)
                        esp.FlagDist.Visible = true
                        flagY = flagY + 11
                    else
                        esp.FlagDist.Visible = false
                    end

                    if config.toggles.healthtext and hp < maxHp then
                        esp.FlagHP.Text = tostring(math.floor(hp)) .. "HP"
                        esp.FlagHP.Position = Vector2.new(flagX, flagY)
                        esp.FlagHP.Color = Color3.fromRGB(math.floor(255 - ((hp/maxHp) * 255)), math.floor((hp/maxHp) * 255), 30)
                        esp.FlagHP.Visible = true
                        flagY = flagY + 11
                    else
                        esp.FlagHP.Visible = false
                    end

                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local actStr = nil
                    if hum then
                        local state = hum:GetState()
                        if state == Enum.HumanoidStateType.Freefall then actStr = "FALL"
                        elseif state == Enum.HumanoidStateType.Jumping then actStr = "JUMP"
                        elseif hum.MoveDirection.Magnitude > 0.1 then actStr = "RUN" end
                    end
                    if actStr then
                        esp.FlagAction.Text = actStr
                        esp.FlagAction.Position = Vector2.new(flagX, flagY)
                        esp.FlagAction.Visible = true
                        flagY = flagY + 11
                    else
                        esp.FlagAction.Visible = false
                    end

                    if isWhitelisted then
                        esp.FlagState.Text = "WHITELIST"
                        esp.FlagState.Color = Color3.fromRGB(50, 255, 50)
                        esp.FlagState.Position = Vector2.new(flagX, flagY)
                        esp.FlagState.Visible = true
                    elseif closestTarget and dist <= 35 then
                        esp.FlagState.Text = "TARGET"
                        esp.FlagState.Color = config.colors.ui_accent
                        esp.FlagState.Position = Vector2.new(flagX, flagY)
                        esp.FlagState.Visible = true
                    else
                        esp.FlagState.Visible = false
                    end
                elseif esp.FlagDist then
                    esp.FlagDist.Visible = false
                    esp.FlagHP.Visible = false
                    esp.FlagAction.Visible = false
                    esp.FlagState.Visible = false
                end
                
                local bottomY = boxY + boxH + 3
                if config.toggles.distances and not config.toggles.esp_flags then
                    if config.selectors.esp_dist_metric == 2 then
                        esp.Distance.Text = "[" .. math.floor(dist) .. " studs]"
                    else
                        esp.Distance.Text = "[" .. math.floor(dist * 0.28) .. "m]"
                    end
                    esp.Distance.Position = Vector2.new(pos.X, bottomY)
                    esp.Distance.Visible = true
                    bottomY = bottomY + 14
                else 
                    esp.Distance.Visible = false 
                end
                
                if config.toggles.weapons then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        esp.Weapon.Text = "[" .. string.upper(tool.Name) .. "]"
                        esp.Weapon.Position = Vector2.new(pos.X, bottomY)
                        esp.Weapon.Visible = true
                    else
                        esp.Weapon.Visible = false
                    end
                else 
                    esp.Weapon.Visible = false 
                end
                
                if config.toggles.tracers then
                    esp.Tracer.From = screenBottom
                    if config.selectors.tracer_origin == 2 then 
                        esp.Tracer.From = screenCenter 
                    elseif config.selectors.tracer_origin == 3 then 
                        esp.Tracer.From = mouseLoc 
                    end
                    esp.Tracer.To = Vector2.new(pos.X, botPos.Y)
                    esp.Tracer.Color = mainClr
                    esp.Tracer.Visible = true
                else 
                    esp.Tracer.Visible = false 
                end

                if config.toggles.skeletons and esp.SkeletonLines then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local boneList = (hum and hum.RigType == Enum.HumanoidRigType.R6) and SKELETON_R6 or SKELETON_R15
                    local lIndex = 1
                    
                    for b = 1, #boneList do
                        local pair = boneList[b]
                        local p1 = char:FindFirstChild(pair[1])
                        local p2 = char:FindFirstChild(pair[2])
                        if p1 and p2 then
                            local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                            if (on1 or on2) and esp.SkeletonLines[lIndex] then
                                esp.SkeletonLines[lIndex].From = Vector2.new(pos1.X, pos1.Y)
                                esp.SkeletonLines[lIndex].To = Vector2.new(pos2.X, pos2.Y)
                                esp.SkeletonLines[lIndex].Color = isWhitelisted and Color3.fromRGB(50, 255, 50) or ESP_COLORS.Skeleton
                                esp.SkeletonLines[lIndex].Visible = true
                                lIndex = lIndex + 1
                            end
                        end
                    end
                    for i = lIndex, 15 do 
                        if esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                    end
                else
                    if esp.SkeletonLines then
                        for i = 1, 15 do 
                            if esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                        end
                    end
                end
            else
                esp.TopLeft1.Visible = false esp.TopLeft2.Visible = false
                esp.TopRight1.Visible = false esp.TopRight2.Visible = false
                esp.BottomLeft1.Visible = false esp.BottomLeft2.Visible = false
                esp.BottomRight1.Visible = false esp.BottomRight2.Visible = false
                if esp.BoxFill then esp.BoxFill.Visible = false end
                if esp.TopLeft1_O then
                    esp.TopLeft1_O.Visible = false esp.TopLeft2_O.Visible = false
                    esp.TopRight1_O.Visible = false esp.TopRight2_O.Visible = false
                    esp.BottomLeft1_O.Visible = false esp.BottomLeft2_O.Visible = false
                    esp.BottomRight1_O.Visible = false esp.BottomRight2_O.Visible = false
                end
                esp.HealthOutline.Visible = false esp.HealthBar.Visible = false esp.HealthText.Visible = false
                esp.Name.Visible = false esp.Distance.Visible = false esp.Weapon.Visible = false
                esp.Tracer.Visible = false esp.HeadDot.Visible = false
                if esp.HeadDot_O then esp.HeadDot_O.Visible = false end
                if esp.FlagDist then
                    esp.FlagDist.Visible = false esp.FlagHP.Visible = false esp.FlagAction.Visible = false esp.FlagState.Visible = false
                end
                if esp.SkeletonLines then
                    for _, l in ipairs(esp.SkeletonLines) do l.Visible = false end
                end
            end
        else
            esp.TopLeft1.Visible = false esp.TopLeft2.Visible = false
            esp.TopRight1.Visible = false esp.TopRight2.Visible = false
            esp.BottomLeft1.Visible = false esp.BottomLeft2.Visible = false
            esp.BottomRight1.Visible = false esp.BottomRight2.Visible = false
            if esp.BoxFill then esp.BoxFill.Visible = false end
            if esp.TopLeft1_O then
                esp.TopLeft1_O.Visible = false esp.TopLeft2_O.Visible = false
                esp.TopRight1_O.Visible = false esp.TopRight2_O.Visible = false
                esp.BottomLeft1_O.Visible = false esp.BottomLeft2_O.Visible = false
                esp.BottomRight1_O.Visible = false esp.BottomRight2_O.Visible = false
            end
            esp.HealthOutline.Visible = false esp.HealthBar.Visible = false esp.HealthText.Visible = false
            esp.Name.Visible = false esp.Distance.Visible = false esp.Weapon.Visible = false
            esp.Tracer.Visible = false esp.HeadDot.Visible = false esp.ViewTracer.Visible = false
            if esp.HeadDot_O then esp.HeadDot_O.Visible = false end
            if esp.FlagDist then
                esp.FlagDist.Visible = false esp.FlagHP.Visible = false esp.FlagAction.Visible = false esp.FlagState.Visible = false
            end
            esp.OffscreenArrow.Visible = false
            if esp.SkeletonLines then
                for _, l in ipairs(esp.SkeletonLines) do l.Visible = false end
            end
            if HighlightInstances[player] then 
                HighlightInstances[player].Enabled = false 
            end
        end
    end
end)

-- ==========================================
-- 15. BEZPIECZNY SYSTEM WYŁĄCZANIA (UNLOAD)
-- ==========================================
local function UnloadAsapware()
    ScriptLoaded = false
    RunService:UnbindFromRenderStep("AsapwareMain")
    if NoclipConnection then NoclipConnection:Disconnect() end
    if ScreenGui then ScreenGui:Destroy() end
    if KeybindsHUD then KeybindsHUD:Destroy() end
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
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
    end
    
    for _, esp in pairs(ESP_Data) do
        for k, v in pairs(esp) do
            if k == "SkeletonLines" then 
                for _, l in ipairs(v) do pcall(function() l:Remove() end) end
            else 
                pcall(function() v:Remove() end) 
            end
        end
    end
    for _, hl in pairs(HighlightInstances) do pcall(function() hl:Destroy() end) end
    table.clear(ESP_Data)
    table.clear(HighlightInstances)
    
    for _, obj in ipairs(AllDrawings) do 
        if obj.Remove then pcall(function() obj:Remove() end) end 
    end
    table.clear(AllDrawings)

    local genv = (getgenv and getgenv()) or _G
    genv.AsapwareUnload = nil
    print("ASAPWARE: Successfully Unloaded.")
end

local genv = (getgenv and getgenv()) or _G
genv.AsapwareUnload = UnloadAsapware

print("ASAPWARE V22 ELITE MONOLITH LOADED.")
