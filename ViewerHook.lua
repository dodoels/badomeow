local addonName, BM = ...

--[[
    ViewerHook: mirrors Blizzard 12.0 CooldownViewer icons.
    Buff section merges both BuffIconCooldownViewer + BuffBarCooldownViewer.
    Supports Masque, per-section toggle, reorderable layout.
]]

local VIEWERS = BM.VIEWERS

local hookedViewers = {}
local hookedMixins = {}
local prevActiveBuffs = {}

local containers = {}

-- Section definitions
local SECTION_SIZES = {
    buff      = 26,
    essential = 30,
    utility   = 22,
    secondary = 10,
    primary   = nil,
}

local ICON_PAD = 1

-- Which Blizzard viewers feed into which section
local BUFF_VIEWERS = { VIEWERS.BUFF, VIEWERS.BUFF_BAR }
local SECTION_VIEWERS = {
    buff      = BUFF_VIEWERS,
    essential = { VIEWERS.ESSENTIAL },
    utility   = { VIEWERS.UTILITY },
}

-- Flat list of all viewers we hook
local ALL_VIEWER_NAMES = { VIEWERS.ESSENTIAL, VIEWERS.UTILITY, VIEWERS.BUFF, VIEWERS.BUFF_BAR }

-- Reverse: viewer -> section
local VIEWER_TO_SECTION = {}
for section, viewers in pairs(SECTION_VIEWERS) do
    for _, vn in ipairs(viewers) do
        VIEWER_TO_SECTION[vn] = section
    end
end

-- Per-section icon pool (not per-viewer)
local sectionIcons = {}

-- Masque
local MSQ = LibStub and LibStub("Masque", true) or nil
local masqueGroups = {}
local iconCounter = 0

local function GetMasqueGroup(section)
    if not MSQ then return nil end
    if masqueGroups[section] then return masqueGroups[section] end
    local groupNames = {
        essential = "核心技能 Essential",
        buff      = "增益/触发 Buff",
        utility   = "工具技能 Utility",
    }
    local name = groupNames[section]
    if not name then return nil end
    masqueGroups[section] = MSQ:Group("badomeow", name)
    return masqueGroups[section]
end

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
    if not spellID then
        local ok2, info2 = pcall(function()
            return frame.GetCooldownInfo and frame:GetCooldownInfo()
        end)
        if ok2 and info2 then
            spellID = info2.overrideSpellID or info2.spellID
        end
    end
    if spellID and type(spellID) == "number" then
        local ok, isSafe = pcall(function() return not issecretvalue(spellID) end)
        if ok and not isSafe then return nil end
    end
    return spellID
end

local function IsFrameActive(frame)
    if not frame then return false end
    if frame.IsActive and type(frame.IsActive) == "function" then
        local ok, result = pcall(frame.IsActive, frame)
        if ok then return result end
    end
    if frame.activeState ~= nil then return frame.activeState end
    return frame:IsShown()
end

local function CreateMirrorIcon(parent, size, section)
    iconCounter = iconCounter + 1
    local btnName = "badomeowIcon" .. iconCounter

    local f = CreateFrame("Button", btnName, parent)
    f:SetSize(size, size)
    f:SetFrameLevel(parent:GetFrameLevel() + 2)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", ICON_PAD, -ICON_PAD)
    f.icon:SetPoint("BOTTOMRIGHT", -ICON_PAD, ICON_PAD)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.cooldown = CreateFrame("Cooldown", btnName .. "Cooldown", f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints(f.icon)
    f.cooldown:SetDrawEdge(true)
    f.cooldown:SetHideCountdownNumbers(false)
    f.cd = f.cooldown

    local normalTex = f:CreateTexture(nil, "BORDER")
    normalTex:SetAllPoints()
    normalTex:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    normalTex:SetTexCoord(0, 1, 0, 1)
    f:SetNormalTexture(normalTex)
    f.NormalTexture = normalTex

    f.glow = f:CreateTexture(nil, "OVERLAY", nil, 2)
    f.glow:SetPoint("TOPLEFT", -4, 4)
    f.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    f.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    f.glow:SetTexCoord(0, 0.5, 0, 0.5)
    f.glow:SetVertexColor(1, 0.85, 0, 0.9)
    f.glow:Hide()

    f.glowPulse = f.glow:CreateAnimationGroup()
    f.glowPulse:SetLooping("BOUNCE")
    local pulse = f.glowPulse:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.5)
    pulse:SetToAlpha(1.0)
    pulse:SetDuration(0.6)
    pulse:SetSmoothing("IN_OUT")

    local group = GetMasqueGroup(section)
    if group then
        group:AddButton(f, {
            Icon = f.icon, Cooldown = f.cooldown, Normal = f.NormalTexture,
            Border = false, Highlight = false, Pushed = false,
            Disabled = false, Checked = false, AutoCastable = false,
            Flash = false, Backdrop = false, Name = false,
            Count = false, Duration = false, HotKey = false, AutoCast = false,
        }, "Action")
        f._masqueGroup = group
    end

    f:Hide()
    return f
