local _, ns = ...

local TIMER_INTERVAL = 0.10
local OBJECTIVE_INTERVAL = 0.50

function ns:StartTicker()
    if self.tickerRunning then
        return
    end

    self.tickerRunning = true
    self._tickElapsed = 0
    self._objectiveElapsed = 0
    self._lastShownSecond = nil

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

        if ns._tickElapsed >= TIMER_INTERVAL then
            ns._tickElapsed = 0
            ns:RefreshTimer()

            local second = math.floor(ns.state.elapsed)
            if second ~= ns._lastShownSecond then
                ns._lastShownSecond = second
                ns:RenderTimer()
            end
        end

        if ns._objectiveElapsed >= OBJECTIVE_INTERVAL then
            ns._objectiveElapsed = 0
            if ns:RefreshObjectives() then
                ns:Render()
            end
        end
    end)
end

function ns:StopTicker()
    self.tickerRunning = false
    self.frame:SetScript("OnUpdate", nil)
end
