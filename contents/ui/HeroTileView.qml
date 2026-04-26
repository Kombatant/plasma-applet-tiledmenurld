import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
	id: heroView
	clip: false

	property real cornerRadius: 0
	property int _modelToken: 0

	readonly property color _surfaceBaseColor: (typeof config !== "undefined" && config) ? config.surfaceBaseColor : Kirigami.Theme.backgroundColor
	readonly property bool _surfaceFrosted: (typeof config !== "undefined" && config) ? config.surfaceUsesFrostedGlass : false
	readonly property real _surfaceShadowSizeMul: (typeof config !== "undefined" && config) ? config.surfaceShadowSizeMultiplier : 1.0
	readonly property real _surfaceShadowOpacityMul: (typeof config !== "undefined" && config) ? config.surfaceShadowOpacityMultiplier : 1.0
	function _relLuma(c) {
		function ch(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
		return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
	}
	readonly property bool _baseIsLight: _relLuma(_surfaceBaseColor) > 0.6
	readonly property color _rimColor: _surfaceFrosted
		? (_baseIsLight ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(1, 1, 1, 0.18))
		: (_baseIsLight ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(1, 1, 1, 0.18))
	readonly property real _baseShadowOpacity: _baseIsLight ? (_surfaceFrosted ? 0.19 : 0.13) : (_surfaceFrosted ? 0.18 : 0.32)
	readonly property int _shadowSize: Math.round(Kirigami.Units.gridUnit * (_surfaceFrosted ? 1.1 : 1.25) * _surfaceShadowSizeMul)
	readonly property color _shadowColor: Qt.rgba(0, 0, 0, Math.min(1, _baseShadowOpacity * _surfaceShadowOpacityMul))
	readonly property int _shadowYOffset: Math.round(2 * Screen.devicePixelRatio)
	readonly property int _rimWidth: plasmoid.configuration.sidebarHideBorder ? 0 : Math.max(1, Math.round(Screen.devicePixelRatio))
	property var subTiles: (_modelToken >= 0 && appObj && appObj.tile && appObj.tile.subTiles) ? appObj.tile.subTiles : []
	property bool autoScrollEnabled: _modelToken >= 0 && !!(appObj && appObj.tile && appObj.tile.autoScrollEnabled)
	property int autoScrollInterval: (_modelToken >= 0 && appObj && appObj.tile && appObj.tile.autoScrollInterval) ? appObj.tile.autoScrollInterval : 5000
	property bool hovered: false

	Connections {
		target: typeof tileGrid !== "undefined" ? tileGrid : null
		function onTileModelChanged() {
			heroView._modelToken = heroView._modelToken + 1
		}
	}

	property int currentIndex: 0
	property bool useLoaderA: true

	readonly property var effectivePages: {
		var arr = []
		var src = subTiles || []
		for (var i = 0; i < src.length; i++) {
			var p = src[i]
			if (!p) continue
			if (p.backgroundImage || p.iconName) {
				arr.push(p)
			}
		}
		return arr
	}
	readonly property var currentSub: (effectivePages && effectivePages.length > 0 && currentIndex >= 0 && currentIndex < effectivePages.length) ? effectivePages[currentIndex] : null
	readonly property var nextSub: (effectivePages && effectivePages.length > 1) ? effectivePages[(currentIndex + 1) % effectivePages.length] : null

	readonly property bool effectiveExpanded: {
		if (typeof widget !== "undefined" && widget && typeof widget.expanded !== "undefined") {
			return !!widget.expanded
		}
		if (plasmoid && typeof plasmoid.expanded !== "undefined") {
			return !!plasmoid.expanded
		}
		return true
	}

	onSubTilesChanged: {
		var pages = effectivePages || []
		if (currentIndex >= pages.length) {
			currentIndex = 0
		}
	}

	function _fileExtFromUrl(url) {
		if (!url) return ""
		var s = ("" + url).toLowerCase()
		var q = s.indexOf("?"); if (q >= 0) s = s.substring(0, q)
		var h = s.indexOf("#"); if (h >= 0) s = s.substring(0, h)
		var dot = s.lastIndexOf(".")
		if (dot < 0 || dot === s.length - 1) return ""
		return s.substring(dot + 1)
	}
	function _isAnimated(src) {
		var ext = _fileExtFromUrl(src)
		return ext === "gif" || ext === "apng" || ext === "webp"
	}

	function next() {
		if (effectivePages.length < 2) return
		currentIndex = (currentIndex + 1) % effectivePages.length
	}
	function prev() {
		if (effectivePages.length < 2) return
		currentIndex = (currentIndex - 1 + effectivePages.length) % effectivePages.length
	}

	function _commitCurrent() {
		var inactive = useLoaderA ? loaderB : loaderA
		if (inactive.item) {
			inactive.item.page = currentSub
		}
		useLoaderA = !useLoaderA
	}

	Connections {
		target: heroView
		function onCurrentSubChanged() { heroView._commitCurrent() }
	}
	Component.onCompleted: {
		if (loaderA.item) loaderA.item.page = heroView.currentSub
	}

	Kirigami.ShadowedRectangle {
		id: surfaceShadow
		anchors.fill: parent
		color: "transparent"
		radius: heroView.cornerRadius
		shadow {
			size: heroView._shadowSize
			color: heroView._shadowColor
			yOffset: heroView._shadowYOffset
		}
	}

	Item {
		id: contentLayer
		anchors.fill: parent

	// Themed backdrop for icon-only or empty pages.
	Rectangle {
		anchors.fill: parent
		radius: heroView.cornerRadius
		gradient: Gradient {
			GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6) }
			GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.6, Kirigami.Theme.backgroundColor.g * 0.6, Kirigami.Theme.backgroundColor.b * 0.6, 0.85) }
		}
	}

	// Two crossfade page layers.
	Component {
		id: pageComponent
		Item {
			id: pageRoot
			property var page: null
			anchors.fill: parent

			readonly property string bgSource: page && page.backgroundImage ? ("" + page.backgroundImage) : ""
			readonly property string iconName: page && page.iconName ? ("" + page.iconName) : ""
			readonly property bool useAnimated: heroView._isAnimated(bgSource)

			Loader {
				anchors.fill: parent
				active: pageRoot.useAnimated && !!pageRoot.bgSource && heroView.effectiveExpanded
				sourceComponent: AnimatedImage {
					source: pageRoot.bgSource
					fillMode: Image.PreserveAspectCrop
					asynchronous: true
					cache: false
					playing: true
				}
			}
			Image {
				anchors.fill: parent
				visible: !pageRoot.useAnimated && !!pageRoot.bgSource
				source: pageRoot.useAnimated ? "" : pageRoot.bgSource
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				cache: true
			}
			Kirigami.Icon {
				anchors.centerIn: parent
				width: Math.min(parent.width, parent.height) * 0.45
				height: width
				visible: !pageRoot.bgSource && !!pageRoot.iconName
				source: pageRoot.iconName
			}
		}
	}

	Loader {
		id: loaderA
		anchors.fill: parent
		sourceComponent: pageComponent
		opacity: heroView.useLoaderA ? 1 : 0
		Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }
		onLoaded: if (item) item.page = heroView.currentSub
	}
	Loader {
		id: loaderB
		anchors.fill: parent
		sourceComponent: pageComponent
		opacity: heroView.useLoaderA ? 0 : 1
		Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }
	}

	// Empty-state hint.
	ColumnLayout {
		anchors.centerIn: parent
		visible: heroView.effectivePages.length === 0
		spacing: Kirigami.Units.smallSpacing
		Kirigami.Icon {
			Layout.alignment: Qt.AlignHCenter
			Layout.preferredWidth: Kirigami.Units.iconSizes.huge
			Layout.preferredHeight: Kirigami.Units.iconSizes.huge
			source: "view-presentation"
			opacity: 0.6
		}
		PlasmaComponents3.Label {
			Layout.alignment: Qt.AlignHCenter
			Layout.maximumWidth: heroView.width - Kirigami.Units.largeSpacing * 2
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.Wrap
			opacity: 0.8
			text: i18n("Hero Tile — right-click → Edit, or drop an app here to add a page")
		}
	}

	// Label overlay for the current page (bottom-left).
	Item {
		id: labelOverlay
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: Kirigami.Units.largeSpacing
		anchors.bottomMargin: Kirigami.Units.largeSpacing * 2 + 8 // leave room for indicator
		height: pageLabel.implicitHeight
		visible: !!heroView.currentSub && !!heroView.currentSub.label
		opacity: visible ? 1 : 0
		Behavior on opacity { NumberAnimation { duration: 350 } }

		PlasmaComponents3.Label {
			id: pageLabel
			anchors.left: parent.left
			anchors.right: parent.right
			text: heroView.currentSub ? ("" + (heroView.currentSub.label || "")) : ""
			color: "white"
			font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.6
			font.bold: true
			elide: Text.ElideRight
			wrapMode: Text.NoWrap
			style: Text.Outline
			styleColor: Qt.rgba(0, 0, 0, 0.85)
		}
	}

	// Page indicator dots.
	Row {
		id: pageIndicator
		anchors.bottom: parent.bottom
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.bottomMargin: Kirigami.Units.largeSpacing
		spacing: Kirigami.Units.smallSpacing
		visible: heroView.effectivePages.length > 1
		Repeater {
			model: heroView.effectivePages.length
			Rectangle {
				width: 8
				height: 8
				radius: 4
				color: index === heroView.currentIndex ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.5)
				border.color: Qt.rgba(0, 0, 0, 0.4)
				border.width: 1
			}
		}
	}

	// Hint chevrons on hover (visual only — clicks go through TileItem's edge-hit zones).
	Kirigami.Icon {
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		anchors.leftMargin: Kirigami.Units.smallSpacing
		width: Kirigami.Units.iconSizes.medium
		height: width
		source: "go-previous"
		visible: heroView.hovered && heroView.effectivePages.length > 1
		opacity: visible ? 0.85 : 0
		Behavior on opacity { NumberAnimation { duration: 200 } }
	}
	Kirigami.Icon {
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		anchors.rightMargin: Kirigami.Units.smallSpacing
		width: Kirigami.Units.iconSizes.medium
		height: width
		source: "go-next"
		visible: heroView.hovered && heroView.effectivePages.length > 1
		opacity: visible ? 0.85 : 0
		Behavior on opacity { NumberAnimation { duration: 200 } }
	}

	} // contentLayer

	Rectangle {
		id: roundedMask
		anchors.fill: parent
		radius: heroView.cornerRadius
		color: "white"
		visible: false
		layer.enabled: true
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

	Rectangle {
		anchors.fill: parent
		radius: heroView.cornerRadius
		color: "transparent"
		border.width: heroView._rimWidth
		border.color: heroView._rimColor
		visible: heroView._rimWidth > 0
	}

	Timer {
		id: autoScrollTimer
		interval: heroView.autoScrollInterval
		repeat: true
		readonly property bool _editing: (typeof config !== "undefined" && config) ? !!config.isEditingTile : false
		running: heroView.autoScrollEnabled && !heroView.hovered && heroView.effectivePages.length > 1 && heroView.effectiveExpanded && !_editing
		onTriggered: heroView.next()
	}
}
