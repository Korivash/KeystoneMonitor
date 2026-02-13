local _, ns = ...

local DEFAULT_X = 0
local DEFAULT_Y = 120

local COLOR_KEYS = {
    { key = "accentColor", label = "Accent", fallback = "53B9FFFF" },
    { key = "backgroundColor", label = "Background", fallback = "0D0D0DC7" },
    { key = "borderColor", label = "Border", fallback = "333333F2" },
    { key = "textColor", label = "Text", fallback = "F2F2F2FF" },
    { key = "timerColor", label = "Timer", fallback = "FFFFFFFF" },
    { key = "forcesBarColor", label = "Forces Bar", fallback = "53B9FFFF" },
    { key = "forcesBarBGColor", label = "Forces Bar BG", fallback = "212121E6" },
}

local FONT_OPTIONS = {
    { key = "FRIZQT", name = "Friz Quadrata" },
    { key = "ARIALN", name = "Arial Narrow" },
    { key = "MORPHEUS", name = "Morpheus" },
    { key = "SKURRI", name = "Skurri" },
}

local PREVIEW_SCENARIO_OPTIONS = {
    { key = "LIVE", name = "Live Data" },
    { key = "IN_PROGRESS", name = "Simulated In-Progress" },
    { key = "FLOODGATE_COMPLETED", name = "Floodgate Completed" },
}

local PRESET_OPTIONS = {
    {
        key = "KEYSTONE",
        name = "Keystone Monitor Default",
        scale = 1.0,
        alpha = 1.0,
        appearance = {
            useClassColor = true,
            frameWidth = 350,
            frameHeight = 248,
            fontScale = 1.0,
            titleFont = "FRIZQT",
            timerFont = "ARIALN",
            bodyFont = "FRIZQT",
            accentColor = "53B9FFFF",
            backgroundColor = "0D0D0DC7",
            borderColor = "333333F2",
            textColor = "F2F2F2FF",
            timerColor = "FFFFFFFF",
            forcesBarColor = "53B9FFFF",
            forcesBarBGColor = "212121E6",
        },
    },
    {
        key = "RAIDER",
        name = "Raider Steel",
        scale = 1.04,
        alpha = 1.0,
        appearance = {
            useClassColor = false,
            frameWidth = 390,
            frameHeight = 268,
            fontScale = 1.02,
            titleFont = "FRIZQT",
            timerFont = "ARIALN",
            bodyFont = "ARIALN",
            accentColor = "4AA3FFFF",
            backgroundColor = "10151CD9",
            borderColor = "2D3C4EE6",
            textColor = "EDF4FFFF",
            timerColor = "EAF5FFFF",
            forcesBarColor = "42B7FFFF",
            forcesBarBGColor = "1A2633E6",
        },
    },
    {
        key = "NEON",
        name = "Neon Pulse",
        scale = 1.06,
        alpha = 1.0,
        appearance = {
            useClassColor = false,
            frameWidth = 410,
            frameHeight = 272,
            fontScale = 1.05,
            titleFont = "MORPHEUS",
            timerFont = "ARIALN",
            bodyFont = "FRIZQT",
            accentColor = "4EFCE0FF",
            backgroundColor = "0B131CCC",
            borderColor = "2BD3C2FF",
            textColor = "E8FFFFFF",
            timerColor = "6DF9E8FF",
            forcesBarColor = "00F7D7FF",
            forcesBarBGColor = "0D2A33E0",
        },
    },
    {
        key = "MINIMAL",
        name = "Minimal Clean",
        scale = 0.95,
        alpha = 0.96,
        appearance = {
            useClassColor = false,
            frameWidth = 330,
            frameHeight = 228,
            fontScale = 0.92,
            titleFont = "ARIALN",
            timerFont = "ARIALN",
            bodyFont = "ARIALN",
            accentColor = "E2E2E2FF",
            backgroundColor = "111111BF",
            borderColor = "3A3A3AD9",
            textColor = "EDEDEDFF",
            timerColor = "FFFFFFFF",
            forcesBarColor = "C8C8C8FF",
            forcesBarBGColor = "2A2A2AE0",
        },
    },
}

