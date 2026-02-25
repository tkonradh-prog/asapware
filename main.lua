--- START OF FILE Paste February 25, 2026 - 3:22PM (ASAPWARE v6 + ACS GODMODE) ---

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- KONFIGURACJA
-- ==========================================
local config = {
    esp_enabled = true,
    teamCheck = false,
    toggles = {
        boxes = true, healthbars = true, healthtext = false,
        names = true, weapons = false, distances = false,
        skeletons = true, tracers = false,
        aim_enabled = false, aim_showFov = true,
        aim_crosshair = true, aim_wallCheck = true, aim_predict = false,
        time_changer = false, fov_changer = false,
        rainbow_ui = false, bhop = false, third_person = false,
        fly = false, godmode = false -- ACS GODMODE
    },
    sliders = {
        esp_distance = 3000, boxThickness = 1,
        aim_distance = 1500, aim_fov = 100, aim_smooth = 5,
        aim_offsetX = 0, aim_offsetY = 36, aim_pred_amt = 10,
        custom_time = 12, custom_fov = 90,
        fly_speed = 50
    },
    colors = {
        enemy_esp = Color3.fromRGB(255, 75, 75),
        ui_accent = Color3.fromRGB(110, 160, 255) 
    },
    selectors = { aim_part = 1, aim_method = 2, tracer_origin = 1 },
    keybinds = {
        aimbot = Enum.UserInputType.MouseButton2,
        fly = Enum.KeyCode.F
    }
}

local ESP_COLORS = {
    Outline = Color3.fromRGB(15, 15, 15),
    Skeleton = Color3.fromRGB(255, 255, 255)
}

-- Zmienne wewnetrzne
local flyPlatform = nil
local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true

-- ==========================================
-- OPTYMALNY SYSTEM HP
-- ==========================================
local function GetHealth(player)
    if player and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            return hum.Health, hum.MaxHealth
        end
    end
    return 0, 100
end

-- ==========================================
-- SILNIK UI & MOTYW
-- ==========================================
local TargetGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local ScreenGui = Instance.new("ScreenGui", TargetGui)
ScreenGui.Name = "AsapwarePerfection"
ScreenGui.ResetOnSpawn = false

local Theme = {
    BG = Color3.fromRGB(15, 15, 17),
    SidebarBG = Color3.fromRGB(20, 20, 23),
    CardBG = Color3.fromRGB(24, 24, 28),
    Border = Color3.fromRGB(45, 45, 50),
    InputBG = Color3.fromRGB(30, 30, 35),
    InputHover = Color3.fromRGB(40, 40, 45),
    TextWhite = Color3.fromRGB(245, 245, 250),
    TextGray = Color3.fromRGB(160, 160, 170),
    PreviewGrid = Color3.fromRGB(12, 12, 14)
}

local DragContainer = Instance.new("Frame", ScreenGui)
DragContainer.Size = UDim2.new(0, 1060, 0, 600)
DragContainer.Position = UDim2.new(0.5, -530, 0.5, -300)
DragContainer.BackgroundTransparency = 1

local UIScale = Instance.new("UIScale", DragContainer)
UIScale.Scale = 0 

local dragging, dragInput, dragStart, startPos
DragContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = DragContainer.Position
    end
end)
DragContainer.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart;
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
    for _, item in ipairs(UIThemeObjects) do 
        if item.Obj.Parent then item.Obj[item.Prop] = config.colors.ui_accent end
    end
end

-- ================== -- SYSTEM TOOLTIP -- ==================
local TooltipGui = Instance.new("Frame", ScreenGui)
TooltipGui.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
TooltipGui.Size = UDim2.new(0, 200, 0, 26)
TooltipGui.Visible = false
TooltipGui.ZIndex = 100
Instance.new("UICorner", TooltipGui).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", TooltipGui).Color = Theme.Border

local TooltipText = Instance.new("TextLabel", TooltipGui)
TooltipText.Size = UDim2.new(1, -16, 1, 0)
TooltipText.Position = UDim2.new(0, 8, 0, 0)
TooltipText.BackgroundTransparency = 1
TooltipText.TextColor3 = Theme.TextGray
TooltipText.Font = Enum.Font.Gotham
TooltipText.TextSize = 11
TooltipText.TextXAlignment = Enum.TextXAlignment.Left
TooltipText.ZIndex = 101

local function AddTooltip(element, text)
    if not text or text == "" then return end
    element.MouseEnter:Connect(function()
        TooltipText.Text = text
        local bounds = TooltipText.TextBounds
        TooltipGui.Size = UDim2.new(0, bounds.X + 20, 0, 24)
        TooltipGui.Visible = true
    end)
    element.MouseLeave:Connect(function() TooltipGui.Visible = false end)
end

RunService.RenderStepped:Connect(function()
    if TooltipGui.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        TooltipGui.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y - 15)
    end
end)

-- ================== -- 1. SIDEBAR -- ==================
local Sidebar = Instance.new("Frame", DragContainer)
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBG
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", Sidebar).Color = Theme.Border

local TopLine1 = Instance.new("Frame", Sidebar)
TopLine1.Size = UDim2.new(1, 0, 0, 3); TopLine1.BorderSizePixel = 0; ApplyAccent(TopLine1, "BackgroundColor3")
Instance.new("UICorner", TopLine1).CornerRadius = UDim.new(0, 6)

local LogoArea = Instance.new("Frame", Sidebar)
LogoArea.Size = UDim2.new(1, 0, 0, 80); LogoArea.BackgroundTransparency = 1
local LogoIcon = Instance.new("TextLabel", LogoArea)
LogoIcon.Size = UDim2.new(1, 0, 1, 0); LogoIcon.BackgroundTransparency = 1
LogoIcon.Text = "ASAPWARE"; LogoIcon.TextColor3 = Theme.TextWhite; LogoIcon.Font = Enum.Font.GothamBlack; LogoIcon.TextSize = 20
local LogoSub = Instance.new("TextLabel", LogoArea)
LogoSub.Size = UDim2.new(1, 0, 0, 20); LogoSub.Position = UDim2.new(0,0,0,50); LogoSub.BackgroundTransparency = 1
LogoSub.Text = "P E R F E C T I O N"; LogoSub.Font = Enum.Font.GothamBold; LogoSub.TextSize = 9; ApplyAccent(LogoSub, "TextColor3")

