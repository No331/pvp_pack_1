-- ====================================================================
-- CLIENT SCRIPT - vMenu Zone Disabler
-- Désactive automatiquement vMenu dans les zones PvP configurées
-- ====================================================================

-- Variables principales pour le suivi d'état
local isInRestrictedZone = false
local currentZone = nil
local zoneBlips = {}
local lastCheck = 0
local vMenuWasEnabled = true -- Mémoriser l'état initial de vMenu

-- ====================================================================
-- GESTION DES BLIPS DE ZONES
-- ====================================================================

-- Fonction pour créer les blips visuels des zones sur la carte
local function createZoneBlips()
    -- Nettoyer les anciens blips avant d'en créer de nouveaux
    removeZoneBlips()
    
    for i, zone in ipairs(Config.RestrictedZones) do
        if zone.showBlip then
            -- Créer le blip de rayon (zone circulaire)
            local radiusBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
            SetBlipColour(radiusBlip, zone.blipColor)
            SetBlipAlpha(radiusBlip, zone.blipAlpha)
            
            -- Créer le blip central avec icône et nom
            local centerBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(centerBlip, 84) -- Icône de combat/PvP
            SetBlipColour(centerBlip, zone.blipColor)
            SetBlipScale(centerBlip, 0.8)
            SetBlipAsShortRange(centerBlip, true)
            
            -- Définir le nom du blip
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(zone.name)
            EndTextCommandSetBlipName(centerBlip)
            
            -- Stocker les références des blips pour nettoyage ultérieur
            table.insert(zoneBlips, {
                radius = radiusBlip, 
                center = centerBlip,
                zoneIndex = i
            })
        end
    end
    
    if Config.DebugMode then
        print(string.format("[vMenu Zone] %d blips créés", #zoneBlips))
    end
end

-- Fonction pour supprimer tous les blips de zones
function removeZoneBlips()
    for _, blipData in ipairs(zoneBlips) do
        if DoesBlipExist(blipData.radius) then
            RemoveBlip(blipData.radius)
        end
        if DoesBlipExist(blipData.center) then
            RemoveBlip(blipData.center)
        end
    end
    zoneBlips = {}
end

-- ====================================================================
-- DÉTECTION ET GESTION DES ZONES
-- ====================================================================

-- Fonction optimisée pour vérifier si le joueur est dans une zone restreinte
local function checkPlayerInZone()
    local playerPed = PlayerPedId()
    
    -- Vérifier si le joueur existe et est valide
    if not DoesEntityExist(playerPed) then
        return
    end
    
    local playerCoords = GetEntityCoords(playerPed)
    local wasInZone = isInRestrictedZone
    local previousZone = currentZone
    local foundZone = nil
    
    -- Parcourir toutes les zones configurées pour trouver celle où se trouve le joueur
    for i, zone in ipairs(Config.RestrictedZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
            foundZone = zone
            break -- Sortir dès qu'une zone est trouvée (optimisation)
        end
    end
    
    -- Mettre à jour l'état actuel
    isInRestrictedZone = foundZone ~= nil
    currentZone = foundZone
    
    -- Gérer les changements d'état uniquement si nécessaire
    if isInRestrictedZone and not wasInZone then
        -- Le joueur vient d'entrer dans une zone restreinte
        onEnterRestrictedZone()
    elseif not isInRestrictedZone and wasInZone then
        -- Le joueur vient de sortir d'une zone restreinte
        onExitRestrictedZone(previousZone)
    elseif isInRestrictedZone and wasInZone and currentZone ~= previousZone then
        -- Le joueur a changé de zone restreinte (rare mais possible)
        onExitRestrictedZone(previousZone)
        Citizen.Wait(100) -- Petite pause pour éviter les conflits
        onEnterRestrictedZone()
    end
end

-- ====================================================================
-- ÉVÉNEMENTS D'ENTRÉE ET SORTIE DE ZONE
-- ====================================================================

-- Fonction appelée lors de l'entrée dans une zone restreinte
function onEnterRestrictedZone()
    if Config.DebugMode then
        print(string.format("[vMenu Zone] Joueur entré dans la zone: %s", 
              currentZone and currentZone.name or "Zone inconnue"))
    end
    
    -- Mémoriser l'état actuel de vMenu avant de le désactiver
    if GetResourceState('vMenu') == 'started' then
        -- Vérifier si vMenu était déjà désactivé par un autre script
        vMenuWasEnabled = not exports.vMenu:IsMenuDisabled()
    end
    
    -- Afficher une notification à l'utilisateur
    if Config.ShowNotifications then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(Config.Messages.enterZone)
        DrawNotification(false, false)
        
        -- Notification sonore optionnelle
        PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)
    end
    
    -- Déclencher l'événement personnalisé pour d'autres scripts
    TriggerEvent('vmenu:zoneRestriction', true, currentZone)
    
    -- Activer le système K/D si configuré
    if Config.EnableKDSystem then
        TriggerEvent('kd:enterPvPZone', currentZone)
    end
    
    -- Informer le serveur pour les logs et statistiques
    TriggerServerEvent('vmenu:playerEnteredRestrictedZone', 
                      currentZone and currentZone.name or "Zone inconnue")
end

-- Fonction appelée lors de la sortie d'une zone restreinte
function onExitRestrictedZone(previousZone)
    if Config.DebugMode then
        print(string.format("[vMenu Zone] Joueur sorti de la zone: %s", 
              previousZone and previousZone.name or "Zone inconnue"))
    end
    
    -- Afficher une notification de sortie
    if Config.ShowNotifications then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(Config.Messages.exitZone)
        DrawNotification(false, false)
        
        -- Son de confirmation
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    end
    
    -- Déclencher l'événement pour d'autres scripts
    TriggerEvent('vmenu:zoneRestriction', false, previousZone)
    
    -- Désactiver le système K/D si configuré
    if Config.EnableKDSystem then
        TriggerEvent('kd:exitPvPZone', previousZone)
    end
    
    -- Informer le serveur
    TriggerServerEvent('vmenu:playerExitedRestrictedZone', 
                      previousZone and previousZone.name or "Zone inconnue")
end

-- ====================================================================
-- GESTION DE LA DÉSACTIVATION DE VMENU
-- ====================================================================

-- Fonction sécurisée pour désactiver vMenu
local function disableVMenu()
    if GetResourceState('vMenu') == 'started' then
        -- Méthode principale : utiliser l'export vMenu si disponible
        if exports.vMenu and exports.vMenu.DisableMenu then
            exports.vMenu:DisableMenu(true)
        else
            -- Méthode alternative : déclencher l'événement vMenu
            TriggerEvent('vMenu:SetDisableMenu', true)
        end
        
        if Config.DebugMode then
            print("[vMenu Zone] vMenu désactivé via export/événement")
        end
    end
end

-- Fonction sécurisée pour réactiver vMenu
local function enableVMenu()
    if GetResourceState('vMenu') == 'started' and vMenuWasEnabled then
        -- Réactiver seulement si vMenu était activé avant l'entrée en zone
        if exports.vMenu and exports.vMenu.DisableMenu then
            exports.vMenu:DisableMenu(false)
        else
            TriggerEvent('vMenu:SetDisableMenu', false)
        end
        
        if Config.DebugMode then
            print("[vMenu Zone] vMenu réactivé")
        end
    end
end

-- ====================================================================
-- THREADS PRINCIPAUX
-- ====================================================================

-- Thread principal pour la vérification des zones (optimisé)
Citizen.CreateThread(function()
    -- Attendre que le joueur soit complètement chargé
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(1000)
    end
    
    -- Créer les blips des zones
    createZoneBlips()
    
    -- Boucle principale de vérification
    while true do
        local currentTime = GetGameTimer()
        
        -- Vérification avec intervalle configurable pour optimiser les performances
        if currentTime - lastCheck >= Config.CheckInterval then
            checkPlayerInZone()
            lastCheck = currentTime
        end
        
        -- Attente adaptative selon l'état
        if isInRestrictedZone then
            Citizen.Wait(Config.CheckInterval / 2) -- Vérification plus fréquente en zone
        else
            Citizen.Wait(Config.CheckInterval) -- Vérification normale hors zone
        end
    end
end)

-- Thread séparé pour la gestion des contrôles désactivés
Citizen.CreateThread(function()
    while true do
        if isInRestrictedZone then
            -- Désactiver toutes les touches configurées
            for _, control in ipairs(Config.DisabledControls) do
                DisableControlAction(0, control, true)
            end
            
            -- Désactiver spécifiquement vMenu
            disableVMenu()
            
            -- Vérification rapide pour une réactivité maximale
            Citizen.Wait(0)
        else
            -- Réactiver vMenu quand on n'est pas en zone
            enableVMenu()
            
            -- Attente plus longue pour économiser les ressources
            Citizen.Wait(500)
        end
    end
end)

-- ====================================================================
-- COMMANDES ET UTILITAIRES
-- ====================================================================

-- Commande pour vérifier le statut actuel (utile pour le debug)
RegisterCommand("checkzone", function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local status = isInRestrictedZone and "dans une zone restreinte" or "en zone libre"
    local zoneName = currentZone and currentZone.name or "Aucune"
    local vMenuStatus = GetResourceState('vMenu') == 'started' and "Démarré" or "Arrêté"
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"[Zone Check]", string.format(
            "Statut: %s\nZone actuelle: %s\nvMenu: %s\nPosition: %.1f, %.1f, %.1f",
            status, zoneName, vMenuStatus, playerCoords.x, playerCoords.y, playerCoords.z
        )}
    })
