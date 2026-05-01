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
	property string activeView: "calendar"
	property bool mouseHovering: false

	anchors.top: true
	anchors.left: true
	anchors.right: true
	margins.top: 0
	exclusiveZone: 0
	color: "transparent"

	focusable: expanded
	WlrLayershell.layer: WlrLayer.Overlay
	mask: Region { item: maskRect }

	implicitHeight: 500 // Large enough to contain expansion/contraction without clipping

	// === Hover logic ===
	readonly property bool isMouseOver: contentHover.hovered || triggerMA.containsMouse
	readonly property bool isActuallyHovering: isMouseOver
	
	HoverHandler {
		id: contentHover
		target: content
	}
	
	onIsMouseOverChanged: {
		if (isMouseOver) {
			hoverGraceTimer.stop();
			root.mouseHovering = true;
			hideTimer.stop();
			hideDelayTimer.stop();
		} else {
			// Longer grace period when expanded to prevent click-induced flickering
			hoverGraceTimer.interval = root.expanded ? 1200 : 150;
			hoverGraceTimer.restart();
		}
	}

	onMouseHoveringChanged: {
		if (!mouseHovering && isVisible) {
			hideTimer.restart();
		}
	}

	Timer {
		id: hideTimer
		interval: 800
		onTriggered: {
			if (root.mouseHovering || root.isActuallyHovering) return;
			root.hideBar();
		}
	}

	Timer {
		id: hideDelayTimer
		interval: 550
		onTriggered: {
				if (root.mouseHovering || root.expanded || root.isActuallyHovering) return;
				root.isVisible = false;
		}
	}

	// Ensure we start hiding if we contract while not hovering
	onExpandedChanged: {
		if (!expanded && !isActuallyHovering && isVisible) {
			hideTimer.restart();
		}
	}

	function showBar() {
		root.isVisible = true;
		if (!root.isActuallyHovering) {
			hideTimer.restart();
		}
	}

	function hideBar() {
		if (root.mouseHovering || root.isActuallyHovering) return; // never hide while hovering
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
		// Round dimensions to prevent sub-pixel jitter in the window mask
		width: Math.round(root.isVisible ? (root.expanded ? 600 : animContainer.implicitWidth + 40) : 240)
		height: Math.round(root.isVisible ? (root.expanded ? 600 : animContainer.implicitHeight + 40) : 6)
		color: "transparent"
	}

	// === Dynamic Surface Tension Swoops ===
	Shape {
		id: dynamicSwoops
		// slideProgress tracks the vertical slide of the body (1.0 = fully visible, 0.0 = completely hidden)
		readonly property real slideProgress: Math.max(0, 1.0 + (animContainer.anchors.topMargin / Math.max(1, animContainer.implicitHeight)))
		
		readonly property real swoopW: Math.round(16 * slideProgress)
		readonly property real maxSwoopH: Math.round(14 * slideProgress)
		
		// visibleH is how much of the notch is currently visible below the top edge
		readonly property real visibleH: Math.round(animContainer.y + animContainer.height)
		// currentSwoopH is bounded between 0 and maxSwoopH
		readonly property real currentSwoopH: Math.round(Math.max(0, Math.min(maxSwoopH, visibleH)))

		x: Math.round(animContainer.x - swoopW)
		y: 0
		width: Math.round(animContainer.width + 2 * swoopW)
		height: currentSwoopH

		visible: currentSwoopH > 0
		layer.enabled: true
		layer.samples: 2

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
		
		// Explicitly round dimensions to prevent centering jitter
		width: Math.round(implicitWidth)
		height: Math.round(implicitHeight)

		transformOrigin: Item.Top

		// Rest completely flush with top. No gap. 
		anchors.topMargin: root.isVisible ? 0 : -(implicitHeight + 10)

		Behavior on anchors.topMargin {
			NumberAnimation {
				duration: 250
				easing.type: Easing.OutCubic
			}
		}

		layer.enabled: root.isVisible || root.expanded
		layer.samples: 2

		Item {
			id: content
			anchors.fill: parent

			// Dimensions are now driven by States
			implicitWidth: collapsedBar.implicitWidth + 20
			implicitHeight: collapsedBar.implicitHeight + 6
			
			// Rounding here ensures all children have integer coordinates
			width: Math.round(parent.width)
			height: Math.round(parent.height)

			states: [
				State {
					name: "expanded"
					when: root.expanded
					PropertyChanges { target: content; implicitWidth: Math.max(collapsedBar.implicitWidth + 20, expandedBody.implicitWidth + 24); implicitHeight: expandedBody.implicitHeight + collapsedBar.implicitHeight + 24 }
					PropertyChanges { target: expandedBody; opacity: 1.0 }
				},
				State {
					name: "collapsed"
					when: !root.expanded
					PropertyChanges { target: content; implicitWidth: collapsedBar.implicitWidth + 20; implicitHeight: collapsedBar.implicitHeight + 6 }
					PropertyChanges { target: expandedBody; opacity: 0.0 }
				}
			]

			transitions: [
				Transition {
					from: "collapsed"; to: "expanded"
					ParallelAnimation {
						NumberAnimation { target: expandedBody; property: "opacity"; duration: 450; easing.type: Easing.OutExpo }
						NumberAnimation { target: content; property: "implicitWidth"; duration: 450; easing.type: Easing.OutExpo }
						NumberAnimation { target: content; property: "implicitHeight"; duration: 450; easing.type: Easing.OutExpo }
					}
				},
				Transition {
					from: "expanded"; to: "collapsed"
					ParallelAnimation {
						NumberAnimation { target: expandedBody; property: "opacity"; duration: 450; easing.type: Easing.OutExpo }
						NumberAnimation { target: content; property: "implicitWidth"; duration: 450; easing.type: Easing.OutExpo }
						NumberAnimation { target: content; property: "implicitHeight"; duration: 450; easing.type: Easing.OutExpo }
					}
				}
			]

			layer.enabled: true
			layer.samples: 2

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
			Timer {
				id: hoverGraceTimer
				interval: 150 // Small window to move between icons
				onTriggered: {
					root.mouseHovering = false;
					root.focus = false;
				}
			}

			MouseArea {
				id: mainMA
				anchors.fill: parent
				hoverEnabled: true
				acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
				propagateComposedEvents: true
				onPressed: (mouse) => {
					mouse.accepted = false;
					hoverGraceTimer.stop();
					root.mouseHovering = true;
				}
			}

			// === The Collapsed Bar ===
			Row {
				id: collapsedBar
				anchors.top: parent.top
				anchors.topMargin: 4
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: 12

				DateTimeWidget {
					anchors.verticalCenter: parent.verticalCenter
					onClicked: {
						if (root.expanded && root.activeView === "calendar") {
							root.expanded = false;
						} else {
							root.activeView = "calendar";
							root.expanded = true;
							hideTimer.stop();
							hideDelayTimer.stop();
						}
					}
				}

				// Divider 1: Clock | (EQ or Tray)
				Item {
					anchors.verticalCenter: parent.verticalCenter
					width: (eqEffect.active || (sysTray.visible && sysTray.opacity > 0)) ? 1 : 0
					height: 12
					clip: true
					opacity: width > 0 ? 1.0 : 0.0
					Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
					Behavior on opacity { NumberAnimation { duration: 300 } }

					Rectangle {
						anchors.fill: parent
						color: "#33ffffff"
					}
				}

				Item {
					id: eqContainer
					anchors.verticalCenter: parent.verticalCenter
					width: eqEffect.active ? eqEffect.width : 0
					height: eqEffect.height
					clip: true
					opacity: eqEffect.active ? 1.0 : 0.0
					visible: opacity > 0

					Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
					Behavior on opacity { NumberAnimation { duration: 300 } }

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						hoverEnabled: true
						onEntered: {
							hoverGraceTimer.stop();
							root.mouseHovering = true;
						}
						onClicked: {
							if (root.expanded && root.activeView === "mpris") {
								root.expanded = false;
							} else {
								root.activeView = "mpris";
								root.expanded = true;
								hideTimer.stop();
								hideDelayTimer.stop();
							}
						}
						EqualizerEffect {
							id: eqEffect
							anchors.centerIn: parent
						}
					}
				}

				// Divider 2: EQ | Tray
				Item {
					anchors.verticalCenter: parent.verticalCenter
					width: (eqEffect.active && (sysTray.visible && sysTray.opacity > 0)) ? 1 : 0
					height: 12
					clip: true
					opacity: width > 0 ? 1.0 : 0.0
					Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
					Behavior on opacity { NumberAnimation { duration: 300 } }

					Rectangle {
						anchors.fill: parent
						color: "#33ffffff"
					}
				}

				// System Tray
				SystemTrayWidget {
					id: sysTray
					anchors.verticalCenter: parent.verticalCenter
					parentWindow: root
				}
			}

			// Dedicated hover catch for the expanded area.
			// This appears IMMEDIATELY when expanded is true, ignoring animations/opacity.
			MouseArea {
				id: expandedHoverArea
				anchors.top: collapsedBar.bottom
				anchors.topMargin: 0
				anchors.horizontalCenter: parent.horizontalCenter
				width: expandedBody.width
				height: expandedBody.height + 20
				visible: root.expanded
				hoverEnabled: true
				acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
				propagateComposedEvents: true
				onPressed: (mouse) => {
					mouse.accepted = false;
					hoverGraceTimer.stop();
					root.mouseHovering = true;
				}
			}

			// Hover catch for collapsed bar icons
			MouseArea {
				id: collapsedCatch
				anchors.fill: collapsedBar
				hoverEnabled: true
				acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
				propagateComposedEvents: true
				onPressed: (mouse) => {
					mouse.accepted = false;
					hoverGraceTimer.stop();
					root.mouseHovering = true;
				}
			}

			// === Expanded content ===
			ExpandedContent {
				id: expandedBody
				anchors.top: collapsedBar.bottom
				anchors.topMargin: 8
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width - 24
				height: parent.height - collapsedBar.height - 16

				// Opacity is now driven by States
				opacity: 0.0
				visible: opacity > 0

				notifServer: root.notifServer
				dndEnabled: root.dndEnabled
				activeView: root.activeView
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
		id: triggerMA
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		width: 240; height: 10
		hoverEnabled: true
		onEntered: {
			forceTriggerTimer.start();
		}
		onExited: {
			forceTriggerTimer.stop();
		}
	}
}
