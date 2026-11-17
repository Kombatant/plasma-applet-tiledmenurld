import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// One tab of a tabbed settings page. Use inside `tabs: [ ... ]` on FormKCM:
//
// LibConfig.FormKCM {
// 	tabs: [
// 		LibConfig.FormTab {
// 			title: i18n("Layout")
// 			LibConfig.CheckBox { ... }
// 		}
// 	]
// }
Kirigami.FormLayout {
	id: formTab

	property string title: ""

	// Share of the tab width kept for the label column in wide mode, so the
	// controls start at the same position on every tab of every page.
	property real labelColumnRatio: 0.36
	readonly property int labelColumnWidth: wideMode ? Math.round(width * labelColumnRatio) : 0

	// Labels sit to the left of their controls when there is room, and above
	// them on a narrow page. Kirigami's default (based on the form's implicit
	// width) would let one long row push a single tab into narrow mode.
	wideMode: width >= Kirigami.Units.gridUnit * 30
	// FormKCM shows the current tab and hides the others (see its tabHost).
	visible: false

	readonly property Item _internalLayout: formTab.children.length > 0 ? formTab.children[0] : null

	// A hidden layout is not arranged, and styled controls only report their
	// final size once they are polished while visible. Left alone, a tab is
	// laid out one or two frames after it appears, which shows as a jump.
	// FormKCM calls this right after showing the tab so the whole pass
	// finishes before the first frame is drawn.
	function _settleLayout() {
		// Wrapped text changes height once it has its width, so one pass is
		// not always enough.
		for (let pass = 0; pass < 3; pass++) {
			formTab._polishTree(formTab)
			if (formTab._internalLayout) {
				formTab._internalLayout.ensurePolished()
			}
			formTab._pinInternalWidth()
		}
	}

	function _polishTree(item) {
		const kids = item.children
		for (let i = 0; i < kids.length; i++) {
			formTab._polishTree(kids[i])
		}
		if (item !== formTab) {
			item.ensurePolished()
		}
	}

	anchors.left: parent ? parent.left : undefined
	anchors.right: parent ? parent.right : undefined
	anchors.top: parent ? parent.top : undefined

	// Kirigami.FormLayout sizes its internal grid to the grid's implicit width
	// and centres it. Pin the grid to the left edge and to the full tab width
	// instead, so section headings span the page and the label column can be
	// given a fixed share of it.
	function _alignInternalLayout() {
		const internalLayout = formTab._internalLayout
		if (!internalLayout || !internalLayout.anchors) {
			return
		}
		internalLayout.anchors.horizontalCenter = undefined
		internalLayout.anchors.left = formTab.left
		formTab._pinInternalWidth()
		formTab._reserveLabelColumn()
	}

	// The first child of Kirigami's grid is the invisible 2px-high item it uses
	// to size the label column. Giving it a minimum width reserves the column.
	// If Kirigami's internals change, the check fails and the column simply
	// falls back to the width of the longest label.
	function _reserveLabelColumn() {
		const internalLayout = formTab._internalLayout
		const spacer = internalLayout && internalLayout.children.length > 0 ? internalLayout.children[0] : null
		if (!spacer || spacer.Layout.preferredHeight !== 2) {
			console.warn("[FormTab] Kirigami.FormLayout internals changed; label column width not reserved")
			return
		}
		spacer.Layout.minimumWidth = Qt.binding(function() {
			return formTab.labelColumnWidth
		})
		// Section headings span both columns, which would otherwise let the
		// label column take a share of any spare width. Give all of it to the
		// control column.
		spacer.Layout.horizontalStretchFactor = 0
		const trailing = internalLayout.children.length > 1 ? internalLayout.children[1] : null
		if (trailing && trailing.Layout.preferredHeight === 2) {
			trailing.Layout.fillWidth = true
			trailing.Layout.horizontalStretchFactor = 1
		}
	}

	// Kirigami keeps writing the grid's width through its own Binding whenever
	// the implicit width changes (some styled controls only report their final
	// size after they are first shown). Writing the width back in the same
	// change keeps full-width rows from resizing after a tab switch.
	function _pinInternalWidth() {
		const internalLayout = formTab._internalLayout
		if (internalLayout && formTab.width > 0 && internalLayout.width !== formTab.width) {
			internalLayout.width = formTab.width
		}
	}

	onWidthChanged: formTab._pinInternalWidth()

	Connections {
		target: formTab._internalLayout
		function onWidthChanged() {
			formTab._pinInternalWidth()
		}
	}

	Component.onCompleted: formTab._alignInternalLayout()
}
