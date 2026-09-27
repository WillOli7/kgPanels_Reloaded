local L = LibStub("AceLocale-3.0"):NewLocale("nxPanels", "enUS", true)
if not L then return end

L["LIB_MISSING"] = "The library %s is missing. Please reinstall nxPanels."
L["ENABLED"] = "Panels enabled."
L["DISABLED"] = "Panels disabled."
L["LAYOUT_ACTIVE"] = "Active layout: %s"
L["LAYOUT_NONE"] = "No active layout."
L["LAYOUT_NOT_FOUND"] = "Layout not found: %s"
L["LAYOUT_LIST"] = "Layouts:"
L["LAYOUT_LIST_ITEM"] = "%s (%d panels)"
L["NO_LAYOUTS"] = "No layouts yet."
L["STATUS"] = "Version %s, %s client. Active layout: %s. Panels shown: %d, waiting for their frame: %d."
L["CLIENT_RETAIL"] = "Retail"
L["CLIENT_FOREVER"] = "WoW Forever"
L["CLIENT_OTHER"] = "unsupported"
L["OPTIONS_SOON"] = "The configuration window is coming in the next milestone. Meanwhile, use /nxp help."
L["MENU_SHOW"] = "Show the panels"

L["HELP_TITLE"] = "Commands (/nxpanels or /nxp):"
L["HELP_LAYOUTS"] = "layouts: list your layouts"
L["HELP_LAYOUT"] = "layout <name>: activate a layout"
L["HELP_TOGGLE"] = "enable / disable: show or hide all panels"
L["HELP_IMPORT"] = "import: import kgPanels data again (as new layouts)"
L["HELP_MINIMAP"] = "minimap: show or hide the minimap button"
L["HELP_STATUS"] = "status: version and diagnostics"

L["MIGRATED"] = "Imported %d layout(s) and %d panel(s) from %s."
L["MIGRATE_NOTHING"] = "No kgPanels data found to import."
L["MIGRATE_POPUP"] = "nxPanels imported your kgPanels layouts.\n\nThe old addon has been disabled. Reload the interface to finish?"
L["RELOAD"] = "Reload"
L["LATER"] = "Later"

L["SCRIPT_ERROR"] = "Script error in panel |cffffd100%s|r (%s): %s. This script is disabled until the next reload."
L["SCRIPT_COMPILE_ERROR"] = "Script of panel |cffffd100%s|r (%s) could not be compiled: %s"
L["ANCHOR_CYCLE"] = "Panel |cffffd100%s|r: circular anchoring detected, anchored to the screen instead."

L["MINIMAP_TOOLTIP_LEFT"] = "|cffffd100Left-click:|r show the layouts"
L["MINIMAP_TOOLTIP_RIGHT"] = "|cffffd100Right-click:|r show or hide the panels"
