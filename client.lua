-- Variables principales
local isInRestrictedZone = false
local currentZone = nil
local zoneBlips = {}
local lastCheck = 0

-- Fonction pour créer les blips des zones
local function createZoneBlips()
    for i, zone in ipairs(Config.RestrictedZones) do
        if zone.showBlip then
            local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
            SetBlipColour(blip, zone.blipColor)
            SetBlipAlpha(blip, zone.blipAlpha)
            
            -- Blip central pour le nom
            local centerBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(centerBlip, 84) -- Icône de combat
            SetBlipColour(centerBlip, zone.blipColor)
            SetBlipScale(centerBlip, 0.8)
            SetBlipAsShortRange(centerBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(zone.name)
            EndTextCommandSetBlipName(centerBlip)
            
            table.insert(zoneBlips, {radius = blip, center = centerBlip})
        end
    end
end

-- Fonction pour supprimer les blips
local function removeZoneBlips()
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

-- Fonction pour vérifier si le joueur est dans une zone restreinte
local function checkPlayerInZone()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local wasInZone = isInRestrictedZone
    local foundZone = nil
    
    -- Vérifier chaque zone configurée
    for i, zone in ipairs(Config.RestrictedZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
            foundZone = zone
            break
        end
    end
    
    -- Mise à jour du statut
    isInRestrictedZone = foundZone ~= nil
    currentZone = foundZone
    
    -- Gestion des changements d'état
    if isInRestrictedZone and not wasInZone then
        -- Entrée dans une zone restreinte
        onEnterRestrictedZone()
    elseif not isInRestrictedZone and wasInZone then
        -- Sortie d'une zone restreinte
        onExitRestrictedZone()
    end
end

-- Fonction appelée lors de l'entrée dans une zone
function onEnterRestrictedZone()
    if Config.DebugMode then
        print("[vMenu Zone] Joueur entré dans la zone: " .. (currentZone and currentZone.name or "Inconnue"))
    end
    
    -- Notification
    if Config.ShowNotifications then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(Config.Messages.enterZone)
        DrawNotification(false, false)
    end
    
    -- Déclencher l'événement pour d'autres scripts si nécessaire
    TriggerEvent('vmenu:zoneRestriction', true, currentZone)
    
    -- Informer le serveur (optionnel pour logs)
    TriggerServerEvent('vmenu:playerEnteredRestrictedZone', currentZone and currentZone.name or "Zone inconnue")
end

-- Fonction appelée lors de la sortie d'une zone
function onExitRestrictedZone()
    if Config.DebugMode then
        print("[vMenu Zone] Joueur sorti de la zone restreinte")
    end
    
    -- Notification
    if Config.ShowNotifications then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(Config.Messages.exitZone)
        DrawNotification(false, false)
    end
    
    -- Déclencher l'événement pour d'autres scripts
    TriggerEvent('vmenu:zoneRestriction', false, nil)
    
    -- Informer le serveur (optionnel pour logs)
    TriggerServerEvent('vmenu:playerExitedRestrictedZone')
end

-- Thread principal pour la vérification des zones
Citizen.CreateThread(function()
    -- Créer les blips au démarrage
    createZoneBlips()
    
    while true do
        local currentTime = GetGameTimer()
        
        -- Vérification optimisée avec intervalle configurable
        if currentTime - lastCheck >= Config.CheckInterval then
            checkPlayerInZone()
            lastCheck = currentTime
        end
        
        Citizen.Wait(100) -- Attente minimale pour éviter la surcharge
    end
end)

-- Thread pour désactiver les contrôles quand en zone restreinte
Citizen.CreateThread(function()
    while true do
        if isInRestrictedZone then
            -- Désactiver toutes les touches configurées
            for _, control in ipairs(Config.DisabledControls) do
                DisableControlAction(0, control, true)
            end
            
            -- Désactiver spécifiquement vMenu si détecté
            if GetResourceState('vMenu') == 'started' then
                TriggerEvent('vMenu:disableMenu', true)
            end
            
            -- Attente réduite quand en zone pour une réactivité maximale
            Citizen.Wait(0)
        else
            -- Réactiver vMenu si on n'est pas en zone
            if GetResourceState('vMenu') == 'started' then
                TriggerEvent('vMenu:disableMenu', false)
            end
            
            -- Attente plus longue quand pas en zone pour économiser les ressources
            Citizen.Wait(500)
        end
    end
end)

-- Commande pour vérifier le statut (debug)
RegisterCommand("checkzone", function()
    local status = isInRestrictedZone and "dans une zone restreinte" or "en zone libre"
    local zoneName = currentZone and currentZone.name or "Aucune"
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        args = {"[Zone Check]", "Statut: " .. status .. " | Zone: " .. zoneName}
    })
end, false)

-- Nettoyage lors de l'arrêt du script
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Supprimer les blips
        removeZoneBlips()
        
        -- Réactiver vMenu au cas où
        if GetResourceState('vMenu') == 'started' then
            TriggerEvent('vMenu:disableMenu', false)
        end
        
        if Config.DebugMode then
            print("[vMenu Zone] Script arrêté - vMenu réactivé")
        end
    end
end)

-- Gestion de la reconnexion du joueur
AddEventHandler('playerSpawned', function()
    -- Réinitialiser les variables
    isInRestrictedZone = false
    currentZone = nil
    
    -- Recréer les blips si nécessaire
    if #zoneBlips == 0 then
        createZoneBlips()
    end
    
    if Config.DebugMode then
        print("[vMenu Zone] Joueur spawné - Variables réinitialisées")
    end
end)