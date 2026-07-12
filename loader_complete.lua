--[[
    ═══════════════════════════════════════════════════════════════
    BLOX FRUITS PREMIUM V2.0 - COMPLETE LOADER WITH KEY SYSTEM
    ═══════════════════════════════════════════════════════════════
    
    SETUP INSTRUCTIONS:
    1. Go to https://dashboard.work.ink/
    2. Create a shortened link with destination: https://work.ink/token
    3. Replace the values in the CONFIG section below:
       - YOUR_LINK_ID: Your work.ink short link ID (e.g., "2JiA")
       - YOUR_FULL_LINK: Your complete work.ink link with token (e.g., "https://work.ink/2JiA/xxxxx")
       - YOUR_DISCORD: Your Discord invite link
    4. Host premium_version.lua on GitHub or pastebin
    5. Replace PREMIUM_SCRIPT_URL with your hosted script URL
    
    HOW IT WORKS:
    1. Checks if player is in Blox Fruits
    2. Shows key system UI
    3. Validates key with work.ink API v2
    4. Loads premium script after successful validation
    5. Saves valid keys locally (auto-login next time)
]]

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION - CHANGE THESE VALUES!
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
    -- work.ink key system settings
    LINK_ID = "2JiA", -- Your work.ink link ID
    FULL_LINK = "https://work.ink/2JiA/d653afbe-06a3-4fc9-ba5f-674b59ebcbbd", -- Your full work.ink link
    DISCORD_INVITE = "https://discord.gg/t9xNXQzSvs", -- Your Discord server
    
    -- Premium script location
    PREMIUM_SCRIPT_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/blox_fruits_premium.lua", -- ← UPDATE THIS AFTER GITHUB UPLOAD
    
    -- Script info
    SCRIPT_NAME = "Blox Fruits Premium V2.0",
    SCRIPT_VERSION = "v2.0",
    
    -- Settings
    SAVE_KEY = true, -- Save keys locally for auto-login
    MAX_ATTEMPTS = 5, -- Max failed key attempts before cooldown
    COOLDOWN_TIME = 30, -- Cooldown duration in seconds
}

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- GAME CHECK
-- ═══════════════════════════════════════════════════════════════
local BLOX_FRUITS_IDS = {2753915549, 4442272183, 7449423635}
local isBloxFruits = false

for _, id in ipairs(BLOX_FRUITS_IDS) do
    if game.PlaceId == id then
        isBloxFruits = true
        break
    end
end

if not isBloxFruits then
    StarterGui:SetCore("SendNotification", {
        Title = "❌ Wrong Game",
        Text = "This script is for Blox Fruits only!",
        Duration = 5
    })
    return
end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- KEY STORAGE
-- ═══════════════════════════════════════════════════════════════
local KEY_FILE = "bloxfruits_premium_key.txt"

local function SaveKey(key)
    if not CONFIG.SAVE_KEY then return end
    pcall(function()
        writefile(KEY_FILE, key)
    end)
end

local function LoadKey()
    if not CONFIG.SAVE_KEY then return nil end
    local success, key = pcall(function()
        return readfile(KEY_FILE)
    end)
    return success and key or nil
end

-- ═══════════════════════════════════════════════════════════════
-- KEY VALIDATION
-- ═══════════════════════════════════════════════════════════════
local KeyValidated = false
local FailedAttempts = 0
local LastAttemptTime = 0

local function ValidateKey(key)
    print("[🍎 Blox Fruits] Validating key...")
    
    -- Cooldown check
    if tick() - LastAttemptTime < CONFIG.COOLDOWN_TIME and FailedAttempts >= CONFIG.MAX_ATTEMPTS then
        local remaining = math.ceil(CONFIG.COOLDOWN_TIME - (tick() - LastAttemptTime))
        return false, "Too many attempts! Wait " .. remaining .. "s"
    end
    
    -- Basic validation
    if not key or key == "" or #key < 10 then
        return false, "Please enter a valid key"
    end
    
    -- Clean key (remove spaces)
    key = key:gsub("%s+", "")
    
    -- Build API URL
    local apiUrl = "https://work.ink/_api/v2/token/isValid/" .. key
    
    -- Make API request
    local success, response = pcall(function()
        return game:HttpGet(apiUrl)
    end)
    
    if not success then
        print("[🍎 Blox Fruits] HTTP error:", response)
        LastAttemptTime = tick()
        FailedAttempts = FailedAttempts + 1
        return false, "Connection error. Check internet."
    end
    
    -- Parse JSON
    local decoded
    success, decoded = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success then
        print("[🍎 Blox Fruits] JSON parse error:", decoded)
        LastAttemptTime = tick()
        FailedAttempts = FailedAttempts + 1
        return false, "Invalid server response"
    end
    
    -- Check validity
    if decoded.valid == true then
        KeyValidated = true
        SaveKey(key)
        FailedAttempts = 0
        print("[🍎 Blox Fruits] Key validated successfully!")
        return true, "Key validated!"
    else
        print("[🍎 Blox Fruits] Invalid key")
        LastAttemptTime = tick()
        FailedAttempts = FailedAttempts + 1
        return false, "Invalid key. Get a new one."
    end
