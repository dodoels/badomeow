local addonName, BM = ...

BM.ADDON_NAME = addonName
BM.VERSION = "1.0.0"

BM.DRUID_CLASS_ID = 11

-- Spec IDs (retail)
BM.SPEC_BALANCE     = 102
BM.SPEC_FERAL       = 103
BM.SPEC_GUARDIAN     = 104
BM.SPEC_RESTORATION = 105

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

-- ==========================================
-- Per-spec spell data
-- ==========================================

BM.SpecData = {}

-- ====================
-- FERAL (103)
-- ====================
BM.SpecData[103] = {
    powerType     = Enum.PowerType.Energy,
    secondaryPower = Enum.PowerType.ComboPoints,
    maxSecondary  = 5,
    powerLabel    = "能量",
    secondaryLabel = "连击点",

    buffs = {
        { spellId = 135700, name = "Clearcasting",        priority = 10, glow = true,  sound = "proc" },
        { spellId = 145152, name = "Bloodtalons",         priority = 9,  glow = true,  sound = "proc" },
        { spellId = 69369,  name = "Predatory Swiftness", priority = 8,  glow = true,  sound = "proc" },
        { spellId = 384667, name = "Sudden Ambush",       priority = 7,  glow = true,  sound = "alert" },
        { spellId = 5217,   name = "Tiger's Fury",        priority = 6,  glow = false, sound = nil },
        { spellId = 52610,  name = "Savage Roar",         priority = 5,  glow = false, sound = nil },
        { spellId = 106951, name = "Berserk",             priority = 4,  glow = false, sound = nil },
        { spellId = 102543, name = "Incarnation",         priority = 3,  glow = false, sound = nil },
    },

    debuffs = {
        { spellId = 155722, name = "Rake",           priority = 10 },
        { spellId = 1079,   name = "Rip",            priority = 9 },
        { spellId = 106830, name = "Thrash",         priority = 8 },
        { spellId = 155625, name = "Moonfire",       priority = 7 },
        { spellId = 391888, name = "Adaptive Swarm", priority = 6 },
    },

    cooldowns = {
        { spellId = 5217,   name = "Tiger's Fury" },
        { spellId = 106951, name = "Berserk" },
        { spellId = 102543, name = "Incarnation" },
        { spellId = 274837, name = "Feral Frenzy" },
        { spellId = 391528, name = "Convoke" },
    },
}

-- ====================
-- BALANCE (102)
-- ====================
BM.SpecData[102] = {
    powerType      = Enum.PowerType.LunarPower,
    secondaryPower = nil,
    maxSecondary   = 0,
    powerLabel     = "星能",
    secondaryLabel = nil,

    buffs = {
        { spellId = 48517,  name = "Eclipse (Solar)",   priority = 10, glow = true,  sound = "proc" },
        { spellId = 48518,  name = "Eclipse (Lunar)",   priority = 9,  glow = true,  sound = "proc" },
        { spellId = 191034, name = "Starfall",          priority = 8,  glow = false, sound = nil },
        { spellId = 394049, name = "Umbral Embrace",    priority = 7,  glow = true,  sound = "proc" },
        { spellId = 202425, name = "Warrior of Elune",  priority = 6,  glow = true,  sound = "alert" },
        { spellId = 194223, name = "Celestial Alignment", priority = 5, glow = false, sound = nil },
        { spellId = 102560, name = "Incarnation: CotEW", priority = 4, glow = false, sound = nil },
        { spellId = 393942, name = "Starweaver's Warp", priority = 3,  glow = true,  sound = "proc" },
        { spellId = 393944, name = "Starweaver's Weft", priority = 2,  glow = true,  sound = "proc" },
    },

    debuffs = {
        { spellId = 164812, name = "Moonfire",        priority = 10 },
        { spellId = 164815, name = "Sunfire",         priority = 9 },
        { spellId = 202347, name = "Stellar Flare",   priority = 8 },
        { spellId = 391888, name = "Adaptive Swarm",  priority = 7 },
    },

    cooldowns = {
        { spellId = 194223, name = "Celestial Alignment" },
        { spellId = 102560, name = "Incarnation: CotEW" },
        { spellId = 202425, name = "Warrior of Elune" },
        { spellId = 391528, name = "Convoke" },
        { spellId = 205636, name = "Force of Nature" },
    },
}

