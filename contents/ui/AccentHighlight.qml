import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
	id: root

	property color accentColor: Kirigami.Theme.highlightColor
	property real radius: 0
	property real inset: 0
	property real borderOpacity: 0.95
	property real glowOpacity: 0.65
	property real fillStrength: 1.0
	property real innerRimOpacity: 0.26
	property real borderWidth: Math.max(1, Math.round(Screen.devicePixelRatio))

	function requestPaint() {
		canvas.requestPaint()
	}

	Canvas {
		id: canvas
		anchors.fill: parent
		antialiasing: true

		function colorWithAlpha(color, alpha) {
			return Qt.rgba(color.r, color.g, color.b, Math.max(0, Math.min(1, alpha)))
		}

		function roundedRectPath(ctx, x, y, w, h, r) {
			var rr = Math.max(0, Math.min(r, Math.min(w, h) / 2))
			ctx.beginPath()
			ctx.moveTo(x + rr, y)
			ctx.lineTo(x + w - rr, y)
			ctx.arcTo(x + w, y, x + w, y + rr, rr)
			ctx.lineTo(x + w, y + h - rr)
			ctx.arcTo(x + w, y + h, x + w - rr, y + h, rr)
			ctx.lineTo(x + rr, y + h)
			ctx.arcTo(x, y + h, x, y + h - rr, rr)
			ctx.lineTo(x, y + rr)
			ctx.arcTo(x, y, x + rr, y, rr)
			ctx.closePath()
		}

		onPaint: {
			var ctx = getContext("2d")
			ctx.clearRect(0, 0, width, height)

			var bw = Math.max(1, root.borderWidth)
			var x = root.inset + bw * 0.5
			var y = root.inset + bw * 0.5
			var w = Math.max(0, width - (root.inset * 2) - bw)
			var h = Math.max(0, height - (root.inset * 2) - bw)
			var r = Math.max(0, root.radius - root.inset)
			if (w <= 0 || h <= 0) {
				return
			}

			// Soft accent bloom that fades inward from the border.
			var glowSteps = 5
			for (var i = glowSteps; i >= 1; --i) {
				var grow = i * bw
				roundedRectPath(ctx, x + grow * 0.35, y + grow * 0.35, Math.max(0, w - grow * 0.7), Math.max(0, h - grow * 0.7), Math.max(0, r - grow * 0.35))
				ctx.lineWidth = bw + i
				ctx.strokeStyle = colorWithAlpha(root.accentColor, root.glowOpacity * (0.07 + (glowSteps - i) * 0.025))
				ctx.stroke()
			}

			roundedRectPath(ctx, x, y, w, h, r)
			ctx.save()
			ctx.clip()

			var vertical = ctx.createLinearGradient(0, y, 0, y + h)
			vertical.addColorStop(0.00, colorWithAlpha(root.accentColor, 0.22 * root.fillStrength))
			vertical.addColorStop(0.42, colorWithAlpha(root.accentColor, 0.105 * root.fillStrength))
			vertical.addColorStop(1.00, colorWithAlpha(root.accentColor, 0.035 * root.fillStrength))
			ctx.fillStyle = vertical
			ctx.fillRect(x, y, w, h)

			var sideWash = ctx.createLinearGradient(x, 0, x + w, 0)
			sideWash.addColorStop(0.00, colorWithAlpha(root.accentColor, 0.15 * root.fillStrength))
			sideWash.addColorStop(0.46, colorWithAlpha(root.accentColor, 0.045 * root.fillStrength))
			sideWash.addColorStop(1.00, colorWithAlpha(root.accentColor, 0.012 * root.fillStrength))
			ctx.fillStyle = sideWash
			ctx.fillRect(x, y, w, h)

			var bloom = ctx.createRadialGradient(x + w * 0.18, y + h * 0.10, 0, x + w * 0.18, y + h * 0.10, Math.max(w, h) * 0.92)
			bloom.addColorStop(0.00, colorWithAlpha(root.accentColor, 0.22 * root.fillStrength))
			bloom.addColorStop(0.48, colorWithAlpha(root.accentColor, 0.075 * root.fillStrength))
			bloom.addColorStop(1.00, colorWithAlpha(root.accentColor, 0.00))
			ctx.fillStyle = bloom
			ctx.fillRect(x, y, w, h)

			var shade = ctx.createLinearGradient(x, y, x + w, y + h)
			shade.addColorStop(0.00, Qt.rgba(1, 1, 1, 0.045 * root.fillStrength))
			shade.addColorStop(0.55, Qt.rgba(0, 0, 0, 0.00))
			shade.addColorStop(1.00, Qt.rgba(0, 0, 0, 0.10 * root.fillStrength))
			ctx.fillStyle = shade
			ctx.fillRect(x, y, w, h)

			ctx.restore()

			roundedRectPath(ctx, x, y, w, h, r)
			ctx.lineWidth = bw
			ctx.strokeStyle = colorWithAlpha(root.accentColor, root.borderOpacity)
			ctx.stroke()
		}

		onWidthChanged: requestPaint()
		onHeightChanged: requestPaint()
	}

	onAccentColorChanged: canvas.requestPaint()
	onRadiusChanged: canvas.requestPaint()
	onInsetChanged: canvas.requestPaint()
	onBorderOpacityChanged: canvas.requestPaint()
	onGlowOpacityChanged: canvas.requestPaint()
	onFillStrengthChanged: canvas.requestPaint()
	onInnerRimOpacityChanged: canvas.requestPaint()
	onBorderWidthChanged: canvas.requestPaint()
	onVisibleChanged: {
		if (visible) {
			canvas.requestPaint()
		}
	}
}
