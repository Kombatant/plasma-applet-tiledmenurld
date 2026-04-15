import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.kde.config as KConfig
import org.kde.kcmutils as KCM

SidebarContextMenu {
	id: profileMenu
	model: appsModel.sessionActionsModel
	property var footerSeparatorItem: null
	property var useCustomAvatarFooterItem: null
	property var revertToSystemAvatarFooterItem: null

	function _updateFooterState() {
		if (revertToSystemAvatarFooterItem) {
			revertToSystemAvatarFooterItem.enabled = !!plasmoid.configuration.customAvatarPath
		}
	}

	function _ensureFooterItems() {
		if (!footerSeparatorItem) {
			footerSeparatorItem = Qt.createQmlObject(
				'import org.kde.plasma.extras as PlasmaExtras; PlasmaExtras.MenuItem { separator: true }',
				profileMenu,
				'footerSeparatorItem'
			)
			profileMenu.addMenuItem(footerSeparatorItem)
		}

		if (!useCustomAvatarFooterItem) {
			useCustomAvatarFooterItem = Qt.createQmlObject(
				'import org.kde.plasma.extras as PlasmaExtras; PlasmaExtras.MenuItem { icon: "document-open" }',
				profileMenu,
				'useCustomAvatarFooterItem'
			)
			useCustomAvatarFooterItem.text = i18n("Use a custom avatar...")
			useCustomAvatarFooterItem.clicked.connect(function() {
				if (widget && typeof widget.openCustomAvatarDialog === "function") {
					widget.openCustomAvatarDialog()
				}
			})
			profileMenu.addMenuItem(useCustomAvatarFooterItem)
		}

		if (!revertToSystemAvatarFooterItem) {
			revertToSystemAvatarFooterItem = Qt.createQmlObject(
				'import org.kde.plasma.extras as PlasmaExtras; PlasmaExtras.MenuItem { icon: "edit-clear" }',
				profileMenu,
				'revertToSystemAvatarFooterItem'
			)
			revertToSystemAvatarFooterItem.text = i18n("Revert to system avatar")
			revertToSystemAvatarFooterItem.clicked.connect(function() {
				plasmoid.configuration.customAvatarPath = ""
				if (widget && typeof widget.refreshAvatar === "function") {
					widget.refreshAvatar()
				}
				profileMenu._updateFooterState()
			})
			profileMenu.addMenuItem(revertToSystemAvatarFooterItem)
		}

		_updateFooterState()
	}

	function toggleOpen() {
		_updateFooterState()
		Qt.callLater(function() {
			profileMenu._ensureFooterItems()
		})
		if (profileMenu.status == PlasmaExtras.Menu.Open) {
			profileMenu.close()
		} else if (profileMenu.status == PlasmaExtras.Menu.Closed) {
			profileMenu.openRelative()
		}
	}

	PlasmaExtras.MenuItem {
		icon: "system-users"
		text: i18n("User Manager")
		onClicked: KCM.KCMLauncher.open("kcm_users")
		visible: KConfig.KAuthorized.authorizeControlModule("kcm_users")
	}
}
