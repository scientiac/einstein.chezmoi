import QtQuick
import Quickshell
import Quickshell.Io

Item {
	id: root

	// === Exposed live state ===
	property real level: -1
	property int maxSteps: 3

	// === Change signal ===
	signal brightnessChanged()

	// === Internal ===
	property real _prevLevel: -1

	function _parse(text) {
		const lines = text.trim().split("\n");
		if (lines.length > 0) {
			const parts = lines[0].split(",");
			if (parts.length >= 5) {
				const pct = parseFloat(parts[3].replace("%", "")) / 100.0;
				const maxVal = parseInt(parts[4]);
				if (maxVal > 0) root.maxSteps = maxVal;
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
				command: ["brightnessctl", "-m", "-d", "*kbd*"]
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
	function setLevel(pct) {
		const percent = Math.round(Math.max(0, Math.min(1, pct)) * 100);
		let proc = Qt.createQmlObject(`
			import Quickshell.Io
			Process {
				command: ["brightnessctl", "-d", "*kbd*", "set", "${percent}%"]
			}
		`, root);
		proc.running = true;
	}

	function toggleOff() {
		if (root.level > 0) {
			root._savedLevel = root.level;
			setLevel(0);
		} else {
			setLevel(root._savedLevel > 0 ? root._savedLevel : 1.0);
		}
	}
	property real _savedLevel: 1.0
}
