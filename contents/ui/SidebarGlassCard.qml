import QtQuick
import org.kde.kirigami as Kirigami

Item {
	id: cardRoot

	default property alias contentData: contentLayer.data
	property alias contentItem: contentLayer

	property bool open: false
	property color baseColor: plasmoid.configuration.sidebarFollowsTheme ? Kirigami.Theme.backgroundColor : config.sidebarBackgroundColor
	property int contentMargins: config.sidebarCardContentPadding
	property real fillOpacity: 0.33
	property real radius: Math.max(Kirigami.Units.cornerRadius, Math.round(10 * Screen.devicePixelRatio))

	function relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		return (0.2126 * channel(color.r)) + (0.7152 * channel(color.g)) + (0.0722 * channel(color.b))
	}

	function colorWithAlpha(color, alpha) {
		return Qt.rgba(color.r, color.g, color.b, alpha)
	}

	readonly property bool baseIsLight: relativeLuminance(baseColor) > 0.6
	readonly property color glassColor: {
		var darkened = Qt.darker(baseColor, baseIsLight ? 1.08 : 1.18)
		return colorWithAlpha(darkened, fillOpacity)
	}
	readonly property color rimColor: baseIsLight ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(1, 1, 1, 0.18)

	Kirigami.ShadowedRectangle {
		id: surface
		anchors.fill: parent
		color: cardRoot.glassColor
		radius: cardRoot.radius

		border {
			width: plasmoid.configuration.sidebarHideBorder ? 0 : Math.max(1, Math.round(Screen.devicePixelRatio))
			color: cardRoot.rimColor
		}

		shadow {
			size: Math.round(Kirigami.Units.gridUnit * 1.25)
			color: Qt.rgba(0, 0, 0, cardRoot.baseIsLight ? 0.18 : 0.32)
			yOffset: Math.round(2 * Screen.devicePixelRatio)
		}
	}

	Item {
		id: contentLayer
		property alias open: cardRoot.open
		anchors.fill: surface
		anchors.margins: cardRoot.contentMargins
	}
}
