import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import ".." as TiledMenu
import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils


LibConfig.FormKCM {
	id: formLayout
	wideMode: false

	readonly property bool pendingUsesClassicLayout: !(formLayout.cfg_useDockedLayout !== undefined ? formLayout.cfg_useDockedLayout : plasmoid.configuration.useDockedLayout)

	function normalizeDistroIconToken(token) {
		token = (token || "").toLowerCase().trim()
		if (!token) {
			return ""
		}

		if (token.indexOf("distributor-logo-") === 0) {
			token = token.substring("distributor-logo-".length)
		}

		token = token.replace(/^["']|["']$/g, "")

		var aliases = {
			"arch": "archlinux",
			"arch-linux": "archlinux",
			"opensuse": "opensuse",
			"opensuse-leap": "opensuse",
			"opensuse-microos": "opensuse",
			"opensuse-slowroll": "opensuse",
			"opensuse-tumbleweed": "opensuse",
			"redhat": "rhel",
			"red-hat": "rhel",
			"red-hat-enterprise-linux": "rhel",
			"rhel": "rhel",
			"linuxmint": "linux-mint",
			"linux-mint": "linux-mint",
			"pop": "pop-os",
			"pop-os": "pop-os",
			"pop_os": "pop-os",
			"endeavour": "endeavouros",
			"endeavouros": "endeavouros",
		}

		return aliases[token] || token
	}

	function pushUnique(target, value) {
		if (!value || target.indexOf(value) >= 0) {
			return
		}
		target.push(value)
	}

	function distroIconCandidates() {
		var candidates = []
		var tokens = []

		pushUnique(tokens, KCoreAddons.KOSRelease.id)
		pushUnique(tokens, KCoreAddons.KOSRelease.logo)

		var idLike = KCoreAddons.KOSRelease.idLike || []
		for (var i = 0; i < idLike.length; ++i) {
			pushUnique(tokens, idLike[i])
		}

		for (var j = 0; j < tokens.length; ++j) {
			var normalized = normalizeDistroIconToken(tokens[j])
			if (!normalized) {
				continue
			}
			pushUnique(candidates, "distributor-logo-" + normalized)
			pushUnique(candidates, normalized)
		}

		pushUnique(candidates, "start-here-kde")
		pushUnique(candidates, "start-here")
		return candidates
	}

	readonly property var distroIconCandidateList: distroIconCandidates()
	property string distroPresetIcon: "start-here-kde"
	property bool distroPresetResolved: false

	// Keyboard shortcuts are handled by the main settings shell.

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	Repeater {
		model: formLayout.distroIconCandidateList
		delegate: Kirigami.Icon {
			required property string modelData
			source: modelData
			visible: false
			onValidChanged: {
				if (valid && !formLayout.distroPresetResolved) {
					formLayout.distroPresetIcon = modelData
					formLayout.distroPresetResolved = true
				}
			}
			Component.onCompleted: {
				if (valid && !formLayout.distroPresetResolved) {
					formLayout.distroPresetIcon = modelData
					formLayout.distroPresetResolved = true
				}
			}
		}
	}

	TiledMenu.AppAutocompleteHelper {
		id: appAutocomplete
	}


	//-------------------------------------------------------
	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Panel Icon")
	}

	LibConfig.IconField {
		Layout.fillWidth: true
		configKey: 'icon'
		defaultValue: 'tiled_rld'
		previewIconSize: Kirigami.Units.iconSizes.large
		presetValues: [
			'format-border-set-none-symbolic',
			'applications-all-symbolic',
			'kde-symbolic',
			formLayout.distroPresetIcon,
			'choice-rhomb-symbolic',
			'choice-round-symbolic',
			'stateshape-symbolic',
			'beamerblock-symbolic',
		]
		showPresetLabel: false

		LibConfig.CheckBox {
			text: i18n("Fixed Size")
			configKey: 'fixedPanelIcon'
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Application List")
	}

	LibConfig.SpinBox {
		configKey: 'appListIconSize'
		Kirigami.FormData.label: i18n("Icon Size")
		suffix: i18n("px")
		minimumValue: 16
		maximumValue: 128
	}

	LibConfig.SpinBox {
		id: appListWidthControl
		configKey: 'appListWidth'
		Kirigami.FormData.label: i18n("App List Area Width")
		suffix: i18n("px")
		minimumValue: 0
		visible: formLayout.pendingUsesClassicLayout
	}

	LibConfig.SpinBox {
		configKey: 'dockedSidebarWidth'
		Kirigami.FormData.label: i18n("Docked Sidebar Width")
		suffix: i18n("px")
		minimumValue: 0
		visible: !formLayout.pendingUsesClassicLayout
	}

	LibConfig.ComboBox {
		id: defaultAppListViewControl
		configKey: "defaultAppListView"
		Kirigami.FormData.label: i18n("Default View")
		model: [
			{ value: "Alphabetical", text: i18n("Alphabetical") },
			{ value: "Categories", text: i18n("Categories") },
			{ value: "LastUsedView", text: i18n("Last Used View") },
			{ value: "JumpToLetter", text: i18n("Jump To Letter") },
			{ value: "JumpToCategory", text: i18n("Jump To Category") },
			{ value: "TilesOnly", text: i18n("Tiles Only") },
			{ value: "AiChat", text: i18n("AI Chat") },
		]
	}

	LibConfig.ComboBox {
		id: appDescriptionControl
		configKey: "appDescription"
		Kirigami.FormData.label: i18n("App Description")
		model: [
			{ value: "hidden", text: i18n("Hidden") },
			{ value: "after", text: i18n("After") },
			{ value: "below", text: i18n("Below") },
		]
	}

	RowLayout {
		Kirigami.FormData.label: i18n("App History")
		LibConfig.CheckBox {
			id: showRecentAppsCheckBox
			text: i18n("Show:")
			configKey: 'showRecentApps'
		}
		LibConfig.SpinBox {
			configKey: 'numRecentApps'
			enabled: showRecentAppsCheckBox.checked
			minimumValue: 1
			maximumValue: 15
		}

		LibConfig.ComboBox {
			configKey: 'recentOrdering'
			model: [
				{ value: 0, text: i18n("Recent applications") },
				{ value: 1, text: i18n("Often used applications") },
			]
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Right Click Menu")
	}
	LibConfig.AutocompleteTextField {
		configKey: 'terminalApp'
		Kirigami.FormData.label: i18n("Terminal")
		placeholderText: cfg_terminalAppDefault || "org.kde.konsole.desktop"
		suggestionsProvider: appAutocomplete.suggestionsProvider
	}
	LibConfig.AutocompleteTextField {
		configKey: 'taskManagerApp'
		Kirigami.FormData.label: i18n("Task Manager")
		placeholderText: cfg_taskManagerAppDefault || "org.kde.plasma-systemmonitor.desktop"
		suggestionsProvider: appAutocomplete.suggestionsProvider
	}
	LibConfig.AutocompleteTextField {
		configKey: 'fileManagerApp'
		Kirigami.FormData.label: i18n("File Manager")
		placeholderText: cfg_fileManagerAppDefault || "org.kde.dolphin.desktop"
		suggestionsProvider: appAutocomplete.suggestionsProvider
	}

}
