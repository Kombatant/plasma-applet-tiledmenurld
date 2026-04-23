import QtQuick

Item {
	id: shadowRoot
	property int shadowSize: 0
	property color shadowColor: Qt.rgba(0, 0, 0, 0)

	readonly property color fadedShadowColor: Qt.rgba(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a * 0.33)
	readonly property color transparentShadowColor: Qt.rgba(shadowColor.r, shadowColor.g, shadowColor.b, 0)

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
		width: shadowSize
		gradient: Gradient {
			orientation: Gradient.Horizontal
			GradientStop { position: 0.0; color: shadowRoot.shadowColor }
			GradientStop { position: 0.3; color: shadowRoot.fadedShadowColor }
			GradientStop { position: 1.0; color: shadowRoot.transparentShadowColor }
		}
	}

	// Shadow on the BOTTOM edge of a top sidebar (casts onto content area)
	Rectangle {
		id: bottomEdgeShadow
		visible: sidebarOnTop
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.bottom
		height: shadowSize
		gradient: Gradient {
			orientation: Gradient.Vertical
			GradientStop { position: 0.0; color: shadowRoot.shadowColor }
			GradientStop { position: 0.3; color: shadowRoot.fadedShadowColor }
			GradientStop { position: 1.0; color: shadowRoot.transparentShadowColor }
		}
	}

	// Shadow on the TOP edge of a bottom sidebar (casts onto content area)
	Rectangle {
		id: topEdgeShadow
		visible: sidebarOnBottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.top
		height: shadowSize
		gradient: Gradient {
			orientation: Gradient.Vertical
			GradientStop { position: 0.0; color: shadowRoot.transparentShadowColor }
			GradientStop { position: 0.7; color: shadowRoot.fadedShadowColor }
			GradientStop { position: 1.0; color: shadowRoot.shadowColor }
		}
	}
}
