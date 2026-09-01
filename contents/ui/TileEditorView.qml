import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes // IconDialog

ColumnLayout {
	id: tileEditorView
	Layout.alignment: Qt.AlignTop

	AppObject {
		id: appObj
	}

	AppAutocompleteHelper {
		id: appAutocomplete
	}
	property alias tile: appObj.tile
	property var tileGrid: null

	// Width the sidebar must have for the editor content to fit without a
	// horizontal scrollbar. Text fields clamp their implicit width (they
	// scroll internally), so this only grows for structural content
	// (buttons, paddings, font size). Consumed via config.tileEditorContentWidth.
	// The scrollbar allowance is a fixed unit on purpose: deriving it from
	// scrollView.width would feed the pane width back into the measurement.
	readonly property real editorContentWidth: Math.max(headerRow.implicitWidth, scrollContent.implicitWidth) + Kirigami.Units.gridUnit

	// When the pane is wider than the editor needs (eg. a wide docked
	// sidebar), stop the content from stretching. An explicit width is used
	// because the StackView sizes this view to the full pane width.
	readonly property int contentWidthCap: Math.min(width, config.tileEditorMaxContentWidth)

	function resetView() {
		tile = null
	}

	function resetTile() {
		delete appObj.tile.showIcon
		delete appObj.tile.showLabel
		delete appObj.tile.label
		delete appObj.tile.icon
		delete appObj.tile.iconFill
		delete appObj.tile.backgroundColor
		delete appObj.tile.backgroundImage
		appObj.tileChanged()
		tileGrid.tileModelChanged()
	}

	function normalizeIconFillForTile() {
		if (!appObj.tile || appObj.isGroup || appObj.tileH !== 1 || typeof appObj.tile.iconFill === "undefined") {
			return
		}
		delete appObj.tile.iconFill
		appObj.tileChanged()
		tileGrid.tileModelChanged()
	}


	RowLayout {
		id: headerRow
		Layout.fillWidth: false
		Layout.preferredWidth: tileEditorView.contentWidthCap
		Layout.rightMargin: scrollView.width - scrollView.availableWidth

		PlasmaExtras.Heading {
			Layout.fillWidth: true
			level: 2
			text: i18n("Edit Tile")
		}

		PlasmaComponents3.Button {
			text: i18n("Reset Tile")
			onClicked: resetTile()
		}

		PlasmaComponents3.Button {
			text: i18n("Close")
			onClicked: {
				tileEditorView.close()
			}
		}
	}


	PlasmaComponents3.ScrollView {
		id: scrollView
		Layout.fillHeight: true
		Layout.fillWidth: false
		Layout.preferredWidth: tileEditorView.contentWidthCap
		// No contentWidth override here: binding it to availableWidth loops
		// through the scrollbar padding (phantom bars, and with a scrollbar
		// policy set it livelocked plasmashell). The pane is instead sized to
		// the measured content width, so nothing overflows horizontally.

		ColumnLayout {
			id: scrollContent
			Layout.fillWidth: true
			width: scrollView.availableWidth

			TileEditorField {
				visible: !appObj.isHero
				title: i18n("Url")
				key: 'url'
				suggestionsProvider: appAutocomplete.suggestionsProvider
			}

			TileEditorField {
				id: labelField
				visible: !appObj.isHero
				title: i18n("Label")
				placeholderText: appObj.appLabel
				key: 'label'
				checkedKey: 'showLabel'
			}

			TileEditorField {
				id: iconField
				visible: !appObj.isHero
				title: i18n("Icon")
				// placeholderText: appObj.appIcon ? appObj.appIcon.toString() : ''
				key: 'icon'
				checkedKey: 'showIcon'
				checkedDefault: appObj.defaultShowIcon
				labelExtras: PlasmaComponents3.CheckBox {
					id: iconFillCheck
					text: i18n("Fill the whole tile")
					enabled: iconField.checked && !appObj.isGroup && appObj.tileH !== 1
					checked: false
					property bool updateOnChange: false
					onCheckedChanged: {
						if (!updateOnChange || !appObj.tile) {
							return
						}
						appObj.tile.iconFill = checked
						appObj.tileChanged()
						tileGrid.tileModelChanged()
					}

					Connections {
						target: appObj
						function onTileChanged() {
							if (!tile) {
								return
							}
							iconFillCheck.updateOnChange = false
							iconFillCheck.checked = typeof appObj.tile.iconFill !== "undefined" ? appObj.tile.iconFill : false
							iconFillCheck.updateOnChange = true
						}
					}
				}

				PlasmaComponents3.Button {
					icon.name: "document-open"
					onClicked: iconDialog.open()

					KIconThemes.IconDialog {
						id: iconDialog
						onIconNameChanged: iconField.text = iconName
					}
				}

				Connections {
					target: iconField
					function onCheckedChanged() {
						if (iconField.checked && backgroundImageField.text) {
							backgroundImageField.text = ""
						}
					}
				}
			}

			TileEditorFileField {
				id: backgroundImageField
				visible: !appObj.isHero
				title: i18n("Background Image")
				key: 'backgroundImage'
				enabled: !iconField.checked
				onTextChanged: {
					if (text) {
						labelField.checked = false
						iconField.checked = false
					}
				}
				onDialogOpen: function(dialog) {
					dialog.title = i18n("Choose an image")
					dialog.nameFilters.unshift(i18n("Image Files (*.png *.apng *.gif *.webp *.jpg *.jpeg *.bmp *.svg *.svgz)"))
				}
			}

			TileEditorPresetTiles {
				visible: !appObj.isHero
				title: i18n("Preset Tiles")
				appObj: appObj
				backgroundImageField: backgroundImageField
				labelField: labelField
				iconField: iconField
				tileGrid: tileGrid
				positionSizeField: positionSizeField
			}

			TileEditorColorGroup {
				visible: !appObj.isHero
				title: i18n("Background Colour")
				placeholderText: config.defaultTileColor
				key: 'backgroundColor'
				enabled: !(appObj.isGroup && !appObj.isCardLayout)
			}

			TileEditorHeroPanel {
				visible: appObj.isHero
				appObj: appObj
				tileGrid: tileEditorView.tileGrid
			}

			TileEditorRectField {
				id: positionSizeField
				title: i18n("Position / Size")
			}

			Item { // Consume the extra space below
				Layout.fillHeight: true
			}
		}
	}

	function show() {
		if (stackView.currentItem != tileEditorView) {
			stackView.replace(tileEditorView)
		}
	}

	function open(tile) {
		resetView()
		tileEditorView.tile = tile
		show()
	}

	function close() {
		searchView.showDefaultView()
	}


	Connections {
		target: stackView

		function onCurrentItemChanged() {
			if (stackView.currentItem != tileEditorView) {
				tileEditorView.resetView()
			}
		}
	}

	Connections {
		target: appObj

		function onTileChanged() {
			tileEditorView.normalizeIconFillForTile()
		}
	}


	Connections {
		target: config.tileModel

		function onLoaded() {
			// Saving `tileModel` may replace the underlying data structure and
			// invalidate any held tile object references. To avoid editing stale
			// references after an Import or save, the editor closes when
			// `config.tileModel.loaded()` fires.
			tileEditorView.close()
		}
	}

}
