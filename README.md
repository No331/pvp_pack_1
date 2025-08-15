# Script vMenu Zone Disabler pour FiveM

## Description
Ce script désactive automatiquement vMenu quand un joueur entre dans des zones PvP spécifiques et le réactive quand il en sort.

## Fonctionnalités
- ✅ Détection automatique d'entrée/sortie de zone
- ✅ Désactivation sélective de vMenu par joueur
- ✅ Blips visuels des zones sur la carte
- ✅ Notifications d'entrée/sortie
- ✅ Système de logs serveur
- ✅ Commandes admin pour monitoring
- ✅ Optimisé pour les performances
- ✅ Compatible avec d'autres scripts

## Installation

1. Placez le dossier dans votre répertoire `resources`
2. Ajoutez `ensure vmenu-zone-disabler` dans votre `server.cfg`
3. Configurez les zones dans `config.lua`
4. Redémarrez le serveur

## Configuration

### Zones PvP
Modifiez le fichier `config.lua` pour ajouter/modifier les zones :

```lua
Config.RestrictedZones = {
    {
        name = "Ma Zone PvP",
        coords = vector3(x, y, z),
        radius = 50.0,
        showBlip = true,
        blipColor = 1,
        blipAlpha = 80
    }
}
```

### Touches désactivées
Personnalisez les touches à bloquer :

```lua
Config.DisabledControls = {
    244, -- M key (vMenu)
    288, -- F1 key
    -- Ajoutez d'autres touches...
}
```

## Commandes

### Joueurs
- `/checkzone` - Vérifier si vous êtes dans une zone restreinte

### Administrateurs
- `/zonestatus` - Voir qui est dans les zones
- `/zonestats` - Statistiques des zones

## Permissions
Ajoutez dans votre `server.cfg` :
```
add_ace group.admin command.zonestatus allow
add_ace group.admin command.zonestats allow
add_ace group.admin vmenu.notify allow
```

## Événements pour développeurs

### Client
```lua
-- Écouter les changements de zone
AddEventHandler('vmenu:zoneRestriction', function(inZone, zoneData)
    if inZone then
        print("Entré dans la zone: " .. zoneData.name)
    else
        print("Sorti de la zone")
    end
end)
```

### Serveur
```lua
-- Écouter les entrées de zone
AddEventHandler('vmenu:playerEnteredRestrictedZone', function(zoneName)
    local src = source
    -- Votre logique ici
end)
```

## Optimisation
- Vérification des zones toutes les 1000ms par défaut
- Thread séparé pour les contrôles désactivés
- Nettoyage automatique des ressources

## Compatibilité
- ✅ vMenu
- ✅ ESX/QBCore
- ✅ Autres scripts de menu
- ✅ Scripts PvP existants

## Support
Pour des questions ou problèmes, vérifiez :
1. Les logs serveur pour les erreurs
2. Que vMenu est bien démarré
3. Les permissions admin si nécessaire

## Changelog
- v1.0.0 : Version initiale avec toutes les fonctionnalités