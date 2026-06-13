import QtQuick

ListModel {
	id: listModel
	
	property var list: []
	property var sectionIcons: { return {} }

	signal refreshing()
	signal refreshed()

	onListChanged: {
		clear()
		for (var i = 0; i < list.length; i++) {
			append(list[i])
		}
	}


	function parseAppsModelItem(model, i) {
		// https://github.com/KDE/plasma-desktop/blob/master/applets/kicker/plugin/actionlist.h#L30
		var DescriptionRole = Qt.UserRole + 1
		var GroupRole = Qt.UserRole + 2
		var FavoriteIdRole = Qt.UserRole + 3
		var IsSeparatorRole = Qt.UserRole + 4
		var IsDropPlaceholderRole = Qt.UserRole + 5
		var IsParentRole = Qt.UserRole + 6
		var HasChildrenRole = Qt.UserRole + 7
		var HasActionListRole = Qt.UserRole + 8
		var ActionListRole = Qt.UserRole + 9
		var UrlRole = Qt.UserRole + 10
		var DisabledRole = Qt.UserRole + 11 // @since: Plasma 5.20
		var IsMultilineTextRole = Qt.UserRole + 12 // @since: Plasma 5.24
		var DisplayWrappedRole = Qt.UserRole + 13 // @since: Plasma 6.0

		var modelIndex = model.index(i, 0)

		var item = {
			parentModel: model,
			indexInParent: i,
			name: model.data(modelIndex, Qt.DisplayRole),
			description: model.data(modelIndex, DescriptionRole),
			favoriteId: model.data(modelIndex, FavoriteIdRole),
			disabled: false, // for SidebarContextMenu
			largeIcon: false, // for KickerListView
		}

		if (typeof model.name === 'string') {
			item.parentName = model.name
		}

		// ListView.append() doesn't like it when we have { key: [object] }.
		var url = model.data(modelIndex, UrlRole)
		if (typeof url === 'object') {
			url = url.toString()
		}
		if (typeof url === 'string') {
			item.url = url
		}

		var icon =  model.data(modelIndex, Qt.DecorationRole)
		if (typeof icon === 'object') {
			item.icon = icon
		} else if (typeof icon === 'string') {
			item.iconName = icon
		}

		var isDisabled = model.data(modelIndex, DisabledRole)
		if (typeof isDisabled !== 'undefined') {
			item.disabled = isDisabled
		}

		return item
	}

	function parseModel(appList, model, path) {
		for (var i = 0; i < model.count; i++) {
			var item = model.modelForRow(i)
			if (!item) {
				item = parseAppsModelItem(model, i)
			} else {
				// Ensure core fields exist even when modelForRow supplies the object.
				if (!item.parentModel) {
					item.parentModel = model
				}
				if (typeof item.indexInParent === "undefined") {
					item.indexInParent = i
				}
			}
			var itemPath = (path || []).concat(i)
			if (item && item.hasChildren) {
				parseModel(appList, item, itemPath)
			} else {
				appList.push(item)
			}
		}
	}


	function refresh() {
		refreshing()

		refreshed()
	}

	// Resolve the live parentModel row for a cached item, guarding against
	// drift: the underlying Kicker submodel can re-sort/reset its rows without
	// our `list` (and the captured indexInParent) being rebuilt. When that
	// happens index N in the C++ model is a *different* app than when parsed,
	// so a blind trigger(indexInParent) launches the wrong program. We verify
	// the favoriteId at the cached row and, on mismatch, re-find the row by
	// favoriteId. Returns indexInParent to trigger, or -1 if unresolvable.
	function _resolveParentRow(item) {
		if (!item || !item.parentModel) {
			return -1
		}
		var FavoriteIdRole = Qt.UserRole + 3
		var model = item.parentModel
		var want = item.favoriteId
		var idx = item.indexInParent
		// Fast path: cached row still holds the expected app.
		if (typeof idx === "number" && idx >= 0 && idx < model.count) {
			var liveId = model.data(model.index(idx, 0), FavoriteIdRole)
			if (!want || liveId === want) {
				return idx
			}
			console.warn("[KickerListModel] index drift: row", idx,
				"expected favoriteId=", want, "but live model has=", liveId,
				"- re-resolving by favoriteId")
		}
		// Slow path: row moved. Find the app by favoriteId in the live model.
		if (want) {
			for (var i = 0; i < model.count; i++) {
				if (model.data(model.index(i, 0), FavoriteIdRole) === want) {
					return i
				}
			}
			console.warn("[KickerListModel] could not re-resolve favoriteId=", want,
				"in live parentModel (", model.count, "rows)")
		}
		return -1
	}

	function triggerIndex(index) {
		var item = list[index]
		var row = _resolveParentRow(item)
		if (row < 0) {
			console.warn("[KickerListModel] triggerIndex aborted: unresolved row for index", index)
			return
		}
		item.parentModel.trigger(row, "", null)
		itemTriggered()
	}

	signal itemTriggered()

	function hasActionList(index) {
		var DescriptionRole = Qt.UserRole + 1
		var HasActionListRole = Qt.UserRole + 8

		var item = list[index]
		var modelIndex = item.parentModel.index(item.indexInParent, 0)
		return item.parentModel.data(modelIndex, HasActionListRole)
	}

	function getActionList(index) {
		var DescriptionRole = Qt.UserRole + 1
		var ActionListRole = Qt.UserRole + 9

		var item = list[index]
		var modelIndex = item.parentModel.index(item.indexInParent, 0)
		return item.parentModel.data(modelIndex, ActionListRole)
	}

	function triggerIndexAction(index, actionId, actionArgument) {
		// kicker/code/tools.js triggerAction()

		var item = list[index]
		var row = _resolveParentRow(item)
		if (row < 0) {
			console.warn("[KickerListModel] triggerIndexAction aborted: unresolved row for index", index)
			return
		}
		item.parentModel.trigger(row, actionId, actionArgument)
		itemTriggered()
	}

	function getByValue(key, value) {
		for (var i = 0; i < count; i++) {
			var item = get(i)
			if (item[key] == value) {
				return item
			}
		}
		return null
	}

	function hasApp(favoriteId) {
		for (var i = 0; i < count; i++) {
			var item = get(i)
			if (item.favoriteId == favoriteId) {
				return true
			}
		}
	}
}
