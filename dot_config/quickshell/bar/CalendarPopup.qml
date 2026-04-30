import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtQuick.Effects

Item {
	id: root

	implicitWidth: 240
	implicitHeight: calGrid.implicitHeight + headerRow.implicitHeight + dayLabels.implicitHeight + 18

	property int displayMonth: new Date().getMonth()
	property int displayYear: new Date().getFullYear()

	property bool dndEnabled: false
	signal toggleDnd()

	property bool isDarkTheme: true

	Process {
		id: themeReadProcess
		command: ["dconf", "read", "/org/gnome/desktop/interface/color-scheme"]
		running: true
		onExited: {
			if (stdout.trim() === "'default'") {
				root.isDarkTheme = false;
			} else {
				root.isDarkTheme = true;
			}
		}
	}

	Process {
		id: themeToggleProcess
		command: ["/home/scientiac/.local/bin/themetoggle"]
	}

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	function _daysInMonth(month, year) {
		return new Date(year, month + 1, 0).getDate();
	}

	function _firstDayOfWeek(month, year) {
		let d = new Date(year, month, 1).getDay();
		return (d + 6) % 7;
	}

	function _prevMonth() {
		if (displayMonth === 0) { displayMonth = 11; displayYear--; }
		else displayMonth--;
	}

	function _nextMonth() {
		if (displayMonth === 11) { displayMonth = 0; displayYear++; }
		else displayMonth++;
	}

	Column {
		anchors.fill: parent
		spacing: 6

		// Month/year header with navigation
		Item {
			width: parent.width
			height: headerRow.implicitHeight

			Row {
				id: headerRow
				anchors.centerIn: parent
				spacing: 8

				// Theme Toggle Button
				Rectangle {
					width: 22; height: 22; radius: 6
					color: themeMA.containsMouse ? "#2a2a2a" : "transparent"
					Behavior on color { ColorAnimation { duration: 150 } }

					IconImage {
						id: themeIcon
						anchors.centerIn: parent
						implicitWidth: 14; implicitHeight: 14
						source: Quickshell.iconPath(
							root.isDarkTheme ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
						)
						visible: false
					}
					MultiEffect {
						anchors.centerIn: parent
						width: 14; height: 14
						source: themeIcon
						colorization: 1.0; brightness: 1.0
						colorizationColor: "#888888"
						Behavior on colorizationColor { ColorAnimation { duration: 200 } }
					}

					MouseArea {
						id: themeMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: {
							root.isDarkTheme = !root.isDarkTheme;
							themeToggleProcess.running = true;
						}
					}
				}

				Rectangle {
					width: 22; height: 22; radius: 6
					color: prevMA.containsMouse ? "#2a2a2a" : "transparent"
					Behavior on color { ColorAnimation { duration: 150 } }
					Text {
						anchors.centerIn: parent
						text: "◀"
						color: "#888888"
						font { pixelSize: 10; family: "FantasqueSansM Nerd Font" }
					}
					MouseArea {
						id: prevMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: root._prevMonth()
					}
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: {
						const months = ["January", "February", "March", "April", "May", "June",
							"July", "August", "September", "October", "November", "December"];
						return months[root.displayMonth] + " " + root.displayYear;
					}
					color: "#ffffff"
					font { pixelSize: 14; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
					width: 110
					horizontalAlignment: Text.AlignHCenter
				}

				Rectangle {
					width: 22; height: 22; radius: 6
					color: nextMA.containsMouse ? "#2a2a2a" : "transparent"
					Behavior on color { ColorAnimation { duration: 150 } }
					Text {
						anchors.centerIn: parent
						text: "▶"
						color: "#888888"
						font { pixelSize: 10; family: "FantasqueSansM Nerd Font" }
					}
					MouseArea {
						id: nextMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: root._nextMonth()
					}
				}

				// DND Toggle Button
				Rectangle {
					width: 22; height: 22; radius: 6
					color: dndMA.containsMouse ? "#2a2a2a" : "transparent"
					Behavior on color { ColorAnimation { duration: 150 } }

					IconImage {
						id: dndIcon
						anchors.centerIn: parent
						implicitWidth: 14; implicitHeight: 14
						source: Quickshell.iconPath(
							root.dndEnabled
								? "notifications-disabled-symbolic"
								: "preferences-system-notifications-symbolic"
						)
						visible: false
					}
					MultiEffect {
						anchors.centerIn: parent
						width: 14; height: 14
						source: dndIcon
						colorization: 1.0; brightness: 1.0
						colorizationColor: root.dndEnabled ? "#ff6666" : "#888888"
						Behavior on colorizationColor { ColorAnimation { duration: 200 } }
					}

					MouseArea {
						id: dndMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: root.toggleDnd()
					}
				}
			}
		}

		// Day-of-week labels
		Row {
			id: dayLabels
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 0
			Repeater {
				model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
				Text {
					width: 34; height: 22
					text: modelData
					color: "#555555"
					font { pixelSize: 11; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
				}
			}
		}

		// Calendar grid
		Grid {
			id: calGrid
			anchors.horizontalCenter: parent.horizontalCenter
			columns: 7
			spacing: 0

			Repeater {
				model: {
					let cells = [];
					const firstDay = root._firstDayOfWeek(root.displayMonth, root.displayYear);
					const daysInMonth = root._daysInMonth(root.displayMonth, root.displayYear);
					const prevDays = root.displayMonth === 0
						? root._daysInMonth(11, root.displayYear - 1)
						: root._daysInMonth(root.displayMonth - 1, root.displayYear);
					for (let i = 0; i < firstDay; i++) {
						cells.push({ day: prevDays - firstDay + 1 + i, current: false });
					}
					for (let i = 1; i <= daysInMonth; i++) {
						cells.push({ day: i, current: true });
					}
					const remaining = 42 - cells.length;
					for (let i = 1; i <= remaining; i++) {
						cells.push({ day: i, current: false });
					}
					return cells;
				}

				Rectangle {
					width: 34; height: 30; radius: 8
					color: {
						const today = clock.date;
						if (modelData.current && modelData.day === today.getDate()
							&& root.displayMonth === today.getMonth()
							&& root.displayYear === today.getFullYear()) {
							return "#ffffff";
						}
						return "transparent";
					}

					Text {
						anchors.centerIn: parent
						text: modelData.day
						color: {
							const today = clock.date;
							if (modelData.current && modelData.day === today.getDate()
								&& root.displayMonth === today.getMonth()
								&& root.displayYear === today.getFullYear()) {
								return "#000000";
							}
							return modelData.current ? "#cccccc" : "#444444";
						}
						font {
							pixelSize: 13
							family: "FantasqueSansM Nerd Font"
							weight: modelData.current ? Font.Normal : Font.Light
						}
					}
				}
			}
		}
	}
}
