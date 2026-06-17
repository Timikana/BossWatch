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
-- IMPORTANT: on Retail Midnight 12.0+, `RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")`
-- is rejected whenever ANY tainted Lua frame sits on the caller's stack
-- — only the caller matters, not the frame being registered on. So any
-- of BossWatch.lua / ElvUI / Auctionator / DBM running their PLAYER_LOGIN
-- handler before us taints the stack for the rest of the tick.
--
-- The robust pattern (used by several major addons after the same dance
-- in v0.8.0 → v0.8.1 → v0.8.2) is:
--   1. C_Timer.After(0, ...)   — re-enter from C-side timer dispatcher
--                                  on a fresh stack
--   2. Verify with IsEventRegistered AFTER the call — RegisterEvent
--                                  fails silently on taint, no pcall catches it
--   3. Exponential backoff retry until success
-- so one unlucky tainted tick never permanently disables the tracker.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")

local BACKOFF = { 0, 0.25, 1, 3, 10, 30 }

local function _tryRegisterCombatLog(self, attempt)
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
        -- Success — also wire the zone-change reset event now.
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        return
    end
    attempt = attempt + 1
    local delay = BACKOFF[attempt]
    if not delay then return end -- give up after the longest backoff
    C_Timer.After(delay, function() _tryRegisterCombatLog(self, attempt) end)
end

ev:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0, function() _tryRegisterCombatLog(self, 0) end)
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
