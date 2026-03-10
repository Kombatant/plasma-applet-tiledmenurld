import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

MouseArea {
	id: sectionDelegate

	width: ListView.view.width
	implicitHeight: listView.iconSize

	property bool enableJumpToSection: false
	property bool collapsible: false
	property bool collapsed: false
	property var collapseToggler: null
	readonly property bool interactive: enableJumpToSection || collapsible
	cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

	PlasmaComponents3.Label {
		id: sectionHeading
		anchors {
			left: parent.left
			leftMargin: Kirigami.Units.smallSpacing
			verticalCenter:  parent.verticalCenter
		}
		text: {
			if (section == appsModel.recentAppsSectionKey) {
				return appsModel.recentAppsSectionLabel
			} else {
				return section
			}
		}

		// Add 4pt to font. Default 10pt => 14pt
		font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4

		property bool centerOverIcon: sectionHeading.contentWidth <= listView.iconSize
		width: centerOverIcon ? listView.iconSize : parent.width
		horizontalAlignment: centerOverIcon ? Text.AlignHCenter : Text.AlignLeft
	}

	Kirigami.Icon {
		anchors {
			right: parent.right
			rightMargin: Kirigami.Units.smallSpacing
			verticalCenter: parent.verticalCenter
		}
		visible: sectionDelegate.collapsible
		width: Math.max(Kirigami.Units.iconSizes.small, listView.iconSize * 0.5)
		height: width
		source: "usermenu-down"
		rotation: sectionDelegate.collapsed ? -90 : 0

		Behavior on rotation {
			NumberAnimation { duration: Kirigami.Units.shortDuration }
		}
	}

	HoverOutlineEffect {
		id: hoverOutlineEffect
		anchors.fill: parent
		visible: sectionDelegate.interactive && sectionDelegate.containsMouse
		hoverRadius: width/2
		pressedRadius: width
		mouseArea: sectionDelegate
	}

	hoverEnabled: true
	onClicked: {
		if (collapsible && typeof collapseToggler === "function") {
			collapseToggler()
		} else if (enableJumpToSection) {
			if (appsModel.order == "alphabetical") {
				jumpToLetterView.show()
			} else { // appsModel.order = "categories"
				jumpToLetterView.show()
			}
		}
	}
}
