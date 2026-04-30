import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
	id: root

	property string currentView: "none"
	property bool isVisible: currentView !== "none"

	property real volumeLevel: 0
	property bool volumeMuted: false
	property real micLevel: 0
	property bool micMuted: false
	property real brightnessLevel: 0
	property real kbdLevel: 0
	property int kbdMaxSteps: 3

	// Battery properties
	property real batteryLevel: -1
	property bool batteryCharging: false
	property int batteryChargeLimit: -1
	property string batteryIconName: "battery-level-100-symbolic"

	signal setVolume(real val)
	signal toggleVolumeMute()
	signal setMicVolume(real val)
	signal toggleMicMute()
	signal setBrightness(real val)
	signal setKbdBrightness(real val)
	signal toggleKbdOff()
	signal iconClicked(string which)
	signal osdMouseEntered()
	signal osdMouseExited()
	signal osdDragStarted()
	signal osdDragEnded()
	signal setChargeLimit(int limit)

	anchors.bottom: true
	anchors.left: true
	anchors.right: true
	margins.bottom: 0
	exclusiveZone: 0
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Overlay

	mask: Region { item: maskRect }

	implicitHeight: 80

	// === Mask (trigger strip when hidden, content+swoops when visible) ===
	Rectangle {
		id: maskRect
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.bottom: parent.bottom
		width: root.isVisible ? animContainer.width + 40 : 240
		height: root.isVisible ? (root.height - animContainer.y + 4) : 6
		color: "transparent"
	}



	// === Dynamic Surface Tension Swoops ===
	Shape {
		id: dynamicSwoops
		readonly property real swoopW: 16
		readonly property real maxSwoopH: 14
		
		// visibleH is how much of the notch is currently visible above the bottom edge
		readonly property real visibleH: root.height - animContainer.y
		// currentSwoopH is bounded between 0 and maxSwoopH, so it only grows up to maxSwoopH
		readonly property real currentSwoopH: Math.max(0, Math.min(maxSwoopH, visibleH))

		x: animContainer.x - swoopW
		y: root.height - currentSwoopH
		width: animContainer.width + 2 * swoopW
		height: currentSwoopH

		visible: currentSwoopH > 0
		layer.enabled: true
		layer.samples: 4

		ShapePath {
			fillColor: "#000000"
			strokeWidth: 0

			startX: 0
			startY: dynamicSwoops.height

			// Left swoop
			PathQuad {
				x: dynamicSwoops.swoopW
				y: 0
				controlX: dynamicSwoops.swoopW
				controlY: dynamicSwoops.height
			}

			// Across body bottom
			PathLine {
				x: dynamicSwoops.width - dynamicSwoops.swoopW
				y: 0
			}

			// Right swoop
			PathQuad {
				x: dynamicSwoops.width
				y: dynamicSwoops.height
				controlX: dynamicSwoops.width - dynamicSwoops.swoopW
				controlY: dynamicSwoops.height
			}

			PathLine { x: 0; y: dynamicSwoops.height }
		}
	}

	// === Content body (slides up/down) ===
	Item {
		id: animContainer
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.bottom: parent.bottom

		implicitWidth: content.implicitWidth
		implicitHeight: content.implicitHeight

		transformOrigin: Item.Bottom

		// Rest completely flush with bottom. No gap. 
		anchors.bottomMargin: root.isVisible ? 0 : -(implicitHeight + 10)

		Behavior on anchors.bottomMargin {
			NumberAnimation {
				duration: 500
				easing.type: Easing.OutExpo
			}
		}

		OsdContent {
			id: content
			anchors.fill: parent
			view: root.currentView

			volumeLevel: root.volumeLevel
			volumeMuted: root.volumeMuted
			micLevel: root.micLevel
			micMuted: root.micMuted
			brightnessLevel: root.brightnessLevel
			kbdLevel: root.kbdLevel
			kbdMaxSteps: root.kbdMaxSteps

			batteryLevel: root.batteryLevel
			batteryCharging: root.batteryCharging
			batteryChargeLimit: root.batteryChargeLimit
			batteryIconName: root.batteryIconName

			onSetVolume: (val) => root.setVolume(val)
			onToggleVolumeMute: root.toggleVolumeMute()
			onSetMicVolume: (val) => root.setMicVolume(val)
			onToggleMicMute: root.toggleMicMute()
			onSetBrightness: (val) => root.setBrightness(val)
			onSetKbdBrightness: (val) => root.setKbdBrightness(val)
			onToggleKbdOff: root.toggleKbdOff()
			onIconClicked: (which) => root.iconClicked(which)
			onMouseEntered: root.osdMouseEntered()
			onMouseExited: root.osdMouseExited()
			onDragStarted: root.osdDragStarted()
			onDragEnded: root.osdDragEnded()
			onSetChargeLimit: (limit) => root.setChargeLimit(limit)
		}
	}

	// === Hover trigger zone (Moved to top of Z-stack) ===
	Timer {
		id: forceTriggerTimer
		interval: 500
		onTriggered: {
			if (root.currentView !== "iconBar") {
				root.iconClicked("_showBar");
			}
		}
	}

	MouseArea {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.bottom: parent.bottom
		width: 240; height: 10
		hoverEnabled: true
		onEntered: {
			root.osdMouseEntered();
			forceTriggerTimer.start();
		}
		onExited: {
			forceTriggerTimer.stop();
			root.osdMouseExited();
		}
	}
}
