import QtQuick
import QtQuick.Layouts
import "../notifications"

Item {
	id: root

	required property var notifServer
	property bool dndEnabled: false
	property string activeView: "calendar"
	signal toggleDnd()

	implicitWidth: {
		if (root.activeView === "calendar") return calendar.implicitWidth;
		if (root.activeView === "mpris") return mpris.implicitWidth;
		return notifications.implicitWidth;
	}
	implicitHeight: {
		if (root.activeView === "calendar") return calendar.implicitHeight;
		if (root.activeView === "mpris") return mpris.implicitHeight;
		return notifications.implicitHeight;
	}
	clip: true

	CalendarPopup {
		id: calendar
		anchors.fill: parent
		opacity: root.activeView === "calendar" ? 1.0 : 0.0
		visible: opacity > 0
		dndEnabled: root.dndEnabled
		onToggleDnd: root.toggleDnd()
	}

	MprisWidget {
		id: mpris
		anchors.fill: parent
		opacity: root.activeView === "mpris" ? 1.0 : 0.0
		visible: opacity > 0
	}
}
