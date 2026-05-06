local addonName, BW = ...

local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local issecretvalue = _G.issecretvalue or function() return false end

local MAX_BOSS = BW.MAX_BOSS

local function CreateCastBar(frame)
    if frame.castBar then return frame.castBar end

    local cb = CreateFrame("StatusBar", nil, frame)
    cb:SetMinMaxValues(0, 1); cb:SetValue(0); cb:Hide()

    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(cb)
    bg:SetColorTexture(0, 0, 0, 0.7)
    cb.bg = bg

    local spark = cb:CreateTexture(nil, "OVERLAY")
    spark:SetSize(8, 20)
    spark:SetBlendMode("ADD")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetPoint("CENTER", cb:GetStatusBarTexture(), "RIGHT", 0, 0)
    cb.spark = spark

    local icon = cb:CreateTexture(nil, "OVERLAY")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cb.icon = icon

    local iconBorder = cb:CreateTexture(nil, "OVERLAY", nil, 1)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetColorTexture(0, 0, 0, 0.8)
    iconBorder:SetDrawLayer("BACKGROUND")
    cb.iconBorder = iconBorder

    local spellText = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellText:SetTextColor(1, 1, 1)
    cb.spellText = spellText

    local timeText = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetTextColor(1, 1, 1)
    cb.timeText = timeText

    frame.castBar = cb
    return cb
end

function BW.LayoutCastBar(frame, db)
    if not db.showCastBar then
        if frame.castBar then frame.castBar:Hide() end
        return
    end

    local cb = CreateCastBar(frame)
    cb:ClearAllPoints()
    cb:SetStatusBarTexture(BW:ResolveTexture(db.castTexture or db.healthTexture))
    if cb.bg then cb.bg:SetColorTexture(0, 0, 0, db.castBackgroundAlpha or 0.7) end

    local barH = db.castBarHeight or 14
    if cb.icon then
        cb.icon:SetSize(barH, barH)
        cb.icon:ClearAllPoints()
        if db.castBarIconPosition == "RIGHT" then
            cb.icon:SetPoint("RIGHT", cb, "RIGHT", 0, 0)
            cb.spellText:ClearAllPoints(); cb.spellText:SetPoint("LEFT", cb, "LEFT", 4, 0)
            cb.timeText:ClearAllPoints();  cb.timeText:SetPoint("RIGHT", cb.icon, "LEFT", -4, 0)
        else
            cb.icon:SetPoint("LEFT", cb, "LEFT", 0, 0)
            cb.spellText:ClearAllPoints(); cb.spellText:SetPoint("LEFT", cb.icon, "RIGHT", 4, 0)
            cb.timeText:ClearAllPoints();  cb.timeText:SetPoint("RIGHT", cb, "RIGHT", -4, 0)
        end
    end

    if db.castBarDetached then
        cb:SetParent(frame)
        local anchor = db.castBarDetachedAnchor or "BOTTOM"
        local own =
            anchor == "TOP" and "BOTTOM" or anchor == "BOTTOM" and "TOP" or
            anchor == "TOPLEFT" and "BOTTOMLEFT" or anchor == "TOPRIGHT" and "BOTTOMRIGHT" or
            anchor == "BOTTOMLEFT" and "TOPLEFT" or anchor == "BOTTOMRIGHT" and "TOPRIGHT" or
            anchor == "LEFT" and "RIGHT" or anchor == "RIGHT" and "LEFT" or "CENTER"
        cb:SetPoint(own, frame, anchor, db.castBarDetachedX or 0, db.castBarDetachedY or 0)
        local w = db.castBarDetachedWidth or 0
        if w <= 0 then w = db.frameWidth or 220 end
        cb:SetWidth(w)
        cb:SetHeight(barH)
    else
        cb:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
        cb:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        cb:SetHeight(barH)
    end
end

local function ClearCast(frame)
    local cb = frame.castBar
    if not cb then return end
    cb._casting = false; cb._channeling = false; cb:Hide()
end

