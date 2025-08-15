-- ====================================================================
-- FXMANIFEST - vMenu Zone Disabler
-- Fichier de configuration du script pour FiveM
-- ====================================================================

fx_version 'cerulean'
games { 'gta5' }

-- ====================================================================
-- INFORMATIONS DU SCRIPT
-- ====================================================================

author 'FiveM Community - Optimisé'
description 'Désactive automatiquement vMenu dans les zones PvP configurées avec gestion avancée et optimisations'
version '2.0.0'
url 'https://github.com/votre-repo/vmenu-zone-disabler'

-- ====================================================================
-- FICHIERS DU SCRIPT
-- ====================================================================

-- Configuration partagée (accessible côté client et serveur)
shared_script 'config.lua'

-- Script côté client (interface utilisateur, détection de zones)
client_script 'client.lua'

-- Script côté serveur (logs, statistiques, commandes admin)
server_script 'server.lua'

-- ====================================================================
-- DÉPENDANCES ET COMPATIBILITÉ
-- ====================================================================

-- Dépendances optionnelles (le script fonctionnera même si elles ne sont pas présentes)
dependencies {
    'vMenu'  -- Script principal que nous gérons
}

-- Dépendances suggérées pour une meilleure expérience
-- Ces scripts sont compatibles et peuvent améliorer l'expérience utilisateur
suggested_dependencies {
    'esx_core',      -- Framework ESX
    'qb-core',       -- Framework QBCore  
    'ox_lib',        -- Bibliothèque utilitaire
    'menuv'          -- Alternative de menu
}

-- ====================================================================
-- EXPORTS DISPONIBLES
-- ====================================================================

-- Exports côté client pour d'autres scripts
client_exports {
    'isPlayerInRestrictedZone',  -- Vérifier si le joueur est en zone restreinte
    'getCurrentZone',            -- Obtenir la zone actuelle du joueur
    'forceZoneCheck'             -- Forcer une vérification des zones
}

-- ====================================================================
-- MÉTADONNÉES ÉTENDUES
-- ====================================================================

-- Informations sur la compatibilité
lua54 'yes'  -- Compatible avec Lua 5.4

-- Informations sur les permissions requises
server_only_permissions {
    'command.zonestatus',
    'command.zonestats', 
    'command.playerstats',
    'command.reloadblips',
    'vmenu.notify'
}

-- ====================================================================
-- CONFIGURATION DE DÉVELOPPEMENT
-- ====================================================================

-- Fichiers à surveiller pour le rechargement automatique en développement
files {
    'config.lua'
}

-- ====================================================================
-- INFORMATIONS DE VERSION ET CHANGELOG
-- ====================================================================

--[[
CHANGELOG:

v2.0.0 (Actuel):
- Refactorisation complète du code pour de meilleures performances
- Ajout d'un système de cache pour les noms de joueurs
- Amélioration de la gestion des erreurs et de la stabilité
- Nouveaux exports pour l'intégration avec d'autres scripts
- Système de maintenance automatique des données
- Commandes admin étendues avec statistiques détaillées
- Optimisation de la détection des zones
- Meilleure gestion de la mémoire et nettoyage automatique

v1.0.0:
- Version initiale avec fonctionnalités de base
- Détection simple des zones PvP
- Désactivation basique de vMenu
- Commandes administrateur de base
]]--