import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami


Item {
	id: tileItem
	x: modelData.x * cellBoxSize + _holoPad
	y: modelData.y * cellBoxSize + _holoPad
	width: modelData.w * cellBoxSize 
	height: modelData.h * cellBoxSize
	z: dragActive ? 20 : ((tileItemView && tileItemView.useHolographicEffect && tileMouseArea.containsMouse) ? 10 : 0)

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
	opacity: faded ? 0.75 : 1
	scale: faded ? fadedWidth / width : 1
	Behavior on opacity { NumberAnimation { duration: 200 } }
	Behavior on scale { NumberAnimation { duration: 200 } }

	//--- View Start
	readonly property bool hasDescription: appObj.descriptionText.length > 0 || appObj.labelText.length > 0
	readonly property string tileTooltipText: (appObj.labelText || "").trim()
	readonly property real descriptionSpacing: cellMargin
	readonly property bool useOverlayLabel: !!appObj.backgroundImage
	readonly property bool useStyledGroupHeader: appObj.isGroup && plasmoid && plasmoid.configuration && plasmoid.configuration.showGroupTileNameBorder
	readonly property real labelPaddingX: cellMargin + (6 * Screen.devicePixelRatio)
	readonly property real labelPaddingY: cellMargin + (4 * Screen.devicePixelRatio)
	readonly property real labelShadowOffset: Math.max(1, Math.round(1 * Screen.devicePixelRatio))
	readonly property color labelBaseColor: (tileItemView && appObj.backgroundGradient ? tileItemView.gradientBottomColor : appObj.backgroundColor)
	readonly property real labelBaseLuma: _relativeLuminance(labelBaseColor)
	readonly property bool labelBaseIsLight: labelBaseLuma >= 0.6
	readonly property bool labelUseDualOutline: !!appObj.backgroundImage
	readonly property real labelOutlineDarkOpacity: labelUseDualOutline ? 0.45 : (labelBaseIsLight ? 0.6 : 0.2)
	readonly property real labelOutlineLightOpacity: labelUseDualOutline ? 0.45 : (labelBaseIsLight ? 0.2 : 0.6)
	readonly property color labelOutlineDarkColor: Qt.rgba(0, 0, 0, labelOutlineDarkOpacity)
	readonly property color labelOutlineLightColor: Qt.rgba(1, 1, 1, labelOutlineLightOpacity)
	readonly property color labelShadowColor: labelBaseIsLight ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(1, 1, 1, 0.3)
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

		TileItemView {
			id: tileItemView
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.margins: cellMargin
			width: modelData.w * cellBoxSize
			// Reserve bottom spacing so vertical gaps match horizontal gaps.
			// (Horizontal gap is cellMargin from each neighbor => total tileMargin.)
			height: Math.max(0, parent.height - (useOverlayLabel ? 0 : (descriptionLabelBelow.visible ? (descriptionLabelBelow.height + descriptionSpacing) : 0)) - (cellMargin * 2))
			readonly property int minSize: Math.min(width, height)
			readonly property int maxSize: Math.max(width, height)
			hovered: tileMouseArea.containsMouse
		}

		FontMetrics {
			id: descriptionLabelFontMetrics
			font: descriptionLabel.font
		}

		Item {
			id: labelOverlay
			visible: useOverlayLabel && !useStyledGroupHeader && appObj.showLabel && appObj.labelText.length > 0
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.leftMargin: labelPaddingX
			anchors.rightMargin: labelPaddingX
			anchors.bottomMargin: labelPaddingY
			height: visible ? (descriptionLabelFontMetrics.lineSpacing * 2) : 0

			QQC2.Label {
				id: descriptionLabelOutlineDark
				visible: labelOverlay.visible && labelOutlineDarkOpacity > 0
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
				styleColor: labelOutlineDarkColor
			}

			QQC2.Label {
				id: descriptionLabelOutlineLight
				visible: labelOverlay.visible && labelOutlineLightOpacity > 0
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
				styleColor: labelOutlineLightColor
			}

			QQC2.Label {
				id: descriptionLabelShadow
				visible: labelOverlay.visible
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
				opacity: labelUseDualOutline ? 0.25 : 0.2
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
				opacity: 0.9
				font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
				color: Kirigami.Theme.textColor
				renderType: Text.QtRendering
			}
		}

		QQC2.Label {
			id: descriptionLabelBelow
			// Hide when inline label is used (wide single-row non-group tiles with label)
			visible: !useOverlayLabel && !useStyledGroupHeader && appObj.showLabel && appObj.labelText.length > 0 && !tileItemView.useInlineLabel
			text: appObj.labelText
			anchors.top: tileItemView.bottom
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.topMargin: descriptionSpacing
			height: visible ? (descriptionLabelFontMetrics.lineSpacing * maximumLineCount) : 0
			clip: true
			horizontalAlignment: tileItemView.labelAlignment
			verticalAlignment: appObj.isGroup ? Text.AlignVCenter : Text.AlignTop
			wrapMode: Text.Wrap
			maximumLineCount: 2
			elide: Text.ElideRight
			opacity: 0.92
			font: appObj.isGroup ? groupLabelFont : Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
			color: Kirigami.Theme.textColor
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
		// Only show classic hover effect when holographic is not enabled; skip group tiles
		// (group tiles use groupEffectLoader instead and the small header rect looks disconnected)
		visible: !appObj.isGroup && !tileItemView.useHolographicEffect && tileMouseArea.containsMouse
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
		cursorShape: (dragActive && dragOutside) ? Qt.ForbiddenCursor : (editing ? Qt.ClosedHandCursor : Qt.ArrowCursor)
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

		drag.target: plasmoid.configuration.tilesLocked ? undefined : tileItem

		// This MouseArea will spam "QQuickItem::ungrabMouse(): Item is not the mouse grabber."
		// but there's no other way of having a clickable drag area.
			onClicked: function(mouse) {
			mouse.accepted = true
			tileGrid.resetDrag()
			if (mouse.button == Qt.LeftButton) {
				if (tileEditorView && tileEditorView.tile) {
					openTileEditor()
				} else if (modelData.url) {
					var favoriteId = modelData.favoriteId || modelData.url
					var launchUrl = modelData.launchUrl || modelData.url
					var ran = appsModel.tileGridModel.runApp(favoriteId)
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
			border.color: "#80ffffff"
			y: modelData.h * cellBoxSize
			z: 100
			width: appObj.groupRect.w * cellBoxSize
			height: appObj.groupRect.h * cellBoxSize
			radius: tileItemView.cornerRadius
		}
	}

	AppContextMenu {
		id: contextMenu
		tileIndex: index
		onPopulateMenu: function(menu) {
			if (!plasmoid.configuration.tilesLocked) {
				menu.addPinToMenuAction(modelData.url)

				if (modelData.tileType == "group") {
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
			}
		}
	}

	function openTileEditor() {
		tileGrid.editTile(tileGrid.tileModel[index])
	}
	function closeTileEditor() {

	}
}
