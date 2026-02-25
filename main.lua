--- START OF FILE Paste February 25, 2026 - ASAPWARE V12 (PREMIUM THEME, TOOLTIPS, SYNCED ANIMATIONS) ---

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
-- 1. KONFIGURACJA
-- ==========================================
local config = {
    esp_enabled = true,
    teamCheck = false,
    toggles = {
        boxes = true,
        healthbars = true,
        healthtext = true,
        names = true,
        weapons = true,
        distances = true,
        skeletons = true,
        tracers = false,
        aim_enabled = false,
        aim_showFov = true,
        aim_crosshair = true,
        aim_wallCheck = true,
        aim_predict = false,
        time_changer = false,
        fov_changer = false,
        rainbow_ui = false,
        bhop = false,
        third_person = false,
        fly = false,
        godmode = false
    },
    sliders = {
        esp_distance = 1500,
        boxThickness = 1,
        aim_distance = 1500,
        aim_fov = 100,
        aim_smooth = 5,
        aim_offsetX = 0,
        aim_offsetY = 36,
        aim_pred_amt = 10,
        custom_time = 12,
        custom_fov = 90,
        fly_speed = 50
    },
    colors = {
        enemy_esp = Color3.fromRGB(255, 75, 75),
        ui_accent = Color3.fromRGB(120, 160, 255) 
    },
    selectors = {
        aim_part = 1,
        aim_method = 2,
        tracer_origin = 1
    },
    keybinds = {
        aimbot = Enum.UserInputType.MouseButton2,
        fly = Enum.KeyCode.F,
        menu = Enum.KeyCode.Insert
    }
}

local ESP_COLORS = {
    Outline = Color3.fromRGB(10, 10, 12),
    Skeleton = Color3.fromRGB(255, 255, 255)
}

local flyPlatform = nil
local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true

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
-- 2. NOWY, PROFESJONALNY MOTYW UI
-- ==========================================
local TargetGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AsapwarePerfection"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

local Theme = {
    BG = Color3.fromRGB(12, 12, 15),
    SidebarBG = Color3.fromRGB(16, 16, 20),
    CardBG = Color3.fromRGB(20, 20, 24),
    Border = Color3.fromRGB(35, 35, 42),
    InputBG = Color3.fromRGB(26, 26, 32),
    InputHover = Color3.fromRGB(36, 36, 42),
    TextWhite = Color3.fromRGB(240, 240, 245),
    TextGray = Color3.fromRGB(140, 140, 155),
    PreviewGrid = Color3.fromRGB(8, 8, 10),
    FontMain = Enum.Font.Montserrat,
    FontCode = Enum.Font.RobotoMono
}

local DragContainer = Instance.new("Frame", ScreenGui)
DragContainer.Size = UDim2.new(0, 1040, 0, 590)
DragContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
DragContainer.AnchorPoint = Vector2.new(0.5, 0.5)
DragContainer.BackgroundTransparency = 1

local UIScale = Instance.new("UIScale", DragContainer)
UIScale.Scale = 0 

-- System Przeciągania
local dragging, dragInput, dragStart, startPos

DragContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = DragContainer.Position
    end
end)

DragContainer.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        DragContainer.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local UpdatePreviewEvent = Instance.new("BindableEvent")
local UIThemeObjects = {}

local function ApplyAccent(obj, property)
    table.insert(UIThemeObjects, {Obj = obj, Prop = property})
    obj[property] = config.colors.ui_accent
end

local function UpdateAccents()
    for _, item in ipairs(UIThemeObjects) do
        if item.Obj.Parent then
            item.Obj[item.Prop] = config.colors.ui_accent
        end
    end
end

-- ================== -- SYSTEM TOOLTIP (OPISY) -- ==================
local TooltipGui = Instance.new("Frame", ScreenGui)
TooltipGui.BackgroundColor3 = Theme.BG
TooltipGui.Size = UDim2.new(0, 200, 0, 28)
TooltipGui.Visible = false
TooltipGui.ZIndex = 1000
Instance.new("UICorner", TooltipGui).CornerRadius = UDim.new(0, 6)
local TooltipStroke = Instance.new("UIStroke", TooltipGui)
TooltipStroke.Color = Theme.Border

local TooltipText = Instance.new("TextLabel", TooltipGui)
TooltipText.Size = UDim2.new(1, -20, 1, 0)
TooltipText.Position = UDim2.new(0, 10, 0, 0)
TooltipText.BackgroundTransparency = 1
TooltipText.TextColor3 = Theme.TextGray
TooltipText.Font = Theme.FontMain
TooltipText.TextSize = 12
TooltipText.TextXAlignment = Enum.TextXAlignment.Left
TooltipText.ZIndex = 1001

local function AddTooltip(element, text)
    if not text or text == "" then return end
    element.MouseEnter:Connect(function()
        TooltipText.Text = text
        local bounds = TooltipText.TextBounds
        TooltipGui.Size = UDim2.new(0, bounds.X + 20, 0, 26)
        TooltipGui.Visible = true
    end)
    element.MouseLeave:Connect(function()
        TooltipGui.Visible = false
    end)
end

RunService.RenderStepped:Connect(function()
    if TooltipGui.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        TooltipGui.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y + 15)
    end
end)

-- ================== -- 3. SIDEBAR & AVATAR -- ==================
local Sidebar = Instance.new("Frame", DragContainer)
Sidebar.Size = UDim2.new(0, 240, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBG
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Sidebar).Color = Theme.Border

local TopLine1 = Instance.new("Frame", Sidebar)
TopLine1.Size = UDim2.new(1, 0, 0, 3)
TopLine1.BorderSizePixel = 0
ApplyAccent(TopLine1, "BackgroundColor3")
Instance.new("UICorner", TopLine1).CornerRadius = UDim.new(0, 8)

local LogoArea = Instance.new("Frame", Sidebar)
LogoArea.Size = UDim2.new(1, 0, 0, 100)
LogoArea.BackgroundTransparency = 1

local LogoIcon = Instance.new("TextLabel", LogoArea)
LogoIcon.Size = UDim2.new(1, 0, 1, -20)
LogoIcon.Position = UDim2.new(0, 0, 0, 15)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Text = "ASAPWARE"
LogoIcon.TextColor3 = Theme.TextWhite
LogoIcon.Font = Enum.Font.GothamBlack
LogoIcon.TextSize = 24

local LogoSub = Instance.new("TextLabel", LogoArea)
LogoSub.Size = UDim2.new(1, 0, 0, 20)
LogoSub.Position = UDim2.new(0, 0, 0, 60)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "P E R F E C T I O N"
LogoSub.Font = Enum.Font.GothamBold
LogoSub.TextSize = 10
ApplyAccent(LogoSub, "TextColor3")

local ProfileArea = Instance.new("Frame", Sidebar)
ProfileArea.Size = UDim2.new(1, -30, 0, 54)
ProfileArea.Position = UDim2.new(0, 15, 1, -70)
ProfileArea.BackgroundColor3 = Theme.InputBG
ProfileArea.BorderSizePixel = 0
Instance.new("UICorner", ProfileArea).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ProfileArea).Color = Theme.Border

