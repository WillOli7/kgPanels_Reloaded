local ADDON, ns = ...
local L = ns.L

-- Slash commands, minimap button and addon compartment
local Commands = {}
ns.Commands = Commands

local ICON = "Interface\\Icons\\INV_Inscription_Tradeskill01"

local function clientName()
	if ns.isForever then return L["CLIENT_FOREVER"] end
	if ns.isRetail then return L["CLIENT_RETAIL"] end
	return L["CLIENT_OTHER"]
end

local function activeName()
	return (ns.API.GetActiveLayout()) or L["LAYOUT_NONE"]
end

function Commands:ListLayouts()
	local list = ns.Database:SortedLayouts()
	if #list == 0 then
		ns:Print(L["NO_LAYOUTS"])
		return
	end
	ns:Print(L["LAYOUT_LIST"])
	local active = ns.Database:GetActiveLayoutId()
	for _, entry in ipairs(list) do
		local line = L["LAYOUT_LIST_ITEM"]:format(entry.layout.name, ns.Database:CountPanels(entry.layout))
		if entry.id == active then
			line = "|cff33ff99> " .. line .. "|r"
		end
		DEFAULT_CHAT_FRAME:AddMessage("   " .. line)
	end
end

function Commands:Activate(key)
	if ns.API.ActivateLayout(key) then
		ns:Print(L["LAYOUT_ACTIVE"], (ns.API.GetActiveLayout()))
	else
		ns:Print(L["LAYOUT_NOT_FOUND"], key)
	end
end

function Commands:Toggle(enabled)
	if enabled == nil then
		enabled = not ns.db.profile.enabled
	end
	ns.Layouts:SetEnabled(enabled)
	ns:Print(enabled and L["ENABLED"] or L["DISABLED"])
end

function Commands:Status()
	local shown, waiting = ns.Layouts:CountShown()
	ns:Print(L["STATUS"], ns.version, clientName(), activeName(), shown, waiting)
end

function Commands:Help()
	ns:Print(L["HELP_TITLE"])
	for _, key in ipairs({ "HELP_LAYOUTS", "HELP_LAYOUT", "HELP_TOGGLE", "HELP_IMPORT", "HELP_MINIMAP", "HELP_STATUS" }) do
		DEFAULT_CHAT_FRAME:AddMessage("   " .. L[key])
	end
end

function Commands:ToggleMinimap()
	local settings = ns.db.profile.minimap
	settings.hide = not settings.hide
	local icon = LibStub("LibDBIcon-1.0")
	if settings.hide then icon:Hide(ADDON) else icon:Show(ADDON) end
end

local function handle(msg)
	local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
	cmd = cmd:lower()
	if cmd == "layouts" or cmd == "list" then
		Commands:ListLayouts()
	elseif cmd == "layout" and rest ~= "" then
		Commands:Activate(rest)
	elseif cmd == "enable" or cmd == "on" then
		Commands:Toggle(true)
	elseif cmd == "disable" or cmd == "off" then
		Commands:Toggle(false)
	elseif cmd == "toggle" then
		Commands:Toggle()
	elseif cmd == "import" then
		ns.Migration:ImportAgain()
	elseif cmd == "minimap" then
		Commands:ToggleMinimap()
	elseif cmd == "status" or cmd == "version" then
		Commands:Status()
	elseif cmd == "config" or cmd == "options" then
		ns:Print(L["OPTIONS_SOON"])
	else
		Commands:Help()
	end
end

---------------------------------------------------------------------------
-- Layout menu (minimap button, addon compartment)
---------------------------------------------------------------------------
function Commands:OpenMenu(owner)
	if not (MenuUtil and MenuUtil.CreateContextMenu) then
		self:ListLayouts()
		return
	end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateTitle("nxPanels")
		for _, entry in ipairs(ns.Database:SortedLayouts()) do
			root:CreateRadio(
				L["LAYOUT_LIST_ITEM"]:format(entry.layout.name, ns.Database:CountPanels(entry.layout)),
				function() return ns.Database:GetActiveLayoutId() == entry.id end,
				function() ns.Layouts:Activate(entry.id) end)
		end
		root:CreateDivider()
		root:CreateCheckbox(L["MENU_SHOW"],
			function() return ns.db.profile.enabled end,
			function() Commands:Toggle() end)
	end)
end

local function onClick(owner, button)
	if button == "RightButton" then
		Commands:Toggle()
	else
		Commands:OpenMenu(owner)
	end
end

function Commands:Init()
	SLASH_NXPANELS1 = "/nxpanels"
	SLASH_NXPANELS2 = "/nxp"
	SlashCmdList.NXPANELS = handle

	local launcher = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
		type = "launcher",
		icon = ICON,
		label = ADDON,
		OnClick = onClick,
		OnTooltipShow = function(tooltip)
			tooltip:AddDoubleLine("nxPanels", ns.version, 0.2, 0.8, 1, 0.6, 0.6, 0.6)
			tooltip:AddLine(L["LAYOUT_ACTIVE"]:format(activeName()), 1, 1, 1)
			tooltip:AddLine(" ")
			tooltip:AddLine(L["MINIMAP_TOOLTIP_LEFT"])
			tooltip:AddLine(L["MINIMAP_TOOLTIP_RIGHT"])
		end,
	})
	LibStub("LibDBIcon-1.0"):Register(ADDON, launcher, ns.db.profile.minimap)
end

-- Declared in the TOC (## AddonCompartmentFunc)
function nxPanels_OnAddonCompartmentClick(_, button, owner)
	onClick(owner or AddonCompartmentFrame, button)
end