end

-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM UI
-- ═══════════════════════════════════════════════════════════════
local function CreateKeySystemUI(onValidated)
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BloxFruitsKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 450, 0, 360)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -180)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 12)
    FrameCorner.Parent = Frame
    
    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ZIndex = 0
    Shadow.Parent = Frame
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar
    
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 12)
    TopBarFix.Position = UDim2.new(0, 0, 1, -12)
    TopBarFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Parent = TopBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🍎 " .. CONFIG.SCRIPT_NAME
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Version
    local Version = Instance.new("TextLabel")
    Version.Size = UDim2.new(0, 60, 1, 0)
    Version.Position = UDim2.new(1, -70, 0, 0)
    Version.BackgroundTransparency = 1
    Version.Text = CONFIG.SCRIPT_VERSION
    Version.TextColor3 = Color3.fromRGB(150, 150, 150)
    Version.TextSize = 14
    Version.Font = Enum.Font.Gotham
    Version.TextXAlignment = Enum.TextXAlignment.Right
    Version.Parent = TopBar
    
    -- Description
    local Description = Instance.new("TextLabel")
    Description.Size = UDim2.new(1, -40, 0, 40)
    Description.Position = UDim2.new(0, 20, 0, 65)
    Description.BackgroundTransparency = 1
    Description.Text = "Enter your key to access premium features"
    Description.TextColor3 = Color3.fromRGB(180, 180, 180)
    Description.TextSize = 14
    Description.Font = Enum.Font.Gotham
    Description.TextWrapped = true
    Description.Parent = Frame
    
    -- Key Input Container
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -40, 0, 45)
    InputContainer.Position = UDim2.new(0, 20, 0, 115)
    InputContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = Frame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = InputContainer
    
    -- Key Input
    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, -20, 1, -10)
    KeyInput.Position = UDim2.new(0, 10, 0, 5)
    KeyInput.BackgroundTransparency = 1
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Enter your key..."
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    KeyInput.TextSize = 14
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = InputContainer
    
    -- Get Key Button
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(1, -40, 0, 45)
    GetKeyBtn.Position = UDim2.new(0, 20, 0, 175)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    GetKeyBtn.BorderSizePixel = 0
    GetKeyBtn.Text = "🔑 Get Key"
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 15
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.Parent = Frame
    
    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 8)
    GetKeyCorner.Parent = GetKeyBtn
    
    -- Validate Button
    local ValidateBtn = Instance.new("TextButton")
    ValidateBtn.Size = UDim2.new(1, -40, 0, 45)
    ValidateBtn.Position = UDim2.new(0, 20, 0, 235)
    ValidateBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
    ValidateBtn.BorderSizePixel = 0
    ValidateBtn.Text = "✓ Validate Key"
    ValidateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValidateBtn.TextSize = 15
    ValidateBtn.Font = Enum.Font.GothamBold
    ValidateBtn.AutoButtonColor = false
    ValidateBtn.Parent = Frame
    
    local ValidateCorner = Instance.new("UICorner")
    ValidateCorner.CornerRadius = UDim.new(0, 8)
    ValidateCorner.Parent = ValidateBtn
    
    -- Discord Button
    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Size = UDim2.new(1, -40, 0, 35)
    DiscordBtn.Position = UDim2.new(0, 20, 1, -45)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    DiscordBtn.BorderSizePixel = 0
    DiscordBtn.Text = "💬 Join Discord"
    DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DiscordBtn.TextSize = 14
    DiscordBtn.Font = Enum.Font.GothamBold
    DiscordBtn.AutoButtonColor = false
    DiscordBtn.Parent = Frame
    
    local DiscordCorner = Instance.new("UICorner")
    DiscordCorner.CornerRadius = UDim.new(0, 8)
    DiscordCorner.Parent = DiscordBtn
    
    -- Status Label
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -40, 0, 20)
    Status.Position = UDim2.new(0, 20, 0, 290)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 100, 100)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.Parent = Frame
    
    -- Dragging
    local dragging, dragInput, dragStart, startPos
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
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
            Frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Button Hover Effects
    local function AddHover(btn, hoverCol, normalCol)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverCol}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalCol}):Play()
        end)
    end
    
    AddHover(GetKeyBtn, Color3.fromRGB(70, 130, 255), Color3.fromRGB(60, 120, 255))
    AddHover(ValidateBtn, Color3.fromRGB(60, 210, 110), Color3.fromRGB(50, 200, 100))
    AddHover(DiscordBtn, Color3.fromRGB(98, 111, 252), Color3.fromRGB(88, 101, 242))
    
    -- Get Key Button
    GetKeyBtn.MouseButton1Click:Connect(function()
        Status.Text = "Link copied! Complete steps to get key."
        Status.TextColor3 = Color3.fromRGB(100, 180, 255)
        
        pcall(function()
            if setclipboard then
                setclipboard(CONFIG.FULL_LINK)
            end
        end)
        
        task.wait(3)
        if Status.Text:find("Link copied") then
            Status.Text = ""
        end
    end)
    
    -- Discord Button
    DiscordBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard(CONFIG.DISCORD_INVITE)
                Status.Text = "Discord invite copied!"
                Status.TextColor3 = Color3.fromRGB(88, 101, 242)
            end
        end)
        
        task.wait(3)
        if Status.Text:find("Discord") then
            Status.Text = ""
        end
    end)
    
    -- Validate Button
    ValidateBtn.MouseButton1Click:Connect(function()
        local key = KeyInput.Text
        
        Status.Text = "Validating..."
        Status.TextColor3 = Color3.fromRGB(100, 180, 255)
        ValidateBtn.Text = "Validating..."
        
        task.wait(0.5)
        
        local success, message = ValidateKey(key)
        
        if success then
            Status.Text = message
            Status.TextColor3 = Color3.fromRGB(100, 255, 100)
            ValidateBtn.Text = "✓ Success!"
            ValidateBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
            
            task.wait(1)
            
            -- Fade out animation
            TweenService:Create(Frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            
            for _, obj in ipairs(Frame:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    TweenService:Create(obj, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                end
                if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                    TweenService:Create(obj, TweenInfo.new(0.5), {BackgroundTransparency = 1, ImageTransparency = 1}):Play()
                end
            end
            
            task.wait(0.5)
            ScreenGui:Destroy()
            
            -- Call success callback
            if onValidated then
                onValidated()
            end
        else
            Status.Text = message
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            ValidateBtn.Text = "✓ Validate Key"
            
            -- Shake animation
            local origPos = ValidateBtn.Position
            for i = 1, 3 do
                ValidateBtn.Position = origPos + UDim2.new(0, 5, 0, 0)
                task.wait(0.05)
                ValidateBtn.Position = origPos - UDim2.new(0, 5, 0, 0)
                task.wait(0.05)
            end
            ValidateBtn.Position = origPos
        end
    end)
    
    -- Enter key to validate
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            ValidateBtn.MouseButton1Click:Fire()
        end
    end)
    
    return ScreenGui
end

-- ═══════════════════════════════════════════════════════════════
-- LOAD PREMIUM SCRIPT
-- ═══════════════════════════════════════════════════════════════
local function LoadPremiumScript()
    Notify("🍎 Loading", "Loading Blox Fruits Premium...", 2)
    
    local success, error = pcall(function()
        -- Load from URL
        loadstring(game:HttpGet(CONFIG.PREMIUM_SCRIPT_URL))()
    end)
    
    if success then
        Notify("✅ Success", "Premium script loaded!", 3)
        print("[🍎 Blox Fruits] Premium script loaded successfully")
    else
        Notify("❌ Error", "Failed to load premium script", 5)
        warn("[🍎 Blox Fruits] Load error:", error)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN EXECUTION
-- ═══════════════════════════════════════════════════════════════
Notify("🍎 Blox Fruits", "Loading key system...", 2)

-- Check for saved key first
local savedKey = LoadKey()
if savedKey then
    Notify("🔑 Saved Key", "Checking saved key...", 2)
    
    local success, message = ValidateKey(savedKey)
    
    if success then
        Notify("✅ Auto-Login", "Welcome back!", 2)
        task.wait(1)
        LoadPremiumScript()
        return
    else
        Notify("⚠️ Invalid", "Saved key expired. Please re-enter.", 3)
    end
end

-- Show key system UI
CreateKeySystemUI(function()
    -- This runs after successful validation
    Notify("✅ Validated", "Loading premium features...", 2)
    task.wait(1)
    LoadPremiumScript()
end)

print("[🍎 Blox Fruits] Key system initialized")
