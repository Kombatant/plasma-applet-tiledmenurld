import QtQuick
import QtTest
import "../contents/ui" as Menu
import "../contents/ui/Utils.js" as Utils
import "../contents/ui/libconfig" as LibConfig

TestCase {
	id: testCase
	name: "RootMenu"
	function i18n(text) { return text }
	property var plasmoid: ({ expanded: true, configuration: { runAsRootInTerminal: false } })
	property var rootAppLauncher: ({ launch: function(url) { testCase.launchedUrl = url } })
	property string launchedUrl: ""

	Menu.RootAppLauncher { id: realLauncher }
	LibConfig.FormKCM {
		id: settingsPage
		cfg_runAsRootInTerminal: false
		cfg_runAsRootInTerminalDefault: false
		LibConfig.CheckBox {
			id: terminalCheckBox
			configKey: "runAsRootInTerminal"
		}
	}
	Menu.AppContextMenu {
		id: contextMenu
		onPopulateMenu: function(menu) { menu.addRunAsRootAction("applications:org.kde.konsole.desktop") }
	}

	function test_menuAction() {
		contextMenu.refreshMenu()
		compare(contextMenu.menu.content.length, 2)
		var action = contextMenu.menu.content[0]
		compare(action.text, "Run as Root")
		compare(contextMenu.menu.content[1].separator, true)
		action.clicked()
		compare(launchedUrl, "applications:org.kde.konsole.desktop")
		compare(plasmoid.expanded, false)
	}

	function test_launcherFiltering() {
		verify(Utils.isApplicationLauncher("applications:org.kde.konsole.desktop"))
		verify(Utils.isApplicationLauncher("file:///tmp/test.desktop"))
		verify(Utils.isApplicationLauncher("org.kde.konsole.desktop"))
		verify(!Utils.isApplicationLauncher("https://example.com/test.desktop"))
		verify(!Utils.isApplicationLauncher("file:///tmp/notes.txt"))
		verify(!Utils.isApplicationLauncher("systemsettings:kcm_users"))
		verify(!Utils.isApplicationLauncher(""))
	}

	function test_shellQuote() {
		compare(Utils.shellQuote("a'b"), "'a'\\''b'")
		compare(Utils.shellQuote("$(touch /tmp/nope)"), "'$(touch /tmp/nope)'")
	}

	function test_terminalSettingStagesUntilApply() {
		compare(realLauncher.showTerminal, false)
		compare(terminalCheckBox.checked, false)
		terminalCheckBox.clicked()
		compare(settingsPage.cfg_runAsRootInTerminal, true)
		compare(terminalCheckBox.checked, true)
		compare(plasmoid.configuration.runAsRootInTerminal, false)
		settingsPage.cfg_runAsRootInTerminal = settingsPage.cfg_runAsRootInTerminalDefault
		compare(terminalCheckBox.checked, false)
	}
}
