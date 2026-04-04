import QtQuick
import org.kde.kirigami as Kirigami
import "./lib/" as Lib

Repeater {
	id: repeater
	property int maxHeight: 1000000
	property int numAvailable: maxHeight / config.flatButtonSize
	property int minVisibleIndex: count - numAvailable // Hide items with an index smaller than this

	property QtObject xdgUserDir: Lib.XdgUserDir {}

	delegate: SidebarItem {
		icon.name: resolvedIconName
		icon.source: resolvedIconSource
		forceMonochromeIcon: true
		desaturateIcon: true
		text: xdgDisplayName || model.name || model.display
		tooltipText: text
		sidebarMenu: repeater.parent.parent // SidebarContextMenu { Column { Repeater{} } }
		onClicked: {
			repeater.parent.parent.open = false // SidebarContextMenu { Column { Repeater{} } }
			var xdgFolder = isLocalizedFolder()
			if (xdgFolder === 'DOCUMENTS') {
				Qt.openUrlExternally(xdgUserDir.documents)
			} else if (xdgFolder === 'DOWNLOAD') {
				Qt.openUrlExternally(xdgUserDir.download)
			} else if (xdgFolder === 'MUSIC') {
				Qt.openUrlExternally(xdgUserDir.music)
			} else if (xdgFolder === 'PICTURES') {
				Qt.openUrlExternally(xdgUserDir.pictures)
			} else if (xdgFolder === 'VIDEOS') {
				Qt.openUrlExternally(xdgUserDir.videos)
			} else {
				repeater.model.triggerIndex(index)
			}
		}
		visible: index >= minVisibleIndex

		// These files are localize, so open them via commandline
		// since Qt 5.7 doesn't expose the localized paths anywhere.
		function isLocalizedFolder() {
			var s = model.url.toString()
			if (startsWith(s, 'xdg:')) {
				s = s.substring('xdg:'.length, s.length)
				if (s == 'DOCUMENTS'
				 || s == 'DOWNLOAD'
				 || s == 'MUSIC'
				 || s == 'PICTURES'
				 || s == 'VIDEOS'
				) {
					return s
				}
			}
			return ''
		}

		function startsWith(s, sub) {
			return s.indexOf(sub) === 0
		}
		function endsWith(s, sub) {
			return s.indexOf(sub) === s.length - sub.length
		}
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

		property string xdgDisplayName: {
			var xdgFolder = isLocalizedFolder()
			if (xdgFolder) {
				// https://translationproject.org/domain/xdg-user-dirs.html
				// https://translationproject.org/PO-files/fr/xdg-user-dirs-0.17.fr.po
				if (xdgFolder === 'DOCUMENTS') {
					return i18nd("xdg-user-dirs", "Documents")
				} else if (xdgFolder === 'DOWNLOAD') {
					return i18nd("xdg-user-dirs", "Download")
				} else if (xdgFolder === 'MUSIC') {
					return i18nd("xdg-user-dirs", "Music")
				} else if (xdgFolder === 'PICTURES') {
					return i18nd("xdg-user-dirs", "Pictures")
				} else if (xdgFolder === 'VIDEOS') {
					return i18nd("xdg-user-dirs", "Videos")
				} else {
					return ''
				}
			} else {
				return ''
			}
		}
		property string symbolicIconCandidate: {
			if (model.url) {
				var s = model.url.toString()
				if (startsWith(s, 'file:///home/')) {
					s = s.substring('file:///home/'.length, s.length)

					var trimIndex = s.indexOf('/')
					if (trimIndex == -1) { // file:///home/username
						s = ''
					} else {
						s = s.substring(trimIndex, s.length)
					}

					if (s === '') { // Home Directory
						return 'user-home-symbolic'
					}
				} else if (startsWith(s, 'xdg:')) {
					s = s.substring('xdg:'.length, s.length)
					if (s === 'DOCUMENTS') {
						return 'folder-documents-symbolic'
					} else if (s === 'DOWNLOAD') {
						return 'folder-download-symbolic'
					} else if (s === 'MUSIC') {
						return 'folder-music-symbolic'
					} else if (s === 'PICTURES') {
						return 'folder-pictures-symbolic'
					} else if (s === 'VIDEOS') {
						return 'folder-videos-symbolic'
					}
				}
			}
			var baseIconName = iconNameCandidate()
			if (baseIconName) {
				if (endsWith(baseIconName, "-symbolic")) {
					return baseIconName
				}
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