local ProfileArea = Instance.new("Frame", Sidebar)
ProfileArea.Size = UDim2.new(1, -20, 0, 50); ProfileArea.Position = UDim2.new(0, 10, 1, -60); ProfileArea.BackgroundColor3 = Theme.InputBG; ProfileArea.BorderSizePixel = 0
Instance.new("UICorner", ProfileArea).CornerRadius = UDim.new(0, 6)
local Avatar = Instance.new("Frame", ProfileArea)
Avatar.Size = UDim2.new(0, 30, 0, 30); Avatar.Position = UDim2.new(0, 10, 0.5, -15); Avatar.BackgroundColor3 = Theme.Border; Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)
local Username = Instance.new("TextLabel", ProfileArea)
Username.Size = UDim2.new(1, -50, 1, 0); Username.Position = UDim2.new(0, 50, 0, 0); Username.BackgroundTransparency = 1; Username.Text = LocalPlayer.Name; Username.TextColor3 = Theme.TextWhite; Username.Font = Enum.Font.GothamMedium; Username.TextSize = 12; Username.TextXAlignment = Enum.TextXAlignment.Left

-- ================== -- 3. OKNO PODGLĄDU 3D ESP -- ==================
local Preview = Instance.new("Frame", DragContainer)
Preview.Size = UDim2.new(0, 330, 1, 0); Preview.Position = UDim2.new(0, 730, 0, 0)
Preview.BackgroundColor3 = Theme.BG; Preview.BorderSizePixel = 0; Preview.Visible = false
Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", Preview).Color = Theme.Border

local TopLine3 = Instance.new("Frame", Preview)
TopLine3.Size = UDim2.new(1, 0, 0, 3); TopLine3.BorderSizePixel = 0; ApplyAccent(TopLine3, "BackgroundColor3")
Instance.new("UICorner", TopLine3).CornerRadius = UDim.new(0, 6)

local PrevTitle = Instance.new("TextLabel", Preview)
PrevTitle.Size = UDim2.new(1, -20, 0, 50); PrevTitle.Position = UDim2.new(0, 20, 0, 0); PrevTitle.BackgroundTransparency = 1
PrevTitle.Text = "Visual Preview"; PrevTitle.TextColor3 = Theme.TextWhite; PrevTitle.Font = Enum.Font.GothamBold; PrevTitle.TextSize = 14; PrevTitle.TextXAlignment = Enum.TextXAlignment.Left

local ViewportContainer = Instance.new("Frame", Preview)
ViewportContainer.Size = UDim2.new(1, -40, 1, -130); ViewportContainer.Position = UDim2.new(0, 20, 0, 55)
ViewportContainer.BackgroundColor3 = Theme.PreviewGrid; Instance.new("UICorner", ViewportContainer).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", ViewportContainer).Color = Theme.Border
ViewportContainer.ClipsDescendants = true

local VPF = Instance.new("ViewportFrame", ViewportContainer)
VPF.Size = UDim2.new(1, 0, 1, 0); VPF.BackgroundTransparency = 1; VPF.Ambient = Color3.fromRGB(150, 150, 160); VPF.LightColor = Color3.fromRGB(255,255,255)
VPF.LightDirection = Vector3.new(-1, -1, -1)
local VPF_Cam = Instance.new("Camera"); VPF.CurrentCamera = VPF_Cam

local DummyModel = Instance.new("Model", VPF)
local function MakePart(name, size, pos, color)
    local p = Instance.new("Part", DummyModel); p.Name = name; p.Size = size; p.CFrame = CFrame.new(pos)
    p.Material = Enum.Material.SmoothPlastic; p.Color = color or Color3.fromRGB(60, 65, 75); 
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local Head = MakePart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.6, 0))
local Torso = MakePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
local LArm = MakePart("LArm", Vector3.new(1, 2, 1), Vector3.new(-1.6, 0, 0))
local RArm = MakePart("RArm", Vector3.new(1, 2, 1), Vector3.new(1.6, 0, 0))
local LLeg = MakePart("LLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
local RLeg = MakePart("RLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
local GunBody = MakePart("GunBody", Vector3.new(0.3, 0.5, 1.5), Vector3.new(1.6, -0.4, -1.2), Color3.fromRGB(30,30,35))
local GunBarrel = MakePart("GunBarrel", Vector3.new(0.15, 0.15, 1.2), Vector3.new(1.6, -0.3, -2.4), Color3.fromRGB(20,20,25))
DummyModel.PrimaryPart = Torso

local Overlay = Instance.new("Frame", ViewportContainer)
Overlay.Size = UDim2.new(1, 0, 1, 0); Overlay.BackgroundTransparency = 1

local P_Box = Instance.new("Frame", Overlay); P_Box.Size = UDim2.new(0, 140, 0, 240); P_Box.Position = UDim2.new(0.5, -70, 0.5, -120); P_Box.BackgroundTransparency = 1; 
local P_BoxStr = Instance.new("UIStroke", P_Box); ApplyAccent(P_BoxStr, "Color")
local P_HealthBg = Instance.new("Frame", P_Box); P_HealthBg.Size = UDim2.new(0, 4, 1, 0); P_HealthBg.Position = UDim2.new(0, -8, 0, 0); P_HealthBg.BackgroundColor3 = Color3.fromRGB(15,15,15); P_HealthBg.BorderSizePixel = 0
local P_HealthFill = Instance.new("Frame", P_HealthBg); P_HealthFill.Size = UDim2.new(1, 0, 0.8, 0); P_HealthFill.Position = UDim2.new(0, 0, 0.2, 0); P_HealthFill.BackgroundColor3 = Color3.fromRGB(80, 255, 80); P_HealthFill.BorderSizePixel = 0
local P_Name = Instance.new("TextLabel", P_Box); P_Name.Size = UDim2.new(1, 0, 0, 15); P_Name.Position = UDim2.new(0, 0, 0, -18); P_Name.BackgroundTransparency = 1; P_Name.Text = "Enemy"; P_Name.TextColor3 = Color3.new(1,1,1); P_Name.Font = Enum.Font.GothamMedium; P_Name.TextSize = 12
local P_Weapon = Instance.new("TextLabel", P_Box); P_Weapon.Size = UDim2.new(1, 0, 0, 15); P_Weapon.Position = UDim2.new(0, 0, 1, 4); P_Weapon.BackgroundTransparency = 1; P_Weapon.Text = "AK-47"; P_Weapon.TextColor3 = Color3.fromRGB(200,200,220); P_Weapon.Font = Enum.Font.Gotham; P_Weapon.TextSize = 11

local BottomBar = Instance.new("Frame", Preview)
BottomBar.Size = UDim2.new(1, -40, 0, 45); BottomBar.Position = UDim2.new(0, 20, 1, -60); BottomBar.BackgroundTransparency = 1
local PillLayout = Instance.new("UIListLayout", BottomBar); PillLayout.Padding = UDim.new(0, 10); PillLayout.FillDirection = Enum.FillDirection.Horizontal; PillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; PillLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function CreatePreviewPill(text, key, tooltipText)
    local btn = Instance.new("TextButton", BottomBar); btn.Size = UDim2.new(0, 55, 0, 26); btn.BackgroundColor3 = Theme.InputBG; btn.Text = text; btn.TextColor3 = Theme.TextGray; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); local str = Instance.new("UIStroke", btn); str.Color = Theme.Border
    UpdatePreviewEvent.Event:Connect(function()
        if config.toggles[key] then str.Color = config.colors.ui_accent; btn.TextColor3 = Theme.TextWhite else str.Color = Theme.Border; btn.TextColor3 = Theme.TextGray end
    end)
    btn.MouseButton1Click:Connect(function() config.toggles[key] = not config.toggles[key]; UpdatePreviewEvent:Fire() end)
    
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputHover}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputBG}):Play() end)
    AddTooltip(btn, tooltipText)
