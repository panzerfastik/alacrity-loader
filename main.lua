-- ==========================================
--  ALACRITY PREMIUM v2.4 (STABLE)
--  #FreeSpeechLegion
--  Полный рефакторинг + фикс крашей + новый UI
--  + локальная key-system + admin key
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- ==========================================
--  KEY SYSTEM
-- ==========================================
local KEY_FILE = "alacrity_key_data.json"

local VALID_KEYS = {
    ["ALC-7K2M-9XQ4-1D"]   = 24,
    ["ALC-P3NR-5TW8-1D"]   = 24,
    ["ALC-H6YB-2LC9-1D"]   = 24,
    ["ALC-4FQD-8KZP-1D"]   = 24,
    ["ALC-N9VT-3MW7-1D"]   = 24,
    ["ALC-2XGR-6BHQ-1D"]   = 24,
    ["ALC-8LKC-4PZN-1D"]   = 24,
    ["ALC-5TWM-7YFR-1D"]   = 24,
    ["ALC-Q3HB-9DNK-1D"]   = 24,
    ["ALC-6ZPV-2XMG-1D"]   = 24,

    ["ALC-B4WK-8NQZ-30D"]  = 720,
    ["ALC-T7MF-3XLP-30D"]  = 720,
    ["ALC-9DHV-5RKQ-30D"]  = 720,
    ["ALC-K2YC-7WBN-30D"]  = 720,
    ["ALC-M8PQ-4TZF-30D"]  = 720,
    ["ALC-3LXR-6DHK-30D"]  = 720,
    ["ALC-W5NB-9CMV-30D"]  = 720,
    ["ALC-F7QZ-2KTP-30D"]  = 720,
    ["ALC-Y9RD-4WML-30D"]  = 720,
    ["ALC-C6HN-8BXV-30D"]  = 720,

    ["ALC-LIFE-7K9M-INF"]  = 0,
    ["ALC-LIFE-3N5P-INF"]  = 0,
    ["ALC-LIFE-8Q2R-INF"]  = 0,
    ["ALC-LIFE-5T4W-INF"]  = 0,
    ["ALC-LIFE-9Y6Z-INF"]  = 0,

    ["ALC-5K2B-9XT4-TOXIDER NIZE"] = 0,
}

local ADMIN_KEY = "ALC-5K2В-9XТ4-toxidernize"

local function NormalizeKey(key)
    if not key then return "" end
    key = string.gsub(key, "%s+", "")
    key = string.upper(key)
    key = string.gsub(key, "В", "B")
    key = string.gsub(key, "Т", "T")
    key = string.gsub(key, "А", "A")
    key = string.gsub(key, "С", "C")
    key = string.gsub(key, "Е", "E")
    key = string.gsub(key, "Н", "H")
    key = string.gsub(key, "К", "K")
    key = string.gsub(key, "М", "M")
    key = string.gsub(key, "О", "O")
    key = string.gsub(key, "Р", "P")
    key = string.gsub(key, "Х", "X")
    return key
end

local function GetHWID()
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id then return tostring(id) end
    return tostring(LocalPlayer.UserId)
end

local function ReadKeyData()
    if not (isfile and readfile) then return {} end
    local ok, data = pcall(function()
        if isfile(KEY_FILE) then
            return HttpService:JSONDecode(readfile(KEY_FILE))
        end
        return {}
    end)
    return ok and data or {}
end

local function WriteKeyData(data)
    if not writefile then return end
    pcall(function()
        writefile(KEY_FILE, HttpService:JSONEncode(data))
    end)
end

local function FindKeyRecord(normalizedKey, data)
    for storedKey, record in pairs(data) do
        if NormalizeKey(storedKey) == normalizedKey then
            return storedKey, record
        end
    end
    return nil, nil
end

local function GetKeyDuration(normalizedKey)
    for rawKey, hours in pairs(VALID_KEYS) do
        if NormalizeKey(rawKey) == normalizedKey then
            return hours
        end
    end
    if NormalizeKey(ADMIN_KEY) == normalizedKey then
        return 0
    end
    return nil
