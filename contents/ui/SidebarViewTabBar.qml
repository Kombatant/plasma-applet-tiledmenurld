import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// View-mode selector for the docked LeftPaneView.
// Renders the Categories/Alphabetical/AI Chat entries as tabs or pills,
// matching the TileTabBar style configured via `config.tileTabStyle`.
// When `config.useTileTabs` is false, falls back to the classic flat icon row.
Item {
	id: root

	// Signals for each action. `direction` is +1 when the target view is to the right of the
	// currently active view, -1 when to the left, 0 when no active view (or same view).
	signal categoriesClicked(int direction)
	signal alphabeticalClicked(int direction)
	signal aiChatClicked(int direction)

	property bool categoriesChecked: false
	property bool alphabeticalChecked: false
	property bool aiChatChecked: false

	readonly property bool _tabsEnabled: !!config.useTileTabs
	readonly property string _style: (plasmoid.configuration.tileTabStyle || "tabs")
	readonly property bool _pillsMode: _tabsEnabled && _style === "pills"
	readonly property bool _underlineMode: _tabsEnabled && _style === "underline"
	// "tabs" is the stored value for the Accent Tab style.
	readonly property bool _tabsMode: _tabsEnabled && !_pillsMode && !_underlineMode
	readonly property bool _flatMode: !_tabsEnabled

	readonly property int tabHeight: Kirigami.Units.gridUnit * 2.5
	readonly property int surfaceHeight: _pillsMode ? Math.round(tabHeight * 0.85) : tabHeight

	implicitHeight: _flatMode ? config.flatButtonSize : tabHeight

	// Active index: 0 categories, 1 alphabetical, 2 ai chat, -1 none
	readonly property int _activeIndex: {
		if (categoriesChecked) return 0
		if (alphabeticalChecked) return 1
		if (aiChatChecked) return 2
		return -1
	}

	readonly property var _items: {
		var arr = [
			{ idx: 0, icon: "view-list-tree", label: i18n("Categories") },
			{ idx: 1, icon: "view-list-text", label: i18n("Alphabetical") }
		]
		if (config.aiChatEnabled) {
			arr.push({ idx: 2, icon: "dialog-messages", label: i18n("AI Chat") })
		}
		return arr
	}

	function _trigger(idx) {
		var dir = 0
		if (_activeIndex >= 0 && idx !== _activeIndex) {
			dir = (idx > _activeIndex) ? 1 : -1
		}
		if (idx === 0) root.categoriesClicked(dir)
		else if (idx === 1) root.alphabeticalClicked(dir)
		else if (idx === 2) root.aiChatClicked(dir)
	}

	// ── Shared styling ───────────────────────────────────────────────────
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
	readonly property color _hoverTextColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.88)
	readonly property color _idleTextColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.72)
	readonly property real _borderWidth: Math.max(1, Math.round(Screen.devicePixelRatio))
	// Theme-derived so the rule reads correctly in light and dark themes.
	readonly property color _borderColor: Qt.rgba(
		Kirigami.Theme.textColor.r,
		Kirigami.Theme.textColor.g,
		Kirigami.Theme.textColor.b,
		0.18)
	// Matches TileTabBar's Accent Tab styling.
	readonly property real _tabCornerRadius: Kirigami.Units.smallSpacing * 2.5
	readonly property real _tabHoverBorderOpacity: 0.30
	readonly property real _tabHoverGlowOpacity: 0.22
	readonly property real _tabHoverFillStrength: 0.42
	readonly property int _tabHoverMotionDuration: 220
	readonly property int _tabFadeDuration: 140
	readonly property real _underlineThickness: 2
	readonly property real _underlineHoverFill: 0.08
	readonly property int _pillMotionDuration: 420

	// ═════════════════════════════════════════════════════════════════════
	// Flat fallback — original icon row
	// ═════════════════════════════════════════════════════════════════════
	RowLayout {
		visible: root._flatMode
		anchors.fill: parent
		spacing: 0

		SidebarViewButton {
			appletIconName: "view-list-tree"
			labelText: i18n("Categories")
			defaultCheckedEdge: Qt.BottomEdge
			checkedPillVisible: true
			checkedUnderlineVisible: true
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			checked: root.categoriesChecked
			onClicked: root._trigger(0)
		}
		SidebarViewButton {
			appletIconName: "view-list-text"
			labelText: i18n("Alphabetical")
			defaultCheckedEdge: Qt.BottomEdge
			checkedPillVisible: true
			checkedUnderlineVisible: true
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			checked: root.alphabeticalChecked
			onClicked: root._trigger(1)
		}
		SidebarViewButton {
			appletIconName: "dialog-messages"
			labelText: i18n("AI Chat")
			defaultCheckedEdge: Qt.BottomEdge
			checkedPillVisible: true
			checkedUnderlineVisible: true
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			checked: root.aiChatChecked
			onClicked: root._trigger(2)
			visible: config.aiChatEnabled
		}
	}

	// ═════════════════════════════════════════════════════════════════════
	// Pills branch
	// ═════════════════════════════════════════════════════════════════════
	Item {
		id: pillsBranch
		visible: root._pillsMode
		anchors.fill: parent

		Item {
			id: pillsSurface
			anchors.left: parent.left
			anchors.right: parent.right
			y: Math.round((parent.height - height) / 2)
			height: root.surfaceHeight

			SidebarGlassCard {
				anchors.fill: parent
				contentMargins: 0
			}

			PillHighlight {
				id: activePillIndicator
				visible: root._activeIndex >= 0 && !!_activeItem
				styleSource: root
				readonly property var _activeItem: {
					void(pillsRepeater.count)
					for (var i = 0; i < pillsRepeater.count; i++) {
						var item = pillsRepeater.itemAt(i)
						if (item && item.itemIdx === root._activeIndex) {
							return item
						}
					}
					return null
				}
				x: _activeItem ? pillsRow.x + _activeItem.x : 0
				anchors.top: pillsRow.top
				anchors.bottom: pillsRow.bottom
				width: _activeItem ? _activeItem.width : 0
				flushLeft: _activeItem && _activeItem.index === 0
				Behavior on x {
					NumberAnimation {
						duration: root._pillMotionDuration
						easing.type: Easing.OutCubic
					}
				}
				Behavior on width {
					NumberAnimation {
						duration: root._pillMotionDuration
						easing.type: Easing.OutCubic
					}
				}
			}

			Row {
				id: pillsRow
				anchors.left: parent.left
				anchors.leftMargin: root._pillsInset
				anchors.right: parent.right
				anchors.rightMargin: root._pillsInset
				height: parent.height
				spacing: Kirigami.Units.smallSpacing

				Repeater {
					id: pillsRepeater
					model: root._items
					delegate: Item {
						id: pillDelegate
						required property int index
						required property var modelData
						readonly property int itemIdx: modelData.idx
						readonly property bool isActive: root._activeIndex === itemIdx
						readonly property bool isHovered: pillMA.containsMouse
						width: Math.max(0, (pillsRow.width - (pillsRepeater.count - 1) * pillsRow.spacing) / pillsRepeater.count)
						height: pillsRow.height

						Kirigami.Icon {
							anchors.centerIn: parent
							source: pillDelegate.modelData.icon
							width: Kirigami.Units.iconSizes.smallMedium
							height: width
							color: pillDelegate.isActive
								? root._activeTextColor
								: (pillDelegate.isHovered ? root._hoverTextColor : root._idleTextColor)
							isMask: true
						}

						MouseArea {
							id: pillMA
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: root._trigger(pillDelegate.itemIdx)
						}

						QQC2.ToolTip.visible: pillMA.containsMouse
						QQC2.ToolTip.text: pillDelegate.modelData.label
					}
				}
			}

		}
	}

	// ═════════════════════════════════════════════════════════════════════
	// Classic tabs branch
	// ═════════════════════════════════════════════════════════════════════
	Item {
		id: tabsBranch
		visible: root._tabsMode
		anchors.fill: parent

		// Follow the highlight's animated geometry rather than the delegate's
		// instant x/width, so the gap in the bottom line travels with the
		// highlight instead of teleporting ahead of it.
		readonly property real _activeTabLeft: tabsActiveIndicator.x
		readonly property real _activeTabRight: tabsActiveIndicator.x + tabsActiveIndicator.width
		readonly property bool _activeReady: root._activeIndex >= 0

		// Hover highlight — slides between tabs, weaker than the active one.
		PillHighlight {
			id: tabsHoverIndicator
			z: 0
			styleSource: root
			active: false
			visible: tabsRow.hoverIndex >= 0 && tabsRow.hoverIndex !== root._activeIndex
			readonly property var _hoverItem: tabsRow.hoverItem
			x: _hoverItem ? tabsRow.x + _hoverItem.x : 0
			width: _hoverItem ? _hoverItem.width : 0
			anchors.top: tabsRow.top
			anchors.bottom: tabsRow.bottom
			radiusTopLeft: root._tabCornerRadius
			radiusTopRight: root._tabCornerRadius
			radiusBottomLeft: 0
			radiusBottomRight: 0
			borderOpacity: root._tabHoverBorderOpacity
			glowOpacity: root._tabHoverGlowOpacity
			fillStrength: root._tabHoverFillStrength
			// Do not slide in from wherever the pointer last was.
			Behavior on x {
				enabled: tabsHoverIndicator.visible
				NumberAnimation {
					duration: root._tabHoverMotionDuration
					easing.type: Easing.OutCubic
				}
			}
			Behavior on width {
				enabled: tabsHoverIndicator.visible
				NumberAnimation {
					duration: root._tabHoverMotionDuration
					easing.type: Easing.OutCubic
				}
			}
		}

		// Single active highlight that slides between tabs.
		PillHighlight {
			id: tabsActiveIndicator
			z: 1
			styleSource: root
			visible: tabsBranch._activeReady
			// tabsRow.activeItem is assigned by the delegates themselves, so it
			// updates when they are created. A binding calling itemAt() here
			// would evaluate once during construction and never re-run.
			readonly property var _activeItem: tabsRow.activeItem
			x: _activeItem ? tabsRow.x + _activeItem.x : 0
			width: _activeItem ? _activeItem.width : 0
			anchors.top: tabsRow.top
			anchors.bottom: tabsRow.bottom
			radiusTopLeft: root._tabCornerRadius
			radiusTopRight: root._tabCornerRadius
			radiusBottomLeft: 0
			radiusBottomRight: 0
			Behavior on x {
				enabled: tabsRow.primed
				NumberAnimation {
					duration: root._pillMotionDuration
					easing.type: Easing.OutCubic
				}
			}
			// Width is deliberately not animated: sidebar entries are equal
			// width, so it only ever changes while delegates are still laying
			// out — animating it made the highlight crawl open on load.
		}

		Row {
			id: tabsRow
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: root.tabHeight
			spacing: 0
			z: 2

			// Index of the hovered tab, or -1. Drives the hover highlight.
			property int hoverIndex: -1

			// Resolved delegates for the active/hovered entries. Delegates call
			// refreshItems() as they are created and destroyed; a binding that
			// called tabsRepeater.itemAt() instead would evaluate once during
			// construction and never re-run, leaving the highlight hidden.
			property Item activeItem: null
			property Item hoverItem: null
			// False until the active delegate resolves for the first time. The
			// indicator's Behaviors stay disabled until then, so its initial
			// geometry snaps into place rather than animating up from zero
			// (which reads as the highlight crawling out on load).
			property bool primed: false

			function refreshItems() {
				var act = null
				var hov = null
				for (var i = 0; i < tabsRepeater.count; i++) {
					var item = tabsRepeater.itemAt(i)
					if (!item) continue
					if (item.itemIdx === root._activeIndex) act = item
					if (i === hoverIndex) hov = item
				}
				activeItem = act
				hoverItem = hov
				if (!primed && tabsRepeater.count > 0 && width > 0) {
					// Let the snapped geometry apply, then allow animation.
					primeTimer.restart()
				}
			}

			onWidthChanged: refreshItems()

			Timer {
				id: primeTimer
				interval: 0
				onTriggered: tabsRow.primed = true
			}

			onHoverIndexChanged: refreshItems()

			Connections {
				target: root
				function on_ActiveIndexChanged() { tabsRow.refreshItems() }
			}

			Repeater {
				id: tabsRepeater
				model: root._items
				delegate: Item {
					id: tabDelegate
					required property var modelData
					readonly property int itemIdx: modelData.idx
					readonly property bool isActive: root._activeIndex === itemIdx
					readonly property bool isHovered: tabMA.containsMouse
					required property int index
					width: Math.max(0, tabsRow.width / tabsRepeater.count)
					height: tabsRow.height

					Component.onCompleted: tabsRow.refreshItems()
					Component.onDestruction: tabsRow.refreshItems()

					Kirigami.Icon {
						anchors.centerIn: parent
						source: tabDelegate.modelData.icon
						width: Kirigami.Units.iconSizes.smallMedium
						height: width
						color: Kirigami.Theme.textColor
						opacity: tabDelegate.isActive ? 1.0 : (tabDelegate.isHovered ? 0.9 : 0.62)
						Behavior on opacity { NumberAnimation { duration: root._tabFadeDuration } }
						isMask: true
					}

					MouseArea {
						id: tabMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: root._trigger(tabDelegate.itemIdx)
						onEntered: tabsRow.hoverIndex = tabDelegate.index
						onExited: if (tabsRow.hoverIndex === tabDelegate.index) tabsRow.hoverIndex = -1
					}

					QQC2.ToolTip.visible: tabMA.containsMouse
					QQC2.ToolTip.text: tabDelegate.modelData.label
				}
			}
		}

		// Bottom line split around active tab
		Rectangle {
			id: bottomLineFull
			visible: !tabsBranch._activeReady
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: root._borderWidth
			color: root._borderColor
		}
		Rectangle {
			visible: tabsBranch._activeReady
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			width: Math.max(0, tabsBranch._activeTabLeft)
			height: root._borderWidth
			color: root._borderColor
		}
		Rectangle {
			visible: tabsBranch._activeReady
			x: tabsBranch._activeTabRight
			anchors.bottom: parent.bottom
			width: Math.max(0, parent.width - x)
			height: root._borderWidth
			color: root._borderColor
		}
	}

	// ═════════════════════════════════════════════════════════════════════
	// Underline branch
	// ═════════════════════════════════════════════════════════════════════
	Item {
		id: underlineBranch
		visible: root._underlineMode
		anchors.fill: parent

		readonly property bool _activeReady: root._activeIndex >= 0

		Row {
			id: underlineRow
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: root.tabHeight
			spacing: 0

			// See tabsRow.refreshItems().
			property Item activeItem: null
			// See tabsRow.primed.
			property bool primed: false

			function refreshItems() {
				var act = null
				for (var i = 0; i < underlineRepeater.count; i++) {
					var item = underlineRepeater.itemAt(i)
					if (item && item.itemIdx === root._activeIndex) act = item
				}
				activeItem = act
				if (!primed && underlineRepeater.count > 0 && width > 0) {
					underlinePrimeTimer.restart()
				}
			}

			onWidthChanged: refreshItems()

			Timer {
				id: underlinePrimeTimer
				interval: 0
				onTriggered: underlineRow.primed = true
			}

			Connections {
				target: root
				function on_ActiveIndexChanged() { underlineRow.refreshItems() }
			}

			Repeater {
				id: underlineRepeater
				model: root._items
				delegate: Item {
					id: underlineDelegate
					required property var modelData
					required property int index
					readonly property int itemIdx: modelData.idx
					readonly property bool isActive: root._activeIndex === itemIdx
					readonly property bool isHovered: underlineMA.containsMouse
					width: Math.max(0, underlineRow.width / underlineRepeater.count)
					height: underlineRow.height

					Component.onCompleted: underlineRow.refreshItems()
					Component.onDestruction: underlineRow.refreshItems()

					Rectangle {
						anchors.fill: parent
						anchors.topMargin: Math.round(Kirigami.Units.smallSpacing * 0.5)
						anchors.bottomMargin: Math.round(Kirigami.Units.smallSpacing * 1.5)
						radius: config.tileCornerRadius
						color: Qt.rgba(
							Kirigami.Theme.textColor.r,
							Kirigami.Theme.textColor.g,
							Kirigami.Theme.textColor.b,
							underlineDelegate.isHovered ? root._underlineHoverFill : 0.0)
						Behavior on color { ColorAnimation { duration: root._tabFadeDuration } }
					}

					Kirigami.Icon {
						anchors.centerIn: parent
						anchors.verticalCenterOffset: -Math.round(Kirigami.Units.smallSpacing * 0.5)
						source: underlineDelegate.modelData.icon
						width: Kirigami.Units.iconSizes.smallMedium
						height: width
						isMask: true
						color: underlineDelegate.isActive
							? Kirigami.Theme.highlightColor
							: Kirigami.Theme.textColor
						opacity: underlineDelegate.isActive ? 1.0 : (underlineDelegate.isHovered ? 0.9 : 0.62)
						Behavior on opacity { NumberAnimation { duration: root._tabFadeDuration } }
						Behavior on color { ColorAnimation { duration: root._tabFadeDuration } }
					}

					MouseArea {
						id: underlineMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: root._trigger(underlineDelegate.itemIdx)
					}

					QQC2.ToolTip.visible: underlineMA.containsMouse
					QQC2.ToolTip.text: underlineDelegate.modelData.label
				}
			}
		}

		// Sliding accent underline beneath the active entry.
		Item {
			id: activeUnderline
			readonly property var _activeItem: underlineRow.activeItem
			visible: underlineBranch._activeReady
			x: (_activeItem ? underlineRow.x + _activeItem.x : 0) + Kirigami.Units.smallSpacing
			width: Math.max(0, (_activeItem ? _activeItem.width : 0) - Kirigami.Units.smallSpacing * 2)
			anchors.bottom: parent.bottom
			anchors.bottomMargin: root._borderWidth
			height: root._underlineThickness

			Behavior on x {
				enabled: underlineRow.primed
				NumberAnimation {
					duration: root._pillMotionDuration
					easing.type: Easing.OutCubic
				}
			}
			// See tabsActiveIndicator: width is intentionally not animated.

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

		// Full-width rule — nothing merges into the content in this style.
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: root._borderWidth
			color: root._borderColor
		}
	}
}
