// Game State
const gameState = {
    health: 100,
    maxHealth: 100,
    inventory: 'None',
    zombies: 0,
    gold: 0,
    activePowerUps: [],
    armor: 'None',
    statusEffects: [],
    comboCounter: 0
};

// Get DOM elements
const healthDisplay = document.getElementById('health');
const inventoryDisplay = document.getElementById('inventory');
const zombiesDisplay = document.getElementById('zombies');
const goldDisplay = document.getElementById('gold');
const messageBox = document.getElementById('messageBox');

// Update Display
function updateDisplay() {
    healthDisplay.textContent = gameState.health;
    inventoryDisplay.textContent = gameState.inventory;
    zombiesDisplay.textContent = gameState.zombies;
    goldDisplay.textContent = gameState.gold;
}

// Show Message
function showMessage(text, type = 'normal') {
    messageBox.textContent = text;
    messageBox.classList.remove('damage', 'heal', 'victory');
    if (type) {
        messageBox.classList.add(type);
    }
    setTimeout(() => {
        messageBox.classList.remove('damage', 'heal', 'victory');
    }, 1000);
}

// Weapon Functions
function giveWeapon(weapon) {
    gameState.inventory = weapon;
    updateDisplay();
    showMessage(`⚔️ You picked up ${weapon}!`);
}

// Enemy Functions
function spawnEnemy(enemy) {
    gameState.zombies++;
    updateDisplay();
    showMessage(`🧟 ${enemy} spawned! Total: ${gameState.zombies}`);
}

function spawnRandomEnemy() {
    const enemies = ['Zombie', 'Skeleton', 'Creeper', 'Spider', 'Enderman', 'Witch', 'Wither', 'Dragon', 'Ghast', 'Piglin'];
    const randomEnemy = enemies[Math.floor(Math.random() * enemies.length)];
    spawnEnemy(randomEnemy);
}

// Damage Function
function takeDamage(amount) {
    // Apply armor reduction (if equipped)
    let actualDamage = amount;
    if (gameState.armor !== 'None') {
        actualDamage = Math.ceil(amount * 0.5); // Armor reduces damage by 50%
    }

    gameState.health -= actualDamage;
    if (gameState.health < 0) gameState.health = 0;
    
    updateDisplay();
    showMessage(`💥 You took ${actualDamage} damage! Health: ${gameState.health}`, 'damage');
    
    if (gameState.health <= 0) {
        showMessage('💀 You are dead!');
    }
}

// Healing Function
function heal(amount) {
    const oldHealth = gameState.health;
    gameState.health += amount;
    if (gameState.health > gameState.maxHealth) {
        gameState.health = gameState.maxHealth;
    }
    const actualHeal = gameState.health - oldHealth;
    updateDisplay();
    showMessage(`🍎 Healed ${actualHeal} HP! Health: ${gameState.health}`, 'heal');
}

// Item/Treasure Function
function giveItem(item) {
    gameState.inventory = item;
    updateDisplay();
    showMessage(`💎 You received ${item}!`);
}

function giveRandomTreasure() {
    const treasures = ['Diamond', 'Gold Ingot', 'Iron Ingot', 'Emerald', 'Netherite Ingot', 'Redstone', 'Lapis Lazuli', 'Obsidian', 'Ancient Debris', 'End Pearl'];
    const randomTreasure = treasures[Math.floor(Math.random() * treasures.length)];
    giveItem(randomTreasure);
}

function giveRandomWeapon() {
    const weapons = ['Wooden Sword', 'Iron Sword', 'Diamond Sword', 'Golden Sword', 'Netherite Sword', 'Axe', 'Pickaxe', 'Bow', 'Crossbow', 'Spear'];
    const randomWeapon = weapons[Math.floor(Math.random() * weapons.length)];
    giveWeapon(randomWeapon);
}

// Gold Function
function addGold(amount) {
    gameState.gold += amount;
    updateDisplay();
    showMessage(`🪙 +${amount} Gold! Total: ${gameState.gold}`);
}

// Power-up Function
function activatePowerUp(powerUp) {
    if (!gameState.activePowerUps.includes(powerUp)) {
        gameState.activePowerUps.push(powerUp);
    }
    showMessage(`⚡ ${powerUp} activated!`);
    
    // Auto-deactivate after 10 seconds
    setTimeout(() => {
        gameState.activePowerUps = gameState.activePowerUps.filter(p => p !== powerUp);
        showMessage(`❌ ${powerUp} deactivated!`);
    }, 10000);
}

// Armor Function
function equipArmor(armor) {
    gameState.armor = armor;
    updateDisplay();
    showMessage(`🛡️ Equipped ${armor}! Damage reduced by 50%`);
}

