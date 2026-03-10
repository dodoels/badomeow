local addonName, BM = ...

local primaryBar, primaryText, primaryLabel
local secondaryContainer
local secondaryPips = {}
local MAX_PIPS = 5
local powerFrame

local function DestroyBars()
    if primaryBar then primaryBar:Hide(); primaryBar:SetParent(nil) end
    if secondaryContainer then secondaryContainer:Hide(); secondaryContainer:SetParent(nil) end
    for _, pip in ipairs(secondaryPips) do pip:Hide(); pip:SetParent(nil) end
    primaryBar = nil
    primaryText = nil
    primaryLabel = nil
    secondaryContainer = nil
    secondaryPips = {}
end

local function CreatePrimaryBar(resData)
    local db = BM.db
    local style = BM.GetCurrentStyle()

    primaryBar = CreateFrame("StatusBar", "badomeowPrimaryBar", BM.MainFrame)
    primaryBar:SetSize(db.barWidth, db.barHeight)
    primaryBar:SetPoint("BOTTOM", BM.MainFrame, "BOTTOM", 0, 6)
    primaryBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    primaryBar:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 2)

    local barColor
    if resData.powerType == Enum.PowerType.Energy then barColor = { 1.0, 1.0, 0.0 }
    elseif resData.powerType == Enum.PowerType.Rage then barColor = { 0.8, 0.2, 0.1 }
    elseif resData.powerType == Enum.PowerType.LunarPower then barColor = { 0.4, 0.4, 1.0 }
    elseif resData.powerType == Enum.PowerType.Mana then barColor = { 0.2, 0.4, 1.0 }
    else barColor = { 1.0, 0.85, 0.0 } end
    primaryBar:SetStatusBarColor(barColor[1], barColor[2], barColor[3])

    local maxPower = UnitPowerMax("player", resData.powerType)
    primaryBar:SetMinMaxValues(0, maxPower > 0 and maxPower or 1)
    primaryBar:SetValue(UnitPower("player", resData.powerType))

    local bg = primaryBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.08, 0.08, 0.08, 0.6)

    local border = CreateFrame("Frame", nil, primaryBar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    border:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.4)

    primaryText = primaryBar:CreateFontString(nil, "OVERLAY")
    primaryText:SetFont(style.fontName, style.fontSize, "OUTLINE")
    primaryText:SetPoint("CENTER")
    primaryText:SetTextColor(1, 1, 1, 1)

    primaryLabel = primaryBar:CreateFontString(nil, "OVERLAY")
    primaryLabel:SetFont(style.fontName, 9, "OUTLINE")
    primaryLabel:SetPoint("LEFT", primaryBar, "LEFT", 4, 0)
    primaryLabel:SetTextColor(0.7, 0.7, 0.7, 0.4)
    primaryLabel:SetText(resData.powerLabel or "")
end

local function CreateSecondaryPips(resData)
    if not resData.secondaryPower then return end
    local db = BM.db
    local maxPips = resData.maxSecondary or MAX_PIPS

    secondaryContainer = CreateFrame("Frame", "badomeowSecondaryBar", BM.MainFrame)
    secondaryContainer:SetSize(db.barWidth, 12)
    secondaryContainer:SetPoint("BOTTOM", primaryBar, "TOP", 0, 3)
    secondaryContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 2)

    local gap = 2
    local pipWidth = (db.barWidth - (maxPips - 1) * gap) / maxPips

    for i = 1, maxPips do
        local pip = CreateFrame("Frame", nil, secondaryContainer, "BackdropTemplate")
        pip:SetSize(pipWidth, 10)
        pip:SetPoint("LEFT", secondaryContainer, "LEFT", (i - 1) * (pipWidth + gap), 0)
        pip:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 4,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        pip:SetBackdropColor(0.08, 0.08, 0.08, 0.5)
        pip:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.3)

        pip.fill = pip:CreateTexture(nil, "ARTWORK")
        pip.fill:SetPoint("TOPLEFT", 2, -2)
        pip.fill:SetPoint("BOTTOMRIGHT", -2, 2)
        pip.fill:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        pip.fill:Hide()

        secondaryPips[i] = pip
    end
end

local function UpdatePrimary()
    if not primaryBar then return end
    local resData = BM.GetEffectiveResourceData()
    if not resData then return end
    if not BM.db.showPrimaryBar then primaryBar:Hide(); return end
    primaryBar:Show()

    local current = UnitPower("player", resData.powerType)
    local maximum = UnitPowerMax("player", resData.powerType)
    if maximum <= 0 then maximum = 1 end
    primaryBar:SetMinMaxValues(0, maximum)
    primaryBar:SetValue(current)

    if resData.powerType == Enum.PowerType.Mana then
        primaryText:SetText(string.format("%.0f%%", current / maximum * 100))
    else
        primaryText:SetText(current .. " / " .. maximum)
    end
    primaryLabel:SetText(resData.powerLabel or "")
end

local lastSecondary = 0
local function UpdateSecondary()
    if not secondaryContainer then return end
    local resData = BM.GetEffectiveResourceData()
    if not resData or not resData.secondaryPower then return end
    if not BM.db.showSecondaryBar then secondaryContainer:Hide(); return end
    secondaryContainer:Show()

    local current = UnitPower("player", resData.secondaryPower)
    local maximum = resData.maxSecondary or MAX_PIPS

    for i = 1, maximum do
        local pip = secondaryPips[i]
        if not pip then break end
        if i <= current then
            local color = BM.ComboPipColors[i] or { 1, 0.5, 0 }
            pip.fill:SetVertexColor(color[1], color[2], color[3], 1)
            pip.fill:Show()
            pip:SetBackdropBorderColor(color[1], color[2], color[3], 0.7)
        else
            pip.fill:Hide()
            pip:SetBackdropColor(0.08, 0.08, 0.08, 0.5)
            pip:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.3)
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

function BM.RebuildResourceBars()
    DestroyBars()
    local resData = BM.GetEffectiveResourceData()
    if not resData then return end
    CreatePrimaryBar(resData)
    CreateSecondaryPips(resData)
    UpdatePrimary()
    UpdateSecondary()
end

function BM.InitResourceBars()
    powerFrame = CreateFrame("Frame")
    powerFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    powerFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    powerFrame:SetScript("OnEvent", function()
        UpdatePrimary()
        UpdateSecondary()
    end)
    BM.RebuildResourceBars()
end
