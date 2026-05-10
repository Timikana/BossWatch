local addonName, BW = ...

if GetLocale() ~= "frFR" then return end

local L = BW.L

-- ============================================================
-- TABS
-- ============================================================
L["Layout"]      = "Disposition"
L["Bars"]        = "Barres"
L["Cast Bar"]    = "Incantation"
L["Text"]        = "Texte"
L["Raid Marker"] = "Marqueur"
L["Auras"]       = "Auras"
L["Profiles"]    = "Profils"
L["About"]       = "À propos"

-- ============================================================
-- PROFILES PAGE
-- ============================================================
L["Active profile"]                              = "Profil actif"
L["Character:"]                                  = "Personnage :"
L["New..."]                                      = "Nouveau..."
L["Reset"]                                       = "Réinitialiser"
L["Delete"]                                      = "Supprimer"
L["Name of the new profile (copies current settings):"] = "Nom du nouveau profil (copie les réglages actuels) :"
L["Name for the imported profile:"]              = "Nom du profil à importer :"
L["Reset profile '%s' to defaults?"]             = "Réinitialiser le profil '%s' aux valeurs par défaut ?"
L["Delete profile '%s'?"]                        = "Supprimer le profil '%s' ?"
L["cannot delete Default"]                       = "impossible de supprimer Default"
L["profile '%s' created"]                        = "profil '%s' créé"
L["profile '%s' imported"]                       = "profil '%s' importé"
L["import failed:"]                              = "échec de l'import :"
L["import box is empty"]                         = "la zone d'import est vide"
L["Export"]                                      = "Exporter"
L["Import"]                                      = "Importer"
L["Refresh export"]                              = "Rafraîchir l'export"
L["Select all"]                                  = "Tout sélectionner"
L["Import as new profile..."]                    = "Importer comme nouveau profil..."

-- ============================================================
-- WINDOW
-- ============================================================
L["BossWatch — Options"] = "BossWatch — Options"

-- ============================================================
-- LAYOUT PAGE
-- ============================================================
L["Unlock / Lock Mover"] = "Déverrouiller / Verrouiller"
L["Test:"]               = "Test :"
L["Off"]                 = "Off"
L["Enable"]              = "Activé"
L["Hide Blizzard"]       = "Cacher Blizzard"
L["Show minimap icon"]   = "Afficher l'icône minicarte"
L["left-click: options"] = "clic gauche : options"
L["right-click: toggle mover"] = "clic droit : afficher / cacher le mover"
L["Anchor"]              = "Ancrage"
L["Grow Direction"]      = "Direction"
L["Down"]                = "Bas"
L["Up"]                  = "Haut"
L["Offset X"]            = "Décalage X"
L["Offset Y"]            = "Décalage Y"
L["Width"]               = "Largeur"
L["Height"]              = "Hauteur"
L["Spacing"]             = "Espacement"
L["Scale"]               = "Échelle"
L["Portrait Position"]   = "Position du portrait"
L["Portrait Size"]       = "Taille du portrait"
L["Left"]                = "Gauche"
L["Right"]               = "Droite"
L["Hidden"]              = "Caché"

-- 9-point anchor
L["Top Left"]     = "Haut gauche"
L["Top"]          = "Haut"
L["Top Right"]    = "Haut droite"
L["Center"]       = "Centre"
L["Bottom Left"]  = "Bas gauche"
L["Bottom"]       = "Bas"
L["Bottom Right"] = "Bas droite"

-- ============================================================
-- BARS PAGE
-- ============================================================
L["Health Texture"]          = "Texture vie"
L["Power Texture"]           = "Texture ressource"
L["Background Texture"]      = "Texture du fond"
L["Show Power Bar"]          = "Afficher la ressource"
L["Power Bar Height"]        = "Hauteur ressource"
L["Health Color"]            = "Couleur de la vie"
L["Reaction (Blizzard)"]     = "Réaction (Blizzard)"
L["Class fallback"]          = "Couleur de classe"
L["Custom static"]           = "Personnalisée"
L["Static color"]            = "Couleur statique"
L["Click to choose a color"] = "Cliquer pour choisir une couleur"
L["Frame background alpha"]  = "Alpha fond du cadre"
L["HP background alpha"]     = "Alpha fond vie"
L["Power background alpha"]  = "Alpha fond ressource"

