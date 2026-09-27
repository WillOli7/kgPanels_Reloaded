local ADDON, ns = ...

local Database = {}
ns.Database = Database

--[[
nxPanelsDB (AceDB)
	global.schema            data schema version (ns.SCHEMA)
	global.nextId            counter used to build stable ids
	global.layouts[id]       { name = "...", folders = { "name", ... }, panels = { [panelId] = panel } }
	global.media.background  user library: [name] = path
	global.media.border      user library: [name] = path
	global.migration         { source = "kgPanels_Reloaded", date = time() } once imported
	profile.layout           id of the active layout
	profile.enabled          panels shown or hidden
	profile.minimap          LibDBIcon settings
]]
local DEFAULTS = {
	global = {
		schema = ns.SCHEMA,
		nextId = 1,
		layouts = {},
		media = { background = {}, border = {} },
	},
	profile = {
		enabled = true,
		minimap = { hide = false },
	},
}

function Database:Init()
	self.db = LibStub("AceDB-3.0"):New("nxPanelsDB", DEFAULTS, true)
	ns.db = self.db

	local LibDualSpec = LibStub("LibDualSpec-1.0", true)
	if LibDualSpec then
		pcall(LibDualSpec.EnhanceDatabase, LibDualSpec, self.db, ADDON)
	end

	local function onProfile()
		ns.Layouts:ApplyActive()
	end
	self.db.RegisterCallback(self, "OnProfileChanged", onProfile)
	self.db.RegisterCallback(self, "OnProfileCopied", onProfile)
	self.db.RegisterCallback(self, "OnProfileReset", onProfile)

	self:Upgrade()
	for _, layout in pairs(self.db.global.layouts) do
		self:NormalizeLayout(layout)
	end
end

-- Future schema changes go here, one step per version
function Database:Upgrade()
	local g = self.db.global
	g.schema = g.schema or ns.SCHEMA
end

function Database:NormalizeLayout(layout)
	layout.panels = layout.panels or {}
	layout.folders = layout.folders or {}
	for _, panel in pairs(layout.panels) do
		ns.FillDefaults(panel, ns.PanelDefaults)
	end
end

function Database:NewId(prefix)
	local g = self.db.global
	local id = g.nextId
	g.nextId = id + 1
	return prefix .. id
end

---------------------------------------------------------------------------
-- Layouts
---------------------------------------------------------------------------
function Database:GetLayout(id)
	return id and self.db.global.layouts[id]
end

-- Accepts an id or a name (case-insensitive)
function Database:FindLayout(key)
	if not key then return end
	local layouts = self.db.global.layouts
	if layouts[key] then
		return key, layouts[key]
	end
	local lower = key:lower()
	for id, layout in pairs(layouts) do
		if layout.name:lower() == lower then
			return id, layout
		end
	end
end

function Database:UniqueLayoutName(name)
	local candidate, n = name, 1
	while self:FindLayout(candidate) do
		n = n + 1
		candidate = ("%s (%d)"):format(name, n)
	end
	return candidate
end

function Database:CreateLayout(name)
	local id = self:NewId("L")
	self.db.global.layouts[id] = { name = self:UniqueLayoutName(name), folders = {}, panels = {} }
	return id, self.db.global.layouts[id]
end

-- Sorted list of { id = ..., layout = ... }
function Database:SortedLayouts()
	local list = {}
	for id, layout in pairs(self.db.global.layouts) do
		list[#list + 1] = { id = id, layout = layout }
	end
	table.sort(list, function(a, b) return a.layout.name:lower() < b.layout.name:lower() end)
	return list
end

function Database:CountPanels(layout)
	local n = 0
	for _ in pairs(layout.panels) do n = n + 1 end
	return n
end

function Database:GetActiveLayoutId()
	local id = self.db.profile.layout
	if id and self.db.global.layouts[id] then
		return id
	end
end

function Database:SetActiveLayoutId(id)
	self.db.profile.layout = id
end

-- Panel lookup by id or by name inside a layout
function Database:FindPanel(layout, key)
	if not layout or not key then return end
	if layout.panels[key] then
		return key, layout.panels[key]
	end
	for id, panel in pairs(layout.panels) do
		if panel.name == key then
			return id, panel
		end
	end
end
