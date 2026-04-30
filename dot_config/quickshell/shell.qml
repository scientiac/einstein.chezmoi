//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "./osd" as Osd
import "./bar" as Bar
import "./notifications" as Notifs

ShellRoot {
	id: root

	// === Shared notification server ===
	NotificationServer {
		id: notifServer
		keepOnReload: true
		actionsSupported: true
		imageSupported: true
		bodySupported: true
		bodyMarkupSupported: true
		persistenceSupported: true

		onNotification: (notification) => {
			notification.tracked = true;
			if (!root.dndEnabled || notification.urgency === NotificationUrgency.Critical) {
				popupManager.showPopup(notification);
			}
			console.log("Notification received, tracked = " + notification.tracked);
		}
	}

	Timer {
		interval: 2000
		running: true
		repeat: true
		onTriggered: {
			if (notifServer && notifServer.notifications) {
				console.log("DEBUG: notifServer.notifications count=" + notifServer.notifications.count + " length=" + notifServer.notifications.length);
			}
		}
	}

	// === Shared state ===
	property bool dndEnabled: false

	// === Popup queue manager ===
	ListModel {
		id: popupManager
		readonly property int maxPopups: 3

		function showPopup(notification) {
			insert(0, { "notifObj": notification });
			if (count > maxPopups) {
				remove(maxPopups, count - maxPopups);
			}
		}

		function removePopup(notification) {
			for (let i = 0; i < count; i++) {
				if (get(i).notifObj === notification) {
					remove(i, 1);
					return;
				}
			}
		}
	}

	// ==========================================
	// === Existing bottom OSD (inlined Scope) ==
	// ==========================================
	Scope {
		id: osdScope

		property string currentView: "none"
		property bool mouseHovering: false
		property bool userDragging: false

		Timer {
			id: hideTimer
			interval: osdScope.currentView === "iconBar" ? 1500 : 2000
			onTriggered: {
				if (!osdScope.mouseHovering && !osdScope.userDragging) {
					osdScope.currentView = "none";
				} else {
					hideTimer.restart();
				}
			}
		}

		function showView(view) {
			osdScope.currentView = view;
			hideTimer.restart();
		}

		Osd.VolumeOsd { id: volumeOsd }
		Osd.BrightnessOsd { id: brightnessOsd }
		Osd.KeyboardBacklightOsd { id: kbdOsd }
		Osd.BatteryOsd { id: batteryOsd }

		property bool isInitialized: false
		Timer {
			id: initTimer
			interval: 500
			running: true
			onTriggered: osdScope.isInitialized = true
		}

		Connections {
			target: volumeOsd
			function onVolumeChanged() {
				if (!osdScope.isInitialized) return;
				if (!osdScope.userDragging || osdScope.currentView !== "volume")
					osdScope.showView("volume");
			}
			function onMicChanged() {
				if (!osdScope.isInitialized) return;
				if (!osdScope.userDragging || osdScope.currentView !== "mic")
					osdScope.showView("mic");
			}
		}

		Connections {
			target: brightnessOsd
			function onBrightnessChanged() {
				if (!osdScope.isInitialized) return;
				if (!osdScope.userDragging || osdScope.currentView !== "brightness")
					osdScope.showView("brightness");
			}
		}

		Connections {
			target: kbdOsd
			function onBrightnessChanged() {
				if (!osdScope.isInitialized) return;
				osdScope.showView("keyboard");
			}
		}

		property bool _brightnessDimmed: false

		function _runCmd(cmd) {
			let proc = Qt.createQmlObject(`
				import Quickshell.Io
				Process { command: ["sh", "-c", "${cmd}"]; onExited: destroy() }
			`, osdScope);
			proc.running = true;
		}

		Connections {
			target: batteryOsd
			function onBatteryLow() {
				if (!osdScope.isInitialized) return;
				osdScope.showView("battery");
				osdScope._brightnessDimmed = true;
				osdScope._runCmd("brightnessctl --save; brightnessctl set 10%");
			}
			function onBatteryCritical() {
				if (!osdScope.isInitialized) return;
				osdScope.showView("battery");
				osdScope._brightnessDimmed = true;
				osdScope._runCmd("brightnessctl --save; brightnessctl set 5%");
			}
			function onBatteryHealthy() {
				if (!osdScope.isInitialized) return;
				osdScope.showView("battery");
			}
			function onBatteryFull() {
				if (!osdScope.isInitialized) return;
				osdScope.showView("battery");
			}
			function onIsChargingChanged() {
				if (!osdScope.isInitialized) return;
				if (batteryOsd.isCharging) {
					osdScope.showView("battery");
					if (osdScope._brightnessDimmed) {
						osdScope._runCmd("brightnessctl --restore");
						osdScope._brightnessDimmed = false;
					}
				}
			}
		}

		Osd.OsdWindow {
			currentView: osdScope.currentView

			volumeLevel: volumeOsd.sinkVolume
			volumeMuted: volumeOsd.sinkMuted
			micLevel: volumeOsd.sourceVolume
			micMuted: volumeOsd.sourceMuted
			brightnessLevel: brightnessOsd.level >= 0 ? brightnessOsd.level : 0
			kbdLevel: kbdOsd.level >= 0 ? kbdOsd.level : 0
			kbdMaxSteps: kbdOsd.maxSteps

			batteryLevel: batteryOsd.percentage
			batteryCharging: batteryOsd.isCharging
			batteryChargeLimit: batteryOsd.chargeLimit
			batteryIconName: batteryOsd.iconName

			onSetVolume: (val) => volumeOsd.setVolume(val)
			onToggleVolumeMute: volumeOsd.toggleMute()
			onSetMicVolume: (val) => volumeOsd.setMicVolume(val)
			onToggleMicMute: volumeOsd.toggleMicMute()
			onSetBrightness: (val) => brightnessOsd.setBrightness(val)
			onSetKbdBrightness: (val) => kbdOsd.setLevel(val)
			onToggleKbdOff: kbdOsd.toggleOff()

			onIconClicked: (which) => {
				if (which === "_showBar") {
					if (!osdScope.userDragging && osdScope.currentView !== "iconBar") {
						osdScope.showView("iconBar");
					}
				} else {
					osdScope.showView(which);
				}
			}

			onSetChargeLimit: (limit) => batteryOsd.setChargeLimit(limit)

			onOsdMouseEntered: {
				osdScope.mouseHovering = true;
				hideTimer.stop();
			}

			onOsdMouseExited: {
				osdScope.mouseHovering = false;
				if (osdScope.currentView !== "none") {
					hideTimer.restart();
				}
			}

			onOsdDragStarted: osdScope.userDragging = true;
			onOsdDragEnded: {
				osdScope.userDragging = false;
				if (!osdScope.mouseHovering && osdScope.currentView !== "none") {
					hideTimer.restart();
				}
			}
		}
	}

	// === Top bar (per screen) ===
	Variants {
		model: Quickshell.screens

		Bar.TopBar {
			required property var modelData
			screen: modelData
			notifServer: notifServer
			dndEnabled: root.dndEnabled
			onToggleDnd: root.dndEnabled = !root.dndEnabled
		}
	}

	// === Notification popups (per screen) ===
	Variants {
		model: Quickshell.screens

		Notifs.NotificationPopup {
			required property var modelData
			screen: modelData
			popupQueue: popupManager
			onDismissPopup: (notif) => popupManager.removePopup(notif)
		}
	}
}
