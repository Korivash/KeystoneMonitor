local _, ns = ...

local function mapRecordTable(mapID)
    local key = tostring(mapID or 0)
    ns.db.records[key] = ns.db.records[key] or {
        bestClearMs = nil,
        bestOnTimeMs = nil,
        bestObjectiveTimes = {},
    }
    return ns.db.records[key]
end

function ns:RecordRunSplits()
    if not self.state.mapID then
        return
    end
    if not self.state.completionTimeMs then
        return
    end

    local entry = mapRecordTable(self.state.mapID)
    local clearMs = tonumber(self.state.completionTimeMs)
    if clearMs and (not entry.bestClearMs or clearMs < entry.bestClearMs) then
        entry.bestClearMs = clearMs
    end
    if self.state.completedOnTime and clearMs and (not entry.bestOnTimeMs or clearMs < entry.bestOnTimeMs) then
        entry.bestOnTimeMs = clearMs
    end

    for i = 1, #self.state.objectives do
        local objective = self.state.objectives[i]
        if objective and objective.completed and objective.doneAt then
            local current = tonumber(objective.doneAt)
            local best = entry.bestObjectiveTimes[i]
            if current and (not best or current < best) then
                entry.bestObjectiveTimes[i] = current
            end
        end
    end
end

function ns:GetRecordSummary()
    if not self.state.mapID then
        return nil
    end

    local entry = self.db.records[tostring(self.state.mapID)]
    if not entry then
        return nil
    end

    local parts = {}
    if entry.bestClearMs then
        parts[#parts + 1] = "PB " .. self:FormatTime(entry.bestClearMs / 1000)
    end
    if entry.bestOnTimeMs then
        parts[#parts + 1] = "Best Timed " .. self:FormatTime(entry.bestOnTimeMs / 1000)
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

    local entry = self.db.records[tostring(self.state.mapID)]
    if not entry then
        return nil
    end
    return tonumber(entry.bestOnTimeMs)
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

