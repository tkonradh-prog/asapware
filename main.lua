local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- KONFIGURACJA ASAPWARE 13.1 (HOTFIX)
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
        skeletons = false,
        tracers = false,
        
        aim_enabled = false,
        aim_showFov = true,
        aim_crosshair = true,
        aim_wallCheck = true,
        aim_predict = false
    },
    sliders = {
        esp_distance = 3000,
        esp_hue = 220, 
        boxThickness = 1,
        
        aim_distance = 1500,
        aim_fov = 100,
        aim_smooth = 5,
        aim_offsetX = 0,
        aim_offsetY = 36,
        aim_pred_amt = 10 
    },
    selectors = {
        aim_part = 1, 
        tracer_origin = 1 
    }
}

local ESP_COLORS = {
    Enemy = Color3.fromHSV(config.sliders.esp_hue / 360, 1, 1),
    Team = Color3.fromRGB(60, 255, 120),
    Skeleton = Color3.fromRGB(255, 255, 255),
    Tracer = Color3.fromRGB(200, 200, 215),
    Outline = Color3.fromRGB(0, 0, 0)
}

-- ==========================================
-- ZAAWANSOWANY SYSTEM HP (RECURSIVE SCANNER)
-- ==========================================
local HealthCache = {}

local function AnalyzePlayerHealth(player, char)
    task.wait(1.5)
    if not char or not char.Parent then return end

    local function findHealthAttributes(obj)
        local checkNames = {"Health", "HP", "CurrentHealth", "health", "hp", "HealthValue"}
        local maxNames = {"MaxHealth", "MaxHP", "maxhealth", "maxhp", "MaxHealthValue"}
        for _, n in ipairs(checkNames) do
            if obj:GetAttribute(n) then
                local mName = "MaxHealth"
                for _, mn in ipairs(maxNames) do if obj:GetAttribute(mn) then mName = mn break end end
                return n, mName
            end
        end
        return nil, nil
    end

    local currentHP_Func = nil

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MaxHealth > 1 then
        currentHP_Func = function() return hum.Health, hum.MaxHealth end
    end

    if not currentHP_Func then
        local n, mn = findHealthAttributes(char)
        if n then
            currentHP_Func = function() return char:GetAttribute(n) or 100, char:GetAttribute(mn) or 100 end
        else
            n, mn = findHealthAttributes(player)
            if n then
                currentHP_Func = function() return player:GetAttribute(n) or 100, player:GetAttribute(mn) or 100 end
            end
        end
    end

    if not currentHP_Func then
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                local ln = string.lower(desc.Name)
                if ln == "health" or ln == "hp" or ln == "currenthealth" then
                    local maxObj = nil
                    if desc.Parent then
                        for _, sib in ipairs(desc.Parent:GetChildren()) do
                            local ls = string.lower(sib.Name)
                            if ls == "maxhealth" or ls == "maxhp" then maxObj = sib break end
                        end
                    end
                    currentHP_Func = function() return desc.Value, maxObj and maxObj.Value or 100 end
                    break
                end
            end
        end
    end

    if not currentHP_Func then currentHP_Func = function() return 100, 100 end end
    HealthCache[player] = { Char = char, Fetch = currentHP_Func }
end

local function GetHP(player)
    local cache = HealthCache[player]
    if cache and cache.Char == player.Character then return cache.Fetch() end
    return 100, 100
end

-- ==========================================
-- NOWOCZESNY SILNIK UI (ROBLOX GUI API)
-- ==========================================
local UI_THEME = {
    MainBG = Color3.fromRGB(18, 18, 24),
    SidebarBG = Color3.fromRGB(12, 12, 16),
    Accent = Color3.fromRGB(114, 137, 218),
    ElementBG = Color3.fromRGB(28, 28, 36),
    TextWhite = Color3.fromRGB(240, 240, 240),
    TextGray = Color3.fromRGB(160, 160, 175),
    Border = Color3.fromRGB(40, 40, 50)
}

local TargetGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AsapwareApex"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = TargetGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 500)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -250)
MainFrame.BackgroundColor3 = UI_THEME.MainBG
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame); MainCorner.CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = UI_THEME.Border; MainStroke.Thickness = 1

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = UI_THEME.SidebarBG
Sidebar.BorderSizePixel = 0
local SidebarCorner = Instance.new("UICorner", Sidebar); SidebarCorner.CornerRadius = UDim.new(0, 10)
local SidebarHider = Instance.new("Frame", Sidebar)
SidebarHider.Size = UDim2.new(0, 10, 1, 0); SidebarHider.Position = UDim2.new(1, -10, 0, 0); SidebarHider.BackgroundColor3 = UI_THEME.SidebarBG; SidebarHider.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Sidebar)
Title.Size = UDim2.new(1, 0, 0, 60); Title.BackgroundTransparency = 1
Title.Text = "ASAPWARE"; Title.TextColor3 = UI_THEME.TextWhite; Title.Font = Enum.Font.GothamBold; Title.TextSize = 20

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -190, 1, -20); TabContainer.Position = UDim2.new(0, 190, 0, 10)
TabContainer.BackgroundTransparency = 1

local tabs = {}
local function CreateTabButton(name, icon, yPos, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundTransparency = 1; btn.Text = "   " .. icon .. "   " .. name
    btn.TextColor3 = isFirst and UI_THEME.TextWhite or UI_THEME.TextGray
    btn.Font = Enum.Font.GothamMedium; btn.TextSize = 15; btn.TextXAlignment = Enum.TextXAlignment.Left
    
    local accent = Instance.new("Frame", btn)
    accent.Size = UDim2.new(0, 3, 0.6, 0); accent.Position = UDim2.new(0, 0, 0.2, 0)
    accent.BackgroundColor3 = UI_THEME.Accent; accent.BorderSizePixel = 0; accent.Visible = isFirst
    
    local page = Instance.new("ScrollingFrame", TabContainer)
    page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.ScrollBarThickness = 2
    page.Visible = isFirst
    
    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 10)
    
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Btn.TextColor3 = UI_THEME.TextGray; t.Accent.Visible = false; t.Page.Visible = false end
        btn.TextColor3 = UI_THEME.TextWhite; accent.Visible = true; page.Visible = true
    end)
    
    tabs[name] = {Btn = btn, Accent = accent, Page = page}
    return page
end

local function CreateSection(page, title)
    local sec = Instance.new("Frame", page)
    sec.Size = UDim2.new(1, -10, 0, 0); sec.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", sec); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 8)
    
    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, 0, 0, 25); lbl.BackgroundTransparency = 1
    lbl.Text = title; lbl.TextColor3 = UI_THEME.Accent; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sec.Size = UDim2.new(1, -10, 0, layout.AbsoluteContentSize.Y) end)
    return sec
end

