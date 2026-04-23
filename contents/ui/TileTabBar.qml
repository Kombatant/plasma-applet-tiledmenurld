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

	// Visual style: "tabs" (classic curved tabs) or "pills".
	property string style: "tabs"
	property bool alignSurfaceToTop: false
	readonly property bool _pillsMode: style === "pills"

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
	readonly property var _tabRepeater: _pillsMode ? pillsBranch.tabRepeater : tabsBranch.tabRepeater

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
	readonly property bool _frostedSurface: config.surfaceUsesFrostedGlass
	readonly property color _listBgColor: _frostedSurface
		? (_listBorderBaseIsLight ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(0.12, 0.14, 0.16, 0.46))
		: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.08)
	readonly property color _indicatorColor: _frostedSurface
		? (_listBorderBaseIsLight ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, 0.13))
		: Kirigami.Theme.backgroundColor
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
	readonly property color _listBorderBaseColor: config.surfaceBaseColor
	readonly property bool _listBorderBaseIsLight: _relativeLuminance(_listBorderBaseColor) > 0.6
	readonly property real _listBorderWidth: plasmoid.configuration.sidebarHideBorder ? 0 : Math.max(1, Math.round(Screen.devicePixelRatio))
	readonly property color _listBorderColor: _frostedSurface
		? (_listBorderBaseIsLight ? Qt.rgba(1, 1, 1, 0.44) : Qt.rgba(1, 1, 1, 0.18))
		: (_listBorderBaseIsLight ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(1, 1, 1, 0.18))

	function _relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		return (0.2126 * channel(color.r)) + (0.7152 * channel(color.g)) + (0.0722 * channel(color.b))
	}

	// ── Styling — Tabs (classic) ────────────────────────────────────────────
	readonly property real _borderWidth: Math.max(1, Math.round(Screen.devicePixelRatio))
	readonly property color _borderColor: Qt.rgba(1.0, 1.0, 1.0, 0.35)
	readonly property color _activeTopBorderColor: Kirigami.Theme.highlightColor
	readonly property color _activeTopBorderGlowColor: Qt.rgba(
		Kirigami.Theme.highlightColor.r,
		Kirigami.Theme.highlightColor.g,
		Kirigami.Theme.highlightColor.b,
		0.25)

	// ═══════════════════════════════════════════════════════════════════════
	// ── Pills branch: Flickable + list background + animated indicator ─────
	// ═══════════════════════════════════════════════════════════════════════
	Item {
		id: pillsBranch
		visible: tabBar._pillsMode
		anchors.fill: parent

		property alias tabRepeater: pillsRepeater

		Rectangle {
			id: listBackground
			anchors.fill: tabFlickable
			radius: config.tileCornerRadius
			color: tabBar._listBgColor
			border.width: tabBar._listBorderWidth
			border.color: tabBar._listBorderColor
			z: -1
		}

		Flickable {
			id: tabFlickable
			anchors.left: parent.left
			anchors.right: pillsTrailing.left
			anchors.rightMargin: Kirigami.Units.smallSpacing
			y: tabBar.alignSurfaceToTop ? 0 : Math.round((parent.height - height) / 2)
			height: tabBar.surfaceHeight
			contentWidth: pillsRow.width + tabBar._listPadding * 2
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

			Rectangle {
				id: activeIndicator
				z: 0
				visible: pillsRepeater.count > 0
				readonly property var _activeItem: {
					void(pillsRepeater.count)
					return pillsRepeater.itemAt(tabBar.activeTab)
				}
				x: _activeItem ? pillsRow.x + _activeItem.x : 0
				y: _activeItem ? pillsRow.y + _activeItem.y + 2 : 0
				width: _activeItem ? _activeItem.width : 0
				height: _activeItem ? _activeItem.height - 4 : 0
				radius: tabBar._pillRadius
				color: tabBar._indicatorColor
				border.width: 1
				border.color: Qt.rgba(0, 0, 0, 0.08)
				Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
				Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
			}

			Row {
				id: pillsRow
				x: tabBar._listPadding
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
			y: tabBar.alignSurfaceToTop ? 0 : Math.round((parent.height - height) / 2)
			height: _controlHeight
			spacing: 0

			readonly property real _controlHeight: tabBar.alignSurfaceToTop ? tabBar.surfaceHeight : tabBar.tabHeight
			readonly property real _availableWidth: tabBar.width - pillsAddBtn.width - Kirigami.Units.smallSpacing
			readonly property real _tabsContentWidth: pillsRow.width + tabBar._listPadding * 2
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

	// ═══════════════════════════════════════════════════════════════════════
	// ── Tabs branch: classic curved tabs with bottom line, no flickable ───
	// ═══════════════════════════════════════════════════════════════════════
	Item {
		id: tabsBranch
		visible: !tabBar._pillsMode
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
		readonly property real _activeTabLeft: {
			void(tabsRepeater.count)
			var item = tabsRepeater.itemAt(tabBar.activeTab)
			if (!item) return 0
			return tabsFlickable.x + item.x - tabsFlickable.contentX
		}
		readonly property real _activeTabRight: {
			void(tabsRepeater.count)
			var item = tabsRepeater.itemAt(tabBar.activeTab)
			if (!item) return 0
			return tabsFlickable.x + item.x + item.width - tabsFlickable.contentX
		}

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

			Row {
				id: tabsRow
				height: tabsFlickable.height
				spacing: 0

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

				QQC2.Label {
					anchors.centerIn: parent
					text: "‹"
					font.pixelSize: Kirigami.Units.gridUnit * 1.2
					color: Kirigami.Theme.textColor
					opacity: !tabsScrollLeft.enabled ? 0.25
						: tabsScrollLeftMA.containsMouse ? 0.9 : 0.55
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

				QQC2.Label {
					anchors.centerIn: parent
					text: "›"
					font.pixelSize: Kirigami.Units.gridUnit * 1.2
					color: Kirigami.Theme.textColor
					opacity: !tabsScrollRight.enabled ? 0.25
						: tabsScrollRightMA.containsMouse ? 0.9 : 0.55
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

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "tab-new-symbolic"
					width: Kirigami.Units.iconSizes.smallMedium
					height: width
					color: Kirigami.Theme.textColor
					opacity: tabsAddMA.containsMouse ? 0.9 : 0.55
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
	// ── Shared tab delegate component ──────────────────────────────────────
	// ═══════════════════════════════════════════════════════════════════════
	component TabDelegate: Item {
		id: tabDelegate

		required property int index
		required property var modelData
		property bool pillsMode: false
		property Item rowRef: null

		readonly property bool isActive: tabBar.activeTab === index
		property bool isEditing: false

		readonly property bool hasIcon: tabIcon !== ""
		readonly property bool isHovered: hoverArea.containsMouse
		readonly property string tabIcon: (modelData && modelData.icon) || ""

		width: pillsMode
			? Math.max(Kirigami.Units.gridUnit * 5, tabLabelMetrics.advanceWidth + (hasIcon ? tabIconItem.width + Kirigami.Units.smallSpacing : 0) + Kirigami.Units.gridUnit * 2)
			: Math.max(Kirigami.Units.gridUnit * 6, tabLabelMetrics.advanceWidth + (hasIcon ? tabIconItem.width + Kirigami.Units.smallSpacing : 0) + Kirigami.Units.gridUnit * 3)
		height: rowRef ? rowRef.height : 0

		TextMetrics {
			id: tabLabelMetrics
			font: tabLabelText.font
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

		// ── Curved tab shape (tabs style only) ──
		Canvas {
			id: tabShape
			visible: !tabDelegate.pillsMode && tabDelegate.isActive
			anchors.fill: parent

			readonly property real r: Kirigami.Units.smallSpacing * 2
			readonly property real bw: tabBar._borderWidth
			readonly property color bc: tabBar._borderColor
			readonly property color topBorderColor: tabBar._activeTopBorderColor
			readonly property color topBorderGlowColor: tabBar._activeTopBorderGlowColor

			onPaint: {
				var ctx = getContext("2d")
				ctx.clearRect(0, 0, width, height)
				var w = width, h = height

				ctx.beginPath()
				ctx.moveTo(0, h)
				ctx.lineTo(0, r)
				ctx.arcTo(0, 0, r, 0, r)
				ctx.lineTo(w - r, 0)
				ctx.arcTo(w, 0, w, r, r)
				ctx.lineTo(w, h)
				ctx.closePath()

				var grad = ctx.createLinearGradient(0, 0, 0, h)
				grad.addColorStop(0.0, Qt.rgba(1.0, 1.0, 1.0, 0.08))
				grad.addColorStop(1.0, "transparent")
				ctx.fillStyle = grad
				ctx.fill()

				ctx.beginPath()
				ctx.moveTo(0, h)
				ctx.lineTo(0, r)
				ctx.arcTo(0, 0, r, 0, r)
				ctx.lineTo(w - r, 0)
				ctx.arcTo(w, 0, w, r, r)
				ctx.lineTo(w, h)
				ctx.lineWidth = bw
				ctx.strokeStyle = bc
				ctx.stroke()

				ctx.beginPath()
				ctx.moveTo(r, bw * 0.5)
				ctx.lineTo(w - r, bw * 0.5)
				ctx.lineWidth = bw
				ctx.strokeStyle = topBorderColor
				ctx.stroke()

				ctx.beginPath()
				ctx.moveTo(r, bw * 1.5)
				ctx.lineTo(w - r, bw * 1.5)
				ctx.lineWidth = bw
				ctx.strokeStyle = topBorderGlowColor
				ctx.stroke()
			}

			onWidthChanged: requestPaint()
			onHeightChanged: requestPaint()
			onBcChanged: requestPaint()
			onTopBorderColorChanged: requestPaint()
			onTopBorderGlowColorChanged: requestPaint()
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
			spacing: tabDelegate.pillsMode ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing
			visible: !tabDelegate.isEditing
			opacity: tabDelegate.pillsMode
				? ((tabBar._dragSourceIndex === tabDelegate.index) ? 0.3 : 1.0)
				: ((tabBar._dragSourceIndex === tabDelegate.index) ? 0.3
					: tabDelegate.isActive ? 1.0
					: hoverArea.containsMouse ? 0.85 : 0.55)
			Behavior on opacity { NumberAnimation { duration: 100 } }

			Kirigami.Icon {
				id: tabIconItem
				visible: tabDelegate.hasIcon
				source: tabDelegate.tabIcon
				width: visible ? tabLabelText.font.pixelSize : 0
				height: width
				anchors.verticalCenter: parent.verticalCenter
				color: tabDelegate._fgColor
			}

			QQC2.Label {
				id: tabLabelText
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				font.pointSize: tabDelegate.pillsMode
					? Kirigami.Theme.defaultFont.pointSize
					: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.05)
				font.weight: tabDelegate.isActive ? Font.DemiBold : Font.Normal
				text: (tabDelegate.modelData && tabDelegate.modelData.name) || ""
				color: tabDelegate._fgColor
				Behavior on color { ColorAnimation { duration: 120 } }
				elide: Text.ElideRight
			}
		}

		// ── Edit input ───────────────────────────────────────────
		TextInput {
			id: tabInput
			anchors.fill: parent
			anchors.leftMargin: Kirigami.Units.largeSpacing
			anchors.rightMargin: Kirigami.Units.largeSpacing
			horizontalAlignment: TextInput.AlignHCenter
			verticalAlignment: TextInput.AlignVCenter
			font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.05)
			color: Kirigami.Theme.textColor
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
