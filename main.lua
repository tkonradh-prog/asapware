local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- KONFIGURACJA ASAPWARE 15.0 (LUCID UI)
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
        esp_hue = 240, 
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
        aim_method = 2, -- 1 = Mouse, 2 = Camera (IDEALNE DLA ACS)
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
-- SILNIK UI "LUCID" (PRZEJRZYSTY DESIGN)
-- ==========================================
local UI_THEME = {
    MainBG = Color3.fromRGB(12, 12, 17),       -- Bardzo ciemny granat
    SidebarBG = Color3.fromRGB(8, 8, 11),      -- Niemal czarny dla kontrastu
    CardBG = Color3.fromRGB(18, 18, 25),       -- Tło sekcji (Karty)
    Accent = Color3.fromRGB(130, 110, 255),    -- Fioletowo-Niebieski "Premium"
    ElementBG = Color3.fromRGB(28, 28, 38),    -- Tło przycisków/suwaków
    TextWhite = Color3.fromRGB(245, 245, 250),
    TextGray = Color3.fromRGB(150, 150, 165),
    Border = Color3.fromRGB(35, 35, 48)
}

local TargetGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AsapwareLucid"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = TargetGui

-- Główne Okno
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 780, 0, 540)
MainFrame.Position = UDim2.new(0.5, -390, 0.5, -270)
MainFrame.BackgroundColor3 = UI_THEME.MainBG
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = UI_THEME.Border; MainStroke.Thickness = 1

-- Dragging
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

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 190, 1, 0)
Sidebar.BackgroundColor3 = UI_THEME.SidebarBG
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SidebarHider = Instance.new("Frame", Sidebar)
SidebarHider.Size = UDim2.new(0, 10, 1, 0); SidebarHider.Position = UDim2.new(1, -10, 0, 0)
SidebarHider.BackgroundColor3 = UI_THEME.SidebarBG; SidebarHider.BorderSizePixel = 0

local TitleLine = Instance.new("Frame", Sidebar)
TitleLine.Size = UDim2.new(1, 0, 0, 2); TitleLine.BackgroundColor3 = UI_THEME.Accent; TitleLine.BorderSizePixel = 0
Instance.new("UICorner", TitleLine).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Sidebar)
Title.Size = UDim2.new(1, 0, 0, 70); Title.BackgroundTransparency = 1
Title.Text = "ASAPWARE"; Title.TextColor3 = UI_THEME.TextWhite
Title.Font = Enum.Font.GothamBold; Title.TextSize = 22; Title.Position = UDim2.new(0, 0, 0, 5)

-- Obszar Zakładek
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -210, 1, -20); TabContainer.Position = UDim2.new(0, 200, 0, 10)
TabContainer.BackgroundTransparency = 1

local tabs = {}
local function CreateTabButton(name, icon, yPos, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -20, 0, 42); btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = UI_THEME.ElementBG; btn.BackgroundTransparency = isFirst and 0 or 1
    btn.Text = "   " .. icon .. "  " .. name; btn.TextColor3 = isFirst and UI_THEME.TextWhite or UI_THEME.TextGray
    btn.Font = Enum.Font.GothamMedium; btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("Frame", TabContainer)
    page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = isFirst
    
    -- Prawdziwy układ dwukolumnowy
    local colLeft = Instance.new("ScrollingFrame", page)
    colLeft.Size = UDim2.new(0.49, 0, 1, 0); colLeft.BackgroundTransparency = 1; colLeft.ScrollBarThickness = 0
    local layL = Instance.new("UIListLayout", colLeft); layL.Padding = UDim.new(0, 12); layL.SortOrder = Enum.SortOrder.LayoutOrder
    
    local colRight = Instance.new("ScrollingFrame", page)
    colRight.Size = UDim2.new(0.49, 0, 1, 0); colRight.Position = UDim2.new(0.51, 0, 0, 0); colRight.BackgroundTransparency = 1; colRight.ScrollBarThickness = 0
    local layR = Instance.new("UIListLayout", colRight); layR.Padding = UDim.new(0, 12); layR.SortOrder = Enum.SortOrder.LayoutOrder

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do 
            TweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = UI_THEME.TextGray}):Play()
            t.Page.Visible = false 
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0, TextColor3 = UI_THEME.TextWhite}):Play()
        page.Visible = true
    end)
    
    tabs[name] = {Btn = btn, Page = page, Col1 = colLeft, Col2 = colRight, L1 = layL, L2 = layR}
    return tabs[name]
