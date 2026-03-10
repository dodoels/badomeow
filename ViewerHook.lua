local addonName, BM = ...

--[[
    ViewerHook: Hooks Blizzard's 12.0 CooldownViewer system.

    Default layout (top to bottom, configurable order):
      [Buff]       active buffs/procs with glow highlight
      [Combo pips] secondary resource
      [Resource]   primary bar
      [Essential]  core cooldowns
      [Utility]    utility cooldowns, small icons

    Each section can be toggled on/off and reordered via layoutOrder.
]]

local VIEWERS = BM.VIEWERS
local ALL_HOOKED = { VIEWERS.ESSENTIAL, VIEWERS.BUFF, VIEWERS.UTILITY }

local hookedViewers = {}
local hookedMixins = {}
local mirrorIcons = {}
local prevActiveBuffs = {}

local containers = {}

local SECTION_SIZES = {
    buff      = 26,
    essential = 30,
    utility   = 22,
    secondary = 10,
    primary   = nil, -- uses db.barHeight
}

local ICON_PAD = 1

local SECTION_VIEWER_MAP = {
    buff      = VIEWERS.BUFF,
    essential = VIEWERS.ESSENTIAL,
    utility   = VIEWERS.UTILITY,
}

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

local function IsFrameActive(frame)
    if not frame then return false end
    if frame.IsActive and type(frame.IsActive) == "function" then
        local ok, result = pcall(frame.IsActive, frame)
        if ok then return result end
    end
    if frame.activeState ~= nil then return frame.activeState end
    return frame:IsShown()
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

local function ViewerForSection(section)
    local vName = SECTION_VIEWER_MAP[section]
    return vName and _G[vName] or nil
end

local function HasVisibleIcons(viewerName)
    local icons = mirrorIcons[viewerName]
    if not icons then return false end
    for _, ic in ipairs(icons) do
        if ic:IsShown() then return true end
    end
    return false
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

local function SectionHasContent(section)
    if not IsSectionEnabled(section) then return false end
    if section == "primary" then return BM.primaryBar ~= nil end
    if section == "secondary" then return BM.secondaryContainer ~= nil end
    local vName = SECTION_VIEWER_MAP[section]
    if vName then return HasVisibleIcons(vName) end
    return false
end

local function SectionHeight(section)
    if section == "primary" then return BM.db.barHeight end
    return SECTION_SIZES[section] or 20
end

-- Master layout: stacks sections bottom-to-top in reverse layoutOrder
function BM.LayoutAll()
    if not BM.MainFrame then return end
    local db = BM.db
    local w = db.barWidth
    local order = db.layoutOrder or BM.SECTIONS
    local y = 0

    -- Stack from bottom: iterate order in reverse (last = bottom)
    for i = #order, 1, -1 do
        local section = order[i]
        if SectionHasContent(section) then
            local h = SectionHeight(section)

            if section == "primary" and BM.primaryBar then
                BM.primaryBar:ClearAllPoints()
                BM.primaryBar:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                BM.primaryBar:SetSize(w, h)
            elseif section == "secondary" and BM.secondaryContainer then
                BM.secondaryContainer:ClearAllPoints()
                BM.secondaryContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
                BM.secondaryContainer:SetSize(w, h)
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

local function RefreshViewerMirror(viewerName)
    local viewer = _G[viewerName]
    if not viewer or not viewer.itemFramePool then return end

    -- Find which section this viewer maps to
    local section
    for sec, vn in pairs(SECTION_VIEWER_MAP) do
        if vn == viewerName then section = sec; break end
    end
    if not section then return end

    local container = EnsureContainer(section)
    if not container then return end

    local size = SECTION_SIZES[section] or 24
    local isBuff = (viewerName == VIEWERS.BUFF)

    if not mirrorIcons[viewerName] then mirrorIcons[viewerName] = {} end
    local icons = mirrorIcons[viewerName]

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

    local idx = 0
    local spacing = (section == "utility") and 1 or 2
    local now = GetTime()
    local currentActiveBuffs = {}

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
        end
    end

    if isBuff then prevActiveBuffs = currentActiveBuffs end
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
        CooldownViewerBuffIconItemMixin  = VIEWERS.BUFF,
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
    for _, vName in ipairs(ALL_HOOKED) do
        if _G[vName] then RefreshViewerMirror(vName) end
    end
end)

-- Swap two adjacent sections in layoutOrder
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
    for _, vName in ipairs(ALL_HOOKED) do HookViewer(vName) end
    HookMixins()
    BM.LayoutAll()
end