// Battle Function
function startBattle(difficulty) {
    const battles = {
        'Easy': { enemies: 3, damage: 5, gold: 50 },
        'Medium': { enemies: 5, damage: 15, gold: 150 },
        'Hard': { enemies: 10, damage: 30, gold: 300 },
        'Nightmare': { enemies: 20, damage: 50, gold: 500 },
        'Impossible': { enemies: 50, damage: 75, gold: 1000 }
    };

    const battle = battles[difficulty];
    gameState.zombies += battle.enemies;
    
    // Deal damage
    takeDamage(battle.damage);
    
    // Award gold
    gameState.gold += battle.gold;
    updateDisplay();
    
    showMessage(`⚔️ ${difficulty} Battle! ${battle.enemies} enemies spawned. +${battle.gold} gold!`, 'victory');
}

// Spell Function
function castSpell(spell) {
    const spells = {
        'Fireball': { damage: 30, message: '🔥 Fireball cast! 30 damage to all enemies!' },
        'Frost Bolt': { damage: 20, message: '❄️ Frost bolt freezes enemies!' },
        'Lightning': { damage: 40, message: '⚡ Lightning strikes! 40 damage!' },
        'Heal': { heal: 50, message: '✨ Healing spell cast! +50 HP!' },
        'Teleport': { message: '🌀 Teleported away safely!' }
    };

    const spellEffect = spells[spell];
    
    if (spellEffect.damage) {
        gameState.zombies = Math.max(0, gameState.zombies - 5);
    }
    if (spellEffect.heal) {
        heal(spellEffect.heal);
        return;
    }
    
    updateDisplay();
    showMessage(spellEffect.message);
}

// Extra Features
function activateCheat(cheat) {
    const cheats = {
        'Mega Boost': { gold: 500, health: 50, message: '🚀 Mega Boost Activated! +500 Gold, +50 HP!' },
        'Lucky Draw': { gold: Math.floor(Math.random() * 500) + 100, message: '🍀 Lucky Draw! Random Gold!' },
        'Double XP': { gold: gameState.gold, message: '✖️2 Double XP Multiplier!' },
        'Mystery Box': { message: '📦 Mystery Box Opened!' },
        'Combo x5': { gold: gameState.gold * 5, message: '💥 Combo x5 Multiplier!' }
    };

    const cheatEffect = cheats[cheat];
    if (cheatEffect.gold) gameState.gold += cheatEffect.gold;
    if (cheatEffect.health) heal(cheatEffect.health);
    updateDisplay();
    showMessage(cheatEffect.message, 'victory');
}

function triggerRoyalRumble() {
    gameState.zombies = 100;
    takeDamage(75);
    gameState.gold += 2000;
    updateDisplay();
    showMessage('👑 Royal Rumble! 100 Enemies! -75 HP! +2000 Gold!', 'victory');
}

function activateFrenzy() {
    gameState.zombies += 50;
    heal(200);
    gameState.gold += 500;
    gameState.comboCounter += 5;
    updateDisplay();
    showMessage('🔥 Frenzy Mode! +50 Enemies, +200 HP, +500 Gold, +5 Combo!', 'victory');
}

// Status Effects
function applyEffect(effect) {
    if (!gameState.statusEffects.includes(effect)) {
        gameState.statusEffects.push(effect);
    }
    showMessage(`${effect} applied to you!`);
    
    // Apply damage over time for certain effects
    if (effect === 'Poison' || effect === 'Burning') {
        takeDamage(5);
    }
    if (effect === 'Bleeding') {
        takeDamage(3);
    }
    
    // Auto-remove after 8 seconds
    setTimeout(() => {
        gameState.statusEffects = gameState.statusEffects.filter(e => e !== effect);
        showMessage(`${effect} cured!`);
    }, 8000);
}

// Reset Game
function resetGame() {
    gameState.health = 100;
    gameState.maxHealth = 100;
    gameState.inventory = 'None';
    gameState.zombies = 0;
    gameState.gold = 0;
    gameState.activePowerUps = [];
    gameState.armor = 'None';
    gameState.statusEffects = [];
    gameState.comboCounter = 0;
    updateDisplay();
    showMessage('🔄 Game reset! Starting fresh...');
}

// Show Stats
function showStats() {
    const stats = `
📊 GAME STATS
───────────────────────────────
Health: ${gameState.health}/${gameState.maxHealth}
Inventory: ${gameState.inventory}
Armor: ${gameState.armor}
Zombies Spawned: ${gameState.zombies}
Gold Earned: ${gameState.gold}
Active Power-ups: ${gameState.activePowerUps.length > 0 ? gameState.activePowerUps.join(', ') : 'None'}
Status Effects: ${gameState.statusEffects.length > 0 ? gameState.statusEffects.join(', ') : 'None'}
Combo Counter: ${gameState.comboCounter}
───────────────────────────────
    `;
    showMessage(stats);
    console.log(stats);
}

// Game Over
function gameOver() {
    showMessage('💥 GAME OVER! Thanks for playing!', 'victory');
    setTimeout(() => {
        if (confirm('Game Over! Would you like to restart?')) {
            resetGame();
        }
    }, 500);
}

// Initialize
updateDisplay();
console.log('🎮 Interactive Button Game Loaded!');
console.log('Total Buttons: 100+');
console.log('Features: Weapons, Enemies, Damage, Healing, Items, Gold, Power-ups, Armor, Battles, Spells, Extra Features, Status Effects');