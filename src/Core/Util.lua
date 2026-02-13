local _, ns = ...

function ns:MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            self:MergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns:ClassColor()
    local _, classFile = UnitClass("player")
    local color = (classFile and RAID_CLASS_COLORS[classFile]) or NORMAL_FONT_COLOR
    return color.r, color.g, color.b
end

function ns:FormatTime(totalSeconds)
    local seconds = tonumber(totalSeconds) or 0
    local sign = ""
    if seconds < 0 then
        sign = "-"
        seconds = math.abs(seconds)
    end

    local whole = math.floor(seconds)
    local hours = math.floor(whole / 3600)
    local minutes = math.floor((whole % 3600) / 60)
    local secs = whole % 60
    if hours > 0 then
        return string.format("%s%d:%02d:%02d", sign, hours, minutes, secs)
    end
    return string.format("%s%d:%02d", sign, minutes, secs)
end

function ns:Trim(text)
    if type(text) ~= "string" then
        return ""
    end
    return text:match("^%s*(.-)%s*$")
end

function ns:NormalizePenalty(value)
    local number = tonumber(value) or 0
    if number > 1000 then
        return math.floor(number / 1000)
    end
    return math.floor(number)
end

function ns:SafeMapName(name)
    if not name or name == "" then
        return "Mythic+"
    end
    return name
end

function ns:NormalizeHexColor(input, fallback)
    local candidate = tostring(input or ""):gsub("#", ""):upper()
    if candidate:match("^%x%x%x%x%x%x$") then
        return candidate .. "FF"
    end
    if candidate:match("^%x%x%x%x%x%x%x%x$") then
        return candidate
    end
    return fallback
end

function ns:HexToRGBA(input, fallbackR, fallbackG, fallbackB, fallbackA)
    local fallbackHex = string.format(
        "%02X%02X%02X%02X",
        math.floor((fallbackR or 1) * 255 + 0.5),
        math.floor((fallbackG or 1) * 255 + 0.5),
        math.floor((fallbackB or 1) * 255 + 0.5),
        math.floor((fallbackA == nil and 1 or fallbackA) * 255 + 0.5)
    )
    local normalized = self:NormalizeHexColor(input, fallbackHex)
    local r = tonumber(normalized:sub(1, 2), 16) / 255
    local g = tonumber(normalized:sub(3, 4), 16) / 255
    local b = tonumber(normalized:sub(5, 6), 16) / 255
    local a = tonumber(normalized:sub(7, 8), 16) / 255
    return r, g, b, a
end
