local addonName, FFS = ...

--[[
    TextureOverlay: user-configurable image panels that sit behind
    all other components. Each overlay is independently positionable,
    resizable, and can display any texture from the Textures folder
    or a direct path.
]]

local overlayFrames = {}
FFS.overlayFrames = overlayFrames

local MAX_OVERLAYS = 10

local function GetOverlayDB(index)
    if not FFS.db.overlays then FFS.db.overlays = {} end
    if not FFS.db.overlays[index] then
        FFS.db.overlays[index] = {
            enabled = false,
            texturePath = "",
            width = 300,
            height = 50,
            alpha = 0.8,
            x = 0,
            y = -200,
            point = "CENTER",
            relPoint = "CENTER",
            layer = "BACKGROUND",
            flipH = false,
            flipV = false,
            r = 1, g = 1, b = 1,
        }
    end
    return FFS.db.overlays[index]
end

local function ApplyOverlay(index)
    local cfg = GetOverlayDB(index)
    local f = overlayFrames[index]
    if not f then return end

    if not cfg.enabled or cfg.texturePath == "" then
        f:Hide()
        return
    end

    f:SetSize(cfg.width, cfg.height)
    f:ClearAllPoints()
    f:SetPoint(cfg.point or "CENTER", UIParent, cfg.relPoint or "CENTER", cfg.x or 0, cfg.y or 0)
    f:SetAlpha(cfg.alpha or 0.8)

    local tex = f.tex
    tex:SetAllPoints()

    local path = cfg.texturePath
    if path ~= "" then
        tex:SetTexture(path)
    end

    tex:SetVertexColor(cfg.r or 1, cfg.g or 1, cfg.b or 1)

    local l, r, t, b = 0, 1, 0, 1
    if cfg.flipH then l, r = 1, 0 end
    if cfg.flipV then t, b = 1, 0 end
    tex:SetTexCoord(l, r, t, b)

    tex:SetDrawLayer(cfg.layer or "BACKGROUND", 0)

    f:Show()
end

local function CreateOverlayFrame(index)
    if overlayFrames[index] then return overlayFrames[index] end

    local f = CreateFrame("Frame", "ffsOverlay_" .. index, UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(0)
    f:SetClampedToScreen(true)

    local tex = f:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    f.tex = tex

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not FFS.db.locked and not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cfg = GetOverlayDB(index)
        local point, _, relPoint, x, y = self:GetPoint()
        cfg.point = point
        cfg.relPoint = relPoint
        cfg.x = x
        cfg.y = y
    end)

    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    f.label:SetPoint("TOP", f, "TOP", 0, 12)
    f.label:SetTextColor(0.6, 0.8, 1, 0.8)
    f.label:SetText("贴图 #" .. index)
    f.label:Hide()

    f.bg = f:CreateTexture(nil, "ARTWORK")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0.2, 0.3, 0.5, 0.2)
    f.bg:Hide()

    overlayFrames[index] = f
    return f
end

function FFS.InitOverlays()
    if not FFS.db.overlays then FFS.db.overlays = {} end
    for i = 1, MAX_OVERLAYS do
        CreateOverlayFrame(i)
        ApplyOverlay(i)
    end
end

function FFS.RefreshOverlays()
    for i = 1, MAX_OVERLAYS do
        if overlayFrames[i] then
            ApplyOverlay(i)
        end
    end
    FFS.UpdateOverlayLockState()
end

function FFS.UpdateOverlayLockState()
    local locked = FFS.db.locked
    local showGuides = not locked or FFS.settingsOpen
    for i = 1, MAX_OVERLAYS do
        local f = overlayFrames[i]
        if f then
            local cfg = GetOverlayDB(i)
            if not InCombatLockdown() then
                f:SetMovable(not locked)
                f:EnableMouse(not locked)
            end
            if f.label then
                if showGuides and cfg.enabled then f.label:Show() else f.label:Hide() end
            end
            if f.bg then
                if showGuides and cfg.enabled then f.bg:Show() else f.bg:Hide() end
            end
        end
    end
end

FFS.MAX_OVERLAYS = MAX_OVERLAYS
