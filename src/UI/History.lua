local _, ns = ...

local ROW_HEIGHT = 42
local SIDE_INSET = 16

local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"

local MODE_CHIPS = {
    FOLLOWER = { text = "F", r = 0.62, g = 0.62, b = 0.62 },
    NORMAL = { text = "N", r = 0.62, g = 0.62, b = 0.62 },
    HEROIC = { text = "HC", r = 0.31, g = 0.68, b = 0.31 },
    TIMEWALKING = { text = "TW", r = 0.44, g = 0.72, b = 0.90 },
    MYTHIC_ZERO = { text = "M0", r = 0.79, g = 0.60, b = 0.29 },
}

local FILTERS = {
    { key = "ALL", label = "All" },
    { key = "MYTHIC_PLUS", label = "Mythic+" },
    { key = "DUNGEON", label = "Dungeons" },
}

local VIEWS = {
    { key = "RUNS", label = "Runs" },
    { key = "BEST_TIMED", label = "Best Timed" },
    { key = "HIGHEST_KEY", label = "Highest Key" },
}

local function keyLevelColor(level)
    if level >= 12 then
        return 1.00, 0.50, 0.00
    elseif level >= 10 then
        return 0.64, 0.21, 0.93
    elseif level >= 7 then
        return 0.25, 0.55, 1.00
    end
    return 0.12, 1.00, 0.00
end

local function runMatchesFilter(run, filter)
    if filter == "ALL" then
        return true
    end
    if filter == "MYTHIC_PLUS" then
        return run.mode == "MYTHIC_PLUS"
    end
    return run.mode ~= "MYTHIC_PLUS"
end

local function accentColor()
    local appearance = ns.db.profile.appearance or {}
    if appearance.useClassColor then
        local r, g, b = ns:ClassColor()
        return r, g, b
    end
    return ns:HexToRGBA(appearance.accentColor, 0.33, 0.73, 1.00, 1)
end

local function createStatTile(parent, index)
    local tile = {}
    local columnWidth = 190

    tile.value = parent:CreateFontString(nil, "OVERLAY")
    tile.value:SetFont("Fonts\\ARIALN.TTF", 20, "")
    tile.value:SetPoint("TOP", parent, "TOPLEFT", SIDE_INSET + columnWidth * (index - 0.5), -52)
    tile.value:SetTextColor(0.95, 0.95, 0.95, 1)

    tile.label = parent:CreateFontString(nil, "OVERLAY")
    tile.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    tile.label:SetPoint("TOP", tile.value, "BOTTOM", 0, -3)
    tile.label:SetTextColor(0.55, 0.55, 0.60, 1)

    return tile
end

