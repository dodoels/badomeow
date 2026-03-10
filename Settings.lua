local addonName, BM = ...
local L

-- ==========================================
-- Settings Panel - ESC menu integration
-- Uses multiple fallback methods for maximum compatibility
-- ==========================================

local settingsRegistered = false

-- ==========================================
-- Create the options panel frame
-- ==========================================
local function CreateOptionsPanel()
    L = BM.L or {}

    local panel = CreateFrame("Frame", "badomeowOptionsPanel", UIParent)
    panel.name = "badomeow"
    panel:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 16)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 1500)
    scrollFrame:SetScrollChild(content)

    local yOff = -10

    local function NextY(h)
        local y = yOff
        yOff = yOff - (h or 30)
        return y
    end

    -- ==========================================
    -- UI Builders
    -- ==========================================

    local function Header(text)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 0, NextY(30))
        lbl:SetText(text)
        lbl:SetTextColor(0.4, 0.9, 0.4, 1)
    end

    local function InfoText(text)
        local y = NextY(18)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetWidth(500)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(text)
        lbl:SetTextColor(0.7, 0.7, 0.7, 1)
    end

    local function Checkbox(labelText, dbKey)
        local y = NextY(26)
        local cb = CreateFrame("CheckButton", "badomeowCB_" .. dbKey, content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        cb:SetSize(26, 26)

        local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        text:SetText(labelText)

        cb:SetChecked(BM.db[dbKey] or false)
        cb:SetScript("OnClick", function(self)
            BM.db[dbKey] = self:GetChecked() and true or false
            BM.RefreshAll()
        end)
    end

    local function Slider(labelText, dbKey, minVal, maxVal, step)
        local y = NextY(48)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local s = CreateFrame("Slider", "badomeowSlider_" .. dbKey, content, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", content, "TOPLEFT", 190, y - 2)
        s:SetSize(200, 17)
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(step)
        s:SetObeyStepOnDrag(true)
        s:SetValue(BM.db[dbKey] or minVal)
        s.Low:SetText(tostring(minVal))
        s.High:SetText(tostring(maxVal))

        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("TOP", s, "BOTTOM", 0, -2)
        valText:SetText(string.format("%.1f", BM.db[dbKey] or minVal))

        s:SetScript("OnValueChanged", function(self, v)
            BM.db[dbKey] = v
            valText:SetText(string.format("%.1f", v))
            BM.RefreshAll()
        end)
    end

    local function EditBox(labelText, dbKey, width)
        local y = NextY(36)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local eb = CreateFrame("EditBox", "badomeowEB_" .. dbKey, content, "InputBoxTemplate")
        eb:SetPoint("TOPLEFT", content, "TOPLEFT", 190, y + 4)
        eb:SetSize(width or 260, 24)
        eb:SetAutoFocus(false)
        eb:SetText(BM.db[dbKey] or "")
        eb:SetScript("OnEnterPressed", function(self)
            BM.db[dbKey] = self:GetText()
            BM.RefreshAll()
            self:ClearFocus()
        end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    end

    local function Button(labelText, onClick)
        local y = NextY(32)
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        btn:SetSize(180, 26)
        btn:SetText(labelText)
        btn:SetScript("OnClick", onClick)
    end

    local function DropdownSimple(labelText, options, dbKey)
        local y = NextY(32)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        -- Simple button-based selector (no UIDropDownMenuTemplate dependency)
        local idx = 0
        local orderedKeys = {}
        for k in pairs(options) do
            orderedKeys[#orderedKeys + 1] = k
        end

        local display = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        display:SetPoint("TOPLEFT", content, "TOPLEFT", 200, y)
        display:SetText(options[BM.db[dbKey]] or BM.db[dbKey] or "?")
        display:SetTextColor(1, 0.85, 0.3, 1)

        local btnNext = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btnNext:SetPoint("LEFT", display, "RIGHT", 8, 0)
        btnNext:SetSize(50, 20)
        btnNext:SetText(">>")
        btnNext:SetScript("OnClick", function()
            local current = BM.db[dbKey]
            local nextIdx = 1
            for i, k in ipairs(orderedKeys) do
                if k == current then
                    nextIdx = (i % #orderedKeys) + 1
                    break
                end
            end
            BM.db[dbKey] = orderedKeys[nextIdx]
            display:SetText(options[BM.db[dbKey]] or BM.db[dbKey])
            BM.RefreshAll()
        end)
    end

    -- ==========================================
    -- Build the panel
    -- ==========================================

    Header("豹集 badomeow · 德鲁伊全系监控")
    local specCN = BM.SpecNamesCN and BM.SpecNamesCN[BM.GetCurrentSpecID()] or "未知"
    InfoText("当前专精: " .. specCN .. " | 插件自动检测专精和变身形态并切换技能组")
    InfoText("非德鲁伊职业时自动隐藏。")
    NextY(6)

    -- General
    Header(L["GENERAL"] or "常规设置")
    Checkbox(L["ENABLED"] or "启用插件", "enabled")
    Checkbox(L["LOCK_FRAME"] or "锁定框体", "locked")
    Slider(L["SCALE"] or "缩放", "scale", 0.5, 2.0, 0.1)

    -- Style
    local styleOpts = {}
    for k, v in pairs(BM.Styles) do styleOpts[k] = v.name end
    DropdownSimple(L["STYLE"] or "风格预设", styleOpts, "style")

    -- Visibility
    DropdownSimple(L["VISIBILITY"] or "显示条件", {
        always           = L["VIS_ALWAYS"] or "始终显示",
        combat           = L["VIS_COMBAT"] or "仅战斗中",
        target           = L["VIS_TARGET"] or "有目标时",
        combat_or_target = L["VIS_COMBAT_OR_TARGET"] or "战斗中或有目标时",
        hidden           = L["VIS_HIDDEN"] or "隐藏",
    }, "visibility")

    -- Background
    Header(L["CUSTOM_BG"] or "自定义背景")
    InfoText(L["CUSTOM_BG_DESC"] or "放入 .tga/.blp 到 Textures\\Backgrounds 后输入路径")
    EditBox(L["CUSTOM_BG"] or "背景路径", "customBg")

    -- Display
    Header(L["DISPLAY"] or "显示设置")
    Checkbox(L["SHOW_BUFFS"] or "显示增益监控", "showBuffs")
    Checkbox(L["SHOW_DEBUFFS"] or "显示减益监控", "showDebuffs")
    Checkbox(L["SHOW_COOLDOWNS"] or "显示冷却监控", "showCooldowns")
    Checkbox(L["SHOW_PRIMARY_BAR"] or "显示主资源条", "showPrimaryBar")
    Checkbox(L["SHOW_SECONDARY_BAR"] or "显示副资源条", "showSecondaryBar")
    Checkbox(L["SHOW_PROC_GLOW"] or "触发发光效果", "showProcGlow")
    Checkbox(L["SHOW_PROC_IMAGE"] or "触发图片提示", "showProcImage")

    Slider(L["BAR_WIDTH"] or "条宽度", "barWidth", 150, 450, 10)
    Slider(L["BAR_HEIGHT"] or "条高度", "barHeight", 10, 40, 2)
    Slider(L["ICON_SIZE"] or "图标大小", "iconSize", 20, 64, 2)
    Slider(L["PROC_IMAGE_SIZE"] or "触发图片大小", "procImageSize", 40, 200, 10)

    -- Sounds
    Header(L["ALERTS"] or "提示与音效")
    Checkbox(L["PLAY_PROC_SOUND"] or "触发时播放音效", "playProcSound")
    Checkbox(L["PLAY_CD_SOUND"] or "冷却结束播放音效", "playCdSound")

    -- Actions
    NextY(10)
    Button(L["RESET_POSITION"] or "重置位置", function()
        BM.db.mainFrameX = 0
        BM.db.mainFrameY = -200
        if BM.MainFrame then
            BM.MainFrame:ClearAllPoints()
            BM.MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        end
    end)

    Button("解锁框体 (拖动移动)", function()
        BM.db.locked = false
        if BM.MainFrame then
            BM.MainFrame:SetMovable(true)
            BM.MainFrame:EnableMouse(true)
        end
        BM.UpdateVisibility()
        print("|cFF00FF00badomeow:|r 框体已解锁，可以拖动，右键点击锁定")
    end)

    -- Credits
    NextY(20)
    Header("关于 / About")
    InfoText("badomeow v" .. BM.VERSION .. " | MIT License")
    InfoText("灵感来源 / Inspirations:")
    InfoText("  · WeakAuras2 (GPL v2) - 经典WA框架设计理念")
    InfoText("  · SenseiClassResourceBar (MIT) - 12.0资源条参考")
    InfoText("  · Arc UI - 组件化UI设计参考")

    return panel
end

-- ==========================================
-- Register into ESC > Options > AddOns
-- Uses multiple methods for compatibility
-- ==========================================
function BM.InitSettings()
    if settingsRegistered then return end
    settingsRegistered = true

    L = BM.L or {}
    local panel = CreateOptionsPanel()

    -- Method 1: Modern Settings API (12.0+)
    local ok, err = pcall(function()
        local category = Settings.RegisterCanvasLayoutSubcategory(
            Settings.GetCategory("InterfaceOptions") or Settings.RegisterCanvasLayoutCategory(panel, panel.name),
            panel,
            panel.name
        )
        BM.settingsCategory = category
    end)

    -- Method 2: Simpler modern registration
    if not ok then
        ok, err = pcall(function()
            local category, _ = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
            Settings.RegisterAddOnCategory(category)
            BM.settingsCategory = category
        end)
    end

    -- Method 3: Legacy fallback
    if not ok then
        pcall(function()
            if InterfaceOptions_AddCategory then
                InterfaceOptions_AddCategory(panel)
            end
        end)
    end

    BM.optionsPanel = panel
end

function BM.OpenSettings()
    -- Try modern Settings API first
    if BM.settingsCategory then
        pcall(function() Settings.OpenToCategory(BM.settingsCategory) end)
        return
    end
    -- Legacy fallback
    pcall(function() InterfaceOptionsFrame_OpenToCategory(BM.optionsPanel) end)
    pcall(function() InterfaceOptionsFrame_OpenToCategory(BM.optionsPanel) end)
end
