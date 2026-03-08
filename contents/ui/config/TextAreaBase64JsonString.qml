import QtQuick
import QtQuick.Layouts

import ".." as TiledMenu
import "../libconfig" as LibConfig

LibConfig.TextArea {
	id: textArea
	Layout.fillWidth: true
	font.family: "monospace"
	// JSON is structured; wrapping tends to make it harder to read.
	// Prefer preserving lines and letting the ScrollView provide horizontal scrolling.
	wrapMode: TextEdit.NoWrap

	property var base64XmlString: TiledMenu.Base64XmlString {
		id: base64XmlString
	}

	property alias xmlKey: base64XmlString.configKey
	property alias defaultValue: base64XmlString.defaultValue

	property alias enabled: textArea.enabled

	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""
	onConfigValueChanged: deserialize()
	readonly property var value: base64XmlString.value

	property alias textArea: textArea
	property alias textAreaText: textArea.text

	function parseValue(value) {
		// Represent the tileModel value as XML text for editing.
		// base64XmlString.value is an array; serialize to XML fragment.
		var xml = base64XmlString._buildTilesXmlFragment ? base64XmlString._buildTilesXmlFragment(value) : ""
		return xml
	}
	function parseText(text) {
		// For now, edits to the XML raw text are not parsed back into structured data by this helper.
		// Use the Export/Import page for XML edits. Return the existing value to avoid corrupting data.
		return value
	}

	function setValue(val) {
		var newText = parseValue(val)
		if (textArea.text != newText) {
			textArea.text = newText
		}
	}

	function deserialize() {
		if (!textArea.focus) {
			setValue(value)
		}
	}
	function serialize() {
		var newValue = parseText(textArea.text)
		base64XmlString.set(newValue)
	}
}
