local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- KONFIGURACJA ASAPWARE 17.1 (COMPLETE)
-- ==========================================
local config = {
    esp_enabled = true,
    teamCheck = false,
    toggles = {
        boxes = true, healthbars = true, healthtext = true,
        names = true, weapons = true, distances = true,
        skeletons = false, tracers = false,
        aim_enabled = false, aim_showFov = true,
        aim_crosshair = true, aim_wallCheck = true, aim_predict = false
    },
    sliders = {
        esp_distance = 3000, esp_hue = 260, boxThickness = 1,
        aim_distance = 1500, aim_fov = 100, aim_smooth = 5,
        aim_offsetX = 0, aim_offsetY = 36, aim_pred_amt = 10,
        ui_hue = 260
    },
    selectors = { aim_part = 1, aim_method = 2, tracer_origin = 1 }
}

local function GetAccent() return Color3.fromHSV(config.sliders.ui_hue / 360, 0.7, 1) end

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
    task.wait(1.5); if not char or not char.Parent then return end
    local function findHealthAttributes(obj)
        local checkNames = {"Health", "HP", "CurrentHealth", "health", "hp", "HealthValue"}
        local maxNames = {"MaxHealth", "MaxHP", "maxhealth", "maxhp", "MaxHealthValue"}
        for _, n in ipairs(checkNames) do
            if obj:GetAttribute(n) then
                local mName = "MaxHealth"
                for _, mn in ipairs(maxNames) do if obj:GetAttribute(mn) then mName = mn break end end
                return n, mName
            end
        end return nil, nil
    end
    local currentHP_Func = nil
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MaxHealth > 1 then currentHP_Func = function() return hum.Health, hum.MaxHealth end end
    if not currentHP_Func then
        local n, mn = findHealthAttributes(char)
        if n then currentHP_Func = function() return char:GetAttribute(n) or 100, char:GetAttribute(mn) or 100 end
        else n, mn = findHealthAttributes(player); if n then currentHP_Func = function() return player:GetAttribute(n) or 100, player:GetAttribute(mn) or 100 end end end
    end
    if not currentHP_Func then
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                local ln = string.lower(desc.Name)
                if ln == "health" or ln == "hp" or ln == "currenthealth" then
                    local maxObj = nil
                    if desc.Parent then for _, sib in ipairs(desc.Parent:GetChildren()) do local ls = string.lower(sib.Name); if ls == "maxhealth" or ls == "maxhp" then maxObj = sib break end end end
                    currentHP_Func = function() return desc.Value, maxObj and maxObj.Value or 100 end; break
                end
            end
        end
    end
    if not currentHP_Func then currentHP_Func = function() return 100, 100 end end
    HealthCache[player] = { Char = char, Fetch = currentHP_Func }
end
local function GetHP(player) local cache = HealthCache[player]; if cache and cache.Char == player.Character then return cache.Fetch() end; return 100, 100 end

-- ==========================================
-- SILNIK UI "MINIMAL" (SZYBKI I STABILNY)
-- ==========================================
local TargetGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local ScreenGui = Instance.new("ScreenGui", TargetGui)
ScreenGui.Name = "AsapwareStable"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Theme = {
    BG = Color3.fromRGB(18, 18, 22),
    Sidebar = Color3.fromRGB(14, 14, 18),
    Section = Color3.fromRGB(24, 24, 28),
    Element = Color3.fromRGB(35, 35, 40),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(130, 130, 140),
    Border = Color3.fromRGB(40, 40, 45)
}

local AccentObjects = {}

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 750, 0, 520)
Main.Position = UDim2.new(0.5, -375, 0.5, -260)
Main.BackgroundColor3 = Theme.BG
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Theme.Border; MainStroke.Thickness = 1

