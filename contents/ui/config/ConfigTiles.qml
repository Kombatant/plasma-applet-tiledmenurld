import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu
import "../lib"
import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils


LibConfig.FormKCM {
	id: formLayout
	wideMode: false
	property string pendingIgdbClientSecret: ""
	property bool pendingIgdbClientSecretInitialized: false
	property bool _updatingIgdbSecretField: false
	property bool _igdbSecretEdited: false
	readonly property bool hasStoredIgdbClientSecret: !!((secureIgdbClientSecret.secret || "").trim())

	function saveConfig() {
		_applyPendingIgdbClientSecret()
	}

	function tileScaleToAbsoluteSize(scale) {
		return Math.round((scale || 0) * 160)
	}

	function absoluteSizeToTileScale(size) {
		return size / 160
	}

	function absoluteSizeToPercent(size) {
		return Math.round((size / 64) * 100)
	}

	readonly property real pendingTileScale: {
		var raw = formLayout.cfg_tileScale !== undefined ? formLayout.cfg_tileScale : plasmoid.configuration.tileScale
		return raw || 0
	}
	readonly property bool pendingUseTileTabs: !!(formLayout.cfg_useTileTabs !== undefined ? formLayout.cfg_useTileTabs : plasmoid.configuration.useTileTabs)
	readonly property string pendingTileTabStyle: {
		var raw = formLayout.cfg_tileTabStyle !== undefined ? formLayout.cfg_tileTabStyle : plasmoid.configuration.tileTabStyle
		return raw === "pills" ? "pills" : "tabs"
	}
	readonly property string pendingTileTabMode: pendingUseTileTabs ? pendingTileTabStyle : "disabled"

	readonly property int pendingCellBoxSize: {
		var rawMargin = formLayout.cfg_tileMargin !== undefined ? formLayout.cfg_tileMargin : plasmoid.configuration.tileMargin
		var tileMarginUnits = rawMargin || 0
		var cellMarginUnits = tileMarginUnits / 2
		var cellSizeUnits = config.cellBoxUnits - tileMarginUnits
		var scale = pendingTileScale || 0
		var cellSize = Math.round(cellSizeUnits * scale * Screen.devicePixelRatio)
		var cellMargin = cellMarginUnits * scale * Screen.devicePixelRatio
		return Math.max(1, Math.round(cellMargin + cellSize + cellMargin))
	}

	function setPendingTileScale(scale) {
		var current = formLayout.pendingTileScale
		if (Math.abs(current - scale) <= 0.0001) {
			return
		}
		ConfigUtils.setPendingValue(formLayout, "tileScale", scale)
	}

	function setPendingTileTabMode(mode) {
		var enabled = mode !== "disabled"
		ConfigUtils.setPendingValue(formLayout, "useTileTabs", enabled)
		if (enabled) {
			ConfigUtils.setPendingValue(formLayout, "tileTabStyle", mode === "pills" ? "pills" : "tabs")
		}
	}

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	KWalletSecret {
		id: secureIgdbClientSecret
		entryName: "igdbClientSecret"
		onLoaded: function(success) {
			if (success && !formLayout.pendingIgdbClientSecretInitialized) {
				formLayout._setPendingIgdbClientSecret(secret || ((plasmoid.configuration.igdbClientSecret || "").trim()), false)
				formLayout.pendingIgdbClientSecretInitialized = true
			}
		}
		onSaved: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(formLayout, "igdbClientSecret", "", false)
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to save the IGDB client secret to KWallet."))
			}
		}
		onCleared: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(formLayout, "igdbClientSecret", "", false)
				formLayout._setPendingIgdbClientSecret("", false)
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to remove the IGDB client secret from KWallet."))
			}
		}
	}

	function _setPendingIgdbClientSecret(value, markDirty) {
		var nextValue = value || ""
		if (formLayout.pendingIgdbClientSecret === nextValue) {
			return
		}
		formLayout.pendingIgdbClientSecret = nextValue
		if (markDirty !== false) {
			ConfigUtils.markConfigurationChanged(formLayout)
		}
		formLayout._updatingIgdbSecretField = true
		igdbClientSecretField.text = nextValue
		formLayout._updatingIgdbSecretField = false
		if (markDirty === false) {
			formLayout._igdbSecretEdited = false
		}
	}

	function _igdbClientSecretValue() {
		var pendingValue = (formLayout.pendingIgdbClientSecret || "").trim()
		if (pendingValue) {
			return pendingValue
		}
		if (formLayout._igdbSecretEdited) {
			return ""
		}
		return (secureIgdbClientSecret.secret || "").trim()
	}

	function _applyPendingIgdbClientSecret() {
		if (!secureIgdbClientSecret.secureStorageAvailable || secureIgdbClientSecret.saving) {
			return
		}
		var draft = _igdbClientSecretValue()
		var stored = secureIgdbClientSecret.secret || ""
		ConfigUtils.setPendingValue(formLayout, "igdbClientSecret", "", false)
		if (draft === stored) {
			return
		}
		if (!draft) {
			secureIgdbClientSecret.clearSecret()
			return
		}
		secureIgdbClientSecret.saveSecret(draft)
	}

	Component.onCompleted: {
		if (!formLayout.pendingIgdbClientSecretInitialized && (plasmoid.configuration.igdbClientSecret || "").trim()) {
			formLayout.pendingIgdbClientSecret = (plasmoid.configuration.igdbClientSecret || "").trim()
			formLayout.pendingIgdbClientSecretInitialized = true
		}
		secureIgdbClientSecret.inspectAvailability()
		secureIgdbClientSecret.readSecret()
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Tabs")
	}

	LibConfig.ComboBox {
		configValue: formLayout.pendingTileTabMode
		Kirigami.FormData.label: i18n("Tab Style")
		onActivated: formLayout.setPendingTileTabMode(currentItem.value)
		model: [
			{ value: "disabled", text: i18n("Disable Tabs") },
			{ value: "tabs", text: i18n("Tabs") },
			{ value: "pills", text: i18n("Pills") },
		]
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Size & Spacing")
	}

	RowLayout {
		id: tileSizeRow
		Kirigami.FormData.label: i18n("Tile Size")

		LibConfig.SpinBox {
			id: tileSizeSpinBox
			suffix: i18n("px")
			minimumValue: 32
			maximumValue: 128
			decimals: 0
			value: formLayout.tileScaleToAbsoluteSize(formLayout.pendingTileScale)
			onValueModified: formLayout.setPendingTileScale(formLayout.absoluteSizeToTileScale(value))
		}
		QQC2.Label {
			text: '(' + formLayout.absoluteSizeToPercent(tileSizeSpinBox.value) + "%)"
		}
	}
	RowLayout {
		Kirigami.FormData.label: i18n("Tile Icon Size")
		LibConfig.SpinBox {
			configKey: 'tileIconSize'
			suffix: i18n("px")
			minimumValue: 16
			maximumValue: 256
			decimals: 0
		}
		QQC2.Label {
			text: i18n("Base size for tile icons; small/large variants scale from this")
		}
	}
	LibConfig.SpinBox {
		configKey: 'tileMargin'
		Kirigami.FormData.label: i18n("Tile Margin")
		suffix: i18n("px")
		minimumValue: 12
		maximumValue: config.cellBoxUnits/2
	}
	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Appearance")
	}

	LibConfig.RadioButtonGroup {
		id: tilesThemeGroup
		Kirigami.FormData.label: i18n("Tile Background Colour")
		spacing: 0 // "Custom Color" has lots of spacings already
		RowLayout {
			QQC2.RadioButton {
				id: defaultTileColorRadioButton
				text: i18n("Custom Colour")
				QQC2.ButtonGroup.group: tilesThemeGroup.group
				checked: defaultTileColorColor.value !== "#00000000"
				onClicked: {
					// If we're currently in the Transparent state, switch back to a non-transparent
					// value so this radio can remain selected.
					if (defaultTileColorColor.value === "#00000000") {
						defaultTileColorColor.text = ""
					}
				}
			}
			LibConfig.ColorField {
				id: defaultTileColorColor
				configKey: 'defaultTileColor'
			}
			LibConfig.CheckBox {
				text: i18n("Gradient")
				configKey: 'defaultTileGradient'
			}
		}
		QQC2.RadioButton {
			id: transparentTileColorRadioButton
			text: i18n("Transparent")
			QQC2.ButtonGroup.group: tilesThemeGroup.group
			checked: defaultTileColorColor.value === "#00000000"
			onClicked: {
				defaultTileColorColor.text = "#00000000"
			}
		}
	}
	LibConfig.ComboBox {
		configKey: "tileHoverEffect"
		Kirigami.FormData.label: i18n("Hover Effect")
		model: [
			{ value: "classic", text: i18n("Classic") },
			{ value: "holographic", text: i18n("Holographic") },
		]
	}

	LibConfig.CheckBox {
		configKey: 'tileAnimatedPlayOnHover'
		text: i18n("Play animated backgrounds only on hover")
		Kirigami.FormData.label: ""
	}
	LibConfig.CheckBox {
		configKey: 'showTileTooltips'
		text: i18n("Show tooltips on hover")
		Kirigami.FormData.label: ""
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Labels")
	}

	LibConfig.ComboBox {
		configKey: "tileLabelAlignment"
		Kirigami.FormData.label: i18n("Text Alignment")
		model: [
			{ value: "left", text: i18n("Left") },
			{ value: "center", text: i18n("Centre") },
			{ value: "right", text: i18n("Right") },
		]
	}
	LibConfig.ComboBox {
		configKey: "groupLabelAlignment"
		Kirigami.FormData.label: i18n("Group Text Alignment")
		model: [
			{ value: "left", text: i18n("Left") },
			{ value: "right", text: i18n("Right") },
		]
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Groups")
	}

	LibConfig.ComboBox {
		configKey: "tileGroupLayout"
		Kirigami.FormData.label: i18n("Group Tile Layout")
		model: [
			{ value: "card", text: i18n("Card") },
			{ value: "classic", text: i18n("Classic") },
		]
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Preset Tiles")
	}

	RowLayout {
		id: presetTilesFolderRow
		Kirigami.FormData.label: i18n("Preset Tile Folder")
		Layout.fillWidth: true

		function toLocalPath(path) {
			var p = (typeof path === "undefined" || path === null) ? "" : ("" + path)
			while (p.indexOf("file://") === 0) {
				p = p.substr("file://".length)
				if (p.length >= 2 && p.charAt(0) === "/" && p.charAt(1) === "/") {
					p = p.substring(1)
				}
				if (p.indexOf("file///") === 0) {
					p = "/" + p.substring("file///".length)
				} else if (p.indexOf("file/") === 0) {
					p = "/" + p.substring("file/".length)
				}
			}
			try {
				p = decodeURIComponent(p)
			} catch (e) {
				// Keep the original path if percent decoding fails.
			}
			return p
		}

		function standardPathForToken(token) {
			var value = ""
			if (token === "%PICTURES%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.PicturesLocation)
			} else if (token === "%DOCUMENTS%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DocumentsLocation)
			} else if (token === "%MUSIC%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.MusicLocation)
			} else if (token === "%DOWNLOADS%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DownloadLocation)
			} else if (token === "%VIDEOS%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.MoviesLocation)
			} else if (token === "%DESKTOP%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DesktopLocation)
			} else if (token === "%HOME%") {
				value = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation)
			}
			return toLocalPath(value)
		}

		function expandStandardPathToken(path) {
			var p = (typeof path === "undefined" || path === null) ? "" : ("" + path)
			if (!p) {
				return ""
			}
			if (p.length >= 2 && p.charAt(0) === "/" && p.charAt(1) === "%") {
				p = p.substring(1)
			}
			var match = /^(%[A-Z]+%)(\/.*)?$/.exec(p)
			if (!match || match.length < 2) {
				return p
			}
			var root = standardPathForToken(match[1])
			return root ? root + (match[2] || "") : p
		}

		function standardPathRoots() {
			var roots = [
				{ token: "%PICTURES%", path: standardPathForToken("%PICTURES%") },
				{ token: "%DOCUMENTS%", path: standardPathForToken("%DOCUMENTS%") },
				{ token: "%MUSIC%", path: standardPathForToken("%MUSIC%") },
				{ token: "%DOWNLOADS%", path: standardPathForToken("%DOWNLOADS%") },
				{ token: "%VIDEOS%", path: standardPathForToken("%VIDEOS%") },
				{ token: "%DESKTOP%", path: standardPathForToken("%DESKTOP%") },
				{ token: "%HOME%", path: standardPathForToken("%HOME%") },
			]
			var out = []
			for (var i = 0; i < roots.length; i++) {
				var path = roots[i].path || ""
				while (path.length > 1 && path.charAt(path.length - 1) === "/") {
					path = path.substring(0, path.length - 1)
				}
				if (path && path !== "/") {
					out.push({ token: roots[i].token, path: path })
				}
			}
			out.sort(function(a, b) {
				return b.path.length - a.path.length
			})
			return out
		}

		function hasPathBoundary(path, prefix) {
			return path.length === prefix.length || path.charAt(prefix.length) === "/"
		}

		function compactStandardPath(path) {
			var p = path || ""
			if (!p) {
				return ""
			}
			var roots = standardPathRoots()
			for (var i = 0; i < roots.length; i++) {
				var root = roots[i]
				if (p.indexOf(root.path) === 0 && hasPathBoundary(p, root.path)) {
					return root.token + p.substring(root.path.length)
				}
			}
			return p
		}

		function pathToUrl(path) {
			var p = toLocalPath(path)
			if (!p) {
				return ""
			}
			if (p.indexOf('://') !== -1) {
				return p
			}
			if (p.indexOf('~/') === 0) {
				var home = standardPathForToken("%HOME%")
				if (home) {
					p = home + p.substr(1)
				}
			}
			p = expandStandardPathToken(p)
			if (p.indexOf('/') === 0) {
				return 'file://' + p
			}
			return p
		}

		function urlToPath(url) {
			if (!url) {
				return ''
			}
			var s = toLocalPath(url)
			return compactStandardPath(s)
		}

		LibConfig.TextField {
			id: presetTilesFolderField
			Layout.fillWidth: true
			configKey: 'presetTilesFolder'
			placeholderText: config.defaultPresetTilesFolder
		}

		QQC2.Button {
			text: i18n("Browse...")
			icon.name: "folder-open"
			onClicked: {
				var startPath = presetTilesFolderField.text || config.defaultPresetTilesFolder
				presetTilesFolderDialog.currentFolder = presetTilesFolderRow.pathToUrl(startPath)
				presetTilesFolderDialog.open()
			}
		}

		QtLabsPlatform.FolderDialog {
			id: presetTilesFolderDialog
			title: i18n("Select Preset Tile Folder")
			onAccepted: {
				var folderPath = presetTilesFolderRow.urlToPath(currentFolder)
				if (folderPath) {
					presetTilesFolderField.text = folderPath
				}
			}
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Online Metadata")
	}

	Kirigami.InlineMessage {
		Layout.fillWidth: true
		visible: secureIgdbClientSecret.checkedAvailability && !secureIgdbClientSecret.secureStorageAvailable && !!secureIgdbClientSecret.availabilityMessage
		type: Kirigami.MessageType.Warning
		text: secureIgdbClientSecret.availabilityMessage
	}

	LibConfig.TextField {
		configKey: "igdbClientId"
		Kirigami.FormData.label: i18n("IGDB Client ID")
		placeholderText: i18n("Required for hero-page IGDB tags")
	}

	LibConfig.TextField {
		id: igdbClientSecretField
		enabled: secureIgdbClientSecret.secureStorageAvailable
		Kirigami.FormData.label: i18n("IGDB Client Secret")
		echoMode: _showSecret ? TextInput.Normal : TextInput.Password
		placeholderText: i18n("Stored in KWallet")
		property bool _showSecret: false
		rightPadding: _toggleSecretButton.width + Kirigami.Units.smallSpacing * 2

		QQC2.ToolButton {
			id: _toggleSecretButton
			anchors.right: parent.right
			anchors.rightMargin: Kirigami.Units.smallSpacing
			anchors.verticalCenter: parent.verticalCenter
			icon.name: igdbClientSecretField._showSecret ? "password-show-off" : "password-show-on"
			onClicked: igdbClientSecretField._showSecret = !igdbClientSecretField._showSecret
			QQC2.ToolTip.text: igdbClientSecretField._showSecret ? i18n("Hide client secret") : i18n("Show client secret")
			QQC2.ToolTip.visible: hovered
			flat: true
			focusPolicy: Qt.NoFocus
			display: QQC2.AbstractButton.IconOnly
			implicitHeight: igdbClientSecretField.implicitHeight - Kirigami.Units.smallSpacing * 2
			implicitWidth: implicitHeight
		}

		onTextChanged: {
			if (formLayout._updatingIgdbSecretField) {
				return
			}
			formLayout._igdbSecretEdited = true
			formLayout._setPendingIgdbClientSecret(text, true)
		}
	}

	QQC2.Label {
		visible: secureIgdbClientSecret.loadedOnce && formLayout.hasStoredIgdbClientSecret
		Layout.fillWidth: true
		wrapMode: Text.Wrap
		opacity: 0.8
		text: i18n("An IGDB client secret is already stored in KWallet. Enter a new value here to replace it.")
	}

	QQC2.Label {
		Layout.fillWidth: true
		wrapMode: Text.Wrap
		opacity: 0.8
		text: i18n("Hero pages can download Steam store descriptions and IGDB tags when you enable the per-page metadata option in the hero editor.")
	}

}