end
CreatePreviewPill("Name", "names", "Toggle name ESP visibility."); 
CreatePreviewPill("Weapon", "weapons", "Toggle weapon ESP visibility."); 
CreatePreviewPill("Health", "healthbars", "Toggle health bar ESP."); 
CreatePreviewPill("Box", "boxes", "Toggle bounding box ESP.")

UpdatePreviewEvent.Event:Connect(function()
    P_Box.Visible = config.toggles.boxes; P_Name.Visible = config.toggles.names
    P_HealthBg.Visible = config.toggles.healthbars; P_Weapon.Visible = config.toggles.weapons
end)

local S_Lines = {}
local function CreatePrevLine()
    local f = Instance.new("Frame", Overlay); f.BackgroundColor3 = Color3.new(1,1,1); f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5)
    table.insert(S_Lines, f); return f
end
for i=1, 5 do CreatePrevLine() end

-- ================== -- 2. PANEL GŁÓWNY -- ==================
local Main = Instance.new("Frame", DragContainer)
Main.Size = UDim2.new(0, 510, 1, 0); Main.Position = UDim2.new(0, 210, 0, 0)
Main.BackgroundColor3 = Theme.BG; Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", Main).Color = Theme.Border

local TopLine2 = Instance.new("Frame", Main)
TopLine2.Size = UDim2.new(1, 0, 0, 3); TopLine2.BorderSizePixel = 0; ApplyAccent(TopLine2, "BackgroundColor3")
Instance.new("UICorner", TopLine2).CornerRadius = UDim.new(0, 6)

local Breadcrumb = Instance.new("TextLabel", Main)
Breadcrumb.Size = UDim2.new(1, -40, 0, 50); Breadcrumb.Position = UDim2.new(0, 20, 0, 0); Breadcrumb.BackgroundTransparency = 1
Breadcrumb.RichText = true; Breadcrumb.TextColor3 = Theme.TextGray; Breadcrumb.Font = Enum.Font.GothamMedium; Breadcrumb.TextSize = 14; Breadcrumb.TextXAlignment = Enum.TextXAlignment.Left

local TabPages = Instance.new("Frame", Main)
TabPages.Size = UDim2.new(1, 0, 1, -51); TabPages.Position = UDim2.new(0, 0, 0, 51); TabPages.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -20, 0, 38); btn.Position = UDim2.new(0, 10, 0, 90 + (#Tabs * 42)); btn.BackgroundTransparency = 1; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local txt = Instance.new("TextLabel", btn); txt.Size = UDim2.new(1, -15, 1, 0); txt.Position = UDim2.new(0, 15, 0, 0); txt.BackgroundTransparency = 1
    txt.Text = name; txt.TextColor3 = isFirst and Theme.TextWhite or Theme.TextGray; txt.Font = Enum.Font.GothamMedium; txt.TextSize = 13; txt.TextXAlignment = Enum.TextXAlignment.Left
    
    local page = Instance.new("ScrollingFrame", TabPages)
    page.Size = UDim2.new(1, -30, 1, -20); page.Position = UDim2.new(0, 15, 0, 10); page.BackgroundTransparency = 1; page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = Theme.Border; page.Visible = isFirst
    page.BorderSizePixel = 0
    
    local colLeft = Instance.new("Frame", page); colLeft.Size = UDim2.new(0.48, 0, 0, 0); colLeft.BackgroundTransparency = 1; colLeft.AutomaticSize = Enum.AutomaticSize.Y
    local colRight = Instance.new("Frame", page); colRight.Size = UDim2.new(0.48, 0, 0, 0); colRight.Position = UDim2.new(0.52, 0, 0, 0); colRight.BackgroundTransparency = 1; colRight.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", colLeft).Padding = UDim.new(0, 15); Instance.new("UIListLayout", colRight).Padding = UDim.new(0, 15)
    
    table.insert(Tabs, {Btn = btn, Txt = txt, Page = page, Name = name})
    
    local function formatBreadcrumb(n)
        local hex = string.format("#%02X%02X%02X", config.colors.ui_accent.R*255, config.colors.ui_accent.G*255, config.colors.ui_accent.B*255)
        return "Menu <font color='"..hex.."'> > " .. n .. "</font>"
    end

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do t.Txt.TextColor3 = Theme.TextGray; t.Btn.BackgroundColor3 = Theme.SidebarBG; t.Page.Visible = false end
        txt.TextColor3 = Theme.TextWhite; btn.BackgroundColor3 = Theme.InputBG; page.Visible = true
        Breadcrumb.Text = formatBreadcrumb(name)
        if name == "Visuals" then Preview.Visible = true else Preview.Visible = false end
    end)
    
    btn.MouseEnter:Connect(function() if not page.Visible then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputHover}):Play() end end)
    btn.MouseLeave:Connect(function() if not page.Visible then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SidebarBG}):Play() end end)
    
    if isFirst then Breadcrumb.Text = formatBreadcrumb(name); btn.BackgroundColor3 = Theme.InputBG end
    local function updateCanvas() page.CanvasSize = UDim2.new(0,0,0, math.max(colLeft.AbsoluteSize.Y, colRight.AbsoluteSize.Y) + 20) end
    colLeft:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas); colRight:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
    return {Left = colLeft, Right = colRight}
end

