local _, ns = ...

-- Public API, also available to the panel scripts as "nxPanels"
local API = {}
ns.API = API
_G.nxPanels = API

API.version = ns.version

-- Frame of a panel of the active layout, by id or by name
function API.GetPanelFrame(key)
	local layout = ns.Database:GetLayout(ns.Layouts.activeId)
	local id = ns.Database:FindPanel(layout, key)
	return id and ns.Layouts.frames[id]
end

-- Name and id of the active layout
function API.GetActiveLayout()
	local id = ns.Layouts.activeId
	local layout = ns.Database:GetLayout(id)
	if layout then
		return layout.name, id
	end
end

-- Activates a layout by id or by name; returns true on success
function API.ActivateLayout(key)
	local id = ns.Database:FindLayout(key)
	if not id then return false end
	ns.Layouts:Activate(id)
	return true
end

function API.Print(...)
	ns:Print(strjoin(" ", tostringall(...)))
end

---------------------------------------------------------------------------
-- Legacy object given to the old kgPanels scripts as "kgPanels"
---------------------------------------------------------------------------
local Legacy = {}
ns.LegacyAPI = Legacy

function Legacy:FetchFrame(name)
	return API.GetPanelFrame(name)
end

function Legacy:ActivateLayout(name)
	return API.ActivateLayout(name)
end

function Legacy:Print(...)
	API.Print(...)
end
