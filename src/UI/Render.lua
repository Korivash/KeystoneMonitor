local _, ns = ...

local FONT_PATHS = {
    FRIZQT = "Fonts\\FRIZQT__.TTF",
    ARIALN = "Fonts\\ARIALN.TTF",
    MORPHEUS = "Fonts\\MORPHEUS.TTF",
    SKURRI = "Fonts\\SKURRI.ttf",
}

local TIMER_FAILED_COLOR = "FFFF2A2E"

local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"
local ICON_DONE = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:-1|t"
local ICON_ENGAGED = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:12:12:0:-1|t"
local ICON_PENDING = "|TInterface\\COMMON\\Indicator-Gray:10:10:0:-1|t"

local BAR_EPSILON = 0.002

local function updateBarSpark(bar)
    local spark = bar._kmSpark
    if not spark then
        return
    end
    local value = bar._kmDisplay or bar:GetValue() or 0
    if value <= 0.001 or value >= 0.999 then
        spark:Hide()
        return
    end
    spark:ClearAllPoints()
    spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * value, 0)
    spark:Show()
end

local function barOnUpdate(bar, elapsed)
    local current = bar._kmDisplay or 0
    local target = bar._kmTarget or 0
    if math.abs(target - current) <= BAR_EPSILON then
        bar._kmDisplay = target
        bar:SetValue(target)
        bar:SetScript("OnUpdate", nil)
    else
        bar._kmDisplay = current + (target - current) * math.min(elapsed * 9, 1)
        bar:SetValue(bar._kmDisplay)
    end
    updateBarSpark(bar)
end

local function setBarValue(bar, target)
    target = math.min(1, math.max(0, target or 0))
    if bar._kmTarget == target then
        return
    end
    bar._kmTarget = target
    if not bar:IsVisible() then
        bar._kmDisplay = target
        bar:SetValue(target)
        bar:SetScript("OnUpdate", nil)
        updateBarSpark(bar)
        return
    end
    bar:SetScript("OnUpdate", barOnUpdate)
end

local function setText(fontString, text)
    if fontString._kmText ~= text then
        fontString._kmText = text
        fontString:SetText(text)
    end
end

local function setTimerColor(fontString, r, g, b, a)
    if fontString._kmR ~= r or fontString._kmG ~= g or fontString._kmB ~= b or fontString._kmA ~= a then
        fontString._kmR, fontString._kmG, fontString._kmB, fontString._kmA = r, g, b, a
        fontString:SetTextColor(r, g, b, a)
    end
end

local floodgateCompletedPreview
local inProgressPreview

local function getFloodgateCompletedPreviewState()
    if not floodgateCompletedPreview then
        floodgateCompletedPreview = {
            inChallenge = true,
            mode = "MYTHIC_PLUS",
            challengeCompleted = true,
            completedOnTime = true,
            completionTimeMs = 1974000,
            elapsed = 1974,
            timeLimit = 2040,
            mapID = nil,
            mapName = "Operation: Floodgate",
            level = 10,
            deathCount = 6,
            deathPenalty = 30,
            forcesCurrent = 100,
            forcesTotal = 100,
            forcesCompleted = true,
            objectives = {
                { text = "Douse Security", completed = true, doneAt = 430 },
                { text = "Disable Aqua Grid", completed = true, doneAt = 1120 },
                { text = "Defeat Head Engineer", completed = true, doneAt = 1865 },
            },
        }
    end
    return floodgateCompletedPreview
end

local function getInProgressPreviewState()
    if not inProgressPreview then
        inProgressPreview = {
            inChallenge = true,
            mode = "MYTHIC_PLUS",
            challengeCompleted = false,
            completedOnTime = nil,
            completionTimeMs = nil,
            elapsed = 1286,
            timeLimit = 2040,
            mapID = nil,
            mapName = "Operation: Floodgate",
            level = 10,
            deathCount = 4,
            deathPenalty = 20,
            forcesCurrent = 78,
            forcesTotal = 100,
            objectives = {
                { text = "Douse Security", completed = true, doneAt = 430 },
                { text = "Disable Aqua Grid", completed = false, doneAt = nil },
                { text = "Defeat Head Engineer", completed = false, doneAt = nil },
            },
        }
    end
    return inProgressPreview
end

