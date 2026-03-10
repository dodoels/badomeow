local addonName, BM = ...

-- ==========================================
-- Display: Spec-aware buff/debuff/cooldown icons + proc overlay
-- ==========================================

local buffIcons = {}
local debuffIcons = {}
local cdIcons = {}
local sectionLabels = {}
local procOverlay

local prevBuffState = {}

-- ==========================================
-- Destroy all display elements for rebuild
-- ==========================================
local function DestroyIcons(tbl)
    for _, icon in ipairs(tbl) do
        icon:Hide()
        icon:SetParent(nil)
    end
    wipe(tbl)
end

local function DestroyLabels()
    for _, label in ipairs(sectionLabels) do
        label:Hide()
        label:SetParent(nil)
    end
    wipe(sectionLabels)
end

-- ==========================================
-- Create icon with cooldown spinner + stack + glow
-- ==========================================
local function CreateTrackerIcon(parent, size, xOff, yOff)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    f:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOff, yOff)
    f:SetFrameLevel(parent:GetFrameLevel() + 3)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 2, -2)
    f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.border = f:CreateTexture(nil, "OVERLAY")
    f.border:SetAllPoints()
    f.border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    f.border:SetVertexColor(0.4, 0.4, 0.4, 0.8)

    f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints(f.icon)
    f.cd:SetDrawEdge(true)
    f.cd:SetHideCountdownNumbers(false)

    f.stack = f:CreateFontString(nil, "OVERLAY")
    f.stack:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    f.stack:SetPoint("BOTTOMRIGHT", -1, 1)
    f.stack:SetTextColor(1, 1, 1, 1)

    f.duration = f:CreateFontString(nil, "OVERLAY")
    f.duration:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    f.duration:SetPoint("TOP", f, "BOTTOM", 0, -1)
    f.duration:SetTextColor(1, 0.9, 0.5, 1)

    f.glow = f:CreateTexture(nil, "OVERLAY", nil, 1)
    f.glow:SetPoint("TOPLEFT", -4, 4)
    f.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    f.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    f.glow:SetTexCoord(0, 0.5, 0, 0.5)
    f.glow:SetVertexColor(1, 0.8, 0, 0.9)
    f.glow:Hide()

    f:Hide()
    return f
end

-- ==========================================
-- Proc overlay
-- ==========================================
local function CreateProcOverlay()
    if procOverlay then return end

    procOverlay = CreateFrame("Frame", "badomeowProcOverlay", BM.MainFrame)
    procOverlay:SetSize(BM.db.procImageSize, BM.db.procImageSize)
    procOverlay:SetPoint("CENTER", BM.MainFrame, "CENTER", 0, 60)
    procOverlay:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 10)

    procOverlay.tex = procOverlay:CreateTexture(nil, "ARTWORK")
    procOverlay.tex:SetAllPoints()
    procOverlay.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    procOverlay.glow = procOverlay:CreateTexture(nil, "BACKGROUND")
    procOverlay.glow:SetPoint("TOPLEFT", -10, 10)
    procOverlay.glow:SetPoint("BOTTOMRIGHT", 10, -10)
    procOverlay.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    procOverlay.glow:SetTexCoord(0, 0.5, 0, 0.5)
    procOverlay.glow:SetVertexColor(1.0, 0.7, 0.0, 0.8)

    procOverlay.fadeIn = procOverlay:CreateAnimationGroup()
    local fi = procOverlay.fadeIn:CreateAnimation("Alpha")
    fi:SetFromAlpha(0); fi:SetToAlpha(1); fi:SetDuration(0.2); fi:SetSmoothing("OUT")

    procOverlay.fadeOut = procOverlay:CreateAnimationGroup()
    local fo = procOverlay.fadeOut:CreateAnimation("Alpha")
    fo:SetFromAlpha(1); fo:SetToAlpha(0); fo:SetDuration(0.5); fo:SetStartDelay(2.0); fo:SetSmoothing("IN")
    procOverlay.fadeOut:SetScript("OnFinished", function() procOverlay:Hide() end)

    procOverlay:Hide()
end

local function ShowProcOverlay(spellId)
    if not BM.db.showProcImage or not procOverlay then return end
    local tex = C_Spell.GetSpellTexture(spellId)
    if tex then
        procOverlay.tex:SetTexture(tex)
        procOverlay:SetSize(BM.db.procImageSize, BM.db.procImageSize)
        procOverlay:Show()
        procOverlay:SetAlpha(1)
        procOverlay.fadeIn:Play()
        procOverlay.fadeOut:Stop()
        procOverlay.fadeOut:Play()
    end
end

