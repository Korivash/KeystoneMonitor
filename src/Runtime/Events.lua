local addonName, ns = ...

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
end

local function onZoneOrDifficulty()
    ns:SyncChallengeState(true)
end

local function onChallengeStart()
    ns.state.inChallenge = true
    ns.state.challengeCompleted = false
    ns:RefreshChallengeData()
    ns:RefreshVisibility()
    ns:Render()
    ns:StartTicker()
end

local function onWorldTimerStart()
    ns.state.timerStarted = true
    ns:RefreshChallengeData()
    ns:Render()
    ns:StartTicker()
end

local function onDeathUpdate()
    ns:RefreshDeaths()
    ns:Render()
end

local function onScenarioUpdate()
    ns:RefreshObjectives()
    ns:Render()
end

local function onChallengeCompleted()
    ns:HandleChallengeCompleted()
    ns:Render()
    ns:StopTicker()
end

local function onChallengeReset()
    ns:StopTicker()
    ns:SyncChallengeState(true)
end

local function onChallengeMapsUpdate()
    ns:InvalidateRunHistoryCache()
    ns:Render()
end

local handlers = {
    ADDON_LOADED = onLoaded,
    PLAYER_ENTERING_WORLD = onThemeEvent,
    PLAYER_SPECIALIZATION_CHANGED = onThemeEvent,
    ACTIVE_TALENT_GROUP_CHANGED = onThemeEvent,
    ZONE_CHANGED_NEW_AREA = onZoneOrDifficulty,
    PLAYER_DIFFICULTY_CHANGED = onZoneOrDifficulty,
    CHALLENGE_MODE_START = onChallengeStart,
    WORLD_STATE_TIMER_START = onWorldTimerStart,
    CHALLENGE_MODE_DEATH_COUNT_UPDATED = onDeathUpdate,
    SCENARIO_CRITERIA_UPDATE = onScenarioUpdate,
    SCENARIO_POI_UPDATE = onScenarioUpdate,
    CHALLENGE_MODE_COMPLETED = onChallengeCompleted,
    CHALLENGE_MODE_RESET = onChallengeReset,
    CHALLENGE_MODE_MAPS_UPDATE = onChallengeMapsUpdate,
}

function ns:RegisterRuntimeEvents()
    self.frame:SetScript("OnEvent", function(_, event, ...)
        local fn = handlers[event]
        if fn then
            fn(event, ...)
        end
    end)

    for eventName in pairs(handlers) do
        if eventName ~= "ADDON_LOADED" then
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
