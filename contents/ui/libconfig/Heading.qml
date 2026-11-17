// Version 7

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/*
** Example:
**
import './libconfig' as LibConfig
LibConfig.Heading {
	text: i18n("Panel icon")
}
*/

// Section heading for a settings form: a small bold title with a rule under
// it, spanning both the label and the control column.
//
// Kirigami's own section header (FormData.isSection with a label) is centred
// and has no rule, so the label is left empty and the heading drawn here.
ColumnLayout {
	id: heading
	spacing: Kirigami.Units.smallSpacing

	property string text: ""
	property alias separator: separator
	property alias label: label
	property bool useThickTopMargin: true

	Kirigami.FormData.isSection: true
	Layout.fillWidth: true

	Kirigami.Heading {
		id: label
		Layout.topMargin: heading.useThickTopMargin ? Kirigami.Units.largeSpacing : 0
		Layout.fillWidth: true
		text: heading.text
		level: 4
		font.weight: Font.DemiBold
		elide: Text.ElideRight
	}

	Kirigami.Separator {
		id: separator
		Layout.fillWidth: true
		Layout.bottomMargin: Kirigami.Units.smallSpacing
	}
}
