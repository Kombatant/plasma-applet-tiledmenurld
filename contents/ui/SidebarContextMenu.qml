import QtQuick
import QtQml.Models as QtModels
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.core as PlasmaCore

// https://invent.kde.org/plasma/plasma-framework/-/blame/master/src/declarativeimports/plasmaextracomponents/qmenu.h
PlasmaExtras.Menu {
	id: kickerContextMenu
	required property var model

	function computePlacement() {
		// Align to the sidebar, not the panel edge, per Plasma 6 menu behavior.
		if (typeof config !== "undefined" && config) {
			if (config.sidebarOnLeft) {
				return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
			}
			if (config.sidebarOnTop) {
				return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
			}
			if (config.sidebarOnBottom) {
				return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
			}
		}

		if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
			return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
		} else if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
			return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
		} else if (Plasmoid.location === PlasmaCore.Types.RightEdge) {
			return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
		} else if (Plasmoid.location === PlasmaCore.Types.BottomEdge) {
			return PlasmaExtras.Menu.TopPosedRightAlignedPopup;
		} else {
			return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
		}
	}

	function toggleOpen() {
		if (kickerContextMenu.status == PlasmaExtras.Menu.Open) {
			kickerContextMenu.close()
		} else if (kickerContextMenu.status == PlasmaExtras.Menu.Closed) {
			kickerContextMenu.openRelative()
		}
	}

	// https://invent.kde.org/plasma/plasma-desktop/-/blame/master/applets/kickoff/package/contents/ui/LeaveButtons.qml
	// https://invent.kde.org/plasma/plasma-desktop/-/blame/master/applets/kickoff/package/contents/ui/ActionMenu.qml
	// https://doc.qt.io/qt-6/qml-qtqml-models-instantiator.html
	property Instantiator _instantiator: QtModels.Instantiator {
		model: kickerContextMenu.model
		delegate: PlasmaExtras.MenuItem {
			icon:  model.iconName || model.decoration
			text: model.name || model.display
			visible: !model.disabled
			onClicked: {
				kickerContextMenu.model.triggerIndex(index)
			}
		}
		onObjectAdded: (index, object) => kickerContextMenu.addMenuItem(object)
		onObjectRemoved: (index, object) => kickerContextMenu.removeMenuItem(object)
	}
	placement: computePlacement()

    // No debug logging in production.
}
