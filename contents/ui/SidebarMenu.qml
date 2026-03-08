import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

MouseArea {
	id: sidebarMenu
	hoverEnabled: true
	z: 1
	// clip: true

	// Support both vertical (left) and horizontal (top/bottom) orientations
	readonly property bool horizontal: config.sidebarHorizontal
	
	// Use explicit width/height based on orientation
	width: horizontal ? parent.width : (open ? config.sidebarMinOpenWidth : config.sidebarWidth)
	height: horizontal ? config.flatButtonSize : parent.height

	property bool open: false

	onOpenChanged: {
		if (open) {
			forceActiveFocus()
		} else {
			searchView.searchField.forceActiveFocus()
		}
	}

	Rectangle {
		anchors.fill: parent
		visible: !plasmoid.configuration.sidebarFollowsTheme
		color: config.sidebarBackgroundColor
	}

	Rectangle {
		anchors.fill: parent
		visible: plasmoid.configuration.sidebarFollowsTheme
		color: Kirigami.Theme.backgroundColor
	}
	KSvg.FrameSvgItem {
		anchors.fill: parent
		visible: plasmoid.configuration.sidebarFollowsTheme
		imagePath: "widgets/frame"
		prefix: "raised"
	}

	property alias showDropShadow: sidebarMenuShadows.visible
	SidebarMenuShadows {
		id: sidebarMenuShadows
		anchors.fill: parent
		visible: !plasmoid.configuration.sidebarFollowsTheme
	}
}