local function resolveRenderState()
    if ns.ui.previewMode then
        local previewScenario = ns.db.profile.previewScenario or "LIVE"
        if previewScenario == "FLOODGATE_COMPLETED" then
            return getFloodgateCompletedPreviewState(), true
        elseif previewScenario == "IN_PROGRESS" then
            return getInProgressPreviewState(), true
        end
    end
    return ns.state, false
end

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

    local panelAlpha = tonumber(self.db.profile.alpha) or 1
    if panelAlpha < 0 then
        panelAlpha = 0
    elseif panelAlpha > 1 then
        panelAlpha = 1
    end

    local backgroundR, backgroundG, backgroundB, backgroundA = self:HexToRGBA(appearance.backgroundColor, 0.05, 0.05, 0.05, 0.78)
    backgroundA = backgroundA * panelAlpha
    local borderR, borderG, borderB, borderA = self:HexToRGBA(appearance.borderColor, 0.2, 0.2, 0.2, 0.95)
    borderA = borderA * panelAlpha
    local textR, textG, textB, textA = self:HexToRGBA(appearance.textColor, 0.95, 0.95, 0.95, 1)
    local timerR, timerG, timerB, timerA = self:HexToRGBA(appearance.timerColor, accentR, accentG, accentB, 1)
    local barR, barG, barB, barA = self:HexToRGBA(appearance.forcesBarColor, accentR, accentG, accentB, 0.95)
    local barBGR, barBGG, barBGB, barBGA = self:HexToRGBA(appearance.forcesBarBGColor, 0.13, 0.13, 0.13, 0.9)

    self.ui.root:SetBackdropColor(backgroundR, backgroundG, backgroundB, backgroundA)
    self.ui.root:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    self.ui.accent:SetGradient("HORIZONTAL", CreateColor(accentR, accentG, accentB, accentA), CreateColor(accentR, accentG, accentB, 0.05))
    self.ui.accentGlow:SetGradient("VERTICAL", CreateColor(accentR, accentG, accentB, 0), CreateColor(accentR, accentG, accentB, 0.12))
    self.ui.sheen:SetGradient("VERTICAL", CreateColor(accentR, accentG, accentB, 0), CreateColor(accentR, accentG, accentB, 0.07 * panelAlpha))
    self.ui.timer._kmR = nil
    self.ui.timer:SetTextColor(timerR, timerG, timerB, timerA)
    self.ui.title:SetTextColor(accentR, accentG, accentB, accentA)
    self.ui.statusText:SetTextColor(textR, textG, textB, textA)
    self.ui.recordText:SetTextColor(textR, textG, textB, textA)
    self.ui.chest3:SetTextColor(textR, textG, textB, textA)
    self.ui.chest2:SetTextColor(textR, textG, textB, textA)
    self.ui.chest1:SetTextColor(textR, textG, textB, textA)
    self.ui.deaths:SetTextColor(textR, textG, textB, textA)
    self.ui.forcesText:SetTextColor(textR, textG, textB, textA)
    local barFill = self.ui.forcesBar:GetStatusBarTexture()
    if barFill then
        barFill:SetGradient("VERTICAL", CreateColor(barR * 0.65, barG * 0.65, barB * 0.65, barA), CreateColor(barR, barG, barB, barA))
    end
    self.ui.forcesBG:SetColorTexture(barBGR, barBGG, barBGB, barBGA)

    for i = 1, #self.ui.objectiveRows do
        self.ui.objectiveRows[i]:SetTextColor(textR, textG, textB, textA)
    end

    if self.ApplyHistoryTheme then
        self:ApplyHistoryTheme()
    end
    if self.ApplyOptionsTheme then
        self:ApplyOptionsTheme()
    end
end

function ns:ApplyFrameSettings()
    if not self.ui.root then
        return
    end

    local appearance = self.db.profile.appearance or {}
    local width = tonumber(appearance.frameWidth) or 288
    local height = tonumber(appearance.frameHeight) or 258
    local scale = tonumber(self.db.profile.scale) or 1
    local fontScale = tonumber(appearance.fontScale) or 1
    local titleFont = FONT_PATHS[appearance.titleFont] or FONT_PATHS.FRIZQT
    local timerFont = FONT_PATHS[appearance.timerFont] or FONT_PATHS.ARIALN
    local bodyFont = FONT_PATHS[appearance.bodyFont] or FONT_PATHS.FRIZQT

    self.ui.root:SetSize(width, height)
    self.ui.root:SetScale(scale)
    updateBarSpark(self.ui.forcesBar)

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
    self:UpdateObjectiveTrackerVisibility()
