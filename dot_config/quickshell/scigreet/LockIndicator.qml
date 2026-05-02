import QtQuick

Item {
	id: root

	property color insideColor: "transparent"
	property color ringColor: "transparent"
	property color keyHlColor: "#c3c3c3"
	property color bsHlColor: "#3a3b3c"
	property color ringVerColor: "#c3c3c3"
	property color ringWrongColor: "#ff0000"
	property color ringClearColor: "#c3c3c3"

	property int radius: 100
	property int thickness: 5

	property bool verifying: false
	property bool wrong: false

	onVerifyingChanged: canvas.requestPaint();
	onWrongChanged: canvas.requestPaint();

	implicitWidth: (radius + thickness) * 2
	implicitHeight: (radius + thickness) * 2

	// We'll manage a few highlights to handle rapid typing.
	property var highlights: []
	property int nextSlot: 0
	readonly property int maxSlots: 10
	readonly property real slotArc: (Math.PI * 2) / maxSlots

	function flash(isBackspace) {
		const hl = {
			angle: nextSlot * slotArc,
			color: isBackspace ? bsHlColor : keyHlColor,
			opacity: 1.0
		};
		// Replace existing highlight in same slot or add new
		if (highlights.length < maxSlots) {
			highlights.push(hl);
		} else {
			highlights[nextSlot] = hl;
		}
		nextSlot = (nextSlot + 1) % maxSlots;
		canvas.requestPaint();
		hlTimer.start();
	}

	Timer {
		id: hlTimer
		interval: 16
		repeat: true
		running: highlights.length > 0
		onTriggered: {
			let active = false;
			for (let i = 0; i < highlights.length; i++) {
				highlights[i].opacity -= 0.02;
				if (highlights[i].opacity > 0) active = true;
			}
			if (!active) {
				highlights = [];
				stop();
			}
			canvas.requestPaint();
		}
	}

	Canvas {
		id: canvas
		anchors.fill: parent
		onPaint: {
			const ctx = getContext("2d");
			ctx.clearRect(0, 0, width, height);

			const centerX = width / 2;
			const centerY = height / 2;

			// Inside circle
			ctx.beginPath();
			ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
			ctx.fillStyle = root.insideColor;
			ctx.fill();

			// Main Ring
			ctx.lineWidth = root.thickness;
			ctx.beginPath();
			ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);

			if (root.verifying) {
				ctx.strokeStyle = root.ringVerColor;
			} else if (root.wrong) {
				ctx.strokeStyle = root.ringWrongColor;
			} else {
				ctx.strokeStyle = root.ringColor;
			}
			ctx.stroke();

			// Highlights
			for (let i = 0; i < root.highlights.length; i++) {
				const hl = root.highlights[i];
				if (hl.opacity <= 0) continue;

				ctx.beginPath();
				// Draw a 60 degree arc
				const arcLength = Math.PI / 3;
				ctx.arc(centerX, centerY, radius, hl.angle, hl.angle + arcLength);
				
				const c = hl.color;
				ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, hl.opacity);
				ctx.stroke();
			}
		}
	}
}
