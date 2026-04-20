import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

MouseArea {
	id: sidebarMenu
	default property alias contentData: contentHost.data
	hoverEnabled: true
	z: 1
	// clip: true

	// Support both vertical (left) and horizontal (top/bottom) orientations
	readonly property bool horizontal: config.sidebarHorizontal
	readonly property int floatingInset: config.sidebarOnLeft ? config.sidebarCardInset : 0
	
	// Use explicit width/height based on orientation
	width: horizontal ? parent.width : (open ? config.sidebarMinOpenWidth : config.sidebarWidth) + (floatingInset * 2) + (config.sidebarCardContentPadding * 2)
	height: horizontal ? config.flatButtonSize : parent.height

	property bool open: false

	onOpenChanged: {
		if (open) {
			forceActiveFocus()
		} else {
			searchView.searchField.forceActiveFocus()
		}
	}

	SidebarGlassCard {
		id: sidebarCard
		anchors.fill: parent
		anchors.margins: sidebarMenu.floatingInset
		visible: config.sidebarOnLeft
		open: sidebarMenu.open
		contentMargins: 0
	}

	Rectangle {
		anchors.fill: parent
		visible: !config.sidebarOnLeft && !plasmoid.configuration.sidebarFollowsTheme
		color: config.sidebarBackgroundColor
	}

	Rectangle {
		anchors.fill: parent
		visible: !config.sidebarOnLeft && plasmoid.configuration.sidebarFollowsTheme
		color: Kirigami.Theme.backgroundColor
	}

	KSvg.FrameSvgItem {
		anchors.fill: parent
		visible: !config.sidebarOnLeft && plasmoid.configuration.sidebarFollowsTheme
		imagePath: "widgets/frame"
		prefix: "raised"
	}

	Item {
		id: contentHost
		property alias open: sidebarMenu.open
		anchors.left: config.sidebarOnLeft ? sidebarCard.left : parent.left
		anchors.right: config.sidebarOnLeft ? sidebarCard.right : parent.right
		anchors.top: config.sidebarOnLeft ? sidebarCard.top : parent.top
		anchors.bottom: config.sidebarOnLeft ? sidebarCard.bottom : parent.bottom
		anchors.margins: config.sidebarOnLeft ? config.sidebarCardContentPadding : 0
	}

	property alias showDropShadow: sidebarMenuShadows.visible
	SidebarMenuShadows {
		id: sidebarMenuShadows
		anchors.fill: parent
		visible: !config.sidebarOnLeft && !plasmoid.configuration.sidebarFollowsTheme
	}
}
