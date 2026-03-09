import QtQuick
import QtQuick.Effects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Rectangle {
	id: tileItemView
	color: appObj.backgroundColor
	radius: cornerRadius
	readonly property real cornerRadius: (config && config.tileCornerRadius ? config.tileCornerRadius : 0)
	property color gradientBottomColor: Qt.darker(appObj.backgroundColor, 2.0)

	// Holographic hover effect properties (disabled for group tiles — the small header rectangle looks wrong with sweep/glow)
	readonly property bool useHolographicEffect: !appObj.isGroup && plasmoid && plasmoid.configuration && plasmoid.configuration.tileHoverEffect === "holographic"
	readonly property color holographicColor: "#00ffff" // Cyan
	readonly property real holographicGlowOpacity: 0.5
	scale: (useHolographicEffect && hovered) ? 1.05 : 1.0
	Behavior on scale {
		NumberAnimation {
			duration: 300
			easing.type: Easing.OutCubic
		}
	}

	// Glow effect layer (box-shadow emulation) - only for holographic effect
	layer.enabled: useHolographicEffect && hovered
	layer.effect: MultiEffect {
		autoPaddingEnabled: true
		shadowEnabled: true
		shadowHorizontalOffset: 0
		shadowVerticalOffset: 0
		shadowBlur: 1.0
		shadowOpacity: tileItemView.holographicGlowOpacity
		shadowColor: tileItemView.holographicColor
	}

	function _fileExtFromUrl(url) {
		if (!url) {
			return ""
		}
		var s = ("" + url).toLowerCase()
		// Strip query/fragment to make extension detection more reliable.
		var q = s.indexOf("?")
		if (q >= 0) {
			s = s.substring(0, q)
		}
		var h = s.indexOf("#")
		if (h >= 0) {
			s = s.substring(0, h)
		}
		// For file URLs, keep the path portion; extension logic works either way.
		var dot = s.lastIndexOf(".")
		if (dot < 0 || dot === s.length - 1) {
			return ""
		}
		return s.substring(dot + 1)
	}

	// Clear image sources when the plasmoid is closed to release cached frames/textures.
	// Use a short delay to avoid thrash when toggling quickly.
	property bool expandedActive: true
	readonly property string activeBackgroundSource: expandedActive ? appObj.backgroundImage : ""
	property int animatedReloadToken: 0
	readonly property string animatedBackgroundSource: activeBackgroundSource ? (activeBackgroundSource + "#reload=" + animatedReloadToken) : ""
	readonly property bool backgroundIsAnimated: {
		var ext = _fileExtFromUrl(activeBackgroundSource)
		return ext === "gif" || ext === "apng" || ext === "webp"
	}
	// When the animated renderer is created via the Loader, check its status
	readonly property bool backgroundAnimatedLoadFailed: backgroundIsAnimated && (animatedLoader.item ? animatedLoader.item.status === Image.Error : false)
	readonly property bool backgroundUseAnimatedRenderer: backgroundIsAnimated && !backgroundAnimatedLoadFailed
	readonly property bool animatedPlayOnHoverEnabled: {
		if (plasmoid && plasmoid.configuration && typeof plasmoid.configuration.tileAnimatedPlayOnHover !== 'undefined') {
			return !!plasmoid.configuration.tileAnimatedPlayOnHover
		}
		return true
	}

	function bumpAnimatedReload() {
		if (!backgroundIsAnimated || !activeBackgroundSource) {
			return
		}
		animatedReloadToken = (animatedReloadToken + 1) % 1000000
	}

	Component {
		id: tileGradient
		Gradient {
			GradientStop { position: 0.0; color: appObj.backgroundColor }
			GradientStop { position: 1.0; color: tileItemView.gradientBottomColor }
		}
	}
	gradient: appObj.backgroundGradient ? tileGradient.createObject(tileItemView) : null

	readonly property real tilePadding: 4 * Screen.devicePixelRatio
	readonly property real iconBaseSize: (plasmoid && plasmoid.configuration && plasmoid.configuration.tileIconSize ? plasmoid.configuration.tileIconSize : 72) * Screen.devicePixelRatio
	readonly property real smallIconSize: Math.max(16 * Screen.devicePixelRatio, Math.round(iconBaseSize * 0.45))
	readonly property real mediumIconSize: Math.max(16 * Screen.devicePixelRatio, Math.round(iconBaseSize))
	readonly property real largeIconSize: Math.max(16 * Screen.devicePixelRatio, Math.round(iconBaseSize * 1.33))

	readonly property int labelAlignment: appObj.isGroup ? config.groupLabelAlignment : config.tileLabelAlignment
	readonly property bool labelBelowIcon: !(modelData.w >= 2 && modelData.h == 1)
	// Wide single-row non-group tiles show inline label (icon in first cell, label in remaining cells)
	readonly property bool useInlineLabel: !appObj.isGroup && modelData.w >= 2 && modelData.h == 1 && appObj.showLabel

	property bool hovered: false

	states: [
		State {
			when: modelData.w == 1 && modelData.h >= 1
			PropertyChanges { target: icon; size: smallIconSize }
			PropertyChanges { target: label; visible: false }
		},
		State {
			// Wide single-row non-group tile with label: icon in first cell, label in remaining cells
			when: useInlineLabel
			AnchorChanges { target: icon
				anchors.horizontalCenter: undefined
				anchors.left: contentLayer.left
			}
			PropertyChanges { target: icon
				anchors.leftMargin: tilePadding
				size: Math.min(tileItemView.height, cellBoxSize) - tilePadding * 2
			}
			PropertyChanges { target: label
				visible: true
				verticalAlignment: Text.AlignVCenter
				horizontalAlignment: Text.AlignLeft
			}
			AnchorChanges { target: label
				anchors.left: inlineLabelAnchor.right
			}
		},
		State {
			// Wide single-row tile without label (or group tile)
			when: modelData.w >= 2 && modelData.h == 1 && !useInlineLabel
			AnchorChanges { target: icon
				anchors.horizontalCenter: undefined
				anchors.left: contentLayer.left
			}
			PropertyChanges { target: icon; anchors.leftMargin: tilePadding }
			PropertyChanges { target: label
				verticalAlignment: Text.AlignVCenter
			}
			AnchorChanges { target: label
				anchors.left: icon.right
			}
		},
		State {
			when: (modelData.w >= 2 && modelData.h == 2) || (modelData.w == 2 && modelData.h >= 2)
			PropertyChanges { target: icon; size: mediumIconSize }
		},
		State {
			when: modelData.w >= 3 && modelData.h >= 3
			PropertyChanges { target: icon; size: largeIconSize }
		}
	]

	Item {
		id: contentLayer
		anchors.fill: parent

		Component {
			id: animatedBackgroundComponent
			AnimatedImage {
				id: backgroundAnimatedImage
				anchors.fill: parent
				source: animatedBackgroundSource
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				cache: false
				playing: (tileItemView.animatedPlayOnHoverEnabled ? hovered : true)
			}
		}

		Loader {
			id: animatedLoader
			anchors.fill: parent
			// Only load the animated renderer when we actually want it running.
			// If `tileAnimatedPlayOnHover` is enabled, create the AnimatedImage only while hovered
			// so the instance is destroyed (and memory released) when hover ends.
			// Also unload when the plasmoid is closed so decoded frames are released.
			readonly property bool plasmoidExpanded: (plasmoid && typeof plasmoid.expanded !== "undefined") ? plasmoid.expanded : true
			active: tileItemView.backgroundUseAnimatedRenderer
				&& !!activeBackgroundSource
				&& plasmoidExpanded
				&& (tileItemView.animatedPlayOnHoverEnabled ? tileItemView.hovered : true)
			sourceComponent: animatedBackgroundComponent
		}

		Image {
			id: backgroundImage
			anchors.fill: parent
			// Show a static fallback (first frame) whenever there's a background image
			// but the animated renderer is not active, or the animated load failed.
			visible: !!activeBackgroundSource && (
				!tileItemView.backgroundIsAnimated || tileItemView.backgroundAnimatedLoadFailed || !animatedLoader.active
			)
			source: activeBackgroundSource
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			cache: false
		}

		Timer {
			id: unloadDelayTimer
			interval: 250
			repeat: false
			onTriggered: tileItemView.expandedActive = false
		}

		Connections {
			target: plasmoid
			ignoreUnknownSignals: true
			function onExpandedChanged() {
				if (plasmoid.expanded) {
					unloadDelayTimer.stop()
					tileItemView.expandedActive = true
					tileItemView.bumpAnimatedReload()
				} else {
					unloadDelayTimer.restart()
				}
			}
		}

		Connections {
			target: Qt.application
			function onStateChanged(state) {
				if (state === Qt.ApplicationActive) {
					tileItemView.bumpAnimatedReload()
				}
			}
		}

		Kirigami.Icon {
			id: icon
			visible: appObj.showIcon
			source: appObj.iconSource
			anchors.verticalCenter: parent.verticalCenter
			anchors.horizontalCenter: parent.horizontalCenter
			property int size: Math.min(parent.width, parent.height) / 2
			width: appObj.showIcon ? size : 0
			height: appObj.showIcon ? size : 0
			anchors.fill: appObj.iconFill ? parent : null
			smooth: appObj.iconFill
		}

		// Invisible anchor item for inline label positioning (marks end of first cell)
		Item {
			id: inlineLabelAnchor
			visible: false
			width: 0
			height: parent.height
			x: cellBoxSize - cellMargin - tilePadding
			anchors.verticalCenter: parent.verticalCenter
		}

		PlasmaComponents3.Label {
			id: label
			visible: false // Label is rendered outside the tile (below) in TileItem.qml
			text: appObj.labelText
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.leftMargin: tilePadding
			anchors.rightMargin: tilePadding
			anchors.left: parent.left
			anchors.right: parent.right
			wrapMode: Text.Wrap
			horizontalAlignment: labelBelowIcon ? Text.AlignHCenter : labelAlignment
			verticalAlignment: Text.AlignBottom
			width: parent.width
			renderType: Text.QtRendering // Fix pixelation when scaling. Plasma.Label uses NativeRendering.
			style: Text.Outline
			styleColor: appObj.backgroundGradient ? tileItemView.gradientBottomColor : appObj.backgroundColor
		}

		// Holographic sweep overlay effect
		Item {
			id: holographicSweep
			anchors.fill: parent
			clip: true
			visible: tileItemView.useHolographicEffect
			opacity: (tileItemView.useHolographicEffect && tileItemView.hovered) ? 1 : 0
			Behavior on opacity {
				NumberAnimation {
					duration: 300
					easing.type: Easing.OutCubic
				}
			}

			Rectangle {
				id: sweepGradient
				width: parent.width * 2
				height: parent.height * 2
				x: tileItemView.hovered ? parent.width : -width
				y: -parent.height * 0.5
				rotation: -45
				transformOrigin: Item.Center
				opacity: 0.3
				gradient: Gradient {
					orientation: Gradient.Vertical
					GradientStop { position: 0.0; color: "transparent" }
					GradientStop { position: 0.3; color: "transparent" }
					GradientStop { position: 0.5; color: tileItemView.holographicColor }
					GradientStop { position: 0.7; color: "transparent" }
					GradientStop { position: 1.0; color: "transparent" }
				}

				Behavior on x {
					NumberAnimation {
						duration: 500
						easing.type: Easing.OutCubic
					}
				}
			}
		}
	}

	Rectangle {
		id: roundedMask
		anchors.fill: parent
		radius: tileItemView.cornerRadius
		color: "white"
	}

	ShaderEffectSource {
		id: roundedMaskSource
		sourceItem: roundedMask
		recursive: true
		live: true
		hideSource: true
	}

	ShaderEffectSource {
		id: contentSource
		sourceItem: contentLayer
		recursive: true
		live: true
		hideSource: true
	}

	MultiEffect {
		anchors.fill: parent
		source: contentSource
		maskEnabled: true
		maskSource: roundedMaskSource
	}
}
