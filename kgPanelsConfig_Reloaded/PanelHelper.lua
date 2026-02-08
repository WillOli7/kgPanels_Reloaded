local kgPanels = LibStub("AceAddon-3.0"):GetAddon("kgPanels")
local kgPanelsConfig = kgPanels:GetModule("kgPanelsConfig")
local L = LibStub("AceLocale-3.0"):GetLocale("kgPanels", false)
local cfgreg = LibStub("AceConfigRegistry-3.0")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0",true)
local guide = kgPanels:GetModule("GuideFrame")

local vert_just = {
	["TOP"] = L["Top"],
	["MIDDLE"] = L["Middle"],
	["BOTTOM"] = L["Bottom"]
}
local horz_just = {
	["LEFT"] = L["Left"],
	["RIGHT"] = L["Right"],
	["CENTER"] = L["Center"]
}
local fontList = {
	["Blizzard"] = "Blizzard"
}
local anchorSpots = {
	["CENTER"] = L["Center"],
	["LEFT"] = L["Left"],
	["RIGHT"] = L["Right"],
	["TOP"] = L["Top"],
	["BOTTOM"] = L["Bottom"],
	["BOTTOMLEFT"] = L["Bottom Left"],
	["BOTTOMRIGHT"] = L["Bottom Right"],
	["TOPLEFT"] = L["Top Left"],
	["TOPRIGHT"] = L["Top Right"]
}
local strata_lst = {
	["BACKGROUND"] = L["Background"],
	["LOW"] = L["Low"],
	["MEDIUM"] = L["Medium"],
	["HIGH"] = L["High"],
	["DIALOG"] = L["Dialog"],
	["TOOLTIP"] = L["Tooltip"],
}
local bg_color_style = {
	["SOLID"] = L["Solid"],
	["GRADIENT"] = L["Gradient"],
	["NONE"] = L["None"]
}
local bg_grad_style = {
	["HORIZONTAL"] = L["Horizontal"],
	["VERTICAL"] = L["Vertical"]
}
local blend_style = {
	["BLEND"] = L["Blend"],
	["ADD"] = L["Add"],
	["MOD"] = L["Mod"],
	["ALPHAKEY"] = L["AlphaKey"],
	["DISABLE"] = L["Disable"]
}
local copy_list = {
	["Textures"] = L["Textures"],
	["Colors"] = L["Colors"],
	["Anchors"] = L["Anchors"],
	["Text"] = L["Text"],
	["Scripts"] = L["Scripts"],
	["Postions"] = L["Postions"],
	["All"] = L["All"]
}
local borderArt = {}
local bgArt = {}
local tostring = tostring

-- =========================
-- Folder helpers
-- =========================
local ROOT_FOLDER = "__ROOT__"

local function GetPanelFolder(panelData)
	-- If user didn't assign a folder, it's Root
	if type(panelData) ~= "table" or not panelData.folder or panelData.folder == "" then
		return ROOT_FOLDER
	end
	return panelData.folder
end

-- shared media font support
if SharedMedia and SharedMedia.HashTable then
	local lst = SharedMedia:HashTable("font")
	for k,v in pairs(lst) do
		fontList[k] = k
	end
	lst = SharedMedia:HashTable("background")
	for k,v in pairs(lst) do
		bgArt[k] = k
	end
	lst = SharedMedia:HashTable("border")
	for k,v in pairs(lst) do
		borderArt[k]=k
	end
	SharedMedia:RegisterCallback("LibSharedMedia_Registered",function()
		lst = SharedMedia:HashTable("border")
		for k,v in pairs(lst) do
			borderArt[k]=k
		end
		local lst = SharedMedia:HashTable("font")
		for k,v in pairs(lst) do
			fontList[k] = k
		end
		lst = SharedMedia:HashTable("background")
		for k,v in pairs(lst) do
			bgArt[k] = k
		end
	end)
else
	for k,v in pairs(kgPanels.db.global.artwork) do
		bgArt[k] = k
	end
	for k,v in pairs(kgPanels.db.global.border) do
		borderArt[k] = k
	end
end
kgPanelsConfig.lockFrames = {}
kgPanelsConfig.activePanels = {}
kgPanelsConfig.panelNames = {}
--[[
-- Self explanatory
--]]
local function DeepCopy(t, lookup_table)
	local copy = {}
	if type(t) ~= "table" then return t end
	for i,v in pairs(t) do
		if type(v) ~= "table" then
			copy[i] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[t] = copy
			if lookup_table[v] then
				copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
			else
				copy[i] = DeepCopy(v,lookup_table) -- not yet copied. copy it.
			end
		end
	end
	return copy
end

function kgPanelsConfig:InjectArt(atype,aname)
	if SharedMedia then
		if atype == "artwork" then
			SharedMedia:Register("background",aname,kgPanels.db.global.artwork[aname])
		else
			SharedMedia:Register("border",aname,kgPanels.db.global.border[aname])
		end
	else
		if atype == "artwork" then
			bgArt[aname]= aname
		end
		if atype == "border" then
			borderArt[aname] = aname
		end
	end
end
function kgPanelsConfig:DeleteArt(atype,aname)
	if atype == "artwork" then
		bgArt[aname]= nil
	end
	if atype == "border" then
		borderArt[aname] = nil
	end
end
--[[
	Generate our global menu for the active layout
]]
function kgPanelsConfig:InitDefaultMenu()
	-- TODO: Figure out which layout is active and generate the global menu
	kgPanelsConfig:CreatePanelMenu(L["Default"],kgPanels.db.global.defaultPanel,true)
end