local Avatar = Instance.new("ImageLabel", ProfileArea)
Avatar.Size = UDim2.new(0, 34, 0, 34)
Avatar.Position = UDim2.new(0, 10, 0.5, -17)
Avatar.BackgroundColor3 = Theme.Border
Avatar.BorderSizePixel = 0
Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    pcall(function()
        local image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        Avatar.Image = image
    end)
end)

local Username = Instance.new("TextLabel", ProfileArea)
Username.Size = UDim2.new(1, -60, 0, 20)
Username.Position = UDim2.new(0, 54, 0.5, -10)
Username.BackgroundTransparency = 1
Username.Text = LocalPlayer.Name
Username.TextColor3 = Theme.TextWhite
Username.Font = Theme.FontMain
Username.TextSize = 13
Username.TextXAlignment = Enum.TextXAlignment.Left

-- ================== -- 4. 3D PREVIEW (NAPRAWIONE NAKŁADANIE) -- ==================
local Preview = Instance.new("Frame", DragContainer)
Preview.Size = UDim2.new(0, 350, 1, 0)
Preview.Position = UDim2.new(1, -350, 0, 0)
Preview.BackgroundColor3 = Theme.BG
Preview.BorderSizePixel = 0
Preview.Visible = false
Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Preview).Color = Theme.Border

local TopLine3 = Instance.new("Frame", Preview)
TopLine3.Size = UDim2.new(1, 0, 0, 3)
TopLine3.BorderSizePixel = 0
ApplyAccent(TopLine3, "BackgroundColor3")
Instance.new("UICorner", TopLine3).CornerRadius = UDim.new(0, 8)

local PrevTitle = Instance.new("TextLabel", Preview)
PrevTitle.Size = UDim2.new(1, -40, 0, 60)
PrevTitle.Position = UDim2.new(0, 20, 0, 0)
PrevTitle.BackgroundTransparency = 1
PrevTitle.Text = "Live Visuals"
PrevTitle.TextColor3 = Theme.TextWhite
PrevTitle.Font = Enum.Font.GothamBold
PrevTitle.TextSize = 15
PrevTitle.TextXAlignment = Enum.TextXAlignment.Left

local ViewportContainer = Instance.new("Frame", Preview)
ViewportContainer.Size = UDim2.new(1, -30, 1, -120)
ViewportContainer.Position = UDim2.new(0, 15, 0, 60)
ViewportContainer.BackgroundColor3 = Theme.PreviewGrid
Instance.new("UICorner", ViewportContainer).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ViewportContainer).Color = Theme.Border
ViewportContainer.ClipsDescendants = true

local GridPattern = Instance.new("ImageLabel", ViewportContainer)
GridPattern.Size = UDim2.new(1, 0, 1, 0)
GridPattern.BackgroundTransparency = 1
GridPattern.Image = "rbxassetid://8992429408"
GridPattern.ImageTransparency = 0.8
GridPattern.ImageColor3 = Theme.Border
GridPattern.ScaleType = Enum.ScaleType.Tile
GridPattern.TileSize = UDim2.new(0, 40, 0, 40)

local VPF = Instance.new("ViewportFrame", ViewportContainer)
VPF.Size = UDim2.new(1, 0, 1, 0)
VPF.BackgroundTransparency = 1
VPF.Ambient = Color3.fromRGB(180, 180, 190)
VPF.LightColor = Color3.fromRGB(255, 255, 255)
VPF.LightDirection = Vector3.new(-1, -1, -1)

local VPF_Cam = Instance.new("Camera")
VPF.CurrentCamera = VPF_Cam

local DummyModel = Instance.new("Model", VPF)

