# Changelog

Toutes les versions notables de **BossWatch** sont listées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versionnage selon [SemVer](https://semver.org/lang/fr/).

## [Unreleased]

### Corrigé
- **Spam d'erreur `ADDON_ACTION_FORBIDDEN` sur Retail Midnight 12.0+** (rapporté par Smuglerz). L'enregistrement de `COMBAT_LOG_EVENT_UNFILTERED` au file-load du nouveau module `Frames/MyAuras.lua` (v0.8.0) déclenchait le piège de fonction protégée de Blizzard, produisant 20+ erreurs au login. L'enregistrement est maintenant différé après `PLAYER_LOGIN`, même pattern que WeakAuras / BigWigs. Le filtre "Only mine" continue de fonctionner identiquement, juste après le tick de login.

## [0.8.0] - 2026-06-16

### Ajouté
- **Support Classic Era / Season of Discovery.** Un troisième TOC (`BossWatch-Vanilla.toc`, Interface 11507) installe maintenant l'addon sur le client Vanilla 1.15.x. Sur ce client, les identifiants d'unité `boss1..5` n'existent pas (introduits en Cataclysm) — BossWatch détecte les ennemis élite/world-boss/rare-elite en scannant la cible, le survol et les nameplates ennemies (`UnitClassification`), et les assigne dynamiquement aux frames. Active les nameplates ennemies (Ctrl-V) pour que la détection auto fonctionne. Stable slot IDs : un slot reste assigné à son mob jusqu'à kill ou changement de zone (pas de saut visuel pendant les adds). Capacité configurable (3/5/8 frames).
- **Nouvel onglet "Classic / SoD"** dans le panneau d'options (visible uniquement sur Classic Era / SoD) : toggles d'inclusion par classification (world bosses, élites rares, élites, rares non-élite), capacité max, délai de libération de slot, bouton de reset manuel.

### Interne
- **Couche d'abstraction `BossW.SlotProvider`** entre les BossFrames et les unit tokens. Sur Retail / Midnight / MoP Classic le provider trivial retourne `"boss"..i` (comportement bit-à-bit identique à avant). Sur Vanilla/SoD un provider override gère les slots virtuels. Permet de supporter le nouveau client sans dupliquer Frames/Boss.lua.
- **Tracking combat-log des auras du joueur** (`Frames/MyAuras.lua`) — sur Retail Midnight 12.0+, les champs `isFromPlayerOrPlayerPet` et `sourceUnit` des auras sont secret-tagged sur les unités hostiles, ce qui rendait le filtre **Auras → Source → "Only mine"** peu fiable. Le nouveau tracker écoute `COMBAT_LOG_EVENT_UNFILTERED` et maintient une table `(GUID cible, spellID) → applied` filtrée sur `COMBATLOG_OBJECT_AFFILIATION_MINE` — les données combat-log ne sont jamais secret-tagged, donc le filtre est maintenant fiable à 100% sur Retail. Fallback sur les champs Blizzard préservé pour Classic / SoD / TBC où il n'y a pas de secret-tagging.

## [0.7.9] - 2026-05-18

### Corrigé
- **Taint EditMode `execution tainted by 'BossWatch'`.** L'ouverture du mode édition de l'UI déclenchait une cascade d'erreurs Lua dans `CastingBarFrame:StopFinishAnims` (table `<forbidden>`). Cause : `HideBlizzardBossFrames` écrasait `frame.Show = function() end` et appelait `UnregisterAllEvents()` sur des frames secure Blizzard, ce qui les rend tainted en 12.0+ et propage le taint à tous leurs enfants (dont la CastingBarFrame). Remplacé par un masquage non-destructif (alpha 0 + frame déplacée hors écran) — aucune méthode secure n'est plus modifiée.

## [0.7.8] - 2026-05-13

### Modifié
- **L'overlay d'absorption (boucliers, bulles) n'est plus marqué "expérimental"** — la feature est stable depuis plusieurs versions et fonctionne sur les boss avec valeurs secrètes via le pattern tracker invisible + texture visible.
- **Couleur d'absorption par défaut passée de cyan translucide à jaune opaque (`#FFEB3EFF`).** Plus visible par-dessus la barre de vie, et les nouveaux utilisateurs n'ont plus à régler l'alpha eux-mêmes. Les profils existants gardent leur couleur — change-la dans Bars > Absorbs ou fais `/bossw reset` pour récupérer le nouveau défaut.

### Ajouté
- Liste des slash commands de l'onglet **À propos** complétée : `/bosswatch` (alias) et `/bossw auras [unit]` (commande de debug) sont maintenant listés.

## [0.7.7] - 2026-05-12

### Modifié
- **Refactor interne du panneau d'options.** Le fichier `Options/Panel.lua` est passé de 2407 lignes à 1043 (-57%). Chaque onglet vit maintenant dans son propre fichier sous `Options/Pages/` (Layout, Bars, Cast, Text, Raid, Auras, Profils, À propos), et les factories de widgets sont isolées dans `Options/Widgets.lua`. Aucun changement de comportement utilisateur — la base de code est juste plus saine pour les évolutions futures.

### Ajouté
- **Lint CI** via `luacheck` sur chaque push beta/main (GitHub Actions). Détecte les erreurs de syntaxe avant que les utilisateurs ne les voient.
- **Script `scripts/release_beta.sh`** pour publier sur le **channel beta** de CurseForge / Wago (séparé du channel stable). Les notifications Discord sortent en orange pour distinguer.

## [0.7.6] - 2026-05-12

### Corrigé
- **Panneau d'options hors écran après changement de résolution.** Si tu avais déplacé ou agrandi le panneau sur un grand moniteur puis relancé WoW sur un écran plus petit, le panneau pouvait apparaître partiellement ou totalement hors écran (`SetClampedToScreen` ne protège que les drag ultérieurs, pas le placement initial). La position ET la taille sauvegardées sont maintenant clampées aux dimensions courantes de `UIParent` au chargement. Pendant équivalent côté frames boss déjà fait en v0.7.3.

## [0.7.5] - 2026-05-12

### Modifié
- Onglet **Nouveautés** retiré du bas du panneau : la liste des versions est maintenant une section au bas de l'onglet **À propos**. Libère un slot de tab et regroupe identité + historique au même endroit.
- Le `README.md` GitHub a été refait au complet pour refléter l'état actuel (MoP Classic, side-tabs, click actions, smooth bars, modern aura API, tooltips, etc.).

### Ajouté
- 3e onglet latéral **SplitWatch** sur le côté gauche du panneau, visible uniquement quand l'addon frère SplitWatch est installé.
- Fichier `CHANGELOG.md` à la racine, format Keep a Changelog, source unique pour les annotations de tag et les posts Discord (extracteur : `scripts/extract_changelog.sh X.Y.Z`).

### Supprimé
- Tous les fichiers `.changelog_v*.md` par version — remplacés par le `CHANGELOG.md` consolidé.

## [0.7.4] - 2026-05-11

### Corrigé
- **Spam d'erreur critique sur barre de vie animée.** La v0.7.1 avait corrigé le crash arithmétique sur les targets secret-tagged, mais un second cas existait : un **StatusBar qui a déjà reçu une fois une valeur secret reste taint à vie** — `GetValue()` continue de renvoyer un secret même après un set non-secret. Le logger de taint Blizzard n'étant **pas catchable par pcall**, le fix consiste à détecter le taint **AVANT** toute opération arithmétique (via `issecretvalue`) et bail vers un `SetValue` direct.

### Modifié
- **Modernisation de la collecte d'auras.** Pattern moderne `C_UnitAuras.GetUnitAuraInstanceIDs` + `C_UnitAuras.GetAuraDataByAuraInstanceID` recommandé par le wiki Blizzard. Tri natif côté C : les debuffs de boss remontent automatiquement via `Enum.AuraFilter.Harmful`. Fallback legacy préservé pour MoP Classic.

  L'ordre des debuffs affichés est désormais cohérent avec la priorité Blizzard.

## [0.7.3] - 2026-05-11

### Ajouté
- **Récupération auto si frames hors écran.** Si tu déplaces les frames sur un grand moniteur puis relances sur un plus petit, les coords sauvegardées sont **clampées aux dimensions de `UIParent`** au chargement — les frames réapparaissent toujours dans l'écran.
- Nouvelle commande debug **`/bossw auras [unit]`** : imprime chaque aura sur les boss visibles (ou unit donnée), avec un code couleur indiquant les champs **vert** (lisible) / **rouge** `[secret]` (Midnight 12.0) / **gris** `nil` (absent). Pratique pour diagnostiquer un debuff manquant ou un tooltip incomplet.

## [0.7.2] - 2026-05-10

### Ajouté
- **Infobulles sur les auras.** Survole une icône d'aura → l'infobulle Blizzard standard apparaît (nom, description, durée). API moderne par instance ID (retail) + fallback legacy par index (MoP Classic) + fallback texte minimal (secret-tagged auras). Bascule dans **Options → Auras → Affichage**.

## [0.7.1] - 2026-05-10

### Corrigé
- Spam d'erreur Lua `attempt to perform arithmetic on local 't'` quand un boss renvoie une valeur PV secret-tagged. Sur ces boss, la barre de vie se rabat sur des updates directes non animées.
- Marques de raid (skull, croix, étoile…) posées sur un boss **pendant le combat** s'affichent maintenant correctement sur le frame BossWatch.

## [0.7.0] - 2026-05-10

### Ajouté
- **Support Mists of Pandaria Classic.** Un seul zip s'installe à la fois sur retail et MoP Classic 5.5.x via multi-TOC (`BossWatch.toc` + `BossWatch-Mists.toc`).
- Bannière jaune "Classic build" en haut du panneau, **uniquement sur clients Classic**.

### Modifié
- **Commande slash `/bw` → `/bossw`** (alias `/bosswatch`). L'ancien préfixe court entrait en collision avec un préfixe courant d'autres mods de combat.
- Onglets du bas du panneau passent maintenant sur une seconde ligne quand le panneau est trop étroit, avec empilage propre (FrameLevel par rangée).
- Switch BossWatch ↔ TankWatch via les side-tabs latéraux garde maintenant la fenêtre exactement en place (handoff de position via `ShowOptionsAt`).
- Filtre **BOSS_ONLY** des auras lit le flag natif `isBossDebuff` au lieu du nom de la source.
- Refactor interne : namespace local `BW` → `BossW` (nom plus distinctif).

## [0.6.1] - 2026-05-10

### Ajouté
- **Onglets latéraux d'addon** sur le bord gauche du panneau : **BossWatch** sélectionné en haut, **TankWatch** juste en dessous (uniquement si l'addon est installé). Clic = ferme un panneau et ouvre l'autre.
- Style moderne sur les side-tabs : fond verre sombre, liseré doré sur l'addon actif, halo lumineux au survol.

