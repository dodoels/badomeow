local addonName, FFS = ...
local L

local settingsRegistered = false

local function CreateOptionsPanel()
    L = FFS.L or {}

    local panel = CreateFrame("Frame", "ffsOptionsPanel", UIParent)
    panel.name = "ForFeralSake"
    panel:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 16)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 2800)
    scrollFrame:SetScrollChild(content)

    local yOff = -10

    local function NextY(h)
        local y = yOff
        yOff = yOff - (h or 30)
        return y
    end

    local function Spacer(h) NextY(h or 12) end

    local function Divider()
        local y = NextY(16)
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y - 6)
        line:SetSize(520, 1)
        line:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    end

    local function Header(text)
        Spacer(8)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 0, NextY(26))
        lbl:SetText(text)
        lbl:SetTextColor(0.4, 0.9, 0.4, 1)
        Spacer(4)
    end

    local function InfoText(text)
        local y = NextY(16)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetWidth(500)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(text)
        lbl:SetTextColor(0.65, 0.65, 0.65, 1)
    end

    local function Checkbox(labelText, dbKey)
        local y = NextY(28)
        local cb = CreateFrame("CheckButton", "ffsCB_" .. dbKey, content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        cb:SetSize(26, 26)
        local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        text:SetText(labelText)
        cb:SetChecked(FFS.db[dbKey] or false)
        cb:SetScript("OnClick", function(self)
            FFS.db[dbKey] = self:GetChecked() and true or false
            FFS.RefreshAll()
        end)
    end

    local function Slider(labelText, dbKey, minVal, maxVal, step, fmt)
        local y = NextY(50)
        fmt = fmt or "%.0f"
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local s = CreateFrame("Slider", "ffsSlider_" .. dbKey, content, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", content, "TOPLEFT", 200, y - 2)
        s:SetSize(200, 17)
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(step)
        s:SetObeyStepOnDrag(true)
        s:SetValue(FFS.db[dbKey] or minVal)
        s.Low:SetText(tostring(minVal))
        s.High:SetText(tostring(maxVal))

        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("TOP", s, "BOTTOM", 0, -2)
        valText:SetText(string.format(fmt, FFS.db[dbKey] or minVal))

        s:SetScript("OnValueChanged", function(self, v)
            FFS.db[dbKey] = v
            valText:SetText(string.format(fmt, v))
            FFS.RefreshAll()
        end)
    end

    local function Button(labelText, onClick)
        local y = NextY(34)
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        btn:SetSize(220, 26)
        btn:SetText(labelText)
        btn:SetScript("OnClick", onClick)
    end

    local popupMenu
    local function ShowPopupMenu(anchor, items)
        if popupMenu then popupMenu:Hide() end
        popupMenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        popupMenu:SetFrameStrata("TOOLTIP")
        popupMenu:SetClampedToScreen(true)
        popupMenu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        popupMenu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)

        local btnH = 18
        local maxH = math.min(#items * btnH + 8, 400)
        local menuW = 240

        local scroll = CreateFrame("ScrollFrame", nil, popupMenu, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 4, -4)
        scroll:SetPoint("BOTTOMRIGHT", -22, 4)

        local scrollChild = CreateFrame("Frame", nil, scroll)
        scrollChild:SetSize(menuW - 26, #items * btnH)
        scroll:SetScrollChild(scrollChild)

        for i, item in ipairs(items) do
            local row = CreateFrame("Button", nil, scrollChild)
            row:SetSize(menuW - 26, btnH)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * btnH)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

            local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            txt:SetPoint("LEFT", 4, 0)
            txt:SetText(item.text or "")
            if item.checked then txt:SetTextColor(0.3, 1, 0.3) end

            row:SetScript("OnClick", function()
                if item.func then item.func() end
                if popupMenu then popupMenu:Hide(); popupMenu = nil end
            end)
        end

        popupMenu:SetSize(menuW, maxH)
        popupMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
        popupMenu:Show()
        popupMenu:SetScript("OnHide", function(self) self:SetScript("OnHide", nil) end)
        C_Timer.After(0.05, function()
            if popupMenu then
                popupMenu:SetScript("OnUpdate", function(self)
                    if not MouseIsOver(self) and not MouseIsOver(anchor) then
                        self:Hide()
                        popupMenu = nil
                    end
                end)
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, NextY(28))
    title:SetText("至暗.八方.豹读诗书.哈基米要你命三千八 v" .. FFS.VERSION)
    title:SetTextColor(0.4, 0.9, 0.4, 1)
    InfoText("自动 hook 暴雪 CooldownViewer，各组件可自由拖动定位。")
    InfoText("打开设置时会显示所有已启用组件的位置预览。")

    Divider()

    ---------------------------------------------------------------------------
    -- General
    ---------------------------------------------------------------------------
    Header("常规设置")
    Checkbox("启用插件", "enabled")
    do
        local y = NextY(28)
        local cb = CreateFrame("CheckButton", "ffsCB_locked", content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        cb:SetSize(26, 26)
        local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        text:SetText("锁定所有组件")
        cb:SetChecked(FFS.db.locked)
        cb:SetScript("OnClick", function(self)
            if InCombatLockdown() then
                print("|cFFFF5555豹读诗书:|r 战斗中无法切换锁定")
                self:SetChecked(FFS.db.locked)
                return
            end
            FFS.db.locked = self:GetChecked() and true or false
            if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
        end)
    end
    InfoText("右键任意已解锁组件 = 快速锁定/解锁。Shift+拖动 = 整体移动。")
    Slider("整体缩放", "scale", 0.5, 2.0, 0.1, "%.1f")

    Spacer(4)
    InfoText("全局偏移 — 同时移动所有组件位置")
    do
        local lastGX = FFS.db.globalOffsetX or 0
        local lastGY = FFS.db.globalOffsetY or 0

        local function ApplyGlobalOffset(axis, newVal)
            local oldVal
            if axis == "x" then oldVal = lastGX else oldVal = lastGY end
            local delta = newVal - oldVal
            if delta == 0 then return end

            for _, sec in ipairs(FFS.SECTIONS) do
                local key = "pos_" .. sec
                local pos = FFS.db[key]
                if pos then
                    if axis == "x" then
                        pos.x = (pos.x or 0) + delta
                    else
                        pos.y = (pos.y or 0) + delta
                    end
                end
                local f = FFS.sectionFrames and FFS.sectionFrames[sec]
                if f and pos then
                    local pt = pos.point or "CENTER"
                    local rpt = pos.relPoint or "CENTER"
                    f:ClearAllPoints()
                    f:SetPoint(pt, UIParent, rpt, pos.x or 0, pos.y or 0)
                end
            end

            if FFS.db.overlays then
                for i, cfg in ipairs(FFS.db.overlays) do
                    if cfg then
                        if axis == "x" then
                            cfg.x = (cfg.x or 0) + delta
                        else
                            cfg.y = (cfg.y or 0) + delta
                        end
                        local f = FFS.overlayFrames and FFS.overlayFrames[i]
                        if f and cfg.enabled then
                            f:ClearAllPoints()
                            f:SetPoint(cfg.point or "CENTER", UIParent, cfg.relPoint or "CENTER", cfg.x or 0, cfg.y or 0)
                        end
                    end
                end
            end

            if axis == "x" then lastGX = newVal else lastGY = newVal end
        end

        local yGX = NextY(50)
        local lblGX = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lblGX:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yGX)
        lblGX:SetText("全局 X 偏移")

        local sGX = CreateFrame("Slider", "ffsSlider_globalOffsetX", content, "OptionsSliderTemplate")
        sGX:SetPoint("TOPLEFT", content, "TOPLEFT", 200, yGX - 2)
        sGX:SetSize(200, 17)
        sGX:SetMinMaxValues(-800, 800)
        sGX:SetValueStep(1)
        sGX:SetObeyStepOnDrag(true)
        sGX:SetValue(FFS.db.globalOffsetX or 0)
        sGX.Low:SetText("-800")
        sGX.High:SetText("800")
        local vGX = sGX:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vGX:SetPoint("TOP", sGX, "BOTTOM", 0, -2)
        vGX:SetText(tostring(FFS.db.globalOffsetX or 0))
        sGX:SetScript("OnValueChanged", function(self, v)
            v = math.floor(v + 0.5)
            FFS.db.globalOffsetX = v
            vGX:SetText(tostring(v))
            ApplyGlobalOffset("x", v)
        end)

        local yGY = NextY(50)
        local lblGY = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lblGY:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yGY)
        lblGY:SetText("全局 Y 偏移")

        local sGY = CreateFrame("Slider", "ffsSlider_globalOffsetY", content, "OptionsSliderTemplate")
        sGY:SetPoint("TOPLEFT", content, "TOPLEFT", 200, yGY - 2)
        sGY:SetSize(200, 17)
        sGY:SetMinMaxValues(-600, 600)
        sGY:SetValueStep(1)
        sGY:SetObeyStepOnDrag(true)
        sGY:SetValue(FFS.db.globalOffsetY or 0)
        sGY.Low:SetText("-600")
        sGY.High:SetText("600")
        local vGY = sGY:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vGY:SetPoint("TOP", sGY, "BOTTOM", 0, -2)
        vGY:SetText(tostring(FFS.db.globalOffsetY or 0))
        sGY:SetScript("OnValueChanged", function(self, v)
            v = math.floor(v + 0.5)
            FFS.db.globalOffsetY = v
            vGY:SetText(tostring(v))
            ApplyGlobalOffset("y", v)
        end)
    end

    Divider()

    ---------------------------------------------------------------------------
    -- Section toggles
    ---------------------------------------------------------------------------
    Header("组件开关")
    InfoText("开/关各组件。解锁后可分别拖动每个组件到任意位置。")
    Spacer(2)
    Checkbox("增益/触发 (Buff/Proc)", "showBuff")
    Checkbox("核心技能 (Essential)", "showEssential")
    Checkbox("工具技能 (Utility)", "showUtility")
    Checkbox("资源条 (Primary Bar)", "showPrimaryBar")
    Checkbox("连击点 (Combo Points)", "showSecondaryBar")
    Checkbox("蓝条 (Mana Bar)", "showManaBar")

    Divider()

    ---------------------------------------------------------------------------
    -- Masque
    ---------------------------------------------------------------------------
    Header("皮肤 / Masque")
    if LibStub and LibStub("Masque", true) then
        InfoText("检测到 Masque — 在 Masque 设置中选择 ForFeralSake 分组来更换皮肤。")
        do
            local y = NextY(28)
            local cb = CreateFrame("CheckButton", "ffsCB_useMasque", content, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
            cb:SetSize(26, 26)
            local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            text:SetText("启用 Masque 皮肤")
            cb:SetChecked(FFS.db.useMasque)
            cb:SetScript("OnClick", function(self)
                FFS.db.useMasque = self:GetChecked() and true or false
                if FFS.db.useMasque then
                    if FFS.ReskinMasque then FFS.ReskinMasque() end
                else
                    if FFS.RemoveAllMasque then FFS.RemoveAllMasque() end
                end
                FFS.RefreshAll()
            end)
        end
        InfoText("提示: 使用 /msq 打开 Masque 设置界面选择皮肤。")
    else
        InfoText("|cFF888888未检测到 Masque 插件 — 安装 Masque 后可使用自定义皮肤（如圆形图标）。|r")
    end

    Divider()

    ---------------------------------------------------------------------------
    -- Icon sizes
    ---------------------------------------------------------------------------
    Header("图标尺寸")
    InfoText("分别设置每个监控区域的图标大小和间距。")
    Spacer(2)
    Slider("核心技能图标", "essentialSize", 20, 60, 1)
    Slider("增益/触发图标", "buffSize", 16, 50, 1)
    Slider("工具技能图标", "utilitySize", 14, 44, 1)
    Slider("图标间距", "iconSpacing", 0, 10, 1)

    Divider()

    ---------------------------------------------------------------------------
    -- Resource bar
    ---------------------------------------------------------------------------
    Header("资源条样式")
    Slider("资源条宽度", "barWidth", 100, 500, 5)
    Slider("资源条高度", "barHeight", 8, 50, 1)
    Spacer(6)
    InfoText("连击点 (Combo Points) 尺寸")
    Slider("连击点宽度", "pipWidth", 60, 500, 5)
    Slider("连击点高度", "pipHeight", 4, 30, 1)
    Spacer(6)
    InfoText("蓝条 (Mana) — 变身时显示在主资源下方")
    Slider("蓝条宽度", "manaBarWidth", 60, 500, 5)
    Slider("蓝条高度", "manaBarHeight", 4, 30, 1)

    Spacer(8)
    InfoText("资源条材质 — 更改资源条的填充纹理")

    local function TextureDropdown(labelText, dbKey, texList)
        local y = NextY(34)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
        lbl:SetText(labelText)

        local btn = CreateFrame("Button", "ffsTexDrop_" .. dbKey, content, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 200, y)
        btn:SetSize(200, 22)

        local function UpdateLabel()
            local id = FFS.db[dbKey] or "default"
            for _, t in ipairs(texList) do
                if t.id == id then btn:SetText(t.name); return end
            end
            btn:SetText(id)
        end
        UpdateLabel()

        btn:SetScript("OnClick", function(self)
            local menu = {}
            for _, t in ipairs(texList) do
                menu[#menu + 1] = {
                    text = t.name,
                    checked = (FFS.db[dbKey] == t.id),
                    func = function()
                        FFS.db[dbKey] = t.id
                        UpdateLabel()
                        FFS.RefreshAll()
                    end,
                }
            end
            ShowPopupMenu(self, menu)
        end)
    end

    TextureDropdown("资源条填充", "barTexture", FFS.BarTextureList or {})
    TextureDropdown("资源条背景", "barBgTexture", FFS.BarTextureList or {})
    TextureDropdown("蓝条填充", "manaBarTexture", FFS.BarTextureList or {})
    TextureDropdown("蓝条背景", "manaBgTexture", FFS.BarTextureList or {})

    Divider()

    ---------------------------------------------------------------------------
    -- Texture Overlays
    ---------------------------------------------------------------------------
    Header("贴图面板 / Texture Overlays")
    InfoText("在屏幕上放置自定义贴图面板作为背景或装饰。")
    InfoText("将 .tga 或 .blp 文件放入 Interface\\AddOns\\ForFeralSake\\Textures\\")
    InfoText("然后在下方注册并配置。解锁后可拖动贴图面板。")

    for i = 1, (FFS.MAX_OVERLAYS or 5) do
        Spacer(4)
        local overlayLabel = "贴图 #" .. i
        do
            local idx = i
            local y = NextY(28)
            local cb = CreateFrame("CheckButton", "ffsCB_overlay" .. idx, content, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
            cb:SetSize(26, 26)
            local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            text:SetText(overlayLabel)

            local function GetCfg()
                if not FFS.db.overlays then FFS.db.overlays = {} end
                if not FFS.db.overlays[idx] then FFS.db.overlays[idx] = { enabled = false } end
                return FFS.db.overlays[idx]
            end

            cb:SetChecked(GetCfg().enabled or false)
            cb:SetScript("OnClick", function(self)
                GetCfg().enabled = self:GetChecked() and true or false
                FFS.RefreshOverlays()
            end)

            -- Texture picker dropdown
            local yPick = NextY(28)
            local pickLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pickLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 40, yPick)
            pickLabel:SetText("素材:")

            local pickBtn = CreateFrame("Button", "ffsOvPick" .. idx, content, "UIPanelButtonTemplate")
            pickBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 80, yPick)
            pickBtn:SetSize(200, 20)

            local pathBox = CreateFrame("EditBox", "ffsOverlayPath" .. idx, content, "InputBoxTemplate")

            local function UpdatePickLabel()
                local curPath = GetCfg().texturePath or ""
                if curPath == "" then
                    pickBtn:SetText("选择素材...")
                else
                    local found = false
                    for _, t in ipairs(FFS.TextureList or {}) do
                        if t.path == curPath then
                            pickBtn:SetText(t.name)
                            found = true
                            break
                        end
                    end
                    if not found then
                        local short = curPath:match("([^\\]+)$") or curPath
                        pickBtn:SetText(short)
                    end
                end
                pathBox:SetText(curPath)
            end
            UpdatePickLabel()

            pickBtn:SetScript("OnClick", function(self)
                local menu = {}
                menu[#menu + 1] = {
                    text = "无 / None",
                    func = function()
                        GetCfg().texturePath = ""
                        UpdatePickLabel()
                        FFS.RefreshOverlays()
                    end,
                }
                for _, t in ipairs(FFS.TextureList or {}) do
                    if t.path and t.path ~= "" then
                        menu[#menu + 1] = {
                            text = t.name,
                            checked = (GetCfg().texturePath == t.path),
                            func = function()
                                GetCfg().texturePath = t.path
                                UpdatePickLabel()
                                FFS.RefreshOverlays()
                            end,
                        }
                    end
                end
                ShowPopupMenu(self, menu)
            end)

            -- Manual path input (power user)
            local yPath = NextY(24)
            local pathLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pathLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 40, yPath)
            pathLabel:SetText("路径:")

            pathBox:SetParent(content)
            pathBox:SetPoint("TOPLEFT", content, "TOPLEFT", 80, yPath + 2)
            pathBox:SetSize(330, 18)
            pathBox:SetAutoFocus(false)
            pathBox:SetText(GetCfg().texturePath or "")
            pathBox:SetScript("OnEnterPressed", function(self)
                GetCfg().texturePath = self:GetText()
                self:ClearFocus()
                UpdatePickLabel()
                FFS.RefreshOverlays()
            end)
            pathBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

            -- Size sliders (compact inline)
            local ySize = NextY(30)
            local wLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            wLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 40, ySize)
            wLabel:SetText("宽:")

            local wBox = CreateFrame("EditBox", "ffsOvW" .. idx, content, "InputBoxTemplate")
            wBox:SetPoint("TOPLEFT", content, "TOPLEFT", 60, ySize + 2)
            wBox:SetSize(50, 18)
            wBox:SetAutoFocus(false)
            wBox:SetText(tostring(GetCfg().width or 300))
            wBox:SetScript("OnEnterPressed", function(self)
                GetCfg().width = tonumber(self:GetText()) or 300
                self:ClearFocus()
                FFS.RefreshOverlays()
            end)
            wBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

            local hLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            hLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 120, ySize)
            hLabel:SetText("高:")

            local hBox = CreateFrame("EditBox", "ffsOvH" .. idx, content, "InputBoxTemplate")
            hBox:SetPoint("TOPLEFT", content, "TOPLEFT", 140, ySize + 2)
            hBox:SetSize(50, 18)
            hBox:SetAutoFocus(false)
            hBox:SetText(tostring(GetCfg().height or 50))
            hBox:SetScript("OnEnterPressed", function(self)
                GetCfg().height = tonumber(self:GetText()) or 50
                self:ClearFocus()
                FFS.RefreshOverlays()
            end)
            hBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

            local aLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            aLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 200, ySize)
            aLabel:SetText("透明度:")

            local aBox = CreateFrame("EditBox", "ffsOvA" .. idx, content, "InputBoxTemplate")
            aBox:SetPoint("TOPLEFT", content, "TOPLEFT", 250, ySize + 2)
            aBox:SetSize(50, 18)
            aBox:SetAutoFocus(false)
            aBox:SetText(tostring(GetCfg().alpha or 0.8))
            aBox:SetScript("OnEnterPressed", function(self)
                GetCfg().alpha = tonumber(self:GetText()) or 0.8
                self:ClearFocus()
                FFS.RefreshOverlays()
            end)
            aBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        end
    end

    InfoText("路径格式: Interface\\AddOns\\ForFeralSake\\Textures\\your_image.tga")
    InfoText("也可以输入游戏内置路径如 Interface\\Tooltips\\UI-Tooltip-Background")

    Divider()

    ---------------------------------------------------------------------------
    -- Actions
    ---------------------------------------------------------------------------
    Header("操作")

    local function SyncLockedCheckbox()
        local cb = _G["ffsCB_locked"]
        if cb then cb:SetChecked(FFS.db.locked) end
    end

    Button("解锁所有组件 (拖动定位)", function()
        if InCombatLockdown() then
            print("|cFFFF5555豹读诗书:|r 战斗中无法解锁"); return
        end
        FFS.db.locked = false
        SyncLockedCheckbox()
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
        print("|cFF00FF00豹读诗书:|r 已解锁，拖动各组件到想要的位置。Shift+拖动=整体移动。右键=快速锁定/解锁。")
    end)

    Button("锁定所有组件", function()
        FFS.db.locked = true
        SyncLockedCheckbox()
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
        print("|cFF00FF00豹读诗书:|r 已锁定")
    end)

    Button("重置所有位置", function()
        if FFS.ResetAllPositions then FFS.ResetAllPositions() end
        print("|cFF00FF00豹读诗书:|r 所有组件位置已重置")
    end)

    Divider()

    ---------------------------------------------------------------------------
    -- About
    ---------------------------------------------------------------------------
    Header("命令列表")
    InfoText("/ffs — 打开此设置面板")
    InfoText("/ffs lock — 锁定所有组件")
    InfoText("/ffs unlock — 解锁所有组件（可拖动）")
    InfoText("/ffs reset — 重置所有组件位置到默认")
    InfoText("/ffs debug — 打印 CooldownViewer 状态（调试用）")
    Spacer(4)
    InfoText("别名: /forferalsake")
    Spacer(4)
    InfoText("解锁后操作:")
    InfoText("  左键拖动 — 移动单个组件")
    InfoText("  Shift + 左键拖动 — 整体移动所有组件")
    InfoText("  右键点击任意组件 — 快速切换锁定/解锁")
    InfoText("  全局 X/Y 偏移滑块 — 精确移动所有组件")

    Divider()

    Header("关于")
    InfoText("至暗.八方.豹读诗书.哈基米要你命三千八 v" .. FFS.VERSION .. " | MIT License")
    InfoText("本插件由 BILIBILI@SOSO财高八抖 四处搜刮纯AI沥尽心血毫无原创打造而成")
    InfoText("基于暴雪 CooldownViewer 系统，自动同步所有职业/专精技能数据")
    InfoText("支持 Masque 皮肤 — 安装 Masque 及皮肤包后可自定义图标外观（圆形、方形等）")
    Spacer(6)
    InfoText("|cFFFFD100致谢 / Credits:|r")
    InfoText("  Ayije_CDM — 作者: Ayije | CooldownViewer hook 核心参考")
    InfoText("  WeakAuras2 — 作者: Buds, Infus, Rivers, Stanzilla 及社区 | GPL v2")
    InfoText("  SenseiClassResourceBar — 作者: Snsei987 | MIT")
    InfoText("  Arc UI — 作者: devdeadviz | 模块化 UI 设计参考")
    InfoText("  Masque — 作者: StormFX | 图标皮肤引擎")

    ---------------------------------------------------------------------------
    -- Show/hide preview when settings panel opens/closes
    ---------------------------------------------------------------------------
    panel:HookScript("OnShow", function()
        FFS.settingsOpen = true
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
        FFS.UpdateVisibility()
    end)
    panel:HookScript("OnHide", function()
        FFS.settingsOpen = false
        if FFS.UpdateSectionLockState then FFS.UpdateSectionLockState() end
    end)

    return panel
end

function FFS.InitSettings()
    if settingsRegistered then return end
    settingsRegistered = true

    L = FFS.L or {}
    local panel = CreateOptionsPanel()

    if SettingsPanel then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ForFeralSake")
        Settings.RegisterAddOnCategory(category)
        FFS.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    FFS.optionsPanel = panel
end

function FFS.OpenSettings()
    if FFS.settingsCategory then
        Settings.OpenToCategory(FFS.settingsCategory.ID)
        return
    end
    if FFS.optionsPanel and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(FFS.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(FFS.optionsPanel)
    end
end
