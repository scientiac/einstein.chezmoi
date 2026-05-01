import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray

Item {
	id: root

	property var parentWindow: null
	property bool expanded: false
	
	implicitWidth: mainLayout.implicitWidth
	implicitHeight: 32

	Behavior on implicitWidth {
		NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
	}

	RowLayout {
		id: mainLayout
		anchors.centerIn: parent
		spacing: 6

		// Icons list
		RowLayout {
			id: iconRow
			spacing: 4
			clip: true

			Repeater {
				model: SystemTray.items

				delegate: TrayItem {
					visible: true
					opacity: 1.0
				}
			}
		}
	}

	component TrayItem: Rectangle {
		id: item
		width: 28; height: 28; radius: 8
		color: "transparent"

		Image {
			id: iconImg
			anchors.centerIn: parent
			source: modelData.icon
			width: 20; height: 20
			fillMode: Image.PreserveAspectFit
			smooth: true
			asynchronous: true
		}

		onVisibleChanged: {
			trayMA.enabled = visible;
		}

		MouseArea {
			id: trayMA
			anchors.fill: parent
			hoverEnabled: true
			enabled: parent.visible
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

			onClicked: (mouse) => {
				if (mouse.button === Qt.LeftButton) {
					// Left click: Show menu (as is)
					if (modelData.hasMenu && root.parentWindow) {
						let mapped = trayMA.mapToItem(null, 0, 0);
						modelData.display(root.parentWindow, mapped.x, mapped.y + trayMA.height);
					} else {
						modelData.activate();
					}
				} else if (mouse.button === Qt.RightButton) {
					// Right click: Open/Toggle (Activate)
					modelData.activate();
				} else if (mouse.button === Qt.MiddleButton) {
					modelData.secondaryActivate();
				}
			}
		}
	}
}
