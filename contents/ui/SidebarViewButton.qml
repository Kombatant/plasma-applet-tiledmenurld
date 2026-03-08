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

	// Adjust checked edge based on sidebar orientation
	checkedEdge: config.sidebarHorizontal ? (config.sidebarOnTop ? Qt.BottomEdge : Qt.TopEdge) : Qt.LeftEdge
	checkedEdgeWidth: 4 * Screen.devicePixelRatio // Twice as thick as normal
	display: QQC2.AbstractButton.IconOnly
	tooltipText: labelText
	implicitHeight: config.flatButtonSize

	contentItem: Item {
		anchors.fill: parent

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
