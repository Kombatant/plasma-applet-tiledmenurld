import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string iconName: ""
    property var iconSource: ""
    property string label: ""
    property string tooltipText: label
    property bool labelVisible: false
    property bool showBadge: false
    property var styleSource: null
    property bool flushLeft: false
    property bool flushRight: false
    property int iconSize: Kirigami.Units.iconSizes.smallMedium
    readonly property bool hovered: mouseArea.containsMouse
    readonly property color foregroundColor: hovered ? _styleValue("activeTextColor", "_activeTextColor", Kirigami.Theme.textColor) : _styleValue("idleTextColor", "_idleTextColor", Kirigami.Theme.textColor)

    signal clicked()

    function _styleValue(name, legacyName, fallback) {
        if (styleSource && typeof styleSource[name] !== "undefined")
            return styleSource[name];

        if (styleSource && legacyName && typeof styleSource[legacyName] !== "undefined")
            return styleSource[legacyName];

        return fallback;
    }

    Accessible.name: tooltipText
    Accessible.role: Accessible.Button
    QQC2.ToolTip.visible: root.hovered
    QQC2.ToolTip.text: root.tooltipText

    PillHighlight {
        anchors.fill: parent
        styleSource: root.styleSource
        active: false
        flushLeft: root.flushLeft
        flushRight: root.flushRight
        visible: root.hovered
    }

    ColumnLayout {
        visible: root.labelVisible
        anchors.centerIn: parent
        width: parent.width
        spacing: Kirigami.Units.smallSpacing / 2

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            source: root.iconSource || root.iconName
            color: root.foregroundColor
            isMask: true

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }

            }

        }

        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.label
            elide: Text.ElideRight
            color: root.foregroundColor
            font: Kirigami.Theme.smallFont

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }

            }

        }

    }

    Kirigami.Icon {
        visible: !root.labelVisible
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.iconSource || root.iconName
        color: root.foregroundColor
        isMask: true

        Behavior on color {
            ColorAnimation {
                duration: 120
            }

        }

    }

    Rectangle {
        visible: root.showBadge
        width: Math.max(8, Math.round(root.height * 0.18))
        height: width
        radius: width / 2
        color: Kirigami.Theme.negativeTextColor
        border.color: Kirigami.Theme.backgroundColor
        border.width: Math.max(1, Math.round(Screen.devicePixelRatio))
        x: root.width - width - Math.round(width * 0.35)
        y: Math.round(width * 0.35)
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

}