end

function ns:RenderTimer()
    if not self.ui.root then
        return
    end

    local state, isPreview = resolveRenderState()
    local isMythicPlus = state.mode == "MYTHIC_PLUS"
    local elapsed = tonumber(state.elapsed) or 0
    local limit = tonumber(state.timeLimit) or 0

    if not isMythicPlus and not self.db.profile.showUntimedStopwatch then
        setText(self.ui.timer, "")
        return
    end

    local timerText = self:FormatTime(elapsed)
    if isMythicPlus and limit > 0 then
        timerText = timerText .. "/" .. self:FormatTime(limit)
    end
    setText(self.ui.timer, timerText)

    local appearance = self.db.profile.appearance or {}
    local useClassColor = appearance.useClassColor and true or false
    local accentR, accentG, accentB
    if useClassColor then
        accentR, accentG, accentB = self:ClassColor()
    else
        accentR, accentG, accentB = self:HexToRGBA(appearance.accentColor, 0.33, 0.73, 1.00, 1)
    end

    local timerFailed = isMythicPlus and (limit > 0) and (elapsed > limit)
    if isMythicPlus and (timerFailed or (state.challengeCompleted and not state.completedOnTime)) then
        local failR, failG, failB, failA = self:HexToRGBA(TIMER_FAILED_COLOR, 1, 0.16, 0.18, 1)
        setTimerColor(self.ui.timer, failR, failG, failB, failA)
    else
        local timerR, timerG, timerB, timerA = self:HexToRGBA(appearance.timerColor, accentR, accentG, accentB, 1)
        setTimerColor(self.ui.timer, timerR, timerG, timerB, timerA)
    end

    if not isMythicPlus then
        return
    end

    if limit <= 0 then
        setText(self.ui.chest3, "+3 --:--")
        setText(self.ui.chest2, "+2 --:--")
        setText(self.ui.chest1, "+1 --:--")
    else
        local tl = state.timeLimits
        local t3 = (tl and tl[3]) or (limit * 0.6)
        local t2 = (tl and tl[2]) or (limit * 0.8)
        local t1 = (tl and tl[1]) or limit
        setText(self.ui.chest3, "+3 " .. self:FormatTime(t3 - elapsed))
        setText(self.ui.chest2, "+2 " .. self:FormatTime(t2 - elapsed))
        setText(self.ui.chest1, "+1 " .. self:FormatTime(t1 - elapsed))
    end

    if state.challengeCompleted then
        if state.completedOnTime then
            setText(self.ui.statusText, "|cff7CFC00COMPLETED (Timed)|r")
        else
            setText(self.ui.statusText, "|cffFF2A2EFAILED|r")
        end
    elseif self.db.profile.showPaceHints and limit > 0 then
        local penalty = tonumber(state.deathPenalty) or 0
        local effective = elapsed + penalty
        local tl = state.timeLimits
        local t3 = (tl and tl[3]) or (limit * 0.6)
        local t2 = (tl and tl[2]) or (limit * 0.8)
        local t1 = (tl and tl[1]) or limit
        if effective <= t3 then
            setText(self.ui.statusText, "|cff7CFC00PACE: +3|r")
        elseif effective <= t2 then
            setText(self.ui.statusText, "|cff53B9FFPACE: +2|r")
        elseif effective <= t1 then
            setText(self.ui.statusText, "|cffFFD966PACE: +1|r")
        else
            setText(self.ui.statusText, "|cffFF6666PACE: Overtime|r")
        end
    else
        setText(self.ui.statusText, "")
    end

    if isPreview then
        setText(self.ui.recordText, "PB 32:54  |  Best Timed +10 32:54")
    else
        local recordSummary = self:GetRecordSummary()
        local comparisonSummary = self:GetBestTimedComparisonSummary()
        if recordSummary and comparisonSummary then
            setText(self.ui.recordText, recordSummary .. "\n" .. comparisonSummary)
        else
            setText(self.ui.recordText, recordSummary or comparisonSummary or "")
        end
    end
end

