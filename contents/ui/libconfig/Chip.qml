import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Small outlined note placed next to a control, e.g. "Classic layout only".
Rectangle {
	id: chip

	property alias text: chipLabel.text

	implicitWidth: chipLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
	implicitHeight: chipLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
	radius: height / 2
	color: "transparent"
	border.width: 1
	border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)

	QQC2.Label {
		id: chipLabel
		anchors.centerIn: parent
		font: Kirigami.Theme.smallFont
		opacity: 0.8
	}
}
