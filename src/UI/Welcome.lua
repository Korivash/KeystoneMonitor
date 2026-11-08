local _, ns = ...

local WIZARD_WIDTH = 560
local WIZARD_HEIGHT = 560
local ROW_HEIGHT = 40
local ROW_GAP = -4
local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"
local ICON_DONE = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:-1|t"

local FEATURE_TOGGLES = {
    { key = "showPaceHints", title = "Pace hints", desc = "Live +1/+2/+3 pace estimate during the run." },
    { key = "showBestTimedComparison", title = "Best time comparison", desc = "Compares this run with your personal best." },
    { key = "announceNewKeyToParty", title = "Announce new key to party", desc = "Shares your new key in party chat when you get one." },
}

local PAGE_TITLES = { "What it does", "Where should it go?", "Using it", "Look", "You're set" }
local CHIP_TITLES = { "About", "Position", "Use", "Look", "Done" }

local ABOUT_BODY = "Keystone Monitor keeps a small panel on screen during dungeon runs: the countdown against the time limit, chest timer splits, pace hints, forces, deaths with their penalty, and the affixes. Every run goes into a history with your personal bests. While a run is tracked it takes the place of the quest tracker and brings it back when the run ends."
local ABOUT_SIDE = "The panel on your screen right now is a preview of a finished run. It shows exactly where the real one will appear. Nothing is tracked until you enter a dungeon."
local POSITION_BODY = "The panel is unlocked and highlighted. Click and drag anywhere on it to move it. It remembers the spot.\n\nWhen you leave this page it locks again so a stray drag during a run cannot move it. Unlock it later with /km unlock or the Unlock toggle in settings, and lock it with /km lock."
local USE_INTRO = "Nothing to start by hand. The panel appears when a dungeon run starts and hides when you leave."
local USE_ROWS = {
    "Click the small clock in the panel's corner to open your run history.",
    "Click the Deaths line to see who died and when.",
    "Type /km for settings, /km unlock or /km lock to move or fix the panel.",
    "Hover an affix icon for what it does this week.",
}
local USE_OPTIONS = "Three settings players change first. Everything else is in /km options."
local LOOK_INTRO = "Pick a preset and adjust the size. Colors, fonts, width and height are in /km options."
local FINISH_BODY = "You're set. The panel appears on its own when a tracked dungeon starts.\n\nTo open this guide again or change anything:\n  • Type /km for settings, or /km setup for this guide\n  • Settings has a Setup guide button under Layout"

local themedToggles = {}
local themedStepChips = {}
local themedPrimaryButtons = {}
local themedRules = {}

local function accentRGB()
    local appearance = ns.db and ns.db.profile and ns.db.profile.appearance or {}
    if appearance.useClassColor then
        return ns:ClassColor()
    end
    return ns:HexToRGBA(appearance.accentColor or "53B9FFFF", 0.33, 0.73, 1.00, 1)
end

local function label(parent, text, template, point, relTo, relPoint, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetPoint(point, relTo, relPoint, x or 0, y or 0)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function styleModernPanel(panel, bg, border)
    panel:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    })
    panel:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    panel:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
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

local function createButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 110, height or 26)
    button:SetText(text)
    styleButton(button, { 0.10, 0.10, 0.13, 0.95 }, { 0.15, 0.15, 0.19, 0.98 }, { 0.26, 0.26, 0.32, 1.0 })
    return button
end

