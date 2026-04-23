import QtQuick
import QtQuick.Layouts
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.config as KConfig
import org.kde.kcmutils as KCM
import "./lib/" as Lib

ColumnLayout {
	id: leftPane
	spacing: 0

	property alias searchViewSlot: searchViewSlotItem

	// ── Helper to save view size before switching ──
	function switchView(action) {
		if (popup && typeof popup.saveCurrentViewSize === "function") {
			popup.saveCurrentViewSize()
		}
		if (typeof action === "function") {
			action()
		}
	}

	Timer {
		id: autoResizeDebounce
		interval: 200
		repeat: false
		onTriggered: {
			if (popup && typeof popup.autoResizeToContent === "function") {
				popup.autoResizeToContent()
			}
		}
	}

	// Settings icon luminance detection
	function _relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		return (0.2126 * channel(color.r)) + (0.7152 * channel(color.g)) + (0.0722 * channel(color.b))
	}
	readonly property color _sidebarIconBackdrop: config.surfaceBaseColor
	readonly property bool _bgIsLight: _relativeLuminance(_sidebarIconBackdrop) > 0.6
	readonly property url settingsIconSource: Qt.resolvedUrl(_bgIsLight ? "assets/tiled-settings-light.png" : "assets/tiled-settings-dark.png")

	// ──────────────────────────────────────────────
	// 1. Large circular user profile icon
	// ──────────────────────────────────────────────
	Item {
		id: profileButton
		Layout.alignment: Qt.AlignHCenter
		Layout.preferredWidth: config.profileIconSize
		Layout.preferredHeight: config.profileIconSize
		Layout.topMargin: Kirigami.Units.largeSpacing
		Layout.bottomMargin: Kirigami.Units.smallSpacing

		SunkenAvatar {
			anchors.fill: parent
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.RightButton
			cursorShape: Qt.PointingHandCursor
			hoverEnabled: true
			onClicked: {
				userMenu.toggleOpen()
			}
		}

		ProfileContextMenu {
			id: userMenu
			visualParent: profileButton
		}
	}

	// ──────────────────────────────────────────────
	// 2. Horizontal row of view-mode buttons
	// ──────────────────────────────────────────────
	RowLayout {
		Layout.alignment: Qt.AlignHCenter
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		spacing: 0

		SidebarViewButton {
			appletIconName: "view-list-tree"
			labelText: i18n("Categories")
			defaultCheckedEdge: Qt.BottomEdge
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			onClicked: leftPane.switchView(function() { appsView.showAppsCategorically() })
			checked: searchView.showingAppsCategorically
		}

		SidebarViewButton {
			appletIconName: "view-list-text"
			labelText: i18n("Alphabetical")
			defaultCheckedEdge: Qt.BottomEdge
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			onClicked: leftPane.switchView(function() { appsView.showAppsAlphabetically() })
			checked: searchView.showingAppsAlphabetically
		}

		// "Tiles Only" not applicable in integrated layout — app list is always visible

		SidebarViewButton {
			appletIconName: "dialog-messages"
			labelText: i18n("AI Chat")
			defaultCheckedEdge: Qt.BottomEdge
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			onClicked: leftPane.switchView(function() { searchView.showAiChat() })
			checked: searchView.showingAiChat
			visible: config.aiChatEnabled
		}

		SidebarItem {
			icon.name: "transform-scale"
			text: i18n("Auto Resize")
			tooltipText: i18n("Auto Resize")
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			onClicked: autoResizeDebounce.restart()
		}
	}

	// ──────────────────────────────────────────────
	// 3. Separator
	// ──────────────────────────────────────────────
	Rectangle {
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		height: 1
		color: Kirigami.Theme.textColor
		opacity: 0.15
	}

	// ──────────────────────────────────────────────
	// 4. SearchView slot (app list)
	// ──────────────────────────────────────────────
	Item {
		id: searchViewSlotItem
		Layout.fillWidth: true
		Layout.fillHeight: true
	}

	// ──────────────────────────────────────────────
	// 5. Separator
	// ──────────────────────────────────────────────
	Rectangle {
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		height: 1
		color: Kirigami.Theme.textColor
		opacity: 0.15
	}

	// ──────────────────────────────────────────────
	// 6. Sidebar favourites row (pinned shortcuts)
	// ──────────────────────────────────────────────
	RowLayout {
		Layout.alignment: Qt.AlignHCenter
		Layout.fillWidth: true
		spacing: 0

		property QtObject xdgUserDir: Lib.XdgUserDir {}

		Repeater {
			model: appsModel.sidebarModel
			delegate: SidebarItem {
				icon.name: resolvedIconName
				icon.source: resolvedIconSource
				forceMonochromeIcon: true
				desaturateIcon: true
				text: xdgDisplayName || model.name || model.display
				tooltipText: text
				Layout.fillWidth: false
				Layout.preferredWidth: config.flatButtonSize
				Layout.preferredHeight: config.flatButtonSize
				onClicked: {
					var xdgFolder = isLocalizedFolder()
					if (xdgFolder === 'DOCUMENTS') {
						Qt.openUrlExternally(parent.parent.xdgUserDir.documents)
					} else if (xdgFolder === 'DOWNLOAD') {
						Qt.openUrlExternally(parent.parent.xdgUserDir.download)
					} else if (xdgFolder === 'MUSIC') {
						Qt.openUrlExternally(parent.parent.xdgUserDir.music)
					} else if (xdgFolder === 'PICTURES') {
						Qt.openUrlExternally(parent.parent.xdgUserDir.pictures)
					} else if (xdgFolder === 'VIDEOS') {
						Qt.openUrlExternally(parent.parent.xdgUserDir.videos)
					} else {
						appsModel.sidebarModel.triggerIndex(index)
					}
				}

				function isLocalizedFolder() {
					var s = model.url ? model.url.toString() : ''
					if (s.indexOf('xdg:') === 0) {
						var folder = s.substring(4)
						if (['DOCUMENTS', 'DOWNLOAD', 'MUSIC', 'PICTURES', 'VIDEOS'].indexOf(folder) >= 0) {
							return folder
						}
					}
					return ''
				}
				function iconValueCandidate() {
					if (model.iconName) return model.iconName
					if (typeof model.decoration === "string") return model.decoration
					return model.decoration || ""
				}
				function isFileLikeIcon(value) {
					if (typeof value !== "string") return false
					return value.indexOf("/") === 0 || value.indexOf("file:/") === 0 || value.indexOf("qrc:/") === 0 || value.indexOf(":/") === 0
				}
				function iconNameCandidate() {
					var candidate = iconValueCandidate()
					if (typeof candidate === "string" && candidate && !isFileLikeIcon(candidate)) return candidate
					return ""
				}
				function iconSourceCandidate() {
					var candidate = iconValueCandidate()
					if (isFileLikeIcon(candidate)) return candidate
					if (candidate && typeof candidate !== "string") return candidate
					return ""
				}
				function endsWith(s, sub) {
					return s.indexOf(sub) === s.length - sub.length
				}
				property string xdgDisplayName: {
					var xdgFolder = isLocalizedFolder()
					if (xdgFolder === 'DOCUMENTS') return i18nd("xdg-user-dirs", "Documents")
					if (xdgFolder === 'DOWNLOAD') return i18nd("xdg-user-dirs", "Download")
					if (xdgFolder === 'MUSIC') return i18nd("xdg-user-dirs", "Music")
					if (xdgFolder === 'PICTURES') return i18nd("xdg-user-dirs", "Pictures")
					if (xdgFolder === 'VIDEOS') return i18nd("xdg-user-dirs", "Videos")
					return ''
				}
				property string symbolicIconCandidate: {
					if (model.url) {
						var s = model.url.toString()
						if (s.indexOf('xdg:') === 0) {
							var folder = s.substring(4)
							var iconMap = {
								'DOCUMENTS': 'folder-documents-symbolic',
								'DOWNLOAD': 'folder-download-symbolic',
								'MUSIC': 'folder-music-symbolic',
								'PICTURES': 'folder-pictures-symbolic',
								'VIDEOS': 'folder-videos-symbolic'
							}
							if (iconMap[folder]) return iconMap[folder]
						}
					}
					var baseIconName = iconNameCandidate()
					if (baseIconName) {
						return endsWith(baseIconName, "-symbolic") ? baseIconName : baseIconName + "-symbolic"
					}
					return ""
				}
				readonly property string resolvedIconName: symbolicIconProbe.valid ? symbolicIconCandidate : iconNameCandidate()
				readonly property var resolvedIconSource: resolvedIconName ? "" : iconSourceCandidate()
				Kirigami.Icon {
					id: symbolicIconProbe
					visible: false
					source: parent.symbolicIconCandidate
				}
			}
		}

		SidebarItem {
			icon.name: ""
			icon.source: leftPane.settingsIconSource
			text: i18n("Settings")
			tooltipText: i18n("Tiled Menu Reloaded Settings")
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			onClicked: plasmoid.internalAction("configure").trigger()
		}
	}

	Rectangle {
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		height: 1
		color: Kirigami.Theme.textColor
		opacity: 0.2
	}

	// ──────────────────────────────────────────────
	// 7. Power actions row
	// ──────────────────────────────────────────────
	RowLayout {
		Layout.alignment: Qt.AlignHCenter
		Layout.fillWidth: true
		Layout.bottomMargin: Kirigami.Units.smallSpacing
		spacing: 0

		Repeater {
			model: appsModel.powerActionsModel
			delegate: SidebarItem {
				// Filter out session actions (lock, logout, switch user)
				readonly property var _sessionIcons: ['system-lock-screen', 'system-log-out', 'system-save-session', 'system-switch-user']
				readonly property string _baseIcon: model.iconName || model.decoration || ""
				// Always prefer symbolic variant for power icons
				icon.name: (_baseIcon && _baseIcon.indexOf("-symbolic") < 0) ? _baseIcon + "-symbolic" : _baseIcon
				forceMonochromeIcon: true
				visible: !model.disabled && _sessionIcons.indexOf(model.iconName) < 0
				tooltipText: model.name || model.display || ""
				Layout.fillWidth: false
				Layout.preferredWidth: config.flatButtonSize
				Layout.preferredHeight: config.flatButtonSize
				onClicked: appsModel.powerActionsModel.triggerIndex(index)
			}
		}
	}
}
