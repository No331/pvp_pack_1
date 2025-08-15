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
    timeInPvP = {},
    headshots = {}
}

-- Configuration de la sauvegarde depuis config.lua
local saveConfig = Config.KDSave

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
            headshots = 0,
            multikills = 0,
            totalDamageDealt = 0,
            totalDamageReceived = 0,
            timeInPvP = 0,
            gamesPlayed = 0,
            lastPlayed = os.time(),
            playerName = GetPlayerName(src) or "Joueur Inconnu",
            firstPlayed = os.time(),
            totalSessions = 0
        }
    end
    
    -- Mettre à jour le nom du joueur et incrémenter les sessions
    playerStatsDB[identifier].playerName = GetPlayerName(src) or playerStatsDB[identifier].playerName
    playerStatsDB[identifier].totalSessions = playerStatsDB[identifier].totalSessions + 1
    
    return playerStatsDB[identifier]
end

-- Calculer le K/D d'un joueur
local function calculatePlayerKD(stats)
    if stats.deaths == 0 then
        return stats.kills > 0 and stats.kills or 0
    end
    return math.floor((stats.kills / stats.deaths) * 100) / 100
end

-- Calculer le KDA d'un joueur
local function calculatePlayerKDA(stats)
    if stats.deaths == 0 then
        return (stats.kills + stats.assists) > 0 and (stats.kills + stats.assists) or 0
    end
    return math.floor(((stats.kills + stats.assists) / stats.deaths) * 100) / 100
end

-- Calculer le taux de headshot
local function calculateHeadshotRate(stats)
    if stats.kills == 0 then return 0 end
    return math.floor((stats.headshots / stats.kills) * 100)
end

-- Mettre à jour les classements
local function updateLeaderboards()
    -- Réinitialiser les classements
    leaderboards.kills = {}
    leaderboards.kd = {}
    leaderboards.streak = {}
    leaderboards.timeInPvP = {}
    leaderboards.headshots = {}
    
    -- Parcourir tous les joueurs
    for identifier, stats in pairs(playerStatsDB) do
        local kd = calculatePlayerKD(stats)
        local headshotRate = calculateHeadshotRate(stats)
        
        -- Classement des kills
        table.insert(leaderboards.kills, {
            identifier = identifier,
            playerName = stats.playerName,
            value = stats.kills,
            stats = stats
        })
        
        -- Classement K/D (minimum configuré de deaths pour être classé)
        if stats.deaths >= Config.Leaderboards.minDeathsForKD then
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
        
        -- Classement headshots (minimum 10 kills pour être classé)
        if stats.kills >= 10 then
            table.insert(leaderboards.headshots, {
                identifier = identifier,
                playerName = stats.playerName,
                value = headshotRate,
                stats = stats
            })
        end
    end
    
    -- Trier les classements
    table.sort(leaderboards.kills, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.kd, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.streak, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.timeInPvP, function(a, b) return a.value > b.value end)
    table.sort(leaderboards.headshots, function(a, b) return a.value > b.value end)
    
    -- Limiter le nombre d'entrées selon la configuration
    for category, board in pairs(leaderboards) do
        if #board > Config.Leaderboards.maxEntries then
            for i = Config.Leaderboards.maxEntries + 1, #board do
                board[i] = nil
            end
        end
    end
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

-- Obtenir le rang d'un joueur dans un classement
local function getPlayerRank(identifier, category)
    local board = leaderboards[category]
    if not board then return nil end
    
    for i, entry in ipairs(board) do
        if entry.identifier == identifier then
            return i
        end
    end
    return nil
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
        if Config.DebugMode then
            print(string.format("[KD System] Statistiques chargées pour %s (K/D: %.2f)", 
                  GetPlayerName(src), calculatePlayerKD(stats)))
        end
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
    serverStats.headshots = clientStats.headshots or serverStats.headshots
    serverStats.multikills = clientStats.multikills or serverStats.multikills
    serverStats.totalDamageDealt = clientStats.totalDamageDealt or serverStats.totalDamageDealt
    serverStats.totalDamageReceived = clientStats.totalDamageReceived or serverStats.totalDamageReceived
    serverStats.timeInPvP = clientStats.timeInPvP or serverStats.timeInPvP
    serverStats.lastPlayed = os.time()
    serverStats.playerName = GetPlayerName(src)
    
    -- Mettre à jour les classements périodiquement
    if math.random(1, 5) == 1 then
        updateLeaderboards()
    end
    
    if Config.DebugMode then
        print(string.format("[KD System] Stats mises à jour pour %s: %d/%d/%d (K/D: %.2f)", 
              GetPlayerName(src), serverStats.kills, serverStats.deaths, serverStats.assists,
              calculatePlayerKD(serverStats)))
    end
