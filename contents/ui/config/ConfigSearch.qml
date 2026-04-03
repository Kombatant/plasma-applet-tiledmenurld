import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import ".." as TiledMenu
import "../libconfig" as LibConfig


LibConfig.FormKCM {
	id: formLayout
	wideMode: false
	readonly property bool searchFieldHidden: !!plasmoid.configuration.hideSearchField
	readonly property bool searchOptionsEnabled: !searchFieldHidden
	readonly property bool groupedSearchResultsEnabled: formLayout.searchOptionsEnabled
		&& !!plasmoid.configuration.searchResultsGrouped
	readonly property bool searchFieldHeightEnabled: searchOptionsEnabled
		&& plasmoid.configuration.sidebarPosition !== 'top'
		&& plasmoid.configuration.sidebarPosition !== 'bottom'

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
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
	}

	LibConfig.SpinBox {
		configKey: 'searchFieldHeight'
		Kirigami.FormData.label: i18n("Search Field Height")
		suffix: i18n("px")
		minimumValue: 0
		enabled: formLayout.searchFieldHeightEnabled
		opacity: enabled ? 1 : 0.45
	}

	LibConfig.RadioButtonGroup {
		Kirigami.FormData.label: i18n("Search Box Theme")
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
		QQC2.RadioButton {
			text: plasmaStyleLabelText
			checked: plasmoid.configuration.searchFieldFollowsTheme
			onClicked: plasmoid.configuration.searchFieldFollowsTheme = true
		}
		QQC2.RadioButton {
			text: i18n("Windows (White)")
			checked: !plasmoid.configuration.searchFieldFollowsTheme
			onClicked: plasmoid.configuration.searchFieldFollowsTheme = false
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