-- ====================
-- GUARDIAN (104)
-- ====================
BM.SpecData[104] = {
    powerType      = Enum.PowerType.Rage,
    secondaryPower = nil,
    maxSecondary   = 0,
    powerLabel     = "怒气",
    secondaryLabel = nil,

    buffs = {
        { spellId = 22842,  name = "Frenzied Regen",     priority = 10, glow = false, sound = nil },
        { spellId = 192081, name = "Ironfur",             priority = 9,  glow = false, sound = nil },
        { spellId = 135286, name = "Tooth and Claw",      priority = 8,  glow = true,  sound = "proc" },
        { spellId = 50334,  name = "Berserk",             priority = 7,  glow = false, sound = nil },
        { spellId = 102558, name = "Incarnation: GoUE",   priority = 6,  glow = false, sound = nil },
        { spellId = 203975, name = "Earthwarden",         priority = 5,  glow = true,  sound = nil },
        { spellId = 61336,  name = "Survival Instincts",  priority = 4,  glow = false, sound = nil },
        { spellId = 22812,  name = "Barkskin",            priority = 3,  glow = false, sound = nil },
    },

    debuffs = {
        { spellId = 77758,  name = "Thrash",         priority = 10 },
        { spellId = 164812, name = "Moonfire",       priority = 9 },
        { spellId = 391888, name = "Adaptive Swarm", priority = 8 },
    },

    cooldowns = {
        { spellId = 22842,  name = "Frenzied Regen" },
        { spellId = 61336,  name = "Survival Instincts" },
        { spellId = 50334,  name = "Berserk" },
        { spellId = 102558, name = "Incarnation: GoUE" },
        { spellId = 391528, name = "Convoke" },
        { spellId = 22812,  name = "Barkskin" },
    },
}

-- ====================
-- RESTORATION (105)
-- ====================
BM.SpecData[105] = {
    powerType      = Enum.PowerType.Mana,
    secondaryPower = nil,
    maxSecondary   = 0,
    powerLabel     = "法力",
    secondaryLabel = nil,

    buffs = {
        { spellId = 16870,  name = "Clearcasting",       priority = 10, glow = true,  sound = "proc" },
        { spellId = 774,    name = "Rejuvenation",       priority = 9,  glow = false, sound = nil },
        { spellId = 48438,  name = "Wild Growth",        priority = 8,  glow = false, sound = nil },
        { spellId = 33763,  name = "Lifebloom",          priority = 7,  glow = false, sound = nil },
        { spellId = 29166,  name = "Innervate",          priority = 6,  glow = true,  sound = "alert" },
        { spellId = 102342, name = "Ironbark",           priority = 5,  glow = false, sound = nil },
        { spellId = 33891,  name = "Incarnation: ToL",   priority = 4,  glow = false, sound = nil },
        { spellId = 197721, name = "Flourish",           priority = 3,  glow = false, sound = nil },
    },

    debuffs = {
        { spellId = 164812, name = "Moonfire",        priority = 10 },
        { spellId = 164815, name = "Sunfire",         priority = 9 },
        { spellId = 391888, name = "Adaptive Swarm",  priority = 8 },
    },

    cooldowns = {
        { spellId = 740,    name = "Tranquility" },
        { spellId = 33891,  name = "Incarnation: ToL" },
        { spellId = 391528, name = "Convoke" },
        { spellId = 197721, name = "Flourish" },
        { spellId = 29166,  name = "Innervate" },
        { spellId = 102342, name = "Ironbark" },
    },
}

