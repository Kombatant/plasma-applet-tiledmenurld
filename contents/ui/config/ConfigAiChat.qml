import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils
import "../lib"

LibConfig.FormKCM {
	id: form
	wideMode: false

	// --- Pending API key state (previously on shared ConfigMain) ---
	property string pendingAiApiKey: ""
	property bool pendingAiApiKeyInitialized: false

	// Plasma's config dialog calls saveConfig() on each page's root item on Apply/OK.
	function saveConfig() {
		_applyPendingApiKey()
	}

	readonly property var providerOptions: [
		{ value: "openai", text: "OpenAI" },
		{ value: "openrouter", text: "OpenRouter" },
		{ value: "google", text: "Google (Gemini API)" },
		{ value: "perplexity", text: "Perplexity" },
		{ value: "anthropic", text: "Anthropic" },
		{ value: "openwebui", text: "Open WebUI" },
		{ value: "ollama", text: "Ollama (Local)" },
	]

	property string providerValueCached: "openai"
	function _refreshProviderValueCached() {
		providerValueCached = ((providerCombo.value) || (form.cfg_aiProvider !== undefined ? form.cfg_aiProvider : plasmoid.configuration.aiProvider) || "openai").toString().toLowerCase()
	}
	readonly property bool keyVisible: providerValueCached !== "ollama"
	readonly property bool keyRequired: providerValueCached !== "ollama" && providerValueCached !== "openwebui"
	readonly property bool usesOllamaUrl: providerValueCached === "ollama"
	readonly property bool usesOpenWebUiUrl: providerValueCached === "openwebui"
	readonly property bool aiChatEnabled: (form.cfg_aiChatEnabled !== undefined ? form.cfg_aiChatEnabled : plasmoid.configuration.aiChatEnabled) !== false
	readonly property var detectedModels: (form.cfg_aiDetectedModels !== undefined ? form.cfg_aiDetectedModels : plasmoid.configuration.aiDetectedModels) || []
	readonly property bool hasStoredApiKey: !!((secureApiKey.secret || "").trim())
	property bool isDetectingModels: false
	property string detectionStatus: ""
	property bool _updatingApiKeyField: false
	property bool _apiKeyEdited: false
	property string _lastDetectionSignature: ""
	property int _requestToken: 0
	readonly property int wrappedLabelPreferredWidth: Kirigami.Units.gridUnit * 20
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
		return providerValueCached
	}

	function _apiKeyValue() {
		var pendingValue = (form.pendingAiApiKey || "").trim()
		if (pendingValue) {
			return pendingValue
		}
		if (form._apiKeyEdited) {
			return ""
		}
		return (secureApiKey.secret || "").trim()
	}

	function _needsKey(provider) {
		return provider !== "ollama" && provider !== "openwebui"
	}

	function _normalizedOpenWebUiApiBase(url) {
		var base = (url || "http://127.0.0.1:3000").replace(/\/+$/, "")
		if (/\/api(?:\/v1)?$/i.test(base)) {
			return base.replace(/\/v1$/i, "")
		}
		return base + "/api"
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
		if (provider === "openwebui") {
			var openWebUiBase = _normalizedOpenWebUiApiBase(ConfigUtils.pendingValue(form, "aiOpenWebUiUrl", plasmoid.configuration.aiOpenWebUiUrl) || "http://127.0.0.1:3000")
			return openWebUiBase + "/models"
		}
		var ollamaBase = (ConfigUtils.pendingValue(form, "aiOllamaUrl", plasmoid.configuration.aiOllamaUrl) || "http://127.0.0.1:11434").replace(/\/+$/, "")
		return ollamaBase + "/api/tags"
	}

	function _applyHeaders(req, provider, apiKey) {
		if (provider === "openai" || provider === "openrouter" || provider === "perplexity" || provider === "openwebui") {
			if (apiKey) {
				req.setRequestHeader("Authorization", "Bearer " + apiKey)
			}
			if (provider === "openrouter") {
				req.setRequestHeader("HTTP-Referer", "https://github.com/Kombatant/plasma-applet-tiledmenurld")
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
		var ollamaUrl = (ConfigUtils.pendingValue(form, "aiOllamaUrl", plasmoid.configuration.aiOllamaUrl) || "http://127.0.0.1:11434").replace(/\/+$/, "")
		var openWebUiUrl = _normalizedOpenWebUiApiBase(ConfigUtils.pendingValue(form, "aiOpenWebUiUrl", plasmoid.configuration.aiOpenWebUiUrl) || "http://127.0.0.1:3000")
		var signature = provider + "|" + (provider === "ollama" ? ollamaUrl : (provider === "openwebui" ? openWebUiUrl + "|" + apiKey : apiKey))

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

			ConfigUtils.setPendingValue(form, "aiDetectedModels", models)
			var selectedModel = ConfigUtils.pendingValue(form, "aiModel", plasmoid.configuration.aiModel)
			if (!selectedModel || models.indexOf(selectedModel) < 0) {
				ConfigUtils.setPendingValue(form, "aiModel", models[0])
				selectedModel = models[0]
			}
			detectionStatus = i18n("Detected %1 model(s).", models.length)
			Qt.callLater(function() {
				if (modelCombo && typeof modelCombo.selectValue === "function") {
					modelCombo.selectValue(selectedModel)
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

	KWalletSecret {
		id: secureApiKey
		onLoaded: function(success) {
			if (success && !form.pendingAiApiKeyInitialized) {
				form._setPendingApiKey(secret || ((plasmoid.configuration.aiApiKey || "").trim()), false)
				form.pendingAiApiKeyInitialized = true
				form._lastDetectionSignature = ""
				if (!form.detectedModels.length && form._apiKeyValue()) {
					form._scheduleDetection()
				}
			}
		}
		onSaved: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(form, "aiApiKey", "", false)
				form._scheduleDetection()
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to save API key to KWallet."))
			}
		}
		onCleared: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(form, "aiApiKey", "", false)
				form._setPendingApiKey("", false)
				form._lastDetectionSignature = ""
				form._scheduleDetection()
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to remove API key from KWallet."))
			}
		}
	}

	function _setPendingApiKey(value, markDirty) {
		var nextValue = value || ""
		if (form.pendingAiApiKey === nextValue) {
			return
		}
		form.pendingAiApiKey = nextValue
		if (markDirty !== false) {
			ConfigUtils.markConfigurationChanged(form)
		}
		form._updatingApiKeyField = true
		apiKeyField.text = nextValue
		form._updatingApiKeyField = false
		if (markDirty === false) {
			form._apiKeyEdited = false
		}
	}

	function _applyPendingApiKey() {
		if (!secureApiKey.secureStorageAvailable || secureApiKey.saving) {
			return
		}
		var draft = _apiKeyValue()
		var stored = secureApiKey.secret || ""
		ConfigUtils.setPendingValue(form, "aiApiKey", "", false)
		if (draft === stored) {
			return
		}
		if (!draft) {
			secureApiKey.clearSecret()
			return
		}
		secureApiKey.saveSecret(draft)
	}

	property var _disconnectProviderChange: null
	Component.onCompleted: {
		if (!form.pendingAiApiKeyInitialized && (plasmoid.configuration.aiApiKey || "").trim()) {
			form.pendingAiApiKey = (plasmoid.configuration.aiApiKey || "").trim()
			form.pendingAiApiKeyInitialized = true
		}
		secureApiKey.inspectAvailability()
		secureApiKey.readSecret()
		_refreshProviderValueCached()
		_disconnectProviderChange = ConfigUtils.connectConfigChange(form, "aiProvider", _refreshProviderValueCached)
		detectionStatus = detectedModels.length
			? i18n("Detected %1 model(s).", detectedModels.length)
			: i18n("Paste your API key to auto-detect models.")
	}
	Component.onDestruction: {
		if (_disconnectProviderChange) _disconnectProviderChange()
	}

	Kirigami.InlineMessage {
		Layout.fillWidth: true
		visible: form.keyRequired && secureApiKey.checkedAvailability && !secureApiKey.secureStorageAvailable && !!secureApiKey.availabilityMessage
		type: Kirigami.MessageType.Warning
		text: secureApiKey.availabilityMessage
	}

	LibConfig.ComboBox {
		id: aiChatEnabledCombo
		configKey: "aiChatEnabled"
		Kirigami.FormData.label: i18n("AI Chat")
		model: [
			{ value: true, text: i18n("Enabled") },
			{ value: false, text: i18n("Disabled") },
		]
	}

	LibConfig.Heading {
		enabled: form.aiChatEnabled
		text: i18n("Provider")
	}

	LibConfig.ComboBox {
		id: providerCombo
		enabled: form.aiChatEnabled
		configKey: "aiProvider"
		Kirigami.FormData.label: i18n("AI Provider")
		model: form.providerOptions
		property bool _initialized: false
		Component.onCompleted: Qt.callLater(function() { _initialized = true })
		onValueChanged: {
			form._refreshProviderValueCached()
			if (!_initialized) {
				return
			}
			ConfigUtils.setPendingValue(form, "aiDetectedModels", [])
			ConfigUtils.setPendingValue(form, "aiModel", "")
			form._lastDetectionSignature = ""
			form._scheduleDetection()
		}
	}

	LibConfig.TextField {
		id: apiKeyField
		enabled: form.aiChatEnabled && secureApiKey.secureStorageAvailable
		visible: form.keyVisible
		Kirigami.FormData.label: form.keyRequired ? i18n("API Key") : i18n("API Key (Optional)")
		echoMode: _showKey ? TextInput.Normal : TextInput.Password
		placeholderText: form.keyRequired
			? i18n("Required for this provider (stored in KWallet)")
			: i18n("Optional bearer token (stored in KWallet)")

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
			if (form._updatingApiKeyField) {
				return
			}
			form._apiKeyEdited = true
			form._setPendingApiKey(text, true)
			if (activeFocus) {
				form._scheduleDetection()
			}
		}
	}

	QQC2.Label {
		enabled: form.aiChatEnabled
		visible: form.keyVisible && secureApiKey.loadedOnce && form.hasStoredApiKey
		Layout.fillWidth: true
		Layout.minimumHeight: Kirigami.Units.gridUnit
		Layout.preferredWidth: form.wrappedLabelPreferredWidth
		wrapMode: Text.Wrap
		opacity: 0.8
		text: i18n("An API key is already stored in KWallet. Enter a new key here to replace it.")
	}

	LibConfig.TextField {
		id: ollamaUrlField
		enabled: form.aiChatEnabled
		configKey: "aiOllamaUrl"
		visible: form.usesOllamaUrl
		Kirigami.FormData.label: i18n("Ollama Server")
		placeholderText: "http://127.0.0.1:11434"
		Layout.maximumWidth: _keyMetrics.advanceWidth("0") * 40 + leftPadding + rightPadding
		onTextChanged: {
			if (activeFocus) {
				form._scheduleDetection()
			}
		}
	}

	LibConfig.TextField {
		id: openWebUiUrlField
		enabled: form.aiChatEnabled
		configKey: "aiOpenWebUiUrl"
		visible: form.usesOpenWebUiUrl
		Kirigami.FormData.label: i18n("Open WebUI Server")
		placeholderText: "http://127.0.0.1:3000 or http://127.0.0.1:3000/api"
		Layout.maximumWidth: _keyMetrics.advanceWidth("0") * 40 + leftPadding + rightPadding
		onTextChanged: {
			if (activeFocus) {
				form._scheduleDetection()
			}
		}
	}

	RowLayout {
		enabled: form.aiChatEnabled
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
		enabled: form.aiChatEnabled
		Layout.fillWidth: true
		Layout.minimumHeight: Kirigami.Units.gridUnit
		Layout.preferredWidth: form.wrappedLabelPreferredWidth
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
		enabled: form.aiChatEnabled
		text: i18n("Chat Options")
	}

	LibConfig.CheckBox {
		enabled: form.aiChatEnabled
		configKey: "aiStreamChat"
		text: i18n("Enable streaming responses")
		Kirigami.FormData.label: ""
	}

	Item {
		enabled: form.aiChatEnabled
		Kirigami.FormData.isSection: false
		Kirigami.FormData.label: ""
		implicitHeight: Kirigami.Units.gridUnit
	}

	Kirigami.InlineMessage {
		enabled: form.aiChatEnabled
		Layout.fillWidth: true
		visible: true
		icon.source: "help-info-symbolic"
		type: Kirigami.MessageType.Information
		text: i18n("<ul><li>OpenAI, OpenRouter, Google, Perplexity and Anthropic require network access and an API key.</li><li>Open WebUI uses its OpenAI-compatible API at your configured server URL and can optionally use a bearer token; both the server root and an /api URL are accepted.</li><li>Ollama connects to a local server (default: http://127.0.0.1:11434).</li></ul>")
	}

}
