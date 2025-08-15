-- ====================================================================
-- SERVER SCRIPT - vMenu Zone Disabler
-- Gestion côté serveur des logs, statistiques et commandes admin
-- ====================================================================

-- ====================================================================
-- VARIABLES GLOBALES ET STOCKAGE
-- ====================================================================

-- Table pour suivre les joueurs actuellement dans les zones restreintes
local playersInZones = {}

-- Statistiques globales du serveur
local serverStats = {
    totalEntries = 0,           -- Nombre total d'entrées en zone
    totalExits = 0,             -- Nombre total de sorties de zone
    currentPlayersInZones = 0,  -- Nombre actuel de joueurs en zone
    sessionsData = {},          -- Données des sessions par joueur
    startTime = os.time()       -- Heure de démarrage du script
}

-- Cache des noms de joueurs pour optimiser les performances
local playerNameCache = {}

-- ====================================================================
-- FONCTIONS UTILITAIRES
-- ====================================================================

-- Fonction pour obtenir le nom d'un joueur avec cache
local function getPlayerNameCached(src)
    if not playerNameCache[src] then
        playerNameCache[src] = GetPlayerName(src) or "Joueur Inconnu"
    end
    return playerNameCache[src]
end

-- Fonction pour nettoyer le cache des noms de joueurs
local function cleanPlayerNameCache()
    local activePlayers = {}
    for _, playerId in ipairs(GetPlayers()) do
        activePlayers[tonumber(playerId)] = true
    end
    
    for playerId in pairs(playerNameCache) do
        if not activePlayers[playerId] then
            playerNameCache[playerId] = nil
        end
    end
end

-- Fonction pour formater la durée en texte lisible
local function formatDuration(seconds)
    if seconds < 60 then
        return string.format("%d secondes", seconds)
    elseif seconds < 3600 then
        return string.format("%d minutes %d secondes", math.floor(seconds / 60), seconds % 60)
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%d heures %d minutes", hours, minutes)
    end
end

-- ====================================================================
-- GESTION DES ÉVÉNEMENTS DE ZONE
-- ====================================================================

-- Événement déclenché quand un joueur entre dans une zone restreinte
RegisterNetEvent('vmenu:playerEnteredRestrictedZone')
AddEventHandler('vmenu:playerEnteredRestrictedZone', function(zoneName)
    local src = source
    local playerName = getPlayerNameCached(src)
    local currentTime = os.time()
    
    -- Vérifier que le joueur existe toujours
    if not GetPlayerName(src) then
        return
    end
    
    -- Enregistrer le joueur dans la zone
    playersInZones[src] = {
        zoneName = zoneName,
        enterTime = currentTime,
        playerName = playerName
    }
    
    -- Mettre à jour les statistiques
    serverStats.totalEntries = serverStats.totalEntries + 1
    serverStats.currentPlayersInZones = serverStats.currentPlayersInZones + 1
    
    -- Initialiser les données de session si nécessaire
    if not serverStats.sessionsData[src] then
        serverStats.sessionsData[src] = {
            totalTimeInZones = 0,
            zonesVisited = {},
            entriesCount = 0
        }
    end
    
    serverStats.sessionsData[src].entriesCount = serverStats.sessionsData[src].entriesCount + 1
    
    -- Ajouter la zone visitée si pas déjà présente
    local zoneVisited = false
    for _, visitedZone in ipairs(serverStats.sessionsData[src].zonesVisited) do
        if visitedZone == zoneName then
            zoneVisited = true
            break
        end
    end
    
    if not zoneVisited then
        table.insert(serverStats.sessionsData[src].zonesVisited, zoneName)
    end
    
    -- Log détaillé pour les administrateurs
    local logMessage = string.format(
        "[vMenu Zone] %s (ID: %d) est entré dans '%s' à %s",
        playerName, src, zoneName, os.date("%H:%M:%S", currentTime)
    )
    print(logMessage)
    
    -- Notification aux administrateurs connectés (optionnel)
    if Config.DebugMode then
        TriggerEvent('vmenu:notifyAdmins', string.format(
            "%s est entré dans %s", playerName, zoneName
        ))
    end
end)

