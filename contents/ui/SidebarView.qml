import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.config as KConfig
import org.kde.draganddrop as DragAndDrop
import org.kde.kcmutils as KCM // KCMLauncher
import "Utils.js" as Utils
import "./lib/" as Lib

Item {
	id: sidebarView
	property var popup
	z: 1
	property int _horizontalSearchWidth: config.appListWidth
	readonly property bool _aiChatEnabled: plasmoid.configuration.aiChatEnabled !== false
	
	function _relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		var r = channel(color.r)
		var g = channel(color.g)
		var b = channel(color.b)
		return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
	}

	readonly property int _fixedHorizontalButtons: _aiChatEnabled ? 8 : 7 // auto resize + 3/4 view buttons + user + settings + power
	readonly property int _fixedVerticalBottomButtons: 3 // user + settings + power
	readonly property color _sidebarIconBackdrop: config.surfaceBaseColor
	readonly property bool _sidebarIsLight: _relativeLuminance(_sidebarIconBackdrop) > 0.6
	readonly property url settingsIconSource: Qt.resolvedUrl(_sidebarIsLight ? "assets/tiled-settings-light.png" : "assets/tiled-settings-dark.png")
	readonly property int sidebarShortcutLimit: {
		if (!appsModel || !appsModel.sidebarModel || !config) {
			return 0
		}
		if (config.sidebarHorizontal) {
			var separatorWidth = (sidebarMenuSeparator ? sidebarMenuSeparator.width : 0) + (sidebarMenuSeparatorViews ? sidebarMenuSeparatorViews.width : 0)
			var searchWidth = (sidebarBottomSearchField && sidebarBottomSearchField.visible) ? sidebarBottomSearchField.width : 0
			var fixedWidth = (_fixedHorizontalButtons * config.flatButtonSize) + separatorWidth + searchWidth
			var availableWidth = Math.max(0, sidebarMenu.width - fixedWidth)
			return Math.max(0, Math.floor(availableWidth / config.flatButtonSize))
		}
		var topHeight = sidebarMenuTopVertical ? sidebarMenuTopVertical.height : 0
		var availableHeight = Math.max(0, sidebarMenu.height - topHeight - (_fixedVerticalBottomButtons * config.flatButtonSize))
		return Math.max(0, Math.floor(availableHeight / config.flatButtonSize))
	}
	readonly property bool canAddSidebarShortcut: {
		if (!appsModel || !appsModel.sidebarModel) {
			return false
		}
		if (sidebarShortcutLimit <= 0) {
			return false
		}
		return appsModel.sidebarModel.count < sidebarShortcutLimit
	}

	readonly property bool widgetExpanded: (typeof widget !== "undefined" && widget && typeof widget.expanded !== "undefined") ? widget.expanded : false
	onWidgetExpandedChanged: {
		if (widgetExpanded && config.sidebarHorizontal) {
			sidebarView._horizontalSearchWidth = config.appListWidth
		}
	}

	Connections {
		target: config
		function onSidebarHorizontalChanged() {
			if (config.sidebarHorizontal) {
				sidebarView._horizontalSearchWidth = config.appListWidth
			}
		}
	}

	// Use states for cleaner anchor management based on sidebar position
	states: [
		State {
			name: "left"
			when: config.sidebarOnLeft
			AnchorChanges {
				target: sidebarView
				anchors.left: parent.left
				anchors.top: parent.top
				anchors.bottom: parent.bottom
				anchors.right: undefined
			}
			PropertyChanges {
				target: sidebarView
				width: sidebarMenu.width
			}
		},
		State {
			name: "top"
			when: config.sidebarOnTop
			AnchorChanges {
				target: sidebarView
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.bottom: undefined
			}
			PropertyChanges {
				target: sidebarView
				height: sidebarMenu.height
			}
		},
		State {
			name: "bottom"
			when: config.sidebarOnBottom
			AnchorChanges {
				target: sidebarView
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: undefined
				anchors.bottom: parent.bottom
			}
			PropertyChanges {
				target: sidebarView
				height: sidebarMenu.height
			}
		}
	]

	Behavior on width { NumberAnimation { duration: 100 } }
	Behavior on height { NumberAnimation { duration: 100 } }

	DragAndDrop.DropArea {
		anchors.fill: sidebarMenu
		enabled: sidebarView.canAddSidebarShortcut

		onDrop: {
			if (!sidebarView.canAddSidebarShortcut) {
				return
			}
			if (event && event.mimeData && event.mimeData.url) {
				var url = event.mimeData.url.toString()
				url = Utils.parseDropUrl(url)
				appsModel.sidebarModel.addFavorite(url, 0)
			}
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

	function switchSidebarView(action) {
		if (popup && typeof popup.saveCurrentViewSize === "function") {
			popup.saveCurrentViewSize()
		}
		if (typeof action === "function") {
			action()
		}
	}

	SidebarMenu {
		id: sidebarMenu
		// Don't use anchors.fill - SidebarMenu manages its own size based on orientation
		anchors.left: parent.left
		anchors.top: parent.top

		// Vertical layout for left sidebar
		ColumnLayout {
			id: sidebarMenuTopVertical
			spacing: 0
			visible: !config.sidebarHorizontal

			SidebarViewButton {
				appletIconName: "view-list-tree"
				labelText: i18n("Categories")
				onClicked: sidebarView.switchSidebarView(function() { appsView.showAppsCategorically() })
				checked: searchView.showingAppsCategorically
			}

			SidebarViewButton {
				appletIconName: "view-list-text"
				labelText: i18n("Alphabetical")
				onClicked: sidebarView.switchSidebarView(function() { appsView.showAppsAlphabetically() })
				checked: searchView.showingAppsAlphabetically
			}

			SidebarViewButton {
				appletIconName: "view-grid-symbolic"
				labelText: i18n("Tiles Only")
				onClicked: sidebarView.switchSidebarView(function() { searchView.showTilesOnly() })
				checked: searchView.showingOnlyTiles
			}

			Rectangle {
				Layout.fillWidth: true
				height: 1
				color: Kirigami.Theme.textColor
				opacity: 0.25
				visible: sidebarView._aiChatEnabled
			}

			SidebarViewButton {
				appletIconName: "dialog-messages"
				labelText: i18n("AI Chat")
				onClicked: sidebarView.switchSidebarView(function() { searchView.showAiChat() })
				checked: searchView.showingAiChat
				visible: sidebarView._aiChatEnabled
			}

			SidebarItem {
				icon.name: "transform-scale"
				text: i18n("Auto Resize")
				tooltipText: i18n("Auto Resize")
				onClicked: autoResizeDebounce.restart()
			}

			Rectangle {
				Layout.fillWidth: true
				height: 1
				color: Kirigami.Theme.textColor
				opacity: 0.25
			}
		}

		ColumnLayout {
			id: sidebarMenuBottomVertical
			anchors.bottom: parent.bottom
			spacing: 0
			visible: !config.sidebarHorizontal

			SidebarItem {
				id: userMenuButton
				icon.name: ""
				icon.source: ""
				property string profileName: kuser.fullName
				text: ""
				tooltipText: kuser.fullName
				contentItem: Item {
					anchors.fill: parent

					SunkenAvatar {
						anchors.centerIn: parent
						width: config.flatButtonIconSize
						height: config.flatButtonIconSize
					}

					MouseArea {
						anchors.fill: parent
						acceptedButtons: Qt.RightButton
						cursorShape: Qt.ArrowCursor
						hoverEnabled: false
						onPressed: function(mouse) {
							mouse.accepted = true
						}
						onReleased: function(mouse) {
							mouse.accepted = true
						}
						onClicked: function(mouse) {
							mouse.accepted = true
							userMenu.toggleOpen()
						}
					}
				}
				ProfileContextMenu {
					id: userMenu
					visualParent: userMenuButton
				}
			}

			SidebarFavouritesView {
				model: appsModel.sidebarModel
				maxHeight: Math.max(0, sidebarMenu.height - sidebarMenuTopVertical.height - (sidebarView._fixedVerticalBottomButtons * config.flatButtonSize))
			}

			SidebarItem {
				id: settingsButton
				icon.name: ""
				icon.source: settingsIconSource
				text: i18n("Settings")
				showBadge: !!(widget && widget.updateAvailable)
				tooltipText: widget && widget.updateAvailable
					? i18n("Tiled Menu Reloaded Settings — Update available")
					: i18n("Tiled Menu Reloaded Settings")
				onClicked: {
					plasmoid.internalAction("configure").trigger()
				}
			}

			SidebarItem {
				id: powerMenuButton
				icon.name: 'system-shutdown-symbolic'
				text: i18n("Power")
				tooltipText: i18n("Power")
				onClicked: {
					powerMenu.toggleOpen()
				}
				SidebarContextMenu {
					id: powerMenu
					visualParent: powerMenuButton
					model: appsModel.powerActionsModel
				}
			}
		}

		// Horizontal layout for top/bottom sidebar
		RowLayout {
			id: sidebarMenuHorizontal
			anchors.fill: parent
			spacing: 0
			visible: config.sidebarHorizontal

			property QtObject xdgUserDirHoriz: Lib.XdgUserDir {}

			SidebarViewButton {
				appletIconName: "view-list-tree"
				labelText: i18n("Categories")
				onClicked: sidebarView.switchSidebarView(function() { appsView.showAppsCategorically() })
				checked: searchView.showingAppsCategorically
			}

			SidebarViewButton {
				appletIconName: "view-list-text"
				labelText: i18n("Alphabetical")
				onClicked: sidebarView.switchSidebarView(function() { appsView.showAppsAlphabetically() })
				checked: searchView.showingAppsAlphabetically
			}

			SidebarViewButton {
				appletIconName: "view-grid-symbolic"
				labelText: i18n("Tiles Only")
				onClicked: sidebarView.switchSidebarView(function() { searchView.showTilesOnly() })
				checked: searchView.showingOnlyTiles
			}

			Rectangle {
				id: sidebarMenuSeparatorViews
				Layout.preferredHeight: config.flatButtonSize * 0.6
				Layout.alignment: Qt.AlignVCenter
				width: 1
				color: Kirigami.Theme.textColor
				opacity: 0.25
				visible: sidebarView._aiChatEnabled
			}

			SidebarViewButton {
				appletIconName: "dialog-messages"
				labelText: i18n("AI Chat")
				onClicked: sidebarView.switchSidebarView(function() { searchView.showAiChat() })
				checked: searchView.showingAiChat
				visible: sidebarView._aiChatEnabled
			}

			SidebarItem {
				icon.name: "transform-scale"
				text: i18n("Auto Resize")
				tooltipText: i18n("Auto Resize")
				onClicked: autoResizeDebounce.restart()
			}

			Rectangle {
				id: sidebarMenuSeparator
				Layout.preferredHeight: config.flatButtonSize * 0.6
				Layout.alignment: Qt.AlignVCenter
				width: 1
				color: Kirigami.Theme.textColor
				opacity: 0.25
			}

			Item { Layout.fillWidth: true } // left spacer

			// Centered search field for horizontal (top/bottom) sidebar. Visible only
			// when the sidebar is at the bottom and the search field isn't hidden.
			SearchField {
				id: sidebarBottomSearchField
				// Respect the global 'Hide search field' setting and show when sidebar is
				// positioned at the top or bottom.
				visible: (config.sidebarOnBottom || config.sidebarOnTop) && !config.isEditingTile && searchView.showSearchField
				height: config.searchFieldHeight
				implicitHeight: config.searchFieldHeight
				Layout.preferredWidth: Math.min(parent.width * 0.7, sidebarView._horizontalSearchWidth)
				Layout.alignment: Qt.AlignVCenter
				listView: (searchView.stackView && searchView.stackView.currentItem && searchView.stackView.currentItem.listView) ? searchView.stackView.currentItem.listView : []

				MouseArea {
					anchors.fill: parent
					onClicked: {
						// Make sure the search UI is visible and forward focus to the field
						searchView.showSearchView()
						if (sidebarBottomSearchField.inputItem && typeof sidebarBottomSearchField.inputItem.forceActiveFocus === 'function') {
							sidebarBottomSearchField.inputItem.forceActiveFocus()
						}
					}
				}
			}

			Item { Layout.fillWidth: true } // right spacer

			SidebarItem {
				id: userMenuButtonHoriz
				icon.name: ""
				icon.source: ""
				text: ""
				tooltipText: kuser.fullName
				contentItem: Item {
					anchors.fill: parent

					SunkenAvatar {
						anchors.centerIn: parent
						width: config.flatButtonIconSize
						height: config.flatButtonIconSize
					}

					MouseArea {
						anchors.fill: parent
						acceptedButtons: Qt.RightButton
						cursorShape: Qt.ArrowCursor
						hoverEnabled: false
						onPressed: function(mouse) {
							mouse.accepted = true
						}
						onReleased: function(mouse) {
							mouse.accepted = true
						}
						onClicked: function(mouse) {
							mouse.accepted = true
							userMenuHoriz.toggleOpen()
						}
					}
				}
				ProfileContextMenu {
					id: userMenuHoriz
					visualParent: userMenuButtonHoriz
				}
			}

			// Horizontal sidebar shortcuts (favourites)
			Repeater {
				id: sidebarFavouritesHorizontal
				model: appsModel.sidebarModel
				property int maxVisible: sidebarView.sidebarShortcutLimit
				property int minVisibleIndex: count - maxVisible

				SidebarItem {
					icon.name: resolvedIconName
					icon.source: resolvedIconSource
					forceMonochromeIcon: true
					desaturateIcon: true
					text: xdgDisplayName || model.name || model.display
					tooltipText: text
					visible: index >= sidebarFavouritesHorizontal.minVisibleIndex
					onClicked: {
						var xdgFolder = isLocalizedFolder()
						if (xdgFolder === 'DOCUMENTS') {
							Qt.openUrlExternally(sidebarMenuHorizontal.xdgUserDirHoriz.documents)
						} else if (xdgFolder === 'DOWNLOAD') {
							Qt.openUrlExternally(sidebarMenuHorizontal.xdgUserDirHoriz.download)
						} else if (xdgFolder === 'MUSIC') {
							Qt.openUrlExternally(sidebarMenuHorizontal.xdgUserDirHoriz.music)
						} else if (xdgFolder === 'PICTURES') {
							Qt.openUrlExternally(sidebarMenuHorizontal.xdgUserDirHoriz.pictures)
						} else if (xdgFolder === 'VIDEOS') {
							Qt.openUrlExternally(sidebarMenuHorizontal.xdgUserDirHoriz.videos)
						} else {
							sidebarFavouritesHorizontal.model.triggerIndex(index)
						}
					}

					function startsWith(s, sub) { return s.indexOf(sub) === 0 }
					function endsWith(s, sub) { return s.indexOf(sub) === s.length - sub.length }
					function iconValueCandidate() {
						if (model.iconName) {
							return model.iconName
						}
						if (typeof model.decoration === "string") {
							return model.decoration
						}
						return model.decoration || ""
					}
					function isFileLikeIcon(value) {
						if (typeof value !== "string") {
							return false
						}
						return startsWith(value, "/") || startsWith(value, "file:/") || startsWith(value, "qrc:/") || startsWith(value, "qrc:///") || startsWith(value, ":/")
					}
					function iconNameCandidate() {
						var candidate = iconValueCandidate()
						if (typeof candidate === "string" && candidate && !isFileLikeIcon(candidate)) {
							return candidate
						}
						return ""
					}
					function iconSourceCandidate() {
						var candidate = iconValueCandidate()
						if (isFileLikeIcon(candidate)) {
							return candidate
						}
						if (candidate && typeof candidate !== "string") {
							return candidate
						}
						return ""
					}
					function isLocalizedFolder() {
						var s = model.url ? model.url.toString() : ''
						if (startsWith(s, 'xdg:')) {
							s = s.substring('xdg:'.length, s.length)
							if (s == 'DOCUMENTS' || s == 'DOWNLOAD' || s == 'MUSIC' || s == 'PICTURES' || s == 'VIDEOS') {
								return s
							}
						}
						return ''
					}
					property string xdgDisplayName: {
						var xdgFolder = isLocalizedFolder()
						if (xdgFolder === 'DOCUMENTS') return i18nd("xdg-user-dirs", "Documents")
						else if (xdgFolder === 'DOWNLOAD') return i18nd("xdg-user-dirs", "Download")
						else if (xdgFolder === 'MUSIC') return i18nd("xdg-user-dirs", "Music")
						else if (xdgFolder === 'PICTURES') return i18nd("xdg-user-dirs", "Pictures")
						else if (xdgFolder === 'VIDEOS') return i18nd("xdg-user-dirs", "Videos")
						return ''
					}
					property string symbolicIconCandidate: {
						if (model.url) {
							var s = model.url.toString()
							if (startsWith(s, 'xdg:')) {
								s = s.substring('xdg:'.length, s.length)
								if (s === 'DOCUMENTS') return 'folder-documents-symbolic'
								else if (s === 'DOWNLOAD') return 'folder-download-symbolic'
								else if (s === 'MUSIC') return 'folder-music-symbolic'
								else if (s === 'PICTURES') return 'folder-pictures-symbolic'
								else if (s === 'VIDEOS') return 'folder-videos-symbolic'
							} else if (startsWith(s, 'file:///home/')) {
								s = s.substring('file:///home/'.length, s.length)
								var trimIndex = s.indexOf('/')
								if (trimIndex === -1) {
									s = ''
								} else {
									s = s.substring(trimIndex, s.length)
								}
								if (s === '') return 'user-home-symbolic'
							}
						}
						var baseIconName = iconNameCandidate()
						if (baseIconName) {
							if (endsWith(baseIconName, "-symbolic")) return baseIconName
							return baseIconName + "-symbolic"
						}
						return ""
					}
					readonly property string resolvedIconName: symbolicIconProbe.valid ? symbolicIconCandidate : iconNameCandidate()
					readonly property var resolvedIconSource: resolvedIconName ? "" : iconSourceCandidate()
					Kirigami.Icon {
						id: symbolicIconProbe
						visible: false
						source: symbolicIconCandidate
					}
				}
			}

			SidebarItem {
				id: settingsButtonHoriz
				icon.name: ""
				icon.source: settingsIconSource
				text: i18n("Settings")
				tooltipText: widget && widget.updateAvailable
					? i18n("Tiled Menu Reloaded Settings — Update available")
					: i18n("Tiled Menu Reloaded Settings")
				showBadge: !!(widget && widget.updateAvailable)
				onClicked: {
					plasmoid.internalAction("configure").trigger()
				}
			}

			SidebarItem {
				id: powerMenuButtonHoriz
				icon.name: 'system-shutdown-symbolic'
				text: i18n("Power")
				tooltipText: i18n("Power")
				onClicked: {
					powerMenuHoriz.toggleOpen()
				}
				SidebarContextMenu {
					id: powerMenuHoriz
					visualParent: powerMenuButtonHoriz
					model: appsModel.powerActionsModel
				}
			}
		}

		onFocusChanged: {
			if (!focus) {
				open = false
			}
		}
	}


}
