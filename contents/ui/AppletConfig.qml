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
		_ensureSettingInitialized('sidebarCollapsibleSearchResults', false)
		_ensureSettingInitialized('customAvatarPath', '')
		_ensureSettingInitialized('defaultAppListView', 'Alphabetical')
		_ensureSettingInitialized('lastUsedAppListView', 'Alphabetical')
		_ensureSettingInitialized('aiChatEnabled', true)
		_ensureSettingInitialized('aiProvider', 'openai')
		_ensureSettingInitialized('aiApiKey', '')
		_ensureSettingInitialized('aiOllamaUrl', 'http://127.0.0.1:11434')
		_ensureSettingInitialized('aiOpenWebUiUrl', 'http://127.0.0.1:3000')
		_ensureSettingInitialized('aiModel', '')
		_ensureSettingInitialized('aiDetectedModels', [])
		_ensureSettingInitialized('aiChatHistory', '')
		_ensureSettingInitialized('aiStreamChat', false)

		_ensureSettingInitialized('terminalApp', 'org.kde.konsole.desktop')
		_ensureSettingInitialized('taskManagerApp', 'org.kde.plasma-systemmonitor.desktop')
		_ensureSettingInitialized('fileManagerApp', 'org.kde.dolphin.desktop')

		// Tile tabs
		_ensureSettingInitialized('useTileTabs', false)
		_ensureSettingInitialized('tileTabStyle', 'tabs')
		_ensureSettingInitialized('tileTabs', '')

		// Base64 encoded XML string; empty string means "use default".
		_ensureSettingInitialized('tileModel', '')
		_ensureSettingInitialized('tileScale', 0.4)
		_ensureSettingInitialized('tileIconSize', 32)
		_ensureSettingInitialized('tileMargin', 12)
		_ensureSettingInitialized('tileRoundedCorners', true)
		_ensureSettingInitialized('tileCornerRadius', 6)
		_ensureSettingInitialized('tilesLocked', false)
		_ensureSettingInitialized('tileHoverEffect', 'classic')
		_ensureSettingInitialized('tileAnimatedPlayOnHover', true)
		_ensureSettingInitialized('showTileTooltips', false)

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
		if (plasmoid.configuration.groupLabelAlignment === 'center') {
			plasmoid.configuration.groupLabelAlignment = 'left'
		}
		_ensureSettingInitialized('tileGroupLayout', 'card')
		_ensureSettingInitialized('presetTilesFolder', '')
		_ensureSettingInitialized('appDescription', 'after')
		_ensureSettingInitialized('appListIconSize', 32)
		_ensureSettingInitialized('searchFieldHeight', 48)
		_ensureSettingInitialized('appListWidth', 350)
		_ensureSettingInitialized('dockedSidebarWidth', 350)
		_ensureSettingInitialized('popupHeight', 620)
		_ensureSettingInitialized('popupWidthAlphabetical', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightAlphabetical', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsAlphabetical', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthCategories', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightCategories', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsCategories', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthTilesOnly', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightTilesOnly', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsTilesOnly', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthAiChat', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightAiChat', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsAiChat', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthDockedAlphabetical', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightDockedAlphabetical', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsDockedAlphabetical', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthDockedCategories', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightDockedCategories', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsDockedCategories', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthDockedTilesOnly', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightDockedTilesOnly', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsDockedTilesOnly', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('popupWidthDockedAiChat', Math.round(popupWidth / (Screen.devicePixelRatio || 1)))
		_ensureSettingInitialized('popupHeightDockedAiChat', plasmoid.configuration.popupHeight)
		_ensureSettingInitialized('favGridColsDockedAiChat', plasmoid.configuration.favGridCols)
		_ensureSettingInitialized('favGridCols', 6)
		_ensureSettingInitialized('sidebarButtonSize', 48)
		_ensureSettingInitialized('sidebarIconSize', 30)
		_ensureSettingInitialized('sidebarPosition', 'left')
		_ensureSettingInitialized('useDockedLayout', true)
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

	function listLength(value) {
		if (!value) {
			return 0
		}
		if (Array.isArray(value)) {
			return value.length
		}
		if (typeof value.length === "number") {
			return value.length
		}
		return 0
	}

	//--- Sizes
	readonly property int flatButtonSize: plasmoid.configuration.sidebarButtonSize * Screen.devicePixelRatio
	readonly property int flatButtonIconSize: plasmoid.configuration.sidebarIconSize * Screen.devicePixelRatio
	readonly property int sidebarWidth: flatButtonSize
	readonly property int sidebarMinOpenWidth: 200 * Screen.devicePixelRatio
	readonly property int sidebarRightMargin: 4 * Screen.devicePixelRatio
	readonly property int sidebarCardInset: Math.max(Kirigami.Units.smallSpacing, Math.round(6 * Screen.devicePixelRatio))
	readonly property int sidebarCardContentPadding: Math.max(Kirigami.Units.smallSpacing, Math.round(5 * Screen.devicePixelRatio))
	readonly property int sidebarPaneGap: Kirigami.Units.smallSpacing
	readonly property string sidebarPosition: plasmoid.configuration.sidebarPosition || 'left'
	readonly property bool sidebarOnLeft: sidebarPosition === 'left'
	readonly property bool sidebarOnTop: sidebarPosition === 'top'
	readonly property bool sidebarOnBottom: sidebarPosition === 'bottom'
	readonly property bool sidebarHorizontal: sidebarOnTop || sidebarOnBottom
	readonly property int sidebarHeight: sidebarHorizontal ? flatButtonSize : -1
	readonly property int sidebarSeparatorThickness: Math.max(1, Math.round(Screen.devicePixelRatio))
	readonly property bool useDockedLayout: plasmoid.configuration.useDockedLayout !== false
	readonly property bool usesDockedSidebarLayout: useDockedLayout
	readonly property bool usesClassicLayout: !usesDockedSidebarLayout
	readonly property int profileIconSize: Math.round(72 * Screen.devicePixelRatio)
	readonly property bool aiChatEnabled: plasmoid.configuration.aiChatEnabled !== false
	readonly property int sidebarFixedHorizontalButtons: aiChatEnabled ? 8 : 7
	readonly property int sidebarFixedVerticalButtons: aiChatEnabled ? 8 : 7
	readonly property int sidebarFixedHorizontalWidth: (sidebarFixedHorizontalButtons * flatButtonSize) + (2 * sidebarSeparatorThickness)
	readonly property int sidebarFixedVerticalHeight: (sidebarFixedVerticalButtons * flatButtonSize) + (2 * sidebarSeparatorThickness)
	readonly property int appListWidth: Math.max(120, plasmoid.configuration.appListWidth) * Screen.devicePixelRatio
	readonly property int dockedSidebarConfiguredWidth: Math.max(120, plasmoid.configuration.dockedSidebarWidth || 350) * Screen.devicePixelRatio
	readonly property int dockedSidebarShortcutButtons: {
		var configuredCount = listLength(plasmoid.configuration.sidebarShortcuts)
		var modelCount = (typeof appsModel !== "undefined" && appsModel && appsModel.sidebarModel) ? appsModel.sidebarModel.count : 0
		return Math.max(1, Math.max(configuredCount, modelCount) + 1)
	}
	readonly property int dockedSidebarPowerButtons: {
		var visibleCount = 0
		var sessionIcons = {
			"system-lock-screen": true,
			"system-log-out": true,
			"system-save-session": true,
			"system-switch-user": true,
		}
		if (typeof appsModel !== "undefined" && appsModel && appsModel.powerActionsModel && appsModel.powerActionsModel.list) {
			for (var i = 0; i < appsModel.powerActionsModel.list.length; i++) {
				var action = appsModel.powerActionsModel.list[i]
				if (!action || action.disabled || sessionIcons[action.iconName]) {
					continue
				}
				visibleCount += 1
			}
		}
		return Math.max(4, visibleCount)
	}
	readonly property int dockedSidebarMinWidth: Math.max(dockedSidebarShortcutButtons, dockedSidebarPowerButtons) * flatButtonSize
	readonly property int dockedSidebarWidth: Math.max(dockedSidebarConfiguredWidth, dockedSidebarMinWidth)
	readonly property int dockedSidebarSlotWidth: dockedSidebarWidth + (sidebarCardInset * 2) + (sidebarCardContentPadding * 2)
	readonly property int classicLeftSidebarSlotWidth: sidebarWidth + (sidebarCardInset * 2) + (sidebarCardContentPadding * 2) + sidebarPaneGap
	readonly property int tileEditorMinWidth: Math.max(350, 350 * Screen.devicePixelRatio)
	readonly property int minimumWidth: {
		return usesClassicLayout ? (sidebarHorizontal ? Math.max(leftSectionWidth, sidebarFixedHorizontalWidth) : leftSectionWidth) : 0
	}
	readonly property int minimumHeight: {
		if (usesDockedSidebarLayout) {
			return profileIconSize + (flatButtonSize * 4) // profile + buttons + power rows + some app list
		}
		return Math.max(flatButtonSize * 5, sidebarHorizontal ? (sidebarHeight + sidebarRightMargin) : sidebarFixedVerticalHeight) // Issue #125
	}

	property bool showSearch: false
	property bool searchOverlayActive: false
	property bool isEditingTile: false
	readonly property int appAreaWidth: {
		if (isEditingTile) {
			return tileEditorMinWidth
		} else if (showSearch && !searchOverlayActive) {
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
			return classicLeftSidebarSlotWidth + appAreaWidth
		}
	}
	readonly property int popupLeftSectionWidth: usesDockedSidebarLayout ? dockedSidebarSlotWidth : leftSectionWidth
	readonly property int minimumPopupWidth: usesDockedSidebarLayout ? (popupLeftSectionWidth + (cellBoxSize * 3)) : minimumWidth

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
	readonly property int cellBoxSize: Math.max(1, Math.round(cellMargin + cellSize + cellMargin))
	readonly property int tileGridWidth: plasmoid.configuration.favGridCols * cellBoxSize
	readonly property int tileCornerRadius: Math.max(0, Math.round((plasmoid.configuration.tileRoundedCorners ? plasmoid.configuration.tileCornerRadius : 0) * Screen.devicePixelRatio))

	readonly property int searchFieldHeight: plasmoid.configuration.searchFieldHeight * Screen.devicePixelRatio

	readonly property int popupWidth: popupLeftSectionWidth + tileGridWidth
	readonly property int popupHeight: Math.floor((plasmoid.configuration.popupHeight || 620) * Screen.devicePixelRatio)
	readonly property int appListIconSize: plasmoid.configuration.appListIconSize * Screen.devicePixelRatio
	
	readonly property int searchFilterReferenceWidth: {
		var dpr = Screen.devicePixelRatio || 1
		return usesDockedSidebarLayout ? Math.round(dockedSidebarWidth / dpr) : (plasmoid.configuration.appListWidth || 0)
	}
	readonly property int searchFilterRowHeight: {
		if (searchFilterReferenceWidth >= 310) {
			return flatButtonSize // 60px
		} else if (searchFilterReferenceWidth >= 250) {
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
	readonly property color flatButtonBgHoverColor: themeButtonBgColor
	readonly property color flatButtonBgColor: Qt.rgba(flatButtonBgHoverColor.r, flatButtonBgHoverColor.g, flatButtonBgHoverColor.b, 0)
	readonly property color flatButtonBgPressedColor: Kirigami.Theme.highlightColor
	readonly property color flatButtonCheckedColor: Kirigami.Theme.highlightColor

	//--- Style
	// Tiles
	readonly property bool showTileTooltips: !!plasmoid.configuration.showTileTooltips
	readonly property bool useTileTabs: !!plasmoid.configuration.useTileTabs
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
		if (val === 'right') {
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
	readonly property bool sidebarCollapsibleSearchResults: !!plasmoid.configuration.sidebarCollapsibleSearchResults
	
	//--- Tile Data
	property var tileModel: Base64XmlString {
		configKey: 'tileModel'
		defaultValue: []
	}
}
