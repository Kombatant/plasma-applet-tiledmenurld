.pragma library

function endsWith(value, suffix) {
	value = "" + value
	return value.length >= suffix.length && value.lastIndexOf(suffix) === value.length - suffix.length
}

function parseDropUrl(url) {
	if (typeof url === "undefined" || url === null) {
		return ""
	}
	url = "" + url
	if (!url) {
		return url
	}

	var startsWithAppsScheme = url.indexOf('applications:') === 0 // Search Results add this prefix
	if (url.indexOf('applications://') === 0) {
		url = url.substr('applications://'.length)
	} else if (startsWithAppsScheme) {
		url = url.substr('applications:'.length)
	}
	if (startsWithAppsScheme) {
		while (url.indexOf('/') === 0) {
			url = url.substr(1)
		}
	}

	var workingDir = Qt.resolvedUrl('.')
	var isDesktopUrl = endsWith(url, '.desktop')
	var isRelativeDesktopUrl = isDesktopUrl && (
		url.indexOf(workingDir) === 0
		// || url.indexOf('file:///usr/share/applications/') === 0
		// || url.indexOf('/.local/share/applications/') >= 0
		|| url.indexOf('/share/applications/') >= 0 // 99% certain this desktop file should be accessed relatively.
	)
	if (isRelativeDesktopUrl) {
		// Remove the path because .favoriteId is just the file name.
		// However passing the favoriteId in mimeData.url will prefix the current QML path because it's a QUrl.
		var tokens = url.toString().split('/')
		var favoriteId = tokens[tokens.length-1]
		return favoriteId
	} else {
		return url
	}
}

function isKickerFavoriteId(url) {
	var favoriteId = parseDropUrl(url)
	if (!favoriteId) {
		return false
	}

	favoriteId = "" + favoriteId
	if (favoriteId.indexOf("://") >= 0 || favoriteId.indexOf("/") >= 0 || favoriteId.indexOf("\\") >= 0) {
		return false
	}

	return endsWith(favoriteId, ".desktop")
}

function kickerFavoriteId(url) {
	var favoriteId = parseDropUrl(url)
	return isKickerFavoriteId(favoriteId) ? ("" + favoriteId) : ""
}