end, false)

-- Commande admin pour recharger les blips
RegisterCommand("reloadblips", function()
    if IsPlayerAceAllowed(PlayerId(), "command.reloadblips") then
        createZoneBlips()
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {"🎯 PVP MODE", "Système K/D activé - Tapez /stats pour vos statistiques"}
        })
        
        -- Déclencher l'événement pour le système K/D si activé
        if Config.EnableKDSystem then
            TriggerEvent('kd:enterPvPZone', zoneData)
        end
    end
end, false)

-- ====================================================================
-- GESTION DES ÉVÉNEMENTS SYSTÈME
-- ====================================================================

-- Nettoyage lors de l'arrêt du script
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Supprimer tous les blips
        -- Déclencher l'événement de sortie pour le système K/D
        if Config.EnableKDSystem then
            TriggerEvent('kd:exitPvPZone', zoneData)
        end
    end
end)

-- Gestion du spawn/respawn du joueur
AddEventHandler('playerSpawned', function()
    -- Réinitialiser les variables d'état
    isInRestrictedZone = false
    currentZone = nil
    vMenuWasEnabled = true
    
    -- Recréer les blips si nécessaire
    Citizen.SetTimeout(2000, function() -- Délai pour s'assurer que tout est chargé
        if #zoneBlips == 0 then
            createZoneBlips()
        end
    end)
    
    if Config.DebugMode then
        print("[vMenu Zone] Joueur spawné - Variables réinitialisées")
    end
end)

-- Gestion de la reconnexion réseau
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Attendre un peu que tout soit initialisé
        Citizen.SetTimeout(1000, function()
            createZoneBlips()
        end)
    end
end)

-- Événement pour forcer la vérification (utilisable par d'autres scripts)
RegisterNetEvent('vmenu:forceZoneCheck')
AddEventHandler('vmenu:forceZoneCheck', function()
    checkPlayerInZone()
end)

-- ====================================================================
-- EXPORTS POUR D'AUTRES SCRIPTS
-- ====================================================================

-- Export pour vérifier si le joueur est en zone restreinte
exports('isPlayerInRestrictedZone', function()
    return isInRestrictedZone
end)

-- Export pour obtenir la zone actuelle
exports('getCurrentZone', function()
    return currentZone
end)

-- Export pour forcer la vérification des zones
exports('forceZoneCheck', function()
    checkPlayerInZone()
end)