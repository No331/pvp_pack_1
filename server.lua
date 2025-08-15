-- Script serveur pour la gestion des logs et événements

-- Table pour suivre les joueurs dans les zones restreintes
local playersInZones = {}

-- Événement quand un joueur entre dans une zone restreinte
RegisterNetEvent('vmenu:playerEnteredRestrictedZone')
AddEventHandler('vmenu:playerEnteredRestrictedZone', function(zoneName)
    local src = source
    local playerName = GetPlayerName(src)
    
    -- Enregistrer le joueur comme étant dans une zone
    playersInZones[src] = {
        zoneName = zoneName,
        enterTime = os.time()
    }
    
    -- Log pour les administrateurs
    print(string.format("[vMenu Zone] %s (ID: %d) est entré dans la zone: %s", 
          playerName, src, zoneName))
    
    -- Optionnel: Envoyer une notification aux admins connectés
    TriggerEvent('vmenu:notifyAdmins', playerName .. " est entré dans " .. zoneName)
end)

-- Événement quand un joueur sort d'une zone restreinte
RegisterNetEvent('vmenu:playerExitedRestrictedZone')
AddEventHandler('vmenu:playerExitedRestrictedZone', function()
    local src = source
    local playerName = GetPlayerName(src)
    
    if playersInZones[src] then
        local timeInZone = os.time() - playersInZones[src].enterTime
        local zoneName = playersInZones[src].zoneName
        
        -- Log de sortie
        print(string.format("[vMenu Zone] %s (ID: %d) a quitté la zone: %s (Durée: %d secondes)", 
              playerName, src, zoneName, timeInZone))
        
        -- Supprimer de la table
        playersInZones[src] = nil
    end
end)

-- Nettoyage quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local src = source
    if playersInZones[src] then
        local playerName = GetPlayerName(src)
        local zoneName = playersInZones[src].zoneName
        
        print(string.format("[vMenu Zone] %s (ID: %d) s'est déconnecté depuis la zone: %s", 
              playerName, src, zoneName))
        
        playersInZones[src] = nil
    end
end)

-- Commande admin pour voir qui est dans les zones
RegisterCommand("zonestatus", function(source, args, rawCommand)
    local src = source
    
    -- Vérifier si c'est un admin (vous pouvez adapter selon votre système de permissions)
    if not IsPlayerAceAllowed(src, "command.zonestatus") then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[Erreur]", "Vous n'avez pas la permission d'utiliser cette commande."}
        })
        return
    end
    
    local count = 0
    local message = "Joueurs dans les zones restreintes:\n"
    
    for playerId, data in pairs(playersInZones) do
        local playerName = GetPlayerName(playerId)
        if playerName then
            local timeInZone = os.time() - data.enterTime
            message = message .. string.format("- %s (ID: %d) dans %s depuis %d secondes\n", 
                     playerName, playerId, data.zoneName, timeInZone)
            count = count + 1
        end
    end
    
    if count == 0 then
        message = "Aucun joueur dans les zones restreintes."
    end
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {0, 255, 255},
        args = {"[Zone Status]", message}
    })
end, true) -- true = commande restreinte

-- Fonction utilitaire pour notifier les admins (optionnelle)
RegisterNetEvent('vmenu:notifyAdmins')
AddEventHandler('vmenu:notifyAdmins', function(message)
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        -- Vérifier si le joueur est admin
        if IsPlayerAceAllowed(playerId, "vmenu.notify") then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 165, 0},
                args = {"[Zone Admin]", message}
            })
        end
    end
end)

-- Statistiques et monitoring
local zoneStats = {
    totalEntries = 0,
    totalExits = 0,
    currentPlayers = 0
}

-- Mise à jour des statistiques
AddEventHandler('vmenu:playerEnteredRestrictedZone', function()
    zoneStats.totalEntries = zoneStats.totalEntries + 1
    zoneStats.currentPlayers = zoneStats.currentPlayers + 1
end)

AddEventHandler('vmenu:playerExitedRestrictedZone', function()
    zoneStats.totalExits = zoneStats.totalExits + 1
    zoneStats.currentPlayers = math.max(0, zoneStats.currentPlayers - 1)
end)

-- Commande pour voir les statistiques
RegisterCommand("zonestats", function(source, args, rawCommand)
    local src = source
    
    if not IsPlayerAceAllowed(src, "command.zonestats") then
        return
    end
    
    local message = string.format(
        "Statistiques des zones:\n" ..
        "- Entrées totales: %d\n" ..
        "- Sorties totales: %d\n" ..
        "- Joueurs actuels: %d",
        zoneStats.totalEntries,
        zoneStats.totalExits,
        zoneStats.currentPlayers
    )
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {0, 255, 0},
        args = {"[Zone Stats]", message}
    })
end, true)