import QtQuick
import QtQuick.Controls as QQC2
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
	property alias dockedSearchField: profileSearchField
	readonly property int compactProfileIconSize: Math.round(Math.min(config.profileIconSize, config.flatButtonSize) * 1.5)
	readonly property string displayName: kuser.loginName || i18n("User")
	readonly property string fullDisplayName: kuser.fullName || ""

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
	readonly property bool pillRowsEnabled: !!config.useTileTabs && (plasmoid.configuration.tileTabStyle || "tabs") === "pills"

	// ──────────────────────────────────────────────
	// 1. Compact user profile header with search
	// ──────────────────────────────────────────────
	ColumnLayout {
		id: profileHeader
		Layout.fillWidth: true
		Layout.topMargin: Kirigami.Units.largeSpacing
		Layout.leftMargin: Kirigami.Units.largeSpacing
		Layout.rightMargin: Kirigami.Units.largeSpacing
		Layout.bottomMargin: Kirigami.Units.smallSpacing
		spacing: Kirigami.Units.smallSpacing

		RowLayout {
			Layout.fillWidth: true
			spacing: Kirigami.Units.largeSpacing

			Item {
				id: profileButton
				Layout.alignment: Qt.AlignVCenter
				Layout.preferredWidth: leftPane.compactProfileIconSize
				Layout.preferredHeight: leftPane.compactProfileIconSize
				Layout.minimumWidth: leftPane.compactProfileIconSize
				Layout.minimumHeight: leftPane.compactProfileIconSize

				SunkenAvatar {
					anchors.fill: parent
				}

				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.RightButton
					cursorShape: Qt.ArrowCursor
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

			ColumnLayout {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
				spacing: Kirigami.Units.smallSpacing / 2

				PlasmaExtras.Heading {
					Layout.fillWidth: true
					level: 3
					text: leftPane.displayName
					elide: Text.ElideRight
					maximumLineCount: 1
					font.weight: Font.Bold
					color: Kirigami.Theme.textColor
				}

				PlasmaExtras.DescriptiveLabel {
					Layout.fillWidth: true
					visible: leftPane.fullDisplayName.length > 0
					text: leftPane.fullDisplayName
					elide: Text.ElideRight
					maximumLineCount: 1
				}
			}
		}

	}

	SearchField {
		id: profileSearchField
		readonly property int _matchedHeight: viewTabBar.surfaceHeight
		visible: !config.isEditingTile && (!config.hideSearchField || search.query.length > 0)
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		Layout.topMargin: Kirigami.Units.smallSpacing
		Layout.bottomMargin: Kirigami.Units.largeSpacing
		Layout.preferredHeight: _matchedHeight
		height: _matchedHeight
		implicitHeight: _matchedHeight
		listView: searchView.stackView && searchView.stackView.currentItem && searchView.stackView.currentItem.listView ? searchView.stackView.currentItem.listView : []
	}

	// ──────────────────────────────────────────────
	// 2. View-mode selector (tabs / pills / flat)
	// ──────────────────────────────────────────────
	SidebarViewTabBar {
		id: viewTabBar
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		Layout.preferredHeight: implicitHeight
		categoriesChecked: searchView.showingAppsCategorically
		alphabeticalChecked: searchView.showingAppsAlphabetically
		aiChatChecked: searchView.showingAiChat
		onCategoriesClicked: function(direction) {
			if (searchView.stackView) searchView.stackView.slideDirection = direction
			leftPane.switchView(function() { appsView.showAppsCategorically() })
		}
		onAlphabeticalClicked: function(direction) {
			if (searchView.stackView) searchView.stackView.slideDirection = direction
			leftPane.switchView(function() { appsView.showAppsAlphabetically() })
		}
		onAiChatClicked: function(direction) {
			if (searchView.stackView) searchView.stackView.slideDirection = direction
			leftPane.switchView(function() { searchView.showAiChat() })
		}
		onAutoResizeClicked: autoResizeDebounce.restart()
	}

	// ──────────────────────────────────────────────
	// 3. SearchView slot (app list)
	// ──────────────────────────────────────────────
	Item {
		id: searchViewSlotItem
		Layout.fillWidth: true
		Layout.fillHeight: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
	}

	// ──────────────────────────────────────────────
	// 6. Sidebar favourites row (pinned shortcuts)
	// ──────────────────────────────────────────────
	RowLayout {
		Layout.alignment: Qt.AlignHCenter
		Layout.fillWidth: true
		spacing: 0
		visible: !leftPane.pillRowsEnabled

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
			showBadge: !!(widget && widget.updateAvailable)
			tooltipText: widget && widget.updateAvailable
				? i18n("Tiled Menu Reloaded Settings — Update available")
				: i18n("Tiled Menu Reloaded Settings")
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
		visible: !leftPane.pillRowsEnabled
	}

	SidebarShortcutPillRow {
		visible: leftPane.pillRowsEnabled
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		Layout.preferredHeight: viewTabBar.surfaceHeight
		surfaceHeight: viewTabBar.surfaceHeight
		settingsIconSource: leftPane.settingsIconSource
	}

	// ──────────────────────────────────────────────
	// 7. Power actions row (icon + label below)
	// ──────────────────────────────────────────────
	RowLayout {
		Layout.alignment: Qt.AlignHCenter
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		Layout.bottomMargin: Kirigami.Units.smallSpacing
		Layout.topMargin: Kirigami.Units.smallSpacing
		spacing: Kirigami.Units.smallSpacing
		visible: !leftPane.pillRowsEnabled

		Repeater {
			model: appsModel.powerActionsModel
			delegate: FlatButton {
				id: powerBtn
				readonly property var _sessionIcons: ['system-lock-screen', 'system-log-out', 'system-save-session', 'system-switch-user']
				readonly property string _baseIcon: model.iconName || model.decoration || ""
				readonly property string _resolvedIcon: (_baseIcon && _baseIcon.indexOf("-symbolic") < 0) ? _baseIcon + "-symbolic" : _baseIcon
				readonly property string _label: model.name || model.display || ""
				visible: !model.disabled && _sessionIcons.indexOf(model.iconName) < 0
				Layout.preferredWidth: config.dockedSidebarPowerButtonWidth
				Layout.preferredHeight: config.flatButtonIconSize + powerLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
				buttonHeight: Layout.preferredHeight
				hoverEnabled: true
				onClicked: {
					if (popup && typeof popup.flushPendingTileLayoutSave === "function") {
						popup.flushPendingTileLayoutSave()
					}
					appsModel.powerActionsModel.triggerIndex(index)
				}

				Loader {
					id: powerHoverEffect
					anchors.fill: parent
					source: "HoverOutlineButtonEffect.qml"
					asynchronous: true
					property var mouseArea: powerBtn.__behavior
					active: !!mouseArea && mouseArea.containsMouse
					visible: active
					property var __mouseArea: mouseArea
				}

				contentItem: ColumnLayout {
					spacing: Kirigami.Units.smallSpacing / 2

					Kirigami.Icon {
						Layout.alignment: Qt.AlignHCenter
						Layout.preferredWidth: config.flatButtonIconSize
						Layout.preferredHeight: config.flatButtonIconSize
						source: powerBtn._resolvedIcon
						color: Kirigami.Theme.textColor
						isMask: true
					}

					QQC2.Label {
						id: powerLabel
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: powerBtn._label
						elide: Text.ElideRight
						color: Kirigami.Theme.textColor
						font: Kirigami.Theme.smallFont
					}
				}

				QQC2.ToolTip {
					visible: powerBtn.hovered && powerLabel.truncated
					text: powerBtn._label
					delay: 500
				}
			}
		}
	}

	PowerActionPillRow {
		visible: leftPane.pillRowsEnabled
		Layout.fillWidth: true
		Layout.leftMargin: Kirigami.Units.smallSpacing
		Layout.rightMargin: Kirigami.Units.smallSpacing
		Layout.bottomMargin: Kirigami.Units.smallSpacing
		Layout.topMargin: Kirigami.Units.largeSpacing
		Layout.preferredHeight: implicitHeight
	}
}
