import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

QQC2.ToolButton {
	id: flatButton

	icon.name: ""
	icon.width: iconSize
	icon.height: iconSize
	property bool expanded: true
	text: ""
	display: expanded ? QQC2.AbstractButton.TextBesideIcon : QQC2.AbstractButton.IconOnly
	property string label: expanded ? text : ""
	property bool labelVisible: text != ""
	property color backgroundColor: config.flatButtonBgColor
	property color backgroundHoverColor: config.flatButtonBgHoverColor
	property color backgroundPressedColor: config.flatButtonBgPressedColor
	property color checkedColor: config.flatButtonCheckedColor
	property bool zoomOnPush: true

	// http://doc.qt.io/qt-5/qt.html#Edge-enum
	property int checkedEdge: 0 // 0 = all edges
	property int checkedEdgeWidth: 2 * Screen.devicePixelRatio

	property int buttonHeight: config.flatButtonSize
	property int iconSize: config.flatButtonIconSize
	readonly property int _iconSize: Math.min(buttonHeight, iconSize)
	implicitHeight: buttonHeight
}
