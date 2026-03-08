// Version 3

import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
	id: simpleKCM
	default property alias _formChildren: formLayout.data

	// Force Window color scheme instead of inheriting Plasma theme colors
	// This ensures controls look correct in light mode when Plasma theme is dark
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	Kirigami.FormLayout {
		id: formLayout
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.rightMargin: Kirigami.Units.gridUnit
	}

	// Historically we forced a large minimum width to keep FormLayout in wideMode.
	// On Plasma 6 (especially with fractional scaling), that results in a config
	// window that's disproportionately wide with lots of empty horizontal space.
	//
	// Use Kirigami grid units (already DPI-aware) and align with Plasma defaults.
	// https://invent.kde.org/plasma/plasma-desktop/-/blob/master/desktoppackage/contents/configuration/AppletConfiguration.qml
	// - implicitWidth: Kirigami.Units.gridUnit * 40
	// - minimumWidth:  Kirigami.Units.gridUnit * 30
	property int wideModeMinWidth: Kirigami.Units.gridUnit * 30
	property int preferredWindowWidth: Kirigami.Units.gridUnit * 40

	function _applyWindowWidthConstraints() {
		if (!Window.window || !Window.window.visible) {
			return
		}
		// Keep the dialog reasonably sized on open.
		// Still lets the user manually resize after it becomes visible.
		if (Window.window.width < wideModeMinWidth) {
			Window.window.width = wideModeMinWidth
		} else if (Window.window.width > preferredWindowWidth) {
			Window.window.width = preferredWindowWidth
		}
	}
	Window.onWindowChanged: {
		if (Window.window) {
			Window.window.visibleChanged.connect(function(){
				// Defer the clamp: the configuration window often applies its own
				// initial size during show; clamping too early gets overridden.
				if (typeof simpleKCM !== 'undefined' && simpleKCM && typeof simpleKCM._applyWindowWidthConstraints === 'function') {
					simpleKCM._applyWindowWidthConstraints()
					Qt.callLater(function() {
						simpleKCM._applyWindowWidthConstraints()
					})
				}
			})
		}
	}
}