-- ==========================================
-- Format time
-- ==========================================
local function FormatTime(sec)
    if sec > 60 then return string.format("%dm", sec / 60)
    elseif sec > 3 then return string.format("%d", sec)
    else return string.format("%.1f", sec) end
end

-- ==========================================
-- Update buffs (reads from current spec data)
-- ==========================================
local function UpdateBuffs()
    local specData = BM.GetCurrentSpecData()
    if not specData or not BM.db.showBuffs then
        for _, icon in ipairs(buffIcons) do icon:Hide() end
        return
    end

    local now = GetTime()
    for idx, tracker in ipairs(specData.buffs) do
        local icon = buffIcons[idx]
        if icon then
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(tracker.spellId)
            if aura then
                icon.icon:SetTexture(C_Spell.GetSpellTexture(tracker.spellId) or aura.icon)
                icon:Show()

                if aura.duration and aura.duration > 0 and aura.expirationTime then
                    icon.cd:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                    local rem = aura.expirationTime - now
                    icon.duration:SetText(rem > 0 and FormatTime(rem) or "")
                else
                    icon.cd:Clear()
                    icon.duration:SetText("")
                end

                icon.stack:SetText(aura.applications and aura.applications > 1 and aura.applications or "")

                if tracker.glow and BM.db.showProcGlow then
                    icon.glow:Show()
                    icon.border:SetVertexColor(1, 0.8, 0, 1)
                else
                    icon.glow:Hide()
                    icon.border:SetVertexColor(0.4, 0.4, 0.4, 0.8)
                end

                if not prevBuffState[tracker.spellId] then
                    if tracker.sound then BM.PlayAlertSound(tracker.sound) end
                    if tracker.glow then ShowProcOverlay(tracker.spellId) end
                end
                prevBuffState[tracker.spellId] = true
            else
                icon:Hide()
                icon.glow:Hide()
                prevBuffState[tracker.spellId] = false
            end
        end
    end
end

-- ==========================================
-- Update debuffs on target
-- ==========================================
function BM.UpdateDebuffs()
    local specData = BM.GetCurrentSpecData()
    if not specData or not BM.db.showDebuffs then
        for _, icon in ipairs(debuffIcons) do icon:Hide() end
        return
    end

    local now = GetTime()
    for idx, tracker in ipairs(specData.debuffs) do
        local icon = debuffIcons[idx]
        if icon then
            if not UnitExists("target") then
                icon:Hide()
            else
                local aura
                for i = 1, 40 do
                    local data = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL")
                    if not data then break end
                    if data.spellId == tracker.spellId and data.sourceUnit == "player" then
                        aura = data; break
                    end
                end

                if aura then
                    icon.icon:SetTexture(C_Spell.GetSpellTexture(tracker.spellId) or aura.icon)
                    icon:Show()
                    if aura.duration and aura.duration > 0 and aura.expirationTime then
                        icon.cd:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                        local rem = aura.expirationTime - now
                        icon.duration:SetText(rem > 0 and FormatTime(rem) or "")
                        icon.border:SetVertexColor(rem < 3 and 1 or 0.8, 0.2, 0.2, rem < 3 and 1 or 0.8)
                    else
                        icon.cd:Clear()
                        icon.duration:SetText("")
                    end
                    icon.stack:SetText(aura.applications and aura.applications > 1 and aura.applications or "")
                else
                    icon:Hide()
                end
            end
        end
    end
end

-- ==========================================
-- Update cooldowns
-- ==========================================
local function UpdateCooldowns()
    local specData = BM.GetCurrentSpecData()
    if not specData or not BM.db.showCooldowns then
        for _, icon in ipairs(cdIcons) do icon:Hide() end
        return
    end

    local now = GetTime()
    for idx, tracker in ipairs(specData.cooldowns) do
        local icon = cdIcons[idx]
        if icon then
            local spellInfo = C_Spell.GetSpellInfo(tracker.spellId)
            if spellInfo then
                local tex = C_Spell.GetSpellTexture(tracker.spellId)
                icon.icon:SetTexture(tex)
                icon:Show()

                local cdInfo = C_Spell.GetSpellCooldown(tracker.spellId)
                if cdInfo and cdInfo.startTime and cdInfo.duration and cdInfo.duration > 1.5 then
                    icon.cd:SetCooldown(cdInfo.startTime, cdInfo.duration)
                    local rem = (cdInfo.startTime + cdInfo.duration) - now
                    icon.duration:SetText(rem > 0 and FormatTime(rem) or "")
                    icon.icon:SetDesaturated(true)
                    icon.border:SetVertexColor(0.5, 0.5, 0.5, 0.6)
                else
                    icon.cd:Clear()
                    icon.duration:SetText("")
                    icon.icon:SetDesaturated(false)
                    icon.border:SetVertexColor(0.3, 0.8, 0.3, 0.8)
                end
            else
                icon:Hide()
            end
        end
    end
