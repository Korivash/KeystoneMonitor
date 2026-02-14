local _, ns = ...

local runHistoryCache = {
    dirty = true,
    byMap = {},
}

local function markRunHistoryDirty()
    runHistoryCache.dirty = true
end

local function extractDurationMs(run)
    if type(run) ~= "table" then
        return nil
    end

    local ms = tonumber(run.durationMS or run.durationMs or run.bestRunDurationMS)
    if ms and ms > 0 then
        return ms
    end

    local sec = tonumber(run.durationSec)
    if sec and sec > 0 then
        return sec * 1000
    end

    local timeMs = tonumber(run.time)
    if timeMs and timeMs > 0 then
        return timeMs
    end

    return nil
end

local function mapIDFromRun(run)
    if type(run) ~= "table" then
        return nil
    end
    return tonumber(run.mapChallengeModeID or run.challengeModeMapID or run.mapID)
end

local function keyLevelFromRun(run)
    if type(run) ~= "table" then
        return nil
    end
    return tonumber(run.keystoneLevel or run.level or run.challengeModeLevel or run.completedLevel)
end

local function loadRunHistory()
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then
        return {}
    end

    local ok, runs = pcall(C_MythicPlus.GetRunHistory, true, true, true)
    if ok and type(runs) == "table" then
        return runs
    end

    ok, runs = pcall(C_MythicPlus.GetRunHistory, true, true)
    if ok and type(runs) == "table" then
        return runs
    end

    ok, runs = pcall(C_MythicPlus.GetRunHistory, false, true)
    if ok and type(runs) == "table" then
        return runs
    end

    return {}
end

local function rebuildRunHistoryCache()
    local mapData = {}
    local runs = loadRunHistory()

    for i = 1, #runs do
        local run = runs[i]
        local mapID = mapIDFromRun(run)
        local durationMs = extractDurationMs(run)
        if mapID and mapID > 0 and durationMs and durationMs > 0 then
            local entry = mapData[mapID]
            if not entry then
                entry = {
                    bestClearMs = nil,
                    bestOnTimeMs = nil,
                    bestOnTimeLevel = nil,
                    highestTimedLevel = nil,
                    bestOnTimeAtHighestLevelMs = nil,
                }
                mapData[mapID] = entry
            end

            if (not entry.bestClearMs) or durationMs < entry.bestClearMs then
                entry.bestClearMs = durationMs
            end

            if run.completed and ((not entry.bestOnTimeMs) or durationMs < entry.bestOnTimeMs) then
                entry.bestOnTimeMs = durationMs
                entry.bestOnTimeLevel = keyLevelFromRun(run)
            end

            if run.completed then
                local runLevel = keyLevelFromRun(run)
                if runLevel and runLevel > 0 then
                    if (not entry.highestTimedLevel) or runLevel > entry.highestTimedLevel then
                        entry.highestTimedLevel = runLevel
                        entry.bestOnTimeAtHighestLevelMs = durationMs
                    elseif runLevel == entry.highestTimedLevel and ((not entry.bestOnTimeAtHighestLevelMs) or durationMs < entry.bestOnTimeAtHighestLevelMs) then
                        entry.bestOnTimeAtHighestLevelMs = durationMs
                    end
                end
            end
        end
    end

    runHistoryCache.byMap = mapData
    runHistoryCache.dirty = false
end

local function getMapRecord(mapID)
    if not mapID then
        return nil
    end

    if runHistoryCache.dirty then
        rebuildRunHistoryCache()
    end

    return runHistoryCache.byMap[tonumber(mapID)]
end

function ns:InvalidateRunHistoryCache()
    markRunHistoryDirty()
end

function ns:RecordRunSplits()
    -- Records come from Blizzard run history, not local SavedVariables.
    markRunHistoryDirty()

    if C_Timer then
        C_Timer.After(2, function()
            markRunHistoryDirty()
            if ns and ns.Render then
                ns:Render()
            end
        end)
    end
end

function ns:GetRecordSummary()
    if not self.state.mapID then
        return nil
    end

    local entry = getMapRecord(self.state.mapID)
    if not entry then
        return nil
    end

    local parts = {}
    if entry.bestClearMs then
        parts[#parts + 1] = "PB " .. self:FormatTime(entry.bestClearMs / 1000)
    end
    if entry.bestOnTimeAtHighestLevelMs then
        if entry.highestTimedLevel then
            parts[#parts + 1] = string.format("Best Timed +%d %s", entry.highestTimedLevel, self:FormatTime(entry.bestOnTimeAtHighestLevelMs / 1000))
        else
            parts[#parts + 1] = "Best Timed " .. self:FormatTime(entry.bestOnTimeAtHighestLevelMs / 1000)
        end
    elseif entry.bestOnTimeMs then
        if entry.bestOnTimeLevel and entry.bestOnTimeLevel > 0 then
            parts[#parts + 1] = string.format("Best Timed +%d %s", entry.bestOnTimeLevel, self:FormatTime(entry.bestOnTimeMs / 1000))
        else
            parts[#parts + 1] = "Best Timed " .. self:FormatTime(entry.bestOnTimeMs / 1000)
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, "  |  ")
end

function ns:GetBestTimedMs()
    if not self.state.mapID then
        return nil
    end

    local entry = getMapRecord(self.state.mapID)
    if not entry then
        return nil
    end

    local bestTimedMs = tonumber(entry.bestOnTimeAtHighestLevelMs or entry.bestOnTimeMs)
    if self.state.challengeCompleted and self.state.completedOnTime and self.state.completionTimeMs then
        local currentRunMs = tonumber(self.state.completionTimeMs)
        if currentRunMs and ((not bestTimedMs) or currentRunMs < bestTimedMs) then
            bestTimedMs = currentRunMs
        end
    end
    return bestTimedMs
end

function ns:GetBestTimedComparisonSummary()
    if not self.db.profile.showBestTimedComparison then
        return nil
    end
    if not self.state.inChallenge then
        return nil
    end

    local bestTimedMs = self:GetBestTimedMs()
    if not bestTimedMs then
        return nil
    end

    local currentMs = nil
    if self.state.challengeCompleted and self.state.completionTimeMs then
        currentMs = tonumber(self.state.completionTimeMs)
    else
        currentMs = (tonumber(self.state.elapsed) or 0) * 1000
    end
    if not currentMs then
        return nil
    end

    local delta = currentMs - bestTimedMs
    local deltaPrefix = delta >= 0 and "+" or "-"
    local deltaText = self:FormatTime(math.abs(delta) / 1000)

    return string.format(
        "Best Timed %s  |  Current %s  |  Delta %s%s",
        self:FormatTime(bestTimedMs / 1000),
        self:FormatTime(currentMs / 1000),
        deltaPrefix,
        deltaText
    )
end

