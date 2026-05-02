import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            property var modelData

            screen: modelData
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            SciGreetContent {
                anchors.fill: parent
                screenName: root.screen?.name ?? ""
                testMode: true
            }

            // Top-right hidden exit button
            Item {
                anchors.top: parent.top
                anchors.right: parent.right
                width: 120
                height: 80

                HoverHandler { id: exitHover }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 16
                width: 40
                height: 40
                radius: 20
                color: exitArea.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.3) : Qt.rgba(0, 0, 0, 0.6)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                opacity: exitHover.hovered || exitBtnHover.hovered ? 1 : 0
                visible: opacity > 0
                z: 100

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                HoverHandler { id: exitBtnHover }

                Text {
                    anchors.fill: parent
                    text: "✕"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: exitArea.containsMouse ? "#ff6b6b" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: exitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.quit()
                }
            }
        }
    }
}
