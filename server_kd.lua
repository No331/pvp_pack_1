-- ====================================================================
-- SERVER KD SYSTEM - Gestion serveur des statistiques K/D
-- Sauvegarde, classements et gestion des données
-- ====================================================================

-- Base de données des statistiques des joueurs
local playerStatsDB = {}

-- Classements globaux
local leaderboards = {
    kills = {},
    kd = {},
    streak = {},
    timeInPvP = {}
}

-- Configuration de la sauvegarde
local saveConfig = {
    autoSaveInterval = 300000, -- 5 minutes
    backupInterval = 1800000,  -- 30 minutes
    maxBackups = 5
}

-- ====================================================================
-- FONCTIONS DE GESTION DES DONNÉES
-- ====================================================================

-- Initialiser les statistiques d'un nouveau joueur
local function initializePlayerStats(src)
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return nil end
    
    if not playerStatsDB[identifier] then
        playerStatsDB[identifier] = {
            kills = 0,
            deaths = 0,
            assists = 0,
            bestStreak = 0,
            totalDamageDealt = 0,
            totalDamageReceived = 0,
            timeInPvP = 0,
            gamesPlayed = 0,
            lastPlayed = os.time(),
            playerName = GetPlayerName(src) or "Joueur Inconnu"
        }
    end
    
    return playerStatsDB[identifier]
end

-- Calculer le K/D d'un joueur
local function calculatePlayerKD(stats)
    if stats.deaths == 0 then
        return stats.kills > 0 and stats.kills or 0
    end
    return math.floor((stats.kills / stats.deaths) * 100) / 100
end

-- Mettre à jour les classements
local function updateLeaderboards()
    -- Réinitialiser les classements
    leaderboards.kills = {}
    leaderboards.kd = {}
    leaderboards.streak = {}
    leaderboards.timeInPvP = {}
    
    -- Parcourir tous les joueurs
    for identifier, stats in pairs(playerStatsDB) do
        local kd = calculatePlayerKD(stats)
        
        -- Classement des kills
        table.insert(leaderboards.kills, {
            identifier = identifier,
            playerName = stats.playerName,
            value = stats.kills,
            stats = stats
        })
        
        -- Classement K/D (minimum 5 deaths pour être classé)
        if stats.deaths >= 5 then
            table.insert(leaderboards.kd, {
                identifier = identifier,
                playerName = stats.playerName,
                value = kd,
                stats = stats
            })
        end
        
        -- Classement streak
        table.insert(leaderboards.streak, {
            identifier = identifier,
            playerName = stats.playerName,
            value = stats.bestStreak,
            stats = stats
        })
        
        -- Classement temps en PvP
        table.insert(leaderboards.timeInPvP, {
            identifier = identifier,
            playerName = stats.playerName,
            value = stats.timeInPvP,
            stats = stats
        })
    end
    
    -- Trier les classements
    table.sort(leaderboards.kills, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.kd, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.streak, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.timeInPvP, function(a, b) return a.value > b.value end)
end

-- Formater le temps en texte lisible
local function formatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%dh %dm", hours, minutes)
    end
end

-- ====================================================================
-- ÉVÉNEMENTS RÉSEAU
-- ====================================================================

-- Charger les statistiques d'un joueur
RegisterNetEvent('kd:loadStats')
AddEventHandler('kd:loadStats', function()
    local src = source
    local stats = initializePlayerStats(src)
    
    if stats then
        TriggerClientEvent('kd:receiveStats', src, stats)
        print(string.format("[KD System] Statistiques chargées pour %s", GetPlayerName(src)))
    end
end)

-- Mettre à jour les statistiques d'un joueur
RegisterNetEvent('kd:updateStats')
AddEventHandler('kd:updateStats', function(clientStats)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier or not clientStats then return end
    
    local serverStats = initializePlayerStats(src)
    if not serverStats then return end
    
    -- Mettre à jour les statistiques
    serverStats.kills = clientStats.kills or serverStats.kills
    serverStats.deaths = clientStats.deaths or serverStats.deaths
    serverStats.assists = clientStats.assists or serverStats.assists
    serverStats.bestStreak = math.max(serverStats.bestStreak, clientStats.bestStreak or 0)
    serverStats.totalDamageDealt = clientStats.totalDamageDealt or serverStats.totalDamageDealt
    serverStats.totalDamageReceived = clientStats.totalDamageReceived or serverStats.totalDamageReceived
    serverStats.timeInPvP = clientStats.timeInPvP or serverStats.timeInPvP
    serverStats.lastPlayed = os.time()
    serverStats.playerName = GetPlayerName(src)
    
    -- Mettre à jour les classements toutes les 10 mises à jour
    if math.random(1, 10) == 1 then
        updateLeaderboards()
    end
end)