end

local function CreateCard(tabData, columnIdx, title)
    local targetCol = columnIdx == 1 and tabData.Col1 or tabData.Col2
    local targetLay = columnIdx == 1 and tabData.L1 or tabData.L2
    
    local card = Instance.new("Frame", targetCol)
    card.BackgroundColor3 = UI_THEME.CardBG; card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local str = Instance.new("UIStroke", card); str.Color = UI_THEME.Border; str.Thickness = 1
    
    local lay = Instance.new("UIListLayout", card); lay.Padding = UDim.new(0, 6); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local header = Instance.new("TextLabel", card)
    header.Size = UDim2.new(1, -20, 0, 30); header.BackgroundTransparency = 1
    header.Text = title; header.TextColor3 = UI_THEME.Accent; header.Font = Enum.Font.GothamBold; header.TextSize = 12; header.TextXAlignment = Enum.TextXAlignment.Left
    
    local div = Instance.new("Frame", card); div.Size = UDim2.new(1, 0, 0, 1); div.BackgroundColor3 = UI_THEME.Border; div.BorderSizePixel = 0
    
    local content = Instance.new("Frame", card)
    content.Size = UDim2.new(1, -20, 0, 0); content.BackgroundTransparency = 1
    local contLay = Instance.new("UIListLayout", content); contLay.Padding = UDim.new(0, 8); contLay.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Auto Resize logic
    local function resize()
        content.Size = UDim2.new(1, -20, 0, contLay.AbsoluteContentSize.Y)
        card.Size = UDim2.new(1, 0, 0, lay.AbsoluteContentSize.Y + 10)
        targetCol.CanvasSize = UDim2.new(0, 0, 0, targetLay.AbsoluteContentSize.Y + 20)
    end
    contLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
    
    return content
end

local function CreateToggle(parent, text, tbl, key)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 26); frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, -45, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = UI_THEME.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local bg = Instance.new("TextButton", frame); bg.Size = UDim2.new(0, 36, 0, 18); bg.Position = UDim2.new(1, -36, 0.5, -9)
    bg.BackgroundColor3 = tbl[key] and UI_THEME.Accent or UI_THEME.ElementBG; bg.Text = ""; bg.AutoButtonColor = false
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", bg); knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = tbl[key] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    bg.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = tbl[key] and UI_THEME.Accent or UI_THEME.ElementBG}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = tbl[key] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
    end)
end

local function CreateSlider(parent, text, tbl, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 40); frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = UI_THEME.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLbl = Instance.new("TextLabel", frame); valLbl.Size = UDim2.new(1, 0, 0, 18); valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(tbl[key]); valLbl.TextColor3 = UI_THEME.Accent; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local bg = Instance.new("TextButton", frame); bg.Size = UDim2.new(1, 0, 0, 6); bg.Position = UDim2.new(0, 0, 0, 26)
    bg.BackgroundColor3 = UI_THEME.ElementBG; bg.Text = ""; bg.AutoButtonColor = false; Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", bg); local pct = (tbl[key] - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0); fill.BackgroundColor3 = UI_THEME.Accent; Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local isDragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local newVal = math.floor(min + ((max - min) * pos))
        tbl[key] = newVal; valLbl.Text = tostring(newVal)
        TweenService:Create(fill, TweenInfo.new(0.05), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        if key == "esp_hue" then ESP_COLORS.Enemy = Color3.fromHSV(newVal/360, 1, 1) end
    end
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
end

local function CreateSelector(parent, text, tbl, key, options)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = UI_THEME.TextWhite; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0.5, 0, 0, 24); btn.Position = UDim2.new(0.5, 0, 0.5, -12)
    btn.BackgroundColor3 = UI_THEME.ElementBG; btn.Text = options[tbl[key]]; btn.TextColor3 = UI_THEME.TextGray; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", btn).Color = UI_THEME.Border
    
    btn.MouseButton1Click:Connect(function()
        tbl[key] = tbl[key] + 1; if tbl[key] > #options then tbl[key] = 1 end
        btn.Text = options[tbl[key]]
    end)
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(1, 0, 0, 32); btn.BackgroundColor3 = UI_THEME.ElementBG
    btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 80, 80); btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", btn).Color = UI_THEME.Border
    btn.MouseButton1Click:Connect(callback)