local function CreateToggle(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -50, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = UI_THEME.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -40, 0.5, -10)
    btn.BackgroundColor3 = tbl[key] and UI_THEME.Accent or UI_THEME.ElementBG; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", btn)
    knob.Size = UDim2.new(0, 16, 0, 16); knob.Position = tbl[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    btn.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(btn, info, {BackgroundColor3 = tbl[key] and UI_THEME.Accent or UI_THEME.ElementBG}):Play()
        TweenService:Create(knob, info, {Position = tbl[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
    end)
end

local function CreateSlider(parent, text, tbl, key, min, max, isColor)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 45); frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 20); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = UI_THEME.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(1, 0, 0, 20); valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(tbl[key]); valLbl.TextColor3 = UI_THEME.TextGray; valLbl.Font = Enum.Font.GothamMedium; valLbl.TextSize = 14; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local bg = Instance.new("TextButton", frame)
    bg.Size = UDim2.new(1, 0, 0, 6); bg.Position = UDim2.new(0, 0, 0, 30); bg.BackgroundColor3 = UI_THEME.ElementBG; bg.Text = ""; bg.AutoButtonColor = false
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", bg)
    local pct = (tbl[key] - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0); fill.BackgroundColor3 = isColor and Color3.fromHSV(tbl[key]/360, 1, 1) or UI_THEME.Accent; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local isDragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local newVal = math.floor(min + ((max - min) * pos))
        tbl[key] = newVal
        valLbl.Text = tostring(newVal)
        TweenService:Create(fill, TweenInfo.new(0.05), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        if isColor then
            local c = Color3.fromHSV(newVal/360, 1, 1)
            fill.BackgroundColor3 = c
            ESP_COLORS.Enemy = c
        end
    end
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
end

local function CreateSelector(parent, text, tbl, key, options)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = UI_THEME.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.5, 0, 0, 24); btn.Position = UDim2.new(0.5, 0, 0.5, -12)
    btn.BackgroundColor3 = UI_THEME.ElementBG; btn.Text = options[tbl[key]]; btn.TextColor3 = UI_THEME.Accent; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        tbl[key] = tbl[key] + 1
        if tbl[key] > #options then tbl[key] = 1 end
        btn.Text = options[tbl[key]]
    end)
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = UI_THEME.ElementBG
    btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 80, 80); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

-- Rysowanie Menu
local pAimbot = CreateTabButton("Aimbot", "⚡", 70, true)
local pVisuals = CreateTabButton("Visuals", "👁️", 110, false)
local pConfig = CreateTabButton("Settings", "⚙️", 150, false)

local aMain = CreateSection(pAimbot, "COMBAT")
CreateToggle(aMain, "Enable Aimbot", config.toggles, "aim_enabled")
CreateToggle(aMain, "Draw FOV Circle", config.toggles, "aim_showFov")
CreateToggle(aMain, "Draw Crosshair Dot", config.toggles, "aim_crosshair")
CreateToggle(aMain, "Visibility Check", config.toggles, "aim_wallCheck")
CreateToggle(aMain, "Velocity Prediction", config.toggles, "aim_predict")

local aSettings = CreateSection(pAimbot, "ADJUSTMENTS")
CreateSelector(aSettings, "Target Part", config.selectors, "aim_part", {"Head", "Torso", "Root"})
CreateSlider(aSettings, "Max Distance (m)", config.sliders, "aim_distance", 50, 5000)
CreateSlider(aSettings, "FOV Radius", config.sliders, "aim_fov", 10, 800)
CreateSlider(aSettings, "Smoothness", config.sliders, "aim_smooth", 1, 20)
CreateSlider(aSettings, "Prediction Strength", config.sliders, "aim_pred_amt", 1, 20)

-- PRZYWRÓCONY OFFSET!
CreateSlider(aSettings, "Aim Offset X", config.sliders, "aim_offsetX", -100, 100)
CreateSlider(aSettings, "Aim Offset Y", config.sliders, "aim_offsetY", -100, 100)


local vMain = CreateSection(pVisuals, "ESP OVERLAY")
CreateToggle(vMain, "Enable ESP", config, "esp_enabled")
CreateToggle(vMain, "Draw Boxes", config.toggles, "boxes")
CreateToggle(vMain, "Health Bars", config.toggles, "healthbars")
CreateToggle(vMain, "Health Text", config.toggles, "healthtext")
CreateToggle(vMain, "Draw Skeletons", config.toggles, "skeletons")

local vInfo = CreateSection(pVisuals, "INFORMATION")
CreateToggle(vInfo, "Show Names", config.toggles, "names")
CreateToggle(vInfo, "Show Weapons", config.toggles, "weapons")
CreateToggle(vInfo, "Show Distances", config.toggles, "distances")
CreateToggle(vInfo, "Show Tracers", config.toggles, "tracers")
CreateSelector(vInfo, "Tracer Origin", config.selectors, "tracer_origin", {"Bottom", "Center", "Mouse"})

