import QtQuick
import QtQuick.Layouts
import Qt.labs.platform as QtLabsPlatform

Item {
	id: presetTileButton
	Layout.fillWidth: true
	Layout.preferredHeight: image.paintedHeight

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

	function toFileUrl(path) {
		if (!path) {
			return ""
		}
		if (path.indexOf('://') !== -1) {
			return path
		}
		if (path.indexOf('/') === 0) {
			return 'file://' + path
		}
		return path
	}

	function normalizeLocation(loc) {
		if (loc === null || typeof loc === 'undefined') {
			return ""
		}
		var s = typeof loc === 'string' ? loc : (loc && typeof loc.toString === 'function' ? loc.toString() : '' + loc)
		s = s ? s.trim() : ''
		if (!s) {
			return ""
		}
		if (s.indexOf('file://') === 0) {
			s = s.substr('file://'.length)
		}
		if (s.indexOf('~/') === 0) {
			var home = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation)
			if (home) {
				s = home + s.substr(1)
			}
		}
		if (!s) {
			return ""
		}
		return s.charAt(s.length - 1) === '/' ? s : s + '/'
	}

	function picturesDir() {
		return normalizeLocation(QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.PicturesLocation))
	}

	function downloadsDir() {
		return normalizeLocation(QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DownloadLocation))
	}

	function candidateDirs() {
		var dirs = []
		function addCandidate(path) {
			var normalized = normalizeLocation(path)
			if (normalized && dirs.indexOf(normalized) === -1) {
				dirs.push(normalized)
			}
		}
		if (typeof config !== 'undefined' && config.presetTilesFolder) {
			addCandidate(config.presetTilesFolder)
		} else if (plasmoid && plasmoid.configuration && plasmoid.configuration.presetTilesFolder) {
			addCandidate(plasmoid.configuration.presetTilesFolder)
		}
		if (typeof config !== 'undefined' && config.defaultPresetTilesFolder) {
			addCandidate(config.defaultPresetTilesFolder)
		}
		var pic = picturesDir()
		if (pic) {
			addCandidate(pic + 'tiledmenu/')
			addCandidate(pic)
		}
		var dl = downloadsDir()
		if (dl) {
			addCandidate(dl)
		}
		return dirs
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
	}

	function setTileBackgroundImage(filepath) {
		var url = toFileUrl(filepath)
		logger.debug('setTileBackgroundImage', filepath, url)
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
		logger.debug('select', source)

		var sourceFilepath = '' + source // cast to string
		var isLocalFilepath = sourceFilepath.indexOf('file://') == 0 || sourceFilepath.indexOf('/') == 0
		if (isLocalFilepath) {
			presetTileButton.setTileBackgroundImage(source)
			presetTileButton.resizeTile()
		} else {
			var dirs = candidateDirs()
			if (dirs.length === 0) {
				logger.debug('No writable location found; skipping save')
				return
			}
			logger.debug('grabToImage.start')
			image.grabToImage(function(result){
				logger.debug('grabToImage.done', result, result.url)
				var saved = false
				for (var i = 0; i < dirs.length; i++) {
					var localFilepath = dirs[i] + filename
					var ok = result.saveToFile(localFilepath)
					logger.debug('saveToFile', ok, localFilepath)
					if (ok) {
						presetTileButton.setTileBackgroundImage(localFilepath)
						presetTileButton.resizeTile()
						saved = true
						break
					}
				}
				if (!saved) {
					logger.debug('Failed to save preset tile image in any candidate dir')
				}
			}, image.sourceSize)
		}
	}

}
