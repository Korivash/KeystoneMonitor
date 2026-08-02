local _, ns = ...

local RUN_RESUME_MAX_AGE = 4 * 3600
local MAX_HISTORY_ENTRIES = 30

local MODE_LABELS = {
    FOLLOWER = "Follower Dungeon",
    NORMAL = "Normal Dungeon",
    HEROIC = "Heroic Dungeon",
    TIMEWALKING = "Timewalking Dungeon",
    MYTHIC_ZERO = "Mythic 0 Dungeon",
}

local function findBossRow(objectives, encounterID, encounterName)
    if encounterID then
        for i = 1, #objectives do
            if objectives[i].encounterID == encounterID then
                return objectives[i], i
            end
        end
    end
    if encounterName then
        for i = 1, #objectives do
            if objectives[i].text == encounterName then
                return objectives[i], i
            end
        end
    end
    return nil
end

function ns:GetModeLabel(mode)
    return MODE_LABELS[mode] or "Dungeon"
end

function ns:UpdateBossProgress()
    local objectives = self.state.objectives
    local done = 0
    for i = 1, #objectives do
        if objectives[i].completed then
            done = done + 1
        end
    end
    self.state.bossesDone = done
    self.state.bossesTotal = #objectives
end

function ns:GetRunRecordKey()
    if self.state.mode == "MYTHIC_PLUS" then
        local mapID = self.state.mapID
        return mapID and ("MP:" .. mapID) or nil
    end
    return self.state.runKey
end

function ns:ClearRunSnapshot()
    self.db.runtime = nil
end

function ns:BeginDungeonRun()
    local mode = self.state.mode
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local key = tostring(instanceID or 0) .. ":" .. tostring(mode)
    self.state.runKey = key

    local snapshot = self.db.runtime
    local now = time()
    local resumable = snapshot
        and snapshot.key == key
        and type(snapshot.startedAt) == "number"
        and (now - snapshot.startedAt) < RUN_RESUME_MAX_AGE

    if resumable then

        if not self.state.runStartTime then
            self.state.runStartTime = GetTime() - (now - snapshot.startedAt)
            self.state.challengeCompleted = snapshot.completed and true or false
            if snapshot.completed and snapshot.timeSec then
                self.state.elapsed = snapshot.timeSec
            end
        end
    else
        self.db.runtime = {
            key = key,
            startedAt = now,
            deaths = {},
            kills = {},
        }
        snapshot = self.db.runtime
        self.state.runStartTime = GetTime()
        self.state.challengeCompleted = false
        self.state.completedOnTime = nil
        self.state.completionTimeMs = nil
    end

    snapshot.deaths = snapshot.deaths or {}
    snapshot.kills = snapshot.kills or {}

    self.state.deathLog = snapshot.deaths
    self.state.deathCount = #snapshot.deaths

    self:RefreshBossList(4)
end

