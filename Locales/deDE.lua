local addonName, BW = ...

if GetLocale() ~= "deDE" then return end

local L = BW.L

-- TABS
L["Layout"]      = "Layout"
L["Bars"]        = "Balken"
L["Cast Bar"]    = "Zauberbalken"
L["Text"]        = "Text"
L["Raid Marker"] = "Schlachtzugsmarker"
L["Auras"]       = "Auren"
L["Profiles"]    = "Profile"
L["About"]       = "Über"

-- PROFILES
L["Active profile"]                              = "Aktives Profil"
L["Character:"]                                  = "Charakter:"
L["New..."]                                      = "Neu..."
L["Reset"]                                       = "Zurücksetzen"
L["Delete"]                                      = "Löschen"
L["Name of the new profile (copies current settings):"] = "Name des neuen Profils (kopiert aktuelle Einstellungen):"
L["Name for the imported profile:"]              = "Name für das importierte Profil:"
L["Reset profile '%s' to defaults?"]             = "Profil '%s' auf Standardwerte zurücksetzen?"
L["Delete profile '%s'?"]                        = "Profil '%s' löschen?"
L["cannot delete Default"]                       = "Default kann nicht gelöscht werden"
L["profile '%s' created"]                        = "Profil '%s' erstellt"
L["profile '%s' imported"]                       = "Profil '%s' importiert"
L["import failed:"]                              = "Import fehlgeschlagen:"
L["import box is empty"]                         = "Importfeld ist leer"
L["Export"]                                      = "Exportieren"
L["Import"]                                      = "Importieren"
L["Refresh export"]                              = "Export aktualisieren"
L["Select all"]                                  = "Alles auswählen"
L["Import as new profile..."]                    = "Als neues Profil importieren..."

-- WINDOW
L["BossWatch — Options"] = "BossWatch — Optionen"

-- LAYOUT
L["Unlock / Lock Mover"] = "Verschieben entsperren / sperren"
L["Test:"]               = "Test:"
L["Off"]                 = "Aus"
L["Enable"]              = "Aktiviert"
L["Hide Blizzard"]       = "Blizzard ausblenden"
L["Show minimap icon"]   = "Minikarten-Symbol anzeigen"
L["left-click: options"] = "Linksklick: Optionen"
L["right-click: toggle mover"] = "Rechtsklick: Verschieben umschalten"
L["Anchor"]              = "Anker"
L["Grow Direction"]      = "Wachstumsrichtung"
L["Down"]                = "Unten"
L["Up"]                  = "Oben"
L["Offset X"]            = "Versatz X"
L["Offset Y"]            = "Versatz Y"
L["Width"]               = "Breite"
L["Height"]              = "Höhe"
L["Spacing"]             = "Abstand"
L["Scale"]               = "Skalierung"
L["Portrait Position"]   = "Porträt-Position"
L["Portrait Size"]       = "Porträt-Größe"
L["Left"]                = "Links"
L["Right"]               = "Rechts"
L["Hidden"]              = "Versteckt"

-- 9-point anchor
L["Top Left"]     = "Oben links"
L["Top"]          = "Oben"
L["Top Right"]    = "Oben rechts"
L["Center"]       = "Mitte"
L["Bottom Left"]  = "Unten links"
L["Bottom"]       = "Unten"
L["Bottom Right"] = "Unten rechts"

-- BARS
L["Health Texture"]          = "Lebensbalken-Textur"
L["Power Texture"]           = "Ressourcenbalken-Textur"
L["Background Texture"]      = "Hintergrundtextur"
L["Show Power Bar"]          = "Ressourcenbalken anzeigen"
L["Power Bar Height"]        = "Höhe Ressourcenbalken"
L["Health Color"]            = "Lebensfarbe"
L["Reaction (Blizzard)"]     = "Reaktion (Blizzard)"
L["Class fallback"]          = "Klassenfarbe"
L["Custom static"]           = "Benutzerdefiniert"
L["Static color"]            = "Statische Farbe"
L["Click to choose a color"] = "Klicken, um Farbe zu wählen"
L["Frame background alpha"]  = "Alpha Rahmen-Hintergrund"
L["HP background alpha"]     = "Alpha Lebens-Hintergrund"
L["Power background alpha"]  = "Alpha Ressourcen-Hintergrund"

-- Target Highlight
L["Target Highlight"]         = "Ziel-Hervorhebung"
L["Highlight current target"] = "Aktuelles Ziel hervorheben"
L["Animate (pulse)"]          = "Animieren (pulsieren)"
L["Border color"]             = "Rahmenfarbe"
L["Border thickness"]         = "Rahmendicke"
L["Thickness"]                = "Dicke"
L["Color mode"]               = "Farbmodus"
L["Static"]                   = "Statisch"
L["Class color"]              = "Klassenfarbe"
L["Reaction"]                 = "Reaktion"

