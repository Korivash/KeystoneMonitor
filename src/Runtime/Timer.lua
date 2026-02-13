local _, ns = ...

local updateInterval = 0.15
local objectiveInterval = 0.35

function ns:StartTicker()
    if self.tickerRunning then
        return
    end

    self.tickerRunning = true
    self._tickElapsed = 0
    self._objectiveElapsed = 0

    self.frame:SetScript("OnUpdate", function(_, elapsed)
        if not ns.tickerRunning then
            return
        end
        if not ns.ui.root or not ns.ui.root:IsShown() then
            return
        end
        if not ns.state.inChallenge then
            return
        end

        ns._tickElapsed = ns._tickElapsed + elapsed
        ns._objectiveElapsed = ns._objectiveElapsed + elapsed

        if ns._tickElapsed >= updateInterval then
            ns._tickElapsed = 0
            ns:RefreshTimer()
            ns:RefreshDeaths()
            ns:Render()
        end

        if ns._objectiveElapsed >= objectiveInterval then
            ns._objectiveElapsed = 0
            ns:RefreshObjectives()
            ns:Render()
        end
    end)
end

function ns:StopTicker()
    self.tickerRunning = false
    self.frame:SetScript("OnUpdate", nil)
end

