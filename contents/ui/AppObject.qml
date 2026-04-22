import QtQuick
import "Utils.js" as Utils

QtObject {
	id: appObj

	property var tile: null

	readonly property bool isCardLayout: plasmoid && plasmoid.configuration && plasmoid.configuration.tileGroupLayout === "card"
	readonly property bool isGroup: tile && tile.tileType == "group"
	readonly property bool isLauncher: !isGroup

	readonly property color defaultBackgroundColor: isGroup ? "transparent" : config.defaultTileColor
	readonly property bool defaultShowIcon: isGroup ? false : true
	readonly property int defaultTileW: isGroup ? 6 : 2
	readonly property int defaultTileH: isGroup ? 1 : 2

	readonly property string favoriteId: tile && (tile.favoriteId || tile.url) || ''
	readonly property string kickerFavoriteId: Utils.kickerFavoriteId(favoriteId)
	readonly property var app: kickerFavoriteId ? appsModel.getTileApp(kickerFavoriteId) : null
	readonly property string appLabel: app ? app.display : ""
	readonly property string appUrl: app ? app.url : ""
	readonly property var appIcon: app ? app.decoration : null
	readonly property string descriptionText: tile && typeof tile.description !== "undefined" ? tile.description : (app && app.description ? app.description : "")
	readonly property string labelText: tile && tile.label || appLabel || favoriteId || appUrl || (tile && tile.launchUrl) || ""
	readonly property var iconSource: tile && tile.icon || appIcon || kickerFavoriteId
	readonly property bool iconFill: tile && typeof tile.iconFill !== "undefined" ? tile.iconFill : false
	readonly property bool showIcon: tile && typeof tile.showIcon !== "undefined" ? tile.showIcon : defaultShowIcon
	readonly property bool showLabel: tile && typeof tile.showLabel !== "undefined" ? tile.showLabel : true
	readonly property bool hasExplicitBackgroundColor: tile && typeof tile.backgroundColor !== "undefined"
	readonly property bool hasExplicitBackgroundImage: tile && typeof tile.backgroundImage !== "undefined" && !!tile.backgroundImage
	readonly property bool hasExplicitGradient: tile && typeof tile.gradient !== "undefined"
	readonly property color backgroundColor: tile && typeof tile.backgroundColor !== "undefined" ? tile.backgroundColor : defaultBackgroundColor
	readonly property string backgroundImage: tile && typeof tile.backgroundImage !== "undefined" ? tile.backgroundImage : ""
	readonly property bool backgroundGradient: tile && typeof tile.gradient !== "undefined" ? tile.gradient : config.defaultTileGradient

	readonly property int tileX: tile && typeof tile.x !== "undefined" ? tile.x : 0
	readonly property int tileY: tile && typeof tile.y !== "undefined" ? tile.y : 0
	readonly property int tileW: tile && typeof tile.w !== "undefined" ? tile.w : defaultTileW
	readonly property int tileH: tile && typeof tile.h !== "undefined" ? tile.h : defaultTileH

	function hasActionList() {
		if (!app || !app.actionListModel) {
			return false
		}
		try {
			return app.actionListModel.hasActionList(app.indexInModel)
		} catch (e) {
			return false
		}
	}

	function getActionList() {
		if (!app || !app.actionListModel) {
			return []
		}
		try {
			return app.actionListModel.getActionList(app.indexInModel)
		} catch (e) {
			return []
		}
	}

	function addActionList(menu) {
		if (hasActionList()) {
			var actionList = getActionList()
			menu.addActionList(actionList, appObj.app.actionListModel, appObj.app.indexInModel)
		}
	}

	readonly property var groupRect: {
		if (isGroup) {
			return tileGrid.getGroupAreaRect(tile)
		} else {
			return null
		}
	}
	readonly property var parentGroupTile: {
		if (!isCardLayout || !tile || isGroup || !tileGrid || !tileGrid.tileModel) {
			return null
		}

		var tileX2 = tileX + tileW - 1
		var tileY2 = tileY + tileH - 1
		for (var i = 0; i < tileGrid.tileModel.length; i++) {
			var candidate = tileGrid.tileModel[i]
			if (!candidate || candidate.tileType !== "group") {
				continue
			}
			var area = tileGrid.getGroupAreaRect(candidate)
			if (tileX >= area.x1 && tileX2 <= area.x2 && tileY >= area.y1 && tileY2 <= area.y2) {
				return candidate
			}
		}
		return null
	}
	readonly property bool inGroup: !!parentGroupTile
	readonly property bool usesGroupPanelStyling: inGroup && !hasExplicitBackgroundColor && !hasExplicitBackgroundImage && !hasExplicitGradient

	// Edge flags: true when this tile sits at the boundary of its parent group panel
	readonly property bool atGroupLeft: inGroup && parentGroupTile && tileX === parentGroupTile.x
	readonly property bool atGroupRight: inGroup && parentGroupTile && (tileX + tileW) === (parentGroupTile.x + parentGroupTile.w)
	readonly property bool atGroupBottom: {
		if (!inGroup || !parentGroupTile) return false
		var area = tileGrid.getGroupAreaRect(parentGroupTile)
		return area && (tileY + tileH - 1) === area.y2
	}
	property Connections tileGridConnection: Connections {
		target: tileGrid
		function onTileModelChanged() {
			if (appObj.isGroup) {
				appObj.groupRectChanged()
			} else {
				appObj.parentGroupTileChanged()
				appObj.inGroupChanged()
				appObj.usesGroupPanelStylingChanged()
			}
		}
	}
}
