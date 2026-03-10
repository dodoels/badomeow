local addonName, BM = ...
local L

-- ==========================================
-- State
-- ==========================================
local MainFrame
local isDruid = false
local currentSpecID = 0
local currentFormPower = nil  -- override power type from shapeshift
local inCombat = false
local hasTarget = false
local isVisible = false

-- GetShapeshiftFormID() returns global constant IDs (not stance bar index)
-- WoW globals: CAT_FORM=1, BEAR_FORM=5, MOONKIN_FORM=31-35
-- We use the globals directly so no local definitions needed

-- ==========================================
-- Utility
-- ==========================================
local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

-- ==========================================
-- Spec detection
-- ==========================================
local function DetectSpec()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    if not specIndex then return 0 end
    local specID = GetSpecializationInfo(specIndex)
    return specID or 0
end

local function IsDruid()
    local _, _, classID = UnitClass("player")
    return classID == BM.DRUID_CLASS_ID
end

function BM.GetCurrentSpecData()
    return BM.SpecData[currentSpecID]
end

function BM.GetCurrentSpecID()
    return currentSpecID
end

-- ==========================================
-- Shapeshift form → effective power override
-- ==========================================
local function DetectFormOverride()
    local formID = GetShapeshiftFormID()
    if not formID then return nil end

    if formID == CAT_FORM then
        return {
            powerType = Enum.PowerType.Energy,
            secondaryPower = Enum.PowerType.ComboPoints,
            maxSecondary = 5,
            powerLabel = "能量",
            secondaryLabel = "连击点",
        }
    elseif formID == BEAR_FORM then
        return {
            powerType = Enum.PowerType.Rage,
            secondaryPower = nil,
            maxSecondary = 0,
            powerLabel = "怒气",
            secondaryLabel = nil,
        }
    end
    return nil
end

-- Returns effective resource info: form override > spec default
function BM.GetEffectiveResourceData()
    local override = DetectFormOverride()
    if override then return override end
    return BM.SpecData[currentSpecID]
end

-- ==========================================
-- Style
-- ==========================================
function BM.GetCurrentStyle()
    local styleName = BM.db.style or "default"
    return BM.Styles[styleName] or BM.Styles["default"]
end

-- ==========================================
-- Visibility
-- ==========================================
local function ShouldShow()
    if not BM.db.enabled then return false end
    if not isDruid then return false end
    if currentSpecID == 0 then return false end
    return true
end

function BM.UpdateVisibility()
    if not MainFrame then return end
    local shouldShow = ShouldShow()
    if shouldShow and not isVisible then
        MainFrame:SetAlpha(1)
        MainFrame:Show()
        isVisible = true
    elseif not shouldShow and isVisible then
        MainFrame:Hide()
        isVisible = false
    end

    if MainFrame.title then
        if not BM.db.locked and isVisible then
            local specCN = BM.SpecNamesCN[currentSpecID] or ""
            MainFrame.title:SetText("豹集 · " .. specCN .. "  |cFFFFFF00[拖动移动 / 右键锁定]|r")
        elseif isVisible then
            local specCN = BM.SpecNamesCN[currentSpecID] or ""
            MainFrame.title:SetText("豹集 · " .. specCN)
        end
    end
end

-- ==========================================
-- Spec switch handler
-- ==========================================
local function OnSpecChanged()
    local newSpec = DetectSpec()
    if newSpec == currentSpecID then return end

    currentSpecID = newSpec

    local specData = BM.SpecData[currentSpecID]
    if not specData then
        if MainFrame then MainFrame:Hide() end
        isVisible = false
        return
    end

    local specName = BM.SpecNamesCN[currentSpecID] or BM.SpecNames[currentSpecID] or "?"
    print("|cFF00FF00badomeow:|r 切换到 |cFFFFD100" .. specName .. "|r 专精监控")

    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    if BM.RebuildDisplay then BM.RebuildDisplay() end
    BM.UpdateVisibility()
end

-- ==========================================
-- Shapeshift form change handler
-- ==========================================
local lastFormID = -1
function BM.OnFormChanged()
    local formID = GetShapeshiftFormID() or 0
    if formID == lastFormID then return end
    lastFormID = formID
    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    BM.UpdateVisibility()
end

-- ==========================================
-- Main frame setup (transparent, no backdrop)
-- ==========================================
local function SetupMainFrame()
    MainFrame = CreateFrame("Frame", "badomeowFrame", UIParent)
    BM.MainFrame = MainFrame

    local db = BM.db

    MainFrame:SetSize(db.barWidth + 20, 200)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", db.mainFrameX, db.mainFrameY)
    MainFrame:SetScale(db.scale)
    MainFrame:SetFrameStrata("MEDIUM")
    MainFrame:SetFrameLevel(10)
    MainFrame:SetClampedToScreen(true)

    -- Custom background layer (user images, or nothing by default)
    MainFrame.customBg = MainFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    MainFrame.customBg:SetAllPoints(MainFrame)
    MainFrame.customBg:Hide()
    BM.ApplyCustomBackground()

    -- Title bar
    MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY")
    MainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    MainFrame.title:SetPoint("TOP", MainFrame, "TOP", 0, -3)
    MainFrame.title:SetTextColor(0.5, 0.8, 0.4, 0.6)
    MainFrame.title:SetText("")

    -- Dragging
    MainFrame:EnableMouse(not db.locked)
    MainFrame:SetMovable(not db.locked)
    MainFrame:RegisterForDrag("LeftButton")

    MainFrame:SetScript("OnDragStart", function(self)
        if not BM.db.locked then self:StartMoving() end
    end)

    MainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        BM.db.mainFrameX = x
        BM.db.mainFrameY = y
    end)

    MainFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            BM.db.locked = not BM.db.locked
            self:SetMovable(not BM.db.locked)
            self:EnableMouse(not BM.db.locked)
            local msg = BM.db.locked and L["LOCK_FRAME"] or L["UNLOCK_FRAME"]
            print("|cFF00FF00badomeow:|r " .. msg)
            BM.UpdateVisibility()
        end
    end)

    MainFrame:Hide()
