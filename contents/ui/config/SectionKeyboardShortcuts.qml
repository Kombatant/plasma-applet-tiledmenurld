import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kquickcontrols as KQuickControls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
	id: page
	anchors.fill: parent
	readonly property int pagePadding: Kirigami.Units.largeSpacing

	// Force Window color scheme instead of inheriting Plasma theme colors
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	// Pending shortcut state — persisted on Apply/OK via saveConfig().
	property string _shortcutPending: "" + Plasmoid.globalShortcut

	signal configurationChanged()

	// Plasma's config dialog calls saveConfig() on each page's root item on Apply/OK.
	function saveConfig() {
		if (("" + Plasmoid.globalShortcut) !== ("" + _shortcutPending))
			Plasmoid.globalShortcut = _shortcutPending
	}

	QQC2.ScrollView {
		id: scrollView
		anchors.fill: parent
		clip: true

		Item {
			width: scrollView.availableWidth
			implicitHeight: shortcutsColumn.implicitHeight + (page.pagePadding * 2)

			ColumnLayout {
				id: shortcutsColumn
				// Bind to the viewport width so long labels wrap instead of expanding
				// the content width and causing a horizontal scrollbar.
				x: page.pagePadding
				y: page.pagePadding
				width: Math.max(0, scrollView.availableWidth - (page.pagePadding * 2))
				spacing: Kirigami.Units.largeSpacing

				QQC2.Label {
					Layout.fillWidth: true
					Layout.maximumWidth: scrollView.availableWidth
					text: i18nd("plasma_shell_org.kde.plasma.desktop", "This shortcut will activate the applet as though it had been clicked.")
					wrapMode: Text.WordWrap
				}

				KQuickControls.KeySequenceItem {
					id: keySequenceItem
					keySequence: page._shortcutPending
					modifierOnlyAllowed: true
					onCaptureFinished: {
						page._shortcutPending = keySequence
						page.configurationChanged()
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
}