end

local function ValidateKey(key)
    local normalized = NormalizeKey(key)

    if normalized == NormalizeKey(ADMIN_KEY) then
        return true, "Admin access."
    end

    local durationHours = GetKeyDuration(normalized)
    if durationHours == nil then
        return false, "Ключ не найден."
    end

    local data = ReadKeyData()
    local storedKey, record = FindKeyRecord(normalized, data)

    local hwid = GetHWID()
    local now = os.time()

    if not record then
        local newRecord = {
            hwid = hwid,
            activated_at = now,
            expires_at = durationHours > 0 and (now + durationHours * 3600) or 0,
            life = durationHours == 0
        }
        data[normalized] = newRecord
        WriteKeyData(data)
        return true, "Активирован."
    end

    if record.hwid ~= hwid then
        return false, "Ключ привязан к другому ПК."
    end

    if record.life then
        return true, "Life time."
    end

    if now >= record.expires_at then
        return false, "Срок истёк."
    end

    return true, "OK."
end

local function ShowKeyPrompt()
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "AlacrityKeyPrompt"
    keyGui.ResetOnSpawn = false
    keyGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 360, 0, 200)
    frame.Position = UDim2.new(0.5, -180, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    frame.BorderSizePixel = 0
    frame.Parent = keyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(138, 43, 226)
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "ALACRITY — АКТИВАЦИЯ"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -40, 0, 40)
    input.Position = UDim2.new(0, 20, 0, 60)
    input.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderText = "ALC-XXXX-XXXX-XX"
    input.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    input.Text = ""
    input.TextSize = 14
    input.Font = Enum.Font.GothamMedium
    input.ClearTextOnFocus = false
    input.BorderSizePixel = 0
    input.Parent = frame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = input

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 0, 108)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 80, 80)
    status.TextSize = 12
    status.Font = Enum.Font.GothamMedium
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -40, 0, 40)
    button.Position = UDim2.new(0, 20, 0, 140)
    button.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "АКТИВИРОВАТЬ"
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    local success = false

    button.MouseButton1Click:Connect(function()
        local key = input.Text
        local ok, msg = ValidateKey(key)
        if ok then
            status.TextColor3 = Color3.fromRGB(80, 255, 120)
            status.Text = "✓ " .. msg
            success = true
            task.wait(0.8)
            keyGui:Destroy()
        else
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            status.Text = "✗ " .. msg
        end
    end)

    return function()
        return success
    end
end

local waitForKey = ShowKeyPrompt()
while not waitForKey() do
    task.wait(0.1)
end

-- ==========================================
--  НАСТРОЙКИ
-- ==========================================
local ESP_Settings = {
    ShowBoxes = true,
    ShowNames = true,
    ShowDistance = true,
    ColorByDist = true,
    ShowCompass = true,
    ShowChams = true,
    TeamCheck = true,
}

-- ==========================================
--  СОСТОЯНИЕ
-- ==========================================
local espData = {}
local connections = {}
local guiElements = {}
local isLoaded = true
local menuOpen = false

-- ==========================================
--  БЕЗОПАСНОЕ ПОЛУЧЕНИЕ ФРАКЦИИ
-- ==========================================
local function getPlayerFaction(player)
    if not player then return nil end
    local success, result = pcall(function()
        if player.Team then return player.Team.Name end
        local char = player.Character
        if not char then return nil end

        local teamVal = player:FindFirstChild("Team") or char:FindFirstChild("Team") or player:FindFirstChild("Faction") or char:FindFirstChild("Faction")
        if teamVal then
            if teamVal:IsA("StringValue") then return teamVal.Value end
            if teamVal:IsA("ObjectValue") and teamVal.Value then return teamVal.Value.Name end
            if teamVal:IsA("Folder") then return teamVal.Name end
        end

        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt then return shirt.ShirtTemplate end

        local pants = char:FindFirstChildOfClass("Pants")
        if pants then return pants.PantsTemplate end

        return nil
    end)

    return success and result or nil