-- Target Highlight
L["Target Highlight"]         = "Surbrillance de la cible"
L["Highlight current target"] = "Surligner la cible actuelle"
L["Animate (pulse)"]          = "Animer (pulsation)"
L["Border color"]             = "Couleur de la bordure"
L["Border thickness"]         = "Épaisseur de la bordure"
L["Thickness"]                = "Épaisseur"
L["Color mode"]               = "Mode de couleur"
L["Static"]                   = "Statique"
L["Class color"]              = "Couleur de classe"
L["Reaction"]                 = "Réaction"

-- ============================================================
-- CAST BAR PAGE
-- ============================================================
L["Cast Bar Texture"]        = "Texture incantation"
L["Show Cast Bar"]           = "Afficher l'incantation"
L["Detached"]                = "Détachée"
L["Frame bg wraps cast zone"] = "Fond du cadre couvre la zone cast"
L["Cast Bar Height"]         = "Hauteur"
L["Icon Position"]           = "Position icône"
L["Cast bg alpha"]           = "Alpha fond"
L["Detached Anchor"]         = "Ancrage détaché"
L["Detached Width (0=auto)"] = "Largeur détachée (0=auto)"
L["Detached Offset X"]       = "Décalage X détaché"
L["Detached Offset Y"]       = "Décalage Y détaché"

-- ============================================================
-- TEXT PAGE
-- ============================================================
L["Show Name"]               = "Afficher le nom"
L["Name Position"]           = "Position du nom"
L["Name Offset X"]           = "Décalage X nom"
L["Name Offset Y"]           = "Décalage Y nom"
L["Name max length (0=off)"] = "Longueur max nom (0=off)"
L["Show Health Text"]        = "Afficher texte vie"
L["HP text position"]        = "Position texte vie"
L["HP text Offset X"]        = "Décalage X texte vie"
L["HP text Offset Y"]        = "Décalage Y texte vie"
L["HP format"]               = "Format vie"
L["Show Power Text"]         = "Afficher texte ressource"
L["Power format"]            = "Format ressource"
L["Percent (50%)"]           = "Pourcentage (50%)"
L["Raw (Blizzard native)"]   = "Brut (natif Blizzard)"
L["Current"]                 = "Actuel"
L["Current (raw)"]           = "Actuel (brut)"
L["Current (50M)"]           = "Actuel (50M)"
L["Current + Percent"]       = "Actuel + pourcentage"
L["Current / Max"]           = "Actuel / Max"

-- Font block
L["Font (applies to all text)"] = "Police (s'applique à tous les textes)"
L["Font"]         = "Police"
L["Font Size"]    = "Taille de police"
L["Outline"]      = "Contour"
L["None"]         = "Aucun"
L["Thick Outline"] = "Contour épais"

-- ============================================================
-- RAID MARKER PAGE
-- ============================================================
L["Show Raid Target Icon"] = "Afficher le marqueur de raid"
L["Position the raid target icon (skull, cross, star...) on each boss frame."] =
    "Positionne le marqueur de raid (crâne, croix, étoile…) sur chaque cadre de boss."
L["Size"]  = "Taille"
L["Alpha"] = "Alpha"

-- ============================================================
-- AURAS PAGE
-- ============================================================
L["Show Auras"]         = "Afficher les auras"
L["Filter"]             = "Filtre"
L["Debuffs (HARMFUL)"]  = "Affaiblissements (HARMFUL)"
L["Buffs (HELPFUL)"]    = "Améliorations (HELPFUL)"
L["Source"]             = "Source"
L["All (Blizzard-like)"] = "Toutes (style Blizzard)"
L["Only mine"]          = "Uniquement les miennes"
L["Hide mine"]          = "Cacher les miennes"
L["Boss-cast only"]     = "Lancées par le boss uniquement"
L["Max Count"]          = "Nombre max"
L["Show Stacks"]        = "Afficher les stacks"
L["Show Timer"]         = "Afficher le timer"
L["Grow X"]             = "Sens horizontal"
L["Timer Placement"]    = "Position du timer"
L["Inside (centered)"]  = "Dedans (centré)"
L["Below icon"]         = "Sous l'icône"
L["Above icon"]         = "Au-dessus de l'icône"

