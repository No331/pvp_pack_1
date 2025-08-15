-- ====================================================================
-- CLIENT KD SYSTEM - Système moderne de compteur Kill/Death/K/D
-- Interface utilisateur et gestion des statistiques côté client
-- ====================================================================

-- Variables pour les statistiques du joueur
local playerStats = {
    kills = 0,
    deaths = 0,
    assists = 0,
    streak = 0,
    bestStreak = 0,
    totalDamageDealt = 0,
    totalDamageReceived = 0,
    timeInPvP = 0,
    lastKillTime = 0,
    sessionStart = GetGameTimer()
}

-- Variables pour l'interface utilisateur
local showKDHud = false
local hudPosition = {x = 0.02, y = 0.02} -- Position en pourcentage de l'écran
local lastDamageTime = 0
local damageIndicators = {}
local killFeedMessages = {}

-- Configuration de l'interface
local hudConfig = {
    backgroundColor = {0, 0, 0, 180},
    primaryColor = {255, 255, 255, 255},
    killColor = {46, 204, 113, 255},
    deathColor = {231, 76, 60, 255},
    assistColor = {52, 152, 219, 255},
    streakColor = {241, 196, 15, 255},
    font = 4,
    scale = 0.4
}

-- ====================================================================
-- FONCTIONS UTILITAIRES
-- ====================================================================

-- Calculer le ratio K/D avec gestion des divisions par zéro
local function calculateKD()
    if playerStats.deaths == 0 then
        return playerStats.kills > 0 and playerStats.kills or 0
    end
    return math.floor((playerStats.kills / playerStats.deaths) * 100) / 100
end

-- Calculer le KDA (Kill/Death/Assist ratio)
local function calculateKDA()
    if playerStats.deaths == 0 then
        return (playerStats.kills + playerStats.assists) > 0 and (playerStats.kills + playerStats.assists) or 0
    end
    return math.floor(((playerStats.kills + playerStats.assists) / playerStats.deaths) * 100) / 100
end

-- Obtenir la couleur selon le ratio K/D
local function getKDColor(ratio)
    if ratio >= 2.0 then
        return {46, 204, 113, 255} -- Vert excellent
    elseif ratio >= 1.5 then
        return {241, 196, 15, 255} -- Jaune bon
    elseif ratio >= 1.0 then
        return {230, 126, 34, 255} -- Orange moyen
    else
        return {231, 76, 60, 255} -- Rouge faible
    end
end

-- Formater le temps de session
local function formatSessionTime()
    local sessionTime = (GetGameTimer() - playerStats.sessionStart) / 1000
    local hours = math.floor(sessionTime / 3600)
    local minutes = math.floor((sessionTime % 3600) / 60)
    local seconds = math.floor(sessionTime % 60)
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%02d:%02d", minutes, seconds)
    end
end

-- ====================================================================
-- SYSTÈME D'AFFICHAGE HUD
-- ====================================================================

