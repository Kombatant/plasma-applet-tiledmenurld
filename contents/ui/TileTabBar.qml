import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

// Tab bar shown above the TileGrid when the "Use Tabs" option is enabled.
// Each entry in `tabs` is an object with at least a `name` string property.
Item {
	id: tabBar

	// Index of the currently selected tab (0-based).
	property int activeTab: 0

	// Array of tab descriptor objects: [{id: string, name: string}, ...]
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

	readonly property int tabHeight: Math.max(28, Kirigami.Units.gridUnit * 1.75)
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
			icon: "edit-delete-remove"
			text: i18n("Delete Tab")
			enabled: tabBar.tabs.length > 1
			onClicked: tabBar.tabDeleted(tabContextMenu.tabIdx)
		}
	}

	// ── Layout ───────────────────────────────────────────────────────────────
	RowLayout {
		anchors.fill: parent
		spacing: 2

		// ── Tab buttons ──────────────────────────────────────────────────────
		Repeater {
			id: tabRepeater
			model: tabBar.tabs

			Item {
				id: tabDelegate

				readonly property bool isActive: tabBar.activeTab === index
				property bool isEditing: false

				Layout.preferredWidth: Math.max(60, tabLabelText.implicitWidth + 24)
				Layout.fillHeight: true

				function startEditing() {
					tabDelegate.isEditing = true
					tabInput.text = modelData.name || ""
					tabInput.forceActiveFocus()
					tabInput.selectAll()
				}

				function finishEditing() {
					var trimmed = tabInput.text.trim()
					if (trimmed.length > 0) {
						tabBar.tabRenamed(index, trimmed)
					}
					tabDelegate.isEditing = false
				}

				// ── Background (flat – no fill) ─────────────────────────────
				Item {
					anchors.fill: parent
				}

				// ── Active tab bottom indicator (text-width underline) ──────
				Rectangle {
					anchors.left: tabLabelText.left
					anchors.right: tabLabelText.right
					anchors.bottom: parent.bottom
					height: 2
					color: Kirigami.Theme.highlightColor
					visible: tabDelegate.isActive && !tabDelegate.isEditing
				}

				// ── Label (read-only) ────────────────────────────────────────
				QQC2.Label {
					id: tabLabelText
					anchors.fill: parent
					anchors.leftMargin: 8
					anchors.rightMargin: 8
					verticalAlignment: Text.AlignVCenter
					font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4
					text: modelData.name || ""
					color: Kirigami.Theme.textColor
					opacity: (tabBar._dragSourceIndex === index) ? 0.3
					: (tabDelegate.isActive ? 1.0 : 0.6)
					Behavior on opacity { NumberAnimation { duration: 100 } }
					elide: Text.ElideRight
					visible: !tabDelegate.isEditing
				}

				// ── Edit input ───────────────────────────────────────────────
				TextInput {
					id: tabInput
					anchors.fill: parent
					anchors.leftMargin: 8
					anchors.rightMargin: 8
					verticalAlignment: TextInput.AlignVCenter
					font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4
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

				// ── Mouse interaction ────────────────────────────────────────
				MouseArea {
					id: hoverArea
					anchors.fill: parent
					hoverEnabled: true
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					cursorShape: tabBar._dragSourceIndex >= 0
						? Qt.ClosedHandCursor : Qt.ArrowCursor

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
						if (pressed && !tabDelegate.isEditing
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
						if (mouse.button === Qt.RightButton) {
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

		// ── "+" Add Tab button ───────────────────────────────────────────────
		Item {
			id: addTabBtn
			Layout.preferredWidth: tabBar.tabHeight
			Layout.fillHeight: true

			// No background fill – flat style
			Item { anchors.fill: parent }

			QQC2.Label {
				anchors.centerIn: parent
				text: "+"
				font.pixelSize: 16
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

		// ── Spacer ───────────────────────────────────────────────────────────
		Item { Layout.fillWidth: true }
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

	// ── Bottom separator line ────────────────────────────────────────────────
	Rectangle {
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		height: Math.max(1, Math.round(Screen.devicePixelRatio * 0.5))
		color: Kirigami.Theme.textColor
		opacity: 0.15
	}
}
