local addonName, BM = ...

--[[
    ViewerHook: Hooks Blizzard's 12.0 CooldownViewer system.
    Mirrors spell icons from official viewers into our own compact layout.

    Layout (top to bottom, no gaps, no labels):
      [Essential icons]  - core cooldowns, full barWidth, large icons
      [Combo pips]       - secondary resource (if any)
      [Resource bar]     - primary resource
      [Utility icons]    - utility cooldowns, small icons
]]

local VIEWERS = BM.VIEWERS

local hookedViewers = {}
local hookedMixins = {}
local mirrorIcons = {}

local essentialContainer
local utilityContainer

local ESSENTIAL_ICON_SIZE = 30
local UTILITY_ICON_SIZE = 22
local ICON_PAD = 1

local function GetSpellIDFromFrame(frame)
    if not frame then return nil end
    local spellID
    if frame.GetSpellID and type(frame.GetSpellID) == "function" then
        local ok, result = pcall(frame.GetSpellID, frame)
        if ok and result then spellID = result end
    end
    if not spellID and frame.cooldownInfo then
        local info = frame.cooldownInfo
        spellID = info.overrideSpellID or info.spellID
    end
    if spellID and type(spellID) == "number" then
        local ok, isSafe = pcall(function() return not issecretvalue(spellID) end)
        if ok and not isSafe then return nil end
    end
    return spellID
end