local function createPrimaryButton(parent, text, width, height)
    local button = createButton(parent, text, width, height)
    local r, g, b = accentRGB()
    button._border:SetColorTexture(r * 0.7, g * 0.7, b * 0.7, 1)
    themedPrimaryButtons[#themedPrimaryButtons + 1] = button
    return button
end

local function createStepChip(parent, index, text, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    styleModernPanel(button, { 0.055, 0.055, 0.07, 0.95 }, { 0.13, 0.13, 0.17, 0.95 })

    button.text = label(button, index and (index .. "  " .. text) or text, "GameFontHighlightSmall", "CENTER", button, "CENTER", 0, 0)
    button.text:SetJustifyH("CENTER")
    button.text:SetTextColor(0.60, 0.60, 0.65)

    function button:SetSelected(selected)
        self._selected = selected and true or false
        local r, g, b = accentRGB()
        if self._selected then
            self:SetBackdropColor(0.07, 0.07, 0.09, 0.98)
            self:SetBackdropBorderColor(r * 0.6, g * 0.6, b * 0.6, 0.9)
            self.text:SetTextColor(0.95, 0.95, 0.98)
        else
            self:SetBackdropColor(0.055, 0.055, 0.07, 0.95)
            self:SetBackdropBorderColor(0.13, 0.13, 0.17, 0.95)
            self.text:SetTextColor(0.60, 0.60, 0.65)
        end
    end

    button:SetScript("OnEnter", function(self)
        if not self._selected then
            self:SetBackdropColor(0.075, 0.075, 0.095, 0.95)
            self.text:SetTextColor(0.85, 0.85, 0.90)
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not self._selected then
            self:SetBackdropColor(0.055, 0.055, 0.07, 0.95)
            self.text:SetTextColor(0.60, 0.60, 0.65)
        end
    end)
    button:SetScript("OnClick", onClick)
    button:SetSelected(false)
    themedStepChips[#themedStepChips + 1] = button
    return button
end

local function createFeatureToggleRow(parent, entry, relTo, yOffset)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("TOPLEFT", relTo, "BOTTOMLEFT", 0, yOffset)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    row:SetHeight(ROW_HEIGHT)
    row.value = false

    row.title = label(row, entry.title, "GameFontHighlight", "TOPLEFT", row, "TOPLEFT", 0, -1)
    row.title:SetWordWrap(false)
    row.desc = label(row, entry.desc, "GameFontDisableSmall", "TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.desc:SetPoint("RIGHT", row, "RIGHT", -50, 0)

    row.track = row:CreateTexture(nil, "ARTWORK")
    row.track:SetSize(36, 16)
    row.track:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)

    row.knob = row:CreateTexture(nil, "OVERLAY")
    row.knob:SetSize(14, 14)
    row.knob:SetPoint("LEFT", row.track, "LEFT", 1, 0)
    row.knob:SetColorTexture(0.90, 0.96, 1.0, 1)

    function row:SetChecked(isChecked)
        self.value = isChecked and true or false
        if self.value then
            local r, g, b = accentRGB()
            self.track:SetColorTexture(r, g, b, 0.95)
            self.knob:ClearAllPoints()
            self.knob:SetPoint("RIGHT", self.track, "RIGHT", -1, 0)
        else
            self.track:SetColorTexture(0.16, 0.16, 0.20, 0.95)
            self.knob:ClearAllPoints()
            self.knob:SetPoint("LEFT", self.track, "LEFT", 1, 0)
        end
    end

    row:SetScript("OnEnter", function(self)
        self.title:SetTextColor(0.98, 0.98, 1.0)
    end)
    row:SetScript("OnLeave", function(self)
        self.title:SetTextColor(0.88, 0.88, 0.91)
    end)
    row:SetScript("OnClick", function(self)
        self:SetChecked(not self.value)
        if self.onChange then
            self.onChange(self.value)
        end
    end)
    row:SetChecked(false)
    themedToggles[#themedToggles + 1] = row
    return row
end

local function createSliderRow(parent, titleText, minValue, maxValue, steps, relTo, yOffset, onChange)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", relTo, "BOTTOMLEFT", 0, yOffset)
    holder:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    holder:SetHeight(40)

    holder.title = label(holder, titleText, "GameFontHighlight", "LEFT", holder, "LEFT", 0, 0)
    holder.title:SetWidth(70)
    holder.title:SetWordWrap(false)

    local function format(v)
        return string.format("%.2f", v)
    end

    if MinimalSliderWithSteppersMixin then
        local control = CreateFrame("Frame", nil, holder, "MinimalSliderWithSteppersTemplate")
        control:SetPoint("LEFT", holder.title, "RIGHT", 10, 0)
        control:SetSize(300, 40)
        control:Init(minValue, minValue, maxValue, steps, {
            [MinimalSliderWithSteppersMixin.Label.Right] = format,
        })
        control:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            if holder._suppress then
                return
            end
            onChange(value)
        end, holder)
        function holder:SetValue(value)
            self._suppress = true
            control.Slider:SetValue(value)
            self._suppress = nil
        end
        return holder
    end

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("LEFT", holder.title, "RIGHT", 10, 0)
    slider:SetSize(260, 16)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep((maxValue - minValue) / steps)
    slider:SetObeyStepOnDrag(true)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.16, 0.16, 0.20, 0.95)
    slider:SetThumbTexture(WHITE8X8)
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(10, 16)
    thumb:SetVertexColor(0.90, 0.96, 1.0, 1)
    holder.valueText = label(holder, "", "GameFontHighlightSmall", "LEFT", slider, "RIGHT", 12, 0)
    slider:SetScript("OnValueChanged", function(_, value)
        holder.valueText:SetText(format(value))
        if holder._suppress then
            return
        end
        onChange(value)
    end)
    function holder:SetValue(value)
        self._suppress = true
        slider:SetValue(value)
        self.valueText:SetText(format(value))
        self._suppress = nil
    end
    return holder
end

local function buildPreviewCard(parent)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(236, 170)
    card:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    })
    card.title = label(card, "Operation: Floodgate  +10", "GameFontHighlight", "TOPLEFT", card, "TOPLEFT", 10, -8)
    card.title:SetWordWrap(false)
    card.timer = label(card, "32:54", "GameFontHighlightLarge", "TOPLEFT", card, "TOPLEFT", 10, -26)
    card.chests = label(card, "+3 24:00   +2 26:24   +1 33:00", "GameFontHighlightSmall", "TOPLEFT", card, "TOPLEFT", 10, -52)
    card.chests:SetWordWrap(false)
    card.bar = CreateFrame("StatusBar", nil, card)
    card.bar:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -70)
    card.bar:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -70)
    card.bar:SetHeight(6)
    card.bar:SetStatusBarTexture(WHITE8X8)
    card.bar:SetMinMaxValues(0, 1)
    card.bar:SetValue(1)
    card.barBG = card.bar:CreateTexture(nil, "BACKGROUND")
    card.barBG:SetAllPoints()
    card.barBG:SetColorTexture(0, 0, 0, 0.30)
    card.forces = label(card, ICON_DONE .. " Forces 100 / 100", "GameFontHighlightSmall", "TOPLEFT", card, "TOPLEFT", 10, -82)
    card.deaths = label(card, "Deaths |cffFF5C5C6|r  ·  Penalty 1:30", "GameFontHighlightSmall", "TOPLEFT", card, "TOPLEFT", 10, -98)
    card.rows = {}
    local objectives = { { "Douse Security", "7:10" }, { "Disable Aqua Grid", "18:40" }, { "Defeat Head Engineer", "31:05" } }
    for i, objective in ipairs(objectives) do
        local row = label(card, string.format("%s %s  |cff9d9d9d%s|r", ICON_DONE, objective[1], objective[2]), "GameFontHighlightSmall", "TOPLEFT", card, "TOPLEFT", 10, -118 - (i - 1) * 15)
        row:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        row:SetWordWrap(false)
        card.rows[i] = row
    end

    function card:Refresh()
        local appearance = ns.db.profile.appearance or {}
        local r, g, b = accentRGB()
        local bgR, bgG, bgB, bgA = ns:HexToRGBA(appearance.backgroundColor or "0D0D0DC7", 0.05, 0.05, 0.05, 0.78)
        local tr, tg, tb = ns:HexToRGBA(appearance.textColor or "53B9FFFF", r, g, b, 1)
        local mr, mg, mb = ns:HexToRGBA(appearance.timerColor or "53B9FFFF", r, g, b, 1)
        local fr, fg, fb = ns:HexToRGBA(appearance.forcesBarColor or "53B9FFFF", r, g, b, 1)
        self:SetBackdropColor(bgR, bgG, bgB, math.max(0.35, bgA or 0.78))
        self:SetBackdropBorderColor(r, g, b, 0.35)
        self.title:SetTextColor(tr, tg, tb)
        self.timer:SetTextColor(mr, mg, mb)
        self.bar:SetStatusBarColor(fr, fg, fb, 0.85)
        self.chests:SetTextColor(0.90, 0.90, 0.93)
        self.forces:SetTextColor(0.90, 0.90, 0.93)
        self.deaths:SetTextColor(0.90, 0.90, 0.93)
        for i = 1, #self.rows do
            self.rows[i]:SetTextColor(0.90, 0.90, 0.93)
        end
    end
    card:Refresh()
    return card
