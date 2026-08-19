local _, ns = ...

local defaults = {
    profile = {
        locked = true,
        showWhenUnlocked = true,
        showBestTimedComparison = true,
        showPaceHints = true,
        autoSlotKeystone = true,
        showUntimedStopwatch = false,
        announceDungeonCompleteToParty = false,
        announceNewKey = true,
        announceNewKeyToParty = false,
        dungeonMode = "AUTO",
        previewScenario = "FLOODGATE_COMPLETED",
        useFloodgateCompletedPreview = true,
        position = {
            x = 0,
            y = 120,
        },
        scale = 0.99,
        alpha = 0.00,
        appearance = {
            useClassColor = false,
            frameWidth = 288,
            frameHeight = 258,
            fontScale = 1.16,
            titleFont = "FRIZQT",
            timerFont = "ARIALN",
            bodyFont = "FRIZQT",
            accentColor = "53B9FFFF",
            backgroundColor = "0D0D0DC7",
            borderColor = "333333F2",
            textColor = "53B9FFFF",
            timerColor = "53B9FFFF",
            forcesBarColor = "53B9FFFF",
            forcesBarBGColor = "212121E6",
        },
    },
    records = {},
    history = {},
}

function ns:InitDB()
    KeystoneMonitorDB = KeystoneMonitorDB or {}
    self:MergeDefaults(KeystoneMonitorDB, defaults)
    self.db = KeystoneMonitorDB

    local profile = self.db.profile
    if profile and profile.useFloodgateCompletedPreview and profile.previewScenario == "LIVE" then
        profile.previewScenario = "FLOODGATE_COMPLETED"
    end
end