local function acquireRow(index)
    local ui = ns.ui.history
    local row = ui.rows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, ui.scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("RIGHT", ui.scrollChild, "RIGHT", 0, 0)

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(WHITE8X8)
    row.highlight:Hide()

    row.separator = row:CreateTexture(nil, "BORDER")
    row.separator:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 2, 0)
    row.separator:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 0)
    row.separator:SetHeight(1)
    row.separator:SetColorTexture(1, 1, 1, 0.05)

    row.chip = row:CreateFontString(nil, "OVERLAY")
    row.chip:SetFont("Fonts\\ARIALN.TTF", 14, "")
    row.chip:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.chip:SetWidth(34)
    row.chip:SetJustifyH("LEFT")

    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 40, -6)
    row.name:SetPoint("RIGHT", row, "RIGHT", -110, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.name:SetTextColor(0.95, 0.95, 0.95, 1)

    row.meta = row:CreateFontString(nil, "OVERLAY")
    row.meta:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    row.meta:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.meta:SetPoint("RIGHT", row, "RIGHT", -110, 0)
    row.meta:SetJustifyH("LEFT")
    row.meta:SetWordWrap(false)
    row.meta:SetTextColor(0.55, 0.55, 0.60, 1)

    row.time = row:CreateFontString(nil, "OVERLAY")
    row.time:SetFont("Fonts\\ARIALN.TTF", 16, "")
    row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
    row.time:SetJustifyH("RIGHT")
    row.time:SetTextColor(0.95, 0.95, 0.95, 1)

    row.result = row:CreateFontString(nil, "OVERLAY")
    row.result:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    row.result:SetPoint("TOPRIGHT", row.time, "BOTTOMRIGHT", 0, -3)
    row.result:SetJustifyH("RIGHT")

    row:SetScript("OnEnter", function(selfRow)
        local r, g, b = accentColor()
        selfRow.highlight:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.10), CreateColor(r, g, b, 0.02))
        selfRow.highlight:Show()

        local run = selfRow.run
        local board = selfRow.board
        if not run and not board then
            return
        end

        GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")

        if board then
            GameTooltip:AddLine(board.name or "?", 1, 1, 1)
            if board.level and board.level > 0 then
                GameTooltip:AddDoubleLine("Keystone", string.format("+%d", board.level), 0.7, 0.7, 0.7, 0.9, 0.9, 0.9)
                GameTooltip:AddDoubleLine("Time", ns:FormatTime((board.ms or 0) / 1000), 0.7, 0.7, 0.7, 0.9, 0.9, 0.9)
                if board.timed then
                    GameTooltip:AddLine("Timed", 0.49, 0.99, 0)
                else
                    GameTooltip:AddLine("Completed over time", 1, 0.65, 0.20)
                end
            else
                GameTooltip:AddLine("No completed runs yet", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
            return
        end

        GameTooltip:AddLine(run.name or "?", 1, 1, 1)
        GameTooltip:AddDoubleLine("Completed", date("%b %d, %Y  %H:%M", run.at or 0), 0.7, 0.7, 0.7, 0.9, 0.9, 0.9)
        if run.mode == "MYTHIC_PLUS" then
            GameTooltip:AddDoubleLine("Keystone", string.format("+%d", run.level or 0), 0.7, 0.7, 0.7, 0.9, 0.9, 0.9)
        end
        GameTooltip:AddDoubleLine("Time", ns:FormatTime(run.timeSec or 0), 0.7, 0.7, 0.7, 0.9, 0.9, 0.9)
        GameTooltip:AddDoubleLine("Deaths", tostring(run.deaths or 0), 0.7, 0.7, 0.7, 0.9, 0.9, 0.9)
        if run.mode == "MYTHIC_PLUS" then
            if run.onTime then
                GameTooltip:AddLine("Timed", 0.49, 0.99, 0)
            else
                GameTooltip:AddLine("Depleted", 1, 0.4, 0.4)
            end
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(selfRow)
        selfRow.highlight:Hide()
        GameTooltip:Hide()
    end)

    ui.rows[index] = row
    return row
end

local function centeredRowStartX(count, buttonWidth, gap)
    local totalWidth = count * buttonWidth + (count - 1) * gap
    return -(totalWidth / 2) + (buttonWidth / 2)
end

local function updateScrollBounds()
    local ui = ns.ui.history
    local visibleHeight = ui.scroll:GetHeight()
    local contentHeight = ui.scrollChild:GetHeight()
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    ui.maxScroll = maxScroll

    if maxScroll <= 0 then
        ui.scroll:SetVerticalScroll(0)
        ui.scrollThumb:Hide()
        return
    end

    local offset = math.min(ui.scroll:GetVerticalScroll(), maxScroll)
    ui.scroll:SetVerticalScroll(offset)

    local trackHeight = visibleHeight
    local thumbHeight = math.max(24, trackHeight * (visibleHeight / contentHeight))
    ui.scrollThumb:SetHeight(thumbHeight)
    ui.scrollThumb:ClearAllPoints()
    local travel = trackHeight - thumbHeight
    ui.scrollThumb:SetPoint("TOPRIGHT", ui.scroll, "TOPRIGHT", 8, -(travel * (offset / maxScroll)))
    ui.scrollThumb:Show()
end

local function buildLeaderboard(view)
    local pool = ns:GetDungeonPool()
    local items = {}

    for i = 1, #pool do
        local dungeon = pool[i]
        local record = ns:GetDungeonMapRecord(dungeon.mapID)
        local level, ms, timed

        if view == "BEST_TIMED" then
            level = record and record.highestTimedLevel
            ms = record and record.bestOnTimeAtHighestLevelMs
            timed = level ~= nil
        else
            level = record and record.highestLevel
            ms = record and record.bestDurationAtHighestLevelMs
            timed = level ~= nil and record.highestTimedLevel ~= nil and record.highestTimedLevel >= level
        end

        items[#items + 1] = {
            mapID = dungeon.mapID,
            name = dungeon.name,
            level = level,
            ms = ms,
            timed = timed and true or false,
        }
    end

    table.sort(items, function(a, b)
        local levelA, levelB = a.level or -1, b.level or -1
        if levelA ~= levelB then
            return levelA > levelB
        end
        if levelA > 0 then
            local msA, msB = a.ms or math.huge, b.ms or math.huge
            if msA ~= msB then
                return msA < msB
            end
        end
        return (a.name or "") < (b.name or "")
    end)

    return items
