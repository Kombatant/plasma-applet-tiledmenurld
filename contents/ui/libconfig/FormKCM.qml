// Version 5

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
	id: formPage
	default property alias _formChildren: formLayout.data
	property alias wideMode: formLayout.wideMode
	readonly property int uniformComboBoxWidth: Kirigami.Units.gridUnit * 12
	readonly property int uniformSpinBoxWidth: Kirigami.Units.gridUnit * 7
	implicitWidth: formLayout.implicitWidth
	implicitHeight: formLayout.implicitHeight

	// Force Window color scheme instead of inheriting Plasma theme colors
	// This ensures controls look correct in light mode when Plasma theme is dark
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	QQC2.ScrollView {
		id: scrollView
		anchors.fill: parent
		clip: true

		Item {
			width: scrollView.availableWidth
			implicitHeight: formLayout.implicitHeight + formLayout.anchors.topMargin * 2

			Kirigami.FormLayout {
				id: formLayout
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.leftMargin: Kirigami.Units.gridUnit * 2
				anchors.topMargin: Kirigami.Units.largeSpacing
				anchors.rightMargin: Kirigami.Units.gridUnit
			}
		}
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
