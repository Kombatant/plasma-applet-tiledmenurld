import QtQuick
import QtQuick.Layouts

Item {
	id: presetTileButton
	Layout.fillWidth: true
	Layout.preferredHeight: visible ? image.paintedHeight : 0

	visible: source
	enabled: !!source
	property alias source: image.source
	property string filename: 'temp.jpg'
	property int w: 0
	property int h: 0
	property var appObj
	property var backgroundImageField
	property var labelField
	property var iconField
	property var tileGrid
	property var positionSizeField

	TilePresetImageHelper {
		id: presetHelper
	}

	Image {
		id: image
		anchors.centerIn: parent
		width: Math.min(parent.width, sourceSize.width)

		fillMode: Image.PreserveAspectFit
	}

	HoverOutlineEffect {
		id: hoverOutlineEffect
		anchors.fill: image
		hoverRadius: Math.min(width, height)
		property alias control: mouseArea
	}

	MouseArea {
		id: mouseArea
		anchors.fill: image
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton
		cursorShape: Qt.ArrowCursor

		onClicked: presetTileButton.select()
	}

	function resizeTile() {
		var sizeChanged = false
		if (presetTileButton.w > 0) {
			if (appObj && appObj.tile) {
				appObj.tile.w = presetTileButton.w
				sizeChanged = true
			}
		}
		if (presetTileButton.h > 0) {
			if (appObj && appObj.tile) {
				appObj.tile.h = presetTileButton.h
				sizeChanged = true
			}
		}
		if (sizeChanged && appObj && tileGrid) {
			appObj.tileChanged()
			tileGrid.tileModelChanged()
		}
		if (positionSizeField && positionSizeField.refreshEditors) {
			positionSizeField.refreshEditors()
		}
	}

	function setTileBackgroundImage(filepath) {
		var url = presetHelper.toFileUrl(filepath)
		if (backgroundImageField) {
			backgroundImageField.text = url
		}
		if (labelField) {
			labelField.checked = false
		}
		if (iconField) {
			iconField.checked = false
		}
	}

	function select() {
		var sourceFilepath = '' + source // cast to string
		var isLocalFilepath = sourceFilepath.indexOf('file://') == 0 || sourceFilepath.indexOf('/') == 0
		if (isLocalFilepath) {
			presetTileButton.resizeTile()
			presetTileButton.setTileBackgroundImage(source)
		} else {
			image.grabToImage(function(result){
				var localFilepath = presetHelper.saveGrabResultToPresetFolder(result, filename)
				if (localFilepath) {
					presetTileButton.resizeTile()
					presetTileButton.setTileBackgroundImage(localFilepath)
				}
			}, image.sourceSize)
		}
	}

}