-- Événement déclenché quand un joueur sort d'une zone restreinte
RegisterNetEvent('vmenu:playerExitedRestrictedZone')
AddEventHandler('vmenu:playerExitedRestrictedZone', function(zoneName)
    local src = source
    local playerName = getPlayerNameCached(src)
    local currentTime = os.time()
    
    -- Vérifier que le joueur était bien enregistré dans une zone
    if playersInZones[src] then
        local timeInZone = currentTime - playersInZones[src].enterTime
        local enteredZoneName = playersInZones[src].zoneName
        
        -- Mettre à jour les statistiques
        serverStats.totalExits = serverStats.totalExits + 1
        serverStats.currentPlayersInZones = math.max(0, serverStats.currentPlayersInZones - 1)
        
        -- Mettre à jour les données de session
        if serverStats.sessionsData[src] then
            serverStats.sessionsData[src].totalTimeInZones = 
                serverStats.sessionsData[src].totalTimeInZones + timeInZone
        end
        
        -- Log de sortie avec durée
        local logMessage = string.format(
            "[vMenu Zone] %s (ID: %d) a quitté '%s' après %s",
            playerName, src, enteredZoneName, formatDuration(timeInZone)
        )
        print(logMessage)
        
        -- Supprimer le joueur de la table des zones
        playersInZones[src] = nil
        
        -- Notification aux admins si mode debug
        if Config.DebugMode then
            TriggerEvent('vmenu:notifyAdmins', string.format(
                "%s a quitté %s (durée: %s)", 
                playerName, enteredZoneName, formatDuration(timeInZone)
            ))
        end
    end
end)

-- ====================================================================
-- GESTION DES DÉCONNEXIONS
-- ====================================================================

-- Nettoyage quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerName = getPlayerNameCached(src)
    
    -- Si le joueur était dans une zone, le traiter comme une sortie
    if playersInZones[src] then
        local timeInZone = os.time() - playersInZones[src].enterTime
        local zoneName = playersInZones[src].zoneName
        
        -- Mettre à jour les statistiques
        serverStats.currentPlayersInZones = math.max(0, serverStats.currentPlayersInZones - 1)
        
        -- Log de déconnexion
        print(string.format(
            "[vMenu Zone] %s (ID: %d) s'est déconnecté depuis '%s' après %s (Raison: %s)",
            playerName, src, zoneName, formatDuration(timeInZone), reason
        ))
        
        -- Nettoyer les données
        playersInZones[src] = nil
    end
    
    -- Nettoyer le cache des noms
    playerNameCache[src] = nil
    
    -- Nettoyer les données de session après un délai (au cas où le joueur se reconnecte)
    Citizen.SetTimeout(300000, function() -- 5 minutes
        if not GetPlayerName(src) then -- Si le joueur n'est toujours pas connecté
            serverStats.sessionsData[src] = nil
        end
    end)
end)

-- ====================================================================
-- COMMANDES ADMINISTRATEUR
-- ====================================================================

-- Commande pour voir qui est actuellement dans les zones
RegisterCommand("zonestatus", function(source, args, rawCommand)
    local src = source
    
    -- Vérification des permissions
    if src > 0 and not IsPlayerAceAllowed(src, Config.AdminPermissions.zonestatus) then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Vous n'avez pas la permission d'utiliser cette commande."}
        })
        return
    end
    
    local count = 0
    local message = "=== JOUEURS DANS LES ZONES RESTREINTES ===\n"
    
    -- Parcourir tous les joueurs en zone
    for playerId, data in pairs(playersInZones) do
        local playerName = getPlayerNameCached(playerId)
        if GetPlayerName(playerId) then -- Vérifier que le joueur est toujours connecté
            local timeInZone = os.time() - data.enterTime
            message = message .. string.format(
                "• %s (ID: %d) - Zone: %s - Durée: %s\n",
                playerName, playerId, data.zoneName, formatDuration(timeInZone)
            )
            count = count + 1
        end
    end
    
    if count == 0 then
        message = "Aucun joueur actuellement dans les zones restreintes."
    else
        message = message .. string.format("\nTotal: %d joueur(s) en zone", count)
    end
    
    -- Envoyer le message
    if src == 0 then
        print(message) -- Console serveur
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {0, 255, 255},
            multiline = true,
            args = {"[Zone Status]", message}
        })
    end
end, true)

-- Commande pour voir les statistiques détaillées
RegisterCommand("zonestats", function(source, args, rawCommand)
    local src = source
    
    -- Vérification des permissions
    if src > 0 and not IsPlayerAceAllowed(src, Config.AdminPermissions.zonestats) then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Permission refusée."}
        })
        return
    end
    
    local uptime = os.time() - serverStats.startTime
    local avgSessionTime = serverStats.totalExits > 0 and 
                          (serverStats.totalEntries > 0 and "Calculé en temps réel" or "N/A") or "N/A"
    
    local message = string.format(
        "=== STATISTIQUES DES ZONES PVP ===\n" ..
        "Uptime du script: %s\n" ..
        "Entrées totales: %d\n" ..
        "Sorties totales: %d\n" ..
        "Joueurs actuellement en zone: %d\n" ..
        "Zones configurées: %d\n" ..
        "Joueurs avec données de session: %d",
        formatDuration(uptime),
        serverStats.totalEntries,
        serverStats.totalExits,
        serverStats.currentPlayersInZones,
        #Config.RestrictedZones,
        #serverStats.sessionsData
    )
    
    -- Envoyer les statistiques
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {0, 255, 0},
            multiline = true,
            args = {"[Zone Stats]", message}
        })
    end
