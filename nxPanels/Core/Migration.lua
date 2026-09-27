local ADDON, ns = ...
local L = ns.L

local Migration = {}
ns.Migration = Migration

--[[
Import of the legacy kgPanels / kgPanels_Reloaded data (global "kgPanelsDB").

An addon can only read its own SavedVariables file. The release therefore ships
a small load-on-demand addon named "kgPanels_Reloaded" (the bridge) which only
declares kgPanelsDB: loading it gives us the old file of kgPanels_Reloaded users.
Users of the original kgPanels have the data loaded by kgPanels itself.

The legacy table is never modified: it stays saved as a backup.
]]

local LEGACY_ORIGINAL = "kgPanels"
local LEGACY_RELOADED = "kgPanels_Reloaded"
local LEGACY_CONFIG = "kgPanelsConfig_Reloaded"

-- "None" as stored by the legacy addon, in every language it was translated to
local NONE = {
	[""] = true, ["None"] = true, ["Aucun"] = true, ["无"] = true, ["無"] = true, ["Keiner"] = true,
	["Ninguno"] = true, ["없음"] = true, ["Нисколько"] = true, ["Nessuno"] = true, ["Nenhum"] = true,
}

-- Legacy translated border names -> LibSharedMedia keys
local BORDER_ALIASES = {
	["Bulle d'aide de Blizzard"] = "Blizzard Tooltip",
	["Blizzard-Tooltip"] = "Blizzard Tooltip",
	["Ventana emergente de Blizzard"] = "Blizzard Tooltip",
	["블리자드 툴팁"] = "Blizzard Tooltip",
	["Подсказка Blizzard"] = "Blizzard Tooltip",
	["默认提示信息框"] = "Blizzard Tooltip",
	["默認提示信息框"] = "Blizzard Tooltip",
	["Fenêtre de dialogue de Blizzard"] = "Blizzard Dialog",
	["Dialogue de Blizzard"] = "Blizzard Dialog",
	["Blizzard-Dialog"] = "Blizzard Dialog",
	["Diálogo de Blizzard"] = "Blizzard Dialog",
	["블리자드 대화창"] = "Blizzard Dialog",
	["Диалог Blizzard"] = "Blizzard Dialog",
	["默认对话框"] = "Blizzard Dialog",
	["默認對話框"] = "Blizzard Dialog",
}

-- Legacy "default font" names: nxPanels uses the language default font instead
local DEFAULT_FONTS = { [""] = true, ["Blizzard"] = true, ["暴雪"] = true, ["블리자드"] = true }

-- Built-in legacy library entries, not worth importing into the user library
local BUILTIN_MEDIA = {
	["Solid"] = true, ["Blizzard Tooltip"] = true, ["Blizzard Dialog"] = true,
}

---------------------------------------------------------------------------
-- Value conversion
---------------------------------------------------------------------------
local function num(value, default)
	return tonumber(value) or default
end

-- "247", 247, "50%" -> value, unit
local function size(value, default)
	local s = tostring(value or "")
	local pct = s:match("^%s*(%d+%.?%d*)%s*%%")
	if pct then
		return tonumber(pct), "%"
	end
	return tonumber(s:match("%-?%d+%.?%d*")) or default, "px"
end

local function color(c, default)
	if type(c) ~= "table" then return ns.DeepCopy(default) end
	return { r = num(c.r, default.r), g = num(c.g, default.g), b = num(c.b, default.b), a = num(c.a, default.a) }
end

-- false = no texture (nil would be replaced by the default texture)
local function mediaKey(value, aliases)
	if type(value) ~= "string" or NONE[value] then return false end
	return aliases and aliases[value] or value
end

local function bool(value)
	return value == true
end

