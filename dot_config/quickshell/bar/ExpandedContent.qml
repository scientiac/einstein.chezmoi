import QtQuick
import QtQuick.Layouts

Item {
	id: root

	required property var notifServer
	property bool dndEnabled: false
	signal toggleDnd()

	implicitWidth: calendar.implicitWidth
	implicitHeight: calendar.implicitHeight

	CalendarPopup {
		id: calendar
		anchors.fill: parent
		dndEnabled: root.dndEnabled
		onToggleDnd: root.toggleDnd()
	}
}
