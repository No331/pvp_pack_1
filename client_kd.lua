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
    multikills = 0,
    headshots = 0,
    totalDamageDealt = 0,
    totalDamageReceived = 0,
    timeInPvP = 0,
    lastKillTime = 0,
    sessionStart = GetGameTimer(),
    lastMultikillTime = 0
}

-- Variables pour l'interface utilisateur
local showKDHud = false
local hudPosition = Config.KDHud.position
local lastDamageTime = 0
local damageIndicators = {}
local killFeedMessages = {}
local streakMessages = {}
local isInPvPZone = false

-- Configuration de l'interface depuis config.lua
local hudConfig = Config.KDHud

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
        return hudConfig.colors.excellent
    elseif ratio >= 1.5 then
        return hudConfig.colors.good
    elseif ratio >= 1.0 then
        return hudConfig.colors.average
    else
        return hudConfig.colors.poor
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

-- Vérifier si c'est un multikill
local function checkMultikill()
    local currentTime = GetGameTimer()
    if currentTime - playerStats.lastKillTime < 4000 then -- 4 secondes pour multikill
        playerStats.multikills = playerStats.multikills + 1
        playerStats.lastMultikillTime = currentTime
        return true
    end
    return false
end

-- ====================================================================
-- SYSTÈME D'AFFICHAGE HUD
-- ====================================================================

