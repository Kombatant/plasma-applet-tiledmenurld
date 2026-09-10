import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// "Breeze Refined" session modal: replaces the plain PlasmaExtras.Menu that used
// to drop out of the sidebar power button. Every entry of powerActionsModel is
// shown as an icon-over-label tile in a grid, so nothing the session offers
// (lock, log out, switch user, sleep, hibernate, restart, shut down) is lost.
Item {
	id: modalRoot

	property var model: null
	property bool open: false

	readonly property int columns: 3
	readonly property int cardPadding: Math.round(Kirigami.Units.gridUnit * 1.1)
	readonly property int tileSpacing: Kirigami.Units.smallSpacing * 2
	readonly property int tileIconSize: Math.round(Kirigami.Units.iconSizes.medium * 1.1)
	readonly property int tileHeight: Math.round(tileIconSize + Kirigami.Units.gridUnit * 2.6)
	readonly property int tileWidth: Math.round(Kirigami.Units.gridUnit * 5.4)

	// Scrim tint follows the theme so it reads correctly in light and dark, and
	// stays translucent enough for a blur behind the plasmoid to remain visible.
	property real scrimOpacity: 0.30

	// In-scene backdrop blur. KWin's blur is a per-window compositor effect and
	// cannot reach elements drawn inside this window, so the popup content is
	// blurred as a texture layer instead. The layer costs two full-surface passes,
	// so it is only enabled while the modal is actually on screen.
	property bool blurBackdrop: (typeof config !== "undefined" && config
		&& typeof config.sessionModalBlurBackdrop !== "undefined")
		? config.sessionModalBlurBackdrop
		: true
	readonly property bool blurBackdropActive: blurBackdrop && visible
	property real blurStrength: 0.65
	property real blurAmount: open ? blurStrength : 0

	Behavior on blurAmount {
		enabled: !modalRoot._skipTransition
		NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
	}
	readonly property color scrimBaseColor: (typeof config !== "undefined" && config)
		? config.surfaceBaseColor
		: Kirigami.Theme.backgroundColor

	visible: opacity > 0
	opacity: open ? 1 : 0
	enabled: open

	property bool _skipTransition: false

	Behavior on opacity {
		enabled: !modalRoot._skipTransition
		NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
	}

	function openModal() {
		open = true
		forceActiveFocus()
	}

	function closeModal() {
		open = false
	}

	// Close with no fade/blur animation, so a close+reopen of the plasmoid never
	// shows the modal mid-transition on the way back in.
	function closeImmediately() {
		// Suppress the Behaviors first: `open = false` drives opacity and blurAmount
		// to 0 through their bindings, and assigning those directly would break the
		// bindings for good.
		_skipTransition = true
		open = false
		_skipTransition = false
	}

	function toggleOpen() {
		if (open) {
			closeModal()
		} else {
			openModal()
		}
	}

	function isVisibleAction(item) {
		return !!item && !item.disabled
	}

	// Scrim: a 30% translucent surface rather than an opaque dim, so a panel blur
	// effect behind the plasmoid shows through it. Also closes on an outside click.
	MouseArea {
		anchors.fill: parent
		hoverEnabled: true
		onClicked: modalRoot.closeModal()

		Rectangle {
			anchors.fill: parent
			color: Qt.rgba(modalRoot.scrimBaseColor.r,
			               modalRoot.scrimBaseColor.g,
			               modalRoot.scrimBaseColor.b,
			               modalRoot.scrimOpacity)
		}
	}

	Keys.onEscapePressed: function(event) {
		modalRoot.closeModal()
		event.accepted = true
	}

	SidebarGlassCard {
		id: card
		anchors.centerIn: parent
		open: modalRoot.open
		contentMargins: modalRoot.cardPadding
		// The scrim is the translucent part; the card itself stays mostly solid so
		// the labels remain readable over whatever tile art is behind it.
		fillOpacity: 0.97
		// The card is sized from the layout's implicit size, so the layout must NOT
		// anchor back to the card (that would be a circular binding). It is
		// positioned at the origin of contentLayer, which is already inset by
		// contentMargins.
		width: cardLayout.implicitWidth + modalRoot.cardPadding * 2
		height: cardLayout.implicitHeight + modalRoot.cardPadding * 2

		scale: modalRoot.open ? 1 : 0.94
		Behavior on scale {
			NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
		}

		// Swallow clicks so the scrim doesn't close the modal from inside the card.
		MouseArea {
			anchors.fill: parent
			onClicked: {}
		}

		ColumnLayout {
			id: cardLayout
			x: 0
			y: 0
			width: implicitWidth
			height: implicitHeight
			spacing: Math.round(Kirigami.Units.gridUnit * 0.9)

			RowLayout {
				Layout.fillWidth: true
				spacing: Kirigami.Units.smallSpacing

				Kirigami.Heading {
					text: i18n("Session")
					level: 3
					color: Kirigami.Theme.textColor
					Layout.fillWidth: true
					elide: Text.ElideRight
				}

				FlatButton {
					icon.name: "window-close-symbolic"
					iconSize: Kirigami.Units.iconSizes.small
					buttonHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
					Layout.preferredWidth: buttonHeight
					Layout.preferredHeight: buttonHeight
					onClicked: modalRoot.closeModal()
				}
			}

			GridLayout {
				id: actionGrid
				Layout.alignment: Qt.AlignHCenter
				columns: modalRoot.columns
				columnSpacing: modalRoot.tileSpacing
				rowSpacing: modalRoot.tileSpacing

				Repeater {
					model: modalRoot.model

					delegate: FlatButton {
						id: actionTile

						readonly property string _baseIcon: model.iconName || model.decoration || ""
						readonly property string _resolvedIcon: (_baseIcon && _baseIcon.indexOf("-symbolic") < 0)
							? _baseIcon + "-symbolic"
							: _baseIcon
						readonly property string _label: model.name || model.display || ""

						visible: modalRoot.isVisibleAction(model)
						Layout.preferredWidth: modalRoot.tileWidth
						Layout.preferredHeight: modalRoot.tileHeight
						buttonHeight: modalRoot.tileHeight
						hoverEnabled: true
						onClicked: {
							modalRoot.closeModal()
							modalRoot.model.triggerIndex(index)
						}

						Loader {
							anchors.fill: parent
							source: "HoverOutlineButtonEffect.qml"
							asynchronous: true
							property var mouseArea: actionTile.__behavior
							active: actionTile.hovered
							visible: active
							property var __mouseArea: mouseArea
						}

						contentItem: ColumnLayout {
							spacing: Kirigami.Units.smallSpacing

							Item { Layout.fillHeight: true }

							Kirigami.Icon {
								Layout.alignment: Qt.AlignHCenter
								Layout.preferredWidth: modalRoot.tileIconSize
								Layout.preferredHeight: modalRoot.tileIconSize
								source: actionTile._resolvedIcon
								color: Kirigami.Theme.textColor
								isMask: true
							}

							QQC2.Label {
								Layout.fillWidth: true
								Layout.alignment: Qt.AlignHCenter
								horizontalAlignment: Text.AlignHCenter
								text: actionTile._label
								color: Kirigami.Theme.textColor
								elide: Text.ElideRight
								maximumLineCount: 2
								wrapMode: Text.WordWrap
								font.pointSize: Kirigami.Theme.smallFont.pointSize
							}

							Item { Layout.fillHeight: true }
						}
					}
				}
			}
		}
	}
}