end

-- ==========================================
-- Section label
-- ==========================================
local function CreateSectionLabel(text, parent, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    label:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
    label:SetTextColor(0.6, 0.8, 0.6, 0.6)
    label:SetText(text)
    sectionLabels[#sectionLabels + 1] = label
    return label
end

-- ==========================================
-- Rebuild display for current spec
-- ==========================================
function BM.RebuildDisplay()
    DestroyIcons(buffIcons)
    DestroyIcons(debuffIcons)
    DestroyIcons(cdIcons)
    DestroyLabels()
    wipe(prevBuffState)

    local specData = BM.GetCurrentSpecData()
    if not specData then return end

    local db = BM.db
    local iconSize = db.iconSize
    local spacing = 4
    local leftPad = 10

    -- Row 1: Buffs (above resource bars)
    local buffY = 75
    for i, tracker in ipairs(specData.buffs) do
        local xOff = leftPad + (i - 1) * (iconSize + spacing)
        local icon = CreateTrackerIcon(BM.MainFrame, iconSize, xOff, buffY)
        local tex = C_Spell.GetSpellTexture(tracker.spellId)
        if tex then icon.icon:SetTexture(tex) end
        buffIcons[i] = icon
    end
    CreateSectionLabel("增益 Buffs", BM.MainFrame, leftPad, buffY + iconSize + 2)

    -- Row 2: Debuffs
    local debuffY = buffY + iconSize + 20
    for i, tracker in ipairs(specData.debuffs) do
        local xOff = leftPad + (i - 1) * (iconSize + spacing)
        local icon = CreateTrackerIcon(BM.MainFrame, iconSize, xOff, debuffY)
        local tex = C_Spell.GetSpellTexture(tracker.spellId)
        if tex then icon.icon:SetTexture(tex) end
        icon.border:SetVertexColor(0.8, 0.2, 0.2, 0.8)
        debuffIcons[i] = icon
    end
    CreateSectionLabel("减益 Debuffs", BM.MainFrame, leftPad, debuffY + iconSize + 2)

    -- Row 3: Cooldowns
    local cdY = debuffY + iconSize + 20
    for i, tracker in ipairs(specData.cooldowns) do
        local xOff = leftPad + (i - 1) * (iconSize + spacing)
        local icon = CreateTrackerIcon(BM.MainFrame, iconSize, xOff, cdY)
        local tex = C_Spell.GetSpellTexture(tracker.spellId)
        if tex then icon.icon:SetTexture(tex) end
        icon.border:SetVertexColor(0.3, 0.6, 0.9, 0.8)
        cdIcons[i] = icon
    end
    CreateSectionLabel("冷却 CDs", BM.MainFrame, leftPad, cdY + iconSize + 2)

    -- Resize main frame
    local totalH = cdY + iconSize + 30
    BM.MainFrame:SetHeight(totalH)

    -- Spec title
    local specCN = BM.SpecNamesCN[BM.GetCurrentSpecID()] or ""
    if BM.MainFrame.title then
        BM.MainFrame.title:SetText("豹集 · " .. specCN)
    end

    CreateProcOverlay()
end

function BM.RefreshDisplay()
    local db = BM.db
    for _, icon in ipairs(buffIcons) do icon:SetSize(db.iconSize, db.iconSize) end
    for _, icon in ipairs(debuffIcons) do icon:SetSize(db.iconSize, db.iconSize) end
    for _, icon in ipairs(cdIcons) do icon:SetSize(db.iconSize, db.iconSize) end
    if procOverlay then procOverlay:SetSize(db.procImageSize, db.procImageSize) end
end

-- ==========================================
-- Init
-- ==========================================
function BM.InitDisplay()
    BM.RebuildDisplay()

    local auraFrame = CreateFrame("Frame")
    auraFrame:RegisterUnitEvent("UNIT_AURA", "player")
    auraFrame:RegisterUnitEvent("UNIT_AURA", "target")
    auraFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    auraFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_AURA" then
            if unit == "player" then UpdateBuffs() end
            if unit == "target" then BM.UpdateDebuffs() end
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            UpdateCooldowns()
        end
    end)

    -- Smooth timer updates
    local timer = 0
    local timerFrame = CreateFrame("Frame")
    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        timer = timer + elapsed
        if timer < 0.05 then return end
        timer = 0
        if not BM.MainFrame or not BM.MainFrame:IsShown() then return end
        UpdateBuffs()
        BM.UpdateDebuffs()
        UpdateCooldowns()
    end)
end
