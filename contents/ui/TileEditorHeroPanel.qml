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

	function _pages() {
		if (!appObj || !appObj.tile || !Array.isArray(appObj.tile.subTiles)) return []
		return appObj.tile.subTiles
	}

	function _commit(arr) {
		if (!appObj || !appObj.tile) return
		appObj.tile.subTiles = arr
		appObj.tileChanged()
		if (tileGrid) tileGrid.tileModelChanged()
	}

	function updatePage(index, key, value) {
		var arr = _pages().slice()
		if (index < 0 || index >= arr.length) return
		var p = Object.assign({}, arr[index])
		p[key] = value
		arr[index] = p
		_commit(arr)
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
			readonly property var staticPresetSpecs: presetHelper.presetSpecsForLaunchUrl(page.launchUrl || "")
			property var igdbPresetSpecs: []
			readonly property var presetSpecs: staticPresetSpecs.concat(igdbPresetSpecs)
			readonly property bool canDownloadPresetImages: staticPresetSpecs.length > 0 || canDownloadHeroicLutrisMetadata
			readonly property bool canDownloadSteamMetadata: !!metadataFetcher._steamGameIdForPage(page)
			property string heroicLutrisKind: ""
			readonly property bool canDownloadHeroicLutrisMetadata: heroicLutrisKind.length > 0
			readonly property bool canDownloadMetadata: canDownloadSteamMetadata || canDownloadHeroicLutrisMetadata
			readonly property bool hasIgdbMetadataSettings: metadataFetcher.hasIgdbMetadataSettings
			readonly property bool canShowDownloadedInfo: (canDownloadSteamMetadata && hasIgdbMetadataSettings) || (canDownloadHeroicLutrisMetadata && hasIgdbMetadataSettings)
			property bool metadataLoading: false
			property string metadataStatus: ""
			property int _pendingPresetSaveIndex: -1

			function refreshHeroicLutrisKind(done) {
				metadataFetcher.resolveHeroicLutrisKindForPage(page, function(kind) {
					pageDelegate.heroicLutrisKind = kind || ""
					if (done) {
						done()
					}
				})
			}

			function downloadPresetImages() {
				if (!staticPresetSpecs.length && !heroicLutrisKind) {
					refreshHeroicLutrisKind(function() {
						pageDelegate.downloadPresetImages()
					})
					return
				}
				if (!canDownloadPresetImages) {
					return
				}
				if (heroicLutrisKind && hasIgdbMetadataSettings && igdbPresetSpecs.length === 0) {
					var title = metadataFetcher._titleForPage(page)
					if (title) {
						metadataStatus = i18n("Looking up IGDB artwork...")
						metadataLoading = true
						metadataFetcher.fetchIgdbArtworksByTitle(title, function(err, detail) {
							metadataLoading = false
							if (err || !detail) {
								metadataStatus = err || i18n("No IGDB artwork found.")
								_startPresetSave()
								return
							}
							igdbPresetSpecs = presetHelper.presetSpecsForIgdbDetail(detail)
							metadataStatus = i18n("Downloaded IGDB artwork.")
							_startPresetSave()
						})
						return
					}
				}
				_startPresetSave()
			}

			function _startPresetSave() {
				_pendingPresetSaveIndex = 0
				_saveNextPresetImage()
			}

			function _saveNextPresetImage() {
				while (_pendingPresetSaveIndex >= 0 && _pendingPresetSaveIndex < presetSpecs.length) {
					var item = presetImageRepeater.itemAt(_pendingPresetSaveIndex)
					_pendingPresetSaveIndex = _pendingPresetSaveIndex + 1
					if (!item) {
						continue
					}
					item.saveToPresetFolder(function(){
						pageDelegate._saveNextPresetImage()
					})
					return
				}
				_pendingPresetSaveIndex = -1
			}

			Component.onCompleted: refreshHeroicLutrisKind()
			onPageChanged: refreshHeroicLutrisKind()

			Repeater {
				id: presetImageRepeater
				model: pageDelegate.presetSpecs

				delegate: Image {
					id: presetImage
					property var spec: modelData
					property var _pendingCallback: null
					x: 0
					y: 0
					z: -1
					opacity: 0
					width: sourceSize.width > 0 ? sourceSize.width : 1
					height: sourceSize.height > 0 ? sourceSize.height : 1
					fillMode: Image.PreserveAspectFit
					asynchronous: true
					cache: true
					source: spec && spec.source ? spec.source : ""

					function saveToPresetFolder(done) {
						if (!spec || !spec.filename || !source) {
							if (done) {
								done(false)
							}
							return
						}
						if (status === Image.Error || status === Image.Null) {
							if (done) {
								done(false)
							}
							return
						}
						if (status !== Image.Ready) {
							_pendingCallback = done || null
							return
						}
						grabToImage(function(result){
							presetHelper.saveGrabResultToPresetFolder(result, spec.filename)
							if (done) {
								done(true)
							}
						}, sourceSize)
					}

					onStatusChanged: {
						if (!_pendingCallback) {
							return
						}
						var callback = _pendingCallback
						_pendingCallback = null
						if (status === Image.Ready) {
							saveToPresetFolder(callback)
						} else if (status === Image.Error || status === Image.Null) {
							callback(false)
						}
					}
				}
			}

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
						icon.name: "folder-download-symbolic"
						enabled: pageDelegate.canDownloadPresetImages
						onClicked: pageDelegate.downloadPresetImages()
						QQC2.ToolTip.visible: hovered
						QQC2.ToolTip.text: enabled
							? i18n("Download all preset tile images for this entry into the preset tiles folder")
							: i18n("No preset tile images are available for this entry")
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