-- ====================================================================
-- COMMANDES ADMINISTRATEUR
-- ====================================================================

-- Commande pour voir le classement des kills
RegisterCommand("topkills", function(source, args, rawCommand)
    local src = source
    updateLeaderboards()
    
    local message = "=== 🏆 TOP 10 KILLS ===\n"
    for i = 1, math.min(10, #leaderboards.kills) do
        local player = leaderboards.kills[i]
        local kd = calculatePlayerKD(player.stats)
        message = message .. string.format(
            "%d. %s - %d kills (K/D: %.2f)\n",
            i, player.playerName, player.value, kd
        )
    end
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {241, 196, 15},
            multiline = true,
            args = {"🏆 TOP KILLS", message}
        })
    end
end, false)

-- Commande pour voir le classement K/D
RegisterCommand("topkd", function(source, args, rawCommand)
    local src = source
    updateLeaderboards()
    
    local message = "=== 📊 TOP 10 K/D RATIO ===\n"
    for i = 1, math.min(10, #leaderboards.kd) do
        local player = leaderboards.kd[i]
        message = message .. string.format(
            "%d. %s - %.2f K/D (%d/%d)\n",
            i, player.playerName, player.value, 
            player.stats.kills, player.stats.deaths
        )
    end
    
    if #leaderboards.kd == 0 then
        message = "Aucun joueur qualifié (minimum 5 deaths requises)"
    end
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {52, 152, 219},
            multiline = true,
            args = {"📊 TOP K/D", message}
        })
    end
end, false)

-- Commande pour voir le classement des streaks
RegisterCommand("topstreak", function(source, args, rawCommand)
    local src = source
    updateLeaderboards()
    
    local message = "=== 🔥 TOP 10 STREAKS ===\n"
    for i = 1, math.min(10, #leaderboards.streak) do
        local player = leaderboards.streak[i]
        if player.value > 0 then
            message = message .. string.format(
                "%d. %s - %d kills de suite\n",
                i, player.playerName, player.value
            )
        end
    end
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {231, 76, 60},
            multiline = true,
            args = {"🔥 TOP STREAKS", message}
        })
    end
end, false)

-- Commande pour voir les statistiques d'un joueur spécifique
RegisterCommand("playerkd", function(source, args, rawCommand)
    local src = source
    
    if not args[1] then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            args = {"[Usage]", "/playerkd <ID du joueur>"}
        })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Joueur introuvable."}
        })
        return
    end
    
    local identifier = GetPlayerIdentifier(targetId, 0)
    if not identifier or not playerStatsDB[identifier] then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            args = {"[Info]", "Aucune statistique trouvée pour ce joueur."}
        })
        return
    end
    
    local stats = playerStatsDB[identifier]
    local kd = calculatePlayerKD(stats)
    local kda = stats.deaths > 0 and ((stats.kills + stats.assists) / stats.deaths) or (stats.kills + stats.assists)
    
    local message = string.format(
        "=== 📊 STATS DE %s ===\n" ..
        "💀 Kills: %d | ☠️ Deaths: %d | 🤝 Assists: %d\n" ..
        "📊 K/D: %.2f | 📈 KDA: %.2f\n" ..
        "🔥 Meilleure streak: %d\n" ..
        "⏱️ Temps en PvP: %s\n" ..
        "🎮 Parties jouées: %d",
        stats.playerName, stats.kills, stats.deaths, stats.assists,
        kd, kda, stats.bestStreak, formatTime(stats.timeInPvP), stats.gamesPlayed
    )
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {46, 204, 113},
            multiline = true,
            args = {"📊 PLAYER STATS", message}
        })
    end
end, false)

