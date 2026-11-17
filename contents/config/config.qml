import QtQuick
import org.kde.plasma.configuration

// Each category is a hub; most split their settings into in-page tabs
// (see LibConfig.FormTab). Tabs per page:
//   Menu:             Layout | App List | Search
//   Tiles:            Tabs | Size & Spacing | Colours & Effects | Labels & Groups
//   Sidebar:          Shortcuts | Options
//   Theme:            (single form, no tab bar)
//   Services:         AI Chat | Game Metadata | Default Apps
//   Backup & Updates: Import / Export | Updates
ConfigModel {
	ConfigCategory {
		name: i18n("Menu")
		icon: "view-app-grid-symbolic"
		source: "config/ConfigMenu.qml"
	}
	ConfigCategory {
		name: i18n("Tiles")
		icon: "view-grid-symbolic"
		source: "config/ConfigTiles.qml"
	}
	ConfigCategory {
		name: i18n("Sidebar")
		icon: "sidebar-expand-left"
		source: "config/ConfigSidebar.qml"
	}
	ConfigCategory {
		name: i18n("Theme")
		icon: "contrast-symbolic"
		source: "config/ConfigAppearance.qml"
	}
	ConfigCategory {
		name: i18n("Services")
		icon: "plugins-symbolic"
		source: "config/ConfigServices.qml"
	}
	ConfigCategory {
		name: i18n("Backup & Updates")
		icon: "package-symbolic"
		source: "config/ConfigExportLayout.qml"
	}
	// Keyboard Shortcuts and About are provided automatically by Plasma.
}
