import QtQuick
import org.kde.kirigami as Kirigami

Item {
	id: cardRoot

	default property alias contentData: contentLayer.data
	property alias contentItem: contentLayer

	property bool open: false
	property string surfaceStyle: (typeof config !== "undefined" && config) ? config.surfaceStyle : "theme"
	property color baseColor: (typeof config !== "undefined" && config) ? config.surfaceBaseColor : Kirigami.Theme.backgroundColor
	property int contentMargins: config.sidebarCardContentPadding
	property real fillOpacity: 0.33
	property real radius: config.tileCornerRadius

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
	readonly property bool useFrostedSurface: surfaceStyle === "frosted"
	readonly property color normalGlassColor: {
		var darkened = Qt.darker(baseColor, baseIsLight ? 1.08 : 1.18)
		return colorWithAlpha(darkened, fillOpacity)
	}
	readonly property color lightFrostedGlassColor: Qt.rgba(0.95, 0.965, 0.985, 0.78)
	readonly property color frostedGlassColor: baseIsLight
		? lightFrostedGlassColor
		: Qt.rgba(0.12, 0.14, 0.16, 0.46)
	readonly property color glassColor: useFrostedSurface ? frostedGlassColor : normalGlassColor
	readonly property color rimColor: useFrostedSurface
		? (baseIsLight ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(1, 1, 1, 0.18))
		: (baseIsLight ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(1, 1, 1, 0.18))
	readonly property color bottomRimColor: useFrostedSurface
		? (baseIsLight ? Qt.rgba(0.16, 0.2, 0.24, 0.18) : Qt.rgba(0, 0, 0, 0.18))
		: "transparent"
	readonly property real shadowSizeMultiplier: (typeof config !== "undefined" && config) ? config.surfaceShadowSizeMultiplier : 1.0
	readonly property real shadowOpacityMultiplier: (typeof config !== "undefined" && config) ? config.surfaceShadowOpacityMultiplier : 1.0
	readonly property real baseShadowOpacity: baseIsLight ? (useFrostedSurface ? 0.19 : 0.13) : (useFrostedSurface ? 0.18 : 0.32)
	readonly property int shadowSize: Math.round(Kirigami.Units.gridUnit * (useFrostedSurface ? 1.1 : 1.25) * shadowSizeMultiplier)
	readonly property color shadowColor: Qt.rgba(0, 0, 0, Math.min(1, baseShadowOpacity * shadowOpacityMultiplier))
	readonly property int shadowYOffset: Math.round(2 * Screen.devicePixelRatio)

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
			size: cardRoot.shadowSize
			color: cardRoot.shadowColor
			yOffset: cardRoot.shadowYOffset
		}
	}

	Rectangle {
		anchors.fill: surface
		visible: cardRoot.useFrostedSurface
		radius: cardRoot.radius
		gradient: Gradient {
			GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, cardRoot.baseIsLight ? 0.24 : 0.10) }
			GradientStop { position: 0.42; color: Qt.rgba(1, 1, 1, cardRoot.baseIsLight ? 0.10 : 0.03) }
			GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, cardRoot.baseIsLight ? 0.08 : 0.08) }
		}
	}

	Rectangle {
		anchors.left: surface.left
		anchors.right: surface.right
		anchors.bottom: surface.bottom
		anchors.leftMargin: cardRoot.radius
		anchors.rightMargin: cardRoot.radius
		visible: cardRoot.useFrostedSurface && !plasmoid.configuration.sidebarHideBorder
		height: Math.max(1, Math.round(Screen.devicePixelRatio))
		color: cardRoot.bottomRimColor
		opacity: 0.55
	}

	Item {
		id: contentLayer
		property alias open: cardRoot.open
		anchors.fill: surface
		anchors.margins: cardRoot.contentMargins
	}
}
