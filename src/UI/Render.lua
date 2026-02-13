local _, ns = ...

local FONT_PATHS = {
    FRIZQT = "Fonts\\FRIZQT__.TTF",
    ARIALN = "Fonts\\ARIALN.TTF",
    MORPHEUS = "Fonts\\MORPHEUS.TTF",
    SKURRI = "Fonts\\SKURRI.ttf",
}

local function savePosition()
    if not ns.ui.root then
        return
    end

    local centerX = ns.ui.root:GetLeft() + (ns.ui.root:GetWidth() / 2)
    local centerY = ns.ui.root:GetBottom() + (ns.ui.root:GetHeight() / 2)
    local parentX = UIParent:GetWidth() / 2
    local parentY = UIParent:GetHeight() / 2
    ns.db.profile.position.x = math.floor(centerX - parentX + 0.5)
    ns.db.profile.position.y = math.floor(centerY - parentY + 0.5)
end

local function updateAffixIcons()
    if not ns.ui.affixIcons then
        return
    end

    local affixes = ns:GetActiveAffixDisplayData()
    local visible = 0
    for i = 1, #ns.ui.affixIcons do
        local iconButton = ns.ui.affixIcons[i]
        local info = affixes[i]
        if info then
            iconButton.icon:SetTexture(info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconButton.affixName = info.name
            iconButton.affixDescription = info.description
            iconButton:Show()
            visible = visible + 1
        else
            iconButton.affixName = nil
            iconButton.affixDescription = nil
            iconButton:Hide()
        end
    end

    if visible > 0 then
        ns.ui.affixRow:Show()
    else
        ns.ui.affixRow:Hide()
    end
end

function ns:RestorePosition()
    if not self.ui.root then
        return
    end
    self.ui.root:ClearAllPoints()
    self.ui.root:SetPoint("CENTER", UIParent, "CENTER", self.db.profile.position.x, self.db.profile.position.y)
end

function ns:ApplyTheme()
    if not self.ui.root then
        return
    end

    local appearance = self.db.profile.appearance or {}
    local useClassColor = appearance.useClassColor and true or false

    local accentR, accentG, accentB, accentA
    if useClassColor then
        local classR, classG, classB = self:ClassColor()
        accentR, accentG, accentB, accentA = classR, classG, classB, 1
    else
        accentR, accentG, accentB, accentA = self:HexToRGBA(appearance.accentColor, 0.33, 0.73, 1.00, 1)
    end

    local backgroundR, backgroundG, backgroundB, backgroundA = self:HexToRGBA(appearance.backgroundColor, 0.05, 0.05, 0.05, 0.78)
    local borderR, borderG, borderB, borderA = self:HexToRGBA(appearance.borderColor, 0.2, 0.2, 0.2, 0.95)
    local textR, textG, textB, textA = self:HexToRGBA(appearance.textColor, 0.95, 0.95, 0.95, 1)
    local timerR, timerG, timerB, timerA = self:HexToRGBA(appearance.timerColor, accentR, accentG, accentB, 1)
    local barR, barG, barB, barA = self:HexToRGBA(appearance.forcesBarColor, accentR, accentG, accentB, 0.95)
    local barBGR, barBGG, barBGB, barBGA = self:HexToRGBA(appearance.forcesBarBGColor, 0.13, 0.13, 0.13, 0.9)

    self.ui.root:SetBackdropColor(backgroundR, backgroundG, backgroundB, backgroundA)
    self.ui.root:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    self.ui.accent:SetColorTexture(accentR, accentG, accentB, accentA)
    self.ui.timer:SetTextColor(timerR, timerG, timerB, timerA)
    self.ui.title:SetTextColor(accentR, accentG, accentB, accentA)
    self.ui.statusText:SetTextColor(textR, textG, textB, textA)
    self.ui.recordText:SetTextColor(textR, textG, textB, textA)
    self.ui.chest3:SetTextColor(textR, textG, textB, textA)
    self.ui.chest2:SetTextColor(textR, textG, textB, textA)
    self.ui.chest1:SetTextColor(textR, textG, textB, textA)
    self.ui.deaths:SetTextColor(textR, textG, textB, textA)
    self.ui.forcesText:SetTextColor(textR, textG, textB, textA)
    self.ui.forcesBar:SetStatusBarColor(barR, barG, barB, barA)
    self.ui.forcesBG:SetColorTexture(barBGR, barBGG, barBGB, barBGA)

    for i = 1, #self.ui.objectiveRows do
        self.ui.objectiveRows[i]:SetTextColor(textR, textG, textB, textA)
    end
end

function ns:ApplyFrameSettings()
    if not self.ui.root then
        return
    end

    local appearance = self.db.profile.appearance or {}
    local width = tonumber(appearance.frameWidth) or 350
    local height = tonumber(appearance.frameHeight) or 248
    local scale = tonumber(self.db.profile.scale) or 1
    local alpha = tonumber(self.db.profile.alpha) or 1
    local fontScale = tonumber(appearance.fontScale) or 1
    local titleFont = FONT_PATHS[appearance.titleFont] or FONT_PATHS.FRIZQT
    local timerFont = FONT_PATHS[appearance.timerFont] or FONT_PATHS.ARIALN
    local bodyFont = FONT_PATHS[appearance.bodyFont] or FONT_PATHS.FRIZQT

    self.ui.root:SetSize(width, height)
    self.ui.root:SetScale(scale)
    self.ui.root:SetAlpha(alpha)

    local function setFontScale(fontString, baseSize, fontPath)
        local currentFont, _, flags = fontString:GetFont()
        local resolved = fontPath or currentFont
        if resolved then
            fontString:SetFont(resolved, baseSize * fontScale, flags)
        end
    end

    setFontScale(self.ui.title, 16, titleFont)
    setFontScale(self.ui.timer, 30, timerFont)
    setFontScale(self.ui.chest3, 12, bodyFont)
    setFontScale(self.ui.chest2, 12, bodyFont)
    setFontScale(self.ui.chest1, 12, bodyFont)
    setFontScale(self.ui.statusText, 11, bodyFont)
    setFontScale(self.ui.recordText, 12, bodyFont)
    setFontScale(self.ui.forcesText, 12, bodyFont)
    setFontScale(self.ui.deaths, 14, bodyFont)
    for i = 1, #self.ui.objectiveRows do
        setFontScale(self.ui.objectiveRows[i], 11, bodyFont)
    end

    self:ApplyTheme()
    self:Render()
end

function ns:RefreshVisibility()
    if not self.ui.root then
        return
    end
    local unlockedVisible = (not self.db.profile.locked) and self.db.profile.showWhenUnlocked
    local previewVisible = self.ui.previewMode and true or false
    local shouldShow = self.state.inChallenge or unlockedVisible or previewVisible
    if shouldShow then
        self.ui.root:Show()
    else
        self.ui.root:Hide()
    end
end

function ns:Render()
    if not self.ui.root then
        return
    end

    local mapText = self.state.mapName
    if self.state.level and self.state.level > 0 then
        mapText = string.format("%s  +%d", self.state.mapName, self.state.level)
    end
    self.ui.title:SetText(mapText)
    self.ui.timer:SetText(self:FormatTime(self.state.elapsed))

    local recordSummary = self:GetRecordSummary()
    local comparisonSummary = self:GetBestTimedComparisonSummary()
    if recordSummary and comparisonSummary then
        self.ui.recordText:SetText(recordSummary .. "\n" .. comparisonSummary)
    else
        self.ui.recordText:SetText(recordSummary or comparisonSummary or "")
    end

    if self.state.challengeCompleted then
        if self.state.completedOnTime then
            self.ui.statusText:SetText("|cff7CFC00COMPLETED (Timed)|r")
        else
            self.ui.statusText:SetText("|cffFF9966COMPLETED|r")
        end
    else
        self.ui.statusText:SetText("")
    end
    updateAffixIcons()

    local limit = tonumber(self.state.timeLimit) or 0
    if limit <= 0 then
        self.ui.chest3:SetText("+3 --:--")
        self.ui.chest2:SetText("+2 --:--")
        self.ui.chest1:SetText("+1 --:--")
    else
        self.ui.chest3:SetText("+3 " .. self:FormatTime((limit * 0.6) - self.state.elapsed))
        self.ui.chest2:SetText("+2 " .. self:FormatTime((limit * 0.8) - self.state.elapsed))
        self.ui.chest1:SetText("+1 " .. self:FormatTime(limit - self.state.elapsed))
    end

    local total = tonumber(self.state.forcesTotal) or 0
    local current = tonumber(self.state.forcesCurrent) or 0
    if total > 0 then
        local pct = math.min(1, math.max(0, current / total))
        self.ui.forcesBar:SetValue(pct)
        if pct >= 1 then
            self.ui.forcesText:SetText(string.format("|cff7CFC00[Done]|r Forces %d / %d (100.0%%)", total, total))
        else
            self.ui.forcesText:SetText(string.format("|cffBFBFBF[ ]|r Forces %d / %d (%.1f%%)", current, total, pct * 100))
        end
    else
        self.ui.forcesBar:SetValue(0)
        self.ui.forcesText:SetText("|cffBFBFBF[ ]|r Forces 0 / 0 (0.0%)")
    end

    self.ui.deaths:SetText(string.format("Deaths %d  |  Penalty %s", self.state.deathCount, self:FormatTime(self.state.deathPenalty)))

    local maxObjectiveRows = #self.ui.objectiveRows
    local firstRow = self.ui.objectiveRows[1]
    local rootBottom = self.ui.root:GetBottom()
    if firstRow and rootBottom then
        local firstTop = firstRow:GetTop()
        if firstTop then
            local sampleHeight = math.max(10, firstRow:GetStringHeight())
            local rowStride = sampleHeight + 4
            local available = firstTop - (rootBottom + 8)
            maxObjectiveRows = math.floor(available / rowStride) + 1
            if maxObjectiveRows < 0 then
                maxObjectiveRows = 0
            end
            if maxObjectiveRows > #self.ui.objectiveRows then
                maxObjectiveRows = #self.ui.objectiveRows
            end
        end
    end

    for i = 1, #self.ui.objectiveRows do
        local row = self.ui.objectiveRows[i]
        local objective = self.state.objectives[i]
        if i > maxObjectiveRows then
            row:Hide()
        elseif objective then
            row:Show()
            if objective.completed then
                row:SetText(string.format("|cff7CFC00[Done]|r %s  |cffAFAFAF%s|r", objective.text, self:FormatTime(objective.doneAt or self.state.elapsed)))
            else
                row:SetText(string.format("|cffBFBFBF[ ]|r %s", objective.text))
            end
        else
            row:Hide()
        end
    end
end

function ns:BuildUI()
    local root = CreateFrame("Frame", "KeystoneMonitorFrame", UIParent, "BackdropTemplate")
    root:SetSize(350, 248)
    root:SetFrameStrata("HIGH")
    root:SetClampedToScreen(true)
    root:EnableMouse(true)
    root:SetMovable(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", function(frame)
        if ns.ui.previewMode or (not ns.db.profile.locked) then
            frame:StartMoving()
        end
    end)
    root:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        savePosition()
    end)
    root:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    root:SetBackdropColor(0.05, 0.05, 0.05, 0.78)
    root:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.95)

    local accent = root:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    accent:SetHeight(3)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 10, -10)
    title:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -10)
    title:SetJustifyH("LEFT")

    local timer = root:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    timer:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    timer:SetText("0:00")

    local chest3 = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chest3:SetPoint("LEFT", timer, "RIGHT", 18, 12)
    local chest2 = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chest2:SetPoint("TOPLEFT", chest3, "BOTTOMLEFT", 0, -3)
    local chest1 = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chest1:SetPoint("TOPLEFT", chest2, "BOTTOMLEFT", 0, -3)

    local recordText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    recordText:SetPoint("TOPLEFT", timer, "BOTTOMLEFT", 0, -2)
    recordText:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -48)
    recordText:SetJustifyH("LEFT")

    local affixRow = CreateFrame("Frame", nil, root)
    affixRow:SetPoint("TOPLEFT", recordText, "BOTTOMLEFT", 0, -6)
    affixRow:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -54)
    affixRow:SetHeight(18)

    local affixIcons = {}
    for i = 1, 4 do
        local iconButton = CreateFrame("Button", nil, affixRow)
        iconButton:SetSize(16, 16)
        if i == 1 then
            iconButton:SetPoint("LEFT", affixRow, "LEFT", 0, 0)
        else
            iconButton:SetPoint("LEFT", affixIcons[i - 1], "RIGHT", 6, 0)
        end

        local bg = iconButton:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local border = iconButton:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", iconButton, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", iconButton, "BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.2, 0.2, 0.2, 1)

        iconButton.icon = icon
        iconButton:SetScript("OnEnter", function(selfButton)
            if not selfButton.affixName then
                return
            end
            GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
            GameTooltip:AddLine(selfButton.affixName, 1, 1, 1)
            if selfButton.affixDescription and selfButton.affixDescription ~= "" then
                GameTooltip:AddLine(selfButton.affixDescription, 0.8, 0.8, 0.8, true)
            end
            GameTooltip:Show()
        end)
        iconButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        affixIcons[i] = iconButton
    end

    local forcesBar = CreateFrame("StatusBar", nil, root)
    forcesBar:SetPoint("TOPLEFT", affixRow, "BOTTOMLEFT", 0, -8)
    forcesBar:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -64)
    forcesBar:SetHeight(15)
    forcesBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    forcesBar:SetMinMaxValues(0, 1)
    forcesBar:SetValue(0)

    local forcesBG = forcesBar:CreateTexture(nil, "BACKGROUND")
    forcesBG:SetAllPoints()
    forcesBG:SetColorTexture(0.13, 0.13, 0.13, 0.9)

    local forcesText = forcesBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    forcesText:SetPoint("CENTER")

    local deaths = root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    deaths:SetPoint("TOPLEFT", forcesBar, "BOTTOMLEFT", 0, -9)
    deaths:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -92)
    deaths:SetJustifyH("LEFT")

    local statusText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", deaths, "BOTTOMLEFT", 0, -4)
    statusText:SetPoint("TOPRIGHT", deaths, "BOTTOMRIGHT", 0, -4)
    statusText:SetJustifyH("LEFT")
    statusText:SetWordWrap(false)

    local objectiveRows = {}
    for i = 1, 6 do
        local row = root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if i == 1 then
            row:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -6)
        else
            row:SetPoint("TOPLEFT", objectiveRows[i - 1], "BOTTOMLEFT", 0, -4)
        end
        row:SetPoint("RIGHT", root, "RIGHT", -10, 0)
        row:SetWordWrap(false)
        row:SetJustifyH("LEFT")
        objectiveRows[i] = row
    end

    self.ui.root = root
    self.ui.accent = accent
    self.ui.title = title
    self.ui.timer = timer
    self.ui.chest3 = chest3
    self.ui.chest2 = chest2
    self.ui.chest1 = chest1
    self.ui.statusText = statusText
    self.ui.recordText = recordText
    self.ui.affixRow = affixRow
    self.ui.affixIcons = affixIcons
    self.ui.forcesBar = forcesBar
    self.ui.forcesText = forcesText
    self.ui.forcesBG = forcesBG
    self.ui.deaths = deaths
    self.ui.objectiveRows = objectiveRows

    self:RestorePosition()
    self:ApplyFrameSettings()
end
