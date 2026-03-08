import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ScrollView {
	id: appsView
	property alias listView: appsListView
	background: Item {} // Remove the default ScrollView frame border

	// The horizontal ScrollBar always appears in QQC2 for some reason.
	// The PC3 is drawn as if it thinks the scrollWidth is 0, which is
	// possible since it inits at width=350px, then changes to 0px until
	// the popup is opened before it returns to 350px.
	QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

	// Custom vertical scrollbar: transparent track (no groove line) with a
	// themed handle so the scrollbar remains visible.
	QQC2.ScrollBar.vertical: QQC2.ScrollBar {
		parent: appsView
		anchors.top: appsView.top
		anchors.bottom: appsView.bottom
		anchors.right: appsView.right
		implicitWidth: 6
		width: 6
		padding: 0
		policy: QQC2.ScrollBar.AsNeeded
		background: Item { implicitWidth: 6 }
		contentItem: Rectangle {
			implicitWidth: 4
			width: 4
			radius: width / 2
			color: Kirigami.Theme.textColor
			opacity: parent.pressed ? 0.6 : parent.hovered ? 0.4 : 0.25
			Behavior on opacity { NumberAnimation { duration: 120 } }
		}
	}

	KickerListView {
		id: appsListView

		section.property: 'sectionKey'
		// section.criteria: ViewSection.FirstCharacter

		model: appsModel.allAppsModel // Should be populated by the time this is created

		section.delegate: KickerSectionHeader {
			enableJumpToSection: true
		}

		delegate: MenuListItem {
			secondRowVisible: config.appDescriptionBelow
			description: config.appDescriptionVisible ? modelDescription : ''
		}

		iconSize: config.appListIconSize
		showItemUrl: false
	}

	function scrollToTop() {
		appsListView.positionViewAtBeginning()
	}

	function jumpToSection(section) {
		for (var i = 0; i < appsListView.model.count; i++) {
			var app = appsListView.model.get(i)
			if (section == app.sectionKey) {
				appsListView.currentIndex = i
				appsListView.positionViewAtIndex(i, ListView.Beginning)
				break
			}
		}
	}
}
