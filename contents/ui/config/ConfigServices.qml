import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".." as TiledMenu
import "../lib"
import "../libconfig" as LibConfig
import "../libconfig/ConfigUtils.js" as ConfigUtils

LibConfig.FormKCM {
	id: formLayout
	wideMode: false

	// --- Pending API key state (previously on shared ConfigMain) ---
	property string pendingAiApiKey: ""
	property bool pendingAiApiKeyInitialized: false

	property string pendingIgdbClientSecret: ""
	property bool pendingIgdbClientSecretInitialized: false
	property bool _updatingIgdbSecretField: false
	property bool _igdbSecretEdited: false
	readonly property bool hasStoredIgdbClientSecret: !!((secureIgdbClientSecret.secret || "").trim())

	// Plasma's config dialog calls saveConfig() on each page's root item on Apply/OK.
	function saveConfig() {
		_applyPendingApiKey()
		_applyPendingIgdbClientSecret()
	}

	readonly property var providerOptions: [
		{ value: "openai", text: i18n("OpenAI") },
		{ value: "openrouter", text: i18n("OpenRouter") },
		{ value: "google", text: i18n("Google (Gemini API)") },
		{ value: "perplexity", text: i18n("Perplexity") },
		{ value: "anthropic", text: i18n("Anthropic") },
		{ value: "openwebui", text: i18n("Open WebUI") },
		{ value: "ollama", text: i18n("Ollama (Local)") },
	]

	property string providerValueCached: "openai"
	function _refreshProviderValueCached() {
		providerValueCached = ((providerCombo.value) || (formLayout.cfg_aiProvider !== undefined ? formLayout.cfg_aiProvider : plasmoid.configuration.aiProvider) || "openai").toString().toLowerCase()
	}
	readonly property bool keyVisible: providerValueCached !== "ollama"
	readonly property bool keyRequired: providerValueCached !== "ollama" && providerValueCached !== "openwebui"
	readonly property bool usesOllamaUrl: providerValueCached === "ollama"
	readonly property bool usesOpenWebUiUrl: providerValueCached === "openwebui"
	readonly property bool aiChatEnabled: (formLayout.cfg_aiChatEnabled !== undefined ? formLayout.cfg_aiChatEnabled : plasmoid.configuration.aiChatEnabled) !== false
	readonly property var detectedModels: (formLayout.cfg_aiDetectedModels !== undefined ? formLayout.cfg_aiDetectedModels : plasmoid.configuration.aiDetectedModels) || []
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
		var pendingValue = (formLayout.pendingAiApiKey || "").trim()
		if (pendingValue) {
			return pendingValue
		}
		if (formLayout._apiKeyEdited) {
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
			var openWebUiBase = _normalizedOpenWebUiApiBase(ConfigUtils.pendingValue(formLayout, "aiOpenWebUiUrl", plasmoid.configuration.aiOpenWebUiUrl) || "http://127.0.0.1:3000")
			return openWebUiBase + "/models"
		}
		var ollamaBase = (ConfigUtils.pendingValue(formLayout, "aiOllamaUrl", plasmoid.configuration.aiOllamaUrl) || "http://127.0.0.1:11434").replace(/\/+$/, "")
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
		var ollamaUrl = (ConfigUtils.pendingValue(formLayout, "aiOllamaUrl", plasmoid.configuration.aiOllamaUrl) || "http://127.0.0.1:11434").replace(/\/+$/, "")
		var openWebUiUrl = _normalizedOpenWebUiApiBase(ConfigUtils.pendingValue(formLayout, "aiOpenWebUiUrl", plasmoid.configuration.aiOpenWebUiUrl) || "http://127.0.0.1:3000")
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

			ConfigUtils.setPendingValue(formLayout, "aiDetectedModels", models)
			var selectedModel = ConfigUtils.pendingValue(formLayout, "aiModel", plasmoid.configuration.aiModel)
			if (!selectedModel || models.indexOf(selectedModel) < 0) {
				ConfigUtils.setPendingValue(formLayout, "aiModel", models[0])
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
		onTriggered: formLayout.detectModelsNow()
	}

	KWalletSecret {
		id: secureApiKey
		onLoaded: function(success) {
			if (success && !formLayout.pendingAiApiKeyInitialized) {
				formLayout._setPendingApiKey(secret || ((plasmoid.configuration.aiApiKey || "").trim()), false)
				formLayout.pendingAiApiKeyInitialized = true
				formLayout._lastDetectionSignature = ""
				if (!formLayout.detectedModels.length && formLayout._apiKeyValue()) {
					formLayout._scheduleDetection()
				}
			}
		}
		onSaved: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(formLayout, "aiApiKey", "", false)
				formLayout._scheduleDetection()
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to save API key to KWallet."))
			}
		}
		onCleared: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(formLayout, "aiApiKey", "", false)
				formLayout._setPendingApiKey("", false)
				formLayout._lastDetectionSignature = ""
				formLayout._scheduleDetection()
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to remove API key from KWallet."))
			}
		}
	}

	function _setPendingApiKey(value, markDirty) {
		var nextValue = value || ""
		if (formLayout.pendingAiApiKey === nextValue) {
			return
		}
		formLayout.pendingAiApiKey = nextValue
		if (markDirty !== false) {
			ConfigUtils.markConfigurationChanged(formLayout)
		}
		formLayout._updatingApiKeyField = true
		apiKeyField.text = nextValue
		formLayout._updatingApiKeyField = false
		if (markDirty === false) {
			formLayout._apiKeyEdited = false
		}
	}

	function _applyPendingApiKey() {
		if (!secureApiKey.secureStorageAvailable || secureApiKey.saving) {
			return
		}
		var draft = _apiKeyValue()
		var stored = secureApiKey.secret || ""
		ConfigUtils.setPendingValue(formLayout, "aiApiKey", "", false)
		if (draft === stored) {
			return
		}
		if (!draft) {
			secureApiKey.clearSecret()
			return
		}
		secureApiKey.saveSecret(draft)
	}


	KWalletSecret {
		id: secureIgdbClientSecret
		entryName: "igdbClientSecret"
		onLoaded: function(success) {
			if (success && !formLayout.pendingIgdbClientSecretInitialized) {
				formLayout._setPendingIgdbClientSecret(secret || ((plasmoid.configuration.igdbClientSecret || "").trim()), false)
				formLayout.pendingIgdbClientSecretInitialized = true
			}
		}
		onSaved: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(formLayout, "igdbClientSecret", "", false)
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to save the IGDB client secret to KWallet."))
			}
		}
		onCleared: function(success) {
			if (success) {
				ConfigUtils.setPendingValue(formLayout, "igdbClientSecret", "", false)
				formLayout._setPendingIgdbClientSecret("", false)
				return
			}
			if (typeof showPassiveNotification === "function") {
				showPassiveNotification(i18n("Failed to remove the IGDB client secret from KWallet."))
			}
		}
	}

	function _setPendingIgdbClientSecret(value, markDirty) {
		var nextValue = value || ""
		if (formLayout.pendingIgdbClientSecret === nextValue) {
			return
		}
		formLayout.pendingIgdbClientSecret = nextValue
		if (markDirty !== false) {
			ConfigUtils.markConfigurationChanged(formLayout)
		}
		formLayout._updatingIgdbSecretField = true
		igdbClientSecretField.text = nextValue
		formLayout._updatingIgdbSecretField = false
		if (markDirty === false) {
			formLayout._igdbSecretEdited = false
		}
	}

	function _igdbClientSecretValue() {
		var pendingValue = (formLayout.pendingIgdbClientSecret || "").trim()
		if (pendingValue) {
			return pendingValue
		}
		if (formLayout._igdbSecretEdited) {
			return ""
		}
		return (secureIgdbClientSecret.secret || "").trim()
	}

	function _applyPendingIgdbClientSecret() {
		if (!secureIgdbClientSecret.secureStorageAvailable || secureIgdbClientSecret.saving) {
			return
		}
		var draft = _igdbClientSecretValue()
		var stored = secureIgdbClientSecret.secret || ""
		ConfigUtils.setPendingValue(formLayout, "igdbClientSecret", "", false)
		if (draft === stored) {
			return
		}
		if (!draft) {
			secureIgdbClientSecret.clearSecret()
			return
		}
		secureIgdbClientSecret.saveSecret(draft)
	}

	TiledMenu.AppAutocompleteHelper {
		id: appAutocomplete
	}

	property var _disconnectProviderChange: null
	Component.onCompleted: {
		if (!formLayout.pendingIgdbClientSecretInitialized && (plasmoid.configuration.igdbClientSecret || "").trim()) {
			formLayout.pendingIgdbClientSecret = (plasmoid.configuration.igdbClientSecret || "").trim()
			formLayout.pendingIgdbClientSecretInitialized = true
		}
		secureIgdbClientSecret.readSecret()
		if (!formLayout.pendingAiApiKeyInitialized && (plasmoid.configuration.aiApiKey || "").trim()) {
			formLayout.pendingAiApiKey = (plasmoid.configuration.aiApiKey || "").trim()
			formLayout.pendingAiApiKeyInitialized = true
		}
		secureApiKey.readSecret()
		_refreshProviderValueCached()
		_disconnectProviderChange = ConfigUtils.connectConfigChange(formLayout, "aiProvider", _refreshProviderValueCached)
		detectionStatus = detectedModels.length
			? i18n("Detected %1 model(s).", detectedModels.length)
			: i18n("Paste your API key to auto-detect models.")
	}
	Component.onDestruction: {
		if (_disconnectProviderChange) _disconnectProviderChange()
	}

	tabs: [
		LibConfig.FormTab {
			title: i18n("AI Chat")

			Kirigami.InlineMessage {
				Layout.fillWidth: true
				visible: formLayout.keyRequired && secureApiKey.checkedAvailability && !secureApiKey.secureStorageAvailable && !!secureApiKey.availabilityMessage
				type: Kirigami.MessageType.Warning
				text: secureApiKey.availabilityMessage
			}

			LibConfig.ComboBox {
				id: aiChatEnabledCombo
				configKey: "aiChatEnabled"
				Kirigami.FormData.label: i18n("AI Chat:")
				model: [
					{ value: true, text: i18n("Enabled") },
					{ value: false, text: i18n("Disabled") },
				]
			}

			LibConfig.Heading {
				enabled: formLayout.aiChatEnabled
				text: i18n("Provider")
			}

			LibConfig.ComboBox {
				id: providerCombo
				enabled: formLayout.aiChatEnabled
				configKey: "aiProvider"
				Kirigami.FormData.label: i18n("AI provider:")
				model: formLayout.providerOptions
				onValueChanged: {
					formLayout._refreshProviderValueCached()
					if (!_initialized) {
						return
					}
					ConfigUtils.setPendingValue(formLayout, "aiDetectedModels", [])
					ConfigUtils.setPendingValue(formLayout, "aiModel", "")
					formLayout._lastDetectionSignature = ""
					formLayout._scheduleDetection()
				}
			}

			LibConfig.TextField {
				id: apiKeyField
				enabled: formLayout.aiChatEnabled && secureApiKey.secureStorageAvailable
				visible: formLayout.keyVisible
				Kirigami.FormData.label: formLayout.keyRequired ? i18n("API key:") : i18n("API key (optional):")
				echoMode: _showKey ? TextInput.Normal : TextInput.Password
				placeholderText: formLayout.keyRequired
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
					if (formLayout._updatingApiKeyField) {
						return
					}
					formLayout._apiKeyEdited = true
					formLayout._setPendingApiKey(text, true)
					if (activeFocus) {
						formLayout._scheduleDetection()
					}
				}
			}

			QQC2.Label {
				enabled: formLayout.aiChatEnabled
				visible: formLayout.keyVisible && secureApiKey.loadedOnce && formLayout.hasStoredApiKey
				Layout.fillWidth: true
				Layout.minimumHeight: Kirigami.Units.gridUnit
				Layout.preferredWidth: formLayout.wrappedLabelPreferredWidth
				wrapMode: Text.Wrap
				opacity: 0.8
				text: i18n("An API key is already stored in KWallet. Enter a new key here to replace it.")
			}

			LibConfig.TextField {
				id: ollamaUrlField
				enabled: formLayout.aiChatEnabled
				configKey: "aiOllamaUrl"
				visible: formLayout.usesOllamaUrl
				Kirigami.FormData.label: i18n("Ollama server:")
				placeholderText: "http://127.0.0.1:11434"
				Layout.maximumWidth: _keyMetrics.advanceWidth("0") * 40 + leftPadding + rightPadding
				onTextChanged: {
					if (activeFocus) {
						formLayout._scheduleDetection()
					}
				}
			}

			LibConfig.TextField {
				id: openWebUiUrlField
				enabled: formLayout.aiChatEnabled
				configKey: "aiOpenWebUiUrl"
				visible: formLayout.usesOpenWebUiUrl
				Kirigami.FormData.label: i18n("Open WebUI server:")
				placeholderText: "http://127.0.0.1:3000 or http://127.0.0.1:3000/api"
				Layout.maximumWidth: _keyMetrics.advanceWidth("0") * 40 + leftPadding + rightPadding
				onTextChanged: {
					if (activeFocus) {
						formLayout._scheduleDetection()
					}
				}
			}

			RowLayout {
				enabled: formLayout.aiChatEnabled
				Kirigami.FormData.label: i18n("Model:")

				LibConfig.ComboBox {
					id: modelCombo
					configKey: "aiModel"
					model: formLayout.modelOptionsData
					populated: true
				}

				QQC2.ToolButton {
					icon.name: "view-refresh"
					enabled: !formLayout.isDetectingModels
					onClicked: formLayout.detectModelsNow(true)
					QQC2.ToolTip.text: formLayout.isDetectingModels ? i18n("Detecting models...") : i18n("Reload models")
					QQC2.ToolTip.visible: hovered
					display: QQC2.AbstractButton.IconOnly
				}
			}

			QQC2.Label {
				id: detectionStatusLabel
				enabled: formLayout.aiChatEnabled
				Layout.fillWidth: true
				Layout.minimumHeight: Kirigami.Units.gridUnit
				Layout.preferredWidth: formLayout.wrappedLabelPreferredWidth
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
				enabled: formLayout.aiChatEnabled
				text: i18n("Chat options")
			}

			LibConfig.CheckBox {
				enabled: formLayout.aiChatEnabled
				configKey: "aiStreamChat"
				text: i18n("Enable streaming responses")
				Kirigami.FormData.label: ""
			}

			Item {
				enabled: formLayout.aiChatEnabled
				Kirigami.FormData.isSection: false
				Kirigami.FormData.label: ""
				implicitHeight: Kirigami.Units.gridUnit
			}

			Kirigami.InlineMessage {
				enabled: formLayout.aiChatEnabled
				Layout.fillWidth: true
				visible: true
				icon.source: "help-info-symbolic"
				type: Kirigami.MessageType.Information
				text: i18n("<ul><li>OpenAI, OpenRouter, Google, Perplexity and Anthropic require network access and an API key.</li><li>Open WebUI uses its OpenAI-compatible API at your configured server URL and can optionally use a bearer token; both the server root and an /api URL are accepted.</li><li>Ollama connects to a local server (default: http://127.0.0.1:11434).</li></ul>")
			}
		},
		LibConfig.FormTab {
			title: i18n("Game Metadata")

			Kirigami.InlineMessage {
				Layout.fillWidth: true
				visible: secureIgdbClientSecret.checkedAvailability && !secureIgdbClientSecret.secureStorageAvailable && !!secureIgdbClientSecret.availabilityMessage
				type: Kirigami.MessageType.Warning
				text: secureIgdbClientSecret.availabilityMessage
			}

			LibConfig.TextField {
				configKey: "igdbClientId"
				Kirigami.FormData.label: i18n("IGDB client ID:")
				placeholderText: i18n("Required for hero-page IGDB tags")
			}

			LibConfig.TextField {
				id: igdbClientSecretField
				enabled: secureIgdbClientSecret.secureStorageAvailable
				Kirigami.FormData.label: i18n("IGDB client secret:")
				echoMode: _showSecret ? TextInput.Normal : TextInput.Password
				placeholderText: i18n("Stored in KWallet")
				property bool _showSecret: false
				rightPadding: _toggleSecretButton.width + Kirigami.Units.smallSpacing * 2

				QQC2.ToolButton {
					id: _toggleSecretButton
					anchors.right: parent.right
					anchors.rightMargin: Kirigami.Units.smallSpacing
					anchors.verticalCenter: parent.verticalCenter
					icon.name: igdbClientSecretField._showSecret ? "password-show-off" : "password-show-on"
					onClicked: igdbClientSecretField._showSecret = !igdbClientSecretField._showSecret
					QQC2.ToolTip.text: igdbClientSecretField._showSecret ? i18n("Hide client secret") : i18n("Show client secret")
					QQC2.ToolTip.visible: hovered
					flat: true
					focusPolicy: Qt.NoFocus
					display: QQC2.AbstractButton.IconOnly
					implicitHeight: igdbClientSecretField.implicitHeight - Kirigami.Units.smallSpacing * 2
					implicitWidth: implicitHeight
				}

				onTextChanged: {
					if (formLayout._updatingIgdbSecretField) {
						return
					}
					formLayout._igdbSecretEdited = true
					formLayout._setPendingIgdbClientSecret(text, true)
				}
			}

			QQC2.Label {
				visible: secureIgdbClientSecret.loadedOnce && formLayout.hasStoredIgdbClientSecret
				Layout.fillWidth: true
				wrapMode: Text.Wrap
				opacity: 0.8
				text: i18n("An IGDB client secret is already stored in KWallet. Enter a new value here to replace it.")
			}

			QQC2.Label {
				Layout.fillWidth: true
				wrapMode: Text.Wrap
				opacity: 0.8
				text: i18n("Hero pages can download Steam store descriptions and IGDB tags when you enable the per-page metadata option in the hero editor.")
			}
		},
		LibConfig.FormTab {
			title: i18n("Default Apps")

			LibConfig.CheckBox {
				configKey: 'runAsRootInTerminal'
				text: i18n("Show a terminal when running as root")
			}
			LibConfig.AutocompleteTextField {
				configKey: 'terminalApp'
				Kirigami.FormData.label: i18n("Terminal:")
				placeholderText: cfg_terminalAppDefault || "org.kde.konsole.desktop"
				suggestionsProvider: appAutocomplete.suggestionsProvider
			}
			LibConfig.AutocompleteTextField {
				configKey: 'taskManagerApp'
				Kirigami.FormData.label: i18n("Task manager:")
				placeholderText: cfg_taskManagerAppDefault || "org.kde.plasma-systemmonitor.desktop"
				suggestionsProvider: appAutocomplete.suggestionsProvider
			}
			LibConfig.AutocompleteTextField {
				configKey: 'fileManagerApp'
				Kirigami.FormData.label: i18n("File manager:")
				placeholderText: cfg_fileManagerAppDefault || "org.kde.dolphin.desktop"
				suggestionsProvider: appAutocomplete.suggestionsProvider
			}
		}
	]
}