end

-- ==========================================
--  БЕЗОПАСНОЕ УДАЛЕНИЕ ОБЪЕКТОВ
-- ==========================================
local function safeDestroy(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("Instance") then
            obj:Destroy()
        else
            obj:Remove()
        end
    end)
end

local function safeDisconnect(conn)
    if not conn then return end
    pcall(function()
        conn:Disconnect()
    end)
end

-- ==========================================
--  ОЧИСТКА ESP ДАННЫХ
-- ==========================================
local function cleanupESP(player)
    local data = espData[player]
    if not data then return end

    safeDisconnect(data.RenderConn)
    safeDestroy(data.Box)
    safeDestroy(data.Text)
    safeDestroy(data.Compass)
    safeDestroy(data.Chams)

    espData[player] = nil
end

local function cleanupAllESP()
    for player in pairs(espData) do
        cleanupESP(player)
    end
    espData = {}
end

-- ==========================================
--  UNLOAD
-- ==========================================
local function unload()
    if not isLoaded then return end
    isLoaded = false

    for _, conn in ipairs(connections) do
        safeDisconnect(conn)
    end
    connections = {}

    cleanupAllESP()

    for _, obj in ipairs(guiElements) do
        safeDestroy(obj)
    end
    guiElements = {}

    print("[Alacrity] Unloaded successfully!")
end

-- ==========================================
--  FATALITY АНИМАЦИЯ
-- ==========================================
local function showFatilityAnimation()
    if not isLoaded then return end

    local animGui = Instance.new("ScreenGui")
    animGui.Name = "FatilityAnim"
    animGui.ResetOnSpawn = false
    animGui.Parent = CoreGui
    table.insert(guiElements, animGui)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0
    frame.Parent = animGui

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 80)
    textLabel.Position = UDim2.new(0, 0, 0.4, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 60
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = true
    textLabel.Parent = frame

    local text = "ALACRITY"
    local currentText = ""

    task.spawn(function()
        for i = 1, #text do
            if not isLoaded then break end
            currentText = currentText .. text:sub(i, i)
            textLabel.Text = currentText
            task.wait(0.08)
        end

        if not isLoaded then return end
        task.wait(0.6)

        TweenService:Create(textLabel, TweenInfo.new(0.4), {
            TextTransparency = 1,
            Position = UDim2.new(0, 0, 0.3, 0)
        }):Play()

        TweenService:Create(frame, TweenInfo.new(0.4), {
            BackgroundTransparency = 1
        }):Play()

        task.wait(0.5)
        safeDestroy(animGui)
    end)
end

-- ==========================================
--  ПРИВЕТСТВИЕ
-- ==========================================
local function showGreeting()
    if not isLoaded then return end

    local greetGui = Instance.new("ScreenGui")
    greetGui.Name = "GreetingGui"
    greetGui.ResetOnSpawn = false
    greetGui.Parent = CoreGui
    table.insert(guiElements, greetGui)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.85, 0)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = greetGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "👋 Welcome, " .. LocalPlayer.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 18
    label.Font = Enum.Font.GothamBold
    label.TextTransparency = 1
    label.Parent = frame

    task.spawn(function()
        TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0.15}):Play()

        task.wait(2.5)

        if not isLoaded then return end

        TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()

        task.wait(0.5)
        safeDestroy(greetGui)
    end)
end

-- ==========================================
--  СОЗДАНИЕ GUI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlacrityPremiumUi"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
table.insert(guiElements, ScreenGui)

