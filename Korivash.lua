local addonName, addon = ...
addon.korivashFlavor = "retail"
local neutralIcon = "Interface\\Icons\\INV_Misc_Book_09"
local catalog = {
    { "AggroWatch", "Aggro Watch", "Threat and aggro warnings.", "aggro-watch", "ToggleWindow", false, "forever" },
    { "DingDash", "Ding Dash", "Leveling routes and XP tracking.", "ding-dash", "Toggle", true, "forever" },
    { "DungeonLedger", "Dungeon Ledger", "Dungeon timers, splits and history.", "dungeon-ledger", "ToggleOptionsUI", true, "forever" },
    { "LegacyTracker", "Legacy Tracker", "Legacy challenges and rewards.", "legacy-tracker", "Toggle", true, "forever" },
    { "AltoLite", "AltoLite", "Your characters at a glance.", "altolite", "Toggle", false, "both" },
    { "Bindsafe", "Bindsafe", "Save and restore your keybinds.", "bindsafe", "Toggle", true, "both" },
    { "KeystoneMonitor", "Keystone Monitor", "Mythic+ timers, splits and history.", "keystone", "ToggleOptionsUI", true, "retail" },
}

local function api(name, ...)
    local fn = type(C_AddOns) == "table" and C_AddOns[name] or nil
    if type(fn) ~= "function" then fn = _G[name] end
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end

local function installed(name)
    return api("IsAddOnLoaded", name) == true or api("GetAddOnInfo", name) ~= nil
end

local function toggle(entry)
    local target = _G[entry[1]]
    if type(target) == "table" and type(target[entry[5]]) == "function" then
        return target[entry[5]], target
    end
end

local function label(parent, value, font, x, y)
    local text = parent:CreateFontString(nil, "ARTWORK", font)
    text:SetPoint("TOPLEFT", x, y)
    text:SetJustifyH("LEFT")
    text:SetText(value)
    return text
end

function addon:BuildKorivashPage(parent, style)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    local title = label(page, "More from Korivash", "GameFontNormalLarge", 12, -12)
    local hint = label(page, "Other addons for " .. (self.korivashFlavor == "forever" and "WoW Forever" or "retail WoW") .. ".", "GameFontHighlightSmall", 12, -38)
    hint:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -38)
    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -66)
    scroll:SetPoint("BOTTOMRIGHT", -30, 76)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(300, 1)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(math.max(1, width)) end)
    local copyHint = label(page, "Select a link, then press Ctrl+C to copy.", "GameFontDisableSmall", 12, 0)
    copyHint:ClearAllPoints()
    copyHint:SetPoint("BOTTOMLEFT", 12, 48)
    local link = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    link:SetPoint("BOTTOMLEFT", 16, 18)
    link:SetPoint("BOTTOMRIGHT", -16, 18)
    link:SetHeight(24)
    link:SetAutoFocus(false)
    link:SetMaxLetters(0)
    link:SetText("")
    link:SetScript("OnTextChanged", function(edit)
        if edit:GetText() ~= (edit.url or "") then edit:SetText(edit.url or "") end
    end)
    link:SetScript("OnEditFocusGained", function(edit) edit:HighlightText() end)
    link:SetScript("OnMouseUp", function(edit) edit:HighlightText() end)
    link:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
    local rows = {}
    for _, entry in ipairs(catalog) do
        if entry[1] ~= addonName and (entry[7] == "both" or entry[7] == self.korivashFlavor) then
            local row = CreateFrame("Frame", nil, content)
            row:SetPoint("TOPLEFT", 0, -#rows * 100)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -#rows * 100)
            row:SetHeight(100)
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", 0, -4)
            icon:SetSize(30, 30)
            local name = label(row, entry[2], "GameFontNormal", 40, -4)
            name:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
            local description = label(row, entry[3], "GameFontHighlightSmall", 40, -24)
            description:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -24)
            description:SetWordWrap(false)
            local status = label(row, "", "GameFontDisableSmall", 0, -58)
            local action = CreateFrame("Button", nil, row, type(style) ~= "function" and "UIPanelButtonTemplate" or nil)
            action:SetSize(160, 24)
            action:SetPoint("TOPRIGHT", -4, -50)
            if type(style) == "function" then style(action) end
            action:SetScript("OnClick", function()
                if installed(entry[1]) then
                    local fn, target = toggle(entry)
                    if type(fn) == "function" then
                        if entry[6] then pcall(fn, target) else pcall(fn) end
                    end
                else
                    link.url = "https://www.curseforge.com/wow/addons/" .. entry[4]
                    link:SetText(link.url)
                    link:SetFocus()
                    link:HighlightText()
                end
            end)
            rows[#rows + 1] = { entry = entry, icon = icon, status = status, action = action }
        end
    end
    content:SetHeight(#rows * 100)
    page:SetScript("OnShow", function()
        content:SetWidth(math.max(1, scroll:GetWidth()))
        for _, row in ipairs(rows) do
            local present = installed(row.entry[1])
            local icon = present and api("GetAddOnMetadata", row.entry[1], "IconTexture") or nil
            row.icon:SetTexture(type(icon) == "string" and icon ~= "" and icon or neutralIcon)
            row.status:SetText(present and "Installed" or "Not installed")
            row.action:SetText(present and "Open" or "Get it on CurseForge")
            row.action:SetEnabled(not present or type(toggle(row.entry)) == "function")
        end
    end)
    page:SetScript("OnHide", function() link:ClearFocus() end)
    page:Hide()
    page.title = title
    return page
end

function addon:MountKorivash(parent)
    local children, regions = { parent:GetChildren() }, { parent:GetRegions() }
    local page = self:BuildKorivashPage(parent)
    local back = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    back:SetSize(80, 22)
    back:SetPoint("TOPRIGHT", -12, -10)
    back:SetText("Back")
    local hidden = {}
    local function restore()
        for _, object in ipairs(hidden) do object:Show() end
        hidden = {}
    end
    back:SetScript("OnClick", function() page:Hide(); restore() end)
    parent:HookScript("OnHide", function() page:Hide(); restore() end)
    return function()
        if page:IsShown() then return end
        for _, objects in ipairs({ children, regions }) do
            for _, object in ipairs(objects) do
                if object:IsShown() then hidden[#hidden + 1] = object; object:Hide() end
            end
        end
        page:Show()
    end, function() page:Hide(); restore() end
end

function addon:ShowKorivashMenu(owner, originalLabel, originalAction)
    if type(MenuUtil) == "table" and type(MenuUtil.CreateContextMenu) == "function" then
        MenuUtil.CreateContextMenu(owner, function(_, root)
            if type(originalAction) == "function" then root:CreateButton(originalLabel, originalAction) end
            root:CreateButton("More from Korivash", function() addon:OpenKorivash() end)
        end)
    else
        self:OpenKorivash()
    end
end
