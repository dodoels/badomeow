local addonName, FFS = ...

FFS.ADDON_NAME = addonName
FFS.VERSION = "1.0.0"

FFS.DRUID_CLASS_ID = 11

FFS.SpecNames = {
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Restoration",
}

FFS.SpecNamesCN = {
    [102] = "平衡",
    [103] = "野性",
    [104] = "守护",
    [105] = "恢复",
}

FFS.VIEWERS = {
    ESSENTIAL = "EssentialCooldownViewer",
    UTILITY   = "UtilityCooldownViewer",
    BUFF      = "BuffIconCooldownViewer",
    BUFF_BAR  = "BuffBarCooldownViewer",
}

FFS.ComboPipColors = {
    [1] = { 1.0, 0.9, 0.2 },
    [2] = { 1.0, 0.7, 0.1 },
    [3] = { 1.0, 0.5, 0.0 },
    [4] = { 1.0, 0.3, 0.0 },
    [5] = { 1.0, 0.1, 0.0 },
}

FFS.Styles = {
    ["default"] = {
        name        = "默认 / Default",
        borderColor = { 0.3, 0.8, 0.3, 0.8 },
        accentColor = { 1.0, 0.6, 0.0, 1.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
}

FFS.SECTIONS = { "buff", "secondary", "primary", "mana", "essential", "utility" }
FFS.SECTION_LABELS = {
    buff      = "增益/触发",
    secondary = "连击点",
    primary   = "资源条",
    mana      = "蓝条",
    essential = "核心技能",
    utility   = "工具技能",
}

FFS.DefaultDB = {
    enabled         = true,
    locked          = true,
    globalOffsetX   = 0,
    globalOffsetY   = 0,
    style           = "default",
    showBuff        = true,
    showEssential   = true,
    showUtility     = true,
    showPrimaryBar  = true,
    showSecondaryBar = true,
    showManaBar     = true,
    scale           = 1.0,
    barWidth        = 260,
    barHeight       = 18,
    pipWidth        = 260,
    pipHeight       = 10,
    manaBarWidth    = 260,
    manaBarHeight   = 10,
    essentialSize   = 36,
    buffSize        = 30,
    utilitySize     = 26,
    useMasque       = true,
    iconSpacing     = 2,
    pos_essential   = { x = 0,   y = -220 },
    pos_buff        = { x = 0,   y = -180 },
    pos_utility     = { x = 0,   y = -290 },
    pos_primary     = { x = 0,   y = -255 },
    pos_secondary   = { x = 0,   y = -240 },
    pos_mana        = { x = 0,   y = -270 },
}