end

function ns:BuildWelcomeWizard()
    local frame = CreateFrame("Frame", "KeystoneMonitorWelcomeFrame", UIParent, "BackdropTemplate")
    frame:SetSize(WIZARD_WIDTH, WIZARD_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    styleModernPanel(frame, { 0.043, 0.043, 0.055, 0.98 }, { 0.16, 0.16, 0.20, 1.0 })
    frame:Hide()
    frame:SetScript("OnHide", function(selfFrame)
        if selfFrame._wizardOpen then
            ns:SkipWelcomeWizard()
        end
    end)
    if UISpecialFrames then
        tinsert(UISpecialFrames, "KeystoneMonitorWelcomeFrame")
    end

    local accentR, accentG, accentB = accentRGB()

    local topStrip = frame:CreateTexture(nil, "OVERLAY")
    topStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topStrip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topStrip:SetHeight(2)
    topStrip:SetTexture(WHITE8X8)
    topStrip:SetGradient("HORIZONTAL", CreateColor(accentR, accentG, accentB, 1), CreateColor(accentR, accentG, accentB, 0.05))

    local topGlow = frame:CreateTexture(nil, "ARTWORK")
    topGlow:SetPoint("TOPLEFT", topStrip, "BOTTOMLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", topStrip, "BOTTOMRIGHT", 0, 0)
    topGlow:SetHeight(16)
    topGlow:SetTexture(WHITE8X8)
    topGlow:SetGradient("VERTICAL", CreateColor(accentR, accentG, accentB, 0), CreateColor(accentR, accentG, accentB, 0.10))

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    header:SetHeight(64)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    styleModernPanel(header, { 0.055, 0.055, 0.07, 1.0 }, { 0.14, 0.14, 0.18, 0.95 })

    local headerTitle = label(header, "Keystone Monitor Setup", "GameFontNormalLarge", "LEFT", header, "LEFT", 14, 0)
    headerTitle:SetTextColor(accentR, accentG, accentB)
    local sub = label(header, "Where · How · Look", "GameFontHighlightSmall", "LEFT", headerTitle, "RIGHT", 12, -1)
    sub:SetTextColor(0.55, 0.55, 0.60)
    frame._topStrip = topStrip
    frame._topGlow = topGlow
    frame._title = headerTitle

    local skipButton = createButton(header, "Skip", 80, 24)
    skipButton:SetPoint("RIGHT", header, "RIGHT", -12, 0)
    skipButton:SetScript("OnClick", function()
        ns:SkipWelcomeWizard()
    end)

    local stepChipsRow = CreateFrame("Frame", nil, frame)
    stepChipsRow:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 16, -12)
    stepChipsRow:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -16, -12)
    stepChipsRow:SetHeight(30)

    local footer = CreateFrame("Frame", nil, frame)
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(56)

    local nextButton = createPrimaryButton(footer, "Next", 110, 28)
    nextButton:SetPoint("RIGHT", footer, "RIGHT", -16, 0)
    local backButton = createButton(footer, "Back", 110, 28)
    backButton:SetPoint("RIGHT", nextButton, "LEFT", -8, 0)
    local stepText = label(footer, "", "GameFontDisableSmall", "LEFT", footer, "LEFT", 18, 0)
    stepText:SetTextColor(0.55, 0.55, 0.60)

    local contentCard = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentCard:SetPoint("TOPLEFT", stepChipsRow, "BOTTOMLEFT", 0, -10)
    contentCard:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -16, 10)
    styleModernPanel(contentCard, { 0.043, 0.043, 0.055, 0.96 }, { 0.13, 0.13, 0.17, 0.95 })

    local content = CreateFrame("Frame", nil, contentCard)
    content:SetPoint("TOPLEFT", contentCard, "TOPLEFT", 18, -16)
    content:SetPoint("BOTTOMRIGHT", contentCard, "BOTTOMRIGHT", -18, 16)

    local cardTitle = label(content, "", "GameFontNormal", "TOPLEFT", content, "TOPLEFT", 0, 0)
    cardTitle:SetTextColor(accentR, accentG, accentB)
    local cardRule = content:CreateTexture(nil, "ARTWORK")
    cardRule:SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -8)
    cardRule:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -8)
    cardRule:SetHeight(1)
    cardRule:SetTexture(WHITE8X8)
    cardRule:SetGradient("HORIZONTAL", CreateColor(accentR, accentG, accentB, 0.55), CreateColor(accentR, accentG, accentB, 0.04))
    themedRules[#themedRules + 1] = cardRule
    frame._cardTitle = cardTitle

    local pagesHost = CreateFrame("Frame", nil, content)
    pagesHost:SetPoint("TOPLEFT", cardRule, "BOTTOMLEFT", 0, -14)
    pagesHost:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    local page1 = CreateFrame("Frame", nil, pagesHost)
    page1:SetAllPoints(pagesHost)
    local p1body = label(page1, ABOUT_BODY, "GameFontHighlight", "TOPLEFT", page1, "TOPLEFT", 0, 0)
    p1body:SetPoint("RIGHT", page1, "RIGHT", 0, 0)
    p1body:SetSpacing(4)
    local previewCard = buildPreviewCard(page1)
    previewCard:SetPoint("TOPLEFT", p1body, "BOTTOMLEFT", 0, -16)
    frame._previewCard = previewCard
    local p1side = label(page1, ABOUT_SIDE, "GameFontHighlightSmall", "TOPLEFT", previewCard, "TOPRIGHT", 16, -4)
    p1side:SetPoint("RIGHT", page1, "RIGHT", 0, 0)
    p1side:SetSpacing(3)
    p1side:SetTextColor(0.70, 0.70, 0.74)

    local page2 = CreateFrame("Frame", nil, pagesHost)
    page2:SetAllPoints(pagesHost)
    local p2body = label(page2, POSITION_BODY, "GameFontHighlight", "TOPLEFT", page2, "TOPLEFT", 0, 0)
    p2body:SetPoint("RIGHT", page2, "RIGHT", 0, 0)
    p2body:SetSpacing(4)
    local resetButton = createButton(page2, "Reset to default position", 200, 26)
    resetButton:SetPoint("TOPLEFT", p2body, "BOTTOMLEFT", 0, -18)
    resetButton:SetScript("OnClick", function()
        ns.db.profile.position.x = 0
        ns.db.profile.position.y = 120
        ns:RestorePosition()
    end)
    local p2note = label(page2, "Settings under Layout also has Reset Position, scale, opacity, width and height.", "GameFontDisableSmall", "TOPLEFT", resetButton, "BOTTOMLEFT", 0, -14)
    p2note:SetPoint("RIGHT", page2, "RIGHT", 0, 0)

    local page3 = CreateFrame("Frame", nil, pagesHost)
    page3:SetAllPoints(pagesHost)
    local p3intro = label(page3, USE_INTRO, "GameFontHighlight", "TOPLEFT", page3, "TOPLEFT", 0, 0)
    p3intro:SetPoint("RIGHT", page3, "RIGHT", 0, 0)
    local prevAnchor = p3intro
    for i, line in ipairs(USE_ROWS) do
        local row = label(page3, "•  " .. line, "GameFontHighlightSmall", "TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, i == 1 and -10 or -4)
        row:SetPoint("RIGHT", page3, "RIGHT", 0, 0)
        row:SetTextColor(0.85, 0.85, 0.88)
        prevAnchor = row
    end
    local p3options = label(page3, USE_OPTIONS, "GameFontHighlightSmall", "TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -16)
    p3options:SetPoint("RIGHT", page3, "RIGHT", 0, 0)
    p3options:SetTextColor(0.70, 0.70, 0.74)
    local featureRows = {}
    prevAnchor = p3options
    for _, entry in ipairs(FEATURE_TOGGLES) do
        local row = createFeatureToggleRow(page3, entry, prevAnchor, ROW_GAP - 6)
        row.onChange = function(value)
            ns.db.profile[entry.key] = value
            ns:RefreshOptionsUI()
            ns:Render()
        end
        featureRows[entry.key] = row
        prevAnchor = row
    end
    local function refreshFeatures()
        for _, entry in ipairs(FEATURE_TOGGLES) do
            featureRows[entry.key]:SetChecked(ns.db.profile[entry.key] and true or false)
        end
    end

    local page4 = CreateFrame("Frame", nil, pagesHost)
    page4:SetAllPoints(pagesHost)
    local p4intro = label(page4, LOOK_INTRO, "GameFontHighlightSmall", "TOPLEFT", page4, "TOPLEFT", 0, 0)
    p4intro:SetPoint("RIGHT", page4, "RIGHT", 0, 0)
    p4intro:SetTextColor(0.70, 0.70, 0.74)
    local presetLabel = label(page4, "Preset", "GameFontHighlight", "TOPLEFT", p4intro, "BOTTOMLEFT", 0, -14)
    local presetChips = {}
    local presets = ns.PRESET_OPTIONS or {}
    local chipWidth = #presets > 0 and (math.floor((WIZARD_WIDTH - 68) / #presets) - 6) or 100
    local scaleRow, alphaRow
    local function refreshLook()
        if ns.DetectPresetKey then
            ns:DetectPresetKey()
        end
        for i = 1, #presetChips do
            presetChips[i]:SetSelected(presetChips[i].presetKey == ns.db.profile.presetKey)
        end
        if scaleRow then scaleRow:SetValue(tonumber(ns.db.profile.scale) or 1) end
        if alphaRow then alphaRow:SetValue(tonumber(ns.db.profile.alpha) or 0) end
    end
    for i, preset in ipairs(presets) do
        local chip = createStepChip(page4, nil, preset.short or preset.name, function()
            ns:ApplyPreset(preset.key, true)
            refreshLook()
        end)
        chip.presetKey = preset.key
        chip:SetSize(chipWidth, 26)
        if i == 1 then
            chip:SetPoint("TOPLEFT", presetLabel, "BOTTOMLEFT", 0, -8)
        else
            chip:SetPoint("LEFT", presetChips[i - 1], "RIGHT", 6, 0)
        end
        presetChips[i] = chip
    end
    local sliderAnchor = presetChips[1] or presetLabel
    scaleRow = createSliderRow(page4, "Scale", 0.70, 1.80, 110, sliderAnchor, -16, function(value)
        ns.db.profile.scale = tonumber(string.format("%.2f", value)) or 1
        ns:ApplyFrameSettings()
    end)
    alphaRow = createSliderRow(page4, "Opacity", 0.00, 1.00, 100, scaleRow, -6, function(value)
        ns.db.profile.alpha = tonumber(string.format("%.2f", value)) or 0
        ns:ApplyFrameSettings()
    end)
    local p4note = label(page4, "Watch the panel on screen while you adjust. Settings has fonts, colors, width and height, and export/import of your look.", "GameFontDisableSmall", "TOPLEFT", alphaRow, "BOTTOMLEFT", 0, -12)
    p4note:SetPoint("RIGHT", page4, "RIGHT", 0, 0)
    frame._refreshLook = refreshLook

    local page5 = CreateFrame("Frame", nil, pagesHost)
    page5:SetAllPoints(pagesHost)
    local p5body = label(page5, FINISH_BODY, "GameFontHighlight", "TOPLEFT", page5, "TOPLEFT", 0, 0)
    p5body:SetPoint("RIGHT", page5, "RIGHT", 0, 0)
    p5body:SetSpacing(4)
    local lockRow = createFeatureToggleRow(page5, {
        title = "Lock the panel in place",
        desc = "Turn off to keep it draggable after setup. /km unlock and /km lock change this any time.",
    }, p5body, -18)
    frame._lockRow = lockRow
    local openSettingsButton = createButton(page5, "Open Settings", 160, 26)
    openSettingsButton:SetPoint("TOPLEFT", lockRow, "BOTTOMLEFT", 0, -18)
    openSettingsButton:SetScript("OnClick", function()
        ns:FinishWelcomeWizard(lockRow.value)
        ns:ToggleOptionsUI()
    end)

    local pages = { page1, page2, page3, page4, page5 }
    frame._pages = pages
    frame._currentPage = 1

    local stepChips = {}
    local chipCount = #CHIP_TITLES
    for i, chipTitle in ipairs(CHIP_TITLES) do
        local chip = createStepChip(stepChipsRow, i, chipTitle, function()
            frame:SetPage(i)
        end)
        chip:SetHeight(30)
        chip:SetWidth(math.floor((WIZARD_WIDTH - 32 - (chipCount - 1) * 8) / chipCount))
        if i == 1 then
            chip:SetPoint("LEFT", stepChipsRow, "LEFT", 0, 0)
        else
            chip:SetPoint("LEFT", stepChips[i - 1], "RIGHT", 8, 0)
        end
        stepChips[i] = chip
    end

    function frame:SetPage(index)
        index = math.max(1, math.min(#pages, index))
        self._currentPage = index
        for i, p in ipairs(pages) do
            p:SetShown(i == index)
        end
        self._cardTitle:SetText(PAGE_TITLES[index])
        for i = 1, #stepChips do
            stepChips[i]:SetSelected(i == index)
        end
        stepText:SetText(string.format("Step %d of %d", index, #pages))
        backButton:SetShown(index > 1)
        nextButton:SetText(index == #pages and "Done" or "Next")
        if not ns.state.inChallenge then
            ns.db.profile.locked = (index ~= 2)
            ns:RefreshVisibility()
            ns:Render()
        end
        if index == 3 then
            refreshFeatures()
        elseif index == 4 then
            refreshLook()
        elseif index == 5 then
            if self._lockDefaultPending then
                self._lockDefaultPending = nil
                lockRow:SetChecked(self._originalLocked ~= false)
            end
        end
    end

    nextButton:SetScript("OnClick", function()
        if frame._currentPage == #pages then
            ns:FinishWelcomeWizard(lockRow.value)
            return
        end
        frame:SetPage(frame._currentPage + 1)
    end)
    backButton:SetScript("OnClick", function()
        frame:SetPage(frame._currentPage - 1)
    end)

    self.ui.welcome = frame
end

function ns:ApplyWelcomeTheme()
    local frame = self.ui.welcome
    if not frame then
        return
    end
    local r, g, b = accentRGB()
    frame._topStrip:SetGradient("HORIZONTAL", CreateColor(r, g, b, 1), CreateColor(r, g, b, 0.05))
    frame._topGlow:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 0.10))
    frame._title:SetTextColor(r, g, b)
    frame._cardTitle:SetTextColor(r, g, b)
    for i = 1, #themedRules do
        themedRules[i]:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.55), CreateColor(r, g, b, 0.04))
    end
    for i = 1, #themedStepChips do
        local chip = themedStepChips[i]
        chip:SetSelected(chip._selected)
    end
    for i = 1, #themedPrimaryButtons do
        local btn = themedPrimaryButtons[i]
        btn._border:SetColorTexture(r * 0.7, g * 0.7, b * 0.7, 1)
    end
    for i = 1, #themedToggles do
        local row = themedToggles[i]
        row:SetChecked(row.value)
    end
    if frame._previewCard then
        frame._previewCard:Refresh()
    end
end

function ns:ShowWelcomeWizard()
    if not self.ui.welcome then
        self:BuildWelcomeWizard()
    end
    if self.ui.options and self.ui.options:IsShown() then
        self.ui.options:Hide()
    end
    local frame = self.ui.welcome
    if frame._wizardOpen and frame:IsShown() then
        frame:Raise()
        return
    end
    frame._originalLocked = self.db.profile.locked
    frame._lockDefaultPending = true
    self.db.profile.seenSetupNotice = true
    if not self.state.inChallenge then
        self.ui.previewMode = true
        self:RefreshVisibility()
        self:Render()
    end
    frame._wizardOpen = true
    frame:SetPage(1)
    frame:Show()
end

local function closeWizard(frame)
    if frame then
        frame._wizardOpen = false
        frame:Hide()
    end
end

function ns:FinishWelcomeWizard(shouldLock)
    self.db.profile.locked = shouldLock and true or false
    self.db.profile.seenIntro = true
    self.db.profile.seenSetupNotice = true
    self.ui.previewMode = false
    closeWizard(self.ui.welcome)
    self:RefreshOptionsUI()
    self:RefreshVisibility()
    self:Render()
    self:Print("Setup complete. Type /km for settings or /km setup to see this guide again.")
end

function ns:SkipWelcomeWizard()
    local frame = self.ui.welcome
    self.db.profile.locked = (frame and frame._originalLocked)
    if self.db.profile.locked == nil then
        self.db.profile.locked = true
    end
    self.db.profile.seenIntro = true
    self.db.profile.seenSetupNotice = true
    self.ui.previewMode = false
    closeWizard(frame)
    self:RefreshOptionsUI()
    self:RefreshVisibility()
    self:Render()
end

function ns:AutoOpenWelcomeWizard()
    if self.db.profile.seenIntro then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        if not self._welcomeCombatFrame then
            self._welcomeCombatFrame = CreateFrame("Frame")
            self._welcomeCombatFrame:SetScript("OnEvent", function(watcher)
                watcher:UnregisterEvent("PLAYER_REGEN_ENABLED")
                ns:AutoOpenWelcomeWizard()
            end)
        end
        self._welcomeCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self:ShowWelcomeWizard()
end
