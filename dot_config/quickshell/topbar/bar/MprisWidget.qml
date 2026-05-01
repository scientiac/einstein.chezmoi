import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

Item {
	id: root

	implicitWidth: 320
	implicitHeight: hasPlayer ? contentContainer.implicitHeight : 0
	visible: hasPlayer
	clip: true

	readonly property bool hasPlayer: Mpris.players.values.length > 0
	readonly property var activePlayer: {
		if (Mpris.players.values.length === 0) return null;
		// Prefer the currently playing player
		for (let i = 0; i < Mpris.players.values.length; i++) {
			let p = Mpris.players.values[i];
			if (p && p.playbackState === MprisPlaybackState.Playing) return p;
		}
		return Mpris.players.values[0] || null;
	}

	Timer {
		interval: 200
		running: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
		repeat: true
		onTriggered: {
			if (root.activePlayer) root.activePlayer.positionChanged();
		}
	}

	Item {
		id: contentContainer
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.top
		implicitHeight: mainCol.implicitHeight + 40

		// Blurred Background Layer
		Rectangle {
			anchors.fill: parent
			radius: 16
			color: "#1a1a1a"
			clip: true

			Image {
				id: bgImage
				anchors.fill: parent
				source: root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
				sourceSize: Qt.size(16, 16)
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				visible: false
			}

			MultiEffect {
				anchors.fill: parent
				source: bgImage
				blurEnabled: true
				blur: 1.0
				colorization: 1.0
				colorizationColor: "#bb000000" // Dark overlay
			}
		}

		// Main Centered Content
		ColumnLayout {
			id: mainCol
			anchors.centerIn: parent
			width: parent.width - 32
			spacing: 16

			// Track Info
			ColumnLayout {
				Layout.alignment: Qt.AlignHCenter
				Layout.fillWidth: true
				spacing: 4

				Item {
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignHCenter
					implicitHeight: titleText.implicitHeight
					clip: true

					Text {
						id: titleText
						text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown Title") : ""
						color: "#ffffff"
						font { pixelSize: 15; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
						
						property bool willScroll: implicitWidth > parent.width
						x: willScroll ? animX : (parent.width - implicitWidth) / 2
						property real animX: 0

						SequentialAnimation on animX {
							loops: Animation.Infinite
							running: titleText.willScroll && root.activePlayer.playbackState === MprisPlaybackState.Playing
							PauseAnimation { duration: 2000 }
							NumberAnimation {
								from: 0
								to: Math.min(0, titleText.parent.width - titleText.implicitWidth)
								duration: Math.max(1000, (titleText.implicitWidth - titleText.parent.width) * 20)
							}
							PauseAnimation { duration: 2000 }
							NumberAnimation {
								from: Math.min(0, titleText.parent.width - titleText.implicitWidth)
								to: 0
								duration: Math.max(1000, (titleText.implicitWidth - titleText.parent.width) * 20)
							}
						}
					}
				}

				Item {
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignHCenter
					implicitHeight: artistText.implicitHeight
					clip: true

					Text {
						id: artistText
						text: root.activePlayer ? (root.activePlayer.trackArtist || "Unknown Artist") : ""
						color: "#cccccc"
						font { pixelSize: 12; family: "FantasqueSansM Nerd Font" }
						
						property bool willScroll: implicitWidth > parent.width
						x: willScroll ? animX : (parent.width - implicitWidth) / 2
						property real animX: 0

						SequentialAnimation on animX {
							loops: Animation.Infinite
							running: artistText.willScroll && root.activePlayer.playbackState === MprisPlaybackState.Playing
							PauseAnimation { duration: 2000 }
							NumberAnimation {
								from: 0
								to: Math.min(0, artistText.parent.width - artistText.implicitWidth)
								duration: Math.max(1000, (artistText.implicitWidth - artistText.parent.width) * 20)
							}
							PauseAnimation { duration: 2000 }
							NumberAnimation {
								from: Math.min(0, artistText.parent.width - artistText.implicitWidth)
								to: 0
								duration: Math.max(1000, (artistText.implicitWidth - artistText.parent.width) * 20)
							}
						}
					}
				}
			}

			// Controls Row
			Row {
				Layout.alignment: Qt.AlignHCenter
				spacing: 24

				// Previous
				Rectangle {
					anchors.verticalCenter: parent.verticalCenter
					width: 36; height: 36; radius: 18
					color: prevMA.containsMouse ? "#33ffffff" : "transparent"

					IconImage {
						id: prevIcon
						anchors.centerIn: parent
						implicitWidth: 16; implicitHeight: 16
						source: Quickshell.iconPath("media-skip-backward-symbolic")
						visible: false
					}
					MultiEffect {
						anchors.centerIn: parent
						width: 16; height: 16
						source: prevIcon
						colorization: 1.0; brightness: 1.0
						colorizationColor: root.activePlayer && root.activePlayer.canGoPrevious ? "#ffffff" : "#66ffffff"
					}
					MouseArea {
						id: prevMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: { if (root.activePlayer) root.activePlayer.previous(); }
					}
				}

				// Play/Pause
				Rectangle {
					anchors.verticalCenter: parent.verticalCenter
					width: 48; height: 48; radius: 24
					color: playMA.containsMouse ? "#22000000" : "#44000000"
					Behavior on color { ColorAnimation { duration: 150 } }

					IconImage {
						id: playIcon
						anchors.centerIn: parent
						implicitWidth: 20; implicitHeight: 20
						source: Quickshell.iconPath(
							root.activePlayer && root.activePlayer.isPlaying
								? "media-playback-pause-symbolic"
								: "media-playback-start-symbolic"
						)
						visible: false
					}
					MultiEffect {
						anchors.centerIn: parent
						width: 20; height: 20
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
					anchors.verticalCenter: parent.verticalCenter
					width: 36; height: 36; radius: 18
					color: nextMA.containsMouse ? "#33ffffff" : "transparent"

					IconImage {
						id: nextIcon
						anchors.centerIn: parent
						implicitWidth: 16; implicitHeight: 16
						source: Quickshell.iconPath("media-skip-forward-symbolic")
						visible: false
					}
					MultiEffect {
						anchors.centerIn: parent
						width: 16; height: 16
						source: nextIcon
						colorization: 1.0; brightness: 1.0
						colorizationColor: root.activePlayer && root.activePlayer.canGoNext ? "#ffffff" : "#66ffffff"
					}
					MouseArea {
						id: nextMA; anchors.fill: parent
						hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: { if (root.activePlayer) root.activePlayer.next(); }
					}
				}
			}

			// Progress Time Text
			Text {
				Layout.alignment: Qt.AlignHCenter
				Layout.bottomMargin: 16
				text: root.activePlayer && root.activePlayer.length > 0
					? _formatTime(root.activePlayer.position) + " / " + _formatTime(root.activePlayer.length)
					: ""
				color: "#eeeeee"
				font { pixelSize: 14; family: "FantasqueSansM Nerd Font" }
				visible: text !== ""
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
