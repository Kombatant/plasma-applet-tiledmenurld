import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import ".." as TiledMenu
import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils


LibConfig.FormKCM {
	id: formLayout
	wideMode: false
	readonly property bool searchFieldHidden: !!(formLayout.cfg_hideSearchField !== undefined ? formLayout.cfg_hideSearchField : plasmoid.configuration.hideSearchField)
	readonly property bool searchOptionsEnabled: !searchFieldHidden
	readonly property bool pendingUsesClassicLayout: !(formLayout.cfg_useDockedLayout !== undefined ? formLayout.cfg_useDockedLayout : plasmoid.configuration.useDockedLayout)
	readonly property bool groupedSearchResultsEnabled: formLayout.searchOptionsEnabled
		&& !!(formLayout.cfg_searchResultsGrouped !== undefined ? formLayout.cfg_searchResultsGrouped : plasmoid.configuration.searchResultsGrouped)
	readonly property string pendingSidebarPosition: formLayout.cfg_sidebarPosition !== undefined ? formLayout.cfg_sidebarPosition : plasmoid.configuration.sidebarPosition
	readonly property bool searchOnTopEnabled: formLayout.searchOptionsEnabled
		&& formLayout.pendingUsesClassicLayout
		&& formLayout.pendingSidebarPosition === 'left'
	readonly property bool searchFieldHeightEnabled: searchOptionsEnabled
		&& formLayout.pendingUsesClassicLayout

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow Current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}

	// Keyboard shortcuts are handled by the main settings shell.

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Search Box")
	}

	LibConfig.CheckBox {
		configKey: 'hideSearchField'
		text: i18n("Hide Search Field")
		Kirigami.FormData.label: ""
	}

	LibConfig.CheckBox {
		configKey: 'searchOnTop'
		text: i18n("Search On Top")
		Kirigami.FormData.label: ""
		enabled: formLayout.searchOnTopEnabled
		opacity: enabled ? 1 : 0.45
	}

	LibConfig.SpinBox {
		configKey: 'searchFieldHeight'
		Kirigami.FormData.label: i18n("Search Field Height")
		suffix: i18n("px")
		minimumValue: 1
		enabled: formLayout.searchFieldHeightEnabled
		opacity: enabled ? 1 : 0.45
	}

	LibConfig.RadioButtonGroup {
		Kirigami.FormData.label: i18n("Search Box Theme")
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45

		property bool searchFieldFollowsThemeValue: !!plasmoid.configuration.searchFieldFollowsTheme
		function _refreshSearchFieldFollowsTheme() {
			searchFieldFollowsThemeValue = !!(formLayout.cfg_searchFieldFollowsTheme !== undefined ? formLayout.cfg_searchFieldFollowsTheme : plasmoid.configuration.searchFieldFollowsTheme)
		}
		property var _disconnectSearchFieldFollowsTheme: null
		Component.onCompleted: {
			_refreshSearchFieldFollowsTheme()
			_disconnectSearchFieldFollowsTheme = ConfigUtils.connectConfigChange(formLayout, "searchFieldFollowsTheme", _refreshSearchFieldFollowsTheme)
		}
		Component.onDestruction: {
			if (_disconnectSearchFieldFollowsTheme) _disconnectSearchFieldFollowsTheme()
		}

		QQC2.RadioButton {
			text: plasmaStyleLabelText
			checked: parent.searchFieldFollowsThemeValue
			onClicked: ConfigUtils.setPendingValue(formLayout, "searchFieldFollowsTheme", true)
		}
		QQC2.RadioButton {
			text: i18n("Windows (White)")
			checked: !parent.searchFieldFollowsThemeValue
			onClicked: ConfigUtils.setPendingValue(formLayout, "searchFieldFollowsTheme", false)
		}
	}

	Item {
		Kirigami.FormData.isSection: false
		Kirigami.FormData.label: ""
		implicitHeight: Kirigami.Units.gridUnit
	}

	LibConfig.CheckBox {
		configKey: 'searchResultsGrouped'
		text: i18n("Group search results")
		Kirigami.FormData.label: ""
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
	}

	Item {
		Kirigami.FormData.isSection: false
		Kirigami.FormData.label: ""
		implicitWidth: collapseSearchResultGroupsRow.implicitWidth
		implicitHeight: collapseSearchResultGroupsRow.implicitHeight
		visible: true
		opacity: formLayout.searchOptionsEnabled ? 1 : 0.45

		RowLayout {
			id: collapseSearchResultGroupsRow
			anchors.left: parent.left
			anchors.right: parent.right
			spacing: 0

			Item {
				Layout.preferredWidth: Kirigami.Units.largeSpacing * 2
			}

			LibConfig.CheckBox {
				configKey: 'sidebarCollapsibleSearchResults'
				text: i18n("Collapse Search Result Groups")
				enabled: formLayout.groupedSearchResultsEnabled
				opacity: enabled ? 1 : 0.45
			}
		}
	}
}