local function MakePart(name, size, pos, color, mat)
    local p = Instance.new("Part", DummyModel)
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(pos)
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Color = color or Color3.fromRGB(50, 55, 60)
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local Head = MakePart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.5, 0))
local Torso = MakePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
local LArm = MakePart("LArm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0))
local RArm = MakePart("RArm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0))
local LLeg = MakePart("LLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
local RLeg = MakePart("RLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
MakePart("Base", Vector3.new(8, 0.2, 8), Vector3.new(0, -3.1, 0), Color3.fromRGB(20, 20, 24), Enum.Material.Neon)

DummyModel.PrimaryPart = Torso

-- Overlay ESP 2D
local Overlay = Instance.new("Frame", ViewportContainer)
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundTransparency = 1

local P_Box = Instance.new("Frame", Overlay)
P_Box.BackgroundTransparency = 1
local P_BoxStr = Instance.new("UIStroke", P_Box)
P_BoxStr.Thickness = 1.5
ApplyAccent(P_BoxStr, "Color")

local P_HealthBg = Instance.new("Frame", P_Box)
P_HealthBg.Size = UDim2.new(0, 3, 1, 0)
P_HealthBg.Position = UDim2.new(0, -7, 0, 0)
P_HealthBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
P_HealthBg.BorderSizePixel = 0

local P_HealthFill = Instance.new("Frame", P_HealthBg)
P_HealthFill.Size = UDim2.new(1, 0, 0.8, 0)
P_HealthFill.Position = UDim2.new(0, 0, 0.2, 0)
P_HealthFill.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
P_HealthFill.BorderSizePixel = 0

local P_HealthTxt = Instance.new("TextLabel", P_HealthBg)
P_HealthTxt.Size = UDim2.new(0, 20, 0, 15)
P_HealthTxt.Position = UDim2.new(0, -22, 0.2, -7)
P_HealthTxt.BackgroundTransparency = 1
P_HealthTxt.Text = "80"
P_HealthTxt.TextColor3 = Color3.new(1, 1, 1)
P_HealthTxt.Font = Theme.FontCode
P_HealthTxt.TextSize = 10
P_HealthTxt.TextXAlignment = Enum.TextXAlignment.Right

local P_Name = Instance.new("TextLabel", P_Box)
P_Name.Size = UDim2.new(1, 0, 0, 15)
P_Name.AnchorPoint = Vector2.new(0.5, 1)
P_Name.Position = UDim2.new(0.5, 0, 0, -3)
P_Name.BackgroundTransparency = 1
P_Name.Text = "Enemy Dummy"
P_Name.TextColor3 = Color3.new(1, 1, 1)
P_Name.Font = Theme.FontMain
P_Name.TextSize = 12

local InfoContainer = Instance.new("Frame", P_Box)
InfoContainer.Size = UDim2.new(1, 0, 0, 40)
InfoContainer.AnchorPoint = Vector2.new(0.5, 0)
InfoContainer.Position = UDim2.new(0.5, 0, 1, 3)
InfoContainer.BackgroundTransparency = 1

local InfoLayout = Instance.new("UIListLayout", InfoContainer)
InfoLayout.Padding = UDim.new(0, 2)
InfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder

local P_Distance = Instance.new("TextLabel", InfoContainer)
P_Distance.Size = UDim2.new(1, 0, 0, 12)
P_Distance.BackgroundTransparency = 1
P_Distance.Text = "[45m]"
P_Distance.TextColor3 = Theme.TextGray
P_Distance.Font = Theme.FontCode
P_Distance.TextSize = 11
P_Distance.LayoutOrder = 1

local P_Weapon = Instance.new("TextLabel", InfoContainer)
P_Weapon.Size = UDim2.new(1, 0, 0, 12)
P_Weapon.BackgroundTransparency = 1
P_Weapon.Text = "AK-47"
P_Weapon.TextColor3 = Color3.fromRGB(200, 200, 220)
P_Weapon.Font = Theme.FontCode
P_Weapon.TextSize = 11
P_Weapon.LayoutOrder = 2

local P_Tracer = Instance.new("Frame", Overlay)
P_Tracer.BorderSizePixel = 0
P_Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
ApplyAccent(P_Tracer, "BackgroundColor3")

local S_Lines = {}
for i = 1, 5 do
    local f = Instance.new("Frame", Overlay)
    f.BackgroundColor3 = Color3.new(1, 1, 1)
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    table.insert(S_Lines, f)
end

-- ULEPSZONE PIGUŁKI 
local PreviewControls = Instance.new("ScrollingFrame", Preview)
PreviewControls.Size = UDim2.new(1, -30, 0, 45)
PreviewControls.Position = UDim2.new(0, 15, 1, -55)
PreviewControls.BackgroundTransparency = 1
PreviewControls.ScrollBarThickness = 0
PreviewControls.CanvasSize = UDim2.new(1.8, 0, 0, 0)

local PillLayout = Instance.new("UIListLayout", PreviewControls)
PillLayout.Padding = UDim.new(0, 8)
PillLayout.FillDirection = Enum.FillDirection.Horizontal
PillLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function CreatePreviewPill(text, key, desc)
    local btn = Instance.new("TextButton", PreviewControls)
    btn.Size = UDim2.new(0, 0, 0, 26)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = Theme.InputBG
    btn.Text = "   " .. text .. "   "
    btn.TextColor3 = Theme.TextGray
    btn.Font = Enum.Font.Ubuntu
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local str = Instance.new("UIStroke", btn)
    str.Color = Theme.Border
    
    UpdatePreviewEvent.Event:Connect(function()
        if config.toggles[key] then
            str.Color = config.colors.ui_accent
            btn.TextColor3 = Theme.TextWhite
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        else
            str.Color = Theme.Border
            btn.TextColor3 = Theme.TextGray
            btn.BackgroundColor3 = Theme.InputBG
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        config.toggles[key] = not config.toggles[key]
        UpdatePreviewEvent:Fire()
    end)
    
    AddTooltip(btn, desc)
end

CreatePreviewPill("Box", "boxes", "Test rendering of the bounding box.")
CreatePreviewPill("Name", "names", "Test rendering of the player name.")
CreatePreviewPill("Health", "healthbars", "Test the health bar placement.")
CreatePreviewPill("HP Text", "healthtext", "Test the numeric health value.")
CreatePreviewPill("Distance", "distances", "Test the distance rendering.")
CreatePreviewPill("Weapon", "weapons", "Test the weapon text.")
CreatePreviewPill("Skeleton", "skeletons", "Test the bone lines rendering.")
CreatePreviewPill("Tracer", "tracers", "Test the snapline rendering.")

local camRadius = 9
local camAngleX = math.rad(45)
local camAngleY = math.rad(15)
local isDraggingPreview = false
local lastMousePos

ViewportContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingPreview = true
        lastMousePos = input.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingPreview and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - lastMousePos
        camAngleX = camAngleX - math.rad(delta.X * 0.7)
        camAngleY = math.clamp(camAngleY - math.rad(delta.Y * 0.7), math.rad(-70), math.rad(70))
        lastMousePos = input.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingPreview = false
    end
end)

-- ================== -- 5. PANEL GŁÓWNY & KOMPONENTY -- ==================
local Main = Instance.new("Frame", DragContainer)
Main.Size = UDim2.new(1, -590, 1, 0)
Main.Position = UDim2.new(0, 240, 0, 0)
Main.BackgroundColor3 = Theme.BG
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Theme.Border

local TopLine2 = Instance.new("Frame", Main)
TopLine2.Size = UDim2.new(1, 0, 0, 3)
TopLine2.BorderSizePixel = 0
ApplyAccent(TopLine2, "BackgroundColor3")
Instance.new("UICorner", TopLine2).CornerRadius = UDim.new(0, 8)

local Breadcrumb = Instance.new("TextLabel", Main)
Breadcrumb.Size = UDim2.new(1, -40, 0, 60)
Breadcrumb.Position = UDim2.new(0, 20, 0, 0)
Breadcrumb.BackgroundTransparency = 1
Breadcrumb.RichText = true
Breadcrumb.TextColor3 = Theme.TextGray
Breadcrumb.Font = Theme.FontMain
Breadcrumb.TextSize = 14
Breadcrumb.TextXAlignment = Enum.TextXAlignment.Left

-- Wymagany CanvasGroup dla zanikania (Transparency) podczas zmiany zakładek
local TabPages = Instance.new("CanvasGroup", Main)
TabPages.Size = UDim2.new(1, 0, 1, -60)
TabPages.Position = UDim2.new(0, 0, 0, 60)
TabPages.BackgroundTransparency = 1

local Tabs = {}
local isSwitchingTab = false

local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -30, 0, 42)
    btn.Position = UDim2.new(0, 15, 0, 95 + (#Tabs * 48))
    btn.BackgroundTransparency = 1
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 3, isFirst and 0.6 or 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    ApplyAccent(indicator, "BackgroundColor3")

    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.new(0, 15, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = name
    txt.TextColor3 = isFirst and Theme.TextWhite or Theme.TextGray
    txt.Font = Theme.FontMain
    txt.TextSize = 13
    txt.TextXAlignment = Enum.TextXAlignment.Left
    
    local page = Instance.new("ScrollingFrame", TabPages)
    page.Size = UDim2.new(1, -30, 1, -20)
    page.Position = isFirst and UDim2.new(0, 15, 0, 0) or UDim2.new(0, 15, 0, 50)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Border
    page.Visible = isFirst
    page.BorderSizePixel = 0
    
    local colLeft = Instance.new("Frame", page)
    colLeft.Size = UDim2.new(0.48, 0, 0, 0)
    colLeft.BackgroundTransparency = 1
    colLeft.AutomaticSize = Enum.AutomaticSize.Y
    
    local colRight = Instance.new("Frame", page)
    colRight.Size = UDim2.new(0.48, 0, 0, 0)
    colRight.Position = UDim2.new(0.52, 0, 0, 0)
    colRight.BackgroundTransparency = 1
    colRight.AutomaticSize = Enum.AutomaticSize.Y
    
    Instance.new("UIListLayout", colLeft).Padding = UDim.new(0, 15)
    Instance.new("UIListLayout", colRight).Padding = UDim.new(0, 15)
    
    table.insert(Tabs, {Btn = btn, Txt = txt, Ind = indicator, Page = page, Name = name})
    
    btn.MouseButton1Click:Connect(function()
        if isSwitchingTab then return end
        
        -- Sprawdzenie czy kliknieto w ten sam tab
        local isAlreadyActive = false
        for _, t in ipairs(Tabs) do
            if t.Name == name and t.Page.Visible then isAlreadyActive = true end
        end
        if isAlreadyActive then return end
        
        isSwitchingTab = true
        
        -- Schowanie starych zakładek (Z TIMEOUTEM)
        for _, t in ipairs(Tabs) do 
            t.Txt.TextColor3 = Theme.TextGray
            t.Btn.BackgroundColor3 = Theme.SidebarBG
            TweenService:Create(t.Ind, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 0)}):Play()
            if t.Name ~= name and t.Page.Visible then
                TweenService:Create(t.Page, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Position = UDim2.new(0, 15, 0, -30)}):Play()
                TweenService:Create(TabPages, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
                task.delay(0.2, function() t.Page.Visible = false end)
            end
        end
        
        task.wait(0.25) -- TIMEOUT dla płynnego przejścia
        
        txt.TextColor3 = Theme.TextWhite
        btn.BackgroundColor3 = Theme.InputBG
        TweenService:Create(indicator, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0.6, 0)}):Play()
        
        page.Visible = true
        page.Position = UDim2.new(0, 15, 0, 30)
        TweenService:Create(page, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 15, 0, 0)}):Play()
        TweenService:Create(TabPages, TweenInfo.new(0.3), {GroupTransparency = 0}):Play()
        
        local hex = string.format("#%02X%02X%02X", config.colors.ui_accent.R*255, config.colors.ui_accent.G*255, config.colors.ui_accent.B*255)
        Breadcrumb.Text = "Menu <font color='"..hex.."'> / " .. name .. "</font>"
        
        if name == "Visuals" then 
            Preview.Visible = true
            TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, -590, 1, 0)}):Play()
        else 
            Preview.Visible = false
            TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, -240, 1, 0)}):Play()
        end
        
        task.wait(0.35)
        isSwitchingTab = false
    end)
    
    btn.MouseEnter:Connect(function()
        if not page.Visible then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.InputHover}):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if not page.Visible then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SidebarBG}):Play()
        end
    end)
    
    if isFirst then
        local hex = string.format("#%02X%02X%02X", config.colors.ui_accent.R*255, config.colors.ui_accent.G*255, config.colors.ui_accent.B*255)
        Breadcrumb.Text = "Menu <font color='"..hex.."'> / " .. name .. "</font>"
        btn.BackgroundColor3 = Theme.InputBG
    end
    
    local function updateCanvas()
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(colLeft.AbsoluteSize.Y, colRight.AbsoluteSize.Y) + 20)
    end
    colLeft:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
    colRight:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
    
    return {Left = colLeft, Right = colRight}
