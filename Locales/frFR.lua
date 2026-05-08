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
