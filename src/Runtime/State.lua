local _, ns = ...

local function newRuntimeState()
    return {
        inChallenge = false,
        challengeCompleted = false,
        completedOnTime = nil,
        completionTimeMs = nil,
        timerStarted = false,
        elapsed = 0,
        timeLimit = 0,
        mapID = nil,
        mapName = "Mythic+",
        level = 0,
        affixIDs = {},
        affixes = {},
        weeklyAffixes = {},
        deathCount = 0,
        deathPenalty = 0,
        forcesCurrent = 0,
        forcesTotal = 0,
        objectives = {},
    }
end

function ns:RefreshWeeklyAffixes()
    wipe(self.state.weeklyAffixes)

    local affixIDs = {}

    if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local currentAffixes = C_MythicPlus.GetCurrentAffixes()
        if currentAffixes then
            for i = 1, #currentAffixes do
                local entry = currentAffixes[i]
                if entry and entry.id then
                    affixIDs[#affixIDs + 1] = entry.id
                end
            end
        end
    end

    if #affixIDs == 0 and C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local _, activeAffixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
        if activeAffixIDs then
            for i = 1, #activeAffixIDs do
                affixIDs[#affixIDs + 1] = activeAffixIDs[i]
            end
        end
    end

    if C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
        for i = 1, #affixIDs do
            local affixID = affixIDs[i]
            local name = C_ChallengeMode.GetAffixInfo(affixID)
            self.state.weeklyAffixes[#self.state.weeklyAffixes + 1] = name or tostring(affixID)
        end
    end
end

function ns:GetWeeklyAffixSummary()
    if not self.state.weeklyAffixes or #self.state.weeklyAffixes == 0 then
        return nil
    end
    return table.concat(self.state.weeklyAffixes, ", ")
end

function ns:ResetRuntimeState()
    self.state = newRuntimeState()
end

function ns:IsChallengeActive()
    if not self:IsInMythicPlusInstance() then
        return false
    end

    if not C_ChallengeMode or not C_ChallengeMode.GetActiveChallengeMapID then
        return false
    end

    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    return mapID and mapID > 0
end

function ns:IsInMythicPlusInstance()
    local _, instanceType, difficultyID = GetInstanceInfo()
    local isMythicPlus = difficultyID == 8 or difficultyID == 23
    return instanceType == "party" and isMythicPlus
end

function ns:RefreshChallengeData()
    self:RefreshWeeklyAffixes()
    self:RefreshMeta()
    self:RefreshTimer()
    self:RefreshDeaths()
    self:RefreshObjectives()
end

function ns:RefreshMeta()
    if not C_ChallengeMode then
        return
    end

    local mapID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    self.state.mapID = mapID or nil

    if mapID and C_ChallengeMode.GetMapUIInfo then
        local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
        self.state.mapName = self:SafeMapName(name)
        self.state.timeLimit = tonumber(timeLimit) or 0
    else
        self.state.mapName = "Mythic+"
        self.state.timeLimit = 0
    end

    if C_ChallengeMode.GetActiveKeystoneInfo then
        local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
        self.state.level = tonumber(level) or 0
        wipe(self.state.affixIDs)
        wipe(self.state.affixes)
        if affixIDs and C_ChallengeMode.GetAffixInfo then
            for i = 1, #affixIDs do
                local affixID = affixIDs[i]
                self.state.affixIDs[#self.state.affixIDs + 1] = affixID
                local name = C_ChallengeMode.GetAffixInfo(affixID)
                self.state.affixes[#self.state.affixes + 1] = name or tostring(affixID)
            end
        end
    else
        self.state.level = 0
        wipe(self.state.affixIDs)
        wipe(self.state.affixes)
    end
end

function ns:GetActiveAffixDisplayData()
    local items = {}
    if not self.state.affixIDs or #self.state.affixIDs == 0 then
        return items
    end
    if not C_ChallengeMode or not C_ChallengeMode.GetAffixInfo then
        return items
    end

    for i = 1, #self.state.affixIDs do
        local affixID = self.state.affixIDs[i]
        local name, description, fileDataID = C_ChallengeMode.GetAffixInfo(affixID)
        items[#items + 1] = {
            id = affixID,
            name = name or tostring(affixID),
            description = description or "",
            icon = fileDataID,
        }
    end
    return items
end

function ns:RefreshTimer()
    if not self.state.inChallenge then
        self.state.elapsed = 0
        self.state.timerStarted = false
        return
    end

    local elapsed = select(2, GetWorldElapsedTime(1))
    if elapsed then
        self.state.elapsed = tonumber(elapsed) or 0
        self.state.timerStarted = true
    end
end

function ns:RefreshDeaths()
    if not C_ChallengeMode or not C_ChallengeMode.GetDeathCount then
        self.state.deathCount = 0
        self.state.deathPenalty = 0
        return
    end

    local count, penalty = C_ChallengeMode.GetDeathCount()
    self.state.deathCount = tonumber(count) or 0
    self.state.deathPenalty = self:NormalizePenalty(penalty)
end

function ns:RefreshObjectives()
    wipe(self.state.objectives)

    if not C_Scenario or not C_Scenario.GetStepInfo then
        return
    end
    if not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then
        return
    end

    local _, _, criteriaCount = C_Scenario.GetStepInfo()
    if not criteriaCount or criteriaCount <= 0 then
        return
    end

    for i = 1, criteriaCount do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info then
            if info.isWeightedProgress and info.totalQuantity and info.totalQuantity > 0 then
                self.state.forcesTotal = tonumber(info.totalQuantity) or 0
                local quantity = tonumber((info.quantityString or ""):match("(%d+)"))
                if not quantity then
                    quantity = tonumber(info.quantity) or 0
                end
                self.state.forcesCurrent = quantity
            else
                local row = {
                    text = info.description or ("Objective " .. i),
                    completed = info.completed and true or false,
                    doneAt = nil,
                }
                if row.completed then
                    local elapsed = tonumber(info.elapsed) or 0
                    row.doneAt = math.max(0, self.state.elapsed - elapsed)
                end
                self.state.objectives[#self.state.objectives + 1] = row
            end
        end
    end
end

function ns:HandleChallengeCompleted()
    self.state.challengeCompleted = true

    if C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo then
        local completion = C_ChallengeMode.GetChallengeCompletionInfo()
        if completion then
            self.state.completedOnTime = completion.onTime and true or false
            self.state.completionTimeMs = completion.time or nil
        end
    end

    -- Preserve the final in-run snapshot on the UI after completion.
    -- Some challenge APIs clear immediately and would zero out stats if re-polled here.
    if self.state.completionTimeMs then
        self.state.elapsed = (tonumber(self.state.completionTimeMs) or 0) / 1000
        self.state.timerStarted = true
    end
    self:RecordRunSplits()
end

ns:ResetRuntimeState()