local function CreateSection(col, title)
    local sec = Instance.new("Frame", col); sec.Size = UDim2.new(1, 0, 0, 0); sec.BackgroundColor3 = Theme.CardBG; sec.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", sec).Color = Theme.Border
    local lbl = Instance.new("TextLabel", sec); lbl.Size = UDim2.new(1, -30, 0, 35); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = title; lbl.TextColor3 = Theme.TextWhite; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local line = Instance.new("Frame", sec); line.Size = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 0, 35); line.BackgroundColor3 = Theme.Border; line.BorderSizePixel = 0
    local content = Instance.new("Frame", sec); content.Size = UDim2.new(1, -30, 0, 0); content.Position = UDim2.new(0, 15, 0, 45); content.BackgroundTransparency = 1; content.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 12)
    local spacer = Instance.new("Frame", sec); spacer.Size = UDim2.new(1, 0, 0, 15); spacer.Position = UDim2.new(0, 0, 1, 0); spacer.BackgroundTransparency = 1
    return content
end

-- ================== -- FUNKCJE POMOCNICZE UI -- ==================

local function FormatKeyName(val)
    if not val then return "NONE" end
    if val == Enum.UserInputType.MouseButton1 then return "MB1" end
    if val == Enum.UserInputType.MouseButton2 then return "MB2" end
    if val == Enum.UserInputType.MouseButton3 then return "MB3" end
    return val.Name
end

local function CreateKeybind(parent, text, tbl, key, tooltipText)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 26); frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, -60, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 60, 0, 22); btn.Position = UDim2.new(1, -60, 0.5, -11); btn.BackgroundColor3 = Theme.InputBG; btn.Text = FormatKeyName(tbl[key]); btn.TextColor3 = Theme.TextWhite; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); local str = Instance.new("UIStroke", btn); str.Color = Theme.Border
    
    local listening = false
    btn.MouseButton1Click:Connect(function()
        task.wait() 
        listening = true
        btn.Text = "..."
        str.Color = config.colors.ui_accent
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        local valid = false; local bindValue = nil
        
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            bindValue = input.KeyCode; valid = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            bindValue = input.UserInputType; valid = true
        end
        
        if valid then
            if bindValue == Enum.KeyCode.Escape then
                tbl[key] = nil; btn.Text = "NONE"
            else
                tbl[key] = bindValue; btn.Text = FormatKeyName(bindValue)
            end
            listening = false
            str.Color = Theme.Border
        end
    end)
    
    btn.MouseEnter:Connect(function() if not listening then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputHover}):Play() end end)
    btn.MouseLeave:Connect(function() if not listening then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputBG}):Play() end end)
    
    AddTooltip(frame, tooltipText)
end

local function CreateCheckbox(parent, text, tbl, key, tooltipText)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(1, 0, 0, 22); btn.BackgroundTransparency = 1; btn.Text = ""
    local box = Instance.new("Frame", btn); box.Size = UDim2.new(0, 16, 0, 16); box.Position = UDim2.new(0, 0, 0.5, -8); box.BackgroundColor3 = tbl[key] and config.colors.ui_accent or Theme.InputBG; box.BorderSizePixel = 0; Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local str = Instance.new("UIStroke", box); str.Color = Theme.Border; str.Enabled = not tbl[key]
    local check = Instance.new("TextLabel", box); check.Size = UDim2.new(1, 0, 1, 0); check.BackgroundTransparency = 1; check.Text = "✓"; check.TextColor3 = Color3.fromRGB(255, 255, 255); check.Font = Enum.Font.GothamBold; check.TextSize = 11; check.Visible = tbl[key]
    local lbl = Instance.new("TextLabel", btn); lbl.Size = UDim2.new(1, -28, 1, 0); lbl.Position = UDim2.new(0, 28, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local function setVisuals()
        local goalColor = tbl[key] and config.colors.ui_accent or Theme.InputBG
        TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
        check.Visible = tbl[key]; str.Enabled = not tbl[key]
    end
    UpdatePreviewEvent.Event:Connect(setVisuals)
    
    btn.MouseButton1Click:Connect(function() tbl[key] = not tbl[key]; UpdatePreviewEvent:Fire() end)
    btn.MouseEnter:Connect(function() if not tbl[key] then TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputHover}):Play() end end)
    btn.MouseLeave:Connect(function() if not tbl[key] then TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputBG}):Play() end end)
    
    AddTooltip(btn, tooltipText)
end

local function CreateSlider(parent, text, tbl, key, min, max, tooltipText)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 40); frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", frame); valLbl.Size = UDim2.new(1, 0, 0, 15); valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(tbl[key]); valLbl.TextColor3 = Theme.TextGray; valLbl.Font = Enum.Font.Gotham; valLbl.TextSize = 11; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("TextButton", frame); track.Size = UDim2.new(1, 0, 0, 6); track.Position = UDim2.new(0, 0, 0, 26); track.BackgroundColor3 = Theme.InputBG; track.Text = ""; Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0); Instance.new("UIStroke", track).Color = Theme.Border
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((tbl[key]-min)/(max-min), 0, 1, 0); ApplyAccent(fill, "BackgroundColor3"); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", fill); knob.Size = UDim2.new(0, 12, 0, 12); knob.Position = UDim2.new(1, -6, 0.5, -6); knob.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    
    local dragging = false
    local function update(i)
        local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pct)); tbl[key] = val; valLbl.Text = tostring(val); fill.Size = UDim2.new(pct, 0, 1, 0)
    end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
    
    AddTooltip(frame, tooltipText)
end

