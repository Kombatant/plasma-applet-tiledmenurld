import QtQuick
import QtQuick.Controls as QQC2

QQC2.StackView {
	id: stackView
	clip: true

	// Disable all transitions to prevent Qt from animating opacity
	// (which can get stuck at 0 when the StackView is reparented at zero width).
	replaceEnter: Transition {}
	replaceExit: Transition {}
	pushEnter: Transition {}
	pushExit: Transition {}
	popEnter: Transition {}
	popExit: Transition {}
}
