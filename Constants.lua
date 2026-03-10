local addonName, BM = ...

BM.ADDON_NAME = addonName
BM.VERSION = "2.0.0"

BM.DRUID_CLASS_ID = 11

BM.SpecNames = {
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Restoration",
}

BM.SpecNamesCN = {
    [102] = "平衡",
    [103] = "野性",
    [104] = "守护",
    [105] = "恢复",
}

-- Blizzard CooldownViewer frame names (12.0+)
BM.VIEWERS = {
    ESSENTIAL = "EssentialCooldownViewer",
    UTILITY   = "UtilityCooldownViewer",
    BUFF      = "BuffIconCooldownViewer",
    BUFF_BAR  = "BuffBarCooldownViewer",
}

-- Combo pip gradient (Feral)
BM.ComboPipColors = {
    [1] = { 1.0, 0.9, 0.2 },
    [2] = { 1.0, 0.7, 0.1 },
    [3] = { 1.0, 0.5, 0.0 },
    [4] = { 1.0, 0.3, 0.0 },
    [5] = { 1.0, 0.1, 0.0 },
}

-- Style presets
BM.Styles = {
    ["default"] = {
        name        = "默认 / Default",
        borderColor = { 0.3, 0.8, 0.3, 0.8 },
        accentColor = { 1.0, 0.6, 0.0, 1.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
    ["dark"] = {
        name        = "暗夜 / Dark Forest",
        borderColor = { 0.15, 0.15, 0.15, 1.0 },
        accentColor = { 0.7, 0.2, 0.8, 1.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
    ["nature"] = {
        name        = "翡翠梦境 / Emerald Dream",
        borderColor = { 0.2, 0.75, 0.2, 1.0 },
        accentColor = { 0.3, 1.0, 0.4, 1.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
}

-- Section keys used for layout ordering and toggle
BM.SECTIONS = { "buff", "secondary", "primary", "essential", "utility" }
BM.SECTION_LABELS = {
    buff      = "增益/触发",
    secondary = "连击点",
    primary   = "资源条",
    essential = "核心技能",
    utility   = "工具技能",
}

BM.DefaultDB = {
    enabled         = true,
    locked          = false,
    style           = "default",
    customBg        = nil,
    showBuff        = true,
    showEssential   = true,
    showUtility     = true,
    showPrimaryBar  = true,
    showSecondaryBar = true,
    playProcSound   = true,
    playCdSound     = false,
    scale           = 1.0,
    mainFrameX      = 0,
    mainFrameY      = -200,
    barWidth        = 260,
    barHeight       = 18,
    soundVolume     = 1.0,
    -- Layout order (top to bottom): each entry is a section key
    layoutOrder     = { "buff", "secondary", "primary", "essential", "utility" },
}
