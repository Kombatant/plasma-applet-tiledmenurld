// Version 4

import QtQuick
import org.kde.kirigami as Kirigami

Item {
	id: formPage
	default property alias _formChildren: formLayout.data
	property alias wideMode: formLayout.wideMode
	implicitWidth: formLayout.implicitWidth
	implicitHeight: formLayout.implicitHeight

	// Force Window color scheme instead of inheriting Plasma theme colors
	// This ensures controls look correct in light mode when Plasma theme is dark
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	Kirigami.FormLayout {
		id: formLayout
		anchors.fill: parent
		anchors.rightMargin: Kirigami.Units.gridUnit
	}

	function _alignInternalFormLayout() {
		const internalLayout = formLayout.children.length > 0 ? formLayout.children[0] : null
		if (!internalLayout || !internalLayout.anchors) {
			return
		}

		// Kirigami.FormLayout narrows to its implicit width and centers itself
		// when wideMode is false. That makes sparse settings pages look centered
		// instead of following the left edge used by denser pages such as General.
		internalLayout.anchors.horizontalCenter = undefined
		internalLayout.anchors.left = Qt.binding(function() {
			return formLayout.left
		})
		internalLayout.width = Qt.binding(function() {
			return formLayout.wideMode ? formLayout.implicitWidth : formLayout.width
		})
	}

	Component.onCompleted: {
		Qt.callLater(formPage._alignInternalFormLayout)
	}
}
