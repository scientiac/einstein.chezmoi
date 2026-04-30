import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
	id: root

	property var parentWindow: null

	implicitWidth: trayRow.implicitWidth + 8
	implicitHeight: 36

	Row {
		id: trayRow
		anchors.centerIn: parent
		spacing: 4

		Repeater {
			model: SystemTray.items

			Rectangle {
				width: 28; height: 28; radius: 6
				color: trayMA.containsMouse ? "#2a2a2a" : "transparent"
				Behavior on color { ColorAnimation { duration: 150 } }

				Image {
					anchors.centerIn: parent
					source: modelData.icon
					width: 20; height: 20
					fillMode: Image.PreserveAspectFit
					smooth: true
				}

				MouseArea {
					id: trayMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
					onClicked: (mouse) => {
						if (mouse.button === Qt.LeftButton) {
							if (modelData.hasMenu) {
								let mapped = trayMA.mapToItem(null, mouse.x, mouse.y);
								if (root.parentWindow) {
									modelData.display(root.parentWindow, mapped.x, mapped.y);
								}
							} else {
								modelData.activate();
							}
						} else if (mouse.button === Qt.RightButton) {
							modelData.activate();
						} else if (mouse.button === Qt.MiddleButton) {
							modelData.secondaryActivate();
						}
					}
				}
			}
		}
	}
}
