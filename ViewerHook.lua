local addonName, BM = ...

--[[
    v4: Each section is an independent frame anchored to UIParent.
    Reparents Blizzard CooldownViewer item frames into section anchors.
    No secret value access. Each section independently draggable.
]]

local VIEWERS = BM.VIEWERS

local sectionFrames = {}  -- section -> anchor Frame

local SECTION_TO_VIEWERS = {
    essential = { VIEWERS.ESSENTIAL },
    utility   = { VIEWERS.UTILITY },
    buff      = { VIEWERS.BUFF, VIEWERS.BUFF_BAR },
}

local VIEWER_TO_SECTION = {}
for sec, list in pairs(SECTION_TO_VIEWERS) do
    for _, v in ipairs(list) do VIEWER_TO_SECTION[v] = sec end
end

local ICON_SECTIONS = { "essential", "buff", "utility" }
local ALL_VIEWER_NAMES = {}
for _, list in pairs(SECTION_TO_VIEWERS) do
    for _, v in ipairs(list) do ALL_VIEWER_NAMES[#ALL_VIEWER_NAMES + 1] = v end
end

---------------------------------------------------------------------------
-- IsSafeNumber
---------------------------------------------------------------------------
local function IsSafeNumber(value)
    if value == nil or type(value) ~= "number" then return false end
    if issecretvalue then return not issecretvalue(value) end
    local ok, _ = pcall(tostring, value)
    return ok
end

---------------------------------------------------------------------------
-- Section icon size from db
---------------------------------------------------------------------------
local function GetSectionIconSize(section)
    local db = BM.db
    if section == "essential" then return db.essentialSize or 36 end
    if section == "buff"      then return db.buffSize or 30 end
    if section == "utility"   then return db.utilitySize or 26 end
    return 30
end

---------------------------------------------------------------------------
-- Section enable check
---------------------------------------------------------------------------
local function IsSectionEnabled(section)
    local db = BM.db
    if section == "buff"      then return db.showBuff ~= false end
    if section == "essential" then return db.showEssential ~= false end
    if section == "utility"   then return db.showUtility ~= false end
    if section == "primary"   then return db.showPrimaryBar ~= false end
    if section == "secondary" then return db.showSecondaryBar ~= false end
    if section == "mana"      then return db.showManaBar ~= false end
    return true
end

---------------------------------------------------------------------------
-- Create / get section anchor frame (independent, parented to UIParent)
---------------------------------------------------------------------------
local function GetPosKey(section) return "pos_" .. section end

local function SaveSectionPos(section)
    local f = sectionFrames[section]
    if not f then return end
    local _, _, relTo, x, y = f:GetPoint()
    if not BM.db[GetPosKey(section)] then BM.db[GetPosKey(section)] = {} end
    BM.db[GetPosKey(section)].x = x
    BM.db[GetPosKey(section)].y = y
end

-- After StopMovingOrSizing, WoW changes the anchor arbitrarily.
-- Use GetCenter() to get screen coords, then convert to CENTER offset.
-- GetCenter() returns coords in the parent's coordinate space, but
-- SetPoint offsets are in the frame's own scaled space, so we must
-- divide by the frame's scale factor.
local function NormalizeToCenterOffset(frame)
    local cx, cy = frame:GetCenter()
    local pcx, pcy = UIParent:GetCenter()
    if not cx or not pcx then return 0, 0 end
    local s = frame:GetScale()
    local offX = (cx - pcx) / s
    local offY = (cy - pcy) / s
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", offX, offY)
    return offX, offY
end

local function MakeDraggable(frame, section)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame._dragStartCX = nil
    frame._dragStartCY = nil
    frame:SetScript("OnDragStart", function(self)
        if not BM.db.locked and not InCombatLockdown() then
            local pos = BM.db[GetPosKey(section)]
            if pos then
                self._dragStartCX = pos.x
                self._dragStartCY = pos.y
            end
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local newX, newY = NormalizeToCenterOffset(self)

        local moveAll = IsShiftKeyDown()
        if moveAll and self._dragStartCX and self._dragStartCY then
            local dx = newX - self._dragStartCX
            local dy = newY - self._dragStartCY
            for _, sec in ipairs(BM.SECTIONS) do
                local sf = sectionFrames[sec]
                if sf and sf ~= self then
                    local p = BM.db[GetPosKey(sec)]
                    if p then
                        local nx = p.x + dx
                        local ny = p.y + dy
                        sf:ClearAllPoints()
                        sf:SetPoint("CENTER", UIParent, "CENTER", nx, ny)
                        BM.db[GetPosKey(sec)].x = nx
                        BM.db[GetPosKey(sec)].y = ny
                    end
                end
            end
        end
        SaveSectionPos(section)
        self._dragStartCX = nil
        self._dragStartCY = nil
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and not InCombatLockdown() then
            BM.db.locked = not BM.db.locked
            if BM.UpdateSectionLockState then BM.UpdateSectionLockState() end
            local msg = BM.db.locked and "已锁定" or "已解锁"
            print("|cFF00FF00badomeow:|r " .. msg)
        end
    end)
end

local function EnsureSectionFrame(section)
    if sectionFrames[section] then return sectionFrames[section] end

    local f = CreateFrame("Frame", "badomeowSec_" .. section, UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(12)
    f:SetClampedToScreen(true)

    local db = BM.db
    local pos = db[GetPosKey(section)] or { x = 0, y = -200 }
    f:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    f:SetScale(db.scale or 1)
    f:SetSize(100, 30)

    MakeDraggable(f, section)

    -- Label shown when unlocked
    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    f.label:SetPoint("TOP", f, "TOP", 0, 12)
    f.label:SetTextColor(1, 0.85, 0, 0.8)
    f.label:SetText(BM.SECTION_LABELS[section] or section)
    f.label:Hide()

    -- Background shown when unlocked (subtle)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0.1, 0.1, 0.1, 0.4)
    f.bg:Hide()

    sectionFrames[section] = f
    return f
end

BM.sectionFrames = sectionFrames

---------------------------------------------------------------------------
-- Update lock/unlock visuals for all section frames
---------------------------------------------------------------------------
function BM.UpdateSectionLockState()
    local locked = BM.db.locked
    local settingsOpen = BM.settingsOpen
    local showGuides = not locked or settingsOpen

    for _, sec in ipairs(BM.SECTIONS) do
        local f = sectionFrames[sec]
        if f then
            if not InCombatLockdown() then
                f:SetMovable(not locked)
                f:EnableMouse(not locked)
            end
            if f.label then
                if showGuides and IsSectionEnabled(sec) then f.label:Show() else f.label:Hide() end
            end
            if f.bg then
                if showGuides and IsSectionEnabled(sec) then f.bg:Show() else f.bg:Hide() end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Refresh icon layout inside a section
---------------------------------------------------------------------------
local function LayoutSection(section)
    local f = sectionFrames[section]
    if not f then return end
    local iconSz = GetSectionIconSize(section)
    local spacing = BM.db.iconSpacing or 2

    if not IsSectionEnabled(section) then
        f:Hide()
        return
    end

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

    local totalW = #frames > 0 and (#frames * iconSz + (#frames - 1) * spacing) or iconSz
    f:SetSize(totalW, iconSz)

    for idx, frame in ipairs(frames) do
        -- Reparent to UIParent (not our container) to avoid disrupting
        -- Blizzard's viewer layout calculations. Position relative to
        -- our container frame so they move with it when dragged.
        frame:SetParent(UIParent)
        frame:ClearAllPoints()
        frame:SetSize(iconSz, iconSz)
        frame:SetPoint("LEFT", f, "LEFT", (idx - 1) * (iconSz + spacing), 0)
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(f:GetFrameLevel() + 2)
    end

    local unlocked = not BM.db.locked
    local previewMode = unlocked or BM.settingsOpen
    if #frames > 0 then
        f:Show()
    elseif previewMode and IsSectionEnabled(section) then
        local minW = GetSectionIconSize(section) * 3 + spacing * 2
        f:SetSize(minW, GetSectionIconSize(section))
        f:Show()
    else
        f:Hide()
    end
end

---------------------------------------------------------------------------
-- Hooking
---------------------------------------------------------------------------
local hookedViewers = {}
local hookedMixins = false

local function OnViewerChanged(vName)
    local section = VIEWER_TO_SECTION[vName]
    if section then LayoutSection(section) end
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
    for _, sec in ipairs(ICON_SECTIONS) do
        LayoutSection(sec)
    end
end)

---------------------------------------------------------------------------
-- Public init
---------------------------------------------------------------------------
function BM.InitViewerHooks()
    -- Create frames for ALL sections (including primary/secondary for resource bars)
    for _, sec in ipairs(BM.SECTIONS) do EnsureSectionFrame(sec) end
    for _, vName in ipairs(ALL_VIEWER_NAMES) do HookViewer(vName) end
    HookMixins()
    BM.UpdateSectionLockState()
end

function BM.RefreshSectionScales()
    local s = BM.db.scale or 1
    for _, sec in ipairs(BM.SECTIONS) do
        local f = sectionFrames[sec]
        if f then f:SetScale(s) end
    end
end

function BM.ResetAllPositions()
    local defaults = BM.DefaultDB
    for _, sec in ipairs(BM.SECTIONS) do
        local key = GetPosKey(sec)
        local def = defaults[key] or { x = 0, y = -200 }
        BM.db[key] = { x = def.x, y = def.y }
        local f = sectionFrames[sec]
        if f then
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", def.x, def.y)
        end
    end
end