-- ============================================================
-- BLIZZARD SETTINGS REGISTRATION
-- ============================================================
L["Custom boss target frames — v%s\nClick the button below to open the BossWatch configuration panel."] =
    "Cadres de boss personnalisés — v%s\nCliquez sur le bouton ci-dessous pour ouvrir le panneau de configuration de BossWatch."
L["Open BossWatch options"]                = "Ouvrir les options de BossWatch"
L["You can also use the slash command: /bw"] = "Vous pouvez aussi utiliser la commande : /bw"

-- ============================================================
-- SLASH / CHAT
-- ============================================================
L["commands:"]                  = "commandes :"
L["open options"]               = "ouvrir les options"
L["toggle mover"]               = "afficher / cacher le mover"
L["simulate N bosses (0-5)"]    = "simuler N boss (0 à 5)"
L["reset all settings + reload"] = "réinitialiser et recharger l'UI"
L["|cffeda55fBossWatch|r v%s loaded — type |cffffff00/bw|r for options"] =
    "|cffeda55fBossWatch|r v%s chargé — tapez |cffffff00/bw|r pour les options"

-- ============================================================
-- ABOUT PAGE
-- ============================================================
L["Custom boss target frames for WoW Retail / Midnight 12.0."] =
    "Cadres de boss personnalisés pour WoW Retail / Midnight 12.0."
L["Author:"]                = "Auteur :"
L["GitHub repository:"]     = "Dépôt GitHub :"
L["Report an issue:"]       = "Signaler un problème :"
L["Slash commands"]         = "Commandes slash"
L["Click a URL to select it, then Ctrl+C to copy."] =
    "Cliquez sur une URL pour la sélectionner, puis Ctrl+C pour copier."

