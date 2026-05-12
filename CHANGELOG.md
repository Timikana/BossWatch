# Changelog

Toutes les versions notables de **BossWatch** sont listées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versionnage selon [SemVer](https://semver.org/lang/fr/).

## [Unreleased]

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
