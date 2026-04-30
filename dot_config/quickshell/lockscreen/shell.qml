import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
	id: root

	LockContext {
		id: lockContext

		onUnlocked: {
			lock.locked = false;
			Qt.quit();
		}
	}

	property bool startLocking: false
	property bool showPreview: true
	property string capturedBlurUrl: ""

	Variants {
		id: screenVariants
		model: Quickshell.screens

		PanelWindow {
			id: previewWindow
			required property var modelData
			screen: modelData
			implicitWidth: screen.width
			implicitHeight: screen.height
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "lockscreen"

			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}
			exclusiveZone: -1

			visible: root.showPreview

			LockSurface {
				anchors.fill: parent
				context: lockContext
				screen: previewWindow.screen
				animate: true

				onBlurredImageReady: (imageUrl) => {
					root.capturedBlurUrl = imageUrl;
				}

				onAnimationFinished: {
					root.startLocking = true;
				}
			}
		}
	}

	WlSessionLock {
		id: lock
		locked: root.startLocking

		WlSessionLockSurface {
			id: lockSurfaceWrapper
			color: "black"

			LockSurface {
				anchors.fill: parent
				context: lockContext
				screen: lockSurfaceWrapper.screen
				animate: false
				prerenderedBackground: root.capturedBlurUrl
				Component.onCompleted: {
					hidePreviewTimer.start();
				}
			}
		}
	}

	Timer {
		id: hidePreviewTimer
		interval: 500
		onTriggered: root.showPreview = false;
	}
}
