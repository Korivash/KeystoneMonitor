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

local DUNGEON_MODE_OPTIONS = {
    { key = "AUTO", name = "Auto" },
    { key = "FOLLOWER", name = "Follower" },
    { key = "NORMAL", name = "Normal" },
    { key = "HEROIC", name = "Heroic" },
    { key = "MYTHIC_ZERO", name = "Mythic 0" },
    { key = "MYTHIC_PLUS", name = "Mythic+" },
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
    "dungeonMode",
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

local function clearOptionsInputFocus(frame)
    if not frame then
        return
    end

    if frame.exportBox and frame.exportBox.ClearFocus then
        frame.exportBox:ClearFocus()
    end
    if frame.importBox and frame.importBox.ClearFocus then
        frame.importBox:ClearFocus()
    end

    if frame.colorRows then
        for _, row in pairs(frame.colorRows) do
            if row and row.input and row.input.ClearFocus then
                row.input:ClearFocus()
            end
        end
    end

    if GetCurrentKeyBoardFocus then
        local focus = GetCurrentKeyBoardFocus()
        if focus and focus.ClearFocus then
            local owner = focus
            while owner do
                if owner == frame then
                    focus:ClearFocus()
                    break
                end
                owner = owner.GetParent and owner:GetParent() or nil
            end
        end
    end
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
        dungeonMode = tostring(profile.dungeonMode or "AUTO"),
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
    if map.dungeonMode then
        if map.dungeonMode == "AUTO"
            or map.dungeonMode == "FOLLOWER"
            or map.dungeonMode == "NORMAL"
            or map.dungeonMode == "HEROIC"
            or map.dungeonMode == "MYTHIC_ZERO"
            or map.dungeonMode == "MYTHIC_PLUS" then
            profile.dungeonMode = map.dungeonMode
        end
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
    ns:SyncChallengeState(true)
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

local function styleModernPanel(panel, bg, border)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    panel:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function styleModernInput(edit, width, height)
    edit:SetSize(width, height or 22)
    edit:SetAutoFocus(false)
    edit:SetTextInsets(6, 6, 0, 0)
    edit:SetJustifyH("LEFT")
    if edit.SetBackdrop then
        edit:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        edit:SetBackdropColor(0.05, 0.08, 0.12, 0.95)
        edit:SetBackdropBorderColor(0.14, 0.34, 0.55, 0.92)
    end
    if edit.SetFontObject then
        edit:SetFontObject("GameFontHighlightSmall")
    elseif edit.SetNormalFontObject then
        edit:SetNormalFontObject("GameFontHighlightSmall")
    end
    edit:SetTextColor(0.90, 0.96, 1.0, 1)
end

local function styleModernDropdown(holder)
    local drop = holder and holder.dropdown
    if not drop then
        return
    end
    local name = drop:GetName()
    if not name then
        return
    end
    local left = _G[name .. "Left"]
    local middle = _G[name .. "Middle"]
    local right = _G[name .. "Right"]
    local button = _G[name .. "Button"]
    if left then left:SetAlpha(0) end
    if middle then middle:SetAlpha(0) end
    if right then right:SetAlpha(0) end
    if button then button:SetAlpha(0.9) end

    holder.bg = holder:CreateTexture(nil, "BACKGROUND")
    holder.bg:SetPoint("TOPLEFT", holder, "TOPLEFT", -1, -16)
    holder.bg:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -132, -3)
    holder.bg:SetColorTexture(0.05, 0.08, 0.12, 0.95)

    holder.border = holder:CreateTexture(nil, "BORDER")
    holder.border:SetPoint("TOPLEFT", holder.bg, "TOPLEFT", -1, 1)
    holder.border:SetPoint("BOTTOMRIGHT", holder.bg, "BOTTOMRIGHT", 1, -1)
    holder.border:SetColorTexture(0.14, 0.34, 0.55, 0.92)
end