end

local function CreateSection(col, title)
    local sec = Instance.new("Frame", col)
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.BackgroundColor3 = Theme.CardBG
    sec.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", sec).Color = Theme.Border
    
    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, -30, 0, 40)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.TextWhite
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local line = Instance.new("Frame", sec)
    line.Size = UDim2.new(1, -30, 0, 1)
    line.Position = UDim2.new(0, 15, 0, 40)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0
    
    local content = Instance.new("Frame", sec)
    content.Size = UDim2.new(1, -30, 0, 0)
    content.Position = UDim2.new(0, 15, 0, 50)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 12)
    
    local spacer = Instance.new("Frame", sec)
    spacer.Size = UDim2.new(1, 0, 0, 15)
    spacer.Position = UDim2.new(0, 0, 1, 0)
    spacer.BackgroundTransparency = 1
    
    return content
end

-- ================== -- FUNKCJE UI Z TOOLTIPAMI -- ==================
local function FormatKeyName(val)
    if not val then return "NONE" end
    if val == Enum.UserInputType.MouseButton1 then return "MB1" end
    if val == Enum.UserInputType.MouseButton2 then return "MB2" end
    if val == Enum.UserInputType.MouseButton3 then return "MB3" end
    return val.Name
end

local function CreateKeybind(parent, text, tbl, key, desc)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 26)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextWhite
    lbl.Font = Theme.FontMain
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 65, 0, 24)
    btn.Position = UDim2.new(1, -65, 0.5, -12)
    btn.BackgroundColor3 = Theme.InputBG
    btn.Text = FormatKeyName(tbl[key])
    btn.TextColor3 = Theme.TextWhite
    btn.Font = Theme.FontCode
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local str = Instance.new("UIStroke", btn)
    str.Color = Theme.Border
    
    local listening = false
    
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -62, 0.5, -10)}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0, 65, 0, 24), Position = UDim2.new(1, -65, 0.5, -12)}):Play()
        
        listening = true
        btn.Text = "..."
        str.Color = config.colors.ui_accent
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        
        local valid = false
        local bindValue = nil
        
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            bindValue = input.KeyCode
            valid = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            bindValue = input.UserInputType
            valid = true
        end
        
        if valid then
            if bindValue == Enum.KeyCode.Escape then
                tbl[key] = nil
                btn.Text = "NONE"
            else
                tbl[key] = bindValue
                btn.Text = FormatKeyName(bindValue)
            end
            listening = false
            str.Color = Theme.Border
        end
    end)
    AddTooltip(frame, desc)
end

local function CreateCheckbox(parent, text, tbl, key, desc)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    local box = Instance.new("Frame", btn)
    box.Size = UDim2.new(0, 16, 0, 16)
    box.Position = UDim2.new(0, 0, 0.5, -8)
    box.BackgroundColor3 = tbl[key] and config.colors.ui_accent or Theme.InputBG
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    local str = Instance.new("UIStroke", box)
    str.Color = Theme.Border
    str.Enabled = not tbl[key]
    
    local check = Instance.new("TextLabel", box)
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = "✓"
    check.TextColor3 = Color3.fromRGB(255, 255, 255)
    check.Font = Enum.Font.GothamBold
    check.TextSize = 11
    check.Visible = tbl[key]
    
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.new(0, 28, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextWhite
    lbl.Font = Theme.FontMain
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local function setVis()
        TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = tbl[key] and config.colors.ui_accent or Theme.InputBG}):Play()
        check.Visible = tbl[key]
        str.Enabled = not tbl[key]
    end
    UpdatePreviewEvent.Event:Connect(setVis)
    
    btn.MouseButton1Click:Connect(function() 
        tbl[key] = not tbl[key]
        UpdatePreviewEvent:Fire()
        
        TweenService:Create(box, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)}):Play()
        task.wait(0.1)
        TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 0.5, -8)}):Play()
    end)
    AddTooltip(btn, desc)
end

local function CreateSlider(parent, text, tbl, key, min, max, desc)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextWhite
    lbl.Font = Theme.FontMain
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(1, 0, 0, 15)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(tbl[key])
    valLbl.TextColor3 = Theme.TextGray
    valLbl.Font = Theme.FontCode
    valLbl.TextSize = 11
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = Theme.InputBG
    track.Text = ""
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", track).Color = Theme.Border
    
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((tbl[key]-min)/(max-min), 0, 1, 0)
    ApplyAccent(fill, "BackgroundColor3")
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", fill)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(1, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", knob).Color = Theme.Border
    
    local dragging = false
    
    local function update(i)
        local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pct))
        tbl[key] = val
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(pct, 0, 1, 0)
    end
    
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -9, 0.5, -9)}):Play()
            update(i)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7)}):Play()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i)
        end
    end)
    AddTooltip(frame, desc)
end

