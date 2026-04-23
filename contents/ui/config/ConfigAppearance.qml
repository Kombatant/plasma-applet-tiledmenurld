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
	readonly property string pendingSurfaceStyle: {
		var value = formLayout.cfg_surfaceStyle !== undefined ? ("" + formLayout.cfg_surfaceStyle) : ("" + plasmoid.configuration.surfaceStyle)
		if (value === "theme" || value === "custom" || value === "frosted") {
			return value
		}
		return pendingSurfaceFollowsTheme ? "theme" : "custom"
	}

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return i18n("Follow Current %1 (%2)", plasmaStyleText, KSvg.ImageSet.imageSetName)
	}

	function setPendingSurfaceStyle(style) {
		ConfigUtils.setPendingValue(formLayout, "surfaceStyle", style)
		ConfigUtils.setPendingValue(formLayout, "sidebarFollowsTheme", style === "theme" || style === "frosted")
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Shared Surfaces")
	}

	LibConfig.RadioButtonGroup {
		id: surfaceThemeGroup
		spacing: 0
		Kirigami.FormData.label: i18n("Surface Style")

		QQC2.RadioButton {
			text: plasmaStyleLabelText
			QQC2.ButtonGroup.group: surfaceThemeGroup.group
			checked: formLayout.pendingSurfaceStyle === "theme"
			onClicked: formLayout.setPendingSurfaceStyle("theme")
		}

		RowLayout {
			QQC2.RadioButton {
				text: i18n("Custom Colour")
				QQC2.ButtonGroup.group: surfaceThemeGroup.group
				checked: formLayout.pendingSurfaceStyle === "custom"
				onClicked: formLayout.setPendingSurfaceStyle("custom")
			}

			LibConfig.ColorField {
				configKey: 'sidebarBackgroundColor'
				enabled: formLayout.pendingSurfaceStyle === "custom"
				opacity: enabled ? 1 : 0.45
			}
		}

		QQC2.RadioButton {
			text: i18n("Frosted Glass")
			QQC2.ButtonGroup.group: surfaceThemeGroup.group
			checked: formLayout.pendingSurfaceStyle === "frosted"
			onClicked: formLayout.setPendingSurfaceStyle("frosted")
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
		text: i18n("Hide surface borders")
		configKey: 'sidebarHideBorder'
	}

	RowLayout {
		Kirigami.FormData.label: i18n("Surface Shadows")

		LibConfig.ComboBox {
			configKey: "surfaceShadowDarkness"
			model: [
				{ value: "normal", text: i18n("Normal") },
				{ value: "dark", text: i18n("Dark") },
				{ value: "darker", text: i18n("Darker") },
			]
		}

		LibConfig.ComboBox {
			configKey: "surfaceShadowSize"
			model: [
				{ value: "normal", text: i18n("Normal") },
				{ value: "large", text: i18n("Large") },
				{ value: "extraLarge", text: i18n("Extra Large") },
			]
		}
	}

	QQC2.Label {
		Kirigami.FormData.label: ""
		text: i18n("Applies to tiles, group panels, sidebar cards, search box, and pill tab bar surfaces.")
		wrapMode: Text.WordWrap
		Layout.fillWidth: true
		opacity: 0.75
	}
}
