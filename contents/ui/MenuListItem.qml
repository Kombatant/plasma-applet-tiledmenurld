import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.draganddrop as DragAndDrop
import org.kde.kquickcontrolsaddons as KQuickControlsAddons
import "Utils.js" as Utils


AppToolButton {
	id: itemDelegate
	preventStealing: true
	showHoverOutline: false

	KQuickControlsAddons.Clipboard {
		id: clipboard
	}

	width: ListView.view.width
	implicitHeight: row.implicitHeight

	property var parentModel: typeof modelList !== "undefined" && modelList[index] ? modelList[index].parentModel : undefined
	property string modelDescription: model.name == model.description ? '' : model.description // Ignore the Comment if it's the same as the Name.
	property string description: model.url ? modelDescription : '' // 
	property bool isDesktopFile: !!(model.url && endsWith(model.url, '.desktop'))
	property bool showItemUrl: listView.showItemUrl && (!isDesktopFile || listView.showDesktopFileUrl)
	property string secondRowText: showItemUrl && model.url ? model.url : modelDescription
	property bool secondRowVisible: secondRowText
	property bool hoverScrollDescriptions: !showItemUrl
	property int hoverScrollPixelsPerSecond: 45
	property string launcherUrl: model.favoriteId || model.url
	property string iconName: model.iconName || ''
	property alias iconSource: itemIcon.source
	property int iconSize: model.largeIcon ? listView.iconSize * 2 : listView.iconSize

	// Tooltip: show full result text (name + description) when hovered
	property string fullResultTooltip: (model && model.name ? model.name : '') + ((model && model.description) ? ('\n' + model.description) : '')
	readonly property string tooltipMainText: (model && model.name) ? ('' + model.name) : ''
	readonly property string tooltipSubText: (model && model.description && model.description !== model.name) ? ('' + model.description) : ''

	AccentHighlight {
		anchors.fill: parent
		anchors.leftMargin: 0
		anchors.rightMargin: 0
		visible: itemDelegate.containsMouse
		radius: config.tileCornerRadius
		borderOpacity: 0.9
		glowOpacity: 0.5
		fillStrength: 0.7
		innerRimOpacity: 0
	}

	// Plasma tooltip follows cursor without stealing hover (avoids flashing).
	// Uses a custom mainItem so long runner replies (e.g. LLM) are fully
	// word-wrapped instead of being truncated by the default tooltip.
	PlasmaCore.ToolTipArea {
		anchors.fill: parent
		active: itemDelegate.containsMouse && (tooltipMainText.length > 0 || tooltipSubText.length > 0)
		// Allow interaction (text selection / scrolling) for long replies.
		interactive: tooltipMainText.length + tooltipSubText.length > 200

		mainItem: Item {
			implicitWidth: tooltipColumn.implicitWidth
			implicitHeight: tooltipColumn.implicitHeight
			width: 400

			ColumnLayout {
				id: tooltipColumn
				anchors.fill: parent
				spacing: Kirigami.Units.smallSpacing

				Kirigami.Heading {
					level: 4
					Layout.fillWidth: true
					Layout.maximumWidth: 400
					text: itemDelegate.tooltipMainText
					wrapMode: Text.Wrap
					visible: text.length > 0
				}

				PlasmaComponents3.Label {
					Layout.fillWidth: true
					Layout.maximumWidth: 400
					text: itemDelegate.tooltipSubText
					wrapMode: Text.Wrap
					visible: text.length > 0
				}
			}
		}
	}

	function endsWith(s, substr) {
		return s.indexOf(substr) == s.length - substr.length
	}

	// We need to look at the js list since ListModel doesn't support item's with non primitive propeties (like an Image).
	property bool modelListPopulated: !!listView.model.list && listView.model.list.length - 1 >= index

	// Drag (based on kicker)
	// https://github.com/KDE/plasma-desktop/blob/4aad3fdf16bc5fd25035d3d59bb6968e06f86ec6/applets/kicker/package/contents/ui/ItemListDelegate.qml#L96
	// https://github.com/KDE/plasma-desktop/blob/master/applets/kicker/plugin/draghelper.cpp
	property int pressX: -1
	property int pressY: -1
	property bool dragEnabled: launcherUrl
	function initDrag(mouse) {
		pressX = mouse.x
		pressY = mouse.y
	}
	function shouldStartDrag(mouse) {
		return dragEnabled
			&& pressX != -1 // Drag initialized?
			&& dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y) // Mouse moved far enough?
	}
	function startDrag() {
		// Note that we fallback from url to favoriteId for "Most Used" apps.
		
		var dragIcon = iconSource
		dragHelper.startDrag(widget, model.url || model.favoriteId, dragIcon, "favoriteId", model.favoriteId)

		resetDragState()
	}
	function resetDragState() {
		pressX = -1
		pressY = -1
	}
	onPressed: function(mouse) {
		//("click menu ", model.iconName)
		if (mouse.buttons & Qt.LeftButton) {
			initDrag(mouse)
		} else if (mouse.buttons & Qt.RightButton) {
			mouse.accepted = true
			resetDragState()
			var targetModel = contextMenuModel()
			// Avoid probing action lists on unsafe models (some runner models can hard-crash plasmashell).
			if (modelSupportsActionLists(targetModel) && targetModel && typeof targetModel.hasActionList === "function") {
				var hasActions = false
				try { hasActions = targetModel.hasActionList(index) } catch (e) { hasActions = false; console.warn('MenuListItem.hasActionList exception', e) }
			}
			contextMenu.open(mouse.x, mouse.y)
		}
	}
	onContainsMouseChanged: function(containsMouse) {
		if (!containsMouse) {
			resetDragState()
		}
	}
	onPositionChanged: function(mouse) {
		if (shouldStartDrag(mouse)) {
			startDrag()
		}
	}

	RowLayout { // ItemListDelegate
		id: row
		anchors.left: parent.left
		anchors.leftMargin: Kirigami.Units.largeSpacing
		anchors.right: parent.right
		anchors.rightMargin: Kirigami.Units.largeSpacing

		Item {
			Layout.fillHeight: true
			implicitHeight: itemIcon.implicitHeight
			implicitWidth: itemIcon.implicitWidth

			Kirigami.Icon {
				id: itemIcon
				anchors.centerIn: parent
				implicitHeight: itemDelegate.iconSize
				implicitWidth: implicitHeight

				animated: true
				source: itemDelegate.iconName || itemDelegate.iconInstance
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignVCenter
			spacing: 0

			RowLayout {
				Layout.fillWidth: true

				Item {
					id: itemLabelClip
					readonly property bool inlineDescriptionVisible: inlineDescriptionLabel.text.length > 0
					Layout.fillWidth: !inlineDescriptionVisible
					Layout.maximumWidth: inlineDescriptionVisible ? itemLabel.implicitWidth : Number.POSITIVE_INFINITY
					implicitWidth: itemLabel.implicitWidth
					implicitHeight: itemLabel.implicitHeight
					clip: true

					readonly property bool scrolling: itemDelegate.containsMouse
						&& itemDelegate.hoverScrollDescriptions
						&& itemLabel.implicitWidth > width
						&& itemLabel.text.length > 0

					PlasmaComponents3.Label {
						id: itemLabel
						x: 0
						width: Math.max(implicitWidth, itemLabelClip.width)
						text: model.name
						maximumLineCount: 1
						elide: itemLabelClip.scrolling ? Text.ElideNone : Text.ElideRight
						height: implicitHeight
					}

					SequentialAnimation {
						running: itemLabelClip.scrolling
						loops: Animation.Infinite

						PauseAnimation { duration: 350 }
						NumberAnimation {
							target: itemLabel
							property: "x"
							to: -(itemLabel.implicitWidth - itemLabelClip.width)
							duration: Math.max(1, Math.round(((itemLabel.implicitWidth - itemLabelClip.width) / itemDelegate.hoverScrollPixelsPerSecond) * 1000))
							easing.type: Easing.Linear
						}
						PauseAnimation { duration: 500 }
					}

					onScrollingChanged: {
						if (!scrolling) {
							itemLabel.x = 0
						}
					}
				}

				Item {
					id: inlineDescriptionClip
					Layout.fillWidth: true
					implicitHeight: inlineDescriptionLabel.implicitHeight
					clip: true

					readonly property bool scrolling: itemDelegate.containsMouse
						&& itemDelegate.hoverScrollDescriptions
						&& inlineDescriptionLabel.implicitWidth > width
						&& inlineDescriptionLabel.text.length > 0

					PlasmaComponents3.Label {
						id: inlineDescriptionLabel
						x: 0
						width: Math.max(implicitWidth, inlineDescriptionClip.width)
						text: !itemDelegate.secondRowVisible ? itemDelegate.description : ''
						color: config.menuItemTextColor2
						maximumLineCount: 1
						elide: inlineDescriptionClip.scrolling ? Text.ElideNone : Text.ElideRight
						height: implicitHeight // ElideRight causes some top padding for some reason
					}

					SequentialAnimation {
						running: inlineDescriptionClip.scrolling
						loops: Animation.Infinite

						PauseAnimation { duration: 350 }
						NumberAnimation {
							target: inlineDescriptionLabel
							property: "x"
							to: -(inlineDescriptionLabel.implicitWidth - inlineDescriptionClip.width)
							duration: Math.max(1, Math.round(((inlineDescriptionLabel.implicitWidth - inlineDescriptionClip.width) / itemDelegate.hoverScrollPixelsPerSecond) * 1000))
							easing.type: Easing.Linear
						}
						PauseAnimation { duration: 500 }
					}

					onScrollingChanged: {
						if (!scrolling) {
							inlineDescriptionLabel.x = 0
						}
					}
				}
			}

			Item {
				id: secondRowClip
				visible: itemDelegate.secondRowVisible
				Layout.fillWidth: true
				implicitHeight: secondRowLabel.implicitHeight
				clip: true

				readonly property bool scrolling: visible
					&& itemDelegate.containsMouse
					&& itemDelegate.hoverScrollDescriptions
					&& secondRowLabel.implicitWidth > width
					&& secondRowLabel.text.length > 0

				PlasmaComponents3.Label {
					id: secondRowLabel
					x: 0
					width: Math.max(implicitWidth, secondRowClip.width)
					text: itemDelegate.secondRowText
					color: config.menuItemTextColor2
					maximumLineCount: 1
					elide: secondRowClip.scrolling ? Text.ElideNone : Text.ElideRight
					height: implicitHeight
				}

				SequentialAnimation {
					running: secondRowClip.scrolling
					loops: Animation.Infinite

					PauseAnimation { duration: 350 }
					NumberAnimation {
						target: secondRowLabel
						property: "x"
						to: -(secondRowLabel.implicitWidth - secondRowClip.width)
						duration: Math.max(1, Math.round(((secondRowLabel.implicitWidth - secondRowClip.width) / itemDelegate.hoverScrollPixelsPerSecond) * 1000))
						easing.type: Easing.Linear
					}
					PauseAnimation { duration: 500 }
				}

				onScrollingChanged: {
					if (!scrolling) {
						secondRowLabel.x = 0
					}
				}
			}
		}

	}

	acceptedButtons: Qt.LeftButton | Qt.RightButton

	onClicked: function(mouse) {
		mouse.accepted = true
		resetDragState()
		if (mouse.button == Qt.LeftButton) {
			trigger()
		}
	}

	function findAllAppsIndexForLauncher(launcherUrl) {
		if (!launcherUrl || !appsModel || !appsModel.allAppsModel || !appsModel.allAppsModel.list) {
			return -1
		}
		var parsed = Utils.parseDropUrl('' + launcherUrl)
		var raw = '' + launcherUrl
		var list = appsModel.allAppsModel.list
		var recentKey = appsModel.recentAppsSectionKey
		// First pass: prefer a match outside the Recent Apps section.
		for (var i = 0; i < list.length; i++) {
			var item = list[i]
			if (!item) {
				continue
			}
			if (item.sectionKey === recentKey) {
				continue
			}
			// Compare against both favoriteId and url; try both raw and parsed forms.
			if (item.favoriteId === parsed || item.url === parsed || item.favoriteId === raw || item.url === raw) {
				return i
			}
		}
		// Fallback: any match.
		for (var j = 0; j < list.length; j++) {
			var itemAny = list[j]
			if (!itemAny) {
				continue
			}
			if (itemAny.favoriteId === parsed || itemAny.url === parsed || itemAny.favoriteId === raw || itemAny.url === raw) {
				return j
			}
		}
		return -1
	}

	function contextMenuModel() {
		return listView && listView.model ? listView.model : null
	}

	function modelSupportsTrigger(model) {
		return model && typeof model.triggerIndex === "function"
	}

	function modelSupportsActionLists(model) {
		if (typeof search !== "undefined" && model === search.results) {
			// Allowlist runners incrementally to avoid crashes.
			// Prefer stable IDs / URL patterns since runnerName can be localized.
			var item = null
			try { item = model.get(index) } catch (e) { item = null }
			var runnerId = item ? (item.runnerId || '') : ''
			var runnerName = item ? (item.runnerName || '') : ''
			var url = item ? (item.url || '') : ''

			var allowByRunnerId = runnerId === 'krunner_services'
			var allowByUrl = (typeof url === 'string') && (
				url.indexOf('applications://') === 0
				|| url.indexOf('applications:') === 0
				|| url.indexOf('systemsettings://') === 0
				|| url.indexOf('systemsettings:') === 0
				|| url.indexOf('settings://') === 0
				|| url.indexOf('kcm:') === 0
				|| url.indexOf('//kcm_') === 0
				|| endsWith(url, '.desktop')
			)
			var allowByRunnerName = runnerName === 'Applications' || runnerName === 'System Settings'

			if (!(allowByRunnerId || allowByUrl || allowByRunnerName)) {
				if (typeof logger !== "undefined" && logger) {
					logger.warn('MenuListItem: skipping action lists for search runner (not allowlisted)', index, runnerId || runnerName || 'no-item')
				}
				console.warn('MenuListItem: skipping action lists for search runner (not allowlisted)', index, runnerId || runnerName || 'no-item')
				return false
			}
		}
		return model
			&& typeof model.hasActionList === "function"
			&& typeof model.getActionList === "function"
			&& typeof model.triggerIndexAction === "function"
	}

	function trigger() {
		var targetModel = contextMenuModel()
		if (modelSupportsTrigger(targetModel)) {
			targetModel.triggerIndex(index)
		} else if (typeof logger !== "undefined" && logger) {
			logger.warn('MenuListItem.trigger: model missing triggerIndex()', targetModel)
		}
	}

	AppContextMenu {
		id: contextMenu
		onPopulateMenu: function(menu) {
			var targetModel = contextMenuModel()
			var isSearchResultsModel = (typeof search !== "undefined" && targetModel === search.results)
			var copyableValueRunnerIds = [
				'calculator',
				'unitconverter',
				'Dictionary',
				'org.kde.datetime',
			]
			var runnerId = (model && typeof model.runnerId !== 'undefined') ? ('' + model.runnerId) : ''
			function _normalizeCopyText(s) {
				if (typeof s === 'undefined' || s === null) {
					return ''
				}
				var t = ('' + s).trim()
				if (!t) {
					return ''
				}
				// Prefer a single line.
				var nl = t.indexOf('\n')
				if (nl >= 0) {
					t = t.substring(0, nl).trim()
				}
				// Collapse whitespace.
				t = t.replace(/\s+/g, ' ').trim()
				return t
			}
			function _extractValuePart(s) {
				var t = _normalizeCopyText(s)
				if (!t) {
					return ''
				}
				// Common patterns for value-like results.
				var splitters = ['=', '→', '=>', '->', ':']
				for (var si = 0; si < splitters.length; si++) {
					var sep = splitters[si]
					var p = t.lastIndexOf(sep)
					if (p >= 0 && p + sep.length < t.length) {
						var rhs = t.substring(p + sep.length).trim()
						if (rhs) {
							return rhs
						}
					}
				}
				return t
			}
			function _hasDigit(s) {
				return /\d/.test(s)
			}
			function _preferValueLike(a, b) {
				var aa = _extractValuePart(a)
				var bb = _extractValuePart(b)
				if (!aa) {
					return bb
				}
				if (!bb) {
					return aa
				}
				// Prefer digit-containing strings when possible.
				var aHas = _hasDigit(aa)
				var bHas = _hasDigit(bb)
				if (aHas && !bHas) {
					return aa
				}
				if (bHas && !aHas) {
					return bb
				}
				// Prefer the shorter one if both look similar.
				if (aa.length !== bb.length) {
					return aa.length < bb.length ? aa : bb
				}
				return aa
			}
			var copyText = ''
			if (model) {
				copyText = _preferValueLike(model.name, model.description)
			}
			var shouldShowCopy = isSearchResultsModel
				&& !!copyText
				&& (copyableValueRunnerIds.indexOf(runnerId) !== -1 || !launcherUrl)
			if (shouldShowCopy) {
				var copyMenuItem = menu.newMenuItem()
				copyMenuItem.text = i18n("Copy")
				copyMenuItem.icon = "edit-copy"
				copyMenuItem.enabled = copyText.length > 0
				copyMenuItem.clicked.connect(function() {
					clipboard.content = copyText
				})
				menu.addMenuItem(copyMenuItem)
			}
			if (launcherUrl && !plasmoid.configuration.tilesLocked) {
				menu.addPinToMenuAction(launcherUrl, {
					label: model.name,
					icon: itemIcon ? itemIcon.source : (model.iconName || model.icon || ""),
					url: model.url || "",
				})
			}

			var isMergedSearch = isSearchResultsModel && search && search.runnerModel && !!search.runnerModel.mergeResults
			var shouldAttemptActions = modelSupportsActionLists(targetModel)
			var isRecentApps = model && appsModel && model.sectionKey === appsModel.recentAppsSectionKey
			var actionList = []
			var allAppsActionList = []
			var allAppsIndex = -1
			if (launcherUrl && appsModel) {
				allAppsIndex = findAllAppsIndexForLauncher(launcherUrl)
			}

			if (isMergedSearch) {
				// When RunnerModel.mergeResults is enabled, the merged runner model can hard-crash plasmashell
				// if we query ActionListRole. For app-like results, resolve actions from the All Apps model instead.
				if (allAppsIndex >= 0 && appsModel.allAppsModel && typeof appsModel.allAppsModel.getActionList === "function") {
					try { actionList = appsModel.allAppsModel.getActionList(allAppsIndex) } catch (e) { actionList = [] }
					if (actionList && typeof actionList.length === "number" && actionList.length > 0) {
						menu.addActionList(actionList, appsModel.allAppsModel, allAppsIndex)
					}
				}
			} else if (shouldAttemptActions) {
				try {
					actionList = targetModel.getActionList(index)
				} catch (e) {
					actionList = []
					if (typeof logger !== "undefined" && logger) {
						logger.warn('MenuListItem: getActionList exception', index, e)
					}
				}
			} else if (targetModel && !isSearchResultsModel && typeof targetModel.getActionList === "function") {
				// Some models may not advertise hasActionList but still return actions; try them defensively (not for search to avoid runner crashes).
				try {
					actionList = targetModel.getActionList(index)
				} catch (e) {
					actionList = []
					if (typeof logger !== "undefined" && logger) {
						logger.warn('MenuListItem: fallback getActionList exception', index, e)
					}
				}
			}

			if (allAppsIndex >= 0 && appsModel && appsModel.allAppsModel && typeof appsModel.allAppsModel.getActionList === "function") {
				try { allAppsActionList = appsModel.allAppsModel.getActionList(allAppsIndex) } catch (e) { allAppsActionList = [] }
			}

			function isForgetAction(actionItem) {
				if (!actionItem) {
					return false
				}
				var id = actionItem.actionId ? ('' + actionItem.actionId).toLowerCase() : ''
				if (id.indexOf('forget') >= 0) {
					return true
				}
				var text = actionItem.text ? ('' + actionItem.text).toLowerCase() : ''
				return text.indexOf('forget') >= 0
			}

			function addActionItem(actionItem, listModel, itemIndex, existingIds) {
				if (!actionItem) {
					return false
				}
				if (actionItem.actionId === 'addToPanel') {
					return false
				}
				if (existingIds && actionItem.actionId && existingIds[actionItem.actionId]) {
					return false
				}
				var menuItem = menu.newMenuItem()
				menuItem.text = actionItem.text ? actionItem.text : ""
				menuItem.enabled = actionItem.type != "title" && ("enabled" in actionItem ? actionItem.enabled : true)
				menuItem.separator = actionItem.type == "separator"
				menuItem.section = actionItem.type == "title"
				menuItem.icon = actionItem.icon ? actionItem.icon : null
				if (actionItem.actionId === 'addToTaskManager') {
					menuItem.text = i18n("Pin to Task Manager")
				}
				;(function(ai) {
					menuItem.clicked.connect(function() {
						listModel.triggerIndexAction(itemIndex, ai.actionId, ai.actionArgument)
					})
				})(actionItem)
				menu.addMenuItem(menuItem)
				if (actionItem.actionId && existingIds) {
					existingIds[actionItem.actionId] = true
				}
				return true
			}

			var addedActions = false
			var existingActionIds = {}
			if (actionList && typeof actionList.length === "number") {
				for (var ai = 0; ai < actionList.length; ai++) {
					var aItem = actionList[ai]
					if (aItem && aItem.actionId) {
						existingActionIds[aItem.actionId] = true
					}
				}
			}

			if (isRecentApps) {
				var hasPrimaryActions = false
				// Add "Add to Desktop" and "Pin to Task Manager" immediately after Pin/Unpin.
				if (allAppsActionList && typeof allAppsActionList.length === "number"
						&& allAppsIndex >= 0 && appsModel.allAppsModel && typeof appsModel.allAppsModel.triggerIndexAction === "function") {
					var pinOrder = ['addToDesktop', 'addToTaskManager']
					for (var po = 0; po < pinOrder.length; po++) {
						for (var pi = 0; pi < allAppsActionList.length; pi++) {
							var pinAction = allAppsActionList[pi]
							if (pinAction && pinAction.actionId === pinOrder[po]) {
								if (addActionItem(pinAction, appsModel.allAppsModel, allAppsIndex, existingActionIds)) {
									hasPrimaryActions = true
								}
								break
							}
						}
					}
				}

				// App-specific actions (New Window, etc.)
				var appActionsAdded = false
				var appActionsSource = []
				var appActionsModel = null
				var appActionsIndex = -1
				if (actionList && typeof actionList.length === "number" && targetModel && typeof targetModel.triggerIndexAction === "function") {
					appActionsSource = actionList
					appActionsModel = targetModel
					appActionsIndex = index
				} else if (allAppsActionList && typeof allAppsActionList.length === "number"
						&& allAppsIndex >= 0 && appsModel.allAppsModel && typeof appsModel.allAppsModel.triggerIndexAction === "function") {
					appActionsSource = allAppsActionList
					appActionsModel = appsModel.allAppsModel
					appActionsIndex = allAppsIndex
				}
					for (var aa = 0; aa < appActionsSource.length; aa++) {
					var appAction = appActionsSource[aa]
					if (!appAction || !appAction.actionId) {
						continue
					}
					if (appAction.actionId === 'addToPanel' || appAction.actionId === 'addToDesktop' || appAction.actionId === 'addToTaskManager') {
						continue
					}
					if (isForgetAction(appAction)) {
						continue
					}
					if (hasPrimaryActions && !appActionsAdded) {
						menu.addMenuItem(menu.newSeperator())
					}
						if (addActionItem(appAction, appActionsModel, appActionsIndex, null)) {
						appActionsAdded = true
						addedActions = true
					}
				}

				// Forget actions (from Recent Apps action list when available)
				var forgetAdded = false
				if (actionList && typeof actionList.length === "number" && targetModel && typeof targetModel.triggerIndexAction === "function") {
					for (var fa = 0; fa < actionList.length; fa++) {
						var forgetAction = actionList[fa]
						if (!isForgetAction(forgetAction)) {
							continue
						}
						if (!forgetAdded && (appActionsAdded || hasPrimaryActions)) {
							menu.addMenuItem(menu.newSeperator())
						}
						if (addActionItem(forgetAction, targetModel, index, null)) {
							forgetAdded = true
							addedActions = true
						}
					}
				}

				if (!addedActions && typeof logger !== "undefined" && logger && targetModel && shouldAttemptActions) {
					logger.warn('MenuListItem: context menu skipped action list; model missing action helpers or empty actions', targetModel)
				}

				// Fallback: if Kicker didn't supply addToTaskManager (task manager not in
				// Kicker's hardcoded list, e.g. alexankitty.fancytasks), try ours.
				if (!existingActionIds['addToTaskManager'] && launcherUrl) {
					menu.addFallbackTaskManagerAction(launcherUrl)
				}
				return
			}

			if (!isMergedSearch && actionList && typeof actionList.length === "number" && actionList.length > 0 && targetModel && typeof targetModel.triggerIndexAction === "function") {
				menu.addActionList(actionList, targetModel, index)
				addedActions = true
			}

			// Fallback for models that don't expose full action lists (eg. Recent Apps)
			if (!addedActions && launcherUrl && appsModel && appsModel.allAppsModel && typeof appsModel.allAppsModel.getActionList === "function") {
				var fallbackIndex = findAllAppsIndexForLauncher(launcherUrl)
				if (fallbackIndex >= 0) {
					var fallbackActionList = []
					try { fallbackActionList = appsModel.allAppsModel.getActionList(fallbackIndex) } catch (e) { fallbackActionList = [] }
					if (fallbackActionList && typeof fallbackActionList.length === "number" && fallbackActionList.length > 0
							&& typeof appsModel.allAppsModel.triggerIndexAction === "function") {
						menu.addActionList(fallbackActionList, appsModel.allAppsModel, fallbackIndex)
						addedActions = true
					}
				}
			}

			if (!addedActions && typeof logger !== "undefined" && logger && targetModel && shouldAttemptActions) {
				logger.warn('MenuListItem: context menu skipped action list; model missing action helpers or empty actions', targetModel)
			}

			// Fallback: if Kicker didn't supply addToTaskManager (task manager not in
			// Kicker's hardcoded list, e.g. alexankitty.fancytasks), try ours.
			if (!existingActionIds['addToTaskManager'] && launcherUrl) {
				menu.addFallbackTaskManagerAction(launcherUrl)
			}
		}
	}

} // delegate: AppToolButton
