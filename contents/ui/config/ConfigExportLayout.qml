import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu

ColumnLayout {
	id: page
	spacing: Kirigami.Units.smallSpacing

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
		defaultAppListView: "string",
		lastUsedAppListView: "string",
		aiProvider: "string",
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
		tileTabs: "string",
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
		tileLabelAlignment: "string",
		groupLabelAlignment: "string",
		// Legacy bool key retained for import/export compatibility:
		// false = Plain, true = Section header.
		showGroupTileNameBorder: "bool",
		presetTilesFolder: "string",
		appDescription: "string",
		appListIconSize: "int",
		searchFieldHeight: "int",
		appListWidth: "int",
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
	property string _lastImportError: ""
	property string _lastTileModelError: ""

	function _flushPendingXmlApply() {
		if (!xmlEditor) {
			return
		}
		if (applyXmlDebounced.running && !_updatingTextFromConfig) {
			applyXmlDebounced.stop()
			applyXmlToConfig(xmlEditor.text)
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
		if (configKey.indexOf("tile") === 0 || configKey.indexOf("favGridCols") === 0 || configKey === "tilesLocked" || configKey === "showTileTooltips" || configKey.indexOf("defaultTile") === 0) {
			return "Tiles"
		}
		if (configKey.indexOf("sidebar") === 0) {
			return "Sidebar"
		}
		if (configKey.indexOf("search") === 0 || configKey === "hideSearchField") {
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
		return plasmoid.configuration[key]
	}

	function _normalizeValueForType(value, typeName) {
		if (typeName === "stringlist") {
			return Array.isArray(value) ? value : (typeof value === "undefined" || value === null || value === "" ? [] : ["" + value])
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
		return (typeof value === "undefined" || value === null) ? "" : ("" + value)
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

	function _buildTileModelXml(tileModelArray) {
		var tiles = Array.isArray(tileModelArray) ? tileModelArray : []
		var lines = []
		lines.push("    <entry key=\"tileModel\" type=\"tilemodel\">")
		lines.push("      <tiles>")
		for (var i = 0; i < tiles.length; i++) {
			var tile = tiles[i]
			if (!tile || typeof tile !== "object") {
				continue
			}
			lines.push("        <tile>")
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
					lines.push("          <prop name=\"" + _escapeXml(k) + "\" type=\"json\"><![CDATA[" + jsonText + "]]></prop>")
				} else {
					lines.push("          <prop name=\"" + _escapeXml(k) + "\" type=\"" + t + "\">" + _escapeXml(v) + "</prop>")
				}
			}
			lines.push("        </tile>")
		}
		lines.push("      </tiles>")
		lines.push("    </entry>")
		return lines
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

	function buildExportXml() {
		var grouped = {
			"General": [],
			"Application List": [],
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
			grouped[_sectionForKey(key)].push({ key: key, type: typeName, value: value })
		}

		var lines = []
		lines.push("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
		lines.push("<tiledmenu format=\"tiled_rld\" version=\"2\">")
		var sectionOrder = ["General", "Application List", "Search", "AI Chat", "Sidebar", "Tiles", "Other"]
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
				var root = page
				while (root && root.parent) {
					root = root.parent
					if (root && typeof root.configurationChanged === "function") {
						break
					}
				}
				return (root && typeof root.configurationChanged === "function") ? root : null
			}

			function notifyConfigurationChanged() {
				// Plasma's configuration dialog only persists changes on OK/Apply when
				// the KCM is marked dirty. Since we edit settings programmatically from
				// the XML editor, explicitly notify the root KCM.
				var rootKcm = getRootKcm()
				if (rootKcm) {
					rootKcm.configurationChanged()
				}
			}

			function setCfgValue(configKey, normalizedValue, typeName) {
				var rootKcm = getRootKcm()
				if (!rootKcm) {
					return
				}
				var propName = "cfg_" + configKey
				if (typeof rootKcm[propName] === "undefined") {
					return
				}
				if (typeName === "tilemodel") {
					// main.xml stores tileModel as a base64-encoded XML fragment (<tiles>...)</n+                    var encoded = ""
					try {
						var lines = _buildTileModelXml(normalizedValue || [])
						// _buildTileModelXml returns an <entry> wrapper; extract inner <tiles>...</tiles>
						// join and remove the first and last lines which are the <entry> tags.
						var joined = lines.join("\n")
						// Extract the <tiles>...</tiles> fragment
						var m = /<tiles[\s\S]*<\/tiles>/.exec(joined)
						var tilesFragment = m && m.length >= 0 ? m[0] : "<tiles></tiles>"
						encoded = Qt.btoa(tilesFragment)
					} catch (e) {
						encoded = Qt.btoa("<tiles></tiles>")
					}
					rootKcm[propName] = encoded
				} else {
					rootKcm[propName] = normalizedValue
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
				if (key === "tileModel") {
					// Ensure the config page's own Base64XmlString mirrors the new value.
					if (configTileModel.value !== normalized) {
						configTileModel.value = normalized
					}
					configTileModel.set(normalized)
					setCfgValue(key, normalized, typeName)
					appliedTileModel = true
					appliedTileModelCount = Array.isArray(normalized) ? normalized.length : 0
					changedSomething = true
				} else {
					if (plasmoid.configuration[key] !== normalized) {
						plasmoid.configuration[key] = normalized
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
				text = Qt.atob(out)
			} catch (e) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Failed to decode imported file"))
				}
				return
			}
			try {
				xmlEditor.text = text
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

	Component.onDestruction: {
		// If the user hits OK immediately after editing, the debounce timer may not fire.
		// Flush pending XML->config changes before this page is torn down.
		_flushPendingXmlApply()
	}

	function saveExportToFilePath(filePath) {
		var text = xmlEditor ? ("" + xmlEditor.text) : ""
		var b64 = Qt.btoa(text)
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

	Timer {
		id: applyXmlDebounced
		interval: 400
		repeat: false
		onTriggered: {
			if (!xmlEditor || page._updatingTextFromConfig) {
				return
			}
			page.applyXmlToConfig(xmlEditor.text)
		}
	}

	Timer {
		id: rebuildXmlDebounced
		interval: 150
		repeat: false
		onTriggered: page.rebuildXmlFromConfig()
	}

	readonly property string configDigest: {
		var parts = []
		var keys = _sortedSchemaKeys()
		for (var i = 0; i < keys.length; i++) {
			var k = keys[i]
			var t = settingsSchema[k]
			var v = _readConfigValue(k)
			if (t === "stringlist") {
				parts.push(k + "=" + JSON.stringify(Array.isArray(v) ? v : []))
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

	onConfigDigestChanged: {
		if (_applyingXmlToConfig) {
			return
		}
		rebuildXmlDebounced.restart()
	}

	Component.onCompleted: rebuildXmlFromConfig()
}
