local _, ns = ...

function ns:RegisterSlashCommands()
    SLASH_MIDNIGHT1 = "/midnight"
    SLASH_MIDNIGHT2 = "/mplus"
    SLASH_MIDNIGHT3 = "/km"

    SlashCmdList.MIDNIGHT = function(message)
        local cmd = self:Trim((message or ""):lower())

        if cmd == "" or cmd == "menu" or cmd == "config" or cmd == "options" or cmd == "open" then
            self:ToggleOptionsUI()
            return
        end

        if cmd == "unlock" then
            self.db.profile.locked = false
            self:RefreshOptionsUI()
            self:RefreshVisibility()
            self:Render()
            self:Print("Unlocked. Drag to move.")
            return
        end

        if cmd == "lock" then
            self.db.profile.locked = true
            self:RefreshOptionsUI()
            self:RefreshVisibility()
            self:Render()
            self:Print("Locked.")
            return
        end

        if cmd == "show" then
            self.db.profile.showWhenUnlocked = true
            self:RefreshOptionsUI()
            self:RefreshVisibility()
            self:Render()
            self:Print("Frame will show while unlocked.")
            return
        end

        if cmd == "hide" then
            self.db.profile.showWhenUnlocked = false
            self:RefreshOptionsUI()
            self:RefreshVisibility()
            self:Render()
            self:Print("Frame hidden outside active runs.")
            return
        end

        if cmd == "reset" then
            self.db.profile.position.x = 0
            self.db.profile.position.y = 120
            self:RestorePosition()
            self:RefreshOptionsUI()
            self:Print("Position reset.")
            return
        end

        self:Print("Commands: /km, /km unlock, /km lock, /km show, /km hide, /km reset")
    end
end