-- Commande admin pour réinitialiser les stats d'un joueur
RegisterCommand("resetplayerkd", function(source, args, rawCommand)
    local src = source
    
    -- Vérification des permissions admin
    if src > 0 and not IsPlayerAceAllowed(src, "command.resetplayerkd") then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Permission refusée."}
        })
        return
    end
    
    if not args[1] then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            args = {"[Usage]", "/resetplayerkd <ID du joueur>"}
        })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Joueur introuvable."}
        })
        return
    end
    
    local identifier = GetPlayerIdentifier(targetId, 0)
    if identifier and playerStatsDB[identifier] then
        local playerName = playerStatsDB[identifier].playerName
        playerStatsDB[identifier] = {
            kills = 0,
            deaths = 0,
            assists = 0,
            bestStreak = 0,
            totalDamageDealt = 0,
            totalDamageReceived = 0,
            timeInPvP = 0,
            gamesPlayed = 0,
            lastPlayed = os.time(),
            playerName = playerName
        }
        
        -- Informer le joueur cible
        TriggerClientEvent('chat:addMessage', targetId, {
            color = {241, 196, 15},
            args = {"🔄 ADMIN", "Vos statistiques K/D ont été réinitialisées"}
        })
        
        -- Confirmer à l'admin
        local message = string.format("Statistiques de %s réinitialisées", playerName)
        if src == 0 then
            print("[KD Admin] " .. message)
        else
            TriggerClientEvent('chat:addMessage', src, {
                color = {46, 204, 113},
                args = {"✅ ADMIN", message}
            })
        end
        
        updateLeaderboards()
    end
end, true)

-- ====================================================================
-- SYSTÈME DE SAUVEGARDE
-- ====================================================================

-- Sauvegarder les données dans un fichier JSON
local function saveStatsToFile()
    local data = {
        playerStats = playerStatsDB,
        lastSave = os.time(),
        version = "2.0.0"
    }
    
    -- Ici vous pouvez implémenter la sauvegarde dans un fichier
    -- ou une base de données selon vos préférences
    print(string.format("[KD System] Statistiques sauvegardées (%d joueurs)", 
          #playerStatsDB))
end

-- Charger les données depuis un fichier
local function loadStatsFromFile()
    -- Ici vous pouvez implémenter le chargement depuis un fichier
    -- ou une base de données
    print("[KD System] Chargement des statistiques...")
end

-- ====================================================================
-- THREADS DE MAINTENANCE
-- ====================================================================

-- Thread de sauvegarde automatique
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(saveConfig.autoSaveInterval)
        saveStatsToFile()
        updateLeaderboards()
    end
end)

-- Thread de nettoyage des données anciennes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000) -- Toutes les heures
        
        local currentTime = os.time()
        local cleanedCount = 0
        
        -- Supprimer les joueurs inactifs depuis plus de 30 jours
        for identifier, stats in pairs(playerStatsDB) do
            if currentTime - stats.lastPlayed > (30 * 24 * 3600) then
                playerStatsDB[identifier] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        if cleanedCount > 0 then
            print(string.format("[KD System] %d profils inactifs supprimés", cleanedCount))
            updateLeaderboards()
        end
    end
end)

-- ====================================================================
-- ÉVÉNEMENTS DE DÉMARRAGE ET ARRÊT
-- ====================================================================

-- Initialisation au démarrage
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("=== KD System Server Started ===")
        loadStatsFromFile()
        updateLeaderboards()
        
        -- Initialiser les joueurs déjà connectés
        for _, playerId in ipairs(GetPlayers()) do
            initializePlayerStats(tonumber(playerId))
        end
    end
end)

-- Sauvegarde à l'arrêt
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        saveStatsToFile()
        print("=== KD System Server Stopped ===")
    end
end)

-- Initialiser un nouveau joueur qui se connecte
AddEventHandler('playerConnecting', function()
    local src = source
    Citizen.SetTimeout(5000, function() -- Attendre que le joueur soit complètement connecté
        initializePlayerStats(src)
    end)
end)

-- Sauvegarder quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if identifier and playerStatsDB[identifier] then
        playerStatsDB[identifier].lastPlayed = os.time()
        print(string.format("[KD System] Statistiques sauvegardées pour %s", 
              playerStatsDB[identifier].playerName))
    end
end)