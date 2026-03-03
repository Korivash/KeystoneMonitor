local _, ns = ...

local MODE_AUTO = "AUTO"
local MODE_MYTHIC_PLUS = "MYTHIC_PLUS"
local MODE_MYTHIC_ZERO = "MYTHIC_ZERO"
local MODE_HEROIC = "HEROIC"
local MODE_NORMAL = "NORMAL"
local MODE_FOLLOWER = "FOLLOWER"

local MYTHIC_PLUS_DIFFICULTIES = {
    [8] = true,
}

local MYTHIC_ZERO_DIFFICULTIES = {
    [23] = true,
}

local FOLLOWER_DIFFICULTIES = {
    [205] = true,
}

local function newRuntimeState()
    return {
        inChallenge = false,
        mode = MODE_MYTHIC_PLUS,
        challengeCompleted = false,
        completedOnTime = nil,
        completionTimeMs = nil,
        timerStarted = false,
        runStartTime = nil,
        elapsed = 0,
        timeLimit = 0,
        mapID = nil,
        instanceID = nil,
        mapName = "Mythic+",
        level = 0,
        affixIDs = {},
        affixes = {},
        weeklyAffixIDs = {},
        weeklyAffixes = {},
        deathCount = 0,
        deathPenalty = 0,
        forcesCurrent = 0,
        forcesTotal = 0,
        objectives = {},
    }
end

function ns:RefreshWeeklyAffixes()
    wipe(self.state.weeklyAffixIDs)
    wipe(self.state.weeklyAffixes)

    local affixIDs = {}

    if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local currentAffixes = C_MythicPlus.GetCurrentAffixes()
        if currentAffixes then
            for i = 1, #currentAffixes do
                local entry = currentAffixes[i]
                if entry and entry.id then
                    affixIDs[#affixIDs + 1] = entry.id
                    self.state.weeklyAffixIDs[#self.state.weeklyAffixIDs + 1] = entry.id
                end
            end
        end
    end

    if #affixIDs == 0 and C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local _, activeAffixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
        if activeAffixIDs then
            for i = 1, #activeAffixIDs do
                affixIDs[#affixIDs + 1] = activeAffixIDs[i]
                self.state.weeklyAffixIDs[#self.state.weeklyAffixIDs + 1] = activeAffixIDs[i]
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
    local isMythicPlus = MYTHIC_PLUS_DIFFICULTIES[difficultyID] and true or false
    return instanceType == "party" and isMythicPlus
end

function ns:GetSelectedDungeonMode()
    local configured = self.db and self.db.profile and self.db.profile.dungeonMode
    if configured == MODE_AUTO
        or configured == MODE_FOLLOWER
        or configured == MODE_NORMAL
        or configured == MODE_HEROIC
        or configured == MODE_MYTHIC_ZERO
        or configured == MODE_MYTHIC_PLUS then
        return configured
    end
    return MODE_AUTO
end

function ns:GetCurrentDungeonMode()
    local _, instanceType, difficultyID, difficultyName = GetInstanceInfo()
    if instanceType ~= "party" then
        return nil
    end

    if FOLLOWER_DIFFICULTIES[difficultyID] then
        return MODE_FOLLOWER
    end

    if MYTHIC_PLUS_DIFFICULTIES[difficultyID] then
        return MODE_MYTHIC_PLUS
    end

    if MYTHIC_ZERO_DIFFICULTIES[difficultyID] then
        return MODE_MYTHIC_ZERO
    end

    local localizedMythic = (PLAYER_DIFFICULTY6 or "Mythic"):lower()
    local localizedNormal = (PLAYER_DIFFICULTY1 or "Normal"):lower()
    local localizedHeroic = (PLAYER_DIFFICULTY2 or "Heroic"):lower()
    local currentDifficultyName = tostring(difficultyName or ""):lower()
    if currentDifficultyName ~= "" then
        if currentDifficultyName:find("follower", 1, true) then
            return MODE_FOLLOWER
        end
        if currentDifficultyName:find(localizedMythic, 1, true) then
            return MODE_MYTHIC_ZERO
        end
        if currentDifficultyName:find(localizedNormal, 1, true) then
            return MODE_NORMAL
        end
        if currentDifficultyName:find(localizedHeroic, 1, true) then
            return MODE_HEROIC
        end
    end

    if difficultyID == 2 then
        return MODE_HEROIC
    end
    if difficultyID == 1 then
        return MODE_NORMAL
    end
    return nil
end

function ns:IsTrackedDungeonActive()
    local selectedMode = self:GetSelectedDungeonMode()
    local currentMode = self:GetCurrentDungeonMode()
    if selectedMode == MODE_AUTO then
        if not currentMode then
            return false, MODE_MYTHIC_PLUS
        end
        if currentMode == MODE_MYTHIC_PLUS then
            return self:IsChallengeActive(), currentMode
        end
        return true, currentMode
    end

    if selectedMode ~= currentMode then
        return false, selectedMode
    end

    if selectedMode == MODE_MYTHIC_PLUS then
        return self:IsChallengeActive(), selectedMode
    end
    return true, selectedMode
end

function ns:RefreshChallengeData()
    self:RefreshWeeklyAffixes()
    self:RefreshMeta()
    self:RefreshTimer()
    self:RefreshDeaths()
    self:RefreshObjectives()
end

function ns:RefreshMeta()
    local mode = self.state.mode or MODE_MYTHIC_PLUS
    local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    self.state.instanceID = tonumber(instanceID) or nil

    if mode ~= MODE_MYTHIC_PLUS then
        self.state.mapID = nil
        self.state.mapName = self:SafeMapName(instanceName or "Dungeon")
        self.state.timeLimit = 0
        self.state.level = 0
        wipe(self.state.affixIDs)
        wipe(self.state.affixes)
        return
    end

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
    if not C_ChallengeMode or not C_ChallengeMode.GetAffixInfo then
        return items
    end

    local sourceIDs = self.state.affixIDs
    if not sourceIDs or #sourceIDs == 0 then
        sourceIDs = self.state.weeklyAffixIDs
    end
    if not sourceIDs or #sourceIDs == 0 then
        return items
    end

    for i = 1, #sourceIDs do
        local affixID = sourceIDs[i]
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
        self.state.runStartTime = nil
        return
    end

    if self.state.mode == MODE_MYTHIC_PLUS then
        local elapsed = select(2, GetWorldElapsedTime(1))
        if elapsed then
            self.state.elapsed = tonumber(elapsed) or 0
            self.state.timerStarted = true
        end
        return
    end

    if not self.state.runStartTime then
        self.state.runStartTime = GetTime()
    end
    self.state.elapsed = math.max(0, GetTime() - self.state.runStartTime)
    self.state.timerStarted = true
end

function ns:RefreshDeaths()
    if self.state.mode ~= MODE_MYTHIC_PLUS then
        self.state.deathCount = 0
        self.state.deathPenalty = 0
        return
    end

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
    self.state.forcesCurrent = 0
    self.state.forcesTotal = 0

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
                if self.state.mode == MODE_MYTHIC_PLUS then
                    self.state.forcesTotal = tonumber(info.totalQuantity) or 0
                    local quantity = tonumber(info.quantity)
                    if not quantity then
                        quantity = tonumber((info.quantityString or ""):match("(%d+)")) or 0
                    end
                    self.state.forcesCurrent = quantity
                end
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

    for i = 1, #self.state.objectives do
        local objective = self.state.objectives[i]
        if objective and not objective.completed then
            objective.completed = true
            objective.doneAt = tonumber(self.state.elapsed) or 0
        end
    end

    self:RecordRunSplits()
end

ns:ResetRuntimeState()
