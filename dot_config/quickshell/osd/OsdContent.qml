import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
	id: root

	property string view: "none"
	property bool isVisible: view !== "none"

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
	signal mouseEntered()
	signal mouseExited()
	signal dragStarted()
	signal dragEnded()
	signal setChargeLimit(int limit)

	property bool userDragging: false
	onUserDraggingChanged: {
		if (userDragging) root.dragStarted();
		else root.dragEnded();
	}

	property bool showChargeLimitToggles: false
	onViewChanged: {
		if (view !== "battery") showChargeLimitToggles = false;
	}

	// === Body sizing ===
	property real bodyW: {
		if (!isVisible) return 180; // Squeeze inward when disappearing
		if (view === "iconBar") return 230;
		return 260;
	}
	readonly property real bodyH: 50

	Behavior on bodyW { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }

	implicitWidth: bodyW
	implicitHeight: bodyH

	// === Body background: rounded top, flat bottom ===
	Rectangle {
		anchors.fill: parent
		color: "#000000"
		radius: 12
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: parent.radius
			color: parent.color
		}
	}

	// === Hover tracking ===
	MouseArea {
		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.NoButton
		onEntered: root.mouseEntered()
		onExited: root.mouseExited()
	}

	// === Content area ===
	Item {
		id: contentArea
		anchors.fill: parent
		anchors.leftMargin: 10
		anchors.rightMargin: 10
		anchors.topMargin: 5
		anchors.bottomMargin: 4

		// === ICON BAR ===
		Row {
			anchors.centerIn: parent
			spacing: 14
			opacity: root.view === "iconBar" ? 1.0 : 0.0
			visible: opacity > 0
			Behavior on opacity { NumberAnimation { duration: 100 } }

			Repeater {
				model: [
					{ name: "volume", icon: "audio-volume-high-symbolic" },
					{ name: "mic", icon: "audio-input-microphone-symbolic" },
					{ name: "battery", icon: "battery-level-100-symbolic" },
					{ name: "brightness", icon: "display-brightness-symbolic" },
					{ name: "keyboard", icon: "keyboard-brightness-symbolic" }
				]

				Rectangle {
					width: 30; height: 36; radius: 8
					color: iMA.containsMouse ? "#2a2a2a" : "transparent"
					Behavior on color { ColorAnimation { duration: 150 } }

					Column {
						anchors.centerIn: parent
						spacing: 2

						IconImage {
							id: barIcon
							anchors.horizontalCenter: parent.horizontalCenter
							implicitWidth: 16; implicitHeight: 16
							source: {
								if (modelData.name === "volume") return Quickshell.iconPath(root.volumeMuted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic");
								if (modelData.name === "mic") return Quickshell.iconPath(root.micMuted ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic");
								if (modelData.name === "battery") return Quickshell.iconPath(root.batteryIconName);
								return Quickshell.iconPath(modelData.icon);
							}
							visible: false
						}
						MultiEffect {
							anchors.horizontalCenter: parent.horizontalCenter
							width: barIcon.implicitWidth
							height: barIcon.implicitHeight
							source: barIcon
							colorization: 1.0
							brightness: 1.0
							colorizationColor: {
								if (modelData.name === "volume" && root.volumeMuted) return "#888888";
								if (modelData.name === "mic" && root.micMuted) return "#888888";
								if (modelData.name === "keyboard" && root.kbdLevel <= 0) return "#888888";
								if (modelData.name === "battery") {
									if (root.batteryLevel <= 10) return "#ff5555";
									if (root.batteryLevel <= 20) return "#ffaa55";
									if (root.batteryCharging) return "#55ff88";
									return "#ffffff";
								}
								return "#ffffff";
							}
							Behavior on colorizationColor { ColorAnimation { duration: 200 } }
						}

						// Battery percentage label under the icon
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							visible: modelData.name === "battery" && root.batteryLevel >= 0
							text: root.batteryLevel >= 0 ? Math.round(root.batteryLevel) + "%" : ""
							color: {
								if (root.batteryLevel <= 10) return "#ff5555";
								if (root.batteryLevel <= 20) return "#ffaa55";
								return "#aaaaaa";
							}
							font { pixelSize: 9; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
						}
					}

					MouseArea {
						id: iMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: root.iconClicked(modelData.name)
						onEntered: root.mouseEntered()
					}
				}
			}
		}

		// === SLIDER VIEW ===
		RowLayout {
			anchors.fill: parent
			spacing: 10
			opacity: (root.view !== "none" && root.view !== "iconBar") ? 1.0 : 0.0
			visible: opacity > 0
			Behavior on opacity { NumberAnimation { duration: 100 } }

			// Toggle icon
			Rectangle {
				Layout.alignment: Qt.AlignVCenter
				width: 30; height: 30; radius: 8
				color: tMA.containsMouse ? "#2a2a2a" : "transparent"
				Behavior on color { ColorAnimation { duration: 150 } }

				IconImage {
					id: toggleIcon
					anchors.centerIn: parent
					implicitWidth: 16; implicitHeight: 16
					source: {
						if (root.view === "volume") return Quickshell.iconPath(root.volumeMuted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic");
						if (root.view === "mic") return Quickshell.iconPath(root.micMuted ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic");
						if (root.view === "brightness") return Quickshell.iconPath("display-brightness-symbolic");
						if (root.view === "keyboard") return Quickshell.iconPath("keyboard-brightness-symbolic");
						if (root.view === "battery") return Quickshell.iconPath(root.batteryIconName);
						return "";
					}
					visible: false
				}
				MultiEffect {
					anchors.fill: toggleIcon
					source: toggleIcon
					colorization: 1.0
					brightness: 1.0
					colorizationColor: {
						if (root.view === "battery") {
							if (root.batteryLevel <= 10) return "#ff5555";
							if (root.batteryLevel <= 20) return "#ffaa55";
							if (root.batteryCharging) return "#55ff88";
							return "#ffffff";
						}
						return _isMuted ? "#888888" : "#ffffff";
					}
					Behavior on colorizationColor { ColorAnimation { duration: 200 } }
				}
				MouseArea {
					id: tMA; anchors.fill: parent
					hoverEnabled: true; cursorShape: Qt.PointingHandCursor
					onEntered: root.mouseEntered()
					onClicked: {
						if (root.view === "volume") root.toggleVolumeMute();
						else if (root.view === "mic") root.toggleMicMute();
						else if (root.view === "keyboard") root.toggleKbdOff();
						else if (root.view === "battery") root.showChargeLimitToggles = !root.showChargeLimitToggles;
					}
				}
			}

			// Continuous slider track
			Item {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
				height: 6
				visible: root.view !== "keyboard" && root.view !== "battery"

				Rectangle {
					id: sTrack; anchors.fill: parent; radius: 100; color: "#333333"

					Rectangle {
						anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
						radius: parent.radius
						width: parent.width * Math.max(0, Math.min(1, _sliderValue))
						color: _isMuted ? "#555555" : "#ffffff"
						Behavior on width { NumberAnimation { duration: root.userDragging ? 0 : 150; easing.type: Easing.OutQuad } }
						Behavior on color { ColorAnimation { duration: 200 } }
					}

					MouseArea {
						anchors.fill: parent; anchors.margins: -8
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onEntered: root.mouseEntered()
						onPressed: (mouse) => { root.userDragging = true; _applySlider(mouse.x / sTrack.width); }
						onPositionChanged: (mouse) => { if (pressed) _applySlider(mouse.x / sTrack.width); }
						onReleased: { root.userDragging = false; }
					}
				}
			}

			// Battery bar (non-interactive, shows battery level)
			Item {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
				height: 6
				visible: root.view === "battery"

				Rectangle {
					id: battTrack; anchors.fill: parent; radius: 100; color: "#333333"

					Rectangle {
						anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
						radius: parent.radius
						width: parent.width * Math.max(0, Math.min(1, root.batteryLevel / 100))
						color: {
							if (root.batteryLevel <= 10) return "#ff5555";
							if (root.batteryLevel <= 20) return "#ffaa55";
							if (root.batteryCharging) return "#55ff88";
							return "#ffffff";
						}
						Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
						Behavior on color { ColorAnimation { duration: 200 } }
					}

					// Charge limit marker
					Rectangle {
						visible: root.batteryChargeLimit > 0 && root.batteryChargeLimit < 100
						x: battTrack.width * (root.batteryChargeLimit / 100) - 1
						anchors.top: parent.top
						anchors.bottom: parent.bottom
						anchors.topMargin: -2
						anchors.bottomMargin: -2
						width: 2
						radius: 1
						color: "#888888"
						opacity: 0.8
					}
				}
			}

			// Segmented slider (keyboard)
			Row {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
				spacing: 4
				visible: root.view === "keyboard"

				Repeater {
					model: root.kbdMaxSteps > 0 ? root.kbdMaxSteps : 3
					Rectangle {
						width: (parent.width - (root.kbdMaxSteps - 1) * 4) / Math.max(1, root.kbdMaxSteps)
						height: 6; radius: 100
						color: index < Math.round(root.kbdLevel * root.kbdMaxSteps) ? "#ffffff" : "#333333"
						Behavior on color { ColorAnimation { duration: 150 } }
						MouseArea {
							anchors.fill: parent; anchors.margins: -4
							hoverEnabled: true; cursorShape: Qt.PointingHandCursor
							onEntered: root.mouseEntered()
							onClicked: root.setKbdBrightness((index + 1) / root.kbdMaxSteps)
						}
					}
				}
			}

			// Charge limit toggles (inline)
			Row {
				Layout.alignment: Qt.AlignVCenter
				Layout.rightMargin: 4
				spacing: 4
				visible: root.view === "battery" && root.showChargeLimitToggles

				Repeater {
					model: [80, 100]
					Rectangle {
						width: 28; height: 18; radius: 6
						color: root.batteryChargeLimit === modelData ? "#ffffff" : "#333333"
						Behavior on color { ColorAnimation { duration: 150 } }
						
						Text {
							anchors.centerIn: parent
							text: modelData
							color: root.batteryChargeLimit === modelData ? "#000000" : "#aaaaaa"
							font { pixelSize: 10; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
							Behavior on color { ColorAnimation { duration: 150 } }
						}
						
						MouseArea {
							anchors.fill: parent
							hoverEnabled: true; cursorShape: Qt.PointingHandCursor
							onEntered: root.mouseEntered()
							onClicked: root.setChargeLimit(modelData)
						}
					}
				}
			}

			// Percentage label
			Text {
				Layout.alignment: Qt.AlignVCenter
				Layout.rightMargin: 8
				text: {
					if (root.view === "keyboard") return "";
					if (root.view === "battery") return Math.round(root.batteryLevel) + "%";
					return Math.round(_sliderValue * 100) + "%";
				}
				color: {
					if (root.view === "battery") {
						if (root.batteryLevel <= 10) return "#ff5555";
						if (root.batteryLevel <= 20) return "#ffaa55";
						return "#ffffff";
					}
					return _isMuted ? "#666666" : "#ffffff";
				}
				font { pixelSize: 14; family: "FantasqueSansM Nerd Font"; weight: Font.Medium }
				visible: root.view !== "keyboard"
				Behavior on color { ColorAnimation { duration: 200 } }
			}
		}
	}

	readonly property real _sliderValue: {
		if (view === "volume") return volumeMuted ? 0 : volumeLevel;
		if (view === "mic") return micMuted ? 0 : micLevel;
		if (view === "brightness") return brightnessLevel;
		if (view === "keyboard") return kbdLevel;
		return 0;
	}
	readonly property bool _isMuted: {
		if (view === "volume") return volumeMuted;
		if (view === "mic") return micMuted;
		if (view === "keyboard") return kbdLevel <= 0;
		return false;
	}

	function _applySlider(ratio) {
		const val = Math.max(0, Math.min(1, ratio));
		if (view === "volume") setVolume(val);
		else if (view === "mic") setMicVolume(val);
		else if (view === "brightness") setBrightness(val);
	}
}
