import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.iconthemes as KIconThemes

// Tab bar shown above the TileGrid when the "Use Tabs" option is enabled.
// Each entry in `tabs` is an object with at least a `name` string property.
Item {
	id: tabBar

	// Index of the currently selected tab (0-based).
	property int activeTab: 0

	// Array of tab descriptor objects: [{id: string, name: string, icon: string}, ...]
	property var tabs: []

	// Emitted when the user selects a different tab.
	signal tabSelected(int index)
	// Emitted when the user clicks the "+" button to add a new tab.
	signal tabAdded()
	// Emitted when the user requests a tab to be deleted (index).
	signal tabDeleted(int index)
	// Emitted when the user finishes renaming a tab (index, newName).
	signal tabRenamed(int index, string newName)
	// Emitted when the user drags a tab to a new position.
	signal tabMoved(int fromIndex, int toIndex)
	// Emitted when the tab icon changes (index, newIcon).
	signal tabIconChanged(int index, string newIcon)

	// ── Internal drag state ─────────────────────────────────────────────────
	property int _dragSourceIndex: -1
	property int _dropSlot: -1

	function _slotAtX(x) {
		for (var i = 0; i < tabRepeater.count; i++) {
			var item = tabRepeater.itemAt(i)
			if (!item) continue
			var itemPos = item.mapToItem(tabBar, 0, 0)
			if (x < itemPos.x + item.width / 2) return i
		}
		return tabRepeater.count
	}

	readonly property int tabHeight: Kirigami.Units.gridUnit * 2.5
	implicitHeight: tabHeight

	// ── Shared context menu ─────────────────────────────────────────────────
	PlasmaExtras.Menu {
		id: tabContextMenu
		property int tabIdx: -1

		PlasmaExtras.MenuItem {
			icon: "edit-rename"
			text: i18n("Rename Tab")
			onClicked: {
				var item = tabRepeater.itemAt(tabContextMenu.tabIdx)
				if (item) {
					item.startEditing()
				}
			}
		}

		PlasmaExtras.MenuItem {
			icon: "preferences-desktop-icons"
			text: i18n("Change Icon…")
			onClicked: tabIconDialog.open()
		}

		PlasmaExtras.MenuItem {
			icon: "edit-clear"
			text: i18n("Clear Icon")
			enabled: {
				var idx = tabContextMenu.tabIdx
				return idx >= 0 && idx < tabBar.tabs.length
					&& (tabBar.tabs[idx].icon || "") !== ""
			}
			onClicked: tabBar.tabIconChanged(tabContextMenu.tabIdx, "")
		}

		PlasmaExtras.MenuItem { separator: true }

		PlasmaExtras.MenuItem {
			icon: "list-add"
			text: i18n("Add Tab")
			onClicked: tabBar.tabAdded()
		}

		PlasmaExtras.MenuItem {
			icon: "edit-delete-remove"
			text: i18n("Delete Tab")
			onClicked: tabBar.tabDeleted(tabContextMenu.tabIdx)
		}
	}

	KIconThemes.IconDialog {
		id: tabIconDialog
		onIconNameChanged: {
			if (iconName && tabContextMenu.tabIdx >= 0) {
				tabBar.tabIconChanged(tabContextMenu.tabIdx, iconName)
			}
		}
	}

	readonly property real _pillRadius: Kirigami.Units.smallSpacing * 1.5
	readonly property real _listPadding: Math.round(Kirigami.Units.smallSpacing * 0.5)
	readonly property color _listBgColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.08)
	readonly property color _indicatorColor: Kirigami.Theme.backgroundColor
	readonly property color _activeTextColor: Kirigami.Theme.textColor
	readonly property color _hoverTextColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.88)
	readonly property color _idleTextColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.72)

	// ── Layout ───────────────────────────────────────────────────────────────
	Rectangle {
		id: listBackground
		anchors.fill: tabFlickable
		radius: Kirigami.Units.smallSpacing * 2
		color: tabBar._listBgColor
		z: -1
	}

	Flickable {
		id: tabFlickable
		anchors.left: parent.left
		anchors.right: trailingControls.left
		anchors.rightMargin: Kirigami.Units.smallSpacing
		anchors.verticalCenter: parent.verticalCenter
		height: Math.round(parent.height * 0.85)
		contentWidth: tabRow.width + tabBar._listPadding * 2
		contentHeight: height
		clip: true
		boundsBehavior: Flickable.StopAtBounds
		flickableDirection: Flickable.HorizontalFlick
		interactive: trailingControls._overflow

		function ensureIndexVisible(idx) {
			if (idx < 0 || idx >= tabRepeater.count) return
			var item = tabRepeater.itemAt(idx)
			if (!item) return
			var left = tabRow.x + item.x
			var right = left + item.width
			if (left < contentX + tabBar._listPadding) {
				contentX = Math.max(0, left - tabBar._listPadding)
			} else if (right > contentX + width - tabBar._listPadding) {
				contentX = Math.min(Math.max(0, contentWidth - width), right - width + tabBar._listPadding)
			}
		}

		function snapContentX(target) {
			var maxX = Math.max(0, contentWidth - width)
			var desired = Math.max(0, Math.min(maxX, target))
			if (tabRepeater.count === 0 || desired <= 0 || desired >= maxX) {
				return desired
			}
			var best = desired
			var bestDist = Number.POSITIVE_INFINITY
			for (var i = 0; i < tabRepeater.count; i++) {
				var item = tabRepeater.itemAt(i)
				if (!item) continue
				var leftBoundary = tabRow.x + item.x - tabBar._listPadding
				var rightBoundary = tabRow.x + item.x + item.width - width + tabBar._listPadding
				var candidates = [leftBoundary, rightBoundary]
				for (var c = 0; c < candidates.length; c++) {
					var cand = Math.max(0, Math.min(maxX, candidates[c]))
					var d = Math.abs(cand - desired)
					if (d < bestDist) {
						bestDist = d
						best = cand
					}
				}
			}
			return best
		}

		onWidthChanged: {
			var maxX = Math.max(0, contentWidth - width)
			if (contentX > maxX) contentX = maxX
			contentX = snapContentX(contentX)
		}

		onMovementEnded: contentX = snapContentX(contentX)

		Connections {
			target: tabBar
			function onActiveTabChanged() { tabFlickable.ensureIndexVisible(tabBar.activeTab) }
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.NoButton
			onWheel: function(wheel) {
				if (!tabFlickable.interactive) { wheel.accepted = false; return }
				var step = Kirigami.Units.gridUnit * 2
				var dy = wheel.angleDelta.y
				var dx = wheel.angleDelta.x
				var delta = (Math.abs(dx) > Math.abs(dy)) ? dx : dy
				var raw = tabFlickable.contentX - delta / 120 * step
				tabFlickable.contentX = tabFlickable.snapContentX(raw)
				wheel.accepted = true
			}
		}

	Rectangle {
		id: activeIndicator
		z: 0
		visible: tabRepeater.count > 0
		readonly property var _activeItem: {
			void(tabRepeater.count)
			return tabRepeater.itemAt(tabBar.activeTab)
		}
		x: _activeItem ? tabRow.x + _activeItem.x : 0
		y: _activeItem ? tabRow.y + _activeItem.y + 2 : 0
		width: _activeItem ? _activeItem.width : 0
		height: _activeItem ? _activeItem.height - 4 : 0
		radius: tabBar._pillRadius
		color: tabBar._indicatorColor
		border.width: 1
		border.color: Qt.rgba(0, 0, 0, 0.08)
		Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
		Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
	}

	Row {
		id: tabRow
		x: tabBar._listPadding
		height: tabFlickable.height
		spacing: Kirigami.Units.smallSpacing

		// ── Tab buttons ──────────────────────────────────────────────────
		Repeater {
			id: tabRepeater
			model: tabBar.tabs

			Item {
				id: tabDelegate

				readonly property bool isActive: tabBar.activeTab === index
				property bool isEditing: false

				readonly property bool hasIcon: tabIcon !== ""
				readonly property bool isHovered: hoverArea.containsMouse
				width: Math.max(Kirigami.Units.gridUnit * 5, tabLabelMetrics.advanceWidth + (hasIcon ? tabIconItem.width + Kirigami.Units.smallSpacing : 0) + Kirigami.Units.gridUnit * 2)
				height: tabRow.height

				readonly property string tabIcon: modelData.icon || ""

				TextMetrics {
					id: tabLabelMetrics
					font: tabLabelText.font
					text: modelData.name || ""
				}

				function startEditing() {
					tabDelegate.isEditing = true
					tabInput.text = modelData.name || ""
					tabInput.forceActiveFocus()
					tabInput.selectAll()
				}

				function finishEditing() {
					var trimmed = tabInput.text.trim()
					var original = modelData.name || ""
					if (trimmed.length > 0 && trimmed !== original) {
						tabBar.tabRenamed(index, trimmed)
					}
					tabDelegate.isEditing = false
				}


				// ── Icon + Label ─────────────────────────────────────────
				readonly property color _fgColor: tabDelegate.isActive
					? tabBar._activeTextColor
					: (tabDelegate.isHovered ? tabBar._hoverTextColor : tabBar._idleTextColor)

				Row {
					id: tabLabelRow
					anchors.centerIn: parent
					spacing: Kirigami.Units.smallSpacing
					visible: !tabDelegate.isEditing
					opacity: (tabBar._dragSourceIndex === index) ? 0.3 : 1.0
					Behavior on opacity { NumberAnimation { duration: 100 } }

					Kirigami.Icon {
						id: tabIconItem
						visible: tabDelegate.hasIcon
						source: tabDelegate.tabIcon
						width: visible ? tabLabelText.font.pixelSize : 0
						height: width
						anchors.verticalCenter: parent.verticalCenter
						color: tabDelegate._fgColor
					}

					QQC2.Label {
						id: tabLabelText
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						font.pointSize: Kirigami.Theme.defaultFont.pointSize
						font.weight: tabDelegate.isActive ? Font.DemiBold : Font.Normal
						text: modelData.name || ""
						color: tabDelegate._fgColor
						Behavior on color { ColorAnimation { duration: 120 } }
						elide: Text.ElideRight
					}
				}

				// ── Edit input ───────────────────────────────────────────
				TextInput {
					id: tabInput
					anchors.fill: parent
					anchors.leftMargin: Kirigami.Units.largeSpacing
					anchors.rightMargin: Kirigami.Units.largeSpacing
					horizontalAlignment: TextInput.AlignHCenter
					verticalAlignment: TextInput.AlignVCenter
					font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.05)
					color: Kirigami.Theme.textColor
					visible: tabDelegate.isEditing
					clip: true

					Keys.onReturnPressed: tabDelegate.finishEditing()
					Keys.onEscapePressed: { tabDelegate.isEditing = false }
					onActiveFocusChanged: {
						if (!activeFocus && tabDelegate.isEditing) {
							tabDelegate.finishEditing()
						}
					}
				}

				// ── Mouse interaction ────────────────────────────────────
				MouseArea {
					id: hoverArea
					anchors.fill: parent
					hoverEnabled: true
					acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
					cursorShape: tabBar._dragSourceIndex >= 0
						? Qt.ClosedHandCursor : Qt.PointingHandCursor

					property point _pressPos
					property bool _didDrag: false

					onPressed: function(mouse) {
						_didDrag = false
						if (mouse.button === Qt.LeftButton
								&& !tabDelegate.isEditing) {
							_pressPos = Qt.point(mouse.x, mouse.y)
						}
					}

					onPositionChanged: function(mouse) {
						if (pressed && mouse.buttons & Qt.LeftButton
								&& !tabDelegate.isEditing
								&& tabBar._dragSourceIndex < 0) {
							if (Math.abs(mouse.x - _pressPos.x) > 8) {
								tabBar._dragSourceIndex = index
								_didDrag = true
							}
						}
						if (tabBar._dragSourceIndex === index) {
							var globalPos = mapToItem(tabBar,
								mouse.x, 0)
							tabBar._dropSlot = tabBar._slotAtX(
								globalPos.x)
						}
					}

					onReleased: function(mouse) {
						if (tabBar._dragSourceIndex === index) {
							var from = tabBar._dragSourceIndex
							var slot = tabBar._dropSlot
							tabBar._dragSourceIndex = -1
							tabBar._dropSlot = -1
							var to = (slot > from) ? slot - 1 : slot
							if (to >= 0 && to !== from) {
								tabBar.tabMoved(from, to)
							}
						}
					}

					onClicked: function(mouse) {
						if (_didDrag) return
						if (mouse.button === Qt.MiddleButton) {
							tabBar.tabDeleted(index)
						} else if (mouse.button === Qt.RightButton) {
							tabContextMenu.tabIdx = index
							var pos = mapToItem(tabBar, mouse.x,
								mouse.y)
							tabContextMenu.open(pos.x, pos.y)
						} else if (!tabDelegate.isEditing) {
							tabBar.tabSelected(index)
						}
					}

					onDoubleClicked: {
						if (!_didDrag) tabDelegate.startEditing()
					}
				}
			}
		}
	}
	}

	// ── Trailing controls: scroll chevrons + "+" ──────────────────────────
	Row {
		id: trailingControls
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		spacing: 0

		// Width available to the flickable if no chevrons were shown.
		// Using this avoids a binding loop: chevron visibility depends on
		// overflow, which would depend on flickable width, which depends on
		// chevron visibility.
		readonly property real _availableWidth: tabBar.width - addTabBtn.width - Kirigami.Units.smallSpacing
		readonly property real _tabsContentWidth: tabRow.width + tabBar._listPadding * 2
		readonly property bool _overflow: _tabsContentWidth > _availableWidth
		readonly property real _maxContentX: Math.max(0, tabFlickable.contentWidth - tabFlickable.width)

		Item {
			id: scrollLeftBtn
			visible: trailingControls._overflow
			width: visible ? tabBar.tabHeight : 0
			height: tabBar.tabHeight
			enabled: tabFlickable.contentX > 0

			QQC2.Label {
				anchors.centerIn: parent
				text: "‹"
				font.pixelSize: Kirigami.Units.gridUnit * 1.2
				color: Kirigami.Theme.textColor
				opacity: !scrollLeftBtn.enabled ? 0.25
					: scrollLeftMA.containsMouse ? 0.9 : 0.55
			}

			MouseArea {
				id: scrollLeftMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				enabled: scrollLeftBtn.enabled
				onClicked: {
					var step = tabFlickable.width * 0.8
					tabFlickable.contentX = tabFlickable.snapContentX(tabFlickable.contentX - step)
				}
			}
		}

		Item {
			id: scrollRightBtn
			visible: trailingControls._overflow
			width: visible ? tabBar.tabHeight : 0
			height: tabBar.tabHeight
			enabled: tabFlickable.contentX < trailingControls._maxContentX

			QQC2.Label {
				anchors.centerIn: parent
				text: "›"
				font.pixelSize: Kirigami.Units.gridUnit * 1.2
				color: Kirigami.Theme.textColor
				opacity: !scrollRightBtn.enabled ? 0.25
					: scrollRightMA.containsMouse ? 0.9 : 0.55
			}

			MouseArea {
				id: scrollRightMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				enabled: scrollRightBtn.enabled
				onClicked: {
					var step = tabFlickable.width * 0.8
					tabFlickable.contentX = tabFlickable.snapContentX(tabFlickable.contentX + step)
				}
			}
		}

		Item {
			id: addTabBtn
			width: tabBar.tabHeight
			height: tabBar.tabHeight

			QQC2.Label {
				anchors.centerIn: parent
				text: "+"
				font.pixelSize: Kirigami.Units.gridUnit
				color: Kirigami.Theme.textColor
				opacity: addTabMA.containsMouse ? 0.9 : 0.55
			}

			MouseArea {
				id: addTabMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: tabBar.tabAdded()
			}
		}
	}

	// ── Drop indicator ──────────────────────────────────────────────────────
	Rectangle {
		id: dropIndicator
		visible: {
			if (tabBar._dragSourceIndex < 0 || tabBar._dropSlot < 0)
				return false
			var to = (tabBar._dropSlot > tabBar._dragSourceIndex)
				? tabBar._dropSlot - 1 : tabBar._dropSlot
			return to !== tabBar._dragSourceIndex
		}
		width: 2
		y: 4
		height: parent.height - 8
		color: Kirigami.Theme.highlightColor
		x: {
			var slot = tabBar._dropSlot
			if (slot < 0) return 0
			if (slot < tabRepeater.count) {
				var item = tabRepeater.itemAt(slot)
				if (item)
					return item.mapToItem(tabBar, 0, 0).x - 1
			} else if (tabRepeater.count > 0) {
				var lastItem = tabRepeater.itemAt(
					tabRepeater.count - 1)
				if (lastItem)
					return lastItem.mapToItem(tabBar,
						lastItem.width, 0).x - 1
			}
			return 0
		}
	}
}