local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = Main.Position end end)
Main.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)
local SidebarHider = Instance.new("Frame", Sidebar); SidebarHider.Size = UDim2.new(0, 6, 1, 0); SidebarHider.Position = UDim2.new(1, -6, 0, 0); SidebarHider.BackgroundColor3 = Theme.Sidebar; SidebarHider.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Sidebar)
Title.Size = UDim2.new(1, 0, 0, 60); Title.BackgroundTransparency = 1
Title.Text = "ASAPWARE"; Title.TextColor3 = Theme.Text; Title.Font = Enum.Font.GothamBold; Title.TextSize = 20
local Line = Instance.new("Frame", Title); Line.Size = UDim2.new(0.8, 0, 0, 1); Line.Position = UDim2.new(0.1, 0, 1, 0); Line.BackgroundColor3 = Theme.Border; Line.BorderSizePixel = 0

-- System Opisów (Info Box)
local InfoBox = Instance.new("Frame", Sidebar)
InfoBox.Size = UDim2.new(1, -20, 0, 110); InfoBox.Position = UDim2.new(0, 10, 1, -120)
InfoBox.BackgroundColor3 = Theme.Section; Instance.new("UICorner", InfoBox).CornerRadius = UDim.new(0, 4)
local InfoTitle = Instance.new("TextLabel", InfoBox); InfoTitle.Size = UDim2.new(1, -10, 0, 20); InfoTitle.Position = UDim2.new(0, 5, 0, 5); InfoTitle.BackgroundTransparency = 1; InfoTitle.Text = "Informacja"; InfoTitle.TextColor3 = GetAccent(); InfoTitle.Font = Enum.Font.GothamBold; InfoTitle.TextSize = 12; InfoTitle.TextXAlignment = Enum.TextXAlignment.Left; table.insert(AccentObjects, InfoTitle)
local InfoDesc = Instance.new("TextLabel", InfoBox); InfoDesc.Size = UDim2.new(1, -10, 1, -30); InfoDesc.Position = UDim2.new(0, 5, 0, 25); InfoDesc.BackgroundTransparency = 1; InfoDesc.Text = "Najedź na opcję, aby zobaczyć opis."; InfoDesc.TextColor3 = Theme.TextDark; InfoDesc.Font = Enum.Font.Gotham; InfoDesc.TextSize = 11; InfoDesc.TextXAlignment = Enum.TextXAlignment.Left; InfoDesc.TextYAlignment = Enum.TextYAlignment.Top; InfoDesc.TextWrapped = true

local function SetInfo(title, desc)
    InfoTitle.Text = title:upper()
    InfoDesc.Text = desc
end

local TabContainer = Instance.new("Frame", Main)
TabContainer.Size = UDim2.new(1, -190, 1, -20); TabContainer.Position = UDim2.new(0, 190, 0, 10)
TabContainer.BackgroundTransparency = 1

local tabs = {}
local function CreateTab(name, icon, yPos, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -20, 0, 35); btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Theme.Element; btn.BackgroundTransparency = isFirst and 0 or 1
    btn.Text = "  " .. icon .. "  " .. name; btn.TextColor3 = isFirst and GetAccent() or Theme.TextDark
    btn.Font = Enum.Font.GothamMedium; btn.TextSize = 13; btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    if isFirst then table.insert(AccentObjects, btn) end

    local page = Instance.new("ScrollingFrame", TabContainer)
    page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = isFirst
    page.ScrollBarThickness = 2; page.ScrollBarImageColor3 = Theme.Border
    local lay = Instance.new("UIListLayout", page); lay.Padding = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Btn.BackgroundTransparency = 1; t.Btn.TextColor3 = Theme.TextDark; t.Page.Visible = false end
        btn.BackgroundTransparency = 0; btn.TextColor3 = GetAccent()
        page.Visible = true
    end)
    
    tabs[name] = {Btn = btn, Page = page, Lay = lay}
    return tabs[name]
end

