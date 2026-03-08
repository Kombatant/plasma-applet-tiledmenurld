import QtQuick
import QtQuick.Layouts
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

	// Disable the default Plasma dialog background for a cleaner look
	// (blur effect is controlled by KDE Desktop Effects, not by the plasmoid)
	Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

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
			// faceIconUrl is an empty QUrl 'object' when ~/.face.icon doesn't exist.
			// Cast it to string first before checking if it's empty by casting to bool.
			readonly property bool hasFaceIcon: (''+faceIconUrl)
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

	compactRepresentation: LauncherIcon {
		id: panelItem
		iconSource: plasmoid.configuration.icon || "tiled_rld"
	}

	hideOnWindowDeactivate: !widget.userConfiguring
	activationTogglesExpanded: true
	onExpandedChanged: function(expanded) {
		if (expanded) {
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

		Layout.minimumWidth: config.minimumWidth
		Layout.minimumHeight: config.minimumHeight
		Layout.preferredWidth: config.popupWidth
		Layout.preferredHeight: config.popupHeight

		 //Layout.minimumHeight: 900 // For quickly testing as a desktop widget
		// Layout.minimumWidth: 800



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
				var favWidth = Math.max(0, widget.width - config.leftSectionWidth)
			// Compute columns based on tile content width (ignore tile margins so margins don't reduce column count)
			var cols = Math.floor(favWidth / config.cellSize)
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