local function CreateDropdown(parent, text, tbl, key, options, desc)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextGray
    lbl.Font = Theme.FontMain
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.Position = UDim2.new(0, 0, 0, 20)
    btn.BackgroundColor3 = Theme.InputBG
    btn.Text = "   " .. options[tbl[key]]
    btn.TextColor3 = Theme.TextWhite
    btn.Font = Theme.FontMain
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", btn).Color = Theme.Border
    
    btn.MouseButton1Click:Connect(function()
        tbl[key] = tbl[key] + 1
        if tbl[key] > #options then
            tbl[key] = 1
        end
        btn.Text = "   " .. options[tbl[key]]
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.InputHover}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.InputBG}):Play()
    end)
    AddTooltip(frame, desc)
end

local function CreateColorPicker(parent, text, tbl, key, desc)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -40, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextWhite
    lbl.Font = Theme.FontMain
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local showBtn = Instance.new("TextButton", frame)
    showBtn.Size = UDim2.new(0, 34, 0, 16)
    showBtn.Position = UDim2.new(1, -34, 0, 4)
    showBtn.BackgroundColor3 = tbl[key]
    showBtn.Text = ""
    Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", showBtn).Color = Theme.Border
    
    local pickerBox = Instance.new("Frame", frame)
    pickerBox.Size = UDim2.new(1, 0, 0, 140)
    pickerBox.Position = UDim2.new(0, 0, 0, 32)
    pickerBox.BackgroundColor3 = Theme.InputBG
    pickerBox.Visible = false
    Instance.new("UICorner", pickerBox).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", pickerBox).Color = Theme.Border
    
    local svMap = Instance.new("TextButton", pickerBox)
    svMap.Size = UDim2.new(1, -30, 0, 120)
    svMap.Position = UDim2.new(0, 10, 0, 10)
    svMap.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
    svMap.Text = ""
    svMap.AutoButtonColor = false
    Instance.new("UICorner", svMap).CornerRadius = UDim.new(0, 3)
    
    local svWhite = Instance.new("Frame", svMap)
    svWhite.Size = UDim2.new(1, 0, 1, 0)
    svWhite.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", svWhite).CornerRadius = UDim.new(0, 3)
    local gradW = Instance.new("UIGradient", svWhite)
    gradW.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}
    
    local svBlack = Instance.new("Frame", svMap)
    svBlack.Size = UDim2.new(1, 0, 1, 0)
    svBlack.BackgroundColor3 = Color3.new(0, 0, 0)
    Instance.new("UICorner", svBlack).CornerRadius = UDim.new(0, 3)
    local gradB = Instance.new("UIGradient", svBlack)
    gradB.Rotation = 90
    gradB.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}
    
    local svCursor = Instance.new("Frame", svMap)
    svCursor.Size = UDim2.new(0, 6, 0, 6)
    svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", svCursor)
    
    local hBar = Instance.new("TextButton", pickerBox)
    hBar.Size = UDim2.new(0, 10, 0, 120)
    hBar.Position = UDim2.new(1, -15, 0, 10)
    hBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hBar.Text = ""
    Instance.new("UICorner", hBar).CornerRadius = UDim.new(0, 3)
    
    local hGrad = Instance.new("UIGradient", hBar)
    hGrad.Rotation = 90
    hGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    
    local hCursor = Instance.new("Frame", hBar)
    hCursor.Size = UDim2.new(1, 2, 0, 4)
    hCursor.Position = UDim2.new(0, -1, 0, 0)
    hCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UIStroke", hCursor)

    local curH, curS, curV = tbl[key]:ToHSV()
    
    local function applyColor()
        local col = Color3.fromHSV(curH, curS, curV)
        tbl[key] = col
        showBtn.BackgroundColor3 = col
        if key == "ui_accent" then
            UpdateAccents()
        end
        UpdatePreviewEvent:Fire()
    end
    
    local hDrag, svDrag = false, false
    
    hBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hDrag = true
        end
    end)
    
    svMap.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hDrag = false
            svDrag = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if hDrag then
                local pct = math.clamp((i.Position.Y - hBar.AbsolutePosition.Y) / hBar.AbsoluteSize.Y, 0, 1)
                curH = 1 - pct
                hCursor.Position = UDim2.new(0, -1, pct, -2)
                svMap.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
                applyColor()
            end
            if svDrag then
                local pctX = math.clamp((i.Position.X - svMap.AbsolutePosition.X) / svMap.AbsoluteSize.X, 0, 1)
                local pctY = math.clamp((i.Position.Y - svMap.AbsolutePosition.Y) / svMap.AbsoluteSize.Y, 0, 1)
                curS = pctX
                curV = 1 - pctY
                svCursor.Position = UDim2.new(pctX, -3, pctY, -3)
                applyColor()
            end
        end
    end)
    
    local isOpen = false
    showBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        pickerBox.Visible = isOpen
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = isOpen and UDim2.new(1, 0, 0, 180) or UDim2.new(1, 0, 0, 24)}):Play()
    end)
    AddTooltip(frame, desc)
end

-- ================== -- 6. BUDOWA MENU (Z OPISAMI) -- ==================
local colsAim = CreateTab("Legitbot", true)
local colsVis = CreateTab("Visuals", false)
local colsMisc = CreateTab("Misc", false)
local colsSet = CreateTab("Settings", false)

-- TAB: AIMBOT
local aSec1 = CreateSection(colsAim.Left, "Aimbot General")
CreateCheckbox(aSec1, "Enable Legitbot", config.toggles, "aim_enabled", "Master switch for aiming assistance.")
CreateKeybind(aSec1, "Aimbot Hotkey", config.keybinds, "aimbot", "Hold this key to lock onto enemies.")
CreateCheckbox(aSec1, "Draw FOV Circle", config.toggles, "aim_showFov", "Shows the active aimbot targeting zone.")
CreateCheckbox(aSec1, "Visibility Check", config.toggles, "aim_wallCheck", "Prevents locking onto enemies behind walls.")
CreateCheckbox(aSec1, "Velocity Prediction", config.toggles, "aim_predict", "Predicts enemy movement for better accuracy.")

local aSec3 = CreateSection(colsAim.Right, "Aimbot Configuration")
CreateDropdown(aSec3, "Hitbox", config.selectors, "aim_part", {"Head", "Torso", "Root"}, "Which body part the aimbot should track.")
CreateDropdown(aSec3, "Method", config.selectors, "aim_method", {"Mouse Movement", "Camera Snap"}, "How the aimbot corrects your aim.")
CreateSlider(aSec3, "Field of View", config.sliders, "aim_fov", 10, 600, "The radius of the aimbot targeting zone.")
CreateSlider(aSec3, "Smoothness", config.sliders, "aim_smooth", 1, 20, "Higher value = slower, more human-like aiming.")
CreateSlider(aSec3, "Aim Offset X", config.sliders, "aim_offsetX", -100, 100, "Shifts aim horizontally.")
CreateSlider(aSec3, "Aim Offset Y", config.sliders, "aim_offsetY", -100, 100, "Shifts aim vertically (good for bullet drop).")

