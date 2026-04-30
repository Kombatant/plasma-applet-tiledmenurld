import QtQuick
import QtQuick.Layouts
import QtQuick.Window
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
	readonly property bool _surfaceBorderVisible: !plasmoid.configuration.sidebarHideBorder
	readonly property real _surfaceBorderWidth: _surfaceBorderVisible ? Math.max(1, Math.round(Screen.devicePixelRatio)) : 0

	Connections {
		target: typeof tileGrid !== "undefined" ? tileGrid : null
		function onTileModelChanged() {
			heroView._modelToken = heroView._modelToken + 1
		}
	}

	property int currentIndex: 0
	property bool useLoaderA: true
	property int _pageSlideDirection: 1
	property bool _pageLayersInitialized: false

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
		_pageSlideDirection = 1
		currentIndex = (currentIndex + 1) % effectivePages.length
	}
	function prev() {
		if (effectivePages.length < 2) return
		_pageSlideDirection = -1
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

	function _assignPage(loader, page) {
		if (!loader) {
			return
		}
		loader.pageData = page
		if (loader.item) {
			loader.item.page = page
		}
	}

	function _activePageItem() {
		var activeLoader = useLoaderA ? loaderA : loaderB
		return activeLoader && activeLoader.item ? activeLoader.item : null
	}

	function containsPlayButton(x, y) {
		var activePage = _activePageItem()
		if (!activePage || !activePage.playButtonVisible || !activePage.playButtonItem) {
			return false
		}
		var origin = activePage.playButtonItem.mapToItem(heroView, 0, 0)
		return x >= origin.x && x <= origin.x + activePage.playButtonItem.width
			&& y >= origin.y && y <= origin.y + activePage.playButtonItem.height
	}

	function _commitCurrent() {
		var active = useLoaderA ? loaderA : loaderB
		var incoming = useLoaderA ? loaderB : loaderA

		pageSlideAnim.stop()
		_assignPage(incoming, currentSub)

		if (!currentSub || effectivePages.length <= 1 || heroView.width <= 0 || !heroView._pageLayersInitialized) {
			heroView._assignPage(active, currentSub)
			active.x = 0
			active.opacity = currentSub ? 1 : 0
			incoming.x = 0
			incoming.opacity = 0
			heroView._pageLayersInitialized = true
			return
		}

		active.x = 0
		active.opacity = 1
		incoming.x = heroView.width * heroView._pageSlideDirection
		incoming.opacity = 0
		useLoaderA = !useLoaderA

		pageSlideOutX.target = active
		pageSlideOutX.from = 0
		pageSlideOutX.to = -heroView.width * heroView._pageSlideDirection
		pageSlideOutOpacity.target = active
		pageSlideOutOpacity.from = 1
		pageSlideOutOpacity.to = 0
		pageSlideInX.target = incoming
		pageSlideInX.from = heroView.width * heroView._pageSlideDirection
		pageSlideInX.to = 0
		pageSlideInOpacity.target = incoming
		pageSlideInOpacity.from = 0
		pageSlideInOpacity.to = 1
		pageSlideAnim.start()
		heroView._pageLayersInitialized = true
	}

	Connections {
		target: heroView
		function onCurrentSubChanged() { heroView._commitCurrent() }
	}
	Component.onCompleted: {
		heroView._assignPage(loaderA, heroView.currentSub)
		loaderA.x = 0
		loaderA.opacity = heroView.currentSub ? 1 : 0
		loaderB.x = 0
		loaderB.opacity = 0
		heroView._pageLayersInitialized = true
	}

	SidebarGlassCard {
		id: surfaceCard
		anchors.fill: parent
		radius: heroView.cornerRadius
		contentMargins: 0
	}

	Item {
		id: contentLayer
		anchors.fill: parent
		clip: true

	// Two page layers animated with the same slide semantics as docked tab transitions.
	Component {
		id: pageComponent
		Item {
			id: pageRoot
			property var page: null
			property alias playButtonItem: playButtonFrame
			readonly property bool playButtonVisible: playButtonFrame.visible
			anchors.fill: parent

			readonly property string bgSource: page && page.backgroundImage ? ("" + page.backgroundImage) : ""
			readonly property string iconName: page && page.iconName ? ("" + page.iconName) : ""
			readonly property bool useAnimated: heroView._isAnimated(bgSource)
			readonly property bool showDownloadedInfo: !!(page && page.showDownloadedInfo)
			readonly property string titleText: page ? ("" + (page.label || page.storeTitle || "")).trim() : ""
			readonly property string descriptionText: (showDownloadedInfo && page) ? ("" + (page.storeDescription || "")).trim() : ""
			readonly property var tags: showDownloadedInfo ? heroView._normalizedStringList(page ? page.igdbTags : []) : []
			readonly property string launchUrl: page ? ("" + (page.launchUrl || "")).trim() : ""
			readonly property bool canLaunch: !!launchUrl
			readonly property bool hasOverlayContent: canLaunch || !!titleText || !!descriptionText || tags.length > 0

			Rectangle {
				anchors.fill: parent
				radius: heroView.cornerRadius
				gradient: Gradient {
					GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6) }
					GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.6, Kirigami.Theme.backgroundColor.g * 0.6, Kirigami.Theme.backgroundColor.b * 0.6, 0.85) }
				}
			}

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

			Rectangle {
				anchors.fill: parent
				radius: heroView.cornerRadius
				visible: !!pageRoot.titleText
				gradient: Gradient {
					GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.04) }
					GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.1) }
					GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, pageRoot.showDownloadedInfo ? 0.64 : 0.5) }
				}
			}

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
				visible: !!pageRoot.page && pageRoot.hasOverlayContent
				opacity: visible ? 1 : 0
				Behavior on opacity { NumberAnimation { duration: 350 } }

				Column {
					id: infoColumn
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					spacing: heroView._heroContentRowSpacing

					PlasmaComponents3.Label {
						visible: !!pageRoot.titleText
						anchors.left: parent.left
						anchors.right: parent.right
						text: pageRoot.titleText
						color: "white"
						font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.6
						font.bold: true
						elide: Text.ElideRight
						wrapMode: Text.NoWrap
						style: Text.Outline
						styleColor: Qt.rgba(0, 0, 0, 0.85)
					}

					PlasmaComponents3.Label {
						visible: !!pageRoot.descriptionText
						anchors.left: parent.left
						anchors.right: parent.right
						text: pageRoot.descriptionText
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
						visible: pageRoot.tags.length > 0
						width: parent.width
						height: Math.max(0, tagChipRow.childrenRect.height)
						clip: true

						Row {
							id: tagChipRow
							height: childrenRect.height
							spacing: heroView._tagChipSpacing

							Repeater {
								model: pageRoot.tags.length
								delegate: Rectangle {
									readonly property string tagText: (pageRoot.tags[index] || "")
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
						visible: pageRoot.canLaunch
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
		}
	}

	Loader {
		id: loaderA
		y: 0
		width: parent ? parent.width : 0
		height: parent ? parent.height : 0
		property var pageData: null
		sourceComponent: pageComponent
		onLoaded: if (item) item.page = pageData
	}
	Loader {
		id: loaderB
		y: 0
		width: parent ? parent.width : 0
		height: parent ? parent.height : 0
		property var pageData: null
		sourceComponent: pageComponent
		onLoaded: if (item) item.page = pageData
	}

	ParallelAnimation {
		id: pageSlideAnim
		NumberAnimation {
			id: pageSlideInX
			property: "x"
			duration: 280
			easing.type: Easing.OutCubic
		}
		NumberAnimation {
			id: pageSlideOutX
			property: "x"
			duration: 280
			easing.type: Easing.OutCubic
		}
		NumberAnimation {
			id: pageSlideInOpacity
			property: "opacity"
			duration: 180
		}
		NumberAnimation {
			id: pageSlideOutOpacity
			property: "opacity"
			duration: 180
		}
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
				readonly property bool active: index === heroView.currentIndex
				width: active ? 20 : 8
				height: 8
				radius: 4
				color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.5)
				border.color: Qt.rgba(0, 0, 0, 0.4)
				border.width: 1
				Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
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
		antialiasing: true
		smooth: true
		layer.enabled: true
		layer.smooth: true
	}

	ShaderEffectSource {
		id: roundedMaskSource
		sourceItem: roundedMask
		recursive: true
		live: true
		hideSource: true
		smooth: true
	}

	ShaderEffectSource {
		id: contentSource
		sourceItem: contentLayer
		recursive: true
		live: true
		hideSource: true
		smooth: true
	}

	MultiEffect {
		anchors.fill: parent
		source: contentSource
		maskEnabled: true
		maskSource: roundedMaskSource
		antialiasing: true
		smooth: true
	}

	Rectangle {
		anchors.fill: parent
		radius: heroView.cornerRadius
		color: "transparent"
		visible: heroView._surfaceBorderVisible
		border.width: heroView._surfaceBorderWidth
		border.color: surfaceCard.rimColor
	}

	Rectangle {
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.leftMargin: heroView.cornerRadius
		anchors.rightMargin: heroView.cornerRadius
		visible: surfaceCard.useFrostedSurface && heroView._surfaceBorderVisible
		height: heroView._surfaceBorderWidth
		color: surfaceCard.bottomRimColor
		opacity: 0.55
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
