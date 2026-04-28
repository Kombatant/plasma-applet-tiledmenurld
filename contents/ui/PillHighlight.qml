import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: root

    property var styleSource: null

    function _styleValue(name, legacyName, fallback) {
        if (styleSource && typeof styleSource[name] !== "undefined")
            return styleSource[name];

        if (styleSource && legacyName && typeof styleSource[legacyName] !== "undefined")
            return styleSource[legacyName];

        return fallback;
    }

    anchors.topMargin: _styleValue("activeIndicatorInset", "_activeIndicatorInset", 0)
    anchors.bottomMargin: _styleValue("activeIndicatorInset", "_activeIndicatorInset", 0)
    color: _styleValue("indicatorColor", "_indicatorColor", Kirigami.Theme.highlightColor)

    corners {
        topLeftRadius: _styleValue("activeIndicatorRadius", "_activeIndicatorRadius", 0)
        bottomLeftRadius: _styleValue("activeIndicatorRadius", "_activeIndicatorRadius", 0)
        topRightRadius: _styleValue("activeIndicatorRadius", "_activeIndicatorRadius", 0)
        bottomRightRadius: _styleValue("activeIndicatorRadius", "_activeIndicatorRadius", 0)
    }

}
