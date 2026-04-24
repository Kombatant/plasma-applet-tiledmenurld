import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

SidebarItem {
	id: control

	implicitWidth: config.flatButtonSize
	property string labelText: ""
	labelVisible: false

	// Use theme-provided icon names to follow the current KDE icon theme.
	property string appletIconName: ""

	// Adjust checked edge based on sidebar orientation. Overridable by parent.
	property int defaultCheckedEdge: config.sidebarHorizontal ? (config.sidebarOnTop ? Qt.BottomEdge : Qt.TopEdge) : Qt.LeftEdge
	property bool checkedPillVisible: false
	property bool checkedUnderlineVisible: false
	checkedEdge: defaultCheckedEdge
	checkedEdgeWidth: 4 * Screen.devicePixelRatio // Twice as thick as normal
	display: QQC2.AbstractButton.IconOnly
	tooltipText: labelText
	implicitHeight: config.flatButtonSize

	contentItem: Item {
		anchors.fill: parent

		Rectangle {
			id: checkedPill
			visible: control.checkedPillVisible
			anchors.centerIn: parent
			width: Math.round(parent.width * 0.72)
			height: Math.round(parent.height * 0.72)
			radius: Math.round(Kirigami.Units.smallSpacing)
			color: Kirigami.Theme.highlightColor
			opacity: control.checked ? 0.24 : (control.hovered ? 0.10 : 0.0)
			Behavior on opacity { NumberAnimation { duration: 120 } }
		}

		Kirigami.Icon {
			id: icon
			source: control.appletIconName
			isMask: true // Force color
			color: control.checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
			property int iconSize: Kirigami.Units.iconSizes.roundedIconSize(config.flatButtonIconSize)
			width: iconSize
			height: iconSize
			anchors.centerIn: parent
		}

		Rectangle {
			id: checkedUnderline
			visible: control.checkedUnderlineVisible && control.checked
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.leftMargin: Math.round(parent.width * 0.22)
			anchors.rightMargin: Math.round(parent.width * 0.22)
			height: Math.max(2, Math.round(2 * Screen.devicePixelRatio))
			radius: height / 2
			color: Kirigami.Theme.highlightColor
		}

		Text {
			id: label
			visible: false
			text: control.labelText
			color: Kirigami.Theme.textColor
			font: Kirigami.Theme.defaultFont
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.WordWrap
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: icon.bottom
			anchors.topMargin: Kirigami.Units.smallSpacing / 2
		}
	}
}
