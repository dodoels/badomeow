local addonName, BM = ...
local L

local MainFrame
local isDruid = false
local currentSpecID = 0
local isVisible = false

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

function BM.GetCurrentSpecID()
    return currentSpecID
end

function BM.GetEffectiveResourceData()
    local formID = GetShapeshiftFormID()
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

    if currentSpecID == 102 then
        return {
            powerType = Enum.PowerType.LunarPower,
            secondaryPower = nil, maxSecondary = 0,
            powerLabel = "星能", secondaryLabel = nil,
        }
    elseif currentSpecID == 103 then
        return {
            powerType = Enum.PowerType.Energy,
            secondaryPower = Enum.PowerType.ComboPoints,
            maxSecondary = 5,
            powerLabel = "能量", secondaryLabel = "连击点",
        }
    elseif currentSpecID == 104 then
        return {
            powerType = Enum.PowerType.Rage,
            secondaryPower = nil, maxSecondary = 0,
            powerLabel = "怒气", secondaryLabel = nil,
        }
    elseif currentSpecID == 105 then
        return {
            powerType = Enum.PowerType.Mana,
            secondaryPower = nil, maxSecondary = 0,
            powerLabel = "法力", secondaryLabel = nil,
        }
    end
    return nil
end

function BM.GetCurrentStyle()
    local styleName = BM.db.style or "default"
    return BM.Styles[styleName] or BM.Styles["default"]
end

local function ShouldShow()
    if not BM.db.enabled then return false end
    if not isDruid then return false end
    if currentSpecID == 0 then return false end
    return true
end

function BM.PlayAlertSound() end

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
            MainFrame.title:SetText("|cFFFFFF00[拖动 / 右键锁定]|r")
            MainFrame.title:Show()
        else
            MainFrame.title:SetText("")
            MainFrame.title:Hide()
        end
    end

    if not InCombatLockdown() then
        MainFrame:SetMovable(not BM.db.locked)
        MainFrame:EnableMouse(not BM.db.locked)
    end
    if BM.LayoutAll then BM.LayoutAll() end
end

local function OnSpecChanged()
    local newSpec = DetectSpec()
    if newSpec == currentSpecID then return end
    currentSpecID = newSpec

    local specName = BM.SpecNamesCN[currentSpecID] or "?"
    print("|cFF00FF00badomeow:|r 切换到 |cFFFFD100" .. specName .. "|r 专精")

    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    BM.UpdateVisibility()
end

local lastFormID = -1
function BM.OnFormChanged()
    local formID = GetShapeshiftFormID() or 0
    if formID == lastFormID then return end
    lastFormID = formID
    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    BM.UpdateVisibility()
end

local function SetupMainFrame()
    MainFrame = CreateFrame("Frame", "badomeowFrame", UIParent)
    BM.MainFrame = MainFrame

    local db = BM.db
    MainFrame:SetSize(db.barWidth, 100)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", db.mainFrameX, db.mainFrameY)
    MainFrame:SetScale(db.scale)
    MainFrame:SetFrameStrata("MEDIUM")
    MainFrame:SetFrameLevel(10)
    MainFrame:SetClampedToScreen(true)
    MainFrame:SetMovable(not db.locked)
    MainFrame:EnableMouse(not db.locked)
    MainFrame:RegisterForDrag("LeftButton")

    MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY")
    MainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    MainFrame.title:SetPoint("TOP", MainFrame, "TOP", 0, 10)
    MainFrame.title:SetTextColor(0.6, 0.8, 0.4, 0.5)
    MainFrame.title:Hide()

    MainFrame:SetScript("OnDragStart", function(self)
        if not BM.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    MainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        BM.db.mainFrameX = x
        BM.db.mainFrameY = y
    end)
    MainFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and not InCombatLockdown() then
            BM.db.locked = not BM.db.locked
            self:SetMovable(not BM.db.locked)
            self:EnableMouse(not BM.db.locked)
            local msg = BM.db.locked and "已锁定" or "已解锁"
            print("|cFF00FF00badomeow:|r " .. msg)
            BM.UpdateVisibility()
        end
    end)

    MainFrame:Hide()
end

function BM.RefreshAll()
    if not MainFrame then return end
    local db = BM.db
    MainFrame:SetScale(db.scale)
    if not InCombatLockdown() then
        MainFrame:SetMovable(not db.locked)
        MainFrame:EnableMouse(not db.locked)
    end
    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    BM.UpdateVisibility()