end

local function EnsureContainer(section)
    if containers[section] then return containers[section] end
    if not BM.MainFrame then return nil end
    local c = CreateFrame("Frame", nil, BM.MainFrame)
    c:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    containers[section] = c
    return c
end

local function IsSectionEnabled(section)
    local db = BM.db
    if section == "buff" then return db.showBuff ~= false end
    if section == "essential" then return db.showEssential ~= false end
    if section == "utility" then return db.showUtility ~= false end
    if section == "primary" then return db.showPrimaryBar ~= false end
    if section == "secondary" then return db.showSecondaryBar ~= false end
    return true
end

local function SectionHasVisibleIcons(section)
    local icons = sectionIcons[section]
    if not icons then return false end
    for _, ic in ipairs(icons) do
        if ic:IsShown() then return true end
    end
    return false
end

local function SectionHasContent(section)
    if not IsSectionEnabled(section) then return false end
    if section == "primary" then return BM.primaryBar ~= nil end
    if section == "secondary" then return BM.secondaryContainer ~= nil end
    return SectionHasVisibleIcons(section)
end

local function SectionHeight(section)
    if section == "primary" then return BM.db.barHeight end
    return SECTION_SIZES[section] or 20
end

function BM.LayoutAll()
    if not BM.MainFrame then return end
    local db = BM.db
    local w = db.barWidth
    local order = db.layoutOrder or BM.SECTIONS
    local y = 0

    for i = #order, 1, -1 do
        local section = order[i]
        if SectionHasContent(section) then
            local h = SectionHeight(section)
            if section == "primary" and BM.primaryBar then
                BM.primaryBar:ClearAllPoints()
                BM.primaryBar:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                BM.primaryBar:SetSize(w, h)
                BM.primaryBar:Show()
            elseif section == "secondary" and BM.secondaryContainer then
                BM.secondaryContainer:ClearAllPoints()
                BM.secondaryContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                BM.secondaryContainer:SetSize(w, h)
                BM.secondaryContainer:Show()
            else
                local c = containers[section]
                if c then
                    c:ClearAllPoints()
                    c:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                    c:SetSize(w, h)
                    c:Show()
                end
            end
            y = y + h
        else
            local c = containers[section]
            if c then c:Hide() end
            if section == "primary" and BM.primaryBar then BM.primaryBar:Hide() end
            if section == "secondary" and BM.secondaryContainer then BM.secondaryContainer:Hide() end
        end
    end

    if not db.locked then y = y + 14 end
    BM.MainFrame:SetSize(w, math.max(y, 20))
end

