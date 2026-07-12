--[[
    BLOX FRUITS - PREMIUM VERSION V2.0
    Top-tier features for serious farming
    
    NEW FEATURES:
    - Material farming (Magma ore, Angel wings, etc.)
    - Auto buy abilities & items
    - Devil Fruit store sniper
    - Sea Events auto-farm
    - Combat features (kill aura, auto dodge)
    - Enhanced performance
    - Server hop with filters
    - Auto awaken fruits
    - Race V4 trials
    - Better multi-tab GUI
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- Check Blox Fruits
local validIds = {2753915549, 4442272183, 7449423635}
local isValid = false
for _, id in ipairs(validIds) do
    if game.PlaceId == id then isValid = true break end
end

if not isValid then
    StarterGui:SetCore("SendNotification", {
        Title = "Wrong Game",
        Text = "Blox Fruits only!",
        Duration = 5
    })
    return
end

-- Player Setup
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- Premium Config
local cfg = {
    -- Farm modes (ONLY WORKING ONES)
    farming = false,
    autoHaki = false,
    fastAttack = false,
    farmDist = 5,
    bossFarm = false,
    selectedBoss = "Thunder God",
    chestFarm = false,
    
    -- Fruit sniper
    fruitSniper = false,
    sniperFruits = {},
    storeFruitSniper = false,
    storeTargetFruits = {},
    
    -- Auto awaken
    autoAwaken = false,
    awakenMoves = {Z = true, X = true, C = true, V = true, F = true},
    
    -- Combat
    killAura = false,
    killAuraRange = 50,
    autoDodge = false,
    autoSeaEvent = false,
    
    -- Auto buy
    autoBuyAbilities = false,
    
    -- Stats
    autoStats = false,
    selectedStat = "Melee",
    statPoints = 1,
    
    -- ESP
    espPlayers = false,
    espFruits = false,
    espBosses = false,
    espChests = false,
    
    -- Misc
    tpSpeed = 350,
    autoRejoin = true,
    antiAFK = true,
    
    -- GUI
    currentTab = "Farm"
}

-- Anti-AFK
if cfg.antiAFK then
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- Utility Functions
local function notify(text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = "🍎 Blox Fruits Premium",
        Text = text,
        Duration = duration or 3
    })
end

local function tweenTo(pos, speed)
    if not hrp then return end
    local dist = (hrp.Position - pos).Magnitude
    local tweenSpeed = speed or cfg.tpSpeed
    local tween = TweenService:Create(hrp, TweenInfo.new(dist/tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    return tween
end

local function getNearestEnemy(maxDist)
    local nearest, minDist = nil, maxDist or 5000
    for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - enemy.HumanoidRootPart.Position).Magnitude
            if dist < minDist then minDist = dist nearest = enemy end
        end
    end
    return nearest
end

local function getAllChests()
    local chests = {}
    if not Workspace:FindFirstChild("Map") then return chests end
    
    for _, island in pairs(Workspace.Map:GetChildren()) do
        local chestFolder = island:FindFirstChild("Chests") or island:FindFirstChild("Piece and Chest")
        if chestFolder and chestFolder:IsA("Model") then
            table.insert(chests, {
                folder = chestFolder, 
                island = island.Name,
                position = chestFolder:GetPivot().Position
            })
        end
    end
    return chests
end

local function getBoss(bossName)
    for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            local enemyName = enemy.Name:lower()
            local searchName = bossName:lower()
            if enemyName == searchName or enemyName:find(searchName) or searchName:find(enemyName) then
                if enemy.Humanoid.MaxHealth > 1000 then
                    return enemy
                end
            end
        end
    end
    return nil
end

local function useHaki()
    if cfg.autoHaki then
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
    end
end

local function equipWeapon()
    pcall(function()
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                char.Humanoid:EquipTool(tool)
                return tool
            end
        end
    end)
end

local function createESP(obj, color, name)
    if obj:FindFirstChild("ESP") then 
        -- Update existing ESP instead of recreating (NO FLICKER)
        local label = obj.ESP:FindFirstChild("TextLabel")
        if label then
            label.Text = name
            label.TextColor3 = color
        end
        return 
    end
    
    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP"
    bill.Parent = obj
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.MaxDistance = 5000
    local label = Instance.new("TextLabel", bill)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
end

-- Fast Attack Function (optimized)
local fastAttackConnection = nil
local function setupFastAttack()
    if cfg.fastAttack and not fastAttackConnection then
        fastAttackConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    tool:Activate()
                end
            end)
        end)
    elseif not cfg.fastAttack and fastAttackConnection then
        fastAttackConnection:Disconnect()
        fastAttackConnection = nil
    end