end

local function InitDB()
    if not badomeowDB then badomeowDB = {} end
    CopyDefaults(BM.DefaultDB, badomeowDB)
    BM.db = badomeowDB
end

local MAX_HOOK_RETRIES = 30
local function RetryViewerHooks(attempt)
    if not BM.InitViewerHooks then return end
    attempt = attempt or 1
    BM.InitViewerHooks()

    local allFound = true
    for _, vName in pairs(BM.VIEWERS) do
        if not _G[vName] then allFound = false; break end
    end

    if not allFound and attempt < MAX_HOOK_RETRIES then
        C_Timer.After(0.3, function() RetryViewerHooks(attempt + 1) end)
    end
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
EventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
EventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
EventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
EventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        L = BM.L
        isDruid = IsDruid()
        if not isDruid then return end

        SetupMainFrame()
        currentSpecID = DetectSpec()

        if BM.InitResourceBars then BM.InitResourceBars() end
        RetryViewerHooks(1)
        if BM.InitSettings then BM.InitSettings() end

        BM.UpdateVisibility()
        print("|cFF00FF00badomeow:|r 已加载 v" .. BM.VERSION)

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not isDruid then return end
        OnSpecChanged()
        lastFormID = -1
        BM.OnFormChanged()
        RetryViewerHooks(1)

    elseif event == "LOADING_SCREEN_DISABLED" then
        if not isDruid then return end
        RetryViewerHooks(1)

    elseif event == "PLAYER_REGEN_ENABLED" then
        if not isDruid or not MainFrame then return end
        MainFrame:SetMovable(not BM.db.locked)
        MainFrame:EnableMouse(not BM.db.locked)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if isDruid then OnSpecChanged() end

    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        if isDruid then BM.OnFormChanged() end
    end
end)

SlashCmdList["BADOMEOW"] = function(msg)
    if not isDruid then
        print("|cFFFF5555badomeow:|r 此插件仅适用于德鲁伊职业")
        return
    end
    if not MainFrame then
        print("|cFFFF5555badomeow:|r 插件尚未初始化")
        return
    end
    msg = strtrim(msg or ""):lower()
    if msg == "lock" then
        BM.db.locked = true
        if not InCombatLockdown() then MainFrame:SetMovable(false); MainFrame:EnableMouse(false) end
        print("|cFF00FF00badomeow:|r 已锁定")
        BM.UpdateVisibility()
    elseif msg == "unlock" then
        if InCombatLockdown() then print("|cFFFF5555badomeow:|r 战斗中无法解锁"); return end
        BM.db.locked = false
        MainFrame:SetMovable(true); MainFrame:EnableMouse(true)
        print("|cFF00FF00badomeow:|r 已解锁")
        BM.UpdateVisibility()
    elseif msg == "reset" then
        BM.db.mainFrameX = 0; BM.db.mainFrameY = -200
        MainFrame:ClearAllPoints()
        MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        print("|cFF00FF00badomeow:|r 位置已重置")
    elseif msg == "debug" then
        print("|cFF00FF00badomeow debug:|r --- Viewer Status ---")
        for key, vName in pairs(BM.VIEWERS) do
            local viewer = _G[vName]
            if viewer then
                local count = 0
                if viewer.itemFramePool then
                    for frame in viewer.itemFramePool:EnumerateActive() do
                        if frame:IsShown() then count = count + 1 end
                    end
                end
                print("  " .. key .. " (" .. vName .. "): |cFF00FF00存在|r, 激活=" .. count)
            else
                print("  " .. key .. " (" .. vName .. "): |cFFFF5555未找到|r")
            end
        end
        print("|cFF00FF00badomeow debug:|r shown=" .. tostring(MainFrame:IsShown()) .. " spec=" .. currentSpecID .. " combat=" .. tostring(InCombatLockdown()))
    else
        if BM.OpenSettings then BM.OpenSettings()
        else print("|cFF00FF00badomeow:|r /bdm lock | unlock | reset | debug") end
    end
end
SLASH_BADOMEOW1 = "/bdm"
SLASH_BADOMEOW2 = "/badomeow"
SLASH_BADOMEOW3 = "/bado"
