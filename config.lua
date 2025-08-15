-- ====================================================================
-- CONFIGURATION - vMenu Zone Disabler
-- Fichier de configuration principal pour personnaliser le comportement
-- ====================================================================

Config = {}

-- ====================================================================
-- CONFIGURATION DES ZONES RESTREINTES
-- ====================================================================

-- Définition des zones où vMenu doit être automatiquement désactivé
-- Chaque zone peut avoir ses propres paramètres visuels et de comportement
Config.RestrictedZones = {
    {
        name = "Arène PvP - Dock",                    -- Nom affiché sur la carte
        coords = vector3(1021.45, -3278.1, 5.89),    -- Coordonnées du centre de la zone
        radius = 45.0,                                -- Rayon de la zone en unités GTA
        showBlip = true,                              -- Afficher un blip sur la carte
        blipColor = 1,                                -- Couleur du blip (1 = Rouge)
        blipAlpha = 80                                -- Transparence du blip (0-255)
    },
    {
        name = "Arène PvP - Port", 
        coords = vector3(238.36, -2995.33, 5.71),
        radius = 45.0,
        showBlip = true,
        blipColor = 1,                                -- Rouge pour zone dangereuse
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
    },
    -- Vous pouvez ajouter d'autres zones ici en suivant le même format
    -- {
    --     name = "Nouvelle Zone PvP",
    --     coords = vector3(x, y, z),
    --     radius = 50.0,
    --     showBlip = true,
    --     blipColor = 3,  -- Bleu
    --     blipAlpha = 100
    -- }
}

-- ====================================================================
-- CONFIGURATION DES CONTRÔLES DÉSACTIVÉS
-- ====================================================================

-- Liste des touches/contrôles à désactiver quand le joueur est en zone restreinte
-- Référence complète des contrôles : https://docs.fivem.net/docs/game-references/controls/
Config.DisabledControls = {
    -- Touches principales de vMenu et menus
    244,    -- M key (vMenu par défaut)
    288,    -- F1 key (souvent utilisé pour d'autres menus)
    170,    -- F3 key (noclip dans certains menus admin)
    166,    -- F5 key (menus personnalisés)
    167,    -- F6 key (menus job/gang)
    289,    -- F2 key (noclip/admin)
    56,     -- F9 key (menus divers)
    57,     -- F10 key (menus divers)
    
    -- Touches supplémentaires que vous pouvez activer si nécessaire
    -- 121,    -- INSERT key
    -- 322,    -- ESC key (attention : peut bloquer d'autres fonctions)
    -- 199,    -- P key
    -- 200,    -- PAUSE key
}

-- ====================================================================
-- MESSAGES ET NOTIFICATIONS
-- ====================================================================

-- Messages affichés aux joueurs lors des transitions de zone
Config.Messages = {
    enterZone = "~r~⚠ vMenu désactivé~w~ - Vous êtes dans une zone PvP",
    exitZone = "~g~✓ vMenu réactivé~w~ - Vous avez quitté la zone PvP"
}

-- ====================================================================
-- PARAMÈTRES D'OPTIMISATION ET PERFORMANCE
-- ====================================================================

-- Intervalle de vérification des zones en millisecondes
-- Plus la valeur est faible, plus la détection est précise mais plus ça consomme de ressources
-- Recommandé : 1000ms (1 seconde) pour un bon équilibre performance/précision
Config.CheckInterval = 1000

-- Affichage des notifications d'entrée/sortie de zone
Config.ShowNotifications = true

-- Mode debug pour les développeurs et administrateurs
-- Active les messages de console détaillés pour le débogage
Config.DebugMode = false

-- ====================================================================
-- PARAMÈTRES AVANCÉS
-- ====================================================================

-- Délai avant réactivation de vMenu après sortie de zone (en ms)
-- Utile pour éviter les conflits si le joueur sort/rentre rapidement
Config.ReactivationDelay = 500

-- Vérifier la compatibilité avec d'autres scripts de menu
-- Si true, le script vérifiera si d'autres menus sont actifs avant de désactiver vMenu
Config.CheckOtherMenus = true

-- Liste des ressources de menu à vérifier (si CheckOtherMenus = true)
Config.OtherMenuResources = {
    'esx_menu_default',
    'esx_menu_dialog',
    'menuv',
    'nh-context',
    'qb-menu'
}

-- ====================================================================
-- CONFIGURATION DES PERMISSIONS
-- ====================================================================

-- Permissions requises pour les commandes administrateur
Config.AdminPermissions = {
    zonestatus = "command.zonestatus",      -- Voir qui est dans les zones
    zonestats = "command.zonestats",        -- Voir les statistiques
    reloadblips = "command.reloadblips",    -- Recharger les blips
    vmenunotify = "vmenu.notify"            -- Recevoir les notifications admin
}

-- ====================================================================
-- COULEURS DES BLIPS (RÉFÉRENCE)
-- ====================================================================

--[[
Couleurs de blips disponibles :
0 = Blanc          8 = Rose           16 = Vert foncé
1 = Rouge          9 = Rouge foncé    17 = Bleu foncé  
2 = Vert          10 = Marron         18 = Violet foncé
3 = Bleu          11 = Violet         19 = Aqua foncé
4 = Blanc         12 = Jaune foncé    20 = Gris foncé
5 = Jaune         13 = Orange         21 = Gris clair
6 = Rouge clair   14 = Bleu clair     22 = Gris très clair
7 = Violet clair  15 = Gris           23 = Rose clair
]]--