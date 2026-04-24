import QtQuick
import QtQuick.Controls as QQC2

QQC2.StackView {
	id: stackView
	clip: true

	// Direction for docked-sidebar slide transitions: +1 slides new view in from the right
	// (old exits to the left), -1 slides new view in from the left. 0 = no slide animation.
	property int slideDirection: 0
	readonly property bool _slideEnabled: config.usesDockedSidebarLayout && slideDirection !== 0

	replaceEnter: Transition {
		ParallelAnimation {
			NumberAnimation {
				property: "x"
				from: stackView._slideEnabled ? stackView.width * stackView.slideDirection : 0
				to: 0
				duration: stackView._slideEnabled ? 280 : 0
				easing.type: Easing.OutCubic
			}
			NumberAnimation {
				property: "opacity"
				from: stackView._slideEnabled ? 0.0 : 1.0
				to: 1.0
				duration: stackView._slideEnabled ? 180 : 0
			}
		}
	}

	replaceExit: Transition {
		ParallelAnimation {
			NumberAnimation {
				property: "x"
				from: 0
				to: stackView._slideEnabled ? -stackView.width * stackView.slideDirection : 0
				duration: stackView._slideEnabled ? 280 : 0
				easing.type: Easing.OutCubic
			}
			NumberAnimation {
				property: "opacity"
				from: 1.0
				to: stackView._slideEnabled ? 0.0 : 1.0
				duration: stackView._slideEnabled ? 180 : 0
			}
		}
	}

	pushEnter: Transition {}
	pushExit: Transition {}
	popEnter: Transition {}
	popExit: Transition {}
}