local vSet = CreateSection(pVisuals, "PROPERTIES")
CreateSlider(vSet, "Render Distance", config.sliders, "esp_distance", 50, 5000)
CreateSlider(vSet, "Enemy Color (HUE)", config.sliders, "esp_hue", 0, 360, true)

local cSet = CreateSection(pConfig, "PREFERENCES")
CreateToggle(cSet, "Team Check", config, "teamCheck")
CreateButton(cSet, "UNLOAD ASAPWARE", function() if _G.AsapwareUnload then _G.AsapwareUnload() end end)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Insert then ScreenGui.Enabled = not ScreenGui.Enabled end
    if input.KeyCode == Enum.KeyCode.Delete then if _G.AsapwareUnload then _G.AsapwareUnload() end end
end)

-- ==========================================
-- SKELETON ESP LOGIC
-- ==========================================
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
            local p1, p2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2])
            if p1 and p2 then table.insert(bones, {p1, p2}) end
        end
    elseif char:FindFirstChild("Torso") then
        local pairs = {
            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
            {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
        }
        for _, p in ipairs(pairs) do
            local p1, p2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2])
            if p1 and p2 then table.insert(bones, {p1, p2}) end
        end
    end
    return bones
end

-- ==========================================
-- LOGIKA RYSOWANIA (DRAWING API)
-- ==========================================
local ESP_Data = {}
local AllDrawings = {}

local function CreateDraw(Type, Properties)
    local obj = Drawing.new(Type)
    for k, v in pairs(Properties) do obj[k] = v end
    table.insert(AllDrawings, obj)
    return obj
end

local FOV_Circle = CreateDraw("Circle", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Filled = false})
local CrosshairDot = CreateDraw("Circle", {Thickness = 1, Radius = 3, Color = UI_THEME.Accent, Filled = true})

local function SetupESP(player)
    if ESP_Data[player] then return end
    local data = {
        BoxOutline = CreateDraw("Square", {Filled = false, Color = ESP_COLORS.Outline}),
        Box = CreateDraw("Square", {Filled = false}),
        HealthOutline = CreateDraw("Square", {Filled = true, Color = ESP_COLORS.Outline}),
        HealthBar = CreateDraw("Square", {Filled = true}),
        HealthText = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255,255,255)}),
        Name = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255,255,255)}),
        Distance = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = UI_THEME.TextGray}),
        Weapon = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = Color3.fromRGB(180,180,220)}),
        Tracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.5, Color = ESP_COLORS.Tracer}),
        SkeletonLines = {} 
    }
    ESP_Data[player] = data
    
    player.CharacterAdded:Connect(function(char) task.spawn(function() AnalyzePlayerHealth(player, char) end) end)
    if player.Character then task.spawn(function() AnalyzePlayerHealth(player, player.Character) end) end
end

local function RemoveESP(player)
    HealthCache[player] = nil
    if ESP_Data[player] then
        for k, v in pairs(ESP_Data[player]) do 
            if k == "SkeletonLines" then for _, l in ipairs(v) do l:Remove() end else v:Remove() end 
        end
        ESP_Data[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
Players.PlayerAdded:Connect(SetupESP)
Players.PlayerRemoving:Connect(RemoveESP)

local isAiming = false
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = true end end)
UserInputService.InputEnded:Connect(function(i, gp) if i.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = false end end)

local function GetAimPart(char)
    local sel = config.selectors.aim_part
    return sel == 1 and char:FindFirstChild("Head") or sel == 2 and char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end

local function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    local params = RaycastParams.new(); params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}; params.FilterType = Enum.RaycastFilterType.Exclude; params.IgnoreWater = true
    local result = Workspace:Raycast(origin, (targetPart.Position - origin), params)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- ==========================================
