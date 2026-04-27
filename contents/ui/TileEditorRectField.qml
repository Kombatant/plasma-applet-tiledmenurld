import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3

TileEditorGroupBox {
	id: tileEditorRectField
	title: i18n("Label")
	implicitWidth: parent.implicitWidth
	Layout.fillWidth: true
	property int currentTileW: appObj && appObj.tile ? (appObj.tile.w || 1) : 1
	property int currentTileH: appObj && appObj.tile ? (appObj.tile.h || 1) : 1

	readonly property bool isGroupTile: appObj && appObj.isGroup
	readonly property string heightKey: isGroupTile ? 'groupAreaH' : 'h'
	readonly property int effectiveTileH: {
		if (!isGroupTile) {
			return currentTileH
		}
		var storedH = (appObj && appObj.tile && typeof appObj.tile.groupAreaH !== "undefined")
			? appObj.tile.groupAreaH
			: 1
		var actualH = (appObj && appObj.groupRect && typeof appObj.groupRect.h !== "undefined")
			? appObj.groupRect.h
			: 1
		return Math.max(storedH, actualH)
	}

	function syncCurrentTileSize() {
		if (!appObj || !appObj.tile) {
			currentTileW = 1
			currentTileH = 1
			return
		}
		currentTileW = appObj.tile.w || 1
		currentTileH = appObj.tile.h || 1
	}

	function refreshEditors() {
		syncCurrentTileSize()
		xSpinBox.syncValue()
		ySpinBox.syncValue()
		wSpinBox.syncValue()
		hSpinBox.syncValue()
	}

	function normalizeGroupTile() {
		if (!isGroupTile || !appObj.tile) {
			return
		}
		var changed = false
		var oldH = (typeof appObj.tile.h !== "undefined" ? appObj.tile.h : 1)
		if (oldH !== 1) {
			// If an existing group header was taller, shrinking it would otherwise
			// leave a blank row at the top of the group content area.
			var oldArea = tileGrid.getGroupAreaRect(appObj.tile)
			var deltaY = 1 - oldH
			appObj.tile.h = 1
			for (var i = 0; i < tileGrid.tileModel.length; i++) {
				var tile = tileGrid.tileModel[i]
				if (!tile || tile === appObj.tile) {
					continue
				}
				if (tileGrid.tileWithin(tile, oldArea.x1, oldArea.y1, oldArea.x2, oldArea.y2)) {
					tile.y += deltaY
				}
			}
			changed = true
		}
		if (typeof appObj.tile.groupAreaH === "undefined") {
			appObj.tile.groupAreaH = 1
			changed = true
		}

		var areaNow = tileGrid.getGroupAreaRect(appObj.tile)
		var h = areaNow && typeof areaNow.h !== "undefined" ? areaNow.h : 1
		var desiredH = Math.max(1, h)
		if (appObj.tile.groupAreaH < desiredH) {
			appObj.tile.groupAreaH = desiredH
			changed = true
		}
		if (changed) {
			appObj.tileChanged()
			tileGrid.tileModelChanged()
		}
	}

	Component.onCompleted: {
		refreshEditors()
		normalizeGroupTile()
	}

	Connections {
		target: appObj

		function onTileChanged() {
			tileEditorRectField.refreshEditors()
			tileEditorRectField.normalizeGroupTile()
		}
	}

	Connections {
		target: tileGrid

		function onTileModelChanged() {
			tileEditorRectField.refreshEditors()
			if (tileEditorRectField.isGroupTile && appObj.tile) {
				tileEditorRectField.normalizeGroupTile()
			}
		}
	}

	RowLayout {
		anchors.fill: parent

		GridLayout {
			columns: 2
			Layout.fillWidth: true

			PlasmaComponents3.Label { text: i18n("x:") }
			TileEditorSpinBox {
				id: xSpinBox
				key: 'x'
				from: 0
				// to: tileGrid.columns - (appObj.tile && appObj.tile.w-1 || 0)
				// to: appObj.tileX + tileEditorRectField.xLeft
			}
			PlasmaComponents3.Label { text: i18n("y:") }
			TileEditorSpinBox {
				id: ySpinBox
				key: 'y'
				from: 0
			}
			PlasmaComponents3.Label { text: i18n("w:") }
			TileEditorSpinBox {
				id: wSpinBox
				key: 'w'
				from: 1
				// to: tileGrid.columns - (appObj.tile && appObj.tile.x || 0)
				// to: appObj.tileW + tileEditorRectField.xLeft
			}
			PlasmaComponents3.Label { text: i18n("h:") }
			TileEditorSpinBox {
				id: hSpinBox
				key: tileEditorRectField.heightKey
				from: 1
			}
		}

		GridLayout {
			id: resizeGrid
			Layout.fillWidth: true
			rows: 4
			columns: 4

			Repeater {
				model: resizeGrid.rows * resizeGrid.columns

				PlasmaComponents3.Button {
					Layout.fillWidth: true
					implicitWidth: 20
					property int w: (modelData % resizeGrid.columns) + 1
					property int h: Math.floor(modelData / resizeGrid.columns) + 1
					text: '' + w + 'x' + h
					checked: w <= tileEditorRectField.currentTileW && h <= tileEditorRectField.effectiveTileH
					// enabled: w - appObj.tileW <= tileEditorRectField.xLeft
					onClicked: {
						appObj.tile.w = w
						if (tileEditorRectField.isGroupTile) {
							appObj.tile.h = 1
							appObj.tile.groupAreaH = h
						} else {
							appObj.tile.h = h
						}
						tileEditorRectField.refreshEditors()
						appObj.tileChanged()
						tileGrid.tileModelChanged()
					}
				}
			}
		}
	}
}
