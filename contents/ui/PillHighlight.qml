import QtQuick
import org.kde.kirigami as Kirigami

Item {
	id: root

	property var styleSource: null
	property bool active: true
	property real borderOpacity: -1
	property real glowOpacity: -1
	property real fillStrength: -1
	property real innerRimOpacity: -1
	property bool flushLeft: false
	property bool flushRight: false
	// Per-corner radius overrides forwarded to AccentHighlight. Negative means
	// "follow the computed pill radius"; the tabs style sets the bottom pair to
	// 0 so the highlight squares off where it meets the grid below.
	property real radiusTopLeft: -1
	property real radiusTopRight: -1
	property real radiusBottomRight: -1
	property real radiusBottomLeft: -1

	onVisibleChanged: {
		if (visible) {
			accentHighlight.requestPaint()
		}
	}

	function _styleValue(name, legacyName, fallback) {
		if (styleSource && typeof styleSource[name] !== "undefined")
			return styleSource[name];

		if (styleSource && legacyName && typeof styleSource[legacyName] !== "undefined")
			return styleSource[legacyName];

		return fallback;
	}

	readonly property real _highlightInset: _styleValue("highlightInset", "_highlightInset", _styleValue("activeIndicatorInset", "_activeIndicatorInset", 0))
	readonly property real _pillRadius: _styleValue("pillRadius", "_pillRadius", _styleValue("activeIndicatorRadius", "_activeIndicatorRadius", 0))
	readonly property real _pillsInset: _styleValue("pillsInset", "_pillsInset", 0)
	readonly property bool _flushEdge: flushLeft || flushRight

	function _cornerRadius(override) {
		if (override < 0) return -1
		return root._flushEdge ? override : Math.max(0, override - root._highlightInset)
	}

	readonly property real _borderOpacity: borderOpacity >= 0
		? borderOpacity
		: (active
			? _styleValue("activeHighlightBorderOpacity", "_activeHighlightBorderOpacity", 0.95)
			: _styleValue("hoverHighlightBorderOpacity", "_hoverHighlightBorderOpacity", 0.62))
	readonly property real _glowOpacity: glowOpacity >= 0
		? glowOpacity
		: (active
			? _styleValue("activeHighlightGlowOpacity", "_activeHighlightGlowOpacity", 0.78)
			: _styleValue("hoverHighlightGlowOpacity", "_hoverHighlightGlowOpacity", 0.44))
	readonly property real _fillStrength: fillStrength >= 0
		? fillStrength
		: (active
			? _styleValue("activeHighlightFillStrength", "_activeHighlightFillStrength", 1.0)
			: _styleValue("hoverHighlightFillStrength", "_hoverHighlightFillStrength", 0.58))
	readonly property real _innerRimOpacity: innerRimOpacity >= 0
		? innerRimOpacity
		: (active
			? _styleValue("activeHighlightInnerRimOpacity", "_activeHighlightInnerRimOpacity", 0.24)
			: _styleValue("hoverHighlightInnerRimOpacity", "_hoverHighlightInnerRimOpacity", 0.14))

	AccentHighlight {
		id: accentHighlight
		anchors.fill: parent
		anchors.leftMargin: root.flushLeft ? -root._pillsInset : root._highlightInset
		anchors.rightMargin: root.flushRight ? -root._pillsInset : root._highlightInset
		anchors.topMargin: root._flushEdge ? 0 : root._highlightInset
		anchors.bottomMargin: root._flushEdge ? 0 : root._highlightInset
		accentColor: root._styleValue("accentHighlightColor", "_accentHighlightColor", Kirigami.Theme.highlightColor)
		radius: root._flushEdge ? root._pillRadius : Math.max(0, root._pillRadius - root._highlightInset)
		// Overrides follow the same inset compensation as `radius` above.
		radiusTopLeft: root._cornerRadius(root.radiusTopLeft)
		radiusTopRight: root._cornerRadius(root.radiusTopRight)
		radiusBottomRight: root._cornerRadius(root.radiusBottomRight)
		radiusBottomLeft: root._cornerRadius(root.radiusBottomLeft)
		inset: 0
		borderOpacity: root._borderOpacity
		glowOpacity: root._glowOpacity
		fillStrength: root._fillStrength
		innerRimOpacity: root._innerRimOpacity
	}
}
