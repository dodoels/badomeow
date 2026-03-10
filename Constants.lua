local addonName, BM = ...

BM.ADDON_NAME = addonName
BM.VERSION = "4.0.0"

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

BM.VIEWERS = {
    ESSENTIAL = "EssentialCooldownViewer",
    UTILITY   = "UtilityCooldownViewer",
    BUFF      = "BuffIconCooldownViewer",
    BUFF_BAR  = "BuffBarCooldownViewer",
}

BM.ComboPipColors = {
    [1] = { 1.0, 0.9, 0.2 },
    [2] = { 1.0, 0.7, 0.1 },
    [3] = { 1.0, 0.5, 0.0 },
    [4] = { 1.0, 0.3, 0.0 },
    [5] = { 1.0, 0.1, 0.0 },
}

BM.Styles = {
    ["default"] = {
        name        = "默认 / Default",
        borderColor = { 0.3, 0.8, 0.3, 0.8 },
        accentColor = { 1.0, 0.6, 0.0, 1.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
}

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
    locked          = true,
    style           = "default",
    showBuff        = true,
    showEssential   = true,
    showUtility     = true,
    showPrimaryBar  = true,
    showSecondaryBar = true,
    scale           = 1.0,
    barWidth        = 260,
    barHeight       = 18,
    essentialSize   = 36,
    buffSize        = 30,
    utilitySize     = 26,
    iconSpacing     = 2,
    -- Per-section position (relative to CENTER of screen)
    pos_essential   = { x = 0,   y = -220 },
    pos_buff        = { x = 0,   y = -180 },
    pos_utility     = { x = 0,   y = -290 },
    pos_primary     = { x = 0,   y = -255 },
    pos_secondary   = { x = 0,   y = -240 },
}
