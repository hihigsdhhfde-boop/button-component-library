-- GameManager.lua
-- Main server-side game logic for multiplayer Roblox game
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Create Remotes Folder if it doesn't exist
if not ReplicatedStorage:FindFirstChild("Remotes") then
    local remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
    
    -- Create all RemoteEvents
    local remoteNames = {
        "SpawnEnemy",
        "TakeDamage",
        "Heal",
        "GiveWeapon",
        "GiveItem",
        "AddGold",
        "ActivatePowerUp",
        "CastSpell",
        "EquipArmor",
        "UpdateStats",
        "ShowMessage",
        "StartBattle",
        "ApplyEffect",
        "ResetGame"
    }
    
    for _, name in ipairs(remoteNames) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
end

-- Player Data Storage
local playerData = {}

-- Game Configuration
local CONFIG = {
    MAX_HEALTH = 100,
    HEALTH_REGEN_RATE = 1,
    HEALTH_REGEN_DELAY = 5,
    ENEMY_SPAWN_COOLDOWN = 1,
    MAX_ENEMIES_PER_PLAYER = 50,
    DAMAGE_REDUCTION_ARMOR = 0.5,
    POWERUP_DURATION = 10,
    STATUS_EFFECT_DURATION = 8
}

-- Battle Configurations
local BATTLES = {
    Easy = { enemies = 3, damage = 5, gold = 50 },
    Medium = { enemies = 5, damage = 15, gold = 150 },
    Hard = { enemies = 10, damage = 30, gold = 300 },
    Nightmare = { enemies = 20, damage = 50, gold = 500 },
    Impossible = { enemies = 50, damage = 75, gold = 1000 }
}

-- Weapons Table
local WEAPONS = {
    "Wooden Sword",
    "Iron Sword",
    "Diamond Sword",
    "Golden Sword",
    "Netherite Sword",
    "Axe",
    "Pickaxe",
    "Bow",
    "Crossbow",
    "Spear"
}

-- Enemies Table
local ENEMIES = {
    "Zombie",
    "Skeleton",
    "Creeper",
    "Spider",
    "Enderman",
    "Witch",
    "Wither",
    "Dragon",
    "Ghast",
    "Piglin"
}

-- Items/Treasures Table
local ITEMS = {
    "Diamond",
    "Gold Ingot",
    "Iron Ingot",
    "Emerald",
    "Netherite Ingot",
    "Redstone",
    "Lapis Lazuli",
    "Obsidian",
    "Ancient Debris",
    "End Pearl"
}

-- Armor Table
local ARMOR = {
    "Leather Armor",
    "Chain Armor",
    "Iron Armor",
    "Diamond Armor",
    "Netherite Armor",
    "Shield"
}

-- Spells Table
local SPELLS = {
    Fireball = { damage = 30, enemiesRemoved = 5, message = "🔥 Fireball cast! 30 damage to all enemies!" },
    FrostBolt = { damage = 20, message = "❄️ Frost bolt freezes enemies!" },
    Lightning = { damage = 40, message = "⚡ Lightning strikes! 40 damage!" },
    Heal = { heal = 50, message = "✨ Healing spell cast! +50 HP!" },
    Teleport = { message = "🌀 Teleported away safely!" }
}

-- Initialize player data
local function initializePlayerData(player)
    playerData[player.UserId] = {
        health = CONFIG.MAX_HEALTH,
        maxHealth = CONFIG.MAX_HEALTH,
        inventory = "None",
        zombies = 0,
        gold = 0,
        activePowerUps = {},
        armor = "None",
        statusEffects = {},
        comboCounter = 0,
        lastEnemySpawn = 0,
        battleCount = 0,
        totalDamage = 0
    }
    print("Player " .. player.Name .. " initialized")
end

-- Get player data safely
local function getPlayerData(player)
    if not playerData[player.UserId] then
        initializePlayerData(player)
    end
    return playerData[player.UserId]
end

-- Broadcast stats update to all players
local function broadcastStats(player)
    local data = getPlayerData(player)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local updateStatsEvent = remotes:FindFirstChild("UpdateStats")
        if updateStatsEvent then
            updateStatsEvent:FireAllClients(player.Name, data)
        end
    end
end

-- Damage Function
local function takeDamage(player, amount)
    local data = getPlayerData(player)
    local actualDamage = amount
    
    -- Apply armor reduction
    if data.armor ~= "None" then
        actualDamage = math.ceil(amount * (1 - CONFIG.DAMAGE_REDUCTION_ARMOR))
    end
    
    data.health = math.max(0, data.health - actualDamage)
    data.totalDamage = data.totalDamage + actualDamage
    
    -- Notify player
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "💥 You took " .. actualDamage .. " damage! Health: " .. data.health, "damage")
        end
    end
    
    broadcastStats(player)
    
    -- Check if dead
    if data.health <= 0 then
        if remotes then
            local messageEvent = remotes:FindFirstChild("ShowMessage")
            if messageEvent then
                messageEvent:FireClient(player, "💀 You are dead!", "death")
            end
        end
    end
