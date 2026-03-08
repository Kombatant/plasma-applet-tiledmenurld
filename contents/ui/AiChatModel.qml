import QtQuick

Item {
	id: aiChatModel
	visible: false

	property bool busy: false
	property string busyText: ""
	property string lastError: ""
	property string streamingContent: ""
	property var activeChatRequest: null
	readonly property bool canStopResponse: !!activeChatRequest

	readonly property string provider: (plasmoid.configuration.aiProvider || "openai").toLowerCase()
	readonly property string apiKey: plasmoid.configuration.aiApiKey || ""
	readonly property string ollamaUrl: (plasmoid.configuration.aiOllamaUrl || "http://127.0.0.1:11434").replace(/\/+$/, "")
	readonly property string selectedModel: plasmoid.configuration.aiModel || ""
	readonly property var detectedModels: plasmoid.configuration.aiDetectedModels || []
	readonly property bool streamEnabled: !!plasmoid.configuration.aiStreamChat

	property var conversationList: []
	property string activeConversationId: ""

	signal conversationsChanged()
	signal modelDetectionFinished(bool success)
	signal sendFinished(bool success)
	signal streamingContentUpdated()

	Base64JsonString {
		id: chatHistory
		configKey: "aiChatHistory"
		defaultValue: {
			return {
				conversations: [],
				activeConversationId: "",
			}
		}
		onLoaded: {
			aiChatModel._applyLoadedHistory(value)
		}
	}

	Timer {
		id: saveDebounce
		interval: 250
		repeat: false
		onTriggered: aiChatModel._saveHistory()
	}

	Component.onCompleted: {
		if (!conversationList || !conversationList.length) {
			newConversation()
		}
	}

	function _applyLoadedHistory(value) {
		var history = value || {}
		var conversations = history.conversations || []
		if (!(conversations instanceof Array)) {
			conversations = []
		}

		conversationList = conversations
		activeConversationId = history.activeConversationId || ""
		if (!activeConversation() && conversationList.length > 0) {
			activeConversationId = conversationList[0].id
		}
		if (!activeConversation()) {
			newConversation()
		}
		conversationsChanged()
	}

	function _saveHistory() {
		chatHistory.value = {
			conversations: conversationList,
			activeConversationId: activeConversationId,
		}
		chatHistory.save()
	}

	function _queueSave() {
		saveDebounce.restart()
	}

	function _newId() {
		return "chat-" + Date.now() + "-" + Math.floor(Math.random() * 100000)
	}

	function _conversationTitle(conversation) {
		if (!conversation || !conversation.messages) {
			return i18n("New Chat")
		}
		for (var i = 0; i < conversation.messages.length; i++) {
			var msg = conversation.messages[i]
			if (msg && msg.role === "user" && msg.content) {
				var title = ("" + msg.content).trim().replace(/\s+/g, " ")
				if (title.length > 48) {
					title = title.substr(0, 47) + "..."
				}
				return title
			}
		}
		return i18n("New Chat")
	}

	function activeConversation() {
		for (var i = 0; i < conversationList.length; i++) {
			if (conversationList[i].id === activeConversationId) {
				return conversationList[i]
			}
		}
		return null
	}

	function sortedConversations() {
		var copy = conversationList.slice(0)
		copy.sort(function(a, b) {
			return (b.updatedAt || 0) - (a.updatedAt || 0)
		})
		return copy
	}

	function conversationOptions() {
		var sorted = sortedConversations()
		var options = []
		for (var i = 0; i < sorted.length; i++) {
			var c = sorted[i]
			options.push({
				value: c.id,
				text: c.title || _conversationTitle(c),
			})
		}
		return options
	}

	function setActiveConversation(id) {
		if (!id || id === activeConversationId) {
			return
		}
		activeConversationId = id
		conversationsChanged()
		_queueSave()
	}

	function newConversation() {
		var now = Date.now()
		var conversation = {
			id: _newId(),
			title: i18n("New Chat"),
			createdAt: now,
			updatedAt: now,
			messages: [],
		}
		conversationList = [conversation].concat(conversationList)
		activeConversationId = conversation.id
		conversationsChanged()
		_queueSave()
	}

	function deleteConversation(id) {
		if (!id) {
			return
		}

		var remaining = []
		for (var i = 0; i < conversationList.length; i++) {
			var c = conversationList[i]
			if (c && c.id !== id) {
				remaining.push(c)
			}
		}

		if (remaining.length === conversationList.length) {
			return
		}

		conversationList = remaining
		if (activeConversationId === id) {
			activeConversationId = remaining.length ? remaining[0].id : ""
		}

		if (!activeConversation()) {
			newConversation()
			return
		}

		conversationsChanged()
		_queueSave()
	}

	function _activeMessages() {
		var active = activeConversation()
		if (!active) {
			return []
		}
		return active.messages || []
	}

	function _updateActiveConversation(messages) {
		var now = Date.now()
		var updated = []
		for (var i = 0; i < conversationList.length; i++) {
			var conversation = conversationList[i]
			if (conversation.id === activeConversationId) {
				conversation.messages = messages
				conversation.updatedAt = now
				conversation.title = _conversationTitle(conversation)
			}
			updated.push(conversation)
		}
		conversationList = updated
		conversationsChanged()
		_queueSave()
	}

	function _appendMessage(role, content) {
		var messages = _activeMessages().slice(0)
		messages.push({
			role: role,
			content: content,
			ts: Date.now(),
		})
		_updateActiveConversation(messages)
	}

	function _requireConfig() {
		if (!selectedModel) {
			lastError = i18n("Please choose a model in settings.")
			return false
		}
		if (provider !== "ollama" && !apiKey) {
			lastError = i18n("Please enter an API key in settings.")
			return false
		}
		return true
	}

	function sendMessage(text) {
		var userText = (text || "").trim()
		if (!userText || busy) {
			return
		}
		lastError = ""
		if (!_requireConfig()) {
			sendFinished(false)
			return
		}

		_appendMessage("user", userText)
		busy = true

		var active = activeConversation()
		var messages = active && active.messages ? active.messages : []
		var endpoint = _providerEndpoint("chat")
		var useStream = streamEnabled

		if (useStream) {
			busyText = ""
			streamingContent = ""
			streamingContentUpdated()
			_sendStreaming(endpoint, messages)
		} else {
			busyText = i18n("Waiting for response...")
			_sendNonStreaming(endpoint, messages)
		}
	}

	function stopResponse() {
		if (!activeChatRequest) {
			return
		}

		var req = activeChatRequest
		req._chatRequestAborted = true
		activeChatRequest = null
		busy = false
		busyText = ""
		lastError = ""

		var partialText = (streamingContent || "").trim()
		streamingContent = ""
		streamingContentUpdated()
		if (partialText) {
			_appendMessage("assistant", partialText)
		}

		try {
			req.abort()
		} catch (e) {
		}

		sendFinished(false)
	}

	function _finishChatRequest(req) {
		if (activeChatRequest === req) {
			activeChatRequest = null
		}
		busy = false
		busyText = ""
	}

	function _sendNonStreaming(endpoint, messages) {
		var req = new XMLHttpRequest()
		activeChatRequest = req
		req.open("POST", endpoint)
		_applyProviderHeaders(req)
		req.setRequestHeader("Content-Type", "application/json")

		req.onreadystatechange = function() {
			if (req.readyState !== XMLHttpRequest.DONE) {
				return
			}
			if (req._chatRequestAborted) {
				_finishChatRequest(req)
				return
			}
			_finishChatRequest(req)
			if (req.status < 200 || req.status >= 300) {
				lastError = _httpErrorText(req)
				sendFinished(false)
				return
			}
			var reply = _extractReplyText(req.responseText)
			if (!reply) {
				lastError = i18n("The provider returned an empty response.")
				sendFinished(false)
				return
			}
			_appendMessage("assistant", reply)
			sendFinished(true)
		}

		var payload = _buildChatPayload(messages, false)
		req.send(JSON.stringify(payload))
	}

	function _sendStreaming(endpoint, messages) {
		var req = new XMLHttpRequest()
		activeChatRequest = req
		req.open("POST", endpoint)
		_applyProviderHeaders(req)
		req.setRequestHeader("Content-Type", "application/json")

		var processed = 0

		req.onreadystatechange = function() {
			if (req._chatRequestAborted) {
				if (req.readyState === XMLHttpRequest.DONE) {
					_finishChatRequest(req)
				}
				return
			}
			if (req.readyState === 3 || req.readyState === XMLHttpRequest.DONE) {
				var raw = req.responseText || ""
				if (raw.length > processed) {
					var chunk = raw.substring(processed)
					processed = raw.length
					var delta = _extractStreamDelta(chunk)
					if (delta) {
						streamingContent += delta
						streamingContentUpdated()
					}
				}
			}
			if (req.readyState === XMLHttpRequest.DONE) {
				_finishChatRequest(req)
				if (req.status < 200 || req.status >= 300) {
					streamingContent = ""
					streamingContentUpdated()
					lastError = _httpErrorText(req)
					sendFinished(false)
					return
				}
				var finalText = streamingContent.trim()
				streamingContent = ""
				streamingContentUpdated()
				if (!finalText) {
					lastError = i18n("The provider returned an empty response.")
					sendFinished(false)
					return
				}
				_appendMessage("assistant", finalText)
				sendFinished(true)
			}
		}

		var payload = _buildChatPayload(messages, true)
		req.send(JSON.stringify(payload))
	}

	function _extractStreamDelta(chunk) {
		var p = provider
		if (p === "ollama") {
			return _extractOllamaStreamDelta(chunk)
		}
		if (p === "google") {
			return _extractGoogleStreamDelta(chunk)
		}
		if (p === "anthropic") {
			return _extractAnthropicStreamDelta(chunk)
		}
		// OpenAI / OpenRouter / Perplexity (SSE format)
		return _extractSSEDelta(chunk)
	}

	function _extractSSEDelta(chunk) {
		var text = ""
		var lines = chunk.split("\n")
		for (var i = 0; i < lines.length; i++) {
			var line = lines[i].trim()
			if (line === "data: [DONE]") {
				continue
			}
			if (line.indexOf("data: ") === 0) {
				var jsonStr = line.substring(6)
				try {
					var obj = JSON.parse(jsonStr)
					var choices = obj.choices || []
					if (choices.length > 0 && choices[0].delta && choices[0].delta.content) {
						text += choices[0].delta.content
					}
				} catch (e) {
					// partial JSON, skip
				}
			}
		}
		return text
	}

	function _extractAnthropicStreamDelta(chunk) {
		var text = ""
		var lines = chunk.split("\n")
		for (var i = 0; i < lines.length; i++) {
			var line = lines[i].trim()
			if (line.indexOf("data: ") === 0) {
				var jsonStr = line.substring(6)
				try {
					var obj = JSON.parse(jsonStr)
					if (obj.type === "content_block_delta" && obj.delta && obj.delta.text) {
						text += obj.delta.text
					}
				} catch (e) {
					// partial JSON, skip
				}
			}
		}
		return text
	}

	function _extractOllamaStreamDelta(chunk) {
		var text = ""
		var lines = chunk.split("\n")
		for (var i = 0; i < lines.length; i++) {
			var line = lines[i].trim()
			if (!line) {
				continue
			}
			try {
				var obj = JSON.parse(line)
				if (obj.message && obj.message.content) {
					text += obj.message.content
				}
			} catch (e) {
				// partial JSON, skip
			}
		}
		return text
	}

	function _extractGoogleStreamDelta(chunk) {
		var text = ""
		var lines = chunk.split("\n")
		for (var i = 0; i < lines.length; i++) {
			var line = lines[i].trim()
			if (line.indexOf("\"text\"") >= 0) {
				// Google streams JSON array items; try parsing each data line
				if (line.indexOf("data: ") === 0) {
					line = line.substring(6)
				}
				try {
					var obj = JSON.parse(line)
					var candidates = obj.candidates || []
					if (candidates.length > 0 && candidates[0].content && candidates[0].content.parts) {
						var parts = candidates[0].content.parts
						for (var j = 0; j < parts.length; j++) {
							if (parts[j].text) {
								text += parts[j].text
							}
						}
					}
				} catch (e) {
					// partial JSON, skip
				}
			}
		}
		return text
	}

	function fetchModels() {
		lastError = ""
		if (provider !== "ollama" && !apiKey) {
			lastError = i18n("Please enter an API key before detecting models.")
			modelDetectionFinished(false)
			return
		}
		busy = true
		busyText = i18n("Detecting models...")

		var req = new XMLHttpRequest()
		req.open("GET", _providerEndpoint("models"))
		_applyProviderHeaders(req)

		req.onreadystatechange = function() {
			if (req.readyState !== XMLHttpRequest.DONE) {
				return
			}
			busy = false
			busyText = ""
			if (req.status < 200 || req.status >= 300) {
				lastError = _httpErrorText(req)
				modelDetectionFinished(false)
				return
			}
			var models = _extractModels(req.responseText)
			if (!models.length) {
				lastError = i18n("No models were detected for this provider.")
				modelDetectionFinished(false)
				return
			}
			plasmoid.configuration.aiDetectedModels = models
			if (!selectedModel || models.indexOf(selectedModel) < 0) {
				plasmoid.configuration.aiModel = models[0]
			}
			modelDetectionFinished(true)
		}

		req.send()
	}

	function _providerEndpoint(kind) {
		var p = provider
		var isStream = (kind === "chat") && streamEnabled
		if (p === "openai") {
			return kind === "models" ? "https://api.openai.com/v1/models" : "https://api.openai.com/v1/chat/completions"
		}
		if (p === "openrouter") {
			return kind === "models" ? "https://openrouter.ai/api/v1/models" : "https://openrouter.ai/api/v1/chat/completions"
		}
		if (p === "perplexity") {
			return kind === "models" ? "https://api.perplexity.ai/models" : "https://api.perplexity.ai/chat/completions"
		}
		if (p === "anthropic") {
			return kind === "models" ? "https://api.anthropic.com/v1/models" : "https://api.anthropic.com/v1/messages"
		}
		if (p === "google") {
			if (kind === "models") {
				return "https://generativelanguage.googleapis.com/v1beta/models?key=" + encodeURIComponent(apiKey)
			}
			var modelName = selectedModel || "gemini-2.0-flash"
			if (modelName.indexOf("models/") !== 0) {
				modelName = "models/" + modelName
			}
			var googleAction = isStream ? "streamGenerateContent?alt=sse&key=" : "generateContent?key="
			return "https://generativelanguage.googleapis.com/v1beta/" + modelName + ":" + googleAction + encodeURIComponent(apiKey)
		}
		// ollama
		return kind === "models" ? (ollamaUrl + "/api/tags") : (ollamaUrl + "/api/chat")
	}

	function _applyProviderHeaders(req) {
		var p = provider
		if (p === "openai" || p === "openrouter" || p === "perplexity") {
			if (apiKey) {
				req.setRequestHeader("Authorization", "Bearer " + apiKey)
			}
			if (p === "openrouter") {
				req.setRequestHeader("HTTP-Referer", "https://github.com/Kombatant/plasma-applet-tiledmenurld")
				req.setRequestHeader("X-Title", "Tiled Menu Reloaded")
			}
			return
		}
		if (p === "anthropic") {
			req.setRequestHeader("x-api-key", apiKey)
			req.setRequestHeader("anthropic-version", "2023-06-01")
		}
	}

	function _extractModels(responseText) {
		var parsed = _parseJson(responseText)
		if (!parsed) {
			return []
		}
		var source = []
		if (provider === "ollama" && parsed.models) {
			source = parsed.models
		} else if (provider === "google" && parsed.models) {
			source = parsed.models
		} else if (parsed.data) {
			source = parsed.data
		}

		var unique = {}
		var names = []
		for (var i = 0; i < source.length; i++) {
			var model = source[i]
			var id = ""
			if (provider === "ollama") {
				id = (model && model.name) ? ("" + model.name) : ""
			} else if (provider === "google") {
				id = (model && model.name) ? ("" + model.name) : ""
			} else {
				id = (model && model.id) ? ("" + model.id) : ""
			}
			if (id && !unique[id]) {
				unique[id] = true
				names.push(id)
			}
		}
		names.sort()
		return names
	}

	function _buildChatPayload(messages, stream) {
		var p = provider
		if (p === "google") {
			var contents = []
			for (var k = 0; k < messages.length; k++) {
				var gmsg = messages[k]
				contents.push({
					role: gmsg.role === "assistant" ? "model" : "user",
					parts: [{ text: gmsg.content }],
				})
			}
			return {
				contents: contents,
			}
		}
		var normalizedMessages = []
		for (var i = 0; i < messages.length; i++) {
			var message = messages[i]
			normalizedMessages.push({
				role: message.role,
				content: message.content,
			})
		}

		if (p === "anthropic") {
			var anthropicPayload = {
				model: selectedModel,
				max_tokens: 1024,
				messages: normalizedMessages,
			}
			if (stream) {
				anthropicPayload.stream = true
			}
			return anthropicPayload
		}
		if (p === "ollama") {
			return {
				model: selectedModel,
				messages: normalizedMessages,
				stream: !!stream,
			}
		}
		var payload = {
			model: selectedModel,
			messages: normalizedMessages,
			temperature: 0.7,
		}
		if (stream) {
			payload.stream = true
		}
		return payload
	}

	function _extractReplyText(responseText) {
		var parsed = _parseJson(responseText)
		if (!parsed) {
			return ""
		}
		if (provider === "google") {
			var candidates = parsed.candidates || []
			if (!candidates.length || !candidates[0].content || !candidates[0].content.parts) {
				return ""
			}
			var gtext = ""
			for (var gi = 0; gi < candidates[0].content.parts.length; gi++) {
				var part = candidates[0].content.parts[gi]
				if (part && part.text) {
					gtext += part.text
				}
			}
			return gtext.trim()
		}
		if (provider === "anthropic") {
			var chunks = parsed.content || []
			var text = ""
			for (var i = 0; i < chunks.length; i++) {
				if (chunks[i] && chunks[i].text) {
					text += chunks[i].text
				}
			}
			return text.trim()
		}
		if (provider === "ollama") {
			return parsed.message && parsed.message.content ? ("" + parsed.message.content).trim() : ""
		}
		var choices = parsed.choices || []
		if (!choices.length) {
			return ""
		}
		var content = choices[0].message ? choices[0].message.content : ""
		if (typeof content === "string") {
			return content.trim()
		}
		if (content instanceof Array) {
			var joined = ""
			for (var j = 0; j < content.length; j++) {
				if (content[j] && content[j].text) {
					joined += content[j].text
				}
			}
			return joined.trim()
		}
		return ""
	}

	function _parseJson(text) {
		try {
			return JSON.parse(text)
		} catch (e) {
			lastError = i18n("Invalid JSON response from provider.")
			return null
		}
	}

	function _httpErrorText(req) {
		var status = req && req.status ? req.status : 0
		var response = req && req.responseText ? ("" + req.responseText).trim() : ""
		if (response.length > 240) {
			response = response.substr(0, 237) + "..."
		}
		if (!response) {
			return i18n("Request failed (%1).", status)
		}
		return i18n("Request failed (%1): %2", status, response)
	}
}
