import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu
import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils


LibConfig.FormKCM {
	id: formLayout
	wideMode: false

	function tileScaleToAbsoluteSize(scale) {
		return Math.round((scale || 0) * 160)
	}

	function absoluteSizeToTileScale(size) {
		return size / 160
	}

	function absoluteSizeToPercent(size) {
		return Math.round((size / 64) * 100)
	}

	function getRootKcm() {
		var root = formLayout
		while (root && root.parent) {
			root = root.parent
			if (root && typeof root.configurationChanged === "function") {
				break
			}
		}
		return (root && typeof root.configurationChanged === "function") ? root : null
	}

	function normalizeDistroIconToken(token) {
		token = (token || "").toLowerCase().trim()
		if (!token) {
			return ""
		}

		if (token.indexOf("distributor-logo-") === 0) {
			token = token.substring("distributor-logo-".length)
		}

		token = token.replace(/^["']|["']$/g, "")

		var aliases = {
			"arch": "archlinux",
			"arch-linux": "archlinux",
			"opensuse": "opensuse",
			"opensuse-leap": "opensuse",
			"opensuse-microos": "opensuse",
			"opensuse-slowroll": "opensuse",
			"opensuse-tumbleweed": "opensuse",
			"redhat": "rhel",
			"red-hat": "rhel",
			"red-hat-enterprise-linux": "rhel",
			"rhel": "rhel",
			"linuxmint": "linux-mint",
			"linux-mint": "linux-mint",
			"pop": "pop-os",
			"pop-os": "pop-os",
			"pop_os": "pop-os",
			"endeavour": "endeavouros",
			"endeavouros": "endeavouros",
		}

		return aliases[token] || token
	}

	function pushUnique(target, value) {
		if (!value || target.indexOf(value) >= 0) {
			return
		}
		target.push(value)
	}

	function distroIconCandidates() {
		var candidates = []
		var tokens = []

		pushUnique(tokens, KCoreAddons.KOSRelease.id)
		pushUnique(tokens, KCoreAddons.KOSRelease.logo)

		var idLike = KCoreAddons.KOSRelease.idLike || []
		for (var i = 0; i < idLike.length; ++i) {
			pushUnique(tokens, idLike[i])
		}

		for (var j = 0; j < tokens.length; ++j) {
			var normalized = normalizeDistroIconToken(tokens[j])
			if (!normalized) {
				continue
			}
			pushUnique(candidates, "distributor-logo-" + normalized)
			pushUnique(candidates, normalized)
		}

		pushUnique(candidates, "start-here-kde")
		pushUnique(candidates, "start-here")
		return candidates
	}

	readonly property real pendingTileScale: {
		var rootKcm = getRootKcm()
		if (rootKcm && typeof rootKcm.cfg_tileScale !== "undefined") {
			return rootKcm.cfg_tileScale || 0
		}
		return plasmoid.configuration.tileScale || 0
	}

	readonly property int pendingCellBoxSize: {
		var tileMarginUnits = ConfigUtils.pendingValue(formLayout, "tileMargin", plasmoid.configuration.tileMargin) || 0
		var cellMarginUnits = tileMarginUnits / 2
		var cellSizeUnits = config.cellBoxUnits - tileMarginUnits
		var scale = pendingTileScale || 0
		var cellSize = Math.round(cellSizeUnits * scale * Screen.devicePixelRatio)
		var cellMargin = cellMarginUnits * scale * Screen.devicePixelRatio
		return Math.max(1, Math.round(cellMargin + cellSize + cellMargin))
	}

	function setPendingTileScale(scale) {
		var rootKcm = getRootKcm()
		if (!rootKcm || typeof rootKcm.cfg_tileScale === "undefined") {
			return
		}
		if (Math.abs((rootKcm.cfg_tileScale || 0) - scale) <= 0.0001) {
			return
		}
		rootKcm.cfg_tileScale = scale
		rootKcm.configurationChanged()
	}

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow Current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}
	readonly property var distroIconCandidateList: distroIconCandidates()
	property string distroPresetIcon: "start-here-kde"
	property bool distroPresetResolved: false

	// Keyboard shortcuts are handled by the main settings shell.

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	Repeater {
		model: formLayout.distroIconCandidateList
		delegate: Kirigami.Icon {
			required property string modelData
			source: modelData
			visible: false
			onValidChanged: {
				if (valid && !formLayout.distroPresetResolved) {
					formLayout.distroPresetIcon = modelData
					formLayout.distroPresetResolved = true
				}
			}
			Component.onCompleted: {
				if (valid && !formLayout.distroPresetResolved) {
					formLayout.distroPresetIcon = modelData
					formLayout.distroPresetResolved = true
				}
			}
		}
	}



	//-------------------------------------------------------
	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Panel Icon")
	}

	LibConfig.IconField {
		Layout.fillWidth: true
		configKey: 'icon'
		defaultValue: 'tiled_rld'
		previewIconSize: Kirigami.Units.iconSizes.large
		presetValues: [
			'format-border-set-none-symbolic',
			'applications-all-symbolic',
			'kde-symbolic',
			formLayout.distroPresetIcon,
			'choice-rhomb-symbolic',
			'choice-round-symbolic',
			'stateshape-symbolic',
			'beamerblock-symbolic',
		]
		showPresetLabel: false

		LibConfig.CheckBox {
			text: i18n("Fixed Size")
			configKey: 'fixedPanelIcon'
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Tiles")
	}

	LibConfig.CheckBox {
		configKey: 'useTileTabs'
		text: i18n("Tab Support")
		Kirigami.FormData.label: i18n("Tabs")
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
	RowLayout {
		Kirigami.FormData.label: i18n("Rounded Corners")
		LibConfig.CheckBox {
			id: tileRoundedCornersToggle
			text: i18n("Enable")
			configKey: 'tileRoundedCorners'
		}
		LibConfig.SpinBox {
			configKey: 'tileCornerRadius'
			suffix: i18n("px")
			minimumValue: 0
			maximumValue: 32
			enabled: tileRoundedCornersToggle.checked
		}
		QQC2.Label {
			text: i18n("Corner radius")
		}
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
		Kirigami.FormData.label: i18n("")
	}
	LibConfig.CheckBox {
		configKey: 'showTileTooltips'
		text: i18n("Show tooltips on hover")
		Kirigami.FormData.label: i18n("")
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
	LibConfig.ComboBox {
		configKey: "tileGroupLayout"
		Kirigami.FormData.label: i18n("Group Tile Layout")
		model: [
			{ value: "card", text: i18n("Card") },
			{ value: "classic", text: i18n("Classic") },
		]
	}
	RowLayout {
		id: presetTilesFolderRow
		Kirigami.FormData.label: i18n("Preset Tile Folder")
		Layout.fillWidth: true

		function pathToUrl(path) {
			var p = path || ""
			if (!p) {
				return ""
			}
			if (p.indexOf('://') !== -1) {
				return p
			}
			if (p.indexOf('~/') === 0) {
				var home = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation)
				if (home) {
					p = home + p.substr(1)
				}
			}
			if (p.indexOf('/') === 0) {
				return 'file://' + p
			}
			return p
		}

		function urlToPath(url) {
			if (!url) {
				return ''
			}
			var s = '' + url
			if (s.indexOf('file://') === 0) {
				s = s.substr('file://'.length)
			}
			return s
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

}
