local _, ns = ...

local WIZARD_WIDTH = 560
local WIZARD_HEIGHT = 560
local ROW_HEIGHT = 40
local ROW_GAP = -4

local FEATURE_TOGGLES = {
    { key = "showPaceHints", title = "Pace Hints", desc = "Live +1/+2/+3 pace estimate during the run." },
    { key = "showBestTimedComparison", title = "Best Time Comparison", desc = "Compares this run to your personal best." },
    { key = "autoSlotKeystone", title = "Auto-Slot Keystone", desc = "Places your keystone in the font automatically." },
    { key = "announceNewKey", title = "Announce New Key (You)", desc = "Prints a message to you when you loot a new key." },
    { key = "announceNewKeyToParty", title = "Announce New Key to Party", desc = "Shares your new key in party chat." },
    { key = "announceDungeonCompleteToParty", title = "Announce Completion to Party", desc = "Posts your run result to party chat when it ends." },
}

local PAGE_TITLES = { "Welcome", "Place Your Monitor", "Choose Your Features", "You're All Set" }

local WELCOME_BODY = "Keystone Monitor tracks your Mythic+ runs live: a countdown timer against the time limit, chest-timer splits, pace hints, a death log, and affix info -- plus full run history and personal bests.\n\nThis quick setup helps you place the monitor and choose which features you want. It takes about 30 seconds, and you can rerun it anytime with /km tutorial."
local PLACEMENT_BODY = "The monitor is now unlocked and showing a live preview so you can see it while you work. Click and drag anywhere on its body to move it.\n\nTake your time. When it's where you want it, click Next."
local FEATURES_INTRO = "Toggle any of these on or off. You can change them later in /km options."
local FINISH_BODY = "You're all set. The monitor will appear automatically whenever you're in a tracked dungeon.\n\nYou can also fully customize the look -- colors, fonts, size, and ready-made presets -- from /km options. Replay this tutorial anytime with /km tutorial."

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
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
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

    button.text = label(button, index .. "  " .. text, "GameFontHighlightSmall", "CENTER", button, "CENTER", 0, 0)
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
    end)
    row:SetChecked(false)
    themedToggles[#themedToggles + 1] = row
    return row
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

    local accentR, accentG, accentB = accentRGB()

    local topStrip = frame:CreateTexture(nil, "OVERLAY")
    topStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topStrip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topStrip:SetHeight(2)
    topStrip:SetTexture("Interface\\Buttons\\WHITE8X8")
    topStrip:SetGradient("HORIZONTAL", CreateColor(accentR, accentG, accentB, 1), CreateColor(accentR, accentG, accentB, 0.05))

    local topGlow = frame:CreateTexture(nil, "ARTWORK")
    topGlow:SetPoint("TOPLEFT", topStrip, "BOTTOMLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", topStrip, "BOTTOMRIGHT", 0, 0)
    topGlow:SetHeight(16)
    topGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
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
    local sub = label(header, "Placement · Features · Setup", "GameFontHighlightSmall", "LEFT", headerTitle, "RIGHT", 12, -1)
    sub:SetTextColor(0.55, 0.55, 0.60)

    frame._topStrip = topStrip
    frame._topGlow = topGlow
    frame._title = headerTitle

    local skipButton = createButton(header, "Skip Tutorial", 108, 24)
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
    cardRule:SetTexture("Interface\\Buttons\\WHITE8X8")
    cardRule:SetGradient("HORIZONTAL", CreateColor(accentR, accentG, accentB, 0.55), CreateColor(accentR, accentG, accentB, 0.04))
    themedRules[#themedRules + 1] = cardRule
    frame._cardTitle = cardTitle

    local pagesHost = CreateFrame("Frame", nil, content)
    pagesHost:SetPoint("TOPLEFT", cardRule, "BOTTOMLEFT", 0, -14)
    pagesHost:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    local page1 = CreateFrame("Frame", nil, pagesHost)
    page1:SetAllPoints(pagesHost)
    local p1body = label(page1, WELCOME_BODY, "GameFontHighlight", "TOPLEFT", page1, "TOPLEFT", 0, 0)
    p1body:SetPoint("RIGHT", page1, "RIGHT", 0, 0)
    p1body:SetSpacing(4)

    local page2 = CreateFrame("Frame", nil, pagesHost)
    page2:SetAllPoints(pagesHost)
    local p2body = label(page2, PLACEMENT_BODY, "GameFontHighlight", "TOPLEFT", page2, "TOPLEFT", 0, 0)
    p2body:SetPoint("RIGHT", page2, "RIGHT", 0, 0)
    p2body:SetSpacing(4)

    local resetButton = createButton(page2, "Reset to Default Position", 200, 26)
    resetButton:SetPoint("TOPLEFT", p2body, "BOTTOMLEFT", 0, -18)
    resetButton:SetScript("OnClick", function()
        ns.db.profile.position.x = 0
        ns.db.profile.position.y = 120
        ns:RestorePosition()
    end)

    local page3 = CreateFrame("Frame", nil, pagesHost)
    page3:SetAllPoints(pagesHost)
    local p3intro = label(page3, FEATURES_INTRO, "GameFontHighlightSmall", "TOPLEFT", page3, "TOPLEFT", 0, 0)
    p3intro:SetPoint("RIGHT", page3, "RIGHT", 0, 0)
    p3intro:SetTextColor(0.70, 0.70, 0.74)

    local featureRows = {}
    local prevAnchor = p3intro
    for _, entry in ipairs(FEATURE_TOGGLES) do
        local row = createFeatureToggleRow(page3, entry, prevAnchor, ROW_GAP)
        featureRows[entry.key] = row
        prevAnchor = row
    end

    local page4 = CreateFrame("Frame", nil, pagesHost)
    page4:SetAllPoints(pagesHost)
    local p4body = label(page4, FINISH_BODY, "GameFontHighlight", "TOPLEFT", page4, "TOPLEFT", 0, 0)
    p4body:SetPoint("RIGHT", page4, "RIGHT", 0, 0)
    p4body:SetSpacing(4)

    local lockRow = createFeatureToggleRow(page4, {
        title = "Lock Monitor In Place",
        desc = "Uncheck to keep it draggable after setup.",
    }, p4body, -18)

    local openSettingsButton = createButton(page4, "Customize Appearance", 200, 26)
    openSettingsButton:SetPoint("TOPLEFT", lockRow, "BOTTOMLEFT", 0, -18)
    openSettingsButton:SetScript("OnClick", function()
        ns:FinishWelcomeWizard(lockRow.value)
        ns:ToggleOptionsUI()
    end)

    local pages = { page1, page2, page3, page4 }
    frame._pages = pages
    frame._currentPage = 1

    local stepChips = {}
    for i, pageTitle in ipairs(PAGE_TITLES) do
        local chip = createStepChip(stepChipsRow, i, pageTitle, function()
            frame:SetPage(i)
        end)
        chip:SetHeight(30)
        if i == 1 then
            chip:SetPoint("LEFT", stepChipsRow, "LEFT", 0, 0)
            chip:SetPoint("RIGHT", stepChipsRow, "LEFT", 128, 0)
        else
            chip:SetPoint("LEFT", stepChips[i - 1], "RIGHT", 8, 0)
            chip:SetWidth(122)
        end
        stepChips[i] = chip
    end

    function frame:SetPage(index)
        index = math.max(1, math.min(#pages, index))

        if self._currentPage == 3 and index ~= 3 then
            for _, entry in ipairs(FEATURE_TOGGLES) do
                ns.db.profile[entry.key] = featureRows[entry.key].value
            end
            ns:RefreshOptionsUI()
            ns:Render()
        end

        self._currentPage = index
        for i, p in ipairs(pages) do
            if i == index then
                p:Show()
            else
                p:Hide()
            end
        end

        self._cardTitle:SetText(PAGE_TITLES[index])
        for i = 1, #stepChips do
            stepChips[i]:SetSelected(i == index)
        end
        backButton:SetShown(index > 1)
        nextButton:SetText(index == #pages and "Finish" or "Next")

        if index == 3 then
            for _, entry in ipairs(FEATURE_TOGGLES) do
                featureRows[entry.key]:SetChecked(ns.db.profile[entry.key] and true or false)
            end
        elseif index == 4 then
            lockRow:SetChecked(true)
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
end

function ns:ShowWelcomeWizard()
    if not self.ui.welcome then
        self:BuildWelcomeWizard()
    end

    if self.ui.options and self.ui.options:IsShown() then
        self.ui.options:Hide()
    end

    local frame = self.ui.welcome
    frame._originalLocked = self.db.profile.locked

    if not self.state.inChallenge then
        self.db.profile.locked = false
        self.ui.previewMode = true
        self:RefreshVisibility()
        self:Render()
    end

    frame:SetPage(1)
    frame:Show()
end

function ns:FinishWelcomeWizard(shouldLock)
    self.db.profile.locked = shouldLock and true or false
    self.db.profile.seenIntro = true
    self.ui.previewMode = false
    if self.ui.welcome then
        self.ui.welcome:Hide()
    end
    self:RefreshOptionsUI()
    self:RefreshVisibility()
    self:Render()
    self:Print("Setup complete. Use /km options for full settings or /km tutorial to see this again.")
end

function ns:SkipWelcomeWizard()
    local frame = self.ui.welcome
    self.db.profile.locked = (frame and frame._originalLocked)
    if self.db.profile.locked == nil then
        self.db.profile.locked = true
    end
    self.db.profile.seenIntro = true
    self.ui.previewMode = false
    if frame then
        frame:Hide()
    end
    self:RefreshOptionsUI()
    self:RefreshVisibility()
    self:Render()
end
