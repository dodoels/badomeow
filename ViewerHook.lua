local addonName, BM = ...

--[[
    ViewerHook: Hooks Blizzard's 12.0 CooldownViewer system.

    Blizzard creates 4 global viewer frames:
      EssentialCooldownViewer  - core rotational cooldowns
      UtilityCooldownViewer    - utility cooldowns
      BuffIconCooldownViewer   - active buff icons
      BuffBarCooldownViewer    - active buffs as progress bars

    We hook their item frame acquisition and layout methods to read
    spell data directly from the game engine, then mirror the info
    into our own styled display below the resource bar.
]]

local VIEWERS = BM.VIEWERS

local hookedViewers = {}
local hookedMixins = {}
local trackedFrames = {}
local mirrorIcons = {}

-- One container per viewer type
local viewerContainers = {}

local VIEWER_LABELS = {
    [VIEWERS.ESSENTIAL] = "核心技能",
    [VIEWERS.UTILITY]   = "工具技能",
    [VIEWERS.BUFF]      = "增益",
    [VIEWERS.BUFF_BAR]  = "增益条",
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
    if spellID and BM.IsSafeNumber and not BM.IsSafeNumber(spellID) then
        return nil
    end
    if spellID and type(spellID) == "number" and issecurevariable and issecretvalue then
        local ok, isSafe = pcall(function() return not issecretvalue(spellID) end)
        if ok and not isSafe then return nil end
    end
    return spellID
end

function BM.IsSafeNumber(value)
    if value == nil or type(value) ~= "number" then return false end
    local ok, result = pcall(function() return not issecretvalue(value) end)
    if ok then return result end
    return true
end

local function CreateMirrorIcon(parent, index)
    local size = 32
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    f:SetFrameLevel(parent:GetFrameLevel() + 2)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 2, -2)
    f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.border = f:CreateTexture(nil, "OVERLAY")
    f.border:SetAllPoints()
    f.border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    f.border:SetVertexColor(0.4, 0.4, 0.4, 0.8)

    f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints(f.icon)
    f.cd:SetDrawEdge(true)
    f.cd:SetHideCountdownNumbers(false)

    f.duration = f:CreateFontString(nil, "OVERLAY")
    f.duration:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    f.duration:SetPoint("TOP", f, "BOTTOM", 0, -1)
    f.duration:SetTextColor(1, 0.9, 0.5, 1)

    f:Hide()
    return f
end

local function EnsureContainer(viewerName)
    if viewerContainers[viewerName] then return viewerContainers[viewerName] end
    if not BM.MainFrame then return nil end

    local container = CreateFrame("Frame", nil, BM.MainFrame)
    container:SetSize(BM.db.barWidth, 36)
    container:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)

    container.label = container:CreateFontString(nil, "OVERLAY")
    container.label:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    container.label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 2)
    container.label:SetTextColor(0.6, 0.8, 0.6, 0.6)
    container.label:SetText(VIEWER_LABELS[viewerName] or viewerName)

    viewerContainers[viewerName] = container
    return container
end

local function LayoutContainers()
    if not BM.MainFrame then return end
    local db = BM.db
    local y = 20
    local order = { VIEWERS.ESSENTIAL, VIEWERS.UTILITY, VIEWERS.BUFF }

    for _, vName in ipairs(order) do
        local container = viewerContainers[vName]
        if container then
            container:ClearAllPoints()
            container:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 10, y)
            container:SetSize(db.barWidth, 36)

            local iconCount = 0
            local icons = mirrorIcons[vName]
            if icons then
                for _, ic in ipairs(icons) do
                    if ic:IsShown() then iconCount = iconCount + 1 end
                end
            end

            if iconCount > 0 then
                y = y + 50
            else
                container:Hide()
            end
        end
    end

    BM.MainFrame:SetHeight(y + 15)
end

local function FormatTime(sec)
    if sec > 60 then return string.format("%dm", sec / 60)
    elseif sec > 3 then return string.format("%d", sec)
    else return string.format("%.1f", sec) end
end

