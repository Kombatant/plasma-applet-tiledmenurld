import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.ksvg as KSvg
import org.kde.coreaddons as KCoreAddons
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu
import "../libconfig" as LibConfig

LibConfig.FormKCM {
	id: formLayout

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow Current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}

	// Keyboard shortcuts are handled by the main settings shell.

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	Kicker.RootModel {
		id: appAutocompleteRootModel
		appletInterface: (typeof plasmoid !== "undefined" && plasmoid) ? plasmoid : formLayout
		flat: true
		showSeparators: false
		showAllApps: true
		showRecentApps: false
		showRecentDocs: false
		autoPopulate: false

		Component.onCompleted: {
			appAutocompleteRefreshTimer.restart()
		}

		onCountChanged: {
			appAutocompleteDebounce.restart()
		}

		onRefreshed: {
			appAutocompleteDebounce.restart()
		}
	}

	Timer {
		id: appAutocompleteRefreshTimer
		interval: 0
		repeat: false
		onTriggered: appAutocompleteRootModel.refresh()
	}

	Timer {
		id: appAutocompleteDebounce
		interval: 50
		repeat: false
		onTriggered: installedAppsModel.refresh()
	}

	TiledMenu.KickerListModel {
		id: installedAppsModel

		function refresh() {
			refreshing()
			var appList = []
			var sourceModel = appAutocompleteRootModel.count > 0 ? appAutocompleteRootModel.modelForRow(0) : null
			if (sourceModel) {
				parseModel(appList, sourceModel)
			}
			appList = appList.filter(function(item) {
				return item && item.name
			}).sort(function(a, b) {
				return ("" + a.name).toLowerCase().localeCompare(("" + b.name).toLowerCase())
			})
			list = appList
			refreshed()
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Sidebar")
	}

	LibConfig.ComboBox {
		id: sidebarPositionControl
		configKey: "sidebarPosition"
		Kirigami.FormData.label: i18n("Position")
		model: [
			{ value: "left", text: i18n("Left") },
			{ value: "top", text: i18n("Top") },
			{ value: "bottom", text: i18n("Bottom") },
		]
	}

	LibConfig.SpinBox {
		id: sidebarButtonSize
		configKey: 'sidebarButtonSize'
		Kirigami.FormData.label: plasmoid.configuration.sidebarPosition === 'left' ? i18n("Width") : i18n("Height")
		suffix: i18n("px")
		minimumValue: 24
		stepSize: 2
	}

	LibConfig.SpinBox {
		id: sidebarIconSize
		configKey: 'sidebarIconSize'
		Kirigami.FormData.label: i18n("Icon Size")
		suffix: i18n("px")
		minimumValue: 16
		maximumValue: sidebarButtonSize.configValue
		stepSize: 2
	}

	LibConfig.RadioButtonGroup {
		id: sidebarThemeGroup
		spacing: 0
		Kirigami.FormData.label: i18n("Theme")

		QQC2.RadioButton {
			text: plasmaStyleLabelText
			QQC2.ButtonGroup.group: sidebarThemeGroup.group
			checked: plasmoid.configuration.sidebarFollowsTheme
			onClicked: plasmoid.configuration.sidebarFollowsTheme = true
		}
		RowLayout {
			QQC2.RadioButton {
				text: i18n("Custom Colour")
				QQC2.ButtonGroup.group: sidebarThemeGroup.group
				checked: !plasmoid.configuration.sidebarFollowsTheme
				onClicked: plasmoid.configuration.sidebarFollowsTheme = false
			}
			LibConfig.ColorField {
				configKey: 'sidebarBackgroundColor'
			}
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Sidebar Shortcuts")
	}

	ColumnLayout {
		Layout.fillWidth: true

		LibConfig.ListBoxStringList {
			id: sidebarShortcuts
			configKey: 'sidebarShortcuts'
			Layout.fillWidth: true
			Layout.fillHeight: true
			implicitWidth: 0

			KCoreAddons.KUser {
				id: kuser
			}

			function startsWith(a, b) {
				return a.substr(0, b.length) === b
			}

			function transformInput(value) {
				var url = ("" + value).trim()
				if (startsWith(url, '~/') && kuser.loginName) {
					url = '/home/' + kuser.loginName + url.substr(1)
				}
				if (startsWith(url, '/')) {
					url = 'file://' + url
				}
				return url
			}

			function endsWith(a, b) {
				return a.indexOf(b, a.length - b.length) !== -1
			}

			function desktopEntryIdFromUrl(url) {
				var value = ("" + (url || "")).trim()
				if (!value.length) {
					return ""
				}
				var queryIndex = value.indexOf("?")
				if (queryIndex >= 0) {
					value = value.substring(0, queryIndex)
				}
				var fragmentIndex = value.indexOf("#")
				if (fragmentIndex >= 0) {
					value = value.substring(0, fragmentIndex)
				}
				var lastSlash = Math.max(value.lastIndexOf("/"), value.lastIndexOf(":"))
				var entryId = lastSlash >= 0 ? value.substring(lastSlash + 1) : value
				return endsWith(entryId, ".desktop") ? entryId : ""
			}

			function desktopEntryIdForApp(app) {
				if (!app) {
					return ""
				}
				if (app.favoriteId && endsWith(app.favoriteId, ".desktop")) {
					return app.favoriteId
				}
				return desktopEntryIdFromUrl(app.url)
			}

			function findInstalledAppByDesktopEntry(shortcut) {
				var target = ("" + shortcut).trim()
				if (!target.length) {
					return null
				}
				for (var i = 0; i < installedAppsModel.count; i++) {
					var app = installedAppsModel.get(i)
					if (desktopEntryIdForApp(app) === target) {
						return app
					}
				}
				return null
			}

			function supportedShortcutSuggestions() {
				return [{
					value: "xdg:DOCUMENTS",
					label: i18nd("xdg-user-dirs", "Documents"),
					description: "xdg:DOCUMENTS"
				}, {
					value: "xdg:DOWNLOAD",
					label: i18nd("xdg-user-dirs", "Download"),
					description: "xdg:DOWNLOAD"
				}, {
					value: "xdg:MUSIC",
					label: i18nd("xdg-user-dirs", "Music"),
					description: "xdg:MUSIC"
				}, {
					value: "xdg:PICTURES",
					label: i18nd("xdg-user-dirs", "Pictures"),
					description: "xdg:PICTURES"
				}, {
					value: "xdg:VIDEOS",
					label: i18nd("xdg-user-dirs", "Videos"),
					description: "xdg:VIDEOS"
				}]
			}

			function sidebarSuggestionScore(candidate, query) {
				var lowerQuery = query.toLowerCase()
				var fields = [candidate.label || "", candidate.value || "", candidate.description || ""]
				var bestScore = -1
				for (var i = 0; i < fields.length; i++) {
					var field = ("" + fields[i]).toLowerCase()
					var index = field.indexOf(lowerQuery)
					if (index < 0) {
						continue
					}
					var score = 1000 - index - field.length
					if (index === 0) {
						score += 250
					}
					if (i === 0) {
						score += 200
					} else if (i === 1) {
						score += 100
					}
					if (score > bestScore) {
						bestScore = score
					}
				}
				return bestScore
			}

			function suggestionItemsForInput(value) {
				var query = ("" + value).trim()
				if (!query.length) {
					return []
				}

				var results = []
				var seen = {}
				var configured = {}
				var entries = plasmoid.configuration.sidebarShortcuts || []
				for (var i = 0; i < entries.length; i++) {
					configured[("" + entries[i]).trim()] = true
				}

				var shortcuts = supportedShortcutSuggestions()
				for (var j = 0; j < shortcuts.length; j++) {
					var shortcut = shortcuts[j]
					var shortcutValue = shortcut.value
					if (configured[shortcutValue] && shortcutValue !== inputText.trim()) {
						continue
					}
					var shortcutScore = sidebarSuggestionScore(shortcut, query)
					if (shortcutScore >= 0) {
						shortcut.score = shortcutScore + 50
						results.push(shortcut)
						seen[shortcutValue] = true
					}
				}

				for (var k = 0; k < installedAppsModel.count; k++) {
					var app = installedAppsModel.get(k)
					var desktopEntryId = desktopEntryIdForApp(app)
					if (!desktopEntryId.length || seen[desktopEntryId]) {
						continue
					}
					if (configured[desktopEntryId] && desktopEntryId !== inputText.trim()) {
						continue
					}
					var candidate = {
						value: desktopEntryId,
						label: app.name || desktopEntryId,
						description: app.description || desktopEntryId
					}
					var appScore = sidebarSuggestionScore(candidate, query)
					if (appScore < 0) {
						continue
					}
					candidate.score = appScore
					results.push(candidate)
					seen[desktopEntryId] = true
				}

				results.sort(function(a, b) {
					if (a.score !== b.score) {
						return b.score - a.score
					}
					return (a.label || "").toLowerCase().localeCompare((b.label || "").toLowerCase())
				})

				return results.slice(0, 10)
			}

			function validateInput(value) {
				var shortcut = ("" + value).trim()
				if (!shortcut.length) {
					return {
						valid: false,
						message: i18n("Shortcut cannot be empty.")
					}
				}
				if (startsWith(shortcut, 'xdg:')) {
					var xdgName = shortcut.substring('xdg:'.length, shortcut.length)
					var supported = ['DOCUMENTS', 'DOWNLOAD', 'MUSIC', 'PICTURES', 'VIDEOS']
					if (supported.indexOf(xdgName) >= 0) {
						return { valid: true, message: "" }
					}
					return {
						valid: false,
						message: i18n("Unsupported XDG shortcut. Use DOCUMENTS, DOWNLOAD, MUSIC, PICTURES, or VIDEOS.")
					}
				}
				if (startsWith(shortcut, 'file:///') || startsWith(shortcut, '/') || startsWith(shortcut, '~/')) {
					return { valid: true, message: "" }
				}
				if (endsWith(shortcut, '.desktop')) {
					var app = findInstalledAppByDesktopEntry(shortcut)
					if (app) {
						return { valid: true, message: "" }
					}
					return {
						valid: false,
						message: i18n("Desktop launcher not found.")
					}
				}
				return {
					valid: false,
					message: i18n("Use an installed .desktop launcher, an xdg: shortcut, or a filesystem path.")
				}
			}

			function addUrl(str) {
				toggleItem(str)
			}
		}

		ColumnLayout {
			id: sidebarDefaultsColumn
			Layout.fillWidth: true

			QQC2.Frame {
				Layout.fillWidth: true

				contentItem: ColumnLayout {
					spacing: Kirigami.Units.smallSpacing

					Kirigami.Heading {
						text: i18n("Shortcut Presets")
						level: 4
					}

					QQC2.Label {
						Layout.fillWidth: true
						text: i18n("Add common folders and apps to the sidebar.")
						wrapMode: Text.WordWrap
						opacity: 0.8
					}

					Flow {
						Layout.fillWidth: true
						spacing: Kirigami.Units.smallSpacing

						QQC2.ToolButton {
							icon.name: "folder-documents-symbolic"
							checkable: true
							checked: sidebarShortcuts.hasItem('xdg:DOCUMENTS')
							text: i18nd("xdg-user-dirs", "Documents")
							onClicked: sidebarShortcuts.addUrl('xdg:DOCUMENTS')
						}
						QQC2.ToolButton {
							icon.name: "folder-download-symbolic"
							checkable: true
							checked: sidebarShortcuts.hasItem('xdg:DOWNLOAD')
							text: i18nd("xdg-user-dirs", "Download")
							onClicked: sidebarShortcuts.addUrl('xdg:DOWNLOAD')
						}
						QQC2.ToolButton {
							icon.name: "folder-music-symbolic"
							checkable: true
							checked: sidebarShortcuts.hasItem('xdg:MUSIC')
							text: i18nd("xdg-user-dirs", "Music")
							onClicked: sidebarShortcuts.addUrl('xdg:MUSIC')
						}
						QQC2.ToolButton {
							icon.name: "folder-pictures-symbolic"
							checkable: true
							checked: sidebarShortcuts.hasItem('xdg:PICTURES')
							text: i18nd("xdg-user-dirs", "Pictures")
							onClicked: sidebarShortcuts.addUrl('xdg:PICTURES')
						}
						QQC2.ToolButton {
							icon.name: "folder-videos-symbolic"
							checkable: true
							checked: sidebarShortcuts.hasItem('xdg:VIDEOS')
							text: i18nd("xdg-user-dirs", "Videos")
							onClicked: sidebarShortcuts.addUrl('xdg:VIDEOS')
						}
						QQC2.ToolButton {
							icon.name: "folder-open-symbolic"
							checkable: true
							checked: sidebarShortcuts.hasItem('org.kde.dolphin.desktop')
							text: i18nd("dolphin", "Dolphin")
							onClicked: sidebarShortcuts.addUrl('org.kde.dolphin.desktop')
						}
						QQC2.ToolButton {
							icon.name: "configure"
							checkable: true
							checked: sidebarShortcuts.hasItem('systemsettings.desktop')
							text: i18nd("systemsettings", "System Settings")
							onClicked: sidebarShortcuts.addUrl('systemsettings.desktop')
						}
					}
				}
			}
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
	LibConfig.TextArea{
		configKey: 'terminalApp'
		Kirigami.FormData.label: i18n("Terminal")
	}
	LibConfig.TextArea {
		configKey: 'taskManagerApp'
		Kirigami.FormData.label: i18n("Task Manager")
	}
	LibConfig.TextArea {
		configKey: 'fileManagerApp'
		Kirigami.FormData.label: i18n("File Manager")
	}
}
