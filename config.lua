Config = {}

-- Configuration des zones où vMenu doit être désactivé
Config.RestrictedZones = {
    {
        name = "Arène PvP - Dock",
        coords = vector3(1021.45, -3278.1, 5.89),
        radius = 45.0,
        showBlip = true,
        blipColor = 1, -- Rouge
        blipAlpha = 80
    },
    {
        name = "Arène PvP - Port", 
        coords = vector3(238.36, -2995.33, 5.71),
        radius = 45.0,
        showBlip = true,
        blipColor = 1,
        blipAlpha = 80
    },
    {
        name = "Arène PvP - Hangar",
        coords = vector3(36.27, -2711.33, 5.37),
        radius = 45.0,
        showBlip = true,
        blipColor = 1,
        blipAlpha = 80
    },
    {
        name = "Arène PvP - Usine",
        coords = vector3(2764.12, 1524.31, 24.5),
        radius = 45.0,
        showBlip = true,
        blipColor = 1,
        blipAlpha = 80
    }
}

-- Touches à désactiver quand vMenu est bloqué
Config.DisabledControls = {
    244, -- M key (vMenu par défaut)
    288, -- F1 key 
    170, -- F3 key
    166, -- F5 key
    167, -- F6 key
    289, -- F2 key (noclip)
    56,  -- F9 key
    57   -- F10 key
}

-- Messages de notification
Config.Messages = {
    enterZone = "~r~vMenu désactivé~w~ - Vous êtes dans une zone PvP",
    exitZone = "~g~vMenu réactivé~w~ - Vous avez quitté la zone PvP"
}

-- Paramètres d'optimisation
Config.CheckInterval = 1000 -- Vérification toutes les 1000ms (1 seconde)
Config.ShowNotifications = true -- Afficher les notifications d'entrée/sortie
Config.DebugMode = false -- Mode debug pour les développeurs