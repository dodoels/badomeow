local addonName, FFS = ...

--[[
    Texture registry: manages available textures for overlays and bar fills.
    Users can drop .tga / .blp files into Interface\AddOns\ForFeralSake\Textures\
    and they will appear in the texture picker.
]]

local ADDON_TEX_PATH = "Interface\\AddOns\\ForFeralSake\\Textures\\"

FFS.TextureList = {}
FFS.BarTextureList = {}

local builtinOverlays = {
    { id = "none",           name = "无 / None",             path = "" },
    { id = "solid_black",    name = "纯黑 Solid Black",      path = "Interface\\Buttons\\WHITE8x8", r = 0, g = 0, b = 0, a = 0.6 },
    { id = "solid_dark",     name = "深灰 Dark Gray",        path = "Interface\\Buttons\\WHITE8x8", r = 0.05, g = 0.05, b = 0.05, a = 0.5 },
}

local builtinBars = {
    { id = "default",        name = "默认 Default",           path = "Interface\\TargetingFrame\\UI-StatusBar" },
    { id = "blizz_clean",    name = "暴雪 Clean",            path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
    { id = "blizz_flat",     name = "暴雪 Flat",             path = "Interface\\Buttons\\WHITE8x8" },
    { id = "blizz_raid",     name = "暴雪 Raid",             path = "Interface\\RaidFrame\\Raid-Bar-Resource-Fill" },
}

local function ScanUserTextures(subdir, list, prefix)
    -- WoW doesn't have filesystem listing, so we use a known-name approach.
    -- Users register textures by placing them in Textures/ with known names,
    -- or we list them from a manifest file.
end

function FFS.InitTextureRegistry()
    wipe(FFS.TextureList)
    wipe(FFS.BarTextureList)

    for _, t in ipairs(builtinOverlays) do
        FFS.TextureList[#FFS.TextureList + 1] = t
    end

    for _, t in ipairs(builtinBars) do
        FFS.BarTextureList[#FFS.BarTextureList + 1] = t
    end

    -- Load from auto-generated TextureManifest (generate_manifest.py)
    if FFS.TextureManifest then
        for _, entry in ipairs(FFS.TextureManifest) do
            local id = "tex_" .. entry.name
            FFS.TextureList[#FFS.TextureList + 1] = {
                id = id,
                name = entry.name,
                path = entry.path,
                custom = true,
            }
            FFS.BarTextureList[#FFS.BarTextureList + 1] = {
                id = id,
                name = entry.name,
                path = entry.path,
                custom = true,
            }
        end
    end

    -- Load user-registered custom textures from saved variables
    local manifest = FFS.db and FFS.db.customTextures
    if manifest then
        for _, entry in ipairs(manifest) do
            local id = "user_" .. entry.name
            local fullPath = ADDON_TEX_PATH .. entry.file
            FFS.TextureList[#FFS.TextureList + 1] = {
                id = id, name = entry.name, path = fullPath, custom = true,
            }
            FFS.BarTextureList[#FFS.BarTextureList + 1] = {
                id = id, name = entry.name, path = fullPath, custom = true,
            }
        end
    end
end

function FFS.GetTexturePath(id)
    for _, t in ipairs(FFS.TextureList) do
        if t.id == id then return t end
    end
    return nil
end

function FFS.GetBarTexturePath(id)
    for _, t in ipairs(FFS.BarTextureList) do
        if t.id == id then return t end
    end
    return nil
end

function FFS.RegisterCustomTexture(name, filename, texType)
    if not FFS.db.customTextures then FFS.db.customTextures = {} end
    local entry = { name = name, file = filename, type = texType or "overlay" }
    FFS.db.customTextures[#FFS.db.customTextures + 1] = entry
    FFS.InitTextureRegistry()
    return entry
end