-- GŁÓWNA PĘTLA RENDEROWANIA
-- ==========================================
local mainLoop = RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    
    FOV_Circle.Position = mouseLoc; FOV_Circle.Radius = config.sliders.aim_fov; FOV_Circle.Visible = config.toggles.aim_showFov and config.toggles.aim_enabled
    CrosshairDot.Position = mouseLoc; CrosshairDot.Visible = config.toggles.aim_crosshair and config.toggles.aim_enabled

    -- AIMBOT LOGIC
    local closestTarget = nil; local shortestDist = math.huge
    if config.toggles.aim_enabled and isAiming then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
                local hp, _ = GetHP(player)
                if hp > 0 then
                    local aimPart = GetAimPart(player.Character)
                    if aimPart and (Camera.CFrame.Position - aimPart.Position).Magnitude <= config.sliders.aim_distance then
                        local targetPos = aimPart.Position
                        
                        -- PREDYKCJA RUCHU
                        if config.toggles.aim_predict and aimPart.AssemblyLinearVelocity then
                            targetPos = targetPos + (aimPart.AssemblyLinearVelocity * (config.sliders.aim_pred_amt / 100))
                        end

                        local pos, onScreen = Camera:WorldToScreenPoint(targetPos)
                        if onScreen then
                            local dist = (Vector2.new(pos.X + config.sliders.aim_offsetX, pos.Y + config.sliders.aim_offsetY) - mouseLoc).Magnitude
                            if dist <= config.sliders.aim_fov and dist < shortestDist then
                                if not config.toggles.aim_wallCheck or IsVisible(aimPart) then shortestDist = dist; closestTarget = targetPos end
                            end
                        end
                    end
                end
            end
        end

        if closestTarget then
            local pos = Camera:WorldToScreenPoint(closestTarget)
            local diffX = (pos.X + config.sliders.aim_offsetX) - mouseLoc.X
            local diffY = (pos.Y + config.sliders.aim_offsetY) - mouseLoc.Y
            local smooth = config.sliders.aim_smooth
            
            if mousemoverel then
                mousemoverel(smooth <= 1 and diffX or diffX / smooth, smooth <= 1 and diffY or diffY / smooth)
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), smooth <= 1 and 1 or (1 / smooth))
            end
        end
    end

    -- ESP LOGIC
    local t_Thick = config.sliders.boxThickness
    for player, esp in pairs(ESP_Data) do
        local isVisible = false
        local char = player.Character

        if config.esp_enabled and char and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
            local hp, maxHp = GetHP(player)
            local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head")

            if root and hp > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                
                if onScreen and dist <= config.sliders.esp_distance then
                    isVisible = true
                    
                    local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
                    local botPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                    local boxH = botPos.Y - topPos.Y; local boxW = boxH / 1.8; local boxX = pos.X - (boxW / 2); local boxY = topPos.Y
                    local drawColor = (player.Team == LocalPlayer.Team) and ESP_COLORS.Team or ESP_COLORS.Enemy
                    
                    if config.toggles.boxes then
                        esp.BoxOutline.Thickness = t_Thick + 2; esp.BoxOutline.Size = Vector2.new(boxW, boxH); esp.BoxOutline.Position = Vector2.new(boxX, boxY); esp.BoxOutline.Visible = true
                        esp.Box.Thickness = t_Thick; esp.Box.Size = Vector2.new(boxW, boxH); esp.Box.Position = Vector2.new(boxX, boxY); esp.Box.Color = drawColor; esp.Box.Visible = true
                    else esp.BoxOutline.Visible = false; esp.Box.Visible = false end

                    if config.toggles.healthbars then
                        local hpPct = math.clamp(hp / maxHp, 0, 1); local barH = boxH * hpPct
                        esp.HealthOutline.Size = Vector2.new(4, boxH + 2); esp.HealthOutline.Position = Vector2.new(boxX - 7, boxY - 1); esp.HealthOutline.Visible = true
                        esp.HealthBar.Size = Vector2.new(2, barH); esp.HealthBar.Position = Vector2.new(boxX - 6, boxY + (boxH - barH))
                        esp.HealthBar.Color = Color3.fromRGB(255 - (hpPct * 255), hpPct * 255, 30); esp.HealthBar.Visible = true
                        if config.toggles.healthtext and hp < maxHp then
                            esp.HealthText.Text = tostring(math.floor(hp)); esp.HealthText.Position = Vector2.new(boxX - 18, boxY + (boxH - barH) - 6); esp.HealthText.Visible = true
                        else esp.HealthText.Visible = false end
                    else esp.HealthOutline.Visible = false; esp.HealthBar.Visible = false; esp.HealthText.Visible = false end

                    if config.toggles.names then esp.Name.Text = player.Name; esp.Name.Position = Vector2.new(pos.X, boxY - 18); esp.Name.Visible = true else esp.Name.Visible = false end
                    local bottomY = boxY + boxH + 3
                    if config.toggles.distances then esp.Distance.Text = "[" .. math.floor(dist) .. "m]"; esp.Distance.Position = Vector2.new(pos.X, bottomY); esp.Distance.Visible = true; bottomY = bottomY + 14 else esp.Distance.Visible = false end
                    if config.toggles.weapons then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then esp.Weapon.Text = tool.Name; esp.Weapon.Position = Vector2.new(pos.X, bottomY); esp.Weapon.Visible = true else esp.Weapon.Visible = false end
                    else esp.Weapon.Visible = false end

                    if config.toggles.tracers then
                        local origin = screenCenter
                        if config.selectors.tracer_origin == 2 then origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        elseif config.selectors.tracer_origin == 3 then origin = mouseLoc end
                        esp.Tracer.From = origin; esp.Tracer.To = Vector2.new(pos.X, botPos.Y); esp.Tracer.Visible = true
                    else esp.Tracer.Visible = false end
                    
                    if config.toggles.skeletons then
                        local bones = GetBones(char)
                        for i, p in ipairs(bones) do
                            local p1, on1 = Camera:WorldToViewportPoint(p[1].Position)
                            local p2, on2 = Camera:WorldToViewportPoint(p[2].Position)
                            if on1 and on2 then
                                if not esp.SkeletonLines[i] then esp.SkeletonLines[i] = CreateDraw("Line", {Thickness = 1, Color = ESP_COLORS.Skeleton, Transparency = 0.8}) end
                                esp.SkeletonLines[i].From = Vector2.new(p1.X, p1.Y); esp.SkeletonLines[i].To = Vector2.new(p2.X, p2.Y); esp.SkeletonLines[i].Visible = true
                            elseif esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                        end
                        for i = #bones + 1, #esp.SkeletonLines do esp.SkeletonLines[i].Visible = false end
                    else
                        for _, l in ipairs(esp.SkeletonLines) do l.Visible = false end
                    end
                end
            end
        end

        if not isVisible then
            for k, v in pairs(esp) do if k == "SkeletonLines" then for _, l in ipairs(v) do l.Visible = false end else v.Visible = false end end
        end
    end
end)

_G.AsapwareUnload = function()
    if mainLoop then mainLoop:Disconnect(); mainLoop = nil end
    ScreenGui:Destroy()
    
    for _, esp in pairs(ESP_Data) do for k, v in pairs(esp) do if k == "SkeletonLines" then for _, l in ipairs(v) do l:Remove() end else v:Remove() end end end
    table.clear(ESP_Data); table.clear(HealthCache)

    for _, obj in ipairs(AllDrawings) do if obj.Remove then obj:Remove() end end
    table.clear(AllDrawings)
    
    _G.AsapwareUnload = nil
    print("ASAPWARE 13.1: Zniszczono pomyślnie.")
end

print("ASAPWARE 13.1: Aktywne! | [INSERT] Menu | [DEL] Zniszcz Cheata | [PPM] Aimbot")
