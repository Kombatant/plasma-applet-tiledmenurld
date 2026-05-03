import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import "Utils.js" as Utils


Item {
	id: tileItem
	x: modelData.x * cellBoxSize + _holoPad
	y: modelData.y * cellBoxSize + _holoPad
	width: modelData.w * cellBoxSize
	height: modelData.h * cellBoxSize
	z: dragActive ? 20 : ((tileItemView && tileMouseArea.containsMouse && (tileItemView.useHolographicEffect || tileItemView.usePillHoverEffect)) ? 10 : 0)

	function fixCoordinateBindings() {
		x = Qt.binding(function(){ return modelData.x * cellBoxSize + _holoPad })
		y = Qt.binding(function(){ return modelData.y * cellBoxSize + _holoPad })
	}

	AppObject {
		id: appObj
		tile: modelData
	}
	readonly property alias app: appObj.app

	readonly property bool faded: tileGrid.editing || tileMouseArea.isLeftPressed
	readonly property int fadedWidth: width - cellPushedMargin
	readonly property bool usePillHoverEffect: !!(tileItemView && tileItemView.usePillHoverEffect)
	readonly property bool isHeroTile: appObj.isHero
	readonly property real pillHoverFrameX: tileItemView.x - tileGrid.hoverOutlineSize
	readonly property real pillHoverFrameY: tileItemView.y - tileGrid.hoverOutlineSize
	readonly property real pillHoverFrameWidth: tileItemView.width + (tileGrid.hoverOutlineSize * 2)
	readonly property real pillHoverFrameHeight: tileItemView.height + (tileGrid.hoverOutlineSize * 2)
	readonly property real pillHoverFrameRadius: tileItemView.cornerRadius + tileGrid.hoverOutlineSize
	opacity: faded ? 0.75 : 1
	scale: faded ? fadedWidth / width : 1
	Behavior on opacity { NumberAnimation { duration: 200 } }
	Behavior on scale { NumberAnimation { duration: 200 } }

	//--- View Start
	readonly property bool hasDescription: appObj.descriptionText.length > 0 || appObj.labelText.length > 0
	readonly property string tileTooltipText: (appObj.labelText || "").trim()
	readonly property real descriptionSpacing: cellMargin
	readonly property bool useOverlayLabel: !!appObj.backgroundImage
	readonly property bool useStyledGroupHeader: appObj.isGroup
	readonly property real labelPaddingX: cellMargin + (6 * Screen.devicePixelRatio)
	readonly property real labelPaddingY: cellMargin + (4 * Screen.devicePixelRatio)
	readonly property real labelScrimTopPadding: Math.max(8, Math.round(8 * Screen.devicePixelRatio))
	readonly property real labelShadowOffset: Math.max(1, Math.round(1 * Screen.devicePixelRatio))
	readonly property color labelBaseColor: (tileItemView && appObj.backgroundGradient ? tileItemView.gradientBottomColor : appObj.backgroundColor)
	readonly property real labelBaseLuma: _relativeLuminance(labelBaseColor)
	readonly property bool labelUsesThemeForeground: appObj.usesGroupPanelStyling || (!useOverlayLabel && appObj.backgroundColor.a <= 0.01)
	readonly property bool labelUsesImageScrim: useOverlayLabel
	readonly property bool labelNeedsInlineOutline: !!(tileItemView && tileItemView.labelOverlapsIcon)
	readonly property bool labelSurfaceIsLight: labelBaseLuma >= 0.5
	readonly property color readableLabelTextColor: {
		if (labelUsesThemeForeground) {
			return Kirigami.Theme.textColor
		}
		if (labelUsesImageScrim || labelNeedsInlineOutline) {
			return Qt.rgba(1, 1, 1, 0.98)
		}
		return labelSurfaceIsLight
			? Qt.rgba(0, 0, 0, 0.92)
			: Qt.rgba(1, 1, 1, 0.96)
	}
	readonly property bool labelNeedsShadow: labelNeedsInlineOutline
	readonly property color labelShadowColor: labelNeedsInlineOutline ? Qt.rgba(0, 0, 0, 0.6) : "transparent"
	readonly property color labelOutlineDarkColor: labelNeedsInlineOutline ? Qt.rgba(0, 0, 0, 0.9) : "transparent"
	readonly property font groupLabelFont: Qt.font({
		family: Kirigami.Theme.defaultFont.family,
		pointSize: Kirigami.Theme.defaultFont.pointSize + 4,
		weight: Kirigami.Theme.defaultFont.weight,
		italic: Kirigami.Theme.defaultFont.italic
	})

	function _linearizeChannel(v) {
		return v <= 0.03928 ? (v / 12.92) : Math.pow((v + 0.055) / 1.055, 2.4)
	}
	function _relativeLuminance(c) {
		if (!c) {
			return 0
		}
		var r = _linearizeChannel(c.r)
		var g = _linearizeChannel(c.g)
		var b = _linearizeChannel(c.b)
		return 0.2126 * r + 0.7152 * g + 0.0722 * b
	}

	Item {
		id: tileContent
		anchors.fill: parent
		clip: appObj.inGroup && !(tileItemView && tileItemView.useHolographicEffect && tileItemView.hovered)
		scale: (!appObj.isHero && tileItemView && tileItemView.useHolographicEffect && tileMouseArea.containsMouse) ? tileGrid.holographicHoverScale : 1.0
		transformOrigin: Item.Center
		Behavior on scale {
			NumberAnimation {
				duration: 300
				easing.type: Easing.OutCubic
			}
		}

		HeroTileView {
			id: heroTileView
			visible: appObj.isHero
			anchors.fill: parent
			// Match group-panel insets so hero-to-group gaps equal group-to-group gaps.
			anchors.leftMargin: tileGrid.groupPanelInsetX
			anchors.rightMargin: tileGrid.groupPanelInsetX
			anchors.topMargin: tileGrid.groupPanelInsetTop
			anchors.bottomMargin: tileGrid.groupPanelInsetBottom
			cornerRadius: tileItemView.cornerRadius
			hovered: tileMouseArea.containsMouse || heroPrevArea.containsMouse || heroNextArea.containsMouse
		}

		TileItemView {
			id: tileItemView
			visible: !appObj.isHero
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.margins: cellMargin
			// Extra inset so edge tiles stay inside the group panel with visible padding
			readonly property real groupEdgePad: tileGrid.groupPanelInsetX + Math.round(4 * Screen.devicePixelRatio)
			anchors.leftMargin: appObj.atGroupLeft ? groupEdgePad : cellMargin
			anchors.rightMargin: appObj.atGroupRight ? groupEdgePad : cellMargin
			anchors.bottomMargin: appObj.atGroupBottom ? (tileGrid.groupPanelInsetBottom + Math.round(4 * Screen.devicePixelRatio)) : cellMargin
			width: modelData.w * cellBoxSize
			// Reserve bottom spacing so vertical gaps match horizontal gaps.
			// (Horizontal gap is cellMargin from each neighbor => total tileMargin.)
			readonly property real topInset: cellMargin
			readonly property real bottomInset: appObj.atGroupBottom ? (tileGrid.groupPanelInsetBottom + Math.round(4 * Screen.devicePixelRatio)) : cellMargin
			height: Math.max(0, parent.height - (useOverlayLabel ? 0 : (descriptionLabelBelow.visible ? (descriptionLabelBelow.height + descriptionSpacing) : 0)) - topInset - bottomInset)
			readonly property int minSize: Math.min(width, height)
			readonly property int maxSize: Math.max(width, height)
			hovered: tileMouseArea.containsMouse
		}

		FontMetrics {
			id: descriptionLabelFontMetrics
			font: descriptionLabel.font
		}

		Item {
			id: labelOverlayScrim
			visible: !appObj.isHero && useOverlayLabel && !useStyledGroupHeader && appObj.showLabel && appObj.labelText.length > 0
			anchors.fill: tileItemView

			Item {
				id: labelOverlayScrimContent
				anchors.fill: parent

				Rectangle {
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					height: (descriptionLabelFontMetrics.lineSpacing * 2) + labelScrimTopPadding + labelPaddingY
					visible: height > 0
					gradient: Gradient {
						GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
						GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.18) }
						GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
					}
				}
			}

			Rectangle {
				id: labelOverlayScrimMask
				anchors.fill: parent
				radius: tileItemView.cornerRadius
				color: "white"
				antialiasing: true
				smooth: true
			}

			ShaderEffectSource {
				id: labelOverlayScrimMaskSource
				sourceItem: labelOverlayScrimMask
				recursive: true
				live: true
				hideSource: true
				smooth: true
			}

			ShaderEffectSource {
				id: labelOverlayScrimSource
				sourceItem: labelOverlayScrimContent
				recursive: true
				live: true
				hideSource: true
				smooth: true
			}

			MultiEffect {
				anchors.fill: parent
				source: labelOverlayScrimSource
				maskEnabled: true
				maskSource: labelOverlayScrimMaskSource
				antialiasing: true
				smooth: true
			}
		}

		Item {
			id: labelOverlay
			visible: labelOverlayScrim.visible
			anchors.left: tileItemView.left
			anchors.right: tileItemView.right
			anchors.bottom: tileItemView.bottom
			anchors.leftMargin: labelPaddingX
			anchors.rightMargin: labelPaddingX
			anchors.bottomMargin: labelPaddingY
			height: visible ? (descriptionLabelFontMetrics.lineSpacing * 2) : 0

			QQC2.Label {
				id: descriptionLabelOutlineDark
				visible: false
				text: appObj.labelText
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				height: parent.height
				clip: true
				horizontalAlignment: Text.AlignLeft
				verticalAlignment: appObj.isGroup ? Text.AlignVCenter : Text.AlignBottom
				wrapMode: Text.Wrap
				maximumLineCount: 2
				elide: Text.ElideRight
				opacity: 1
				font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
				color: "transparent"
				renderType: Text.QtRendering
				style: Text.Outline
				styleColor: "transparent"
			}

			QQC2.Label {
				id: descriptionLabelOutlineLight
				visible: false
				text: appObj.labelText
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				height: parent.height
				clip: true
				horizontalAlignment: Text.AlignLeft
				verticalAlignment: appObj.isGroup ? Text.AlignVCenter : Text.AlignBottom
				wrapMode: Text.Wrap
				maximumLineCount: 2
				elide: Text.ElideRight
				opacity: 1
				font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
				color: "transparent"
				renderType: Text.QtRendering
				style: Text.Outline
				styleColor: "transparent"
			}

			QQC2.Label {
				id: descriptionLabelShadow
				visible: labelOverlay.visible && labelNeedsShadow
				text: appObj.labelText
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				anchors.leftMargin: labelShadowOffset
				anchors.bottomMargin: labelShadowOffset
				height: parent.height
				clip: true
				horizontalAlignment: Text.AlignLeft
				verticalAlignment: appObj.isGroup ? Text.AlignVCenter : Text.AlignBottom
				wrapMode: Text.Wrap
				maximumLineCount: 2
				elide: Text.ElideRight
				opacity: 1
				font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
				color: labelShadowColor
				renderType: Text.QtRendering
			}

			QQC2.Label {
				id: descriptionLabel
				visible: labelOverlay.visible
				text: appObj.labelText
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				height: parent.height
				clip: true
				horizontalAlignment: Text.AlignLeft
				verticalAlignment: appObj.isGroup ? Text.AlignVCenter : Text.AlignBottom
				wrapMode: Text.Wrap
				maximumLineCount: 2
				elide: Text.ElideRight
				opacity: useOverlayLabel ? 1 : 0.9
				font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
				color: readableLabelTextColor
				renderType: Text.QtRendering
			}
		}

		QQC2.Label {
			id: descriptionLabelBelowOutlineDark
			visible: false
			text: descriptionLabelBelow.text
			anchors.fill: descriptionLabelBelow
			clip: true
			horizontalAlignment: descriptionLabelBelow.horizontalAlignment
			verticalAlignment: descriptionLabelBelow.verticalAlignment
			wrapMode: descriptionLabelBelow.wrapMode
			maximumLineCount: descriptionLabelBelow.maximumLineCount
			elide: descriptionLabelBelow.elide
			opacity: 1
			font: descriptionLabelBelow.font
			color: "transparent"
			renderType: Text.QtRendering
			style: Text.Outline
			styleColor: "transparent"
		}

		QQC2.Label {
			id: descriptionLabelBelowOutlineLight
			visible: false
			text: descriptionLabelBelow.text
			anchors.fill: descriptionLabelBelow
			clip: true
			horizontalAlignment: descriptionLabelBelow.horizontalAlignment
			verticalAlignment: descriptionLabelBelow.verticalAlignment
			wrapMode: descriptionLabelBelow.wrapMode
			maximumLineCount: descriptionLabelBelow.maximumLineCount
			elide: descriptionLabelBelow.elide
			opacity: 1
			font: descriptionLabelBelow.font
			color: "transparent"
			renderType: Text.QtRendering
			style: Text.Outline
			styleColor: "transparent"
		}

		QQC2.Label {
			id: descriptionLabelBelowShadow
			visible: descriptionLabelBelow.visible && labelNeedsShadow
			text: descriptionLabelBelow.text
			x: descriptionLabelBelow.x + labelShadowOffset
			y: descriptionLabelBelow.y + labelShadowOffset
			width: descriptionLabelBelow.width
			height: descriptionLabelBelow.height
			clip: true
			horizontalAlignment: descriptionLabelBelow.horizontalAlignment
			verticalAlignment: descriptionLabelBelow.verticalAlignment
			wrapMode: descriptionLabelBelow.wrapMode
			maximumLineCount: descriptionLabelBelow.maximumLineCount
			elide: descriptionLabelBelow.elide
			opacity: 1
			font: descriptionLabelBelow.font
			color: labelShadowColor
			renderType: Text.QtRendering
		}

		QQC2.Label {
			id: descriptionLabelBelow
			// Hide when inline label is used (wide single-row non-group tiles with label)
			visible: !appObj.isHero && !useOverlayLabel && !useStyledGroupHeader && appObj.showLabel && appObj.labelText.length > 0 && !tileItemView.useInlineLabel && !tileItemView.useStandaloneFilledLabel
			text: appObj.labelText
			anchors.top: tileItemView.bottom
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.leftMargin: appObj.inGroup ? tileItemView.anchors.leftMargin : 0
			anchors.rightMargin: appObj.inGroup ? tileItemView.anchors.rightMargin : 0
			anchors.topMargin: descriptionSpacing
			height: visible ? (descriptionLabelFontMetrics.lineSpacing * maximumLineCount) : 0
			clip: true
			horizontalAlignment: appObj.usesGroupPanelStyling ? Text.AlignHCenter : tileItemView.labelAlignment
			verticalAlignment: appObj.isGroup ? Text.AlignVCenter : Text.AlignTop
			wrapMode: Text.Wrap
			maximumLineCount: 2
			elide: Text.ElideRight
			opacity: 1
			font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
			style: Text.Normal
			styleColor: "transparent"
			color: readableLabelTextColor
			renderType: Text.QtRendering
		}
	}

	HoverOutlineEffect {
		id: hoverOutlineEffect
		x: tileItemView.x
		y: tileItemView.y
		width: tileItemView.width
		height: tileItemView.height
		cornerRadius: tileItemView.cornerRadius
		hoverRadius: {
			if (appObj.isGroup) {
				return tileItemView.maxSize
			} else {
				return tileItemView.minSize
			}
		}
		hoverOutlineSize: tileGrid.hoverOutlineSize
		mouseArea: tileMouseArea
		visible: !appObj.isHero && tileItemView.useClassicHoverEffect && tileMouseArea.containsMouse
	}

	Kicker.ProcessRunner {
		id: tileProcessRunner
	}
	//--- View End

	MouseArea {
		id: tileMouseArea
		anchors.fill: parent
		hoverEnabled: true
		QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
		QQC2.ToolTip.visible: !!plasmoid.configuration.showTileTooltips && containsMouse && tileTooltipText.length > 0
		QQC2.ToolTip.text: tileTooltipText
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: (dragActive && dragOutside)
			? Qt.ForbiddenCursor
			: ((appObj.isHero && heroTileView && heroTileView.containsPlayButton(tileMouseArea.mouseX - heroTileView.x, tileMouseArea.mouseY - heroTileView.y))
				? Qt.PointingHandCursor
				: (editing ? Qt.ClosedHandCursor : Qt.ArrowCursor))
		readonly property bool isLeftPressed: pressedButtons & Qt.LeftButton
		property bool dragOutside: false

		function updateDragOutside(mouse) {
			if (!dragActive || !popup) {
				dragOutside = false
				return
			}
			var p = tileMouseArea.mapToItem(popup, mouse.x, mouse.y)
			dragOutside = !popup.contains(Qt.point(p.x, p.y))
		}

		property int pressX: -1
		property int pressY: -1
		onPressed: function(mouse) {
			pressX = mouse.x
			pressY = mouse.y
			dragOutside = false
		}
			onPositionChanged: function(mouse) {
				updateDragOutside(mouse)
			}
			onContainsMouseChanged: {
				if (containsMouse) {
					if (!tileItem.usePillHoverEffect || tileItem.isHeroTile) {
						tileGrid.resetHoveredTileIndicator()
						return
					}
					tileGrid.setHoveredTileItem(tileItem)
					return
				}
				Qt.callLater(function() {
					if (tileGrid.hoveredTileItem === tileItem && !tileMouseArea.containsMouse) {
						tileGrid.resetHoveredTileIndicator()
					}
				})
			}

		drag.target: plasmoid.configuration.tilesLocked ? undefined : tileItem

		// This MouseArea will spam "QQuickItem::ungrabMouse(): Item is not the mouse grabber."
		// but there's no other way of having a clickable drag area.
			onClicked: function(mouse) {
			mouse.accepted = true
			tileGrid.resetDrag()
			if (mouse.button == Qt.LeftButton) {
				if (tileEditorView && tileEditorView.tile) {
					openTileEditor()
				} else if (appObj.isHero) {
					if (heroTileView && heroTileView.containsPlayButton(mouse.x - heroTileView.x, mouse.y - heroTileView.y)) {
						heroTileView.launchCurrentPage()
					}
				} else if (modelData.url) {
					var favoriteId = modelData.favoriteId || modelData.url
					var launchUrl = modelData.launchUrl || modelData.url
					var kickerFavoriteId = Utils.kickerFavoriteId(favoriteId)
					var ran = kickerFavoriteId ? appsModel.runTileApp(kickerFavoriteId) : false
					if (!ran && launchUrl) {
						// Try deep link to systemsettings modules if runner provided a kcm id.
						var opened = false
						var moduleId = ""
						if (launchUrl.indexOf('applications://') === 0) {
							moduleId = launchUrl.substr('applications://'.length)
						} else if (launchUrl.indexOf('applications:') === 0) {
							moduleId = launchUrl.substr('applications:'.length)
						} else if (launchUrl.indexOf('//kcm_') === 0) {
							moduleId = launchUrl.substr(2) // trim leading //
						}
						if (moduleId.indexOf('//') === 0) {
							moduleId = moduleId.substr(2)
						}
						if (moduleId) {
							var candidates = [
								'systemsettings://' + moduleId,
								'systemsettings:' + moduleId,
								'settings://' + moduleId,
								'kcm:' + moduleId,
							]
							for (var i = 0; i < candidates.length && !opened; i++) {
								var target = candidates[i]
								try {
									opened = Qt.openUrlExternally(target)
								} catch(e) {
									console.warn('Tile click systemsettings candidate failed', target, e)
								}
							}
							if (!opened) {
								try {
									tileProcessRunner.runCommand('systemsettings ' + moduleId)
									opened = true
								} catch(e) {
									console.warn('Tile click systemsettings command failed', moduleId, e)
								}
							}
						}
						if (!opened) {
							try { Qt.openUrlExternally(launchUrl) } catch(e) { console.warn('Tile click fallback failed', launchUrl, e) }
						}
					}
				}
			} else if (mouse.button == Qt.RightButton) {
				contextMenu.open(mouse.x, mouse.y)
			}
		}
	}

	// Hero-tile prev/next click overlays aligned to the visible chevrons.
	MouseArea {
		id: heroPrevArea
		visible: appObj.isHero && heroTileView && heroTileView.effectivePages.length > 1
		x: heroTileView.x
		y: heroTileView.y + Math.round((heroTileView.height - height) / 2)
		width: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
		height: width
		acceptedButtons: Qt.LeftButton
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: function(mouse) {
			mouse.accepted = true
			if (heroTileView) heroTileView.prev()
		}
	}
	MouseArea {
		id: heroNextArea
		visible: appObj.isHero && heroTileView && heroTileView.effectivePages.length > 1
		x: heroTileView.x + heroTileView.width - width
		y: heroTileView.y + Math.round((heroTileView.height - height) / 2)
		width: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
		height: width
		acceptedButtons: Qt.LeftButton
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: function(mouse) {
			mouse.accepted = true
			if (heroTileView) heroTileView.next()
		}
	}

	Drag.dragType: Drag.Automatic
	Drag.proposedAction: Qt.MoveAction

	// We use this drag pattern to use the internal drag with events.
	// https://stackoverflow.com/a/24729837/947742
	property bool dragActive: tileMouseArea.drag.active
	onDragActiveChanged: {
		if (dragActive) {
			tileMouseArea.dragOutside = false
			tileGrid.startDrag(index)
			 tileGrid.dropOffsetX = 0
			// tileGrid.dropOffsetY = 0
			Drag.start()
		} else {
			var removeOnDrop = tileMouseArea.dragOutside
			Qt.callLater(tileGrid.resetDrag)
			if (!removeOnDrop) {
				Qt.callLater(tileItem.fixCoordinateBindings)
			}
			Drag.drop() // Breaks QML context.
			if (removeOnDrop && !plasmoid.configuration.tilesLocked) {
				tileGrid.removeIndex(index)
			}
			// We need to use callLater to call functions after Drag.drop().
		}
	}

	QQC2.ToolTip {
		id: control
		visible: tileItemView.hovered && !(dragActive || contextMenu.opened) && appObj.tile.w == 1 && appObj.tile.h == 1
		text: appObj.labelText
		delay: 0
		x: parent.width + rightPadding
		y: (parent.height - height) / 2
	}

	Loader {
		id: groupEffectLoader
		visible: tileMouseArea.containsMouse
		active: appObj.isGroup && visible
		sourceComponent: Rectangle {
			id: groupOutline
			color: "transparent"
			border.width: Math.max(1, Math.round(1 * Screen.devicePixelRatio))
			border.color: appObj.isCardLayout ? "#66ffffff" : "#80ffffff"
			x: appObj.isCardLayout ? tileGrid.groupPanelInsetX : 0
			y: appObj.isCardLayout ? tileGrid.groupPanelInsetTop : modelData.h * cellBoxSize
			z: 100
			width: appObj.isCardLayout
				? Math.max(0, appObj.groupRect.w * cellBoxSize - (tileGrid.groupPanelInsetX * 2))
				: appObj.groupRect.w * cellBoxSize
			height: appObj.isCardLayout
				? Math.max(0, (modelData.h + appObj.groupRect.h) * cellBoxSize - tileGrid.groupPanelInsetTop - tileGrid.groupPanelInsetBottom)
				: appObj.groupRect.h * cellBoxSize
			radius: tileItemView.cornerRadius
		}
	}

	AppContextMenu {
		id: contextMenu
		tileIndex: index
		onPopulateMenu: function(menu) {
			if (!plasmoid.configuration.tilesLocked) {
				menu.addPinToMenuAction(modelData.url)

				if (modelData.tileType == "group" || modelData.tileType == "hero") {
					var unpinItem = menu.newMenuItem()
					unpinItem.text = i18n("Unpin from Menu")
					unpinItem.icon = 'list-remove'
					unpinItem.clicked.connect(function(){
						tileGrid.removeIndex(index)
					})
					menu.addMenuItem(unpinItem)
				}
			}

			appObj.addActionList(menu)

			if (!plasmoid.configuration.tilesLocked) {
				if (modelData.tileType == "group") {
					var menuItem = menu.newMenuItem()
					menuItem.text = i18n("Sort Tiles")
					menuItem.icon = 'sort-name'
					menuItem.clicked.connect(function(){
						tileGrid.sortGroupTiles(modelData)
					})
					menu.addMenuItem(menuItem)
				}
				var menuItem = menu.newMenuItem()
				menuItem.text = i18n("Edit Tile")
				menuItem.icon = 'rectangle-shape'
				menuItem.clicked.connect(function(){
					tileItem.openTileEditor()
				})
				menu.addMenuItem(menuItem)

				// "Move to" submenu — only when tabs are enabled and >1 tab
				if (config.useTileTabs
						&& popup.tileTabsData.length > 1) {
					var moveItem = menu.newMenuItem()
					moveItem.text = i18n("Move to")
					moveItem.icon = 'tab-duplicate'
					var subMenu = Qt.createQmlObject(
						"import org.kde.plasma.extras as PlasmaExtras; PlasmaExtras.Menu {}",
						moveItem)
					subMenu.visualParent = moveItem.action
					for (var t = 0; t < popup.tileTabsData.length; t++) {
						if (t === popup.activeTabIndex) continue
						var tab = popup.tileTabsData[t]
						var tabItem = Qt.createQmlObject(
							"import org.kde.plasma.extras as PlasmaExtras; PlasmaExtras.MenuItem {}",
							subMenu)
						tabItem.text = tab.name
						;(function(tabId) {
							tabItem.clicked.connect(function() {
								tileGrid.moveTileToTab(index, tabId)
							})
						})(tab.id)
						subMenu.addMenuItem(tabItem)
					}
					menu.addMenuItem(moveItem)
				}
			}
		}
	}

	function openTileEditor() {
		tileGrid.editTile(tileGrid.tileModel[index])
	}
	function closeTileEditor() {

	}
}