-- ============================================================
-- BETA UI: SECTION HEADERS + TOOLTIPS
-- ============================================================
L["Position"]           = "Position"
L["Texture"]            = "Texture"
L["Overwrite existing profile '%s'?"] = "Écraser le profil existant « %s » ?"
L["Discord (support / bugs / suggestions):"] = "Discord (support / bugs / suggestions) :"
L["3 blocks (compact)"]     = "3 blocs (compact)"
L["4 blocks (name on top)"] = "4 blocs (nom au-dessus)"
L["3 blocks: name is overlaid on the HP bar (compact). 4 blocks: name has its own dedicated row above the HP bar (more readable)."] = "3 blocs : le nom est superposé sur la barre de vie (compact). 4 blocs : le nom a sa propre rangée dédiée au-dessus de la barre de vie (plus lisible)."
L["Total height"]      = "Hauteur totale"
L["Power bar height"]  = "Hauteur barre ressource"
L["Cast bar height"]   = "Hauteur barre incantation"
L["Total height of each boss frame in pixels. The HP bar fills whatever space is left after the power and cast bars."] = "Hauteur totale de chaque cadre en pixels. La barre de vie occupe l'espace restant après les barres de ressource et d'incantation."
L["Height of the power bar in pixels (resource: mana, rage, energy, etc.)."] = "Hauteur de la barre de ressource en pixels (mana, rage, énergie, etc.)."
L["Absorbs"] = "Absorptions"
L["Experimental"] = "Expérimental"
L["Create a new profile by copying the current settings."] = "Créer un nouveau profil en copiant les réglages actuels."
L["Reset the active profile to default settings."] = "Remet le profil actif aux réglages par défaut."
L["Delete the active profile (cannot delete Default)."] = "Supprime le profil actif (impossible de supprimer Default)."
L["Re-generate the export string from the current profile settings."] = "Régénère la chaîne d'export à partir des réglages actuels du profil."
L["Highlight the export string so you can Ctrl+C copy it."] = "Sélectionne la chaîne d'export pour la copier avec Ctrl+C."
L["Paste a profile export string above and click here to import it as a new profile."] = "Colle une chaîne d'export de profil ci-dessus et clique ici pour l'importer comme un nouveau profil."
L["Switch the active profile for the current character. Each character can use a different profile."] = "Change le profil actif pour le personnage courant. Chaque personnage peut utiliser un profil différent."
L["How the HP value is displayed.\n\n|cffffd200Percent|r — uses UnitHealthPercent, always clean (50%).\n|cffffd200Raw|r — Blizzard native passthrough, may show K-prefixed or raw depending on magnitude.\n|cffffd200Current|r — Blizzard's AbbreviateLargeNumbers (K/M smart abbrev when applicable).\n|cffffd200Current + Percent|r — both combined.\n\nOn hostile boss frames, secret-tagged values limit what can be displayed; Blizzard's render is used as-is."] = "Comment la valeur PV est affichée.\n\n|cffffd200Pourcent|r — propre, toujours (50%).\n|cffffd200Brut|r — passthrough natif Blizzard, peut afficher du K ou du brut selon la magnitude.\n|cffffd200Actuel|r — abréviation intelligente K/M quand applicable.\n|cffffd200Actuel + Pourcent|r — les deux combinés.\n\nSur les boss hostiles, certaines valeurs sont masquées par Blizzard ; on affiche ce que le jeu nous donne."
L["Show absorbs / shields"] = "Afficher les absorptions / boucliers"
L["Absorb Texture"]         = "Texture absorption"
L["Absorb color"]           = "Couleur absorption"
L["Color and opacity of the absorb overlay. Default matches Blizzard's standard shield cyan."] = "Couleur et opacité de la surcouche d'absorption. Par défaut le cyan standard des boucliers Blizzard."
L["Status bar texture used for the absorb overlay."] = "Texture utilisée pour la surcouche d'absorption."
L["Display incoming damage absorbs (shields, bubbles) as a translucent overlay extending the health bar. May not show on bosses with secret-tagged values."] = "Affiche les absorptions de dégâts (boucliers, bulles) en surcouche translucide qui prolonge la barre de vie. Peut ne pas s'afficher sur les boss avec valeurs secrètes."
L["General"]            = "Général"
L["Dimensions"]         = "Dimensions"
L["Portrait"]           = "Portrait"
L["Textures"]           = "Textures"
L["Power Bar"]          = "Barre de ressource"
L["Health Color"]       = "Couleur de la vie"
L["Background Alpha"]   = "Opacité du fond"
L["Display"]            = "Affichage"
L["Detached Position"]  = "Position détachée"
L["Name"]               = "Nom"
L["Health Text"]        = "Texte vie"
L["Power Text"]         = "Texte ressource"
L["Raid Target Icon"]   = "Marqueur de raid"

L["alias"]                = "alias"
L["stop the simulation"]  = "arrêter la simulation"
L["Panel opacity"]        = "Opacité du panneau"
L["Opacity of this options window. Saved account-wide."] = "Opacité de cette fenêtre d'options. Sauvegardée pour tout le compte."

