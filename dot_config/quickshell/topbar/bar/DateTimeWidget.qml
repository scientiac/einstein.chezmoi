import QtQuick
import Quickshell

Item {
	id: root

	signal clicked()

	implicitWidth: timeCol.implicitWidth + 16
	implicitHeight: 36

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	Row {
		id: timeCol
		anchors.centerIn: parent
		spacing: 8

		Text {
			id: timeText
			anchors.verticalCenter: parent.verticalCenter
			text: {
				const h = clock.hours;
				const m = clock.minutes;
				return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
			}
			color: "#ffffff"
			font { pixelSize: 18; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
		}

		Text {
			anchors.baseline: timeText.baseline
			text: {
				const d = clock.date;
				const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
				const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
					"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
				return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
			}
			color: "#888888"
			font { pixelSize: 13; family: "FantasqueSansM Nerd Font" }
		}
	}

	MouseArea {
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
