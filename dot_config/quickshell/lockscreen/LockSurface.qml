import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Effects
import Quickshell.Wayland

Rectangle {
	id: root
	required property LockContext context
	property var screen: null
	property bool animate: true
	property string prerenderedBackground: ""
	signal animationFinished()
	signal blurredImageReady(string imageUrl)

	color: "black"
	opacity: animate ? 0 : 1

	Component.onCompleted: {
		console.log("LockSurface initialized. Screen:", screen, "Animate:", animate, "Prerendered:", prerenderedBackground !== "");
	}

	NumberAnimation {
		id: fadeInAnimation
		target: root
		property: "opacity"
		running: root.animate
		from: 0
		to: 1
		duration: 800
		easing.type: Easing.OutCubic
		onFinished: {
			captureBlurredImage();
		}
	}

	function captureBlurredImage() {
		blurEffect.grabToImage(function(result) {
			root.blurredImageReady(result.url);
			root.animationFinished();
		});
	}

	// Prerendered background image (used by the real lock surface)
	Image {
		anchors.fill: parent
		source: root.prerenderedBackground
		visible: root.prerenderedBackground !== ""
		fillMode: Image.Stretch
	}

	// Native Quickshell screencopy (only used by preview window)
	ScreencopyView {
		id: screencopy
		anchors.fill: parent
		captureSource: root.screen
		live: root.prerenderedBackground === ""
		visible: false
	}

	// Stop live capture after a short delay to prevent feedback loops
	Timer {
		interval: 200
		running: root.prerenderedBackground === "" && screencopy.live
		onTriggered: screencopy.live = false;
	}

	MultiEffect {
		id: blurEffect
		anchors.fill: parent
		source: screencopy
		visible: root.prerenderedBackground === ""

		blurEnabled: true
		blur: 0.8
		blurMax: 48

		opacity: 1
	}

	Item {
		id: indicatorContainer
		anchors.centerIn: parent
		width: indicator.width + 40
		height: indicator.height + 40

		// Glow layer (behind the sharp ring)
		MultiEffect {
			id: bloomEffect
			anchors.centerIn: indicator
			width: indicator.width
			height: indicator.height
			source: indicator
			z: 0

			autoPaddingEnabled: true
			blurEnabled: true
			blur: 1.0
			blurMax: 64

			brightness: 0.5
		}

		// Sharp ring layer (on top)
		LockIndicator {
			id: indicator
			anchors.centerIn: parent
			radius: 100
			thickness: 5
			z: 1

			insideColor: "#00000000"
			ringColor: "#00000000"
			keyHlColor: "#c3c3c3"
			bsHlColor: "#e8875b"
			ringVerColor: "#c3c3c3"
			ringWrongColor: "#ff0000"
			ringClearColor: "#c3c3c3"

			verifying: root.context.unlockInProgress
			wrong: root.context.showFailure

			Connections {
				target: root.context
				function onKeyPressed(isBackspace) {
					indicator.flash(isBackspace);
				}
			}
		}
	}

	// Hidden input to capture keyboard events
	TextField {
		id: passwordBox
		opacity: 0
		focus: true
		enabled: !root.context.unlockInProgress

		onTextChanged: root.context.currentText = this.text;
		onAccepted: root.context.tryUnlock();

		Keys.onPressed: (event) => {
			if (event.key === Qt.Key_Backspace) {
				if (passwordBox.text.length > 0) {
					root.context.keyPressed(true);
				}
			} else if (event.text !== "" && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Tab) {
				root.context.keyPressed(false);
			}
		}

		Connections {
			target: root.context
			function onCurrentTextChanged() {
				passwordBox.text = root.context.currentText;
			}
		}
	}
}
