import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
	id: searchField

	signal escapeClearsSearchRequested()

	property int topMargin: 0
	property int bottomMargin: 0
	property real defaultFontSize: 16 * Screen.devicePixelRatio // Not the same as pointSize=16
	property real fontScale: 0.35
	readonly property real styleMaxFontSize: Math.max(0, height - topMargin - bottomMargin)
	readonly property real computedFontSize: Math.max(
		10 * Screen.devicePixelRatio,
		Math.min(styleMaxFontSize * fontScale, defaultFontSize)
	)
	readonly property int searchIconSize: Math.round(Math.max(
		12 * Screen.devicePixelRatio,
		Math.min(24 * Screen.devicePixelRatio, styleMaxFontSize * 0.8)
	))
	readonly property int searchIconPadding: Math.round(Kirigami.Units.smallSpacing)

	property var listView: searchResultsView.listView
	property string text: search.query
	readonly property bool followsTheme: !!plasmoid.configuration.searchFieldFollowsTheme
	readonly property color glassBaseColor: followsTheme ? Kirigami.Theme.backgroundColor : config.sidebarBackgroundColor
	readonly property bool glassBaseIsLight: relativeLuminance(glassBaseColor) > 0.6
	readonly property color foregroundColor: followsTheme
		? Kirigami.Theme.textColor
		: (glassBaseIsLight ? Qt.rgba(0, 0, 0, 0.88) : Qt.rgba(1, 1, 1, 0.92))
	readonly property color mutedForegroundColor: colorWithAlpha(foregroundColor, glassBaseIsLight ? 0.58 : 0.66)

	function relativeLuminance(color) {
		function channel(c) {
			return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
		}
		return (0.2126 * channel(color.r)) + (0.7152 * channel(color.g)) + (0.0722 * channel(color.b))
	}

	function colorWithAlpha(color, alpha) {
		return Qt.rgba(color.r, color.g, color.b, alpha)
	}

	function onTextChangedInternal(newText) {
		if (text !== newText) {
			text = newText
		}
		if (search.query !== newText) {
			search.query = newText
		}
	}

	Connections {
		target: search
		function onQueryChanged() {
			if (searchField.text !== search.query) {
				searchField.text = search.query
			}
			if (fieldLoader.item && fieldLoader.item.text !== search.query) {
				fieldLoader.item.text = search.query
			}
		}
	}

	readonly property var inputItem: fieldLoader.item

	function focusAndInsert(insertText) {
		if (!searchField.inputItem) {
			return
		}
		searchField.inputItem.forceActiveFocus()
		if (typeof insertText !== "string" || insertText.length === 0) {
			return
		}
		if (typeof searchField.inputItem.insert === "function") {
			var pos = 0
			if (typeof searchField.inputItem.cursorPosition === "number") {
				pos = searchField.inputItem.cursorPosition
			} else if (typeof searchField.inputItem.length === "number") {
				pos = searchField.inputItem.length
			} else if (typeof searchField.inputItem.text === "string") {
				pos = searchField.inputItem.text.length
			}
			searchField.inputItem.insert(pos, insertText)
		} else {
			var base = (typeof searchField.inputItem.text === "string") ? searchField.inputItem.text : ""
			searchField.inputItem.text = base + insertText
		}
	}

	Loader {
		id: fieldLoader
		anchors.fill: parent
		sourceComponent: searchField.followsTheme ? themedField : windowsField
		onLoaded: {
			item.text = searchField.text
			item.forceActiveFocus()
		}
	}

	Component {
		id: themedField
		PlasmaComponents3.TextField {
			id: themedTextField
			placeholderText: i18n("Search apps, files and settings...")
			font.pixelSize: searchField.computedFontSize
			leftPadding: searchField.searchIconSize + (searchField.searchIconPadding * 2)
			rightPadding: clearButton.visible
				? searchField.searchIconSize + (searchField.searchIconPadding * 2)
				: searchField.searchIconPadding
			background: SidebarGlassCard {
				baseColor: searchField.glassBaseColor
				contentMargins: 0
			}
			color: searchField.foregroundColor
			placeholderTextColor: searchField.mutedForegroundColor
			onTextChanged: searchField.onTextChangedInternal(text)

			Kirigami.Icon {
				anchors.left: parent.left
				anchors.leftMargin: searchField.searchIconPadding
				anchors.verticalCenter: parent.verticalCenter
				width: searchField.searchIconSize
				height: searchField.searchIconSize
				source: "search-symbolic"
				color: searchField.foregroundColor
				opacity: 0.6
				enabled: false
			}

			Item {
				id: clearButton
				anchors.right: parent.right
				anchors.rightMargin: searchField.searchIconPadding
				anchors.verticalCenter: parent.verticalCenter
				width: searchField.searchIconSize
				height: searchField.searchIconSize
				visible: themedTextField.text && themedTextField.text.length > 0
				z: 2

				Kirigami.Icon {
					anchors.fill: parent
					source: "edit-clear"
					color: searchField.foregroundColor
					opacity: clearMouseArea.containsMouse ? 0.9 : 0.7
				}

				MouseArea {
					id: clearMouseArea
					anchors.fill: parent
					onClicked: {
						themedTextField.text = ""
						themedTextField.forceActiveFocus()
					}
					cursorShape: Qt.PointingHandCursor
					hoverEnabled: true
				}
			}

			Keys.onPressed: function(event) {
				if (event.key == Qt.Key_Up) {
					event.accepted = true; searchField.listView.goUp()
				} else if (event.key == Qt.Key_Down) {
					event.accepted = true; searchField.listView.goDown()
				} else if (event.key == Qt.Key_PageUp) {
					event.accepted = true; searchField.listView.pageUp()
				} else if (event.key == Qt.Key_PageDown) {
					event.accepted = true; searchField.listView.pageDown()
				} else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
					event.accepted = true; searchField.listView.triggerCurrentIndex()
				} else if (event.modifiers & Qt.MetaModifier && event.key == Qt.Key_R) {
					event.accepted = true; search.filters = ['shell']
				} else if (event.key == Qt.Key_Escape) {
					if (searchField.text && searchField.text.length > 0) {
						event.accepted = true
						searchField.escapeClearsSearchRequested()
					} else {
						plasmoid.expanded = false
					}
				}
			}
		}
	}

	Component {
		id: windowsField
		PlasmaComponents3.TextField {
			id: windowsTextField
			placeholderText: i18n("Search...")
			font.pixelSize: searchField.computedFontSize
			leftPadding: searchField.searchIconSize + (searchField.searchIconPadding * 2)
			rightPadding: clearButton.visible
				? searchField.searchIconSize + (searchField.searchIconPadding * 2)
				: searchField.searchIconPadding
			background: SidebarGlassCard {
				baseColor: "#ffffff"
				contentMargins: 0
				fillOpacity: 1.0
			}
			color: "#111"
			placeholderTextColor: "#777"
			onTextChanged: searchField.onTextChangedInternal(text)

			Kirigami.Icon {
				anchors.left: parent.left
				anchors.leftMargin: searchField.searchIconPadding
				anchors.verticalCenter: parent.verticalCenter
				width: searchField.searchIconSize
				height: searchField.searchIconSize
				source: "search-symbolic"
				color: "#777"
				enabled: false
			}

			Item {
				id: clearButton
				anchors.right: parent.right
				anchors.rightMargin: searchField.searchIconPadding
				anchors.verticalCenter: parent.verticalCenter
				width: searchField.searchIconSize
				height: searchField.searchIconSize
				visible: windowsTextField.text && windowsTextField.text.length > 0
				z: 2

				Kirigami.Icon {
					anchors.fill: parent
					source: "edit-clear"
					color: "#777"
					opacity: clearMouseArea.containsMouse ? 1.0 : 0.9
				}

				MouseArea {
					id: clearMouseArea
					anchors.fill: parent
					onClicked: {
						windowsTextField.text = ""
						windowsTextField.forceActiveFocus()
					}
					cursorShape: Qt.PointingHandCursor
					hoverEnabled: true
				}
			}

			Keys.onPressed: function(event) {
				if (event.key == Qt.Key_Up) {
					event.accepted = true; searchField.listView.goUp()
				} else if (event.key == Qt.Key_Down) {
					event.accepted = true; searchField.listView.goDown()
				} else if (event.key == Qt.Key_PageUp) {
					event.accepted = true; searchField.listView.pageUp()
				} else if (event.key == Qt.Key_PageDown) {
					event.accepted = true; searchField.listView.pageDown()
				} else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
					event.accepted = true; searchField.listView.triggerCurrentIndex()
				} else if (event.modifiers & Qt.MetaModifier && event.key == Qt.Key_R) {
					event.accepted = true; search.filters = ['shell']
				} else if (event.key == Qt.Key_Escape) {
					if (searchField.text && searchField.text.length > 0) {
						event.accepted = true
						searchField.escapeClearsSearchRequested()
					} else {
						plasmoid.expanded = false
					}
				}
			}
		}
	}
}
