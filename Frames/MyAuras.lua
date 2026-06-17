local addonName, BossW = ...

-- MyAuras — combat-log tracker for auras applied by the player or their pet.
--
-- Why this exists: on Retail Midnight 12.0+, the aura fields
-- `isFromPlayerOrPlayerPet` and `sourceUnit` are SECRET-TAGGED on hostile
-- (boss) units. Comparing or string-matching them taints execution and
-- isn't reliable inside pcall. So `aurasSource = "MINE"` couldn't be
-- answered correctly from the C_UnitAuras data alone.
--
-- Combat-log events ARE NOT subject to that secret-tagging. We listen to
-- SPELL_AURA_APPLIED / REFRESH / APPLIED_DOSE / REMOVED, filter by the
-- COMBATLOG_OBJECT_AFFILIATION_MINE source flag (which covers the player
-- AND their pet/vehicle), and maintain a per-target set of spell IDs the
-- player has applied. Auras.lua then queries this set as the primary
-- signal for "MINE" / "NOT_MINE" filtering.
--
-- Public API:
--   BossW.MyAuras:IsMine(targetGUID, spellId) -> boolean
--   BossW.MyAuras:ClearTarget(targetGUID)              -- on UNIT_DIED
--   BossW.MyAuras:Wipe()                                -- on zone change

local bit_band            = bit and bit.band
local GetTime             = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame         = CreateFrame
local AFFIL_MINE          = COMBATLOG_OBJECT_AFFILIATION_MINE or 0x00000001

local mine = {}  -- mine[destGUID][spellId] = appliedAt (GetTime)
local lastPrune = 0

local MyAuras = {}
BossW.MyAuras = MyAuras

function MyAuras:IsMine(guid, spellId)
    if not guid or not spellId then return false end
    local t = mine[guid]
    return t and t[spellId] ~= nil
end

function MyAuras:ClearTarget(guid)
    if guid then mine[guid] = nil end
end

function MyAuras:Wipe()
    wipe(mine)
end

-- Prune entries older than ten minutes — defensive, in case UNIT_DIED is
-- never observed for a mob we tagged (despawn, phasing, dispel without
-- combat-log SPELL_AURA_REMOVED, etc.).
local function _prune(now)
    if (now - lastPrune) < 60 then return end
    lastPrune = now
    local cutoff = now - 600
    for guid, t in pairs(mine) do
        local any = false
        for spellId, appliedAt in pairs(t) do
            if appliedAt < cutoff then t[spellId] = nil else any = true end
        end
        if not any then mine[guid] = nil end
    end
end

-- Single combat-log frame, very tight handler — this fires on every line
-- of combat log so it must do nothing more than table writes for events
-- we care about.
--
-- IMPORTANT: COMBAT_LOG_EVENT_UNFILTERED triggers ADDON_ACTION_FORBIDDEN
-- on Retail Midnight 12.0+ when subscribed in any context that shares its
-- Lua thread with BossWatch.lua's own PLAYER_LOGIN handler (which builds
-- SecureUnitButton frames and taints the thread). First reported by
-- Smuglerz (v0.8.0, fixed in v0.8.1 by deferring to PLAYER_LOGIN); still
-- triggered on Klav / warcraftiiitft (v0.8.1) because the same handler
-- chain is involved. The robust pattern is to escape the current Lua
-- thread entirely via C_Timer.After(0, ...) — the callback runs on the
-- next frame tick in a fresh, untainted execution context.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")

ev:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Defer registration onto the next frame tick. RegisterEvent is
        -- idempotent so it's safe to call once here; we never re-arm it.
        C_Timer.After(0, function()
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
        end)
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        MyAuras:Wipe()
        return
    end

    -- COMBAT_LOG_EVENT_UNFILTERED — no args; pull from CombatLogGetCurrentEventInfo.
    local _, sub, _, _, _, sourceFlags, _, destGUID, _, _, _, spellId =
        CombatLogGetCurrentEventInfo()

    if not destGUID or not spellId then return end

    -- Only events that change the player's auras on a target.
    local apply  = (sub == "SPELL_AURA_APPLIED")
                or (sub == "SPELL_AURA_REFRESH")
                or (sub == "SPELL_AURA_APPLIED_DOSE")
    local remove = (sub == "SPELL_AURA_REMOVED")
    if not (apply or remove) then return end

    -- Player + pet + vehicle all carry the MINE affiliation flag. Other
    -- raiders / friendly NPCs don't, so this is the right gate.
    if not bit_band or bit_band(sourceFlags or 0, AFFIL_MINE) == 0 then return end

    if apply then
        local now = GetTime()
        local t = mine[destGUID]
        if not t then t = {}; mine[destGUID] = t end
        t[spellId] = now
        _prune(now)
    else
        local t = mine[destGUID]
        if t then t[spellId] = nil end
    end
end)
