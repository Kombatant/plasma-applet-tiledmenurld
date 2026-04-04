import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons as KQuickControlsAddons

Item {
	id: aiChatView
	clip: true

	property var chatModel
	property var conversationOptions: []
	property var messages: []
	property string streamingText: ""
	property string composerHistoryDraft: ""
	property int composerHistoryIndex: -1
	property bool _settingComposerFromHistory: false
	property int copiedMessageIndex: -1
	readonly property var detectedModels: chatModel ? (chatModel.detectedModels || []) : []
	readonly property var detectedModelOptions: {
		var options = []
		for (var i = 0; i < detectedModels.length; i++) {
			var modelId = "" + detectedModels[i]
			options.push({
				value: modelId,
				text: displayModelName(modelId),
			})
		}
		return options
	}
	readonly property bool readyToSend: {
		if (!chatModel) {
			return false
		}
		if (!chatModel.selectedModel) {
			return false
		}
		if (chatModel.apiKeyRequired && !chatModel.apiKey) {
			return false
		}
		return true
	}

	property var listView: messageList

	KQuickControlsAddons.Clipboard {
		id: clipboard
	}

	Timer {
		id: copyFeedbackTimer
		interval: 1500
		repeat: false
		onTriggered: aiChatView.copiedMessageIndex = -1
	}

	function focusComposer() {
		composer.forceActiveFocus()
	}

	function focusAndInsert(text) {
		focusComposer()
		if (typeof composer.insert === "function") {
			composer.insert(composer.cursorPosition, text)
		} else {
			composer.text = composer.text + text
		}
	}

	function sendCurrentMessage() {
		var text = composer.text
		if (!text || !text.trim() || !chatModel || chatModel.busy) {
			return
		}
		resetComposerHistory()
		composer.clear()
		chatModel.sendMessage(text)
	}

	function copyAssistantMessage(index, text) {
		clipboard.content = text || ""
		copiedMessageIndex = index
		copyFeedbackTimer.restart()
	}

	function stopCurrentResponse() {
		if (!chatModel || !chatModel.canStopResponse) {
			return
		}
		chatModel.stopResponse()
		focusComposer()
	}

	function resetComposerHistory() {
		composerHistoryDraft = ""
		composerHistoryIndex = -1
	}

	function userMessageHistory() {
		var active = chatModel ? chatModel.activeConversation() : null
		var source = active && active.messages ? active.messages : []
		var history = []
		for (var i = 0; i < source.length; i++) {
			var item = source[i]
			if (item && item.role === "user" && item.content) {
				history.push("" + item.content)
			}
		}
		return history
	}

	function _cursorOnFirstLine() {
		return composer.text.lastIndexOf("\n", Math.max(0, composer.cursorPosition - 1)) < 0
	}

	function _cursorOnLastLine() {
		return composer.text.indexOf("\n", composer.cursorPosition) < 0
	}

	function _applyComposerHistoryText(text) {
		_settingComposerFromHistory = true
		composer.text = text
		composer.cursorPosition = composer.text.length
		composer.forceActiveFocus()
		_settingComposerFromHistory = false
	}

	function navigateComposerHistory(step) {
		if (!composer || composer.selectionStart !== composer.selectionEnd) {
			return false
		}

		if (step < 0 && !_cursorOnFirstLine()) {
			return false
		}
		if (step > 0 && !_cursorOnLastLine()) {
			return false
		}

		var history = userMessageHistory()
		if (!history.length) {
			return false
		}

		if (step < 0) {
			if (composerHistoryIndex < 0) {
				composerHistoryDraft = composer.text
				composerHistoryIndex = history.length - 1
			} else if (composerHistoryIndex > 0) {
				composerHistoryIndex -= 1
			}
			_applyComposerHistoryText(history[composerHistoryIndex])
			return true
		}

		if (composerHistoryIndex < 0) {
			return false
		}

		if (composerHistoryIndex < history.length - 1) {
			composerHistoryIndex += 1
			_applyComposerHistoryText(history[composerHistoryIndex])
			return true
		}

		composerHistoryIndex = -1
		_applyComposerHistoryText(composerHistoryDraft)
		composerHistoryDraft = ""
		return true
	}

	function displayModelName(modelId) {
		if (!modelId) {
			return ""
		}
		var s = "" + modelId
		var slash = s.lastIndexOf("/")
		return slash >= 0 ? s.substr(slash + 1) : s
	}

	function refreshConversationOptions() {
		conversationOptions = chatModel ? chatModel.conversationOptions() : []
		Qt.callLater(function() {
			if (conversationCombo && typeof conversationCombo.refreshCurrentIndex === "function") {
				conversationCombo.refreshCurrentIndex()
			}
		})
	}

	function refreshMessages() {
		var active = chatModel ? chatModel.activeConversation() : null
		messages = active && active.messages ? active.messages : []
		Qt.callLater(function() {
			if (messageList && messageList.count > 0) {
				messageList.positionViewAtEnd()
			}
		})
	}

	function syncModelSelection() {
		if (!modelCombo || !chatModel || !modelCombo.model || !modelCombo.model.length) {
			return
		}
		for (var i = 0; i < modelCombo.model.length; i++) {
			if (modelCombo.model[i].value === chatModel.selectedModel) {
				modelCombo.currentIndex = i
				return
			}
		}
	}

	function selectedConversationId() {
		if (!conversationCombo || !conversationCombo.model || conversationCombo.currentIndex < 0 || conversationCombo.currentIndex >= conversationCombo.model.length) {
			return ""
		}
		var selected = conversationCombo.model[conversationCombo.currentIndex].value
		if (selected === "__new__") {
			return ""
		}
		return selected
	}

	Component.onCompleted: {
		refreshConversationOptions()
		refreshMessages()
	}

	onChatModelChanged: {
		refreshConversationOptions()
		refreshMessages()
	}

	Connections {
		target: chatModel
		function onConversationsChanged() {
			resetComposerHistory()
			refreshConversationOptions()
			refreshMessages()
		}
		function onActiveConversationIdChanged() {
			resetComposerHistory()
			refreshMessages()
		}
		function onStreamingContentUpdated() {
			_updateStreamingView()
		}
	}

	function _updateStreamingView() {
		if (!chatModel) {
			return
		}
		var sc = chatModel.streamingContent || ""
		if (!sc) {
			streamingText = ""
			refreshMessages()
			return
		}
		// First token: add a placeholder streaming message to the array
		if (!streamingText) {
			var active = chatModel.activeConversation()
			var base = active && active.messages ? active.messages.slice(0) : []
			base.push({ role: "assistant", content: "", ts: 0, _streaming: true })
			messages = base
		}
		// Update the streaming text property; delegate reads it reactively
		streamingText = sc
		Qt.callLater(function() {
			if (messageList && messageList.count > 0) {
				messageList.positionViewAtEnd()
			}
		})
	}

	readonly property var chatMenuOptions: {
		var options = [{
			value: "__new__",
			text: i18n("+ Start New Chat"),
		}]
		for (var i = 0; i < conversationOptions.length; i++) {
			options.push(conversationOptions[i])
		}
		return options
	}

	Rectangle {
		anchors.fill: parent
		gradient: Gradient {
			GradientStop {
				position: 0.0
				color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.42)
			}
			GradientStop {
				position: 1.0
				color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.95, Kirigami.Theme.backgroundColor.g * 0.95, Kirigami.Theme.backgroundColor.b * 0.95, 0.5)
			}
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.smallSpacing
		spacing: Kirigami.Units.smallSpacing

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: topRow.implicitHeight + (Kirigami.Units.smallSpacing * 2)
			radius: Kirigami.Units.smallSpacing
			color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.34)
			border.width: 1
			border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)

			RowLayout {
				id: topRow
				anchors.fill: parent
				anchors.margins: Kirigami.Units.smallSpacing
				spacing: Kirigami.Units.smallSpacing

				QQC2.ComboBox {
					id: conversationCombo
					Layout.fillWidth: true
					textRole: "text"
					model: chatMenuOptions
					onActivated: function(index) {
						if (!chatModel || index < 0 || index >= model.length) {
							return
						}
						var selected = model[index].value
						if (selected === "__new__") {
							chatModel.newConversation()
							Qt.callLater(function() {
								conversationCombo.refreshCurrentIndex()
							})
							return
						}
						chatModel.setActiveConversation(selected)
					}
					Component.onCompleted: refreshCurrentIndex()
					function refreshCurrentIndex() {
						if (!chatModel) {
							return
						}
						for (var i = 0; i < model.length; i++) {
							if (model[i].value === chatModel.activeConversationId) {
								currentIndex = i
								return
							}
						}
						currentIndex = 0
					}
					Connections {
						target: chatModel
						function onConversationsChanged() {
							conversationCombo.refreshCurrentIndex()
						}
					}
				}

				QQC2.ToolButton {
					icon.name: "edit-delete"
					enabled: !!selectedConversationId() && conversationOptions.length > 0
					display: QQC2.AbstractButton.IconOnly
					onClicked: {
						if (!chatModel) {
							return
						}
						var id = selectedConversationId()
						if (!id) {
							return
						}
						chatModel.deleteConversation(id)
					}
					QQC2.ToolTip.visible: hovered
					QQC2.ToolTip.text: i18n("Delete This Conversation")
				}
			}
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.fillHeight: true
			radius: Kirigami.Units.smallSpacing
			color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.18)
			border.width: 1
			border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

			ListView {
				id: messageList
				anchors.fill: parent
				anchors.margins: Kirigami.Units.largeSpacing
				spacing: Kirigami.Units.largeSpacing * 0.6
				model: messages
				clip: true

				delegate: Item {
					required property var modelData
					required property int index
					width: messageList.width
					height: bubble.implicitHeight + roleLabel.implicitHeight + Kirigami.Units.smallSpacing * 0.35

					readonly property bool isUser: modelData.role === "user"
					readonly property bool isStreaming: !!modelData._streaming
					readonly property string displayContent: isStreaming ? aiChatView.streamingText : (modelData.content || "")
					readonly property bool showCopyButton: !isUser && !!displayContent

					QQC2.Label {
						id: roleLabel
						anchors.top: parent.top
						anchors.left: bubble.left
						anchors.right: bubble.right
						text: isUser ? i18n("You") : i18n("Assistant")
						font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 0.88)
						opacity: 0.55
					}

					Rectangle {
						id: bubble
						readonly property real bubblePadding: Kirigami.Units.smallSpacing * 1.2
						anchors.top: roleLabel.bottom
						anchors.topMargin: Kirigami.Units.smallSpacing * 0.35
						anchors.right: isUser ? parent.right : undefined
						anchors.left: !isUser ? parent.left : undefined
						width: Math.min(parent.width * 0.88, Math.max(240, Math.max(messageText.implicitWidth, copyButton.implicitWidth + Kirigami.Units.largeSpacing) + (Kirigami.Units.largeSpacing * 2)))
						implicitHeight: messageText.implicitHeight + (bubblePadding * 2) + (showCopyButton ? (copyButton.implicitHeight + Kirigami.Units.smallSpacing * 0.5) : 0)
						radius: Kirigami.Units.largeSpacing * 0.7
						color: isUser
							? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.16)
							: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
						border.width: 1
						border.color: isUser
							? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.36)
							: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.11)

						TextEdit {
							id: messageText
							anchors.top: parent.top
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.bottom: parent.bottom
							anchors.leftMargin: bubble.bubblePadding
							anchors.topMargin: bubble.bubblePadding
							anchors.rightMargin: bubble.bubblePadding
							anchors.bottomMargin: bubble.bubblePadding + (showCopyButton ? (copyButton.implicitHeight + Kirigami.Units.smallSpacing * 0.5) : 0)
							readOnly: true
							selectByMouse: true
							persistentSelection: true
							activeFocusOnPress: false
							cursorVisible: false
							text: displayContent
							textFormat: TextEdit.MarkdownText
							wrapMode: Text.Wrap
							color: Kirigami.Theme.textColor
							font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.02)
							onLinkActivated: function(link) {
								Qt.openUrlExternally(link)
							}
						}

						QQC2.ToolButton {
							id: copyButton
							visible: showCopyButton
							anchors.right: parent.right
							anchors.bottom: parent.bottom
							anchors.rightMargin: bubble.bubblePadding * 0.8
							anchors.bottomMargin: bubble.bubblePadding * 0.55
							icon.name: "edit-copy"
							display: QQC2.AbstractButton.IconOnly
							flat: true
							focusPolicy: Qt.NoFocus
							onClicked: aiChatView.copyAssistantMessage(index, displayContent)
							QQC2.ToolTip.visible: hovered
							QQC2.ToolTip.text: aiChatView.copiedMessageIndex === index ? i18n("Copied") : i18n("Copy")
						}
					}
				}

				QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
				onCountChanged: Qt.callLater(function() { positionViewAtEnd() })
			}

			QQC2.Label {
				anchors.centerIn: parent
				visible: !messageList.count
				text: i18n("Start a new conversation")
				opacity: 0.55
				font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
			}
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: composerRow.implicitHeight + (Kirigami.Units.smallSpacing * 1.4)
			radius: Kirigami.Units.smallSpacing
			color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.38)
			border.width: 1
			border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)

			ColumnLayout {
				id: composerRow
				anchors.fill: parent
				anchors.margins: Kirigami.Units.smallSpacing
				spacing: Kirigami.Units.smallSpacing * 0.75

				QQC2.Label {
					Layout.fillWidth: true
					visible: !readyToSend || (chatModel && (chatModel.busy || !!chatModel.lastError))
					text: {
						if (!readyToSend) {
							return i18n("Configure provider, API key and model in settings before sending.")
						}
						if (chatModel && chatModel.lastError) {
							return chatModel.lastError
						}
						if (chatModel && chatModel.busy && chatModel.busyText) {
							return chatModel.busyText
						}
						return ""
					}
					color: chatModel && chatModel.lastError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
					wrapMode: Text.Wrap
					opacity: 0.78
				}

				RowLayout {
					Layout.fillWidth: true
					spacing: Kirigami.Units.smallSpacing

					QQC2.ComboBox {
						id: modelCombo
						Layout.fillWidth: true
						textRole: "text"
						model: detectedModelOptions
						enabled: !!model.length
						onActivated: function(index) {
							if (!chatModel || index < 0 || index >= model.length) {
								return
							}
							plasmoid.configuration.aiModel = model[index].value
						}
						Component.onCompleted: syncModelSelection()
						onModelChanged: syncModelSelection()
						Connections {
							target: chatModel
							function onSelectedModelChanged() {
								syncModelSelection()
							}
						}
					}
				}

				RowLayout {
					Layout.fillWidth: true
					Item {
						Layout.fillWidth: true
						Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit * 3.2, composer.implicitHeight)

						QQC2.TextArea {
							id: composer
							anchors.fill: parent
							placeholderText: i18n("Ask anything... (Enter to send, Shift+Enter for newline)")
							wrapMode: TextEdit.Wrap
							selectByMouse: true
							rightPadding: sendStopButton.width + (Kirigami.Units.smallSpacing * 1.5)
							onTextChanged: {
								if (!_settingComposerFromHistory && composerHistoryIndex >= 0) {
									composerHistoryDraft = composer.text
									composerHistoryIndex = -1
								}
							}
							Keys.onPressed: function(event) {
								if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
									event.accepted = true
									sendCurrentMessage()
									return
								}
								if (!(event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
									&& (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
									&& navigateComposerHistory(event.key === Qt.Key_Up ? -1 : 1)) {
									event.accepted = true
								}
							}
						}

						QQC2.ToolButton {
							id: sendStopButton
							anchors.right: parent.right
							anchors.rightMargin: Kirigami.Units.smallSpacing * 0.6
							anchors.bottom: parent.bottom
							anchors.bottomMargin: Kirigami.Units.smallSpacing * 0.45
							display: QQC2.AbstractButton.IconOnly
							icon.name: chatModel && chatModel.canStopResponse ? "media-playback-stop" : "mail-send"
							enabled: chatModel && (chatModel.canStopResponse || (readyToSend && composer.text.trim().length > 0 && !chatModel.busy))
							onClicked: {
								if (chatModel && chatModel.canStopResponse) {
									stopCurrentResponse()
									return
								}
								sendCurrentMessage()
							}
							QQC2.ToolTip.visible: hovered
							QQC2.ToolTip.text: chatModel && chatModel.canStopResponse ? i18n("Stop Response") : i18n("Send Message")
						}
					}
				}
			}
		}
	}

	MouseArea {
		anchors.fill: parent
		z: 1000
		acceptedButtons: Qt.RightButton
		hoverEnabled: false
		cursorShape: Qt.ArrowCursor
		onPressed: function(mouse) {
			mouse.accepted = true
		}
		onReleased: function(mouse) {
			mouse.accepted = true
		}
		onClicked: function(mouse) {
			mouse.accepted = true
		}
	}
}
