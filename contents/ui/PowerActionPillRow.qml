import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

PillRowSurface {
	id: root

	surfaceHeight: Math.round(config.flatButtonIconSize + Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing * 3)
	implicitHeight: surfaceHeight
	readonly property var sessionIcons: ['system-lock-screen', 'system-log-out', 'system-save-session', 'system-switch-user']
	readonly property int firstVisiblePowerActionIndex: visiblePowerActionIndex(1)
	readonly property int lastVisiblePowerActionIndex: visiblePowerActionIndex(-1)

	function isVisiblePowerAction(item) {
		if (!item) {
			return false
		}
		return !item.disabled && sessionIcons.indexOf(item.iconName) < 0
	}

	function visiblePowerActionIndex(direction) {
		var list = appsModel && appsModel.powerActionsModel ? appsModel.powerActionsModel.list : null
		if (!list || !list.length) {
			return -1
		}
		var start = direction > 0 ? 0 : list.length - 1
		for (var i = start; i >= 0 && i < list.length; i += direction) {
			if (isVisiblePowerAction(list[i])) {
				return i
			}
		}
		return -1
	}

	RowLayout {
		id: powerPills
		anchors.left: parent.left
		anchors.leftMargin: root.pillsInset
		anchors.right: parent.right
		anchors.rightMargin: root.pillsInset
		height: parent.height
		spacing: Kirigami.Units.smallSpacing

		Repeater {
			id: powerPillsRepeater

			model: appsModel.powerActionsModel
			delegate: PillIconButton {
				readonly property string _baseIcon: model.iconName || model.decoration || ""
				readonly property string _resolvedIcon: (_baseIcon && _baseIcon.indexOf("-symbolic") < 0) ? _baseIcon + "-symbolic" : _baseIcon
				readonly property string _label: model.name || model.display || ""
				visible: root.isVisiblePowerAction(model)
				iconName: _resolvedIcon
				label: _label
				tooltipText: _label
				labelVisible: true
				styleSource: root
				flushLeft: index === root.firstVisiblePowerActionIndex
				flushRight: index === root.lastVisiblePowerActionIndex
				Layout.fillWidth: true
				Layout.fillHeight: true
				Layout.minimumWidth: 0
				iconSize: config.flatButtonIconSize
				onClicked: appsModel.powerActionsModel.triggerIndex(index)
			}
		}
	}
}