-- CAST BAR
L["Cast Bar Texture"]        = "Zauberbalken-Textur"
L["Show Cast Bar"]           = "Zauberbalken anzeigen"
L["Detached"]                = "Abgekoppelt"
L["Frame bg wraps cast zone"] = "Rahmen-Hintergrund deckt Zauberbereich"
L["Cast Bar Height"]         = "Höhe"
L["Icon Position"]           = "Symbol-Position"
L["Cast bg alpha"]           = "Alpha Hintergrund"
L["Detached Anchor"]         = "Abgekoppelter Anker"
L["Detached Width (0=auto)"] = "Abgekoppelte Breite (0=auto)"
L["Detached Offset X"]       = "Abgekoppelter Versatz X"
L["Detached Offset Y"]       = "Abgekoppelter Versatz Y"

-- TEXT
L["Show Name"]               = "Name anzeigen"
L["Name Position"]           = "Name-Position"
L["Name Offset X"]           = "Name-Versatz X"
L["Name Offset Y"]           = "Name-Versatz Y"
L["Name max length (0=off)"] = "Name max. Länge (0=aus)"
L["Show Health Text"]        = "Lebenstext anzeigen"
L["HP text position"]        = "Lebenstext-Position"
L["HP text Offset X"]        = "Lebenstext-Versatz X"
L["HP text Offset Y"]        = "Lebenstext-Versatz Y"
L["HP format"]               = "Lebensformat"
L["Show Power Text"]         = "Ressourcentext anzeigen"
L["Power format"]            = "Ressourcenformat"
L["Percent (50%)"]           = "Prozent (50%)"
L["Current (50M)"]           = "Aktuell (50M)"
L["Current + Percent"]       = "Aktuell + Prozent"
L["Current / Max"]           = "Aktuell / Max"

-- Font
L["Font (applies to all text)"] = "Schrift (gilt für alle Texte)"
L["Font"]         = "Schrift"
L["Font Size"]    = "Schriftgröße"
L["Outline"]      = "Umriss"
L["None"]         = "Keiner"
L["Thick Outline"] = "Dicker Umriss"

-- RAID MARKER
L["Show Raid Target Icon"] = "Schlachtzugsziel-Symbol anzeigen"
L["Position the raid target icon (skull, cross, star...) on each boss frame."] =
    "Positioniert das Schlachtzugsziel-Symbol (Totenkopf, Kreuz, Stern...) auf jedem Boss-Rahmen."
L["Size"]  = "Größe"
L["Alpha"] = "Alpha"

-- AURAS
L["Show Auras"]         = "Auren anzeigen"
L["Filter"]             = "Filter"
L["Debuffs (HARMFUL)"]  = "Schwächungszauber (HARMFUL)"
L["Buffs (HELPFUL)"]    = "Stärkungszauber (HELPFUL)"
L["Source"]             = "Quelle"
L["All (Blizzard-like)"] = "Alle (Blizzard-Stil)"
L["Only mine"]          = "Nur eigene"
L["Hide mine"]          = "Eigene ausblenden"
L["Boss-cast only"]     = "Nur Boss-gewirkte"
L["Max Count"]          = "Max. Anzahl"
L["Show Stacks"]        = "Stapel anzeigen"
L["Show Timer"]         = "Timer anzeigen"
L["Grow X"]             = "Wachstum X"
L["Timer Placement"]    = "Timer-Position"
L["Inside (centered)"]  = "Innen (zentriert)"
L["Below icon"]         = "Unter dem Symbol"
L["Above icon"]         = "Über dem Symbol"

-- BLIZZARD SETTINGS
L["Custom boss target frames — v%s\nClick the button below to open the BossWatch configuration panel."] =
    "Benutzerdefinierte Boss-Zielrahmen — v%s\nKlicke unten, um die BossWatch-Optionen zu öffnen."
L["Open BossWatch options"]                = "BossWatch-Optionen öffnen"
L["You can also use the slash command: /bw"] = "Du kannst auch den Slash-Befehl verwenden: /bw"

-- SLASH
L["commands:"]                  = "Befehle:"
L["open options"]               = "Optionen öffnen"
L["toggle mover"]               = "Verschieben umschalten"
L["simulate N bosses (0-5)"]    = "N Bosse simulieren (0-5)"
L["reset all settings + reload"] = "alle Einstellungen zurücksetzen + neu laden"
L["|cffeda55fBossWatch|r v%s loaded — type |cffffff00/bw|r for options"] =
    "|cffeda55fBossWatch|r v%s geladen — gib |cffffff00/bw|r für Optionen ein"

-- ABOUT
L["Custom boss target frames for WoW Retail / Midnight 12.0."] =
    "Benutzerdefinierte Boss-Zielrahmen für WoW Retail / Midnight 12.0."
L["Author:"]                = "Autor:"
L["GitHub repository:"]     = "GitHub-Repository:"
L["Report an issue:"]       = "Problem melden:"
L["Slash commands"]         = "Slash-Befehle"
L["Click a URL to select it, then Ctrl+C to copy."] =
    "Klicke auf eine URL, um sie auszuwählen, dann Strg+C zum Kopieren."