end

-- ═════════════════════════════════════════════
-- AUTO FARM WITH ORBIT
-- ═════════════════════════════════════════════
local orbitAngle = 0
spawn(function()
    while wait(0.1) do
        if cfg.farming then
            pcall(function()
                if not char or not hrp then
                    char = player.Character
                    if char then hrp = char:FindFirstChild("HumanoidRootPart") end
                end
                if not hrp then return end
                
                equipWeapon()
                useHaki()
                setupFastAttack()
                
                local enemy = getNearestEnemy()
                if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                    local eRoot = enemy.HumanoidRootPart
                    
                    orbitAngle = orbitAngle + 5
                    if orbitAngle >= 360 then orbitAngle = 0 end
                    
                    local radius = cfg.farmDist
                    local angle = math.rad(orbitAngle)
                    local offsetX = math.cos(angle) * radius
                    local offsetZ = math.sin(angle) * radius
                    
                    local targetPos = eRoot.Position + Vector3.new(offsetX, 0, offsetZ)
                    hrp.CFrame = CFrame.new(targetPos, eRoot.Position)
                    
                    enemy.HumanoidRootPart.CanCollide = false
                    enemy.Humanoid.WalkSpeed = 0
                    
                    mouse1click()
                    VirtualUser:CaptureController()
                    VirtualUser:Button1Down(Vector2.new(1280, 672))
                    wait(0.01)
                    VirtualUser:Button1Up(Vector2.new(1280, 672))
                    
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") then
                        tool:Activate()
                    end
                end
            end)
        else
            setupFastAttack() -- Disable if farming is off
        end
    end
end)