---------------------------------------------------------------------------
-- Panel conversion
---------------------------------------------------------------------------
local function convertPanel(old, name, refToId, dependency)
	local D = ns.PanelDefaults
	local p = {}

	p.name = name
	p.folder = type(old.folder) == "string" and old.folder ~= "" and old.folder or nil

	-- References to another panel of the same layout become "panel:<id>"
	local function ref(value)
		if type(value) ~= "string" or value == "" then return "UIParent" end
		if refToId[value] then return "panel:" .. refToId[value] end
		return value
	end
	p.parent = ref(old.parent)
	p.anchor = {
		point = old.anchorFrom or "CENTER",
		relativeTo = ref(old.anchor),
		relativePoint = old.anchorTo or "CENTER",
		x = num(old.x, 0),
		y = num(old.y, 0),
	}
	p.width, p.widthUnit = size(old.width, D.width)
	p.height, p.heightUnit = size(old.height, D.height)
	p.scale = num(old.scale, 1)
	p.strata = old.strata or D.strata
	p.level = math.max(0, num(old.level, 0))
	p.mouse = bool(old.mouse)

	local insets = type(old.bg_insets) == "table" and old.bg_insets or {}
	local style = old.bg_style
	if style ~= "SOLID" and style ~= "GRADIENT" and style ~= "NONE" then style = "SOLID" end
	local texCoord
	if old.use_absolute_bg and type(old.absolute_bg) == "table" then
		local c = old.absolute_bg
		texCoord = { num(c.ULx, 0), num(c.ULy, 0), num(c.LLx, 0), num(c.LLy, 1), num(c.URx, 1), num(c.URy, 0), num(c.LRx, 1), num(c.LRy, 1) }
	end
	p.background = {
		style = style,
		texture = mediaKey(old.bg_texture),
		color = color(old.bg_color, D.background.color),
		color2 = color(old.gradient_color, D.background.color2),
		orientation = old.bg_orientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL",
		blend = old.bg_blend or "BLEND",
		alpha = num(old.bg_alpha, 1),
		-- Legacy offsets: TOPLEFT (l, t) and BOTTOMRIGHT (r, b)
		insets = { left = num(insets.l, 4), top = -num(insets.t, -4), right = -num(insets.r, -4), bottom = num(insets.b, 4) },
		rotation = num(old.rotation, 0),
		flipH = bool(old.hflip),
		flipV = bool(old.vflip),
		texCoord = texCoord,
		tile = bool(old.tiling),
		tileSize = num(old.tileSize, 0),
		subLevel = math.max(-8, math.min(7, num(old.sub_level, 0))),
	}

	local hidden = {}
	if type(old.border_advanced) == "table" and old.border_advanced.enable and type(old.border_advanced.show) == "table" then
		for section, shown in pairs(old.border_advanced.show) do
			if shown == false then hidden[section] = true end
		end
	end
	p.border = {
		texture = mediaKey(old.border_texture, BORDER_ALIASES),
		color = color(old.border_color, D.border.color),
		size = num(old.border_edgeSize, 16),
		hidden = hidden,
	}

	local t = type(old.text) == "table" and old.text or {}
	local font = type(t.font) == "string" and not DEFAULT_FONTS[t.font] and t.font or nil
	local fontSize = num(t.size, 12)
	p.text = {
		value = type(t.text) == "string" and t.text or "",
		font = font,
		size = fontSize > 0 and fontSize or 12,
		outline = "",
		color = color(t.color, D.text.color),
		x = num(t.x, 0),
		y = num(t.y, 0),
		justifyH = t.justifyH or "CENTER",
		justifyV = t.justifyV or "MIDDLE",
	}

	p.scripts = {}
	if type(old.scripts) == "table" then
		for hook, code in pairs(old.scripts) do
			if type(code) == "string" and code:find("%S") then
				p.scripts[hook] = code
			end
		end
	end
	p.scriptDependency = type(dependency) == "string" and dependency ~= "" and dependency or nil

	return ns.FillDefaults(p, D)
end

---------------------------------------------------------------------------
-- Layout conversion into a raw nxPanelsDB table
-- Returns the number of layouts and panels, and the old name -> new id map
---------------------------------------------------------------------------
local function newId(g, prefix)
	local id = g.nextId or 1
	g.nextId = id + 1
	return prefix .. id
end

