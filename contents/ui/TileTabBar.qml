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

	// Whether the tab row overflows and needs scrolling
	readonly property bool _canScroll: tabFlickable.contentWidth > tabFlickable.width

	// ── Layout ───────────────────────────────────────────────────────────────
	Flickable {
		id: tabFlickable
		anchors.left: parent.left
		anchors.right: scrollArrows.visible ? scrollArrows.left : parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		contentWidth: tabRow.width
		contentHeight: height
		clip: true
		flickableDirection: Flickable.HorizontalFlick
		boundsBehavior: Flickable.StopAtBounds

		Row {
			id: tabRow
			height: parent.height
			spacing: Kirigami.Units.smallSpacing

		// ── Tab buttons ──────────────────────────────────────────────────────
		Repeater {
			id: tabRepeater
			model: tabBar.tabs

			Item {
				id: tabDelegate

				readonly property bool isActive: tabBar.activeTab === index
				property bool isEditing: false

				width: Math.max(Kirigami.Units.gridUnit * 4.5, tabLabelText.implicitWidth + (tabIconItem.visible ? tabIconItem.width + Kirigami.Units.smallSpacing : 0) + Kirigami.Units.gridUnit * 2)
				height: tabFlickable.height

				readonly property string tabIcon: modelData.icon || ""

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
						// Auto-assign icon based on the new name
						var inferred = tabBar.inferIconForName(trimmed)
						if (inferred) {
							tabBar.tabIconChanged(index, inferred)
						}
					}
					tabDelegate.isEditing = false
				}

				// ── Background (hover highlight) ────────────────────────────
				Rectangle {
					anchors.fill: parent
					anchors.margins: Math.round(Kirigami.Units.smallSpacing / 2)
					radius: Kirigami.Units.smallSpacing
					color: Kirigami.Theme.highlightColor
					opacity: hoverArea.containsMouse && !tabDelegate.isActive ? 0.15 : 0
					Behavior on opacity { NumberAnimation { duration: 100 } }
				}

				// ── Active tab bottom indicator (text-width underline) ──────
				Rectangle {
					anchors.left: tabLabelRow.left
					anchors.right: tabLabelRow.right
					anchors.bottom: parent.bottom
					height: 2
					color: Kirigami.Theme.highlightColor
					visible: tabDelegate.isActive && !tabDelegate.isEditing
				}

				// ── Label (read-only) with icon ──────────────────────────────
				Row {
					id: tabLabelRow
					anchors.fill: parent
					anchors.leftMargin: Kirigami.Units.largeSpacing
					anchors.rightMargin: Kirigami.Units.largeSpacing
					spacing: Kirigami.Units.smallSpacing
					visible: !tabDelegate.isEditing
					opacity: (tabBar._dragSourceIndex === index) ? 0.3
						: tabDelegate.isActive ? 1.0
						: hoverArea.containsMouse ? 0.85 : 0.6
					Behavior on opacity { NumberAnimation { duration: 100 } }

					Kirigami.Icon {
						id: tabIconItem
						visible: tabDelegate.tabIcon !== ""
						source: tabDelegate.tabIcon
						width: visible ? tabLabelText.font.pixelSize : 0
						height: width
						anchors.verticalCenter: parent.verticalCenter
						color: Kirigami.Theme.textColor
					}

					QQC2.Label {
						id: tabLabelText
						width: parent.width - (tabIconItem.visible ? tabIconItem.width + parent.spacing : 0)
						height: parent.height
						verticalAlignment: Text.AlignVCenter
						font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.3)
						text: modelData.name || ""
						color: Kirigami.Theme.textColor
						elide: Text.ElideRight
					}
				}

				// ── Edit input ───────────────────────────────────────────────
				TextInput {
					id: tabInput
					anchors.fill: parent
					anchors.leftMargin: Kirigami.Units.largeSpacing
					anchors.rightMargin: Kirigami.Units.largeSpacing
					verticalAlignment: TextInput.AlignVCenter
					font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.3)
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
					acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
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

		// ── "+" Add Tab button ───────────────────────────────────────────────
		Item {
			id: addTabBtn
			width: tabBar.tabHeight
			height: tabFlickable.height

			// No background fill – flat style
			Item { anchors.fill: parent }

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
	}

	// ── Scroll arrow controls ────────────────────────────────────────────────
	Row {
		id: scrollArrows
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		visible: tabBar._canScroll
		spacing: 0

		Rectangle {
			width: 1
			height: parent.height
			color: Kirigami.Theme.textColor
			opacity: 0.12
		}

		Item {
			width: Kirigami.Units.gridUnit * 1.5
			height: parent.height
			Kirigami.Icon {
				anchors.centerIn: parent
				width: Kirigami.Units.iconSizes.small
				height: width
				source: "go-previous"
				color: Kirigami.Theme.textColor
				opacity: scrollBackMA.containsMouse ? 0.9 : (tabFlickable.contentX > 0 ? 0.55 : 0.2)
			}
			MouseArea {
				id: scrollBackMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					tabFlickable.contentX = Math.max(0,
						tabFlickable.contentX - tabFlickable.width * 0.6)
				}
			}
		}

		Item {
			width: Kirigami.Units.gridUnit * 1.5
			height: parent.height
			Kirigami.Icon {
				anchors.centerIn: parent
				width: Kirigami.Units.iconSizes.small
				height: width
				source: "go-next"
				color: Kirigami.Theme.textColor
				opacity: scrollFwdMA.containsMouse ? 0.9 : (tabFlickable.contentX < tabFlickable.contentWidth - tabFlickable.width ? 0.55 : 0.2)
			}
			MouseArea {
				id: scrollFwdMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					tabFlickable.contentX = Math.min(
						tabFlickable.contentWidth - tabFlickable.width,
						tabFlickable.contentX + tabFlickable.width * 0.6)
				}
			}
		}
	}

	// Translate vertical mouse-wheel into horizontal tab scrolling
	MouseArea {
		anchors.fill: tabFlickable
		acceptedButtons: Qt.NoButton
		onWheel: function(wheel) {
			var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
			if (delta !== 0 && tabFlickable.contentWidth > tabFlickable.width) {
				tabFlickable.contentX = Math.max(0,
					Math.min(tabFlickable.contentWidth - tabFlickable.width,
						tabFlickable.contentX - delta))
			}
		}
	}

	// Auto-scroll so the active tab is always visible
	onActiveTabChanged: {
		var item = tabRepeater.itemAt(activeTab)
		if (!item || !tabFlickable) return
		var itemLeft = item.x
		var itemRight = item.x + item.width
		if (itemLeft < tabFlickable.contentX)
			tabFlickable.contentX = itemLeft
		else if (itemRight > tabFlickable.contentX + tabFlickable.width)
			tabFlickable.contentX = itemRight - tabFlickable.width
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
