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

	// ── Keyword → icon mapping ─────────────────────────────────────────────
	// Returns a symbolic icon name that best matches the given tab name,
	// or "" if no keyword matched (caller decides the fallback).
	function inferIconForName(name) {
		var n = (name || "").toLowerCase()
		var map = [
			[["game", "gaming", "steam", "play"], "applications-games"],
			[["music", "audio", "sound", "spotify"], "applications-multimedia"],
			[["video", "movie", "film", "stream", "youtube", "vlc"], "camera-video"],
			[["work", "office", "productivity", "business"], "applications-office"],
			[["dev", "code", "programming", "develop", "terminal", "ide"], "applications-development"],
			[["web", "browser", "internet", "firefox", "chrome", "chromium"], "applications-internet"],
			[["social", "chat", "message", "discord", "telegram", "signal"], "applications-chat"],
			[["mail", "email", "e-mail"], "mail-message"],
			[["photo", "image", "picture", "graphic", "design", "art", "gimp", "inkscape"], "applications-graphics"],
			[["tool", "utility", "utilities", "system", "settings", "config"], "applications-utilities"],
			[["science", "math", "education", "learn"], "applications-science"],
			[["file", "folder", "document", "documents", "files", "dolphin"], "system-file-manager"],
			[["download", "torrent", "transfer"], "folder-download"],
			[["security", "privacy", "password", "vault", "encrypt"], "security-high"],
			[["network", "vpn", "server", "remote", "ssh"], "network-workgroup"],
			[["favorite", "favourite", "starred", "pinned", "bookmark"], "starred"],
			[["main", "home", "start", "all", "general", "default", "application"], "go-home"],
			[["new", "recent", "latest"], "document-new"],
		]
		for (var i = 0; i < map.length; i++) {
			var keywords = map[i][0]
			var icon = map[i][1]
			for (var j = 0; j < keywords.length; j++) {
				if (n.indexOf(keywords[j]) >= 0) return icon
			}
		}
		return ""
	}

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

	readonly property real _borderWidth: Math.max(1, Math.round(Screen.devicePixelRatio))
	readonly property color _borderColor: Qt.rgba(1.0, 1.0, 1.0, 0.35)

	// Active tab edges in tabBar coordinates — reactive bindings via
	// tabRow.x + item.x instead of imperative mapToItem calls.
	// We read tabRepeater.count to force re-evaluation when items are created.
	readonly property bool _activeTabReady: {
		if (tabRepeater.count <= 0) return false
		var item = tabRepeater.itemAt(activeTab)
		return item !== null && item.width > 0
	}
	readonly property real _activeTabLeft: {
		void(tabRepeater.count) // dependency on count so binding re-evaluates when items are created
		var item = tabRepeater.itemAt(activeTab)
		if (!item) return 0
		return tabRow.x + item.x
	}
	readonly property real _activeTabRight: {
		void(tabRepeater.count)
		var item = tabRepeater.itemAt(activeTab)
		if (!item) return 0
		return tabRow.x + item.x + item.width
	}

	// ── Layout ───────────────────────────────────────────────────────────────
	Row {
		id: tabRow
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		height: parent.height
		spacing: 0

		// ── Tab buttons ──────────────────────────────────────────────────
		Repeater {
			id: tabRepeater
			model: tabBar.tabs

			Item {
				id: tabDelegate

				readonly property bool isActive: tabBar.activeTab === index
				property bool isEditing: false

				width: Math.max(Kirigami.Units.gridUnit * 6, tabLabelMetrics.advanceWidth + Kirigami.Units.gridUnit * 3)
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
					if (trimmed.length > 0) {
						tabBar.tabRenamed(index, trimmed)
						var inferred = tabBar.inferIconForName(trimmed)
						if (inferred) {
							tabBar.tabIconChanged(index, inferred)
						}
					}
					tabDelegate.isEditing = false
				}

				// ── Curved tab shape (fill + border) for active tab ──
				Canvas {
					id: tabShape
					visible: tabDelegate.isActive
					anchors.fill: parent

					readonly property real r: Kirigami.Units.smallSpacing * 2
					readonly property real bw: tabBar._borderWidth
					readonly property color bc: tabBar._borderColor

					onPaint: {
						var ctx = getContext("2d")
						ctx.clearRect(0, 0, width, height)
						var w = width, h = height

						// ── Filled background with gradient ──
						ctx.beginPath()
						ctx.moveTo(0, h)
						ctx.lineTo(0, r)
						ctx.arcTo(0, 0, r, 0, r)
						ctx.lineTo(w - r, 0)
						ctx.arcTo(w, 0, w, r, r)
						ctx.lineTo(w, h)
						ctx.closePath()

						var grad = ctx.createLinearGradient(0, 0, 0, h)
						grad.addColorStop(0.0, Qt.rgba(1.0, 1.0, 1.0, 0.08))
						grad.addColorStop(1.0, "transparent")
						ctx.fillStyle = grad
						ctx.fill()

						// ── Border stroke (top + left + right, no bottom) ──
						ctx.beginPath()
						ctx.moveTo(0, h)
						ctx.lineTo(0, r)
						ctx.arcTo(0, 0, r, 0, r)
						ctx.lineTo(w - r, 0)
						ctx.arcTo(w, 0, w, r, r)
						ctx.lineTo(w, h)
						ctx.lineWidth = bw
						ctx.strokeStyle = bc
						ctx.stroke()
					}

					onWidthChanged: requestPaint()
					onHeightChanged: requestPaint()
				}

				// ── Label ────────────────────────────────────────────────
				QQC2.Label {
					id: tabLabelText
					anchors.fill: parent
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.05)
					font.weight: tabDelegate.isActive ? Font.DemiBold : Font.Normal
					text: modelData.name || ""
					color: Kirigami.Theme.textColor
					elide: Text.ElideRight
					visible: !tabDelegate.isEditing
					opacity: (tabBar._dragSourceIndex === index) ? 0.3
						: tabDelegate.isActive ? 1.0
						: hoverArea.containsMouse ? 0.85 : 0.55
					Behavior on opacity { NumberAnimation { duration: 100 } }
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

	// ── "+" Add Tab button ──────────────────────────────────────────────────
	Item {
		id: addTabBtn
		anchors.left: tabRow.right
		anchors.bottom: parent.bottom
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

	// ── Bottom line — split around the active tab to create the tab illusion ──
	// When the Repeater hasn't instantiated items yet, draw one full-width line
	// as a fallback (no tab gap to cut out yet).
	Rectangle {
		id: bottomLineFull
		visible: !tabBar._activeTabReady
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		height: tabBar._borderWidth
		color: tabBar._borderColor
	}
	Rectangle {
		id: bottomLineLeft
		visible: tabBar._activeTabReady
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		width: tabBar._activeTabLeft
		height: tabBar._borderWidth
		color: tabBar._borderColor
	}
	Rectangle {
		id: bottomLineRight
		visible: tabBar._activeTabReady
		x: tabBar._activeTabRight
		anchors.bottom: parent.bottom
		width: parent.width - tabBar._activeTabRight
		height: tabBar._borderWidth
		color: tabBar._borderColor
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
