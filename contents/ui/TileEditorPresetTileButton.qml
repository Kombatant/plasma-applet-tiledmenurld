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
	property var spec: null
	property int w: 0
	property int h: 0
	property var appObj
	property var backgroundImageField
	property var labelField
	property var iconField
	property var tileGrid
	property var positionSizeField
	property string _reportedErrorSource: ''
	signal imageLoadFailed(var spec)

	onSourceChanged: _reportedErrorSource = ''

	TilePresetImageHelper {
		id: presetHelper
	}

	Image {
		id: image
		anchors.centerIn: parent
		width: Math.min(parent.width, sourceSize.width)

		fillMode: Image.PreserveAspectFit
		asynchronous: true
		cache: true

		onStatusChanged: {
			var failedSource = "" + source
			if (status === Image.Error && failedSource && presetTileButton._reportedErrorSource !== failedSource) {
				presetTileButton._reportedErrorSource = failedSource
				presetTileButton.imageLoadFailed(presetTileButton.spec)
			}
		}
	}

	HoverOutlineEffect {
		id: hoverOutlineEffect
		anchors.fill: image
		hoverRadius: Math.min(width, height)
		property alias control: mouseArea
	}

	Rectangle {
		id: sizeBadge
		anchors.right: image.right
		anchors.bottom: image.bottom
		anchors.margins: 6
		width: sizeBadgeLabel.implicitWidth + 12
		height: sizeBadgeLabel.implicitHeight + 6
		z: 2
		visible: !!presetTileButton.source && presetTileButton.w > 0 && presetTileButton.h > 0
		color: "#C0000000"
		border.color: "#80FFFFFF"
		border.width: 1
		radius: 4

		Text {
			id: sizeBadgeLabel
			anchors.centerIn: parent
			text: presetTileButton.w + "×" + presetTileButton.h
			color: "white"
			font.bold: true
			font.pixelSize: 12
		}
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
