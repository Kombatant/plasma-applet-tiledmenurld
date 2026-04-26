import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "Utils.js" as Utils

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
	function _normalizedStringList(value) {
		var out = []

		function pushItem(item) {
			var text = ("" + (item || "")).trim()
			if (text) {
				out.push(text)
			}
		}

		if (!value) {
			return out
		}

		if (Array.isArray(value)) {
			for (var i = 0; i < value.length; i++) {
				pushItem(value[i])
			}
			return out
		}

		if (typeof value === "object" && typeof value.length === "number") {
			for (var j = 0; j < value.length; j++) {
				pushItem(value[j])
			}
			return out
		}

		if (typeof value === "string") {
			var text = value.trim()
			if (!text) {
				return out
			}
			var parts = text.split(/\s*,\s*/)
			for (var k = 0; k < parts.length; k++) {
				pushItem(parts[k])
			}
			return out
		}

		pushItem(value)
		return out
	}
	readonly property real _tagChipSpacing: Kirigami.Units.smallSpacing
	readonly property real _tagChipPaddingX: Kirigami.Units.smallSpacing * 1.5
	readonly property real _tagChipPaddingY: Math.max(2, Math.round(Kirigami.Units.smallSpacing * 0.5))
	readonly property real _heroNavHitSize: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
	readonly property real _heroContentSideMargin: Kirigami.Units.largeSpacing + ((effectivePages && effectivePages.length > 1) ? (_heroNavHitSize + Kirigami.Units.smallSpacing) : 0)
	readonly property real _heroContentRowSpacing: Kirigami.Units.smallSpacing * 1.5

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
	readonly property bool showDownloadedInfo: !!(currentSub && currentSub.showDownloadedInfo)
	readonly property string currentTitleText: currentSub ? ("" + (currentSub.label || currentSub.storeTitle || "")).trim() : ""
	readonly property string currentDescriptionText: (showDownloadedInfo && currentSub) ? ("" + (currentSub.storeDescription || "")).trim() : ""
	readonly property var currentTags: showDownloadedInfo ? _normalizedStringList(currentSub ? currentSub.igdbTags : []) : []
	readonly property string currentLaunchUrl: currentSub ? ("" + (currentSub.launchUrl || "")).trim() : ""
	readonly property bool canLaunchCurrentPage: !!currentLaunchUrl

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

	function launchCurrentPage() {
		if (!canLaunchCurrentPage) {
			return false
		}

		var favoriteId = Utils.kickerFavoriteId((currentSub && currentSub.favoriteId) || currentLaunchUrl)
		if (favoriteId && typeof appsModel !== "undefined" && appsModel && typeof appsModel.runTileApp === "function") {
			if (appsModel.runTileApp(favoriteId)) {
				return true
			}
		}

		try {
			return Qt.openUrlExternally(currentLaunchUrl)
		} catch (e) {
			console.warn("HeroTileView launch failed", currentLaunchUrl, e)
		}
		return false
	}

	function containsPlayButton(x, y) {
		if (!playButtonFrame.visible) {
			return false
		}
		var origin = playButtonFrame.mapToItem(heroView, 0, 0)
		return x >= origin.x && x <= origin.x + playButtonFrame.width
			&& y >= origin.y && y <= origin.y + playButtonFrame.height
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

	Rectangle {
		anchors.fill: parent
		radius: heroView.cornerRadius
		visible: !!heroView.currentTitleText
		gradient: Gradient {
			GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.04) }
			GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.1) }
			GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, heroView.showDownloadedInfo ? 0.64 : 0.5) }
		}
	}

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

	// Metadata and CTA overlay for the current page (bottom-left).
	Item {
		id: infoOverlay
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.leftMargin: heroView._heroContentSideMargin
		anchors.rightMargin: heroView._heroContentSideMargin
		anchors.topMargin: Kirigami.Units.largeSpacing
		anchors.bottomMargin: Kirigami.Units.largeSpacing * 2 + 8
		height: infoColumn.implicitHeight
		visible: !!heroView.currentSub && (heroView.canLaunchCurrentPage || !!heroView.currentTitleText || !!heroView.currentDescriptionText || heroView.currentTags.length > 0)
		opacity: visible ? 1 : 0
		Behavior on opacity { NumberAnimation { duration: 350 } }

		Column {
			id: infoColumn
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			spacing: heroView._heroContentRowSpacing

			PlasmaComponents3.Label {
				visible: !!heroView.currentTitleText
				anchors.left: parent.left
				anchors.right: parent.right
				text: heroView.currentTitleText
				color: "white"
				font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.6
				font.bold: true
				elide: Text.ElideRight
				wrapMode: Text.NoWrap
				style: Text.Outline
				styleColor: Qt.rgba(0, 0, 0, 0.85)
			}

			PlasmaComponents3.Label {
				visible: !!heroView.currentDescriptionText
				anchors.left: parent.left
				anchors.right: parent.right
				text: heroView.currentDescriptionText
				color: Qt.rgba(1, 1, 1, 0.92)
				font.pixelSize: Kirigami.Theme.smallFont.pixelSize
				maximumLineCount: 2
				wrapMode: Text.Wrap
				elide: Text.ElideRight
				style: Text.Outline
				styleColor: Qt.rgba(0, 0, 0, 0.78)
			}

			Item {
				id: tagViewport
				visible: heroView.currentTags.length > 0
				width: parent.width
				height: Math.max(0, tagChipRow.childrenRect.height)
				clip: true

				Row {
					id: tagChipRow
					height: childrenRect.height
					spacing: heroView._tagChipSpacing

					Repeater {
						model: heroView.currentTags.length
						delegate: Rectangle {
							readonly property string tagText: (heroView.currentTags[index] || "")
							readonly property bool fitsWidth: (x + width) <= tagViewport.width
							radius: Math.round(height / 2)
							color: Qt.rgba(0, 0, 0, 0.36)
							border.color: Qt.rgba(1, 1, 1, 0.12)
							border.width: 1
							height: chipLabel.implicitHeight + heroView._tagChipPaddingY * 2
							width: chipLabel.implicitWidth + heroView._tagChipPaddingX * 2
							implicitHeight: height
							implicitWidth: width
							opacity: fitsWidth ? 1 : 0

							PlasmaComponents3.Label {
								id: chipLabel
								anchors.centerIn: parent
								text: parent.tagText
								color: Qt.rgba(1, 1, 1, 0.92)
								font.pixelSize: Kirigami.Theme.smallFont.pixelSize
								wrapMode: Text.NoWrap
								elide: Text.ElideNone
								maximumLineCount: 1
								style: Text.Outline
								styleColor: Qt.rgba(0, 0, 0, 0.62)
							}
						}
					}
				}
			}

			Item {
				id: playButtonFrame
				visible: heroView.canLaunchCurrentPage
				width: playButtonBackground.implicitWidth
				height: playButtonBackground.implicitHeight

				Rectangle {
					id: playButtonShadow
					anchors.fill: playButtonBackground
					anchors.topMargin: 2
					radius: playButtonBackground.radius
					color: Qt.rgba(0, 0, 0, 0.28)
				}

				Rectangle {
					id: playButtonBackground
					anchors.fill: parent
					implicitWidth: Math.max(Kirigami.Units.gridUnit * 4.75, playButtonLabel.implicitWidth + Kirigami.Units.largeSpacing * 1.6)
					implicitHeight: playButtonLabel.implicitHeight + Kirigami.Units.smallSpacing * 2.2
					radius: Math.round(height / 4)
					border.width: 1
					border.color: Qt.rgba(1, 1, 1, 0.18)
					gradient: Gradient {
						GradientStop { position: 0.0; color: Qt.rgba(0.18, 0.58, 0.95, 0.98) }
						GradientStop { position: 1.0; color: Qt.rgba(0.11, 0.42, 0.88, 0.98) }
					}

					PlasmaComponents3.Label {
						id: playButtonLabel
						anchors.centerIn: parent
						text: i18n("Launch")
						color: "white"
						font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
						font.bold: true
						style: Text.Outline
						styleColor: Qt.rgba(0, 0, 0, 0.24)
					}
				}
			}
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

	// Hint chevrons on hover. Click handling is mapped in TileItem to these visual controls.
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