function ns:Render()
    if not self.ui.root then
        return
    end

    local state = resolveRenderState()
    local isMythicPlus = state.mode == "MYTHIC_PLUS"

    local mapText = state.mapName
    if isMythicPlus and state.level and state.level > 0 then
        mapText = string.format("%s  +%d", state.mapName, state.level)
    end
    setText(self.ui.title, mapText)

    if isMythicPlus then
        updateAffixIcons()
        self.ui.chest3:Show()
        self.ui.chest2:Show()
        self.ui.chest1:Show()
        self.ui.forcesBar:Show()
        self.ui.forcesText:Show()
        self.ui.deaths:Show()

        local total = tonumber(state.forcesTotal) or 0
        local current = tonumber(state.forcesCurrent) or 0
        if total > 0 then
            local pct = math.min(1, math.max(0, current / total))
            setBarValue(self.ui.forcesBar, pct)
            if state.forcesCompleted or pct >= 1 then
                setText(self.ui.forcesText, string.format(ICON_DONE .. " Forces %d / %d", total, total))
            else
                setText(self.ui.forcesText, string.format("Forces %d / %d  ·  %.1f%%", current, total, pct * 100))
            end
        else
            setBarValue(self.ui.forcesBar, 0)
            setText(self.ui.forcesText, "Forces 0 / 0  ·  0.0%")
        end

        local deathCount = tonumber(state.deathCount) or 0
        local deathText = deathCount > 0 and string.format("|cffFF5C5C%d|r", deathCount) or "0"
        setText(self.ui.deaths, string.format("Deaths %s  ·  Penalty %s", deathText, self:FormatTime(state.deathPenalty)))
    else
        self.ui.affixRow:Hide()
        self.ui.chest3:Hide()
        self.ui.chest2:Hide()
        self.ui.chest1:Hide()
        self.ui.forcesBar:Show()
        self.ui.forcesText:Show()
        self.ui.deaths:Show()

        local done = tonumber(state.bossesDone) or 0
        local total = tonumber(state.bossesTotal) or 0
        if total > 0 then
            setBarValue(self.ui.forcesBar, done / total)
        else
            setBarValue(self.ui.forcesBar, 0)
        end
        setText(self.ui.forcesText, string.format("Bosses %d / %d", done, total))
        local deathCount = tonumber(state.deathCount) or 0
        local deathText = deathCount > 0 and string.format("|cffFF5C5C%d|r", deathCount) or "0"
        setText(self.ui.deaths, string.format("Deaths %s", deathText))

        setText(self.ui.recordText, self:GetDungeonRecordSummary())
        if state.challengeCompleted then
            setText(self.ui.statusText, string.format("|cff7CFC00COMPLETE  %s|r", self:FormatTime(state.elapsed)))
        else
            setText(self.ui.statusText, string.format("Bosses %d / %d", done, total))
        end
    end

    for i = 1, #self.ui.objectiveRows do
        local row = self.ui.objectiveRows[i]
        local objective = state.objectives[i]
        if objective then
            row:Show()
            if objective.completed then
                local deltaText = ""
                local delta = self:GetSplitDelta(objective, i)
                if delta then
                    local color = delta > 0 and "ffFF6666" or "ff7CFC00"
                    deltaText = string.format("  |c%s(%s)|r", color, self:FormatDelta(delta))
                end
                setText(row, string.format(
                    ICON_DONE .. " %s  |cffAFAFAF%s|r%s",
                    objective.text,
                    self:FormatTime(objective.doneAt or state.elapsed),
                    deltaText
                ))
            elseif objective.engaged then
                setText(row, string.format(ICON_ENGAGED .. " |cffFFD100%s|r", objective.text))
            else
                setText(row, string.format(ICON_PENDING .. " |cff9D9DA3%s|r", objective.text))
            end
        else
            row:Hide()
        end
    end

    self:RenderTimer()
end

