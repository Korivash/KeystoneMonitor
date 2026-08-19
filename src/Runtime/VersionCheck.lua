local _, ns = ...

local ADDON_PREFIX = "KeystoneMonitor"
local BROADCAST_THROTTLE = 30

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
end

local function parseVersionParts(str)
    local parts = {}
    for num in tostring(str or ""):gmatch("%d+") do
        parts[#parts + 1] = tonumber(num)
    end
    return parts
end

local function isVersionNewer(candidate, current)
    local a, b = parseVersionParts(candidate), parseVersionParts(current)
    for i = 1, math.max(#a, #b) do
        local va, vb = a[i] or 0, b[i] or 0
        if va ~= vb then
            return va > vb
        end
    end
    return false
end

local lastBroadcast = {}
function ns:BroadcastVersion(channel)
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage or not self.version then
        return
    end
    if channel == "PARTY" and not (IsInGroup and IsInGroup()) then
        return
    end
    if channel == "GUILD" and not (IsInGuild and IsInGuild()) then
        return
    end

    local now = GetTime()
    if lastBroadcast[channel] and now - lastBroadcast[channel] < BROADCAST_THROTTLE then
        return
    end
    lastBroadcast[channel] = now

    pcall(C_ChatInfo.SendAddonMessage, ADDON_PREFIX, self.version, channel)
end

function ns:HandleVersionBroadcast(prefix, message, channel, sender)
    if prefix ~= ADDON_PREFIX or self._newerVersionNotified or not self.version then
        return
    end
    if type(message) ~= "string" then
        return
    end

    local ok, newer = pcall(isVersionNewer, message, self.version)
    if not ok or not newer then
        return
    end

    self._newerVersionNotified = true
    self:Print(string.format("A newer version (v%s) is available.", message))
end
