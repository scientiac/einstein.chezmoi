//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "./bar" as Bar
import "./notifications" as Notifs

ShellRoot {
	id: root

	// === Shared notification server ===
	NotificationServer {
		id: notifServer
		keepOnReload: true
		actionsSupported: true
		imageSupported: true
		bodySupported: true
		bodyMarkupSupported: true
		persistenceSupported: true

		onNotification: (notification) => {
			notification.tracked = true;
			if (!root.dndEnabled || notification.urgency === NotificationUrgency.Critical) {
				popupManager.showPopup(notification);
			}
			console.log("Notification received, tracked = " + notification.tracked);
		}
	}

	// === Shared state ===
	property bool dndEnabled: false

	// === Popup queue manager ===
	ListModel {
		id: popupManager
		readonly property int maxPopups: 2

		function showPopup(notification) {
			insert(0, { "notifObj": notification });
			if (count > maxPopups) {
				remove(maxPopups, count - maxPopups);
			}
		}

		function removePopup(notification) {
			for (let i = 0; i < count; i++) {
				if (get(i).notifObj === notification) {
					remove(i, 1);
					return;
				}
			}
		}
	}

	// === Top bar (per screen) ===
	Variants {
		model: Quickshell.screens

		Bar.TopBar {
			required property var modelData
			screen: modelData
			notifServer: notifServer
			dndEnabled: root.dndEnabled
			onToggleDnd: root.dndEnabled = !root.dndEnabled
		}
	}

	// === Notification popups (per screen) ===
	Variants {
		model: Quickshell.screens

		Notifs.NotificationPopup {
			required property var modelData
			screen: modelData
			popupQueue: popupManager
			onDismissPopup: (notif) => popupManager.removePopup(notif)
		}
	}
}