local function uniqueName(g, name)
	local used = {}
	for _, layout in pairs(g.layouts) do used[layout.name:lower()] = true end
	local candidate, n = name, 1
	while used[candidate:lower()] do
		n = n + 1
		candidate = ("%s (%d)"):format(name, n)
	end
	return candidate
end

local function convertLayouts(legacyGlobal, g)
	local layoutIds, layoutCount, panelCount = {}, 0, 0
	local legacyLayouts = type(legacyGlobal.layouts) == "table" and legacyGlobal.layouts or {}
	local deps = type(legacyGlobal.layout_deps) == "table" and legacyGlobal.layout_deps or {}
	local folders = type(legacyGlobal.foldersByLayout) == "table" and legacyGlobal.foldersByLayout or {}

	-- Stable order: sorted by name
	local names = {}
	for name, data in pairs(legacyLayouts) do
		if type(name) == "string" and type(data) == "table" and not (NONE[name] and next(data) == nil) then
			names[#names + 1] = name
		end
	end
	table.sort(names)

	for _, layoutName in ipairs(names) do
		local legacy = legacyLayouts[layoutName]
		local id = newId(g, "L")
		local layout = { name = uniqueName(g, layoutName), folders = {}, panels = {} }
		g.layouts[id] = layout
		layoutIds[layoutName] = id
		layoutCount = layoutCount + 1

		local panelNames = {}
		for panelName in pairs(legacy) do
			if type(panelName) == "string" then panelNames[#panelNames + 1] = panelName end
		end
		table.sort(panelNames)

		-- First pass: ids, so panels can reference each other
		local refToId = {}
		for _, panelName in ipairs(panelNames) do
			refToId[panelName] = newId(g, "P")
		end

		local folderSet = {}
		local layoutDeps = type(deps[layoutName]) == "table" and deps[layoutName] or {}
		for _, panelName in ipairs(panelNames) do
			local old = legacy[panelName]
			if type(old) == "table" then
				local panel = convertPanel(old, panelName, refToId, layoutDeps[panelName])
				layout.panels[refToId[panelName]] = panel
				panelCount = panelCount + 1
				if panel.folder then folderSet[panel.folder] = true end
			end
		end
		if type(folders[layoutName]) == "table" then
			for folder, enabled in pairs(folders[layoutName]) do
				if enabled and type(folder) == "string" and folder ~= "" and folder ~= "__ROOT__" then
					folderSet[folder] = true
				end
			end
		end
		for folder in pairs(folderSet) do layout.folders[#layout.folders + 1] = folder end
		table.sort(layout.folders)
	end

	-- Custom art of the legacy library
	for kind, legacyKind in pairs({ background = "artwork", border = "border" }) do
		if type(legacyGlobal[legacyKind]) == "table" then
			for name, path in pairs(legacyGlobal[legacyKind]) do
				if type(name) == "string" and type(path) == "string" and path ~= ""
					and not NONE[name] and not BUILTIN_MEDIA[name] and not BORDER_ALIASES[name] then
					g.media[kind][name] = g.media[kind][name] or path
				end
			end
		end
	end

	return layoutCount, panelCount, layoutIds
end

---------------------------------------------------------------------------
-- Legacy data access
---------------------------------------------------------------------------
local function isLoaded(name)
	return C_AddOns.IsAddOnLoaded(name)
end

local function exists(name)
	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.GetAddOnInfo(i) == name then
			return true
		end
	end
	return false
end

-- Returns the legacy table and its source name, loading the bridge if needed
function Migration:GetLegacyData()
	if isLoaded(LEGACY_ORIGINAL) and type(_G.kgPanelsDB) == "table" then
		return _G.kgPanelsDB, LEGACY_ORIGINAL
	end
	if exists(LEGACY_RELOADED) then
		if not isLoaded(LEGACY_RELOADED) then
			local loaded, reason = C_AddOns.LoadAddOn(LEGACY_RELOADED)
			if not loaded and reason == "DISABLED" then
				C_AddOns.EnableAddOn(LEGACY_RELOADED)
				C_AddOns.LoadAddOn(LEGACY_RELOADED)
			end
		end
		if type(_G.kgPanelsDB) == "table" then
			return _G.kgPanelsDB, LEGACY_RELOADED
		end
	end
end

---------------------------------------------------------------------------
-- Automatic migration: runs before AceDB, on the first start of nxPanels
---------------------------------------------------------------------------
function Migration:Prepare()
	local sv = _G.nxPanelsDB
	if type(sv) == "table" and type(sv.global) == "table"
		and (sv.global.migration or (type(sv.global.layouts) == "table" and next(sv.global.layouts))) then
		return
	end

	local legacy, source = self:GetLegacyData()
	if type(legacy) ~= "table" or type(legacy.global) ~= "table" then return end

	legacy = ns.DeepCopy(legacy)
	sv = type(sv) == "table" and sv or {}
	sv.global = sv.global or {}
	local g = sv.global
	g.schema = ns.SCHEMA
	g.nextId = g.nextId or 1
	g.layouts = g.layouts or {}
	g.media = g.media or { background = {}, border = {} }
	g.media.background = g.media.background or {}
	g.media.border = g.media.border or {}

	local layoutCount, panelCount, layoutIds = convertLayouts(legacy.global, g)

	-- Profiles keep their name, their characters and their active layout
	sv.profiles = sv.profiles or {}
	if type(legacy.profiles) == "table" then
		for profileName, profile in pairs(legacy.profiles) do
			if type(profile) == "table" then
				sv.profiles[profileName] = {
					layout = layoutIds[profile.layout],
					enabled = profile.enabled ~= false,
				}
			end
		end
	end
	if type(legacy.profileKeys) == "table" then
		sv.profileKeys = sv.profileKeys or {}
		for char, profileName in pairs(legacy.profileKeys) do
			sv.profileKeys[char] = sv.profileKeys[char] or profileName
		end
	end
	if type(legacy.namespaces) == "table" and type(legacy.namespaces["LibDualSpec-1.0"]) == "table" then
		sv.namespaces = sv.namespaces or {}
		sv.namespaces["LibDualSpec-1.0"] = legacy.namespaces["LibDualSpec-1.0"]
	end

	g.migration = { source = source, date = time(), layouts = layoutCount, panels = panelCount }
	_G.nxPanelsDB = sv
	self.done = { source = source, layouts = layoutCount, panels = panelCount }
end

-- After login: report, and switch the legacy addons off
function Migration:Finish()
	local done = self.done
	if not done then return end
	self.done = nil

	ns:Print(L["MIGRATED"], done.layouts, done.panels, done.source)

	local needReload = isLoaded(LEGACY_ORIGINAL)
	for _, name in ipairs({ LEGACY_ORIGINAL, LEGACY_RELOADED, LEGACY_CONFIG }) do
		if exists(name) then
			C_AddOns.DisableAddOn(name)
		end
	end

	if needReload then
		StaticPopupDialogs["NXPANELS_MIGRATED"] = {
			text = L["MIGRATE_POPUP"],
			button1 = L["RELOAD"],
			button2 = L["LATER"],
			OnAccept = function() ReloadUI() end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("NXPANELS_MIGRATED")
	end
end

---------------------------------------------------------------------------
-- Manual import (/nxp import): adds the legacy layouts as new layouts
---------------------------------------------------------------------------
function Migration:ImportAgain()
	local legacy, source = self:GetLegacyData()
	if type(legacy) ~= "table" or type(legacy.global) ~= "table" then
		ns:Print(L["MIGRATE_NOTHING"])
		return
	end
	local layoutCount, panelCount = convertLayouts(ns.DeepCopy(legacy.global), ns.db.global)
	for _, layout in pairs(ns.db.global.layouts) do
		ns.Database:NormalizeLayout(layout)
	end
	ns:Print(L["MIGRATED"], layoutCount, panelCount, source)
end

-- Exposed for the offline tests (tools/tests)
Migration._convertLayouts = convertLayouts
