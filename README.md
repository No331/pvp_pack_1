# Script vMenu Zone Disabler pour FiveM - Version Optimisée

## 📋 Description
Ce script désactive automatiquement vMenu quand un joueur entre dans des zones PvP spécifiques et le réactive quand il en sort. Cette version optimisée inclut de nombreuses améliorations de performance, de stabilité et de fonctionnalités avancées.

## ✨ Fonctionnalités

### 🎯 Fonctionnalités Principales
- ✅ **Détection automatique** d'entrée/sortie de zone avec optimisation des performances
- ✅ **Désactivation sélective** de vMenu par joueur (n'affecte pas les autres)
- ✅ **Blips visuels** des zones sur la carte avec personnalisation complète
- ✅ **Notifications** d'entrée/sortie avec sons et messages personnalisables
- ✅ **Système de logs** serveur détaillé avec horodatage
- ✅ **Commandes admin** étendues pour monitoring et statistiques
- ✅ **Optimisé** pour les performances avec vérifications adaptatives
- ✅ **Compatible** avec tous les frameworks (ESX, QBCore, standalone)

### 🔧 Fonctionnalités Avancées
- 🚀 **Cache intelligent** des noms de joueurs pour réduire les appels API
- 📊 **Statistiques détaillées** par joueur et globales
- 🔄 **Maintenance automatique** des données obsolètes
- 🎛️ **Exports** pour intégration avec d'autres scripts
- 🛡️ **Gestion d'erreurs** robuste avec récupération automatique
- ⚡ **Vérification adaptative** (plus fréquente en zone, moins fréquente hors zone)
- 🎨 **Interface améliorée** avec messages multilignes et couleurs

## 📦 Installation

### Installation Standard
1. **Téléchargez** le script et placez le dossier dans votre répertoire `resources`
2. **Ajoutez** `ensure vmenu-zone-disabler` dans votre `server.cfg`
3. **Configurez** les zones dans `config.lua` selon vos besoins
4. **Redémarrez** le serveur ou utilisez `refresh` puis `start vmenu-zone-disabler`

### Vérification de l'Installation
```bash
# Dans la console serveur, vérifiez que le script est démarré
> resource vmenu-zone-disabler
# Devrait afficher "started"

# Testez une commande admin
> zonestats
```

## ⚙️ Configuration

### 🗺️ Configuration des Zones PvP
Modifiez le fichier `config.lua` pour personnaliser vos zones :

```lua
Config.RestrictedZones = {
    {
        name = "Ma Zone PvP Personnalisée",     -- Nom affiché
        coords = vector3(x, y, z),              -- Coordonnées du centre
        radius = 50.0,                          -- Rayon en unités GTA
        showBlip = true,                        -- Afficher sur la carte
        blipColor = 1,                          -- Couleur (1=Rouge, 2=Vert, 3=Bleu...)
        blipAlpha = 80                          -- Transparence (0-255)
    },
    -- Ajoutez autant de zones que nécessaire...
}
```

### ⌨️ Touches Désactivées
Personnalisez les contrôles à bloquer :

```lua
Config.DisabledControls = {
    244,    -- M key (vMenu par défaut)
    288,    -- F1 key
    170,    -- F3 key (noclip)
    -- Ajoutez d'autres touches selon vos besoins...
}
```

### 🎨 Messages et Notifications
```lua
Config.Messages = {
    enterZone = "~r~⚠ vMenu désactivé~w~ - Vous êtes dans une zone PvP",
    exitZone = "~g~✓ vMenu réactivé~w~ - Vous avez quitté la zone PvP"
}
```

### ⚡ Optimisation des Performances
```lua
Config.CheckInterval = 1000        -- Vérification toutes les 1000ms
Config.ShowNotifications = true    -- Afficher les notifications
Config.DebugMode = false          -- Mode debug (désactiver en production)
```

## 🎮 Commandes

### 👤 Commandes Joueurs
| Commande | Description | Exemple |
|----------|-------------|---------|
| `/checkzone` | Vérifier votre statut de zone actuel | `/checkzone` |

### 👑 Commandes Administrateur
| Commande | Permission | Description |
|----------|------------|-------------|
| `/zonestatus` | `command.zonestatus` | Voir qui est dans les zones |
| `/zonestats` | `command.zonestats` | Statistiques globales des zones |
| `/playerstats <ID>` | `command.zonestats` | Statistiques d'un joueur spécifique |
| `/reloadblips` | `command.reloadblips` | Recharger les blips des zones |

## 🔐 Configuration des Permissions

Ajoutez dans votre `server.cfg` :
```cfg
# Permissions pour les commandes admin
add_ace group.admin command.zonestatus allow
add_ace group.admin command.zonestats allow
add_ace group.admin command.reloadblips allow
add_ace group.admin vmenu.notify allow

# Pour des groupes spécifiques
add_ace group.moderator command.zonestatus allow
```

## 🔌 Intégration avec d'autres Scripts

### 📡 Événements Disponibles

#### Côté Client
```lua
-- Écouter les changements de zone
AddEventHandler('vmenu:zoneRestriction', function(inZone, zoneData)
    if inZone then
        print("Entré dans la zone: " .. zoneData.name)
        -- Votre logique personnalisée ici
    else
        print("Sorti de la zone")
        -- Logique de sortie
    end
end)

-- Forcer une vérification des zones
TriggerEvent('vmenu:forceZoneCheck')
```

#### Côté Serveur
```lua
-- Écouter les entrées de zone
AddEventHandler('vmenu:playerEnteredRestrictedZone', function(zoneName)
    local src = source
    local playerName = GetPlayerName(src)
    -- Votre logique serveur ici
end)

-- Écouter les sorties de zone
AddEventHandler('vmenu:playerExitedRestrictedZone', function(zoneName)
    local src = source
    -- Logique de sortie côté serveur
end)
```

### 📤 Exports Disponibles
```lua
-- Vérifier si un joueur est en zone restreinte
local isInZone = exports['vmenu-zone-disabler']:isPlayerInRestrictedZone()

-- Obtenir la zone actuelle du joueur
local currentZone = exports['vmenu-zone-disabler']:getCurrentZone()

-- Forcer une vérification des zones
exports['vmenu-zone-disabler']:forceZoneCheck()
```

## 🚀 Optimisations et Performance

### 📈 Améliorations de Performance
- **Vérification adaptative** : Plus fréquente en zone (500ms), moins fréquente hors zone (1000ms)
- **Cache des noms** : Évite les appels répétés à `GetPlayerName()`
- **Nettoyage automatique** : Suppression des données obsolètes toutes les 5 minutes
- **Vérifications conditionnelles** : Évite les calculs inutiles

### 💾 Gestion de la Mémoire
- Nettoyage automatique des joueurs déconnectés
- Cache intelligent avec expiration automatique
- Optimisation des boucles et des vérifications

## 🔧 Dépannage

### ❌ Problèmes Courants

**vMenu ne se désactive pas :**
1. Vérifiez que vMenu est bien démarré : `resource vMenu`
2. Vérifiez les logs pour les erreurs : `con_miniconChannels script:*`
3. Testez avec `/checkzone` pour voir si vous êtes détecté en zone

**Blips n'apparaissent pas :**
1. Vérifiez `Config.RestrictedZones[].showBlip = true`
2. Utilisez `/reloadblips` pour les recréer
3. Vérifiez les coordonnées des zones

**Performances dégradées :**
1. Augmentez `Config.CheckInterval` (ex: 2000ms)
2. Désactivez `Config.DebugMode` en production
3. Réduisez le nombre de `Config.DisabledControls`

### 🔍 Mode Debug
Activez le mode debug dans `config.lua` :
```lua
Config.DebugMode = true
```

Cela affichera des informations détaillées dans la console pour diagnostiquer les problèmes.

## 🔄 Compatibilité

### ✅ Scripts Compatibles
- **vMenu** (toutes versions)
- **ESX/QBCore** (tous frameworks)
- **Autres scripts de menu** (MenuV, ox_lib, etc.)
- **Scripts PvP existants**
- **Scripts de zones personnalisés**

### 🔧 Intégration Framework
Le script est conçu pour être **framework-agnostic** et fonctionne avec :
- ESX Legacy/1.2+
- QBCore
- Serveurs Standalone
- Frameworks personnalisés

## 📊 Statistiques et Monitoring

### 📈 Données Collectées
- Nombre total d'entrées/sorties de zones
- Temps passé par joueur dans les zones
- Zones les plus visitées
- Statistiques en temps réel

### 📋 Exemple de Sortie de Statistiques
```
=== STATISTIQUES DES ZONES PVP ===
Uptime du script: 2 heures 15 minutes
Entrées totales: 47
Sorties totales: 45
Joueurs actuellement en zone: 2
Zones configurées: 4
Joueurs avec données de session: 12
```

## 🆕 Changelog

### Version 2.0.0 (Actuelle)
- 🔄 Refactorisation complète pour de meilleures performances
- 📊 Système de statistiques avancé avec données par joueur
- 🧹 Maintenance automatique et nettoyage des données
- 🔌 Nouveaux exports pour l'intégration
- 🎨 Interface améliorée avec messages multilignes
- 🛡️ Gestion d'erreurs robuste
- ⚡ Optimisations de performance majeures

### Version 1.0.0
- 🎯 Fonctionnalités de base
- 🗺️ Détection simple des zones
- 🚫 Désactivation basique de vMenu

## 📞 Support

Pour obtenir de l'aide :

1. **Vérifiez les logs** serveur pour les erreurs
2. **Testez les commandes** de debug (`/checkzone`, `/zonestats`)
3. **Vérifiez la configuration** dans `config.lua`
4. **Consultez la documentation** ci-dessus

### 🐛 Signaler un Bug
Lors du signalement d'un problème, incluez :
- Version du script
- Logs d'erreur complets
- Configuration utilisée
- Étapes pour reproduire le problème

---

**Développé avec ❤️ pour la communauté FiveM**