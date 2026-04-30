import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
	id: root

	required property var notifServer
	property bool dndEnabled: false
	signal toggleDnd()

	property bool isVisible: false
	property bool expanded: false
	property bool mouseHovering: false

	anchors.top: true
	anchors.left: true
	anchors.right: true
	margins.top: 0
	exclusiveZone: 0
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Overlay

	mask: Region { item: maskRect }

	implicitHeight: 500 // Large enough to contain expansion/contraction without clipping

	// === Hover logic ===
	Timer {
		id: hideTimer
		interval: expanded ? 2000 : 1000
		onTriggered: {
			if (!root.mouseHovering) {
				root.hideBar();
			} else {
				hideTimer.restart();
			}
		}
	}

	Timer {
		id: hideDelayTimer
		interval: 550 // Matches total contraction duration (100ms opacity + 450ms shrink)
		onTriggered: {
			if (!root.mouseHovering && !root.expanded) {
				root.isVisible = false;
			}
		}
	}

	function showBar() {
		root.isVisible = true;
		hideTimer.restart();
	}

	function hideBar() {
		if (root.expanded) {
			root.expanded = false;
			hideDelayTimer.restart();
		} else {
			root.isVisible = false;
		}
	}

	// === Mask (trigger strip when hidden, content+swoops when visible) ===
	Rectangle {
		id: maskRect
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		width: root.isVisible ? animContainer.width + 40 : 240
		height: root.isVisible ? (animContainer.y + animContainer.height + 4) : 6
		color: "transparent"
	}

	// === Dynamic Surface Tension Swoops ===
	Shape {
		id: dynamicSwoops
		// slideProgress tracks the vertical slide of the body (1.0 = fully visible, 0.0 = completely hidden)
		readonly property real slideProgress: Math.max(0, 1.0 + (animContainer.anchors.topMargin / animContainer.implicitHeight))
		
		readonly property real swoopW: 16 * slideProgress
		readonly property real maxSwoopH: 14 * slideProgress
		
		// visibleH is how much of the notch is currently visible below the top edge
		readonly property real visibleH: animContainer.y + animContainer.height
		// currentSwoopH is bounded between 0 and maxSwoopH
		readonly property real currentSwoopH: Math.max(0, Math.min(maxSwoopH, visibleH))

		x: animContainer.x - swoopW
		y: 0
		width: animContainer.width + 2 * swoopW
		height: currentSwoopH

		visible: currentSwoopH > 0
		layer.enabled: true
		layer.samples: 4

		ShapePath {
			fillColor: "#000000"
			strokeWidth: 0

			startX: 0
			startY: 0

			// Left swoop
			PathQuad {
				x: dynamicSwoops.swoopW
				y: dynamicSwoops.height
				controlX: dynamicSwoops.swoopW
				controlY: 0
			}

			// Across body bottom
			PathLine {
				x: dynamicSwoops.width - dynamicSwoops.swoopW
				y: dynamicSwoops.height
			}

			// Right swoop
			PathQuad {
				x: dynamicSwoops.width
				y: 0
				controlX: dynamicSwoops.width - dynamicSwoops.swoopW
				controlY: 0
			}

			PathLine { x: 0; y: 0 }
		}
	}

	// === Content body (slides up/down) ===
	Item {
		id: animContainer
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top

		implicitWidth: content.implicitWidth
		implicitHeight: content.implicitHeight

		transformOrigin: Item.Top

		// Rest completely flush with top. No gap. 
		anchors.topMargin: root.isVisible ? 0 : -(implicitHeight + 10)

		Behavior on anchors.topMargin {
			NumberAnimation {
				duration: 400
				easing.type: Easing.OutQuint
			}
		}

		Item {
			id: content
			anchors.fill: parent

			// Dimensions are now driven by States
			implicitWidth: collapsedBar.implicitWidth + 20
			implicitHeight: collapsedBar.implicitHeight + 12

			states: [
				State {
					name: "expanded"
					when: root.expanded
					PropertyChanges { target: content; implicitWidth: expandedBody.implicitWidth + 24; implicitHeight: expandedBody.implicitHeight + collapsedBar.implicitHeight + 20 }
					PropertyChanges { target: expandedBody; opacity: 1.0 }
				},
				State {
					name: "collapsed"
					when: !root.expanded
					PropertyChanges { target: content; implicitWidth: collapsedBar.implicitWidth + 20; implicitHeight: collapsedBar.implicitHeight + 12 }
					PropertyChanges { target: expandedBody; opacity: 0.0 }
				}
			]

			transitions: [
				Transition {
					from: "collapsed"; to: "expanded"
					ParallelAnimation {
						NumberAnimation { target: content; properties: "implicitWidth,implicitHeight"; duration: 550; easing.type: Easing.OutExpo }
						SequentialAnimation {
							PauseAnimation { duration: 100 }
							NumberAnimation { target: expandedBody; property: "opacity"; duration: 400; easing.type: Easing.OutCubic }
						}
					}
				},
				Transition {
					from: "expanded"; to: "collapsed"
					ParallelAnimation {
						NumberAnimation { target: content; properties: "implicitWidth,implicitHeight"; duration: 500; easing.type: Easing.OutExpo }
						NumberAnimation { target: expandedBody; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
					}
				}
			]

			// === Body background: rounded bottom, flat top ===
			Rectangle {
				anchors.fill: parent
				color: "#000000"
				radius: 12

				// Flat top edge
				Rectangle {
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.top: parent.top
					height: parent.radius
					color: parent.color
				}
			}

			// === Hover tracking ===
			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				acceptedButtons: Qt.NoButton
				onEntered: {
					root.mouseHovering = true;
					hideTimer.stop();
				}
				onExited: {
					root.mouseHovering = false;
					if (root.isVisible) hideTimer.restart();
				}
			}

			// === Collapsed bar (always visible when notch is down) ===
			Row {
				id: collapsedBar
				anchors.top: parent.top
				anchors.topMargin: 6
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: 12

				DateTimeWidget {
					anchors.verticalCenter: parent.verticalCenter
					onClicked: root.expanded = !root.expanded
				}



				SystemTrayWidget {
					id: sysTray
					anchors.verticalCenter: parent.verticalCenter
					parentWindow: root
				}




			}

			// === Expanded content ===
			ExpandedContent {
				id: expandedBody
				anchors.top: collapsedBar.bottom
				anchors.topMargin: 16
				anchors.left: parent.left
				anchors.leftMargin: 20
				anchors.right: parent.right
				anchors.rightMargin: 20
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 20

				// Opacity is now driven by States
				opacity: 0.0
				visible: opacity > 0

				notifServer: root.notifServer
				dndEnabled: root.dndEnabled
				onToggleDnd: root.toggleDnd()
			}
		}
	}

	// === Hover trigger zone ===
	Timer {
		id: forceTriggerTimer
		interval: 500
		onTriggered: {
			if (!root.isVisible) {
				root.showBar();
			}
		}
	}

	MouseArea {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		width: 240; height: 10
		hoverEnabled: true
		onEntered: {
			root.mouseHovering = true;
			forceTriggerTimer.start();
			if (root.isVisible) hideTimer.stop();
		}
		onExited: {
			forceTriggerTimer.stop();
			root.mouseHovering = false;
			if (root.isVisible) hideTimer.restart();
		}
	}
}