local function RefreshViewerMirror(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end
    if not viewer.itemFramePool then return end

    local container = EnsureContainer(viewerName)
    if not container then return end

    if not mirrorIcons[viewerName] then mirrorIcons[viewerName] = {} end
    local icons = mirrorIcons[viewerName]

    -- Hide all first
    for _, ic in ipairs(icons) do ic:Hide() end

    local idx = 0
    local spacing = 4
    local size = 32
    local now = GetTime()

    for frame in viewer.itemFramePool:EnumerateActive() do
        if frame:IsShown() then
            local spellID = GetSpellIDFromFrame(frame)
            if spellID then
                idx = idx + 1
                local ic = icons[idx]
                if not ic then
                    ic = CreateMirrorIcon(container, idx)
                    icons[idx] = ic
                end

                local tex = C_Spell.GetSpellTexture(spellID)
                if tex then ic.icon:SetTexture(tex) end

                ic:ClearAllPoints()
                ic:SetPoint("LEFT", container, "LEFT", (idx - 1) * (size + spacing), 0)

                -- Mirror cooldown state from original frame
                if frame.Cooldown then
                    local cdStart, cdDuration = frame.Cooldown:GetCooldownTimes()
                    if cdStart and cdDuration then
                        cdStart = cdStart / 1000
                        cdDuration = cdDuration / 1000
                        if cdDuration > 1.5 then
                            ic.cd:SetCooldown(cdStart, cdDuration)
                            local rem = (cdStart + cdDuration) - now
                            ic.duration:SetText(rem > 0 and FormatTime(rem) or "")
                            ic.icon:SetDesaturated(true)
                        else
                            ic.cd:Clear()
                            ic.duration:SetText("")
                            ic.icon:SetDesaturated(false)
                        end
                    end
                end

                ic:Show()
            end
        end
    end

    container:Show()
    LayoutContainers()
end

local function HookViewer(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end
    if hookedViewers[viewer] then return end
    hookedViewers[viewer] = true

    -- Hook layout methods
    if viewer.RefreshData then
        hooksecurefunc(viewer, "RefreshData", function()
            RefreshViewerMirror(viewerName)
        end)
    end
    if viewer.UpdateLayout then
        hooksecurefunc(viewer, "UpdateLayout", function()
            RefreshViewerMirror(viewerName)
        end)
    elseif viewer.Layout then
        hooksecurefunc(viewer, "Layout", function()
            RefreshViewerMirror(viewerName)
        end)
    end
    if viewer.RefreshLayout then
        hooksecurefunc(viewer, "RefreshLayout", function()
            RefreshViewerMirror(viewerName)
        end)
    end

    -- Hook pool acquire/release
    if viewer.itemFramePool then
        hooksecurefunc(viewer.itemFramePool, "Acquire", function()
            RefreshViewerMirror(viewerName)
        end)
        hooksecurefunc(viewer.itemFramePool, "Release", function()
            RefreshViewerMirror(viewerName)
        end)
    end

    viewer:HookScript("OnShow", function()
        RefreshViewerMirror(viewerName)
    end)

    RefreshViewerMirror(viewerName)
end

-- Hook the mixin methods (fires when Blizzard assigns a spell to a frame)
local function HookMixins()
    if hookedMixins.done then return end

    local mixinNames = {
        "CooldownViewerEssentialItemMixin",
        "CooldownViewerUtilityItemMixin",
        "CooldownViewerBuffIconItemMixin",
        "CooldownViewerBuffBarItemMixin",
    }

    local viewerMap = {
        CooldownViewerEssentialItemMixin = VIEWERS.ESSENTIAL,
        CooldownViewerUtilityItemMixin   = VIEWERS.UTILITY,
        CooldownViewerBuffIconItemMixin  = VIEWERS.BUFF,
        CooldownViewerBuffBarItemMixin   = VIEWERS.BUFF_BAR,
    }

    for _, mixinName in ipairs(mixinNames) do
        local mixin = _G[mixinName]
        if mixin then
            if mixin.OnCooldownIDSet then
                hooksecurefunc(mixin, "OnCooldownIDSet", function()
                    local vName = viewerMap[mixinName]
                    if vName then RefreshViewerMirror(vName) end
                end)
            end
            if mixin.OnActiveStateChanged then
                hooksecurefunc(mixin, "OnActiveStateChanged", function()
                    local vName = viewerMap[mixinName]
                    if vName then RefreshViewerMirror(vName) end
                end)
            end
        end
    end

    hookedMixins.done = true
end

-- Periodic refresh for cooldown timers
local refreshTimer = 0
local refreshFrame = CreateFrame("Frame")
refreshFrame:SetScript("OnUpdate", function(self, elapsed)
    refreshTimer = refreshTimer + elapsed
    if refreshTimer < 0.1 then return end
    refreshTimer = 0
    if not BM.MainFrame or not BM.MainFrame:IsShown() then return end

    for _, vName in ipairs({ VIEWERS.ESSENTIAL, VIEWERS.UTILITY, VIEWERS.BUFF }) do
        if _G[vName] then
            RefreshViewerMirror(vName)
        end
    end
end)

function BM.InitViewerHooks()
    local viewerOrder = { VIEWERS.ESSENTIAL, VIEWERS.UTILITY, VIEWERS.BUFF }
    for _, vName in ipairs(viewerOrder) do
        HookViewer(vName)
    end
    HookMixins()
    LayoutContainers()
end
