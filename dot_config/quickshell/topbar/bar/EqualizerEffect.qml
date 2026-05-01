import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

Item {
	id: root
	implicitWidth: active ? maskContainer.width : 0
	implicitHeight: 16

	readonly property bool active: Mpris.players.values.length > 0 && Mpris.players.values.some(p => p && p.playbackState === MprisPlaybackState.Playing)
	readonly property var activePlayer: {
		if (Mpris.players.values.length === 0) return null;
		for (let i = 0; i < Mpris.players.values.length; i++) {
			let p = Mpris.players.values[i];
			if (p && p.playbackState === MprisPlaybackState.Playing) return p;
		}
		return Mpris.players.values[0] || null;
	}

	Image {
		id: eqImage
		anchors.fill: maskContainer
		source: root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
		sourceSize: Qt.size(4, 4)
		fillMode: Image.Stretch
		smooth: true
		visible: false
	}

	Item {
		id: maskContainer
		anchors.verticalCenter: parent.verticalCenter
		width: row.width
		height: 16
		visible: false
		layer.enabled: true

		Row {
			id: row
			anchors.centerIn: parent
			spacing: 2

			Repeater {
				model: 12
				Rectangle {
					anchors.verticalCenter: parent.verticalCenter
					width: 2
					height: root.active ? 8 + Math.random() * 8 : 4
					radius: 1
					color: "white"

					Behavior on height {
						NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
					}

					Timer {
						running: root.active
						repeat: true
						interval: 100 + index * 30
						onTriggered: {
							if (root.active) {
								parent.height = 4 + Math.random() * 12;
							} else {
								parent.height = 4;
							}
						}
					}
				}
			}
		}
	}

	MultiEffect {
		anchors.fill: maskContainer
		source: eqImage
		maskEnabled: true
		maskSource: maskContainer
	}
}