local function CreateMirrorIcon(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    f:SetFrameLevel(parent:GetFrameLevel() + 2)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", ICON_PAD, -ICON_PAD)
    f.icon:SetPoint("BOTTOMRIGHT", -ICON_PAD, ICON_PAD)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints(f.icon)
    f.cd:SetDrawEdge(true)
    f.cd:SetHideCountdownNumbers(false)

    f:Hide()
    return f
end

local function EnsureContainers()
    if essentialContainer and utilityContainer then return end
    if not BM.MainFrame then return end

    local db = BM.db

    if not essentialContainer then
        essentialContainer = CreateFrame("Frame", nil, BM.MainFrame)
        essentialContainer:SetSize(db.barWidth, ESSENTIAL_ICON_SIZE)
        essentialContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    end

    if not utilityContainer then
        utilityContainer = CreateFrame("Frame", nil, BM.MainFrame)
        utilityContainer:SetSize(db.barWidth, UTILITY_ICON_SIZE)
        utilityContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    end
end

-- Core layout: position everything tightly
function BM.LayoutAll()
    if not BM.MainFrame then return end
    EnsureContainers()
    local db = BM.db
    local w = db.barWidth

    -- Build from bottom up
    local y = 0

    -- Utility row (bottom)
    if utilityContainer then
        local hasIcons = false
        local icons = mirrorIcons[VIEWERS.UTILITY]
        if icons then
            for _, ic in ipairs(icons) do
                if ic:IsShown() then hasIcons = true; break end
            end
        end
        if hasIcons then
            utilityContainer:ClearAllPoints()
            utilityContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
            utilityContainer:SetSize(w, UTILITY_ICON_SIZE)
            utilityContainer:Show()
            y = y + UTILITY_ICON_SIZE
        else
            utilityContainer:Hide()
        end
    end

    -- Primary resource bar
    if BM.primaryBar then
        BM.primaryBar:ClearAllPoints()
        BM.primaryBar:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        BM.primaryBar:SetSize(w, db.barHeight)
        y = y + db.barHeight
    end

    -- Secondary pips (combo points)
    if BM.secondaryContainer then
        BM.secondaryContainer:ClearAllPoints()
        BM.secondaryContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        BM.secondaryContainer:SetSize(w, 10)
        y = y + 10
    end

    -- Essential row (top)
    if essentialContainer then
        local hasIcons = false
        local icons = mirrorIcons[VIEWERS.ESSENTIAL]
        if icons then
            for _, ic in ipairs(icons) do
                if ic:IsShown() then hasIcons = true; break end
            end
        end
        if hasIcons then
            essentialContainer:ClearAllPoints()
            essentialContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
            essentialContainer:SetSize(w, ESSENTIAL_ICON_SIZE)
            essentialContainer:Show()
            y = y + ESSENTIAL_ICON_SIZE
        else
            essentialContainer:Hide()
        end
    end

    -- Title bar space (only when unlocked)
    if not db.locked then
        y = y + 14
    end

    BM.MainFrame:SetSize(w, math.max(y, 20))
end

local function FormatTime(sec)
    if sec > 60 then return string.format("%dm", sec / 60)
    elseif sec > 3 then return string.format("%d", sec)
    else return string.format("%.1f", sec) end
end

local function RefreshViewerMirror(viewerName)
    local viewer = _G[viewerName]
    if not viewer or not viewer.itemFramePool then return end

    EnsureContainers()
    local isEssential = (viewerName == VIEWERS.ESSENTIAL)
    local container = isEssential and essentialContainer or utilityContainer
    if not container then return end

    local size = isEssential and ESSENTIAL_ICON_SIZE or UTILITY_ICON_SIZE

    if not mirrorIcons[viewerName] then mirrorIcons[viewerName] = {} end
    local icons = mirrorIcons[viewerName]

    for _, ic in ipairs(icons) do ic:Hide() end

    local idx = 0
    local spacing = isEssential and 2 or 1
    local now = GetTime()

    for frame in viewer.itemFramePool:EnumerateActive() do
        if frame:IsShown() then
            local spellID = GetSpellIDFromFrame(frame)
            if spellID then
                idx = idx + 1
                local ic = icons[idx]
                if not ic then
                    ic = CreateMirrorIcon(container, size)
                    icons[idx] = ic
                end
                ic:SetSize(size, size)

                local tex = C_Spell.GetSpellTexture(spellID)
                if tex then ic.icon:SetTexture(tex) end

                ic:ClearAllPoints()
                ic:SetPoint("LEFT", container, "LEFT", (idx - 1) * (size + spacing), 0)

                if frame.Cooldown then
                    local cdStart, cdDuration = frame.Cooldown:GetCooldownTimes()
                    if cdStart and cdDuration then
                        cdStart = cdStart / 1000
                        cdDuration = cdDuration / 1000
                        if cdDuration > 1.5 then
                            ic.cd:SetCooldown(cdStart, cdDuration)
                            ic.icon:SetDesaturated(true)
                        else
                            ic.cd:Clear()
                            ic.icon:SetDesaturated(false)
                        end
                    end
                end

                ic:Show()
            end
        end
    end

    container:Show()
    BM.LayoutAll()
end

local function HookViewer(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end
    if hookedViewers[viewer] then return end
    hookedViewers[viewer] = true

    local function OnChange() RefreshViewerMirror(viewerName) end

    if viewer.RefreshData then hooksecurefunc(viewer, "RefreshData", OnChange) end
    if viewer.UpdateLayout then
        hooksecurefunc(viewer, "UpdateLayout", OnChange)
    elseif viewer.Layout then
        hooksecurefunc(viewer, "Layout", OnChange)
    end
    if viewer.RefreshLayout then hooksecurefunc(viewer, "RefreshLayout", OnChange) end

    if viewer.itemFramePool then
        hooksecurefunc(viewer.itemFramePool, "Acquire", OnChange)
        hooksecurefunc(viewer.itemFramePool, "Release", OnChange)
    end

    viewer:HookScript("OnShow", OnChange)
    RefreshViewerMirror(viewerName)
end

local function HookMixins()
    if hookedMixins.done then return end

    local map = {
        CooldownViewerEssentialItemMixin = VIEWERS.ESSENTIAL,
        CooldownViewerUtilityItemMixin   = VIEWERS.UTILITY,
    }

    for mixinName, vName in pairs(map) do
        local mixin = _G[mixinName]
        if mixin then
            if mixin.OnCooldownIDSet then
                hooksecurefunc(mixin, "OnCooldownIDSet", function()
                    RefreshViewerMirror(vName)
                end)
            end
            if mixin.OnActiveStateChanged then
                hooksecurefunc(mixin, "OnActiveStateChanged", function()
                    RefreshViewerMirror(vName)
                end)
            end
        end
    end

    hookedMixins.done = true
end

local refreshTimer = 0
local refreshFrame = CreateFrame("Frame")
refreshFrame:SetScript("OnUpdate", function(self, elapsed)
    refreshTimer = refreshTimer + elapsed
    if refreshTimer < 0.1 then return end
    refreshTimer = 0
    if not BM.MainFrame or not BM.MainFrame:IsShown() then return end

    for _, vName in ipairs({ VIEWERS.ESSENTIAL, VIEWERS.UTILITY }) do
        if _G[vName] then
            RefreshViewerMirror(vName)
        end
    end
end)

function BM.InitViewerHooks()
    for _, vName in ipairs({ VIEWERS.ESSENTIAL, VIEWERS.UTILITY }) do
        HookViewer(vName)
    end
    HookMixins()
    BM.LayoutAll()
end
