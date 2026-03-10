local addonName, BM = ...

-- ==========================================
-- Dynamic resource bars: adapts to current spec
-- ==========================================

local primaryBar, primaryText, primaryLabel
local secondaryContainer
local secondaryPips = {}
local MAX_PIPS = 5

local powerFrame

-- ==========================================
-- Destroy existing bars for rebuild
-- ==========================================
local function DestroyBars()
    if primaryBar then primaryBar:Hide(); primaryBar:SetParent(nil) end
    if secondaryContainer then secondaryContainer:Hide(); secondaryContainer:SetParent(nil) end
    for _, pip in ipairs(secondaryPips) do
        pip:Hide()
        pip:SetParent(nil)
    end
    primaryBar = nil
    primaryText = nil
    primaryLabel = nil
    secondaryContainer = nil
    secondaryPips = {}
end

-- ==========================================
-- Create primary power bar (Energy / Astral / Rage / Mana)
-- ==========================================
local function CreatePrimaryBar(specData)
    local db = BM.db
    local style = BM.GetCurrentStyle()
    local specID = BM.GetCurrentSpecID()
    local barColor = BM.SpecBarColors[specID] and BM.SpecBarColors[specID].primary or style.primaryBarColor

    primaryBar = CreateFrame("StatusBar", "badomeowPrimaryBar", BM.MainFrame)
    primaryBar:SetSize(db.barWidth, db.barHeight)
    primaryBar:SetPoint("BOTTOM", BM.MainFrame, "BOTTOM", 0, 10)
    primaryBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    primaryBar:SetStatusBarColor(barColor[1], barColor[2], barColor[3])
    primaryBar:SetMinMaxValues(0, UnitPowerMax("player", specData.powerType))
    primaryBar:SetValue(UnitPower("player", specData.powerType))
    primaryBar:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 2)

    local bg = primaryBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.12, 0.12, 0.12, 0.8)

    local border = CreateFrame("Frame", nil, primaryBar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)

    primaryText = primaryBar:CreateFontString(nil, "OVERLAY")
    primaryText:SetFont(style.fontName, style.fontSize, "OUTLINE")
    primaryText:SetPoint("CENTER")
    primaryText:SetTextColor(1, 1, 1, 1)

    primaryLabel = primaryBar:CreateFontString(nil, "OVERLAY")
    primaryLabel:SetFont(style.fontName, 9, "OUTLINE")
    primaryLabel:SetPoint("LEFT", primaryBar, "LEFT", 4, 0)
    primaryLabel:SetTextColor(0.7, 0.7, 0.7, 0.5)
    primaryLabel:SetText(specData.powerLabel or "")
end

-- ==========================================
-- Create secondary resource pips (combo points for Feral)
-- ==========================================
local function CreateSecondaryPips(specData)
    if not specData.secondaryPower then return end

    local db = BM.db
    local maxPips = specData.maxSecondary or MAX_PIPS

    secondaryContainer = CreateFrame("Frame", "badomeowSecondaryBar", BM.MainFrame)
    secondaryContainer:SetSize(db.barWidth, 14)
    secondaryContainer:SetPoint("BOTTOM", primaryBar, "TOP", 0, 4)
    secondaryContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 2)

    local pipWidth = (db.barWidth - (maxPips - 1) * 3) / maxPips

    for i = 1, maxPips do
        local pip = CreateFrame("Frame", nil, secondaryContainer, "BackdropTemplate")
        pip:SetSize(pipWidth, 12)
        pip:SetPoint("LEFT", secondaryContainer, "LEFT", (i - 1) * (pipWidth + 3), 0)
        pip:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 6,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        pip:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        pip:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.4)

        pip.fill = pip:CreateTexture(nil, "ARTWORK")
        pip.fill:SetPoint("TOPLEFT", 2, -2)
        pip.fill:SetPoint("BOTTOMRIGHT", -2, 2)
        pip.fill:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        pip.fill:Hide()

        secondaryPips[i] = pip
    end
end

