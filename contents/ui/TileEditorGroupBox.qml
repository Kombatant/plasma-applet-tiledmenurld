import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3

// https://invent.kde.org/frameworks/plasma-framework/-/blame/master/src/declarativeimports/plasmacomponents3/GroupBox.qml
PlasmaComponents3.GroupBox {
	id: control
	property bool checkable: false
	property bool checked: false
	property alias labelExtras: labelExtras.data
	readonly property bool hasLabelExtras: labelExtras.children.length > 0

	label: RowLayout {
		x: control.leftPadding
		y: control.topInset
		width: control.availableWidth

		Loader {
			id: checkBoxLoader
			active: control.checkable
			sourceComponent: PlasmaComponents3.CheckBox {
				id: checkBox
				Layout.fillWidth: !control.hasLabelExtras
				enabled: control.enabled
				text: control.title
				checked: control.checked
				onCheckedChanged: control.checked = checked
			}
		}
		RowLayout {
			id: labelExtras
			spacing: 6
			visible: control.hasLabelExtras
		}
		PlasmaComponents3.Label {
			Layout.fillWidth: true
			enabled: control.enabled
			visible: !control.checkable

			text: control.title
			font: control.font
			elide: Text.ElideRight
			horizontalAlignment: Text.AlignLeft
			verticalAlignment: Text.AlignVCenter
		}
	}
}
