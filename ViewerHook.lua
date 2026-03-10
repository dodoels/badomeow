local addonName, BM = ...

--[[
    Reparents Blizzard CooldownViewer item frames into badomeow containers.
    Following Ayije_CDM's approach: we never create mirror icons or read
    secret values. We simply move Blizzard's own frames into our layout.
]]

local VIEWERS = BM.VIEWERS

local containers = {}

local SECTION_SIZES = {
    buff      = 26,
    essential = 30,
    utility   = 22,
}

local SECTION_TO_VIEWERS = {
    essential = { VIEWERS.ESSENTIAL },
    utility   = { VIEWERS.UTILITY },
    buff      = { VIEWERS.BUFF, VIEWERS.BUFF_BAR },
}

local VIEWER_TO_SECTION = {}
for sec, list in pairs(SECTION_TO_VIEWERS) do
    for _, v in ipairs(list) do VIEWER_TO_SECTION[v] = sec end
end

local ALL_SECTIONS = { "essential", "buff", "utility" }
local ALL_VIEWER_NAMES = {}
for _, list in pairs(SECTION_TO_VIEWERS) do
    for _, v in ipairs(list) do ALL_VIEWER_NAMES[#ALL_VIEWER_NAMES + 1] = v end
end

---------------------------------------------------------------------------
-- IsSafeNumber — identical approach to Ayije_CDM
---------------------------------------------------------------------------
local function IsSafeNumber(value)
    if value == nil or type(value) ~= "number" then return false end
    if issecretvalue then
        return not issecretvalue(value)
    end
    local ok, _ = pcall(tostring, value)
    return ok
end

local function IsSafeValue(value)
    if value == nil then return false end
    if type(value) == "number" then return IsSafeNumber(value) end
    if type(value) == "boolean" then
        if issecretvalue then return not issecretvalue(value) end
        local ok, _ = pcall(tostring, value)
        return ok
    end
    return true
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function IsSectionEnabled(section)
    local db = BM.db
    if section == "buff"      then return db.showBuff ~= false end
    if section == "essential" then return db.showEssential ~= false end
    if section == "utility"   then return db.showUtility ~= false end
    if section == "primary"   then return db.showPrimaryBar ~= false end
    if section == "secondary" then return db.showSecondaryBar ~= false end
    return true
end

local function SectionHasContent(section)
    if not IsSectionEnabled(section) then return false end
    if section == "primary" then return BM.primaryBar ~= nil end
    if section == "secondary" then return BM.secondaryContainer ~= nil end
    local c = containers[section]
    if not c then return false end
    local children = { c:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsShown() then return true end
    end
    return false
end

local function SectionHeight(section)
    if section == "primary" then return BM.db.barHeight end
    return SECTION_SIZES[section] or 20
end

local function EnsureContainer(section)
    if containers[section] then return containers[section] end
    if not BM.MainFrame then return nil end
    local c = CreateFrame("Frame", nil, BM.MainFrame)
    c:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    containers[section] = c
    return c
end

---------------------------------------------------------------------------
-- Master layout
---------------------------------------------------------------------------
function BM.LayoutAll()
    if not BM.MainFrame then return end
    local db = BM.db
    local w = db.barWidth
    local order = db.layoutOrder or BM.SECTIONS
    local y = 0

    for i = #order, 1, -1 do
        local sec = order[i]
        if SectionHasContent(sec) then
            local h = SectionHeight(sec)
            if sec == "primary" and BM.primaryBar then
                BM.primaryBar:ClearAllPoints()
                BM.primaryBar:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                BM.primaryBar:SetSize(w, h)
                BM.primaryBar:Show()
            elseif sec == "secondary" and BM.secondaryContainer then
                BM.secondaryContainer:ClearAllPoints()
                BM.secondaryContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                BM.secondaryContainer:SetSize(w, h)
                BM.secondaryContainer:Show()
            else
                local c = containers[sec]
                if c then
                    c:ClearAllPoints()
                    c:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                    c:SetSize(w, h)
                    c:Show()
                end
            end
            y = y + h
        else
            if containers[sec] then containers[sec]:Hide() end
            if sec == "primary" and BM.primaryBar then BM.primaryBar:Hide() end
            if sec == "secondary" and BM.secondaryContainer then BM.secondaryContainer:Hide() end
        end
    end

    if not db.locked then y = y + 14 end
    BM.MainFrame:SetSize(w, math.max(y, 20))
end

---------------------------------------------------------------------------
-- Reparent Blizzard frames into our containers (Ayije_CDM approach)
---------------------------------------------------------------------------
local function LayoutSection(section)
    local container = EnsureContainer(section)
    if not container then return end
    local size = SECTION_SIZES[section] or 24

    if not IsSectionEnabled(section) then
        container:Hide()
        return
    end

    -- Collect all active frames from all viewers for this section
    local frames = {}
    local viewerList = SECTION_TO_VIEWERS[section]
    if viewerList then
        for _, vName in ipairs(viewerList) do
            local viewer = _G[vName]
            if viewer and viewer.itemFramePool then
                for frame in viewer.itemFramePool:EnumerateActive() do
                    if frame and frame:IsShown() then
                        frames[#frames + 1] = frame
                    end
                end
            end
        end
    end

    -- Sort by layoutIndex (safe check)
    if #frames > 1 then
        table.sort(frames, function(a, b)
            local aIdx = a.layoutIndex
            local bIdx = b.layoutIndex
            local aOk = IsSafeNumber(aIdx)
            local bOk = IsSafeNumber(bIdx)
            if aOk and bOk then return aIdx < bIdx end
            if aOk then return true end
            if bOk then return false end
            return false
        end)
    end

    -- Reparent and position each frame
    local spacing = (section == "utility") and 1 or 2
    for idx, frame in ipairs(frames) do
        frame:SetParent(container)
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", container, "LEFT", (idx - 1) * (size + spacing), 0)
    end

    if #frames > 0 then container:Show() else container:Hide() end
end

---------------------------------------------------------------------------
-- Hooking (same as before but calls LayoutSection)
---------------------------------------------------------------------------
local hookedViewers = {}
local hookedMixins = false

local function OnViewerChanged(vName)
    local section = VIEWER_TO_SECTION[vName]
    if section then
        LayoutSection(section)
        BM.LayoutAll()
    end
end

local function HookViewer(vName)
    local viewer = _G[vName]
    if not viewer or hookedViewers[viewer] then return end
    hookedViewers[viewer] = true

    local function cb() OnViewerChanged(vName) end

    if viewer.RefreshData then hooksecurefunc(viewer, "RefreshData", cb) end
    if viewer.UpdateLayout then hooksecurefunc(viewer, "UpdateLayout", cb)
    elseif viewer.Layout then hooksecurefunc(viewer, "Layout", cb) end
    if viewer.RefreshLayout then hooksecurefunc(viewer, "RefreshLayout", cb) end
    if viewer.itemFramePool then
        hooksecurefunc(viewer.itemFramePool, "Acquire", cb)
        hooksecurefunc(viewer.itemFramePool, "Release", cb)
    end
    viewer:HookScript("OnShow", cb)
    cb()
end

local function HookMixins()
    if hookedMixins then return end
    hookedMixins = true
    local map = {
        CooldownViewerEssentialItemMixin = VIEWERS.ESSENTIAL,
        CooldownViewerUtilityItemMixin   = VIEWERS.UTILITY,
        CooldownViewerBuffIconItemMixin  = VIEWERS.BUFF,
        CooldownViewerBuffBarItemMixin   = VIEWERS.BUFF_BAR,
    }
    for name, vName in pairs(map) do
        local m = _G[name]
        if m then
            local cb = function() OnViewerChanged(vName) end
            if m.OnCooldownIDSet      then hooksecurefunc(m, "OnCooldownIDSet", cb) end
            if m.OnActiveStateChanged then hooksecurefunc(m, "OnActiveStateChanged", cb) end
        end
    end
end

---------------------------------------------------------------------------
-- Periodic fallback refresh
---------------------------------------------------------------------------
local timer = 0
local tickFrame = CreateFrame("Frame")
tickFrame:SetScript("OnUpdate", function(_, dt)
    timer = timer + dt
    if timer < 0.2 then return end
    timer = 0
    if not BM.MainFrame or not BM.MainFrame:IsShown() then return end
    for _, sec in ipairs(ALL_SECTIONS) do
        LayoutSection(sec)
    end
    BM.LayoutAll()
end)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function BM.SwapSectionOrder(key, dir)
    local order = BM.db.layoutOrder
    for i, k in ipairs(order) do
        if k == key then
            local t = i + dir
            if t >= 1 and t <= #order then
                order[i], order[t] = order[t], order[i]
                BM.LayoutAll()
            end
            return
        end
    end
end

function BM.InitViewerHooks()
    for _, sec in ipairs(ALL_SECTIONS) do EnsureContainer(sec) end
    for _, vName in ipairs(ALL_VIEWER_NAMES) do HookViewer(vName) end
    HookMixins()
    BM.LayoutAll()
end