function ns:BuildUI()
    local root = CreateFrame("Frame", "KeystoneMonitorFrame", UIParent, "BackdropTemplate")
    root:SetSize(288, 258)
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
    accent:SetTexture(WHITE8X8)

    local accentGlow = root:CreateTexture(nil, "BORDER")
    accentGlow:SetPoint("TOPLEFT", accent, "BOTTOMLEFT", 0, 0)
    accentGlow:SetPoint("TOPRIGHT", accent, "BOTTOMRIGHT", 0, 0)
    accentGlow:SetHeight(14)
    accentGlow:SetTexture(WHITE8X8)

    local sheen = root:CreateTexture(nil, "BACKGROUND", nil, 1)
    sheen:SetPoint("TOPLEFT", root, "TOPLEFT", 1, -1)
    sheen:SetPoint("BOTTOMRIGHT", root, "TOPRIGHT", -1, -90)
    sheen:SetTexture(WHITE8X8)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 10, -10)
    title:SetPoint("TOPRIGHT", root, "TOPRIGHT", -30, -10)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)

    local historyButton = CreateFrame("Button", nil, root)
    historyButton:SetSize(16, 16)
    historyButton:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -8)
    historyButton:SetAlpha(0.35)
    local historyIcon = historyButton:CreateTexture(nil, "ARTWORK")
    historyIcon:SetAllPoints()
    historyIcon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    historyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    historyIcon:SetDesaturated(true)
    historyButton:SetScript("OnEnter", function(selfButton)
        selfButton:SetAlpha(1)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Run History", 1, 1, 1)
        GameTooltip:AddLine("Opens the Keystone Monitor window", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    historyButton:SetScript("OnLeave", function(selfButton)
        selfButton:SetAlpha(0.35)
        GameTooltip:Hide()
    end)
    historyButton:SetScript("OnClick", function()
        ns:ShowHistoryTab()
    end)

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
    recordText:SetPoint("TOPLEFT", timer, "BOTTOMLEFT", 0, -14)
    recordText:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -58)
    recordText:SetJustifyH("CENTER")

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
    forcesBar:SetStatusBarTexture(WHITE8X8)
    forcesBar:SetMinMaxValues(0, 1)
    forcesBar:SetValue(0)

    local forcesSpark = forcesBar:CreateTexture(nil, "OVERLAY")
    forcesSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    forcesSpark:SetBlendMode("ADD")
    forcesSpark:SetSize(14, 34)
    forcesSpark:Hide()
    forcesBar._kmSpark = forcesSpark

    local forcesBG = forcesBar:CreateTexture(nil, "BACKGROUND")
    forcesBG:SetAllPoints()
    forcesBG:SetColorTexture(0.13, 0.13, 0.13, 0.9)

    local forcesText = forcesBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    forcesText:SetPoint("CENTER")

    local deaths = root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    deaths:SetPoint("TOPLEFT", forcesBar, "BOTTOMLEFT", 0, -9)
    deaths:SetPoint("TOPRIGHT", root, "TOPRIGHT", -10, -92)
    deaths:SetJustifyH("LEFT")

    local deathsButton = CreateFrame("Button", nil, root)
    deathsButton:SetAllPoints(deaths)
    deathsButton:RegisterForDrag("LeftButton")
    deathsButton:SetScript("OnDragStart", function()
        if ns.ui.previewMode or (not ns.db.profile.locked) then
            root:StartMoving()
        end
    end)
    deathsButton:SetScript("OnDragStop", function()
        root:StopMovingOrSizing()
        savePosition()
    end)
    deathsButton:SetScript("OnEnter", function(selfButton)
        local log = ns.state.deathLog
        if not log or #log == 0 then
            return
        end
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Death Log", 1, 1, 1)
        local first = math.max(1, #log - 14)
        if first > 1 then
            GameTooltip:AddLine(string.format("(%d earlier deaths hidden)", first - 1), 0.6, 0.6, 0.6)
        end
        for i = first, #log do
            local entry = log[i]
            local color = entry.class and RAID_CLASS_COLORS[entry.class]
            GameTooltip:AddDoubleLine(
                entry.name or "?",
                ns:FormatTime(entry.t or 0),
                color and color.r or 0.9, color and color.g or 0.9, color and color.b or 0.9,
                0.7, 0.7, 0.7
            )
        end
        GameTooltip:Show()
    end)
    deathsButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local statusText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", deaths, "BOTTOMLEFT", 0, -4)
    statusText:SetPoint("TOPRIGHT", deaths, "BOTTOMRIGHT", 0, -4)
    statusText:SetJustifyH("LEFT")
    statusText:SetWordWrap(false)

    local objectiveRows = {}
    for i = 1, 10 do
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
    self.ui.accentGlow = accentGlow
    self.ui.sheen = sheen
    self.ui.historyButton = historyButton
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
    self.ui.deathsButton = deathsButton
    self.ui.objectiveRows = objectiveRows

    self:RestorePosition()
    self:ApplyFrameSettings()
end
