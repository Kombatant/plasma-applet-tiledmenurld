.pragma library
// Version 6

function request(opt, callback) {
	if (typeof opt === 'string') {
		opt = { url: opt }
	}
	var req = new XMLHttpRequest()
	req.onerror = function(e) {
		if (e) {
			callback(e.message)
		} else {
			callback('XMLHttpRequest.onerror(undefined)')
		}
	}
	req.onreadystatechange = function() {
		if (req.readyState === XMLHttpRequest.DONE) { // https://xhr.spec.whatwg.org/#dom-xmlhttprequest-done
			if (200 <= req.status && req.status < 400) {
				callback(null, req.responseText, req)
			} else {
				var msg = "HTTP Error " + req.status + ": " + req.statusText
				callback(msg, req.responseText, req)
			}
		}
	}
	req.open(opt.method || "GET", opt.url, true)
	if (opt.headers) {
		for (var key in opt.headers) {
			req.setRequestHeader(key, opt.headers[key])
		}
	}
	req.send(opt.data)
}

function encodeFormData(opt) {
	opt.headers = opt.headers || {}
	opt.headers['Content-Type'] = 'application/x-www-form-urlencoded'
	if (opt.data) {
		var parts = []

		function addPair(key, value) {
			var v = (value === null || typeof value === 'undefined') ? '' : value
			parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(v))
		}

		function flatten(value, prefix) {
			if (value === null || typeof value === 'undefined') {
				addPair(prefix, '')
				return
			}
			if (Array.isArray(value)) {
				for (var i = 0; i < value.length; i++) {
					flatten(value[i], prefix + '[' + i + ']')
				}
				return
			}
			if (typeof value === 'object') {
				for (var key in value) {
					if (!value.hasOwnProperty(key)) {
						continue
					}
					flatten(value[key], prefix + '[' + key + ']')
				}
				return
			}
			addPair(prefix, value)
		}

		for (var rootKey in opt.data) {
			if (!opt.data.hasOwnProperty(rootKey)) {
				continue
			}
			flatten(opt.data[rootKey], rootKey)
		}
		opt.data = parts.join('&')
	}
	return opt
}

function post(opt, callback) {
	if (typeof opt === 'string') {
		opt = { url: opt }
	}
	opt.method = 'POST'
	encodeFormData(opt)
	request(opt, callback)
}


function getJSON(opt, callback) {
	if (typeof opt === 'string') {
		opt = { url: opt }
	}
	opt.headers = opt.headers || {}
	opt.headers['Accept'] = 'application/json'
	request(opt, function(err, data, req) {
		if (!err && data) {
			data = JSON.parse(data)
		}
		callback(err, data, req)
	})
}


function postJSON(opt, callback) {
	if (typeof opt === 'string') {
		opt = { url: opt }
	}
	opt.method = opt.method || 'POST'
	opt.headers = opt.headers || {}
	opt.headers['Content-Type'] = 'application/json'
	if (opt.data) {
		opt.data = JSON.stringify(opt.data)
	}
	getJSON(opt, callback)
}