local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(0, 440, 0, 400)
Shadow.Position = UDim2.new(0.5, -220, 0.5, -190)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Shadow.Parent = ScreenGui
table.insert(guiElements, Shadow)

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 12)
ShadowCorner.Parent = Shadow

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 440, 0, 400)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui
table.insert(guiElements, MainFrame)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(138, 43, 226)
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 2)
Accent.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
Accent.BorderSizePixel = 0
Accent.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopLabel = Instance.new("TextLabel")
TopLabel.Size = UDim2.new(1, -20, 0, 24)
TopLabel.Position = UDim2.new(0, 16, 0, 6)
TopLabel.BackgroundTransparency = 1
TopLabel.Text = "ALACRITY PREMIUM"
TopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TopLabel.TextSize = 16
TopLabel.Font = Enum.Font.GothamBold
TopLabel.TextXAlignment = Enum.TextXAlignment.Left
TopLabel.Parent = TopBar

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -20, 0, 16)
SubLabel.Position = UDim2.new(0, 16, 0, 30)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "v2.4 // free speech legion"
SubLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
SubLabel.TextSize = 10
SubLabel.Font = Enum.Font.GothamMedium
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = TopBar

local SideBar = Instance.new("Frame")
SideBar.Size = UDim2.new(0, 140, 1, -50)
SideBar.Position = UDim2.new(0, 0, 0, 50)
SideBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
SideBar.BackgroundTransparency = 0.2
SideBar.BorderSizePixel = 0
SideBar.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -140, 1, -50)
ContentFrame.Position = UDim2.new(0, 140, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local Pages = {}
local TabsButtons = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
    page.Visible = false
    page.Parent = ContentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    Pages[name] = page
    return page
end

local function createCheckbox(page, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundTransparency = 1
    container.Parent = page

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(0, 0, 0.5, -10)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    box.BorderSizePixel = 0
    box.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1
    boxStroke.Color = Color3.fromRGB(80, 80, 90)
    boxStroke.Parent = box

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = "✓"
    check.TextColor3 = Color3.fromRGB(255, 255, 255)
    check.TextSize = 14
    check.Font = Enum.Font.GothamBold
    check.Visible = false
    check.Parent = box

    local label = Instance.new("TextButton")
    label.Size = UDim2.new(1, -28, 1, 0)
    label.Position = UDim2.new(0, 28, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local state = default

    local function update()
        if state then
            TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(138, 43, 226)}):Play()
            TweenService:Create(boxStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(138, 43, 226)}):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            check.Visible = true
        else
            TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
            TweenService:Create(boxStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 80, 90)}):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(180, 180, 190)}):Play()
            check.Visible = false
        end
        callback(state)
    end
    update()

    local function toggle()
        state = not state
        update()
    end

    box.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggle()
        end
    end)
    label.MouseButton1Click:Connect(toggle)
end

local function createUnloadButton(page)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = UDim2.new(0.05, 0, 0, 8)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "UNLOAD / EXIT"
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 60, 60)
    stroke.Transparency = 0.3
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(unload)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 30, 40)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
    end)
end

local function selectTab(name)
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
    end
    for n, b in pairs(TabsButtons) do
        if n == name then
            TweenService:Create(b, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(138, 43, 226)}):Play()
        else
            TweenService:Create(b, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(120, 120, 130), BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        end
    end
end

local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, (order-1)*44 + 8)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = icon .. "  " .. name:upper()
    btn.TextColor3 = Color3.fromRGB(120, 120, 130)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.AutoButtonColor = false
    btn.Parent = SideBar

    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)

    TabsButtons[name] = btn
    return btn
end

createTab("Visuals", "👁", 1)
createTab("Settings", "⚙", 2)

local visualsPage = createPage("Visuals")
local settingsPage = createPage("Settings")

createCheckbox(visualsPage, "2D Boxes", ESP_Settings.ShowBoxes, function(v) ESP_Settings.ShowBoxes = v end)
createCheckbox(visualsPage, "Enemy Names", ESP_Settings.ShowNames, function(v) ESP_Settings.ShowNames = v end)
createCheckbox(visualsPage, "Distance (m)", ESP_Settings.ShowDistance, function(v) ESP_Settings.ShowDistance = v end)
createCheckbox(visualsPage, "Color by Distance", ESP_Settings.ColorByDist, function(v) ESP_Settings.ColorByDist = v end)
createCheckbox(visualsPage, "Compass (Direction)", ESP_Settings.ShowCompass, function(v) ESP_Settings.ShowCompass = v end)
createCheckbox(visualsPage, "Chams (Wallhack)", ESP_Settings.ShowChams, function(v) ESP_Settings.ShowChams = v end)
createCheckbox(settingsPage, "Team Check", ESP_Settings.TeamCheck, function(v) ESP_Settings.TeamCheck = v end)

