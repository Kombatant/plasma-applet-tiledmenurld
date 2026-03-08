import QtQuick

Item {
	id: shadowRoot
	property int dropShadowSize: 8 * Screen.devicePixelRatio

	// Use softer shadows that work well in both light and dark modes
	readonly property real shadowOpacity: 0.12

	// Determine which edge needs a shadow based on sidebar position
	readonly property bool sidebarOnLeft: config.sidebarOnLeft
	readonly property bool sidebarOnTop: config.sidebarOnTop
	readonly property bool sidebarOnBottom: config.sidebarOnBottom

	// Shadow on the RIGHT edge of a left sidebar (casts onto content area)
	Rectangle {
		id: rightEdgeShadow
		visible: sidebarOnLeft
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.left: parent.right
		width: dropShadowSize
		gradient: Gradient {
			orientation: Gradient.Horizontal
			GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, shadowOpacity) }
			GradientStop { position: 0.3; color: Qt.rgba(0, 0, 0, 0.04) }
			GradientStop { position: 1.0; color: "transparent" }
		}
	}

	// Shadow on the BOTTOM edge of a top sidebar (casts onto content area)
	Rectangle {
		id: bottomEdgeShadow
		visible: sidebarOnTop
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.bottom
		height: dropShadowSize
		gradient: Gradient {
			orientation: Gradient.Vertical
			GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, shadowOpacity) }
			GradientStop { position: 0.3; color: Qt.rgba(0, 0, 0, 0.04) }
			GradientStop { position: 1.0; color: "transparent" }
		}
	}

	// Shadow on the TOP edge of a bottom sidebar (casts onto content area)
	Rectangle {
		id: topEdgeShadow
		visible: sidebarOnBottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.top
		height: dropShadowSize
		gradient: Gradient {
			orientation: Gradient.Vertical
			GradientStop { position: 0.0; color: "transparent" }
			GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.04) }
			GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, shadowOpacity) }
		}
	}
}
