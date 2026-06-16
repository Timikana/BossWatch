local addonName, BossW = ...

-- SoD / Classic Era slot provider.
-- Loaded ONLY by BossWatch-Vanilla.toc, AFTER Frames/SlotProvider.lua, so it
-- replaces the trivial provider that ships with Retail/MoP.
--
-- The Vanilla/SoD client does not expose boss1..boss5 unit tokens (those were
-- introduced in Cataclysm 4.0). Instead, this module scans:
--   - target / mouseover
--   - nameplate1..40
-- and keeps a dynamic mapping slot index -> live unit token. Each visible
-- hostile NPC matching the configured classification filters (worldboss,
-- elite, rareelite, optionally rare) is assigned to the first free slot and
-- holds it until the unit dies, the player leaves the zone, or the unit's
-- token has gone missing for sodReleaseDelay seconds out of combat.

local UnitExists, UnitGUID, UnitIsDead = UnitExists, UnitGUID, UnitIsDead
local UnitClassification, UnitCanAttack = UnitClassification, UnitCanAttack
local InCombatLockdown, GetTime = InCombatLockdown, GetTime
local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

-- ============================================================
-- Configuration (read once at load — /reload to apply changes)
-- ============================================================
local function _readDB()
    -- BossWatchDB is restored before this file runs, but the active profile
    -- depends on the character which we don't reliably know until login.
    -- Fall back to "Default" profile, then to bare defaults.
    local db = (BossWatchDB and BossWatchDB.profiles and BossWatchDB.profiles.Default) or {}
    return {
        maxSlots          = math.min(8, math.max(3, db.maxBossSoD or 5)),
        includeWorldBoss  = db.sodIncludeWorldBosses ~= false,
        includeRareElite  = db.sodIncludeRareElites  ~= false,
        includeElite      = db.sodIncludeElites      ~= false,
        includeRare       = db.sodIncludeRares       == true,
        releaseDelay      = tonumber(db.sodReleaseDelay) or 5,
    }
end

local CFG = _readDB()

-- Raise BossW.MAX_BOSS to the SoD cap so Boss/CastBar/Auras allocate enough
-- frames. Must happen BEFORE they capture MAX_BOSS as an upvalue (enforced
-- by the .toc load order).
BossW.MAX_BOSS = math.max(BossW.MAX_BOSS or 5, CFG.maxSlots)

-- Marker checked by Options/Panel.lua to decide whether to show the
-- Classic / SoD tab. True on any client where this file is loaded —
-- Classic Era / SoD, and TBC Anniversary (both lack boss1..5 unit IDs).
BossW._sodMode = true

-- ============================================================
-- Slot state
-- ============================================================
-- slots[i] = { unit = "nameplate12", guid = "Creature-...", lastSeen = GetTime() }
-- or nil if the slot is unassigned.
local slots = {}

local function _classifiesAsBoss(unit)
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsDead(unit) then return false end
    local c = UnitClassification(unit)
    if c == "worldboss"  and CFG.includeWorldBoss  then return true end
    if c == "rareelite"  and CFG.includeRareElite  then return true end
    if c == "elite"      and CFG.includeElite      then return true end
    if c == "rare"       and CFG.includeRare       then return true end
    return false
end

local function _slotOfGUID(guid)
    if not guid then return nil end
    for i, s in pairs(slots) do
        if s.guid == guid then return i end
    end
    return nil
end

local function _firstFreeSlot()
    for i = 1, CFG.maxSlots do
        if not slots[i] then return i end
    end
    return nil
end

-- ============================================================
-- Provider API (overrides Frames/SlotProvider.lua)
-- ============================================================
local provider = BossW.SlotProvider  -- already created by SlotProvider.lua

function provider:GetMaxSlots()
    return CFG.maxSlots
end

function provider:GetUnit(i)
    local s = slots[i]
    return s and s.unit or nil
end

function provider:GetVisibilityDriver(i)
    local s = slots[i]
    if not s or not s.unit then
        -- No assigned token → empty driver; the consumer will fall back to
        -- explicit Hide() via the slot-changed callback below.
        return "hide"
    end
    return "[@" .. s.unit .. ",exists]show;hide"
end

function provider:EventFilter(unit)
    if not unit then return nil end
    for i, s in pairs(slots) do
        if s.unit == unit then return i end
    end
    return nil
end

-- ============================================================
-- Assignment / release
-- ============================================================
local function _assign(unit)
    if not _classifiesAsBoss(unit) then return end
    local guid = UnitGUID(unit)
    if not guid then return end
    if _slotOfGUID(guid) then
        -- Already tracked — refresh unit token (it can change as the nameplate
        -- moves through the nameplate token pool) and lastSeen.
        local i = _slotOfGUID(guid)
        local old = slots[i].unit
        slots[i].unit = unit
        slots[i].lastSeen = GetTime()
        if old ~= unit then provider:_fireSlotChanged(i, old, unit) end
        return
    end
    local i = _firstFreeSlot()
    if not i then return end -- all slots full, ignore extra elites
    slots[i] = { unit = unit, guid = guid, lastSeen = GetTime() }
    provider:_fireSlotChanged(i, nil, unit)
end

local function _markStale(unit)
    for _, s in pairs(slots) do
        if s.unit == unit then s.lastSeen = GetTime() - 0.001; s.unit = nil end
    end
end

local function _releaseSlot(i)
    local s = slots[i]
    if not s then return end
    local old = s.unit
    slots[i] = nil
    provider:_fireSlotChanged(i, old, nil)
end

local function _releaseByGUID(guid)
    local i = _slotOfGUID(guid)
    if i then _releaseSlot(i) end
end

local function _sweep()
    if InCombatLockdown() then return end
    local now = GetTime()
    for i, s in pairs(slots) do
        if not s.unit or not UnitExists(s.unit) then
            if (now - s.lastSeen) > CFG.releaseDelay then
                _releaseSlot(i)
            end
        end
    end
end

local function _flushAll()
    for i in pairs(slots) do _releaseSlot(i) end
end

-- ============================================================
-- Event wiring
-- ============================================================
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

ev:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "PLAYER_LOGIN" then
        -- Refresh config now that the player's profile is bound.
        CFG = _readDB()
        BossW.MAX_BOSS = math.max(BossW.MAX_BOSS or 5, CFG.maxSlots)
        -- Friendly warning if enemy nameplates are off — the user will think
        -- the addon is broken otherwise.
        local cvarOn = GetCVar and GetCVar("nameplateShowEnemies") == "1"
        if not cvarOn then
            print("|cffeda55fBossWatch:|r " .. (BossW.L
                and BossW.L["enable enemy nameplates (Ctrl-V) for SoD elite auto-detection"]
                or "enable enemy nameplates (Ctrl-V) for SoD elite auto-detection"))
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        _flushAll()
    elseif event == "PLAYER_REGEN_ENABLED" then
        _sweep()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        _assign(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        _markStale(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        _assign("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        _assign("mouseover")
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if sub == "UNIT_DIED" or sub == "PARTY_KILL" then
            _releaseByGUID(destGUID)
        end
    end
end)

-- Periodic sweeper for tokens that disappeared without a death event
-- (mob despawned, etc.). Cheap — runs every 2s only out of combat.
local sweeper = CreateFrame("Frame")
local accum = 0
sweeper:SetScript("OnUpdate", function(_, elapsed)
    accum = accum + elapsed
    if accum < 2 then return end
    accum = 0
    _sweep()
end)
