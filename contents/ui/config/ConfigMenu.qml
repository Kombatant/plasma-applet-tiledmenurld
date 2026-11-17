import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
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
	readonly property bool searchFieldHidden: !!(formLayout.cfg_hideSearchField !== undefined ? formLayout.cfg_hideSearchField : plasmoid.configuration.hideSearchField)
	readonly property bool searchOptionsEnabled: !searchFieldHidden
	readonly property bool groupedSearchResultsEnabled: formLayout.searchOptionsEnabled
		&& !!(formLayout.cfg_searchResultsGrouped !== undefined ? formLayout.cfg_searchResultsGrouped : plasmoid.configuration.searchResultsGrouped)
	readonly property string pendingSidebarPosition: formLayout.cfg_sidebarPosition !== undefined ? formLayout.cfg_sidebarPosition : plasmoid.configuration.sidebarPosition
	readonly property bool searchOnTopEnabled: formLayout.searchOptionsEnabled
		&& formLayout.pendingUsesClassicLayout
		&& formLayout.pendingSidebarPosition === 'left'
	readonly property bool searchFieldHeightEnabled: searchOptionsEnabled
		&& formLayout.pendingUsesClassicLayout

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}

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

	tabs: [
		LibConfig.FormTab {
			title: i18n("Layout")

			LibConfig.ComboBox {
				id: layoutModeControl
				configKey: "useDockedLayout"
				Kirigami.FormData.label: i18n("Layout mode:")
				model: [
					{ value: true, text: i18n("Docked Sidebar Layout") },
					{ value: false, text: i18n("Classic Layout") },
				]
			}

			RowLayout {
				Kirigami.FormData.label: i18n("Docked sidebar width:")
				Kirigami.FormData.buddyFor: dockedSidebarWidthControl
				spacing: Kirigami.Units.largeSpacing

				LibConfig.SpinBox {
					id: dockedSidebarWidthControl
					configKey: 'dockedSidebarWidth'
					suffix: i18n("px")
					minimumValue: 0
					enabled: !formLayout.pendingUsesClassicLayout
					opacity: enabled ? 1 : 0.45
				}
				LibConfig.Chip {
					text: i18n("Docked layout only")
				}
			}

			RowLayout {
				Kirigami.FormData.label: i18n("App list width:")
				Kirigami.FormData.buddyFor: appListWidthControl
				spacing: Kirigami.Units.largeSpacing

				LibConfig.SpinBox {
					id: appListWidthControl
					configKey: 'appListWidth'
					suffix: i18n("px")
					minimumValue: 0
					enabled: formLayout.pendingUsesClassicLayout
					opacity: enabled ? 1 : 0.45
				}
				LibConfig.Chip {
					text: i18n("Classic layout only")
				}
			}

			LibConfig.ComboBox {
				id: defaultAppListViewControl
				configKey: "defaultAppListView"
				Kirigami.FormData.label: i18n("Default view:")
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

			LibConfig.CheckBox {
				configKey: 'showPinButton'
				text: i18n("Show a pin button to keep the menu open while launching apps")
			}

			LibConfig.Heading {
				text: i18n("Panel icon")
			}

			LibConfig.IconField {
				Kirigami.FormData.label: i18n("Panel icon:")
				Kirigami.FormData.labelAlignment: Qt.AlignTop
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
					text: i18n("Fixed size")
					configKey: 'fixedPanelIcon'
				}
			}
		},
		LibConfig.FormTab {
			title: i18n("App List")

			LibConfig.SpinBox {
				configKey: 'appListIconSize'
				Kirigami.FormData.label: i18n("App list icon size:")
				suffix: i18n("px")
				minimumValue: 16
				maximumValue: 128
			}

			LibConfig.ComboBox {
				id: appDescriptionControl
				configKey: "appDescription"
				Kirigami.FormData.label: i18n("App description:")
				model: [
					{ value: "hidden", text: i18n("Hidden") },
					{ value: "after", text: i18n("After") },
					{ value: "below", text: i18n("Below") },
				]
			}

			RowLayout {
				Kirigami.FormData.label: i18n("App history:")
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
		},
		LibConfig.FormTab {
			title: i18n("Search")

			LibConfig.CheckBox {
				configKey: 'hideSearchField'
				text: i18n("Hide search field")
				Kirigami.FormData.label: ""
			}

			RowLayout {
				Kirigami.FormData.label: ""
				spacing: Kirigami.Units.largeSpacing

				LibConfig.CheckBox {
					configKey: 'searchOnTop'
					text: i18n("Search on top")
					enabled: formLayout.searchOnTopEnabled
					opacity: enabled ? 1 : 0.45
				}
				LibConfig.Chip {
					text: i18n("Classic layout, left sidebar only")
				}
			}

			RowLayout {
				Kirigami.FormData.label: i18n("Search field height:")
				Kirigami.FormData.buddyFor: searchFieldHeightControl
				spacing: Kirigami.Units.largeSpacing

				LibConfig.SpinBox {
					id: searchFieldHeightControl
					configKey: 'searchFieldHeight'
					suffix: i18n("px")
					minimumValue: 1
					enabled: formLayout.searchFieldHeightEnabled
					opacity: enabled ? 1 : 0.45
				}
				LibConfig.Chip {
					text: i18n("Classic layout only")
				}
			}

			LibConfig.RadioButtonGroup {
				Kirigami.FormData.label: i18n("Search box theme:")
				enabled: formLayout.searchOptionsEnabled
				opacity: enabled ? 1 : 0.45

				property bool searchFieldFollowsThemeValue: !!plasmoid.configuration.searchFieldFollowsTheme
				function _refreshSearchFieldFollowsTheme() {
					searchFieldFollowsThemeValue = !!(formLayout.cfg_searchFieldFollowsTheme !== undefined ? formLayout.cfg_searchFieldFollowsTheme : plasmoid.configuration.searchFieldFollowsTheme)
				}
				property var _disconnectSearchFieldFollowsTheme: null
				Component.onCompleted: {
					_refreshSearchFieldFollowsTheme()
					_disconnectSearchFieldFollowsTheme = ConfigUtils.connectConfigChange(formLayout, "searchFieldFollowsTheme", _refreshSearchFieldFollowsTheme)
				}
				Component.onDestruction: {
					if (_disconnectSearchFieldFollowsTheme) _disconnectSearchFieldFollowsTheme()
				}

				QQC2.RadioButton {
					text: plasmaStyleLabelText
					checked: parent.searchFieldFollowsThemeValue
					onClicked: ConfigUtils.setPendingValue(formLayout, "searchFieldFollowsTheme", true)
				}
				QQC2.RadioButton {
					text: i18n("Windows (White)")
					checked: !parent.searchFieldFollowsThemeValue
					onClicked: ConfigUtils.setPendingValue(formLayout, "searchFieldFollowsTheme", false)
				}
			}

			Item {
				Kirigami.FormData.isSection: false
				Kirigami.FormData.label: ""
				implicitHeight: Kirigami.Units.gridUnit
			}

			LibConfig.CheckBox {
				configKey: 'searchResultsGrouped'
				text: i18n("Group search results")
				Kirigami.FormData.label: ""
				enabled: formLayout.searchOptionsEnabled
				opacity: enabled ? 1 : 0.45
			}

			Item {
				Kirigami.FormData.isSection: false
				Kirigami.FormData.label: ""
				implicitWidth: collapseSearchResultGroupsRow.implicitWidth
				implicitHeight: collapseSearchResultGroupsRow.implicitHeight
				visible: true
				opacity: formLayout.searchOptionsEnabled ? 1 : 0.45

				RowLayout {
					id: collapseSearchResultGroupsRow
					anchors.left: parent.left
					anchors.right: parent.right
					spacing: 0

					Item {
						Layout.preferredWidth: Kirigami.Units.largeSpacing * 2
					}

					LibConfig.CheckBox {
						configKey: 'sidebarCollapsibleSearchResults'
						text: i18n("Collapse search result groups")
						enabled: formLayout.groupedSearchResultsEnabled
						opacity: enabled ? 1 : 0.45
					}
				}
			}
		}
	]
}