local EXPORT_FIELDS = {
    "locked",
    "showWhenUnlocked",
    "showBestTimedComparison",
    "showPaceHints",
    "previewScenario",
    "useFloodgateCompletedPreview",
    "scale",
    "alpha",
    "useClassColor",
    "frameWidth",
    "frameHeight",
    "fontScale",
    "titleFont",
    "timerFont",
    "bodyFont",
    "accentColor",
    "backgroundColor",
    "borderColor",
    "textColor",
    "timerColor",
    "forcesBarColor",
    "forcesBarBGColor",
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function clamp01(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function rgbaToHex(r, g, b, a)
    local rr = math.floor(clamp01(r or 1) * 255 + 0.5)
    local gg = math.floor(clamp01(g or 1) * 255 + 0.5)
    local bb = math.floor(clamp01(b or 1) * 255 + 0.5)
    local aa = math.floor(clamp01(a == nil and 1 or a) * 255 + 0.5)
    return string.format("%02X%02X%02X%02X", rr, gg, bb, aa)
end

local function label(parent, text, template, point, relTo, relPoint, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetPoint(point, relTo, relPoint, x or 0, y or 0)
    fs:SetText(text or "")
    return fs
end

local function section(parent, title, point, relTo, relPoint, x, y, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint(point, relTo, relPoint, x, y)
    frame:SetSize(width, height)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.08, 0.10, 0.13, 0.96)
    frame:SetBackdropBorderColor(0.19, 0.23, 0.28, 1)
    local titleFS = label(frame, title, "GameFontNormal", "TOPLEFT", frame, "TOPLEFT", 10, -9)
    titleFS:SetTextColor(0.76, 0.86, 0.98)
    return frame
end

local function styleButton(button, normal, hover, border)
    button:SetNormalFontObject("GameFontHighlight")
    button:SetHighlightFontObject("GameFontHighlight")
    button:SetPushedTextOffset(0, -1)

    button._bg = button:CreateTexture(nil, "BACKGROUND")
    button._bg:SetAllPoints()
    button._bg:SetColorTexture(normal[1], normal[2], normal[3], normal[4])

    button._border = button:CreateTexture(nil, "BORDER")
    button._border:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    button._border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button._border:SetColorTexture(border[1], border[2], border[3], border[4])

    button:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
    end)
    button:SetScript("OnLeave", function(self)
        self._bg:SetColorTexture(normal[1], normal[2], normal[3], normal[4])
    end)
end

local function styleSlider(slider, titleText, minValue, maxValue)
    slider:SetOrientation("HORIZONTAL")
    slider:SetObeyStepOnDrag(true)

    slider.track = slider:CreateTexture(nil, "BACKGROUND")
    slider.track:SetPoint("TOPLEFT", slider, "TOPLEFT", 0, -7)
    slider.track:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", 0, 7)
    slider.track:SetColorTexture(0.10, 0.12, 0.16, 0.9)

    slider.edge = slider:CreateTexture(nil, "BORDER")
    slider.edge:SetPoint("TOPLEFT", slider.track, "TOPLEFT", -1, 1)
    slider.edge:SetPoint("BOTTOMRIGHT", slider.track, "BOTTOMRIGHT", 1, -1)
    slider.edge:SetColorTexture(0.20, 0.24, 0.29, 1)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetVertexColor(0.33, 0.73, 1.00, 0.95)
    end

    slider.title = label(slider, titleText, "GameFontNormal", "BOTTOMLEFT", slider, "TOPLEFT", 0, 7)
    slider.value = label(slider, "", "GameFontHighlightSmall", "BOTTOMRIGHT", slider, "TOPRIGHT", 0, 7)
    slider.min = label(slider, string.format("%.2f", minValue), "GameFontDisableSmall", "TOPLEFT", slider, "BOTTOMLEFT", 0, -7)
    slider.max = label(slider, string.format("%.2f", maxValue), "GameFontDisableSmall", "TOPRIGHT", slider, "BOTTOMRIGHT", 0, -7)
end

local function makeHexRow(parent, text, point, relTo, relPoint, x, y)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint(point, relTo, relPoint, x, y)
    row:SetSize(340, 24)

    local name = label(row, text, "GameFontNormalSmall", "LEFT", row, "LEFT", 0, 0)
    name:SetTextColor(0.93, 0.95, 0.99)

    local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    input:SetSize(120, 20)
    input:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    input:SetAutoFocus(false)
    input:SetMaxLetters(9)
    input:SetTextInsets(6, 6, 0, 0)
    input:SetJustifyH("LEFT")

    local hash = label(row, "#", "GameFontHighlight", "RIGHT", input, "LEFT", -4, 0)
    hash:SetTextColor(0.67, 0.76, 0.86)

    local preview = row:CreateTexture(nil, "ARTWORK")
    preview:SetSize(12, 12)
    preview:SetPoint("RIGHT", hash, "LEFT", -8, 0)
    preview:SetColorTexture(1, 1, 1, 1)

    local swatchButton = CreateFrame("Button", nil, row)
    swatchButton:SetSize(18, 18)
    swatchButton:SetPoint("CENTER", preview, "CENTER", 0, 0)
    swatchButton:SetNormalTexture("")
    swatchButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    row.input = input
    row.preview = preview
    row.swatchButton = swatchButton
    return row
end

local function makeInput(parent, width, point, relTo, relPoint, x, y)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, 20)
    edit:SetPoint(point, relTo, relPoint, x, y)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(1024)
    edit:SetTextInsets(6, 6, 0, 0)
    edit:SetJustifyH("LEFT")
    return edit
end

local function dropdownSetValue(dropdown, options, key)
    for i = 1, #options do
        local opt = options[i]
        if opt.key == key then
            UIDropDownMenu_SetSelectedValue(dropdown, key)
            UIDropDownMenu_SetText(dropdown, opt.name)
            return
        end
    end
    UIDropDownMenu_SetSelectedValue(dropdown, options[1].key)
    UIDropDownMenu_SetText(dropdown, options[1].name)
end

local function makeDropdown(parent, text, options, point, relTo, relPoint, x, y, onSelect)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint(point, relTo, relPoint, x, y)
    holder:SetSize(330, 44)

    local title = label(holder, text, "GameFontNormalSmall", "TOPLEFT", holder, "TOPLEFT", 0, 0)
    title:SetTextColor(0.93, 0.95, 0.99)

    local dropdown = CreateFrame("Frame", nil, holder, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", holder, "TOPLEFT", -16, -14)
    UIDropDownMenu_SetWidth(dropdown, 178)
    UIDropDownMenu_SetText(dropdown, "")
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        if level ~= 1 then
            return
        end
        for i = 1, #options do
            local opt = options[i]
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.name
            info.value = opt.key
            info.func = function()
                dropdownSetValue(dropdown, options, opt.key)
                onSelect(opt.key)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    holder.dropdown = dropdown
    return holder
end

local function updateColorPreview(frame, key, value)
    if not frame or not frame.colorRows or not frame.colorRows[key] then
        return
    end
    local row = frame.colorRows[key]
    local r, g, b, a = ns:HexToRGBA(value, 1, 1, 1, 1)
    row.preview:SetColorTexture(r, g, b, a)
end

local function applyColorsFromInputs(frame)
    local appearance = ns.db.profile.appearance
    for i = 1, #COLOR_KEYS do
        local entry = COLOR_KEYS[i]
        local row = frame.colorRows[entry.key]
        local clean = ns:NormalizeHexColor(row.input:GetText(), entry.fallback)
        row.input:SetText(clean)
        appearance[entry.key] = clean
        updateColorPreview(frame, entry.key, clean)
    end
    ns:ApplyTheme()
end

local function buildExportString()
    local profile = ns.db.profile
    local appearance = profile.appearance
    local values = {
        locked = profile.locked and "1" or "0",
        showWhenUnlocked = profile.showWhenUnlocked and "1" or "0",
        showBestTimedComparison = profile.showBestTimedComparison and "1" or "0",
        showPaceHints = profile.showPaceHints and "1" or "0",
        previewScenario = tostring(profile.previewScenario or "LIVE"),
        useFloodgateCompletedPreview = ((profile.previewScenario or "LIVE") == "FLOODGATE_COMPLETED") and "1" or "0",
        scale = string.format("%.2f", profile.scale or 1),
        alpha = string.format("%.2f", profile.alpha or 1),
        useClassColor = appearance.useClassColor and "1" or "0",
        frameWidth = tostring(appearance.frameWidth or 350),
        frameHeight = tostring(appearance.frameHeight or 248),
        fontScale = string.format("%.2f", appearance.fontScale or 1),
        titleFont = tostring(appearance.titleFont or "FRIZQT"),
        timerFont = tostring(appearance.timerFont or "ARIALN"),
        bodyFont = tostring(appearance.bodyFont or "FRIZQT"),
        accentColor = tostring(appearance.accentColor or "53B9FFFF"),
        backgroundColor = tostring(appearance.backgroundColor or "0D0D0DC7"),
        borderColor = tostring(appearance.borderColor or "333333F2"),
        textColor = tostring(appearance.textColor or "F2F2F2FF"),
        timerColor = tostring(appearance.timerColor or "FFFFFFFF"),
        forcesBarColor = tostring(appearance.forcesBarColor or "53B9FFFF"),
        forcesBarBGColor = tostring(appearance.forcesBarBGColor or "212121E6"),
    }

    local parts = {}
    for i = 1, #EXPORT_FIELDS do
        local key = EXPORT_FIELDS[i]
        parts[#parts + 1] = key .. "=" .. values[key]
    end
    return "MMP1|" .. table.concat(parts, ";")
end

local function findFontKey(input)
    for i = 1, #FONT_OPTIONS do
        if FONT_OPTIONS[i].key == input then
            return input
        end
    end
    return nil
end

local function applyImportString(serialized)
    local text = ns:Trim(serialized or "")
    if text == "" then
        return false, "Import string is empty."
    end
    if not text:find("^MMP1|") then
        return false, "Invalid import header."
    end

    local body = text:sub(6)
    local map = {}
    for pair in body:gmatch("[^;]+") do
        local key, value = pair:match("^([^=]+)=(.*)$")
        if key and value then
            map[key] = value
        end
    end

    local profile = ns.db.profile
    local appearance = profile.appearance

    if map.locked then
        profile.locked = map.locked == "1"
    end
    if map.showWhenUnlocked then
        profile.showWhenUnlocked = map.showWhenUnlocked ~= "0"
    end
    if map.showBestTimedComparison then
        profile.showBestTimedComparison = map.showBestTimedComparison ~= "0"
    end
    if map.showPaceHints then
        profile.showPaceHints = map.showPaceHints ~= "0"
    end
    if map.previewScenario then
        if map.previewScenario == "LIVE" or map.previewScenario == "IN_PROGRESS" or map.previewScenario == "FLOODGATE_COMPLETED" then
            profile.previewScenario = map.previewScenario
        end
    end
    if map.useFloodgateCompletedPreview then
        if map.useFloodgateCompletedPreview == "1" then
            profile.previewScenario = "FLOODGATE_COMPLETED"
        end
    end
    if map.scale then
        profile.scale = clamp(tonumber(map.scale) or profile.scale or 1, 0.70, 1.80)
    end
    if map.alpha then
        profile.alpha = clamp(tonumber(map.alpha) or profile.alpha or 1, 0.00, 1.00)
    end
    if map.useClassColor then
        appearance.useClassColor = map.useClassColor == "1"
    end
    if map.frameWidth then
        appearance.frameWidth = math.floor(clamp(tonumber(map.frameWidth) or appearance.frameWidth or 350, 280, 760) + 0.5)
    end
    if map.frameHeight then
        appearance.frameHeight = math.floor(clamp(tonumber(map.frameHeight) or appearance.frameHeight or 248, 200, 520) + 0.5)
    end
    if map.fontScale then
        appearance.fontScale = clamp(tonumber(map.fontScale) or appearance.fontScale or 1, 0.70, 1.60)
    end
    if map.titleFont then
        appearance.titleFont = findFontKey(map.titleFont) or appearance.titleFont or "FRIZQT"
    end
    if map.timerFont then
        appearance.timerFont = findFontKey(map.timerFont) or appearance.timerFont or "ARIALN"
    end
    if map.bodyFont then
        appearance.bodyFont = findFontKey(map.bodyFont) or appearance.bodyFont or "FRIZQT"
    end

    for i = 1, #COLOR_KEYS do
        local entry = COLOR_KEYS[i]
        if map[entry.key] then
            appearance[entry.key] = ns:NormalizeHexColor(map[entry.key], entry.fallback)
        end
    end

    ns:ApplyFrameSettings()
    return true, "Profile imported."
end

local function applyPreset(presetKey)
    local selected = nil
    for i = 1, #PRESET_OPTIONS do
        if PRESET_OPTIONS[i].key == presetKey then
            selected = PRESET_OPTIONS[i]
            break
        end
    end
    if not selected then
        return
    end

    local profile = ns.db.profile
    local appearance = profile.appearance
    local presetAppearance = selected.appearance

    profile.scale = selected.scale or profile.scale
    profile.alpha = selected.alpha or profile.alpha

    appearance.useClassColor = presetAppearance.useClassColor and true or false
    appearance.frameWidth = presetAppearance.frameWidth
    appearance.frameHeight = presetAppearance.frameHeight
    appearance.fontScale = presetAppearance.fontScale
    appearance.titleFont = presetAppearance.titleFont
    appearance.timerFont = presetAppearance.timerFont
    appearance.bodyFont = presetAppearance.bodyFont
    appearance.accentColor = presetAppearance.accentColor
    appearance.backgroundColor = presetAppearance.backgroundColor
    appearance.borderColor = presetAppearance.borderColor
    appearance.textColor = presetAppearance.textColor
    appearance.timerColor = presetAppearance.timerColor
    appearance.forcesBarColor = presetAppearance.forcesBarColor
    appearance.forcesBarBGColor = presetAppearance.forcesBarBGColor

    ns:ApplyFrameSettings()
    ns:RefreshOptionsUI()
    ns:Print("Applied preset: " .. selected.name)
end

local function openColorPickerForKey(frame, key, fallback)
    local row = frame.colorRows[key]
    if not row then
        return
    end

    local initialHex = ns:NormalizeHexColor(row.input:GetText(), fallback)
    local startR, startG, startB, startA = ns:HexToRGBA(initialHex, 1, 1, 1, 1)
    local previousHex = initialHex

    local function applyColor(r, g, b, a)
        local hex = rgbaToHex(r, g, b, a)
        row.input:SetText(hex)
        ns.db.profile.appearance[key] = hex
        updateColorPreview(frame, key, hex)
        ns:ApplyTheme()
    end

    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        local pickerInfo = {
            r = startR,
            g = startG,
            b = startB,
            opacity = 1 - startA,
            hasOpacity = true,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
                applyColor(r, g, b, a)
            end,
            opacityFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
                applyColor(r, g, b, a)
            end,
            cancelFunc = function()
                row.input:SetText(previousHex)
                ns.db.profile.appearance[key] = previousHex
                updateColorPreview(frame, key, previousHex)
                ns:ApplyTheme()
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(pickerInfo)
        return
    end

    if not ColorPickerFrame then
        return
    end

    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - startA
    ColorPickerFrame.previousValues = { startR, startG, startB, startA }
    ColorPickerFrame:SetColorRGB(startR, startG, startB)
    ColorPickerFrame.func = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
        applyColor(r, g, b, a)
    end
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.cancelFunc = function(previous)
        local r = previous and previous.r or startR
        local g = previous and previous.g or startG
        local b = previous and previous.b or startB
        local a = previous and (1 - (previous.opacity or (1 - startA))) or startA
        row.input:SetText(rgbaToHex(r, g, b, a))
        ns.db.profile.appearance[key] = row.input:GetText()
        updateColorPreview(frame, key, row.input:GetText())
        ns:ApplyTheme()
    end
    ColorPickerFrame:Show()
end

function ns:RefreshOptionsUI()
    if not self.ui.options then
        return
    end

    local frame = self.ui.options
    local profile = self.db.profile
    local appearance = profile.appearance

    frame.lockCheck:SetChecked(profile.locked and true or false)
    frame.showUnlockedCheck:SetChecked(profile.showWhenUnlocked and true or false)
    frame.showBestTimedComparisonCheck:SetChecked(profile.showBestTimedComparison and true or false)
    frame.showPaceHintsCheck:SetChecked(profile.showPaceHints and true or false)
    frame.useClassColorCheck:SetChecked(appearance.useClassColor and true or false)
    dropdownSetValue(frame.previewScenarioDrop.dropdown, PREVIEW_SCENARIO_OPTIONS, profile.previewScenario or "LIVE")

    frame.widthSlider:SetValue(appearance.frameWidth or 350)
    frame.heightSlider:SetValue(appearance.frameHeight or 248)
    frame.scaleSlider:SetValue(profile.scale or 1)
    frame.alphaSlider:SetValue(profile.alpha or 1)
    frame.fontScaleSlider:SetValue(appearance.fontScale or 1)

    dropdownSetValue(frame.titleFontDrop.dropdown, FONT_OPTIONS, appearance.titleFont or "FRIZQT")
    dropdownSetValue(frame.timerFontDrop.dropdown, FONT_OPTIONS, appearance.timerFont or "ARIALN")
    dropdownSetValue(frame.bodyFontDrop.dropdown, FONT_OPTIONS, appearance.bodyFont or "FRIZQT")
    dropdownSetValue(frame.presetDrop.dropdown, PRESET_OPTIONS, "KEYSTONE")

    for i = 1, #COLOR_KEYS do
        local entry = COLOR_KEYS[i]
        local row = frame.colorRows[entry.key]
        local value = ns:NormalizeHexColor(appearance[entry.key], entry.fallback)
        row.input:SetText(value)
        updateColorPreview(frame, entry.key, value)
    end

    frame.exportBox:SetText(buildExportString())
end

function ns:ToggleOptionsUI()
    if not self.ui.options then
        return
    end

    if self.ui.options:IsShown() then
        self.ui.options:Hide()
    else
        self:RefreshOptionsUI()
        self.ui.options:Show()
    end
end

function ns:BuildOptionsUI()
    local frame = CreateFrame("Frame", "KeystoneMonitorOptionsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(940, 920)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
    end)
    frame:SetScript("OnShow", function()
        ns.ui.previewMode = true
        ns:RefreshVisibility()
        ns:Render()
    end)
    frame:SetScript("OnHide", function()
        ns.ui.previewMode = false
        ns:RefreshVisibility()
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.04, 0.05, 0.07, 0.97)
    frame:SetBackdropBorderColor(0.17, 0.20, 0.25, 1)
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    header:SetHeight(72)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    header:SetBackdropColor(0.07, 0.10, 0.14, 1)

    local accent = header:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetColorTexture(0.33, 0.73, 1.00, 0.95)

    label(header, "Keystone Monitor UI STUDIO", "GameFontNormalLarge", "TOP", header, "TOP", 0, -12)
    local sub = label(header, "Profiles, presets, and deep skinning", "GameFontHighlightSmall", "TOP", header, "TOP", 0, -31)
    sub:SetTextColor(0.67, 0.76, 0.86)

    local colWidth = 448
    local gutter = 20
    local topOffset = -18

    local behavior = section(frame, "Behavior", "TOPLEFT", header, "BOTTOMLEFT", 12, topOffset, colWidth, 280)
    local layout = section(frame, "Layout & Sizing", "TOPRIGHT", header, "BOTTOMRIGHT", -12, topOffset, colWidth, 320)
    local fonts = section(frame, "Per-Element Fonts", "TOPLEFT", behavior, "BOTTOMLEFT", 0, -12, colWidth, 168)
    local actions = section(frame, "Actions", "BOTTOM", frame, "BOTTOM", 0, 12, (colWidth * 2) + gutter, 92)

    local profiles = section(frame, "Presets & Profile Import/Export", "TOPLEFT", fonts, "BOTTOMLEFT", 0, -12, colWidth, 200)
    profiles:ClearAllPoints()
    profiles:SetPoint("TOPLEFT", fonts, "BOTTOMLEFT", 0, -12)
    profiles:SetPoint("BOTTOMLEFT", actions, "TOPLEFT", 0, 12)
    profiles:SetWidth(colWidth)

    local colors = section(frame, "Hex Skin Colors (RRGGBB or RRGGBBAA)", "TOPRIGHT", layout, "BOTTOMRIGHT", 0, -12, colWidth, 200)
    colors:ClearAllPoints()
    colors:SetPoint("TOPRIGHT", layout, "BOTTOMRIGHT", 0, -12)
    colors:SetPoint("BOTTOMRIGHT", actions, "TOPRIGHT", 0, 12)
    colors:SetWidth(colWidth)

    local lockCheck = CreateFrame("CheckButton", nil, behavior, "ChatConfigCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", behavior, "TOPLEFT", 12, -30)
    lockCheck.Text:SetText("Lock tracker position")
    lockCheck:SetScript("OnClick", function(button)
        ns.db.profile.locked = button:GetChecked() and true or false
        ns:RefreshVisibility()
        ns:Render()
    end)

    local showUnlockedCheck = CreateFrame("CheckButton", nil, behavior, "ChatConfigCheckButtonTemplate")
    showUnlockedCheck:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 0, -10)
    showUnlockedCheck.Text:SetText("Show tracker while unlocked")
    showUnlockedCheck:SetScript("OnClick", function(button)
        ns.db.profile.showWhenUnlocked = button:GetChecked() and true or false
        ns:RefreshVisibility()
        ns:Render()
    end)

    local showBestTimedComparisonCheck = CreateFrame("CheckButton", nil, behavior, "ChatConfigCheckButtonTemplate")
    showBestTimedComparisonCheck:SetPoint("TOPLEFT", showUnlockedCheck, "BOTTOMLEFT", 0, -10)
    showBestTimedComparisonCheck.Text:SetText("Show best timed vs current")
    showBestTimedComparisonCheck:SetScript("OnClick", function(button)
        ns.db.profile.showBestTimedComparison = button:GetChecked() and true or false
        ns:Render()
    end)

    local useClassColorCheck = CreateFrame("CheckButton", nil, behavior, "ChatConfigCheckButtonTemplate")
    useClassColorCheck:SetPoint("TOPLEFT", showBestTimedComparisonCheck, "BOTTOMLEFT", 0, -10)
    useClassColorCheck.Text:SetText("Use class color for accent")
    useClassColorCheck:SetScript("OnClick", function(button)
        ns.db.profile.appearance.useClassColor = button:GetChecked() and true or false
        ns:ApplyTheme()
    end)

    local showPaceHintsCheck = CreateFrame("CheckButton", nil, behavior, "ChatConfigCheckButtonTemplate")
    showPaceHintsCheck:SetPoint("TOPLEFT", useClassColorCheck, "BOTTOMLEFT", 0, -10)
    showPaceHintsCheck.Text:SetText("Show pace hints on tracker")
    showPaceHintsCheck:SetScript("OnClick", function(button)
        ns.db.profile.showPaceHints = button:GetChecked() and true or false
        ns:Render()
    end)

    local previewScenarioDrop = makeDropdown(
        behavior,
        "Preview Scenario",
        PREVIEW_SCENARIO_OPTIONS,
        "TOPLEFT",
        showPaceHintsCheck,
        "BOTTOMLEFT",
        0,
        -8,
        function(key)
            ns.db.profile.previewScenario = key
            ns:Render()
        end
    )

    local widthSlider = CreateFrame("Slider", nil, layout, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", layout, "TOPLEFT", 12, -32)
    widthSlider:SetWidth(420)
    widthSlider:SetMinMaxValues(280, 760)
    widthSlider:SetValueStep(2)
    styleSlider(widthSlider, "Frame Width", 280, 760)
    widthSlider:SetScript("OnValueChanged", function(slider, value)
        local rounded = math.floor(value + 0.5)
        ns.db.profile.appearance.frameWidth = rounded
        slider.value:SetText(tostring(rounded))
        ns:ApplyFrameSettings()
    end)

    local heightSlider = CreateFrame("Slider", nil, layout, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -36)
    heightSlider:SetWidth(420)
    heightSlider:SetMinMaxValues(200, 520)
    heightSlider:SetValueStep(2)
    styleSlider(heightSlider, "Frame Height", 200, 520)
    heightSlider:SetScript("OnValueChanged", function(slider, value)
        local rounded = math.floor(value + 0.5)
        ns.db.profile.appearance.frameHeight = rounded
        slider.value:SetText(tostring(rounded))
        ns:ApplyFrameSettings()
    end)

    local scaleSlider = CreateFrame("Slider", nil, layout, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -36)
    scaleSlider:SetWidth(420)
    scaleSlider:SetMinMaxValues(0.70, 1.80)
    scaleSlider:SetValueStep(0.01)
    styleSlider(scaleSlider, "Frame Scale", 0.70, 1.80)
    scaleSlider:SetScript("OnValueChanged", function(slider, value)
        local rounded = tonumber(string.format("%.2f", value)) or 1
        ns.db.profile.scale = rounded
        slider.value:SetText(string.format("%.2f", rounded))
        ns:ApplyFrameSettings()
    end)

    local alphaSlider = CreateFrame("Slider", nil, layout, "OptionsSliderTemplate")
    alphaSlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -36)
    alphaSlider:SetWidth(420)
    alphaSlider:SetMinMaxValues(0.00, 1.00)
    alphaSlider:SetValueStep(0.01)
    styleSlider(alphaSlider, "Frame Opacity", 0.00, 1.00)
    alphaSlider:SetScript("OnValueChanged", function(slider, value)
        local rounded = tonumber(string.format("%.2f", value)) or 1
        ns.db.profile.alpha = rounded
        slider.value:SetText(string.format("%.2f", rounded))
        ns:ApplyFrameSettings()
    end)

    local fontScaleSlider = CreateFrame("Slider", nil, layout, "OptionsSliderTemplate")
    fontScaleSlider:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -36)
    fontScaleSlider:SetWidth(420)
    fontScaleSlider:SetMinMaxValues(0.70, 1.60)
    fontScaleSlider:SetValueStep(0.01)
    styleSlider(fontScaleSlider, "Font Scale", 0.70, 1.60)
    fontScaleSlider:SetScript("OnValueChanged", function(slider, value)
        local rounded = tonumber(string.format("%.2f", value)) or 1
        ns.db.profile.appearance.fontScale = rounded
        slider.value:SetText(string.format("%.2f", rounded))
        ns:ApplyFrameSettings()
    end)

    local titleFontDrop = makeDropdown(fonts, "Title Font", FONT_OPTIONS, "TOPLEFT", fonts, "TOPLEFT", 12, -28, function(key)
        ns.db.profile.appearance.titleFont = key
        ns:ApplyFrameSettings()
    end)
    local timerFontDrop = makeDropdown(fonts, "Timer Font", FONT_OPTIONS, "TOPLEFT", titleFontDrop, "BOTTOMLEFT", 0, -8, function(key)
        ns.db.profile.appearance.timerFont = key
        ns:ApplyFrameSettings()
    end)
    local bodyFontDrop = makeDropdown(fonts, "Body Font", FONT_OPTIONS, "TOPLEFT", timerFontDrop, "BOTTOMLEFT", 0, -8, function(key)
        ns.db.profile.appearance.bodyFont = key
        ns:ApplyFrameSettings()
    end)

    frame.colorRows = {}
    for i = 1, #COLOR_KEYS do
        local entry = COLOR_KEYS[i]
        local row = makeHexRow(colors, entry.label, "TOPLEFT", colors, "TOPLEFT", 12, -30 - ((i - 1) * 26))
        frame.colorRows[entry.key] = row
        row.swatchButton:SetScript("OnClick", function()
            openColorPickerForKey(frame, entry.key, entry.fallback)
        end)
        row.input:SetScript("OnEnterPressed", function(input)
            input:ClearFocus()
            applyColorsFromInputs(frame)
        end)
        row.input:SetScript("OnEscapePressed", function(input)
            input:ClearFocus()
            ns:RefreshOptionsUI()
        end)
    end

    local hint = label(colors, "Tip: click swatch to open color wheel, or type hex manually (53B9FFCC)", "GameFontDisableSmall", "BOTTOMLEFT", colors, "BOTTOMLEFT", 12, 10)
    hint:SetTextColor(0.62, 0.68, 0.75)

    local presetDrop = makeDropdown(profiles, "Theme Preset", PRESET_OPTIONS, "TOPLEFT", profiles, "TOPLEFT", 12, -28, function() end)
    label(profiles, "Export Profile", "GameFontNormalSmall", "TOPLEFT", presetDrop, "BOTTOMLEFT", 0, -10)
    local exportBox = makeInput(profiles, 420, "TOPLEFT", presetDrop, "BOTTOMLEFT", 0, -30)
    exportBox:SetScript("OnEditFocusGained", function(edit)
        edit:HighlightText()
    end)

    local generateExportButton = CreateFrame("Button", nil, profiles, "UIPanelButtonTemplate")
    generateExportButton:SetSize(132, 24)
    generateExportButton:SetPoint("TOPLEFT", exportBox, "BOTTOMLEFT", 0, -8)
    generateExportButton:SetText("Generate Export")
    styleButton(generateExportButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    generateExportButton:SetScript("OnClick", function()
        local code = buildExportString()
        exportBox:SetText(code)
        exportBox:SetFocus()
        exportBox:HighlightText()
    end)

    label(profiles, "Import Profile", "GameFontNormalSmall", "TOPLEFT", generateExportButton, "BOTTOMLEFT", 0, -10)
    local importBox = makeInput(profiles, 420, "TOPLEFT", generateExportButton, "BOTTOMLEFT", 0, -30)
    importBox:SetScript("OnEnterPressed", function(edit)
        edit:ClearFocus()
        local ok, msg = applyImportString(edit:GetText())
        if ok then
            ns:RefreshOptionsUI()
            ns:Print("Profile imported.")
        else
            ns:Print(msg)
        end
    end)

    local importButton = CreateFrame("Button", nil, profiles, "UIPanelButtonTemplate")
    importButton:SetSize(132, 24)
    importButton:SetPoint("TOPLEFT", importBox, "BOTTOMLEFT", 0, -8)
    importButton:SetText("Import Profile")
    styleButton(importButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    importButton:SetScript("OnClick", function()
        local ok, msg = applyImportString(importBox:GetText())
        if ok then
            ns:RefreshOptionsUI()
            ns:Print("Profile imported.")
        else
            ns:Print(msg)
        end
    end)

    local applyColorsButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    applyColorsButton:SetSize(120, 24)
    applyColorsButton:SetPoint("CENTER", actions, "CENTER", -256, -6)
    applyColorsButton:SetText("Apply Colors")
    styleButton(applyColorsButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    applyColorsButton:SetScript("OnClick", function()
        applyColorsFromInputs(frame)
        ns:Print("Appearance colors applied.")
    end)

    local resetPosButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    resetPosButton:SetSize(120, 24)
    resetPosButton:SetPoint("LEFT", applyColorsButton, "RIGHT", 8, 0)
    resetPosButton:SetText("Reset Position")
    styleButton(resetPosButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    resetPosButton:SetScript("OnClick", function()
        ns.db.profile.position.x = DEFAULT_X
        ns.db.profile.position.y = DEFAULT_Y
        ns:RestorePosition()
        ns:Print("Position reset.")
    end)

    local resetRecordsButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    resetRecordsButton:SetSize(120, 24)
    resetRecordsButton:SetPoint("LEFT", resetPosButton, "RIGHT", 8, 0)
    resetRecordsButton:SetText("Reset Records")
    styleButton(resetRecordsButton, { 0.34, 0.18, 0.09, 0.95 }, { 0.44, 0.24, 0.13, 0.98 }, { 0.65, 0.36, 0.22, 1 })
    resetRecordsButton:SetScript("OnClick", function()
        wipe(ns.db.records)
        ns:Render()
        ns:Print("Saved dungeon records reset.")
    end)

    local applyPresetButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    applyPresetButton:SetSize(120, 24)
    applyPresetButton:SetPoint("LEFT", resetRecordsButton, "RIGHT", 8, 0)
    applyPresetButton:SetText("Apply Preset")
    styleButton(applyPresetButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    applyPresetButton:SetScript("OnClick", function()
        local selected = UIDropDownMenu_GetSelectedValue(presetDrop.dropdown) or "KEYSTONE"
        applyPreset(selected)
    end)

    local closeButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    closeButton:SetSize(120, 24)
    closeButton:SetPoint("LEFT", applyPresetButton, "RIGHT", 8, 0)
    closeButton:SetText("Close")
    styleButton(closeButton, { 0.15, 0.15, 0.17, 0.95 }, { 0.20, 0.20, 0.23, 0.98 }, { 0.30, 0.32, 0.37, 1 })
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    self.ui.options = frame
    frame.lockCheck = lockCheck
    frame.showUnlockedCheck = showUnlockedCheck
    frame.showBestTimedComparisonCheck = showBestTimedComparisonCheck
    frame.showPaceHintsCheck = showPaceHintsCheck
    frame.previewScenarioDrop = previewScenarioDrop
    frame.useClassColorCheck = useClassColorCheck
    frame.widthSlider = widthSlider
    frame.heightSlider = heightSlider
    frame.scaleSlider = scaleSlider
    frame.alphaSlider = alphaSlider
    frame.fontScaleSlider = fontScaleSlider
    frame.titleFontDrop = titleFontDrop
    frame.timerFontDrop = timerFontDrop
    frame.bodyFontDrop = bodyFontDrop
    frame.presetDrop = presetDrop
    frame.exportBox = exportBox
    frame.importBox = importBox
    frame.closeButton = closeButton
end
