import QtQuick
import org.kde.plasma.private.kicker as Kicker

Kicker.SimpleFavoritesModel {
	// Kicker.FavoritesModel must be a child object of RootModel.
	// appEntry.actions() looks at the parent object for parent.appletInterface and will crash plasma if it can't find it.
	// https://github.com/KDE/plasma-desktop/blob/master/applets/kicker/plugin/appentry.cpp#L151
	id: kickerAppModel

	function triggerIndex(index) {
		var closeRequested = false
		try {
			closeRequested = kickerAppModel.trigger(index, "", null)
		} catch (e) {
			console.warn('KickerAppModel.triggerIndex exception', index, e)
			if (typeof logger !== "undefined" && logger) {
				logger.warn('KickerAppModel.triggerIndex exception', index, e)
			}
			return false
		}
		if (closeRequested) {
			plasmoid.expanded = false
		}
		return closeRequested
	}

	function triggerIndexAction(index, actionId, actionArgument) {
		var closeRequested = false
		try {
			closeRequested = kickerAppModel.trigger(index, actionId, actionArgument)
		} catch (e) {
			console.warn('KickerAppModel.triggerIndexAction exception', index, actionId, e)
			if (typeof logger !== "undefined" && logger) {
				logger.warn('KickerAppModel.triggerIndexAction exception', index, actionId, e)
			}
			return false
		}
		if (closeRequested) {
			plasmoid.expanded = false
		}
		return closeRequested
	}

	// https://invent.kde.org/plasma/plasma-workspace/-/blame/master/applets/kicker/plugin/actionlist.h#L18
	// DescriptionRole        Qt.UserRole + 1
	// GroupRole              Qt.UserRole + 2
	// FavoriteIdRole         Qt.UserRole + 3
	// IsSeparatorRole        Qt.UserRole + 4
	// IsDropPlaceholderRole  Qt.UserRole + 5
	// IsParentRole           Qt.UserRole + 6
	// HasChildrenRole        Qt.UserRole + 7
	// HasActionListRole      Qt.UserRole + 8
	// ActionListRole         Qt.UserRole + 9
	// UrlRole                Qt.UserRole + 10
	// DisabledRole           Qt.UserRole + 11        @since: Plasma 5.20
	// IsMultilineTextRole    Qt.UserRole + 12        @since: Plasma 5.24
	// DisplayWrappedRole     Qt.UserRole + 13        @since: Plasma 6.0
	function getApp(url) {
		for (var i = 0; i < count; i++) {
			var modelIndex = kickerAppModel.index(i, 0)
			var favoriteId = kickerAppModel.data(modelIndex, Qt.UserRole + 3)
			if (favoriteId == url) {
				var app = {}
				app.indexInModel = i
				app.favoriteId = favoriteId
				app.display = kickerAppModel.data(modelIndex, Qt.DisplayRole)
				app.decoration = kickerAppModel.data(modelIndex, Qt.DecorationRole)
				app.description = kickerAppModel.data(modelIndex, Qt.UserRole + 1)
				app.group = kickerAppModel.data(modelIndex, Qt.UserRole + 2)
				app.url = kickerAppModel.data(modelIndex, Qt.UserRole + 10)

				return app
			}
		}
		return null
	}
	function runApp(url) {
		for (var i = 0; i < count; i++) {
			var modelIndex = kickerAppModel.index(i, 0)
			var favoriteId = kickerAppModel.data(modelIndex, Qt.UserRole + 3)
			if (favoriteId == url) {
				kickerAppModel.triggerIndex(i)
				return true
			}
		}
		return false
	}

	function indexHasActionList(i) {
		var modelIndex = kickerAppModel.index(i, 0)
		var hasActionList = kickerAppModel.data(modelIndex, Qt.UserRole + 8)
		return hasActionList
	}

	function getActionListAtIndex(i) {
		var modelIndex = kickerAppModel.index(i, 0)
		var actionList = kickerAppModel.data(modelIndex, Qt.UserRole + 9)
		return actionList
	}
}