--[[
	-- Generate our panel menus for the active layout
]]
function kgPanelsConfig:InitPanelMenus()
	local layoutName = self.activeLayout
	local layoutdata = kgPanels.db.global.layouts[layoutName] or {}

	-- Reset runtime lists
	self.activePanels = {}
	self.panelNames = {}

	-- Clean dynamic entries in the "Active Panels" tree (keep static UI groups)
	for key in pairs(self.panelList) do
		if key ~= "panelCreation" and key ~= "folderCreation" then
			self.panelList[key] = nil
		end
	end

	-- Group panels by folder
	local folders = {} -- folders[folderName] = { panelName1, panelName2, ... }
	for panelName, panelData in pairs(layoutdata) do
		if type(panelData) == "table" then
			self.activePanels[panelName] = panelData
			self.panelNames[panelName] = panelName

			local folderName = GetPanelFolder(panelData)
			folders[folderName] = folders[folderName] or {}
			table.insert(folders[folderName], panelName)
		end
	end

	-- Include saved folders even if they are empty (so they show immediately after "Create Folder")
	folders[ROOT_FOLDER] = folders[ROOT_FOLDER] or {}

	local savedFolders = kgPanels.db.global.foldersByLayout
		and kgPanels.db.global.foldersByLayout[layoutName]
	if savedFolders then
		for folderName, enabled in pairs(savedFolders) do
			if enabled and folderName and folderName ~= "" then
				folders[folderName] = folders[folderName] or {}
			end
		end
	end

	-- Sort folders (Root first)
	local folderNames = {}
	for folderName in pairs(folders) do
		table.insert(folderNames, folderName)
	end
	table.sort(folderNames, function(a, b)
		if a == ROOT_FOLDER then return true end
		if b == ROOT_FOLDER then return false end
		return a < b
	end)

	-- Build folder groups + insert folder options + insert panel menus inside
	local folderOrder = 10
	for _, folderName in ipairs(folderNames) do
		local displayName = (folderName == ROOT_FOLDER) and L["Root"] or folderName
		local folderKey = "folder_" .. self:makeKey(displayName)

		-- Capture stable values for closures
		local currentFolder = folderName
		local currentLayout = layoutName

		self.panelList[folderKey] = {
			type = "group",
			name = displayName,
			childGroups = "tree",
			order = folderOrder,
			args = {
				folderOptions = (function()
					local renameValue = ""

					local function PanelCount()
						return #(folders[currentFolder] or {})
					end

					local function FolderHeader()
						if currentFolder == ROOT_FOLDER then
							return (L["Root (%d panel(s))."]):format(PanelCount())
						end
						return (L["Folder '%s' (%d panel(s))."]):format(currentFolder, PanelCount())
					end

					return {
						type = "group",
						name = L["Folder Options"],
						guiInline = true,
						order = 0,
						args = {
							headerTitle = {
								type = "header",
								name = FolderHeader,
								order = 0,
							},

							spacerA = {
								type = "description",
								name = " ",
								order = 0.1,
							},

							renameLabel = {
								type = "description",
								name = L["Rename folder"],
								order = 1,
							},

							renameInput = {
								type = "input",
								name = "",
								order = 2,
								width = "double",
								disabled = function() return currentFolder == ROOT_FOLDER end,
								get = function() return renameValue end,
								set = function(info, val) renameValue = val or "" end,
							},

							renameButton = {
								type = "execute",
								name = L["Rename"],
								order = 3,
								width = "half",
								disabled = function()
									local v = strtrim(renameValue or "")
									return currentFolder == ROOT_FOLDER or v == "" or v == currentFolder
								end,
								func = function()
									local v = strtrim(renameValue or "")
									if v == "" or v == currentFolder then return end
									kgPanelsConfig:RenameFolder(currentFolder, v, currentLayout)
									renameValue = ""
									kgPanelsConfig:InitPanelMenus()
								end,
							},

							spacerB = {
								type = "description",
								name = " ",
								order = 4,
							},

							deleteHeader = {
								type = "header",
								name = L["Delete folder"],
								order = 5,
							},

							deleteHint = {
								type = "description",
								name = L["Panels inside will be moved to Root."],
								order = 6,
							},

							deleteButton = {
								type = "execute",
								name = L["Delete..."],
								order = 7,
								width = "half",
								disabled = function() return currentFolder == ROOT_FOLDER end,
								confirm = function()
									return L["Delete this folder? Panels inside will be moved to Root."]
								end,
								func = function()
									kgPanelsConfig:DeleteFolder(currentFolder, currentLayout)
									kgPanelsConfig:InitPanelMenus()
								end,
							},
						},
					}
				end)(),
			},
		}

		-- Sort panels inside folder
		table.sort(folders[folderName])

		-- Insert panels directly under the folder (no "Panels" subgroup)
		local targetArgs = self.panelList[folderKey].args
		local panelOrder = 10

		for _, panelName in ipairs(folders[folderName]) do
			local panelData = layoutdata[panelName]
			self:CreatePanelMenu(panelName, panelData, false, targetArgs)

			-- Force panels to appear after folderOptions
			local k = self:makeKey(panelName)
			if targetArgs[k] then
				targetArgs[k].order = panelOrder
				panelOrder = panelOrder + 1
			end
		end

		folderOrder = folderOrder + 1
	end

	-- Notify once after rebuilding the full tree
	cfgreg:NotifyChange("kgPanelsConfig")
end


--[[
	Called by our config menu when the user asks to create a new panel
	We tell kgPanels to handle creation of the panel, and then we create a menu for the panel
]]
function kgPanelsConfig:CreatePanel(name, data)
	local panelName = name
	-- Check if the panel name exists already, and modify it if there's a collision
	panelName = kgPanelsConfig:uniqueName(panelName, self.panelList, 0)
	if not data then
		self.activePanels[panelName] = DeepCopy(kgPanels.db.global.defaultPanel)
		data = self.activePanels[panelName]
	else
		self.activePanels[panelName] = DeepCopy(data)
	end
	self.panelNames[panelName] = panelName
	kgPanels.db.global.layouts[self.activeLayout][panelName] = self.activePanels[panelName]
	-- place the frame in view
	kgPanels:PlaceFrame(panelName,self.activePanels[panelName])
	kgPanelsConfig:CreatePanelMenu(panelName,self.activePanels[panelName])
	-- add the guide frame
	local g = guide:GetGuideFrame(panelName,data.anchorTo,data.anchorFrom,data.anchor)
	self.lockFrames[panelName] = g
	cfgreg:NotifyChange("kgPanelsConfig")
