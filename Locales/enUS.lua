local _, BM = ...
if not BM.L then BM.L = {} end
local L = BM.L

local defaults = {
    ["ADDON_LOADED"]         = "badomeow loaded - type /bdm or /badomeow to open settings",
    ["SETTINGS_TITLE"]       = "badomeow - Druid Combat Monitor",
    ["GENERAL"]              = "General",
    ["ENABLED"]              = "Enable Addon",
    ["LOCK_FRAME"]           = "Frame Locked",
    ["UNLOCK_FRAME"]         = "Frame Unlocked (Drag to move, right-click to lock)",
    ["SCALE"]                = "Scale",
    ["STYLE"]                = "Style Preset",
    ["CUSTOM_BG"]            = "Custom Background",
    ["CUSTOM_BG_DESC"]       = "Put .tga/.blp in Textures\\Backgrounds, then enter path\ne.g.: Interface\\AddOns\\badomeow\\Textures\\Backgrounds\\my_art",
    ["DISPLAY"]              = "Display",
    ["SHOW_BUFFS"]           = "Show Buff Tracking",
    ["SHOW_DEBUFFS"]         = "Show Debuff Tracking (Target)",
    ["SHOW_COOLDOWNS"]       = "Show Cooldown Tracking",
    ["SHOW_PRIMARY_BAR"]     = "Show Primary Resource Bar",
    ["SHOW_SECONDARY_BAR"]   = "Show Secondary Resource (Combo etc.)",
    ["SHOW_PROC_GLOW"]       = "Show Proc Glow Effect",
    ["SHOW_PROC_IMAGE"]      = "Show Proc Image Alert",
    ["ALERTS"]               = "Alerts & Sounds",
    ["PLAY_PROC_SOUND"]      = "Play Sound on Proc",
    ["PLAY_CD_SOUND"]        = "Play Sound on CD Ready",
    ["SOUND_VOLUME"]         = "Sound Volume",
    ["VISIBILITY"]           = "Visibility",
    ["VIS_ALWAYS"]           = "Always Visible",
    ["VIS_COMBAT"]           = "In Combat Only",
    ["VIS_TARGET"]           = "With Target",
    ["VIS_COMBAT_OR_TARGET"] = "Combat or Target",
    ["VIS_HIDDEN"]           = "Hidden",
    ["DRAG_TO_MOVE"]         = "Drag to move - Right-click to lock",
    ["RESET_POSITION"]       = "Reset Position",
    ["BAR_WIDTH"]            = "Bar Width",
    ["BAR_HEIGHT"]           = "Bar Height",
    ["ICON_SIZE"]            = "Icon Size",
    ["PROC_IMAGE_SIZE"]      = "Proc Image Size",
    ["SPEC_AUTO"]            = "Auto-detected spec: %s",
    ["NOT_DRUID"]            = "This addon is for Druid class only",
}

for k, v in pairs(defaults) do
    if not L[k] then L[k] = v end
end
