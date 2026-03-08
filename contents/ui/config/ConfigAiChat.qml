import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../libconfig" as LibConfig

LibConfig.FormKCM {
	id: form

	readonly property var providerOptions: [
		{ value: "openai", text: "OpenAI" },
		{ value: "openrouter", text: "OpenRouter" },
		{ value: "google", text: "Google (Gemini API)" },
		{ value: "perplexity", text: "Perplexity" },
		{ value: "anthropic", text: "Anthropic" },
		{ value: "ollama", text: "Ollama (Local)" },
	]

	readonly property bool keyRequired: (plasmoid.configuration.aiProvider || "openai") !== "ollama"
	readonly property var detectedModels: plasmoid.configuration.aiDetectedModels || []
	property bool isDetectingModels: false
	property string detectionStatus: ""
	property string _lastDetectionSignature: ""
	property int _requestToken: 0
	readonly property var modelOptionsData: {
		var options = []
		for (var i = 0; i < detectedModels.length; i++) {
			var modelId = "" + detectedModels[i]
			options.push({
				value: modelId,
				text: _displayModelName(modelId),
			})
		}
		return options
	}

	function _displayModelName(modelId) {
		if (!modelId) {
			return ""
		}
		var s = "" + modelId
		var slash = s.lastIndexOf("/")
		return slash >= 0 ? s.substr(slash + 1) : s
	}

	function _providerValue() {
		return (providerCombo.value || plasmoid.configuration.aiProvider || "openai").toLowerCase()
	}

	function _apiKeyValue() {
		return (apiKeyField.text || "").trim()
	}

	function _needsKey(provider) {
		return provider !== "ollama"
	}

	function _modelsEndpoint(provider, apiKey) {
		if (provider === "openai") {
			return "https://api.openai.com/v1/models"
		}
		if (provider === "openrouter") {
			return "https://openrouter.ai/api/v1/models"
		}
		if (provider === "perplexity") {
			return "https://api.perplexity.ai/models"
		}
		if (provider === "anthropic") {
			return "https://api.anthropic.com/v1/models"
		}
		if (provider === "google") {
			return "https://generativelanguage.googleapis.com/v1beta/models?key=" + encodeURIComponent(apiKey)
		}
		var ollamaBase = (plasmoid.configuration.aiOllamaUrl || "http://127.0.0.1:11434").replace(/\/+$/, "")
		return ollamaBase + "/api/tags"
	}

	function _applyHeaders(req, provider, apiKey) {
		if (provider === "openai" || provider === "openrouter" || provider === "perplexity") {
			req.setRequestHeader("Authorization", "Bearer " + apiKey)
			if (provider === "openrouter") {
				req.setRequestHeader("HTTP-Referer", "https://github.com/kombatant/tiled_rld")
				req.setRequestHeader("X-Title", "Tiled Menu Reloaded")
			}
			return
		}
		if (provider === "anthropic") {
			req.setRequestHeader("x-api-key", apiKey)
			req.setRequestHeader("anthropic-version", "2023-06-01")
		}
	}

	function _extractModels(provider, responseText) {
		var parsed = null
		try {
			parsed = JSON.parse(responseText)
		} catch (e) {
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
		var models = []
		for (var i = 0; i < source.length; i++) {
			var item = source[i]
			var id = ""
			if (provider === "ollama") {
				id = item && item.name ? ("" + item.name) : ""
			} else if (provider === "google") {
				id = item && item.name ? ("" + item.name) : ""
			} else {
				id = item && item.id ? ("" + item.id) : ""
			}
			if (id && !unique[id]) {
				unique[id] = true
				models.push(id)
			}
		}
		models.sort()
		return models
	}

	function _scheduleDetection() {
		detectDebounce.restart()
	}

	function detectModelsNow(force) {
		var shouldForce = !!force
		var provider = _providerValue()
		var apiKey = _apiKeyValue()
		var ollamaUrl = (plasmoid.configuration.aiOllamaUrl || "http://127.0.0.1:11434").replace(/\/+$/, "")
		var signature = provider + "|" + (provider === "ollama" ? ollamaUrl : apiKey)

		if (!shouldForce && signature === _lastDetectionSignature) {
			return
		}

		if (_needsKey(provider) && !apiKey) {
			_lastDetectionSignature = ""
			isDetectingModels = false
			detectionStatus = i18n("Add an API key to detect models.")
			return
		}

		_lastDetectionSignature = signature
		isDetectingModels = true
		detectionStatus = i18n("Detecting models...")
		_requestToken += 1
		var token = _requestToken

		var req = new XMLHttpRequest()
		req.open("GET", _modelsEndpoint(provider, apiKey))
		_applyHeaders(req, provider, apiKey)

		req.onreadystatechange = function() {
			if (req.readyState !== XMLHttpRequest.DONE) {
				return
			}
			if (token !== _requestToken) {
				return
			}
			isDetectingModels = false
			if (req.status < 200 || req.status >= 300) {
				detectionStatus = i18n("Model detection failed (%1).", req.status)
				return
			}

			var models = _extractModels(provider, req.responseText)
			if (!models.length) {
				detectionStatus = i18n("No models were detected.")
				return
			}

			plasmoid.configuration.aiDetectedModels = models
			if (!plasmoid.configuration.aiModel || models.indexOf(plasmoid.configuration.aiModel) < 0) {
				plasmoid.configuration.aiModel = models[0]
			}
			detectionStatus = i18n("Detected %1 model(s).", models.length)
			Qt.callLater(function() {
				if (modelCombo && typeof modelCombo.selectValue === "function") {
					modelCombo.selectValue(plasmoid.configuration.aiModel)
				}
			})
		}

		req.send()
	}

	Timer {
		id: detectDebounce
		interval: 450
		repeat: false
		onTriggered: form.detectModelsNow()
	}

	Component.onCompleted: {
		detectionStatus = detectedModels.length
			? i18n("Detected %1 model(s).", detectedModels.length)
			: i18n("Paste your API key to auto-detect models.")
	}

	LibConfig.Heading {
		text: i18n("Provider")
	}

	LibConfig.ComboBox {
		id: providerCombo
		configKey: "aiProvider"
		Kirigami.FormData.label: i18n("AI Provider")
		model: form.providerOptions
		property bool _initialized: false
		Component.onCompleted: Qt.callLater(function() { _initialized = true })
		onValueChanged: {
			if (!_initialized) {
				return
			}
			plasmoid.configuration.aiDetectedModels = []
			plasmoid.configuration.aiModel = ""
			form._lastDetectionSignature = ""
			form._scheduleDetection()
		}
	}

	LibConfig.TextField {
		id: apiKeyField
		configKey: "aiApiKey"
		visible: form.keyRequired
		Kirigami.FormData.label: i18n("API Key")
		echoMode: _showKey ? TextInput.Normal : TextInput.Password
		placeholderText: i18n("Required for this provider")

		property bool _showKey: false

		rightPadding: _eyeButton.width + Kirigami.Units.smallSpacing * 2
		Layout.maximumWidth: _keyMetrics.advanceWidth("0") * 40 + leftPadding + rightPadding

		FontMetrics {
			id: _keyMetrics
			font: apiKeyField.font
		}

		QQC2.ToolButton {
			id: _eyeButton
			anchors.right: parent.right
			anchors.rightMargin: Kirigami.Units.smallSpacing
			anchors.verticalCenter: parent.verticalCenter
			icon.name: apiKeyField._showKey ? "password-show-off" : "password-show-on"
			onClicked: apiKeyField._showKey = !apiKeyField._showKey
			QQC2.ToolTip.text: apiKeyField._showKey ? i18n("Hide API Key") : i18n("Show API Key")
			QQC2.ToolTip.visible: hovered
			flat: true
			focusPolicy: Qt.NoFocus
			display: QQC2.AbstractButton.IconOnly
			implicitHeight: apiKeyField.implicitHeight - Kirigami.Units.smallSpacing * 2
			implicitWidth: implicitHeight
		}

		onTextChanged: {
			if (activeFocus) {
				form._scheduleDetection()
			}
		}
	}

	LibConfig.TextField {
		id: ollamaUrlField
		configKey: "aiOllamaUrl"
		visible: !form.keyRequired
		Kirigami.FormData.label: i18n("Ollama Server")
		placeholderText: "http://127.0.0.1:11434"
		Layout.maximumWidth: _keyMetrics.advanceWidth("0") * 40 + leftPadding + rightPadding
		onTextChanged: {
			if (activeFocus) {
				form._scheduleDetection()
			}
		}
	}

	RowLayout {
		Kirigami.FormData.label: i18n("Detected Models")

		LibConfig.ComboBox {
			id: modelCombo
			configKey: "aiModel"
			model: form.modelOptionsData
			populated: true
		}

		QQC2.ToolButton {
			icon.name: "view-refresh"
			enabled: !form.isDetectingModels
			onClicked: form.detectModelsNow(true)
			QQC2.ToolTip.text: form.isDetectingModels ? i18n("Detecting models...") : i18n("Reload models")
			QQC2.ToolTip.visible: hovered
			display: QQC2.AbstractButton.IconOnly
		}
	}

	QQC2.Label {
		id: detectionStatusLabel
		Layout.fillWidth: true
		Layout.minimumHeight: Kirigami.Units.gridUnit
		wrapMode: Text.Wrap
		opacity: 0.8
		text: {
			if (isDetectingModels) {
				return detectionStatus
			}
			if (!detectedModels.length) {
				return detectionStatus || i18n("No models detected yet. Paste your API key to auto-detect.")
			}
			return detectionStatus || i18n("Detected %1 model(s).", detectedModels.length)
		}
	}

	LibConfig.Heading {
		text: i18n("Chat Options")
	}

	LibConfig.CheckBox {
		configKey: "aiStreamChat"
		text: i18n("Enable streaming responses")
	}

	LibConfig.Heading {
		text: i18n("Notes")
	}

	QQC2.Label {
		Layout.fillWidth: true
		wrapMode: Text.Wrap
		opacity: 0.85
		text: i18n("OpenAI, OpenRouter, Google, Perplexity and Anthropic require network access and an API key. Ollama connects to a local server (default: http://127.0.0.1:11434).")
	}
}
