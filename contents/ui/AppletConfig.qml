import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import Qt.labs.platform as QtLabsPlatform

Item {
	function _ensureSettingInitialized(key, defaultValue) {
		var cur = plasmoid.configuration[key]
		if (typeof cur === 'undefined' || cur === null) {
			plasmoid.configuration[key] = defaultValue
		}
	}

	function ensureAllSettingsInitialized() {
		// Ensure every setting defined in contents/config/main.xml has a concrete value.
		// This is primarily for upgrades (new keys) and for config UIs that don't
		// gracefully handle undefined values.
		_ensureSettingInitialized('icon', 'tiled_rld')

		// Upgrade default: older versions used the Kickoff icon name as the default.
		// If the user still has that legacy default, migrate it to our bundled icon.
		// (Do not touch other custom icon choices.)
		var legacyDefaultIcons = ['start-here-kde-symbolic', 'start-here-kde']
		if (legacyDefaultIcons.indexOf(plasmoid.configuration.icon) !== -1) {
			plasmoid.configuration.icon = 'tiled_rld'
		}

		_ensureSettingInitialized('fixedPanelIcon', true)
		_ensureSettingInitialized('searchResultsGrouped', true)
		_ensureSettingInitialized('searchDefaultFilters', [
			'krunner_systemsettings',
			'krunner_dictionary',
			'krunner_services',
			'calculator',
			'krunner_shell',
			'org.kde.windowedwidgets',
			'org.kde.datetime',
			'baloosearch',
			'locations',
			'unitconverter',
		])
		_ensureSettingInitialized('showRecentApps', true)
		_ensureSettingInitialized('recentOrdering', 1)
		_ensureSettingInitialized('numRecentApps', 5)
		_ensureSettingInitialized('sidebarShortcuts', [
			'xdg:DOCUMENTS',
			'xdg:PICTURES',
			'org.kde.dolphin.desktop',
			'systemsettings.desktop',
		])
		_ensureSettingInitialized('defaultAppListView', 'Alphabetical')
		_ensureSettingInitialized('aiProvider', 'openai')
		_ensureSettingInitialized('aiApiKey', '')
		_ensureSettingInitialized('aiOllamaUrl', 'http://127.0.0.1:11434')
		_ensureSettingInitialized('aiModel', '')
		_ensureSettingInitialized('aiDetectedModels', [])
		_ensureSettingInitialized('aiChatHistory', '')
		_ensureSettingInitialized('aiStreamChat', false)

		_ensureSettingInitialized('terminalApp', 'org.kde.konsole.desktop')
		_ensureSettingInitialized('taskManagerApp', 'org.kde.plasma-systemmonitor.desktop')
		_ensureSettingInitialized('fileManagerApp', 'org.kde.dolphin.desktop')

		// Base64 encoded XML string; empty string means "use default".
		_ensureSettingInitialized('tileModel', '')
		_ensureSettingInitialized('tileScale', 0.8)
		_ensureSettingInitialized('tileIconSize', 72)
		_ensureSettingInitialized('tileMargin', 5)
		_ensureSettingInitialized('tileRoundedCorners', true)
		_ensureSettingInitialized('tileCornerRadius', 6)
		_ensureSettingInitialized('tilesLocked', false)
		_ensureSettingInitialized('tileHoverEffect', 'classic')
		_ensureSettingInitialized('tileAnimatedPlayOnHover', true)

		// Use empty string to indicate "use theme/default".
		_ensureSettingInitialized('defaultTileColor', '')
		_ensureSettingInitialized('defaultTileGradient', false)
		_ensureSettingInitialized('sidebarBackgroundColor', '')

		_ensureSettingInitialized('hideSearchField', false)
		_ensureSettingInitialized('searchOnTop', false)
		_ensureSettingInitialized('searchFieldFollowsTheme', false)
		_ensureSettingInitialized('sidebarFollowsTheme', false)
		_ensureSettingInitialized('tileLabelAlignment', 'left')
		_ensureSettingInitialized('groupLabelAlignment', 'left')
		_ensureSettingInitialized('showGroupTileNameBorder', true)
		_ensureSettingInitialized('presetTilesFolder', '')
		_ensureSettingInitialized('appDescription', 'after')
		_ensureSettingInitialized('appListIconSize', 32)
		_ensureSettingInitialized('searchFieldHeight', 48)
		_ensureSettingInitialized('appListWidth', 350)
		_ensureSettingInitialized('popupHeight', 620)
		_ensureSettingInitialized('popupBackgroundOpacity', 0.8)
		_ensureSettingInitialized('favGridCols', 6)
		_ensureSettingInitialized('sidebarButtonSize', 48)
		_ensureSettingInitialized('sidebarIconSize', 30)
		_ensureSettingInitialized('sidebarPosition', 'left')
	}

	Component.onCompleted: {
		ensureAllSettingsInitialized()
	}

	function setAlpha(c, a) {
		var c2 = Qt.darker(c, 1)
		c2.a = a
		return c2
	}

	function ensureTrailingSlash(path) {
		if (!path) {
			return ""
		}
		return path.charAt(path.length - 1) === '/' ? path : path + '/'
	}

	function resolvePresetPath(path) {
		var p = path || ""
		if (!p) {
			return ""
		}
		if (typeof p !== 'string') {
			p = '' + p
		}
		p = p.trim()
		if (!p) {
			return ""
		}
		if (p.indexOf('file://') === 0) {
			p = p.substr('file://'.length)
		}
		if (p.indexOf('~/') === 0) {
			var home = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation)
			if (home) {
				p = home + p.substr(1)
			}
		}
		return p
	}

	function resolveDefaultPresetTilesFolder() {
		var pictures = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.PicturesLocation)
		if (pictures) {
			return pictures + '/TiledMenuReloaded'
		}
		var downloads = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.DownloadLocation)
		if (downloads) {
			return downloads
		}
		return ""
	}

	//--- Sizes
	readonly property int panelIconSize: 24 * Screen.devicePixelRatio
	readonly property int flatButtonSize: plasmoid.configuration.sidebarButtonSize * Screen.devicePixelRatio
	readonly property int flatButtonIconSize: plasmoid.configuration.sidebarIconSize * Screen.devicePixelRatio
	readonly property int sidebarWidth: flatButtonSize
	readonly property int sidebarMinOpenWidth: 200 * Screen.devicePixelRatio
	readonly property int sidebarRightMargin: 4 * Screen.devicePixelRatio
	readonly property string sidebarPosition: plasmoid.configuration.sidebarPosition || 'left'
	readonly property bool sidebarOnLeft: sidebarPosition === 'left'
	readonly property bool sidebarOnTop: sidebarPosition === 'top'
	readonly property bool sidebarOnBottom: sidebarPosition === 'bottom'
	readonly property bool sidebarHorizontal: sidebarOnTop || sidebarOnBottom
	readonly property int sidebarHeight: sidebarHorizontal ? flatButtonSize : -1
	readonly property int appListWidth: plasmoid.configuration.appListWidth * Screen.devicePixelRatio
	readonly property int tileEditorMinWidth: Math.max(350, 350 * Screen.devicePixelRatio)
	readonly property int minimumHeight: flatButtonSize * 5 // Issue #125

	property bool showSearch: false
	property bool isEditingTile: false
	readonly property int appAreaWidth: {
		if (isEditingTile) {
			return tileEditorMinWidth
		} else if (showSearch) {
			return appListWidth
		} else {
			return 0
		}
	}
	readonly property bool hideSearchField: plasmoid.configuration.hideSearchField
	readonly property bool searchOnTop: plasmoid.configuration.searchOnTop
	// When sidebar is on left, include it in the left section width
	// When sidebar is horizontal (top/bottom), don't include it in the left section
	readonly property int leftSectionWidth: {
		if (sidebarHorizontal) {
			return appAreaWidth
		} else {
			return sidebarWidth + sidebarRightMargin + appAreaWidth
		}
	}

	readonly property real tileScale: plasmoid.configuration.tileScale
	readonly property int cellBoxUnits: 80
	// "Tile Margin" is expressed as the *gap between tiles* in px.
	// Since adjacent tiles each contribute spacing on their touching edge,
	// we split the gap across each tile side.
	readonly property real tileMarginUnits: plasmoid.configuration.tileMargin
	readonly property real cellMarginUnits: tileMarginUnits / 2
	readonly property real cellSizeUnits: cellBoxUnits - tileMarginUnits
	readonly property int cellSize: Math.round(cellSizeUnits * tileScale * Screen.devicePixelRatio)
	readonly property real cellMargin: cellMarginUnits * tileScale * Screen.devicePixelRatio
	readonly property real cellPushedMargin: cellMargin * 2
	readonly property int cellBoxSize: Math.round(cellMargin + cellSize + cellMargin)
	readonly property int tileGridWidth: plasmoid.configuration.favGridCols * cellBoxSize
	readonly property int tileCornerRadius: Math.max(0, Math.round((plasmoid.configuration.tileRoundedCorners ? plasmoid.configuration.tileCornerRadius : 0) * Screen.devicePixelRatio))

	readonly property int favCellWidth: 60 * Screen.devicePixelRatio
	readonly property int favCellPushedMargin: 5 * Screen.devicePixelRatio
	readonly property int favCellPadding: 3 * Screen.devicePixelRatio
	readonly property int favColWidth: ((favCellWidth + favCellPadding * 2) * 2) // = 132 (Medium Size)
	readonly property int favViewDefaultWidth: (favColWidth * 3) * Screen.devicePixelRatio
	readonly property int favSmallIconSize: 32 * Screen.devicePixelRatio
	readonly property int favMediumIconSize: 72 * Screen.devicePixelRatio
	readonly property int favGridWidth: (plasmoid.configuration.favGridCols/2) * favColWidth

	readonly property int searchFieldHeight: plasmoid.configuration.searchFieldHeight * Screen.devicePixelRatio

	readonly property int popupWidth: leftSectionWidth + tileGridWidth
	readonly property int popupHeight: Math.floor((plasmoid.configuration.popupHeight || 620) * Screen.devicePixelRatio)
	// Hardcoded to 0 - fully transparent (blur is controlled by KDE Desktop Effects)
	readonly property real popupBackgroundOpacity: 0
	
	readonly property int appListIconSize: plasmoid.configuration.appListIconSize * Screen.devicePixelRatio
	
	readonly property int searchFilterRowHeight: {
		if (plasmoid.configuration.appListWidth >= 310) {
			return flatButtonSize // 60px
		} else if (plasmoid.configuration.appListWidth >= 250) {
			return flatButtonSize*3/4 // 45px
		} else {
			return flatButtonSize/2 // 30px
		}
	}

	readonly property string defaultPresetTilesFolder: resolveDefaultPresetTilesFolder()
	readonly property string presetTilesFolder: {
		var custom = resolvePresetPath(plasmoid.configuration.presetTilesFolder)
		if (custom) {
			return ensureTrailingSlash(custom)
		}
		var fallback = resolvePresetPath(defaultPresetTilesFolder)
		return fallback ? ensureTrailingSlash(fallback) : ""
	}

	//--- Colors
	readonly property color themeButtonBgColor: {
		if (KSvg.ImageSet.imageSetName == "oxygen") {
			return "#20FFFFFF"
		} else {
			return Kirigami.Theme.backgroundColor
		}
	}
	readonly property color defaultTileColor: plasmoid.configuration.defaultTileColor || themeButtonBgColor
	readonly property bool defaultTileGradient: plasmoid.configuration.defaultTileGradient
	readonly property color sidebarBackgroundColor: plasmoid.configuration.sidebarBackgroundColor || Kirigami.Theme.backgroundColor
	readonly property color menuItemTextColor2: setAlpha(Kirigami.Theme.textColor, 0.6)
	readonly property color favHoverOutlineColor: setAlpha(Kirigami.Theme.textColor, 0.8)
	readonly property color flatButtonBgHoverColor: themeButtonBgColor
	readonly property color flatButtonBgColor: Qt.rgba(flatButtonBgHoverColor.r, flatButtonBgHoverColor.g, flatButtonBgHoverColor.b, 0)
	readonly property color flatButtonBgPressedColor: Kirigami.Theme.highlightColor
	readonly property color flatButtonCheckedColor: Kirigami.Theme.highlightColor

	//--- Style
	// Tiles
	readonly property int tileLabelAlignment: {
		var val = plasmoid.configuration.tileLabelAlignment
		if (val === 'center') {
			return Text.AlignHCenter
		} else if (val === 'right') {
			return Text.AlignRight
		} else { // left
			return Text.AlignLeft
		}
	}
	readonly property int groupLabelAlignment: {
		var val = plasmoid.configuration.groupLabelAlignment
		if (val === 'center') {
			return Text.AlignHCenter
		} else if (val === 'right') {
			return Text.AlignRight
		} else { // left
			return Text.AlignLeft
		}
	}
	
	// App Description Enum (hidden, after, below)
	readonly property bool appDescriptionVisible: plasmoid.configuration.appDescription !== 'hidden'
	readonly property bool appDescriptionBelow: plasmoid.configuration.appDescription == 'below'

	//--- Settings
	// Search
	readonly property bool searchResultsGrouped: plasmoid.configuration.searchResultsGrouped
	
	//--- Tile Data
	property var tileModel: Base64XmlString {
		configKey: 'tileModel'
		defaultValue: []

		// defaultValue: [
		// 	{
		// 		"x": 0,
		// 		"y": 0,
		// 		"w": 2,
		// 		"h": 2,
		// 		"url": "org.kde.dolphin.desktop",
		// 		"label": "Files",
		// 	},
		// 	{
		// 		"x": 2,
		// 		"y": 1,
		// 		"w": 1,
		// 		"h": 1,
		// 		"url": "virtualbox.desktop",
		// 		"iconFill": true,
		// 	},
		// 	{
		// 		"x": 2,
		// 		"y": 0,
		// 		"w": 1,
		// 		"h": 1,
		// 		"url": "org.kde.ark.desktop",
		// 	},
		// ]
	}
}