createUnloadButton(settingsPage)
selectTab("Visuals")

-- ==========================================
--  PING СЧЁТЧИК
-- ==========================================
local pingCounter = 0
local lastUpdate = tick()

local function updatePing()
    if tick() - lastUpdate >= 1 then
        pingCounter = math.random(20, 100)
        lastUpdate = tick()
    end
end

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 80, 0, 24)
statsFrame.Position = UDim2.new(1, -90, 0, 10)
statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statsFrame.BackgroundTransparency = 0.3
statsFrame.BorderSizePixel = 0
statsFrame.Parent = ScreenGui
table.insert(guiElements, statsFrame)

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 4)
statsCorner.Parent = statsFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "PING: 0ms"
statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statsLabel.TextSize = 11
statsLabel.Font = Enum.Font.GothamMedium
statsLabel.Parent = statsFrame

local pingConnection = RunService.Heartbeat:Connect(function()
    if not isLoaded then return end
    updatePing()
    statsLabel.Text = "PING: " .. pingCounter .. "ms"
end)
table.insert(connections, pingConnection)

-- ==========================================
--  ПЕРЕТАСКИВАНИЕ ОКНА
-- ==========================================
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================
--  ПЕРЕКЛЮЧЕНИЕ МЕНЮ
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        menuOpen = not menuOpen

        if menuOpen then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 440, 0, 0)
            TweenService:Create(MainFrame, TweenInfo.new(0.25), {
                Size = UDim2.new(0, 440, 0, 400),
                BackgroundTransparency = 0.05
            }):Play()
            TweenService:Create(Shadow, TweenInfo.new(0.25), {
                Size = UDim2.new(0, 440, 0, 400),
                BackgroundTransparency = 0.6
            }):Play()
        else
            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 440, 0, 0),
                BackgroundTransparency = 1
            })
            tween:Play()
            TweenService:Create(Shadow, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 440, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            tween.Completed:Connect(function()
                if not menuOpen then
                    MainFrame.Visible = false
                end
            end)
        end
    end
end)

