import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
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

	readonly property real pendingTileScale: {
		var raw = formLayout.cfg_tileScale !== undefined ? formLayout.cfg_tileScale : plasmoid.configuration.tileScale
		return raw || 0
	}
	readonly property bool pendingUseTileTabs: !!(formLayout.cfg_useTileTabs !== undefined ? formLayout.cfg_useTileTabs : plasmoid.configuration.useTileTabs)
	readonly property string pendingTileTabStyle: {
		var raw = formLayout.cfg_tileTabStyle !== undefined ? formLayout.cfg_tileTabStyle : plasmoid.configuration.tileTabStyle
		if (raw === "pills") return "pills"
		if (raw === "underline") return "underline"
		return "tabs"
	}
	readonly property string pendingDefaultTileColorMode: {
		var raw = formLayout.cfg_defaultTileColorMode !== undefined ? ("" + formLayout.cfg_defaultTileColorMode) : ("" + plasmoid.configuration.defaultTileColorMode)
		if (raw === "theme" || raw === "custom" || raw === "transparent") {
			return raw
		}
		var legacyValue = formLayout.cfg_defaultTileColor !== undefined ? ("" + formLayout.cfg_defaultTileColor) : ("" + plasmoid.configuration.defaultTileColor)
		if (legacyValue === "#00000000") {
			return "transparent"
		}
		if (legacyValue.length > 0) {
			return "custom"
		}
		return "theme"
	}
	readonly property string pendingTileTabMode: pendingUseTileTabs ? pendingTileTabStyle : "disabled"
	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}
	readonly property string plasmaStyleTileColorText: "" + Kirigami.Theme.highlightColor

	readonly property int pendingCellBoxSize: {
		var rawMargin = formLayout.cfg_tileMargin !== undefined ? formLayout.cfg_tileMargin : plasmoid.configuration.tileMargin
		var tileMarginUnits = rawMargin || 0
		var cellMarginUnits = tileMarginUnits / 2
		var cellSizeUnits = config.cellBoxUnits - tileMarginUnits
		var scale = pendingTileScale || 0
		var cellSize = Math.round(cellSizeUnits * scale * Screen.devicePixelRatio)
		var cellMargin = Math.round(cellMarginUnits * scale * Screen.devicePixelRatio)
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
			var style = (mode === "pills" || mode === "underline") ? mode : "tabs"
			ConfigUtils.setPendingValue(formLayout, "tileTabStyle", style)
		}
	}

	function setPendingDefaultTileColorMode(mode) {
		ConfigUtils.setPendingValue(formLayout, "defaultTileColorMode", mode)
		if (mode === "custom") {
			var currentColor = formLayout.cfg_defaultTileColor !== undefined ? ("" + formLayout.cfg_defaultTileColor) : ("" + plasmoid.configuration.defaultTileColor)
			if (!currentColor || currentColor === "#00000000") {
				ConfigUtils.setPendingValue(formLayout, "defaultTileColor", plasmaStyleTileColorText)
			}
		}
	}

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	tabs: [
		LibConfig.FormTab {
			title: i18n("Tabs")

			LibConfig.ComboBox {
				configValue: formLayout.pendingTileTabMode
				Kirigami.FormData.label: i18n("Tab style:")
				onActivated: formLayout.setPendingTileTabMode(currentItem.value)
				model: [
					{ value: "disabled", text: i18n("Disable Tabs") },
					{ value: "tabs", text: i18n("Accent Tab") },
					{ value: "underline", text: i18n("Underline") },
					{ value: "pills", text: i18n("Pills") },
				]
			}

			LibConfig.CheckBox {
				text: i18n("Remember last open tab")
				configKey: 'rememberLastOpenTab'
				enabled: formLayout.pendingUseTileTabs
			}

			LibConfig.CheckBox {
				text: i18n("Add a Popular tab")
				configKey: 'showPopularTab'
				enabled: formLayout.pendingUseTileTabs
			}

			LibConfig.SpinBox {
				Kirigami.FormData.label: i18n("Popular applications to display:")
				configKey: 'numMostUsedApps'
				enabled: formLayout.pendingUseTileTabs
				minimumValue: 1
				maximumValue: 15
			}

			QQC2.Label {
				Layout.fillWidth: true
				wrapMode: Text.Wrap
				opacity: 0.8
				text: i18n("The Popular tab ranks applications using KDE's application history for the current Activity. Its Most Recent group shows recently launched applications that aren't already listed, using the App History count from Menu › App List. KDE keeps that history; removing the tab doesn't clear it.")
			}
		},
		LibConfig.FormTab {
			title: i18n("Size & Spacing")

			RowLayout {
				id: tileSizeRow
				Kirigami.FormData.label: i18n("Tile size:")

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
				Kirigami.FormData.label: i18n("Tile icon size:")
				Layout.fillWidth: true
				LibConfig.SpinBox {
					configKey: 'tileIconSize'
					suffix: i18n("px")
					minimumValue: 16
					maximumValue: 256
					decimals: 0
				}
				QQC2.Label {
					Layout.fillWidth: true
					wrapMode: Text.Wrap
					opacity: 0.8
					text: i18n("Base size for tile icons; small/large variants scale from this")
				}
			}
			LibConfig.SpinBox {
				configKey: 'tileMargin'
				Kirigami.FormData.label: i18n("Tile margin:")
				suffix: i18n("px")
				minimumValue: 12
				maximumValue: config.cellBoxUnits/2
			}
		},
		LibConfig.FormTab {
			title: i18n("Colours & Effects")

			LibConfig.RadioButtonGroup {
				id: tilesThemeGroup
				Kirigami.FormData.label: i18n("Standalone tile background:")
				spacing: 0 // "Custom Colour" has lots of spacings already

				QQC2.RadioButton {
					text: formLayout.plasmaStyleLabelText
					QQC2.ButtonGroup.group: tilesThemeGroup.group
					checked: formLayout.pendingDefaultTileColorMode === "theme"
					onClicked: formLayout.setPendingDefaultTileColorMode("theme")
				}

				RowLayout {
					QQC2.RadioButton {
						id: defaultTileColorRadioButton
						text: i18n("Custom colour")
						QQC2.ButtonGroup.group: tilesThemeGroup.group
						checked: formLayout.pendingDefaultTileColorMode === "custom"
						onClicked: formLayout.setPendingDefaultTileColorMode("custom")
					}
					LibConfig.ColorField {
						id: defaultTileColorColor
						configKey: 'defaultTileColor'
						enabled: formLayout.pendingDefaultTileColorMode === "custom"
						opacity: enabled ? 1 : 0.45
					}
				}
				QQC2.RadioButton {
					id: transparentTileColorRadioButton
					text: i18n("Transparent")
					QQC2.ButtonGroup.group: tilesThemeGroup.group
					checked: formLayout.pendingDefaultTileColorMode === "transparent"
					onClicked: formLayout.setPendingDefaultTileColorMode("transparent")
				}
				LibConfig.CheckBox {
					text: i18n("Gradient")
					configKey: 'defaultTileGradient'
					enabled: formLayout.pendingDefaultTileColorMode !== "transparent"
					opacity: enabled ? 1 : 0.45
				}
			}
			LibConfig.RadioButtonGroup {
				configKey: "groupedTileBackground"
				Kirigami.FormData.label: i18n("Grouped tile background:")
				model: [
					{ value: "panel", text: i18n("Group panel") },
					{ value: "standalone", text: i18n("Same as standalone tiles") },
				]
			}
			LibConfig.ComboBox {
				configKey: "tileHoverEffect"
				Kirigami.FormData.label: i18n("Hover effect:")
				model: [
					{ value: "classic", text: i18n("Classic") },
					{ value: "pills", text: i18n("Pills") },
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
		},
		LibConfig.FormTab {
			title: i18n("Labels & Groups")

			LibConfig.ComboBox {
				configKey: "tileLabelAlignment"
				Kirigami.FormData.label: i18n("Tile label alignment:")
				model: [
					{ value: "left", text: i18n("Left") },
					{ value: "center", text: i18n("Centre") },
					{ value: "right", text: i18n("Right") },
				]
			}
			LibConfig.ComboBox {
				configKey: "groupLabelAlignment"
				Kirigami.FormData.label: i18n("Group label alignment:")
				model: [
					{ value: "left", text: i18n("Left") },
					{ value: "right", text: i18n("Right") },
				]
			}

			LibConfig.ComboBox {
				configKey: "tileGroupLayout"
				Kirigami.FormData.label: i18n("Group layout:")
				model: [
					{ value: "card", text: i18n("Card") },
					{ value: "classic", text: i18n("Classic") },
				]
			}

			LibConfig.CheckBox {
				configKey: 'tilesLocked'
				text: i18n("Lock tiles")
			}

			LibConfig.Heading {
				text: i18n("Preset tiles")
			}

			RowLayout {
				id: presetTilesFolderRow
				Kirigami.FormData.label: i18n("Preset tile folder:")
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
		}
	]
}