local function createSection(parent, title, yOffset, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(height)
    styleModernPanel(frame, { 0.07, 0.10, 0.15, 0.92 }, { 0.11, 0.24, 0.39, 0.95 })

    frame.title = label(frame, title, "GameFontNormal", "TOPLEFT", frame, "TOPLEFT", 12, -10)
    frame.title:SetTextColor(0.72, 0.88, 1.0)
    frame.rule = frame:CreateTexture(nil, "ARTWORK")
    frame.rule:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
    frame.rule:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -28)
    frame.rule:SetHeight(1)
    frame.rule:SetColorTexture(0.12, 0.44, 0.72, 0.82)
    return frame
end

local function attachSectionCollapse(section, targets, expandedHeight, collapsedHeight)
    section._expandedHeight = expandedHeight or section:GetHeight()
    section._collapsedHeight = collapsedHeight or 34
    section._collapsed = false

    local toggle = CreateFrame("Button", nil, section)
    toggle:SetSize(18, 18)
    toggle:SetPoint("TOPRIGHT", section, "TOPRIGHT", -10, -8)
    toggle:SetText("-")
    styleButton(toggle, { 0.10, 0.16, 0.24, 0.95 }, { 0.13, 0.20, 0.30, 0.98 }, { 0.18, 0.36, 0.56, 1.0 })

    local function setCollapsed(collapsed)
        section._collapsed = collapsed and true or false
        section:SetHeight(section._collapsed and section._collapsedHeight or section._expandedHeight)
        toggle:SetText(section._collapsed and "+" or "-")
        for i = 1, #targets do
            if section._collapsed then
                targets[i]:Hide()
            else
                targets[i]:Show()
            end
        end
    end

    toggle:SetScript("OnClick", function()
        setCollapsed(not section._collapsed)
    end)
    setCollapsed(false)
end

local function createToggleRow(parent, text, point, relTo, relPoint, x, y, onChange)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint(point, relTo, relPoint, x, y)
    row:SetSize(460, 22)
    row.value = false

    row.label = label(row, text, "GameFontHighlightSmall", "LEFT", row, "LEFT", 0, 0)
    row.label:SetTextColor(0.86, 0.93, 1.0)

    row.track = row:CreateTexture(nil, "ARTWORK")
    row.track:SetSize(36, 16)
    row.track:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    row.knob = row:CreateTexture(nil, "OVERLAY")
    row.knob:SetSize(14, 14)
    row.knob:SetPoint("LEFT", row.track, "LEFT", 1, 0)
    row.knob:SetColorTexture(0.90, 0.96, 1.0, 1)

    function row:SetChecked(isChecked)
        self.value = isChecked and true or false
        if self.value then
            self.track:SetColorTexture(0.00, 0.70, 1.0, 0.95)
            self.knob:ClearAllPoints()
            self.knob:SetPoint("RIGHT", self.track, "RIGHT", -1, 0)
        else
            self.track:SetColorTexture(0.18, 0.22, 0.28, 0.95)
            self.knob:ClearAllPoints()
            self.knob:SetPoint("LEFT", self.track, "LEFT", 1, 0)
        end
    end

    row:SetScript("OnEnter", function(self)
        self.label:SetTextColor(0.94, 0.98, 1.0)
    end)
    row:SetScript("OnLeave", function(self)
        self.label:SetTextColor(0.86, 0.93, 1.0)
    end)
    row:SetScript("OnClick", function(self)
        self:SetChecked(not self.value)
        if onChange then
            onChange(self.value)
        end
    end)
    row:SetChecked(false)
    return row
end