-- Dessiner le HUD principal des statistiques
local function drawKDHud()
    if not showKDHud then return end
    
    local x, y = hudPosition.x, hudPosition.y
    local kd = calculateKD()
    local kda = calculateKDA()
    local kdColor = getKDColor(kd)
    
    -- Fond du HUD avec bordure moderne
    DrawRect(x + 0.08, y + 0.06, 0.16, 0.12, 
             hudConfig.backgroundColor[1], hudConfig.backgroundColor[2], 
             hudConfig.backgroundColor[3], hudConfig.backgroundColor[4])
    
    -- Bordure gradient
    DrawRect(x + 0.08, y + 0.001, 0.16, 0.002, 
             kdColor[1], kdColor[2], kdColor[3], 200)
    
    -- Titre principal
    SetTextFont(hudConfig.font)
    SetTextProportional(1)
    SetTextScale(0.0, hudConfig.scale + 0.1)
    SetTextColour(hudConfig.primaryColor[1], hudConfig.primaryColor[2], 
                  hudConfig.primaryColor[3], hudConfig.primaryColor[4])
    SetTextEntry("STRING")
    AddTextComponentString("🎯 STATS PVP")
    DrawText(x + 0.01, y + 0.01)
    
    -- Statistiques principales
    local yOffset = 0.03
    
    -- Kills
    SetTextScale(0.0, hudConfig.scale)
    SetTextColour(hudConfig.killColor[1], hudConfig.killColor[2], 
                  hudConfig.killColor[3], hudConfig.killColor[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("💀 Kills: %d", playerStats.kills))
    DrawText(x + 0.01, y + yOffset)
    
    -- Deaths
    yOffset = yOffset + 0.02
    SetTextColour(hudConfig.deathColor[1], hudConfig.deathColor[2], 
                  hudConfig.deathColor[3], hudConfig.deathColor[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("☠️ Deaths: %d", playerStats.deaths))
    DrawText(x + 0.01, y + yOffset)
    
    -- Assists
    yOffset = yOffset + 0.02
    SetTextColour(hudConfig.assistColor[1], hudConfig.assistColor[2], 
                  hudConfig.assistColor[3], hudConfig.assistColor[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("🤝 Assists: %d", playerStats.assists))
    DrawText(x + 0.01, y + yOffset)
    
    -- K/D Ratio
    yOffset = yOffset + 0.02
    SetTextColour(kdColor[1], kdColor[2], kdColor[3], kdColor[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("📊 K/D: %.2f", kd))
    DrawText(x + 0.01, y + yOffset)
    
    -- KDA Ratio
    yOffset = yOffset + 0.02
    SetTextColour(hudConfig.primaryColor[1], hudConfig.primaryColor[2], 
                  hudConfig.primaryColor[3], hudConfig.primaryColor[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("📈 KDA: %.2f", kda))
    DrawText(x + 0.01, y + yOffset)
    
    -- Streak actuelle
    if playerStats.streak > 0 then
        yOffset = yOffset + 0.02
        SetTextColour(hudConfig.streakColor[1], hudConfig.streakColor[2], 
                      hudConfig.streakColor[3], hudConfig.streakColor[4])
        SetTextEntry("STRING")
        AddTextComponentString(string.format("🔥 Streak: %d", playerStats.streak))
        DrawText(x + 0.01, y + yOffset)
    end
    
    -- Temps de session (coin droit)
    SetTextScale(0.0, hudConfig.scale - 0.05)
    SetTextColour(200, 200, 200, 200)
    SetTextEntry("STRING")
    AddTextComponentString(formatSessionTime())
    DrawText(x + 0.12, y + 0.01)
end

-- Dessiner les indicateurs de dégâts
local function drawDamageIndicators()
    local currentTime = GetGameTimer()
    
    for i = #damageIndicators, 1, -1 do
        local indicator = damageIndicators[i]
        local timeDiff = currentTime - indicator.time
        
        if timeDiff > 2000 then -- Supprimer après 2 secondes
            table.remove(damageIndicators, i)
        else
            local alpha = math.max(0, 255 - (timeDiff / 2000 * 255))
            local yOffset = timeDiff / 2000 * 0.05 -- Animation vers le haut
            
            SetTextFont(4)
            SetTextScale(0.0, 0.5)
            SetTextColour(indicator.color[1], indicator.color[2], 
                          indicator.color[3], alpha)
            SetTextEntry("STRING")
            AddTextComponentString(indicator.text)
            DrawText(indicator.x, indicator.y - yOffset)
        end
    end
end

-- Dessiner le kill feed
local function drawKillFeed()
    local currentTime = GetGameTimer()
    local yStart = 0.3
    
    for i = #killFeedMessages, 1, -1 do
        local message = killFeedMessages[i]
        local timeDiff = currentTime - message.time
        
        if timeDiff > 5000 then -- Supprimer après 5 secondes
            table.remove(killFeedMessages, i)
        else
            local alpha = math.max(0, 255 - (timeDiff / 5000 * 255))
            local yPos = yStart + ((#killFeedMessages - i) * 0.03)
            
            -- Fond du message
            DrawRect(0.85, yPos + 0.01, 0.28, 0.025, 0, 0, 0, alpha * 0.7)
            
            SetTextFont(4)
            SetTextScale(0.0, 0.35)
            SetTextColour(message.color[1], message.color[2], 
                          message.color[3], alpha)
            SetTextEntry("STRING")
            AddTextComponentString(message.text)
            DrawText(0.72, yPos)
        end
    end
end

-- ====================================================================
-- GESTION DES ÉVÉNEMENTS DE COMBAT
-- ====================================================================

-- Événement déclenché lors d'un kill
RegisterNetEvent('kd:onKill')
AddEventHandler('kd:onKill', function(victimName, weapon, headshot, distance)
    playerStats.kills = playerStats.kills + 1
    playerStats.streak = playerStats.streak + 1
    playerStats.lastKillTime = GetGameTimer()
    
    if playerStats.streak > playerStats.bestStreak then
        playerStats.bestStreak = playerStats.streak
    end
    
    -- Effet sonore de kill
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    
    -- Message de kill feed
    local killMessage = string.format("💀 %s", victimName or "Joueur")
    if headshot then
        killMessage = killMessage .. " 🎯"
    end
    if distance and distance > 50 then
        killMessage = killMessage .. string.format(" (%.0fm)", distance)
    end
    
    table.insert(killFeedMessages, {
        text = killMessage,
        time = GetGameTimer(),
        color = hudConfig.killColor
    })
    
    -- Indicateur de dégâts pour le kill
    table.insert(damageIndicators, {
        text = "KILL!",
        x = 0.5,
        y = 0.5,
        time = GetGameTimer(),
        color = hudConfig.killColor
    })
    
    -- Notification de streak
    if playerStats.streak > 1 and playerStats.streak % 5 == 0 then
        TriggerEvent('chat:addMessage', {
            color = {241, 196, 15},
            args = {"🔥 STREAK", string.format("Série de %d kills!", playerStats.streak)}
        })
        PlaySoundFrontend(-1, "MEDAL_BRONZE", "HUD_AWARDS", 1)
    end
    
    -- Sauvegarder les statistiques
    TriggerServerEvent('kd:updateStats', playerStats)
end)

-- Événement déclenché lors d'une mort
RegisterNetEvent('kd:onDeath')
AddEventHandler('kd:onDeath', function(killerName, weapon, headshot)
    playerStats.deaths = playerStats.deaths + 1
    
    -- Réinitialiser la streak si elle était > 0
    if playerStats.streak > 0 then
        local lostStreak = playerStats.streak
        playerStats.streak = 0
        
        if lostStreak >= 5 then
            TriggerEvent('chat:addMessage', {
                color = {231, 76, 60},
                args = {"💔 STREAK PERDUE", string.format("Série de %d kills terminée", lostStreak)}
            })
        end
    end
    
    -- Effet sonore de mort
    PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", 1)
    
    -- Message de kill feed
    local deathMessage = string.format("☠️ Tué par %s", killerName or "Joueur")
    if headshot then
        deathMessage = deathMessage .. " 🎯"
    end
    
    table.insert(killFeedMessages, {
        text = deathMessage,
        time = GetGameTimer(),
        color = hudConfig.deathColor
    })
    
    -- Indicateur de mort
    table.insert(damageIndicators, {
        text = "MORT",
        x = 0.5,
        y = 0.5,
        time = GetGameTimer(),
        color = hudConfig.deathColor
    })
    
    -- Sauvegarder les statistiques
    TriggerServerEvent('kd:updateStats', playerStats)
end)

-- Événement déclenché lors d'une assistance
RegisterNetEvent('kd:onAssist')
AddEventHandler('kd:onAssist', function(victimName, damage)
    playerStats.assists = playerStats.assists + 1
    
    -- Message de kill feed
    local assistMessage = string.format("🤝 Assistance sur %s", victimName or "Joueur")
    
    table.insert(killFeedMessages, {
        text = assistMessage,
        time = GetGameTimer(),
        color = hudConfig.assistColor
    })
    
    -- Indicateur d'assistance
    table.insert(damageIndicators, {
        text = "ASSIST!",
        x = 0.5,
        y = 0.45,
        time = GetGameTimer(),
        color = hudConfig.assistColor
    })
    
    -- Son d'assistance
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)
    
    -- Sauvegarder les statistiques
    TriggerServerEvent('kd:updateStats', playerStats)
end)

-- ====================================================================
-- GESTION DE L'AFFICHAGE SELON LES ZONES
-- ====================================================================

-- Événement de changement de zone (intégration avec le système existant)
AddEventHandler('vmenu:zoneRestriction', function(inZone, zoneData)
    showKDHud = inZone
    
    if inZone then
        -- Réinitialiser le temps de session PvP
        playerStats.sessionStart = GetGameTimer()
        
        -- Notification d'entrée en mode PvP
        TriggerEvent('chat:addMessage', {
            color = {52, 152, 219},
            args = {"🎯 PVP MODE", "Statistiques K/D activées"}
        })
    else
        -- Calculer le temps passé en PvP
        local sessionTime = (GetGameTimer() - playerStats.sessionStart) / 1000
        playerStats.timeInPvP = playerStats.timeInPvP + sessionTime
        
        -- Afficher un résumé de session si des actions ont eu lieu
        if playerStats.kills > 0 or playerStats.deaths > 0 then
            local kd = calculateKD()
            TriggerEvent('chat:addMessage', {
                color = {46, 204, 113},
                multiline = true,
                args = {"📊 RÉSUMÉ SESSION", string.format(
                    "Kills: %d | Deaths: %d | K/D: %.2f\nTemps: %s",
                    playerStats.kills, playerStats.deaths, kd, formatSessionTime()
                )}
            })
        end
    end
end)

-- ====================================================================
-- THREADS D'AFFICHAGE
-- ====================================================================

-- Thread principal pour l'affichage du HUD
Citizen.CreateThread(function()
    while true do
        if showKDHud then
            drawKDHud()
            drawDamageIndicators()
            drawKillFeed()
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- Thread pour la détection des dégâts et kills
Citizen.CreateThread(function()
    while true do
        if showKDHud then
            local playerPed = PlayerPedId()
            
            -- Vérifier si le joueur a été tué
            if IsEntityDead(playerPed) then
                local killer = GetPedSourceOfDeath(playerPed)
                local killerPlayer = nil
                local weapon = GetPedCauseOfDeath(playerPed)
                
                -- Trouver le joueur qui a tué
                for _, playerId in ipairs(GetActivePlayers()) do
                    if GetPlayerPed(playerId) == killer then
                        killerPlayer = GetPlayerName(playerId)
                        break
                    end
                end
                
                -- Vérifier si c'est un headshot
                local headshot = HasEntityBeenDamagedByWeapon(playerPed, weapon, 2) -- Head component
                
                TriggerEvent('kd:onDeath', killerPlayer, weapon, headshot)
                
                -- Attendre la réapparition
                while IsEntityDead(playerPed) do
                    Citizen.Wait(1000)
                end
            end
            
            Citizen.Wait(100)
        else
            Citizen.Wait(1000)
        end
    end
end)

-- ====================================================================
-- COMMANDES UTILISATEUR
-- ====================================================================

-- Commande pour afficher les statistiques détaillées
RegisterCommand("stats", function()
    local kd = calculateKD()
    local kda = calculateKDA()
    local sessionTime = formatSessionTime()
    
    TriggerEvent('chat:addMessage', {
        color = {52, 152, 219},
        multiline = true,
        args = {"📊 MES STATISTIQUES", string.format(
            "💀 Kills: %d | ☠️ Deaths: %d | 🤝 Assists: %d\n" ..
            "📊 K/D: %.2f | 📈 KDA: %.2f\n" ..
            "🔥 Streak: %d | 🏆 Meilleure: %d\n" ..
            "⏱️ Session: %s",
            playerStats.kills, playerStats.deaths, playerStats.assists,
            kd, kda, playerStats.streak, playerStats.bestStreak, sessionTime
        )}
    })
end, false)

-- Commande pour réinitialiser les statistiques de session
RegisterCommand("resetstats", function()
    playerStats.kills = 0
    playerStats.deaths = 0
    playerStats.assists = 0
    playerStats.streak = 0
    playerStats.sessionStart = GetGameTimer()
    
    TriggerEvent('chat:addMessage', {
        color = {241, 196, 15},
        args = {"🔄 RESET", "Statistiques de session réinitialisées"}
    })
end, false)

-- Commande pour basculer l'affichage du HUD
RegisterCommand("togglekd", function()
    showKDHud = not showKDHud
    TriggerEvent('chat:addMessage', {
        color = {52, 152, 219},
        args = {"🎯 HUD K/D", showKDHud and "Activé" or "Désactivé"}
    })
end, false)

-- ====================================================================
-- INITIALISATION ET NETTOYAGE
-- ====================================================================

-- Charger les statistiques sauvegardées au démarrage
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('kd:loadStats')
end)

-- Événement pour recevoir les statistiques du serveur
RegisterNetEvent('kd:receiveStats')
AddEventHandler('kd:receiveStats', function(stats)
    if stats then
        playerStats.kills = stats.kills or 0
        playerStats.deaths = stats.deaths or 0
        playerStats.assists = stats.assists or 0
        playerStats.bestStreak = stats.bestStreak or 0
        playerStats.timeInPvP = stats.timeInPvP or 0
        playerStats.totalDamageDealt = stats.totalDamageDealt or 0
        playerStats.totalDamageReceived = stats.totalDamageReceived or 0
    end
end)

-- Nettoyage à l'arrêt du script
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Sauvegarder les statistiques finales
        TriggerServerEvent('kd:updateStats', playerStats)
    end
end)