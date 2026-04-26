import QtQuick
import org.kde.plasma.plasmoid

import "lib/Requests.js" as Requests
import "lib"

Item {
	id: fetcher
	visible: false
	width: 0
	height: 0

	property bool secretReady: false
	property bool secretLoading: false

	readonly property string igdbClientId: (plasmoid && plasmoid.configuration && plasmoid.configuration.igdbClientId) ? ("" + plasmoid.configuration.igdbClientId).trim() : ""
	readonly property string igdbClientSecret: (secureIgdbClientSecret.secret || ((plasmoid && plasmoid.configuration && plasmoid.configuration.igdbClientSecret) ? plasmoid.configuration.igdbClientSecret : "") || "").trim()
	readonly property bool hasIgdbMetadataSettings: !!igdbClientId && !!igdbClientSecret

	TilePresetImageHelper {
		id: presetHelper
	}

	KWalletSecret {
		id: secureIgdbClientSecret
		entryName: "igdbClientSecret"
		onLoaded: function() {
			fetcher.secretLoading = false
			fetcher.secretReady = true
			fetcher._drainSecretWaiters()
		}
	}

	property var _secretWaiters: []

	function _drainSecretWaiters() {
		var waiters = _secretWaiters.slice()
		_secretWaiters = []
		for (var i = 0; i < waiters.length; i++) {
			waiters[i]()
		}
	}

	function _ensureSecretLoaded(callback) {
		if (secretReady || secureIgdbClientSecret.loadedOnce) {
			callback()
			return
		}
		_secretWaiters.push(callback)
		if (secretLoading) {
			return
		}
		secretLoading = true
		secureIgdbClientSecret.inspectAvailability()
		secureIgdbClientSecret.readSecret()
	}

	Component.onCompleted: {
		_ensureSecretLoaded(function() {})
	}

	function _steamGameIdForPage(page) {
		if (!page) {
			return ""
		}
		if (page.steamAppId) {
			return "" + page.steamAppId
		}
		var launchUrl = "" + (page.launchUrl || "")
		var directMatch = /steam:\/\/rungameid\/(\d+)/.exec(launchUrl)
		if (directMatch) {
			return directMatch[1]
		}
		var app = presetHelper.launcherAppForLaunchUrl(launchUrl)
		if (!app) {
			return presetHelper.steamGameIdForIcon(page.iconName || "")
		}
		return presetHelper.steamGameIdForIcon(app.decoration || page.iconName || "")
	}

	function _parseJsonResponse(err, text, callback) {
		if (err) {
			callback(err, null)
			return
		}
		try {
			callback(null, JSON.parse(text || "null"))
		} catch (e) {
			callback(i18n("Received malformed JSON."), null)
		}
	}

	function _stripHtml(text) {
		var s = "" + (text || "")
		s = s.replace(/<\s*br\s*\/?>/gi, "\n")
		s = s.replace(/<[^>]+>/g, " ")
		s = s.replace(/&nbsp;/g, " ")
		s = s.replace(/&amp;/g, "&")
		s = s.replace(/&quot;/g, '"')
		s = s.replace(/&#39;/g, "'")
		s = s.replace(/&lt;/g, "<")
		s = s.replace(/&gt;/g, ">")
		s = s.replace(/[ \t\r\n]+/g, " ")
		return s.trim()
	}

	function _steamDescription(data) {
		if (!data) {
			return ""
		}
		var shortText = _stripHtml(data.short_description || "")
		if (shortText) {
			return shortText
		}
		return _stripHtml(data.about_the_game || data.detailed_description || "")
	}

	function _steamYear(data) {
		var raw = data && data.release_date ? ("" + (data.release_date.date || "")) : ""
		var match = /(19|20)\d\d/.exec(raw)
		return match ? match[0] : ""
	}

	function _requestSteamDetails(appId, callback) {
		var url = "https://store.steampowered.com/api/appdetails?appids=" + encodeURIComponent(appId) + "&l=english&cc=us"
		Requests.request({
			url: url,
			headers: {
				"Accept": "application/json"
			}
		}, function(err, text) {
			_parseJsonResponse(err, text, function(parseErr, payload) {
				if (parseErr) {
					callback(parseErr, null)
					return
				}
				var node = payload && payload[appId]
				if (!node || !node.success || !node.data) {
					callback(i18n("Steam did not return store details for app %1.", appId), null)
					return
				}
				callback(null, node.data)
			})
		})
	}

	function _requestIgdbToken(clientId, clientSecret, callback) {
		Requests.post({
			url: "https://id.twitch.tv/oauth2/token",
			data: {
				client_id: clientId,
				client_secret: clientSecret,
				grant_type: "client_credentials"
			}
		}, function(err, text) {
			_parseJsonResponse(err, text, function(parseErr, payload) {
				if (parseErr) {
					callback(parseErr, "")
					return
				}
				var accessToken = payload && payload.access_token ? ("" + payload.access_token) : ""
				if (!accessToken) {
					callback(i18n("IGDB authentication failed."), "")
					return
				}
				callback(null, accessToken)
			})
		})
	}

	function _igdbRequest(path, query, clientId, accessToken, callback) {
		Requests.request({
			method: "POST",
			url: "https://api.igdb.com/v4/" + path,
			data: query,
			headers: {
				"Accept": "application/json",
				"Client-ID": clientId,
				"Authorization": "Bearer " + accessToken,
				"Content-Type": "text/plain"
			}
		}, function(err, text) {
			_parseJsonResponse(err, text, callback)
		})
	}

	function _findIgdbGameIdBySteamAppId(appId, clientId, accessToken, callback) {
		var query = 'fields game; where uid = "' + ("" + appId).replace(/"/g, '\\"') + '" & external_game_source = 1; limit 1;'
		_igdbRequest("external_games", query, clientId, accessToken, function(err, payload) {
			if (err) {
				callback(err, 0)
				return
			}
			if (!payload || !payload.length || !payload[0].game) {
				callback(i18n("IGDB has no Steam mapping for app %1.", appId), 0)
				return
			}
			callback(null, payload[0].game)
		})
	}

	function _findIgdbGameIdByTitle(title, year, clientId, accessToken, callback) {
		var safeTitle = ("" + (title || "")).replace(/"/g, '\\"')
		var query = 'search "' + safeTitle + '"; fields name,first_release_date; limit 5;'
		_igdbRequest("games", query, clientId, accessToken, function(err, payload) {
			if (err) {
				callback(err, 0)
				return
			}
			var normalizedTitle = safeTitle.toLowerCase()
			var chosenId = 0
			for (var i = 0; payload && i < payload.length; i++) {
				var item = payload[i]
				if (!item || !item.id || !item.name) {
					continue
				}
				if (("" + item.name).toLowerCase() !== normalizedTitle) {
					continue
				}
				if (!year || !item.first_release_date) {
					chosenId = item.id
					break
				}
				var itemYear = new Date(item.first_release_date * 1000).getUTCFullYear()
				if (("" + itemYear) === ("" + year)) {
					chosenId = item.id
					break
				}
				if (!chosenId) {
					chosenId = item.id
				}
			}
			if (!chosenId) {
				callback(i18n("IGDB has no title match for %1.", title), 0)
				return
			}
			callback(null, chosenId)
		})
	}

	function _collectIgdbTags(game) {
		var tags = []
		var seen = {}

		function pushName(name) {
			var s = ("" + (name || "")).trim()
			if (!s) {
				return
			}
			var key = s.toLowerCase()
			if (seen[key]) {
				return
			}
			seen[key] = true
			tags.push(s)
		}

		function pushList(list) {
			for (var i = 0; list && i < list.length; i++) {
				pushName(list[i] && list[i].name)
			}
		}

		pushList(game && game.genres)
		pushList(game && game.themes)
		pushList(game && game.game_modes)
		pushList(game && game.keywords)
		return tags
	}

	function _requestIgdbGameTags(gameId, clientId, accessToken, callback) {
		var query = "fields name,genres.name,themes.name,game_modes.name,keywords.name; where id = " + gameId + "; limit 1;"
		_igdbRequest("games", query, clientId, accessToken, function(err, payload) {
			if (err) {
				callback(err, [])
				return
			}
			if (!payload || !payload.length) {
				callback(i18n("IGDB returned no data for game %1.", gameId), [])
				return
			}
			callback(null, _collectIgdbTags(payload[0]))
		})
	}

	function fetchForPage(page, callback) {
		var appId = _steamGameIdForPage(page)
		if (!appId) {
			callback(false, null, i18n("This hero page is not linked to a Steam game launcher."))
			return
		}
		_ensureSecretLoaded(function() {
			_requestSteamDetails(appId, function(steamErr, steamData) {
				if (steamErr) {
					callback(false, null, steamErr)
					return
				}

				var result = {
					steamAppId: "" + appId,
					storeTitle: "" + (steamData.name || ""),
					storeDescription: _steamDescription(steamData),
					igdbTags: []
				}

				if (!igdbClientId || !igdbClientSecret) {
					callback(true, result, i18n("Saved the Steam store info, but IGDB credentials are missing so no tags were downloaded."))
					return
				}

				_requestIgdbToken(igdbClientId, igdbClientSecret, function(tokenErr, accessToken) {
					if (tokenErr) {
						callback(true, result, i18n("Saved the Steam store info, but IGDB authentication failed."))
						return
					}

					_findIgdbGameIdBySteamAppId(appId, igdbClientId, accessToken, function(mappingErr, gameId) {
						function requestTagsForGame(resolvedGameId) {
							_requestIgdbGameTags(resolvedGameId, igdbClientId, accessToken, function(tagErr, tags) {
								if (tagErr) {
									callback(true, result, i18n("Saved the Steam store info, but downloading IGDB tags failed."))
									return
								}
								result.igdbTags = tags
								callback(true, result, "")
							})
						}

						if (!mappingErr && gameId) {
							requestTagsForGame(gameId)
							return
						}

						_findIgdbGameIdByTitle(result.storeTitle || page.label || "", _steamYear(steamData), igdbClientId, accessToken, function(searchErr, fallbackGameId) {
							if (searchErr || !fallbackGameId) {
								callback(true, result, i18n("Saved the Steam store info, but no IGDB game match was found."))
								return
							}
							requestTagsForGame(fallbackGameId)
						})
					})
				})
			})
		})
	}
}