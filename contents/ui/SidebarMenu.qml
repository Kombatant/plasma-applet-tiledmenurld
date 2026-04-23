import QtQuick

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
		open: sidebarMenu.open
		contentMargins: 0
	}

	Item {
		id: contentHost
		property alias open: sidebarMenu.open
		anchors.left: sidebarCard.left
		anchors.right: sidebarCard.right
		anchors.top: sidebarCard.top
		anchors.bottom: sidebarCard.bottom
		anchors.margins: config.sidebarOnLeft ? config.sidebarCardContentPadding : 0
	}

	property alias showDropShadow: sidebarMenuShadows.visible
	SidebarMenuShadows {
		id: sidebarMenuShadows
		anchors.fill: parent
		shadowSize: sidebarCard.shadowSize
		shadowColor: sidebarCard.shadowColor
		visible: false
	}
}
