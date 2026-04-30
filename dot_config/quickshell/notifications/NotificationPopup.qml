import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

PanelWindow {
	id: root

	property var popupQueue: null
	signal dismissPopup(var notif)

	anchors.top: true
	anchors.right: true
	margins.top: 0
	margins.right: 0
	exclusiveZone: 0
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Top
	mask: Region { item: maskRect }

	implicitWidth: 440
	implicitHeight: blobShape.height + 10
	
	readonly property real sw: 14 * Math.min(1.0, root.bodyH / 30)
	readonly property real cr: 16
	readonly property real bodyW: popupColumn.width + 24
	readonly property real bodyH: popupColumn.implicitHeight
	
	readonly property bool hasPopups: popupQueue && popupQueue.count > 0

	// Mask
	Rectangle {
		id: maskRect
		anchors.right: parent.right
		anchors.top: parent.top
		width: root.bodyW + root.sw + 4
		height: root.bodyH + root.sw + 4
		color: "transparent"
	}

	// Unified body + swoops as single Shape
	Shape {
		id: blobShape
		anchors.right: parent.right
		anchors.top: parent.top
		width: root.bodyW + root.sw
		height: root.bodyH + root.sw
		visible: root.bodyH > 0.1
		layer.enabled: true
		layer.samples: 4

		ShapePath {
			fillColor: "#000000"
			strokeWidth: 0

			// sw = swoop size, bodyW/bodyH = body dimensions
			// Body occupies x: [sw .. sw+bodyW], y: [0 .. bodyH]
			// Left swoop occupies x: [0 .. sw], y: [0 .. sw]
			// Bottom swoop occupies x: [sw+bodyW-sw .. sw+bodyW], y: [bodyH .. bodyH+sw]

			// Start top-left (screen top edge, left of body)
			startX: 0
			startY: 0

			// Left swoop: curve from screen top edge into body left edge
			// Same pattern as TopBar left swoop
			PathQuad {
				x: root.sw
				y: root.sw
				controlX: root.sw
				controlY: 0
			}

			// Down body left edge to bottom-left rounded corner
			PathLine {
				x: root.sw
				y: root.bodyH - root.cr
			}

			// Bottom-left rounded corner
			PathQuad {
				x: root.sw + root.cr
				y: root.bodyH
				controlX: root.sw
				controlY: root.bodyH
			}

			// Across body bottom, stop before right edge for bottom swoop
			PathLine {
				x: blobShape.width - root.sw
				y: root.bodyH
			}

			// Bottom swoop: curve from body bottom into right screen edge
			// Same pattern as TopBar right swoop but rotated 90°
			PathQuad {
				x: blobShape.width
				y: root.bodyH + root.sw
				controlX: blobShape.width
				controlY: root.bodyH
			}

			// Up right screen edge to top
			PathLine {
				x: blobShape.width
				y: 0
			}

			// Across top back to start
			PathLine {
				x: 0
				y: 0
			}
		}
	}

	// Popup column
	Column {
		id: popupColumn
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.rightMargin: 12
		spacing: 0
		width: 370

		Repeater {
			model: root.popupQueue

			Item {
				id: popupWrapper
				width: parent.width
				height: wrapperHeight
				clip: true

				property bool isAppearing: true
				property bool isClosing: false
				
				property bool isFirst: index === 0
				property bool isLast: index === root.popupQueue.count - 1
				
				property real topPadding: isFirst ? 12 : 0
				property real bottomPadding: isLast ? 12 : 8
				
				property real wrapperHeight: {
					if (isAppearing || isClosing) return 0;
					return topPadding + card.implicitHeight + bottomPadding;
				}
				
				property var notifObj: model.notifObj
				property real lastX: 0
				property real lastTime: 0
				property real velocity: 0
				property bool isDragging: false

				Behavior on wrapperHeight {
					NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
				}

				Timer {
					id: expireTimer
					interval: {
						if (!popupWrapper.notifObj) return 5000;
						const t = popupWrapper.notifObj.expireTimeout;
						return (t && t > 0) ? t * 1000 : 5000;
					}
					running: true
					onTriggered: {
						if (!popupWrapper.isDragging) {
							popupWrapper.isClosing = true;
							expireAnim.start();
						} else {
							expireTimer.restart();
						}
					}
				}

				Component.onCompleted: {
					isAppearing = false;
					entryAnim.start();
				}

				ParallelAnimation {
					id: entryAnim
					NumberAnimation {
						target: card; property: "x"
						from: popupWrapper.width + 30; to: 0
						duration: 400; easing.type: Easing.OutQuint
					}
					NumberAnimation {
						target: card; property: "opacity"
						from: 0.0; to: 1.0; duration: 250
					}
					NumberAnimation {
						target: card; property: "scale"
						from: 0.92; to: 1.0
						duration: 400; easing.type: Easing.OutQuint
					}
				}

				SequentialAnimation {
					id: expireAnim
					ParallelAnimation {
						NumberAnimation {
							target: card; property: "x"
							to: popupWrapper.width + 30
							duration: 400; easing.type: Easing.OutQuint
						}
						NumberAnimation {
							target: card; property: "opacity"
							to: 0.0; duration: 400
						}
					}
					ScriptAction { script: { popupWrapper.isClosing = true; } }
					PauseAnimation { duration: 400 }
					ScriptAction {
						script: { if (popupWrapper.notifObj) root.dismissPopup(popupWrapper.notifObj); }
					}
				}

				SequentialAnimation {
					id: throwAnim
					property real throwTarget: popupWrapper.width + 50
					property int throwDuration: 250
					ParallelAnimation {
						NumberAnimation {
							target: card; property: "x"
							to: throwAnim.throwTarget
							duration: throwAnim.throwDuration; easing.type: Easing.OutQuad
						}
						NumberAnimation {
							target: card; property: "opacity"
							to: 0.0; duration: throwAnim.throwDuration
						}
					}
					ScriptAction { script: { popupWrapper.isClosing = true; } }
					PauseAnimation { duration: 400 }
					ScriptAction {
						script: { if (popupWrapper.notifObj) root.dismissPopup(popupWrapper.notifObj); }
					}
				}

				ParallelAnimation {
					id: springBack
					NumberAnimation {
						target: card; property: "x"
						to: 0; duration: 400
						easing.type: Easing.OutQuint
					}
					NumberAnimation {
						target: card; property: "opacity"
						to: 1.0; duration: 200
					}
					NumberAnimation {
						target: card; property: "rotation"
						to: 0; duration: 300; easing.type: Easing.OutQuint
					}
				}

				NotificationCard {
					id: card
					y: popupWrapper.topPadding
					Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
					
					notification: popupWrapper.notifObj
					isPopup: true
					maxWidth: popupWrapper.width
					width: parent.width
					x: popupWrapper.width + 30
					transformOrigin: Item.Right
				}

				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					property real pressX: 0
					property bool dragActive: false

					onEntered: expireTimer.stop()
					onExited: { if (!popupWrapper.isClosing && !dragActive) expireTimer.restart(); }

					onPressed: (mouse) => {
						pressX = mouse.x;
						dragActive = false;
						popupWrapper.lastX = mouse.x;
						popupWrapper.lastTime = Date.now();
						popupWrapper.velocity = 0;
						springBack.stop();
					}

					onPositionChanged: (mouse) => {
						if (!pressed) return;
						const dx = mouse.x - pressX;
						if (!dragActive && Math.abs(dx) > 8) {
							dragActive = true;
							popupWrapper.isDragging = true;
							expireTimer.stop();
						}
						if (dragActive) {
							card.x = Math.max(0, dx);
							const progress = card.x / popupWrapper.width;
							card.opacity = Math.max(0.2, 1.0 - progress * 0.8);
							card.rotation = Math.min(2, progress * 3);
							const now = Date.now();
							const dt = now - popupWrapper.lastTime;
							if (dt > 0) popupWrapper.velocity = ((mouse.x - popupWrapper.lastX) / dt) * 1000;
							popupWrapper.lastX = mouse.x;
							popupWrapper.lastTime = now;
						}
					}

					onReleased: {
						if (!dragActive) { if (!popupWrapper.isClosing) expireTimer.restart(); return; }
						dragActive = false;
						popupWrapper.isDragging = false;
						if (card.x > popupWrapper.width * 0.35 || popupWrapper.velocity > 600) {
							popupWrapper.isClosing = true;
							const remaining = popupWrapper.width + 50 - card.x;
							const dur = Math.max(120, Math.min(400, (remaining / Math.max(popupWrapper.velocity, 800)) * 1000));
							throwAnim.throwTarget = popupWrapper.width + 50;
							throwAnim.throwDuration = dur;
							throwAnim.start();
						} else {
							springBack.start();
							expireTimer.restart();
						}
					}
				}
			}
		}
	}
}
