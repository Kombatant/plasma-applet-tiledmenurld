import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

FlatButton {
	id: sidebarItem
	// In vertical mode (left sidebar): fill width, fixed height
	// In horizontal mode (top/bottom sidebar): fixed width, fixed height
	Layout.fillWidth: !config.sidebarHorizontal
	Layout.fillHeight: false
	Layout.preferredWidth: config.sidebarHorizontal ? config.flatButtonSize : -1
	Layout.preferredHeight: config.flatButtonSize
	Layout.minimumWidth: expanded ? config.sidebarMinOpenWidth : implicitWidth
	Layout.alignment: config.sidebarHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
	implicitWidth: config.flatButtonSize
	implicitHeight: config.flatButtonSize
	property var sidebarMenu: parent.parent // Column.SidebarMenu
	expanded: sidebarMenu ? sidebarMenu.open : false
	labelVisible: expanded
	property bool closeOnClick: true
	property string tooltipText: ""

	QQC2.ToolTip {
		id: control
		visible: sidebarItem.hovered && !sidebarItem.expanded && !sidebarItem.labelVisible
		text: sidebarItem.tooltipText
		delay: 0
		x: parent.width + rightPadding
		y: (parent.height - height) / 2
	}

	Loader {
		id: hoverOutlineEffectLoader
		anchors.fill: parent
		source: "HoverOutlineButtonEffect.qml"
		asynchronous: true
		property var mouseArea: sidebarItem.__behavior
		active: !!mouseArea && mouseArea.containsMouse
		visible: active
		property var __mouseArea: mouseArea
	}
}
