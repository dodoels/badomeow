local _, FFS = ...
if not FFS.L then FFS.L = {} end
local L = FFS.L

local defaults = {
    ["ADDON_LOADED"]         = "ForFeralSake v1.0.0 loaded - /ffs to open settings (Official CDM sync)",
    ["SETTINGS_TITLE"]       = "ForFeralSake - Official CDM Sync Monitor",
    ["GENERAL"]              = "General",
    ["ENABLED"]              = "Enable Addon",
    ["LOCK_FRAME"]           = "Frame Locked",
    ["UNLOCK_FRAME"]         = "Frame Unlocked (Drag to move, right-click to lock)",
    ["SCALE"]                = "Scale",
    ["STYLE"]                = "Style Preset",
    ["SHOW_PRIMARY_BAR"]     = "Show Primary Resource Bar",
    ["SHOW_SECONDARY_BAR"]   = "Show Secondary Resource (Combo etc.)",
    ["ALERTS"]               = "Alerts & Sounds",
    ["PLAY_PROC_SOUND"]      = "Play Sound on Proc",
    ["PLAY_CD_SOUND"]        = "Play Sound on CD Ready",
    ["RESET_POSITION"]       = "Reset Position",
    ["BAR_WIDTH"]            = "Bar Width",
    ["BAR_HEIGHT"]           = "Bar Height",
    ["NOT_DRUID"]            = "This addon is for Druid class only",
}

for k, v in pairs(defaults) do
    if not L[k] then L[k] = v end
end