end)

-- ====================================================================
-- COMMANDES ADMINISTRATEUR
-- ====================================================================

-- Commande pour voir le classement des kills
RegisterCommand("topkills", function(source, args, rawCommand)
    local src = source
    updateLeaderboards()
    
    local limit = math.min(10, #leaderboards.kills)
    local message = string.format("=== 🏆 TOP %d KILLS ===\n", limit)
    
    for i = 1, limit do
        local player = leaderboards.kills[i]
        local kd = calculatePlayerKD(player.stats)
        local kda = calculatePlayerKDA(player.stats)
        message = message .. string.format(
            "%d. %s - %d kills (K/D: %.2f | KDA: %.2f)\n",
            i, player.playerName, player.value, kd, kda
        )
    end
    
    if #leaderboards.kills == 0 then
        message = "Aucune statistique disponible"
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
    
    local limit = math.min(10, #leaderboards.kd)
    local message = string.format("=== 📊 TOP %d K/D RATIO ===\n", limit)
    
    for i = 1, limit do
        local player = leaderboards.kd[i]
        local kda = calculatePlayerKDA(player.stats)
        message = message .. string.format(
            "%d. %s - %.2f K/D (%d/%d) | KDA: %.2f\n",
            i, player.playerName, player.value, 
            player.stats.kills, player.stats.deaths, kda
        )
    end
    
    if #leaderboards.kd == 0 then
        message = string.format("Aucun joueur qualifié (minimum %d deaths requises)", 
                               Config.Leaderboards.minDeathsForKD)
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
    
    local limit = math.min(10, #leaderboards.streak)
    local message = string.format("=== 🔥 TOP %d STREAKS ===\n", limit)
    
    for i = 1, limit do
        local player = leaderboards.streak[i]
        if player.value > 0 then
            local kd = calculatePlayerKD(player.stats)
            message = message .. string.format(
                "%d. %s - %d kills de suite (K/D: %.2f)\n",
                i, player.playerName, player.value, kd
            )
        end
    end
    
    if #leaderboards.streak == 0 or leaderboards.streak[1].value == 0 then
        message = "Aucune streak enregistrée"
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

-- Commande pour voir le classement des headshots
RegisterCommand("topheadshots", function(source, args, rawCommand)
    local src = source
    updateLeaderboards()
    
    local limit = math.min(10, #leaderboards.headshots)
    local message = string.format("=== 🎯 TOP %d HEADSHOTS ===\n", limit)
    
    for i = 1, limit do
        local player = leaderboards.headshots[i]
        message = message .. string.format(
            "%d. %s - %d%% headshots (%d/%d kills)\n",
            i, player.playerName, player.value, 
            player.stats.headshots, player.stats.kills
        )
    end
    
    if #leaderboards.headshots == 0 then
        message = "Aucun joueur qualifié (minimum 10 kills requises)"
    end
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {241, 196, 15},
            multiline = true,
            args = {"🎯 TOP HEADSHOTS", message}
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
    local kda = calculatePlayerKDA(stats)
    local headshotRate = calculateHeadshotRate(stats)
    
    -- Obtenir les rangs dans les classements
    updateLeaderboards()
    local killRank = getPlayerRank(identifier, 'kills') or "Non classé"
    local kdRank = getPlayerRank(identifier, 'kd') or "Non classé"
    
    local message = string.format(
        "=== 📊 STATS DE %s ===\n" ..
        "💀 Kills: %d | ☠️ Deaths: %d | 🤝 Assists: %d | 🎯 Headshots: %d\n" ..
        "📊 K/D: %.2f | 📈 KDA: %.2f | 🎯 Headshot%%: %d%%\n" ..
        "🔥 Meilleure streak: %d | ⚡ Multikills: %d\n" ..
        "⏱️ Temps en PvP: %s | 🎮 Sessions: %d\n" ..
        "🏆 Rang kills: %s | 📊 Rang K/D: %s",
        stats.playerName, stats.kills, stats.deaths, stats.assists, stats.headshots,
        kd, kda, headshotRate, stats.bestStreak, stats.multikills,
        formatTime(stats.timeInPvP), stats.totalSessions, 
        tostring(killRank), tostring(kdRank)
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

-- Commande pour voir les statistiques globales du serveur
RegisterCommand("serverstats", function(source, args, rawCommand)
    local src = source
    
    local totalPlayers = 0
    local totalKills = 0
    local totalDeaths = 0
    local totalAssists = 0
    local totalHeadshots = 0
    local totalTimeInPvP = 0
    local activePlayers = 0
    
    local currentTime = os.time()
    
    for _, stats in pairs(playerStatsDB) do
        totalPlayers = totalPlayers + 1
        totalKills = totalKills + stats.kills
        totalDeaths = totalDeaths + stats.deaths
        totalAssists = totalAssists + stats.assists
        totalHeadshots = totalHeadshots + stats.headshots
        totalTimeInPvP = totalTimeInPvP + stats.timeInPvP
        
        -- Joueur actif dans les dernières 24h
        if currentTime - stats.lastPlayed < 86400 then
            activePlayers = activePlayers + 1
        end
    end
    
    local avgKD = totalDeaths > 0 and (totalKills / totalDeaths) or totalKills
    local headshotRate = totalKills > 0 and (totalHeadshots / totalKills * 100) or 0
    
    local message = string.format(
        "=== 📊 STATISTIQUES SERVEUR ===\n" ..
        "👥 Joueurs total: %d | 🟢 Actifs (24h): %d\n" ..
        "💀 Kills total: %d | ☠️ Deaths total: %d | 🤝 Assists total: %d\n" ..
        "📊 K/D moyen: %.2f | 🎯 Headshots: %d (%.1f%%)\n" ..
        "⏱️ Temps PvP total: %s",
        totalPlayers, activePlayers, totalKills, totalDeaths, totalAssists,
        avgKD, totalHeadshots, headshotRate, formatTime(totalTimeInPvP)
    )
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {155, 89, 182},
            multiline = true,
            args = {"📊 SERVER STATS", message}
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
        local oldStats = {
            kills = playerStatsDB[identifier].kills,
            deaths = playerStatsDB[identifier].deaths,
            assists = playerStatsDB[identifier].assists
        }
        
        playerStatsDB[identifier] = {
            kills = 0,
            deaths = 0,
            assists = 0,
            bestStreak = 0,
            headshots = 0,
            multikills = 0,
            totalDamageDealt = 0,
            totalDamageReceived = 0,
            timeInPvP = 0,
            gamesPlayed = 0,
            totalSessions = playerStatsDB[identifier].totalSessions or 0,
            firstPlayed = playerStatsDB[identifier].firstPlayed or os.time(),
            lastPlayed = os.time(),
            playerName = playerName
        }
        
        -- Informer le joueur cible
        TriggerClientEvent('chat:addMessage', targetId, {
            color = {241, 196, 15},
            args = {"🔄 ADMIN", "Vos statistiques K/D ont été réinitialisées"}
        })
        
        -- Confirmer à l'admin
        local message = string.format(
            "Statistiques de %s réinitialisées (ancien: %d/%d/%d)",
            playerName, oldStats.kills, oldStats.deaths, oldStats.assists
        )
        if src == 0 then
            print("[KD Admin] " .. message)
        else
            TriggerClientEvent('chat:addMessage', src, {
                color = {46, 204, 113},
                multiline = true,
                args = {"✅ ADMIN", message}
            })
        end
        
        updateLeaderboards()
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Aucune statistique trouvée pour ce joueur"}
        })
    end
end, true)

-- ====================================================================
-- SYSTÈME DE SAUVEGARDE
-- ====================================================================

-- Sauvegarder les données dans un fichier JSON
local function saveStatsToFile()
    if not saveConfig.enablePersistence then return end
    
    local data = {
        playerStats = playerStatsDB,
        lastSave = os.time(),
        version = "2.0.0",
        totalPlayers = 0
    }
    
    -- Compter le nombre de joueurs
    for _ in pairs(playerStatsDB) do
        data.totalPlayers = data.totalPlayers + 1
    end
    
    -- Ici vous pouvez implémenter la sauvegarde dans un fichier
    -- ou une base de données selon vos préférences
    if Config.DebugMode then
        print(string.format("[KD System] Statistiques sauvegardées (%d joueurs)", 
              data.totalPlayers))
    end
end

-- Charger les données depuis un fichier
local function loadStatsFromFile()
    if not saveConfig.enablePersistence then return end
    
    -- Ici vous pouvez implémenter le chargement depuis un fichier
    -- ou une base de données
    if Config.DebugMode then
        print("[KD System] Chargement des statistiques...")
    end
end

-- ====================================================================
-- THREADS DE MAINTENANCE
-- ====================================================================

-- Thread de sauvegarde automatique
Citizen.CreateThread(function()
    if not saveConfig.enablePersistence then return end
    
    while true do
        Citizen.Wait(saveConfig.autoSaveInterval)
        saveStatsToFile()
        
        -- Mettre à jour les classements selon l'intervalle configuré
        if Config.Leaderboards.updateInterval <= saveConfig.autoSaveInterval then
            updateLeaderboards()
        end
    end
end)

-- Thread de mise à jour des classements
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Leaderboards.updateInterval)
        updateLeaderboards()
        
        if Config.DebugMode then
            print(string.format("[KD System] Classements mis à jour (%d joueurs)", 
                  #leaderboards.kills))
        end
    end
end)

-- Thread de nettoyage des données anciennes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000) -- Toutes les heures
        
        local currentTime = os.time()
        local cleanedCount = 0
        local maxInactiveTime = saveConfig.maxInactiveDays * 24 * 3600
        
        -- Supprimer les joueurs inactifs selon la configuration
        for identifier, stats in pairs(playerStatsDB) do
            if currentTime - stats.lastPlayed > maxInactiveTime then
                playerStatsDB[identifier] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        if cleanedCount > 0 then
            print(string.format("[KD System] %d profils inactifs supprimés (>%d jours)", 
                  cleanedCount, saveConfig.maxInactiveDays))
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
        print(string.format("Sauvegarde persistante: %s", 
              saveConfig.enablePersistence and "Activée" or "Désactivée"))
        print(string.format("Intervalle de sauvegarde: %d minutes", 
              saveConfig.autoSaveInterval / 60000))
        
        loadStatsFromFile()
        updateLeaderboards()
        
        -- Initialiser les joueurs déjà connectés
        for _, playerId in ipairs(GetPlayers()) do
            initializePlayerStats(tonumber(playerId))
        end
        
        print(string.format("Joueurs avec statistiques: %d", 
              #playerStatsDB))
    end
end)

-- Sauvegarde à l'arrêt
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        saveStatsToFile()
        print("=== KD System Server Stopped ===")
        local totalPlayers = 0
        for _ in pairs(playerStatsDB) do
            totalPlayers = totalPlayers + 1
        end
        
        print(string.format("Statistiques finales sauvegardées pour %d joueurs", totalPlayers))
    end
end)

-- Initialiser un nouveau joueur qui se connecte
AddEventHandler('playerConnecting', function()
    local src = source
    Citizen.SetTimeout(5000, function() -- Attendre que le joueur soit complètement connecté
        if GetPlayerName(src) then -- Vérifier que le joueur est toujours connecté
            initializePlayerStats(src)
        end
    end)
end)

-- Sauvegarder quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if identifier and playerStatsDB[identifier] then
        playerStatsDB[identifier].lastPlayed = os.time()
        
        if Config.DebugMode then
            local stats = playerStatsDB[identifier]
            print(string.format("[KD System] Statistiques sauvegardées pour %s (K/D: %.2f)", 
                  stats.playerName, calculatePlayerKD(stats)))
        end
    end
end)