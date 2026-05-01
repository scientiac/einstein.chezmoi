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
	exclusiveZone: -1
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Top
	mask: Region { item: maskRect }

	implicitWidth: 440
	implicitHeight: blobShape.height + 10
	
	readonly property real sw: 16 * Math.min(1.0, root.bodyH / 30)
	readonly property real cr: 16
	readonly property real bodyW: popupColumn.width + 24
	readonly property real bodyH: popupColumn.implicitHeight
	
	readonly property bool hasPopups: popupQueue && popupQueue.count > 0

	// Mask
	Rectangle {
		id: maskRect
		anchors.right: parent.right
		anchors.top: parent.top
		width: root.bodyW + root.sw + 10
		height: root.bodyH + root.sw + 10
		color: "transparent"
	}

	// Unified body + swoops as single Shape
	Shape {
		id: blobShape
		anchors.right: parent.right
		anchors.top: parent.top
		width: root.bodyW + root.sw
		height: root.bodyH + root.sw
		visible: root.hasPopups && root.bodyH > 1.0
		layer.enabled: true
		layer.samples: 4

		ShapePath {
			fillColor: "#000000"
			strokeWidth: 0

			startX: 0
			startY: 0

			// Top edge (flushed)
			PathLine {
				x: blobShape.width
				y: 0
			}

			// Down right edge to swoop
			PathLine {
				x: blobShape.width
				y: root.bodyH + root.sw
			}

			// Bottom-right swoop
			PathQuad {
				x: blobShape.width - root.sw
				y: root.bodyH
				controlX: blobShape.width
				controlY: root.bodyH
			}

			// Across bottom
			PathLine {
				x: root.sw + root.cr
				y: root.bodyH
			}

			// Bottom-left corner
			PathQuad {
				x: root.sw
				y: root.bodyH - root.cr
				controlX: root.sw
				controlY: root.bodyH
			}

			// Up left edge to swoop start
			PathLine {
				x: root.sw
				y: root.sw
			}

			// Left swoop up to top
			PathQuad {
				x: 0
				y: 0
				controlX: root.sw
				controlY: 0
			}

			// Close path
			PathLine { x: 0; y: 0 }
		}
	}

	Column {
		id: popupColumn
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.rightMargin: 12
		spacing: 0
		width: 380

		Repeater {
			model: root.popupQueue

			Item {
				id: popupWrapper
				width: parent.width
				height: wrapperHeight
				clip: true

				property bool isClosing: false
				property bool isFirst: index === 0
				property bool isLast: index === root.popupQueue.count - 1
				
				property real targetH: card.implicitHeight + (isLast ? 2 : 6)
				
				property real entryProgress: 0
				property real wrapperHeight: entryProgress * targetH
				
				property var notifObj: model.notifObj
				property real lastX: 0
				property real lastTime: 0
				property real velocity: 0
				property bool isDragging: false

				MouseArea {
					id: hoverMA
					anchors.fill: parent
					hoverEnabled: true
					propagateComposedEvents: true
					onPressed: (mouse) => mouse.accepted = false
				}

				Timer {
					id: expireTimer
					interval: {
						if (!popupWrapper.notifObj) return 5000;
						const t = popupWrapper.notifObj.expireTimeout;
						return (t && t > 0) ? t * 1000 : 5000;
					}
					running: entryAnim.running === false && !isClosing && !hoverMA.containsMouse
					onTriggered: {
						if (!popupWrapper.isDragging) {
							popupWrapper.isClosing = true;
							expireAnim.start();
						} else {
							expireTimer.restart();
						}
					}
				}

				Component.onCompleted: entryAnim.start()

				ParallelAnimation {
					id: entryAnim
					NumberAnimation {
						target: popupWrapper; property: "entryProgress"
						from: 0; to: 1.0
						duration: 300; easing.type: Easing.OutQuart
					}
					NumberAnimation {
						target: card; property: "x"
						from: popupWrapper.width + 50; to: 0
						duration: 350; easing.type: Easing.OutQuart
					}
					NumberAnimation {
						target: card; property: "opacity"
						from: 0.0; to: 1.0; duration: 400
					}
				}

				SequentialAnimation {
					id: expireAnim
					ParallelAnimation {
						NumberAnimation {
							target: card; property: "x"
							to: popupWrapper.width + 50
							duration: 450; easing.type: Easing.InQuart
						}
						NumberAnimation {
							target: card; property: "opacity"
							to: 0.0; duration: 400
						}
						NumberAnimation {
							target: popupWrapper; property: "entryProgress"
							to: 0; duration: 350; easing.type: Easing.OutQuart
						}
					}
					ScriptAction {
						script: { if (popupWrapper.notifObj) root.dismissPopup(popupWrapper.notifObj); }
					}
				}

				NumberAnimation {
					id: shrinkOnly
					target: popupWrapper; property: "entryProgress"
					to: 0; duration: 450; easing.type: Easing.OutQuart
					onFinished: { if (popupWrapper.notifObj) root.dismissPopup(popupWrapper.notifObj); }
				}

				NotificationCard {
					id: card
					y: 0
					
					notification: popupWrapper.notifObj
					isPopup: true
					maxWidth: popupWrapper.width
					width: parent.width
					x: popupWrapper.width + 50
					transformOrigin: Item.Right

					onAboutToDismiss: {
						// Start shrinking vertical space immediately as the throw starts
						shrinkOnly.start();
					}

					onDismissed: {
						// Ensure it's removed if it wasn't already by shrinkOnly
						if (popupWrapper.notifObj) root.dismissPopup(popupWrapper.notifObj);
					}

					onActionInvoked: (action) => {
						exitAnim.start();
					}

					Behavior on y {
						NumberAnimation { duration: 450; easing.type: Easing.OutQuart }
					}
				}
			}
		}
	}
}