local function CreateSection(tab, title)
    local sec = Instance.new("Frame", tab.Page)
    sec.BackgroundColor3 = Theme.Section; sec.BorderSizePixel = 0
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", sec).Color = Theme.Border
    
    local lbl = Instance.new("TextLabel", sec); lbl.Size = UDim2.new(1, -20, 0, 25); lbl.Position = UDim2.new(0, 10, 0, 5); lbl.BackgroundTransparency = 1
    lbl.Text = title:upper(); lbl.TextColor3 = GetAccent(); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(AccentObjects, lbl)
    
    local content = Instance.new("Frame", sec); content.Size = UDim2.new(1, -20, 0, 0); content.Position = UDim2.new(0, 10, 0, 30); content.BackgroundTransparency = 1
    local cLay = Instance.new("UIListLayout", content); cLay.Padding = UDim.new(0, 5)
    
    cLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.Size = UDim2.new(1, -20, 0, cLay.AbsoluteContentSize.Y)
        sec.Size = UDim2.new(1, -10, 0, cLay.AbsoluteContentSize.Y + 40)
        tab.Page.CanvasSize = UDim2.new(0, 0, 0, tab.Lay.AbsoluteContentSize.Y + 10)
    end)
    return content
end

local function BindHover(obj, title, desc)
    obj.MouseEnter:Connect(function() SetInfo(title, desc) end)
    obj.MouseLeave:Connect(function() SetInfo("Asapware", "Najedź na opcję, aby zobaczyć opis.") end)
end

local function CreateToggle(parent, text, tbl, key, desc)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(1, 0, 0, 26); btn.BackgroundColor3 = Theme.Element; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", btn); lbl.Size = UDim2.new(1, -10, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.Text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local indicator = Instance.new("Frame", btn); indicator.Size = UDim2.new(0, 14, 0, 14); indicator.Position = UDim2.new(1, -20, 0.5, -7); indicator.BackgroundColor3 = tbl[key] and GetAccent() or Theme.Border
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 3)
    if tbl[key] then table.insert(AccentObjects, indicator) end
    
    btn.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        indicator.BackgroundColor3 = tbl[key] and GetAccent() or Theme.Border
    end)
    BindHover(btn, text, desc)
end

local function CreateSlider(parent, text, tbl, key, min, max, desc)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 40); frame.BackgroundColor3 = Theme.Element; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, -10, 0, 20); lbl.Position = UDim2.new(0, 10, 0, 2); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.Text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", frame); valLbl.Size = UDim2.new(1, -10, 0, 20); valLbl.Position = UDim2.new(0, 0, 0, 2); valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(tbl[key]); valLbl.TextColor3 = Theme.TextDark; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("TextButton", frame); track.Size = UDim2.new(1, -20, 0, 4); track.Position = UDim2.new(0, 10, 0, 28); track.BackgroundColor3 = Theme.Border; track.Text = ""; Instance.new("UICorner", track)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((tbl[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = GetAccent(); Instance.new("UICorner", fill); table.insert(AccentObjects, fill)

    local dragging = false
    local function update(i)
        local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pct))
        tbl[key] = val; valLbl.Text = tostring(val); fill.Size = UDim2.new(pct, 0, 1, 0)
        
        if key == "esp_hue" then ESP_COLORS.Enemy = Color3.fromHSV(val/360, 1, 1) end
        if key == "ui_hue" then 
            local c = GetAccent()
            for _, obj in ipairs(AccentObjects) do 
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = c else obj.BackgroundColor3 = c end 
            end
        end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
    BindHover(frame, text, desc)
end

local function CreateSelector(parent, text, tbl, key, options, desc)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(1, 0, 0, 26); btn.BackgroundColor3 = Theme.Element; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", btn); lbl.Size = UDim2.new(0.5, -10, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Theme.Text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", btn); valLbl.Size = UDim2.new(0.5, -10, 1, 0); valLbl.Position = UDim2.new(0.5, 0, 0, 0); valLbl.BackgroundTransparency = 1; valLbl.Text = options[tbl[key]]; valLbl.TextColor3 = GetAccent(); valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    table.insert(AccentObjects, valLbl)

    btn.MouseButton1Click:Connect(function()
        tbl[key] = tbl[key] + 1; if tbl[key] > #options then tbl[key] = 1 end
        valLbl.Text = options[tbl[key]]
    end)
    BindHover(btn, text, desc)
end

-- --- BUDOWA MENU ---
local tAim = CreateTab("Legitbot", "🎯", 70, true)
local tVis = CreateTab("Visuals", "👁️", 110, false)
local tSet = CreateTab("Settings", "⚙️", 150, false)

