import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
	id: avatar

	property url source: widget.hasUserAvatar ? widget.userAvatarSource : ""
	property bool hasAvatar: widget.hasUserAvatar
	property real inset: Math.max(2, Math.round(width * 0.035))
	property color baseColor: plasmoid.configuration.sidebarFollowsTheme ? Kirigami.Theme.backgroundColor : config.sidebarBackgroundColor

	function relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		return (0.2126 * channel(color.r)) + (0.7152 * channel(color.g)) + (0.0722 * channel(color.b))
	}

	readonly property bool baseIsLight: relativeLuminance(baseColor) > 0.6

	Rectangle {
		id: recessedWell
		anchors.fill: parent
		radius: width / 2
		color: Qt.rgba(0, 0, 0, avatar.baseIsLight ? 0.12 : 0.26)
		border.width: Math.max(1, Math.round(Screen.devicePixelRatio))
		border.color: Qt.rgba(0, 0, 0, avatar.baseIsLight ? 0.24 : 0.44)
	}

	Rectangle {
		anchors.fill: recessedWell
		anchors.margins: Math.max(1, Math.round(Screen.devicePixelRatio))
		radius: recessedWell.radius
		gradient: Gradient {
			GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, avatar.baseIsLight ? 0.18 : 0.32) }
			GradientStop { position: 0.42; color: "transparent" }
			GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, avatar.baseIsLight ? 0.12 : 0.06) }
		}
	}

	Rectangle {
		id: avatarMask
		anchors.fill: avatarContent
		radius: width / 2
		visible: false
		layer.enabled: true
	}

	Item {
		id: avatarContent
		anchors.fill: parent
		anchors.margins: avatar.inset
		layer.enabled: true
		layer.live: true
		layer.effect: MultiEffect {
			maskEnabled: true
			maskSource: avatarMask
		}

		AnimatedImage {
			anchors.fill: parent
			source: avatar.source
			cache: false
			asynchronous: true
			fillMode: Image.PreserveAspectCrop
			sourceSize.width: width
			sourceSize.height: height
			playing: visible
			visible: avatar.hasAvatar
		}

		Kirigami.Icon {
			anchors.fill: parent
			source: "user-identity"
			visible: !avatar.hasAvatar
		}
	}

	Rectangle {
		anchors.fill: avatarContent
		radius: width / 2
		color: "transparent"
		border.width: Math.max(1, Math.round(Screen.devicePixelRatio))
		border.color: Qt.rgba(1, 1, 1, avatar.baseIsLight ? 0.16 : 0.1)
	}
}
