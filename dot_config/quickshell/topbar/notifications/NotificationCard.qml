import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets

Item {
	id: root

	required property var notification
	property bool isPopup: false
	property real maxWidth: 380
	property bool expanded: false

	signal dismissed()
	signal actionInvoked(var action)

	implicitWidth: maxWidth
	implicitHeight: mainLayout.implicitHeight + 24

	readonly property bool hasContentImage: {
		if (!notification) return false;
		if ((notification.image || "") !== "") return true;
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
		if (icon.startsWith("file://") || icon.startsWith("/")) return false;
		return true;
	}

	readonly property int bodyTextFormat: /[<*_`#\[\]]/.test(notification.body || "") ? Text.MarkdownText : Text.PlainText

	Component.onCompleted: {
		if (notification && notification.lock) {
			notification.lock(root);
		}
	}

	Component.onDestruction: {
		if (notification && notification.unlock) {
			notification.unlock(root);
		}
	}

	// Swipe state
	property real lastX: 0
	property real lastTime: 0
	property real velocity: 0
	property bool isDragging: false
	property real pressX: 0

	// Card background
	Rectangle {
		anchors.fill: parent
		radius: 16
		color: (root.isPopup || !root.notification) ? "transparent" : "#000000"
		border.color: "#1a1a1a"
		border.width: root.isPopup ? 0 : 1
		opacity: (!!root.notification && root.opacity > 0) ? 1.0 : 0.0
		visible: opacity > 0
		Behavior on opacity { NumberAnimation { duration: 200 } }

		// Swipe MouseArea - behind content so it doesn't block buttons
		MouseArea {
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor

			onPressed: (mouse) => {
				if (!root.notification) return;
				root.pressX = mouse.x;
				root.isDragging = false;
				root.lastX = mouse.x;
				root.lastTime = Date.now();
				root.velocity = 0;
				springBack.stop();
			}

			onPositionChanged: (mouse) => {
				if (!pressed || !root.notification) return;
				const dx = mouse.x - root.pressX;
				if (!root.isDragging && Math.abs(dx) > 10) {
					root.isDragging = true;
				}
				if (root.isDragging) {
					root.x = Math.max(-20, dx);
					const progress = Math.abs(root.x) / root.width;
					root.opacity = Math.max(0.1, 1.0 - progress * 0.9);
					root.rotation = (root.x / root.width) * 5;
					
					const now = Date.now();
					const dt = now - root.lastTime;
					if (dt > 0) root.velocity = ((mouse.x - root.lastX) / dt) * 1000;
					root.lastX = mouse.x;
					root.lastTime = now;
				}
			}

			onReleased: {
				if (!root.isDragging || !root.notification) return;
				root.isDragging = false;
				
				if (root.x > root.width * 0.3 || root.velocity > 700) {
					const remaining = root.width + 60 - root.x;
					const dur = Math.max(100, Math.min(350, (remaining / Math.max(root.velocity, 1000)) * 1000));
					throwAnim.throwTarget = root.width + 60;
					throwAnim.throwDuration = dur;
					throwAnim.start();
				} else {
					springBack.start();
				}
			}

			onClicked: {
				if (root.isDragging || !root.notification) return;
				// Trigger default action (focus app)
				root.notification.invoke("default");
				root.actionInvoked(null); // Signal dismissal
			}
		}
	}

	ParallelAnimation {
		id: springBack
		NumberAnimation {
			target: root; property: "x"
			to: 0; duration: 400; easing.type: Easing.OutQuart
		}
		NumberAnimation {
			target: root; property: "opacity"
			to: 1.0; duration: 250
		}
		NumberAnimation {
			target: root; property: "rotation"
			to: 0; duration: 400; easing.type: Easing.OutQuart
		}
	}

	signal aboutToDismiss()

	SequentialAnimation {
		id: throwAnim
		property real throwTarget: root.width + 60
		property int throwDuration: 250
		
		ScriptAction { script: root.aboutToDismiss() }
		
		ParallelAnimation {
			NumberAnimation {
				target: root; property: "x"
				to: throwAnim.throwTarget
				duration: throwAnim.throwDuration; easing.type: Easing.OutQuad
			}
			NumberAnimation {
				target: root; property: "opacity"
				to: 0.0; duration: throwAnim.throwDuration
			}
		}
		ScriptAction {
			script: root.dismissed()
		}
	}

	ColumnLayout {
		id: mainLayout
		anchors.fill: parent
		anchors.margins: 12
		spacing: 10
		z: 1 // Ensure content is above swipe MouseArea
		visible: !!root.notification
		opacity: visible ? 1.0 : 0.0

		RowLayout {
			Layout.fillWidth: true
			spacing: 12
			Layout.alignment: Qt.AlignTop

			// Left side: Image/Icon
			Item {
				id: iconContainer
				Layout.preferredWidth: 32
				Layout.preferredHeight: 32
				Layout.alignment: Qt.AlignTop

				// Main Image (if available) or Large App Icon
				Item {
					id: mainVisual
					anchors.fill: parent

					// Rounded clipping for the image/icon
					Rectangle {
						id: visualMask
						anchors.fill: parent
						radius: 6 // Slightly smaller radius for 32px size
						color: "#111111"
						clip: true

						Image {
							id: contentImg
							anchors.fill: parent
							source: root.hasContentImage ? root.contentImageSource : ""
							fillMode: Image.PreserveAspectCrop
							visible: root.hasContentImage && status === Image.Ready
							asynchronous: true
						}

						// Fallback: Large app icon if no content image
						IconImage {
							id: largeAppIcon
							anchors.centerIn: parent
							width: 18; height: 18
							source: (!root.hasContentImage && root.hasAppIcon) ? Quickshell.iconPath(root.notification.appIcon) : ""
							visible: false
						}

						MultiEffect {
							anchors.fill: largeAppIcon
							source: largeAppIcon
							visible: !root.hasContentImage && root.hasAppIcon && largeAppIcon.status === Image.Ready
							colorization: 1.0; brightness: 1.0; colorizationColor: "#888888"
						}
					}
				}

				// Small Badge (App Icon)
				Rectangle {
					id: badge
					width: 14; height: 14; radius: 7
					color: "#000000"
					anchors.bottom: parent.bottom
					anchors.right: parent.right
					anchors.bottomMargin: -2
					anchors.rightMargin: -2
					visible: root.hasContentImage && root.hasAppIcon
					border.color: "#33ffffff"
					border.width: 1

					IconImage {
						id: badgeIcon
						anchors.centerIn: parent
						width: 8; height: 8
						source: root.hasAppIcon ? Quickshell.iconPath(root.notification.appIcon) : ""
						visible: false
					}

					MultiEffect {
						anchors.fill: badgeIcon
						source: badgeIcon
						visible: badgeIcon.status === Image.Ready
						colorization: 1.0; brightness: 1.0; colorizationColor: "#ffffff"
					}
				}
			}

			// Right side: Text details
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 2

				RowLayout {
					Layout.fillWidth: true
					spacing: 4

					Text {
						text: root.notification ? (root.notification.appName || "") : ""
						color: "#888888"
						font { pixelSize: 11; family: "FantasqueSansM Nerd Font"; weight: Font.Medium }
						Layout.fillWidth: true
						elide: Text.ElideRight
					}

					Text {
						text: {
							if (!root.notification || !root.notification.time) return "";
							const now = new Date();
							const diff = (now - root.notification.time) / 1000;
							if (diff < 60) return "now";
							if (diff < 3600) return Math.floor(diff / 60) + "m";
							return Math.floor(diff / 3600) + "h";
						}
						color: "#444444"
						font { pixelSize: 10; family: "FantasqueSansM Nerd Font" }
					}

					// Compact Expand toggle in header
					Rectangle {
						width: 20; height: 20; radius: 10
						color: expandMA.containsMouse ? "#333333" : "transparent"
						visible: bodyText.lineCount > 2 || root.hasContentImage
						scale: expandMA.pressed ? 0.9 : 1.0
						Behavior on scale { NumberAnimation { duration: 100 } }
						Behavior on color { ColorAnimation { duration: 150 } }
						
						Text {
							anchors.centerIn: parent
							text: root.expanded ? "󰅃" : "󰅀"
							color: "#888888"
							font { pixelSize: 12; family: "FantasqueSansM Nerd Font" }
						}

						MouseArea {
							id: expandMA
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: root.expanded = !root.expanded
						}
					}
				}

				Text {
					Layout.fillWidth: true
					text: root.notification ? (root.notification.summary || "") : ""
					color: "#ffffff"
					font { pixelSize: 14; family: "FantasqueSansM Nerd Font"; weight: Font.Bold }
					elide: Text.ElideRight
					maximumLineCount: 1
				}

				Text {
					id: bodyText
					Layout.fillWidth: true
					text: root.notification ? (root.notification.body || "") : ""
					color: "#aaaaaa"
					font { pixelSize: 13; family: "FantasqueSansM Nerd Font" }
					wrapMode: Text.WordWrap
					textFormat: root.bodyTextFormat
					maximumLineCount: root.expanded ? 10 : 2
					elide: Text.ElideRight
					visible: text !== ""

					Behavior on maximumLineCount {
						NumberAnimation { duration: 200 }
					}
				}
			}
		}


	}
}