end

-- Healing Function
local function healPlayer(player, amount)
    local data = getPlayerData(player)
    local oldHealth = data.health
    data.health = math.min(data.maxHealth, data.health + amount)
    local actualHeal = data.health - oldHealth
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "🍎 Healed " .. actualHeal .. " HP! Health: " .. data.health, "heal")
        end
    end
    
    broadcastStats(player)
end

-- Give Weapon Function
local function giveWeapon(player, weapon)
    local data = getPlayerData(player)
    data.inventory = weapon
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "⚔️ You picked up " .. weapon .. "!", "item")
        end
    end
    
    broadcastStats(player)
end

-- Give Item Function
local function giveItem(player, item)
    local data = getPlayerData(player)
    data.inventory = item
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "💎 You received " .. item .. "!", "treasure")
        end
    end
    
    broadcastStats(player)
end

-- Add Gold Function
local function addGold(player, amount)
    local data = getPlayerData(player)
    data.gold = data.gold + amount
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "💰 +" .. amount .. " Gold! Total: " .. data.gold, "gold")
        end
    end
    
    broadcastStats(player)
end

-- Spawn Enemy Function
local function spawnEnemy(player, enemyType)
    local data = getPlayerData(player)
    
    -- Check spawn cooldown
    if tick() - data.lastEnemySpawn < CONFIG.ENEMY_SPAWN_COOLDOWN then
        return
    end
    
    -- Check max enemies
    if data.zombies >= CONFIG.MAX_ENEMIES_PER_PLAYER then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local messageEvent = remotes:FindFirstChild("ShowMessage")
            if messageEvent then
                messageEvent:FireClient(player, "⚠️ Max enemies reached!", "warning")
            end
        end
        return
    end
    
    data.zombies = data.zombies + 1
    data.lastEnemySpawn = tick()
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "🧟 " .. enemyType .. " spawned! Total: " .. data.zombies, "enemy")
        end
        
        -- Create visual enemy in game world (optional)
        local spawnEvent = remotes:FindFirstChild("SpawnEnemy")
        if spawnEvent then
            spawnEvent:FireAllClients(player.Name, enemyType)
        end
    end
    
    broadcastStats(player)
end

-- Equip Armor Function
local function equipArmor(player, armor)
    local data = getPlayerData(player)
    data.armor = armor
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "🛡️ Equipped " .. armor .. "! Damage reduced by 50%", "armor")
        end
    end
    
    broadcastStats(player)
end

-- Activate Power-up Function
local function activatePowerUp(player, powerUp)
    local data = getPlayerData(player)
    
    if not table.find(data.activePowerUps, powerUp) then
        table.insert(data.activePowerUps, powerUp)
    end
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "⚡ " .. powerUp .. " activated!", "powerup")
        end
    end
    
    -- Deactivate after duration
    task.delay(CONFIG.POWERUP_DURATION, function()
        data.activePowerUps = {}
        if remotes then
            local messageEvent = remotes:FindFirstChild("ShowMessage")
            if messageEvent then
                messageEvent:FireClient(player, "❌ " .. powerUp .. " deactivated!", "info")
            end
        end
    end)
    
    broadcastStats(player)
end

-- Cast Spell Function
local function castSpell(player, spellName)
    local data = getPlayerData(player)
    local spell = SPELLS[spellName]
    
    if not spell then return end
    
    if spell.damage then
        data.zombies = math.max(0, data.zombies - (spell.enemiesRemoved or 5))
    end
    
    if spell.heal then
        healPlayer(player, spell.heal)
        return
    end
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, spell.message, "spell")
        end
    end
    
    broadcastStats(player)
end

-- Start Battle Function
local function startBattle(player, difficulty)
    local data = getPlayerData(player)
    local battle = BATTLES[difficulty]
    
    if not battle then return end
    
    data.zombies = data.zombies + battle.enemies
    takeDamage(player, battle.damage)
    addGold(player, battle.gold)
    data.battleCount = data.battleCount + 1
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "⚔️ " .. difficulty .. " Battle! " .. battle.enemies .. " enemies spawned. +" .. battle.gold .. " gold!", "battle")
        end
    end
    
    broadcastStats(player)
end

