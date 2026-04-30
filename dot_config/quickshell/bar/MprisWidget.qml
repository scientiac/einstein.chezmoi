import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

Item {
	id: root

	implicitWidth: 220
	implicitHeight: hasPlayer ? contentCol.implicitHeight : 0
	visible: hasPlayer

	readonly property bool hasPlayer: Mpris.players.count > 0
	readonly property var activePlayer: {
		if (Mpris.players.count === 0) return null;
		// Prefer the currently playing player
		for (let i = 0; i < Mpris.players.count; i++) {
			let p = Mpris.players.values[i];
			if (p && p.playbackState === MprisPlaybackState.Playing) return p;
		}
		return Mpris.players.values[0] || null;
	}

	// Position tracker for smooth progress bar
	FrameAnimation {
		running: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
		onTriggered: {
			if (root.activePlayer) root.activePlayer.positionChanged();
		}
	}

	ColumnLayout {
		id: contentCol
		anchors.fill: parent
		spacing: 8

		// Album art + track info
		RowLayout {
			Layout.fillWidth: true
			spacing: 10

			// Album art
			Rectangle {
				Layout.preferredWidth: 48
				Layout.preferredHeight: 48
				radius: 8
				color: "#252525"
				clip: true

				Image {
					anchors.fill: parent
					source: root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
					fillMode: Image.PreserveAspectCrop
					smooth: true
					visible: status === Image.Ready
				}

				// Fallback music icon
				Text {
					anchors.centerIn: parent
					text: "♫"
					color: "#555555"
					font { pixelSize: 20; family: "FantasqueSansM Nerd Font" }
					visible: !root.activePlayer || !root.activePlayer.trackArtUrl
				}
			}

			// Track info
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 1

				Text {
					Layout.fillWidth: true
					text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown Title") : ""
					color: "#ffffff"
					font { pixelSize: 12; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
					elide: Text.ElideRight
					maximumLineCount: 1
				}

				Text {
					Layout.fillWidth: true
					text: root.activePlayer ? (root.activePlayer.trackArtist || "Unknown Artist") : ""
					color: "#888888"
					font { pixelSize: 10; family: "FantasqueSansM Nerd Font" }
					elide: Text.ElideRight
					maximumLineCount: 1
				}

				Text {
					Layout.fillWidth: true
					text: root.activePlayer ? (root.activePlayer.identity || "") : ""
					color: "#555555"
					font { pixelSize: 9; family: "FantasqueSansM Nerd Font" }
					elide: Text.ElideRight
					visible: text !== ""
				}
			}
		}

		// Progress bar
		Item {
			Layout.fillWidth: true
			height: 14
			visible: root.activePlayer && root.activePlayer.lengthSupported && root.activePlayer.length > 0

			// Time labels
			Text {
				anchors.left: parent.left
				anchors.bottom: parent.bottom
				text: root.activePlayer ? _formatTime(root.activePlayer.position) : ""
				color: "#666666"
				font { pixelSize: 9; family: "FantasqueSansM Nerd Font" }
			}

			Text {
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				text: root.activePlayer ? _formatTime(root.activePlayer.length) : ""
				color: "#666666"
				font { pixelSize: 9; family: "FantasqueSansM Nerd Font" }
			}

			// Progress track
			Rectangle {
				id: progressTrack
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				height: 4
				radius: 2
				color: "#333333"

				Rectangle {
					anchors.left: parent.left
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					radius: parent.radius
					width: {
						if (!root.activePlayer || root.activePlayer.length <= 0) return 0;
						return parent.width * Math.min(1, root.activePlayer.position / root.activePlayer.length);
					}
					color: "#ffffff"
				}

				MouseArea {
					anchors.fill: parent
					anchors.margins: -4
					cursorShape: Qt.PointingHandCursor
					onClicked: (mouse) => {
						if (root.activePlayer && root.activePlayer.canSeek) {
							const ratio = mouse.x / progressTrack.width;
							root.activePlayer.position = ratio * root.activePlayer.length;
						}
					}
				}
			}
		}

		// Transport controls
		Row {
			Layout.alignment: Qt.AlignHCenter
			spacing: 12

			// Shuffle
			Rectangle {
				width: 26; height: 26; radius: 8
				color: shuffleMA.containsMouse ? "#2a2a2a" : "transparent"
				visible: root.activePlayer && root.activePlayer.shuffleSupported

				Text {
					anchors.centerIn: parent
					text: "🔀"
					font.pixelSize: 12
					opacity: root.activePlayer && root.activePlayer.shuffle ? 1.0 : 0.4
				}
				MouseArea {
					id: shuffleMA; anchors.fill: parent
					hoverEnabled: true; cursorShape: Qt.PointingHandCursor
					onClicked: { if (root.activePlayer) root.activePlayer.shuffle = !root.activePlayer.shuffle; }
				}
			}

			// Previous
			Rectangle {
				width: 30; height: 30; radius: 8
				color: prevMA.containsMouse ? "#2a2a2a" : "transparent"

				IconImage {
					id: prevIcon
					anchors.centerIn: parent
					implicitWidth: 14; implicitHeight: 14
					source: Quickshell.iconPath("media-skip-backward-symbolic")
					visible: false
				}
				MultiEffect {
					anchors.centerIn: parent
					width: 14; height: 14
					source: prevIcon
					colorization: 1.0; brightness: 1.0
					colorizationColor: root.activePlayer && root.activePlayer.canGoPrevious ? "#ffffff" : "#555555"
				}
				MouseArea {
					id: prevMA; anchors.fill: parent
					hoverEnabled: true; cursorShape: Qt.PointingHandCursor
					onClicked: { if (root.activePlayer) root.activePlayer.previous(); }
				}
			}

			// Play/Pause
			Rectangle {
				width: 36; height: 36; radius: 18
				color: playMA.containsMouse ? "#333333" : "#222222"
				Behavior on color { ColorAnimation { duration: 150 } }

				IconImage {
					id: playIcon
					anchors.centerIn: parent
					implicitWidth: 16; implicitHeight: 16
					source: Quickshell.iconPath(
						root.activePlayer && root.activePlayer.isPlaying
							? "media-playback-pause-symbolic"
							: "media-playback-start-symbolic"
					)
					visible: false
				}
				MultiEffect {
					anchors.centerIn: parent
					width: 16; height: 16
					source: playIcon
					colorization: 1.0; brightness: 1.0
					colorizationColor: "#ffffff"
				}
				MouseArea {
					id: playMA; anchors.fill: parent
					hoverEnabled: true; cursorShape: Qt.PointingHandCursor
					onClicked: { if (root.activePlayer) root.activePlayer.togglePlaying(); }
				}
			}

			// Next
			Rectangle {
				width: 30; height: 30; radius: 8
				color: nextMA.containsMouse ? "#2a2a2a" : "transparent"

				IconImage {
					id: nextIcon
					anchors.centerIn: parent
					implicitWidth: 14; implicitHeight: 14
					source: Quickshell.iconPath("media-skip-forward-symbolic")
					visible: false
				}
				MultiEffect {
					anchors.centerIn: parent
					width: 14; height: 14
					source: nextIcon
					colorization: 1.0; brightness: 1.0
					colorizationColor: root.activePlayer && root.activePlayer.canGoNext ? "#ffffff" : "#555555"
				}
				MouseArea {
					id: nextMA; anchors.fill: parent
					hoverEnabled: true; cursorShape: Qt.PointingHandCursor
					onClicked: { if (root.activePlayer) root.activePlayer.next(); }
				}
			}

			// Loop
			Rectangle {
				width: 26; height: 26; radius: 8
				color: loopMA.containsMouse ? "#2a2a2a" : "transparent"
				visible: root.activePlayer && root.activePlayer.loopSupported

				Text {
					anchors.centerIn: parent
					text: root.activePlayer && root.activePlayer.loopState === MprisLoopState.Track ? "🔂" : "🔁"
					font.pixelSize: 12
					opacity: root.activePlayer && root.activePlayer.loopState !== MprisLoopState.None ? 1.0 : 0.4
				}
				MouseArea {
					id: loopMA; anchors.fill: parent
					hoverEnabled: true; cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (!root.activePlayer) return;
						if (root.activePlayer.loopState === MprisLoopState.None)
							root.activePlayer.loopState = MprisLoopState.Playlist;
						else if (root.activePlayer.loopState === MprisLoopState.Playlist)
							root.activePlayer.loopState = MprisLoopState.Track;
						else
							root.activePlayer.loopState = MprisLoopState.None;
					}
				}
			}
		}
	}

	function _formatTime(seconds) {
		if (!seconds || seconds < 0) return "0:00";
		const m = Math.floor(seconds / 60);
		const s = Math.floor(seconds % 60);
		return m + ":" + (s < 10 ? "0" : "") + s;
	}
}
