import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

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
	property var sidebarMenu: parent ? parent.parent : null // Column.SidebarMenu
	expanded: sidebarMenu && typeof sidebarMenu.open !== 'undefined' ? sidebarMenu.open : false
	labelVisible: expanded
	property bool closeOnClick: true
	property string tooltipText: ""
	property bool forceMonochromeIcon: false
	property bool desaturateIcon: false
	property bool showBadge: false
	property bool showHoverOutline: true
	icon.color: forceMonochromeIcon ? (checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor) : "transparent"
	layer.enabled: desaturateIcon && !hovered && !pressed
	layer.effect: MultiEffect {
		saturation: -1.0
	}

	QQC2.ToolTip {
		id: control
		visible: sidebarItem.hovered && !sidebarItem.expanded && !sidebarItem.labelVisible
		text: sidebarItem.tooltipText
		delay: 0
		x: parent.width + rightPadding
		y: (parent.height - height) / 2
	}

	readonly property real _badgeIconWidth: Math.max(0, icon.width || sidebarItem._iconSize)
	readonly property real _badgeIconHeight: Math.max(0, icon.height || sidebarItem._iconSize)
	readonly property real _badgeIconLeft: display === QQC2.AbstractButton.IconOnly
		? leftPadding + ((availableWidth - _badgeIconWidth) / 2)
		: leftPadding
	readonly property real _badgeIconTop: topPadding + ((availableHeight - _badgeIconHeight) / 2)

	Rectangle {
		id: updateBadgeDot
		visible: sidebarItem.showBadge
		width: Math.max(10, Math.round(sidebarItem.height * 0.32))
		height: width
		radius: width / 2
		color: Kirigami.Theme.negativeTextColor
		border.color: Kirigami.Theme.backgroundColor
		border.width: Math.max(1, Math.round(Screen.devicePixelRatio * 1.5))
		z: 9999
		x: Math.round(sidebarItem._badgeIconLeft + sidebarItem._badgeIconWidth - (width * 0.45))
		y: Math.round(sidebarItem._badgeIconTop - (width * 0.15))
	}

	Loader {
		id: hoverOutlineEffectLoader
		anchors.fill: parent
		source: "HoverOutlineButtonEffect.qml"
		asynchronous: true
		property var mouseArea: sidebarItem.__behavior
		active: sidebarItem.showHoverOutline && !!mouseArea && mouseArea.containsMouse
		visible: active
		property var __mouseArea: mouseArea
	}
}