local function CreateDropdown(parent, text, tbl, key, options, tooltipText)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 50); frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.TextGray; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(1, 0, 0, 28); btn.Position = UDim2.new(0, 0, 0, 20); btn.BackgroundColor3 = Theme.InputBG; btn.Text = "   " .. options[tbl[key]]; btn.TextColor3 = Theme.TextWhite; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", btn).Color = Theme.Border
    local icon = Instance.new("TextLabel", btn); icon.Size = UDim2.new(0, 20, 1, 0); icon.Position = UDim2.new(1, -25, 0, 0); icon.BackgroundTransparency = 1; icon.Text = "▼"; icon.TextColor3 = Theme.TextGray; icon.Font = Enum.Font.Gotham; icon.TextSize = 10
    
    btn.MouseButton1Click:Connect(function() tbl[key] = tbl[key] + 1; if tbl[key] > #options then tbl[key] = 1 end; btn.Text = "   " .. options[tbl[key]] end)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputHover}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputBG}):Play() end)
    
    AddTooltip(frame, tooltipText)
end

local function CreateColorPicker(parent, text, tbl, key, tooltipText)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 24); frame.BackgroundTransparency = 1; frame.ClipsDescendants = true
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, -40, 0, 24); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local showBtn = Instance.new("TextButton", frame); showBtn.Size = UDim2.new(0, 34, 0, 16); showBtn.Position = UDim2.new(1, -34, 0, 4); showBtn.BackgroundColor3 = tbl[key]; showBtn.Text = ""; Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0,4); Instance.new("UIStroke", showBtn).Color = Theme.Border
    
    local pickerBox = Instance.new("Frame", frame); pickerBox.Size = UDim2.new(1, 0, 0, 140); pickerBox.Position = UDim2.new(0, 0, 0, 32); pickerBox.BackgroundColor3 = Theme.InputBG; pickerBox.Visible = false; Instance.new("UICorner", pickerBox).CornerRadius = UDim.new(0,4); Instance.new("UIStroke", pickerBox).Color = Theme.Border
    local svMap = Instance.new("TextButton", pickerBox); svMap.Size = UDim2.new(1, -30, 0, 120); svMap.Position = UDim2.new(0, 10, 0, 10); svMap.BackgroundColor3 = Color3.fromHSV(0, 1, 1); svMap.Text = ""; svMap.AutoButtonColor = false; Instance.new("UICorner", svMap).CornerRadius = UDim.new(0,3)
    local svWhite = Instance.new("Frame", svMap); svWhite.Size = UDim2.new(1, 0, 1, 0); svWhite.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", svWhite).CornerRadius = UDim.new(0,3); local gradW = Instance.new("UIGradient", svWhite); gradW.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}
    local svBlack = Instance.new("Frame", svMap); svBlack.Size = UDim2.new(1, 0, 1, 0); svBlack.BackgroundColor3 = Color3.new(0,0,0); Instance.new("UICorner", svBlack).CornerRadius = UDim.new(0,3); local gradB = Instance.new("UIGradient", svBlack); gradB.Rotation = 90; gradB.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}
    local svCursor = Instance.new("Frame", svMap); svCursor.Size = UDim2.new(0,6,0,6); svCursor.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1,0); Instance.new("UIStroke", svCursor)
    local hBar = Instance.new("TextButton", pickerBox); hBar.Size = UDim2.new(0, 10, 0, 120); hBar.Position = UDim2.new(1, -15, 0, 10); hBar.BackgroundColor3 = Color3.new(1,1,1); hBar.Text = ""; Instance.new("UICorner", hBar).CornerRadius = UDim.new(0,3)
    local hGrad = Instance.new("UIGradient", hBar); hGrad.Rotation = 90; hGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))}
    local hCursor = Instance.new("Frame", hBar); hCursor.Size = UDim2.new(1,2,0,4); hCursor.Position = UDim2.new(0,-1,0,0); hCursor.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UIStroke", hCursor)

    local curH, curS, curV = tbl[key]:ToHSV()
    local function applyColor()
        local col = Color3.fromHSV(curH, curS, curV); tbl[key] = col; showBtn.BackgroundColor3 = col
        if key == "ui_accent" then UpdateAccents() end; UpdatePreviewEvent:Fire()
    end
    local hDrag, svDrag = false, false
    hBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then hDrag = true end end)
    svMap.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then hDrag = false; svDrag = false end end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if hDrag then local pct = math.clamp((i.Position.Y - hBar.AbsolutePosition.Y)/hBar.AbsoluteSize.Y, 0, 1); curH = 1 - pct; hCursor.Position = UDim2.new(0, -1, pct, -2); svMap.BackgroundColor3 = Color3.fromHSV(curH, 1, 1); applyColor() end
            if svDrag then local pctX = math.clamp((i.Position.X - svMap.AbsolutePosition.X)/svMap.AbsoluteSize.X, 0, 1); local pctY = math.clamp((i.Position.Y - svMap.AbsolutePosition.Y)/svMap.AbsoluteSize.Y, 0, 1); curS = pctX; curV = 1 - pctY; svCursor.Position = UDim2.new(pctX, -3, pctY, -3); applyColor() end
        end
    end)
    local isOpen = false
    showBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; pickerBox.Visible = isOpen; frame.Size = isOpen and UDim2.new(1, 0, 0, 180) or UDim2.new(1, 0, 0, 24) end)
    
    AddTooltip(frame, tooltipText)
end

-- ================== -- STRONY MENU -- ==================
local colsAim = CreateTab("Legitbot", true)
local colsVis = CreateTab("Visuals", false)
local colsMisc = CreateTab("Misc", false)
local colsSet = CreateTab("Settings", false)

-- AIMBOT
local aSec1 = CreateSection(colsAim.Left, "Aimbot General")
CreateCheckbox(aSec1, "Enable Legitbot", config.toggles, "aim_enabled", "Master switch for aim assistance.")
CreateKeybind(aSec1, "Aimbot Hotkey", config.keybinds, "aimbot", "Hold this key/button to lock onto enemies.")
CreateCheckbox(aSec1, "Draw FOV Circle", config.toggles, "aim_showFov", "Shows the active aimbot target area.")
CreateCheckbox(aSec1, "Visibility Check", config.toggles, "aim_wallCheck", "Prevents locking onto enemies behind walls.")
CreateCheckbox(aSec1, "Velocity Prediction", config.toggles, "aim_predict", "Predicts where the enemy will be moving.")

local aSec3 = CreateSection(colsAim.Right, "Aimbot Configuration")
CreateDropdown(aSec3, "Hitbox", config.selectors, "aim_part", {"Head", "Torso", "Root"}, "Which body part the aimbot should track.")
CreateDropdown(aSec3, "Method", config.selectors, "aim_method", {"Mouse Movement", "Camera Snap"}, "How the aimbot corrects your aim.")
CreateSlider(aSec3, "Field of View", config.sliders, "aim_fov", 10, 600, "The radius of the aimbot targeting zone.")
CreateSlider(aSec3, "Smoothness", config.sliders, "aim_smooth", 1, 20, "Higher value = slower, more human-like aiming.")
CreateSlider(aSec3, "Aim Offset X", config.sliders, "aim_offsetX", -100, 100, "Shifts aim horizontally.")
CreateSlider(aSec3, "Aim Offset Y", config.sliders, "aim_offsetY", -100, 100, "Shifts aim vertically (good for bullet drop).")

-- VISUALS
local vSec1 = CreateSection(colsVis.Left, "Esp Elements")
CreateCheckbox(vSec1, "Master Switch", config, "esp_enabled", "Toggles all visual features on or off.")
CreateCheckbox(vSec1, "Bounding Box", config.toggles, "boxes", "Draws a square around enemies.")
CreateCheckbox(vSec1, "Skeleton", config.toggles, "skeletons", "Draws lines connecting enemy joints.")
CreateCheckbox(vSec1, "Health Bar", config.toggles, "healthbars", "Shows how much HP the enemy has.")

