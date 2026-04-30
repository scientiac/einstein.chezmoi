import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
	id: root

	// === Central state ===
	// "none", "iconBar", "volume", "mic", "brightness", "keyboard", "battery"
	property string currentView: "none"
	property bool mouseHovering: false
	property bool userDragging: false

	// === Hide timer (hover-aware) ===
	Timer {
		id: hideTimer
		interval: root.currentView === "iconBar" ? 1500 : 2000
		onTriggered: {
			if (!root.mouseHovering && !root.userDragging) {
				root.currentView = "none";
			} else {
				hideTimer.restart();
			}
		}
	}

	function showView(view) {
		root.currentView = view;
		hideTimer.restart();
	}

	// === Data providers ===
	VolumeOsd { id: volumeOsd }
	BrightnessOsd { id: brightnessOsd }
	KeyboardBacklightOsd { id: kbdOsd }
	BatteryOsd { id: batteryOsd }

	// === Prevent startup triggers ===
	property bool isInitialized: false
	Timer {
		id: initTimer
		interval: 500
		running: true
		onTriggered: root.isInitialized = true
	}

	// === React to hardware changes ===
	Connections {
		target: volumeOsd
		function onVolumeChanged() {
			if (!root.isInitialized) return;
			if (!root.userDragging || root.currentView !== "volume")
				root.showView("volume");
		}
		function onMicChanged() {
			if (!root.isInitialized) return;
			if (!root.userDragging || root.currentView !== "mic")
				root.showView("mic");
		}
	}

	Connections {
		target: brightnessOsd
		function onBrightnessChanged() {
			if (!root.isInitialized) return;
			if (!root.userDragging || root.currentView !== "brightness")
				root.showView("brightness");
		}
	}

	Connections {
		target: kbdOsd
		function onBrightnessChanged() {
			if (!root.isInitialized) return;
			root.showView("keyboard");
		}
	}

	property bool _brightnessDimmed: false

	function _runCmd(cmd) {
		let proc = Qt.createQmlObject(`
			import Quickshell.Io
			Process { command: ["sh", "-c", "${cmd}"]; onExited: destroy() }
		`, root);
		proc.running = true;
	}

	// === Battery threshold triggers ===
	Connections {
		target: batteryOsd
		function onBatteryLow() {
			if (!root.isInitialized) return;
			root.showView("battery");
			root._brightnessDimmed = true;
			root._runCmd("brightnessctl --save; brightnessctl set 10%");
		}
		function onBatteryCritical() {
			if (!root.isInitialized) return;
			root.showView("battery");
			root._brightnessDimmed = true;
			root._runCmd("brightnessctl --save; brightnessctl set 5%");
		}
		function onBatteryHealthy() {
			if (!root.isInitialized) return;
			root.showView("battery");
		}
		function onBatteryFull() {
			if (!root.isInitialized) return;
			root.showView("battery");
		}
		function onIsChargingChanged() {
			if (!root.isInitialized) return;
			if (batteryOsd.isCharging) {
				root.showView("battery");
				if (root._brightnessDimmed) {
					root._runCmd("brightnessctl --restore");
					root._brightnessDimmed = false;
				}
			}
		}
	}

	// === The OSD Window ===
	OsdWindow {
		currentView: root.currentView

		// Bind live data
		volumeLevel: volumeOsd.sinkVolume
		volumeMuted: volumeOsd.sinkMuted
		micLevel: volumeOsd.sourceVolume
		micMuted: volumeOsd.sourceMuted
		brightnessLevel: brightnessOsd.level >= 0 ? brightnessOsd.level : 0
		kbdLevel: kbdOsd.level >= 0 ? kbdOsd.level : 0
		kbdMaxSteps: kbdOsd.maxSteps

		// Battery data
		batteryLevel: batteryOsd.percentage
		batteryCharging: batteryOsd.isCharging
		batteryChargeLimit: batteryOsd.chargeLimit
		batteryIconName: batteryOsd.iconName

		// Handle control signals
		onSetVolume: (val) => volumeOsd.setVolume(val)
		onToggleVolumeMute: volumeOsd.toggleMute()
		onSetMicVolume: (val) => volumeOsd.setMicVolume(val)
		onToggleMicMute: volumeOsd.toggleMicMute()
		onSetBrightness: (val) => brightnessOsd.setBrightness(val)
		onSetKbdBrightness: (val) => kbdOsd.setLevel(val)
		onToggleKbdOff: kbdOsd.toggleOff()

		onIconClicked: (which) => {
			if (which === "_showBar") {
				if (!root.userDragging && root.currentView !== "iconBar") {
					root.showView("iconBar");
				}
			} else {
				root.showView(which);
			}
		}

		onSetChargeLimit: (limit) => batteryOsd.setChargeLimit(limit)

		onOsdMouseEntered: {
			root.mouseHovering = true;
			hideTimer.stop();
		}

		onOsdMouseExited: {
			root.mouseHovering = false;
			if (root.currentView !== "none") {
				hideTimer.restart();
			}
		}

		onOsdDragStarted: root.userDragging = true;
		onOsdDragEnded: {
			root.userDragging = false;
			if (!root.mouseHovering && root.currentView !== "none") {
				hideTimer.restart();
			}
		}
	}


}