local function StartCast(frame, channeling)
    local cb = frame.castBar or CreateCastBar(frame)
    local unit = frame.unit
    local name, text, texture, startMs, endMs, _, _, notInterruptible
    if channeling then
        name, text, texture, startMs, endMs, _, notInterruptible = UnitChannelInfo(unit)
    else
        name, text, texture, startMs, endMs, _, _, notInterruptible = UnitCastingInfo(unit)
    end
    if not name or not startMs or not endMs then ClearCast(frame); return end

    local secret = issecretvalue(startMs) or issecretvalue(endMs)
    cb._secret = secret
    cb._startTimeMs = startMs
    cb._endTimeMs = endMs
    pcall(cb.SetMinMaxValues, cb, startMs, endMs)
    pcall(cb.SetValue, cb, channeling and endMs or startMs)
    if not secret then
        cb._startTime = startMs / 1000
        cb._endTime   = endMs / 1000
    else
        cb._startTime = nil; cb._endTime = nil
    end

    cb._channeling = channeling and true or false
    cb._casting = not channeling
    cb.spellText:SetText(text or name or "")
    if texture then cb.icon:SetTexture(texture); cb.icon:Show() else cb.icon:Hide() end

    local isProtected
    do
        local ok, v = pcall(function() return notInterruptible == true end)
        if ok then isProtected = v end
    end
    if isProtected then cb:SetStatusBarColor(0.7, 0.7, 0.7)
    elseif channeling then cb:SetStatusBarColor(0.3, 0.9, 0.3)
    else cb:SetStatusBarColor(1, 0.7, 0) end
    cb:Show()
end

local function FlashResult(frame, color)
    local cb = frame.castBar
    if not cb then return end
    cb:SetMinMaxValues(0, 1); cb:SetValue(1)
    cb:SetStatusBarColor(color[1], color[2], color[3])
    if cb.spark then cb.spark:Hide() end
    cb._casting = false; cb._channeling = false
    cb._fadeOut = GetTime() + 0.6
    cb:Show()
end

-- Ticker
local tickerFrame = CreateFrame("Frame")
tickerFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    for i = 1, MAX_BOSS do
        local f = BW.BossFrames and BW.BossFrames[i]
        local cb = f and f.castBar
        if cb and cb:IsShown() then
            if cb._fadeOut then
                local left = cb._fadeOut - now
                if left <= 0 then cb:Hide(); cb._fadeOut = nil
                else cb:SetAlpha(left / 0.6) end
            elseif cb._casting or cb._channeling then
                cb:SetAlpha(1)
                if cb._secret then
                    pcall(cb.SetValue, cb, now * 1000)
                    local ok, remaining = pcall(function()
                        return (cb._endTimeMs - now * 1000) / 1000
                    end)
                    if ok and remaining and remaining > 0 then
                        cb.timeText:SetFormattedText("%.1f", remaining)
                    else cb.timeText:SetText("") end
                elseif cb._endTime and now >= cb._endTime then
                    ClearCast(f)
                elseif cb._endTime then
                    cb:SetValue(now)
                    cb.timeText:SetFormattedText("%.1f", cb._endTime - now)
                end
            end
        end
    end
end)

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if not unit or not unit:match("^boss%d$") then return end
    local idx = tonumber(unit:sub(5))
    local frame = BW.BossFrames and BW.BossFrames[idx]
    if not frame then return end

    if event == "UNIT_SPELLCAST_START" then StartCast(frame, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        StartCast(frame, true)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        ClearCast(frame)
    elseif event == "UNIT_SPELLCAST_FAILED" then FlashResult(frame, {0.8, 0.3, 0.3})
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then FlashResult(frame, {1, 0.1, 0.1})
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local cb = frame.castBar
        if cb and (cb._casting or cb._channeling) then ClearCast(frame) end
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        local cb = frame.castBar
        if cb and cb:IsShown() then cb:SetStatusBarColor(1, 0.7, 0) end
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        local cb = frame.castBar
        if cb and cb:IsShown() then cb:SetStatusBarColor(0.7, 0.7, 0.7) end
    end
end)

-- Test simulation
local SIMULATED_SPELLS = {
    { name = "Fireball", texture = 135812, duration = 2.5 },
    { name = "Shadow Bolt", texture = 136197, duration = 3.0 },
    { name = "Frost Lance", texture = 135844, duration = 1.5 },
    { name = "Chain Heal", texture = 136042, duration = 2.2 },
    { name = "Lightning Bolt", texture = 136048, duration = 1.8 },
}

function BW.SimulateCast(frame, channeling)
    local cb = CreateCastBar(frame)
    local db = BW:GetDB()
    if not db.showCastBar then return end
    local spell = SIMULATED_SPELLS[math.random(#SIMULATED_SPELLS)]
    local now = GetTime()
    cb._secret = false
    cb._startTime = now; cb._endTime = now + spell.duration
    cb._startTimeMs = now * 1000; cb._endTimeMs = (now + spell.duration) * 1000
    cb._channeling = channeling and true or false
    cb._casting = not channeling
    cb:SetMinMaxValues(now, cb._endTime)
    cb:SetValue(channeling and cb._endTime or now)
    cb.spellText:SetText(spell.name)
    cb.icon:SetTexture(spell.texture)
    cb.icon:Show()
    cb:SetStatusBarColor(channeling and 0.3 or 1, channeling and 0.9 or 0.7, channeling and 0.3 or 0)
    cb:SetAlpha(1)
    cb:Show()
end
