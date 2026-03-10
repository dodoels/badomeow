local addonName, BM = ...
local L

local isDruid = false
local currentSpecID = 0

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if dst[k] == nil then
                dst[k] = {}
            end
            if type(dst[k]) == "table" then
                CopyDefaults(v, dst[k])
            end
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

function BM.GetCurrentSpecID() return currentSpecID end

function BM.GetEffectiveResourceData()
    local formID = GetShapeshiftFormID()
    if formID == CAT_FORM then
        return {
            powerType = Enum.PowerType.Energy,
            secondaryPower = Enum.PowerType.ComboPoints,
            maxSecondary = 5,
            showMana = true,
        }
    elseif formID == BEAR_FORM then
        return {
            powerType = Enum.PowerType.Rage,
            showMana = true,
        }
    end
    if currentSpecID == 102 then return { powerType = Enum.PowerType.LunarPower, showMana = true }
    elseif currentSpecID == 103 then return { powerType = Enum.PowerType.Energy, secondaryPower = Enum.PowerType.ComboPoints, maxSecondary = 5, showMana = false }
    elseif currentSpecID == 104 then return { powerType = Enum.PowerType.Rage, showMana = false }
    elseif currentSpecID == 105 then return { powerType = Enum.PowerType.Mana, showMana = false }
    end
    return nil
end

function BM.GetCurrentStyle()
    return BM.Styles[BM.db.style or "default"] or BM.Styles["default"]
end

function BM.PlayAlertSound() end

BM.settingsOpen = false

---------------------------------------------------------------------------
-- Visibility: show/hide all section frames based on class+spec
---------------------------------------------------------------------------
local function ShouldShow()
    if not BM.db.enabled then return false end
    if not isDruid then return false end
    if currentSpecID == 0 then return false end
    return true
end

function BM.UpdateVisibility()
    local show = ShouldShow()
    for _, sec in ipairs(BM.SECTIONS) do
        local f = BM.sectionFrames and BM.sectionFrames[sec]
        if f then
            if show then f:Show() else f:Hide() end
        end
    end
    if BM.UpdateSectionLockState then BM.UpdateSectionLockState() end
end

---------------------------------------------------------------------------
-- Spec / form changes
---------------------------------------------------------------------------
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
end

---------------------------------------------------------------------------
-- Refresh all (called from Settings sliders)
---------------------------------------------------------------------------
function BM.RefreshAll()
    if BM.RefreshSectionScales then BM.RefreshSectionScales() end
    if BM.RebuildResourceBars then BM.RebuildResourceBars() end
    BM.UpdateVisibility()
end

---------------------------------------------------------------------------
-- DB init
---------------------------------------------------------------------------
local function InitDB()
    if not badomeowDB then badomeowDB = {} end
    CopyDefaults(BM.DefaultDB, badomeowDB)
    BM.db = badomeowDB
end

---------------------------------------------------------------------------
-- Retry viewer hooks
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
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
        if not isDruid then return end
        if BM.UpdateSectionLockState then BM.UpdateSectionLockState() end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if isDruid then OnSpecChanged() end

    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        if isDruid then BM.OnFormChanged() end
    end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SlashCmdList["BADOMEOW"] = function(msg)
    if not isDruid then
        print("|cFFFF5555badomeow:|r 此插件仅适用于德鲁伊职业"); return
    end
    msg = strtrim(msg or ""):lower()
    if msg == "lock" then
        BM.db.locked = true
        if BM.UpdateSectionLockState then BM.UpdateSectionLockState() end
        print("|cFF00FF00badomeow:|r 已锁定")
    elseif msg == "unlock" then
        if InCombatLockdown() then print("|cFFFF5555badomeow:|r 战斗中无法解锁"); return end
        BM.db.locked = false
        if BM.UpdateSectionLockState then BM.UpdateSectionLockState() end
        print("|cFF00FF00badomeow:|r 已解锁，拖动各组件移动位置")
    elseif msg == "reset" then
        if BM.ResetAllPositions then BM.ResetAllPositions() end
        print("|cFF00FF00badomeow:|r 所有位置已重置")
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
                print("  " .. key .. ": |cFF00FF00存在|r, 激活=" .. count)
            else
                print("  " .. key .. ": |cFFFF5555未找到|r")
            end
        end
        print("  spec=" .. currentSpecID .. " combat=" .. tostring(InCombatLockdown()))
    else
        if BM.OpenSettings then BM.OpenSettings()
        else print("|cFF00FF00badomeow:|r /bdm lock | unlock | reset | debug") end
    end
end
SLASH_BADOMEOW1 = "/bdm"
SLASH_BADOMEOW2 = "/badomeow"
SLASH_BADOMEOW3 = "/bado"
