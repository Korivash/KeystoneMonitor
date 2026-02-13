local addonName, ns = ...

ns.addonName = addonName
ns.frame = CreateFrame("Frame", "KeystoneMonitorEventFrame")
ns.state = {}
ns.ui = {}

_G.KeystoneMonitor = ns

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff6cc6ffKeystone Monitor|r " .. tostring(msg))
end

function ns:Initialize()
    self:InitDB()
    self:BuildUI()
    self:BuildOptionsUI()
    self:RegisterSlashCommands()
    self:RegisterRuntimeEvents()
    self:ApplyTheme()
    self:SyncChallengeState(true)
end

function ns:SyncChallengeState(forceFull)
    self:RefreshWeeklyAffixes()

    local wasInChallenge = self.state.inChallenge
    local nowInChallenge = self:IsChallengeActive()
    local insideMythicPlusInstance = self:IsInMythicPlusInstance()

    if not nowInChallenge and self.state.challengeCompleted and insideMythicPlusInstance then
        self.state.inChallenge = true
        self:RefreshVisibility()
        self:Render()
        return
    end

    if not nowInChallenge and (wasInChallenge or forceFull) then
        self:StopTicker()
        self:ResetRuntimeState()
        self:RefreshWeeklyAffixes()
        self:RefreshVisibility()
        self:Render()
        return
    end

    if nowInChallenge and (not wasInChallenge or forceFull) then
        self.state.inChallenge = true
        self:RefreshChallengeData()
        self:RefreshVisibility()
        self:Render()
        self:StartTicker()
        return
    end

    if nowInChallenge then
        self:RefreshChallengeData()
        self:StartTicker()
    end
    self:RefreshVisibility()
    self:Render()
end
