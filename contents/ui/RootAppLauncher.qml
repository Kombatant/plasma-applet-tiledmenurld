import QtQuick
import QtQuick.Dialogs
import org.kde.plasma.plasma5support as Plasma5Support
import "Utils.js" as Utils

Item {
	id: root
	property bool showTerminal: false

	function launch(launcherUrl) {
		var scriptPath = decodeURIComponent(Qt.resolvedUrl("../scripts/run-as-root.py").toString().replace(/^file:\/\//, ""))
		executable.connectSource("python3 " + Utils.shellQuote(scriptPath)
			+ (root.showTerminal ? " --terminal" : "") + " -- " + Utils.shellQuote(launcherUrl))
	}

	Plasma5Support.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			// Cancellation from kdesu can return a nonzero status without an error.
			if (data["exit code"] !== 0 && data.stderr && data.stderr.trim()) {
				console.warn("Run as Root:", data.stderr)
				errorDialog.informativeText = data.stderr.trim()
				errorDialog.open()
			}
		}
	}

	MessageDialog {
		id: errorDialog
		title: i18n("Run as Root")
		text: i18n("Could not run the application as root.")
		buttons: MessageDialog.Ok
	}
}
