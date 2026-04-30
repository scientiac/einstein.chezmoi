import QtQuick
import Quickshell.Services.Pam

Item {
	id: root
	signal unlocked()
	signal failed()

	property string currentText: ""
	property bool unlockInProgress: false
	property bool showFailure: false

	signal keyPressed(bool isBackspace)

	onCurrentTextChanged: showFailure = false;

	function tryUnlock() {
		if (currentText === "") return;

		root.unlockInProgress = true;
		pam.start();
	}

	PamContext {
		id: pam
		configDirectory: "pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.currentText);
			}
		}

		onCompleted: result => {
			if (result == PamResult.Success) {
				root.unlocked();
			} else {
				root.currentText = "";
				root.showFailure = true;
			}

			root.unlockInProgress = false;
		}
	}
}
