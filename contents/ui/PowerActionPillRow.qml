import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

PillRowSurface {
	id: root

	surfaceHeight: Math.round(config.flatButtonIconSize + Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing * 3)
	implicitHeight: surfaceHeight
	property int hoveredPowerActionIndex: -1
	property bool hoverAnimationEnabled: true
	readonly property int _pillMotionDuration: 420
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

	function setHoveredPowerActionIndex(index) {
		hoverAnimationEnabled = hoveredPowerActionIndex >= 0
		hoveredPowerActionIndex = index
		Qt.callLater(function() {
			hoverAnimationEnabled = true
		})
	}

	function resetHoverIndicator() {
		hoverAnimationEnabled = false
		hoveredPowerActionIndex = -1
	}

	function flushPendingState() {
		if (popup && typeof popup.flushPendingTileLayoutSave === "function") {
			popup.flushPendingTileLayoutSave()
		}
	}

	HoverHandler {
		id: powerRowHover
		target: root
		onHoveredChanged: {
			if (!hovered) {
				root.resetHoverIndicator()
			}
		}
	}

	PillHighlight {
		id: hoverIndicator
		visible: root.hoveredPowerActionIndex >= 0 && !!_hoveredItem
		styleSource: root
		active: false
		readonly property var _hoveredItem: {
			void(powerPillsRepeater.count)
			return root.hoveredPowerActionIndex >= 0 ? powerPillsRepeater.itemAt(root.hoveredPowerActionIndex) : null
		}
		x: _hoveredItem ? powerPills.x + _hoveredItem.x : 0
		anchors.top: powerPills.top
		anchors.bottom: powerPills.bottom
		width: _hoveredItem ? _hoveredItem.width : 0
		flushLeft: root.hoveredPowerActionIndex === root.firstVisiblePowerActionIndex
		flushRight: root.hoveredPowerActionIndex === root.lastVisiblePowerActionIndex
		Behavior on x {
			enabled: root.hoverAnimationEnabled
			NumberAnimation {
				duration: root._pillMotionDuration
				easing.type: Easing.OutCubic
			}
		}
		Behavior on width {
			enabled: root.hoverAnimationEnabled
			NumberAnimation {
				duration: root._pillMotionDuration
				easing.type: Easing.OutCubic
			}
		}
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
				highlightEnabled: false
				Layout.fillWidth: true
				Layout.fillHeight: true
				Layout.minimumWidth: 0
				iconSize: config.flatButtonIconSize
				onClicked: {
					root.flushPendingState()
					appsModel.powerActionsModel.triggerIndex(index)
				}
				onHoveredChanged: {
					if (hovered) {
						root.setHoveredPowerActionIndex(index)
					} else if (root.hoveredPowerActionIndex === index && !powerRowHover.hovered) {
						root.resetHoverIndicator()
					}
				}
			}
		}
	}
}
