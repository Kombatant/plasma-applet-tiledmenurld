import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "./lib/" as Lib

PillRowSurface {
	id: root

	property url settingsIconSource
	property int hoveredShortcutIndex: -1
	property bool hoverAnimationEnabled: true
	readonly property int _pillMotionDuration: 420

	property QtObject xdgUserDir: Lib.XdgUserDir {}

	function setHoveredShortcutIndex(index) {
		hoverAnimationEnabled = hoveredShortcutIndex >= 0
		hoveredShortcutIndex = index
		Qt.callLater(function() {
			hoverAnimationEnabled = true
		})
	}

	function resetHoverIndicator() {
		hoverAnimationEnabled = false
		hoveredShortcutIndex = -1
	}

	HoverHandler {
		id: shortcutRowHover
		target: root
		onHoveredChanged: {
			if (!hovered) {
				root.resetHoverIndicator()
			}
		}
	}

	PillHighlight {
		id: hoverIndicator
		visible: root.hoveredShortcutIndex >= 0 && !!_hoveredItem
		styleSource: root
		active: false
		readonly property var _hoveredItem: {
			void(shortcutPillsRepeater.count)
			if (root.hoveredShortcutIndex < 0) {
				return null
			}
			if (root.hoveredShortcutIndex < shortcutPillsRepeater.count) {
				return shortcutPillsRepeater.itemAt(root.hoveredShortcutIndex)
			}
			return root.hoveredShortcutIndex === shortcutPillsRepeater.count ? settingsPill : null
		}
		x: _hoveredItem ? shortcutPills.x + _hoveredItem.x : 0
		anchors.top: shortcutPills.top
		anchors.bottom: shortcutPills.bottom
		width: _hoveredItem ? _hoveredItem.width : 0
		flushLeft: root.hoveredShortcutIndex === 0
		flushRight: root.hoveredShortcutIndex === shortcutPillsRepeater.count
		Behavior on x {
			enabled: root.hoverAnimationEnabled
			NumberAnimation {
				duration: root._pillMotionDuration
				easing.type: Easing.OutCubic
			}
		}
		Behavior on width {
			enabled: root.hoverAnimationEnabled
			NumberAnimation {
				duration: root._pillMotionDuration
				easing.type: Easing.OutCubic
			}
		}
	}

	RowLayout {
		id: shortcutPills
		anchors.left: parent.left
		anchors.leftMargin: root.pillsInset
		anchors.right: parent.right
		anchors.rightMargin: root.pillsInset
		height: parent.height
		spacing: Kirigami.Units.smallSpacing

		Repeater {
			id: shortcutPillsRepeater
			model: appsModel.sidebarModel
			delegate: Item {
				Layout.fillWidth: true
				Layout.fillHeight: true
				Layout.minimumWidth: 0

				SidebarItem {
					id: shortcutButton
					anchors.fill: parent
					hoverEnabled: false
					down: false
					icon.name: resolvedIconName
					icon.source: resolvedIconSource
					forceMonochromeIcon: true
					desaturateIcon: true
					showHoverOutline: false
					text: xdgDisplayName || model.name || model.display
					tooltipText: text
					onClicked: {
						var xdgFolder = isLocalizedFolder()
						if (xdgFolder === 'DOCUMENTS') {
							Qt.openUrlExternally(root.xdgUserDir.documents)
						} else if (xdgFolder === 'DOWNLOAD') {
							Qt.openUrlExternally(root.xdgUserDir.download)
						} else if (xdgFolder === 'MUSIC') {
							Qt.openUrlExternally(root.xdgUserDir.music)
						} else if (xdgFolder === 'PICTURES') {
							Qt.openUrlExternally(root.xdgUserDir.pictures)
						} else if (xdgFolder === 'VIDEOS') {
							Qt.openUrlExternally(root.xdgUserDir.videos)
						} else {
							appsModel.sidebarModel.triggerIndex(index)
						}
					}
				}

				MouseArea {
					id: shortcutHoverArea
					anchors.fill: parent
					acceptedButtons: Qt.NoButton
					hoverEnabled: true
					onEntered: root.setHoveredShortcutIndex(index)
					onExited: {
						if (root.hoveredShortcutIndex === index && !shortcutRowHover.hovered) {
							root.resetHoverIndicator()
						}
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

		Item {
			id: settingsPill
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.minimumWidth: 0

			SidebarItem {
				id: settingsButton
				anchors.fill: parent
				hoverEnabled: false
				down: false
				icon.name: ""
				icon.source: root.settingsIconSource
				text: i18n("Settings")
				showBadge: !!(widget && widget.updateAvailable)
				showHoverOutline: false
				tooltipText: widget && widget.updateAvailable
					? i18n("Tiled Menu Reloaded Settings — Update available")
					: i18n("Tiled Menu Reloaded Settings")
				onClicked: plasmoid.internalAction("configure").trigger()
			}

			MouseArea {
				id: settingsHoverArea
				anchors.fill: parent
				acceptedButtons: Qt.NoButton
				hoverEnabled: true
				onEntered: root.setHoveredShortcutIndex(shortcutPillsRepeater.count)
				onExited: {
					if (root.hoveredShortcutIndex === shortcutPillsRepeater.count && !shortcutRowHover.hovered) {
						root.resetHoverIndicator()
					}
				}
			}
		}
	}
}
