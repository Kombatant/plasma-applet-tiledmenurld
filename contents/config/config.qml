import QtQuick
import org.kde.plasma.configuration

ConfigModel {
	ConfigCategory {
		name: i18n("General")
		icon: "configure"
		source: "config/ConfigGeneral.qml"
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
		name: i18n("Search")
		icon: "edit-find"
		source: "config/ConfigSearch.qml"
	}
	ConfigCategory {
		name: i18n("AI Chat")
		icon: "dialog-messages"
		source: "config/ConfigAiChat.qml"
	}
	ConfigCategory {
		name: i18n("Import/Export Layout")
		icon: "grid-rectangular"
		source: "config/ConfigExportLayout.qml"
	}
	// Keyboard Shortcuts and About are provided automatically by Plasma.
}
