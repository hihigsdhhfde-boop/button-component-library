-- GameClient.lua
-- Main client-side logic for multiplayer Roblox game
-- Place this in StarterPlayer > StarterPlayerScripts or StarterCharacterScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes to load
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Game State
local gameState = {
    health = 100,
    maxHealth = 100,
    inventory = "None",
    zombies = 0,
    gold = 0,
    activePowerUps = {},
    armor = "None",
    statusEffects = {},
    comboCounter = 0
}

-- Create GUI
local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(107, 92, 231)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.Text = "🎮 Interactive Button Game - Roblox"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = screenGui
    
    -- Stats Frame
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, 0, 0, 100)
    statsFrame.Position = UDim2.new(0, 0, 0, 50)
    statsFrame.BackgroundColor3 = Color3.fromRGB(245, 246, 250)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = screenGui
    
    -- Health Stat
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(0.25, 0, 1, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
    healthLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    healthLabel.TextSize = 18
    healthLabel.Text = "❤️ Health:\n100"
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.Parent = statsFrame
    gameState.healthLabel = healthLabel
    
    -- Inventory Stat
    local inventoryLabel = Instance.new("TextLabel")
    inventoryLabel.Name = "InventoryLabel"
    inventoryLabel.Size = UDim2.new(0.25, 0, 1, 0)
    inventoryLabel.Position = UDim2.new(0.25, 0, 0, 0)
    inventoryLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 255)
    inventoryLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    inventoryLabel.TextSize = 18
    inventoryLabel.Text = "🎒 Inventory:\nNone"
    inventoryLabel.Font = Enum.Font.Gotham
    inventoryLabel.Parent = statsFrame
    gameState.inventoryLabel = inventoryLabel
    
    -- Zombies Stat
    local zombiesLabel = Instance.new("TextLabel")
    zombiesLabel.Name = "ZombiesLabel"
    zombiesLabel.Size = UDim2.new(0.25, 0, 1, 0)
    zombiesLabel.Position = UDim2.new(0.5, 0, 0, 0)
    zombiesLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    zombiesLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    zombiesLabel.TextSize = 18
    zombiesLabel.Text = "🧟 Zombies:\n0"
    zombiesLabel.Font = Enum.Font.Gotham
    zombiesLabel.Parent = statsFrame
    gameState.zombiesLabel = zombiesLabel
    
    -- Gold Stat
    local goldLabel = Instance.new("TextLabel")
    goldLabel.Name = "GoldLabel"
    goldLabel.Size = UDim2.new(0.25, 0, 1, 0)
    goldLabel.Position = UDim2.new(0.75, 0, 0, 0)
    goldLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
    goldLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    goldLabel.TextSize = 18
    goldLabel.Text = "💰 Gold:\n0"
    goldLabel.Font = Enum.Font.Gotham
    goldLabel.Parent = statsFrame
    gameState.goldLabel = goldLabel
    
    -- Message Box
    local messageBox = Instance.new("TextLabel")
    messageBox.Name = "MessageBox"
    messageBox.Size = UDim2.new(1, 0, 0, 50)
    messageBox.Position = UDim2.new(0, 0, 0, 150)
    messageBox.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    messageBox.TextColor3 = Color3.fromRGB(0, 0, 0)
    messageBox.TextSize = 16
    messageBox.Text = "Welcome to the game!"
    messageBox.Font = Enum.Font.Gotham
    messageBox.BorderSizePixel = 1
    messageBox.Parent = screenGui
    gameState.messageBox = messageBox
    
    -- Buttons Frame (Scrollable)
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, 0, 1, -200)
    buttonsFrame.Position = UDim2.new(0, 0, 0, 200)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(102, 126, 234)
    buttonsFrame.BorderSizePixel = 0
    buttonsFrame.Parent = screenGui
    
    -- Buttons Grid (UIGridLayout)
    local uiGridLayout = Instance.new("UIGridLayout")
    uiGridLayout.CellSize = UDim2.new(0.15, 0, 0, 50)
    uiGridLayout.CellPadding = UDim2.new(0.01, 0, 0.01, 0)
    uiGridLayout.Parent = buttonsFrame
    
    gameState.buttonsFrame = buttonsFrame
    gameState.screenGui = screenGui
    
    return screenGui, buttonsFrame
end

