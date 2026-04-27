import QtQuick
import Qt.labs.platform as QtLabsPlatform
import org.kde.plasma.plasma5support as Plasma5Support

import "lib/Requests.js" as Requests

Item {
	id: fetcher
	visible: false
	width: 0
	height: 0

	readonly property string homeDir: {
		var home = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation) || ""
		return ("" + home).replace(/^file:\/\//, "")
	}

	readonly property string heroicCacheDir: {
		var home = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation) || ""
		var base = ("" + home).replace(/^file:\/\//, "")
		return base ? base + "/.config/heroic/store_cache/" : ""
	}

	readonly property var heroicLibraryFiles: [
		"legendary_library.json",
		"gog_library.json",
		"nile_library.json"
	]

	property var _heroicLibraryCache: ({})
	property var _pendingReads: ({})

	Plasma5Support.DataSource {
		id: catExec
		engine: "executable"
		connectedSources: []
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var pending = fetcher._pendingReads[sourceName]
			delete fetcher._pendingReads[sourceName]
			if (!pending || !pending.callback) return
			var exitCode = data && typeof data["exit code"] !== "undefined" ? data["exit code"] : -1
			var stdout = data && data.stdout ? ("" + data.stdout) : ""
			if (exitCode !== 0 || !stdout) {
				pending.callback("cat failed (exit " + exitCode + ")", null)
				return
			}
			if (pending.kind === "text") {
				pending.callback(null, stdout)
				return
			}
			try {
				pending.callback(null, JSON.parse(stdout))
			} catch (e) {
				pending.callback("Malformed JSON from " + sourceName, null)
			}
		}
	}

	function _shellEscape(path) {
		return "'" + ("" + path).replace(/'/g, "'\\''") + "'"
	}

	function _readJsonFile(path, callback) {
		var cmd = "cat " + _shellEscape(path)
		_pendingReads[cmd] = { kind: "json", callback: callback }
		catExec.connectSource(cmd)
	}

	function _readTextFile(path, callback) {
		var cmd = "cat " + _shellEscape(path)
		_pendingReads[cmd] = { kind: "text", callback: callback }
		catExec.connectSource(cmd)
	}

	function _looksLikeDesktopEntry(value) {
		return /\.desktop($|[?#])/i.test("" + (value || ""))
	}

	function _desktopFileCandidates(launchUrl, favoriteId, appUrl) {
		var candidates = []

		function addCandidate(value) {
			var candidate = ("" + (value || "")).trim()
			if (!candidate) return
			if (candidate.indexOf("file://") === 0) {
				candidate = candidate.substring("file://".length)
			}
			if (!fetcher._looksLikeDesktopEntry(candidate)) return
			if (candidate.indexOf("/") < 0) {
				if (fetcher.homeDir) {
					candidates.push(fetcher.homeDir + "/.local/share/applications/" + candidate)
					candidates.push(fetcher.homeDir + "/.local/share/flatpak/exports/share/applications/" + candidate)
				}
				candidates.push("/usr/share/applications/" + candidate)
				candidates.push("/var/lib/flatpak/exports/share/applications/" + candidate)
				return
			}
			candidates.push(candidate)
		}

		addCandidate(launchUrl)
		addCandidate(appUrl)
		addCandidate(favoriteId)

		var deduped = []
		for (var i = 0; i < candidates.length; i++) {
			if (deduped.indexOf(candidates[i]) < 0) {
				deduped.push(candidates[i])
			}
		}
		return deduped
	}

	function _desktopEntryValue(text, key) {
		var match = new RegExp("^" + key + "=(.*)$", "m").exec("" + (text || ""))
		return match ? ("" + match[1]).trim() : ""
	}

	function _readDesktopFile(launchUrl, favoriteId, appUrl, callback) {
		var candidates = _desktopFileCandidates(launchUrl, favoriteId, appUrl)
		function tryCandidate(index) {
			if (index >= candidates.length) {
				callback("No desktop file found.", "")
				return
			}
			_readTextFile(candidates[index], function(err, text) {
				if (!err && text) {
					callback(null, text)
					return
				}
				tryCandidate(index + 1)
			})
		}
		tryCandidate(0)
	}

	function _launcherInfoFromApp(app, launchUrl) {
		var heroicAppName = _heroicAppNameForApp(app, launchUrl)
		if (heroicAppName) {
			return {
				kind: "heroic",
				heroicAppName: heroicAppName,
				lutrisSlug: ""
			}
		}
		var lutrisSlug = _lutrisSlugForApp(app, launchUrl)
		if (lutrisSlug) {
			return {
				kind: "lutris",
				heroicAppName: "",
				lutrisSlug: lutrisSlug
			}
		}
		return {
			kind: "",
			heroicAppName: "",
			lutrisSlug: ""
		}
	}

	function resolveLauncherInfo(app, launchUrl, favoriteId, callback) {
		var info = _launcherInfoFromApp(app, launchUrl)
		if (info.kind) {
			callback(info)
			return
		}
		_readDesktopFile(launchUrl, favoriteId, app && app.url, function(err, text) {
			if (err || !text) {
				callback(info)
				return
			}
			var execValue = _desktopEntryValue(text, "Exec")
			var iconValue = _desktopEntryValue(text, "Icon")
			callback(_launcherInfoFromApp({ decoration: iconValue }, execValue))
		})
	}

	function _heroicAppNameForApp(app, launchUrl) {
		var iconSource = "" + ((app && app.decoration) || "")
		if (/heroic\/icons\//i.test(iconSource)) {
			return "heroic"
		}
		var match = /heroic:\/\/launch\?[^"]*appName=([^&"\s]+)/i.exec("" + (launchUrl || ""))
		if (match) {
			return decodeURIComponent(match[1])
		}
		return ""
	}

	function _lutrisSlugForApp(app, launchUrl) {
		var iconSource = "" + ((app && app.decoration) || "")
		var match = /lutris_([\w\-]+)/.exec(iconSource)
		if (match) {
			return match[1]
		}
		match = /lutris:rungame\/([\w\-]+)/.exec("" + (launchUrl || ""))
		if (match) {
			return match[1]
		}
		return ""
	}

	function _findHeroicGame(appName, libraries) {
		for (var i = 0; i < libraries.length; i++) {
			var lib = libraries[i]
			var entries = (lib && (lib.library || lib.games)) || []
			for (var j = 0; j < entries.length; j++) {
				var entry = entries[j]
				if (entry && ("" + entry.app_name) === appName) {
					return entry
				}
			}
		}
		return null
	}

	function _heroicResultFromEntry(entry) {
		var about = (entry && entry.extra && entry.extra.about) || {}
		var description = ("" + (about.description || about.shortDescription || "")).trim()
		var tags = []
		var genres = (entry && entry.extra && entry.extra.genres) || []
		for (var i = 0; i < genres.length; i++) {
			var g = ("" + genres[i]).trim()
			if (g) {
				tags.push(g)
			}
		}
		return {
			storeTitle: "" + (entry.title || ""),
			storeDescription: description,
			igdbTags: tags
		}
	}

	function _loadHeroicLibraries(callback) {
		if (!heroicCacheDir) {
			callback([])
			return
		}
		var libs = []
		var pending = heroicLibraryFiles.length
		for (var i = 0; i < heroicLibraryFiles.length; i++) {
			var name = heroicLibraryFiles[i]
			if (_heroicLibraryCache[name]) {
				libs.push(_heroicLibraryCache[name])
				if (--pending === 0) callback(libs)
				continue
			}
			(function(fname) {
				_readJsonFile(heroicCacheDir + fname, function(err, data) {
					if (!err && data) {
						_heroicLibraryCache[fname] = data
						libs.push(data)
					}
					if (--pending === 0) {
						callback(libs)
					}
				})
			})(name)
		}
	}

	function fetchHeroic(appName, callback) {
		_loadHeroicLibraries(function(libs) {
			if (!libs.length) {
				callback("Could not read Heroic library cache.", null)
				return
			}
			var entry = _findHeroicGame(appName, libs)
			if (!entry) {
				callback("No Heroic library entry for " + appName, null)
				return
			}
			callback(null, _heroicResultFromEntry(entry))
		})
	}

	function fetchLutris(slug, callback) {
		Requests.request({
			url: "https://lutris.net/api/games/" + encodeURIComponent(slug),
			headers: { "Accept": "application/json" }
		}, function(err, text) {
			if (err) {
				callback(err, null)
				return
			}
			try {
				var data = JSON.parse(text || "null")
				if (!data || !data.slug) {
					callback("Lutris API returned no data for " + slug, null)
					return
				}
				var tags = []
				var genres = data.genres || []
				for (var i = 0; i < genres.length; i++) {
					var g = ("" + (genres[i] && genres[i].name || "")).trim()
					if (g) tags.push(g)
				}
				callback(null, {
					storeTitle: "" + (data.name || ""),
					storeDescription: ("" + (data.description || "")).trim(),
					igdbTags: tags
				})
			} catch (e) {
				callback("Malformed Lutris JSON for " + slug, null)
			}
		})
	}

	function fetchForApp(app, launchUrl, callback) {
		resolveLauncherInfo(app, launchUrl, "", function(info) {
			if (info.heroicAppName) {
				fetchHeroic(info.heroicAppName, callback)
				return
			}
			if (info.lutrisSlug) {
				fetchLutris(info.lutrisSlug, callback)
				return
			}
			callback("Not a Heroic or Lutris launcher.", null)
		})
	}

	function detectKindForApp(app, launchUrl) {
		if (_heroicAppNameForApp(app, launchUrl)) return "heroic"
		if (_lutrisSlugForApp(app, launchUrl)) return "lutris"
		return ""
	}
}
