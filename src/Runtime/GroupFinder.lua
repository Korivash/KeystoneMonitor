local _, ns = ...

local GROUP_SIZE_REQUIRED = 5

-- Statuses that mean the application is still waiting or was never sent anywhere.
local PENDING_STATUSES = {
    none = true,
    applied = true,
}

-- Statuses that mean the application is dead and won't turn into a group.
local CLEARED_STATUSES = {
    invitedeclined = true,
    cancelled = true,
    timedout = true,
    declined = true,
    declined_full = true,
    declined_delisted = true,
    removed = true,
    failed = true,
}

local function firstActivityID(data)
    if not data then
        return nil
    end
    if data.activityIDs and data.activityIDs[1] then
        return data.activityIDs[1]
    end
    return data.activityID
end

local function activityNameForID(activityID)
    if not activityID or not C_LFGList or not C_LFGList.GetActivityInfoTable then
        return nil
    end
    local info = C_LFGList.GetActivityInfoTable(activityID)
    return info and (info.fullName or info.name)
end

-- Text for a group we're hosting: our own held keystone is what the listing was built from.
local function getOwnKeystoneText()
    local mapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()

    local name
    if mapID and mapID > 0 and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        name = C_ChallengeMode.GetMapUIInfo(mapID)
    end

    if not name and C_LFGList and C_LFGList.GetActiveEntryInfo then
        name = activityNameForID(firstActivityID(C_LFGList.GetActiveEntryInfo()))
    end

    if not name then
        return nil
    end

    if level and level > 0 then
        return string.format("+%d %s", level, name)
    end
    return name
end

-- Text for a group we applied to and joined: read the listing's own description.
local function formatListingText(searchResultData)
    if not searchResultData then
        return nil
    end

    local activityName = activityNameForID(firstActivityID(searchResultData))
    local comment = searchResultData.comment

    if comment and comment ~= "" then
        if activityName then
            return string.format("%s (%s)", activityName, comment)
        end
        return comment
    end

    return activityName
end

-- Best-effort live lookup for whatever we're still applied to, used as a fallback
-- when we never (or not yet) got a clean status transition for the accepted application.
local function findAppliedListingTextLive()
    if not C_LFGList or not C_LFGList.GetApplications or not C_LFGList.GetSearchResultInfo then
        return nil
    end

    local applications = C_LFGList.GetApplications()
    if not applications then
        return nil
    end

    for i = 1, #applications do
        local data = C_LFGList.GetSearchResultInfo(applications[i])
        local text = formatListingText(data)
        if text then
            return text
        end
    end

    return nil
end

local function announce(self, message)
    self:Print(message)

    if self.db.profile.announceGroupFilledToParty then
        self:AnnounceToParty(message)
    end
end

function ns:CheckGroupFinderListing()
    if not C_LFGList or not C_LFGList.GetActiveEntryInfo then
        return
    end

    local entry = C_LFGList.GetActiveEntryInfo()
    if entry then
        if not self._lfgListing then
            self._lfgAnnounced = false
        end
        self._lfgListing = true
    else
        self._lfgListing = false
        self._lfgAnnounced = false
    end
end

function ns:HandleLFGApplicationStatusUpdated(searchResultID, newStatus)
    if not searchResultID then
        return
    end

    if CLEARED_STATUSES[newStatus] then
        self._appliedPending = false
        self._appliedListingText = nil
        self._appliedAnnounced = false
        return
    end

    if PENDING_STATUSES[newStatus] then
        return
    end

    -- Anything else ("invited", "inviteaccepted", or any status Blizzard adds later)
    -- means this application is on track to become our group.
    self._appliedPending = true
    self._appliedAnnounced = false

    local data = C_LFGList and C_LFGList.GetSearchResultInfo and C_LFGList.GetSearchResultInfo(searchResultID)
    local text = formatListingText(data)
    if text then
        self._appliedListingText = text
    end

    self:CheckGroupFinderFilled()
end

function ns:CheckGroupFinderFilled()
    if not self.db or not self.db.profile.announceGroupFilled then
        return
    end

    if not IsInGroup or not IsInGroup() then
        self._lfgAnnounced = false
        self._appliedAnnounced = false
        self._appliedPending = false
        self._appliedListingText = nil
        return
    end

    local size = GetNumGroupMembers and GetNumGroupMembers() or 0
    if size < GROUP_SIZE_REQUIRED then
        self._lfgAnnounced = false
        self._appliedAnnounced = false
        return
    end

    -- A group we applied to and were invited into is a much stronger signal than
    -- re-checking our own listing below, which can briefly still look "active" if
    -- Blizzard hasn't yet cancelled it server-side after we joined someone else's group.
    local hosting = C_LFGList and C_LFGList.GetActiveEntryInfo and C_LFGList.GetActiveEntryInfo()
    self._lfgListing = hosting and true or false

    if not hosting and not self._appliedPending then
        -- We're in a full group we didn't host and never saw an application status
        -- transition for (event ordering, or Blizzard using an unrecognized status
        -- string). Fall back to a live check of our outstanding applications before
        -- giving up, so we still catch the common "joined a random group" case.
        local liveText = findAppliedListingTextLive()
        if liveText then
            self._appliedPending = true
            self._appliedListingText = liveText
        end
    end

    if not hosting and self._appliedPending and not self._appliedAnnounced then
        self._appliedAnnounced = true
        announce(self, string.format("Group Filled For %s", self._appliedListingText or "the dungeon you joined"))
        return
    end

    if hosting and not self._lfgAnnounced then
        self._lfgAnnounced = true
        local keyText = getOwnKeystoneText()
        announce(self, string.format("Group Filled For %s", keyText or "your Mythic+ key"))
    end
end