function ns:RefreshBossList(retries)
    if not self.state.inChallenge or self.state.mode == "MYTHIC_PLUS" then
        return
    end

    local key = self.state.runKey
    if self._bossListKey == key and #self.state.objectives > 0 then
        return
    end

    if not self._ejLoaded and C_AddOns and C_AddOns.LoadAddOn then
        self._ejLoaded = true
        pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal")
    end

    local uiMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local journalID = uiMapID and EJ_GetInstanceForMap and EJ_GetInstanceForMap(uiMapID)

    local found = {}
    if journalID and journalID > 0 and EJ_GetEncounterInfoByIndex then

        pcall(EJ_SelectInstance, journalID)
        for i = 1, 20 do
            local ok, name, _, _, _, _, _, dungeonEncounterID = pcall(EJ_GetEncounterInfoByIndex, i, journalID)
            if not ok or not name then
                break
            end
            found[#found + 1] = { name = name, encounterID = dungeonEncounterID }
        end
    end

    if #found == 0 then
        if (retries or 0) > 0 then
            C_Timer.After(2, function()
                if ns.state.inChallenge and ns.state.runKey == key then
                    ns:RefreshBossList(retries - 1)
                end
            end)
        end
        return
    end

    local snapshot = self.db.runtime
    local kills = (snapshot and snapshot.kills) or {}

    wipe(self.state.objectives)
    for i = 1, #found do
        local entry = found[i]
        local doneAt = kills[entry.encounterID or entry.name]
        self.state.objectives[i] = {
            text = entry.name,
            encounterID = entry.encounterID,
            completed = doneAt ~= nil,
            doneAt = doneAt,
            engaged = false,
        }
    end

    self._bossListKey = key
    self:UpdateBossProgress()
    self:Render()
end

function ns:HandleEncounterStart(encounterID, encounterName)
    if not self.state.inChallenge or self.state.mode == "MYTHIC_PLUS" or self.state.challengeCompleted then
        return
    end

    local row = findBossRow(self.state.objectives, encounterID, encounterName)
    if not row then
        row = {
            text = encounterName or ("Boss " .. tostring(encounterID)),
            encounterID = encounterID,
            completed = false,
            doneAt = nil,
            engaged = false,
        }
        self.state.objectives[#self.state.objectives + 1] = row
        self:UpdateBossProgress()
    end
    row.engaged = true
    self:Render()
end

function ns:HandleEncounterEnd(encounterID, encounterName, _, _, success)
    if not self.state.inChallenge or self.state.mode == "MYTHIC_PLUS" then
        return
    end

    local row = findBossRow(self.state.objectives, encounterID, encounterName)
    if not row and success == 1 then
        row = {
            text = encounterName or ("Boss " .. tostring(encounterID)),
            encounterID = encounterID,
            completed = false,
            doneAt = nil,
            engaged = false,
        }
        self.state.objectives[#self.state.objectives + 1] = row
    end
    if not row then
        return
    end

    row.engaged = false

    if success == 1 and not row.completed then
        self:RefreshTimer()
        row.completed = true
        row.doneAt = math.floor(self.state.elapsed)

        local snapshot = self.db.runtime
        if snapshot and snapshot.kills then
            snapshot.kills[row.encounterID or row.text] = row.doneAt
        end

        self:UpdateBossProgress()
        if self.state.bossesTotal > 0 and self.state.bossesDone >= self.state.bossesTotal then
            self:HandleDungeonRunCompleted()
        end
    end

    self:Render()
end

function ns:HandleDungeonRunCompleted()
    self:RefreshTimer()
    self.state.challengeCompleted = true
    local timeSec = math.floor(self.state.elapsed)

    local snapshot = self.db.runtime
    if snapshot then
        snapshot.completed = true
        snapshot.timeSec = timeSec
    end

    local key = self:GetRunRecordKey()
    if key then
        local splits = {}
        local objectives = self.state.objectives
        for i = 1, #objectives do
            local row = objectives[i]
            if row.doneAt then
                splits[row.encounterID or i] = row.doneAt
            end
        end
        self:SaveRunRecord(key, timeSec * 1000, splits, nil)
    end

    self:AddHistoryEntry({
        at = time(),
        mode = self.state.mode,
        name = self.state.mapName,
        level = 0,
        timeSec = timeSec,
        deaths = self.state.deathCount,
        onTime = nil,
    })

    self:UpdateDeathWatcher()
end

function ns:SaveRunRecord(key, timeMs, splits, level)
    self.db.records = self.db.records or {}
    local existing = self.db.records[key]
    if existing and existing.bestMs and existing.bestMs <= timeMs then
        return false
    end
    self.db.records[key] = {
        bestMs = timeMs,
        at = time(),
        level = level,
        splits = splits,
    }
    return true
end

function ns:AddHistoryEntry(entry)
    self.db.history = self.db.history or {}
    table.insert(self.db.history, 1, entry)
    for i = #self.db.history, MAX_HISTORY_ENTRIES + 1, -1 do
        table.remove(self.db.history, i)
    end
end

function ns:GetSplitDelta(row, index)
    if not row or not row.doneAt then
        return nil
    end
    local key = self:GetRunRecordKey()
    local record = key and self.db.records and self.db.records[key]
    local splits = record and record.splits
    if not splits then
        return nil
    end
    local best = splits[row.encounterID or index]
    if not best then
        return nil
    end
    local delta = row.doneAt - best
    if math.abs(delta) < 1 then
        return nil
    end
    return delta
end

function ns:GetDungeonRecordSummary()
    local label = self:GetModeLabel(self.state.mode)
    local key = self:GetRunRecordKey()
    local record = key and self.db.records and self.db.records[key]
    if record and record.bestMs then
        return string.format("%s  ·  Best %s", label, self:FormatTime(record.bestMs / 1000))
    end
    return label
end

local GROUP_UNITS = {
    player = true,
    party1 = true,
    party2 = true,
    party3 = true,
    party4 = true,
}

function ns:UpdateDeathWatcher()
    local want = (self.state.inChallenge and not self.state.challengeCompleted) and true or false
    if want == (self._deathWatcherActive or false) then
        return
    end
    self._deathWatcherActive = want
    if want then
        self._deadUnits = {}
        pcall(self.frame.RegisterEvent, self.frame, "UNIT_HEALTH")
        pcall(self.frame.RegisterEvent, self.frame, "UNIT_FLAGS")
    else
        pcall(self.frame.UnregisterEvent, self.frame, "UNIT_HEALTH")
        pcall(self.frame.UnregisterEvent, self.frame, "UNIT_FLAGS")
    end
end

function ns:HandleUnitVitalsEvent(unit)
    if not unit or not GROUP_UNITS[unit] then
        return
    end
    if not self.state.inChallenge or self.state.challengeCompleted then
        return
    end

    local guid = UnitGUID(unit)
    if not guid then
        return
    end

    self._deadUnits = self._deadUnits or {}

    if UnitIsDead(unit) and not (UnitIsFeignDeath and UnitIsFeignDeath(unit)) then
        if not self._deadUnits[guid] then
            self._deadUnits[guid] = true
            self:RefreshTimer()
            local name = UnitName(unit)
            local _, classFile = UnitClass(unit)
            local log = self.state.deathLog
            log[#log + 1] = {
                t = math.floor(self.state.elapsed),
                name = name or "?",
                class = classFile,
            }
            if self.state.mode ~= "MYTHIC_PLUS" then
                self.state.deathCount = #log
            end
            self:Render()
        end
    elseif not UnitIsDeadOrGhost(unit) then
        self._deadUnits[guid] = nil
    end
end

function ns:TryAutoSlotKeystone()
    if not self.db.profile.autoSlotKeystone then
        return
    end
    if not C_ChallengeMode or not C_Container then
        return
    end
    if C_ChallengeMode.HasSlottedKeystone and C_ChallengeMode.HasSlottedKeystone() then
        return
    end

    for bag = 0, NUM_BAG_SLOTS or 4 do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link and link:find("Hkeystone:", 1, true) then
                ClearCursor()
                C_Container.PickupContainerItem(bag, slot)
                if CursorHasItem() then
                    C_ChallengeMode.SlotKeystone()
                    ClearCursor()
                    self:Print("Keystone inserted.")
                end
                return
            end
        end
    end
end