-- TAB: VISUALS
local vSec1 = CreateSection(colsVis.Left, "Esp Elements")
CreateCheckbox(vSec1, "Master Switch", config, "esp_enabled", "Toggles all visual features on or off.")
CreateSlider(vSec1, "Max Distance", config.sliders, "esp_distance", 50, 5000, "Maximum distance to render ESP.")
CreateCheckbox(vSec1, "Bounding Box", config.toggles, "boxes", "Draws a 2D box around the enemy.")
CreateCheckbox(vSec1, "Skeleton", config.toggles, "skeletons", "Draws lines connecting the enemy's bones.")
CreateCheckbox(vSec1, "Health Bar", config.toggles, "healthbars", "Shows how much HP the enemy has via a bar.")
CreateCheckbox(vSec1, "Health Text", config.toggles, "healthtext", "Shows the exact numeric HP value.")

local vSec2 = CreateSection(colsVis.Right, "Information")
CreateCheckbox(vSec2, "Nickname", config.toggles, "names", "Displays the enemy's username.")
CreateCheckbox(vSec2, "Weapon Name", config.toggles, "weapons", "Shows what item the enemy is currently holding.")
CreateCheckbox(vSec2, "Distance", config.toggles, "distances", "Shows how far away the enemy is from you.")
CreateCheckbox(vSec2, "Snaplines", config.toggles, "tracers", "Draws a line from you to the enemy.")
CreateDropdown(vSec2, "Snapline Origin", config.selectors, "tracer_origin", {"Bottom", "Center", "Mouse"}, "Where the snaplines should start from.")

local vSec3 = CreateSection(colsVis.Right, "Colors")
CreateColorPicker(vSec3, "Enemy ESP Box", config.colors, "enemy_esp", "The primary color for enemy visual elements.")

-- TAB: MISC
local mSec1 = CreateSection(colsMisc.Left, "World Modulation")
CreateCheckbox(mSec1, "Enable Custom Time", config.toggles, "time_changer", "Override the in-game daylight time.")
CreateSlider(mSec1, "Time of Day", config.sliders, "custom_time", 0, 24, "Set the world time (0 = Midnight, 12 = Noon).")
CreateCheckbox(mSec1, "Enable Custom FOV", config.toggles, "fov_changer", "Override the game's camera field of view.")
CreateSlider(mSec1, "Camera FOV", config.sliders, "custom_fov", 60, 120, "Adjust how wide your camera view is.")

local mSec2 = CreateSection(colsMisc.Right, "Exploits & Movement")
CreateCheckbox(mSec2, "ACS Godmode", config.toggles, "godmode", "Forces max health & blood in ACS Engine games.")
CreateCheckbox(mSec2, "Bunny Hop", config.toggles, "bhop", "Hold Space to jump automatically.")
CreateCheckbox(mSec2, "Third Person", config.toggles, "third_person", "Forces camera into 3rd person mode.")
CreateCheckbox(mSec2, "Stealth Fly (Undetected)", config.toggles, "fly", "Safe fly method via an invisible platform.")
CreateKeybind(mSec2, "Toggle Fly Bind", config.keybinds, "fly", "Press this key to quickly toggle Fly ON/OFF.")
CreateSlider(mSec2, "Fly Speed", config.sliders, "fly_speed", 10, 150, "Adjust how fast you fly.")

-- TAB: SETTINGS
local sSec1 = CreateSection(colsSet.Left, "Configuration")
CreateKeybind(sSec1, "Menu Toggle Key", config.keybinds, "menu", "Key to open and close this interface.")
CreateCheckbox(sSec1, "Team Check", config, "teamCheck", "Prevents targeting or showing ESP on your teammates.")
CreateCheckbox(sSec1, "Custom Crosshair", config.toggles, "aim_crosshair", "Draws a custom crosshair in the center of your screen.")
CreateCheckbox(sSec1, "Rainbow UI Mode", config.toggles, "rainbow_ui", "Cycles the menu accent color through the RGB spectrum.")
CreateColorPicker(sSec1, "Menu Accent Color", config.colors, "ui_accent", "Changes the primary theme color of this menu.")

local btnUnload = Instance.new("TextButton", sSec1)
btnUnload.Size = UDim2.new(1, 0, 0, 34)
btnUnload.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
btnUnload.Text = "UNLOAD SCRIPT"
btnUnload.TextColor3 = config.colors.ui_accent
btnUnload.Font = Enum.Font.GothamBold
btnUnload.TextSize = 12
ApplyAccent(btnUnload, "TextColor3")
Instance.new("UICorner", btnUnload).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", btnUnload).Color = Theme.Border
AddTooltip(btnUnload, "Removes the script and all drawings entirely from the game.")

btnUnload.MouseButton1Click:Connect(function()
    if _G.AsapwareUnload then
        _G.AsapwareUnload()
    end
end)

UpdatePreviewEvent:Fire()

-- Logika Otwierania / Zamykania Menu (Smooth Center Zoom)
local menuOpen = true

local function ToggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        DragContainer.Visible = true
        TweenService:Create(UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        local tw = TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 0})
        tw:Play()
        tw.Completed:Connect(function()
            if not menuOpen then
                DragContainer.Visible = false
            end
        end)
    end
end

-- Animacja Startowa
UIScale.Scale = 0
TweenService:Create(UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == config.keybinds.menu then
        ToggleMenu()
    end
    
    if config.keybinds.fly and (input.KeyCode == config.keybinds.fly or input.UserInputType == config.keybinds.fly) then
        config.toggles.fly = not config.toggles.fly
        UpdatePreviewEvent:Fire()
    end
end)

-- ==========================================
-- 7. LOGIKA ESP & DRAWING API
-- ==========================================
local DrawingSupported = pcall(function() Drawing.new("Line"):Remove() end)

if not DrawingSupported then
    warn("ASAPWARE: Twoj executor nie wspiera Drawing API. Wizualizacje (ESP, Crosshair) moga nie dzialac.")
end

local ESP_Data = {}
local AllDrawings = {}

local function CreateDraw(Type, Properties)
    if not DrawingSupported then return {Visible = false, Remove = function() end} end
    local obj = Drawing.new(Type)
    for k, v in pairs(Properties) do
        obj[k] = v
    end
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
    ESP_Data[player] = {
        BoxOutline = CreateDraw("Square", {Filled = false, Color = ESP_COLORS.Outline}),
        Box = CreateDraw("Square", {Filled = false}),
        HealthOutline = CreateDraw("Square", {Filled = true, Color = ESP_COLORS.Outline}),
        HealthBar = CreateDraw("Square", {Filled = true}),
        HealthText = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = Color3.fromRGB(255, 255, 255)}),
        Name = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255, 255, 255)}),
        Distance = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 11, Color = Theme.TextGray}),
        Weapon = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 11, Color = Color3.fromRGB(180, 180, 220)}),
        Tracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.5}),
        SkeletonLines = {}
    }
end

local function RemoveESP(player) 
    if ESP_Data[player] then 
        for k, v in pairs(ESP_Data[player]) do
            if k == "SkeletonLines" then
                for _, l in ipairs(v) do
                    l.Visible = false
                    pcall(function() l:Remove() end)
                end
            else
                v.Visible = false
                pcall(function() v:Remove() end)
            end
        end
        ESP_Data[player] = nil 
    end 
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        SetupESP(p)
    end
end
Players.PlayerAdded:Connect(SetupESP)
Players.PlayerRemoving:Connect(RemoveESP)

