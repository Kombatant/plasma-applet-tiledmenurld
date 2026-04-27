import QtQuick
import Qt.labs.platform as QtLabsPlatform
import "Utils.js" as Utils

QtObject {
	id: helper

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

	function standardPathForToken(token) {
		if (token === "%PICTURES%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.PicturesLocation)
		}
		if (token === "%DOCUMENTS%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DocumentsLocation)
		}
		if (token === "%MUSIC%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.MusicLocation)
		}
		if (token === "%DOWNLOADS%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DownloadLocation)
		}
		if (token === "%VIDEOS%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.MoviesLocation)
		}
		if (token === "%DESKTOP%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DesktopLocation)
		}
		if (token === "%HOME%") {
			return QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation)
		}
		return ""
	}

	function expandStandardPathToken(path) {
		var p = path || ""
		if (!p) {
			return ""
		}
		var match = /^(%[A-Z]+%)(\/.*)?$/.exec(p)
		if (!match || match.length < 2) {
			return p
		}
		var root = standardPathForToken(match[1])
		return root ? root + (match[2] || "") : p
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
		s = expandStandardPathToken(s)
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

	function saveGrabResultToPresetFolder(result, filename) {
		if (!result || !filename) {
			return ""
		}
		var dirs = candidateDirs()
		for (var i = 0; i < dirs.length; i++) {
			var localFilepath = dirs[i] + filename
			if (result.saveToFile(localFilepath)) {
				return localFilepath
			}
		}
		return ""
	}

	function steamGameIdForIcon(iconSource) {
		var match = /steam_icon_(\d+)/.exec(iconSource || "")
		return match ? match[1] : ""
	}

	function lutrisGameSlugForIcon(iconSource) {
		var match = /lutris_([\w\-]+)/.exec(iconSource || "")
		return match ? match[1] : ""
	}

	function presetSpecsForSteamGameId(gameId) {
		if (!gameId) {
			return []
		}
		return [
			{
				filename: 'steam_' + gameId + '_4x2.jpg',
				source: 'https://steamcdn-a.akamaihd.net/steam/apps/' + gameId + '/header.jpg',
				w: 4,
				h: 2
			},
			{
				filename: 'steam_' + gameId + '_3x1.jpg',
				source: 'https://steamcdn-a.akamaihd.net/steam/apps/' + gameId + '/capsule_184x69.jpg',
				w: 3,
				h: 1
			},
			{
				filename: 'steam_' + gameId + '_5x3.jpg',
				source: 'https://steamcdn-a.akamaihd.net/steam/apps/' + gameId + '/capsule_616x353.jpg',
				w: 5,
				h: 3
			}
		]
	}

	function presetSpecsForIgdbDetail(detail) {
		if (!detail || !detail.gameId) {
			return []
		}
		var specs = []
		var prefix = 'igdb_' + detail.gameId
		var artworks = detail.artworks || []
		var landscapeUrl = (artworks.length > 0 && artworks[0].url) ? artworks[0].url : ""
		if (!landscapeUrl) {
			var shots = detail.screenshots || []
			landscapeUrl = (shots.length > 0 && shots[0].url) ? shots[0].url : ""
		}
		if (landscapeUrl) {
			specs.push({ filename: prefix + '_4x2.jpg', source: landscapeUrl, w: 4, h: 2 })
			specs.push({ filename: prefix + '_3x1.jpg', source: landscapeUrl, w: 3, h: 1 })
			specs.push({ filename: prefix + '_5x3.jpg', source: landscapeUrl, w: 5, h: 3 })
		}
		var covers = detail.covers || []
		var coverUrl = (covers.length > 0 && covers[0].url) ? covers[0].url : ""
		if (coverUrl) {
			specs.push({ filename: prefix + '_1x1.jpg', source: coverUrl, w: 1, h: 1 })
			specs.push({ filename: prefix + '_2x2.jpg', source: coverUrl, w: 2, h: 2 })
		}
		return specs
	}

	function presetSpecsForLutrisGameSlug(gameSlug) {
		if (!gameSlug) {
			return []
		}
		return [{
			filename: 'lutris_' + gameSlug + '_2x1.jpg',
			source: 'https://lutris.net/games/banner/' + gameSlug + '.jpg',
			w: 2,
			h: 1
		}]
	}

	function launcherAppForLaunchUrl(launchUrl) {
		var favoriteId = Utils.kickerFavoriteId(launchUrl || "")
		if (!favoriteId || typeof appsModel === 'undefined' || !appsModel || typeof appsModel.getTileApp !== 'function') {
			return null
		}
		return appsModel.getTileApp(favoriteId)
	}

	function presetSpecsForLaunchUrl(launchUrl) {
		var app = launcherAppForLaunchUrl(launchUrl)
		if (!app) {
			return []
		}
		var iconSource = "" + (app.decoration || "")
		var specs = presetSpecsForSteamGameId(steamGameIdForIcon(iconSource))
		return specs.concat(presetSpecsForLutrisGameSlug(lutrisGameSlugForIcon(iconSource)))
	}
}