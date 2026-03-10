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

    -- Build panel
    Header("豹集 badomeow v2 · 官方CDM同步监控")
    InfoText("自动 hook 暴雪 CooldownViewer 系统，无需手动配置技能列表。")
    InfoText("所有冷却、增益数据直接来自游戏官方系统，自动跟随专精切换。")
    NextY(6)

    Header(L["GENERAL"] or "常规设置")
    Checkbox(L["ENABLED"] or "启用插件", "enabled")
    Checkbox(L["LOCK_FRAME"] or "锁定框体", "locked")
    Slider(L["SCALE"] or "缩放", "scale", 0.5, 2.0, 0.1)

    Header("资源条")
    Checkbox(L["SHOW_PRIMARY_BAR"] or "显示主资源条", "showPrimaryBar")
    Checkbox(L["SHOW_SECONDARY_BAR"] or "显示副资源条（连击点等）", "showSecondaryBar")
    Slider(L["BAR_WIDTH"] or "条宽度", "barWidth", 150, 450, 10)
    Slider(L["BAR_HEIGHT"] or "条高度", "barHeight", 10, 40, 2)

    Header(L["ALERTS"] or "提示与音效")
    Checkbox(L["PLAY_PROC_SOUND"] or "触发时播放音效", "playProcSound")
    Checkbox(L["PLAY_CD_SOUND"] or "冷却结束播放音效", "playCdSound")

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

    NextY(20)
    Header("关于 / About")
    InfoText("badomeow v" .. BM.VERSION .. " | MIT License")
    InfoText("基于暴雪 CooldownViewer 系统，自动同步所有职业/专精技能数据")
    InfoText("灵感: Ayije_CDM, WeakAuras2, SenseiClassResourceBar")

    return panel
end

-- MRT-style registration
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
