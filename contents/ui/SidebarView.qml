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
	
	function _relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		var r = channel(color.r)
		var g = channel(color.g)
		var b = channel(color.b)
		return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
	}

	readonly property int _fixedHorizontalButtons: 8 // auto resize + 4 view buttons + user + settings + power
	readonly property color _sidebarIconBackdrop: plasmoid.configuration.sidebarFollowsTheme ? Kirigami.Theme.backgroundColor : config.sidebarBackgroundColor
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
		var availableHeight = Math.max(0, sidebarMenu.height - topHeight - (2 * config.flatButtonSize))
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

	Connections {
		target: plasmoid
		function onExpandedChanged() {
			if (plasmoid.expanded && config.sidebarHorizontal) {
				sidebarView._horizontalSearchWidth = config.appListWidth
			}
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
				onClicked:  appsView.showAppsCategorically()
				checked: searchView.showingAppsCategorically
			}

			SidebarViewButton {
				appletIconName: "view-list-text"
				labelText: i18n("Alphabetical")
				onClicked: appsView.showAppsAlphabetically()
				checked: searchView.showingAppsAlphabetically
			}

			SidebarViewButton {
				appletIconName: "view-grid-symbolic"
				labelText: i18n("Tiles Only")
				onClicked: searchView.showTilesOnly()
				checked: searchView.showingOnlyTiles
			}

			Rectangle {
				Layout.fillWidth: true
				height: 1
				color: Kirigami.Theme.textColor
				opacity: 0.25
			}

			SidebarViewButton {
				appletIconName: "dialog-messages"
				labelText: i18n("AI Chat")
				onClicked: searchView.showAiChat()
				checked: searchView.showingAiChat
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
			anchors.bottom: parent.bottom
			spacing: 0
			visible: !config.sidebarHorizontal

			SidebarItem {
				id: userMenuButton
				icon.name: kuser.hasFaceIcon ? kuser.faceIconUrl : 'user-identity'
				text: kuser.fullName
				tooltipText: kuser.fullName
				onClicked: {
					userMenu.toggleOpen()
				}
				SidebarContextMenu {
					id: userMenu
					visualParent: userMenuButton
					model: appsModel.sessionActionsModel

					PlasmaExtras.MenuItem {
						icon: 'system-users'
						text: i18n("User Manager")
						onClicked: KCM.KCMLauncher.open('kcm_users')
						visible: KConfig.KAuthorized.authorizeControlModule('kcm_users')
					}

					// ... appsModel.sessionActionsModel
				}
			}

			SidebarFavouritesView {
				model: appsModel.sidebarModel
				maxHeight: sidebarMenu.height - sidebarMenuTopVertical.height - 2 * config.flatButtonSize
			}

			SidebarItem {
				id: settingsButton
				icon.name: ""
				icon.source: settingsIconSource
				text: i18n("Settings")
				tooltipText: i18n("Tiled Menu Reloaded Settings")
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
				onClicked: appsView.showAppsCategorically()
				checked: searchView.showingAppsCategorically
			}

			SidebarViewButton {
				appletIconName: "view-list-text"
				labelText: i18n("Alphabetical")
				onClicked: appsView.showAppsAlphabetically()
				checked: searchView.showingAppsAlphabetically
			}

			SidebarViewButton {
				appletIconName: "view-grid-symbolic"
				labelText: i18n("Tiles Only")
				onClicked: searchView.showTilesOnly()
				checked: searchView.showingOnlyTiles
			}

			Rectangle {
				id: sidebarMenuSeparatorViews
				Layout.preferredHeight: config.flatButtonSize * 0.6
				Layout.alignment: Qt.AlignVCenter
				width: 1
				color: Kirigami.Theme.textColor
				opacity: 0.25
			}

			SidebarViewButton {
				appletIconName: "dialog-messages"
				labelText: i18n("AI Chat")
				onClicked: searchView.showAiChat()
				checked: searchView.showingAiChat
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
				icon.name: kuser.hasFaceIcon ? kuser.faceIconUrl : 'user-identity'
				text: kuser.fullName
				tooltipText: kuser.fullName
				onClicked: {
					userMenuHoriz.toggleOpen()
				}
				SidebarContextMenu {
					id: userMenuHoriz
					visualParent: userMenuButtonHoriz
					model: appsModel.sessionActionsModel

					PlasmaExtras.MenuItem {
						icon: 'system-users'
						text: i18n("User Manager")
						onClicked: KCM.KCMLauncher.open('kcm_users')
						visible: KConfig.KAuthorized.authorizeControlModule('kcm_users')
					}
				}
			}

			// Horizontal sidebar shortcuts (favourites)
			Repeater {
				id: sidebarFavouritesHorizontal
				model: appsModel.sidebarModel
				property int maxVisible: sidebarView.sidebarShortcutLimit
				property int minVisibleIndex: count - maxVisible

				SidebarItem {
					icon.name: symbolicIconName || model.iconName || model.decoration
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
					property string symbolicIconName: {
						if (!model.url) return ""
						var s = model.url.toString()
						if (endsWith(s, '/org.kde.dolphin.desktop')) return 'folder-open-symbolic'
						else if (endsWith(s, '/systemsettings.desktop')) return 'configure'
						else if (startsWith(s, 'xdg:')) {
							s = s.substring('xdg:'.length, s.length)
							if (s === 'DOCUMENTS') return 'folder-documents-symbolic'
							else if (s === 'DOWNLOAD') return 'folder-download-symbolic'
							else if (s === 'MUSIC') return 'folder-music-symbolic'
							else if (s === 'PICTURES') return 'folder-pictures-symbolic'
							else if (s === 'VIDEOS') return 'folder-videos-symbolic'
						}
						return ""
					}
				}
			}

			SidebarItem {
				id: settingsButtonHoriz
				icon.name: ""
				icon.source: settingsIconSource
				text: i18n("Settings")
				tooltipText: i18n("Tiled Menu Reloaded Settings")
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
			logger.debug('searchView.onFocusChanged', focus)
			if (!focus) {
				open = false
			}
		}
	}


}
