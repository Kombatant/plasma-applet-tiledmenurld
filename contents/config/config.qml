import QtQuick
import org.kde.plasma.configuration

ConfigModel {
	// We provide our own Kate-like settings shell.
	// Keep the same sections and functionality internally.
	ConfigCategory {
		name: i18n("Settings")
		icon: "configure"
		source: "config/ConfigMain.qml"
	}
}
