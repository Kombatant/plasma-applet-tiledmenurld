.pragma library

var _alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function _utf8Bytes(text) {
	text = (typeof text === "undefined" || text === null) ? "" : ("" + text)
	var bytes = []
	for (var i = 0; i < text.length; i++) {
		var codePoint = text.charCodeAt(i)
		if (codePoint >= 0xd800 && codePoint <= 0xdbff && i + 1 < text.length) {
			var next = text.charCodeAt(i + 1)
			if (next >= 0xdc00 && next <= 0xdfff) {
				codePoint = 0x10000 + ((codePoint - 0xd800) << 10) + (next - 0xdc00)
				i++
			}
		}

		if (codePoint < 0x80) {
			bytes.push(codePoint)
		} else if (codePoint < 0x800) {
			bytes.push(0xc0 | (codePoint >> 6))
			bytes.push(0x80 | (codePoint & 0x3f))
		} else if (codePoint < 0x10000) {
			bytes.push(0xe0 | (codePoint >> 12))
			bytes.push(0x80 | ((codePoint >> 6) & 0x3f))
			bytes.push(0x80 | (codePoint & 0x3f))
		} else {
			bytes.push(0xf0 | (codePoint >> 18))
			bytes.push(0x80 | ((codePoint >> 12) & 0x3f))
			bytes.push(0x80 | ((codePoint >> 6) & 0x3f))
			bytes.push(0x80 | (codePoint & 0x3f))
		}
	}
	return bytes
}

function _stringFromUtf8Bytes(bytes) {
	var out = ""
	for (var i = 0; i < bytes.length; i++) {
		var b0 = bytes[i]
		var codePoint = 0
		if (b0 < 0x80) {
			codePoint = b0
		} else if ((b0 & 0xe0) === 0xc0 && i + 1 < bytes.length) {
			codePoint = ((b0 & 0x1f) << 6) | (bytes[++i] & 0x3f)
		} else if ((b0 & 0xf0) === 0xe0 && i + 2 < bytes.length) {
			codePoint = ((b0 & 0x0f) << 12) | ((bytes[++i] & 0x3f) << 6) | (bytes[++i] & 0x3f)
		} else if ((b0 & 0xf8) === 0xf0 && i + 3 < bytes.length) {
			codePoint = ((b0 & 0x07) << 18) | ((bytes[++i] & 0x3f) << 12) | ((bytes[++i] & 0x3f) << 6) | (bytes[++i] & 0x3f)
		} else {
			throw new Error("Invalid UTF-8 base64 data")
		}

		if (codePoint <= 0xffff) {
			out += String.fromCharCode(codePoint)
		} else {
			codePoint -= 0x10000
			out += String.fromCharCode(0xd800 + (codePoint >> 10))
			out += String.fromCharCode(0xdc00 + (codePoint & 0x3ff))
		}
	}
	return out
}

function _stringFromLatin1Bytes(bytes) {
	var out = ""
	for (var i = 0; i < bytes.length; i++) {
		out += String.fromCharCode(bytes[i])
	}
	return out
}

function encodeString(text) {
	var bytes = _utf8Bytes(text)
	var out = ""
	for (var i = 0; i < bytes.length; i += 3) {
		var b0 = bytes[i]
		var b1 = (i + 1 < bytes.length) ? bytes[i + 1] : 0
		var b2 = (i + 2 < bytes.length) ? bytes[i + 2] : 0
		var triplet = (b0 << 16) | (b1 << 8) | b2
		out += _alphabet[(triplet >> 18) & 0x3f]
		out += _alphabet[(triplet >> 12) & 0x3f]
		out += (i + 1 < bytes.length) ? _alphabet[(triplet >> 6) & 0x3f] : "="
		out += (i + 2 < bytes.length) ? _alphabet[triplet & 0x3f] : "="
	}
	return out
}

function decodeString(encoded) {
	encoded = (encoded || "").replace(/\s/g, "")
	var bytes = []
	for (var i = 0; i < encoded.length; i += 4) {
		var c0 = _alphabet.indexOf(encoded.charAt(i))
		var c1 = _alphabet.indexOf(encoded.charAt(i + 1))
		var c2Char = encoded.charAt(i + 2)
		var c3Char = encoded.charAt(i + 3)
		var c2 = c2Char === "=" ? 0 : _alphabet.indexOf(c2Char)
		var c3 = c3Char === "=" ? 0 : _alphabet.indexOf(c3Char)
		if (c0 < 0 || c1 < 0 || (c2Char !== "=" && c2 < 0) || (c3Char !== "=" && c3 < 0)) {
			throw new Error("Invalid base64 data")
		}

		var triplet = (c0 << 18) | (c1 << 12) | (c2 << 6) | c3
		bytes.push((triplet >> 16) & 0xff)
		if (c2Char !== "=") {
			bytes.push((triplet >> 8) & 0xff)
		}
		if (c3Char !== "=") {
			bytes.push(triplet & 0xff)
		}
	}
	try {
		return _stringFromUtf8Bytes(bytes)
	} catch (e) {
		return _stringFromLatin1Bytes(bytes)
	}
}
