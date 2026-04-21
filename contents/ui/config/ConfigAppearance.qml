import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils

LibConfig.FormKCM {
	id: formLayout
	wideMode: false
	readonly property bool pendingSurfaceFollowsTheme: !!(formLayout.cfg_sidebarFollowsTheme !== undefined ? formLayout.cfg_sidebarFollowsTheme : plasmoid.configuration.sidebarFollowsTheme)

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow Current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Shared Surfaces")
	}

	LibConfig.RadioButtonGroup {
		id: surfaceThemeGroup
		spacing: 0
		Kirigami.FormData.label: i18n("Surface Colour")

		QQC2.RadioButton {
			text: plasmaStyleLabelText
			QQC2.ButtonGroup.group: surfaceThemeGroup.group
			checked: formLayout.pendingSurfaceFollowsTheme
			onClicked: ConfigUtils.setPendingValue(formLayout, "sidebarFollowsTheme", true)
		}

		RowLayout {
			QQC2.RadioButton {
				text: i18n("Custom Colour")
				QQC2.ButtonGroup.group: surfaceThemeGroup.group
				checked: !formLayout.pendingSurfaceFollowsTheme
				onClicked: ConfigUtils.setPendingValue(formLayout, "sidebarFollowsTheme", false)
			}

			LibConfig.ColorField {
				configKey: 'sidebarBackgroundColor'
			}
		}
	}

	RowLayout {
		Kirigami.FormData.label: i18n("Surface Corners")

		LibConfig.CheckBox {
			id: surfaceRoundedCornersToggle
			text: i18n("Rounded corners")
			configKey: 'tileRoundedCorners'
		}

		LibConfig.SpinBox {
			configKey: 'tileCornerRadius'
			suffix: i18n("px")
			minimumValue: 0
			maximumValue: 32
			enabled: surfaceRoundedCornersToggle.checked
		}

		QQC2.Label {
			text: i18n("Corner radius")
		}
	}

	LibConfig.CheckBox {
		Kirigami.FormData.label: i18n("Surface Borders")
		text: i18n("Hide glass surface borders")
		configKey: 'sidebarHideBorder'
	}

	QQC2.Label {
		Kirigami.FormData.label: ""
		text: i18n("Applies to tiles, group panels, sidebar cards, search box, and pill tab bar surfaces.")
		wrapMode: Text.WordWrap
		Layout.fillWidth: true
		opacity: 0.75
	}
}