local vSec2 = CreateSection(colsVis.Right, "Information")
CreateCheckbox(vSec2, "Nickname", config.toggles, "names", "Displays the enemy's username.")
CreateCheckbox(vSec2, "Weapon Name", config.toggles, "weapons", "Shows what item the enemy is holding.")
CreateCheckbox(vSec2, "Distance", config.toggles, "distances", "Shows how far away the enemy is.")
CreateDropdown(vSec2, "Tracer Origin", config.selectors, "tracer_origin", {"Bottom", "Center", "Mouse"}, "Where the lines drawn to enemies originate from.")

local vSec3 = CreateSection(colsVis.Right, "Colors")
CreateColorPicker(vSec3, "Enemy ESP Box", config.colors, "enemy_esp", "Color of the ESP boxes & lines.")

-- MISC
local mSec1 = CreateSection(colsMisc.Left, "World Modulation")
CreateCheckbox(mSec1, "Enable Custom Time", config.toggles, "time_changer", "Override the in-game daylight time.")
CreateSlider(mSec1, "Time of Day", config.sliders, "custom_time", 0, 24, "Set the time (0 = Midnight, 12 = Noon).")
CreateCheckbox(mSec1, "Enable Custom FOV", config.toggles, "fov_changer", "Override the game's camera field of view.")
CreateSlider(mSec1, "Camera FOV", config.sliders, "custom_fov", 60, 120, "Adjust how wide your camera view is.")

local mSec2 = CreateSection(colsMisc.Right, "Exploits & Movement")
CreateCheckbox(mSec2, "ACS Godmode", config.toggles, "godmode", "Forces max health & blood in ACS games.")
CreateCheckbox(mSec2, "Bunny Hop", config.toggles, "bhop", "Hold Space to jump automatically.")
CreateCheckbox(mSec2, "Third Person", config.toggles, "third_person", "Forces camera into 3rd person mode.")
CreateCheckbox(mSec2, "Stealth Fly (Undetected)", config.toggles, "fly", "Safe fly method via invisible platform.")
CreateKeybind(mSec2, "Toggle Fly Bind", config.keybinds, "fly", "Press this key to turn Fly ON/OFF.")
CreateSlider(mSec2, "Fly Speed", config.sliders, "fly_speed", 10, 150, "Adjust how fast you fly.")

-- SETTINGS
local sSec1 = CreateSection(colsSet.Left, "Configuration")
CreateCheckbox(sSec1, "Team Check", config, "teamCheck", "Prevents targeting or ESP on your teammates.")
CreateCheckbox(sSec1, "Custom Crosshair", config.toggles, "aim_crosshair", "Draws a custom crosshair in the center.")
CreateCheckbox(sSec1, "Rainbow UI Mode", config.toggles, "rainbow_ui", "Cycles the menu accent color through RGB.")
CreateColorPicker(sSec1, "Menu Accent Color", config.colors, "ui_accent", "Changes the primary color of this menu.")

local btnUnload = Instance.new("TextButton", sSec1); btnUnload.Size = UDim2.new(1, 0, 0, 32); btnUnload.BackgroundColor3 = Color3.fromRGB(35, 20, 25); btnUnload.Text = "UNLOAD SCRIPT"; btnUnload.TextColor3 = config.colors.ui_accent; btnUnload.Font = Enum.Font.GothamBold; btnUnload.TextSize = 12; ApplyAccent(btnUnload, "TextColor3")
Instance.new("UICorner", btnUnload).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", btnUnload).Color = Theme.Border
btnUnload.MouseButton1Click:Connect(function() if _G.AsapwareUnload then _G.AsapwareUnload() end end)
AddTooltip(btnUnload, "Removes the script and drawings entirely.")

UpdatePreviewEvent:Fire()

-- Otwieranie / Zamykanie Menu Oraz Listener Bindowania (Toggle Fly)
local menuOpen = true
local function ToggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        DragContainer.Visible = true
        TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        local tween = TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
        tween:Play()
        tween.Completed:Connect(function() if not menuOpen then DragContainer.Visible = false end end)
    end
end
UIScale.Scale = 1 

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete then ToggleMenu() end
    
    if config.keybinds.fly then
        if input.KeyCode == config.keybinds.fly or input.UserInputType == config.keybinds.fly then
            config.toggles.fly = not config.toggles.fly
            UpdatePreviewEvent:Fire() 
        end
    end
end)

-- ==========================================
-- LOGIKA RYSOWANIA I ESP
-- ==========================================
local ESP_Data = {}
local AllDrawings = {}
local function CreateDraw(Type, Properties) local obj = Drawing.new(Type); for k, v in pairs(Properties) do obj[k] = v end; table.insert(AllDrawings, obj); return obj end

local FOV_Circle = CreateDraw("Circle", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Filled = false})

local CrossTop = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossBot = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossLeft = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
local CrossRight = CreateDraw("Line", {Thickness = 2, Color = config.colors.ui_accent})
table.insert(UIThemeObjects, {Obj = CrossTop, Prop = "Color"}); table.insert(UIThemeObjects, {Obj = CrossBot, Prop = "Color"})
table.insert(UIThemeObjects, {Obj = CrossLeft, Prop = "Color"}); table.insert(UIThemeObjects, {Obj = CrossRight, Prop = "Color"})

local function SetupESP(player)
    if ESP_Data[player] then return end
    ESP_Data[player] = {
        BoxOutline = CreateDraw("Square", {Filled = false, Color = ESP_COLORS.Outline}),
        Box = CreateDraw("Square", {Filled = false}),
        HealthOutline = CreateDraw("Square", {Filled = true, Color = ESP_COLORS.Outline}),
        HealthBar = CreateDraw("Square", {Filled = true}),
        HealthText = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = Color3.fromRGB(255,255,255)}),
        Name = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255,255,255)}),
        Distance = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 11, Color = Theme.TextGray}),
        Weapon = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 11, Color = Color3.fromRGB(180,180,220)}),
        Tracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.5}),
        SkeletonLines = {}
    }
end
local function RemoveESP(player) 
    if ESP_Data[player] then 
        for k, v in pairs(ESP_Data[player]) do 
            if k == "SkeletonLines" then 
                for _, l in ipairs(v) do l:Remove() end 
            else v:Remove() end 
        end
        ESP_Data[player] = nil 
    end 
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
Players.PlayerAdded:Connect(SetupESP); Players.PlayerRemoving:Connect(RemoveESP)