end

local function populateBoardRow(row, item, view)
    row.run = nil
    row.board = item

    if item.level and item.level > 0 then
        row.chip:SetText(string.format("+%d", item.level))
        row.chip:SetTextColor(keyLevelColor(item.level))
    else
        row.chip:SetText("-")
        row.chip:SetTextColor(0.45, 0.45, 0.50)
    end

    row.name:SetText(item.name or "?")
    row.time:SetText(item.ms and ns:FormatTime(item.ms / 1000) or "--")

    if not item.level or item.level == 0 then
        row.meta:SetText(view == "BEST_TIMED" and "Not yet timed" or "Not yet completed")
        row.result:SetText("")
    elseif item.timed then
        row.meta:SetText("")
        row.result:SetText("TIMED")
        row.result:SetTextColor(0.49, 0.99, 0, 1)
    else
        row.meta:SetText("Completed over time")
        row.result:SetText("OVER TIME")
        row.result:SetTextColor(1, 0.65, 0.20, 1)
    end
end

function ns:RefreshHistoryUI()
    local ui = self.ui.history
    if not ui or not ui.root:IsVisible() then
        return
    end

    local view = ui.view or "RUNS"
    local history = self.db.history or {}
    local filter = ui.filter or "ALL"

    local totalRuns = #history
    local mythicRuns, timedRuns, bestTimedLevel, totalDeaths = 0, 0, 0, 0
    for i = 1, totalRuns do
        local run = history[i]
        totalDeaths = totalDeaths + (run.deaths or 0)
        if run.mode == "MYTHIC_PLUS" then
            mythicRuns = mythicRuns + 1
            if run.onTime then
                timedRuns = timedRuns + 1
                if (run.level or 0) > bestTimedLevel then
                    bestTimedLevel = run.level or 0
                end
            end
        end
    end

    ui.stats[1].value:SetText(tostring(totalRuns))
    ui.stats[2].value:SetText(mythicRuns > 0 and string.format("%d%%", math.floor((timedRuns / mythicRuns) * 100 + 0.5)) or "--")
    if bestTimedLevel > 0 then
        ui.stats[3].value:SetText(string.format("+%d", bestTimedLevel))
        ui.stats[3].value:SetTextColor(keyLevelColor(bestTimedLevel))
    else
        ui.stats[3].value:SetText("--")
        ui.stats[3].value:SetTextColor(0.95, 0.95, 0.95, 1)
    end
    ui.stats[4].value:SetText(totalRuns > 0 and string.format("%.1f", totalDeaths / totalRuns) or "--")

    local shown = 0

    if view == "BEST_TIMED" or view == "HIGHEST_KEY" then
        local items = buildLeaderboard(view)
        for i = 1, #items do
            shown = shown + 1
            local row = acquireRow(shown)
            populateBoardRow(row, items[i], view)
            row:Show()
        end
        ui.emptyText:SetText(view == "BEST_TIMED"
            and "No timed Mythic+ runs recorded yet."
            or "No completed Mythic+ runs recorded yet.")
    else
        for i = 1, totalRuns do
            local run = history[i]
            if runMatchesFilter(run, filter) then
                shown = shown + 1
                local row = acquireRow(shown)
                row.run = run
                row.board = nil

                if run.mode == "MYTHIC_PLUS" then
                    local level = run.level or 0
                    row.chip:SetText(string.format("+%d", level))
                    row.chip:SetTextColor(keyLevelColor(level))
                else
                    local chip = MODE_CHIPS[run.mode] or { text = "D", r = 0.62, g = 0.62, b = 0.62 }
                    row.chip:SetText(chip.text)
                    row.chip:SetTextColor(chip.r, chip.g, chip.b)
                end

                row.name:SetText(run.name or "?")
                row.meta:SetText(string.format(
                    "%s  ·  %d %s",
                    date("%b %d · %H:%M", run.at or 0),
                    run.deaths or 0,
                    (run.deaths or 0) == 1 and "death" or "deaths"
                ))
                row.time:SetText(self:FormatTime(run.timeSec or 0))

                if run.mode == "MYTHIC_PLUS" then
                    if run.onTime then
                        row.result:SetText("TIMED")
                        row.result:SetTextColor(0.49, 0.99, 0, 1)
                    else
                        row.result:SetText("DEPLETED")
                        row.result:SetTextColor(1, 0.40, 0.40, 1)
                    end
                else
                    row.result:SetText("CLEARED")
                    row.result:SetTextColor(0.60, 0.60, 0.65, 1)
                end

                row:Show()
            end
        end
        ui.emptyText:SetText("No runs recorded yet.\nFinish a dungeon to start your log.")
    end

    for i = shown + 1, #ui.rows do
        ui.rows[i]:Hide()
        ui.rows[i].run = nil
        ui.rows[i].board = nil
    end

    if shown == 0 then
        ui.emptyText:Show()
    else
        ui.emptyText:Hide()
    end

    ui.scrollChild:SetHeight(math.max(1, shown * ROW_HEIGHT))
    updateScrollBounds()
