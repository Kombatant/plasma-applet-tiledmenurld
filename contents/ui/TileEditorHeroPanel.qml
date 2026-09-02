import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "libconfig" as LibConfig

ColumnLayout {
	id: heroPanel
	Layout.fillWidth: true
	spacing: Kirigami.Units.smallSpacing

	property var appObj: null
	property var tileGrid: null

	TilePresetImageHelper {
		id: presetHelper
	}

	AppAutocompleteHelper {
		id: appAutocomplete
	}

	HeroPageMetadataFetcher {
		id: metadataFetcher
	}

	// Warm the KWallet-stored IGDB client secret as soon as the Hero editor
	// opens (only when an IGDB client id is configured, so users who never set
	// up IGDB aren't prompted for KWallet on every editor open). Without this
	// the secret stays unread, hasIgdbMetadataSettings is false, and the "Show
	// downloaded store info and tags" checkbox is permanently disabled while
	// KWallet is never prompted to unlock.
	Component.onCompleted: {
		if (metadataFetcher.igdbClientId) {
			metadataFetcher.warmSecret()
		}
	}

	function _pages() {
		if (!appObj || !appObj.tile || !Array.isArray(appObj.tile.subTiles)) return []
		return appObj.tile.subTiles
	}

	function _effectiveIndexForPage(pages, pageIndex) {
		var effectiveIndex = -1
		for (var i = 0; i < pages.length; i++) {
			var page = pages[i]
			if (!page || (!page.backgroundImage && !page.iconName)) continue
			effectiveIndex += 1
			if (i === pageIndex) return effectiveIndex
		}
		return -1
	}

	function _commit(arr, requestedHeroPageIndex) {
		if (!appObj || !appObj.tile) return
		appObj.tile.subTiles = arr
		var shouldShowEditedPage = tileGrid && typeof tileGrid.requestHeroPageIndex === "function"
			&& typeof requestedHeroPageIndex === "number" && requestedHeroPageIndex >= 0
		var editedTile = appObj.tile
		if (shouldShowEditedPage) {
			tileGrid.requestHeroPageIndex(appObj.tile, requestedHeroPageIndex)
		}
		appObj.tileChanged()
		if (tileGrid) tileGrid.tileModelChanged()
		if (shouldShowEditedPage) {
			Qt.callLater(function() {
				if (heroPanel.tileGrid && typeof heroPanel.tileGrid.showHeroPageIndex === "function") {
					heroPanel.tileGrid.showHeroPageIndex(editedTile, requestedHeroPageIndex)
				}
			})
		}
	}

	function updatePage(index, key, value) {
		var arr = _pages().slice()
		if (index < 0 || index >= arr.length) return
		var p = Object.assign({}, arr[index])
		p[key] = value
		arr[index] = p
		var requestedHeroPageIndex = key === "backgroundImage" ? _effectiveIndexForPage(arr, index) : -1
		_commit(arr, requestedHeroPageIndex)
	}

	function updatePageFields(index, values) {
		var arr = _pages().slice()
		if (index < 0 || index >= arr.length) return
		var p = Object.assign({}, arr[index])
		var keys = Object.keys(values || {})
		for (var i = 0; i < keys.length; i++) {
			p[keys[i]] = values[keys[i]]
		}
		arr[index] = p
		_commit(arr)
	}

	function refreshPageMetadata(index, delegate) {
		var page = _pages()[index]
		if (!page) {
			return
		}
		if (delegate) {
			delegate.metadataLoading = true
			delegate.metadataStatus = i18n("Downloading metadata...")
		}
		metadataFetcher.fetchForPage(page, function(success, data, message) {
			if (delegate) {
				delegate.metadataLoading = false
			}
			if (!success || !data) {
				if (delegate) {
					delegate.metadataStatus = message || i18n("Metadata download failed.")
				}
				return
			}
			heroPanel.updatePageFields(index, {
				steamAppId: data.steamAppId || "",
				storeTitle: data.storeTitle || "",
				storeDescription: data.storeDescription || "",
				igdbTags: data.igdbTags || [],
				showDownloadedInfo: true,
			})
			if (delegate) {
				delegate.metadataStatus = message || i18n("Downloaded metadata.")
			}
		})
	}

	function addPage() {
		var arr = _pages().slice()
		arr.push({
			backgroundImage: "",
			launchUrl: "",
			label: "",
			iconName: "",
			showDownloadedInfo: false,
			storeTitle: "",
			storeDescription: "",
			igdbTags: [],
			steamAppId: "",
		})
		_commit(arr)
	}

	function removePage(index) {
		var arr = _pages().slice()
		if (index < 0 || index >= arr.length) return
		arr.splice(index, 1)
		_commit(arr)
	}

	function movePage(index, delta) {
		var arr = _pages().slice()
		var target = index + delta
		if (index < 0 || index >= arr.length || target < 0 || target >= arr.length) return
		var tmp = arr[index]
		arr[index] = arr[target]
		arr[target] = tmp
		_commit(arr)
	}

	PlasmaExtras.Heading {
		level: 3
		text: i18n("Hero Carousel")
	}

	RowLayout {
		Layout.fillWidth: true
		QQC2.CheckBox {
			id: autoScrollCheck
			text: i18n("Auto-scroll")
			checked: !!(heroPanel.appObj && heroPanel.appObj.tile && heroPanel.appObj.tile.autoScrollEnabled)
			onToggled: {
				if (!heroPanel.appObj || !heroPanel.appObj.tile) return
				heroPanel.appObj.tile.autoScrollEnabled = checked
				heroPanel.appObj.tileChanged()
				if (heroPanel.tileGrid) heroPanel.tileGrid.tileModelChanged()
			}
		}
		Item { Layout.fillWidth: true }
		PlasmaComponents3.Label { text: i18n("Interval (s):") }
		QQC2.SpinBox {
			id: intervalBox
			from: 1
			to: 60
			stepSize: 1
			value: {
				var intervalMs = (heroPanel.appObj && heroPanel.appObj.tile && heroPanel.appObj.tile.autoScrollInterval)
					? heroPanel.appObj.tile.autoScrollInterval
					: 5000
				return Math.max(intervalBox.from, Math.min(intervalBox.to, Math.round(intervalMs / 1000)))
			}
			onValueModified: {
				if (!heroPanel.appObj || !heroPanel.appObj.tile) return
				heroPanel.appObj.tile.autoScrollInterval = value * 1000
				heroPanel.appObj.tileChanged()
				if (heroPanel.tileGrid) heroPanel.tileGrid.tileModelChanged()
			}
		}
	}

	PlasmaExtras.Heading {
		level: 4
		text: i18n("Pages")
	}

	property int _refreshToken: 0

	Repeater {
		id: pagesRepeater
		model: heroPanel._refreshToken >= 0 ? heroPanel._pages().length : 0

		delegate: Rectangle {
			id: pageDelegate
			Layout.fillWidth: true
			Layout.preferredHeight: rowLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
			color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
			border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
			border.width: 1
			radius: 4

			readonly property int rowIndex: index
			readonly property var page: (heroPanel._refreshToken >= 0 && heroPanel._pages()[index]) ? heroPanel._pages()[index] : ({})
			property string steamAppId: ""
			property var steamPresetSpecs: []
			property var lutrisPresetSpecs: []
			property var igdbPresetSpecs: []
			readonly property var presetSpecs: steamPresetSpecs.concat(lutrisPresetSpecs).concat(igdbPresetSpecs)
			readonly property bool canOpenPresetPicker: presetSpecs.length > 0
				|| artworkLoading
				|| (canDownloadHeroicLutrisMetadata && canAttemptIgdbMetadata && !igdbArtworkAttempted)
			readonly property bool canDownloadSteamMetadata: !!steamAppId
			property string heroicLutrisKind: ""
			property string lutrisSlug: ""
			readonly property bool canDownloadHeroicLutrisMetadata: heroicLutrisKind.length > 0
			readonly property bool canDownloadMetadata: canDownloadSteamMetadata || canDownloadHeroicLutrisMetadata
			readonly property bool hasIgdbMetadataSettings: metadataFetcher.hasIgdbMetadataSettings
			readonly property bool canAttemptIgdbMetadata: !!metadataFetcher.igdbClientId
			readonly property bool canShowDownloadedInfo: (canDownloadSteamMetadata && canAttemptIgdbMetadata) || (canDownloadHeroicLutrisMetadata && canAttemptIgdbMetadata)
			property bool steamArtworkLoading: false
			property bool igdbArtworkLoading: false
			readonly property bool artworkLoading: steamArtworkLoading || igdbArtworkLoading
			property bool igdbArtworkAttempted: false
			property int presetRequestGeneration: 0
			property string presetRequestKey: ""
			property bool metadataLoading: false
			property string metadataStatus: ""
			property bool presetPickerExpanded: false
			property bool presetSelectionSaving: false
			property string presetSelectionStatus: ""

			function _currentPresetRequestKey() {
				return ("" + (page.launchUrl || "")) + "\n" + metadataFetcher._titleForPage(page) + "\n" + metadataFetcher._steamGameIdForPage(page)
			}

			function refreshPresetSources(force) {
				var nextKey = _currentPresetRequestKey()
				if (!force && nextKey === presetRequestKey) return
				presetRequestKey = nextKey
				presetRequestGeneration += 1
				var generation = presetRequestGeneration
				steamAppId = metadataFetcher._steamGameIdForPage(page)
				steamPresetSpecs = []
				lutrisPresetSpecs = []
				igdbPresetSpecs = []
				heroicLutrisKind = ""
				lutrisSlug = ""
				steamArtworkLoading = false
				igdbArtworkLoading = false
				igdbArtworkAttempted = false
				presetSelectionStatus = ""

				if (steamAppId) {
					var requestedAppId = steamAppId
					steamArtworkLoading = true
					metadataFetcher.fetchSteamArtwork(requestedAppId, function(err, detail) {
						if (generation !== pageDelegate.presetRequestGeneration || requestedAppId !== pageDelegate.steamAppId) return
						steamArtworkLoading = false
						steamPresetSpecs = (!err && detail) ? presetHelper.presetSpecsForSteamDetail(detail) : []
					})
					maybeFetchSteamIgdbArt()
				}

				metadataFetcher.resolveHeroicLutrisInfoForPage(page, function(info) {
					if (generation !== pageDelegate.presetRequestGeneration) return
					var resolved = info || ({})
					heroicLutrisKind = resolved.kind ? ("" + resolved.kind) : ""
					lutrisSlug = resolved.lutrisSlug ? ("" + resolved.lutrisSlug) : ""
					lutrisPresetSpecs = presetHelper.presetSpecsForLutrisGameSlug(lutrisSlug)
				})
			}

			function maybeFetchSteamIgdbArt() {
				if (!steamAppId || igdbArtworkAttempted || igdbArtworkLoading || igdbPresetSpecs.length > 0) return
				if (!canAttemptIgdbMetadata) return
				var generation = presetRequestGeneration
				var requestedAppId = steamAppId
				var fallbackTitle = metadataFetcher._titleForPage(page)
				igdbArtworkAttempted = true
				igdbArtworkLoading = true
				metadataFetcher.fetchIgdbArtworksBySteamAppId(requestedAppId, fallbackTitle, function(err, detail) {
					if (generation !== pageDelegate.presetRequestGeneration || requestedAppId !== pageDelegate.steamAppId) return
					igdbArtworkLoading = false
					if (!err && detail) {
						igdbPresetSpecs = presetHelper.presetSpecsForIgdbDetail(detail)
					}
				})
			}

			function fetchHeroicLutrisIgdbArt() {
				if (!heroicLutrisKind || !canAttemptIgdbMetadata || igdbArtworkAttempted || igdbArtworkLoading) {
					return
				}
				var title = metadataFetcher._titleForPage(page)
				if (!title) {
					presetSelectionStatus = i18n("Could not determine a title for this launcher.")
					return
				}
				var generation = presetRequestGeneration
				igdbArtworkAttempted = true
				igdbArtworkLoading = true
				metadataStatus = i18n("Looking up IGDB artwork...")
				metadataFetcher.fetchIgdbArtworksByTitle(title, function(err, detail) {
					if (generation !== pageDelegate.presetRequestGeneration) return
					igdbArtworkLoading = false
					if (err || !detail) {
						metadataStatus = err || i18n("No IGDB artwork found.")
					} else {
						igdbPresetSpecs = presetHelper.presetSpecsForIgdbDetail(detail)
						metadataStatus = i18n("Downloaded IGDB artwork.")
					}
				})
			}

			function removeFailedPreset(spec) {
				if (!spec || !spec.source) return
				var failedSource = "" + spec.source
				if (spec.provider === 'steam') {
					steamPresetSpecs = steamPresetSpecs.filter(function(item) { return ("" + item.source) !== failedSource })
					maybeFetchSteamIgdbArt()
				} else if (spec.provider === 'igdb') {
					igdbPresetSpecs = igdbPresetSpecs.filter(function(item) { return ("" + item.source) !== failedSource })
				} else if (spec.provider === 'lutris') {
					lutrisPresetSpecs = lutrisPresetSpecs.filter(function(item) { return ("" + item.source) !== failedSource })
				}
			}

			function togglePresetPicker() {
				if (presetSelectionSaving) return
				presetPickerExpanded = !presetPickerExpanded
				presetSelectionStatus = ""
				if (!presetPickerExpanded) return
				if (heroicLutrisKind && canAttemptIgdbMetadata && igdbPresetSpecs.length === 0 && !igdbArtworkAttempted) {
					fetchHeroicLutrisIgdbArt()
				}
			}

			function applyPresetImage(imageItem, spec) {
				if (!imageItem || !spec || !spec.source || presetSelectionSaving) return
				var sourceFilepath = "" + spec.source
				var isLocalFilepath = sourceFilepath.indexOf("file://") === 0 || sourceFilepath.indexOf("/") === 0
				if (isLocalFilepath) {
					heroPanel.updatePage(rowIndex, "backgroundImage", presetHelper.toFileUrl(sourceFilepath))
					presetPickerExpanded = false
					return
				}

				presetSelectionSaving = true
				presetSelectionStatus = i18n("Saving selected image...")
				imageItem.grabToImage(function(result) {
					var localFilepath = presetHelper.saveGrabResultToPresetFolder(result, spec.filename)
					pageDelegate.presetSelectionSaving = false
					if (!localFilepath) {
						pageDelegate.presetSelectionStatus = i18n("Could not save the selected image.")
						return
					}
					heroPanel.updatePage(pageDelegate.rowIndex, "backgroundImage", presetHelper.toFileUrl(localFilepath))
					pageDelegate.presetSelectionStatus = ""
					pageDelegate.presetPickerExpanded = false
				}, imageItem.sourceSize)
			}

			Component.onCompleted: refreshPresetSources(true)
			onPageChanged: refreshPresetSources(false)
			onHasIgdbMetadataSettingsChanged: maybeFetchSteamIgdbArt()

			ColumnLayout {
				id: rowLayout
				anchors.fill: parent
				anchors.margins: Kirigami.Units.largeSpacing
				spacing: Kirigami.Units.smallSpacing

				RowLayout {
					Layout.fillWidth: true
					PlasmaComponents3.Label { text: i18n("Page %1", index + 1); font.bold: true }
					Item { Layout.fillWidth: true }
					QQC2.ToolButton {
						icon.name: "go-up"
						enabled: index > 0
						onClicked: heroPanel.movePage(index, -1)
					}
					QQC2.ToolButton {
						icon.name: "go-down"
						enabled: index < heroPanel._pages().length - 1
						onClicked: heroPanel.movePage(index, 1)
					}
					QQC2.ToolButton {
						icon.name: "list-remove"
						onClicked: heroPanel.removePage(index)
					}
				}

				RowLayout {
					Layout.fillWidth: true
					PlasmaComponents3.Label { text: i18n("Image:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 6 }
					QQC2.TextField {
						id: imageField
						Layout.fillWidth: true
						text: ("" + (pageDelegate.page.backgroundImage || ""))
						placeholderText: i18n("File path or URL")
						onEditingFinished: heroPanel.updatePage(index, "backgroundImage", text)
					}
					QQC2.Button {
						icon.name: "document-open"
						onClicked: fileDialogLoader.active = true
						QQC2.ToolTip.visible: hovered
						QQC2.ToolTip.text: i18n("Choose a background image for this hero page")
						Loader {
							id: fileDialogLoader
							active: false
							sourceComponent: QtDialogs.FileDialog {
								id: fileDialog
								visible: false
								modality: Qt.WindowModal
								title: i18n("Choose an image")
								nameFilters: [i18n("Image Files (*.png *.apng *.gif *.webp *.jpg *.jpeg *.bmp *.svg *.svgz)")]
								onAccepted: {
									heroPanel.updatePage(index, "backgroundImage", "" + selectedFile)
									fileDialogLoader.active = false
								}
								onRejected: fileDialogLoader.active = false
								Component.onCompleted: visible = true
							}
						}
					}
					QQC2.ToolButton {
						icon.name: pageDelegate.presetPickerExpanded ? "arrow-up" : "arrow-down"
						enabled: (pageDelegate.presetPickerExpanded || pageDelegate.canOpenPresetPicker)
							&& !pageDelegate.presetSelectionSaving
						checkable: true
						checked: pageDelegate.presetPickerExpanded
						onClicked: pageDelegate.togglePresetPicker()
						Accessible.name: pageDelegate.presetPickerExpanded
							? i18n("Hide preset images")
							: i18n("Choose from preset images")
						QQC2.ToolTip.visible: hovered
						QQC2.ToolTip.text: enabled
							? (pageDelegate.presetPickerExpanded
								? i18n("Hide preset images")
								: i18n("Choose from preset images"))
							: i18n("No preset tile images are available for this entry")
					}
				}

				GridLayout {
					id: presetPicker
					Layout.fillWidth: true
					columns: 2
					columnSpacing: Kirigami.Units.smallSpacing
					rowSpacing: Kirigami.Units.smallSpacing
					visible: pageDelegate.presetPickerExpanded

					Repeater {
						model: pageDelegate.presetSpecs

						delegate: Item {
							id: presetChoice
							Layout.fillWidth: true
							Layout.preferredWidth: 0
							Layout.preferredHeight: Kirigami.Units.gridUnit * 5
							property var spec: modelData

							Rectangle {
								anchors.fill: parent
								color: presetMouse.containsMouse
									? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
									: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.35)
								border.color: presetMouse.containsMouse
									? Kirigami.Theme.highlightColor
									: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
								border.width: 1
								radius: Kirigami.Units.smallSpacing
							}

							Image {
								id: presetImage
								anchors.fill: parent
								anchors.margins: Kirigami.Units.smallSpacing
								fillMode: Image.PreserveAspectFit
								asynchronous: true
								cache: true
								source: presetChoice.spec && presetChoice.spec.source ? presetChoice.spec.source : ""
								property string _reportedErrorSource: ""

								onSourceChanged: _reportedErrorSource = ""
								onStatusChanged: {
									var failedSource = "" + source
									if (status === Image.Error && failedSource && _reportedErrorSource !== failedSource) {
										_reportedErrorSource = failedSource
										pageDelegate.removeFailedPreset(presetChoice.spec)
									}
								}
							}

							QQC2.BusyIndicator {
								anchors.centerIn: parent
								running: presetImage.status === Image.Loading
								visible: running
							}

							Rectangle {
								anchors.right: parent.right
								anchors.bottom: parent.bottom
								anchors.margins: Kirigami.Units.smallSpacing
								width: presetSizeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
								height: presetSizeLabel.implicitHeight + Kirigami.Units.smallSpacing
								visible: presetChoice.spec && presetChoice.spec.w > 0 && presetChoice.spec.h > 0
								color: "#C0000000"
								border.color: "#80FFFFFF"
								border.width: 1
								radius: Kirigami.Units.smallSpacing

								Text {
									id: presetSizeLabel
									anchors.centerIn: parent
									text: presetChoice.spec ? presetChoice.spec.w + "×" + presetChoice.spec.h : ""
									color: "white"
									font.bold: true
									font.pixelSize: 12
								}
							}

							MouseArea {
								id: presetMouse
								anchors.fill: parent
								hoverEnabled: true
								enabled: presetImage.status === Image.Ready && !pageDelegate.presetSelectionSaving
								cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
								onClicked: pageDelegate.applyPresetImage(presetImage, presetChoice.spec)
							}

							QQC2.ToolTip.visible: presetMouse.containsMouse
							QQC2.ToolTip.text: presetChoice.spec && presetChoice.spec.filename
								? i18n("Use %1", presetChoice.spec.filename)
								: i18n("Use this image")
						}
					}

					QQC2.BusyIndicator {
						Layout.columnSpan: 2
						Layout.alignment: Qt.AlignHCenter
						running: pageDelegate.artworkLoading
						visible: running
					}

					QQC2.Label {
						Layout.columnSpan: 2
						Layout.fillWidth: true
						visible: pageDelegate.presetSelectionSaving || pageDelegate.presetSelectionStatus.length > 0
						wrapMode: Text.Wrap
						opacity: 0.8
						text: pageDelegate.presetSelectionStatus
					}

					QQC2.Label {
						Layout.columnSpan: 2
						Layout.fillWidth: true
						visible: pageDelegate.presetSpecs.length === 0
							&& !pageDelegate.artworkLoading
							&& !pageDelegate.presetSelectionSaving
							&& pageDelegate.presetSelectionStatus.length === 0
						wrapMode: Text.Wrap
						opacity: 0.8
						text: i18n("No preset images are available.")
					}
				}

				RowLayout {
					Layout.fillWidth: true
					PlasmaComponents3.Label { text: i18n("Label:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 6 }
					QQC2.TextField {
						Layout.fillWidth: true
						text: ("" + (pageDelegate.page.label || ""))
						placeholderText: i18n("Optional overlay text")
						onEditingFinished: heroPanel.updatePage(index, "label", text)
					}
				}

				RowLayout {
					Layout.fillWidth: true
					PlasmaComponents3.Label { text: i18n("Launch URL:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 6 }
					LibConfig.AutocompleteTextField {
						Layout.fillWidth: true
						text: ("" + (pageDelegate.page.launchUrl || ""))
						placeholderText: i18n("Optional .desktop file or http(s):// URL")
						suggestionsProvider: appAutocomplete.suggestionsProvider
						onEditingFinished: heroPanel.updatePage(index, "launchUrl", text)
					}
				}

				RowLayout {
					Layout.fillWidth: true
					QQC2.CheckBox {
						id: downloadedInfoCheck
						text: i18n("Show downloaded store info and tags")
						checked: !!pageDelegate.page.showDownloadedInfo
						enabled: pageDelegate.canShowDownloadedInfo
						onToggled: {
							heroPanel.updatePage(index, "showDownloadedInfo", checked)
							if (checked) {
								heroPanel.refreshPageMetadata(index, pageDelegate)
							} else {
								pageDelegate.metadataStatus = ""
							}
						}
						QQC2.ToolTip.visible: hovered
						QQC2.ToolTip.text: enabled
							? i18n("Download store text and tags for this page when enabled")
							: (pageDelegate.canDownloadMetadata
								? i18n("Set the IGDB Client ID and Client Secret in the Tiles settings to enable this option")
								: i18n("This option is only available for Steam, Heroic, or Lutris game launchers"))
					}
					Item { Layout.fillWidth: true }
					QQC2.ToolButton {
						icon.name: "view-refresh"
						enabled: pageDelegate.canShowDownloadedInfo && !pageDelegate.metadataLoading
						onClicked: heroPanel.refreshPageMetadata(index, pageDelegate)
						QQC2.ToolTip.visible: hovered
						QQC2.ToolTip.text: enabled
							? i18n("Refresh downloaded metadata")
							: i18n("Fill in the IGDB metadata settings first")
					}
				}

				QQC2.Label {
					visible: pageDelegate.metadataLoading || metadataStatus.length > 0
					Layout.fillWidth: true
					wrapMode: Text.Wrap
					opacity: 0.8
					text: pageDelegate.metadataLoading ? i18n("Downloading metadata...") : metadataStatus
				}
			}
		}
	}

	QQC2.Button {
		Layout.fillWidth: true
		icon.name: "list-add"
		text: i18n("Add page")
		onClicked: heroPanel.addPage()
	}

	Connections {
		target: heroPanel.appObj
		function onTileChanged() {
			heroPanel._refreshToken = heroPanel._refreshToken + 1
		}
	}
}
