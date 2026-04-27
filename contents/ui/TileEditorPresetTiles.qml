import QtQuick
import QtQuick.Layouts
import QtQml.Models as QtModels

// Note: This references a global KCoreAddons.KUser { id: kuser }

TileEditorGroupBox {
	id: tileEditorPresetTiles
	title: i18n("Label")
	implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, content.implicitHeight + topPadding + bottomPadding)
	Layout.preferredHeight: visible ? implicitHeight : 0
	Layout.fillWidth: true
	property var appObj
	property var backgroundImageField
	property var labelField
	property var iconField
	property var tileGrid
	property var positionSizeField
	readonly property var steamPresetSpecs: presetHelper.presetSpecsForSteamGameId(steamGameId)
	readonly property var lutrisPresetSpecs: presetHelper.presetSpecsForLutrisGameSlug(lutrisGameSlug)
	property var igdbPresetSpecs: []
	property bool igdbLoading: false
	property string igdbStatus: ''

	TilePresetImageHelper {
		id: presetHelper
	}

	property Instantiator igdbPresetInstantiator: QtModels.Instantiator {
		model: tileEditorPresetTiles.igdbPresetSpecs
		delegate: TileEditorPresetTileButton {
			parent: content
			appObj: tileEditorPresetTiles.appObj
			backgroundImageField: tileEditorPresetTiles.backgroundImageField
			labelField: tileEditorPresetTiles.labelField
			iconField: tileEditorPresetTiles.iconField
			tileGrid: tileEditorPresetTiles.tileGrid
			positionSizeField: tileEditorPresetTiles.positionSizeField
			filename: modelData.filename
			source: modelData.source
			w: modelData.w
			h: modelData.h
		}
		onObjectAdded: function() {
			tileEditorPresetTiles.checkForPreset()
		}
		onObjectRemoved: function() {
			tileEditorPresetTiles.checkForPreset()
		}
	}

	HeroPageMetadataFetcher {
		id: metadataFetcher
		parent: null
	}

	HeroicLutrisMetadataFetcher {
		id: launcherFetcher
		parent: null
	}

	Connections {
		target: metadataFetcher
		function onHasIgdbMetadataSettingsChanged() {
			tileEditorPresetTiles.maybeFetchIgdbArt()
		}
	}

	visible: false
	function checkForPreset() {
		var visiblePresets = 0
		for (var i = 0; i < content.children.length; i++) {
			var item = content.children[i]
			var hasImageUrl = item.source && item.source.toString()
			if (hasImageUrl) {
				visiblePresets += 1
			}
		}
		visible = visiblePresets > 0 || igdbLoading || !!igdbStatus
	}
	Component.onCompleted: {
		checkIfRecognizedLauncher()
	}

	property string steamGameId: ''
	readonly property bool isSteamGameLauncher: !!steamGameId
	property string lutrisGameSlug: ''
	readonly property bool isLutrisGameLauncher: !!lutrisGameSlug || recognizedLauncherKind === 'lutris'
	property string heroicAppName: ''
	readonly property bool isHeroicGameLauncher: !!heroicAppName || recognizedLauncherKind === 'heroic'
	property string recognizedLauncherKind: ''

	function endsWith(s, substr) {
		return s.indexOf(substr) == s.length - substr.length
	}

	function _applyResolvedLauncherInfo(info) {
		var resolved = info || {}
		tileEditorPresetTiles.recognizedLauncherKind = resolved.kind ? ("" + resolved.kind) : ''
		tileEditorPresetTiles.heroicAppName = resolved.heroicAppName ? ("" + resolved.heroicAppName) : ''
		if (resolved.lutrisSlug) {
			tileEditorPresetTiles.lutrisGameSlug = "" + resolved.lutrisSlug
		}
	}

	function resetRecognizedLaunchers() {
		tileEditorPresetTiles.steamGameId = ''
		tileEditorPresetTiles.lutrisGameSlug = ''
		tileEditorPresetTiles.heroicAppName = ''
		tileEditorPresetTiles.recognizedLauncherKind = ''
		tileEditorPresetTiles.igdbPresetSpecs = []
		tileEditorPresetTiles.igdbStatus = ''
	}

	function _launchUrlForApp() {
		if (appObj && appObj.tile && appObj.tile.launchUrl) return "" + appObj.tile.launchUrl
		if (appObj && appObj.favoriteId) return "" + appObj.favoriteId
		return ''
	}

	function checkIfRecognizedLauncher() {
		resetRecognizedLaunchers()
		checkForPreset()

		if (!appObj) {
			return
		}

		checkIfSteamIcon(appObj.iconSource)
		launcherFetcher.resolveLauncherInfo(appObj.app, _launchUrlForApp(), appObj.favoriteId || '', function(info) {
			tileEditorPresetTiles._applyResolvedLauncherInfo(info)
			tileEditorPresetTiles.checkForPreset()
			tileEditorPresetTiles.maybeFetchIgdbArt()
		})

		// Lutris does not use game id in icon name. Eg: lutris_overwatch instead of lutris_game_1
	}

	function _titleForApp() {
		if (appObj && appObj.appLabel) return ("" + appObj.appLabel).trim()
		if (appObj && appObj.tile && appObj.tile.label) return ("" + appObj.tile.label).trim()
		if (appObj && appObj.labelText) return ("" + appObj.labelText).trim()
		return ''
	}

	function maybeFetchIgdbArt() {
		if (!isHeroicGameLauncher && !isLutrisGameLauncher) {
			igdbStatus = ''
			checkForPreset()
			return
		}
		if (!metadataFetcher.hasIgdbMetadataSettings) {
			igdbStatus = i18n("Set the IGDB Client ID and Client Secret in the Tiles settings to download artwork.")
			checkForPreset()
			return
		}
		if (igdbPresetSpecs.length > 0 || igdbLoading) return
		var title = _titleForApp()
		if (!title) {
			igdbStatus = i18n("Could not determine a title for this launcher.")
			checkForPreset()
			return
		}
		igdbLoading = true
		igdbStatus = i18n("Looking up IGDB artwork...")
		checkForPreset()
		metadataFetcher.fetchIgdbArtworksByTitle(title, function(err, detail) {
			igdbLoading = false
			if (err || !detail) {
				igdbStatus = err || i18n("No IGDB artwork found.")
				checkForPreset()
				return
			}
			igdbPresetSpecs = presetHelper.presetSpecsForIgdbDetail(detail)
			igdbStatus = ''
			checkForPreset()
		})
	}

	function checkIfSteamIcon(iconSource) {
		var src = "" + (iconSource || "")
		var m = /steam_icon_(\d+)/.exec(src)
		if (m) {
			tileEditorPresetTiles.steamGameId = m[1]
		} else if (src.length > 0) {
			tileEditorPresetTiles.steamGameId = ''
		}
	}

	function checkIfSteamLauncher(desktopFile) {
		var steamCommandRegex = /steam steam:\/\/rungameid\/(\d+)/
		var m = steamCommandRegex.exec(desktopFile['Exec'])
		if (m) {
			tileEditorPresetTiles.steamGameId = m[1]
		} else {
			tileEditorPresetTiles.steamGameId = '' // Reset
		}
	}

	function checkIfLutrisLauncher(desktopFile) {
		var lutrisCommandRegex = /lutris lutris:rungameid\/(\d+)/
		var m1 = lutrisCommandRegex.exec(desktopFile['Exec'])
		var lutrisIconRegex = /^lutris_(.+)$/
		var m2 = lutrisIconRegex.exec(desktopFile['Icon'])
		if (m1 && m2) {
			tileEditorPresetTiles.lutrisGameSlug = m2[1]
		} else {
			tileEditorPresetTiles.lutrisGameSlug = '' // Reset
		}
	}

	Connections {
		target: appObj

		function onAppUrlChanged() {
			tileEditorPresetTiles.checkIfRecognizedLauncher()
		}

		function onIconSourceChanged() {
			tileEditorPresetTiles.checkIfRecognizedLauncher()
		}
	}

	GridLayout {
		id: content
		anchors.left: parent.left
		anchors.right: parent.right
		columns: 2

		//--- Steam
		// 4x2
		TileEditorPresetTileButton {
			appObj: tileEditorPresetTiles.appObj
			backgroundImageField: tileEditorPresetTiles.backgroundImageField
			labelField: tileEditorPresetTiles.labelField
			iconField: tileEditorPresetTiles.iconField
			tileGrid: tileEditorPresetTiles.tileGrid
			positionSizeField: tileEditorPresetTiles.positionSizeField
			filename: tileEditorPresetTiles.steamPresetSpecs.length > 0 ? tileEditorPresetTiles.steamPresetSpecs[0].filename : ''
			source: isSteamGameLauncher && tileEditorPresetTiles.steamPresetSpecs.length > 0 ? tileEditorPresetTiles.steamPresetSpecs[0].source : ''
			w: tileEditorPresetTiles.steamPresetSpecs.length > 0 ? tileEditorPresetTiles.steamPresetSpecs[0].w : 0
			h: tileEditorPresetTiles.steamPresetSpecs.length > 0 ? tileEditorPresetTiles.steamPresetSpecs[0].h : 0
		}

		// 3x1
		TileEditorPresetTileButton {
			appObj: tileEditorPresetTiles.appObj
			backgroundImageField: tileEditorPresetTiles.backgroundImageField
			labelField: tileEditorPresetTiles.labelField
			iconField: tileEditorPresetTiles.iconField
			tileGrid: tileEditorPresetTiles.tileGrid
			positionSizeField: tileEditorPresetTiles.positionSizeField
			filename: tileEditorPresetTiles.steamPresetSpecs.length > 1 ? tileEditorPresetTiles.steamPresetSpecs[1].filename : ''
			source: isSteamGameLauncher && tileEditorPresetTiles.steamPresetSpecs.length > 1 ? tileEditorPresetTiles.steamPresetSpecs[1].source : ''
			w: tileEditorPresetTiles.steamPresetSpecs.length > 1 ? tileEditorPresetTiles.steamPresetSpecs[1].w : 0
			h: tileEditorPresetTiles.steamPresetSpecs.length > 1 ? tileEditorPresetTiles.steamPresetSpecs[1].h : 0
		}

		// 5x3
		TileEditorPresetTileButton {
			appObj: tileEditorPresetTiles.appObj
			backgroundImageField: tileEditorPresetTiles.backgroundImageField
			labelField: tileEditorPresetTiles.labelField
			iconField: tileEditorPresetTiles.iconField
			tileGrid: tileEditorPresetTiles.tileGrid
			positionSizeField: tileEditorPresetTiles.positionSizeField
			filename: tileEditorPresetTiles.steamPresetSpecs.length > 2 ? tileEditorPresetTiles.steamPresetSpecs[2].filename : ''
			source: isSteamGameLauncher && tileEditorPresetTiles.steamPresetSpecs.length > 2 ? tileEditorPresetTiles.steamPresetSpecs[2].source : ''
			w: tileEditorPresetTiles.steamPresetSpecs.length > 2 ? tileEditorPresetTiles.steamPresetSpecs[2].w : 0
			h: tileEditorPresetTiles.steamPresetSpecs.length > 2 ? tileEditorPresetTiles.steamPresetSpecs[2].h : 0
		}

		// 5x2 or 2x1
		TileEditorPresetTileButton {
			appObj: tileEditorPresetTiles.appObj
			backgroundImageField: tileEditorPresetTiles.backgroundImageField
			labelField: tileEditorPresetTiles.labelField
			iconField: tileEditorPresetTiles.iconField
			tileGrid: tileEditorPresetTiles.tileGrid
			positionSizeField: tileEditorPresetTiles.positionSizeField
			filename: tileEditorPresetTiles.lutrisPresetSpecs.length > 0 ? tileEditorPresetTiles.lutrisPresetSpecs[0].filename : ''
			source: isLutrisGameLauncher && tileEditorPresetTiles.lutrisPresetSpecs.length > 0 ? tileEditorPresetTiles.lutrisPresetSpecs[0].source : ''
			w: tileEditorPresetTiles.lutrisPresetSpecs.length > 0 ? tileEditorPresetTiles.lutrisPresetSpecs[0].w : 0
			h: tileEditorPresetTiles.lutrisPresetSpecs.length > 0 ? tileEditorPresetTiles.lutrisPresetSpecs[0].h : 0
		}

		Text {
			Layout.columnSpan: 2
			Layout.fillWidth: true
			visible: !!tileEditorPresetTiles.igdbStatus
			text: tileEditorPresetTiles.igdbStatus
			wrapMode: Text.Wrap
			color: Qt.alpha("white", 0.8)
		}
	}
}
