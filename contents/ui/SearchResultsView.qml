import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

GridLayout {
	id: searchResultsView
	columns: 1
	rowSpacing: 0
	columnSpacing: 0
	property alias listView: searchResultsList
	property bool filterViewOpen: false
	
	RowLayout {
		id: searchFiltersRow
		Layout.row: searchView.searchOnTop ? 2 : 0
		Layout.preferredHeight: config.searchFilterRowHeight - 1 // -1px is for the underline seperator
		Layout.fillWidth: true
		property int filterIconSize: Math.floor(Math.min(Layout.preferredHeight * 0.6, config.flatButtonIconSize))
		property int filterPadding: Math.max(0, (Layout.preferredHeight - filterIconSize) / 2)

		FlatButton {
			icon.name: "system-search-symbolic"
			Layout.preferredHeight: parent.Layout.preferredHeight
			Layout.preferredWidth: parent.Layout.preferredHeight
			icon.width: searchFiltersRow.filterIconSize
			icon.height: searchFiltersRow.filterIconSize
			QQC2.ToolTip.text: i18n("All results")
			QQC2.ToolTip.visible: hovered
			onClicked: search.applyDefaultFilters()
			checked: search.isDefaultFilter
			checkedEdge: searchView.searchOnTop ?  Qt.TopEdge : Qt.BottomEdge
		}
		FlatButton {
			icon.name: "window"
			Layout.preferredHeight: parent.Layout.preferredHeight
			Layout.preferredWidth: parent.Layout.preferredHeight
			icon.width: searchFiltersRow.filterIconSize
			icon.height: searchFiltersRow.filterIconSize
			QQC2.ToolTip.text: i18n("Applications only")
			QQC2.ToolTip.visible: hovered
			onClicked: search.filters = ['krunner_services']
			checked: search.isAppsFilter
			checkedEdge: searchView.searchOnTop ?  Qt.TopEdge : Qt.BottomEdge
		}
		FlatButton {
			icon.name: "document-new"
			Layout.preferredHeight: parent.Layout.preferredHeight
			Layout.preferredWidth: parent.Layout.preferredHeight
			icon.width: searchFiltersRow.filterIconSize
			icon.height: searchFiltersRow.filterIconSize
			QQC2.ToolTip.text: i18n("Files only")
			QQC2.ToolTip.visible: hovered
			onClicked: search.filters = ['baloosearch']
			checked: search.isFileFilter
			checkedEdge: searchView.searchOnTop ?  Qt.TopEdge : Qt.BottomEdge
		}

		Item { Layout.fillWidth: true }

		FlatButton {
			id: moreFiltersButton
			Layout.preferredHeight: parent.Layout.preferredHeight
			Layout.preferredWidth: moreFiltersButtonRow.implicitWidth + padding*2
			padding: searchFiltersRow.filterPadding
			// enabled: false

			RowLayout {
				id: moreFiltersButtonRow
				anchors.centerIn: parent
				anchors.margins: parent.padding
				
				PlasmaComponents3.Label {
					id: moreFiltersButtonLabel
					text: i18n("Filters")
				}
				Kirigami.Icon {
					source: "usermenu-down"
					rotation: searchResultsView.filterViewOpen ? 180 : 0
					Layout.preferredHeight: searchFiltersRow.filterIconSize
					Layout.preferredWidth: searchFiltersRow.filterIconSize

					Behavior on rotation {
						NumberAnimation { duration: Kirigami.Units.longDuration }
					}
				}
			}

			onClicked: searchResultsView.filterViewOpen = !searchResultsView.filterViewOpen
		}
	}

	Rectangle {
		Layout.row: 1
		Layout.fillWidth: true
		Layout.preferredHeight: 1
		color: "#111"
	}

	QQC2.StackView {
		id: searchResultsViewStackView
		Layout.row: searchView.searchOnTop ? 0 : 2
		Layout.fillWidth: true
		Layout.fillHeight: true
		clip: true
		initialItem: searchResultsListScrollView

		Connections {
			target: searchResultsView
			function onFilterViewOpenChanged() {
				if (searchResultsView.filterViewOpen) {
					searchResultsViewStackView.push(searchFiltersViewScrollView)
				} else {
					searchResultsViewStackView.pop()
				}
			}
		}

		QQC2.ScrollView {
			id: searchResultsListScrollView
			visible: false
			background: Item {}
			QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
			QQC2.ScrollBar.vertical: QQC2.ScrollBar {
				parent: searchResultsListScrollView
				anchors.top: searchResultsListScrollView.top
				anchors.bottom: searchResultsListScrollView.bottom
				anchors.right: searchResultsListScrollView.right
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

			SearchResultsList {
				id: searchResultsList
			}
		}

		QQC2.ScrollView {
			id: searchFiltersViewScrollView
			visible: false
			background: Item {}
			QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
			QQC2.ScrollBar.vertical: QQC2.ScrollBar {
				parent: searchFiltersViewScrollView
				anchors.top: searchFiltersViewScrollView.top
				anchors.bottom: searchFiltersViewScrollView.bottom
				anchors.right: searchFiltersViewScrollView.right
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

			SearchFiltersView {
				id: searchFiltersView
			}
		}
		
	}
}
