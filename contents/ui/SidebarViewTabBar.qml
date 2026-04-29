import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// View-mode selector for the docked LeftPaneView.
// Renders the Categories/Alphabetical/AI Chat entries as tabs or pills,
// matching the TileTabBar style configured via `config.tileTabStyle`.
// When `config.useTileTabs` is false, falls back to the classic flat icon row.
// The Auto Resize action is shown in the trailing "+"-slot of the bar.
Item {
	id: root

	// Signals for each action. `direction` is +1 when the target view is to the right of the
	// currently active view, -1 when to the left, 0 when no active view (or same view).
	signal categoriesClicked(int direction)
	signal alphabeticalClicked(int direction)
	signal aiChatClicked(int direction)
	signal autoResizeClicked()

	property bool categoriesChecked: false
	property bool alphabeticalChecked: false
	property bool aiChatChecked: false

	readonly property bool _tabsEnabled: !!config.useTileTabs
	readonly property string _style: (plasmoid.configuration.tileTabStyle || "tabs")
	readonly property bool _pillsMode: _tabsEnabled && _style === "pills"
	readonly property bool _tabsMode: _tabsEnabled && _style === "tabs"
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
	readonly property color _borderColor: Qt.rgba(1.0, 1.0, 1.0, 0.35)
	readonly property color _activeTopBorderColor: Kirigami.Theme.highlightColor
	readonly property color _activeTopBorderGlowColor: Qt.rgba(
		Kirigami.Theme.highlightColor.r,
		Kirigami.Theme.highlightColor.g,
		Kirigami.Theme.highlightColor.b,
		0.25)

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
		SidebarItem {
			icon.name: "transform-scale"
			text: i18n("Auto Resize")
			tooltipText: i18n("Auto Resize")
			Layout.fillWidth: false
			Layout.preferredWidth: config.flatButtonSize
			Layout.preferredHeight: config.flatButtonSize
			onClicked: root.autoResizeClicked()
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

			Row {
				id: pillsRow
				anchors.left: parent.left
				anchors.leftMargin: root._pillsInset
				anchors.right: pillsAddBtn.left
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

						PillHighlight {
							visible: pillDelegate.isActive
							anchors.fill: parent
							styleSource: root
							flushLeft: pillDelegate.index === 0
						}

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

			Item {
				id: pillsAddBtn
				anchors.right: parent.right
				width: parent.height
				height: parent.height

				Accessible.name: i18n("Auto Resize")
				Accessible.role: Accessible.Button
				QQC2.ToolTip.visible: pillsAddMA.containsMouse
				QQC2.ToolTip.text: i18n("Auto Resize")

				Kirigami.Icon {
					anchors.centerIn: parent
					source: "transform-scale"
					width: Kirigami.Units.iconSizes.smallMedium
					height: width
					color: Kirigami.Theme.textColor
					opacity: pillsAddMA.containsMouse ? 0.9 : 0.55
					isMask: true
				}

				MouseArea {
					id: pillsAddMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.autoResizeClicked()
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

		readonly property real _activeTabLeft: {
			void(tabsRepeater.count)
			var item = tabsRepeater.itemAt(root._activeIndex)
			if (!item) return 0
			return tabsRow.x + item.x
		}
		readonly property real _activeTabRight: {
			void(tabsRepeater.count)
			var item = tabsRepeater.itemAt(root._activeIndex)
			if (!item) return 0
			return tabsRow.x + item.x + item.width
		}
		readonly property bool _activeReady: root._activeIndex >= 0 && tabsRepeater.itemAt(root._activeIndex)

		Row {
			id: tabsRow
			anchors.left: parent.left
			anchors.right: tabsAddBtn.left
			anchors.bottom: parent.bottom
			height: root.tabHeight
			spacing: 0

			Repeater {
				id: tabsRepeater
				model: root._items
				delegate: Item {
					id: tabDelegate
					required property var modelData
					readonly property int itemIdx: modelData.idx
					readonly property bool isActive: root._activeIndex === itemIdx
					readonly property bool isHovered: tabMA.containsMouse
					width: Math.max(0, tabsRow.width / tabsRepeater.count)
					height: tabsRow.height

					Canvas {
						id: tabShape
						visible: tabDelegate.isActive
						anchors.fill: parent

						readonly property real r: Kirigami.Units.smallSpacing * 2
						readonly property real bw: root._borderWidth
						readonly property color bc: root._borderColor
						readonly property color topBorderColor: root._activeTopBorderColor
						readonly property color topBorderGlowColor: root._activeTopBorderGlowColor

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

					Kirigami.Icon {
						anchors.centerIn: parent
						source: tabDelegate.modelData.icon
						width: Kirigami.Units.iconSizes.smallMedium
						height: width
						color: Kirigami.Theme.textColor
						opacity: tabDelegate.isActive ? 1.0 : (tabDelegate.isHovered ? 0.85 : 0.55)
						Behavior on opacity { NumberAnimation { duration: 100 } }
						isMask: true
					}

					MouseArea {
						id: tabMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: root._trigger(tabDelegate.itemIdx)
					}

					QQC2.ToolTip.visible: tabMA.containsMouse
					QQC2.ToolTip.text: tabDelegate.modelData.label
				}
			}
		}

		Item {
			id: tabsAddBtn
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			width: root.tabHeight
			height: root.tabHeight

			Accessible.name: i18n("Auto Resize")
			Accessible.role: Accessible.Button
			QQC2.ToolTip.visible: tabsAddMA.containsMouse
			QQC2.ToolTip.text: i18n("Auto Resize")

			Kirigami.Icon {
				anchors.centerIn: parent
				source: "transform-scale"
				width: Kirigami.Units.iconSizes.smallMedium
				height: width
				color: Kirigami.Theme.textColor
				opacity: tabsAddMA.containsMouse ? 0.9 : 0.55
				isMask: true
			}

			MouseArea {
				id: tabsAddMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: root.autoResizeClicked()
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
}
