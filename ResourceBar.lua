local addonName, BM = ...

local primaryBar, primaryText, primaryBg
local secondaryContainer
local secondaryPips = {}
local MAX_PIPS = 5
local manaBar, manaText, manaBg
local powerFrame

local function GetParent(section)
    if BM.sectionFrames and BM.sectionFrames[section] then
        return BM.sectionFrames[section]
    end
    return UIParent
end

---------------------------------------------------------------------------
-- Destroy
---------------------------------------------------------------------------
local function DestroyBars()
    if primaryBar then primaryBar:Hide(); primaryBar:SetParent(nil) end
    if secondaryContainer then secondaryContainer:Hide(); secondaryContainer:SetParent(nil) end
    for _, pip in ipairs(secondaryPips) do pip:Hide(); pip:SetParent(nil) end
    if manaBar then manaBar:Hide(); manaBar:SetParent(nil) end
    primaryBar = nil
    primaryText = nil
    primaryBg = nil
    secondaryContainer = nil
    secondaryPips = {}
    manaBar = nil
    manaText = nil
    manaBg = nil
    BM.primaryBar = nil
    BM.secondaryContainer = nil
    BM.manaBar = nil
end

---------------------------------------------------------------------------
-- Primary bar (Energy / Rage / LunarPower / Mana)
---------------------------------------------------------------------------
local function CreatePrimaryBar(resData)
    local db = BM.db
    local style = BM.GetCurrentStyle()
    local parent = GetParent("primary")

    primaryBar = CreateFrame("StatusBar", "badomeowPrimaryBar", parent)
    primaryBar:SetSize(db.barWidth, db.barHeight)
    primaryBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    primaryBar:SetAllPoints(parent)

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

    primaryBg = primaryBar:CreateTexture(nil, "BACKGROUND")
    primaryBg:SetAllPoints()
    primaryBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    primaryBg:SetVertexColor(0.08, 0.08, 0.08, 0.6)

    primaryText = primaryBar:CreateFontString(nil, "OVERLAY")
    primaryText:SetFont(style.fontName, style.fontSize, "OUTLINE")
    primaryText:SetPoint("CENTER")
    primaryText:SetTextColor(1, 1, 1, 1)

    parent:SetSize(db.barWidth, db.barHeight)
    BM.primaryBar = primaryBar
end

---------------------------------------------------------------------------
-- Secondary pips (Combo Points)
---------------------------------------------------------------------------
local function CreateSecondaryPips(resData)
    if not resData.secondaryPower then return end
    local db = BM.db
    local maxPips = resData.maxSecondary or MAX_PIPS
    local parent = GetParent("secondary")
    local pipW = db.pipWidth or 260
    local pipH = db.pipHeight or 10

    secondaryContainer = CreateFrame("Frame", "badomeowSecondaryBar", parent)
    secondaryContainer:SetAllPoints(parent)

    local gap = 1
    local singleW = (pipW - (maxPips - 1) * gap) / maxPips

    for i = 1, maxPips do
        local pip = CreateFrame("Frame", nil, secondaryContainer, "BackdropTemplate")
        pip:SetSize(singleW, pipH)
        pip:SetPoint("LEFT", secondaryContainer, "LEFT", (i - 1) * (singleW + gap), 0)
        pip:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            tile = true, tileSize = 8,
        })
        pip:SetBackdropColor(0.1, 0.1, 0.1, 0.7)

        pip.fill = pip:CreateTexture(nil, "ARTWORK")
        pip.fill:SetAllPoints()
        pip.fill:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        pip.fill:Hide()

        secondaryPips[i] = pip
    end

    parent:SetSize(pipW, pipH)
    BM.secondaryContainer = secondaryContainer
end

