local addonName, FFS = ...
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
    return classID == FFS.DRUID_CLASS_ID
end

function FFS.GetCurrentSpecID() return currentSpecID end

function FFS.GetEffectiveResourceData()
    local currentPowerType = UnitPowerType("player")

    local result = { showMana = false }

    if currentPowerType == Enum.PowerType.Energy then
        result.powerType = Enum.PowerType.Energy
        result.secondaryPower = Enum.PowerType.ComboPoints
        result.maxSecondary = 5
        result.showMana = true
    elseif currentPowerType == Enum.PowerType.Rage then
        result.powerType = Enum.PowerType.Rage
        result.showMana = true
    elseif currentPowerType == Enum.PowerType.LunarPower then
        result.powerType = Enum.PowerType.LunarPower
        result.showMana = true
    elseif currentPowerType == Enum.PowerType.Mana then
        result.powerType = Enum.PowerType.Mana
        result.showMana = false
    else
        if currentSpecID == 102 then
            result.powerType = Enum.PowerType.LunarPower
            result.showMana = true
        elseif currentSpecID == 103 then
            result.powerType = Enum.PowerType.Energy
            result.secondaryPower = Enum.PowerType.ComboPoints
            result.maxSecondary = 5
        elseif currentSpecID == 104 then
            result.powerType = Enum.PowerType.Rage
        elseif currentSpecID == 105 then
            result.powerType = Enum.PowerType.Mana
        else
            return nil
        end
    end

    if result.powerType == Enum.PowerType.Mana then
        result.showMana = false
    end

    return result
end

function FFS.GetCurrentStyle()
    return FFS.Styles[FFS.db.style or "default"] or FFS.Styles["default"]
end

function FFS.PlayAlertSound() end

FFS.settingsOpen = false

local function ShouldShow()
    if not FFS.db.enabled then return false end
    if not isDruid then return false end
    if currentSpecID == 0 then return false end
    return true
end

function FFS.UpdateVisibility()
    local show = ShouldShow()
    for _, sec in ipairs(FFS.SECTIONS) do
        local f = FFS.sectionFrames and FFS.sectionFrames[sec]
        if f then
            if show then f:Show() else f:Hide() end
        end
    end
    if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
end

local function OnSpecChanged()
    local newSpec = DetectSpec()
    if newSpec == currentSpecID then return end
    currentSpecID = newSpec
    local specName = FFS.SpecNamesCN[currentSpecID] or "?"
    print("|cFF00FF00豹读诗书:|r 切换到 |cFFFFD100" .. specName .. "|r 专精")
    if FFS.RebuildResourceBars then FFS.RebuildResourceBars() end
    FFS.UpdateVisibility()
end

local lastFormID = -1
function FFS.OnFormChanged()
    local formID = GetShapeshiftFormID() or 0
    if formID == lastFormID then return end
    lastFormID = formID
    if FFS.RebuildResourceBars then FFS.RebuildResourceBars() end
end

function FFS.RefreshAll()
    if FFS.RefreshSectionScales then FFS.RefreshSectionScales() end
    if FFS.RebuildResourceBars then FFS.RebuildResourceBars() end
    FFS.UpdateVisibility()
end

local function InitDB()
    if not ForFeralSakeDB then ForFeralSakeDB = {} end
    CopyDefaults(FFS.DefaultDB, ForFeralSakeDB)
    FFS.db = ForFeralSakeDB
end

local MAX_HOOK_RETRIES = 30
local function RetryViewerHooks(attempt)
    if not FFS.InitViewerHooks then return end
    attempt = attempt or 1
    FFS.InitViewerHooks()
    local allFound = true
    for _, vName in pairs(FFS.VIEWERS) do
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
        L = FFS.L
        isDruid = IsDruid()
        if not isDruid then return end
        currentSpecID = DetectSpec()
        if FFS.InitResourceBars then FFS.InitResourceBars() end
        RetryViewerHooks(1)
        if FFS.InitSettings then FFS.InitSettings() end
        FFS.UpdateVisibility()
        print("|cFF00FF00豹读诗书:|r 已加载 v" .. FFS.VERSION)

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not isDruid then return end
        OnSpecChanged()
        lastFormID = -1
        FFS.OnFormChanged()
        RetryViewerHooks(1)

    elseif event == "LOADING_SCREEN_DISABLED" then
        if not isDruid then return end
        RetryViewerHooks(1)

    elseif event == "PLAYER_REGEN_ENABLED" then
        if not isDruid then return end
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if isDruid then OnSpecChanged() end

    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        if isDruid then FFS.OnFormChanged() end
    end
end)

SlashCmdList["FORFERALSAKE"] = function(msg)
    if not isDruid then
        print("|cFFFF5555豹读诗书:|r 此插件仅适用于德鲁伊职业"); return
    end
    msg = strtrim(msg or ""):lower()
    if msg == "lock" then
        FFS.db.locked = true
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
        print("|cFF00FF00豹读诗书:|r 已锁定")
    elseif msg == "unlock" then
        if InCombatLockdown() then print("|cFFFF5555豹读诗书:|r 战斗中无法解锁"); return end
        FFS.db.locked = false
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
        print("|cFF00FF00豹读诗书:|r 已解锁，拖动各组件移动位置")
    elseif msg == "reset" then
        if FFS.ResetAllPositions then FFS.ResetAllPositions() end
        print("|cFF00FF00豹读诗书:|r 所有位置已重置")
    elseif msg == "debug" then
        print("|cFF00FF00豹读诗书 debug:|r --- Viewer Status ---")
        for key, vName in pairs(FFS.VIEWERS) do
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
        if FFS.OpenSettings then FFS.OpenSettings()
        else print("|cFF00FF00豹读诗书:|r /ffs lock | unlock | reset | debug") end
    end
end
SLASH_FORFERALSAKE1 = "/ffs"
SLASH_FORFERALSAKE2 = "/forferalsake"
