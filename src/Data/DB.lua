local _, ns = ...

local defaults = {
    profile = {
        locked = true,
        showWhenUnlocked = true,
        showBestTimedComparison = true,
        position = {
            x = 0,
            y = 120,
        },
        scale = 1.0,
        alpha = 1.0,
        appearance = {
            useClassColor = true,
            frameWidth = 350,
            frameHeight = 248,
            fontScale = 1.0,
            titleFont = "FRIZQT",
            timerFont = "ARIALN",
            bodyFont = "FRIZQT",
            accentColor = "53B9FFFF",
            backgroundColor = "0D0D0DC7",
            borderColor = "333333F2",
            textColor = "F2F2F2FF",
            timerColor = "FFFFFFFF",
            forcesBarColor = "53B9FFFF",
            forcesBarBGColor = "212121E6",
        },
    },
    records = {},
}

function ns:InitDB()
    KeystoneMonitorDB = KeystoneMonitorDB or {}
    self:MergeDefaults(KeystoneMonitorDB, defaults)
    self.db = KeystoneMonitorDB
end