-- Dessiner le HUD principal des statistiques
local function drawKDHud()
    if not showKDHud or not isInPvPZone then return end
    
    local x, y = hudPosition.x, hudPosition.y
    local kd = calculateKD()
    local kda = calculateKDA()
    local kdColor = getKDColor(kd)
    
    -- Calculer la hauteur dynamique selon le contenu
    local hudHeight = 0.12
    if playerStats.streak > 0 then
        hudHeight = hudHeight + 0.02
    end
    if playerStats.headshots > 0 then
        hudHeight = hudHeight + 0.02
    end
    
    -- Fond du HUD avec bordure moderne et effet de transparence
    DrawRect(x + 0.08, y + hudHeight/2, 0.16, hudHeight, 
             hudConfig.colors.background[1], hudConfig.colors.background[2], 
             hudConfig.colors.background[3], hudConfig.colors.background[4])
    
    -- Bordure gradient dynamique selon performance
    DrawRect(x + 0.08, y + 0.001, 0.16, 0.003, 
             kdColor[1], kdColor[2], kdColor[3], 200)
    
    -- Titre principal
    SetTextFont(hudConfig.font)
    SetTextProportional(1)
    SetTextScale(0.0, hudConfig.scale + 0.05)
    SetTextColour(hudConfig.colors.primary[1], hudConfig.colors.primary[2], 
                  hudConfig.colors.primary[3], hudConfig.colors.primary[4])
    SetTextEntry("STRING")
    AddTextComponentString("🎯 PVP STATS")
    DrawText(x + 0.01, y + 0.01)
    
    -- Statistiques principales
    local yOffset = 0.025
    
    -- Kills
    SetTextScale(0.0, hudConfig.scale)
    local killAlpha = 255
    if GetGameTimer() - playerStats.lastKillTime < 2000 then
        killAlpha = math.floor(255 * (math.sin(GetGameTimer() / 100) + 1) / 2) + 128
    end
    SetTextColour(hudConfig.colors.kills[1], hudConfig.colors.kills[2], 
                  hudConfig.colors.kills[3], killAlpha)
    SetTextEntry("STRING")
    AddTextComponentString(string.format("💀 Kills: %d", playerStats.kills))
    DrawText(x + 0.01, y + yOffset)
    
    -- Deaths
    yOffset = yOffset + 0.018
    SetTextColour(hudConfig.colors.deaths[1], hudConfig.colors.deaths[2], 
                  hudConfig.colors.deaths[3], hudConfig.colors.deaths[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("☠️ Deaths: %d", playerStats.deaths))
    DrawText(x + 0.01, y + yOffset)
    
    -- Assists
    yOffset = yOffset + 0.018
    SetTextColour(hudConfig.colors.assists[1], hudConfig.colors.assists[2], 
                  hudConfig.colors.assists[3], hudConfig.colors.assists[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("🤝 Assists: %d", playerStats.assists))
    DrawText(x + 0.01, y + yOffset)
    
    -- K/D Ratio
    yOffset = yOffset + 0.018
    SetTextColour(kdColor[1], kdColor[2], kdColor[3], kdColor[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("📊 K/D: %.2f", kd))
    DrawText(x + 0.01, y + yOffset)
    
    -- KDA Ratio
    yOffset = yOffset + 0.018
    SetTextColour(hudConfig.colors.primary[1], hudConfig.colors.primary[2], 
                  hudConfig.colors.primary[3], hudConfig.colors.primary[4])
    SetTextEntry("STRING")
    AddTextComponentString(string.format("📈 KDA: %.2f", kda))
    DrawText(x + 0.01, y + yOffset)
    
    -- Streak actuelle
    if playerStats.streak > 0 then
        yOffset = yOffset + 0.018
        local streakAlpha = 255
        if playerStats.streak >= 5 then
            streakAlpha = math.floor(255 * (math.sin(GetGameTimer() / 150) + 1) / 2) + 128
        end
        SetTextColour(hudConfig.colors.streak[1], hudConfig.colors.streak[2], 
                      hudConfig.colors.streak[3], streakAlpha)
        SetTextEntry("STRING")
        AddTextComponentString(string.format("🔥 Streak: %d", playerStats.streak))
        DrawText(x + 0.01, y + yOffset)
    end
    
    -- Headshots si présents
    if playerStats.headshots > 0 then
        yOffset = yOffset + 0.018
        SetTextColour(hudConfig.colors.streak[1], hudConfig.colors.streak[2], 
                      hudConfig.colors.streak[3], 200)
        SetTextEntry("STRING")
        AddTextComponentString(string.format("🎯 Headshots: %d", playerStats.headshots))
        DrawText(x + 0.01, y + yOffset)
    end
    
    -- Temps de session (coin droit)
    SetTextScale(0.0, hudConfig.scale - 0.08)
    SetTextColour(200, 200, 200, 200)
    SetTextEntry("STRING")
    AddTextComponentString(formatSessionTime())
    DrawText(x + 0.11, y + 0.008)
end

-- Dessiner les indicateurs de dégâts
local function drawDamageIndicators()
    local currentTime = GetGameTimer()
    
    for i = #damageIndicators, 1, -1 do
        local indicator = damageIndicators[i]
        local timeDiff = currentTime - indicator.startTime
        
        if timeDiff > hudConfig.damageIndicatorDuration then
            table.remove(damageIndicators, i)
        else
            local alpha = math.max(0, 255 - (timeDiff / hudConfig.damageIndicatorDuration * 255))
            local yOffset = timeDiff / hudConfig.damageIndicatorDuration * 0.08
            local scale = 0.5 + (timeDiff / hudConfig.damageIndicatorDuration * 0.2)
            
            SetTextFont(4)
            SetTextScale(0.0, scale)
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
    local yStart = 0.25
    
    for i = #killFeedMessages, 1, -1 do
        local message = killFeedMessages[i]
        local timeDiff = currentTime - message.startTime
        
        if timeDiff > hudConfig.killFeedDuration then
            table.remove(killFeedMessages, i)
        else
            local alpha = math.max(0, 255 - (timeDiff / hudConfig.killFeedDuration * 255))
            local yPos = yStart + ((#killFeedMessages - i) * 0.025)
            
            -- Fond du message
            DrawRect(0.85, yPos + 0.0125, 0.28, 0.025, 0, 0, 0, math.floor(alpha * 0.8))
            
            SetTextFont(4)
            SetTextScale(0.0, 0.32)
            SetTextColour(message.color[1], message.color[2], 
                          message.color[3], alpha)
            SetTextEntry("STRING")
            AddTextComponentString(message.text)
            DrawText(0.72, yPos)
        end
    end
end

-- Dessiner les messages de streak
local function drawStreakMessages()
    local currentTime = GetGameTimer()
    
    for i = #streakMessages, 1, -1 do
        local message = streakMessages[i]
        local timeDiff = currentTime - message.startTime
        
        if timeDiff > 3000 then
            table.remove(streakMessages, i)
        else
            local alpha = math.max(0, 255 - (timeDiff / 3000 * 255))
            local scale = 0.8 + (math.sin(timeDiff / 100) * 0.1)
            
            SetTextFont(4)
            SetTextScale(0.0, scale)
            SetTextColour(message.color[1], message.color[2], 
                          message.color[3], alpha)
            SetTextEntry("STRING")
            AddTextComponentString(message.text)
            DrawText(0.5 - (string.len(message.text) * 0.01), 0.3)
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
    local currentTime = GetGameTimer()
    
    -- Vérifier les headshots
    if headshot then
        playerStats.headshots = playerStats.headshots + 1
    end
    
    -- Vérifier les multikills
    local isMultikill = checkMultikill()
    playerStats.lastKillTime = currentTime
    
    if playerStats.streak > playerStats.bestStreak then
        playerStats.bestStreak = playerStats.streak
    end
    
    -- Effet sonore selon le type de kill
    if isMultikill then
        PlaySoundFrontend(-1, Config.KDSounds.multikill.sound, Config.KDSounds.multikill.set, 1)
    else
        PlaySoundFrontend(-1, Config.KDSounds.kill.sound, Config.KDSounds.kill.set, 1)
    end
    
    -- Message de kill feed
    local killMessage = string.format("💀 Tué %s", victimName or "Joueur")
    if headshot and Config.KDHud.showHeadshots then
        killMessage = killMessage .. " 🎯"
    end
    if distance and distance > 50 and Config.KDHud.showDistance then
        killMessage = killMessage .. string.format(" (%.0fm)", distance)
    end
    if isMultikill then
        killMessage = "⚡ " .. killMessage .. " ⚡"
    end
    
    table.insert(killFeedMessages, {
        text = killMessage,
        startTime = currentTime,
        color = hudConfig.colors.kills
    })
    
    -- Indicateur de dégâts pour le kill
    table.insert(damageIndicators, {
        text = isMultikill and "MULTIKILL!" or (headshot and "HEADSHOT!" or "KILL!"),
        x = 0.5,
        y = 0.5,
        startTime = currentTime,
        color = headshot and hudConfig.colors.streak or hudConfig.colors.kills
    })
    
    -- Vérifier les récompenses de streak
    for _, reward in ipairs(Config.StreakRewards) do
        if playerStats.streak == reward.kills then
            table.insert(streakMessages, {
                text = reward.message,
                startTime = currentTime,
                color = reward.color
            })
            
            if reward.sound then
                PlaySoundFrontend(-1, Config.KDSounds.streak.sound, Config.KDSounds.streak.set, 1)
            end
            
            TriggerEvent('chat:addMessage', {
                color = reward.color,
                args = {"🔥 STREAK", reward.message}
            })
            break
        end
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
    PlaySoundFrontend(-1, Config.KDSounds.death.sound, Config.KDSounds.death.set, 1)
    
    -- Message de kill feed
    local deathMessage = string.format("☠️ Tué par %s", killerName or "Joueur")
    if headshot and Config.KDHud.showHeadshots then
        deathMessage = deathMessage .. " 🎯"
    end
    
    table.insert(killFeedMessages, {
        text = deathMessage,
        startTime = GetGameTimer(),
        color = hudConfig.colors.deaths
    })
    
    -- Indicateur de mort
    table.insert(damageIndicators, {
        text = headshot and "HEADSHOT MORT" or "MORT",
        x = 0.5,
        y = 0.5,
        startTime = GetGameTimer(),
        color = hudConfig.colors.deaths
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
        startTime = GetGameTimer(),
        color = hudConfig.colors.assists
    })
    
    -- Indicateur d'assistance
    table.insert(damageIndicators, {
        text = "ASSIST!",
        x = 0.5,
        y = 0.45,
        startTime = GetGameTimer(),
        color = hudConfig.colors.assists
    })
    
    -- Son d'assistance
    PlaySoundFrontend(-1, Config.KDSounds.assist.sound, Config.KDSounds.assist.set, 1)
    
    -- Sauvegarder les statistiques
    TriggerServerEvent('kd:updateStats', playerStats)
end)

-- ====================================================================
-- GESTION DE L'AFFICHAGE SELON LES ZONES
-- ====================================================================

-- Événement de changement de zone (intégration avec le système existant)
AddEventHandler('vmenu:zoneRestriction', function(inZone, zoneData)
    isInPvPZone = inZone
    showKDHud = inZone and Config.KDHud.autoShow
    
    if inZone then
        -- Réinitialiser le temps de session PvP
        playerStats.sessionStart = GetGameTimer()
        
        -- Notification d'entrée en mode PvP
        TriggerEvent('chat:addMessage', {
            color = {52, 152, 219},
            args = {"🎯 PVP MODE", "Système K/D activé - Tapez /stats pour voir vos statistiques"}
        })
    else
        -- Calculer le temps passé en PvP
        local sessionTime = (GetGameTimer() - playerStats.sessionStart) / 1000
        playerStats.timeInPvP = playerStats.timeInPvP + sessionTime
        
        -- Afficher un résumé de session si des actions ont eu lieu
        if playerStats.kills > 0 or playerStats.deaths > 0 then
            local kd = calculateKD()
            local kda = calculateKDA()
            TriggerEvent('chat:addMessage', {
                color = {46, 204, 113},
                multiline = true,
                args = {"📊 RÉSUMÉ SESSION", string.format(
                    "💀 Kills: %d | ☠️ Deaths: %d | 🤝 Assists: %d\n📊 K/D: %.2f | 📈 KDA: %.2f | ⏱️ Temps: %s",
                    playerStats.kills, playerStats.deaths, playerStats.assists, kd, kda, formatSessionTime()
                )}
            })
        end
        
        -- Sauvegarder les statistiques finales
        TriggerServerEvent('kd:updateStats', playerStats)
    end
end)

-- ====================================================================
-- THREADS D'AFFICHAGE
-- ====================================================================

-- Thread principal pour l'affichage du HUD
Citizen.CreateThread(function()
    while true do
        if showKDHud and isInPvPZone then
            drawKDHud()
            drawDamageIndicators()
            drawKillFeed()
            drawStreakMessages()
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- Thread pour la détection automatique des kills/deaths
Citizen.CreateThread(function()
    local lastHealth = 0
    local lastArmour = 0
    
    while true do
        if isInPvPZone then
            local playerPed = PlayerPedId()
            local currentHealth = GetEntityHealth(playerPed)
            local currentArmour = GetPedArmour(playerPed)
            
            -- Détecter les dégâts reçus
            if lastHealth > 0 and currentHealth < lastHealth then
                local damage = lastHealth - currentHealth
                playerStats.totalDamageReceived = playerStats.totalDamageReceived + damage
            end
            
            if lastArmour > 0 and currentArmour < lastArmour then
                local armourDamage = lastArmour - currentArmour
                playerStats.totalDamageReceived = playerStats.totalDamageReceived + armourDamage
            end
            
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
                local headshot = HasEntityBeenDamagedByWeapon(playerPed, weapon, 2)
                
                TriggerEvent('kd:onDeath', killerPlayer, weapon, headshot)
                
                -- Attendre la réapparition
                while IsEntityDead(playerPed) do
                    Citizen.Wait(1000)
                end
                
                -- Réinitialiser les valeurs de santé
                lastHealth = GetEntityHealth(PlayerPedId())
                lastArmour = GetPedArmour(PlayerPedId())
            else
                lastHealth = currentHealth
                lastArmour = currentArmour
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
    local headshotRate = playerStats.kills > 0 and math.floor((playerStats.headshots / playerStats.kills) * 100) or 0
    
    TriggerEvent('chat:addMessage', {
        color = {52, 152, 219},
        multiline = true,
        args = {"📊 MES STATISTIQUES", string.format(
            "💀 Kills: %d | ☠️ Deaths: %d | 🤝 Assists: %d | 🎯 Headshots: %d\n" ..
            "📊 K/D: %.2f | 📈 KDA: %.2f | 🎯 Headshot%%: %d%%\n" ..
            "🔥 Streak actuelle: %d | 🏆 Meilleure streak: %d\n" ..
            "⏱️ Temps de session: %s | 💥 Multikills: %d",
            playerStats.kills, playerStats.deaths, playerStats.assists, playerStats.headshots,
            kd, kda, headshotRate, playerStats.streak, playerStats.bestStreak, 
            sessionTime, playerStats.multikills
        )}
    })
end, false)

-- Commande pour réinitialiser les statistiques de session
RegisterCommand("resetstats", function()
    local oldStats = {
        kills = playerStats.kills,
        deaths = playerStats.deaths,
        assists = playerStats.assists
    }
    
    playerStats.kills = 0
    playerStats.deaths = 0
    playerStats.assists = 0
    playerStats.streak = 0
    playerStats.headshots = 0
    playerStats.multikills = 0
    playerStats.sessionStart = GetGameTimer()
    playerStats.totalDamageDealt = 0
    playerStats.totalDamageReceived = 0
    
    TriggerEvent('chat:addMessage', {
        color = {241, 196, 15},
        multiline = true,
        args = {"🔄 RESET", string.format(
            "Statistiques de session réinitialisées\nAnciens stats: %d kills, %d deaths, %d assists",
            oldStats.kills, oldStats.deaths, oldStats.assists
        )}
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

-- Commande pour ajuster la position du HUD
RegisterCommand("movekd", function(source, args)
    if not args[1] or not args[2] then
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            args = {"[Usage]", "/movekd <x> <y> (valeurs entre 0.0 et 1.0)"}
        })
        return
    end
    
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    
    if x and y and x >= 0.0 and x <= 1.0 and y >= 0.0 and y <= 1.0 then
        hudPosition.x = x
        hudPosition.y = y
        TriggerEvent('chat:addMessage', {
            color = {46, 204, 113},
            args = {"🎯 HUD K/D", string.format("Position mise à jour: %.2f, %.2f", x, y)}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {231, 76, 60},
            args = {"[Erreur]", "Valeurs invalides. Utilisez des nombres entre 0.0 et 1.0"}
        })
    end
end, false)

-- ====================================================================
-- INITIALISATION ET NETTOYAGE
-- ====================================================================

-- Charger les statistiques sauvegardées au démarrage
AddEventHandler('playerSpawned', function()
    if Config.KDSave.enablePersistence then
        TriggerServerEvent('kd:loadStats')
    end
    
    -- Réinitialiser les variables d'affichage
    showKDHud = Config.KDHud.autoShow
    isInPvPZone = false
end)

-- Événement pour recevoir les statistiques du serveur
RegisterNetEvent('kd:receiveStats')
AddEventHandler('kd:receiveStats', function(stats)
    if stats then
        playerStats.kills = stats.kills or 0
        playerStats.deaths = stats.deaths or 0
        playerStats.assists = stats.assists or 0
        playerStats.bestStreak = stats.bestStreak or 0
        playerStats.headshots = stats.headshots or 0
        playerStats.multikills = stats.multikills or 0
        playerStats.timeInPvP = stats.timeInPvP or 0
        playerStats.totalDamageDealt = stats.totalDamageDealt or 0
        playerStats.totalDamageReceived = stats.totalDamageReceived or 0
        
        TriggerEvent('chat:addMessage', {
            color = {46, 204, 113},
            args = {"📊 K/D", "Statistiques chargées avec succès"}
        })
    end
end)

-- Nettoyage à l'arrêt du script
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Sauvegarder les statistiques finales
        if Config.KDSave.enablePersistence then
            TriggerServerEvent('kd:updateStats', playerStats)
        end
        
        -- Nettoyer les variables
        showKDHud = false
        isInPvPZone = false
        damageIndicators = {}
        killFeedMessages = {}
        streakMessages = {}
    end
end)