local aSec1 = CreateSection(tAim, "Wspomaganie Celowania")
CreateToggle(aSec1, "Włącz Aimbot", config.toggles, "aim_enabled", "Aktywuje system nakierowywania na cel.")
CreateToggle(aSec1, "Pokaż Zasięg (FOV)", config.toggles, "aim_showFov", "Rysuje na ekranie okrąg, w którym Aimbot szuka wrogów.")
CreateToggle(aSec1, "Sprawdzaj Ściany", config.toggles, "aim_wallCheck", "Nie namierza graczy schowanych za przeszkodami.")
CreateToggle(aSec1, "Przewidywanie Ruchu", config.toggles, "aim_predict", "Celuje przed poruszającego się wroga (Lead).")

local aSec2 = CreateSection(tAim, "Parametry Celowania")
CreateSelector(aSec2, "Część Ciała", config.selectors, "aim_part", {"Głowa", "Tors", "Środek"}, "Zdecyduj, w co ma celować bot.")
CreateSelector(aSec2, "Metoda Namierzania", config.selectors, "aim_method", {"Myszka", "Kamera (ACS)"}, "Użyj Kamera (ACS) jeśli grasz w gry typu strzelanki taktyczne.")
CreateSlider(aSec2, "Rozmiar FOV", config.sliders, "aim_fov", 10, 600, "Wielkość strefy detekcji.")
CreateSlider(aSec2, "Gładkość (Smooth)", config.sliders, "aim_smooth", 1, 20, "Większa wartość = bardziej naturalne, wolniejsze celowanie.")
CreateSlider(aSec2, "Siła Przewidywania", config.sliders, "aim_pred_amt", 1, 20, "Jak daleko w przód ma celować (tylko przy włączonym Prediction).")

-- PRZYWRÓCONA SEKCJA OFFSETS
local aSec3 = CreateSection(tAim, "Przesunięcie Celownika (Offsets)")
CreateSlider(aSec3, "Przesunięcie X (Lewo/Prawo)", config.sliders, "aim_offsetX", -100, 100, "Wymusza celowanie obok wroga (w poziomie).")
CreateSlider(aSec3, "Przesunięcie Y (Góra/Dół)", config.sliders, "aim_offsetY", -100, 100, "Wymusza celowanie nad lub pod wrogiem (idealne dla gier TPS).")

local vSec1 = CreateSection(tVis, "Główne ESP")
CreateToggle(vSec1, "Włącz ESP", config, "esp_enabled", "Włącza widzenie przez ściany.")
CreateToggle(vSec1, "Ramki 2D", config.toggles, "boxes", "Rysuje kwadrat wokół postaci.")
CreateToggle(vSec1, "Szkielety (Bones)", config.toggles, "skeletons", "Rysuje układ kostny postaci.")
CreateToggle(vSec1, "Paski Zdrowia", config.toggles, "healthbars", "Pokazuje graficzny pasek HP po lewej.")
CreateToggle(vSec1, "Zdrowie jako Liczba", config.toggles, "healthtext", "Pokazuje dokładne HP (np. 100) obok paska.")

local vSec2 = CreateSection(tVis, "Informacje o Graczu")
CreateToggle(vSec2, "Nazwy Graczy", config.toggles, "names", "Wyświetla nick nad głową.")
CreateToggle(vSec2, "Pokazuj Bronie", config.toggles, "weapons", "Wyświetla broń pod ramką gracza.")
CreateToggle(vSec2, "Pokazuj Dystans", config.toggles, "distances", "Wskazuje odległość (w metrach).")
CreateToggle(vSec2, "Linie Tracer", config.toggles, "tracers", "Rysuje linię na ekranie prosto do wroga.")
CreateSelector(vSec2, "Początek Tracera", config.selectors, "tracer_origin", {"Dół", "Środek", "Myszka"}, "Z jakiego punktu ekranu rysować linie.")

local vSec3 = CreateSection(tVis, "Wygląd Wizualizacji")
CreateSlider(vSec3, "Dystans Renderowania", config.sliders, "esp_distance", 100, 5000, "Z jakiej odległości maksymalnie widać graczy.")
CreateSlider(vSec3, "Kolor Wrogów (HUE)", config.sliders, "esp_hue", 0, 360, "Paleta barw - dostosuj kolor ESP.")

