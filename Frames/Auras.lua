local addonName, BossW = ...

local CreateFrame = CreateFrame
local GetTime = GetTime
local format = string.format
local MAX_BOSS = BossW.MAX_BOSS

local function CreateAuraButton(parent, index)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(24, 24); b:Hide()
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
        local db = BossW:GetDB()
        if not db.aurasTooltip then return end
        if not self._unit then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local filter = db.aurasFilter or "HARMFUL"
        local shown = false
        -- Modern path: instance-ID-based tooltip (10.0+).
        if self._auraInstanceID then
            if filter == "HARMFUL" and GameTooltip.SetUnitDebuffByAuraInstanceID then
                shown = pcall(GameTooltip.SetUnitDebuffByAuraInstanceID, GameTooltip, self._unit, self._auraInstanceID)
            elseif filter == "HELPFUL" and GameTooltip.SetUnitBuffByAuraInstanceID then
                shown = pcall(GameTooltip.SetUnitBuffByAuraInstanceID, GameTooltip, self._unit, self._auraInstanceID)
            end
        end
        -- Legacy fallback: index-based (Classic + when modern API is missing).
        if not shown and self._auraIndex then
            shown = pcall(GameTooltip.SetUnitAura, GameTooltip, self._unit, self._auraIndex, filter)
        end
        if not shown then
            -- Last-resort: secret-tagged auras may refuse to populate the tooltip.
            -- Show a minimal placeholder so the user still gets feedback.
            GameTooltip:SetText(self._auraName or "")
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(b)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetPoint("TOPLEFT", b, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 0.9)
    border:SetDrawLayer("BACKGROUND")
    b.border = border

    local cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    cd:SetAllPoints(b)
    cd:SetHideCountdownNumbers(true)
    cd:SetDrawEdge(false); cd:SetDrawSwipe(true)
    b.cd = cd

    local stackFont = _G["NumberFontNormalSmall"]
    local stacks = cd:CreateFontString(nil, "OVERLAY", nil)
    stacks:SetFontObject(stackFont)
    stacks:SetTextColor(1, 1, 1)
    stacks:SetDrawLayer("OVERLAY", 7)
    b.stacks = stacks

    local timer = cd:CreateFontString(nil, "OVERLAY", nil)
    timer:SetFontObject(stackFont)
    timer:SetTextColor(1, 0.85, 0.1)
    timer:SetDrawLayer("OVERLAY", 7)
    b.timer = timer

    b.index = index
    return b
end

local function ensurePool(frame, count)
    frame._auras = frame._auras or {}
    for i = 1, count do
        if not frame._auras[i] then
            frame._auras[i] = CreateAuraButton(frame, i)
        end
    end
    for i = count + 1, #frame._auras do frame._auras[i]:Hide() end
end

local function formatTime(s)
    if s <= 0 then return "" end
    if s < 10 then return format("%.1f", s) end
    if s < 60 then return format("%d", s) end
    if s < 3600 then return format("%dm", s / 60) end
    return format("%dh", s / 3600)
end

-- ============================================================
-- AURA COLLECTION + SOURCE FILTER
-- ============================================================
local function auraMatchesSource(data, source)
    if source == "ALL" or not source then return true end

    local mine = false
    do
        local ok, v = pcall(function()
            if data.isFromPlayerOrPlayerPet ~= nil then
                return data.isFromPlayerOrPlayerPet == true
            end
            local s = data.sourceUnit
            return s == "player" or s == "pet" or s == "vehicle"
        end)
        if ok then mine = v or false end
    end

    if source == "MINE" then return mine end
    if source == "NOT_MINE" then return not mine end
    if source == "BOSS_ONLY" then
        local okBoss, isBoss = pcall(function() return data.isBossAura == true end)
        if okBoss and isBoss then return true end
        local okSrc, v = pcall(function()
            local s = data.sourceUnit
            return s and s:match("^boss") and true or false
        end)
        return okSrc and v or false
    end
    return true
end