-- Apply Status Effect Function
local function applyEffect(player, effect)
    local data = getPlayerData(player)
    
    if not table.find(data.statusEffects, effect) then
        table.insert(data.statusEffects, effect)
    end
    
    -- Apply damage for certain effects
    if effect == "Poison" or effect == "Burning" then
        takeDamage(player, 5)
    elseif effect == "Bleeding" then
        takeDamage(player, 3)
    end
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, effect .. " applied to you!", "effect")
        end
    end
    
    -- Remove after duration
    task.delay(CONFIG.STATUS_EFFECT_DURATION, function()
        data.statusEffects = table.create(0)
        if remotes then
            local messageEvent = remotes:FindFirstChild("ShowMessage")
            if messageEvent then
                messageEvent:FireClient(player, effect .. " cured!", "info")
            end
        end
    end)
    
    broadcastStats(player)
end

-- Reset Game Function
local function resetGame(player)
    playerData[player.UserId] = nil
    initializePlayerData(player)
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local messageEvent = remotes:FindFirstChild("ShowMessage")
        if messageEvent then
            messageEvent:FireClient(player, "🔄 Game reset! Starting fresh...", "reset")
        end
    end
    
    broadcastStats(player)
end

-- Connect Remote Events
local function setupRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    
    -- Spawn Enemy
    local spawnEnemyEvent = remotes:FindFirstChild("SpawnEnemy")
    if spawnEnemyEvent then
        spawnEnemyEvent.OnServerEvent:Connect(function(player, enemyType)
            spawnEnemy(player, enemyType or ENEMIES[math.random(1, #ENEMIES)])
        end)
    end
    
    -- Take Damage
    local takeDamageEvent = remotes:FindFirstChild("TakeDamage")
    if takeDamageEvent then
        takeDamageEvent.OnServerEvent:Connect(function(player, amount)
            takeDamage(player, amount or 10)
        end)
    end
    
    -- Heal
    local healEvent = remotes:FindFirstChild("Heal")
    if healEvent then
        healEvent.OnServerEvent:Connect(function(player, amount)
            healPlayer(player, amount or 25)
        end)
    end
    
    -- Give Weapon
    local giveWeaponEvent = remotes:FindFirstChild("GiveWeapon")
    if giveWeaponEvent then
        giveWeaponEvent.OnServerEvent:Connect(function(player, weapon)
            giveWeapon(player, weapon or WEAPONS[math.random(1, #WEAPONS)])
        end)
    end
    
    -- Give Item
    local giveItemEvent = remotes:FindFirstChild("GiveItem")
    if giveItemEvent then
        giveItemEvent.OnServerEvent:Connect(function(player, item)
            giveItem(player, item or ITEMS[math.random(1, #ITEMS)])
        end)
    end
    
    -- Add Gold
    local addGoldEvent = remotes:FindFirstChild("AddGold")
    if addGoldEvent then
        addGoldEvent.OnServerEvent:Connect(function(player, amount)
            addGold(player, amount or 50)
        end)
    end
    
    -- Activate Power-up
    local powerUpEvent = remotes:FindFirstChild("ActivatePowerUp")
    if powerUpEvent then
        powerUpEvent.OnServerEvent:Connect(function(player, powerUp)
            activatePowerUp(player, powerUp)
        end)
    end
    
    -- Cast Spell
    local spellEvent = remotes:FindFirstChild("CastSpell")
    if spellEvent then
        spellEvent.OnServerEvent:Connect(function(player, spell)
            castSpell(player, spell)
        end)
    end
    
    -- Equip Armor
    local armorEvent = remotes:FindFirstChild("EquipArmor")
    if armorEvent then
        armorEvent.OnServerEvent:Connect(function(player, armor)
            equipArmor(player, armor)
        end)
    end
    
    -- Start Battle
    local battleEvent = remotes:FindFirstChild("StartBattle")
    if battleEvent then
        battleEvent.OnServerEvent:Connect(function(player, difficulty)
            startBattle(player, difficulty)
        end)
    end
    
    -- Apply Effect
    local effectEvent = remotes:FindFirstChild("ApplyEffect")
    if effectEvent then
        effectEvent.OnServerEvent:Connect(function(player, effect)
            applyEffect(player, effect)
        end)
    end
    
    -- Reset Game
    local resetEvent = remotes:FindFirstChild("ResetGame")
    if resetEvent then
        resetEvent.OnServerEvent:Connect(function(player)
            resetGame(player)
        end)
    end
end

-- Player Join
Players.PlayerAdded:Connect(function(player)
    initializePlayerData(player)
    print("Player " .. player.Name .. " joined the game")
end)

-- Player Leave
Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    print("Player " .. player.Name .. " left the game")
end)

-- Initialize
setupRemotes()
print("GameManager loaded and ready!")