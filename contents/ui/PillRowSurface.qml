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
    readonly property color listBorderBaseColor: config.surfaceBaseColor
    readonly property bool listBorderBaseIsLight: _relativeLuminance(listBorderBaseColor) > 0.6
    readonly property color indicatorColor: listBorderBaseIsLight ? Qt.darker(Kirigami.Theme.backgroundColor, 1.25) : Qt.lighter(Kirigami.Theme.backgroundColor, 1.6)
    readonly property color activeTextColor: Kirigami.Theme.textColor
    readonly property color hoverTextColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.88)
    readonly property color idleTextColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.72)

    function _relativeLuminance(color) {
        function channel(c) {
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        }

        return (0.2126 * channel(color.r)) + (0.7152 * channel(color.g)) + (0.0722 * channel(color.b));
    }

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