end

function ns:ApplyHistoryTheme()
    local ui = self.ui.history
    if not ui then
        return
    end

    local r, g, b = accentColor()

    ui.heading:SetTextColor(r, g, b, 1)
    ui.scrollThumb:SetColorTexture(r, g, b, 0.55)

    local view = ui.view or "RUNS"

    for i = 1, #ui.viewButtons do
        local button = ui.viewButtons[i]
        if button.viewKey == view then
            button.label:SetTextColor(r, g, b, 1)
            button.underline:SetColorTexture(r, g, b, 0.9)
            button.underline:Show()
        else
            button.label:SetTextColor(0.60, 0.60, 0.65, 1)
            button.underline:Hide()
        end
    end

    local showFilters = view == "RUNS"
    for i = 1, #ui.filterButtons do
        local button = ui.filterButtons[i]
        if showFilters then
            button:Show()
        else
            button:Hide()
        end
        if button.filterKey == (ui.filter or "ALL") then
            button.label:SetTextColor(r, g, b, 1)
            button.underline:SetColorTexture(r, g, b, 0.9)
            button.underline:Show()
        else
            button.label:SetTextColor(0.60, 0.60, 0.65, 1)
            button.underline:Hide()
        end
    end

    ui.subtitle:SetText(view == "BEST_TIMED" and "Highest keystone level timed for each dungeon"
        or view == "HIGHEST_KEY" and "Highest keystone level completed for each dungeon"
        or "Your last 100 dungeon and keystone runs")
end

