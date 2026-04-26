import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami

QQC2.ScrollView {
	id: appsView
	property alias listView: appsListView
	property var pendingRecentAppsClearAction: null
	property bool canClearRecentApps: false
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
			actionButtonVisible: section == appsModel.recentAppsSectionKey
			actionButtonEnabled: appsView.canClearRecentApps
			actionButtonText: i18n("Clear")
			actionButtonHandler: function() {
				appsView.confirmClearRecentApps()
			}
		}

		delegate: MenuListItem {
			secondRowVisible: config.appDescriptionBelow
			description: config.appDescriptionVisible ? modelDescription : ''
		}

		iconSize: config.appListIconSize
		showItemUrl: false
	}

	Connections {
		target: appsListView.model
		ignoreUnknownSignals: true
		function onRefreshed() {
			appsView.updateRecentAppsActionState()
		}
	}

	function isForgetAllRecentAppsAction(actionItem) {
		if (!actionItem) {
			return false
		}
		var id = actionItem.actionId ? ("" + actionItem.actionId).toLowerCase() : ""
		if (id.indexOf("forget") >= 0 && id.indexOf("all") >= 0) {
			return true
		}
		var text = actionItem.text ? ("" + actionItem.text).toLowerCase() : ""
		return text.indexOf("forget all") >= 0
	}

	function findClearRecentAppsAction() {
		var model = appsListView.model
		if (!model || typeof model.count !== "number"
				|| typeof model.get !== "function"
				|| typeof model.getActionList !== "function"
				|| typeof model.triggerIndexAction !== "function") {
			return null
		}

		for (var i = 0; i < model.count; i++) {
			var item = model.get(i)
			if (!item || item.sectionKey !== appsModel.recentAppsSectionKey) {
				continue
			}

			var actionList = []
			try {
				actionList = model.getActionList(i)
			} catch (e) {
				actionList = []
			}

			if (!actionList || typeof actionList.length !== "number") {
				continue
			}

			for (var ai = 0; ai < actionList.length; ai++) {
				var actionItem = actionList[ai]
				if (!appsView.isForgetAllRecentAppsAction(actionItem)) {
					continue
				}
				return {
					index: i,
					actionId: actionItem.actionId,
					actionArgument: actionItem.actionArgument,
					text: actionItem.text || "",
				}
			}
		}

		return null
	}

	function updateRecentAppsActionState() {
		canClearRecentApps = !!findClearRecentAppsAction()
	}

	function confirmClearRecentApps() {
		pendingRecentAppsClearAction = findClearRecentAppsAction()
		if (!pendingRecentAppsClearAction) {
			canClearRecentApps = false
			return
		}
		clearRecentAppsDialog.open()
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

	Component.onCompleted: updateRecentAppsActionState()
	onVisibleChanged: {
		if (visible) {
			updateRecentAppsActionState()
		}
	}

	QtDialogs.MessageDialog {
		id: clearRecentAppsDialog
		title: i18n("Clear Recent Apps")
		text: i18n("Forget all recent applications?")
		buttons: QtDialogs.MessageDialog.Yes | QtDialogs.MessageDialog.No
		onButtonClicked: function(button, role) {
			if (button === QtDialogs.MessageDialog.Yes && appsView.pendingRecentAppsClearAction) {
				appsListView.model.triggerIndexAction(
					appsView.pendingRecentAppsClearAction.index,
					appsView.pendingRecentAppsClearAction.actionId,
					appsView.pendingRecentAppsClearAction.actionArgument
				)
			}
			appsView.pendingRecentAppsClearAction = null
			Qt.callLater(appsView.updateRecentAppsActionState)
		}
	}
}
