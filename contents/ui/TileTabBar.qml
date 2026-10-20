import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.iconthemes as KIconThemes

// Tab bar shown above the TileGrid when the "Use Tabs" option is enabled.
// Each entry in `tabs` is an object with at least a `name` string property.
Item {
	id: tabBar

	// Index of the currently selected tab (0-based).
	property int activeTab: 0

	// Array of tab descriptor objects: [{id: string, name: string, icon: string}, ...]
	property var tabs: []

	// Visual style: "tabs" (accent-lit tab), "underline", or "pills".
	property string style: "tabs"
	property bool alignSurfaceToTop: false
	readonly property bool _pillsMode: style === "pills"
	readonly property bool _underlineMode: style === "underline"
	// "tabs" is the stored value for the Accent Tab style; anything that is
	// neither pills nor underline falls back to it.
	readonly property bool _tabsMode: !_pillsMode && !_underlineMode

	// Emitted when the user selects a different tab.
	signal tabSelected(int index)
	signal tabAdded()
	signal tabDeleted(int index)
	signal tabRenamed(int index, string newName)
	signal tabMoved(int fromIndex, int toIndex)
	signal tabIconChanged(int index, string newIcon)

	// ── Internal drag state ─────────────────────────────────────────────────
	property int _dragSourceIndex: -1
	property int _dropSlot: -1

	// Proxy to the repeater of the currently active style branch.
	readonly property var _tabRepeater: _pillsMode
		? pillsBranch.tabRepeater
		: (_underlineMode ? underlineBranch.tabRepeater : tabsBranch.tabRepeater)

	function _slotAtX(x) {
		var rep = _tabRepeater
		if (!rep) return 0
		for (var i = 0; i < rep.count; i++) {
			var item = rep.itemAt(i)
			if (!item) continue
			var itemPos = item.mapToItem(tabBar, 0, 0)
			if (x < itemPos.x + item.width / 2) return i
		}
		return rep.count
	}

	readonly property int tabHeight: Kirigami.Units.gridUnit * 2.5
	readonly property int surfaceHeight: _pillsMode ? Math.round(tabHeight * 0.85) : tabHeight
	// Shared active-tab geometry for the branch currently on screen, used by
	// the split bottom line (Accent Tab) and by TileGrid alignment.
	readonly property int _motionDuration: _pillMotionDuration
	implicitHeight: tabHeight

	// ── Shared context menu ─────────────────────────────────────────────────
	PlasmaExtras.Menu {
		id: tabContextMenu
		property int tabIdx: -1

		PlasmaExtras.MenuItem {
			icon: "edit-rename"
			text: i18n("Rename Tab")
			onClicked: {
				var rep = tabBar._tabRepeater
				var item = rep ? rep.itemAt(tabContextMenu.tabIdx) : null
				if (item) item.startEditing()
			}
		}

		PlasmaExtras.MenuItem {
			icon: "preferences-desktop-icons"
			text: i18n("Change Icon…")
			onClicked: tabIconDialog.open()
		}

		PlasmaExtras.MenuItem {
			icon: "edit-clear"
			text: i18n("Clear Icon")
			enabled: {
				var idx = tabContextMenu.tabIdx
				return idx >= 0 && idx < tabBar.tabs.length
					&& (tabBar.tabs[idx].icon || "") !== ""
			}
			onClicked: tabBar.tabIconChanged(tabContextMenu.tabIdx, "")
		}

		PlasmaExtras.MenuItem { separator: true }

		PlasmaExtras.MenuItem {
			icon: "list-add"
			text: i18n("Add Tab")
			onClicked: tabBar.tabAdded()
		}

		PlasmaExtras.MenuItem {
			icon: "edit-delete-remove"
			text: i18n("Delete Tab")
			onClicked: tabBar.tabDeleted(tabContextMenu.tabIdx)
		}
	}

	KIconThemes.IconDialog {
		id: tabIconDialog
		onIconNameChanged: {
			if (iconName && tabContextMenu.tabIdx >= 0) {
				tabBar.tabIconChanged(tabContextMenu.tabIdx, iconName)
			}
		}
	}

	// ── Styling — Pills ─────────────────────────────────────────────────────
	readonly property real _pillRadius: config.tileCornerRadius
	readonly property real _listPadding: Math.round(Kirigami.Units.smallSpacing * 0.5)
	readonly property bool _surfaceBorderVisible: !plasmoid.configuration.sidebarHideBorder
	readonly property real _pillsInset: _surfaceBorderVisible ? _listPadding : 0
	readonly property real _activeIndicatorInset: _surfaceBorderVisible ? 2 : 0
	readonly property real _activeIndicatorRadius: Math.max(0, _pillRadius - _activeIndicatorInset)
	readonly property bool _frostedSurface: config.surfaceUsesFrostedGlass
	readonly property color _accentHighlightColor: Kirigami.Theme.highlightColor
	readonly property real _activeHighlightBorderOpacity: 0.95
	readonly property real _activeHighlightGlowOpacity: 0.78
	readonly property real _activeHighlightFillStrength: 1.0
	readonly property real _activeHighlightInnerRimOpacity: 0.24
	readonly property real _hoverHighlightBorderOpacity: 0.62
	readonly property real _hoverHighlightGlowOpacity: 0.44
	readonly property real _hoverHighlightFillStrength: 0.58
	readonly property real _hoverHighlightInnerRimOpacity: 0.14
	readonly property color _activeTextColor: Kirigami.Theme.textColor
	readonly property color _hoverTextColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.88)
	readonly property color _idleTextColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.72)
	readonly property int _pillMotionDuration: 420
	readonly property int _pillScrollDuration: 320

	// ── Styling — Accent Tab + Underline ────────────────────────────────────
	readonly property real _borderWidth: Math.max(1, Math.round(Screen.devicePixelRatio))
	// Theme-derived so the rule reads correctly in light and dark themes.
	readonly property color _borderColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.18)
	// Top corner rounding for the Accent Tab highlight; the bottom pair stays
	// square so the active tab merges into the grid below.
	readonly property real _tabCornerRadius: Kirigami.Units.smallSpacing * 2.5
	readonly property real _tabHoverBorderOpacity: 0.30
	readonly property real _tabHoverGlowOpacity: 0.22
	readonly property real _tabHoverFillStrength: 0.42
	readonly property int _tabHoverMotionDuration: 220
	readonly property int _tabFadeDuration: 140
	// Underline style
	readonly property real _underlineThickness: 2
	readonly property real _underlineHoverFill: 0.08

	// ═══════════════════════════════════════════════════════════════════════
	// ── Pills branch: Flickable + list background + animated indicator ─────
	// ═══════════════════════════════════════════════════════════════════════
	Item {
		id: pillsBranch
		visible: tabBar._pillsMode
		anchors.fill: parent

		property alias tabRepeater: pillsRepeater

		Item {
			id: pillsSurface
			anchors.left: parent.left
			anchors.right: parent.right
			y: tabBar.alignSurfaceToTop ? 0 : Math.round((parent.height - height) / 2)
			height: tabBar.surfaceHeight

			SidebarGlassCard {
				id: listBackground
				anchors.fill: parent
				contentMargins: 0
			}

			Flickable {
				id: tabFlickable
				anchors.left: parent.left
				anchors.right: pillsTrailing.left
				height: parent.height
				contentWidth: pillsRow.width + tabBar._pillsInset * 2
				contentHeight: height
				clip: true
				boundsBehavior: Flickable.StopAtBounds
				flickableDirection: Flickable.HorizontalFlick
				interactive: pillsTrailing._overflow

				function ensureIndexVisible(idx) {
					if (idx < 0 || idx >= pillsRepeater.count) return
					var item = pillsRepeater.itemAt(idx)
					if (!item) return
					var left = pillsRow.x + item.x
					var right = left + item.width
					if (left < contentX + tabBar._listPadding) {
						contentX = Math.max(0, left - tabBar._listPadding)
					} else if (right > contentX + width - tabBar._listPadding) {
						contentX = Math.min(Math.max(0, contentWidth - width), right - width + tabBar._listPadding)
					}
				}

				function snapContentX(target) {
					var maxX = Math.max(0, contentWidth - width)
					var desired = Math.max(0, Math.min(maxX, target))
					if (pillsRepeater.count === 0 || desired <= 0 || desired >= maxX) {
						return desired
					}
					var best = desired
					var bestDist = Number.POSITIVE_INFINITY
					for (var i = 0; i < pillsRepeater.count; i++) {
						var item = pillsRepeater.itemAt(i)
						if (!item) continue
						var leftBoundary = pillsRow.x + item.x - tabBar._listPadding
						var rightBoundary = pillsRow.x + item.x + item.width - width + tabBar._listPadding
						var candidates = [leftBoundary, rightBoundary]
						for (var c = 0; c < candidates.length; c++) {
							var cand = Math.max(0, Math.min(maxX, candidates[c]))
							var d = Math.abs(cand - desired)
							if (d < bestDist) {
								bestDist = d
								best = cand
							}
						}
					}
					return best
				}

				onWidthChanged: {
					var maxX = Math.max(0, contentWidth - width)
					if (contentX > maxX) contentX = maxX
					contentX = snapContentX(contentX)
				}

				onMovementEnded: contentX = snapContentX(contentX)

				Behavior on contentX {
					enabled: tabBar._pillsMode && !tabFlickable.dragging && !tabFlickable.flicking
					NumberAnimation {
						duration: tabBar._pillScrollDuration
						easing.type: Easing.OutCubic
					}
				}

				Connections {
					target: tabBar
					function onActiveTabChanged() {
						if (tabBar._pillsMode) tabFlickable.ensureIndexVisible(tabBar.activeTab)
					}
				}

				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.NoButton
					onWheel: function(wheel) {
						if (!tabFlickable.interactive) { wheel.accepted = false; return }
						var step = Kirigami.Units.gridUnit * 2
						var dy = wheel.angleDelta.y
						var dx = wheel.angleDelta.x
						var delta = (Math.abs(dx) > Math.abs(dy)) ? dx : dy
						var raw = tabFlickable.contentX - delta / 120 * step
						tabFlickable.contentX = tabFlickable.snapContentX(raw)
						wheel.accepted = true
					}
				}

				PillHighlight {
					id: activeIndicator
					z: 0
					visible: pillsRepeater.count > 0
					styleSource: tabBar
					readonly property var _activeItem: {
						void(pillsRepeater.count)
						return pillsRepeater.itemAt(tabBar.activeTab)
					}
					readonly property bool _atLeftEdge: x <= tabBar._pillsInset
					readonly property bool _atRightEdge: {
						if (!_activeItem) return false
						return x + width >= tabFlickable.contentWidth - tabBar._pillsInset
					}
					x: _activeItem ? pillsRow.x + _activeItem.x : 0
					anchors.top: pillsRow.top
					anchors.bottom: pillsRow.bottom
					width: _activeItem ? _activeItem.width : 0
					flushLeft: _atLeftEdge
					flushRight: _atRightEdge
					Behavior on x {
						NumberAnimation {
							duration: tabBar._pillMotionDuration
							easing.type: Easing.OutCubic
						}
					}
					Behavior on width {
						NumberAnimation {
							duration: tabBar._pillMotionDuration
							easing.type: Easing.OutCubic
						}
					}
				}

				Row {
					id: pillsRow
					x: tabBar._pillsInset
					height: tabFlickable.height
					spacing: Kirigami.Units.smallSpacing

					Repeater {
						id: pillsRepeater
						model: tabBar.tabs
						delegate: TabDelegate {
							pillsMode: true
							rowRef: pillsRow
						}
					}
				}
			}

			// ── Trailing controls for pills: scroll chevrons + add tab ──
			Row {
				id: pillsTrailing
				anchors.right: parent.right
				height: parent.height
				spacing: 0

				readonly property real _controlHeight: parent.height
				readonly property real _availableWidth: Math.max(0, pillsSurface.width - pillsAddBtn.width - Kirigami.Units.smallSpacing)
				readonly property real _tabsContentWidth: pillsRow.width + tabBar._pillsInset * 2
				readonly property bool _overflow: _tabsContentWidth > _availableWidth
				readonly property real _maxContentX: Math.max(0, tabFlickable.contentWidth - tabFlickable.width)

				Item {
					id: pillsScrollLeft
					visible: pillsTrailing._overflow
					width: visible ? pillsTrailing._controlHeight : 0
					height: pillsTrailing._controlHeight
					enabled: tabFlickable.contentX > 0

					QQC2.Label {
						anchors.centerIn: parent
						text: "‹"
						font.pixelSize: Kirigami.Units.gridUnit * 1.2
						color: Kirigami.Theme.textColor
						opacity: !pillsScrollLeft.enabled ? 0.25
							: pillsScrollLeftMA.containsMouse ? 0.9 : 0.55
					}

					MouseArea {
						id: pillsScrollLeftMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						enabled: pillsScrollLeft.enabled
						onClicked: {
							var step = tabFlickable.width * 0.8
							tabFlickable.contentX = tabFlickable.snapContentX(tabFlickable.contentX - step)
						}
					}
				}

				Item {
					id: pillsScrollRight
					visible: pillsTrailing._overflow
					width: visible ? pillsTrailing._controlHeight : 0
					height: pillsTrailing._controlHeight
					enabled: tabFlickable.contentX < pillsTrailing._maxContentX

					QQC2.Label {
						anchors.centerIn: parent
						text: "›"
						font.pixelSize: Kirigami.Units.gridUnit * 1.2
						color: Kirigami.Theme.textColor
						opacity: !pillsScrollRight.enabled ? 0.25
							: pillsScrollRightMA.containsMouse ? 0.9 : 0.55
					}

					MouseArea {
						id: pillsScrollRightMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						enabled: pillsScrollRight.enabled
						onClicked: {
							var step = tabFlickable.width * 0.8
							tabFlickable.contentX = tabFlickable.snapContentX(tabFlickable.contentX + step)
						}
					}
				}

				Item {
					id: pillsAddBtn
					width: pillsTrailing._controlHeight
					height: pillsTrailing._controlHeight

					Accessible.name: i18n("Add Tab")
					Accessible.role: Accessible.Button
					QQC2.ToolTip.visible: pillsAddMA.containsMouse
					QQC2.ToolTip.text: i18n("Add Tab")

					Kirigami.Icon {
						anchors.centerIn: parent
						source: "tab-new-symbolic"
						width: Kirigami.Units.iconSizes.smallMedium
						height: width
						color: Kirigami.Theme.textColor
						opacity: pillsAddMA.containsMouse ? 0.9 : 0.55
					}

					MouseArea {
						id: pillsAddMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: tabBar.tabAdded()
					}
				}
			}
		}
	}

	// ═══════════════════════════════════════════════════════════════════════
	// ── Tabs branch: classic curved tabs with bottom line, no flickable ───
	// ═══════════════════════════════════════════════════════════════════════
	Item {
		id: tabsBranch
		visible: tabBar._tabsMode
		anchors.fill: parent

		property alias tabRepeater: tabsRepeater

		readonly property bool _activeTabReady: {
			if (tabsRepeater.count <= 0) return false
			var item = tabsRepeater.itemAt(tabBar.activeTab)
			if (!item || item.width <= 0) return false
			// Hide split line when active tab scrolled out of view
			var left = item.x - tabsFlickable.contentX
			var right = left + item.width
			return right > 0 && left < tabsFlickable.width
		}
		// Follow the highlight's animated geometry rather than the delegate's
		// instant x/width, so the gap in the bottom line travels with the
		// highlight instead of teleporting ahead of it.
		readonly property real _activeTabLeft:
			tabsFlickable.x + tabsActiveIndicator.x - tabsFlickable.contentX
		readonly property real _activeTabRight:
			tabsFlickable.x + tabsActiveIndicator.x + tabsActiveIndicator.width - tabsFlickable.contentX

		Flickable {
			id: tabsFlickable
			anchors.left: parent.left
			anchors.right: tabsTrailing.left
			anchors.bottom: parent.bottom
			height: parent.height
			contentWidth: tabsRow.width
			contentHeight: height
			clip: true
			boundsBehavior: Flickable.StopAtBounds
			flickableDirection: Flickable.HorizontalFlick
			interactive: tabsTrailing._overflow

			function ensureIndexVisible(idx) {
				if (idx < 0 || idx >= tabsRepeater.count) return
				var item = tabsRepeater.itemAt(idx)
				if (!item) return
				var left = item.x
				var right = left + item.width
				if (left < contentX) {
					contentX = Math.max(0, left)
				} else if (right > contentX + width) {
					contentX = Math.min(Math.max(0, contentWidth - width), right - width)
				}
			}

			onWidthChanged: {
				var maxX = Math.max(0, contentWidth - width)
				if (contentX > maxX) contentX = maxX
			}

			Connections {
				target: tabBar
				function onActiveTabChanged() {
					if (!tabBar._pillsMode) tabsFlickable.ensureIndexVisible(tabBar.activeTab)
				}
			}

			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.NoButton
				onWheel: function(wheel) {
					if (!tabsFlickable.interactive) { wheel.accepted = false; return }
					var step = Kirigami.Units.gridUnit * 2
					var dy = wheel.angleDelta.y
					var dx = wheel.angleDelta.x
					var delta = (Math.abs(dx) > Math.abs(dy)) ? dx : dy
					var maxX = Math.max(0, tabsFlickable.contentWidth - tabsFlickable.width)
					var raw = tabsFlickable.contentX - delta / 120 * step
					tabsFlickable.contentX = Math.max(0, Math.min(maxX, raw))
					wheel.accepted = true
				}
			}

			// Hover highlight — slides between tabs, weaker than the active one.
			PillHighlight {
				id: tabsHoverIndicator
				z: 0
				styleSource: tabBar
				active: false
				visible: tabsRow.hoverIndex >= 0
					&& tabsRow.hoverIndex !== tabBar.activeTab
					&& tabBar._dragSourceIndex < 0
				readonly property var _hoverItem: {
					void(tabsRepeater.count)
					return tabsRow.hoverIndex >= 0 ? tabsRepeater.itemAt(tabsRow.hoverIndex) : null
				}
				x: _hoverItem ? _hoverItem.x : 0
				width: _hoverItem ? _hoverItem.width : 0
				anchors.top: tabsRow.top
				anchors.bottom: tabsRow.bottom
				radiusTopLeft: tabBar._tabCornerRadius
				radiusTopRight: tabBar._tabCornerRadius
				radiusBottomLeft: 0
				radiusBottomRight: 0
				borderOpacity: tabBar._tabHoverBorderOpacity
				glowOpacity: tabBar._tabHoverGlowOpacity
				fillStrength: tabBar._tabHoverFillStrength
				// Do not slide in from wherever the pointer last was: only
				// animate while moving between adjacent hovered tabs.
				Behavior on x {
					enabled: tabsHoverIndicator.visible
					NumberAnimation {
						duration: tabBar._tabHoverMotionDuration
						easing.type: Easing.OutCubic
					}
				}
				Behavior on width {
					enabled: tabsHoverIndicator.visible
					NumberAnimation {
						duration: tabBar._tabHoverMotionDuration
						easing.type: Easing.OutCubic
					}
				}
			}

			// Single active highlight that slides between tabs, mirroring the
			// motion the pills style already uses.
			PillHighlight {
				id: tabsActiveIndicator
				z: 1
				styleSource: tabBar
				visible: tabsRepeater.count > 0 && _settled
				readonly property var _activeItem: {
					void(tabsRepeater.count)
					return tabsRepeater.itemAt(tabBar.activeTab)
				}
				// Only animate deliberate selection changes. Delegates resolve
				// and lay out after creation, so animating those early width/x
				// changes makes the highlight crawl toward a moving target —
				// which reads as jitter, and on first load leaves it visibly
				// mis-sized. `_settled` snaps the first valid geometry into
				// place, then hands over to the Behaviors.
				property bool _settled: false
				x: _activeItem ? _activeItem.x : 0
				width: _activeItem ? _activeItem.width : 0
				onWidthChanged: _markSettled()
				onXChanged: _markSettled()
				function _markSettled() {
					if (!_settled && _activeItem && width > 0) {
						_settled = true
					}
				}
				anchors.top: tabsRow.top
				anchors.bottom: tabsRow.bottom
				radiusTopLeft: tabBar._tabCornerRadius
				radiusTopRight: tabBar._tabCornerRadius
				radiusBottomLeft: 0
				radiusBottomRight: 0
				Behavior on x {
					enabled: tabsActiveIndicator._settled
					NumberAnimation {
						duration: tabBar._pillMotionDuration
						easing.type: Easing.OutCubic
					}
				}
				Behavior on width {
					enabled: tabsActiveIndicator._settled
					NumberAnimation {
						duration: tabBar._pillMotionDuration
						easing.type: Easing.OutCubic
					}
				}
			}

			Row {
				id: tabsRow
				height: tabsFlickable.height
				spacing: 0
				z: 2

				// Index of the hovered tab, or -1. Drives the hover highlight.
				property int hoverIndex: -1

				Repeater {
					id: tabsRepeater
					model: tabBar.tabs
					delegate: TabDelegate {
						pillsMode: false
						rowRef: tabsRow
					}
				}
			}
		}

		// ── Trailing controls: scroll chevrons + add tab ──
		Row {
			id: tabsTrailing
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: tabBar.tabHeight
			spacing: 0

			readonly property real _availableWidth: tabBar.width - tabsAddBtn.width
			readonly property bool _overflow: tabsRow.width > _availableWidth
			readonly property real _maxContentX: Math.max(0, tabsFlickable.contentWidth - tabsFlickable.width)

			Item {
				id: tabsScrollLeft
				visible: tabsTrailing._overflow
				width: visible ? tabBar.tabHeight : 0
				height: tabBar.tabHeight
				enabled: tabsFlickable.contentX > 0

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "go-previous-symbolic"
					isMask: true
					width: Kirigami.Units.iconSizes.small
					height: width
					color: Kirigami.Theme.textColor
					opacity: !tabsScrollLeft.enabled ? 0.25
						: tabsScrollLeftMA.containsMouse ? 0.95 : 0.6
					Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				}

				MouseArea {
					id: tabsScrollLeftMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					enabled: tabsScrollLeft.enabled
					onClicked: {
						var step = tabsFlickable.width * 0.8
						var maxX = tabsTrailing._maxContentX
						tabsFlickable.contentX = Math.max(0, Math.min(maxX, tabsFlickable.contentX - step))
					}
				}
			}

			Item {
				id: tabsScrollRight
				visible: tabsTrailing._overflow
				width: visible ? tabBar.tabHeight : 0
				height: tabBar.tabHeight
				enabled: tabsFlickable.contentX < tabsTrailing._maxContentX

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "go-next-symbolic"
					isMask: true
					width: Kirigami.Units.iconSizes.small
					height: width
					color: Kirigami.Theme.textColor
					opacity: !tabsScrollRight.enabled ? 0.25
						: tabsScrollRightMA.containsMouse ? 0.95 : 0.6
					Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				}

				MouseArea {
					id: tabsScrollRightMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					enabled: tabsScrollRight.enabled
					onClicked: {
						var step = tabsFlickable.width * 0.8
						var maxX = tabsTrailing._maxContentX
						tabsFlickable.contentX = Math.max(0, Math.min(maxX, tabsFlickable.contentX + step))
					}
				}
			}

			Item {
				id: tabsAddBtn
				width: tabBar.tabHeight
				height: tabBar.tabHeight

				Accessible.name: i18n("Add Tab")
				Accessible.role: Accessible.Button
				QQC2.ToolTip.visible: tabsAddMA.containsMouse
				QQC2.ToolTip.text: i18n("Add Tab")

				Rectangle {
					anchors.centerIn: parent
					width: Kirigami.Units.gridUnit * 1.8
					height: width
					radius: height / 2
					color: Qt.rgba(
						Kirigami.Theme.textColor.r,
						Kirigami.Theme.textColor.g,
						Kirigami.Theme.textColor.b,
						tabsAddMA.containsMouse ? 0.10 : 0.0)
					Behavior on color { ColorAnimation { duration: tabBar._tabFadeDuration } }
				}

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "tab-new-symbolic"
					isMask: true
					width: Kirigami.Units.iconSizes.smallMedium
					height: width
					color: Kirigami.Theme.textColor
					opacity: tabsAddMA.containsMouse ? 0.95 : 0.55
					Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				}

				MouseArea {
					id: tabsAddMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: tabBar.tabAdded()
				}
			}
		}

		// ── Bottom line split around active tab ──
		Rectangle {
			id: bottomLineFull
			visible: !tabsBranch._activeTabReady
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: tabBar._borderWidth
			color: tabBar._borderColor
		}
		Rectangle {
			id: bottomLineLeft
			visible: tabsBranch._activeTabReady
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			width: Math.max(0, Math.min(tabsBranch._activeTabLeft, tabsFlickable.x + tabsFlickable.width))
			height: tabBar._borderWidth
			color: tabBar._borderColor
		}
		Rectangle {
			id: bottomLineRight
			visible: tabsBranch._activeTabReady
			x: Math.max(tabsFlickable.x, Math.min(tabsBranch._activeTabRight, tabsFlickable.x + tabsFlickable.width))
			anchors.bottom: parent.bottom
			width: parent.width - x
			height: tabBar._borderWidth
			color: tabBar._borderColor
		}
	}

	// ═══════════════════════════════════════════════════════════════════════
	// ── Underline branch: flat row with a sliding accent underline ─────────
	// ═══════════════════════════════════════════════════════════════════════
	Item {
		id: underlineBranch
		visible: tabBar._underlineMode
		anchors.fill: parent

		property alias tabRepeater: underlineRepeater

		Flickable {
			id: underlineFlickable
			anchors.left: parent.left
			anchors.right: underlineTrailing.left
			anchors.bottom: parent.bottom
			height: parent.height
			contentWidth: underlineRow.width + Kirigami.Units.smallSpacing * 2
			contentHeight: height
			clip: true
			boundsBehavior: Flickable.StopAtBounds
			flickableDirection: Flickable.HorizontalFlick
			interactive: underlineTrailing._overflow

			function ensureIndexVisible(idx) {
				if (idx < 0 || idx >= underlineRepeater.count) return
				var item = underlineRepeater.itemAt(idx)
				if (!item) return
				var left = underlineRow.x + item.x
				var right = left + item.width
				if (left < contentX) {
					contentX = Math.max(0, left)
				} else if (right > contentX + width) {
					contentX = Math.min(Math.max(0, contentWidth - width), right - width)
				}
			}

			onWidthChanged: {
				var maxX = Math.max(0, contentWidth - width)
				if (contentX > maxX) contentX = maxX
			}

			Connections {
				target: tabBar
				function onActiveTabChanged() {
					if (tabBar._underlineMode) underlineFlickable.ensureIndexVisible(tabBar.activeTab)
				}
			}

			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.NoButton
				onWheel: function(wheel) {
					if (!underlineFlickable.interactive) { wheel.accepted = false; return }
					var step = Kirigami.Units.gridUnit * 2
					var dy = wheel.angleDelta.y
					var dx = wheel.angleDelta.x
					var delta = (Math.abs(dx) > Math.abs(dy)) ? dx : dy
					var maxX = Math.max(0, underlineFlickable.contentWidth - underlineFlickable.width)
					var raw = underlineFlickable.contentX - delta / 120 * step
					underlineFlickable.contentX = Math.max(0, Math.min(maxX, raw))
					wheel.accepted = true
				}
			}

			Row {
				id: underlineRow
				x: Kirigami.Units.smallSpacing
				height: underlineFlickable.height
				spacing: Kirigami.Units.largeSpacing

				Repeater {
					id: underlineRepeater
					model: tabBar.tabs
					delegate: TabDelegate {
						pillsMode: false
						underlineMode: true
						rowRef: underlineRow
					}
				}
			}

			// Sliding accent underline beneath the active tab.
			Item {
				id: activeUnderline
				readonly property var _activeItem: {
					void(underlineRepeater.count)
					return underlineRepeater.itemAt(tabBar.activeTab)
				}
				visible: !!_activeItem && tabBar._dragSourceIndex < 0 && _settled
				// See tabsActiveIndicator: snap the first valid geometry, then animate.
				property bool _settled: false
				x: (_activeItem ? underlineRow.x + _activeItem.x : 0) + Kirigami.Units.smallSpacing
				width: Math.max(0, (_activeItem ? _activeItem.width : 0) - Kirigami.Units.smallSpacing * 2)
				onWidthChanged: _markSettled()
				onXChanged: _markSettled()
				function _markSettled() {
					if (!_settled && _activeItem && width > 0) {
						_settled = true
					}
				}
				anchors.bottom: parent.bottom
				anchors.bottomMargin: tabBar._borderWidth
				height: tabBar._underlineThickness

				Behavior on x {
					enabled: activeUnderline._settled
					NumberAnimation {
						duration: tabBar._pillMotionDuration
						easing.type: Easing.OutCubic
					}
				}
				Behavior on width {
					enabled: activeUnderline._settled
					NumberAnimation {
						duration: tabBar._pillMotionDuration
						easing.type: Easing.OutCubic
					}
				}

				Rectangle {
					anchors.fill: parent
					radius: height / 2
					color: Kirigami.Theme.highlightColor
				}

				// Soft bloom rising from the bar.
				Rectangle {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
					width: parent.width
					height: parent.height * 3
					radius: height / 2
					opacity: 0.35
					gradient: Gradient {
						GradientStop { position: 0.0; color: "transparent" }
						GradientStop {
							position: 1.0
							color: Qt.rgba(
								Kirigami.Theme.highlightColor.r,
								Kirigami.Theme.highlightColor.g,
								Kirigami.Theme.highlightColor.b,
								0.5)
						}
					}
				}
			}
		}

		// ── Trailing controls: scroll chevrons + add tab ──
		Row {
			id: underlineTrailing
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: tabBar.tabHeight
			spacing: 0

			readonly property real _availableWidth: tabBar.width - underlineAddBtn.width
			readonly property bool _overflow: underlineRow.width > _availableWidth
			readonly property real _maxContentX: Math.max(0, underlineFlickable.contentWidth - underlineFlickable.width)

			Item {
				id: underlineScrollLeft
				visible: underlineTrailing._overflow
				width: visible ? tabBar.tabHeight : 0
				height: tabBar.tabHeight
				enabled: underlineFlickable.contentX > 0

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "go-previous-symbolic"
					isMask: true
					width: Kirigami.Units.iconSizes.small
					height: width
					color: Kirigami.Theme.textColor
					opacity: !underlineScrollLeft.enabled ? 0.25
						: underlineScrollLeftMA.containsMouse ? 0.95 : 0.6
					Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				}

				MouseArea {
					id: underlineScrollLeftMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					enabled: underlineScrollLeft.enabled
					onClicked: {
						var step = underlineFlickable.width * 0.8
						var maxX = underlineTrailing._maxContentX
						underlineFlickable.contentX = Math.max(0, Math.min(maxX, underlineFlickable.contentX - step))
					}
				}
			}

			Item {
				id: underlineScrollRight
				visible: underlineTrailing._overflow
				width: visible ? tabBar.tabHeight : 0
				height: tabBar.tabHeight
				enabled: underlineFlickable.contentX < underlineTrailing._maxContentX

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "go-next-symbolic"
					isMask: true
					width: Kirigami.Units.iconSizes.small
					height: width
					color: Kirigami.Theme.textColor
					opacity: !underlineScrollRight.enabled ? 0.25
						: underlineScrollRightMA.containsMouse ? 0.95 : 0.6
					Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				}

				MouseArea {
					id: underlineScrollRightMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					enabled: underlineScrollRight.enabled
					onClicked: {
						var step = underlineFlickable.width * 0.8
						var maxX = underlineTrailing._maxContentX
						underlineFlickable.contentX = Math.max(0, Math.min(maxX, underlineFlickable.contentX + step))
					}
				}
			}

			Item {
				id: underlineAddBtn
				width: tabBar.tabHeight
				height: tabBar.tabHeight

				Accessible.name: i18n("Add Tab")
				Accessible.role: Accessible.Button
				QQC2.ToolTip.visible: underlineAddMA.containsMouse
				QQC2.ToolTip.text: i18n("Add Tab")

				Rectangle {
					anchors.centerIn: parent
					width: Kirigami.Units.gridUnit * 1.8
					height: width
					radius: height / 2
					color: Qt.rgba(
						Kirigami.Theme.textColor.r,
						Kirigami.Theme.textColor.g,
						Kirigami.Theme.textColor.b,
						underlineAddMA.containsMouse ? 0.10 : 0.0)
					Behavior on color { ColorAnimation { duration: tabBar._tabFadeDuration } }
				}

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "tab-new-symbolic"
					isMask: true
					width: Kirigami.Units.iconSizes.smallMedium
					height: width
					color: Kirigami.Theme.textColor
					opacity: underlineAddMA.containsMouse ? 0.95 : 0.55
					Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				}

				MouseArea {
					id: underlineAddMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: tabBar.tabAdded()
				}
			}
		}

		// Full-width rule — nothing merges into the grid in this style.
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: tabBar._borderWidth
			color: tabBar._borderColor
		}
	}

	// ═══════════════════════════════════════════════════════════════════════
	// ── Shared tab delegate component ──────────────────────────────────────
	// ═══════════════════════════════════════════════════════════════════════
	component TabDelegate: Item {
		id: tabDelegate

		required property int index
		required property var modelData
		property bool pillsMode: false
		// Underline style: no tab body, content-hugging width, sliding underline.
		property bool underlineMode: false
		property Item rowRef: null

		readonly property bool isActive: tabBar.activeTab === index
		property bool isEditing: false

		readonly property bool hasIcon: tabIcon !== ""
		readonly property bool isHovered: hoverArea.containsMouse
		readonly property string tabIcon: (modelData && modelData.icon) || ""
		// Only symbolic (single-colour) icons may be recoloured to follow the
		// tab foreground. Masking a full-colour icon throws away its colours
		// and repaints its alpha coverage flat, turning it into a solid block.
		readonly property bool _tabIconIsSymbolic: tabIcon.endsWith("-symbolic")
		readonly property font _labelFont: Qt.font({
			family: Kirigami.Theme.defaultFont.family,
			pointSize: Kirigami.Theme.defaultFont.pointSize,
			weight: tabDelegate.isActive ? Font.DemiBold : Font.Normal,
			italic: Kirigami.Theme.defaultFont.italic
		})
		// Widths are measured at the heaviest weight the label can take, so
		// selecting a tab does not reflow the row while the highlight slides
		// over it. Measuring with _labelFont instead makes every tab resize the
		// moment its weight flips, which reads as jitter.
		readonly property font _metricsFont: Qt.font({
			family: Kirigami.Theme.defaultFont.family,
			pointSize: Kirigami.Theme.defaultFont.pointSize,
			weight: Font.DemiBold,
			italic: Kirigami.Theme.defaultFont.italic
		})

		readonly property real _iconAllowance: hasIcon
			? tabIconItem.width + Kirigami.Units.smallSpacing
			: 0

		width: {
			if (pillsMode) {
				return Math.max(Kirigami.Units.gridUnit * 5,
					tabLabelMetrics.advanceWidth + _iconAllowance + Kirigami.Units.gridUnit * 2)
			}
			if (underlineMode) {
				// Hugs its content — no slab minimum.
				return tabLabelMetrics.advanceWidth + _iconAllowance + Kirigami.Units.gridUnit * 1.2
			}
			// Accent Tab: tighter than the old gridUnit*6 / *3 slab, and capped
			// so one long name cannot eat the whole bar.
			return Math.min(Kirigami.Units.gridUnit * 11,
				Math.max(Kirigami.Units.gridUnit * 5,
					tabLabelMetrics.advanceWidth + _iconAllowance + Kirigami.Units.gridUnit * 2.2))
		}
		height: rowRef ? rowRef.height : 0

		TextMetrics {
			id: tabLabelMetrics
			font: tabDelegate._metricsFont
			text: (tabDelegate.modelData && tabDelegate.modelData.name) || ""
		}

		function startEditing() {
			tabDelegate.isEditing = true
			tabInput.text = (tabDelegate.modelData && tabDelegate.modelData.name) || ""
			tabInput.forceActiveFocus()
			tabInput.selectAll()
		}

		function finishEditing() {
			var trimmed = tabInput.text.trim()
			var original = (tabDelegate.modelData && tabDelegate.modelData.name) || ""
			if (trimmed.length > 0 && trimmed !== original) {
				tabBar.tabRenamed(tabDelegate.index, trimmed)
			}
			tabDelegate.isEditing = false
		}

		// The Accent Tab body is drawn once by the sliding PillHighlight in the
		// tabs branch, so the delegate itself paints no shape.

		// ── Hover chrome (underline style only) ──
		Rectangle {
			visible: tabDelegate.underlineMode
			anchors.fill: parent
			anchors.topMargin: Math.round(Kirigami.Units.smallSpacing * 0.5)
			anchors.bottomMargin: Math.round(Kirigami.Units.smallSpacing * 1.5)
			radius: config.tileCornerRadius
			color: Qt.rgba(
				Kirigami.Theme.textColor.r,
				Kirigami.Theme.textColor.g,
				Kirigami.Theme.textColor.b,
				tabDelegate.isHovered ? tabBar._underlineHoverFill : 0.0)
			Behavior on color { ColorAnimation { duration: tabBar._tabFadeDuration } }
		}

		// ── Icon + Label ─────────────────────────────────────────
		readonly property color _fgColor: tabDelegate.pillsMode
			? (tabDelegate.isActive
				? tabBar._activeTextColor
				: (tabDelegate.isHovered ? tabBar._hoverTextColor : tabBar._idleTextColor))
			: Kirigami.Theme.textColor

		Row {
			id: tabLabelRow
			anchors.centerIn: parent
			// Underline sits below the label, so nudge content up to keep the
			// text optically centred in the tab.
			anchors.verticalCenterOffset: tabDelegate.underlineMode
				? -Math.round(Kirigami.Units.smallSpacing * 0.5)
				: 0
			spacing: Kirigami.Units.smallSpacing
			visible: !tabDelegate.isEditing
			width: Math.min(
				tabDelegate.width - Kirigami.Units.gridUnit,
				tabDelegate._iconAllowance + tabLabelText.implicitWidth)
			opacity: (tabBar._dragSourceIndex === tabDelegate.index) ? 0.3 : 1.0
			Behavior on opacity { NumberAnimation { duration: 100 } }

			Kirigami.Icon {
				id: tabIconItem
				visible: tabDelegate.hasIcon
				source: tabDelegate.tabIcon
				isMask: tabDelegate._tabIconIsSymbolic
				width: visible ? tabDelegate._labelFont.pixelSize : 0
				height: width
				anchors.verticalCenter: parent.verticalCenter
				color: tabDelegate.underlineMode && tabDelegate.isActive
					? Kirigami.Theme.highlightColor
					: tabDelegate._fgColor
				opacity: tabDelegate.pillsMode
					? 1.0
					: (tabDelegate.isActive ? 1.0 : (tabDelegate.isHovered ? 0.9 : 0.62))
				Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
				Behavior on color { ColorAnimation { duration: tabBar._tabFadeDuration } }
			}

			// One label. The old stack of four (two outlines plus a shadow under
			// the real text) cancelled into a muddy halo and cost 4x the nodes;
			// the highlight behind the tab supplies the contrast instead.
			QQC2.Label {
				id: tabLabelText
				anchors.verticalCenter: parent.verticalCenter
				width: Math.min(implicitWidth,
					Math.max(0, parent.width - tabDelegate._iconAllowance))
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				font: tabDelegate._labelFont
				text: (tabDelegate.modelData && tabDelegate.modelData.name) || ""
				color: tabDelegate._fgColor
				renderType: Text.QtRendering
				elide: Text.ElideRight
				opacity: tabDelegate.pillsMode
					? 1.0
					: (tabDelegate.isActive ? 1.0 : (tabDelegate.isHovered ? 0.9 : 0.62))
				Behavior on color { ColorAnimation { duration: 120 } }
				Behavior on opacity { NumberAnimation { duration: tabBar._tabFadeDuration } }
			}
		}

		// ── Edit input ───────────────────────────────────────────
		// Background so the field reads as editable against the tab behind it.
		Rectangle {
			visible: tabDelegate.isEditing
			anchors.fill: parent
			anchors.margins: Math.round(Kirigami.Units.smallSpacing * 0.5)
			radius: config.tileCornerRadius
			color: Kirigami.Theme.backgroundColor
			border.width: tabBar._borderWidth
			border.color: Kirigami.Theme.highlightColor
		}

		TextInput {
			id: tabInput
			anchors.fill: parent
			anchors.leftMargin: Kirigami.Units.largeSpacing
			anchors.rightMargin: Kirigami.Units.largeSpacing
			horizontalAlignment: TextInput.AlignHCenter
			verticalAlignment: TextInput.AlignVCenter
			font: tabDelegate._labelFont
			color: Kirigami.Theme.textColor
			selectionColor: Kirigami.Theme.highlightColor
			selectedTextColor: Kirigami.Theme.highlightedTextColor
			visible: tabDelegate.isEditing
			clip: true

			Keys.onReturnPressed: tabDelegate.finishEditing()
			Keys.onEscapePressed: { tabDelegate.isEditing = false }
			onActiveFocusChanged: {
				if (!activeFocus && tabDelegate.isEditing) {
					tabDelegate.finishEditing()
				}
			}
		}

		// ── Mouse interaction ────────────────────────────────────
		MouseArea {
			id: hoverArea
			anchors.fill: parent
			hoverEnabled: true
			acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
			cursorShape: tabBar._dragSourceIndex >= 0
				? Qt.ClosedHandCursor : Qt.PointingHandCursor

			property point _pressPos
			property bool _didDrag: false

			// Feed the Accent Tab sliding hover highlight.
			onEntered: {
				if (tabDelegate.rowRef && tabDelegate.rowRef.hoverIndex !== undefined) {
					tabDelegate.rowRef.hoverIndex = tabDelegate.index
				}
			}
			onExited: {
				if (tabDelegate.rowRef && tabDelegate.rowRef.hoverIndex === tabDelegate.index) {
					tabDelegate.rowRef.hoverIndex = -1
				}
			}

			onPressed: function(mouse) {
				_didDrag = false
				if (mouse.button === Qt.LeftButton
						&& !tabDelegate.isEditing) {
					_pressPos = Qt.point(mouse.x, mouse.y)
				}
			}

			onPositionChanged: function(mouse) {
				if (pressed && mouse.buttons & Qt.LeftButton
						&& !tabDelegate.isEditing
						&& tabBar._dragSourceIndex < 0) {
					if (Math.abs(mouse.x - _pressPos.x) > 8) {
						tabBar._dragSourceIndex = tabDelegate.index
						_didDrag = true
					}
				}
				if (tabBar._dragSourceIndex === tabDelegate.index) {
					var globalPos = mapToItem(tabBar, mouse.x, 0)
					tabBar._dropSlot = tabBar._slotAtX(globalPos.x)
				}
			}

			onReleased: function(mouse) {
				if (tabBar._dragSourceIndex === tabDelegate.index) {
					var from = tabBar._dragSourceIndex
					var slot = tabBar._dropSlot
					tabBar._dragSourceIndex = -1
					tabBar._dropSlot = -1
					var to = (slot > from) ? slot - 1 : slot
					if (to >= 0 && to !== from) {
						tabBar.tabMoved(from, to)
					}
				}
			}

			onClicked: function(mouse) {
				if (_didDrag) return
				if (mouse.button === Qt.MiddleButton) {
					tabBar.tabDeleted(tabDelegate.index)
				} else if (mouse.button === Qt.RightButton) {
					tabContextMenu.tabIdx = tabDelegate.index
					var pos = mapToItem(tabBar, mouse.x, mouse.y)
					tabContextMenu.open(pos.x, pos.y)
				} else if (!tabDelegate.isEditing) {
					tabBar.tabSelected(tabDelegate.index)
				}
			}

			onDoubleClicked: {
				if (!_didDrag) tabDelegate.startEditing()
			}
		}
	}

	// ── Drop indicator ──────────────────────────────────────────────────────
	Rectangle {
		id: dropIndicator
		visible: {
			if (tabBar._dragSourceIndex < 0 || tabBar._dropSlot < 0)
				return false
			var to = (tabBar._dropSlot > tabBar._dragSourceIndex)
				? tabBar._dropSlot - 1 : tabBar._dropSlot
			return to !== tabBar._dragSourceIndex
		}
		width: 2
		y: 4
		height: parent.height - 8
		color: Kirigami.Theme.highlightColor
		x: {
			var rep = tabBar._tabRepeater
			if (!rep) return 0
			var slot = tabBar._dropSlot
			if (slot < 0) return 0
			if (slot < rep.count) {
				var item = rep.itemAt(slot)
				if (item)
					return item.mapToItem(tabBar, 0, 0).x - 1
			} else if (rep.count > 0) {
				var lastItem = rep.itemAt(rep.count - 1)
				if (lastItem)
					return lastItem.mapToItem(tabBar, lastItem.width, 0).x - 1
			}
			return 0
		}
	}
}
