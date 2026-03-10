local addonName, BM = ...

--[[
    Layout (top to bottom, zero gap, no labels):
      [Essential]  core cooldowns, large icons
      [Buff]       active buffs/procs with glow highlight
      [Combo pips] secondary resource
      [Resource]   primary bar
      [Utility]    utility cooldowns, small icons
]]

local VIEWERS = BM.VIEWERS
local ALL_HOOKED = { VIEWERS.ESSENTIAL, VIEWERS.BUFF, VIEWERS.UTILITY }

local hookedViewers = {}
local hookedMixins = {}
local mirrorIcons = {}
local prevActiveBuffs = {}

local essentialContainer, buffContainer, utilityContainer

local ESSENTIAL_SIZE = 30
local BUFF_SIZE = 26
local UTILITY_SIZE = 22
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

    -- Glow overlay for proc highlights
    f.glow = f:CreateTexture(nil, "OVERLAY", nil, 2)
    f.glow:SetPoint("TOPLEFT", -4, 4)
    f.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    f.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    f.glow:SetTexCoord(0, 0.5, 0, 0.5)
    f.glow:SetVertexColor(1, 0.85, 0, 0.9)
    f.glow:Hide()

    -- Pulsing animation group for the glow
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

local function EnsureContainers()
    if essentialContainer and buffContainer and utilityContainer then return end
    if not BM.MainFrame then return end
    local db = BM.db

    if not essentialContainer then
        essentialContainer = CreateFrame("Frame", nil, BM.MainFrame)
        essentialContainer:SetSize(db.barWidth, ESSENTIAL_SIZE)
        essentialContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    end
    if not buffContainer then
        buffContainer = CreateFrame("Frame", nil, BM.MainFrame)
        buffContainer:SetSize(db.barWidth, BUFF_SIZE)
        buffContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    end
    if not utilityContainer then
        utilityContainer = CreateFrame("Frame", nil, BM.MainFrame)
        utilityContainer:SetSize(db.barWidth, UTILITY_SIZE)
        utilityContainer:SetFrameLevel(BM.MainFrame:GetFrameLevel() + 1)
    end
end

local function ContainerForViewer(viewerName)
    if viewerName == VIEWERS.ESSENTIAL then return essentialContainer
    elseif viewerName == VIEWERS.BUFF then return buffContainer
    elseif viewerName == VIEWERS.UTILITY then return utilityContainer
    end
end

local function SizeForViewer(viewerName)
    if viewerName == VIEWERS.ESSENTIAL then return ESSENTIAL_SIZE
    elseif viewerName == VIEWERS.BUFF then return BUFF_SIZE
    elseif viewerName == VIEWERS.UTILITY then return UTILITY_SIZE
    end
    return 24
end

local function HasVisibleIcons(viewerName)
    local icons = mirrorIcons[viewerName]
    if not icons then return false end
    for _, ic in ipairs(icons) do
        if ic:IsShown() then return true end
    end
    return false
end

function BM.LayoutAll()
    if not BM.MainFrame then return end
    EnsureContainers()
    local db = BM.db
    local w = db.barWidth
    local y = 0

    -- Bottom: Utility
    if HasVisibleIcons(VIEWERS.UTILITY) then
        utilityContainer:ClearAllPoints()
        utilityContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        utilityContainer:SetSize(w, UTILITY_SIZE)
        utilityContainer:Show()
        y = y + UTILITY_SIZE
    else
        utilityContainer:Hide()
    end

    -- Resource bar
    if BM.primaryBar then
        BM.primaryBar:ClearAllPoints()
        BM.primaryBar:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        BM.primaryBar:SetSize(w, db.barHeight)
        y = y + db.barHeight
    end

    -- Combo pips
    if BM.secondaryContainer then
        BM.secondaryContainer:ClearAllPoints()
        BM.secondaryContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        BM.secondaryContainer:SetSize(w, 10)
        y = y + 10
    end

    -- Buffs/procs
    if HasVisibleIcons(VIEWERS.BUFF) then
        buffContainer:ClearAllPoints()
        buffContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        buffContainer:SetSize(w, BUFF_SIZE)
        buffContainer:Show()
        y = y + BUFF_SIZE
    else
        buffContainer:Hide()
    end

    -- Top: Essential
    if HasVisibleIcons(VIEWERS.ESSENTIAL) then
        essentialContainer:ClearAllPoints()
        essentialContainer:SetPoint("BOTTOMLEFT", BM.MainFrame, "BOTTOMLEFT", 0, y)
        essentialContainer:SetSize(w, ESSENTIAL_SIZE)
        essentialContainer:Show()
        y = y + ESSENTIAL_SIZE
    else
        essentialContainer:Hide()
    end

    if not db.locked then y = y + 14 end
    BM.MainFrame:SetSize(w, math.max(y, 20))
end

local function RefreshViewerMirror(viewerName)
    local viewer = _G[viewerName]
    if not viewer or not viewer.itemFramePool then return end

    EnsureContainers()
    local container = ContainerForViewer(viewerName)
    if not container then return end

    local size = SizeForViewer(viewerName)
    local isBuff = (viewerName == VIEWERS.BUFF)

    if not mirrorIcons[viewerName] then mirrorIcons[viewerName] = {} end
    local icons = mirrorIcons[viewerName]

    for _, ic in ipairs(icons) do
        ic:Hide()
        if ic.glow then ic.glow:Hide() end
        if ic.glowPulse then ic.glowPulse:Stop() end
    end

    local idx = 0
    local spacing = (viewerName == VIEWERS.UTILITY) and 1 or 2
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
                        if not ic.glowPulse:IsPlaying() then
                            ic.glowPulse:Play()
                        end
                        ic.icon:SetDesaturated(false)

                        -- New proc detection: play sound on first appearance
                        if not prevActiveBuffs[spellID] then
                            BM.PlayAlertSound("proc")
                        end
                        currentActiveBuffs[spellID] = true
                    else
                        ic.glow:Hide()
                        ic.glowPulse:Stop()
                        ic.icon:SetDesaturated(true)
                    end

                    -- Mirror remaining duration via cooldown spinner
                    if frame.Cooldown then
                        local cdStart, cdDuration = frame.Cooldown:GetCooldownTimes()
                        if cdStart and cdDuration then
                            cdStart = cdStart / 1000
                            cdDuration = cdDuration / 1000
                            if cdDuration > 0 then
                                ic.cd:SetCooldown(cdStart, cdDuration)
                            else
                                ic.cd:Clear()
                            end
                        end
                    end
                else
                    -- Essential / Utility: show cooldown state
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
                end

                ic:Show()
            end
        end
    end

    if isBuff then
        prevActiveBuffs = currentActiveBuffs
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
        if _G[vName] then
            RefreshViewerMirror(vName)
        end
    end
end)

function BM.InitViewerHooks()
    for _, vName in ipairs(ALL_HOOKED) do
        HookViewer(vName)
    end
    HookMixins()
    BM.LayoutAll()
end