L["Toggle a draggable handle on the boss frames container so you can move it on screen."] = "Affiche une poignée pour déplacer les cadres de boss à l'écran."
L["Stop the simulation."] = "Arrête la simulation."
L["Simulate %d boss frame(s) with fake HP, casts and auras."] = "Simule %d cadre(s) de boss avec PV, incantations et auras factices."
L["Master switch for the addon. When off, BossWatch frames stay hidden."] = "Interrupteur principal. Désactivé, les cadres BossWatch restent masqués."
L["Hide the default Blizzard boss frames."] = "Masque les cadres de boss par défaut de Blizzard."
L["Show a minimap button to open the options. Left-click: options, right-click: toggle mover."] = "Affiche un bouton minicarte. Clic gauche : options, clic droit : poignée."
L["Anchor point on the screen used as origin for the X/Y offsets."] = "Point d'ancrage à l'écran servant d'origine aux décalages X/Y."
L["Direction the additional boss frames stack from the first one."] = "Direction d'empilement des cadres supplémentaires depuis le premier."
L["Horizontal offset from the anchor point."] = "Décalage horizontal depuis le point d'ancrage."
L["Vertical offset from the anchor point."] = "Décalage vertical depuis le point d'ancrage."
L["Width of each boss frame in pixels."] = "Largeur de chaque cadre en pixels."
L["Height of each boss frame in pixels."] = "Hauteur de chaque cadre en pixels."
L["Vertical gap between stacked boss frames."] = "Espacement vertical entre cadres empilés."
L["Overall scale of all boss frames."] = "Échelle globale des cadres."
L["Where the boss portrait icon is shown on the frame."] = "Position du portrait du boss sur le cadre."
L["Size of the boss portrait icon in pixels."] = "Taille du portrait en pixels."
L["Add a colored border around the boss frame matching your current target."] = "Ajoute une bordure colorée autour du cadre correspondant à votre cible."
L["Pulsing animation on the highlight border."] = "Animation pulsante de la bordure."
L["Border thickness of the highlight in pixels."] = "Épaisseur de la bordure en pixels."
L["How the highlight border is colored: fixed color, target's class, or reaction."] = "Coloration : couleur fixe, classe de la cible, ou réaction."
L["Fixed color used when the mode above is set to 'Static'."] = "Couleur fixe utilisée quand le mode est « Statique »."
L["Status bar texture used for the boss health bar."] = "Texture de barre utilisée pour la vie du boss."
L["Status bar texture used for the boss power (mana / rage / etc.) bar."] = "Texture de barre utilisée pour la ressource du boss (mana / rage / etc.)."
L["Texture used behind the bars (the empty / dark portion)."] = "Texture utilisée derrière les barres (portion vide / sombre)."
L["Display the power bar below the health bar."] = "Affiche la barre de ressource sous la barre de vie."
L["Height of the power bar in pixels."] = "Hauteur de la barre de ressource en pixels."
L["How the health bar is colored: by reaction (red/yellow/green), by class, or one fixed color."] = "Coloration de la vie : par réaction (rouge/jaune/vert), classe, ou couleur fixe."
L["Fixed color used when the mode above is set to 'Custom static'."] = "Couleur fixe utilisée quand le mode est « Personnalisé »."
L["Opacity of the dark frame backdrop behind everything."] = "Opacité du fond sombre derrière tout le cadre."
L["Opacity of the empty (un-filled) part of the health bar."] = "Opacité de la partie vide de la barre de vie."
L["Opacity of the empty part of the power bar."] = "Opacité de la partie vide de la barre de ressource."
L["When on, the frame background extends down to include the cast bar area."] = "Activé, le fond du cadre s'étend jusqu'à la zone d'incantation."
L["Status bar texture used for the cast bar fill."] = "Texture utilisée pour le remplissage de la barre d'incantation."
L["Show a cast bar under the boss frame when it's casting."] = "Affiche une barre d'incantation pendant les sorts."
L["Detach the cast bar from the boss frame so you can place it anywhere on screen."] = "Détache la barre d'incantation du cadre pour la placer où vous voulez."
L["Height of the cast bar in pixels."] = "Hauteur de la barre d'incantation en pixels."
L["Side of the cast bar where the spell icon is shown."] = "Côté où l'icône du sort est affichée."
L["Opacity of the cast bar's empty/background portion."] = "Opacité du fond / portion vide de la barre."
L["Screen anchor used as origin when the cast bar is detached."] = "Ancrage utilisé quand la barre est détachée."
L["Width of the detached cast bar. 0 keeps the boss frame width."] = "Largeur de la barre détachée. 0 conserve la largeur du cadre."
L["Horizontal offset from the detached anchor."] = "Décalage horizontal depuis l'ancrage détaché."
L["Vertical offset from the detached anchor."] = "Décalage vertical depuis l'ancrage détaché."
L["Show the boss name on the frame."] = "Affiche le nom du boss sur le cadre."
L["Anchor point where the name is attached on the frame."] = "Point d'ancrage du nom sur le cadre."
L["Horizontal offset of the name from its anchor."] = "Décalage horizontal du nom."
L["Vertical offset of the name from its anchor."] = "Décalage vertical du nom."
L["Trim the name after this many characters. 0 disables trimming."] = "Tronque le nom après ce nombre de caractères. 0 désactive."
L["Visually clip the name to roughly this many characters (~7px each). 0 disables. Works on real bosses too — width-based, not string-based."] = "Tronque visuellement le nom à environ ce nombre de caractères (~7 px chacun). 0 désactive. Marche aussi sur les vrais boss — basé sur la largeur, pas sur la string."