-- Collect all active Blizzard frames from the viewer(s) that feed a section,
-- then create/update mirror icons sequentially in one container.
local function RefreshSection(section)
    local container = EnsureContainer(section)
    if not container then return end

    local size = SECTION_SIZES[section] or 24
    local isBuff = (section == "buff")

    if not sectionIcons[section] then sectionIcons[section] = {} end
    local icons = sectionIcons[section]

    -- Reset all icons
    for _, ic in ipairs(icons) do
        ic:Hide()
        if ic.glow then ic.glow:Hide() end
        if ic.glowPulse then ic.glowPulse:Stop() end
    end

    if not IsSectionEnabled(section) then
        container:Hide()
        BM.LayoutAll()
        return
    end

    -- Gather all source frames from every viewer feeding this section
    local sourceFrames = {}
    local viewers = SECTION_VIEWERS[section]
    if viewers then
        for _, vName in ipairs(viewers) do
            local viewer = _G[vName]
            if viewer and viewer.itemFramePool then
                for frame in viewer.itemFramePool:EnumerateActive() do
                    if frame and frame:IsShown() then
                        local spellID = GetSpellIDFromFrame(frame)
                        if spellID then
                            sourceFrames[#sourceFrames + 1] = { frame = frame, spellID = spellID }
                        end
                    end
                end
            end
        end
    end

    local spacing = (section == "utility") and 1 or 2
    local currentActiveBuffs = {}

    for idx, entry in ipairs(sourceFrames) do
        local frame = entry.frame
        local spellID = entry.spellID

        local ic = icons[idx]
        if not ic then
            ic = CreateMirrorIcon(container, size, section)
            icons[idx] = ic
        end
        ic:SetSize(size, size)

        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then ic.icon:SetTexture(tex) end

        ic:ClearAllPoints()
        ic:SetPoint("LEFT", container, "LEFT", (idx - 1) * (size + spacing), 0)

        if isBuff then
            local active = IsFrameActive(frame)
            if active then
                ic.glow:Show()
                if not ic.glowPulse:IsPlaying() then ic.glowPulse:Play() end
                ic.icon:SetDesaturated(false)
                if not prevActiveBuffs[spellID] then
                    BM.PlayAlertSound("proc")
                end
                currentActiveBuffs[spellID] = true
            else
                ic.glow:Hide()
                ic.glowPulse:Stop()
                ic.icon:SetDesaturated(true)
            end
            if frame.Cooldown then
                local cdStart, cdDuration = frame.Cooldown:GetCooldownTimes()
                if cdStart and cdDuration then
                    cdStart = cdStart / 1000; cdDuration = cdDuration / 1000
                    if cdDuration > 0 then ic.cd:SetCooldown(cdStart, cdDuration)
                    else ic.cd:Clear() end
                end
            end
        else
            if frame.Cooldown then
                local cdStart, cdDuration = frame.Cooldown:GetCooldownTimes()
                if cdStart and cdDuration then
                    cdStart = cdStart / 1000; cdDuration = cdDuration / 1000
                    if cdDuration > 1.5 then
                        ic.cd:SetCooldown(cdStart, cdDuration)
                        ic.icon:SetDesaturated(true)
                    else
                        ic.cd:Clear()
                        ic.icon:SetDesaturated(false)
                    end
                end
            end
        end

        ic:Show()
    end

    if isBuff then prevActiveBuffs = currentActiveBuffs end
    if #sourceFrames > 0 then
        container:Show()
    else
        container:Hide()
    end
    BM.LayoutAll()
end

-- When any viewer fires, refresh the entire section it belongs to
local function OnViewerChanged(viewerName)
    local section = VIEWER_TO_SECTION[viewerName]
    if section then RefreshSection(section) end
end

local function HookViewer(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end
    if hookedViewers[viewer] then return end
    hookedViewers[viewer] = true

    local function OnChange() OnViewerChanged(viewerName) end

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
    OnChange()
end

local function HookMixins()
    if hookedMixins.done then return end

    local map = {
        CooldownViewerEssentialItemMixin = VIEWERS.ESSENTIAL,
        CooldownViewerUtilityItemMixin   = VIEWERS.UTILITY,
        CooldownViewerBuffIconItemMixin  = VIEWERS.BUFF,
        CooldownViewerBuffBarItemMixin   = VIEWERS.BUFF_BAR,
    }

    for mixinName, vName in pairs(map) do
        local mixin = _G[mixinName]
        if mixin then
            if mixin.OnCooldownIDSet then
                hooksecurefunc(mixin, "OnCooldownIDSet", function()
                    OnViewerChanged(vName)
                end)
            end
            if mixin.OnActiveStateChanged then
                hooksecurefunc(mixin, "OnActiveStateChanged", function()
                    OnViewerChanged(vName)
                end)
            end
        end
    end
    hookedMixins.done = true
end

-- Periodic fallback refresh
local refreshTimer = 0
local refreshFrame = CreateFrame("Frame")
refreshFrame:SetScript("OnUpdate", function(self, elapsed)
    refreshTimer = refreshTimer + elapsed
    if refreshTimer < 0.15 then return end
    refreshTimer = 0
    if not BM.MainFrame or not BM.MainFrame:IsShown() then return end
    for _, vName in ipairs(ALL_VIEWER_NAMES) do
        if _G[vName] then OnViewerChanged(vName) end
    end
end)

function BM.SwapSectionOrder(sectionKey, direction)
    local order = BM.db.layoutOrder
    for i, key in ipairs(order) do
        if key == sectionKey then
            local target = i + direction
            if target >= 1 and target <= #order then
                order[i], order[target] = order[target], order[i]
                BM.LayoutAll()
            end
            return
        end
    end
end

function BM.InitViewerHooks()
    for _, vName in ipairs(ALL_VIEWER_NAMES) do HookViewer(vName) end
    HookMixins()
    BM.LayoutAll()
end