local function GetAimPart(char)
    local sel = config.selectors.aim_part
    if sel == 1 then
        return char:FindFirstChild("Head")
    elseif sel == 2 then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    else
        return char:FindFirstChild("HumanoidRootPart")
    end
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
        local pairs = {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }
        for _, p in ipairs(pairs) do
            local p1 = char:FindFirstChild(p[1])
            local p2 = char:FindFirstChild(p[2])
            if p1 and p2 then
                table.insert(bones, {p1, p2})
            end
        end
    elseif char:FindFirstChild("Torso") then
        local pairs = {
            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
            {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
        }
        for _, p in ipairs(pairs) do
            local p1 = char:FindFirstChild(p[1])
            local p2 = char:FindFirstChild(p[2])
            if p1 and p2 then
                table.insert(bones, {p1, p2})
            end
        end
    end
    return bones
end

-- ==========================================
-- 8. GŁÓWNA PĘTLA
-- ==========================================
RunService:BindToRenderStep("AsapwareMain", Enum.RenderPriority.Camera.Value + 1, function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    local cTick = tick()
    
    if config.toggles.rainbow_ui then
        config.colors.ui_accent = Color3.fromHSV((cTick % 5) / 5, 0.8, 1)
        UpdateAccents()
        UpdatePreviewEvent:Fire()
    end
    
    if config.toggles.time_changer then
        Lighting.ClockTime = config.sliders.custom_time
    end
    
    if config.toggles.fov_changer then
        Camera.FieldOfView = config.sliders.custom_fov
    end
    
    if config.toggles.third_person then
        LocalPlayer.CameraMaxZoomDistance = 12
        LocalPlayer.CameraMinZoomDistance = 12
    else
        LocalPlayer.CameraMaxZoomDistance = 400
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
    
    if config.toggles.bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not config.toggles.fly then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
    end
    
    if config.toggles.godmode then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = hum.MaxHealth
            end
            
            local h = char:FindFirstChild("Health")
            if h and (h:IsA("NumberValue") or h:IsA("IntValue")) then
                h.Value = 100
            end
            
            local b = char:FindFirstChild("Blood")
            if b and (b:IsA("NumberValue") or b:IsA("IntValue")) then
                b.Value = 100
            end
            
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
            
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
            end
            
            hrp.CFrame = hrp.CFrame + (moveDir * (config.sliders.fly_speed / 20))
            hrp.Velocity = Vector3.zero
            flyPlatform.CFrame = hrp.CFrame * CFrame.new(0, -3.2, 0)
        end
    else
        if flyPlatform then
            flyPlatform:Destroy()
            flyPlatform = nil
        end
    end
    
    -- ZAAWANSOWANE PREVIEW 3D (ZAAWANSOWANA MATEMATYKA NAKŁADANIA)
    if Preview.Visible then
        if not isDraggingPreview then
            camAngleX = camAngleX + 0.005
        end
        
        local camPosX = math.sin(camAngleX) * math.cos(camAngleY) * camRadius
        local camPosY = math.sin(camAngleY) * camRadius + 1.5
        local camPosZ = math.cos(camAngleX) * math.cos(camAngleY) * camRadius
        
        VPF_Cam.CFrame = CFrame.new(Vector3.new(camPosX, camPosY, camPosZ), Torso.Position)
        
        P_BoxStr.Color = config.colors.enemy_esp
        P_Tracer.BackgroundColor3 = config.colors.enemy_esp
        
        if config.toggles.skeletons then
            local pPairs = {
                {Head, Torso}, {Torso, LArm}, {Torso, RArm}, {Torso, LLeg}, {Torso, RLeg}
            }
            for i, p in ipairs(pPairs) do
                local p1, on1 = VPF_Cam:WorldToViewportPoint(p[1].Position)
                local p2, on2 = VPF_Cam:WorldToViewportPoint(p[2].Position)
                
                if on1 and on2 then
                    S_Lines[i].Visible = true
                    local v1 = Vector2.new(p1.X, p1.Y)
                    local v2 = Vector2.new(p2.X, p2.Y)
                    
                    local center = (v1 + v2) / 2
                    local dist = (v2 - v1).Magnitude
                    local angle = math.deg(math.atan2(v2.Y - v1.Y, v2.X - v1.X))
                    
                    S_Lines[i].Position = UDim2.new(0, center.X, 0, center.Y)
                    S_Lines[i].Size = UDim2.new(0, dist, 0, 1.5)
                    S_Lines[i].Rotation = angle
                else
                    S_Lines[i].Visible = false
                end
            end
        else
            for _, l in ipairs(S_Lines) do
                l.Visible = false
            end
        end

        local pTop, onT = VPF_Cam:WorldToViewportPoint(Torso.Position + Vector3.new(0, 2.5, 0))
        local pBot, onB = VPF_Cam:WorldToViewportPoint(Torso.Position - Vector3.new(0, 3, 0))
        
        if onT and onB then
            local h = pBot.Y - pTop.Y
            local w = h / 1.5
            local bx = pTop.X - (w / 2)
            local by = pTop.Y
            
            -- Ustawienie pozycji rodowica gwarantuje, że wszystko co pod boxem będzie idealnie wyrównane
            P_Box.Size = UDim2.new(0, w, 0, h)
            P_Box.Position = UDim2.new(0, bx, 0, by)
            
            P_Box.Visible = config.toggles.boxes
            P_HealthBg.Visible = config.toggles.healthbars
            P_HealthTxt.Visible = config.toggles.healthtext and config.toggles.healthbars
            P_Name.Visible = config.toggles.names
            
            P_Distance.Visible = config.toggles.distances
            P_Weapon.Visible = config.toggles.weapons
            
            if config.toggles.tracers then
                local oX = ViewportContainer.AbsoluteSize.X / 2
                local oY = ViewportContainer.AbsoluteSize.Y
                local tX = bx + (w / 2)
                local tY = by + h
                
                local dist = math.sqrt((tX - oX)^2 + (tY - oY)^2)
                P_Tracer.Size = UDim2.new(0, 1.5, 0, dist)
                P_Tracer.Position = UDim2.new(0, (oX + tX) / 2, 0, (oY + tY) / 2)
                P_Tracer.Rotation = math.deg(math.atan2(tY - oY, tX - oX)) - 90
                P_Tracer.Visible = true
            else
                P_Tracer.Visible = false
            end
        end
    end

    -- AIMBOT LOGIC
    FOV_Circle.Position = mouseLoc
    FOV_Circle.Radius = config.sliders.aim_fov
    FOV_Circle.Visible = config.toggles.aim_showFov and config.toggles.aim_enabled
    
    local cSize, cGap = 6, 4
    CrossTop.From = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap)
    CrossTop.To = Vector2.new(mouseLoc.X, mouseLoc.Y - cGap - cSize)
    CrossTop.Visible = config.toggles.aim_crosshair
    
    CrossBot.From = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap)
    CrossBot.To = Vector2.new(mouseLoc.X, mouseLoc.Y + cGap + cSize)
    CrossBot.Visible = config.toggles.aim_crosshair
    
    CrossLeft.From = Vector2.new(mouseLoc.X - cGap, mouseLoc.Y)
    CrossLeft.To = Vector2.new(mouseLoc.X - cGap - cSize, mouseLoc.Y)
    CrossLeft.Visible = config.toggles.aim_crosshair
    
    CrossRight.From = Vector2.new(mouseLoc.X + cGap, mouseLoc.Y)
    CrossRight.To = Vector2.new(mouseLoc.X + cGap + cSize, mouseLoc.Y)
    CrossRight.Visible = config.toggles.aim_crosshair

    local isAiming = false
    local aBind = config.keybinds.aimbot
    
    if aBind and typeof(aBind) == "EnumItem" then
        if aBind.EnumType == Enum.KeyCode then
            isAiming = UserInputService:IsKeyDown(aBind)
        elseif aBind.EnumType == Enum.UserInputType then
            isAiming = UserInputService:IsMouseButtonPressed(aBind)
        end
    end

    local closestTarget = nil
    local shortestDist = math.huge
    
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
            if config.selectors.aim_method == 1 then
                local pos = Camera:WorldToScreenPoint(closestTarget)
                local diffX = (pos.X + config.sliders.aim_offsetX) - mouseLoc.X
                local diffY = (pos.Y + config.sliders.aim_offsetY) - mouseLoc.Y
                if mousemoverel then
                    mousemoverel(diffX / smooth, diffY / smooth)
                else
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), 1 / smooth)
                end
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), 1 / smooth)
            end
        end
    end

    -- ESP LOGIC
    local t_Thick = config.sliders.boxThickness
    
    for player, esp in pairs(ESP_Data) do
        local isVisible = false
        
        if not player or not player.Parent then
            RemoveESP(player)
            continue
        end

        local char = player.Character
        if config.esp_enabled and char and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
            local hp, maxHp = GetHealth(player)
            if hp > 0 then
                local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    
                    if onScreen and pos.Z > 0 and dist <= config.sliders.esp_distance then
                        isVisible = true
                        
                        local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
                        local botPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                        
                        local boxH = botPos.Y - topPos.Y
                        local boxW = boxH / 1.8
                        local boxX = pos.X - (boxW / 2)
                        local boxY = topPos.Y

                        if config.toggles.boxes then
                            esp.BoxOutline.Thickness = t_Thick + 2
                            esp.BoxOutline.Size = Vector2.new(boxW, boxH)
                            esp.BoxOutline.Position = Vector2.new(boxX, boxY)
                            esp.BoxOutline.Visible = true
                            
                            esp.Box.Thickness = t_Thick
                            esp.Box.Size = Vector2.new(boxW, boxH)
                            esp.Box.Position = Vector2.new(boxX, boxY)
                            esp.Box.Color = config.colors.enemy_esp
                            esp.Box.Visible = true
                        else
                            esp.BoxOutline.Visible = false
                            esp.Box.Visible = false
                        end

                        if config.toggles.healthbars then
                            local hpPct = math.clamp(hp / maxHp, 0, 1)
                            local barH = boxH * hpPct
                            
                            esp.HealthOutline.Size = Vector2.new(4, boxH + 2)
                            esp.HealthOutline.Position = Vector2.new(boxX - 7, boxY - 1)
                            esp.HealthOutline.Visible = true
                            
                            esp.HealthBar.Size = Vector2.new(2, barH)
                            esp.HealthBar.Position = Vector2.new(boxX - 6, boxY + (boxH - barH))
                            esp.HealthBar.Color = Color3.fromRGB(255 - (hpPct * 255), hpPct * 255, 30)
                            esp.HealthBar.Visible = true
                            
                            if config.toggles.healthtext and hp < maxHp then
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
                            esp.Name.Text = player.Name
                            esp.Name.Position = Vector2.new(pos.X, boxY - 18)
                            esp.Name.Visible = true
                        else
                            esp.Name.Visible = false
                        end
                        
                        local bottomY = boxY + boxH + 3
                        
                        if config.toggles.distances then
                            esp.Distance.Text = "[" .. math.floor(dist) .. "m]"
                            esp.Distance.Position = Vector2.new(pos.X, bottomY)
                            esp.Distance.Visible = true
                            bottomY = bottomY + 14
                        else
                            esp.Distance.Visible = false
                        end
                        
                        if config.toggles.weapons then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                esp.Weapon.Text = tool.Name
                                esp.Weapon.Position = Vector2.new(pos.X, bottomY)
                                esp.Weapon.Visible = true
                            else
                                esp.Weapon.Visible = false
                            end
                        else
                            esp.Weapon.Visible = false
                        end

                        if config.toggles.tracers then
                            local origin = screenCenter
                            if config.selectors.tracer_origin == 2 then
                                origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            elseif config.selectors.tracer_origin == 3 then
                                origin = mouseLoc
                            end
                            esp.Tracer.From = origin
                            esp.Tracer.To = Vector2.new(pos.X, botPos.Y)
                            esp.Tracer.Color = config.colors.enemy_esp
                            esp.Tracer.Visible = true
                        else
                            esp.Tracer.Visible = false
                        end
                        
                        if config.toggles.skeletons then
                            local bones = GetBones(char)
                            for i, p in ipairs(bones) do
                                local p1, on1 = Camera:WorldToViewportPoint(p[1].Position)
                                local p2, on2 = Camera:WorldToViewportPoint(p[2].Position)
                                
                                if on1 and on2 and p1.Z > 0 and p2.Z > 0 then
                                    if not esp.SkeletonLines[i] then
                                        esp.SkeletonLines[i] = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Skeleton, Transparency = 0.8})
                                    end
                                    esp.SkeletonLines[i].From = Vector2.new(p1.X, p1.Y)
                                    esp.SkeletonLines[i].To = Vector2.new(p2.X, p2.Y)
                                    esp.SkeletonLines[i].Visible = true
                                elseif esp.SkeletonLines[i] then
                                    esp.SkeletonLines[i].Visible = false
                                end
                            end
                            for i = #bones + 1, #esp.SkeletonLines do
                                esp.SkeletonLines[i].Visible = false
                            end
                        else
                            for _, l in ipairs(esp.SkeletonLines) do
                                l.Visible = false
                            end
                        end
                    end
                end
            end
        end
        
        if not isVisible then 
            esp.BoxOutline.Visible = false
            esp.Box.Visible = false
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthText.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.Weapon.Visible = false
            esp.Tracer.Visible = false
            for _, l in ipairs(esp.SkeletonLines) do
                l.Visible = false
            end
        end
    end
end)

_G.AsapwareUnload = function()
    RunService:UnbindFromRenderStep("AsapwareMain")
    if ScreenGui then ScreenGui:Destroy() end
    if flyPlatform then flyPlatform:Destroy() end
    
    for _, esp in pairs(ESP_Data) do
        for k, v in pairs(esp) do
            if k == "SkeletonLines" then
                for _, l in ipairs(v) do
                    pcall(function() l:Remove() end)
                end
            else
                pcall(function() v:Remove() end)
            end
        end
    end
    table.clear(ESP_Data)
    
    for _, obj in ipairs(AllDrawings) do
        if obj.Remove then 
            pcall(function() obj:Remove() end)
        end
    end
    table.clear(AllDrawings)
    _G.AsapwareUnload = nil
end

print("ASAPWARE V12: Zaladowano poprawnie! Plynne animacje, opisy i naprawione ESP 3D. Wcisnij [INSERT].")