local function createSliderRow(parent, titleText, minValue, maxValue, step, point, relTo, relPoint, x, y, formatter, onChange)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint(point, relTo, relPoint, x, y)
    holder:SetSize(500, 54)

    local slider = CreateFrame("Slider", nil, holder, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -16)
    slider:SetWidth(380)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    styleSlider(slider, titleText, minValue, maxValue)

    local input = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", 14, 0)
    styleModernInput(input, 84, 22)
    input:SetScript("OnEnterPressed", function(edit)
        edit:ClearFocus()
        local raw = tonumber(edit:GetText())
        if raw then
            local clamped = clamp(raw, minValue, maxValue)
            slider:SetValue(clamped)
            if onChange then
                onChange(clamped)
            end
        end
    end)
    input:SetScript("OnEscapePressed", function(edit)
        edit:ClearFocus()
    end)

    slider:SetScript("OnValueChanged", function(_, value)
        local rendered = formatter and formatter(value) or tostring(value)
        slider.value:SetText(rendered)
        input:SetText(rendered)
        if onChange then
            onChange(value)
        end
    end)

    holder.slider = slider
    holder.input = input
    return holder
end

local function createTabButton(parent, text, iconText, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(172, 34)
    styleModernPanel(button, { 0.07, 0.10, 0.15, 0.95 }, { 0.12, 0.22, 0.33, 0.95 })

    button.activeGlow = button:CreateTexture(nil, "BACKGROUND")
    button.activeGlow:SetAllPoints()
    button.activeGlow:SetColorTexture(0.00, 0.58, 1.0, 0.16)
    button.activeGlow:Hide()

    button.icon = label(button, iconText, "GameFontHighlightSmall", "LEFT", button, "LEFT", 9, 0)
    button.icon:SetTextColor(0.54, 0.80, 1.0)
    button.text = label(button, text, "GameFontHighlightSmall", "LEFT", button.icon, "RIGHT", 8, 0)
    button.text:SetTextColor(0.83, 0.91, 0.98)

    function button:SetSelected(selected)
        if selected then
            self:SetBackdropColor(0.09, 0.18, 0.28, 0.98)
            self:SetBackdropBorderColor(0.10, 0.55, 0.94, 0.98)
            self.activeGlow:Show()
            self.text:SetTextColor(0.95, 0.98, 1.0)
        else
            self:SetBackdropColor(0.07, 0.10, 0.15, 0.95)
            self:SetBackdropBorderColor(0.12, 0.22, 0.33, 0.95)
            self.activeGlow:Hide()
            self.text:SetTextColor(0.83, 0.91, 0.98)
        end
    end

    button:SetScript("OnEnter", function(self)
        if not self.selected then
            self:SetBackdropColor(0.09, 0.14, 0.20, 0.95)
            self:SetBackdropBorderColor(0.15, 0.31, 0.46, 0.95)
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not self.selected then
            self:SetBackdropColor(0.07, 0.10, 0.15, 0.95)
            self:SetBackdropBorderColor(0.12, 0.22, 0.33, 0.95)
        end
    end)
    button:SetScript("OnClick", function()
        if onClick then
            onClick()
        end
    end)
    button:SetSelected(false)
    return button
end

local function createScrollPanel(parent, width, height)
    local scrollHost = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    scrollHost:SetSize(width, height)
    styleModernPanel(scrollHost, { 0.04, 0.07, 0.11, 0.96 }, { 0.10, 0.27, 0.42, 0.95 })

    local scroll = CreateFrame("ScrollFrame", nil, scrollHost, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", scrollHost, "TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", scrollHost, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width - 44, height - 16)
    scroll:SetScrollChild(content)

    scrollHost.scroll = scroll
    scrollHost.content = content
    return scrollHost
end

local function refreshSliderRow(row, value, formatter)
    if not row or not row.slider then
        return
    end
    row.slider:SetValue(value)
    local rendered = formatter and formatter(value) or tostring(value)
    row.slider.value:SetText(rendered)
    if row.input then
        row.input:SetText(rendered)
    end
end

function ns:RefreshOptionsUI()
    if not self.ui.options then
        return
    end

    local frame = self.ui.options
    local profile = self.db.profile
    local appearance = profile.appearance

    frame.lockToggle:SetChecked(profile.locked and true or false)
    frame.showUnlockedToggle:SetChecked(profile.showWhenUnlocked and true or false)
    frame.showBestTimedComparisonToggle:SetChecked(profile.showBestTimedComparison and true or false)
    frame.showPaceHintsToggle:SetChecked(profile.showPaceHints and true or false)
    frame.useClassColorToggle:SetChecked(appearance.useClassColor and true or false)
    dropdownSetValue(frame.dungeonModeDrop.dropdown, DUNGEON_MODE_OPTIONS, profile.dungeonMode or "AUTO")
    dropdownSetValue(frame.previewScenarioDrop.dropdown, PREVIEW_SCENARIO_OPTIONS, profile.previewScenario or "LIVE")

    refreshSliderRow(frame.widthSliderRow, appearance.frameWidth or 350, function(v) return tostring(math.floor(v + 0.5)) end)
    refreshSliderRow(frame.heightSliderRow, appearance.frameHeight or 248, function(v) return tostring(math.floor(v + 0.5)) end)
    refreshSliderRow(frame.scaleSliderRow, profile.scale or 1, function(v) return string.format("%.2f", v) end)
    refreshSliderRow(frame.alphaSliderRow, profile.alpha or 1, function(v) return string.format("%.2f", v) end)
    refreshSliderRow(frame.fontScaleSliderRow, appearance.fontScale or 1, function(v) return string.format("%.2f", v) end)

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
    frame:SetSize(1040, 760)
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
        clearOptionsInputFocus(frame)
        ns.ui.previewMode = true
        ns:RefreshVisibility()
        ns:Render()
    end)
    frame:SetScript("OnHide", function()
        clearOptionsInputFocus(frame)
        ns.ui.previewMode = false
        ns:RefreshVisibility()
    end)
    styleModernPanel(frame, { 0.04, 0.06, 0.09, 0.98 }, { 0.08, 0.35, 0.58, 0.95 })
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    header:SetHeight(66)
    styleModernPanel(header, { 0.05, 0.08, 0.12, 1.0 }, { 0.05, 0.20, 0.34, 0.95 })

    local accent = header:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetColorTexture(0.00, 0.70, 1.00, 0.95)

    label(header, "Keystone Monitor Control Studio", "GameFontNormalLarge", "LEFT", header, "LEFT", 14, 0)
    local sub = label(header, "Modern dungeon tracking configuration", "GameFontHighlightSmall", "LEFT", header, "LEFT", 280, 0)
    sub:SetTextColor(0.65, 0.80, 0.93)

    local closeButton = CreateFrame("Button", nil, header)
    closeButton:SetSize(70, 24)
    closeButton:SetPoint("RIGHT", header, "RIGHT", -12, 0)
    closeButton:SetText("Close")
    styleButton(closeButton, { 0.13, 0.14, 0.17, 0.96 }, { 0.18, 0.19, 0.23, 0.98 }, { 0.28, 0.30, 0.35, 1.0 })
    closeButton:SetScript("OnClick", function()
        clearOptionsInputFocus(frame)
        frame:Hide()
    end)

    local leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftPane:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 10, -10)
    leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    leftPane:SetWidth(192)
    styleModernPanel(leftPane, { 0.06, 0.09, 0.13, 0.95 }, { 0.10, 0.22, 0.36, 0.95 })

    local rightPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 10, 0)
    rightPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    styleModernPanel(rightPane, { 0.04, 0.06, 0.09, 0.96 }, { 0.08, 0.25, 0.40, 0.95 })

    local searchBox = CreateFrame("EditBox", nil, leftPane, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 10, -10)
    styleModernInput(searchBox, 170, 22)
    searchBox:SetMaxLetters(64)
    searchBox:SetText("")

    local searchHint = label(leftPane, "Search tabs", "GameFontDisableSmall", "TOPLEFT", searchBox, "BOTTOMLEFT", 2, -2)
    searchHint:SetTextColor(0.52, 0.68, 0.84)

    local collapseButton = CreateFrame("Button", nil, leftPane)
    collapseButton:SetSize(20, 20)
    collapseButton:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -8, -11)
    collapseButton:SetText("<")
    styleButton(collapseButton, { 0.08, 0.13, 0.20, 0.94 }, { 0.12, 0.19, 0.28, 0.98 }, { 0.18, 0.36, 0.56, 1.0 })

    local tabs = {}
    local tabOrder = {
        { key = "GENERAL", label = "General", icon = "G" },
        { key = "LAYOUT", label = "Layout", icon = "L" },
        { key = "VISUAL", label = "Visual", icon = "V" },
        { key = "FONTS", label = "Fonts", icon = "F" },
        { key = "PROFILES", label = "Profiles", icon = "P" },
    }

    local panels = {}
    local function makeTabPanel(key)
        local panel = createScrollPanel(rightPane, 814, 664)
        panel:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 10, -10)
        panel:Hide()
        panels[key] = panel
        return panel
    end

    local selectedTabKey = "GENERAL"
    local function setTab(key)
        selectedTabKey = key
        for i = 1, #tabOrder do
            local entry = tabOrder[i]
            local button = tabs[entry.key]
            local isSelected = entry.key == key
            button.selected = isSelected
            button:SetSelected(isSelected)
            if panels[entry.key] then
                if isSelected then
                    panels[entry.key]:Show()
                    if UIFrameFadeIn then
                        UIFrameFadeIn(panels[entry.key], 0.12, 0.2, 1)
                    end
                else
                    panels[entry.key]:Hide()
                end
            end
        end
    end

    for i = 1, #tabOrder do
        local entry = tabOrder[i]
        local tab = createTabButton(leftPane, entry.label, entry.icon, function()
            setTab(entry.key)
        end)
        tab:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 10, -44 - ((i - 1) * 40))
        tabs[entry.key] = tab
    end

    local sidebarExpanded = true
    collapseButton:SetScript("OnClick", function()
        sidebarExpanded = not sidebarExpanded
        if sidebarExpanded then
            leftPane:SetWidth(192)
            searchBox:Show()
            searchHint:Show()
            collapseButton:SetText("<")
            for i = 1, #tabOrder do
                tabs[tabOrder[i].key].text:Show()
            end
        else
            leftPane:SetWidth(60)
            searchBox:Hide()
            searchHint:Hide()
            collapseButton:SetText(">")
            for i = 1, #tabOrder do
                tabs[tabOrder[i].key].text:Hide()
            end
        end
    end)

    searchBox:SetScript("OnTextChanged", function(edit)
        local needle = string.lower(ns:Trim(edit:GetText() or ""))
        if needle == "" then
            for i = 1, #tabOrder do
                tabs[tabOrder[i].key]:Show()
            end
            return
        end
        local firstMatch = nil
        for i = 1, #tabOrder do
            local entry = tabOrder[i]
            local matches = string.find(string.lower(entry.label), needle, 1, true) ~= nil
            if matches then
                tabs[entry.key]:Show()
                if not firstMatch then
                    firstMatch = entry.key
                end
            else
                tabs[entry.key]:Hide()
            end
        end
        if firstMatch and firstMatch ~= selectedTabKey then
            setTab(firstMatch)
        end
    end)

    local generalPanel = makeTabPanel("GENERAL")
    local layoutPanel = makeTabPanel("LAYOUT")
    local visualPanel = makeTabPanel("VISUAL")
    local fontsPanel = makeTabPanel("FONTS")
    local profilesPanel = makeTabPanel("PROFILES")

    local generalCore = createSection(generalPanel.content, "Core Tracking", 0, 236)
    local lockToggle = createToggleRow(generalCore, "Lock tracker position", "TOPLEFT", generalCore, "TOPLEFT", 14, -44, function(value)
        ns.db.profile.locked = value and true or false
        ns:RefreshVisibility()
        ns:Render()
    end)
    local showUnlockedToggle = createToggleRow(generalCore, "Show tracker while unlocked", "TOPLEFT", lockToggle, "BOTTOMLEFT", 0, -10, function(value)
        ns.db.profile.showWhenUnlocked = value and true or false
        ns:RefreshVisibility()
        ns:Render()
    end)
    local showBestTimedComparisonToggle = createToggleRow(generalCore, "Show best timed comparison", "TOPLEFT", showUnlockedToggle, "BOTTOMLEFT", 0, -10, function(value)
        ns.db.profile.showBestTimedComparison = value and true or false
        ns:Render()
    end)
    local showPaceHintsToggle = createToggleRow(generalCore, "Show pace hints", "TOPLEFT", showBestTimedComparisonToggle, "BOTTOMLEFT", 0, -10, function(value)
        ns.db.profile.showPaceHints = value and true or false
        ns:Render()
    end)

    local generalAdvanced = createSection(generalPanel.content, "Advanced", -248, 180)
    local dungeonModeDrop = makeDropdown(
        generalAdvanced,
        "Tracked Dungeon Mode",
        DUNGEON_MODE_OPTIONS,
        "TOPLEFT",
        generalAdvanced,
        "TOPLEFT",
        14,
        -38,
        function(key)
            ns.db.profile.dungeonMode = key
            ns:SyncChallengeState(true)
            ns:Render()
        end
    )
    styleModernDropdown(dungeonModeDrop)

    local previewScenarioDrop = makeDropdown(
        generalAdvanced,
        "Preview Scenario",
        PREVIEW_SCENARIO_OPTIONS,
        "TOPLEFT",
        dungeonModeDrop,
        "BOTTOMLEFT",
        0,
        -8,
        function(key)
            ns.db.profile.previewScenario = key
            ns:Render()
        end
    )
    styleModernDropdown(previewScenarioDrop)
    attachSectionCollapse(generalAdvanced, { dungeonModeDrop, previewScenarioDrop }, 180, 38)

    local layoutSection = createSection(layoutPanel.content, "Layout & Size", 0, 332)
    local widthSliderRow = createSliderRow(layoutSection, "Frame Width", 280, 760, 2, "TOPLEFT", layoutSection, "TOPLEFT", 14, -42, function(v) return tostring(math.floor(v + 0.5)) end, function(v)
        ns.db.profile.appearance.frameWidth = math.floor(v + 0.5)
        ns:ApplyFrameSettings()
    end)
    local heightSliderRow = createSliderRow(layoutSection, "Frame Height", 200, 520, 2, "TOPLEFT", widthSliderRow, "BOTTOMLEFT", 0, -12, function(v) return tostring(math.floor(v + 0.5)) end, function(v)
        ns.db.profile.appearance.frameHeight = math.floor(v + 0.5)
        ns:ApplyFrameSettings()
    end)
    local scaleSliderRow = createSliderRow(layoutSection, "Frame Scale", 0.70, 1.80, 0.01, "TOPLEFT", heightSliderRow, "BOTTOMLEFT", 0, -12, function(v) return string.format("%.2f", v) end, function(v)
        ns.db.profile.scale = tonumber(string.format("%.2f", v)) or 1
        ns:ApplyFrameSettings()
    end)
    local alphaSliderRow = createSliderRow(layoutSection, "Panel Opacity", 0.00, 1.00, 0.01, "TOPLEFT", scaleSliderRow, "BOTTOMLEFT", 0, -12, function(v) return string.format("%.2f", v) end, function(v)
        ns.db.profile.alpha = tonumber(string.format("%.2f", v)) or 1
        ns:ApplyFrameSettings()
    end)

    local layoutActions = createSection(layoutPanel.content, "Layout Actions", -344, 118)
    local resetPosButton = CreateFrame("Button", nil, layoutActions)
    resetPosButton:SetSize(160, 24)
    resetPosButton:SetPoint("TOPLEFT", layoutActions, "TOPLEFT", 14, -42)
    resetPosButton:SetText("Reset Position")
    styleButton(resetPosButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    resetPosButton:SetScript("OnClick", function()
        ns.db.profile.position.x = DEFAULT_X
        ns.db.profile.position.y = DEFAULT_Y
        ns:RestorePosition()
        ns:Print("Position reset.")
    end)
    attachSectionCollapse(layoutActions, { resetPosButton }, 118, 38)

    local visualSection = createSection(visualPanel.content, "Color & Theme", 0, 340)
    local useClassColorToggle = createToggleRow(visualSection, "Use class color for accent", "TOPLEFT", visualSection, "TOPLEFT", 14, -44, function(value)
        ns.db.profile.appearance.useClassColor = value and true or false
        ns:ApplyTheme()
    end)

    frame.colorRows = {}
    for i = 1, #COLOR_KEYS do
        local entry = COLOR_KEYS[i]
        local row = makeHexRow(visualSection, entry.label, "TOPLEFT", useClassColorToggle, "BOTTOMLEFT", 0, -12 - ((i - 1) * 26))
        frame.colorRows[entry.key] = row
        styleModernInput(row.input, 120, 20)
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

    local applyColorsButton = CreateFrame("Button", nil, visualSection)
    applyColorsButton:SetSize(150, 24)
    applyColorsButton:SetPoint("TOPLEFT", visualSection, "TOPLEFT", 14, -308)
    applyColorsButton:SetText("Apply Colors")
    styleButton(applyColorsButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    applyColorsButton:SetScript("OnClick", function()
        applyColorsFromInputs(frame)
        ns:Print("Appearance colors applied.")
    end)

    local visualDensity = createSection(visualPanel.content, "Density", -352, 110)
    local fontScaleSliderRow = createSliderRow(visualDensity, "Font Scale", 0.70, 1.60, 0.01, "TOPLEFT", visualDensity, "TOPLEFT", 14, -42, function(v) return string.format("%.2f", v) end, function(v)
        ns.db.profile.appearance.fontScale = tonumber(string.format("%.2f", v)) or 1
        ns:ApplyFrameSettings()
    end)

    local fontsSection = createSection(fontsPanel.content, "Typography", 0, 200)
    local titleFontDrop = makeDropdown(fontsSection, "Title Font", FONT_OPTIONS, "TOPLEFT", fontsSection, "TOPLEFT", 14, -38, function(key)
        ns.db.profile.appearance.titleFont = key
        ns:ApplyFrameSettings()
    end)
    local timerFontDrop = makeDropdown(fontsSection, "Timer Font", FONT_OPTIONS, "TOPLEFT", titleFontDrop, "BOTTOMLEFT", 0, -8, function(key)
        ns.db.profile.appearance.timerFont = key
        ns:ApplyFrameSettings()
    end)
    local bodyFontDrop = makeDropdown(fontsSection, "Body Font", FONT_OPTIONS, "TOPLEFT", timerFontDrop, "BOTTOMLEFT", 0, -8, function(key)
        ns.db.profile.appearance.bodyFont = key
        ns:ApplyFrameSettings()
    end)
    styleModernDropdown(titleFontDrop)
    styleModernDropdown(timerFontDrop)
    styleModernDropdown(bodyFontDrop)

    local profilesSection = createSection(profilesPanel.content, "Presets & Profiles", 0, 320)
    local presetDrop = makeDropdown(profilesSection, "Theme Preset", PRESET_OPTIONS, "TOPLEFT", profilesSection, "TOPLEFT", 14, -38, function() end)
    styleModernDropdown(presetDrop)

    local applyPresetButton = CreateFrame("Button", nil, profilesSection)
    applyPresetButton:SetSize(140, 24)
    applyPresetButton:SetPoint("TOPLEFT", presetDrop, "BOTTOMLEFT", 0, -8)
    applyPresetButton:SetText("Apply Preset")
    styleButton(applyPresetButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    applyPresetButton:SetScript("OnClick", function()
        local selected = UIDropDownMenu_GetSelectedValue(presetDrop.dropdown) or "KEYSTONE"
        applyPreset(selected)
    end)

    local exportLabel = label(profilesSection, "Export Profile", "GameFontNormalSmall", "TOPLEFT", applyPresetButton, "BOTTOMLEFT", 0, -10)
    exportLabel:SetTextColor(0.85, 0.92, 0.99)
    local exportBox = makeInput(profilesSection, 620, "TOPLEFT", exportLabel, "BOTTOMLEFT", 0, -6)
    styleModernInput(exportBox, 620, 22)
    exportBox:SetScript("OnEditFocusGained", function(edit)
        edit:HighlightText()
    end)
    exportBox:SetScript("OnEscapePressed", function(edit)
        edit:ClearFocus()
    end)

    local generateExportButton = CreateFrame("Button", nil, profilesSection)
    generateExportButton:SetSize(150, 24)
    generateExportButton:SetPoint("TOPLEFT", exportBox, "BOTTOMLEFT", 0, -8)
    generateExportButton:SetText("Generate Export")
    styleButton(generateExportButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    generateExportButton:SetScript("OnClick", function()
        local code = buildExportString()
        exportBox:SetText(code)
        exportBox:SetFocus()
        exportBox:HighlightText()
    end)

    local importLabel = label(profilesSection, "Import Profile", "GameFontNormalSmall", "TOPLEFT", generateExportButton, "BOTTOMLEFT", 0, -10)
    importLabel:SetTextColor(0.85, 0.92, 0.99)
    local importBox = makeInput(profilesSection, 620, "TOPLEFT", importLabel, "BOTTOMLEFT", 0, -6)
    styleModernInput(importBox, 620, 22)
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
    importBox:SetScript("OnEscapePressed", function(edit)
        edit:ClearFocus()
    end)

    local importButton = CreateFrame("Button", nil, profilesSection)
    importButton:SetSize(150, 24)
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

    local refreshHistoryButton = CreateFrame("Button", nil, profilesSection)
    refreshHistoryButton:SetSize(180, 24)
    refreshHistoryButton:SetPoint("LEFT", importButton, "RIGHT", 8, 0)
    refreshHistoryButton:SetText("Refresh M+ Data")
    styleButton(refreshHistoryButton, { 0.09, 0.23, 0.36, 0.95 }, { 0.14, 0.30, 0.46, 0.98 }, { 0.21, 0.47, 0.70, 1 })
    refreshHistoryButton:SetScript("OnClick", function()
        ns:InvalidateRunHistoryCache()
        ns:Render()
        ns:Print("Reloaded best times from Blizzard M+ history.")
    end)
    attachSectionCollapse(
        profilesSection,
        { presetDrop, applyPresetButton, exportLabel, exportBox, generateExportButton, importLabel, importBox, importButton, refreshHistoryButton },
        320,
        38
    )

    generalPanel.content:SetHeight(470)
    layoutPanel.content:SetHeight(480)
    visualPanel.content:SetHeight(500)
    fontsPanel.content:SetHeight(260)
    profilesPanel.content:SetHeight(430)

    self.ui.options = frame
    frame.lockToggle = lockToggle
    frame.showUnlockedToggle = showUnlockedToggle
    frame.showBestTimedComparisonToggle = showBestTimedComparisonToggle
    frame.showPaceHintsToggle = showPaceHintsToggle
    frame.useClassColorToggle = useClassColorToggle
    frame.dungeonModeDrop = dungeonModeDrop
    frame.previewScenarioDrop = previewScenarioDrop
    frame.widthSliderRow = widthSliderRow
    frame.heightSliderRow = heightSliderRow
    frame.scaleSliderRow = scaleSliderRow
    frame.alphaSliderRow = alphaSliderRow
    frame.fontScaleSliderRow = fontScaleSliderRow
    frame.titleFontDrop = titleFontDrop
    frame.timerFontDrop = timerFontDrop
    frame.bodyFontDrop = bodyFontDrop
    frame.presetDrop = presetDrop
    frame.exportBox = exportBox
    frame.importBox = importBox
    frame.closeButton = closeButton

    setTab("GENERAL")
end