local cSec1 = CreateSection(tSet, "Konfiguracja Systemu")
CreateToggle(cSec1, "Ignoruj Drużynę", config, "teamCheck", "Nie celuje w sojuszników (Team Check).")
CreateSlider(cSec1, "Kolor Akcentu UI", config.sliders, "ui_hue", 0, 360, "Zmień motyw kolorystyczny menu na żywo.")

local btnUnload = Instance.new("TextButton", cSec1); btnUnload.Size = UDim2.new(1, 0, 0, 30); btnUnload.BackgroundColor3 = Color3.fromRGB(50, 20, 20); btnUnload.Text = "WYŁĄCZ CHEATA"; btnUnload.TextColor3 = Color3.fromRGB(255, 100, 100); btnUnload.Font = Enum.Font.GothamBold; btnUnload.TextSize = 12
Instance.new("UICorner", btnUnload).CornerRadius = UDim.new(0, 4)
btnUnload.MouseButton1Click:Connect(function() if _G.AsapwareUnload then _G.AsapwareUnload() end end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then ScreenGui.Enabled = not ScreenGui.Enabled end
    if input.KeyCode == Enum.KeyCode.Delete then if _G.AsapwareUnload then _G.AsapwareUnload() end end
end)

-- ==========================================
-- LOGIKA RYSOWANIA (DRAWING API) I ESP
-- ==========================================
local ESP_Data = {}
local AllDrawings = {}
local function CreateDraw(Type, Properties) local obj = Drawing.new(Type); for k, v in pairs(Properties) do obj[k] = v end; table.insert(AllDrawings, obj); return obj end

local FOV_Circle = CreateDraw("Circle", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Filled = false})
local CrosshairDot = CreateDraw("Circle", {Thickness = 1, Radius = 3, Color = GetAccent(), Filled = true})

local function SetupESP(player)
    if ESP_Data[player] then return end
    ESP_Data[player] = {
        BoxOutline = CreateDraw("Square", {Filled = false, Color = ESP_COLORS.Outline}),
        Box = CreateDraw("Square", {Filled = false}),
        HealthOutline = CreateDraw("Square", {Filled = true, Color = ESP_COLORS.Outline}),
        HealthBar = CreateDraw("Square", {Filled = true}),
        HealthText = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255,255,255)}),
        Name = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 13, Color = Color3.fromRGB(255,255,255)}),
        Distance = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = Theme.TextDark}),
        Weapon = CreateDraw("Text", {Center = true, Outline = true, Font = 2, Size = 12, Color = Color3.fromRGB(180,180,220)}),
        Tracer = CreateDraw("Line", {Thickness = 1, Transparency = 0.5, Color = ESP_COLORS.Tracer}),
        SkeletonLines = {} 
    }
    player.CharacterAdded:Connect(function(char) task.spawn(function() AnalyzePlayerHealth(player, char) end) end)
    if player.Character then task.spawn(function() AnalyzePlayerHealth(player, player.Character) end) end
end
local function RemoveESP(player) HealthCache[player] = nil; if ESP_Data[player] then for k, v in pairs(ESP_Data[player]) do if k == "SkeletonLines" then for _, l in ipairs(v) do l:Remove() end else v:Remove() end end; ESP_Data[player] = nil end end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
Players.PlayerAdded:Connect(SetupESP); Players.PlayerRemoving:Connect(RemoveESP)