L["Number scale"]            = "Échelle des nombres"
L["Auto (smart)"]            = "Auto (intelligent)"
L["Raw (full number)"]       = "Brut (nombre complet)"
L["Thousands (K)"]           = "Milliers (K)"
L["Millions (M)"]            = "Millions (M)"
L["Billions (B)"]            = "Milliards (B)"
L["How current and max numbers are scaled when displayed.\n\n|cffffd200Auto|r picks the best magnitude (e.g. 14.4M).\n|cffffd200Raw|r shows the full number as Blizzard renders it.\n|cffffd200K/M/B|r force a specific scale."] = "Comment les valeurs actuelles et max sont mises à l'échelle.\n\n|cffffd200Auto|r choisit la meilleure magnitude (ex: 14.4M).\n|cffffd200Brut|r affiche le nombre complet tel que rendu par Blizzard.\n|cffffd200K/M/B|r forcent une échelle spécifique."
L["Display HP value as text on the health bar."] = "Affiche la valeur des PV sur la barre."
L["Anchor point of the HP text on the bar."] = "Point d'ancrage du texte PV sur la barre."
L["Horizontal offset of the HP text."] = "Décalage horizontal du texte PV."
L["Vertical offset of the HP text."] = "Décalage vertical du texte PV."
L["Format of the HP value: percent, current, both, or current/max."] = "Format des PV : pourcent, actuel, les deux, ou actuel/max."
L["Format of the HP value: percent, current, both, or current/max.\n\n|cffffd200Note:|r Blizzard now bucketizes boss HP percent (10%, 5%, 1%, 0%) — at low HP the value may read 0% while the boss still has HP left. Use 'Current' or 'Current / Max' for a more granular view."] = "Format des PV : pourcent, actuel, les deux, ou actuel/max.\n\n|cffffd200Note :|r Blizzard regroupe désormais le pourcentage de PV des boss par paliers (10%, 5%, 1%, 0%) — à très bas PV la valeur peut afficher 0% alors qu'il reste encore des PV. Utilise « Actuel » ou « Actuel / Max » pour une vue plus précise."
L["Display power value as text on the power bar."] = "Affiche la valeur de ressource en texte."
L["Format of the power value."] = "Format de la valeur de ressource."
L["Format of the power value. On hostile bosses with secret-tagged values, only Percent and Current (raw) work."] = "Format de la valeur de ressource. Sur les boss hostiles avec valeurs secrètes, seuls Pourcentage et Actuel (brut) fonctionnent."
L["CurseForge:"]                = "CurseForge :"
L["Wago:"]                      = "Wago :"
L["Font used for every text on the boss frames."] = "Police utilisée pour tous les textes des cadres."
L["Base font size in points."] = "Taille de police de base en points."
L["Black outline drawn around text for readability."] = "Contour noir autour du texte pour la lisibilité."
L["Display the raid target icon (if any) over each boss frame."] = "Affiche le marqueur de raid (s'il y en a) sur chaque cadre."
L["Anchor point of the raid icon on the frame."] = "Point d'ancrage du marqueur sur le cadre."
L["Horizontal offset of the raid icon."] = "Décalage horizontal du marqueur."
L["Vertical offset of the raid icon."] = "Décalage vertical du marqueur."
L["Size of the raid icon in pixels."] = "Taille du marqueur en pixels."
L["Opacity of the raid icon."] = "Opacité du marqueur."
L["Show buffs or debuffs on the boss frame."] = "Affiche les améliorations ou affaiblissements sur le cadre."
L["Which kind of auras to display: debuffs (HARMFUL) or buffs (HELPFUL)."] = "Type d'auras affichées : affaiblissements (HARMFUL) ou améliorations (HELPFUL)."
L["Filter by who applied the aura: anyone, only you, hide yours, or only boss-cast."] = "Filtrer par lanceur : tous, vous, masquer les vôtres, ou boss seulement."
L["Maximum number of aura icons displayed per frame."] = "Nombre max d'icônes d'auras par cadre."
L["Size of each aura icon in pixels."] = "Taille de chaque icône en pixels."
L["Gap between aura icons in pixels."] = "Espacement entre icônes en pixels."
L["Where the aura row attaches on the boss frame."] = "Point d'ancrage de la rangée d'auras sur le cadre."
L["Direction the icons stack horizontally from the anchor."] = "Sens d'empilement horizontal des icônes."
L["Horizontal offset of the aura row."] = "Décalage horizontal de la rangée."
L["Vertical offset of the aura row."] = "Décalage vertical de la rangée."
L["Display aura stack count when applicable."] = "Affiche le compteur de stacks quand applicable."
L["Display the remaining duration on the icon."] = "Affiche la durée restante sur l'icône."
L["Where the timer text is positioned relative to the icon."] = "Position du texte de durée par rapport à l'icône."

