import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
	id: root

	required property var notification
	property bool isPopup: false
	property real maxWidth: 380

	signal dismissed()
	signal actionInvoked(var action)

	implicitWidth: maxWidth
	implicitHeight: contentCol.implicitHeight + 24

	readonly property bool hasContentImage: {
		if (!notification) return false;
		// Check notification.image first
		if ((notification.image || "") !== "") return true;
		// If appIcon is a file path (screenshot), treat it as content image
		const icon = notification.appIcon || "";
		if (icon.startsWith("file://") || icon.startsWith("/")) return true;
		return false;
	}

	readonly property string contentImageSource: {
		if (!notification) return "";
		if ((notification.image || "") !== "") return notification.image;
		const icon = notification.appIcon || "";
		if (icon.startsWith("file://") || icon.startsWith("/")) return icon;
		return "";
	}

	readonly property bool hasAppIcon: {
		if (!notification) return false;
		const icon = notification.appIcon || "";
		if (icon === "") return false;
		// File paths are content images, not app icons
		if (icon.startsWith("file://") || icon.startsWith("/")) return false;
		return true;
	}

	// Card background
	Rectangle {
		anchors.fill: parent
		radius: 16
		color: "#000000"
	}

	// Content
	ColumnLayout {
		id: contentCol
		anchors.fill: parent
		anchors.margins: 12
		spacing: 8

		// Header row: icon + app name
		RowLayout {
			Layout.fillWidth: true
			spacing: 8

			// App icon — only shown if the app actually has one
			Item {
				Layout.preferredWidth: 20
				Layout.preferredHeight: 20
				visible: appIconEffect.visible || appIconRaw.visible

				IconImage {
					id: appIconImg
					anchors.fill: parent
					source: root.hasAppIcon ? Quickshell.iconPath(root.notification.appIcon) : ""
					visible: false
				}

				MultiEffect {
					id: appIconEffect
					anchors.fill: parent
					source: appIconImg
					visible: appIconImg.status === Image.Ready
					colorization: 1.0
					brightness: 1.0
					colorizationColor: "#888888"
				}

				Image {
					id: appIconRaw
					anchors.fill: parent
					source: root.hasAppIcon ? (root.notification.appIcon || "") : ""
					visible: !appIconEffect.visible && status === Image.Ready
					fillMode: Image.PreserveAspectFit
					smooth: true
				}
			}

			// App name
			Text {
				text: root.notification ? (root.notification.appName || "") : ""
				color: "#555555"
				font { pixelSize: 12; family: "FantasqueSansM Nerd Font" }
				visible: text !== ""
				Layout.fillWidth: true
				elide: Text.ElideRight
			}
		}

		// Summary (title)
		Text {
			Layout.fillWidth: true
			text: root.notification ? (root.notification.summary || "") : ""
			color: "#ffffff"
			font { pixelSize: 15; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
			wrapMode: Text.WordWrap
			visible: text !== ""
		}

		// Body
		Text {
			Layout.fillWidth: true
			text: root.notification ? (root.notification.body || "") : ""
			color: "#999999"
			font { pixelSize: 13; family: "FantasqueSansM Nerd Font" }
			wrapMode: Text.WordWrap
			maximumLineCount: root.isPopup ? 3 : 8
			elide: Text.ElideRight
			textFormat: Text.PlainText
			visible: text !== ""
		}

		// Content image (screenshots, photos, etc.)
		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: contentImage.status === Image.Ready
				? Math.min(contentImage.sourceSize.height * (width / Math.max(1, contentImage.sourceSize.width)), 200)
				: 0
			visible: root.hasContentImage && contentImage.status === Image.Ready
			radius: 10
			color: "#111111"
			clip: true

			Image {
				id: contentImage
				anchors.fill: parent
				source: root.contentImageSource
				fillMode: Image.PreserveAspectCrop
				smooth: true
				asynchronous: true
			}
		}

		// Actions row
		Row {
			Layout.fillWidth: true
			spacing: 6
			visible: root.notification ? (root.notification.actions ? root.notification.actions.length > 0 : false) : false

			Repeater {
				model: root.notification ? root.notification.actions : []

				Rectangle {
					width: actionText.implicitWidth + 20
					height: 26
					radius: 8
					color: actionMA.containsMouse ? "#222222" : "#111111"
					Behavior on color { ColorAnimation { duration: 150 } }

					Text {
						id: actionText
						anchors.centerIn: parent
						text: modelData.text || ""
						color: "#cccccc"
						font { pixelSize: 11; family: "FantasqueSansM Nerd Font" }
					}

					MouseArea {
						id: actionMA
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							modelData.invoke();
							root.actionInvoked(modelData);
						}
					}
				}
			}
		}
	}
}
