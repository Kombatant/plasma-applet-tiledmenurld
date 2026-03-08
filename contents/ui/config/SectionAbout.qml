import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCM

// Based on Plasma's built-in AboutPlugin.qml, but embedded into our settings shell.
KCM.SimpleKCM {
	id: page
	title: i18n("About")

	// Force Window color scheme instead of inheriting Plasma theme colors
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	readonly property var metaData: Plasmoid.metaData

	Component {
		id: personDelegate
		RowLayout {
			height: implicitHeight + (Kirigami.Units.smallSpacing * 2)
			spacing: Kirigami.Units.smallSpacing * 2
			Kirigami.Icon {
				width: Kirigami.Units.iconSizes.smallMedium
				height: width
				source: "user"
			}
			QQC2.Label {
				text: modelData.name
				textFormat: Text.PlainText
			}
			Row {
				spacing: 0
				QQC2.ToolButton {
					visible: modelData.emailAddress
					width: height
					icon.name: "mail-sent"
					display: QQC2.AbstractButton.IconOnly
					text: i18nd("plasma_shell_org.kde.plasma.desktop", "Send an email to %1", modelData.emailAddress)
					QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
					QQC2.ToolTip.visible: hovered
					QQC2.ToolTip.text: text
					onClicked: Qt.openUrlExternally("mailto:%1".arg(modelData.emailAddress))
				}
				QQC2.ToolButton {
					visible: modelData.webAddress
					width: height
					icon.name: "globe"
					display: QQC2.AbstractButton.IconOnly
					text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:tooltip %1 url", "Open website %1", modelData.webAddress)
					QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
					QQC2.ToolTip.visible: hovered
					QQC2.ToolTip.text: modelData.webAddress
					onClicked: Qt.openUrlExternally(modelData.webAddress)
				}
			}
		}
	}

	Component {
		id: licenseComponent
		Kirigami.OverlaySheet {
			property alias text: licenseLabel.text
			onClosed: destroy()
			Kirigami.SelectableLabel {
				id: licenseLabel
				implicitWidth: Math.max(Kirigami.Units.gridUnit * 25, Math.round(page.width / 2), contentWidth)
				wrapMode: Text.WordWrap
			}
			Component.onCompleted: open()
		}
	}

	Item {
		anchors.fill: parent

		ColumnLayout {
			id: column
			anchors {
				left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
				leftMargin: Kirigami.Units.largeSpacing; rightMargin: Kirigami.Units.largeSpacing; topMargin: Kirigami.Units.largeSpacing; bottomMargin: Kirigami.Units.largeSpacing
			}
			width: Math.max(0, parent.width - (Kirigami.Units.largeSpacing * 2))
			spacing: Kirigami.Units.largeSpacing

			GridLayout {
				columns: 2
				Layout.fillWidth: true
				columnSpacing: Kirigami.Units.largeSpacing
				rowSpacing: Kirigami.Units.smallSpacing

				Kirigami.Icon {
					Layout.rowSpan: 2
					Layout.preferredHeight: Kirigami.Units.iconSizes.huge
					Layout.preferredWidth: height
					Layout.maximumWidth: page.width / 3
					Layout.rightMargin: Kirigami.Units.largeSpacing
					source: page.metaData.iconName || page.metaData.pluginId
					fallback: "application-x-plasma"
				}

				Kirigami.Heading {
					Layout.fillWidth: true
					text: page.metaData.name + " " + page.metaData.version
					textFormat: Text.PlainText
				}

				Kirigami.Heading {
					Layout.fillWidth: true
					Layout.maximumWidth: Kirigami.Units.gridUnit * 18
					level: 2
					wrapMode: Text.WordWrap
					text: page.metaData.description
					textFormat: Text.PlainText
				}
			}

			Kirigami.Separator {
				Layout.fillWidth: true
				Layout.topMargin: Kirigami.Units.smallSpacing
			}

			Kirigami.Heading {
				text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@title:group", "Website")
				textFormat: Text.PlainText
				visible: page.metaData.website && page.metaData.website.length > 0
			}
			Kirigami.UrlButton {
				Layout.leftMargin: Kirigami.Units.smallSpacing
				url: page.metaData.website
				visible: url.length > 0
			}

			Kirigami.Heading {
				text: i18nd("plasma_shell_org.kde.plasma.desktop", "Copyright")
				textFormat: Text.PlainText
				visible: (page.metaData.copyrightText && page.metaData.copyrightText.length > 0) || (page.metaData.license && page.metaData.license.length > 0)
			}

			ColumnLayout {
				Layout.leftMargin: Kirigami.Units.smallSpacing
				spacing: Kirigami.Units.smallSpacing

				QQC2.Label {
					text: page.metaData.copyrightText
					textFormat: Text.PlainText
					visible: text.length > 0
					wrapMode: Text.WordWrap
				}

				RowLayout {
					spacing: Kirigami.Units.smallSpacing
					visible: page.metaData.license && page.metaData.license.length > 0
					QQC2.Label {
						text: i18nd("plasma_shell_org.kde.plasma.desktop", "License:")
						textFormat: Text.PlainText
					}
					Kirigami.LinkButton {
						text: page.metaData.license
						Accessible.description: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:whatsthis", "View license text")
						onClicked: {
							licenseComponent.incubateObject(page.Window.window.contentItem, {
								"text": page.metaData.licenseText,
								"title": page.metaData.license,
							}, Qt.Asynchronous)
						}
					}
				}
			}

			Kirigami.Heading {
				Layout.topMargin: Kirigami.Units.smallSpacing
				text: i18nd("plasma_shell_org.kde.plasma.desktop", "Authors")
				textFormat: Text.PlainText
				visible: page.metaData.authors && page.metaData.authors.length > 0
			}
			Repeater {
				Layout.leftMargin: Kirigami.Units.smallSpacing
				model: page.metaData.authors
				delegate: personDelegate
			}

			Kirigami.Heading {
				Layout.topMargin: Kirigami.Units.smallSpacing
				text: i18nd("plasma_shell_org.kde.plasma.desktop", "Credits")
				textFormat: Text.PlainText
				visible: page.metaData.otherContributors && page.metaData.otherContributors.length > 0
			}
			Repeater {
				Layout.leftMargin: Kirigami.Units.smallSpacing
				model: page.metaData.otherContributors
				delegate: personDelegate
			}

			Kirigami.Heading {
				Layout.topMargin: Kirigami.Units.smallSpacing
				text: i18nd("plasma_shell_org.kde.plasma.desktop", "Translators")
				textFormat: Text.PlainText
				visible: page.metaData.translators && page.metaData.translators.length > 0
			}
			Repeater {
				Layout.leftMargin: Kirigami.Units.smallSpacing
				model: page.metaData.translators
				delegate: personDelegate
			}

			QQC2.Button {
				Layout.alignment: Qt.AlignHCenter
				icon.name: "tools-report-bug"
				text: i18nd("plasma_shell_org.kde.plasma.desktop", "Report a Bug…")
				visible: page.metaData.bugReportUrl && page.metaData.bugReportUrl.length > 0
				onClicked: Qt.openUrlExternally(page.metaData.bugReportUrl)
			}

			Item { Layout.fillHeight: true }
		}
	}
}