local function GetAimPart(char)
    local sel = config.selectors.aim_part; return sel == 1 and char:FindFirstChild("Head") or sel == 2 and char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end
local function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    GlobalRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(origin, (targetPart.Position - origin), GlobalRaycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetBones(char)
    local bones = {}
    if char:FindFirstChild("UpperTorso") then
        local pairs = { {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"} }
        for _, p in ipairs(pairs) do local p1, p2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2]); if p1 and p2 then table.insert(bones, {p1, p2}) end end
    elseif char:FindFirstChild("Torso") then
        local pairs = { {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"} }
        for _, p in ipairs(pairs) do local p1, p2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2]); if p1 and p2 then table.insert(bones, {p1, p2}) end end
    end return bones
end

-- ==========================================
-- GŁÓWNA PĘTLA (RENDER STEPPED) ZOPTYMALIZOWANA
-- ==========================================
RunService:BindToRenderStep("AsapwareMain", Enum.RenderPriority.Camera.Value + 1, function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    local cTick = tick()
    
    -- RGB UI
    if config.toggles.rainbow_ui then
        local hue = cTick % 5 / 5
        config.colors.ui_accent = Color3.fromHSV(hue, 0.8, 1)
        UpdateAccents()
        UpdatePreviewEvent:Fire()
    end
    
    -- MISC
    if config.toggles.time_changer then Lighting.ClockTime = config.sliders.custom_time end
    if config.toggles.fov_changer then Camera.FieldOfView = config.sliders.custom_fov end
    
    if config.toggles.third_person then
        LocalPlayer.CameraMaxZoomDistance = 12; LocalPlayer.CameraMinZoomDistance = 12
    else
        LocalPlayer.CameraMaxZoomDistance = 400; LocalPlayer.CameraMinZoomDistance = 0.5
    end
    
    if config.toggles.bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not config.toggles.fly then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
    end
    
    -- ACS GODMODE (Zoptymalizowane pod nadpisywanie zmiennych ACS)
    if config.toggles.godmode then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
            
            local h = char:FindFirstChild("Health")
            if h and (h:IsA("NumberValue") or h:IsA("IntValue")) then h.Value = 100 end
            
            local b = char:FindFirstChild("Blood")
            if b and (b:IsA("NumberValue") or b:IsA("IntValue")) then b.Value = 100 end
            
            local vars = char:FindFirstChild("ACS_Modulo") and char.ACS_Modulo:FindFirstChild("Variaveis")
            if vars then
                local vH = vars:FindFirstChild("Health")
                if vH then vH.Value = 100 end
                local vB = vars:FindFirstChild("Blood")
                if vB then vB.Value = 100 end
                local vBleed = vars:FindFirstChild("Bleeding")
                if vBleed then vBleed.Value = 0 end
            end
        end
    end
    
    -- STEALTH FLY
    if config.toggles.fly then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            if not flyPlatform then
                flyPlatform = Instance.new("Part", Workspace)
                flyPlatform.Name = "AntiAC_Platform_Fly"
                flyPlatform.Size = Vector3.new(6, 1, 6)
                flyPlatform.Transparency = 1
                flyPlatform.Anchored = true
                flyPlatform.CanCollide = true
            end
            
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

            hrp.Velocity = Vector3.zero
            hrp.CFrame = hrp.CFrame + (moveDir * (config.sliders.fly_speed / 20))
            
            flyPlatform.CFrame = hrp.CFrame * CFrame.new(0, -3.2, 0)
        end
    else
        if flyPlatform then flyPlatform:Destroy(); flyPlatform = nil end
    end
    
    -- PREVIEW 3D
    if Preview.Visible then
        local t = cTick * 0.8
        local rad = 8
        VPF_Cam.CFrame = CFrame.new(Vector3.new(math.sin(t) * rad, 1.5, math.cos(t) * rad), Torso.Position)
        
        if config.toggles.skeletons then
            local pPairs = { {Head, Torso}, {Torso, LArm}, {Torso, RArm}, {Torso, LLeg}, {Torso, RLeg} }
            for i, p in ipairs(pPairs) do
                local pos1, on1 = VPF_Cam:WorldToViewportPoint(p[1].Position)
                local pos2, on2 = VPF_Cam:WorldToViewportPoint(p[2].Position)
                if on1 and on2 then
                    S_Lines[i].Visible = true
                    local v1, v2 = Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y)
                    local dist = (v2 - v1).Magnitude
                    S_Lines[i].Size = UDim2.new(0, dist, 0, 1.5)
                    S_Lines[i].Position = UDim2.new(0, (v1.X + v2.X)/2, 0, (v1.Y + v2.Y)/2)
                    S_Lines[i].Rotation = math.deg(math.atan2(v2.Y - v1.Y, v2.X - v1.X))
                else S_Lines[i].Visible = false end
            end
        else for _, l in ipairs(S_Lines) do l.Visible = false end end
    end

    -- AIMBOT & CROSSHAIR
    FOV_Circle.Position = mouseLoc; FOV_Circle.Radius = config.sliders.aim_fov; FOV_Circle.Visible = config.toggles.aim_showFov and config.toggles.aim_enabled
    
    local cSize, cGap = 6, 4
    CrossTop.From = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap); CrossTop.To = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap - cSize); CrossTop.Visible = config.toggles.aim_crosshair
    CrossBot.From = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap); CrossBot.To = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap + cSize); CrossBot.Visible = config.toggles.aim_crosshair
    CrossLeft.From = Vector2.new(mouseLoc.X - cGap, mouseLoc.Y); CrossLeft.To = Vector2.new(mouseLoc.X - cGap - cSize, mouseLoc.Y); CrossLeft.Visible = config.toggles.aim_crosshair
    CrossRight.From = Vector2.new(mouseLoc.X + cGap, mouseLoc.Y); CrossRight.To = Vector2.new(mouseLoc.X + cGap + cSize, mouseLoc.Y); CrossRight.Visible = config.toggles.aim_crosshair

    local isAiming = false
    local aBind = config.keybinds.aimbot
    if aBind then
        if typeof(aBind) == "EnumItem" then
            if aBind.EnumType == Enum.KeyCode then
                isAiming = UserInputService:IsKeyDown(aBind)
            elseif aBind.EnumType == Enum.UserInputType then
                isAiming = UserInputService:IsMouseButtonPressed(aBind)
            end
        end
    end

    local closestTarget = nil; local shortestDist = math.huge

    if config.toggles.aim_enabled and isAiming then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
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
                            local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                            if dist <= config.sliders.aim_fov and dist < shortestDist then
                                if not config.toggles.aim_wallCheck or IsVisible(aimPart) then 
                                    shortestDist = dist; closestTarget = targetPos 
                                end
                            end
                        end
                    end
                end
            end
        end

        if closestTarget then
            local smooth = config.sliders.aim_smooth
            if config.selectors.aim_method == 1 then
                local pos = Camera:WorldToScreenPoint(closestTarget)
                local diffX = (pos.X + config.sliders.aim_offsetX) - mouseLoc.X
                local diffY = (pos.Y + config.sliders.aim_offsetY) - mouseLoc.Y
                if mousemoverel then mousemoverel(diffX / smooth, diffY / smooth) else Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), 1 / smooth) end
            else Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), 1 / smooth) end
        end
    end

    -- ZOPTYMALIZOWANE ESP
    local t_Thick = config.sliders.boxThickness
    for player, esp in pairs(ESP_Data) do
        local isVisible = false
        local char = player.Character

        if config.esp_enabled and char and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
            local hp, maxHp = GetHealth(player)
            
            if hp > 0 then
                local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    
                    if onScreen and dist <= config.sliders.esp_distance then
                        isVisible = true
                        local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
                        local botPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                        local boxH = botPos.Y - topPos.Y; local boxW = boxH / 1.8; local boxX = pos.X - (boxW / 2); local boxY = topPos.Y

                        if config.toggles.boxes then
                            esp.BoxOutline.Thickness = t_Thick + 2; esp.BoxOutline.Size = Vector2.new(boxW, boxH); esp.BoxOutline.Position = Vector2.new(boxX, boxY); esp.BoxOutline.Visible = true
                            esp.Box.Thickness = t_Thick; esp.Box.Size = Vector2.new(boxW, boxH); esp.Box.Position = Vector2.new(boxX, boxY); esp.Box.Color = config.colors.enemy_esp; esp.Box.Visible = true
                        else esp.BoxOutline.Visible = false; esp.Box.Visible = false end

                        if config.toggles.healthbars then
                            local hpPct = math.clamp(hp / maxHp, 0, 1); local barH = boxH * hpPct
                            esp.HealthOutline.Size = Vector2.new(4, boxH + 2); esp.HealthOutline.Position = Vector2.new(boxX - 7, boxY - 1); esp.HealthOutline.Visible = true
                            esp.HealthBar.Size = Vector2.new(2, barH); esp.HealthBar.Position = Vector2.new(boxX - 6, boxY + (boxH - barH)); esp.HealthBar.Color = Color3.fromRGB(255 - (hpPct * 255), hpPct * 255, 30); esp.HealthBar.Visible = true
                            if config.toggles.healthtext and hp < maxHp then esp.HealthText.Text = tostring(math.floor(hp)); esp.HealthText.Position = Vector2.new(boxX - 18, boxY + (boxH - barH) - 6); esp.HealthText.Visible = true else esp.HealthText.Visible = false end
                        else esp.HealthOutline.Visible = false; esp.HealthBar.Visible = false; esp.HealthText.Visible = false end

                        if config.toggles.names then esp.Name.Text = player.Name; esp.Name.Position = Vector2.new(pos.X, boxY - 18); esp.Name.Visible = true else esp.Name.Visible = false end
                        
                        local bottomY = boxY + boxH + 3
                        if config.toggles.distances then esp.Distance.Text = "[" .. math.floor(dist) .. "m]"; esp.Distance.Position = Vector2.new(pos.X, bottomY); esp.Distance.Visible = true; bottomY = bottomY + 14 else esp.Distance.Visible = false end
                        if config.toggles.weapons then local tool = char:FindFirstChildOfClass("Tool"); if tool then esp.Weapon.Text = tool.Name; esp.Weapon.Position = Vector2.new(pos.X, bottomY); esp.Weapon.Visible = true else esp.Weapon.Visible = false end else esp.Weapon.Visible = false end

                        if config.toggles.tracers then
                            local origin = screenCenter
                            if config.selectors.tracer_origin == 2 then origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) elseif config.selectors.tracer_origin == 3 then origin = mouseLoc end
                            esp.Tracer.From = origin; esp.Tracer.To = Vector2.new(pos.X, botPos.Y); esp.Tracer.Color = config.colors.enemy_esp; esp.Tracer.Visible = true
                        else esp.Tracer.Visible = false end
                        
                        if config.toggles.skeletons then
                            local bones = GetBones(char)
                            for i, p in ipairs(bones) do
                                local p1, on1 = Camera:WorldToViewportPoint(p[1].Position); local p2, on2 = Camera:WorldToViewportPoint(p[2].Position)
                                if on1 and on2 then
                                    if not esp.SkeletonLines[i] then esp.SkeletonLines[i] = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Skeleton, Transparency = 0.8}) end
                                    esp.SkeletonLines[i].From = Vector2.new(p1.X, p1.Y); esp.SkeletonLines[i].To = Vector2.new(p2.X, p2.Y); esp.SkeletonLines[i].Visible = true
                                elseif esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                            end
                            for i = #bones + 1, #esp.SkeletonLines do esp.SkeletonLines[i].Visible = false end
                        else for _, l in ipairs(esp.SkeletonLines) do l.Visible = false end end
                    end
                end
            end
        end
        
        if not isVisible then 
            esp.BoxOutline.Visible = false; esp.Box.Visible = false
            esp.HealthOutline.Visible = false; esp.HealthBar.Visible = false; esp.HealthText.Visible = false
            esp.Name.Visible = false; esp.Distance.Visible = false; esp.Weapon.Visible = false; esp.Tracer.Visible = false
            for _, l in ipairs(esp.SkeletonLines) do l.Visible = false end
        end
    end
end)

_G.AsapwareUnload = function()
    RunService:UnbindFromRenderStep("AsapwareMain")
    if ScreenGui then ScreenGui:Destroy() end
    if flyPlatform then flyPlatform:Destroy() end
    for _, esp in pairs(ESP_Data) do for k, v in pairs(esp) do if k == "SkeletonLines" then for _, l in ipairs(v) do l:Remove() end else v:Remove() end end end
    table.clear(ESP_Data)
    for _, obj in ipairs(AllDrawings) do if obj.Remove then obj:Remove() end end
    table.clear(AllDrawings)
    _G.AsapwareUnload = nil
end

print("ASAPWARE V6 (ACS GODMODE): Załadowano! Wciśnij [INSERT], aby otworzyć.")
