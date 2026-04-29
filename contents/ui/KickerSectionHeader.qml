import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

MouseArea {
	id: sectionDelegate

	width: ListView.view.width
	implicitHeight: listView.iconSize

	property bool enableJumpToSection: false
	property bool collapsible: false
	property bool collapsed: false
	property var collapseToggler: null
	property bool actionButtonVisible: false
	property bool actionButtonEnabled: true
	property string actionButtonText: ""
	property var actionButtonHandler: null
	readonly property bool interactive: enableJumpToSection || collapsible
	cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
	readonly property real trailingSpace: (actionButton.visible ? actionButton.implicitWidth + Kirigami.Units.smallSpacing : 0)
		+ (collapseIndicator.visible ? collapseIndicator.width + Kirigami.Units.smallSpacing : 0)
		+ Kirigami.Units.smallSpacing

	PlasmaComponents3.Label {
		id: sectionHeading
		anchors {
			left: parent.left
			leftMargin: Kirigami.Units.largeSpacing
			verticalCenter:  parent.verticalCenter
		}
		text: {
			if (section == appsModel.recentAppsSectionKey) {
				return appsModel.recentAppsSectionLabel
			} else {
				return section
			}
		}

		// Add 4pt to font. Default 10pt => 14pt
		font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4

		// Use the intrinsic label width so elision cannot collapse the header into the icon-width path.
		property bool centerOverIcon: !actionButton.visible && !collapseIndicator.visible && sectionHeading.implicitWidth <= listView.iconSize
		width: centerOverIcon ? listView.iconSize : Math.max(listView.iconSize, parent.width - anchors.leftMargin - sectionDelegate.trailingSpace)
		horizontalAlignment: centerOverIcon ? Text.AlignHCenter : Text.AlignLeft
		elide: Text.ElideRight
	}

	QQC2.ToolButton {
		id: actionButton
		anchors {
			right: collapseIndicator.visible ? collapseIndicator.left : parent.right
			rightMargin: Kirigami.Units.largeSpacing
			verticalCenter: parent.verticalCenter
		}
		visible: sectionDelegate.actionButtonVisible
		enabled: sectionDelegate.actionButtonEnabled
		text: sectionDelegate.actionButtonText
		display: QQC2.AbstractButton.TextOnly
		autoRepeat: false
		leftPadding: Kirigami.Units.smallSpacing * 1.5
		rightPadding: Kirigami.Units.smallSpacing * 1.5
		topPadding: Math.max(2, Math.round(Kirigami.Units.smallSpacing * 0.4))
		bottomPadding: topPadding
		implicitHeight: Math.max(sectionHeading.implicitHeight, Math.round(Kirigami.Units.gridUnit * 1.2))
		font.pointSize: Math.max(1, Kirigami.Theme.defaultFont.pointSize - 1)

		background: Rectangle {
			radius: height / 2
			color: !actionButton.enabled
				? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
				: actionButton.down
					? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.32)
					: actionButton.hovered
						? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22)
						: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.16)
			border.width: 1
			border.color: !actionButton.enabled
				? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
				: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, actionButton.hovered ? 0.45 : 0.32)
		}

		contentItem: Text {
			text: actionButton.text
			font: actionButton.font
			color: actionButton.enabled ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			elide: Text.ElideRight
		}
		onClicked: {
			if (typeof sectionDelegate.actionButtonHandler === "function") {
				sectionDelegate.actionButtonHandler()
			}
		}
	}

	Kirigami.Icon {
		id: collapseIndicator
		anchors {
			right: parent.right
			rightMargin: Kirigami.Units.largeSpacing
			verticalCenter: parent.verticalCenter
		}
		visible: sectionDelegate.collapsible
		width: Math.max(Kirigami.Units.iconSizes.small, listView.iconSize * 0.5)
		height: width
		source: "usermenu-down"
		rotation: sectionDelegate.collapsed ? -90 : 0

		Behavior on rotation {
			NumberAnimation { duration: Kirigami.Units.shortDuration }
		}
	}

	AccentHighlight {
		anchors.fill: parent
		anchors.leftMargin: 0
		anchors.rightMargin: 0
		visible: sectionDelegate.interactive && sectionDelegate.containsMouse
		radius: config.tileCornerRadius
		borderOpacity: 0.9
		glowOpacity: 0.5
		fillStrength: 0.7
		innerRimOpacity: 0
	}

	hoverEnabled: true
	onClicked: {
		if (collapsible && typeof collapseToggler === "function") {
			collapseToggler()
		} else if (enableJumpToSection) {
			if (appsModel.order == "alphabetical") {
				jumpToLetterView.show()
			} else { // appsModel.order = "categories"
				jumpToLetterView.show()
			}
		}
	}
}