local function GetAimPart(char) local sel = config.selectors.aim_part; return sel == 1 and char:FindFirstChild("Head") or sel == 2 and char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") end
local function IsVisible(targetPart) local origin = Camera.CFrame.Position; local params = RaycastParams.new(); params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}; params.FilterType = Enum.RaycastFilterType.Exclude; params.IgnoreWater = true; local result = Workspace:Raycast(origin, (targetPart.Position - origin), params); return not result or result.Instance:IsDescendantOf(targetPart.Parent) end

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
-- GŁÓWNA PĘTLA (RENDER STEPPED)
-- ==========================================
RunService:BindToRenderStep("AsapwareMain", 2000, function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local mouseLoc = UserInputService:GetMouseLocation()
    
    FOV_Circle.Position = mouseLoc; FOV_Circle.Radius = config.sliders.aim_fov; FOV_Circle.Visible = config.toggles.aim_showFov and config.toggles.aim_enabled
    CrosshairDot.Color = GetAccent(); CrosshairDot.Position = mouseLoc; CrosshairDot.Visible = config.toggles.aim_crosshair and config.toggles.aim_enabled

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
                            -- TUTAJ UŻYWANE SĄ PRZESUNIĘCIA (OFFSETS) DO OBLICZEŃ FOV
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
            -- TUTAJ OFFSETS KIERUJĄ MYSZKĘ / KAMERĘ W NOWE MIEJSCE
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
                    
                    -- Boxes
                    if config.toggles.boxes then
                        esp.BoxOutline.Thickness = t_Thick + 2; esp.BoxOutline.Size = Vector2.new(boxW, boxH); esp.BoxOutline.Position = Vector2.new(boxX, boxY); esp.BoxOutline.Visible = true
                        esp.Box.Thickness = t_Thick; esp.Box.Size = Vector2.new(boxW, boxH); esp.Box.Position = Vector2.new(boxX, boxY); esp.Box.Color = drawColor; esp.Box.Visible = true
                    else esp.BoxOutline.Visible = false; esp.Box.Visible = false end

                    -- Healthbars + Health Text
                    if config.toggles.healthbars then
                        local hpPct = math.clamp(hp / maxHp, 0, 1); local barH = boxH * hpPct
                        esp.HealthOutline.Size = Vector2.new(4, boxH + 2); esp.HealthOutline.Position = Vector2.new(boxX - 7, boxY - 1); esp.HealthOutline.Visible = true
                        esp.HealthBar.Size = Vector2.new(2, barH); esp.HealthBar.Position = Vector2.new(boxX - 6, boxY + (boxH - barH))
                        esp.HealthBar.Color = Color3.fromRGB(255 - (hpPct * 255), hpPct * 255, 30); esp.HealthBar.Visible = true
                        
                        if config.toggles.healthtext and hp < maxHp then
                            esp.HealthText.Text = tostring(math.floor(hp)); esp.HealthText.Position = Vector2.new(boxX - 18, boxY + (boxH - barH) - 6); esp.HealthText.Visible = true
                        else esp.HealthText.Visible = false end
                    else esp.HealthOutline.Visible = false; esp.HealthBar.Visible = false; esp.HealthText.Visible = false end

                    -- Names
                    if config.toggles.names then esp.Name.Text = player.Name; esp.Name.Position = Vector2.new(pos.X, boxY - 18); esp.Name.Visible = true else esp.Name.Visible = false end
                    
                    -- Distances & Weapons
                    local bottomY = boxY + boxH + 3
                    if config.toggles.distances then esp.Distance.Text = "[" .. math.floor(dist) .. "m]"; esp.Distance.Position = Vector2.new(pos.X, bottomY); esp.Distance.Visible = true; bottomY = bottomY + 14 else esp.Distance.Visible = false end
                    if config.toggles.weapons then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then esp.Weapon.Text = tool.Name; esp.Weapon.Position = Vector2.new(pos.X, bottomY); esp.Weapon.Visible = true else esp.Weapon.Visible = false end
                    else esp.Weapon.Visible = false end

                    -- Tracers
                    if config.toggles.tracers then
                        local origin = screenCenter
                        if config.selectors.tracer_origin == 2 then origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        elseif config.selectors.tracer_origin == 3 then origin = mouseLoc end
                        esp.Tracer.From = origin; esp.Tracer.To = Vector2.new(pos.X, botPos.Y); esp.Tracer.Visible = true
                    else esp.Tracer.Visible = false end
                    
                    -- Skeletons
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
end

print("ASAPWARE 17.1 (OFFSETS FIXED): Załadowano! Wciśnij [INSERT], aby otworzyć.")