-- Create Button
local function createButton(name, color, callback, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Text = name
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    -- Button animation
    button.MouseButton1Click:Connect(function()
        button.BackgroundColor3 = Color3.new(button.BackgroundColor3.R * 0.8, button.BackgroundColor3.G * 0.8, button.BackgroundColor3.B * 0.8)
        task.wait(0.1)
        button.BackgroundColor3 = color
        
        if callback then
            callback()
        end
    end)
    
    return button
end

-- Update Display
local function updateDisplay()
    if gameState.healthLabel then
        gameState.healthLabel.Text = "❤️ Health:\n" .. gameState.health .. "/" .. gameState.maxHealth
    end
    if gameState.inventoryLabel then
        gameState.inventoryLabel.Text = "🎒 Inventory:\n" .. gameState.inventory
    end
    if gameState.zombiesLabel then
        gameState.zombiesLabel.Text = "🧟 Zombies:\n" .. gameState.zombies
    end
    if gameState.goldLabel then
        gameState.goldLabel.Text = "💰 Gold:\n" .. gameState.gold
    end
end

-- Show Message
local function showMessage(text, messageType)
    if gameState.messageBox then
        gameState.messageBox.Text = text
        
        -- Color based on type
        if messageType == "damage" then
            gameState.messageBox.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
        elseif messageType == "heal" then
            gameState.messageBox.BackgroundColor3 = Color3.fromRGB(200, 255, 200)
        elseif messageType == "gold" then
            gameState.messageBox.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
        elseif messageType == "treasure" then
            gameState.messageBox.BackgroundColor3 = Color3.fromRGB(200, 200, 255)
        else
            gameState.messageBox.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        end
    end
end

-- Setup Buttons
local function setupButtons()
    local buttonsFrame = gameState.buttonsFrame
    local remotes = remotes
    
    -- Weapon Buttons
    createButton("⚔️ Wooden Sword", Color3.fromRGB(162, 155, 254), function()
        remotes:FindFirstChild("GiveWeapon"):FireServer("Wooden Sword")
    end, buttonsFrame)
    
    createButton("⚔️ Iron Sword", Color3.fromRGB(162, 155, 254), function()
        remotes:FindFirstChild("GiveWeapon"):FireServer("Iron Sword")
    end, buttonsFrame)
    
    createButton("💎 Diamond Sword", Color3.fromRGB(162, 155, 254), function()
        remotes:FindFirstChild("GiveWeapon"):FireServer("Diamond Sword")
    end, buttonsFrame)
    
    -- Enemy Buttons
    createButton("🧟 Zombie", Color3.fromRGB(250, 177, 160), function()
        remotes:FindFirstChild("SpawnEnemy"):FireServer("Zombie")
    end, buttonsFrame)
    
    createButton("💀 Skeleton", Color3.fromRGB(250, 177, 160), function()
        remotes:FindFirstChild("SpawnEnemy"):FireServer("Skeleton")
    end, buttonsFrame)
    
    createButton("💚 Creeper", Color3.fromRGB(250, 177, 160), function()
        remotes:FindFirstChild("SpawnEnemy"):FireServer("Creeper")
    end, buttonsFrame)
    
    -- Damage Buttons
    createButton("💥 5 Damage", Color3.fromRGB(255, 118, 117), function()
        remotes:FindFirstChild("TakeDamage"):FireServer(5)
    end, buttonsFrame)
    
    createButton("💥 10 Damage", Color3.fromRGB(255, 118, 117), function()
        remotes:FindFirstChild("TakeDamage"):FireServer(10)
    end, buttonsFrame)
    
    createButton("💥 20 Damage", Color3.fromRGB(255, 118, 117), function()
        remotes:FindFirstChild("TakeDamage"):FireServer(20)
    end, buttonsFrame)
    
    -- Healing Buttons
    createButton("🍎 Heal 10", Color3.fromRGB(85, 239, 196), function()
        remotes:FindFirstChild("Heal"):FireServer(10)
    end, buttonsFrame)
    
    createButton("🍎 Heal 25", Color3.fromRGB(85, 239, 196), function()
        remotes:FindFirstChild("Heal"):FireServer(25)
    end, buttonsFrame)
    
    createButton("🍎 Heal 50", Color3.fromRGB(85, 239, 196), function()
        remotes:FindFirstChild("Heal"):FireServer(50)
    end, buttonsFrame)
    
    -- Gold Buttons
    createButton("💰 10 Gold", Color3.fromRGB(255, 217, 155), function()
        remotes:FindFirstChild("AddGold"):FireServer(10)
    end, buttonsFrame)
    
    createButton("💰 50 Gold", Color3.fromRGB(255, 217, 155), function()
        remotes:FindFirstChild("AddGold"):FireServer(50)
    end, buttonsFrame)
    
    createButton("💰 100 Gold", Color3.fromRGB(255, 217, 155), function()
        remotes:FindFirstChild("AddGold"):FireServer(100)
    end, buttonsFrame)
    
    -- Treasure Buttons
    createButton("💎 Diamond", Color3.fromRGB(255, 234, 167), function()
        remotes:FindFirstChild("GiveItem"):FireServer("Diamond")
    end, buttonsFrame)
    
    createButton("🏆 Gold Ingot", Color3.fromRGB(255, 234, 167), function()
        remotes:FindFirstChild("GiveItem"):FireServer("Gold Ingot")
    end, buttonsFrame)
    
    createButton("⚙️ Iron Ingot", Color3.fromRGB(255, 234, 167), function()
        remotes:FindFirstChild("GiveItem"):FireServer("Iron Ingot")
    end, buttonsFrame)
    
    -- Power-up Buttons
    createButton("🛡️ Invincibility", Color3.fromRGB(162, 155, 254), function()
        remotes:FindFirstChild("ActivatePowerUp"):FireServer("Invincibility")
    end, buttonsFrame)
    
    createButton("⚡ Speed Boost", Color3.fromRGB(162, 155, 254), function()
        remotes:FindFirstChild("ActivatePowerUp"):FireServer("Speed Boost")
    end, buttonsFrame)
    
    createButton("🔥 Double Damage", Color3.fromRGB(162, 155, 254), function()
        remotes:FindFirstChild("ActivatePowerUp"):FireServer("Double Damage")
    end, buttonsFrame)
    
    -- Armor Buttons
    createButton("🛡️ Leather", Color3.fromRGB(129, 236, 236), function()
        remotes:FindFirstChild("EquipArmor"):FireServer("Leather Armor")
    end, buttonsFrame)
    
    createButton("⛓️ Chain", Color3.fromRGB(129, 236, 236), function()
        remotes:FindFirstChild("EquipArmor"):FireServer("Chain Armor")
    end, buttonsFrame)
    
    createButton("💎 Diamond", Color3.fromRGB(129, 236, 236), function()
        remotes:FindFirstChild("EquipArmor"):FireServer("Diamond Armor")
    end, buttonsFrame)
    
    -- Spell Buttons
    createButton("🔥 Fireball", Color3.fromRGB(255, 190, 118), function()
        remotes:FindFirstChild("CastSpell"):FireServer("Fireball")
    end, buttonsFrame)
    
    createButton("❄️ Frost Bolt", Color3.fromRGB(255, 190, 118), function()
        remotes:FindFirstChild("CastSpell"):FireServer("FrostBolt")
    end, buttonsFrame)
    
    createButton("⚡ Lightning", Color3.fromRGB(255, 190, 118), function()
        remotes:FindFirstChild("CastSpell"):FireServer("Lightning")
    end, buttonsFrame)
    
    -- Battle Buttons
    createButton("⚔️ Easy Battle", Color3.fromRGB(253, 121, 168), function()
        remotes:FindFirstChild("StartBattle"):FireServer("Easy")
    end, buttonsFrame)
    
    createButton("⚔️ Medium Battle", Color3.fromRGB(253, 121, 168), function()
        remotes:FindFirstChild("StartBattle"):FireServer("Medium")
    end, buttonsFrame)
    
    createButton("⚔️ Hard Battle", Color3.fromRGB(253, 121, 168), function()
        remotes:FindFirstChild("StartBattle"):FireServer("Hard")
    end, buttonsFrame)
    
    -- Control Buttons
    createButton("🔄 Reset", Color3.fromRGB(116, 185, 255), function()
        remotes:FindFirstChild("ResetGame"):FireServer()
    end, buttonsFrame)
    
    createButton("📊 Stats", Color3.fromRGB(85, 239, 196), function()
        showMessage("Health: " .. gameState.health .. "/" .. gameState.maxHealth .. " | Gold: " .. gameState.gold .. " | Zombies: " .. gameState.zombies, "info")
    end, buttonsFrame)
end

-- Connect Server Events
local function connectServerEvents()
    local updateStatsEvent = remotes:FindFirstChild("UpdateStats")
    if updateStatsEvent then
        updateStatsEvent.OnClientEvent:Connect(function(playerName, data)
            if playerName == player.Name then
                gameState.health = data.health
                gameState.maxHealth = data.maxHealth
                gameState.inventory = data.inventory
                gameState.zombies = data.zombies
                gameState.gold = data.gold
                gameState.activePowerUps = data.activePowerUps
                gameState.armor = data.armor
                gameState.statusEffects = data.statusEffects
                gameState.comboCounter = data.comboCounter
                
                updateDisplay()
            end
        end)
    end
    
    local messageEvent = remotes:FindFirstChild("ShowMessage")
    if messageEvent then
        messageEvent.OnClientEvent:Connect(function(text, messageType)
            showMessage(text, messageType)
        end)
    end
end

-- Initialize
local screenGui, buttonsFrame = createGui()
setupButtons()
connectServerEvents()
updateDisplay()

print("GameClient loaded for player: " .. player.Name)