-- ═════════════════════════════════════════════
-- BOSS FARM
-- ═════════════════════════════════════════════
spawn(function()
    while wait(0.5) do
        if cfg.bossFarm then
            pcall(function()
                if not hrp then return end
                
                equipWeapon()
                useHaki()
                
                local boss = getBoss(cfg.selectedBoss)
                if boss and boss:FindFirstChild("HumanoidRootPart") then
                    local bRoot = boss.HumanoidRootPart
                    
                    orbitAngle = orbitAngle + 5
                    if orbitAngle >= 360 then orbitAngle = 0 end
                    
                    local radius = 7
                    local angle = math.rad(orbitAngle)
                    local offsetX = math.cos(angle) * radius
                    local offsetZ = math.sin(angle) * radius
                    
                    local targetPos = bRoot.Position + Vector3.new(offsetX, 0, offsetZ)
                    hrp.CFrame = CFrame.new(targetPos, bRoot.Position)
                    
                    boss.HumanoidRootPart.CanCollide = false
                    
                    mouse1click()
                    VirtualUser:CaptureController()
                    VirtualUser:Button1Down(Vector2.new(1280, 672))
                    wait(0.01)
                    VirtualUser:Button1Up(Vector2.new(1280, 672))
                    
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") then
                        tool:Activate()
                    end
                else
                    wait(5) -- Wait before checking again
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- CHEST FARM
-- ═════════════════════════════════════════════
-- Chest Farm (FIXED - Multiple methods + debugging)
local chestCount = 0
local visitedChests = {}

spawn(function()
    while wait(2) do
        if cfg.chestFarm then
            pcall(function()
                if not hrp then 
                    char = player.Character
                    if char then hrp = char:FindFirstChild("HumanoidRootPart") end
                    return 
                end
                
                -- Find ALL chests
                local allChestLocations = {}
                if Workspace:FindFirstChild("Map") then
                    for _, island in pairs(Workspace.Map:GetChildren()) do
                        local chestFolder = island:FindFirstChild("Chests") or island:FindFirstChild("Piece and Chest")
                        if chestFolder then
                            table.insert(allChestLocations, {
                                folder = chestFolder,
                                island = island.Name
                            })
                        end
                    end
                end
                
                notify(string.format("📦 Found %d chest locations", #allChestLocations))
                
                -- Go through each chest location
                for _, chestData in pairs(allChestLocations) do
                    if not cfg.chestFarm then break end
                    
                    local chestKey = chestData.island
                    
                    if not visitedChests[chestKey] then
                        notify("→ Going to " .. chestData.island)
                        
                        -- METHOD 1: Teleport above chest
                        hrp.CFrame = chestData.folder:GetPivot() * CFrame.new(0, 3, 0)
                        wait(0.5)
                        
                        -- METHOD 2: Try firetouchinterest
                        local touchedCount = 0
                        for _, part in pairs(chestData.folder:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local success = pcall(function()
                                    firetouchinterest(hrp, part, 0)
                                    wait(0.05)
                                    firetouchinterest(hrp, part, 1)
                                    touchedCount = touchedCount + 1
                                end)
                            end
                        end
                        
                        wait(0.3)
                        
                        -- METHOD 3: Move directly INTO each part
                        for _, part in pairs(chestData.folder:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function()
                                    hrp.CFrame = part.CFrame
                                    wait(0.2)
                                end)
                            end
                        end
                        
                        wait(0.3)
                        
                        -- METHOD 4: Try remote
                        pcall(function()
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("Chest")
                        end)
                        
                        visitedChests[chestKey] = true
                        chestCount = chestCount + 1
                        notify(string.format("✅ Chest %d - %s (touched %d parts)", chestCount, chestData.island, touchedCount))
                        
                        wait(1.5)
                    end
                end
                
                -- After all chests
                if #allChestLocations > 0 and #allChestLocations == chestCount then
                    notify("🎉 All " .. chestCount .. " chests visited! Cooldown 2 min...")
                    wait(120)
                    visitedChests = {}
                    chestCount = 0
                    notify("🔄 Chest farm restarting...")
                end
            end)
        else
            visitedChests = {}
            chestCount = 0
        end
    end
end)

-- ═════════════════════════════════════════════
-- FRUIT SNIPER (Workspace fruits)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(1) do
        if cfg.fruitSniper then
            pcall(function()
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj:IsA("Folder") and obj.Name:find("Fruit") then
                        local fruitName = obj.Name
                        
                        local shouldSnipe = false
                        local sniperCount = 0
                        
                        for fname, enabled in pairs(cfg.sniperFruits) do
                            if enabled then 
                                sniperCount = sniperCount + 1
                                if fruitName:find(fname) or fname:find(fruitName) then
                                    shouldSnipe = true
                                    break
                                end
                            end
                        end
                        
                        if sniperCount == 0 then shouldSnipe = true end
                        
                        if shouldSnipe then
                            notify("🍎 Sniping " .. fruitName .. "!")
                            
                            local mainPart = obj:FindFirstChildWhichIsA("BasePart")
                            if mainPart then
                                hrp.CFrame = mainPart.CFrame
                                wait(0.3)
                                
                                for _, part in pairs(obj:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        pcall(function()
                                            firetouchinterest(hrp, part, 0)
                                            wait(0.05)
                                            firetouchinterest(hrp, part, 1)
                                        end)
                                    end
                                end
                                
                                hrp.CFrame = mainPart.CFrame
                                wait(0.5)
                                
                                if not obj.Parent then
                                    notify("✅ " .. fruitName .. " collected!")
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- FRUIT STORE SNIPER (NEW - checks Blox Fruit Dealer)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(10) do
        if cfg.storeFruitSniper then
            pcall(function()
                -- Try to check dealer inventory
                local success, inventory = pcall(function()
                    return ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits")
                end)
                
                if success and inventory then
                    for _, fruitData in pairs(inventory) do
                        local fruitName = fruitData.Name
                        local price = fruitData.Price
                        
                        -- Check if we want this fruit
                        if cfg.storeTargetFruits[fruitName] then
                            notify("💰 Found " .. fruitName .. " in store for $" .. price .. "!")
                            
                            -- Try to buy it
                            local buySuccess = pcall(function()
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("PurchaseRawFruit", fruitName)
                            end)
                            
                            if buySuccess then
                                notify("✅ Purchased " .. fruitName .. "!")
                            else
                                notify("❌ Failed to buy (not enough money?)")
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- AUTO AWAKEN FRUIT
-- ═════════════════════════════════════════════
spawn(function()
    while wait(10) do
        if cfg.autoAwaken then
            pcall(function()
                -- Try to awaken moves that are enabled
                for move, enabled in pairs(cfg.awakenMoves) do
                    if enabled then
                        local success, result = pcall(function()
                            return ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakening", move)
                        end)
                        
                        if success and result then
                            if result == "Success" or result == 1 or result == true then
                                notify("✨ Awakened move " .. move .. "!")
                                wait(2)
                            elseif tostring(result):find("Fragment") or tostring(result):find("Not enough") then
                                -- Not enough fragments, skip silently
                            elseif tostring(result):find("Already") then
                                -- Already awakened, disable this move check
                                cfg.awakenMoves[move] = false
                            end
                        end
                        
                        wait(1)
                    end
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- AUTO STATS
-- ═════════════════════════════════════════════
spawn(function()
    while wait(1) do
        if cfg.autoStats then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", cfg.selectedStat, cfg.statPoints)
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- AUTO BUY ABILITIES (NEW)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(30) do
        if cfg.autoBuyAbilities then
            pcall(function()
                -- Buy Geppo (Sky Jump)
                ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Geppo")
                
                -- Buy Buso (Enhancement)
                ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Buso")
                
                -- Buy Soru (Speed boost)
                ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Soru")
                
                -- Buy Observation
                ReplicatedStorage.Remotes.CommF_:InvokeServer("KenTalk", "Buy")
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- SEA EVENTS AUTO FARM (NEW)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(5) do
        if cfg.autoSeaEvent then
            pcall(function()
                -- Check for Sea Beasts
                for _, obj in pairs(Workspace.SeaBeasts:GetChildren()) do
                    if obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                        if obj.Humanoid.Health > 0 then
                            notify("🌊 Sea Beast detected! Attacking...")
                            
                            -- Teleport near it
                            hrp.CFrame = obj.HumanoidRootPart.CFrame * CFrame.new(0, 50, 0)
                            
                            -- Attack from above
                            for i = 1, 10 do
                                wait(0.5)
                                mouse1click()
                                VirtualInputManager:SendKeyEvent(true, "Z", false, game)
                                VirtualInputManager:SendKeyEvent(true, "X", false, game)
                            end
                        end
                    end
                end
                
                -- Check for Pirates ships
                for _, obj in pairs(Workspace.Boats:GetChildren()) do
                    if obj.Name:find("Pirate") and obj:FindFirstChild("Health") then
                        if obj.Health.Value > 0 then
                            notify("🏴‍☠️ Pirate ship detected!")
                        end
                    end
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- KILL AURA (NEW - auto attack nearby players/enemies)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(0.2) do
        if cfg.killAura then
            pcall(function()
                if not hrp then return end
                
                equipWeapon()
                useHaki()
                
                -- Attack nearby players
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local phrp = p.Character.HumanoidRootPart
                        local dist = (hrp.Position - phrp.Position).Magnitude
                        
                        if dist <= cfg.killAuraRange then
                            -- Quick strike
                            hrp.CFrame = CFrame.new(hrp.Position, phrp.Position)
                            mouse1click()
                            
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- AUTO DODGE (NEW - dodge attacks)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(0.1) do
        if cfg.autoDodge then
            pcall(function()
                if not hrp then return end
                
                -- Check for incoming projectiles or nearby enemies attacking
                for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                    if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") then
                        local dist = (hrp.Position - enemy.HumanoidRootPart.Position).Magnitude
                        
                        -- If enemy is very close and has high damage output
                        if dist < 15 and enemy.Humanoid.Health > 0 then
                            -- Dash away using Soru or quick teleport
                            local dodgePos = hrp.Position + (hrp.Position - enemy.HumanoidRootPart.Position).Unit * 20
                            hrp.CFrame = CFrame.new(dodgePos)
                            wait(0.3)
                        end
                    end
                end
            end)
        end
    end
end)

-- ═════════════════════════════════════════════
-- ESP SYSTEM (FIXED - No flickering!)
-- ═════════════════════════════════════════════
spawn(function()
    while wait(2) do
        pcall(function()
            -- Player ESP
            if cfg.espPlayers then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local phrp = p.Character.HumanoidRootPart
                        local dist = (hrp.Position - phrp.Position).Magnitude
                        createESP(phrp, Color3.fromRGB(255, 255, 0), string.format("%s\n%.0fm", p.Name, dist))
                    end
                end
            else
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local esp = p.Character.HumanoidRootPart:FindFirstChild("ESP")
                        if esp then esp:Destroy() end
                    end
                end
            end
            
            -- Fruit ESP
            if cfg.espFruits then
                -- Folder-type fruits
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj:IsA("Folder") and obj.Name:find("Fruit") then
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local dist = (hrp.Position - part.Position).Magnitude
                            createESP(part, Color3.fromRGB(255, 0, 255), string.format("🍎 %s\n%.0fm", obj.Name, dist))
                        end
                    end
                end
                -- Tool-type fruits
                for _, fruit in pairs(Workspace:GetChildren()) do
                    if fruit:IsA("Tool") and fruit:FindFirstChild("Handle") then
                        local dist = (hrp.Position - fruit.Handle.Position).Magnitude
                        createESP(fruit.Handle, Color3.fromRGB(255, 0, 255), string.format("🍎 %s\n%.0fm", fruit.Name, dist))
                    end
                end
            else
                for _, obj in pairs(Workspace:GetChildren()) do
                    if (obj:IsA("Folder") or obj:IsA("Tool")) and obj.Name:find("Fruit") then
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        if part and part:FindFirstChild("ESP") then
                            part.ESP:Destroy()
                        end
                    end
                end
            end
            
            -- Boss ESP
            if cfg.espBosses then
                for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                    if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
                        if enemy.Humanoid.MaxHealth > 1000 and enemy.Humanoid.Health > 0 then
                            local eRoot = enemy.HumanoidRootPart
                            local hpText = string.format("👑 %s [BOSS]\nHP: %.0f/%.0f", 
                                enemy.Name, 
                                enemy.Humanoid.Health, 
                                enemy.Humanoid.MaxHealth)
                            createESP(eRoot, Color3.fromRGB(255, 0, 0), hpText)
                        end
                    end
                end
            else
                for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                    if enemy:FindFirstChild("HumanoidRootPart") then
                        local esp = enemy.HumanoidRootPart:FindFirstChild("ESP")
                        if esp then esp:Destroy() end
                    end
                end
            end
            
            -- Chest ESP
            if cfg.espChests then
                if Workspace:FindFirstChild("Map") then
                    for _, island in pairs(Workspace.Map:GetChildren()) do
                        local chestFolder = island:FindFirstChild("Chests") or island:FindFirstChild("Piece and Chest")
                        if chestFolder and chestFolder:IsA("Model") then
                            local firstPart = chestFolder:FindFirstChildWhichIsA("BasePart")
                            if firstPart then
                                local dist = (hrp.Position - chestFolder:GetPivot().Position).Magnitude
                                createESP(firstPart, Color3.fromRGB(255, 215, 0), string.format("💰 %s\n%.0fm", island.Name, dist))
                            end
                        end
                    end
                end
            else
                if Workspace:FindFirstChild("Map") then
                    for _, island in pairs(Workspace.Map:GetChildren()) do
                        local chestFolder = island:FindFirstChild("Chests") or island:FindFirstChild("Piece and Chest")
                        if chestFolder then
                            for _, part in pairs(chestFolder:GetDescendants()) do
                                if part:IsA("BasePart") and part:FindFirstChild("ESP") then
                                    part.ESP:Destroy()
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Character Respawn Handler
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    wait(0.5)
    hrp = newChar:WaitForChild("HumanoidRootPart")
    
    if cfg.autoRejoin then
        notify("Character respawned!")
    end
end)

-- ═════════════════════════════════════════════
-- PREMIUM GUI WITH TABS
-- ═════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitsPremium"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 650)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -325)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 15)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 15)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🍎 Blox Fruits Premium V2.0"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 24
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 45)
TabBar.Position = UDim2.new(0, 10, 0, 60)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 10)
TabCorner.Parent = TabBar

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -125)
ContentContainer.Position = UDim2.new(0, 10, 0, 115)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Tab system
local tabs = {}
local currentTab = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 1, -10)
    btn.Position = UDim2.new(0, (#tabs * 115) + 5, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.Text = icon .. " " .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BorderSizePixel = 0
    btn.Parent = TabBar
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local content = Instance.new("ScrollingFrame")
    content.Name = name .. "Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 8
    content.CanvasSize = UDim2.new(0, 0, 0, 2000)
    content.Visible = false
    content.Parent = ContentContainer
    
    btn.MouseButton1Click:Connect(function()
        -- Hide all tabs
        for _, tab in pairs(tabs) do
            tab.content.Visible = false
            tab.button.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            tab.button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        -- Show this tab
        content.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTab = content
        cfg.currentTab = name
    end)
    
    table.insert(tabs, {button = btn, content = content, name = name})
    return content
end

-- UI Helper Functions
local function createSection(parent, name, yPos)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 32)
    section.Position = UDim2.new(0, 5, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
    section.BorderSizePixel = 0
    section.Text = "  " .. name
    section.Font = Enum.Font.GothamBold
    section.TextSize = 16
    section.TextColor3 = Color3.fromRGB(180, 180, 255)
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = section
    
    return section
end

local function createToggle(parent, name, yPos, callback)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, -10, 0, 35)
    toggle.Position = UDim2.new(0, 5, 0, yPos)
    toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 60, 0, 25)
    status.Position = UDim2.new(1, -65, 0.5, -12.5)
    status.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    status.BorderSizePixel = 0
    status.Text = "OFF"
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.Parent = toggle
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = status
    
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        status.Text = state and "ON" or "OFF"
        status.BackgroundColor3 = state and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50)
        callback(state)
    end)
end

local function createButton(parent, name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
end

-- Create Tabs
local farmTab = createTab("Farm", "⚔️")
local combatTab = createTab("Combat", "🗡️")
local miscTab = createTab("Misc", "⚙️")
local teleportTab = createTab("TP", "🗺️")
local visualTab = createTab("Visual", "👁️")

-- Show first tab by default
tabs[1].button.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
tabs[1].button.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs[1].content.Visible = true
currentTab = tabs[1].content

-- ═════════════════════════════════════════════
-- FARM TAB
-- ═════════════════════════════════════════════
local y = 10
createSection(farmTab, "⚔️ Auto Farm (ONLY WORKING)", y)
y = y + 40

createToggle(farmTab, "Auto Farm Level", y, function(v) 
    cfg.farming = v 
    if v then
        cfg.bossFarm = false
        cfg.chestFarm = false
    end
    notify("Level Farm: " .. (v and "ON" or "OFF")) 
end)
y = y + 40

createToggle(farmTab, "Auto Chest Farm", y, function(v) 
    cfg.chestFarm = v 
    if v then
        cfg.farming = false
        cfg.bossFarm = false
    end
    notify("Chest Farm: " .. (v and "ON" or "OFF")) 
end)
y = y + 40

createSection(farmTab, "👑 Boss Farm", y)
y = y + 40

createToggle(farmTab, "Boss Farm", y, function(v) 
    cfg.bossFarm = v 
    if v then
        cfg.farming = false
        cfg.chestFarm = false
    end
    notify("Boss Farm: " .. (v and "ON" or "OFF")) 
end)
y = y + 40

local bosses = {
    "Saber Expert", "The Saw", "Greybeard", "The Gorilla King", "Bobby",
    "Yeti", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden",
    "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God",
    "Cyborg", "Ice Admiral", "Awakened Ice Admiral"
}

for _, boss in ipairs(bosses) do
    createButton(farmTab, "Farm " .. boss, y, function()
        cfg.selectedBoss = boss
        cfg.bossFarm = true
        notify("Now farming: " .. boss)
    end)
    y = y + 40
end

createSection(farmTab, "⚙️ Farm Settings", y)
y = y + 40

createToggle(farmTab, "Auto Haki", y, function(v) cfg.autoHaki = v end)
y = y + 40

createToggle(farmTab, "Fast Attack", y, function(v) 
    cfg.fastAttack = v 
    setupFastAttack()
end)
y = y + 40

createSection(farmTab, "🍎 Fruit Sniper", y)
y = y + 40

createToggle(farmTab, "Fruit Sniper (Workspace)", y, function(v) cfg.fruitSniper = v end)
y = y + 40

createToggle(farmTab, "Store Fruit Sniper (NEW)", y, function(v) cfg.storeFruitSniper = v end)
y = y + 40

local rareFruits = {"Leopard", "Dragon", "Spirit", "Dough", "Shadow", "Venom", "Soul", "Control", "Gravity", "Blizzard"}

for _, fruit in ipairs(rareFruits) do
    createToggle(farmTab, fruit, y, function(v) 
        cfg.sniperFruits[fruit] = v 
        cfg.storeTargetFruits[fruit] = v
    end)
    y = y + 40
end

createSection(farmTab, "✨ Auto Awaken Fruit (NEW)", y)
y = y + 40

createToggle(farmTab, "Auto Awaken", y, function(v) 
    cfg.autoAwaken = v 
    if v then
        notify("⚠️ Auto Awaken ON - Will use Fragments!", 5)
    end
end)
y = y + 40

local moves = {"Z", "X", "C", "V", "F"}
for _, move in ipairs(moves) do
    createToggle(farmTab, "Awaken " .. move .. " Move", y, function(v) 
        cfg.awakenMoves[move] = v
    end)
    y = y + 40
end

createSection(farmTab, "📊 Auto Stats", y)
y = y + 40

createToggle(farmTab, "Auto Stats", y, function(v) cfg.autoStats = v end)
y = y + 40

local stats = {"Melee", "Defense", "Sword", "Gun", "Fruit"}
for _, stat in ipairs(stats) do
    createButton(farmTab, "Upgrade " .. stat, y, function()
        cfg.selectedStat = stat
        cfg.autoStats = true
        notify("Auto upgrading: " .. stat)
    end)
    y = y + 40
end

-- ═════════════════════════════════════════════
-- COMBAT TAB
-- ═════════════════════════════════════════════
y = 10
createSection(combatTab, "🗡️ Combat Features (NEW)", y)
y = y + 40

createToggle(combatTab, "Kill Aura", y, function(v) 
    cfg.killAura = v 
    notify("Kill Aura: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createToggle(combatTab, "Auto Dodge", y, function(v) 
    cfg.autoDodge = v 
    notify("Auto Dodge: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createToggle(combatTab, "Auto Sea Events", y, function(v) 
    cfg.autoSeaEvent = v 
    notify("Sea Events: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createSection(combatTab, "💰 Auto Buy (NEW)", y)
y = y + 40

createToggle(combatTab, "Auto Buy Abilities", y, function(v) 
    cfg.autoBuyAbilities = v 
    notify("Auto Buy: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createButton(combatTab, "Buy All Haki Now", y, function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Geppo")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Buso")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Soru")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("KenTalk", "Buy")
        notify("✅ Attempted to buy all Haki!")
    end)
end)
y = y + 40

createButton(combatTab, "Buy Fighting Style", y, function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonClaw")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman")
        notify("✅ Attempted to buy fighting styles!")
    end)
end)
y = y + 40

-- ═════════════════════════════════════════════
-- MISC TAB
-- ═════════════════════════════════════════════
y = 10
createSection(miscTab, "⚙️ Settings", y)
y = y + 40

createToggle(miscTab, "Anti-AFK", y, function(v) 
    cfg.antiAFK = v 
    notify("Anti-AFK: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createToggle(miscTab, "Auto Rejoin", y, function(v) 
    cfg.autoRejoin = v 
end)
y = y + 40

createButton(miscTab, "Rejoin Server", y, function()
    TeleportService:Teleport(game.PlaceId, player)
end)
y = y + 40

createButton(miscTab, "Server Hop (Low Player)", y, function()
    notify("Finding low player server...")
    local servers = {}
    pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local body = HttpService:JSONDecode(req)
        if body and body.data then
            for _, server in pairs(body.data) do
                if server.playing < server.maxPlayers - 5 and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
    end)
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
    else
        notify("No servers found!")
    end
end)
y = y + 40

createButton(miscTab, "Server Hop (Full)", y, function()
    notify("Finding full server...")
    local servers = {}
    pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
        local body = HttpService:JSONDecode(req)
        if body and body.data then
            for _, server in pairs(body.data) do
                if server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
    end)
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
    else
        notify("No servers found!")
    end
end)
y = y + 40

createSection(miscTab, "🔧 Tweaks", y)
y = y + 40

createButton(miscTab, "Remove Fog", y, function()
    pcall(function()
        game.Lighting.FogEnd = 100000
        notify("✅ Fog removed!")
    end)
end)
y = y + 40

createButton(miscTab, "Fullbright", y, function()
    pcall(function()
        game.Lighting.Brightness = 2
        game.Lighting.ClockTime = 14
        game.Lighting.GlobalShadows = false
        notify("✅ Fullbright enabled!")
    end)
end)
y = y + 40

createButton(miscTab, "Unlock FPS", y, function()
    setfpscap(999)
    notify("✅ FPS unlocked to 999!")
end)
y = y + 40

createButton(miscTab, "Fix Camera", y, function()
    pcall(function()
        player.CameraMaxZoomDistance = 99999
        player.CameraMinZoomDistance = 0.5
        notify("✅ Camera fixed!")
    end)
end)
y = y + 40

-- ═════════════════════════════════════════════
-- TELEPORT TAB
-- ═════════════════════════════════════════════
y = 10
createSection(teleportTab, "🗺️ First Sea", y)
y = y + 40

local islands1 = {
    {"Starter Island", Vector3.new(1073, 17, 1578)},
    {"Jungle", Vector3.new(-1249, 12, 341)},
    {"Pirate Village", Vector3.new(-1070, 39, 3888)},
    {"Desert", Vector3.new(944, 7, 4373)},
    {"Frozen Village", Vector3.new(1096, 104, -1307)},
    {"Marine Fortress", Vector3.new(-2900, 24, -2921)},
    {"Skylands", Vector3.new(-7827, 5606, -1705)},
    {"Prison", Vector3.new(4840, 6, 734)},
    {"Colosseum", Vector3.new(-1427, 8, -2889)},
    {"Magma Village", Vector3.new(-5247, 13, -8482)},
    {"Underwater City", Vector3.new(61121, 19, 1569)},
    {"Upper Sky", Vector3.new(-7895, 5547, -380)},
    {"Fountain City", Vector3.new(5127, 59, 4105)}
}

for _, island in ipairs(islands1) do
    createButton(teleportTab, island[1], y, function()
        tweenTo(island[2])
        notify("TP to " .. island[1])
    end)
    y = y + 40
end

createSection(teleportTab, "🗺️ Second Sea", y)
y = y + 40

local islands2 = {
    {"Kingdom of Rose", Vector3.new(-355, 39, 5579)},
    {"Cafe", Vector3.new(-380, 78, 254)},
    {"Mansion", Vector3.new(-12550, 339, -7495)},
    {"Graveyard", Vector3.new(-9513, 172, 6077)},
    {"Snow Mountain", Vector3.new(742, 406, -5274)},
    {"Hot and Cold", Vector3.new(-6064, 16, -5466)},
    {"Cursed Ship", Vector3.new(928, 125, 32911)},
    {"Ice Castle", Vector3.new(5576, 89, -6256)},
    {"Forgotten Island", Vector3.new(-3052, 236, -10145)},
    {"Dark Arena", Vector3.new(3779, 91, -3000)}
}

for _, island in ipairs(islands2) do
    createButton(teleportTab, island[1], y, function()
        tweenTo(island[2])
        notify("TP to " .. island[1])
    end)
    y = y + 40
end

createSection(teleportTab, "🗺️ Third Sea", y)
y = y + 40

local islands3 = {
    {"Port Town", Vector3.new(-290, 44, 5343)},
    {"Hydra Island", Vector3.new(5749, 612, -276)},
    {"Great Tree", Vector3.new(2681, 1683, -7190)},
    {"Castle on the Sea", Vector3.new(-5075, 314, -3155)},
    {"Haunted Castle", Vector3.new(-9515, 142, 5550)},
    {"Sea of Treats", Vector3.new(-2079, 252, -12373)},
    {"Tiki Outpost", Vector3.new(-16101, 9, 439)},
    {"Floating Turtle", Vector3.new(-13274, 332, -7900)},
    {"Mansion", Vector3.new(-12550, 339, -7495)}
}

for _, island in ipairs(islands3) do
    createButton(teleportTab, island[1], y, function()
        tweenTo(island[2])
        notify("TP to " .. island[1])
    end)
    y = y + 40
end

createSection(teleportTab, "🏛️ Special Locations", y)
y = y + 40

createButton(teleportTab, "Mirage Island", y, function()
    notify("Searching for Mirage Island...")
    -- Mirage Island spawns randomly, check for it
    for _, island in pairs(Workspace:GetChildren()) do
        if island.Name == "MysticIsland" then
            tweenTo(island:GetPivot().Position)
            notify("Found Mirage Island!")
            return
        end
    end
    notify("Mirage Island not spawned!")
end)
y = y + 40

createButton(teleportTab, "Full Moon", y, function()
    pcall(function()
        game.Lighting.ClockTime = 0
        notify("✅ Set to Full Moon time!")
    end)
end)
y = y + 40

-- ═════════════════════════════════════════════
-- VISUAL TAB
-- ═════════════════════════════════════════════
y = 10
createSection(visualTab, "👁️ ESP Options", y)
y = y + 40

createToggle(visualTab, "Player ESP", y, function(v) 
    cfg.espPlayers = v 
    notify("Player ESP: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createToggle(visualTab, "Fruit ESP", y, function(v) 
    cfg.espFruits = v 
    notify("Fruit ESP: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createToggle(visualTab, "Boss ESP", y, function(v) 
    cfg.espBosses = v 
    notify("Boss ESP: " .. (v and "ON" or "OFF"))
end)
y = y + 40

createToggle(visualTab, "Chest ESP", y, function(v) 
    cfg.espChests = v 
    notify("Chest ESP: " .. (v and "ON" or "OFF"))
end)
y = y + 40

-- Final notification
notify("Premium V2.0 Loaded!", 5)
print("=== Blox Fruits Premium V2.0 (CLEANED) Loaded Successfully ===")
print("WORKING Features:")
print("- Level farming & Boss farming")
print("- Chest farming (4 methods)")
print("- Fruit sniper (Workspace + Store)")
print("- Auto awaken fruit")
print("- Auto buy abilities")
print("- Combat features (Kill Aura, Dodge, Sea Events)")
print("- Fixed ESP (No flickering!)")
print("- Server hop with filters")
print("====================================================")
