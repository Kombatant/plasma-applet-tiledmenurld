// Based on LibConfig.ColorField v8
// QQC2.TextField => PlasmaComponents3.TextField

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Window
import org.kde.kirigami as Kirigami

import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.TextField {
	id: colorField
	font.family: "monospace"
	readonly property string defaultText: "#AARRGGBB"
	placeholderText: defaultColor ? defaultColor : defaultText

	onTextChanged: {
		// Make sure the text is:
		//   Empty (use default)
		//   or #123 or #112233 or #11223344 before applying the color.
		if (text.length === 0
			|| (text.indexOf('#') === 0 && (text.length == 4 || text.length == 7 || text.length == 9))
		) {
			colorField.value = text
		}
	}

	property bool showAlphaChannel: true
	property bool showPreviewBg: true

	property string configKey: ''
	property string defaultColor: ''
	property string value: {
		if (configKey) {
			return plasmoid.configuration[configKey]
		} else {
			// Tile editor: start empty so the default colour shows as the hint.
			return ""
		}
	}

	readonly property color defaultColorValue: defaultColor
	readonly property color valueColor: {
		if (value == '' && defaultColor) {
			return defaultColor
		} else {
			return value
		}
	}
	readonly property int sideControlMargin: Math.max(2 * Screen.devicePixelRatio, Math.round(Kirigami.Units.smallSpacing / 2))

	onValueChanged: {
		if (!activeFocus) {
			text = colorField.value
		}
		if (configKey) {
			if (value == defaultColorValue) {
				plasmoid.configuration[configKey] = ""
			} else {
				plasmoid.configuration[configKey] = value
			}
		}
	}

	leftPadding: sideControlMargin + mouseArea.width + sideControlMargin

	FontMetrics {
		id: fontMetrics
		font.family: colorField.font.family
		font.italic: colorField.font.italic
		font.pointSize: colorField.font.pointSize
		font.pixelSize: colorField.font.pixelSize
		font.weight: colorField.font.weight
	}
	readonly property int defaultWidth: Math.ceil(fontMetrics.advanceWidth(defaultText))
	implicitWidth: rightPadding + Math.max(defaultWidth, contentWidth) + leftPadding

	MouseArea {
		id: mouseArea
		anchors.leftMargin: colorField.sideControlMargin
		anchors.topMargin: parent.topPadding
		anchors.bottomMargin: parent.bottomPadding
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		width: height
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor

		onClicked: dialogLoader.active = true

		// Color Preview Circle
		// Checkerboard behind the preview so translucent colours (e.g. #00000000)
		// read as transparent rather than as solid black. Clipped to a circle so
		// the square cells don't poke out past the round preview.
		Canvas {
			id: previewBgChecker
			visible: colorField.showPreviewBg
			anchors.fill: parent
			readonly property int checkerCells: 4

			onWidthChanged: requestPaint()
			onHeightChanged: requestPaint()
			onPaint: {
				const ctx = getContext("2d")
				ctx.reset()
				if (width <= 0 || height <= 0) {
					return
				}
				ctx.save()
				ctx.beginPath()
				ctx.arc(width / 2, height / 2, Math.min(width, height) / 2, 0, 2 * Math.PI)
				ctx.clip()
				ctx.fillStyle = "white"
				ctx.fillRect(0, 0, width, height)
				ctx.fillStyle = "#cccccc"
				const cellW = width / checkerCells
				const cellH = height / checkerCells
				for (let row = 0; row < checkerCells; row++) {
					for (let col = 0; col < checkerCells; col++) {
						if ((row + col) % 2 === 1) {
							ctx.fillRect(col * cellW, row * cellH, cellW, cellH)
						}
					}
				}
				ctx.restore()
			}
		}
		Rectangle {
			id: previewFill
			anchors.fill: parent
			color: colorField.valueColor
			border.width: 1
			border.color: Kirigami.ColorUtils.linearInterpolation(color, Kirigami.Theme.textColor, 0.5)
			radius: width / 2
		}
	}

	Loader {
		id: dialogLoader
		active: false
		sourceComponent: QtDialogs.ColorDialog {
			id: dialog
			visible: true
			modality: Qt.WindowModal
			options: colorField.showAlphaChannel ? QtDialogs.ColorDialog.ShowAlphaChannel : 0
			selectedColor: colorField.valueColor
			onSelectedColorChanged: {
				if (visible) {
					colorField.text = selectedColor
				}
			}
			onAccepted: {
				colorField.text = selectedColor
				dialogLoader.active = false
			}
			onRejected: {
				// This event is also triggered when the user clicks outside the popup modal.
				colorField.text = initValue
				dialogLoader.active = false
			}

			property string initValue
			Component.onCompleted: {
				initValue = colorField.value
			}
		}
	}
}
