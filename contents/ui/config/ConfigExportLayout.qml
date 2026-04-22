import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import Qt.labs.platform as QtLabsPlatform
import "../libconfig/ConfigUtils.js" as ConfigUtils
import "../lib/Base64.js" as Base64

import ".." as TiledMenu

Item {
	id: page
	implicitWidth: contentLayout.implicitWidth + Kirigami.Units.gridUnit * 4
	implicitHeight: contentLayout.implicitHeight + Kirigami.Units.gridUnit * 4

	// Plasma's config dialog sets these initial properties on each page root.
	// This page does not use FormKCM, so it declares them directly.
	property string title: ""
	property var cfg_icon
	property var cfg_iconDefault
	property var cfg_fixedPanelIcon
	property var cfg_fixedPanelIconDefault
	property var cfg_searchResultsGrouped
	property var cfg_searchResultsGroupedDefault
	property var cfg_searchDefaultFilters
	property var cfg_searchDefaultFiltersDefault
	property var cfg_showRecentApps
	property var cfg_showRecentAppsDefault
	property var cfg_recentOrdering
	property var cfg_recentOrderingDefault
	property var cfg_numRecentApps
	property var cfg_numRecentAppsDefault
	property var cfg_sidebarShortcuts
	property var cfg_sidebarShortcutsDefault
	property var cfg_sidebarCollapsibleSearchResults
	property var cfg_sidebarCollapsibleSearchResultsDefault
	property var cfg_customAvatarPath
	property var cfg_customAvatarPathDefault
	property var cfg_defaultAppListView
	property var cfg_defaultAppListViewDefault
	property var cfg_lastUsedAppListView
	property var cfg_lastUsedAppListViewDefault
	property var cfg_aiChatEnabled
	property var cfg_aiChatEnabledDefault
	property var cfg_aiProvider
	property var cfg_aiProviderDefault
	property var cfg_aiApiKey
	property var cfg_aiApiKeyDefault
	property var cfg_aiOllamaUrl
	property var cfg_aiOllamaUrlDefault
	property var cfg_aiOpenWebUiUrl
	property var cfg_aiOpenWebUiUrlDefault
	property var cfg_aiModel
	property var cfg_aiModelDefault
	property var cfg_aiDetectedModels
	property var cfg_aiDetectedModelsDefault
	property var cfg_aiChatHistory
	property var cfg_aiChatHistoryDefault
	property var cfg_aiStreamChat
	property var cfg_aiStreamChatDefault
	property var cfg_terminalApp
	property var cfg_terminalAppDefault
	property var cfg_taskManagerApp
	property var cfg_taskManagerAppDefault
	property var cfg_fileManagerApp
	property var cfg_fileManagerAppDefault
	property var cfg_useTileTabs
	property var cfg_useTileTabsDefault
	property var cfg_tileTabStyle
	property var cfg_tileTabStyleDefault
	property var cfg_tileTabs
	property var cfg_tileTabsDefault
	property var cfg_tileModel
	property var cfg_tileModelDefault
	property var cfg_tileScale
	property var cfg_tileScaleDefault
	property var cfg_tileIconSize
	property var cfg_tileIconSizeDefault
	property var cfg_tileMargin
	property var cfg_tileMarginDefault
	property var cfg_tileRoundedCorners
	property var cfg_tileRoundedCornersDefault
	property var cfg_tileCornerRadius
	property var cfg_tileCornerRadiusDefault
	property var cfg_tilesLocked
	property var cfg_tilesLockedDefault
	property var cfg_tileHoverEffect
	property var cfg_tileHoverEffectDefault
	property var cfg_tileAnimatedPlayOnHover
	property var cfg_tileAnimatedPlayOnHoverDefault
	property var cfg_showTileTooltips
	property var cfg_showTileTooltipsDefault
	property var cfg_defaultTileColor
	property var cfg_defaultTileColorDefault
	property var cfg_defaultTileGradient
	property var cfg_defaultTileGradientDefault
	property var cfg_sidebarBackgroundColor
	property var cfg_sidebarBackgroundColorDefault
	property var cfg_hideSearchField
	property var cfg_hideSearchFieldDefault
	property var cfg_searchOnTop
	property var cfg_searchOnTopDefault
	property var cfg_searchFieldFollowsTheme
	property var cfg_searchFieldFollowsThemeDefault
	property var cfg_sidebarFollowsTheme
	property var cfg_sidebarFollowsThemeDefault
	property var cfg_sidebarHideBorder
	property var cfg_sidebarHideBorderDefault
	property var cfg_tileLabelAlignment
	property var cfg_tileLabelAlignmentDefault
	property var cfg_groupLabelAlignment
	property var cfg_groupLabelAlignmentDefault
	property var cfg_tileGroupLayout
	property var cfg_tileGroupLayoutDefault
	property var cfg_presetTilesFolder
	property var cfg_presetTilesFolderDefault
	property var cfg_appDescription
	property var cfg_appDescriptionDefault
	property var cfg_appListIconSize
	property var cfg_appListIconSizeDefault
	property var cfg_searchFieldHeight
	property var cfg_searchFieldHeightDefault
	property var cfg_dockedSearchFieldWidth
	property var cfg_dockedSearchFieldWidthDefault
	property var cfg_appListWidth
	property var cfg_appListWidthDefault
	property var cfg_dockedSidebarWidth
	property var cfg_dockedSidebarWidthDefault
	property var cfg_popupHeight
	property var cfg_popupHeightDefault
	property var cfg_popupHeightAlphabetical
	property var cfg_popupHeightAlphabeticalDefault
	property var cfg_popupWidthAlphabetical
	property var cfg_popupWidthAlphabeticalDefault
	property var cfg_favGridColsAlphabetical
	property var cfg_favGridColsAlphabeticalDefault
	property var cfg_popupHeightCategories
	property var cfg_popupHeightCategoriesDefault
	property var cfg_popupWidthCategories
	property var cfg_popupWidthCategoriesDefault
	property var cfg_favGridColsCategories
	property var cfg_favGridColsCategoriesDefault
	property var cfg_popupHeightTilesOnly
	property var cfg_popupHeightTilesOnlyDefault
	property var cfg_popupWidthTilesOnly
	property var cfg_popupWidthTilesOnlyDefault
	property var cfg_favGridColsTilesOnly
	property var cfg_favGridColsTilesOnlyDefault
	property var cfg_popupHeightAiChat
	property var cfg_popupHeightAiChatDefault
	property var cfg_popupWidthAiChat
	property var cfg_popupWidthAiChatDefault
	property var cfg_favGridColsAiChat
	property var cfg_favGridColsAiChatDefault
	property var cfg_popupHeightDockedAlphabetical
	property var cfg_popupHeightDockedAlphabeticalDefault
	property var cfg_popupWidthDockedAlphabetical
	property var cfg_popupWidthDockedAlphabeticalDefault
	property var cfg_favGridColsDockedAlphabetical
	property var cfg_favGridColsDockedAlphabeticalDefault
	property var cfg_popupHeightDockedCategories
	property var cfg_popupHeightDockedCategoriesDefault
	property var cfg_popupWidthDockedCategories
	property var cfg_popupWidthDockedCategoriesDefault
	property var cfg_favGridColsDockedCategories
	property var cfg_favGridColsDockedCategoriesDefault
	property var cfg_popupHeightDockedTilesOnly
	property var cfg_popupHeightDockedTilesOnlyDefault
	property var cfg_popupWidthDockedTilesOnly
	property var cfg_popupWidthDockedTilesOnlyDefault
	property var cfg_favGridColsDockedTilesOnly
	property var cfg_favGridColsDockedTilesOnlyDefault
	property var cfg_popupHeightDockedAiChat
	property var cfg_popupHeightDockedAiChatDefault
	property var cfg_popupWidthDockedAiChat
	property var cfg_popupWidthDockedAiChatDefault
	property var cfg_favGridColsDockedAiChat
	property var cfg_favGridColsDockedAiChatDefault
	property var cfg_favGridCols
	property var cfg_favGridColsDefault
	property var cfg_sidebarButtonSize
	property var cfg_sidebarButtonSizeDefault
	property var cfg_sidebarIconSize
	property var cfg_sidebarIconSizeDefault
	property var cfg_sidebarPosition
	property var cfg_sidebarPositionDefault
	property var cfg_useDockedLayout
	property var cfg_useDockedLayoutDefault

	// Force Window color scheme instead of inheriting Plasma theme colors
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	// Ensure defaults are initialized even if the user opens this page first.
	TiledMenu.AppletConfig {
		id: _configInit
	}

	// Schema sourced from contents/config/main.xml.
	readonly property var settingsSchema: ({
		icon: "string",
		fixedPanelIcon: "bool",
		searchResultsGrouped: "bool",
		searchDefaultFilters: "stringlist",
		showRecentApps: "bool",
		recentOrdering: "int",
		numRecentApps: "int",
		sidebarShortcuts: "stringlist",
		sidebarCollapsibleSearchResults: "bool",
		customAvatarPath: "string",
		defaultAppListView: "string",
		lastUsedAppListView: "string",
		aiChatEnabled: "bool",
		aiProvider: "string",
		aiApiKey: "string",
		aiOllamaUrl: "string",
		aiOpenWebUiUrl: "string",
		aiModel: "string",
		aiDetectedModels: "stringlist",
		aiChatHistory: "string",
		aiStreamChat: "bool",
		terminalApp: "string",
		taskManagerApp: "string",
		fileManagerApp: "string",
		useTileTabs: "bool",
		tileTabStyle: "string",
		tileTabs: "tiletabs",
		tileModel: "tilemodel",
		tileScale: "double",
		tileIconSize: "int",
		tileMargin: "double",
		tilesLocked: "bool",
		tileHoverEffect: "string",
		tileAnimatedPlayOnHover: "bool",
		showTileTooltips: "bool",
		defaultTileColor: "string",
		defaultTileGradient: "bool",
		sidebarBackgroundColor: "string",
		hideSearchField: "bool",
		searchOnTop: "bool",
		searchFieldFollowsTheme: "bool",
		sidebarFollowsTheme: "bool",
		sidebarHideBorder: "bool",
		tileLabelAlignment: "string",
		groupLabelAlignment: "string",
		tileGroupLayout: "string",
		presetTilesFolder: "string",
		appDescription: "string",
		appListIconSize: "int",
		searchFieldHeight: "int",
		dockedSearchFieldWidth: "int",
		appListWidth: "int",
		dockedSidebarWidth: "int",
		useDockedLayout: "bool",
		popupHeight: "int",
		popupWidthAlphabetical: "int",
		popupHeightAlphabetical: "int",
		favGridColsAlphabetical: "int",
		popupWidthCategories: "int",
		popupHeightCategories: "int",
		favGridColsCategories: "int",
		popupWidthTilesOnly: "int",
		popupHeightTilesOnly: "int",
		favGridColsTilesOnly: "int",
		popupWidthAiChat: "int",
		popupHeightAiChat: "int",
		favGridColsAiChat: "int",
		popupWidthDockedAlphabetical: "int",
		popupHeightDockedAlphabetical: "int",
		favGridColsDockedAlphabetical: "int",
		popupWidthDockedCategories: "int",
		popupHeightDockedCategories: "int",
		favGridColsDockedCategories: "int",
		popupWidthDockedTilesOnly: "int",
		popupHeightDockedTilesOnly: "int",
		favGridColsDockedTilesOnly: "int",
		popupWidthDockedAiChat: "int",
		popupHeightDockedAiChat: "int",
		favGridColsDockedAiChat: "int",
		favGridCols: "int",
		sidebarButtonSize: "int",
		sidebarIconSize: "int",
		sidebarPosition: "string",
		tileRoundedCorners: "bool",
		tileCornerRadius: "int",
	})

			TiledMenu.Base64XmlString {
				id: configTileModel
				configKey: "tileModel"
				defaultValue: []
			}

	property bool _updatingTextFromConfig: false
	property bool _applyingXmlToConfig: false
	property bool _xmlEditedByUser: false
	property string _lastImportError: ""
	property string _lastTileModelError: ""

	function _flushPendingXmlApply() {
		if (!xmlEditor) {
			return
		}
		if (_xmlEditedByUser && applyXmlDebounced.running && !_updatingTextFromConfig) {
			applyXmlDebounced.stop()
			applyXmlToConfig(xmlEditor.text)
			_xmlEditedByUser = false
		}
	}

	function _shellSingleQuote(s) {
		s = (typeof s === "undefined" || s === null) ? "" : ("" + s)
		return "'" + s.replace(/'/g, "'\\''") + "'"
	}

	function _toLocalPath(urlOrString) {
		var s = (typeof urlOrString === "undefined" || urlOrString === null) ? "" : ("" + urlOrString)
		if (!s) {
			return ""
		}
		if (s.indexOf("file://") === 0) {
			s = s.substring("file://".length)
			if (s.length >= 2 && s.charAt(0) === '/' && s.charAt(1) === '/') {
				s = s.substring(1)
			}
			try {
				s = decodeURIComponent(s)
			} catch (e) {
				// ignore
			}
		}
		return s
	}

	function _escapeXml(s) {
		s = (typeof s === "undefined" || s === null) ? "" : ("" + s)
		return s
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/\"/g, "&quot;")
			.replace(/'/g, "&apos;")
	}

	function _unescapeXml(s) {
		s = (typeof s === "undefined" || s === null) ? "" : ("" + s)
		return s
			.replace(/&apos;/g, "'")
			.replace(/&quot;/g, "\"")
			.replace(/&gt;/g, ">")
			.replace(/&lt;/g, "<")
			.replace(/&amp;/g, "&")
	}

	function _sortedSchemaKeys() {
		var keys = Object.keys(settingsSchema)
		keys.sort()
		return keys
	}

	function _tileScaleToPercent(scale) {
		return Math.round((parseFloat(scale) || 0) * 250)
	}

	function _percentToTileScale(percent) {
		return (parseFloat(percent) || 0) / 250
	}

	function _sectionForKey(configKey) {
		if (configKey.indexOf("ai") === 0) {
			return "AI Chat"
		}
		if (configKey === "tileRoundedCorners" || configKey === "tileCornerRadius" || configKey === "sidebarHideBorder" || configKey === "sidebarFollowsTheme" || configKey === "sidebarBackgroundColor") {
			return "Appearance"
		}
		if (configKey.indexOf("tile") === 0 || configKey.indexOf("favGridCols") === 0 || configKey === "tilesLocked" || configKey === "showTileTooltips" || configKey.indexOf("defaultTile") === 0) {
			return "Tiles"
		}
		if (configKey.indexOf("sidebar") === 0 || configKey === "dockedSidebarWidth") {
			return "Sidebar"
		}
		if (configKey.indexOf("search") === 0 || configKey === "hideSearchField" || configKey === "dockedSearchFieldWidth") {
			return "Search"
		}
		if (configKey.indexOf("appList") === 0 || configKey === "appDescription" || configKey === "defaultAppListView" || configKey === "lastUsedAppListView" || configKey === "showRecentApps" || configKey === "recentOrdering" || configKey === "numRecentApps") {
			return "Application List"
		}
		if (configKey.indexOf("popupHeight") === 0 || configKey.indexOf("popupWidth") === 0 || configKey === "icon" || configKey === "fixedPanelIcon" || configKey === "terminalApp" || configKey === "taskManagerApp" || configKey === "fileManagerApp" || configKey === "presetTilesFolder") {
			return "General"
		}
		return "Other"
	}

	function _readConfigValue(key) {
		if (key === "tileModel") {
			return configTileModel.value
		}
		var cfgName = "cfg_" + key
		var cfgVal = page[cfgName]
		if (typeof cfgVal !== "undefined") {
			return cfgVal
		}
		return plasmoid.configuration[key]
	}

	function _stringListToArray(value) {
		if (!value) {
			return []
		}
		if (Array.isArray(value)) {
			return value.slice()
		}
		if (typeof value === "string") {
			return value ? [value] : []
		}
		var list = []
		var length = typeof value.length === "number" ? value.length : 0
		for (var i = 0; i < length; i++) {
			list.push("" + value[i])
		}
		return list
	}

	function _normalizeValueForType(value, typeName) {
		if (typeName === "stringlist") {
			return _stringListToArray(value)
		}
		if (typeName === "bool") {
			if (typeof value === "boolean") {
				return value
			}
			if (typeof value === "number") {
				return value !== 0
			}
			var s = ("" + value).trim().toLowerCase()
			return (s === "true" || s === "1" || s === "yes" || s === "on")
		}
		if (typeName === "int") {
			var n = parseInt(value, 10)
			return isNaN(n) ? 0 : n
		}
		if (typeName === "double") {
			var f = parseFloat(value)
			return isNaN(f) ? 0 : f
		}
		if (typeName === "tilemodel") {
			return Array.isArray(value) ? value : []
		}
		if (typeName === "tiletabs") {
			return _normalizeTileTabs(value)
		}
		return (typeof value === "undefined" || value === null) ? "" : ("" + value)
	}

	function _normalizeTileTabs(value) {
		var tabs = []
		if (Array.isArray(value)) {
			tabs = value
		} else if (typeof value === "string" && value) {
			try {
				var decoded = Base64.decodeString(value)
				var parsed = JSON.parse(decoded)
				if (Array.isArray(parsed)) {
					tabs = parsed
				}
			} catch (e) {
				tabs = []
			}
		}

		var out = []
		for (var i = 0; i < tabs.length; i++) {
			var tab = tabs[i]
			if (!tab || typeof tab !== "object") {
				continue
			}
			out.push({
				id: (typeof tab.id === "undefined" || tab.id === null) ? "" : ("" + tab.id),
				name: (typeof tab.name === "undefined" || tab.name === null) ? "" : ("" + tab.name),
				icon: (typeof tab.icon === "undefined" || tab.icon === null) ? "" : ("" + tab.icon),
				tiles: Array.isArray(tab.tiles) ? tab.tiles : [],
			})
		}
		return out
	}

	function _encodeTileTabs(tabs) {
		var normalized = _normalizeTileTabs(tabs)
		if (normalized.length === 0) {
			return ""
		}
		return Base64.encodeString(JSON.stringify(normalized))
	}

	function _propTypeForValue(v) {
		if (typeof v === "boolean") {
			return "bool"
		}
		if (typeof v === "number") {
			return (Math.floor(v) === v) ? "int" : "double"
		}
		if (typeof v === "object" && v !== null) {
			return "json"
		}
		return "string"
	}

	function _normalizePropValueForType(value, typeName) {
		if (typeName === "bool") {
			if (typeof value === "boolean") {
				return value
			}
			var s = ("" + value).trim().toLowerCase()
			return (s === "true" || s === "1" || s === "yes" || s === "on")
		}
		if (typeName === "int") {
			var n = parseInt(value, 10)
			return isNaN(n) ? 0 : n
		}
		if (typeName === "double") {
			var f = parseFloat(value)
			return isNaN(f) ? 0 : f
		}
		if (typeName === "json") {
			if (typeof value === "object") {
				return value
			}
			try {
				return JSON.parse("" + value)
			} catch (e) {
				_lastTileModelError = i18n("Invalid tile property JSON")
				return null
			}
		}
		// string
		return (typeof value === "undefined" || value === null) ? "" : ("" + value)
	}

	function _buildTilesXmlLines(tileModelArray, indent) {
		var tiles = Array.isArray(tileModelArray) ? tileModelArray : []
		var lines = []
		lines.push(indent + "<tiles>")
		for (var i = 0; i < tiles.length; i++) {
			var tile = tiles[i]
			if (!tile || typeof tile !== "object") {
				continue
			}
			lines.push(indent + "  <tile>")
			var keys = Object.keys(tile)
			keys.sort()
			for (var ki = 0; ki < keys.length; ki++) {
				var k = keys[ki]
				var v = tile[k]
				var t = _propTypeForValue(v)
				if (t === "json") {
					var jsonText = "null"
					try {
						jsonText = JSON.stringify(v, null, 2)
					} catch (e) {
						jsonText = "null"
					}
					lines.push(indent + "    <prop name=\"" + _escapeXml(k) + "\" type=\"json\"><![CDATA[" + jsonText + "]]></prop>")
				} else {
					lines.push(indent + "    <prop name=\"" + _escapeXml(k) + "\" type=\"" + t + "\">" + _escapeXml(v) + "</prop>")
				}
			}
			lines.push(indent + "  </tile>")
		}
		lines.push(indent + "</tiles>")
		return lines
	}

	function _buildTileModelXml(tileModelArray) {
		var lines = []
		lines.push("    <entry key=\"tileModel\" type=\"tilemodel\">")
		var tileLines = _buildTilesXmlLines(tileModelArray, "      ")
		for (var i = 0; i < tileLines.length; i++) {
			lines.push(tileLines[i])
		}
		lines.push("    </entry>")
		return lines
	}

	function _buildTileTabsXml(tileTabsArray) {
		var tabs = _normalizeTileTabs(tileTabsArray)
		var lines = []
		lines.push("    <entry key=\"tileTabs\" type=\"tiletabs\">")
		lines.push("      <tabs>")
		for (var i = 0; i < tabs.length; i++) {
			var tab = tabs[i]
			lines.push("        <tab id=\"" + _escapeXml(tab.id) + "\" name=\"" + _escapeXml(tab.name) + "\" icon=\"" + _escapeXml(tab.icon) + "\">")
			var tileLines = _buildTilesXmlLines(tab.tiles, "          ")
			for (var ti = 0; ti < tileLines.length; ti++) {
				lines.push(tileLines[ti])
			}
			lines.push("        </tab>")
		}
		lines.push("      </tabs>")
		lines.push("    </entry>")
		return lines
	}

	function _xmlAttribute(tagText, attrName, defaultValue) {
		var re = new RegExp(attrName + "=\"([^\"]*)\"")
		var m = re.exec(tagText || "")
		return m && m.length >= 2 ? _unescapeXml(m[1]) : defaultValue
	}

	function _parseTileModelXml(inner) {
		_lastTileModelError = ""
		var out = []
		var xml = inner || ""
		var reTile = /<tile\b[^>]*>([\s\S]*?)<\/tile>/g
		var tileMatch
		while ((tileMatch = reTile.exec(xml)) !== null) {
			var tileInner = tileMatch[1]
			var tileObj = {}
			var reProp = /<prop\s+[^>]*name=\"([^\"]+)\"[^>]*>([\s\S]*?)<\/prop>/g
			var propMatch
			while ((propMatch = reProp.exec(tileInner)) !== null) {
				var name = _unescapeXml(propMatch[1])
				var propInner = propMatch[2]
				var openTagMatch = /^<prop\s+[^>]*>/.exec(propMatch[0])
				var openTag = openTagMatch ? openTagMatch[0] : ""
				var typeMatch = /type=\"([^\"]+)\"/.exec(openTag)
				var typeName = typeMatch && typeMatch.length >= 2 ? _unescapeXml(typeMatch[1]) : "string"
				if (typeName === "json") {
					var raw = _extractCdataOrText(propInner)
					tileObj[name] = _normalizePropValueForType(raw, "json")
				} else {
					var raw2 = _extractCdataOrText(propInner)
					tileObj[name] = _normalizePropValueForType(raw2, typeName)
				}
			}
			out.push(tileObj)
		}
		return out
	}

	function _parseTileTabsXml(inner) {
		var out = []
		var xml = inner || ""
		var reTab = /<tab\b([^>]*)>([\s\S]*?)<\/tab>/g
		var tabMatch
		while ((tabMatch = reTab.exec(xml)) !== null) {
			var attrs = tabMatch[1] || ""
			var tabInner = tabMatch[2] || ""
			var tilesMatch = /<tiles\b[^>]*>([\s\S]*?)<\/tiles>/.exec(tabInner)
			out.push({
				id: _xmlAttribute(attrs, "id", ""),
				name: _xmlAttribute(attrs, "name", ""),
				icon: _xmlAttribute(attrs, "icon", ""),
				tiles: tilesMatch ? _parseTileModelXml(tilesMatch[0]) : [],
			})
		}
		return out
	}

	function buildExportXml() {
		var grouped = {
			"General": [],
			"Application List": [],
			"Appearance": [],
			"Search": [],
			"AI Chat": [],
			"Sidebar": [],
			"Tiles": [],
			"Other": [],
		}
		var keys = _sortedSchemaKeys()
		for (var i = 0; i < keys.length; i++) {
			var key = keys[i]
			var typeName = settingsSchema[key]
			var raw = _readConfigValue(key)
			var value = _normalizeValueForType(raw, typeName)
			var sectionName = _sectionForKey(key)
			if (!grouped[sectionName]) {
				sectionName = "Other"
			}
			grouped[sectionName].push({ key: key, type: typeName, value: value })
		}

		var lines = []
		lines.push("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
		lines.push("<tiledmenu format=\"tiled_rld\" version=\"2\">")
		var sectionOrder = ["General", "Application List", "Appearance", "Search", "AI Chat", "Sidebar", "Tiles", "Other"]
		for (var si = 0; si < sectionOrder.length; si++) {
			var sectionName = sectionOrder[si]
			lines.push("  <section name=\"" + _escapeXml(sectionName) + "\">")
			var items = grouped[sectionName]
			for (var ti = 0; ti < items.length; ti++) {
				var item = items[ti]
				var k = item.key
				var t = item.type
				if (k === "tileModel" && t === "tilemodel") {
					var tileLines = _buildTileModelXml(item.value)
					for (var tl = 0; tl < tileLines.length; tl++) {
						lines.push(tileLines[tl])
					}
					continue
				}
				if (k === "tileTabs" && t === "tiletabs") {
					var tabLines = _buildTileTabsXml(item.value)
					for (var tbl = 0; tbl < tabLines.length; tbl++) {
						lines.push(tabLines[tbl])
					}
					continue
				}
				if (t === "stringlist") {
					lines.push("    <entry key=\"" + _escapeXml(k) + "\" type=\"stringlist\">")
					var list = item.value
					for (var li = 0; li < list.length; li++) {
						lines.push("      <value>" + _escapeXml(list[li]) + "</value>")
					}
					lines.push("    </entry>")
				} else if (k === "tileScale") {
					lines.push("    <entry key=\"tileScale\" type=\"int\">" + _escapeXml(_tileScaleToPercent(item.value)) + "</entry>")
				} else {
					lines.push("    <entry key=\"" + _escapeXml(k) + "\" type=\"" + _escapeXml(t) + "\">" + _escapeXml(item.value) + "</entry>")
				}
			}
			lines.push("  </section>")
		}
		lines.push("</tiledmenu>")
		lines.push("")
		return lines.join("\n")
	}

	function _extractCdataOrText(inner) {
		var m = /<!\[CDATA\[([\s\S]*?)\]\]>/.exec(inner)
		if (m && m.length >= 2) {
			return m[1]
		}
		return _unescapeXml((inner || "").trim())
	}

	function parseImportXml(xmlText) {
		_lastImportError = ""
		_lastTileModelError = ""
		var out = {}
		var xml = (xmlText || "")
		var rootMatch = /<tiledmenu\s+[^>]*version=\"([^\"]+)\"/.exec(xml)
		var importVersion = rootMatch && rootMatch.length >= 2 ? parseInt(rootMatch[1], 10) : 1
		if (isNaN(importVersion) || importVersion < 1) {
			importVersion = 1
		}
		var reEntry = /<entry\s+[^>]*key=\"([^\"]+)\"[^>]*>([\s\S]*?)<\/entry>/g
		var match
		while ((match = reEntry.exec(xml)) !== null) {
			var key = _unescapeXml(match[1])
			var inner = match[2]
			var typeMatch = /<entry\s+[^>]*key=\"[^\"]+\"[^>]*type=\"([^\"]+)\"/.exec(match[0])
			var typeName = typeMatch && typeMatch.length >= 2 ? _unescapeXml(typeMatch[1]) : (settingsSchema[key] || "string")

			if (typeName === "stringlist") {
				var values = []
				var reVal = /<value>([\s\S]*?)<\/value>/g
				var m2
				while ((m2 = reVal.exec(inner)) !== null) {
					values.push(_unescapeXml((m2[1] || "").trim()))
				}
				out[key] = values
			} else if (typeName === "tilemodel") {
				out[key] = _parseTileModelXml(inner)
				if (_lastTileModelError) {
					_lastImportError = _lastTileModelError
				}
			} else if (typeName === "tiletabs") {
				out[key] = _parseTileTabsXml(inner)
				if (_lastTileModelError) {
					_lastImportError = _lastTileModelError
				}
			} else {
				var value = _extractCdataOrText(inner)
				if (key === "tileScale" && importVersion >= 2) {
					out[key] = _percentToTileScale(value)
				} else {
					out[key] = value
				}
			}
		}
		return out
	}

	function applyXmlToConfig(xmlText) {
		var imported = parseImportXml(xmlText)
		if (_lastImportError && typeof showPassiveNotification === "function") {
			showPassiveNotification(_lastImportError)
		}
		var keys = _sortedSchemaKeys()
		_applyingXmlToConfig = true
		try {
			function getRootKcm() {
				return ConfigUtils.getRootKcm(page)
			}

			function notifyConfigurationChanged() {
				// Plasma's configuration dialog only persists changes on OK/Apply when
				// the KCM is marked dirty. Since we edit settings programmatically from
				// the XML editor, explicitly notify the root KCM.
				ConfigUtils.markConfigurationChanged(page)
			}

			function setCfgValue(configKey, normalizedValue, typeName) {
				var rootKcm = getRootKcm()
				if (!rootKcm) {
					return
				}
				var propName = "cfg_" + configKey
				if (typeof rootKcm[propName] === "undefined" && typeof rootKcm[propName + "Changed"] === "undefined") {
					return
				}
				if (typeName === "tilemodel") {
					var encoded = ""
					// main.xml stores tileModel as a base64-encoded XML fragment (<tiles>...</tiles>).
					try {
						var lines = _buildTileModelXml(normalizedValue || [])
						// _buildTileModelXml returns an <entry> wrapper; extract inner <tiles>...</tiles>
						// join and remove the first and last lines which are the <entry> tags.
						var joined = lines.join("\n")
						// Extract the <tiles>...</tiles> fragment
						var m = /<tiles[\s\S]*<\/tiles>/.exec(joined)
						var tilesFragment = m && m.length >= 0 ? m[0] : "<tiles></tiles>"
						encoded = Base64.encodeString(tilesFragment)
					} catch (e) {
						encoded = Base64.encodeString("<tiles></tiles>")
					}
					rootKcm[propName] = encoded
				} else if (typeName === "tiletabs") {
					rootKcm[propName] = _encodeTileTabs(normalizedValue)
				} else {
					rootKcm[propName] = ConfigUtils.cloneValue(normalizedValue)
				}
			}

			var appliedTileModel = false
			var appliedTileModelCount = 0
			var changedSomething = false
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				if (typeof imported[key] === "undefined") {
					continue
				}
				var typeName = settingsSchema[key]
				var normalized = _normalizeValueForType(imported[key], typeName)
				var current = _normalizeValueForType(_readConfigValue(key), typeName)
				if (key === "tileModel") {
					var tileModelChanged = !ConfigUtils.valuesEqual(current, normalized)
					if (tileModelChanged) {
						// Ensure the config page's own Base64XmlString mirrors the new value.
						configTileModel.value = normalized
						setCfgValue(key, normalized, typeName)
						appliedTileModel = true
						appliedTileModelCount = Array.isArray(normalized) ? normalized.length : 0
						changedSomething = true
					}
				} else {
					if (!ConfigUtils.valuesEqual(current, normalized)) {
						setCfgValue(key, normalized, typeName)
						changedSomething = true
					}
				}
			}
			if (appliedTileModel && typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Applied tile model (%1 tiles)", appliedTileModelCount))
			}
			if (changedSomething) {
				notifyConfigurationChanged()
			}
		} finally {
			_applyingXmlToConfig = false
		}
	}

	function rebuildXmlFromConfig() {
		if (!xmlEditor || xmlEditor.focus || _applyingXmlToConfig) {
			return
		}
		_updatingTextFromConfig = true
		try {
			var next = buildExportXml()
			if (xmlEditor.text !== next) {
				xmlEditor.text = next
			}
			_xmlEditedByUser = false
		} finally {
			_updatingTextFromConfig = false
		}
	}

	Plasma5Support.DataSource {
		id: exec
		engine: "executable"
		connectedSources: []
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var exitCode = data && typeof data["exit code"] !== "undefined" ? data["exit code"] : 0
			if (exitCode && exitCode !== 0) {
				var stderr = data && data.stderr ? ("" + data.stderr).trim() : ""
				var msg = stderr ? stderr : i18n("Failed to save file")
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(msg)
				}
			}
		}
	}

	Plasma5Support.DataSource {
		id: execRead
		engine: "executable"
		connectedSources: []
		property string pendingImportPath: ""
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var exitCode = data && typeof data["exit code"] !== "undefined" ? data["exit code"] : 0
			if (exitCode && exitCode !== 0) {
				var stderr = data && data.stderr ? ("" + data.stderr).trim() : ""
				var msg = stderr ? stderr : i18n("Failed to import file")
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(msg)
				}
				return
			}
			var out = data && data.stdout ? ("" + data.stdout).trim() : ""
			if (!out) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Import produced no data"))
				}
				return
			}
			var text = ""
			try {
				text = Base64.decodeString(out)
			} catch (e) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Failed to decode imported file"))
				}
				return
			}
			try {
				page._updatingTextFromConfig = true
				xmlEditor.text = text
			} finally {
				page._updatingTextFromConfig = false
			}
			try {
				page._xmlEditedByUser = false
				applyXmlToConfig(text)
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Imported from %1", pendingImportPath || ""))
				}
			} catch (e2) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Failed to import settings"))
				}
			}
		}
	}

	QtLabsPlatform.FileDialog {
		id: saveDialog
		title: i18n("Save Layout")
		fileMode: QtLabsPlatform.FileDialog.SaveFile
		nameFilters: [
			i18n("Layout Files (*.xml)"),
			i18n("All Files (*)"),
		]
		defaultSuffix: "xml"
		onAccepted: {
			var chosenUrl = (saveDialog.currentFile || saveDialog.file || saveDialog.selectedFile || (saveDialog.files && saveDialog.files.length ? saveDialog.files[0] : ""))
			var filePath = page._toLocalPath(chosenUrl)
			if (!filePath) {
				return
			}
			page.saveExportToFilePath(filePath)
		}
	}

	QtLabsPlatform.FileDialog {
		id: importDialog
		title: i18n("Import Layout")
		fileMode: QtLabsPlatform.FileDialog.OpenFile
		nameFilters: [
			i18n("Layout Files (*.xml)"),
			i18n("All Files (*)"),
		]
		onAccepted: {
			var chosenUrl = (importDialog.currentFile || importDialog.file || importDialog.selectedFile || (importDialog.files && importDialog.files.length ? importDialog.files[0] : ""))
			var filePath = page._toLocalPath(chosenUrl)
			if (!filePath) {
				return
			}
			page.importFromFilePath(filePath)
		}
	}

	function saveExportToFilePath(filePath) {
		var text = xmlEditor ? ("" + xmlEditor.text) : ""
		var b64 = Base64.encodeString(text)
		var py = "import sys,base64,pathlib; pathlib.Path(sys.argv[1]).write_bytes(base64.b64decode(sys.argv[2].encode('ascii')))"
		var cmd = "python3 -c " + _shellSingleQuote(py) + " " + _shellSingleQuote(filePath) + " " + _shellSingleQuote(b64)
		exec.connectSource(cmd)
		if (typeof showPassiveNotification === "function") {
			showPassiveNotification(i18n("Saved to %1", filePath))
		}
	}

	function importFromFilePath(filePath) {
		execRead.pendingImportPath = filePath
		var py = "import sys,base64; sys.stdout.write(base64.b64encode(open(sys.argv[1],'rb').read()).decode('ascii'))"
		var cmd = "python3 -c " + _shellSingleQuote(py) + " " + _shellSingleQuote(filePath)
		execRead.connectSource(cmd)
	}

	ColumnLayout {
		id: contentLayout
		anchors.fill: parent
		anchors.margins: Kirigami.Units.gridUnit * 2
		spacing: Kirigami.Units.smallSpacing

		RowLayout {
			Layout.fillWidth: true
			spacing: Kirigami.Units.smallSpacing
			Item { Layout.fillWidth: true }
			Button {
				text: i18n("Import XML")
				icon.name: "document-open"
				onClicked: importDialog.open()
			}
			Button {
				text: i18n("Export XML")
				icon.name: "document-save"
				onClicked: saveDialog.open()
			}
		}

		ScrollView {
			id: xmlScrollView
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true

			TextArea {
				id: xmlEditor
				// Avoid anchoring inside ScrollView (can produce anchor-loop warnings).
				width: xmlScrollView.availableWidth
				height: Math.max(xmlScrollView.availableHeight, implicitHeight)
				font.family: "monospace"
				wrapMode: TextEdit.NoWrap
				selectByMouse: true
				onTextChanged: {
					if (page._updatingTextFromConfig) {
						return
					}
					page._xmlEditedByUser = true
					applyXmlDebounced.restart()
				}
				onActiveFocusChanged: {
					// When the user clicks OK, focus moves away from the editor.
					// Flush any pending debounced apply so changes are not lost.
					if (!activeFocus) {
						page._flushPendingXmlApply()
					}
				}
			}
		}
	}

	Timer {
		id: applyXmlDebounced
		interval: 400
		repeat: false
		onTriggered: {
			if (!xmlEditor || page._updatingTextFromConfig || !page._xmlEditedByUser) {
				return
			}
			page.applyXmlToConfig(xmlEditor.text)
			page._xmlEditedByUser = false
		}
	}

	Timer {
		id: rebuildXmlDebounced
		interval: 150
		repeat: false
		onTriggered: page.rebuildXmlFromConfig()
	}

	property string configDigest: ""

	function _computeConfigDigest() {
		var parts = []
		var keys = _sortedSchemaKeys()
		for (var i = 0; i < keys.length; i++) {
			var k = keys[i]
			var t = settingsSchema[k]
			var v = _readConfigValue(k)
			if (t === "stringlist") {
				parts.push(k + "=" + JSON.stringify(_stringListToArray(v)))
			} else if (t === "json") {
				try {
					parts.push(k + "=" + JSON.stringify(v))
				} catch (e) {
					parts.push(k + "=[]")
				}
			} else {
				parts.push(k + "=" + (typeof v === "undefined" || v === null ? "" : ("" + v)))
			}
		}
		return parts.join("\u001f")
	}

	function _refreshConfigDigest() {
		var next = _computeConfigDigest()
		if (next !== configDigest) {
			configDigest = next
		}
	}

	onConfigDigestChanged: {
		if (_applyingXmlToConfig) {
			return
		}
		rebuildXmlDebounced.restart()
	}

	property var _configChangeDisconnects: []
	function _wireConfigChangeListeners() {
		var keys = _sortedSchemaKeys()
		for (var i = 0; i < keys.length; i++) {
			var disconnect = ConfigUtils.connectConfigChange(page, keys[i], _refreshConfigDigest)
			_configChangeDisconnects.push(disconnect)
		}
	}

	Component.onCompleted: {
		_wireConfigChangeListeners()
		_refreshConfigDigest()
		rebuildXmlFromConfig()
	}

	Component.onDestruction: {
		for (var i = 0; i < _configChangeDisconnects.length; i++) {
			_configChangeDisconnects[i]()
		}
		// If the user hits OK immediately after editing, the debounce timer may not fire.
		// Flush pending XML->config changes before this page is torn down.
		if (_xmlEditedByUser) {
			_flushPendingXmlApply()
		}
	}
}
