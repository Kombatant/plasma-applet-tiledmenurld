import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons as KCoreAddons

import "lib"

PlasmoidItem {
	id: widget
	property string systemTerminalApp: ""
	property string systemFileManagerApp: ""
	property bool suppressHideOnWindowDeactivate: false
	readonly property url userAvatarSource: avatarResolver.avatarSource
	readonly property bool hasUserAvatar: ("" + userAvatarSource)

	function refreshAvatar() {
		avatarResolver.refresh()
	}

	function openCustomAvatarDialog() {
		if (customAvatarDialogLoader.active) {
			customAvatarDialogLoader.active = false
		}
		customAvatarDialogLoader.active = true
	}

	// Use Plasma's standard popup background so compositor/window-rule opacity
	// is applied to the same shell treatment as other Plasma dialogs.
	Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

	function resolveTerminalLauncher() {
		if (systemTerminalApp) {
			return systemTerminalApp
		}
		return plasmoid.configuration.terminalApp
	}

	function resolveFileManagerLauncher() {
		if (systemFileManagerApp) {
			return systemFileManagerApp
		}
		return plasmoid.configuration.fileManagerApp
	}

	Logger {
		id: logger
		name: 'tiledmenu'
		showDebug: false
	}

	SearchModel {
		id: search
		Component.onCompleted: {
			search.applyDefaultFilters()
		}
	}

	AiChatModel {
		id: aiChatService
	}

	property alias rootModel: appsModel.rootModel
	AppsModel {
		id: appsModel
	}

	Item {
		// https://invent.kde.org/frameworks/kcoreaddons/-/blob/master/src/qml/kuserproxy.h
		// https://invent.kde.org/frameworks/kcoreaddons/-/blob/master/src/qml/kuserproxy.cpp
		KCoreAddons.KUser {
			id: kuser
		}

		QtObject {
			id: avatarResolver
			property string avatarPath: ""
			readonly property url avatarSource: avatarPath ? _fileUrl(avatarPath) : ""
			Component.onCompleted: refresh()

			function _localPathFromUrl(value) {
				if (!value) {
					return ""
				}
				if (value.indexOf("file://") === 0) {
					return decodeURIComponent(value.slice(7))
				}
				if (value.indexOf("/") === 0) {
					return value
				}
				return ""
			}

			function _fileUrl(path) {
				var encodedPath = encodeURI(path).replace(/#/g, "%23")
				return "file://" + encodedPath
			}

			function _preferredPath() {
				var customAvatarPath = _localPathFromUrl("" + plasmoid.configuration.customAvatarPath)
				if (customAvatarPath) {
					return customAvatarPath
				}
				if (kuser.loginName) {
					return "/var/lib/AccountsService/icons/" + kuser.loginName
				}
				var faceIconPath = _localPathFromUrl("" + kuser.faceIconUrl)
				if (faceIconPath) {
					return faceIconPath
				}
				if (kuser.homeDir) {
					return kuser.homeDir + "/.face.icon"
				}
				return ""
			}

			function refresh() {
				var nextPath = _preferredPath()
				if (avatarPath === nextPath) {
					avatarPath = ""
					Qt.callLater(function() {
						avatarPath = nextPath
					})
					return
				}
				avatarPath = nextPath
			}
		}

		Connections {
			target: plasmoid.configuration
			function onCustomAvatarPathChanged() {
				avatarResolver.refresh()
			}
		}

		Connections {
			target: kuser
			function onFaceIconUrlChanged() {
				avatarResolver.refresh()
			}
			function onHomeDirChanged() {
				avatarResolver.refresh()
			}
			function onLoginNameChanged() {
				avatarResolver.refresh()
			}
		}

		Kicker.DragHelper {
			id: dragHelper

			dragIconSize: Kirigami.Units.iconSizes.medium
		}

		Kicker.ProcessRunner {
			id: processRunner
			// .runMenuEditor() to run kmenuedit
		}
	}

	Plasma5Support.DataSource {
		id: systemDefaultsExec
		engine: "executable"
		connectedSources: []
		function readTerminalService() {
			connectSource("kreadconfig6 --file kdeglobals --group General --key TerminalService")
		}
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var out = data && data.stdout ? ("" + data.stdout).trim() : ""
			if (out) {
				widget.systemTerminalApp = out
			}
		}
	}

	Plasma5Support.DataSource {
		id: systemFileManagerExec
		engine: "executable"
		connectedSources: []
		function readFileManagerService() {
			connectSource("kreadconfig6 --file kdeglobals --group General --key FileManagerService")
			connectSource("kreadconfig6 --file kdeglobals --group General --key FileManager")
		}
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var out = data && data.stdout ? ("" + data.stdout).trim() : ""
			if (!out) {
				return
			}
			var isService = sourceName.indexOf("FileManagerService") >= 0
			if (isService || !widget.systemFileManagerApp) {
				widget.systemFileManagerApp = out
			}
		}
	}

	AppletConfig {
		id: config
	}

	toolTipMainText: ""
	toolTipSubText: ""

	Loader {
		id: customAvatarDialogLoader
		active: false
		sourceComponent: QtDialogs.FileDialog {
			id: customAvatarDialog
			visible: false
			modality: Qt.WindowModal
			title: i18n("Choose a custom avatar")
			onAccepted: {
				plasmoid.configuration.customAvatarPath = "" + selectedFile
				widget.refreshAvatar()
				customAvatarDialogLoader.active = false
			}
			onRejected: {
				customAvatarDialogLoader.active = false
			}
			Component.onCompleted: {
				nameFilters = [i18n("Image Files (*.png *.apng *.gif *.webp *.jpg *.jpeg *.bmp *.svg *.svgz)")]
				open()
			}
		}
	}

	compactRepresentation: LauncherIcon {
		id: panelItem
		iconSource: plasmoid.configuration.icon || "tiled_rld"
	}

	hideOnWindowDeactivate: !widget.userConfiguring && !widget.suppressHideOnWindowDeactivate
	activationTogglesExpanded: true
	onExpandedChanged: function(expanded) {
		if (expanded) {
			avatarResolver.refresh()
			search.query = ""
			search.applyDefaultFilters()
			fullRepresentationItem.searchView.showDefaultView()
			fullRepresentationItem.searchView.focusPrimaryInput()

			// Show icon active effect without hovering
			justOpenedTimer.start()
		}
	}
	Timer {
		id: justOpenedTimer
		repeat: false
		interval: 600
	}

	fullRepresentation: Popup {
		id: popup
		aiChatModel: aiChatService

		Layout.minimumWidth: config.minimumPopupWidth
		Layout.minimumHeight: config.minimumHeight
		Layout.preferredWidth: config.popupWidth
		Layout.preferredHeight: config.popupHeight

		// Make popup resizeable like default Kickoff widget.
		// The FullRepresentation must have an appletInterface property.
		// https://invent.kde.org/plasma/plasma-desktop/-/commit/23c4e82cdcb6c7f251c27c6eefa643415c8c5927
		// https://invent.kde.org/frameworks/plasma-framework/-/merge_requests/500/diffs
		readonly property var appletInterface: Plasmoid.self

		Timer {
			id: resizeToFit
			interval: attemptsLeft == attempts ? 200 : 100
			repeat: attemptsLeft > 0
			property int attempts: 10
			property int attemptsLeft: 10

			function run() {
				restart()
				attemptsLeft = attempts
			}

			onTriggered: {
				var favWidth = Math.max(0, widget.width - config.popupLeftSectionWidth)
				var cols = Math.floor(favWidth / config.cellBoxSize)
				if (plasmoid.configuration.favGridCols != cols) {
					plasmoid.configuration.favGridCols = cols
				}
				config.popupWidthChanged()
				widget.Layout.preferredWidthChanged()
				attemptsLeft -= 1
			}
		}
		onFocusChanged: {
			if (focus) {
				popup.searchView.focusPrimaryInput()
			}
		}
	}

	Plasmoid.contextualActions: [
		PlasmaCore.Action {
			text: i18n("System Info")
			icon.name: "hwinfo"
			onTriggered: appsModel.launch('org.kde.kinfocenter')
		},
		PlasmaCore.Action {
			text: i18n("Terminal")
			icon.name: "utilities-terminal"
			onTriggered: appsModel.launch(widget.resolveTerminalLauncher())
		},
		PlasmaCore.Action {
			isSeparator: true
		},
		PlasmaCore.Action {
			text: i18n("Task Manager")
			icon.name: "utilities-system-monitor"
			onTriggered: appsModel.launch(plasmoid.configuration.taskManagerApp)
		},
		PlasmaCore.Action {
			text: i18n("System Settings")
			icon.name: "systemsettings"
			onTriggered: appsModel.launch('systemsettings')
		},
		PlasmaCore.Action {
			text: i18n("File Manager")
			icon.name: "folder"
			onTriggered: appsModel.launch(widget.resolveFileManagerLauncher())
		},
		PlasmaCore.Action {
			isSeparator: true
		},
		PlasmaCore.Action {
			text: i18n("Edit Applications...")
			icon.name: "kmenuedit"
			onTriggered: processRunner.runMenuEditor()
		}
	]

	Component.onCompleted: {
		systemDefaultsExec.readTerminalService()
		systemFileManagerExec.readFileManagerService()
	}
}