function ns:BuildHistoryPanel(parent)
    if self.ui.history then
        return
    end

    local heading = parent:CreateFontString(nil, "OVERLAY")
    heading:SetFont("Fonts\\FRIZQT__.TTF", 15, "")
    heading:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDE_INSET, -16)
    heading:SetText("Run History")

    local subtitle = parent:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    subtitle:SetPoint("BOTTOMLEFT", heading, "BOTTOMRIGHT", 8, 1)
    subtitle:SetTextColor(0.55, 0.55, 0.60, 1)
    subtitle:SetText("Your last 100 dungeon and keystone runs")

    local stats = {}
    local statLabels = { "RUNS", "TIMED RATE", "BEST TIMED", "AVG DEATHS" }
    for i = 1, 4 do
        stats[i] = createStatTile(parent, i)
        stats[i].label:SetText(statLabels[i])
    end

    local VIEW_BUTTON_WIDTH = 110
    local VIEW_BUTTON_GAP = 8

    local viewButtons = {}
    for i = 1, #VIEWS do
        local info = VIEWS[i]
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(VIEW_BUTTON_WIDTH, 24)
        if i == 1 then
            local startX = centeredRowStartX(#VIEWS, VIEW_BUTTON_WIDTH, VIEW_BUTTON_GAP)
            button:SetPoint("TOP", parent, "TOP", startX, -98)
        else
            button:SetPoint("LEFT", viewButtons[i - 1], "RIGHT", VIEW_BUTTON_GAP, 0)
        end
        button.viewKey = info.key

        button.label = button:CreateFontString(nil, "OVERLAY")
        button.label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        button.label:SetPoint("CENTER", button, "CENTER", 0, 2)
        button.label:SetText(info.label)

        button.underline = button:CreateTexture(nil, "ARTWORK")
        button.underline:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 8, 0)
        button.underline:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 0)
        button.underline:SetHeight(2)

        button:SetScript("OnClick", function(selfButton)
            ns.ui.history.view = selfButton.viewKey
            ns:ApplyHistoryTheme()
            ns.ui.history.scroll:SetVerticalScroll(0)
            ns:RefreshHistoryUI()
        end)

        viewButtons[i] = button
    end

    local FILTER_BUTTON_WIDTH = 80
    local FILTER_BUTTON_GAP = 6

    local filterButtons = {}
    for i = 1, #FILTERS do
        local info = FILTERS[i]
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(FILTER_BUTTON_WIDTH, 22)
        if i == 1 then
            local startX = centeredRowStartX(#FILTERS, FILTER_BUTTON_WIDTH, FILTER_BUTTON_GAP)
            button:SetPoint("TOP", parent, "TOP", startX, -134)
        else
            button:SetPoint("LEFT", filterButtons[i - 1], "RIGHT", FILTER_BUTTON_GAP, 0)
        end
        button.filterKey = info.key

        button.label = button:CreateFontString(nil, "OVERLAY")
        button.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        button.label:SetPoint("CENTER", button, "CENTER", 0, 2)
        button.label:SetText(info.label)

        button.underline = button:CreateTexture(nil, "ARTWORK")
        button.underline:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 12, 0)
        button.underline:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -12, 0)
        button.underline:SetHeight(2)

        button:SetScript("OnClick", function(selfButton)
            ns.ui.history.filter = selfButton.filterKey
            ns:ApplyHistoryTheme()
            ns.ui.history.scroll:SetVerticalScroll(0)
            ns:RefreshHistoryUI()
        end)

        filterButtons[i] = button
    end

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDE_INSET, -164)
    divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -SIDE_INSET, -164)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 1, 1, 0.08)

    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDE_INSET, -172)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -SIDE_INSET, 14)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfScroll, delta)
        local ui = ns.ui.history
        local offset = selfScroll:GetVerticalScroll() - delta * ROW_HEIGHT * 2
        offset = math.min(math.max(0, offset), ui.maxScroll or 0)
        selfScroll:SetVerticalScroll(offset)
        updateScrollBounds()
    end)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(400)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)
    scroll:SetScript("OnSizeChanged", function(selfScroll, width)
        scrollChild:SetWidth(width)
    end)

    local scrollThumb = parent:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetWidth(3)
    scrollThumb:Hide()

    local emptyText = parent:CreateFontString(nil, "OVERLAY")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    emptyText:SetPoint("CENTER", scroll, "CENTER", 0, 20)
    emptyText:SetTextColor(0.55, 0.55, 0.60, 1)
    emptyText:SetText("No runs recorded yet.\nFinish a dungeon to start your log.")
    emptyText:Hide()

    parent:SetScript("OnShow", function()
        ns:ApplyHistoryTheme()
        ns:RefreshHistoryUI()
    end)

    self.ui.history = {
        root = parent,
        heading = heading,
        subtitle = subtitle,
        stats = stats,
        viewButtons = viewButtons,
        filterButtons = filterButtons,
        scroll = scroll,
        scrollChild = scrollChild,
        scrollThumb = scrollThumb,
        emptyText = emptyText,
        rows = {},
        filter = "ALL",
        view = "RUNS",
        maxScroll = 0,
    }

    self:ApplyHistoryTheme()
end

function ns:ShowHistoryTab()
    if not self.ui.options then
        return
    end
    if not self.ui.options:IsShown() then
        self:RefreshOptionsUI()
        self.ui.options:Show()
    end
    if self.ui.options.SetTab then
        self.ui.options.SetTab("HISTORY")
    end
end

function ns:NotifyHistoryChanged()
    if self.ui.history and self.ui.history.root:IsVisible() then
        self:RefreshHistoryUI()
    end
end