## [0.6.0] - 2026-05-10

### Ajouté
- **Barre de recherche** style Blizzard (en haut à droite). Tous les contrôles correspondants sont réunis sur une page Résultats. Badges `(N)` par onglet.
- **Sections repliables** avec icône 🔄 de reset par section. État sauvegardé.
- **Fenêtre redimensionnable** : glisse le coin bas-droit. Taille et position sauvegardées account-wide. Bouton "Réinitialiser la fenêtre" dans À propos.
- **Auto-flow** des contrôles : la colonne de droite glisse avec le bord quand on agrandit.
- **Actions au clic** sur les frames boss : **Maj+Clic** cycle les marqueurs de raid, **Ctrl+Clic** met en focus. Toggle dans Disposition > Général.
- **Animation fluide de la barre de vie** (toggle dans Barres > Vie).
- Onglet **Nouveautés** pour voir ce qui a changé sans quitter WoW.

### Modifié
- Pleins de petites finitions : séparateurs de section étendus à la largeur du panneau, libellés de dropdown ancrés au-dessus, tooltips ajoutés sur quasiment tout.

## [0.5.1] - 2026-05-10

### Corrigé
- Compatibilité patch WoW **12.0.7** (plus d'avertissement "addon obsolète").

## [0.5.0] - 2026-05-09

### Ajouté
- **Affichage des absorptions / boucliers** en surcouche sur la barre de vie. Couleur, opacité, texture personnalisables dans Barres > Absorptions.
- **Surbrillance de la cible** : bordure colorée animée autour du frame du boss ciblé (3 modes : statique / couleur de classe / réaction).
- Choix entre layout **3 blocs** (compact) ou **4 blocs** (nom sur sa propre rangée).
- Mode test thématisé (Lich King, Kel'Thuzad, Onyxia, Ragnaros, Illidan) avec portraits, HP fluctuant, casts simulés.
- Traductions Allemand, Espagnol, Italien, Portugais (Brésil) (en plus du Français).
- Tooltips partout, y compris sur les onglets.
- Lien Discord ajouté dans À propos.

### Modifié
- **Interface modernisée** avec le style WoW moderne (Portrait frame).
- Réorganisation des options : Disposition / Barres / Incantation / etc.

### Corrigé
- Tooltips manquants sur certains contrôles.
- Alignement des éléments.

## [0.4.x] - 2026-04

### Ajouté
- Modern UI portrait frame, scrollable LSM media dropdowns avec previews.
- Profile import/export avec confirmation d'overwrite.

### Corrigé
- Défauts de texture et de police.
- Bugs autour du texte HP/Power sur boss hostiles.

## [0.3.x] - 2026-03

### Ajouté
- Contrôles de fond de frame.
- Modes de couleur pour la surbrillance de cible.
- Stubs locales DE / ES / IT / PT-BR.

## [0.2.0] - 2026-02

### Ajouté
- Système de profils, icône minimap, target highlight, color pickers.

## [0.1.0] - 2026-01

### Ajouté
- Release initiale : frames boss custom extraites de DandersFrames.