end


--[[
	Create a option menu for a panel, and insert it into our configuration menu table
]]
function kgPanelsConfig:CreatePanelMenu(panelName, panelData, isDefault, parentArgsTable)
	--local panelData = data or self.activePanels[panelName]
	local _copy_src = nil
	local _panel_src = nil
	local _rename = nil
	local _default = isDefault
	-- Create the panel menu
	local tempPanelMenu = {
		type = "group",
		name = panelName,
		desc = L["User defined Panel"],
		childGroups = "tree",
		get = function( k ) return panelData[k.arg] end,
		args = {
			generalOpts = {
				type = "group",
				name = L["General Settings"],
				guiInline = true,
				order = 1,
				args = {
					lock = {
						type = 'toggle',
						name = L["Lock Panel"],
						desc = L["Lock/Unlock this panel."],
						order = 1,
						get = function()
							if self.lockFrames[panelName] then
								return false
							else
								return true
							end
						end,
						set = function(info,val)
							if not val then
								local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
								self.lockFrames[panelName] = g
							else
								if self.lockFrames[panelName] then
									guide:DeleteGuide(self.lockFrames[panelName])
									self.lockFrames[panelName] = nil
								end
							end
						end,
						disabled = function() return _default end,
					},
					interceptMouse = {
						type = 'toggle',
						name = L["Intercept Mouse Clicks"],
						desc = L["This option controls wether the panel will interact with the mouse. Required for OnLeave,OnEnter,OnClick"],
						width = "full",
						order = 1,
						arg = "mouse",
						get = function() return panelData.mouse end,
						set = function(info,val)
							panelData[info.arg] = val
							local frame = kgPanels:FetchFrame(panelName)
							if frame then
								frame:EnableMouse(val)
							end
						end,
					},
					remove = {
						type = 'execute',
						name = L["Remove Panel"],
						desc = L["Delete this panel from the layout."],
						order = 2,
						func = function()
							-- nuke the guide frame it if exists
							if self.lockFrames[panelName] then
								guide:DeleteGuide(self.lockFrames[panelName])
								self.lockFrames[panelName] = nil
							end
							self.panelList[self:makeKey(panelName)] = nil
							self.activePanels[panelName] = nil
							self.panelNames[panelName] = nil
							kgPanels:RemoveFrame(panelName)
							-- remvoe from db
							kgPanels.db.global.layouts[self.activeLayout][panelName] = nil
							cfgreg:NotifyChange("kgPanelsConfig")
						end,
						confirm = true,
						confirmText = L["Are you sure you wish to delete this panel? This can not be undone."],
					},
					copy = {
						type = 'select',
						name = L["Copy"],
						desc = L["Copy configuration from another panel to use in this panel."],
						order = 3,
						style = "dropdown",
						values = copy_list,
						set = function(info,val) _copy_src = val end,
						get = function() return _copy_src end
					},
					paste = {
						type = 'select',
						name = L["From"],
						desc = L["Panel you wish to copy from."],
						order = 4,
						style = "dropdown",
						values = self.panelNames,
						set = function(info,val) _paste_src = val end,
						get = function() return _paste_src end
					},
					space = {
						type = "description",
						name = " ",
						desc = " ",
						order = 6,
					},
					perform = {
						type = "execute",
						name = L["Paste"],
						desc = L["Perform a paste."],
						order = 5,
						disabled = function() return _copy_src == nil or _paste_src == nil end,
						func = function()
							-- do copy
							local d = self.activePanels[_paste_src]
							local t = self.activePanels[panelName]
							if _copy_src == "All" then
								t = DeepCopy(d)
								t.scripts = DeepCopy(d.scripts)
								t.text = DeepCopy(d.text)
								t.bg_insets = DeepCopy(d.bg_insets)
								t.bg_color = DeepCopy(d.bg_color)
								t.border_color = DeepCopy(d.border_color)
								t.gradient_color = DeepCopy(d.gradient_color)
								t.absolute_bg = DeepCopy(d.absolute_bg)
							elseif _copy_src == "Anchors" then
								t.anchor = d.anchor
								t.anchorFrom = d.anchorFrom
								t.anchorTo = d.anchorTo
							elseif _copy_src == "Positions" then
								t.x = d.x
								t.y = d.y
								t.level = d.level
								t.strata = d.strata
								t.width = d.width
								t.height = d.height
							elseif _copy_src == "Textures" then
								t.border_texture = d.border_texture
								t.border_edgeSize = d.border_edgeSize
								t.bg_blend = d.bg_blend
								t.bg_style = d.bg_style
								t.bg_texture = d.bg_texture
								t.bg_alpha = d.bg_alpha
								t.bg_insets = DeepCopy(d.bg_insets)
								t.absolute_bg = DeepCopy(d.absolute_bg)
								t.use_absolute_bg = d.use_absolute_bg
							elseif _copy_src == "Colors" then
								t.bg_color = DeepCopy(d.bg_color)
								t.border_color = DeepCopy(d.border_color)
								t.gradient_color = DeepCopy(d.gradient_color)
							elseif _copy_src == "Text" then
								t.text = DeepCopy(d.text)
							elseif _copy_src == "Scripts" then
								t.scripts = DeepCopy(d.scripts)
							end
							-- post check
							kgPanels.db.global.layouts[self.activeLayout][panelName] = t
							cfgreg:NotifyChange("kgPanelsConfig")
							kgPanels:RemoveFrame(panelName)
							kgPanels:PlaceFrame(panelName,t)
							if self.lockFrames[panelName] then
								guide:DeleteGuide(self.lockFrames[panelName])
								local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
								self.lockFrames[panelName] = g
							end
							_copy_src = nil
							_paste_src = nil
							panelData = t
						end
					},
					rename_input = {
						type = "input",
						name = L["Rename"],
						desc = L["New name for this panel."],
						order = 7,
						get = function(k) return _rename end,
						set = function(info,k) _rename = k end,
					},
					rename_exec = {
						type = "execute",
						name = L["Rename Panel"],
						desc = L["Change the name of this panel."],
						order = 8,
						func =  function()
							local dc = DeepCopy(kgPanels.db.global.layouts[self.activeLayout][panelName])
							kgPanels:RemoveFrame(panelName)
							kgPanels:PlaceFrame(_rename,dc)
							kgPanels.db.global.layouts[self.activeLayout][_rename] = dc
							kgPanels.db.global.layouts[self.activeLayout][panelName] = nil
							if self.lockFrames[panelName] then
								guide:DeleteGuide(self.lockFrames[panelName])
								self.lockFrames[panelName] = nil
							end
							self.panelList[self:makeKey(panelName)] = nil
							self.activePanels[panelName] = nil
							self.panelNames[panelName] = nil
							self:CreatePanelMenu(_rename, dc)
							self.activePanels[_rename] = dc
							self.panelNames[_rename] = _rename
						end,
						disabled = function()
							if _rename == nil or strlen(_rename) <1 or _default then
								return true
							end
							return false
						end,
						confirm = function()
							if kgPanels.db.global.layouts[self.activeLayout][_rename] then return true end
							return false
						end,
						confirmText = L["There is already a panel with that name. Overwrite?"],
					}
				},
			},
			colorOpts = {
				type = "group",
				name = L["Color And Opacity Settings"],
				guiInline = true,
				order = 3,
				set = function(info,val)
					panelData[info.arg] = val
					local frame = kgPanels:FetchFrame(panelName)
					if frame then
						kgPanels:ResetTextures(frame,panelData,panelName)
					end
				end,
				args = {
					overallOpacity = {
						type = "range",
						name = L["Panel Opacity"],
						desc = L["Set the opacity of this panel."],
						width = "full",
						order = 0,
						min = 0,
						max = 1,
						isPercent = true,
						step = 0.005,
						arg = "bg_alpha",
					},
					bgColorStyle =
					{
						type='select',
						name = L["Background Color Style"],
						desc = L["Color style of this panel. NOTE: None disables background coloring."],
						values = bg_color_style,
						order = 10,
						arg = "bg_style",
					},

					bgColor = {
						type = "color",
						name = L["Background Color"],
						desc = L["Background color of this panel."],
						order = 11,
						hasAlpha = true,
						get = function() return panelData.bg_color.r,panelData.bg_color.g,panelData.bg_color.b,panelData.bg_color.a end,
						set = function(info,r,g,b,a)
							panelData.bg_color.r =r
							panelData.bg_color.g =g
							panelData.bg_color.b =b
							panelData.bg_color.a =a
							local frame = kgPanels:FetchFrame(panelName)
							if frame then
								kgPanels:ResetTextures(frame,panelData,panelName)
							end
						end
					},

					bgGradientStyle =
					{
						type='select',
						name = L["Background Gradient Style"],
						desc = L["Gradient style of this panel."],
						values = bg_grad_style,
						order = 17,
						arg = "bg_orientation"
					},

					bgGradientColor = {
						type = "color",
						name = L["Background Gradient Color"],
						desc = L["Color to use for the gradient."],
						order = 18,
						hasAlpha = true,
						get = function() return panelData.gradient_color.r, panelData.gradient_color.g, panelData.gradient_color.b, panelData.gradient_color.a end,
						set = function(info,r,g,b,a)
							panelData.gradient_color.r =r
							panelData.gradient_color.g =g
							panelData.gradient_color.b =b
							panelData.gradient_color.a =a
							local frame = kgPanels:FetchFrame(panelName)
							if frame then
								kgPanels:ResetTextures(frame,panelData,panelName)
							end
						end
					},

					bgBlendMode = {
						type = "select",
						name = L["Background Color Blending"],
						desc = L["Blend mode for the background color."],
						values = blend_style,
						order = 19,
						arg = "bg_blend",
					},

					bgBorderColor = {
						type = "color",
						name = L["Border Color"],
						desc = L["Border coloring."],
						order = 20,
						hasAlpha = true,
						get = function() return panelData.border_color.r, panelData.border_color.g, panelData.border_color.b, panelData.border_color.a end,
						set = function(info,r,g,b,a)
							panelData.border_color.r =r
							panelData.border_color.g =g
							panelData.border_color.b =b
							panelData.border_color.a =a
							local frame = kgPanels:FetchFrame(panelName)
							if frame then
								kgPanels:ResetTextures(frame,panelData,panelName)
							end
						end
					},
				},
			},
			positionOpts = {
				type = "group",
				name = L["Position Settings"],
				guiInline = true,
				order = 5,
				set = function(info,val)
					panelData[info.arg] = val
					local frame = kgPanels:FetchFrame(panelName)
					if frame then
						kgPanels:ResetParent(frame,panelData,panelName)
						kgPanels:ResetTextures(frame,panelData,panelName)
						if self.lockFrames[panelName] then
							guide:DeleteGuide(self.lockFrames[panelName])
							local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
							self.lockFrames[panelName] = g
						end
					end
				end,
				get = function(k)
					return tostring(panelData[k.arg])
				end,
				args = {
					width = {
						type = "input",
						name = L["Panel Width"],
						desc = L["Panel width."],
						order = 30,
						pattern = "%d+%.?%d*%%?",
						usage='10.0, 10%, 20.2%',
						arg = "width"
					},
					height = {
						type = "input",
						name = L["Panel Height"],
						desc = L["Panel height."],
						order = 40,
						usage='10.0, 10%, 20.2%',
						pattern = "%d+%.?%d*%%?",
						arg = "height",
					},
					xOffset = {
						type = "input",
						name = L["X Offset"],
						desc = L["X offsetting, positive for right, negative for left."],
						order = 50,
						usage='10',
						pattern = "%-?%d+",
						arg = "x",
					},
					yOffset = {
						type = "input",
						name = L["Y Offset"],
						desc = L["Y offsetting, positive for up, negative for down."],
						order = 60,
						usage='10',
						pattern = "%-?%d+",
						arg = "y"
					},
					nudge = {
						type = "group",
						name = L["Nudge"],
						desc = L["Nudge the panel position in a given direction."],
						order = 61,
						width = "half",
						guiInline = true,
						args = {
							up = {
								type = "execute",
								name = L["Up"],
								desc = "",
								width = "half",
								order=1,
								func = function()
									local v = panelData["y"]
									v = v + 1
									panelData["y"] = v
									local frame = kgPanels:FetchFrame(panelName)
									if frame then
										kgPanels:ResetParent(frame,panelData,panelName)
										if self.lockFrames[panelName] then
											guide:DeleteGuide(self.lockFrames[panelName])
											local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
											self.lockFrames[panelName] = g
										end
									end
								end
							},
							down = {
								type = "execute",
								name = L["Down"],
								desc = "",
								width="half",
								order=2,
								func = function()
									local v = panelData["y"]
									v = v - 1
									panelData["y"] = v
									local frame = kgPanels:FetchFrame(panelName)
									if frame then
										kgPanels:ResetParent(frame,panelData,panelName)
										if self.lockFrames[panelName] then
											guide:DeleteGuide(self.lockFrames[panelName])
											local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
											self.lockFrames[panelName] = g
										end
									end
								end
							},
							left = {
								type = "execute",
								name = L["Left"],
								desc = "",
								width="half",
								order=3,
								func = function()
									local v = panelData["x"]
									v = v - 1
									panelData["x"] = v
									local frame = kgPanels:FetchFrame(panelName)
									if frame then
										kgPanels:ResetParent(frame,panelData,panelName)
										if self.lockFrames[panelName] then
											guide:DeleteGuide(self.lockFrames[panelName])
											local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
											self.lockFrames[panelName] = g
										end
									end
								end

							},
							right={
								type = "execute",
								name = L["Right"],
								desc = "",
								width = "half",
								order=4,
								func = function()
									local v = panelData["x"]
									v = v + 1
									panelData["x"] = v
									local frame = kgPanels:FetchFrame(panelName)
									if frame then
										kgPanels:ResetParent(frame,panelData,panelName)
										if self.lockFrames[panelName] then
											guide:DeleteGuide(self.lockFrames[panelName])
											local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
											self.lockFrames[panelName] = g
										end
									end
								end
							},
						},
					},
					level = {
						type = "range",
						name = L["Level"],
						desc = L["Panel level, for Z-Indexing."],
						order = 70,
						min = 0,
						max = 20,
						step = 1,
						get = function(k)
							if panelData[k.arg] < 0 then
								panelData[k.arg] = 0
							end
							return panelData[k.arg]
						end,
						arg = "level",
					},
					strata = {
						type = "select",
						name = L["Strata"],
						desc = L["Frame strata to set this in, Background is the lowest strata."],
						values = strata_lst,
						order = 80,
						arg = "strata",
					},
					subLevel = {
						type = 'range',
						name = L["Sublevel"],
						desc = L["Sublevel allows you to have multiple backgrounds in the same draw layer for stacking effects"],
						min = -8,
						max = 7,
						step = 1,
						order = 81,
						get = function(k)
							if not panelData[k.arg] then
								panelData[k.arg] = 0
							end
							return panelData[k.arg]
						end,
						arg = "sub_level",
					},
					scaling = {
						type = "range",
						name = L["Scaling"],
						desc = L["Panel scaling options."],
						order = 90,
						min = 0.1,
						max = 2.0,
						step = 0.01,
						arg = "scale",
						width = "fill",
						get = function(k)
							if not panelData[k.arg] then
								return 1
							end
							return panelData[k.arg]
						end,
					}
				},
			},
			parentOpts = {
				type = "group",
				name = L["Parent And Anchor Settings"],
				guiInline = true,
				order = 7,
				set = function(info,val)
					panelData[info.arg] = val
					local frame = kgPanels:FetchFrame(panelName)
					if frame then
						if arg == anchor then
							panelData["x"] = 0
							panelData["y"] = 0
						end
						kgPanels:ResetParent(frame,panelData,panelName)
						if self.lockFrames[panelName] then
							guide:DeleteGuide(self.lockFrames[panelName])
							local g = guide:GetGuideFrame(panelName,panelData.anchorTo,panelData.anchorFrom,panelData.anchor)
							self.lockFrames[panelName] = g
						end
					end
				end,
				args = {
					parent = {
						type = "input",
						name = L["Parent Frame"],
						desc = L["Frame you wish to parent against. NOTE: To parent against a panel you have already defined, simply use that name."],
						order = 10,
						usage='',
						arg = "parent",
					},
					anchor = {
						type = "input",
						name = L["Anchor Frame"],
						desc = L["Frame you wish to anchor this panel to."],
						order = 20,
						usage='',
						arg = "anchor",
					},
					anchorFrom = {
						type = "select",
						name = L["Anchor From"],
						desc = L["Anchoring from."],
						values = anchorSpots,
						order = 30,
						arg = "anchorFrom",
					},
					anchorTo = {
						type = "select",
						name = L["Anchor To"],
						desc = L["Anchoring to."],
						values = anchorSpots,
						order = 40,
						arg = "anchorTo",
					},
				},
			},
			-- border and background textures
			-- Do we want to allow for default backdrop texture swapping? -- Right now .. no, lets add this to a todo list
			-- Do we want to allow for multiple texture layers? -- Right now .. no, possible future after release.
			textureOptions = {
				type = "group",
				name = L["Texture Options"],
				childGroups = "tree",
				order = 6,
				set = function(info,val)
					panelData[info.arg] = val
					local frame = kgPanels:FetchFrame(panelName)
					if frame then
						kgPanels:ResetTextures(frame,panelData,panelName)
					end
				end,
				args = {
					texture = {
						type = "group",
						name = L["Background Texture"],
						guiInline = true,
						order = 0,
						args = {
							textureName = {
								type = 'select',
								name = L["Name"],
								dialogControl = "LSM30_Background",
								desc = L["Artwork to use for a background."],
								values = bgArt,
								order = 0,
								arg = "bg_texture",
								width = "full",
							},
							rotate =
							{
								type = 'range',
								name = L["Rotate"],
								desc = L["Rotate the artwork centered on the middle point."],
								width = "full",
								min = 0,
								max = 360,
								step = 1,
								bigStep = 5,
								order = 5,
								arg = "rotation"
							},
							flipHorizontal =
							{
								type = 'toggle',
								name = L["Flip Horizontally"],
								desc = L["Mirror this background."],
								order = 6,
								arg = "hflip",
							},
							flipVertical =
							{
								type = 'toggle',
								name = L["Flip Vertically"],
								desc = L["Invert the artwork."],
								order = 7,
								arg = "vflip"
							},
							tiling =
							{
								type = 'toggle',
								name = L["Tile Background"],
								desc = L["Tile the background texture, NOTE: this disables rotation and flipping."],
								order = 8,
								arg = "tiling",
							},
							--[[
							vert_tile = {
								type = 'toggle',
								name = L["Vertical Tiling"],
								desc = L["Tile the background vertically."],
								order = 9,
								arg = "vert_tile",
								disabled = function() return not (kgPanels.isCata and panelData["tiling"]) end,
							},
							horz_tile = {
								type = 'toggle',
								name = L["Horizontal Tiling"],
								desc = L["Tile the background horizontally."],
								order = 10,
								arg = "horz_tile",
								disabled = function() return not (kgPanels.isCata and panelData["tiling"]) end,
							},
							--]]
							--[[
								CODE HERE to TILE base don the new options hor or vert
							--]]
							tile_size =
							{
								type = 'range',
								name = L["Tile Size"],
								desc = L["Size of each tile."],
								order = 11,
								min = 1,
								max = 128,
								step = 1,
								arg = "tileSize",
								width = "fill",
								get = function(k)
									if not panelData[k.arg] then
										return 16
									end
									return panelData[k.arg]
								end,
								disabled = function() return not panelData.tiling end,
							},
							absolute_bg =
							{
								type = "toggle",
								name = L["Custom Coords"],
								desc = L["Use custom TexCoords. This is an adavance feature."],
								order = 12,
								arg = "use_absolute_bg"
							},
							textCoords = {
								type = "group",
								guiInline=true,
								name = L["Custom Coords Configuration"],
								desc = L["Setup custom Text Coords for your texture."],
								get = function(info) return tostring(panelData.absolute_bg[info.arg]) end,
								set = function(info,val)
									if val then
										local y = tonumber(val)
										if y then
											panelData.absolute_bg[info.arg] = y
										end
									end
									local frame = kgPanels:FetchFrame(panelName)
									if frame then
										kgPanels:ResetTextures(frame,panelData,panelName)
									end
								end,
								disabled = function() return not panelData.use_absolute_bg end,
								args = {
									ULx = {
										type = "input",
										name = L["ULx"],
										width = "half",
										arg="ULx",
										usage="0.001",
										order=1,
									},
									ULy = {
										type = "input",
										name = L["ULy"],
										width = "half",
										arg="ULy",
										usage="0.001",
										order=2,
									},
									LLx = {
										type = "input",
										name = L["LLx"],
										width = "half",
										arg="LLx",
										usage="0.001",
										order=3,
									},
									LLy = {
										type = "input",
										name = L["LLy"],
										width = "half",
										arg="LLy",
										usage="0.001",
										order=4,
									},
									URx = {
										type = "input",
										name = L["URx"],
										width = "half",
										arg="URx",
										usage="0.001",
										order=5,
									},
									URy = {
										type = "input",
										name = L["URy"],
										width = "half",
										arg="URy",
										usage="0.001",
										order=6,
									},
									LRx = {
										type = "input",
										name = L["LRx"],
										width = "half",
										arg="LRx",
										usage="0.001",
										order=7,
									},
									LRy = {
										type = "input",
										name = L["LRy"],
										width = "half",
										arg="LRy",
										usage="0.001",
										order=8,
									},
								}
							}
						},
					},
					backgroundInsetSize =
					{
						type = "group",
						guiInline = true,
						name = L["Background Insets"],
						desc = L["Inset Options"],
						get = function(info)
							return tostring(panelData.bg_insets[info.arg])
						end,
						set = function(info,val)
							panelData.bg_insets[info.arg] = val
							local frame = kgPanels:FetchFrame(panelName)
							if frame then
								kgPanels:ResetTextures(frame,panelData, name)
							end
						end,
						args = {
							left = {
								type = 'input',
								name = L["Top"],
								desc = L["Top background inset."],
								width = "half",
								usage='10.0',
								--pattern = "%d+%.?%d*%%?",
								order = 1,
								arg = "t"
							},
							right = {
								type = 'input',
								name = L["Left"],
								desc = L["Left background inset."],
								width = "half",
								usage='10.0',
								--pattern = "%d+%.?%d*%%?",
								order = 2,
								arg = "l"
							},
							top = {
								type = 'input',
								name = L["Bottom"],
								desc = L["Bottom background inset."],
								order = 3,
								usage='10.0',
								--pattern = "%d+%.?%d*%%?",
								width = "half",
								arg = "b"
							},
							bottom = {
								type = 'input',
								name = L["Right"],
								desc = L["Right background inset."],
								width = "half",
								usage='10.0',
								--pattern = "%d+%.?%d*%%?",
								order = 4,
								arg = "r"
							},
						},
					},
					border = {
						type = "group",
						name = L["Border Texture"],
						guiInline = true,
						order = 2,
						args = {
							textureName = {
								type = 'select',
								dialogControl = "LSM30_Border",
								name = L["Name"],
								desc = L["Border artwork."],
								values = borderArt,
								order = 0,
								arg = "border_texture",
								width = "full",
							},
						},
					},
					borderEdgeSize =
					{
						type = 'range',
						name = L["Border Edge Size"],
						desc = L["Border edge size, see the FAQ."],
						width = "full",
						min = 0,
						max = 100,
						step = 1,
						order = 3,
						arg = "border_edgeSize",
					},
					borderCustom = {
						type = "group",
						name = L["Advanced Texture Options"],
						order = 5,
						get = function(info) return panelData.border_advanced.show[info.arg] end,
						set = function(info,val)
							panelData.border_advanced.show[info.arg] = val
							local frame = kgPanels:FetchFrame(panelName)
							if frame then
								kgPanels:ResetTextures(frame,panelData,panelName)
							end
						end,
						args = {
							enable = {
								type = "group",
								name = L["Enable Advanced Border Functions"],
								desc = L["Enable Advanced Border Features"],
								guiInline = true,
								order = 1,
								get = function(info) return panelData.border_advanced.enable end,
								set = function(info,val)
									panelData.border_advanced.enable = val
									local frame = kgPanels:FetchFrame(panelName)
									if frame then
										kgPanels:ResetTextures(frame,panelData,panelName)
									end
								end,
								args = {
									button = {
										type = "toggle",
										name = L["Enable"],
									}
								}
							},
							top = {
								type = "toggle",
								name = L["Top"],
								desc = L["Hide or Show the Top border."],
								arg = "TOP",
								order = 2,
								disabled = function() return not panelData.border_advanced.enable end,
							},
							bot = {
								type = "toggle",
								name = L["Bottom"],
								order = 3,
								desc = L["Hide or Show the Bottom border."],
								arg = "BOT",
								disabled = function() return not panelData.border_advanced.enable end,
							},
							left = {
								type = "toggle",
								name = L["Left"],
								desc = L["Hide or Show the Left border."],
								arg = "LEFT",
								disabled = function() return not panelData.border_advanced.enable end,
								order = 4,
							},
							right = {
								type = "toggle",
								name = L["Right"],
								desc = L["Hide or Show the Right border."],
								arg = "RIGHT",
								disabled = function() return not panelData.border_advanced.enable end,
								order = 5,
							},
							topleft = {
								type = "toggle",
								name = L["Top Left Corner"],
								desc = L["Hide or Show the Top Left Corner."],
								arg = "TOPLEFTCORNER",
								order = 6,
								disabled = function() return not panelData.border_advanced.enable end,
							},
							topright = {
								type = "toggle",
								name = L["Top Right Corner"],
								desc = L["Hide or Show the Top Right Corner."],
								arg = "TOPRIGHTCORNER",
								order = 7,
								disabled = function() return not panelData.border_advanced.enable end,
							},
							botleft = {
								type = "toggle",
								name = L["Bottom Left Corner"],
								desc = L["Hide or Show the Bottom Left Corner."],
								arg = "BOTLEFTCORNER",
								order = 8,
								disabled = function() return not panelData.border_advanced.enable end,
							},
							botright = {
								type = "toggle",
								name = L["Bottom Right Corner"],
								desc = L["Hide or Show the Bottom Right Corner."],
								arg = "BOTRIGHTCORNER",
								order = 9,
								disabled = function() return not panelData.border_advanced.enable end,
							},
						}
					}
				},
			},

			textOptions = {
				type = "group",
				name = L["Text Options"],
				childGroups = "tree",
				order = 7,
				args = {
					generalOpts = {
						type = "group",
						name = L["General Text Settings"],
						guiInline = true,
						order = 0,
						args = {
							text = {
								type = "input",
								name = L["Text"],
								desc = L["What you would like to appear on the panel."],
								width = "full",
								order = 0,
								get = function() return panelData.text.text end,
								set = function(app,val) panelData.text.text = val; kgPanels:ResetFont(panelName,panelData.text) end
							},
							color = {
								type = "color",
								name = L["Font Color"],
								desc = L["Color for the text."],
								order = 10,
								get = function() return panelData.text.color.r, panelData.text.color.g, panelData.text.color.b, panelData.text.color.a end,
								set = function(app,r,g,b,a)
									panelData.text.color.r = r
									panelData.text.color.g = g
									panelData.text.color.b = b
									panelData.text.color.a = a
									kgPanels:ResetFont(panelName,panelData.text)
								end
							},
							size = {
								type = "range",
								name = L["Font Size"],
								desc = L["Size of the text in points."],
								order = 20,
								min = 6,
								max = 30,
								step = 1,
								get = function() return panelData.text.size end,
								set = function(app,val) panelData.text.size = val; kgPanels:ResetFont(panelName,panelData.text) end
							},
							font = {
								type = "select",
								name = L["Font"],
								desc = L["Font to use for this panel."],
								values = fontList,
								dialogControl = 'LSM30_Font',
								disabled = function() return SharedMedia == nil end,
								order = 40,
								get = function()
									if strlen(panelData.text.font) < 1 then
										return L["Blizzard"]
									else
										return panelData.text.font
									end
								end,
								set = function(app, key) panelData.text.font = key; kgPanels:ResetFont(panelName,panelData.text); kgPanels:Print("Font is "..key) end
							},
						},
					},
					space = {
						type = "description",
						name = " ",
						order = 1,
					},
					positionOpts = {
						type = "group",
						name = L["Text Positioning"],
						guiInline = true,
						order = 2,
						args = {
							xOffset = {
								type = "input",
								name = L["X Offset"],
								desc = L["X offset from center. NOTE: positive for up, negative for down."],
								order = 50,
								usage='10',
								--pattern = "%d+",
								get = function() return tostring(panelData.text.x) end,
								set = function(app,val) panelData.text.x = val; kgPanels:ResetFont(panelName,panelData.text) end
							},
							yOffset = {
								type = "input",
								name = L["Y Offset"],
								desc = L["Y offset. NOTE: positive for right, negative for left."],
								order = 60,
								usage='10',
								--pattern = "%d+",
								get = function() return tostring(panelData.text.y) end,
								set = function(app,val) panelData.text.y = val; kgPanels:ResetFont(panelName,panelData.text) end
							},
							--[[ disabling justifications since i can get them to work with offsets
							horizontalJustify = {
								type = "select",
								name = L["Horizontal Justification"],
								desc = L["Justification of the text."],
								values = horz_just,
								order = 70,
								get = function() return panelData.text.justifyH end,
								set = function(app,key,val )
									panelData.text.justifyH = key; kgPanels:ResetFont(panelName,panelData.text)
								end
							},
							verticalJustify = {
								type = "select",
								name = L["Vertical Justification"],
								desc = L["Justification of the text."],
								values = vert_just,
								order = 80,
								get = function() return panelData.text.justifyV end,
								set = function(info,key,val) panelData.text.justifyV = key; kgPanels:ResetFont(panelName,panelData.text) end
							},
							]]
						},
					},
				},
			},
			-- scripting complete
			scriptOptions = {
				type = "group",
				name = L["Scripts"],
				childGroups = "tree",
				order = 8,
				get = function(k) return panelData.scripts[k.arg] end,
				set = function(k,val) panelData.scripts[k.arg] = val;
					local frame = kgPanels:FetchFrame(panelName)
					if frame then
						kgPanels:SetupScript(frame,k.arg,val,panelName)
					end
				end,
				args = {
					deps = {
						type = "group",
						order = 1,
						--guiInline = true,
						name = L["Scripts Dependency"],
						args = {
							dep_ins = {
								type = "input",
								name = L["Addon Name"],
								order = 1,
								set = function(k,val)
									kgPanels.db.global.layout_deps[self.activeLayout][panelName] = val
								end,
								get = function()
									return kgPanels.db.global.layout_deps[self.activeLayout][panelName]
								end,
								width = "full",
								usage = L["Addon this Panels script depends."]
							}
						}
					},
					onEvent = {
						type = "group",
						name = L["OnEvent"],
						childGroups = "tree",
						order = 10,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnEvent callback."],
								order = 1,
							},

							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "EVENT",
							},
						},
					},

					onUpdate = {
						type = "group",
						name = L["OnUpdate"],
						childGroups = "tree",
						order = 20,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnUpdate callback."],
								order = 1,
							},

							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "UPDATE",
							},
						},
					},

					OnShow = {
						type = "group",
						name = L["OnShow"],
						childGroups = "tree",
						order = 30,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnShow callback."],
								order = 1,
							},

							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "SHOW",
							},
						},
					},

					OnHide = {
						type = "group",
						name = L["OnHide"],
						childGroups = "tree",
						order = 40,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnHide callback."],
								order = 1,
							},

							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "HIDE",
							},
						},
					},

					OnEnter = {
						type = "group",
						name = L["OnEnter"],
						childGroups = "tree",
						order = 50,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnEnter callback."],
								order = 1,
							},

							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "ENTER",
							},
						},
					},
					OnLeave = {
						type = "group",
						name = L["OnLeave"],
						childGroups = "tree",
						order = 60,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnLeave callback."],
								order = 1,
							},

							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "LEAVE",
							},
						},
					},
					OnClick = {
						type = "group",
						name = L["OnClick"],
						childGroups = "tree",
						order = 70,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnClick callback."],
								order = 1,
							},
							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "CLICK"
							},
						},
					},
					OnResize = {
						type = "group",
						name = L["OnSizeChanged"],
						childGroups = "tree",
						order = 70,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnSizechanged callback."],
								order = 1,
							},
							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "RESIZE"
							},
						},
					},
					OnDrop = {
						type = "group",
						name = L["OnReceiveDrag"],
						childGroups = "tree",
						order = 70,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnReceiveDrag callback."],
								order = 1,
							},
							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "DROP"
							},
						},
					},


					OnLoad = {
						type = "group",
						name = L["OnLoad"],
						childGroups = "tree",
						order = 9,
						args = {
							desc = {
								type = "description",
								name = L["Enter the script for OnLoad callback."],
								order = 1,
							},
							code = {
								type = "input",
								name = "",
								multiline = 24,
								width = "full",
								order = 2,
								arg = "LOAD"
							},
						},
					},
				},
			},
		},
	}
	if isDefault then
		-- redo this for better look
		self.defaultOptions.args.Default = {}
		self.defaultOptions.args.Default.args = tempPanelMenu.args
		self.defaultOptions.args.Default.type = tempPanelMenu.type
		self.defaultOptions.args.Default.name = tempPanelMenu.name
		self.defaultOptions.args.Default.desc = tempPanelMenu.desc
		self.defaultOptions.args.Default.get = tempPanelMenu.get

	else
		local parent = parentArgsTable or self.panelList
		parent[self:makeKey(panelName)] = tempPanelMenu
	end
end
