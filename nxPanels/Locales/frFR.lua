local L = LibStub("AceLocale-3.0"):NewLocale("nxPanels", "frFR")
if not L then return end

L["LIB_MISSING"] = "La librairie %s est manquante. Réinstallez nxPanels."
L["ENABLED"] = "Panneaux activés."
L["DISABLED"] = "Panneaux désactivés."
L["LAYOUT_ACTIVE"] = "Layout actif : %s"
L["LAYOUT_NONE"] = "Aucun layout actif."
L["LAYOUT_NOT_FOUND"] = "Layout introuvable : %s"
L["LAYOUT_LIST"] = "Layouts :"
L["LAYOUT_LIST_ITEM"] = "%s (%d panneaux)"
L["NO_LAYOUTS"] = "Aucun layout pour l'instant."
L["STATUS"] = "Version %s, client %s. Layout actif : %s. Panneaux affichés : %d, en attente de leur frame : %d."
L["CLIENT_RETAIL"] = "Retail"
L["CLIENT_FOREVER"] = "WoW Forever"
L["CLIENT_OTHER"] = "non pris en charge"
L["OPTIONS_SOON"] = "La fenêtre de configuration arrive à la prochaine étape. En attendant, utilisez /nxp help."
L["MENU_SHOW"] = "Afficher les panneaux"

L["HELP_TITLE"] = "Commandes (/nxpanels ou /nxp) :"
L["HELP_LAYOUTS"] = "layouts : liste vos layouts"
L["HELP_LAYOUT"] = "layout <nom> : active un layout"
L["HELP_TOGGLE"] = "enable / disable : affiche ou masque tous les panneaux"
L["HELP_IMPORT"] = "import : importe à nouveau les données kgPanels (en nouveaux layouts)"
L["HELP_MINIMAP"] = "minimap : affiche ou masque le bouton de la minicarte"
L["HELP_STATUS"] = "status : version et diagnostic"

L["MIGRATED"] = "%d layout(s) et %d panneau(x) importés depuis %s."
L["MIGRATE_NOTHING"] = "Aucune donnée kgPanels à importer."
L["MIGRATE_POPUP"] = "nxPanels a importé vos layouts kgPanels.\n\nL'ancien addon a été désactivé. Recharger l'interface pour terminer ?"
L["RELOAD"] = "Recharger"
L["LATER"] = "Plus tard"

L["SCRIPT_ERROR"] = "Erreur de script dans le panneau |cffffd100%s|r (%s) : %s. Ce script est désactivé jusqu'au prochain rechargement."
L["SCRIPT_COMPILE_ERROR"] = "Le script du panneau |cffffd100%s|r (%s) ne peut pas être compilé : %s"
L["ANCHOR_CYCLE"] = "Panneau |cffffd100%s|r : ancrage circulaire détecté, ancré à l'écran à la place."

L["MINIMAP_TOOLTIP_LEFT"] = "|cffffd100Clic gauche :|r affiche les layouts"
L["MINIMAP_TOOLTIP_RIGHT"] = "|cffffd100Clic droit :|r affiche ou masque les panneaux"
