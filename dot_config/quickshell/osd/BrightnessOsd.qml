import QtQuick
import Quickshell
import Quickshell.Io

Item {
	id: root

	// === Exposed live state ===
	property real level: -1

	// === Change signal (only fires on actual changes, not initial read) ===
	signal brightnessChanged()

	// === Internal ===
	property real _prevLevel: -1

	function _parse(text) {
		const lines = text.trim().split("\n");
		if (lines.length > 0) {
			const parts = lines[0].split(",");
			if (parts.length >= 4) {
				const pct = parseFloat(parts[3].replace("%", "")) / 100.0;
				root.level = pct;
				if (root._prevLevel >= 0 && pct !== root._prevLevel) {
					root.brightnessChanged();
				}
				root._prevLevel = pct;
			}
		}
	}

	function _poll() {
		let proc = Qt.createQmlObject(`
			import Quickshell.Io
			Process {
				command: ["brightnessctl", "-m", "-c", "backlight"]
				stdout: StdioCollector {
					onStreamFinished: root._parse(text)
				}
			}
		`, root);
		proc.running = true;
	}

	Timer {
		interval: 100
		running: true
		repeat: true
		onTriggered: root._poll()
	}

	// === Control function ===
	function setBrightness(pct) {
		const percent = Math.round(Math.max(0, Math.min(1, pct)) * 100);
		let proc = Qt.createQmlObject(`
			import Quickshell.Io
			Process {
				command: ["brightnessctl", "set", "${percent}%"]
			}
		`, root);
		proc.running = true;
	}
}