-- ==========================================
-- Update primary bar
-- ==========================================
local function UpdatePrimary()
    if not primaryBar then return end
    local specData = BM.GetCurrentSpecData()
    if not specData then return end
    if not BM.db.showPrimaryBar then primaryBar:Hide(); return end
    primaryBar:Show()

    local current = UnitPower("player", specData.powerType)
    local maximum = UnitPowerMax("player", specData.powerType)
    primaryBar:SetMinMaxValues(0, maximum)
    primaryBar:SetValue(current)

    if specData.powerType == Enum.PowerType.Mana then
        local pct = maximum > 0 and (current / maximum * 100) or 0
        primaryText:SetText(string.format("%.0f%%", pct))
    else
        primaryText:SetText(current .. " / " .. maximum)
    end
end

-- ==========================================
-- Update secondary pips
-- ==========================================
local lastSecondary = 0

local function UpdateSecondary()
    if not secondaryContainer then return end
    local specData = BM.GetCurrentSpecData()
    if not specData or not specData.secondaryPower then return end
    if not BM.db.showSecondaryBar then secondaryContainer:Hide(); return end
    secondaryContainer:Show()

    local current = UnitPower("player", specData.secondaryPower)
    local maximum = specData.maxSecondary or MAX_PIPS

    for i = 1, maximum do
        local pip = secondaryPips[i]
        if not pip then break end
        if i <= current then
            local color = BM.ComboPipColors[i] or { 1, 0.5, 0 }
            pip.fill:SetVertexColor(color[1], color[2], color[3], 1)
            pip.fill:Show()
            pip:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
        else
            pip.fill:Hide()
            pip:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
            pip:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.4)
        end
    end

    if current >= maximum and lastSecondary < maximum then
        for i = 1, maximum do
            if secondaryPips[i] then
                secondaryPips[i]:SetBackdropBorderColor(1, 1, 1, 1)
            end
        end
    end
    lastSecondary = current
end

-- ==========================================
-- Rebuild on spec change
-- ==========================================
function BM.RebuildResourceBars()
    DestroyBars()
    local specData = BM.GetCurrentSpecData()
    if not specData then return end

    CreatePrimaryBar(specData)
    CreateSecondaryPips(specData)
    UpdatePrimary()
    UpdateSecondary()
end

function BM.RefreshResourceBars()
    if not primaryBar then return end
    local db = BM.db
    local style = BM.GetCurrentStyle()
    local specID = BM.GetCurrentSpecID()
    local barColor = BM.SpecBarColors[specID] and BM.SpecBarColors[specID].primary or style.primaryBarColor

    primaryBar:SetSize(db.barWidth, db.barHeight)
    primaryBar:SetStatusBarColor(barColor[1], barColor[2], barColor[3])
    if primaryText then primaryText:SetFont(style.fontName, style.fontSize, "OUTLINE") end
    if primaryLabel then primaryLabel:SetFont(style.fontName, 9, "OUTLINE") end

    if secondaryContainer then
        local specData = BM.GetCurrentSpecData()
        local maxPips = specData and specData.maxSecondary or MAX_PIPS
        secondaryContainer:SetSize(db.barWidth, 14)
        local pipWidth = (db.barWidth - (maxPips - 1) * 3) / maxPips
        for i = 1, maxPips do
            if secondaryPips[i] then
                secondaryPips[i]:SetSize(pipWidth, 12)
                secondaryPips[i]:ClearAllPoints()
                secondaryPips[i]:SetPoint("LEFT", secondaryContainer, "LEFT", (i - 1) * (pipWidth + 3), 0)
            end
        end
    end

    UpdatePrimary()
    UpdateSecondary()
end

-- ==========================================
-- Init: register power events
-- ==========================================
function BM.InitResourceBars()
    powerFrame = CreateFrame("Frame")
    powerFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    powerFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    powerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    powerFrame:SetScript("OnEvent", function()
        UpdatePrimary()
        UpdateSecondary()
    end)

    BM.RebuildResourceBars()
end
