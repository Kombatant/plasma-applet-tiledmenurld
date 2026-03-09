import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu
import "../libconfig" as LibConfig


LibConfig.FormKCM {
	id: formLayout

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return plasmaStyleText + ' (' + KSvg.ImageSet.imageSetName + ')'
	}

	// Keyboard shortcuts are handled by the main settings shell.

	property var config: TiledMenu.AppletConfig {
		id: config
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
			'openSUSE-distributor-logo',
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

	RowLayout {
		Kirigami.FormData.label: i18n("Tile Size")
		LibConfig.SpinBox {
			configKey: 'tileScale'
			suffix: 'x'
			minimumValue: 0.1
			maximumValue: 4
			decimals: 1
		}
		QQC2.Label {
			text: '' + config.cellBoxSize + i18n("px")
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
		Kirigami.FormData.label: i18n("Background Colour")
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
			{ value: "center", text: i18n("Centre") },
			{ value: "right", text: i18n("Right") },
		]
	}
	LibConfig.ComboBox {
		configKey: "showGroupTileNameBorder"
		Kirigami.FormData.label: i18n("Show border under Group Tile name")
		model: [
			{ value: true, text: i18n("Yes") },
			{ value: false, text: i18n("No") },
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