---------------------------------------------------------------------------
-- Mana bar (shown in shifted forms alongside main resource)
---------------------------------------------------------------------------
local function CreateManaBar()
    local db = BM.db
    local style = BM.GetCurrentStyle()
    local parent = GetParent("mana")
    local mW = db.manaBarWidth or 260
    local mH = db.manaBarHeight or 10

    manaBar = CreateFrame("StatusBar", "badomeowManaBar", parent)
    manaBar:SetSize(mW, mH)
    manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    manaBar:SetAllPoints(parent)
    manaBar:SetStatusBarColor(0.2, 0.4, 1.0)

    local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
    manaBar:SetMinMaxValues(0, maxMana > 0 and maxMana or 1)
    manaBar:SetValue(UnitPower("player", Enum.PowerType.Mana))

    manaBg = manaBar:CreateTexture(nil, "BACKGROUND")
    manaBg:SetAllPoints()
    manaBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    manaBg:SetVertexColor(0.08, 0.08, 0.08, 0.6)

    manaText = manaBar:CreateFontString(nil, "OVERLAY")
    manaText:SetFont(style.fontName, math.max(style.fontSize - 2, 8), "OUTLINE")
    manaText:SetPoint("CENTER")
    manaText:SetTextColor(1, 1, 1, 1)

    parent:SetSize(mW, mH)
    BM.manaBar = manaBar
end

---------------------------------------------------------------------------
-- Update functions
---------------------------------------------------------------------------
local function UpdatePrimary()
    if not primaryBar then return end
    local resData = BM.GetEffectiveResourceData()
    if not resData then return end

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
end

local lastSecondary = 0
local function UpdateSecondary()
    if not secondaryContainer then return end
    local resData = BM.GetEffectiveResourceData()
    if not resData or not resData.secondaryPower then return end

    local current = UnitPower("player", resData.secondaryPower)
    local maximum = resData.maxSecondary or MAX_PIPS

    for i = 1, maximum do
        local pip = secondaryPips[i]
        if not pip then break end
        if i <= current then
            local color = BM.ComboPipColors[i] or { 1, 0.5, 0 }
            pip.fill:SetVertexColor(color[1], color[2], color[3], 1)
            pip.fill:Show()
        else
            pip.fill:Hide()
        end
    end

    if current >= maximum and lastSecondary < maximum then
        for i = 1, maximum do
            if secondaryPips[i] and secondaryPips[i].fill then
                secondaryPips[i].fill:SetVertexColor(1, 1, 1, 1)
            end
        end
    end
    lastSecondary = current
end

local function UpdateMana()
    if not manaBar then return end
    local current = UnitPower("player", Enum.PowerType.Mana)
    local maximum = UnitPowerMax("player", Enum.PowerType.Mana)
    if maximum <= 0 then maximum = 1 end
    manaBar:SetMinMaxValues(0, maximum)
    manaBar:SetValue(current)
    manaText:SetText(string.format("%.0f%%", current / maximum * 100))
end

---------------------------------------------------------------------------
-- Section visibility based on form
---------------------------------------------------------------------------
local function UpdateSectionVisibility()
    local resData = BM.GetEffectiveResourceData()
    if not resData then return end

    local secFrame = BM.sectionFrames and BM.sectionFrames["secondary"]
    if secFrame then
        if resData.secondaryPower and BM.db.showSecondaryBar ~= false then
            secFrame:Show()
        else
            secFrame:Hide()
        end
    end

    local manaFrame = BM.sectionFrames and BM.sectionFrames["mana"]
    if manaFrame then
        if resData.showMana and BM.db.showManaBar ~= false then
            manaFrame:Show()
        else
            manaFrame:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- Build / Rebuild
---------------------------------------------------------------------------
function BM.RebuildResourceBars()
    DestroyBars()
    local resData = BM.GetEffectiveResourceData()
    if not resData then return end

    CreatePrimaryBar(resData)
    UpdatePrimary()

    if resData.secondaryPower then
        CreateSecondaryPips(resData)
        UpdateSecondary()
    end

    if resData.showMana then
        CreateManaBar()
        UpdateMana()
    end

    UpdateSectionVisibility()
end

function BM.InitResourceBars()
    powerFrame = CreateFrame("Frame")
    powerFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    powerFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    powerFrame:SetScript("OnEvent", function()
        UpdatePrimary()
        UpdateSecondary()
        UpdateMana()
    end)
    BM.RebuildResourceBars()
end