end

-- Budowa Menu
local tAim = CreateTabButton("Legitbot", "🎯", 80, true)
local tVis = CreateTabButton("Visuals", "👁️", 130, false)
local tSet = CreateTabButton("Config", "⚙️", 180, false)

-- Aimbot Tab
local aCard1 = CreateCard(tAim, 1, "COMBAT ASSIST")
CreateToggle(aCard1, "Enable Aimbot", config.toggles, "aim_enabled")
CreateToggle(aCard1, "Draw FOV Circle", config.toggles, "aim_showFov")
CreateToggle(aCard1, "Draw Crosshair", config.toggles, "aim_crosshair")
CreateToggle(aCard1, "Visibility Check", config.toggles, "aim_wallCheck")
CreateToggle(aCard1, "Velocity Prediction", config.toggles, "aim_predict")

local aCard2 = CreateCard(tAim, 2, "PROPERTIES")
CreateSelector(aCard2, "Target Part", config.selectors, "aim_part", {"Head", "Torso", "Root"})
CreateSelector(aCard2, "Aim Method", config.selectors, "aim_method", {"Mouse", "Camera (ACS)"})
CreateSlider(aCard2, "Max Distance (m)", config.sliders, "aim_distance", 50, 5000)
CreateSlider(aCard2, "FOV Radius", config.sliders, "aim_fov", 10, 800)
CreateSlider(aCard2, "Smoothness", config.sliders, "aim_smooth", 1, 20)
CreateSlider(aCard2, "Predict Strength", config.sliders, "aim_pred_amt", 1, 20)

local aCard3 = CreateCard(tAim, 1, "OFFSETS")
CreateSlider(aCard3, "Aim Offset X", config.sliders, "aim_offsetX", -100, 100)
CreateSlider(aCard3, "Aim Offset Y", config.sliders, "aim_offsetY", -100, 100)

-- Visuals Tab
local vCard1 = CreateCard(tVis, 1, "ESP MAIN")
CreateToggle(vCard1, "Master Switch", config, "esp_enabled")
CreateToggle(vCard1, "Bounding Boxes", config.toggles, "boxes")
CreateToggle(vCard1, "Health Bars", config.toggles, "healthbars")
CreateToggle(vCard1, "Health Text", config.toggles, "healthtext")
CreateToggle(vCard1, "Draw Skeletons", config.toggles, "skeletons")

local vCard2 = CreateCard(tVis, 2, "INFORMATION")
CreateToggle(vCard2, "Show Names", config.toggles, "names")
CreateToggle(vCard2, "Show Weapons", config.toggles, "weapons")
CreateToggle(vCard2, "Show Distances", config.toggles, "distances")
CreateToggle(vCard2, "Show Tracers", config.toggles, "tracers")
CreateSelector(vCard2, "Tracer Origin", config.selectors, "tracer_origin", {"Bottom", "Center", "Mouse"})

local vCard3 = CreateCard(tVis, 1, "APPEARANCE")
CreateSlider(vCard3, "Render Distance", config.sliders, "esp_distance", 50, 5000)
CreateSlider(vCard3, "Enemy Color (HUE)", config.sliders, "esp_hue", 0, 360)

-- Config Tab
local cCard1 = CreateCard(tSet, 1, "SYSTEM")
CreateToggle(cCard1, "Team Check", config, "teamCheck")
CreateButton(cCard1, "UNLOAD ASAPWARE", function() if _G.AsapwareUnload then _G.AsapwareUnload() end end)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Insert then ScreenGui.Enabled = not ScreenGui.Enabled end
    if input.KeyCode == Enum.KeyCode.Delete then if _G.AsapwareUnload then _G.AsapwareUnload() end end
end)


