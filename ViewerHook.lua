local addonName, BM = ...

--[[
    Mirrors Blizzard CooldownViewer icons into badomeow layout.
    All frames are plain Frame (never Button) to avoid combat taint.
    No sounds. No Masque. Pure display mirroring.
]]

local VIEWERS = BM.VIEWERS

-- Per-section data
local sectionIcons = {}
local containers  = {}

local SECTION_SIZES = {
    buff      = 26,
    essential = 30,
    utility   = 22,
    secondary = 10,
}

local ICON_PAD = 1
local iconCounter = 0

-- Which blizzard viewers map to which section
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
    for _, v in ipairs(list) do ALL_VIEWER_NAMES[#ALL_VIEWER_NAMES+1] = v end
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function GetSpellIDFromFrame(frame)
    if not frame then return nil end
    local id
    -- method 1: GetSpellID()
    if frame.GetSpellID then
        local ok, r = pcall(frame.GetSpellID, frame)
        if ok and r then id = r end
    end
    -- method 2: .cooldownInfo table
    if not id and frame.cooldownInfo then
        id = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
    end
    -- method 3: GetCooldownInfo()
    if not id and frame.GetCooldownInfo then
        local ok, info = pcall(frame.GetCooldownInfo, frame)
        if ok and info then id = info.overrideSpellID or info.spellID end
    end
    -- safety: reject secret values
    if id then
        local ok, _ = pcall(tostring, id)
        if not ok then return nil end
    end
    return id
end

local function IsFrameActive(frame)
    if not frame then return false end
    local ok, r = pcall(function()
        if frame.IsActive then return frame.IsActive(frame) end
        if frame.activeState ~= nil then return frame.activeState end
        return frame:IsShown()
    end)
    if ok then return r end
    return false
end

---------------------------------------------------------------------------
-- Icon creation (plain Frame, pre-allocated)
---------------------------------------------------------------------------
local function CreateIcon(parent, size)
    iconCounter = iconCounter + 1
    local name = "badomeowIC" .. iconCounter
    local f = CreateFrame("Frame", name, parent)
    f:SetSize(size, size)
    f:SetFrameLevel(parent:GetFrameLevel() + 2)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", ICON_PAD, -ICON_PAD)
    f.icon:SetPoint("BOTTOMRIGHT", -ICON_PAD, ICON_PAD)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.cd = CreateFrame("Cooldown", name.."CD", f, "CooldownFrameTemplate")
    f.cd:SetAllPoints(f.icon)
    f.cd:SetDrawEdge(true)
    f.cd:SetHideCountdownNumbers(false)
    if f.cd.SetMuteAudio then f.cd:SetMuteAudio(true) end

    f.glow = f:CreateTexture(nil, "OVERLAY", nil, 2)
    f.glow:SetPoint("TOPLEFT", -3, 3)
    f.glow:SetPoint("BOTTOMRIGHT", 3, -3)
    f.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    f.glow:SetTexCoord(0, 0.5, 0, 0.5)
    f.glow:SetVertexColor(1, 0.85, 0, 0.9)
    f.glow:Hide()

    f.glowAnim = f.glow:CreateAnimationGroup()
    f.glowAnim:SetLooping("BOUNCE")
    local a = f.glowAnim:CreateAnimation("Alpha")
    a:SetFromAlpha(0.4); a:SetToAlpha(1); a:SetDuration(0.6); a:SetSmoothing("IN_OUT")

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

local function GetIcon(section, idx)
    if not sectionIcons[section] then sectionIcons[section] = {} end
    local icons = sectionIcons[section]
    if icons[idx] then return icons[idx] end
    -- Only create outside combat
    if InCombatLockdown() then return nil end
    local container = EnsureContainer(section)
    if not container then return nil end
    local size = SECTION_SIZES[section] or 24
    icons[idx] = CreateIcon(container, size)
    return icons[idx]
end

---------------------------------------------------------------------------
-- Section enable / content checks
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
    local icons = sectionIcons[section]
    if not icons then return false end
    for _, ic in ipairs(icons) do
        if ic:IsShown() then return true end
    end
    return false
end

local function SectionHeight(section)
    if section == "primary" then return BM.db.barHeight end
    return SECTION_SIZES[section] or 20
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
-- Section refresh: collect blizzard frames → mirror into our icons
---------------------------------------------------------------------------
local function RefreshSection(section)
    local container = EnsureContainer(section)
    if not container then return end

    local size = SECTION_SIZES[section] or 24
    local isBuff = (section == "buff")
    if not sectionIcons[section] then sectionIcons[section] = {} end
    local icons = sectionIcons[section]

    -- hide all existing icons
    for _, ic in ipairs(icons) do
        ic:Hide()
        ic.glow:Hide()
        ic.glowAnim:Stop()
    end

    if not IsSectionEnabled(section) then
        container:Hide()
        return
    end

    -- collect blizzard source frames
    local sources = {}
    local viewerList = SECTION_TO_VIEWERS[section]
    if viewerList then
        for _, vName in ipairs(viewerList) do
            local viewer = _G[vName]
            if viewer and viewer.itemFramePool then
                for frame in viewer.itemFramePool:EnumerateActive() do
                    if frame and frame:IsShown() then
                        local sid = GetSpellIDFromFrame(frame)
                        if sid then
                            sources[#sources+1] = { f = frame, id = sid }
                        end
                    end
                end
            end
        end
    end

    -- mirror each source into our icon pool
    local spacing = (section == "utility") and 1 or 2
    for idx, src in ipairs(sources) do
        local ic = GetIcon(section, idx)
        if not ic then break end  -- combat, can't create more
        ic:SetSize(size, size)

        local okTex, tex = pcall(C_Spell.GetSpellTexture, src.id)
        if okTex and tex then ic.icon:SetTexture(tex) end

        ic:ClearAllPoints()
        ic:SetPoint("LEFT", container, "LEFT", (idx-1) * (size + spacing), 0)

        -- All cooldown numbers are secret in 12.0 — cannot read, compare,
        -- or do arithmetic on them. We detect on-cooldown purely by checking
        -- if the source Cooldown frame is visually spinning (shown + alpha>0).
        -- We show a simple desaturated overlay instead of a sweep animation.
        local srcCD = src.f.Cooldown or src.f.cooldown
        local onCD = false
        if srcCD then
            local ok, shown = pcall(srcCD.IsShown, srcCD)
            if ok and shown then
                local ok2, alpha = pcall(srcCD.GetAlpha, srcCD)
                onCD = ok2 and alpha > 0.01
            end
        end
        ic.cd:Hide()
        if not isBuff then ic.icon:SetDesaturated(onCD) end

        -- buff glow
        if isBuff then
            local active = IsFrameActive(src.f)
            if active then
                ic.glow:Show()
                if not ic.glowAnim:IsPlaying() then ic.glowAnim:Play() end
                ic.icon:SetDesaturated(false)
            else
                ic.glow:Hide()
                ic.glowAnim:Stop()
                ic.icon:SetDesaturated(true)
            end
        end

        ic:Show()
    end

    if #sources > 0 then container:Show() else container:Hide() end
end

---------------------------------------------------------------------------
-- Pre-allocate icons outside combat
---------------------------------------------------------------------------
local function Preallocate()
    local counts = { essential = 12, buff = 8, utility = 8 }
    for sec, n in pairs(counts) do
        local container = EnsureContainer(sec)
        if container then
            for i = 1, n do GetIcon(sec, i) end
        end
    end
end

---------------------------------------------------------------------------
-- Hooking
---------------------------------------------------------------------------
local hookedViewers = {}
local hookedMixins = false

local function HookViewer(vName)
    local viewer = _G[vName]
    if not viewer or hookedViewers[viewer] then return end
    hookedViewers[viewer] = true

    local sec = VIEWER_TO_SECTION[vName]
    local function onChange() if sec then RefreshSection(sec) end end

    if viewer.RefreshData    then hooksecurefunc(viewer, "RefreshData", onChange) end
    if viewer.UpdateLayout   then hooksecurefunc(viewer, "UpdateLayout", onChange)
    elseif viewer.Layout     then hooksecurefunc(viewer, "Layout", onChange) end
    if viewer.RefreshLayout  then hooksecurefunc(viewer, "RefreshLayout", onChange) end
    if viewer.itemFramePool then
        hooksecurefunc(viewer.itemFramePool, "Acquire", onChange)
        hooksecurefunc(viewer.itemFramePool, "Release", onChange)
    end
    viewer:HookScript("OnShow", onChange)
    onChange()
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
            local sec = VIEWER_TO_SECTION[vName]
            local cb = function() if sec then RefreshSection(sec) end end
            if m.OnCooldownIDSet      then hooksecurefunc(m, "OnCooldownIDSet", cb) end
            if m.OnActiveStateChanged then hooksecurefunc(m, "OnActiveStateChanged", cb) end
        end
    end
end

---------------------------------------------------------------------------
-- Periodic fallback: refresh all sections + layout, once per cycle
---------------------------------------------------------------------------
local timer = 0
local tickFrame = CreateFrame("Frame")
tickFrame:SetScript("OnUpdate", function(_, dt)
    timer = timer + dt
    if timer < 0.15 then return end
    timer = 0
    if not BM.MainFrame or not BM.MainFrame:IsShown() then return end
    for _, sec in ipairs(ALL_SECTIONS) do
        RefreshSection(sec)
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
    Preallocate()
    for _, vName in ipairs(ALL_VIEWER_NAMES) do HookViewer(vName) end
    HookMixins()
    BM.LayoutAll()
end
