// Version 1

import QtQuick

QtObject {
    property string configKey
    readonly property string configValue: configKey ? plasmoid.configuration[configKey] : ""
    property variant value: { return {} }
    property variant defaultValue: { return {} }
    property bool writing: false
    property bool loadOnConfigChange: true
    signal loaded()

    Component.onCompleted: {
        load()
    }

    onConfigValueChanged: {
        if (loadOnConfigChange && !writing) {
            load()
        }
    }

    onDefaultValueChanged: {
        if (configValue === '') { // Optimization
            load()
        }
    }

    function _escapeXml(s) {
        s = (typeof s === "undefined" || s === null) ? "" : ("" + s)
        return s
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
            .replace(/'/g, "&apos;")
    }

    function _unescapeXml(s) {
        s = (typeof s === "undefined" || s === null) ? "" : ("" + s)
        return s
            .replace(/&apos;/g, "'")
            .replace(/&quot;/g, '"')
            .replace(/&gt;/g, ">")
            .replace(/&lt;/g, "<")
            .replace(/&amp;/g, "&")
    }

    function _propTypeForValue(v) {
        if (typeof v === "boolean") {
            return "bool"
        }
        if (typeof v === "number") {
            return (Math.floor(v) === v) ? "int" : "double"
        }
        if (typeof v === "object" && v !== null) {
            return "json"
        }
        return "string"
    }

    function _normalizePropValueForType(value, typeName) {
        if (typeName === "bool") {
            if (typeof value === "boolean") {
                return value
            }
            if (typeof value === "number") {
                return value !== 0
            }
            var s = ("" + value).trim().toLowerCase()
            return (s === "true" || s === "1" || s === "yes" || s === "on")
        }
        if (typeName === "int") {
            var n = parseInt(value, 10)
            return isNaN(n) ? 0 : n
        }
        if (typeName === "double") {
            var f = parseFloat(value)
            return isNaN(f) ? 0 : f
        }
        if (typeName === "json") {
            try {
                return JSON.parse("" + value)
            } catch (e) {
                return null
            }
        }
        return (typeof value === "undefined" || value === null) ? "" : ("" + value)
    }

    function _parseTileModelXml(xml) {
        var out = []
        var reTile = /<tile\b[^>]*>([\s\S]*?)<\/tile>/g
        var tileMatch
        while ((tileMatch = reTile.exec(xml)) !== null) {
            var tileInner = tileMatch[1]
            var tileObj = {}
            var reProp = /<prop\s+[^>]*name=\"([^\"]+)\"[^>]*>([\s\S]*?)<\/prop>/g
            var propMatch
            while ((propMatch = reProp.exec(tileInner)) !== null) {
                var name = _unescapeXml(propMatch[1])
                var propInner = propMatch[2]
                var openTagMatch = /^<prop\s+[^>]*>/.exec(propMatch[0])
                var openTag = openTagMatch ? openTagMatch[0] : ""
                var typeMatch = /type=\"([^\"]+)\"/.exec(openTag)
                var typeName = typeMatch && typeMatch.length >= 2 ? _unescapeXml(typeMatch[1]) : "string"
                if (typeName === "json") {
                    var raw = (function(){ var m = /<!\[CDATA\[([\s\S]*?)\]\]>/.exec(propInner); return m && m.length>=2?m[1]:_unescapeXml((propInner||"").trim()) })()
                    tileObj[name] = _normalizePropValueForType(raw, "json")
                } else {
                    var raw2 = (function(){ var m = /<!\[CDATA\[([\s\S]*?)\]\]>/.exec(propInner); return m && m.length>=2?m[1]:_unescapeXml((propInner||"").trim()) })()
                    tileObj[name] = _normalizePropValueForType(raw2, typeName)
                }
            }
            out.push(tileObj)
        }
        return out
    }

    function _buildTilesXmlFragment(tileModelArray) {
        var tiles = Array.isArray(tileModelArray) ? tileModelArray : []
        var lines = []
        lines.push("<tiles>")
        for (var i = 0; i < tiles.length; i++) {
            var tile = tiles[i]
            if (!tile || typeof tile !== "object") {
                continue
            }
            lines.push("  <tile>")
            var keys = Object.keys(tile)
            keys.sort()
            for (var ki = 0; ki < keys.length; ki++) {
                var k = keys[ki]
                var v = tile[k]
                var t = _propTypeForValue(v)
                if (t === "json") {
                    var jsonText = "null"
                    try {
                        jsonText = JSON.stringify(v, null, 2)
                    } catch (e) {
                        jsonText = "null"
                    }
                    lines.push("    <prop name=\"" + _escapeXml(k) + "\" type=\"json\"><![CDATA[" + jsonText + "]]></prop>")
                } else {
                    lines.push("    <prop name=\"" + _escapeXml(k) + "\" type=\"" + t + "\">" + _escapeXml(v) + "</prop>")
                }
            }
            lines.push("  </tile>")
        }
        lines.push("</tiles>")
        return lines.join("\n")
    }

    function getBase64Xml(key, defaultValue) {
        if (configValue === '') {
            return defaultValue
        }
        var val = Qt.atob(configValue) // decode base64
        // If it looks like XML, parse tiles
        var trimmed = ("" + val).trim()
        if (trimmed.indexOf('<') === 0) {
            // Expecting a <tiles>...</tiles> fragment
            return _parseTileModelXml(trimmed)
        }
        // Fallback: try JSON
        try {
            return JSON.parse(val)
        } catch (e) {
            return defaultValue
        }
    }

    function setBase64Xml(key, data) {
        // Serialize to an XML <tiles> fragment then base64 encode
        var xml = _buildTilesXmlFragment(data)
        var val = Qt.btoa(xml)
        writing = true
        plasmoid.configuration[key] = val
        writing = false
    }

    function set(obj) {
        setBase64Xml(configKey, obj)
    }

    function load() {
        value = getBase64Xml(configKey, defaultValue)
        loaded()
    }

    function save() {
        setBase64Xml(configKey, value || defaultValue)
    }
}