end

-- ==========================================
-- Custom background
-- ==========================================
function BM.ApplyCustomBackground()
    if not MainFrame or not MainFrame.customBg then return end
    local bgPath = BM.db.customBg
    if bgPath and bgPath ~= "" then
        MainFrame.customBg:SetTexture(bgPath)
        MainFrame.customBg:SetAlpha(0.8)
        MainFrame.customBg:Show()
    else
        MainFrame.customBg:Hide()
    end
end

-- ==========================================
-- Sound system
-- ==========================================
local SOUND_PROC  = 888
local SOUND_ALERT = 12889
local SOUND_CD    = 43487

function BM.PlayAlertSound(soundType)
    if not BM.db.playProcSound and soundType ~= "cd" then return end
    if not BM.db.playCdSound and soundType == "cd" then return end

    local soundID
    if soundType == "proc" then soundID = SOUND_PROC
    elseif soundType == "alert" then soundID = SOUND_ALERT
    elseif soundType == "cd" then soundID = SOUND_CD
    end

    if soundID then PlaySound(soundID, "SFX") end
end

function BM.PlayCustomSound(filePath)
    if filePath and filePath ~= "" then
        PlaySoundFile(filePath, "SFX")
    end
end

-- ==========================================
-- Full refresh
-- ==========================================
function BM.RefreshAll()
    if not MainFrame then return end
    local db = BM.db

    MainFrame:SetSize(db.barWidth + 20, 200)
    MainFrame:SetScale(db.scale)
    MainFrame:EnableMouse(not db.locked)
    MainFrame:SetMovable(not db.locked)

    BM.ApplyCustomBackground()
    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    if BM.RebuildDisplay then BM.RebuildDisplay() end
    BM.UpdateVisibility()
end

-- ==========================================
-- Initialization
-- ==========================================
local function InitDB()
    if not badomeowDB then badomeowDB = {} end
    CopyDefaults(BM.DefaultDB, badomeowDB)
    BM.db = badomeowDB
end

-- ==========================================
-- Events
-- ==========================================
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
EventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
EventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
EventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")

EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        L = BM.L
        isDruid = IsDruid()

        if not isDruid then return end

        SetupMainFrame()
        currentSpecID = DetectSpec()

        if BM.InitResourceBars then BM.InitResourceBars() end
        if BM.InitDisplay then BM.InitDisplay() end
        if BM.InitSettings then BM.InitSettings() end

        BM.UpdateVisibility()
        print("|cFF00FF00" .. L["ADDON_LOADED"] .. "|r")

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not isDruid then return end
        hasTarget = UnitExists("target")
        inCombat = InCombatLockdown()
        OnSpecChanged()
        lastFormID = -1
        BM.OnFormChanged()

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        if isDruid then BM.UpdateVisibility() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        if isDruid then BM.UpdateVisibility() end

    elseif event == "PLAYER_TARGET_CHANGED" then
        hasTarget = UnitExists("target")
        if isDruid then
            BM.UpdateVisibility()
            if BM.UpdateDebuffs then BM.UpdateDebuffs() end
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if isDruid then OnSpecChanged() end

    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        if isDruid then BM.OnFormChanged() end
    end
end)

-- ==========================================
-- Slash commands (MRT/DBM pattern: handler first, then SLASH_ vars)
-- ==========================================
SlashCmdList["BADOMEOW"] = function(msg)
    if not isDruid then
        print("|cFFFF5555badomeow:|r 此插件仅适用于德鲁伊职业")
        return
    end

    if not MainFrame then
        print("|cFFFF5555badomeow:|r 插件尚未完成初始化，请先 /reload")
        return
    end

    msg = strtrim(msg or ""):lower()
    if msg == "lock" then
        BM.db.locked = true
        MainFrame:SetMovable(false)
        MainFrame:EnableMouse(false)
        print("|cFF00FF00badomeow:|r " .. (L and L["LOCK_FRAME"] or "Locked"))
        BM.UpdateVisibility()
    elseif msg == "unlock" then
        BM.db.locked = false
        MainFrame:SetMovable(true)
        MainFrame:EnableMouse(true)
        print("|cFF00FF00badomeow:|r " .. (L and L["UNLOCK_FRAME"] or "Unlocked"))
        BM.UpdateVisibility()
    elseif msg == "reset" then
        BM.db.mainFrameX = 0
        BM.db.mainFrameY = -200
        MainFrame:ClearAllPoints()
        MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        print("|cFF00FF00badomeow:|r " .. (L and L["RESET_POSITION"] or "Reset"))
    elseif msg == "toggle" then
        BM.db.enabled = not BM.db.enabled
        BM.RefreshAll()
    elseif msg == "spec" then
        local specName = BM.SpecNamesCN[currentSpecID] or BM.SpecNames[currentSpecID] or "未知"
        print("|cFF00FF00badomeow:|r 当前专精: |cFFFFD100" .. specName .. "|r (" .. currentSpecID .. ")")
    else
        if BM.OpenSettings then
            BM.OpenSettings()
        else
            print("|cFF00FF00badomeow:|r /bdm lock | unlock | reset | toggle | spec")
        end
    end
end
SLASH_BADOMEOW1 = "/bdm"
SLASH_BADOMEOW2 = "/badomeow"
SLASH_BADOMEOW3 = "/baomeow"
SLASH_BADOMEOW4 = "/bado"
