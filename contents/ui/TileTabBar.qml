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

				// ── Background ───────────────────────────────────────────────
				Rectangle {
					anchors.fill: parent
					anchors.margins: 1
					radius: Kirigami.Units.smallSpacing
					color: {
						if (tabDelegate.isActive) {
							return Kirigami.Theme.highlightColor
						}
						if (hoverArea.containsMouse) {
							return Qt.alpha(Kirigami.Theme.textColor, 0.12)
						}
						return "transparent"
					}
					Behavior on color { ColorAnimation { duration: 100 } }
				}

				// ── Active tab bottom indicator ──────────────────────────────
				Rectangle {
					anchors.left: parent.left
					anchors.right: parent.right
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
					text: modelData.name || ""
					color: tabDelegate.isActive
						? Kirigami.Theme.highlightedTextColor
						: Kirigami.Theme.textColor
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
					color: tabDelegate.isActive
						? Kirigami.Theme.highlightedTextColor
						: Kirigami.Theme.textColor
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

					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton) {
							tabContextMenu.tabIdx = index
							var pos = mapToItem(tabBar, mouse.x, mouse.y)
							tabContextMenu.open(pos.x, pos.y)
						} else if (!tabDelegate.isEditing) {
							tabBar.tabSelected(index)
						}
					}

					onDoubleClicked: tabDelegate.startEditing()
				}
			}
		}

		// ── "+" Add Tab button ───────────────────────────────────────────────
		Item {
			id: addTabBtn
			Layout.preferredWidth: tabBar.tabHeight
			Layout.fillHeight: true

			Rectangle {
				anchors.fill: parent
				anchors.margins: 1
				radius: Kirigami.Units.smallSpacing
				color: addTabMA.containsMouse
					? Qt.alpha(Kirigami.Theme.textColor, 0.12)
					: "transparent"
			}

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