-- ==========================================
-- LOGIKA RYSOWANIA (DRAWING API) I ESP
-- ==========================================
local ESP_Data = {}
local AllDrawings = {}
local function CreateDraw(Type, Properties)
    local obj = Drawing.new(Type); for k, v in pairs(Properties) do obj[k] = v end
    table.insert(AllDrawings, obj); return obj
end

local FOV_Circle = CreateDraw("Circle", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Filled = false})
local CrosshairDot = CreateDraw("Circle", {Thickness = 1, Radius = 3, Color = UI_THEME.Accent, Filled = true})

local function SetupESP(player)
    if ESP_Data[player] then return end
    ESP_Data[player] = {
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
    player.CharacterAdded:Connect(function(char) task.spawn(function() AnalyzePlayerHealth(player, char) end) end)
    if player.Character then task.spawn(function() AnalyzePlayerHealth(player, player.Character) end) end
end

local function RemoveESP(player)
    HealthCache[player] = nil
    if ESP_Data[player] then
        for k, v in pairs(ESP_Data[player]) do if k == "SkeletonLines" then for _, l in ipairs(v) do l:Remove() end else v:Remove() end end
        ESP_Data[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
Players.PlayerAdded:Connect(SetupESP); Players.PlayerRemoving:Connect(RemoveESP)

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

local function GetBones(char)
    local bones = {}
    if char:FindFirstChild("UpperTorso") then
        local pairs = { {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"} }
        for _, p in ipairs(pairs) do local p1, p2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2]); if p1 and p2 then table.insert(bones, {p1, p2}) end end
    elseif char:FindFirstChild("Torso") then
        local pairs = { {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"} }
        for _, p in ipairs(pairs) do local p1, p2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2]); if p1 and p2 then table.insert(bones, {p1, p2}) end end
    end
    return bones
end

-- ==========================================
-- GŁÓWNA PĘTLA (PRIORITY 2000 - ACS BYPASS)
-- ==========================================
RunService:BindToRenderStep("AsapwareMain", 2000, function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    
    FOV_Circle.Position = mouseLoc; FOV_Circle.Radius = config.sliders.aim_fov; FOV_Circle.Visible = config.toggles.aim_showFov and config.toggles.aim_enabled
    CrosshairDot.Position = mouseLoc; CrosshairDot.Visible = config.toggles.aim_crosshair and config.toggles.aim_enabled

    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local closestTarget = nil; local shortestDist = math.huge

    if config.toggles.aim_enabled and isAiming then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and (not config.teamCheck or player.Team ~= LocalPlayer.Team) then
                local hp, _ = GetHP(player)
                if hp > 0 then
                    local aimPart = GetAimPart(player.Character)
                    if aimPart and (Camera.CFrame.Position - aimPart.Position).Magnitude <= config.sliders.aim_distance then
                        local targetPos = aimPart.Position
                        if config.toggles.aim_predict and aimPart.AssemblyLinearVelocity then targetPos = targetPos + (aimPart.AssemblyLinearVelocity * (config.sliders.aim_pred_amt / 100)) end

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
            
            if config.selectors.aim_method == 1 then
                if mousemoverel then mousemoverel(smooth <= 1 and diffX or diffX / smooth, smooth <= 1 and diffY or diffY / smooth)
                else Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), smooth <= 1 and 1 or (1 / smooth)) end
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget), smooth <= 1 and 1 or (1 / smooth))
            end
        end
    end

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
    RunService:UnbindFromRenderStep("AsapwareMain")
    if ScreenGui then ScreenGui:Destroy() end
    for _, esp in pairs(ESP_Data) do for k, v in pairs(esp) do if k == "SkeletonLines" then for _, l in ipairs(v) do l:Remove() end else v:Remove() end end end
    table.clear(ESP_Data); table.clear(HealthCache)
    for _, obj in ipairs(AllDrawings) do if obj.Remove then obj:Remove() end end
    table.clear(AllDrawings)
    _G.AsapwareUnload = nil
    print("ASAPWARE 15.0: Zniszczono pomyślnie.")
end

print("ASAPWARE 15.0: Aktywne! | [INSERT] Menu | [DEL] Zniszcz Cheata")
