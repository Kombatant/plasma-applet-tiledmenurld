import QtQuick
import QtQuick.Controls as QQC2
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/libconfig" as LibConfig

// Covers the in-page tabs used by the settings pages (LibConfig.FormKCM `tabs`
// + LibConfig.FormTab), and smoke-loads the tabbed pages with a stubbed
// Plasma context. ConfigServices.qml and ConfigExportLayout.qml are not loaded
// here: they talk to KWallet and the real configuration.
TestCase {
	id: testCase
	name: "ConfigTabs"
	when: windowShown
	width: 900
	height: 700
	visible: true

	function i18n(text) {
		var out = "" + text
		for (var i = 1; i < arguments.length; i++) {
			out = out.replace("%" + i, arguments[i])
		}
		return out
	}
	function i18nd(domain, text) { return text }
	function i18nc(context, text) { return text }

	// showPinButton is false in the saved configuration but true in the page's
	// staged cfg_ value, so a control that shows "checked" has resolved the page
	// root while it was being created.
	property var plasmoid: ({
		configuration: {
			showPinButton: false,
			tilesLocked: false,
			useDockedLayout: true,
			sidebarPosition: "left",
			useTileTabs: true,
			tileTabStyle: "tabs",
			tileScale: 0.4,
			tileMargin: 12,
			defaultTileColorMode: "theme",
			defaultTileColor: "",
			customAvatarPath: "",
			sidebarShortcuts: [],
			surfaceStyle: "theme",
			icon: "tiled_rld",
		},
		metaData: { version: "0" }
	})

	LibConfig.FormKCM {
		id: tabbedPage
		anchors.fill: parent
		cfg_showPinButton: true
		cfg_tilesLocked: false

		tabs: [
			LibConfig.FormTab {
				id: firstTab
				title: "First"
				LibConfig.CheckBox {
					id: firstTabCheckBox
					configKey: "showPinButton"
					text: "Pin"
				}
			},
			LibConfig.FormTab {
				id: secondTab
				title: "Second"
				LibConfig.CheckBox {
					id: secondTabCheckBox
					Kirigami.FormData.label: "A longer label than the first tab has:"
					configKey: "tilesLocked"
					text: "Lock"
				}
			}
		]
	}

	LibConfig.FormKCM {
		id: plainPage
		visible: false
		LibConfig.CheckBox {
			configKey: "tilesLocked"
			text: "Lock"
		}
	}

	Loader {
		id: pageLoader
		anchors.fill: parent
		visible: false
	}

	function findTabBar(item) {
		for (var i = 0; i < item.children.length; i++) {
			var child = item.children[i]
			if (child instanceof QQC2.TabBar) {
				return child
			}
			var nested = findTabBar(child)
			if (nested) {
				return nested
			}
		}
		return null
	}

	function test_tabs_are_listed_and_only_the_current_one_shows() {
		verify(tabbedPage.tabbed)
		var tabBar = findTabBar(tabbedPage)
		verify(tabBar)
		verify(tabBar.visible)
		compare(tabBar.count, 2)
		compare(tabBar.itemAt(0).text, "First")
		compare(tabBar.itemAt(1).text, "Second")

		tabbedPage.currentTab = 0
		verify(firstTab.visible)
		verify(!secondTab.visible)
		tabbedPage.currentTab = 1
		verify(!firstTab.visible)
		verify(secondTab.visible)
		tabbedPage.currentTab = 0
	}

	function test_page_without_tabs_keeps_the_plain_form() {
		verify(!plainPage.tabbed)
		verify(!findTabBar(plainPage).visible)
	}

	function test_controls_in_tabs_stage_through_the_page_root() {
		// Read from cfg_showPinButton (true), not the saved value (false).
		verify(firstTabCheckBox.checked)

		tabbedPage.currentTab = 1
		tryVerify(function() { return secondTab.visible })
		waitForRendering(tabbedPage)
		compare(tabbedPage.cfg_tilesLocked, false)
		mouseClick(secondTabCheckBox)
		compare(tabbedPage.cfg_tilesLocked, true)
		// Staged only: the saved configuration is untouched until Apply.
		compare(plasmoid.configuration.tilesLocked, false)
		tabbedPage.currentTab = 0
	}

	function test_real_pages_load_data() {
		return [
			{ tag: "Menu", source: "../contents/ui/config/ConfigMenu.qml", tabs: ["Layout", "App List", "Search"] },
			{ tag: "Tiles", source: "../contents/ui/config/ConfigTiles.qml", tabs: ["Tabs", "Size & Spacing", "Colours & Effects", "Labels & Groups"] },
			{ tag: "Sidebar", source: "../contents/ui/config/ConfigSidebar.qml", tabs: ["Shortcuts", "Options"] },
			{ tag: "Theme", source: "../contents/ui/config/ConfigAppearance.qml", tabs: [""], tabBarHidden: true },
		]
	}

	function test_real_pages_load(data) {
		tabbedPage.visible = false
		pageLoader.visible = true
		pageLoader.setSource(data.source, {
			title: data.tag,
			cfg_useDockedLayout: true,
			cfg_tilesLocked: false,
			cfg_customAvatarPath: "",
			cfg_sidebarShortcuts: [],
		})
		compare(pageLoader.status, Loader.Ready)
		var page = pageLoader.item
		verify(page.tabbed)
		var tabBar = findTabBar(page)
		compare(tabBar.count, data.tabs.length)
		// A page with a single tab is a plain form and shows no tab bar.
		compare(tabBar.visible, !data.tabBarHidden)
		for (var i = 0; i < data.tabs.length; i++) {
			compare(tabBar.itemAt(i).text, data.tabs[i])
			page.currentTab = i
			wait(0)
		}
		pageLoader.source = ""
		pageLoader.visible = false
		tabbedPage.visible = true
	}

	// Geometry of every visible item under `item`, keyed by its position in the tree.
	function geometrySnapshot(item, depth, out, path) {
		for (var i = 0; i < item.children.length; i++) {
			var child = item.children[i]
			if (!child.visible) {
				continue
			}
			var key = path + "/" + i
			out[key] = [Math.round(child.x), Math.round(child.y), Math.round(child.width), Math.round(child.height)].join(",")
			if (depth > 0) {
				geometrySnapshot(child, depth - 1, out, key)
			}
		}
		return out
	}

	function movedItems(before, after) {
		var moved = []
		for (var key in after) {
			if (before[key] !== after[key]) {
				moved.push(key + " " + before[key] + " -> " + after[key])
			}
		}
		return moved
	}

	function collectTabs(item, out) {
		for (var i = 0; i < item.children.length; i++) {
			var child = item.children[i]
			if (typeof child._settleLayout === "function") {
				out.push(child)
			} else {
				collectTabs(child, out)
			}
		}
		return out
	}

	function findByConfigKey(item, key) {
		for (var i = 0; i < item.children.length; i++) {
			var child = item.children[i]
			if (child.configKey === key) {
				return child
			}
			var nested = findByConfigKey(child, key)
			if (nested) {
				return nested
			}
		}
		return null
	}

	// Settings that only apply to one layout mode are greyed out in the other,
	// and follow the Layout mode control before Apply is pressed.
	function test_layout_specific_settings_follow_layout_mode() {
		tabbedPage.visible = false
		pageLoader.visible = true
		pageLoader.setSource("../contents/ui/config/ConfigMenu.qml", { cfg_useDockedLayout: true, cfg_sidebarPosition: "left", cfg_hideSearchField: false })
		compare(pageLoader.status, Loader.Ready)
		var page = pageLoader.item
		var dockedWidth = findByConfigKey(page, "dockedSidebarWidth")
		var appListWidth = findByConfigKey(page, "appListWidth")
		var searchOnTop = findByConfigKey(page, "searchOnTop")
		var searchHeight = findByConfigKey(page, "searchFieldHeight")
		verify(dockedWidth && appListWidth && searchOnTop && searchHeight)

		verify(dockedWidth.enabled)
		verify(!appListWidth.enabled)
		verify(!searchOnTop.enabled)
		verify(!searchHeight.enabled)

		page.cfg_useDockedLayout = false
		verify(!dockedWidth.enabled)
		verify(appListWidth.enabled)
		verify(searchOnTop.enabled)
		verify(searchHeight.enabled)

		pageLoader.source = ""
		pageLoader.visible = false
		tabbedPage.visible = true
	}

	// Controls start at the same horizontal position on every tab, because
	// each tab reserves the same share of its width for the label column.
	function test_label_column_lines_up_across_tabs() {
		tabbedPage.currentTab = 0
		wait(50)
		verify(firstTab.wideMode)
		verify(firstTab.labelColumnWidth > 0)
		var firstX = firstTabCheckBox.mapToItem(tabbedPage, 0, 0).x
		tabbedPage.currentTab = 1
		wait(50)
		var secondX = secondTabCheckBox.mapToItem(tabbedPage, 0, 0).x
		compare(secondX, firstX)
		// Past the reserved label column, not at the left edge.
		verify(firstX >= firstTab.labelColumnWidth)
		tabbedPage.currentTab = 0
	}

	function test_page_title_is_shown() {
		tabbedPage.title = "Menu"
		var found = false
		function scan(item) {
			for (var i = 0; i < item.children.length && !found; i++) {
				var child = item.children[i]
				if (child.visible && child.text === "Menu" && typeof child.level === "number") {
					found = true
				} else {
					scan(child)
				}
			}
		}
		scan(tabbedPage)
		verify(found)
		tabbedPage.title = ""
	}

	// A tab must be fully laid out in the same call that shows it. Anything
	// that still moves a few frames later is seen as a jump by the user.
	function test_tabs_do_not_move_after_showing_data() {
		return [
			{ tag: "Menu", source: "../contents/ui/config/ConfigMenu.qml", height: 700 },
			{ tag: "Tiles", source: "../contents/ui/config/ConfigTiles.qml", height: 700 },
			{ tag: "Sidebar", source: "../contents/ui/config/ConfigSidebar.qml", height: 700 },
			// Short page: some tabs need the scroll bar and some do not.
			{ tag: "Menu, scrolling", source: "../contents/ui/config/ConfigMenu.qml", height: 300 },
			{ tag: "Tiles, scrolling", source: "../contents/ui/config/ConfigTiles.qml", height: 300 },
		]
	}

	function test_tabs_do_not_move_after_showing(data) {
		tabbedPage.visible = false
		pageLoader.anchors.fill = undefined
		pageLoader.width = testCase.width
		pageLoader.height = data.height
		pageLoader.visible = true
		pageLoader.setSource(data.source, { cfg_useDockedLayout: true, cfg_sidebarShortcuts: [] })
		compare(pageLoader.status, Loader.Ready)
		var page = pageLoader.item
		var tabs = collectTabs(page, [])
		verify(tabs.length > 1)

		var order = [0]
		for (var i = 1; i < tabs.length; i++) {
			order.push(i)
		}
		order.push(0)
		for (var step = 0; step < order.length; step++) {
			var tab = tabs[order[step]]
			page.currentTab = order[step]
			var shown = geometrySnapshot(tab, 6, {}, "")
			var hostHeight = tab.parent.height
			wait(150)
			compare(movedItems(shown, geometrySnapshot(tab, 6, {}, "")), [], "items moved after showing tab " + order[step])
			compare(tab.parent.height, hostHeight)
		}

		pageLoader.source = ""
		pageLoader.visible = false
		pageLoader.anchors.fill = testCase
		tabbedPage.visible = true
	}
}
