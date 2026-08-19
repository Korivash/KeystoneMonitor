local addonName, ns = ...

local function isMythicPlusTrackingEnabled()
    local selectedMode = ns:GetSelectedDungeonMode()
    if selectedMode == "MYTHIC_PLUS" then
        return true
    end
    if selectedMode == "AUTO" and ns:GetCurrentDungeonMode() == "MYTHIC_PLUS" then
        return true
    end
    return false
end

local function onLoaded(_, loadedName)
    if loadedName ~= addonName then
        return
    end
    ns.frame:UnregisterEvent("ADDON_LOADED")
    ns:Initialize()
end

local function onThemeEvent()
    ns:ApplyTheme()
    ns:SyncChallengeState(false)
    ns:ScheduleOwnedKeystoneCheck(2)
    ns:BroadcastVersion("GUILD")
    if ns:IsDebugModeEnabled() then
        ns:PrintDungeonModeDebug("ENTER_WORLD")
    end
end

local function onZoneOrDifficulty()
    ns:SyncChallengeState(true)
    if ns:IsDebugModeEnabled() then
        ns:PrintDungeonModeDebug("ZONE_OR_DIFF")
    end
end

local function onChallengeStart()
    if not isMythicPlusTrackingEnabled() then
        return
    end
    ns.state.inChallenge = true
    ns.state.mode = "MYTHIC_PLUS"
    ns.state.challengeCompleted = false
    ns.state.deathLog = {}
    ns._deadUnits = {}
    ns:RefreshChallengeData()
    ns:UpdateDeathWatcher()
    ns:RefreshVisibility()
    ns:Render()
    ns:StartTicker()
end

local function onWorldTimerStart()
    if not isMythicPlusTrackingEnabled() then
        return
    end
    ns.state.timerStarted = true
    ns:RefreshChallengeData()
    ns:Render()
    ns:StartTicker()
end

local function onDeathUpdate()
    if not isMythicPlusTrackingEnabled() then
        return
    end
    ns:RefreshDeaths()
    ns:Render()
end

local function onScenarioUpdate()
    if ns:RefreshObjectives() then
        ns:Render()
    end
end

local function onChallengeCompleted()
    if C_MythicPlus and C_MythicPlus.RequestRewards then
        C_MythicPlus.RequestRewards()
    end
    ns:ScheduleOwnedKeystoneCheck(3)

    if not isMythicPlusTrackingEnabled() then
        return
    end
    ns:HandleChallengeCompleted()
    ns:Render()
    ns:StopTicker()
end

local function onChallengeReset()
    ns:ScheduleOwnedKeystoneCheck(2)

    if not isMythicPlusTrackingEnabled() then
        return
    end
    ns:StopTicker()
    ns:SyncChallengeState(true)
end

local function onChallengeMapsUpdate()
    if not isMythicPlusTrackingEnabled() then
        return
    end
    ns:InvalidateRunHistoryCache()
    ns:Render()
end

local function onEncounterStart(_, encounterID, encounterName)
    ns:HandleEncounterStart(encounterID, encounterName)
end

local function onEncounterEnd(_, encounterID, encounterName, difficultyID, groupSize, success)
    ns:HandleEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
end

local function onUnitVitals(_, unit)
    ns:HandleUnitVitalsEvent(unit)
end

local function onKeystoneReceptacleOpen()
    ns:TryAutoSlotKeystone()
end

local function onOwnedItemChanged()
    ns:ScheduleOwnedKeystoneCheck(1.5)
end

local function onPartyChatMessage(_, text)
    ns:HandlePartyKeysTrigger(text)
end

local function onAddonMessage(_, prefix, message, channel, sender)
    ns:HandleVersionBroadcast(prefix, message, channel, sender)
end

local function onGroupRosterUpdate()
    ns:BroadcastVersion("PARTY")
end

local handlers = {
    ADDON_LOADED = onLoaded,
    PLAYER_ENTERING_WORLD = onThemeEvent,
    PLAYER_SPECIALIZATION_CHANGED = onThemeEvent,
    ACTIVE_TALENT_GROUP_CHANGED = onThemeEvent,
    ZONE_CHANGED = onZoneOrDifficulty,
    ZONE_CHANGED_NEW_AREA = onZoneOrDifficulty,
    ZONE_CHANGED_INDOORS = onZoneOrDifficulty,
    PLAYER_DIFFICULTY_CHANGED = onZoneOrDifficulty,
    CHALLENGE_MODE_START = onChallengeStart,
    WORLD_STATE_TIMER_START = onWorldTimerStart,
    CHALLENGE_MODE_DEATH_COUNT_UPDATED = onDeathUpdate,
    SCENARIO_CRITERIA_UPDATE = onScenarioUpdate,
    SCENARIO_POI_UPDATE = onScenarioUpdate,
    CHALLENGE_MODE_COMPLETED = onChallengeCompleted,
    CHALLENGE_MODE_RESET = onChallengeReset,
    CHALLENGE_MODE_MAPS_UPDATE = onChallengeMapsUpdate,
    ENCOUNTER_START = onEncounterStart,
    ENCOUNTER_END = onEncounterEnd,
    CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN = onKeystoneReceptacleOpen,
    ITEM_CHANGED = onOwnedItemChanged,
    CHAT_MSG_PARTY = onPartyChatMessage,
    CHAT_MSG_PARTY_LEADER = onPartyChatMessage,
    CHAT_MSG_ADDON = onAddonMessage,
    UNIT_HEALTH = onUnitVitals,
    UNIT_FLAGS = onUnitVitals,
    GROUP_ROSTER_UPDATE = onGroupRosterUpdate,
}

local DEFERRED_EVENTS = {
    ADDON_LOADED = true,
    UNIT_HEALTH = true,
    UNIT_FLAGS = true,
}

function ns:RegisterRuntimeEvents()
    self.frame:SetScript("OnEvent", function(_, event, ...)
        local fn = handlers[event]
        if fn then
            fn(event, ...)
        end
    end)

    for eventName in pairs(handlers) do
        if not DEFERRED_EVENTS[eventName] then
            self.frame:RegisterEvent(eventName)
        end
    end
end

ns.frame:SetScript("OnEvent", function(_, event, ...)
    local fn = handlers[event]
    if fn then
        fn(event, ...)
    end
end)
ns.frame:RegisterEvent("ADDON_LOADED")
