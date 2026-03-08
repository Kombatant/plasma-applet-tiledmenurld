import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kquickcontrols as KQuickControls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
	id: page
	anchors.fill: parent

	// Force Window color scheme instead of inheriting Plasma theme colors
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	// The parent ConfigMain.qml owns save/apply behavior and persists to Plasmoid.globalShortcut.
	// We only edit the pending value.
	property alias pendingShortcut: keySequenceItem.keySequence

	QQC2.ScrollView {
		id: scrollView
		anchors.fill: parent
		clip: true

		ColumnLayout {
			// Bind to the viewport width so long labels wrap instead of expanding
			// the content width and causing a horizontal scrollbar.
			width: scrollView.availableWidth
			spacing: Kirigami.Units.largeSpacing

			QQC2.Label {
				Layout.fillWidth: true
				Layout.maximumWidth: scrollView.availableWidth
				text: i18nd("plasma_shell_org.kde.plasma.desktop", "This shortcut will activate the applet as though it had been clicked.")
				wrapMode: Text.WordWrap
			}

			KQuickControls.KeySequenceItem {
				id: keySequenceItem
				keySequence: (page.parent && page.parent._shortcutPending !== undefined)
					? page.parent._shortcutPending
					: Plasmoid.globalShortcut
				modifierOnlyAllowed: true
				onCaptureFinished: {
					// bubble up to ConfigMain so Apply becomes enabled
					var root = page
					while (root && root.parent) {
						root = root.parent
						if (root && typeof root.configurationChanged === "function") {
							break
						}
					}
					if (root && typeof root._shortcutPending !== "undefined") {
						root._shortcutPending = keySequence
					}
					if (root && typeof root.configurationChanged === "function") {
						root.configurationChanged()
					}
				}
			}

			QQC2.Label {
				Layout.fillWidth: true
				Layout.maximumWidth: scrollView.availableWidth
				text: i18n("When this widget has a global shortcut set, like 'Alt+F1', Plasma will open this menu with just the ⊞ Windows / Meta key.")
				wrapMode: Text.WordWrap
			}

			Item { Layout.fillHeight: true }
		}
	}
}
