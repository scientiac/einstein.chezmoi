import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Item {
	id: root

	// === Exposed live state ===
	readonly property real percentage: {
		if (_battery && _battery.ready) return _battery.percentage * 100;
		return -1;
	}
	readonly property bool isCharging: {
		if (_battery && _battery.ready) return _battery.state === UPowerDeviceState.Charging;
		return false;
	}
	readonly property bool isPresent: {
		if (_battery && _battery.ready) return _battery.isLaptopBattery;
		return false;
	}
	readonly property string iconName: {
		if (_battery && _battery.ready && _battery.iconName !== "") return _battery.iconName;
		// Fallback based on percentage
		if (percentage >= 80) return "battery-level-100-symbolic";
		if (percentage >= 60) return "battery-level-80-symbolic";
		if (percentage >= 40) return "battery-level-60-symbolic";
		if (percentage >= 20) return "battery-level-40-symbolic";
		if (percentage >= 10) return "battery-level-20-symbolic";
		return "battery-level-0-symbolic";
	}

	property int chargeLimit: -1
	property int healthyThreshold: 80

	// === Threshold signals ===
	signal batteryLow()      // <= 20%
	signal batteryCritical() // <= 10%
	signal batteryHealthy()  // >= healthyThreshold
	signal batteryFull()     // == 100%

	// === Internal ===
	property var _battery: UPower.displayDevice
	property real _prevPercentage: -1

	onPercentageChanged: {
		if (_prevPercentage < 0) {
			// First reading, just record
			_prevPercentage = percentage;
			return;
		}

		// Low threshold (crossing down to 20%)
		if (percentage <= 20 && _prevPercentage > 20) {
			root.batteryLow();
		}

		// Critical threshold (crossing down to 10%)
		if (percentage <= 10 && _prevPercentage > 10) {
			root.batteryCritical();
		}

		// Healthy threshold (crossing up to 80%)
		if (chargeLimit !== 80 && percentage >= 80 && _prevPercentage < 80) {
			root.batteryHealthy();
		}

		// Full threshold (from percentage crossing)
		const targetFull = chargeLimit > 0 ? chargeLimit : 100;
		if (percentage >= targetFull && _prevPercentage < targetFull) {
			root.batteryFull();
		}

		_prevPercentage = percentage;
	}

	// Watch for UPower state changes (e.g., hitting FullyCharged while plugged in)
	property bool _stateFiredFull: false
	Connections {
		target: _battery
		function onStateChanged() {
			if (_battery.state === UPowerDeviceState.FullyCharged && !_stateFiredFull) {
				_stateFiredFull = true;
				root.batteryFull();
			} else if (_battery.state !== UPowerDeviceState.FullyCharged && percentage < (chargeLimit > 0 ? chargeLimit : 100)) {
				_stateFiredFull = false;
			}
		}
	}

	// === Read current charge limit ===
	function _pollChargeLimit() {
		let proc = Qt.createQmlObject(`
			import Quickshell.Io
			Process {
				command: ["cat", "/sys/class/power_supply/BAT0/charge_control_end_threshold"]
				stdout: StdioCollector {
					onStreamFinished: {
						const val = parseInt(text.trim());
						if (!isNaN(val)) root.chargeLimit = val;
					}
				}
			}
		`, root);
		proc.running = true;
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: root._pollChargeLimit()
	}
	Component.onCompleted: _pollChargeLimit()

	// === Set charge limit (privileged) ===
	// Persistent process for setting charge limit
	Process {
		id: chargeLimitProc
		onExited: root._pollChargeLimit()
	}

	function setChargeLimit(value) {
		const clampedVal = Math.max(20, Math.min(100, Math.round(value)));
		chargeLimitProc.running = false; // stop any previous
		chargeLimitProc.command = ["sh", "-c", "echo " + clampedVal + " | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold"];
		chargeLimitProc.running = true;
	}
}
