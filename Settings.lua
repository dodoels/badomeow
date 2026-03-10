local addonName, BM = ...
local L

local settingsRegistered = false

local function CreateOptionsPanel()
    L = BM.L or {}

    local panel = CreateFrame("Frame", "badomeowOptionsPanel", UIParent)
    panel.name = "badomeow"
    panel:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 16)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 900)
    scrollFrame:SetScrollChild(content)

    local yOff = -10

    local function NextY(h)
        local y = yOff
        yOff = yOff - (h or 30)
        return y
    end

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

    local function Button(labelText, onClick)
        local y = NextY(32)
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        btn:SetSize(180, 26)
        btn:SetText(labelText)
        btn:SetScript("OnClick", onClick)
    end

    Header("豹集 badomeow v3 · 官方CDM同步监控")
    InfoText("自动 hook 暴雪 CooldownViewer 系统，无需手动配置技能列表。")
    InfoText("所有冷却、增益数据直接来自游戏官方系统，自动跟随专精切换。")
    NextY(6)

    Header("常规设置")
    Checkbox("启用插件", "enabled")
    Checkbox("锁定框体", "locked")
    Slider("缩放", "scale", 0.5, 2.0, 0.1)

    Header("组件开关")
    InfoText("分别控制每个区域的显示/隐藏。关闭后该区域不占空间。")
    Checkbox("增益/触发 (Buff/Proc)", "showBuff")
    Checkbox("核心技能 (Essential)", "showEssential")
    Checkbox("工具技能 (Utility)", "showUtility")
    Checkbox("资源条 (Primary Bar)", "showPrimaryBar")
    Checkbox("连击点 (Combo Points)", "showSecondaryBar")

    Header("组件排列顺序")
    InfoText("点击 ▲ / ▼ 调整各组件从上到下的排列顺序。")

    local orderWidgets = {}
    local function RebuildOrderWidgets()
        local order = BM.db.layoutOrder or BM.SECTIONS
        for i, w in ipairs(orderWidgets) do
            local section = order[i]
            if section then
                local label = BM.SECTION_LABELS[section] or section
                w.label:SetText(string.format("%d.  %s", i, label))
                w.section = section
                w:Show()
            else
                w:Hide()
            end
        end
    end

    for i = 1, #BM.SECTIONS do
        local y = NextY(28)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        row:SetSize(400, 24)

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.label:SetJustifyH("LEFT")

        local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        upBtn:SetPoint("LEFT", row, "LEFT", 200, 0)
        upBtn:SetSize(28, 22)
        upBtn:SetText("▲")
        upBtn:SetScript("OnClick", function()
            if row.section then
                BM.SwapSectionOrder(row.section, -1)
                RebuildOrderWidgets()
            end
        end)

        local downBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        downBtn:SetPoint("LEFT", upBtn, "RIGHT", 2, 0)
        downBtn:SetSize(28, 22)
        downBtn:SetText("▼")
        downBtn:SetScript("OnClick", function()
            if row.section then
                BM.SwapSectionOrder(row.section, 1)
                RebuildOrderWidgets()
            end
        end)

        orderWidgets[i] = row
    end

    panel:HookScript("OnShow", function() RebuildOrderWidgets() end)

    NextY(6)
    Header("资源条样式")
    Slider("条宽度", "barWidth", 150, 450, 10)
    Slider("条高度", "barHeight", 10, 40, 2)

    NextY(10)
    Button("重置位置", function()
        BM.db.mainFrameX = 0
        BM.db.mainFrameY = -200
        if BM.MainFrame then
            BM.MainFrame:ClearAllPoints()
            BM.MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        end
    end)

    Button("重置排列顺序", function()
        BM.db.layoutOrder = { "buff", "secondary", "primary", "essential", "utility" }
        RebuildOrderWidgets()
        if BM.LayoutAll then BM.LayoutAll() end
        print("|cFF00FF00badomeow:|r 排列顺序已重置")
    end)

    Button("解锁框体 (拖动移动)", function()
        if InCombatLockdown() then
            print("|cFFFF5555badomeow:|r 战斗中无法解锁")
            return
        end
        BM.db.locked = false
        BM.UpdateVisibility()
        print("|cFF00FF00badomeow:|r 框体已解锁，可以拖动，右键点击锁定")
    end)

    NextY(20)
    Header("关于")
    InfoText("badomeow v" .. BM.VERSION .. " | MIT License")
    InfoText("基于暴雪 CooldownViewer 系统，自动同步所有职业/专精技能数据")
    InfoText("灵感: Ayije_CDM, WeakAuras2, SenseiClassResourceBar")

    return panel
end

function BM.InitSettings()
    if settingsRegistered then return end
    settingsRegistered = true

    L = BM.L or {}
    local panel = CreateOptionsPanel()

    if SettingsPanel then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "badomeow")
        Settings.RegisterAddOnCategory(category)
        BM.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    BM.optionsPanel = panel
end

function BM.OpenSettings()
    if BM.settingsCategory then
        Settings.OpenToCategory(BM.settingsCategory.ID)
        return
    end
    if BM.optionsPanel and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(BM.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(BM.optionsPanel)
    end
end