-- ==========================================
--  СОЗДАНИЕ ESP
-- ==========================================
local function createESP(player)
    if player == LocalPlayer then return end
    if not isLoaded then return end

    cleanupESP(player)

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Thickness = 1.2
    box.Filled = false
    box.Transparency = 0.3

    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 13
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)

    local compass = Drawing.new("Text")
    compass.Visible = false
    compass.Color = Color3.fromRGB(255, 255, 255)
    compass.Size = 18
    compass.Center = true
    compass.Outline = true
    compass.OutlineColor = Color3.fromRGB(0, 0, 0)
    compass.Text = "⬆️"

    local chams = Instance.new("Highlight")
    chams.Enabled = false
    chams.FillColor = Color3.fromRGB(255, 0, 0)
    chams.FillTransparency = 0.4
    chams.OutlineColor = Color3.fromRGB(255, 0, 0)
    chams.OutlineTransparency = 0.2
    chams.Adornee = nil
    chams.Parent = CoreGui

    espData[player] = {
        Box = box,
        Text = text,
        Compass = compass,
        Chams = chams,
        RenderConn = nil
    }

    local renderConnection
    renderConnection = RunService.RenderStepped:Connect(function()
        if not isLoaded then
            cleanupESP(player)
            return
        end

        if not player.Parent then
            cleanupESP(player)
            return
        end

        local char = player.Character
        if not char or not char.Parent then
            box.Visible = false
            text.Visible = false
            compass.Visible = false
            chams.Enabled = false
            return
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if not root or not head or not hum or hum.Health <= 0 or not myRoot then
            box.Visible = false
            text.Visible = false
            compass.Visible = false
            chams.Enabled = false
            return
        end

        if ESP_Settings.TeamCheck then
            local myFaction = getPlayerFaction(LocalPlayer)
            local theirFaction = getPlayerFaction(player)

            if myFaction and theirFaction and myFaction == theirFaction then
                box.Visible = false
                text.Visible = false
                compass.Visible = false
                chams.Enabled = false
                return
            end
        end

        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos, legOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        local dist = (myRoot.Position - root.Position).Magnitude

        local color
        if ESP_Settings.ColorByDist then
            if dist < 50 then
                color = Color3.fromRGB(255, 60, 60)
            elseif dist < 150 then
                color = Color3.fromRGB(255, 200, 60)
            else
                color = Color3.fromRGB(60, 255, 60)
            end
        else
            color = Color3.fromRGB(255, 255, 255)
        end

        if ESP_Settings.ShowChams then
            chams.Adornee = char
            chams.Enabled = true
            if headOnScreen and legOnScreen then
                chams.FillColor = Color3.fromRGB(0, 255, 100)
                chams.OutlineColor = Color3.fromRGB(0, 255, 100)
            else
                chams.FillColor = Color3.fromRGB(255, 50, 50)
                chams.OutlineColor = Color3.fromRGB(255, 50, 50)
            end
        else
            chams.Enabled = false
        end

        if headOnScreen and legOnScreen then
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 1.6

            if ESP_Settings.ShowBoxes then
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                box.Color = color
                box.Visible = true
            else
                box.Visible = false
            end

            if ESP_Settings.ShowNames or ESP_Settings.ShowDistance then
                local displayText = ""
                if ESP_Settings.ShowNames then
                    displayText = player.Name
                end
                if ESP_Settings.ShowDistance then
                    local distText = "[" .. math.floor(dist) .. "m]"
                    displayText = (displayText ~= "") and (displayText .. " " .. distText) or distText
                end
                text.Text = displayText
                text.Color = color
                text.Position = Vector2.new(headPos.X, headPos.Y + height + 4)
                text.Visible = true
            else
                text.Visible = false
            end

            compass.Visible = false
        else
            box.Visible = false
            text.Visible = false

            if ESP_Settings.ShowCompass then
                local dir = (root.Position - myRoot.Position).Unit
                local angle = math.atan2(dir.X, dir.Z) - Camera.CFrame.Y
                local edgeX = Camera.ViewportSize.X / 2 + math.sin(angle) * Camera.ViewportSize.X * 0.4
                local edgeY = Camera.ViewportSize.Y / 2 - math.cos(angle) * Camera.ViewportSize.Y * 0.35
                compass.Position = Vector2.new(edgeX, edgeY)
                compass.Color = color
                compass.Visible = true
            else
                compass.Visible = false
            end
        end
    end)

    local data = espData[player]
    if data then
        data.RenderConn = renderConnection
    end

    local charRemovedConnection
    charRemovedConnection = player.CharacterRemoving:Connect(function()
        if not isLoaded then return end

        box.Visible = false
        text.Visible = false
        compass.Visible = false
        chams.Enabled = false

        safeDisconnect(charRemovedConnection)
    end)
    table.insert(connections, charRemovedConnection)
end

-- ==========================================
--  ПЕРЕИНИЦИАЛИЗАЦИЯ
-- ==========================================
local function reinitialize()
    if not isLoaded then return end

    cleanupAllESP()

    task.wait(0.5)

    if not isLoaded then return end

    if LocalPlayer.Character and LocalPlayer.Character.Parent then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
    end
end

-- ==========================================
--  ЗАПУСК
-- ==========================================
showFatilityAnimation()
task.wait(0.2)
showGreeting()
task.wait(0.3)
reinitialize()

table.insert(connections, Players.PlayerAdded:Connect(function(player)
    if isLoaded then
        createESP(player)
    end
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    if isLoaded then
        reinitialize()
    end
end))

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    unload()
end)