-- ==========================================
-- Style presets
-- ==========================================
BM.Styles = {
    ["default"] = {
        name        = "默认 / Default",
        bgAlpha     = 0.7,
        bgColor     = { 0.05, 0.05, 0.1, 0.7 },
        borderColor = { 0.4, 0.8, 0.3, 1.0 },
        accentColor = { 1.0, 0.6, 0.0, 1.0 },
        primaryBarColor  = { 1.0, 0.85, 0.0 },
        secondaryColor   = { 1.0, 0.8, 0.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
    ["dark"] = {
        name        = "暗夜 / Dark Forest",
        bgAlpha     = 0.85,
        bgColor     = { 0.02, 0.02, 0.02, 0.85 },
        borderColor = { 0.15, 0.15, 0.15, 1.0 },
        accentColor = { 0.7, 0.2, 0.8, 1.0 },
        primaryBarColor  = { 0.6, 0.3, 0.8 },
        secondaryColor   = { 0.9, 0.3, 0.1 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
    ["nature"] = {
        name        = "翡翠梦境 / Emerald Dream",
        bgAlpha     = 0.6,
        bgColor     = { 0.0, 0.12, 0.05, 0.6 },
        borderColor = { 0.2, 0.75, 0.2, 1.0 },
        accentColor = { 0.3, 1.0, 0.4, 1.0 },
        primaryBarColor  = { 0.3, 0.9, 0.3 },
        secondaryColor   = { 0.3, 1.0, 0.3 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
    ["moonkin"] = {
        name        = "月光 / Moonlight",
        bgAlpha     = 0.7,
        bgColor     = { 0.04, 0.02, 0.1, 0.7 },
        borderColor = { 0.3, 0.3, 0.8, 1.0 },
        accentColor = { 0.5, 0.5, 1.0, 1.0 },
        primaryBarColor  = { 0.4, 0.4, 1.0 },
        secondaryColor   = { 0.8, 0.6, 1.0 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
    ["guardian"] = {
        name        = "熊灵 / Bear Spirit",
        bgAlpha     = 0.75,
        bgColor     = { 0.08, 0.04, 0.02, 0.75 },
        borderColor = { 0.6, 0.4, 0.2, 1.0 },
        accentColor = { 1.0, 0.6, 0.2, 1.0 },
        primaryBarColor  = { 0.8, 0.3, 0.1 },
        secondaryColor   = { 1.0, 0.5, 0.1 },
        fontName    = "Fonts\\FRIZQT__.TTF",
        fontSize    = 12,
    },
}

-- Per-spec color overrides for resource bars
BM.SpecBarColors = {
    [102] = { primary = { 0.4, 0.4, 1.0 } },   -- Astral Power: blue
    [103] = { primary = { 1.0, 1.0, 0.0 }, secondary = { 1.0, 0.8, 0.0 } },  -- Energy: yellow, Combo: orange
    [104] = { primary = { 0.8, 0.2, 0.1 } },   -- Rage: red
    [105] = { primary = { 0.2, 0.4, 1.0 } },   -- Mana: blue
}

-- Combo pip gradient (Feral)
BM.ComboPipColors = {
    [1] = { 1.0, 0.9, 0.2 },
    [2] = { 1.0, 0.7, 0.1 },
    [3] = { 1.0, 0.5, 0.0 },
    [4] = { 1.0, 0.3, 0.0 },
    [5] = { 1.0, 0.1, 0.0 },
}

-- ==========================================
-- Default saved variables
-- ==========================================
BM.DefaultDB = {
    enabled         = true,
    locked          = false,
    style           = "default",
    customBg        = nil,
    showBuffs       = true,
    showDebuffs     = true,
    showCooldowns   = true,
    showPrimaryBar  = true,
    showSecondaryBar = true,
    showProcGlow    = true,
    showProcImage   = true,
    playProcSound   = true,
    playCdSound     = false,
    scale           = 1.0,
    mainFrameX      = 0,
    mainFrameY      = -200,
    barWidth        = 260,
    barHeight       = 18,
    iconSize        = 36,
    procImageSize   = 80,
    soundVolume     = 1.0,
    visibility      = "combat",
}
