import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
	id: root

	default property alias content: contentLayer.data
	property real surfaceHeight: Math.round((Kirigami.Units.gridUnit * 2.5) * 0.85)
	readonly property real pillRadius: config.tileCornerRadius
	readonly property real listPadding: Math.round(Kirigami.Units.smallSpacing * 0.5)
	readonly property bool surfaceBorderVisible: !plasmoid.configuration.sidebarHideBorder
	readonly property real pillsInset: surfaceBorderVisible ? listPadding : 0
	readonly property real activeIndicatorInset: surfaceBorderVisible ? 2 : 0
	readonly property real activeIndicatorRadius: Math.max(0, pillRadius - activeIndicatorInset)
	readonly property color accentHighlightColor: Kirigami.Theme.highlightColor
	readonly property real activeHighlightBorderOpacity: 0.95
	readonly property real activeHighlightGlowOpacity: 0.78
	readonly property real activeHighlightFillStrength: 1.0
	readonly property real activeHighlightInnerRimOpacity: 0.24
	readonly property real hoverHighlightBorderOpacity: 0.62
	readonly property real hoverHighlightGlowOpacity: 0.44
	readonly property real hoverHighlightFillStrength: 0.58
	readonly property real hoverHighlightInnerRimOpacity: 0.14
	readonly property color activeTextColor: Kirigami.Theme.textColor
	readonly property color hoverTextColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.88)
	readonly property color idleTextColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.72)

	implicitHeight: surfaceHeight

	SidebarGlassCard {
		anchors.fill: parent
		contentMargins: 0
	}

	Item {
		id: contentLayer

		anchors.fill: parent
	}

}
