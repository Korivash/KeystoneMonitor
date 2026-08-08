local addonName, ns = ...

ns.addonName = addonName
ns.frame = CreateFrame("Frame", "KeystoneMonitorEventFrame")
ns.state = {}
ns.ui = {}

_G.KeystoneMonitor = ns

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff6cc6ffKeystone Monitor|r " .. tostring(msg))
end

function ns:AnnounceToParty(msg)
    if not IsInGroup or not IsInGroup() or not SendChatMessage then
        return
    end
    local chatType = (IsInRaid and IsInRaid()) and "RAID" or "PARTY"
    SendChatMessage("Keystone Monitor: " .. tostring(msg), chatType)
end

function ns:Initialize()
    self:InitDB()
    self:BuildUI()
    self:HookObjectiveTracker()
    self:BuildOptionsUI()
    self:RegisterSlashCommands()
    self:RegisterRuntimeEvents()
    self:ApplyTheme()
    self:SyncChallengeState(true)
end

function ns:HookObjectiveTracker()
    if self._objectiveTrackerHooked then
        return
    end
    if not ObjectiveTrackerFrame then
        return
    end

    self._objectiveTrackerHooked = true
    hooksecurefunc(ObjectiveTrackerFrame, "Show", function()
        if ns._objectiveTrackerHidden then
            ObjectiveTrackerFrame:Hide()
        end
    end)
end

function ns:HideObjectiveTracker()
    if not ObjectiveTrackerFrame then
        return
    end
    ObjectiveTrackerFrame:Hide()
end

function ns:ShowObjectiveTracker()
    if not ObjectiveTrackerFrame then
        return
    end
    ObjectiveTrackerFrame:Update()
end

function ns:UpdateObjectiveTrackerVisibility()
    local shouldHide = self.state.inChallenge and self.ui and self.ui.root and self.ui.root:IsShown()
    shouldHide = shouldHide and true or false

    if shouldHide == self._objectiveTrackerHidden then
        return
    end
    self._objectiveTrackerHidden = shouldHide

    if shouldHide then
        self:HideObjectiveTracker()
    else
        self:ShowObjectiveTracker()
    end
end

function ns:SyncChallengeState(forceFull)
    local wasInChallenge = self.state.inChallenge
    local nowInChallenge, activeMode = self:IsTrackedDungeonActive()
    self.state.mode = activeMode

    if activeMode == "MYTHIC_PLUS" then
        self:RefreshWeeklyAffixes()
    else
        wipe(self.state.weeklyAffixIDs)
        wipe(self.state.weeklyAffixes)
        self._affixCacheDirty = true
    end

    if not nowInChallenge and self.state.challengeCompleted and activeMode == "MYTHIC_PLUS" and self:IsInMythicPlusInstance() then
        self.state.inChallenge = true
        self:RefreshVisibility()
        self:UpdateObjectiveTrackerVisibility()
        self:Render()
        return
    end

    if not nowInChallenge and (wasInChallenge or forceFull) then
        self:StopTicker()
        self:ResetRuntimeState()
        self._bossListKey = nil
        self:UpdateDeathWatcher()
        self:RefreshWeeklyAffixes()
        self:RefreshVisibility()
        self:UpdateObjectiveTrackerVisibility()
        self:Render()
        return
    end

    if nowInChallenge and (not wasInChallenge or forceFull) then
        self.state.inChallenge = true
        if activeMode ~= "MYTHIC_PLUS" then
            self:BeginDungeonRun()
        end
        self:RefreshChallengeData()
        self:UpdateDeathWatcher()
        self:RefreshVisibility()
        self:UpdateObjectiveTrackerVisibility()
        self:Render()
        self:StartTicker()
        return
    end

    if nowInChallenge then
        self:RefreshChallengeData()
        self:StartTicker()
    end
    self:RefreshVisibility()
    self:UpdateObjectiveTrackerVisibility()
    self:Render()
end
