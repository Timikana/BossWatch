local addonName, BossW = ...

-- SlotProvider — abstraction between BossFrames and the underlying unit tokens.
--
-- On Retail / Midnight / MoP Classic / Cata / Wrath / TBC, unit IDs boss1..boss5
-- are provided directly by the game client. The trivial provider in this file
-- just hands them back unchanged.
--
-- On Vanilla / Classic Era / SoD (where boss1..5 do NOT exist), a different
-- provider — Frames/SodSlotProvider.lua — is loaded by BossWatch-Vanilla.toc
-- AFTER this file and overrides BossW.SlotProvider with a target+nameplate
-- scanner producing dynamic unit tokens.
--
-- Consumers (Frames/Boss.lua, Frames/CastBar.lua, Frames/Auras.lua) interact
-- with the provider only — they never build "boss" .. i directly. That keeps
-- Boss.lua / CastBar.lua / Auras.lua client-agnostic.

local provider = {
    -- Number of slots managed. Locked to BossW.MAX_BOSS on Retail/MoP because
    -- the game itself provides exactly boss1..boss5. SoD provider overrides.
    GetMaxSlots = function(self)
        return BossW.MAX_BOSS
    end,

    -- Return the unit token for slot i (1..MAX_BOSS), or nil if unassigned.
    -- On Retail/MoP, slot i always maps to "boss"..i; the token exists in the
    -- game globals regardless of whether a boss is actually engaged
    -- (UnitExists(token) will simply return false out of encounter).
    GetUnit = function(self, i)
        return "boss" .. i
    end,

    -- State-driver expression evaluated by the secure macro engine. Used to
    -- toggle the frame's visibility automatically when the underlying unit
    -- appears/disappears, without needing combat-unsafe Lua Show/Hide.
    GetVisibilityDriver = function(self, i)
        return "[@boss" .. i .. ",exists]show;hide"
    end,

    -- For UNIT_* events: given the unit argument, return the slot index this
    -- event belongs to, or nil to ignore the event. Replaces the inline
    -- `unit:match("^boss%d$")` filter used previously.
    EventFilter = function(self, unit)
        if not unit then return nil end
        local i = unit:match("^boss(%d)$")
        return i and tonumber(i) or nil
    end,

    -- Hook used by SoD provider to notify consumers that a slot now references
    -- a different unit (so they can re-RegisterUnitEvent, re-apply state
    -- drivers, re-build click macros, etc.). On Retail/MoP the slot ↔ unit
    -- mapping never changes, so the hook list stays empty and OnSlotChanged
    -- is never fired.
    _slotChangedCallbacks = {},
    OnSlotChanged = function(self, cb)
        self._slotChangedCallbacks[#self._slotChangedCallbacks + 1] = cb
    end,
    _fireSlotChanged = function(self, slotIndex, oldUnit, newUnit)
        for _, cb in ipairs(self._slotChangedCallbacks) do
            cb(slotIndex, oldUnit, newUnit)
        end
    end,
}

BossW.SlotProvider = provider