end, true)

-- Commande pour voir les statistiques d'un joueur spécifique
RegisterCommand("playerstats", function(source, args, rawCommand)
    local src = source
    
    if src > 0 and not IsPlayerAceAllowed(src, Config.AdminPermissions.zonestats) then
        return
    end
    
    if not args[1] then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            args = {"[Usage]", "/playerstats <ID du joueur>"}
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
    
    local targetName = getPlayerNameCached(targetId)
    local sessionData = serverStats.sessionsData[targetId]
    
    if not sessionData then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            args = {"[Info]", targetName .. " n'a pas encore visité de zones."}
        })
        return
    end
    
    local zonesVisitedStr = table.concat(sessionData.zonesVisited, ", ")
    local message = string.format(
        "=== STATS DE %s (ID: %d) ===\n" ..
        "Entrées en zone: %d\n" ..
        "Temps total en zones: %s\n" ..
        "Zones visitées: %s\n" ..
        "Actuellement en zone: %s",
        targetName, targetId,
        sessionData.entriesCount,
        formatDuration(sessionData.totalTimeInZones),
        zonesVisitedStr ~= "" and zonesVisitedStr or "Aucune",
        playersInZones[targetId] and playersInZones[targetId].zoneName or "Non"
    )
    
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 165, 0},
            multiline = true,
            args = {"[Player Stats]", message}
        })
    end
end, true)

-- ====================================================================
-- SYSTÈME DE NOTIFICATIONS ADMIN
-- ====================================================================

-- Fonction pour notifier tous les administrateurs connectés
RegisterNetEvent('vmenu:notifyAdmins')
AddEventHandler('vmenu:notifyAdmins', function(message)
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if playerIdNum and IsPlayerAceAllowed(playerIdNum, Config.AdminPermissions.vmenunotify) then
            TriggerClientEvent('chat:addMessage', playerIdNum, {
                color = {255, 165, 0},
                args = {"[Zone Admin]", message}
            })
        end
    end
end)

-- ====================================================================
-- MAINTENANCE ET OPTIMISATION
-- ====================================================================

-- Thread de maintenance pour nettoyer les données obsolètes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- Toutes les 5 minutes
        
        -- Nettoyer le cache des noms de joueurs
        cleanPlayerNameCache()
        
        -- Vérifier la cohérence des données de zones
        local actualCount = 0
        for playerId, data in pairs(playersInZones) do
            if GetPlayerName(playerId) then
                actualCount = actualCount + 1
            else
                -- Joueur déconnecté mais pas nettoyé
                playersInZones[playerId] = nil
            end
        end
        
        -- Corriger le compteur si nécessaire
        if actualCount ~= serverStats.currentPlayersInZones then
            print(string.format(
                "[vMenu Zone] Correction du compteur: %d -> %d",
                serverStats.currentPlayersInZones, actualCount
            ))
            serverStats.currentPlayersInZones = actualCount
        end
    end
end)

-- ====================================================================
-- ÉVÉNEMENTS DE DÉMARRAGE ET ARRÊT
-- ====================================================================

-- Initialisation au démarrage du script
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("=== vMenu Zone Disabler Server Started ===")
        print(string.format("Zones configurées: %d", #Config.RestrictedZones))
        print(string.format("Mode debug: %s", Config.DebugMode and "Activé" or "Désactivé"))
        
        -- Réinitialiser les statistiques
        serverStats.startTime = os.time()
        serverStats.totalEntries = 0
        serverStats.totalExits = 0
        serverStats.currentPlayersInZones = 0
        playersInZones = {}
        playerNameCache = {}
    end
end)

-- Nettoyage à l'arrêt du script
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("=== vMenu Zone Disabler Server Stopped ===")
        
        -- Sauvegarder les statistiques finales si nécessaire
        local uptime = os.time() - serverStats.startTime
        print(string.format("Statistiques finales - Uptime: %s, Entrées: %d, Sorties: %d",
              formatDuration(uptime), serverStats.totalEntries, serverStats.totalExits))
    end
end)