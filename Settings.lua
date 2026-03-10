local addonName, BM = ...
local L

function BM.InitSettings()
    L = BM.L

    local category, layout = Settings.RegisterCanvasLayoutCategory(
        CreateFrame("Frame"),
        L["SETTINGS_TITLE"]
    )
    BM.settingsCategory = category

    local canvas = category:GetFrame()
    canvas:SetAllPoints()

    local scrollFrame = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 1400)
    scrollFrame:SetScrollChild(content)

    local yOff = -10
    local function NextY(h)
        local y = yOff
        yOff = yOff - (h or 30)
        return y
    end

    -- ==========================================
    -- UI Helpers
    -- ==========================================

    local function Header(text)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 0, NextY(28))
        lbl:SetText(text)
        lbl:SetTextColor(0.4, 0.9, 0.4, 1)
    end

    local function Checkbox(labelText, dbKey)
        local y = NextY(28)
        local cb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        cb.Text:SetText(labelText)
        cb:SetChecked(BM.db[dbKey])
        cb:SetScript("OnClick", function(self)
            BM.db[dbKey] = self:GetChecked()
            BM.RefreshAll()
        end)
    end

    local function Slider(labelText, dbKey, minVal, maxVal, step)
        local y = NextY(50)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local s = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", content, "TOPLEFT", 180, y - 2)
        s:SetSize(200, 16)
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

    local function Dropdown(labelText, options, dbKey)
        local y = NextY(40)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local dd = CreateFrame("Frame", "badomeowDD_" .. dbKey, content, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", content, "TOPLEFT", 160, y + 5)
        UIDropDownMenu_SetWidth(dd, 160)

        UIDropDownMenu_Initialize(dd, function(self, level)
            for key, label in pairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = label
                info.value = key
                info.checked = (BM.db[dbKey] == key)
                info.func = function(self)
                    BM.db[dbKey] = self.value
                    UIDropDownMenu_SetText(dd, label)
                    CloseDropDownMenus()
                    BM.RefreshAll()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        UIDropDownMenu_SetText(dd, options[BM.db[dbKey]] or BM.db[dbKey])
    end

    local function EditBox(labelText, dbKey, width)
        local y = NextY(40)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local eb = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        eb:SetPoint("TOPLEFT", content, "TOPLEFT", 180, y + 2)
        eb:SetSize(width or 250, 22)
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
        local y = NextY(35)
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        btn:SetSize(180, 24)
        btn:SetText(labelText)
        btn:SetScript("OnClick", onClick)
    end

    local function InfoText(text)
        local y = NextY(20)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetWidth(500)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(text)
        lbl:SetTextColor(0.7, 0.7, 0.7, 1)
    end

    -- ==========================================
    -- Build UI
    -- ==========================================

    -- Spec info
    Header(L["SETTINGS_TITLE"])
    local specCN = BM.SpecNamesCN[BM.GetCurrentSpecID()] or "未知"
    InfoText(string.format(L["SPEC_AUTO"], specCN))
    InfoText("插件自动检测德鲁伊专精并切换技能组，非德鲁伊职业时自动隐藏。")
    NextY(8)

    -- General
    Header(L["GENERAL"])
    Checkbox(L["ENABLED"], "enabled")
    Checkbox(L["LOCK_FRAME"], "locked")
    Slider(L["SCALE"], "scale", 0.5, 2.0, 0.1)

    -- Style
    local styleOpts = {}
    for k, v in pairs(BM.Styles) do styleOpts[k] = v.name end
    Dropdown(L["STYLE"], styleOpts, "style")

    -- Visibility
    Dropdown(L["VISIBILITY"], {
        always           = L["VIS_ALWAYS"],
        combat           = L["VIS_COMBAT"],
        target           = L["VIS_TARGET"],
        combat_or_target = L["VIS_COMBAT_OR_TARGET"],
        hidden           = L["VIS_HIDDEN"],
    }, "visibility")

    -- Background
    Header(L["CUSTOM_BG"])
    InfoText(L["CUSTOM_BG_DESC"])
    EditBox(L["CUSTOM_BG"], "customBg")

    -- Display
    Header(L["DISPLAY"])
    Checkbox(L["SHOW_BUFFS"], "showBuffs")
    Checkbox(L["SHOW_DEBUFFS"], "showDebuffs")
    Checkbox(L["SHOW_COOLDOWNS"], "showCooldowns")
    Checkbox(L["SHOW_PRIMARY_BAR"], "showPrimaryBar")
    Checkbox(L["SHOW_SECONDARY_BAR"], "showSecondaryBar")
    Checkbox(L["SHOW_PROC_GLOW"], "showProcGlow")
    Checkbox(L["SHOW_PROC_IMAGE"], "showProcImage")

    Slider(L["BAR_WIDTH"], "barWidth", 150, 450, 10)
    Slider(L["BAR_HEIGHT"], "barHeight", 10, 40, 2)
    Slider(L["ICON_SIZE"], "iconSize", 20, 64, 2)
    Slider(L["PROC_IMAGE_SIZE"], "procImageSize", 40, 200, 10)

    -- Sounds
    Header(L["ALERTS"])
    Checkbox(L["PLAY_PROC_SOUND"], "playProcSound")
    Checkbox(L["PLAY_CD_SOUND"], "playCdSound")

    -- Actions
    NextY(10)
    Button(L["RESET_POSITION"], function()
        BM.db.mainFrameX = 0
        BM.db.mainFrameY = -200
        BM.MainFrame:ClearAllPoints()
        BM.MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end)

    -- Credits
    NextY(20)
    Header("关于 / About")
    InfoText("badomeow v" .. BM.VERSION .. " | MIT License")
    InfoText("灵感来源 Inspirations:")
    InfoText("  · WeakAuras2 (GPL v2) - 经典WA框架设计理念")
    InfoText("  · SenseiClassResourceBar (MIT) - 12.0资源条参考")
    InfoText("  · Arc UI - 组件化UI设计参考")

    Settings.RegisterAddOnCategory(category)
end

function BM.OpenSettings()
    if BM.settingsCategory then
        Settings.OpenToCategory(BM.settingsCategory)
    end
end