-- ============================================================
-- TAB TOOLTIPS
-- ============================================================
L["Frame placement, dimensions, mover, test mode, target highlight."] = "Position des cadres, dimensions, déplacement, mode test, surbrillance de cible."
L["Health, power and absorb bar textures and colors."]                = "Textures et couleurs des barres de vie, ressource et absorption."
L["Cast bar texture, position, detached mode."]                       = "Texture, position et mode détaché de la barre d'incantation."
L["Name, HP, power text formats, and global font."]                   = "Formats du nom, des PV, de la ressource, et police globale."
L["Raid target icon (skull, cross, star...) display."]                = "Affichage de l'icône de cible de raid (tête de mort, croix, étoile…)."
L["Buffs and debuffs filtering, source, layout."]                     = "Filtrage des buffs/debuffs, source et disposition."
L["Per-character profiles, import/export."]                           = "Profils par personnage, import/export."
L["Version, links, slash commands."]                                  = "Version, liens et commandes slash."

-- ============================================================
-- ABOUT / PROFILES MISC TOOLTIPS
-- ============================================================
L["Click to select, then Ctrl+C to copy."]                                            = "Cliquer pour sélectionner, puis Ctrl+C pour copier."
L["Export string for the active profile. Click Select All then Ctrl+C to copy."]     = "Chaîne d'export du profil actif. Clic sur Tout sélectionner puis Ctrl+C pour copier."
L["Paste a profile export string here, then click Import to create a new profile."]   = "Collez ici une chaîne d'export, puis cliquez sur Importer pour créer un nouveau profil."
L["Open the floating BossWatch options panel."]                                      = "Ouvre le panneau d'options flottant de BossWatch."
L["Drag to resize the options window. Saved account-wide."]                          = "Glisser pour redimensionner la fenêtre d'options. Sauvegardé pour tout le compte."
L["Click to collapse/expand this section."]                                          = "Cliquer pour replier/déplier cette section."
L["Reset this section to default values."]                                           = "Réinitialiser cette section aux valeurs par défaut."
L["Reset window size"]                                                               = "Réinitialiser la fenêtre"
L["Reset the options window to its default size and position."]                      = "Remet la fenêtre d'options à sa taille et sa position par défaut."
L["Search options…"]                                                                 = "Rechercher…"
L["Filter the panel: type any keyword from a label or tooltip. Sections without a match are auto-collapsed."] = "Filtrer le panneau : tape un mot-clé d'un libellé ou d'une astuce. Les sections sans correspondance se replient automatiquement."
L["Clear the search."]                                                               = "Effacer la recherche."
L["No options match your search."]                                                   = "Aucune option ne correspond à ta recherche."
L["Smooth bar animation"]                                                            = "Animation fluide des barres"
L["Animate the health bar between values instead of jumping. Disable for instant updates."] = "Anime la barre de vie entre les valeurs au lieu de sauter. Désactive pour des mises à jour instantanées."
L["Click actions on boss frames"]                                                    = "Actions au clic sur les cadres de boss"
L["Enable modifier+click shortcuts on boss frames: Shift+Click cycles a raid marker, Ctrl+Click sets focus."] = "Active les raccourcis modificateur+clic : Maj+Clic fait tourner les marqueurs de raid, Ctrl+Clic met en focus."

-- ============================================================
-- SECTION HEADERS (UI reorg)
-- ============================================================
L["Actions"]      = "Actions"
L["Layout style"] = "Style de mise en page"
L["Health"]       = "Vie"
L["Power"]        = "Ressource"
L["Background"]   = "Arrière-plan"
L["Spell Icon"]   = "Icône du sort"
