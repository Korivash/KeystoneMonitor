local _, ns = ...

local function findOwnedKeystoneLink()
    if not C_Container then
        return nil
    end
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link and link:find("Hkeystone:", 1, true) then
                return link
            end
        end
    end
    return nil
end

local function formatOwnedKeystoneFallback(mapID, level)
    if not mapID or mapID == 0 or not level or level == 0 then
        return nil
    end
    local name = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then
        return nil
    end
    return string.format("+%d %s", level, name)
end

function ns:GetOwnedKeystoneAnnounceText(mapID, level)
    return findOwnedKeystoneLink() or formatOwnedKeystoneFallback(mapID, level)
end

function ns:CheckOwnedKeystoneChanged()
    if not C_MythicPlus or not C_MythicPlus.GetOwnedKeystoneChallengeMapID or not C_MythicPlus.GetOwnedKeystoneLevel then
        return
    end

    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()

    if not mapID or mapID == 0 or not level or level == 0 then
        return
    end

    local previous = self._ownedKeystone

    if (not previous) or (mapID == previous.mapID and level < previous.level) then
        self._ownedKeystone = { mapID = mapID, level = level }
        return
    end

    self._ownedKeystone = { mapID = mapID, level = level }

    if mapID == previous.mapID and level == previous.level then
        return
    end

    if not self.db or not self.db.profile.announceNewKey then
        return
    end

    local text = self:GetOwnedKeystoneAnnounceText(mapID, level)
    local message = "My new Key is " .. (text or "a new Mythic+ keystone")
    self:Print(message)
    if self.db.profile.announceNewKeyToParty then
        self:AnnounceToParty(message)
    end
end

local pendingOwnedKeystoneCheck = false
function ns:ScheduleOwnedKeystoneCheck(delay)
    if pendingOwnedKeystoneCheck then
        return
    end
    pendingOwnedKeystoneCheck = true
    C_Timer.After(delay or 1.5, function()
        pendingOwnedKeystoneCheck = false
        ns:CheckOwnedKeystoneChanged()
    end)
end

local KEYS_TRIGGER = "!keys"

local function announceOwnedKeystoneToParty()
    if not IsInGroup or not IsInGroup() then
        return
    end

    local mapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()

    if not mapID or mapID == 0 or not level or level == 0 then
        ns:AnnounceToParty("My key: none")
        return
    end

    local text = ns:GetOwnedKeystoneAnnounceText(mapID, level)
    ns:AnnounceToParty("My key: " .. (text or string.format("+%d", level)))
end

function ns:HandlePartyKeysTrigger(text)
    if type(text) ~= "string" then
        return
    end
    local ok, trimmed = pcall(function() return ns:Trim(text):lower() end)
    if not ok or trimmed ~= KEYS_TRIGGER then
        return
    end
    C_Timer.After(math.random() * 0.5, announceOwnedKeystoneToParty)
end
