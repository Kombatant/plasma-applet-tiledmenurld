// Version 5

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
	id: formPage
	default property alias _formChildren: formLayout.data
	property string title: ""
	property alias wideMode: formLayout.wideMode
	readonly property int uniformComboBoxWidth: Kirigami.Units.gridUnit * 12
	readonly property int uniformSpinBoxWidth: Kirigami.Units.gridUnit * 7
	implicitWidth: formLayout.implicitWidth
	implicitHeight: formLayout.implicitHeight

	// Plasma's config dialog sets cfg_<key> / cfg_<key>Default on each page
	// root via setInitialProperties. We inherit all declarations here so every
	// page that extends FormKCM can stage edits via those props. Keys must
	// stay in sync with contents/config/main.xml.
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
	property var cfg_surfaceStyle
	property var cfg_surfaceStyleDefault
	property var cfg_surfaceShadowDarkness
	property var cfg_surfaceShadowDarknessDefault
	property var cfg_surfaceShadowSize
	property var cfg_surfaceShadowSizeDefault
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
	// This ensures controls look correct in light mode when Plasma theme is dark
	Kirigami.Theme.colorSet: Kirigami.Theme.Window
	Kirigami.Theme.inherit: false

	// Kirigami.Theme only drives Kirigami-aware colors; QQC2 controls still read
	// Qt's palette, which otherwise stays tied to the Plasma theme (often dark).
	// Bind palette to Kirigami.Theme so QQC2 Buttons, ComboBox items, RadioButton
	// indicators, and the dialog's Apply button render with matching light colors.
	palette.window: Kirigami.Theme.backgroundColor
	palette.windowText: Kirigami.Theme.textColor
	palette.base: Kirigami.Theme.backgroundColor
	palette.alternateBase: Kirigami.Theme.alternateBackgroundColor
	palette.text: Kirigami.Theme.textColor
	palette.button: Kirigami.Theme.backgroundColor
	palette.buttonText: Kirigami.Theme.textColor
	palette.highlight: Kirigami.Theme.highlightColor
	palette.highlightedText: Kirigami.Theme.highlightedTextColor
	palette.toolTipBase: Kirigami.Theme.backgroundColor
	palette.toolTipText: Kirigami.Theme.textColor
	palette.placeholderText: Kirigami.Theme.disabledTextColor
	palette.mid: Kirigami.Theme.disabledTextColor
	palette.midlight: Kirigami.Theme.alternateBackgroundColor
	palette.dark: Kirigami.Theme.disabledTextColor
	palette.light: Kirigami.Theme.backgroundColor
	palette.shadow: Kirigami.Theme.disabledTextColor
	palette.link: Kirigami.Theme.linkColor
	palette.linkVisited: Kirigami.Theme.visitedLinkColor

	QQC2.ScrollView {
		id: scrollView
		anchors.fill: parent
		clip: true

		Item {
			width: scrollView.availableWidth
			implicitHeight: formLayout.implicitHeight + formLayout.anchors.topMargin * 2

			Kirigami.FormLayout {
				id: formLayout
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.leftMargin: Kirigami.Units.gridUnit * 2
				anchors.topMargin: Kirigami.Units.largeSpacing
				anchors.rightMargin: Kirigami.Units.gridUnit
			}
		}
	}

	function _alignInternalFormLayout() {
		const internalLayout = formLayout.children.length > 0 ? formLayout.children[0] : null
		if (!internalLayout || !internalLayout.anchors) {
			return
		}

		// Kirigami.FormLayout narrows to its implicit width and centers itself
		// when wideMode is false. That makes sparse settings pages look centered
		// instead of following the left edge used by denser pages such as General.
		internalLayout.anchors.horizontalCenter = undefined
		internalLayout.anchors.left = Qt.binding(function() {
			return formLayout.left
		})
		internalLayout.width = Qt.binding(function() {
			return formLayout.wideMode ? formLayout.implicitWidth : formLayout.width
		})
	}

	Component.onCompleted: {
		Qt.callLater(formPage._alignInternalFormLayout)
	}
}
