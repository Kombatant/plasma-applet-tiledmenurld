import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

PillRowSurface {
	id: root

	surfaceHeight: Math.round(config.flatButtonIconSize + Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing * 3)
	implicitHeight: surfaceHeight

	RowLayout {
		id: powerPills
		anchors.left: parent.left
		anchors.leftMargin: root.pillsInset
		anchors.right: parent.right
		anchors.rightMargin: root.pillsInset
		height: parent.height
		spacing: Kirigami.Units.smallSpacing

		Repeater {
			model: appsModel.powerActionsModel
			delegate: PillIconButton {
				readonly property var _sessionIcons: ['system-lock-screen', 'system-log-out', 'system-save-session', 'system-switch-user']
				readonly property string _baseIcon: model.iconName || model.decoration || ""
				readonly property string _resolvedIcon: (_baseIcon && _baseIcon.indexOf("-symbolic") < 0) ? _baseIcon + "-symbolic" : _baseIcon
				readonly property string _label: model.name || model.display || ""
				visible: !model.disabled && _sessionIcons.indexOf(model.iconName) < 0
				iconName: _resolvedIcon
				label: _label
				tooltipText: _label
				labelVisible: true
				styleSource: root
				Layout.fillWidth: true
				Layout.fillHeight: true
				Layout.minimumWidth: 0
				iconSize: config.flatButtonIconSize
				onClicked: appsModel.powerActionsModel.triggerIndex(index)
			}
		}
	}
}
