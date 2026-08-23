import QtQuick
import QtQuick.Layouts

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
	property var steamPresetSpecs: []
	readonly property var lutrisPresetSpecs: presetHelper.presetSpecsForLutrisGameSlug(lutrisGameSlug)
	property var igdbPresetSpecs: []
	readonly property var presetSpecs: steamPresetSpecs.concat(lutrisPresetSpecs).concat(igdbPresetSpecs)
	property bool steamLoading: false
	property bool igdbLoading: false
	property bool igdbAttempted: false
	property string igdbStatus: ''
	property int requestGeneration: 0

	TilePresetImageHelper {
		id: presetHelper
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
		function onSecretReadyChanged() {
			// Secret finished loading from KWallet. If it was empty (no entry
			// stored), hasIgdbMetadataSettings stays false and the change
			// handler above never fires, so clear the "Looking up..." status
			// and show the missing-credentials hint for relevant launchers.
			if (metadataFetcher.secretReady && !metadataFetcher.hasIgdbMetadataSettings
				&& (tileEditorPresetTiles.isSteamGameLauncher || tileEditorPresetTiles.isHeroicGameLauncher || tileEditorPresetTiles.isLutrisGameLauncher)) {
				tileEditorPresetTiles.igdbStatus = i18n("Set the IGDB Client ID and Client Secret in the Tiles settings to download artwork.")
				tileEditorPresetTiles.checkForPreset()
			}
		}
	}

	visible: false
	function checkForPreset() {
		visible = presetSpecs.length > 0 || steamLoading || igdbLoading || !!igdbStatus
	}
	onPresetSpecsChanged: checkForPreset()
	onSteamLoadingChanged: checkForPreset()
	onIgdbLoadingChanged: checkForPreset()
	onIgdbStatusChanged: checkForPreset()
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
		return s.length >= substr.length && s.lastIndexOf(substr) == s.length - substr.length
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
		tileEditorPresetTiles.requestGeneration += 1
		tileEditorPresetTiles.steamGameId = ''
		tileEditorPresetTiles.lutrisGameSlug = ''
		tileEditorPresetTiles.heroicAppName = ''
		tileEditorPresetTiles.recognizedLauncherKind = ''
		tileEditorPresetTiles.steamPresetSpecs = []
		tileEditorPresetTiles.igdbPresetSpecs = []
		tileEditorPresetTiles.steamLoading = false
		tileEditorPresetTiles.igdbLoading = false
		tileEditorPresetTiles.igdbAttempted = false
		tileEditorPresetTiles.igdbStatus = ''
	}

	function _launchUrlForApp() {
		if (appObj && appObj.tile && appObj.tile.launchUrl) return "" + appObj.tile.launchUrl
		if (appObj && appObj.favoriteId) return "" + appObj.favoriteId
		return ''
	}

	function checkIfRecognizedLauncher() {
		resetRecognizedLaunchers()
		var generation = requestGeneration
		checkForPreset()

		if (!appObj) {
			return
		}

		checkIfSteamIcon(appObj.iconSource)
		if (steamGameId) {
			fetchSteamArt(steamGameId, generation)
			maybeFetchIgdbArt()
		}
		launcherFetcher.resolveLauncherInfo(appObj.app, _launchUrlForApp(), appObj.favoriteId || '', function(info) {
			if (generation !== tileEditorPresetTiles.requestGeneration) return
			tileEditorPresetTiles._applyResolvedLauncherInfo(info)
			tileEditorPresetTiles.checkForPreset()
			tileEditorPresetTiles.maybeFetchIgdbArt()
		})

		// Lutris does not use game id in icon name. Eg: lutris_overwatch instead of lutris_game_1
	}

	function fetchSteamArt(appId, generation) {
		steamLoading = true
		metadataFetcher.fetchSteamArtwork(appId, function(err, detail) {
			if (generation !== tileEditorPresetTiles.requestGeneration || appId !== tileEditorPresetTiles.steamGameId) return
			steamLoading = false
			steamPresetSpecs = (!err && detail) ? presetHelper.presetSpecsForSteamDetail(detail) : []
			checkForPreset()
		})
	}

	function _titleForApp() {
		if (appObj && appObj.appLabel) return ("" + appObj.appLabel).trim()
		if (appObj && appObj.tile && appObj.tile.label) return ("" + appObj.tile.label).trim()
		if (appObj && appObj.labelText) return ("" + appObj.labelText).trim()
		return ''
	}

	function maybeFetchIgdbArt() {
		if (!isSteamGameLauncher && !isHeroicGameLauncher && !isLutrisGameLauncher) {
			igdbStatus = ''
			checkForPreset()
			return
		}
		if (!metadataFetcher.hasIgdbMetadataSettings) {
			// The client secret lives in KWallet and is read lazily. When a
			// client id is configured but the secret has not been loaded yet,
			// warm it so KWallet prompts to unlock; hasIgdbMetadataSettings then
			// flips and the onHasIgdbMetadataSettingsChanged handler re-runs this.
			if (metadataFetcher.igdbClientId) {
				igdbStatus = i18n("Looking up IGDB artwork...")
				checkForPreset()
				metadataFetcher.warmSecret()
				return
			}
			igdbStatus = i18n("Set the IGDB Client ID and Client Secret in the Tiles settings to download artwork.")
			checkForPreset()
			return
		}
		if (igdbPresetSpecs.length > 0 || igdbLoading || igdbAttempted) return
		var title = _titleForApp()
		if (!title) {
			igdbStatus = i18n("Could not determine a title for this launcher.")
			checkForPreset()
			return
		}
		var generation = requestGeneration
		var requestedSteamAppId = steamGameId
		igdbAttempted = true
		igdbLoading = true
		igdbStatus = i18n("Looking up IGDB artwork...")
		checkForPreset()
		var fetchCallback = function(err, detail) {
			if (generation !== tileEditorPresetTiles.requestGeneration || requestedSteamAppId !== tileEditorPresetTiles.steamGameId) return
			igdbLoading = false
			if (err || !detail) {
				igdbStatus = err || i18n("No IGDB artwork found.")
				checkForPreset()
				return
			}
			igdbPresetSpecs = presetHelper.presetSpecsForIgdbDetail(detail)
			igdbStatus = ''
			checkForPreset()
		}
		if (requestedSteamAppId) {
			metadataFetcher.fetchIgdbArtworksBySteamAppId(requestedSteamAppId, title, fetchCallback)
		} else {
			metadataFetcher.fetchIgdbArtworksByTitle(title, fetchCallback)
		}
	}

	function removeFailedPreset(spec) {
		if (!spec || !spec.source) return
		var failedSource = "" + spec.source
		if (spec.provider === 'steam') {
			steamPresetSpecs = steamPresetSpecs.filter(function(item) { return ("" + item.source) !== failedSource })
			maybeFetchIgdbArt()
		} else if (spec.provider === 'igdb') {
			igdbPresetSpecs = igdbPresetSpecs.filter(function(item) { return ("" + item.source) !== failedSource })
		}
		checkForPreset()
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

		Repeater {
			model: tileEditorPresetTiles.presetSpecs
			delegate: TileEditorPresetTileButton {
				appObj: tileEditorPresetTiles.appObj
				backgroundImageField: tileEditorPresetTiles.backgroundImageField
				labelField: tileEditorPresetTiles.labelField
				iconField: tileEditorPresetTiles.iconField
				tileGrid: tileEditorPresetTiles.tileGrid
				positionSizeField: tileEditorPresetTiles.positionSizeField
				spec: modelData
				filename: modelData.filename
				source: modelData.source
				w: modelData.w
				h: modelData.h
				onImageLoadFailed: function(failedSpec) {
					tileEditorPresetTiles.removeFailedPreset(failedSpec)
				}
			}
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