local auraBuffer = {}
local function collectAuras(unit, filter, source, maxCount)
    wipe(auraBuffer)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local data = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if not data then break end
            data._auraIndex = i  -- preserved for tooltip fallback
            if auraMatchesSource(data, source) then
                auraBuffer[#auraBuffer + 1] = data
                if #auraBuffer >= maxCount then break end
            end
        end
    else
        for i = 1, 40 do
            -- Position 12 (isBossDebuff) is available since MoP. Populating
            -- data.isBossAura makes the BOSS_ONLY filter exact instead of
            -- falling back to the fragile sourceUnit:match("^boss") test.
            local name, icon, count, _, duration, expiration, caster,
                  _, _, _, _, isBossDebuff = UnitAura(unit, i, filter)
            if not name then break end
            local data = {
                name = name, icon = icon, applications = count or 0,
                duration = duration or 0, expirationTime = expiration or 0,
                sourceUnit = caster,
                isBossAura = isBossDebuff or false,
                _auraIndex = i,  -- preserved for tooltip
            }
            if auraMatchesSource(data, source) then
                auraBuffer[#auraBuffer + 1] = data
                if #auraBuffer >= maxCount then break end
            end
        end
    end
    return auraBuffer
end

-- ============================================================
-- LAYOUT + UPDATE
-- ============================================================
function BossW.LayoutAuras(frame, db)
    if not db.showAuras then
        if frame._auras then for _, b in ipairs(frame._auras) do b:Hide() end end
        return
    end

    local maxCount = math.min(math.max(db.aurasMaxCount or 3, 1), 8)
    ensurePool(frame, maxCount)

    local size = db.aurasSize or 22
    local spacing = db.aurasSpacing or 2
    local anchor = db.aurasAnchor or "TOPRIGHT"
    local growX = db.aurasGrowX or "LEFT"
    local ox, oy = db.aurasX or 0, db.aurasY or 0
    local dx = (growX == "LEFT") and -(size + spacing) or (size + spacing)

    for i = 1, maxCount do
        local b = frame._auras[i]
        b:SetSize(size, size)
        b:ClearAllPoints()
        if i == 1 then
            b:SetPoint(anchor, frame, anchor, ox, oy)
        else
            b:SetPoint(anchor, frame._auras[i - 1], anchor, dx, 0)
        end

        if b.stacks then
            b.stacks:ClearAllPoints()
            local sa = db.aurasStackAnchor or "BOTTOMRIGHT"
            b.stacks:SetPoint(sa, b, sa, db.aurasStackX or 0, db.aurasStackY or 0)
        end

        if b.timer then
            b.timer:ClearAllPoints()
            local place = db.aurasTimerPlacement or "BELOW"
            local tx, ty = db.aurasTimerX or 0, db.aurasTimerY or 0
            if place == "BELOW" then b.timer:SetPoint("TOP", b, "BOTTOM", tx, ty - 1)
            elseif place == "ABOVE" then b.timer:SetPoint("BOTTOM", b, "TOP", tx, ty + 1)
            else b.timer:SetPoint("CENTER", b, "CENTER", tx, ty) end
        end
    end
end

function BossW.UpdateAuras(frame)
    local db = BossW:GetDB()
    if not db.showAuras or not frame._auras then
        if frame._auras then for _, b in ipairs(frame._auras) do b:Hide() end end
        return
    end

    local maxCount = math.min(math.max(db.aurasMaxCount or 3, 1), 8)

    if frame._testMode then
        local now = GetTime()
        if not frame._testAuras or not frame._testAuras[1] or frame._testAuras[1].expirationTime < now then
            local durations = { 10, 15, 8, 20, 30 }
            local icons     = { 135812, 136197, 135844, 136048, 136042 }
            frame._testAuras = {}
            for i = 1, 5 do
                frame._testAuras[i] = {
                    icon = icons[i], duration = durations[i],
                    expirationTime = now + durations[i],
                    stackGrowSpeed = 40 / durations[i],
                }
            end
        end
        for i = 1, maxCount do
            local b = frame._auras[i]
            local a = frame._testAuras[i]
            if a then
                -- No real unit aura in test mode — wipe refs so OnEnter
                -- shows just the test aura name as a placeholder.
                b._unit = nil; b._auraInstanceID = nil; b._auraIndex = nil
                b._auraName = "Test Aura"
                b.icon:SetTexture(a.icon)
                local elapsed = a.duration - (a.expirationTime - now)
                local stacks = math.floor(1 + elapsed * (a.stackGrowSpeed or 0))
                if stacks < 1 then stacks = 1 end
                if stacks > 40 then stacks = 40 end
                if db.aurasShowStacks and stacks > 1 then b.stacks:SetText(stacks) else b.stacks:SetText("") end
                if db.aurasShowTimer and a.expirationTime > 0 then
                    b.timer:SetText(formatTime(a.expirationTime - now))
                    if b.cd and a.duration > 0 then b.cd:SetCooldown(a.expirationTime - a.duration, a.duration) end
                else b.timer:SetText("") end
                b:Show()
            else b:Hide() end
        end
        return
    end

    local unit = frame.unit
    if not UnitExists(unit) then
        for _, b in ipairs(frame._auras) do b:Hide() end
        return
    end

    local auras = collectAuras(unit, db.aurasFilter or "HARMFUL", db.aurasSource or "ALL", maxCount)
    for i = 1, maxCount do
        local b = frame._auras[i]
        local a = auras[i]
        if a then
            -- Tooltip metadata: instance ID for modern API, index for legacy
            -- fallback, name as last-resort string when both fail.
            b._unit = unit
            b._auraInstanceID = a.auraInstanceID
            b._auraIndex = a._auraIndex
            b._auraName = a.name
            b.icon:SetTexture(a.icon)
            if db.aurasShowStacks then
                local ok, showIt = pcall(function() return a.applications and a.applications > 1 end)
                if ok and showIt then pcall(b.stacks.SetText, b.stacks, a.applications)
                else b.stacks:SetText("") end
            else b.stacks:SetText("") end

            if db.aurasShowTimer then
                local okText, remaining = pcall(function()
                    if a.expirationTime and a.expirationTime > 0 then
                        return a.expirationTime - GetTime()
                    end
                end)
                if okText and remaining then b.timer:SetText(formatTime(remaining))
                else b.timer:SetText("") end
                if b.cd and a.duration and a.expirationTime then
                    pcall(function() b.cd:SetCooldown(a.expirationTime - a.duration, a.duration) end)
                end
            else
                b.timer:SetText("")
                if b.cd then b.cd:Clear() end
            end
            b:Show()
        else b:Hide() end
    end
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if not unit or not unit:match("^boss%d$") then return end
    local idx = tonumber(unit:sub(5))
    local frame = BossW.BossFrames and BossW.BossFrames[idx]
    if frame then BossW.UpdateAuras(frame) end
end)
