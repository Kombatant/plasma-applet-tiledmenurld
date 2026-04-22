.pragma library

function parseDropUrl(url) {
	if (typeof url === "undefined" || url === null) {
		return ""
	}
	url = "" + url
	if (!url) {
		return url
	}

	var startsWithAppsScheme = url.indexOf('applications:') === 0 // Search Results add this prefix
	if (startsWithAppsScheme) {
		url = url.substr('applications:'.length)
	}

	var workingDir = Qt.resolvedUrl('.')
	var endsWithDesktop = url.indexOf('.desktop') === url.length - '.desktop'.length
	var isRelativeDesktopUrl = endsWithDesktop && (
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

	return favoriteId.indexOf(".desktop") === favoriteId.length - ".desktop".length
}

function kickerFavoriteId(url) {
	var favoriteId = parseDropUrl(url)
	return isKickerFavoriteId(favoriteId) ? ("" + favoriteId) : ""
}
