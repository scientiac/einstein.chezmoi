import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

Item {
    id: root

    property string screenName: ""
    property bool testMode: false
    property bool isPrimaryScreen: !Quickshell.screens?.length || screenName === Quickshell.screens[0]?.name

    property string detectedUsername: ""
    property string passwordBuffer: ""
    property bool unlocking: false
    property string authState: ""
    property bool pendingSubmit: false
    property bool pendingResponse: false

    property var sessions: []
    property int currentSessionIndex: 0
    property string savedSessionExec: ""
    property string savedUsername: ""
    property bool sessionsReady: false
    property bool sessionMemoryLoaded: false
    property bool sessionDetectionDone: false

    readonly property string sessionMemoryPath: {
        if (root.testMode) return "/tmp/scigreet-memory.json";
        return "/var/lib/greeter/scigreet-memory.json";
    }

    Process {
        id: userDetect
        running: root.isPrimaryScreen && !root.testMode
        command: ["sh", "-c", "awk -F: '$3 >= 1000 && $3 < 65534 && $7 !~ /nologin|false/ {print $1; exit}' /etc/passwd"]
        stdout: SplitParser {
            onRead: data => {
                if (!root.savedUsername) {
                    root.detectedUsername = data.trim();
                }
            }
        }
    }

    Process {
        id: sessionDetect
        running: root.isPrimaryScreen
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop /usr/share/xsessions/*.desktop; do [ -f \"$f\" ] && awk -F= '/^Name=/ {if(!name) name=$2} /^Exec=/ {if(!exec) exec=$2} END{if(name && exec) print name \"|\" exec}' \"$f\"; done"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 2) {
                    let s = root.sessions.slice();
                    s.push({ name: parts[0], exec: parts[1] });
                    root.sessions = s;
                }
            }
        }
        onRunningChanged: {
            if (!running)
                sessionFinalizeDelay.restart();
        }
    }

    Timer {
        id: sessionFinalizeDelay
        interval: 200
        onTriggered: {
            root.sessionDetectionDone = true;
            root.tryFinalizeSession();
        }
    }

    function tryFinalizeSession() {
        if (sessionsReady || !sessionMemoryLoaded || !sessionDetectionDone) return;
        if (sessions.length === 0) return;
        finalizeSessionSelection();
    }

    function finalizeSessionSelection() {
        if (sessionsReady) return;
        sessionsReady = true;
        if (savedSessionExec) {
            for (let i = 0; i < sessions.length; i++) {
                if (sessions[i].exec === savedSessionExec) {
                    currentSessionIndex = i;
                    return;
                }
            }
        }
        currentSessionIndex = 0;
    }

    function saveMemory(saveUser = false) {
        let memory = {};
        const session = sessions[currentSessionIndex];
        if (session) memory.lastSessionExec = session.exec;
        
        if (saveUser && detectedUsername) {
            memory.lastSuccessfulUser = detectedUsername;
            root.savedUsername = detectedUsername;
        } else if (root.savedUsername) {
            memory.lastSuccessfulUser = root.savedUsername;
        }
        
        sessionMemoryFile.setText(JSON.stringify(memory, null, 2));
    }

    onCurrentSessionIndexChanged: {
        if (sessionsReady)
            saveMemory(false);
    }

    FileView {
        id: sessionMemoryFile
        path: root.sessionMemoryPath
        blockLoading: false
        blockWrites: false
        atomicWrites: false
        watchChanges: false
        printErrors: true
        onLoaded: {
            try {
                const content = sessionMemoryFile.text().trim();
                if (content) {
                    const memory = JSON.parse(content);
                    root.savedSessionExec = memory.lastSessionExec || "";
                    if (memory.lastSuccessfulUser) {
                        root.savedUsername = memory.lastSuccessfulUser;
                        root.detectedUsername = root.savedUsername;
                    }
                }
            } catch (e) {
                console.warn("SciGreet: Failed to parse memory.json", e);
            }
            root.sessionMemoryLoaded = true;
            root.tryFinalizeSession();
        }
        onLoadFailed: {
            root.sessionMemoryLoaded = true;
            root.tryFinalizeSession();
        }
    }

    function submitPassword() {
        if (!passwordBuffer || unlocking || testMode) return;
        if (!detectedUsername) return;
        pendingSubmit = true;
        authState = "";
        if (Greetd.state === GreetdState.Inactive) {
            Greetd.createSession(detectedUsername);
        } else if (pendingResponse) {
            doRespond();
        }
    }

    function doRespond() {
        pendingResponse = false;
        pendingSubmit = false;
        Greetd.respond(passwordBuffer);
        passwordBuffer = "";
        passwordInput.text = "";
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "earth.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: false
        cache: true
        layer.enabled: true

        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.8
            blurMax: 32
            blurMultiplier: 1
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4
    }

    Item {
        id: indicatorContainer
        anchors.centerIn: parent
        width: indicator.width + 40
        height: indicator.height + 40

        MultiEffect {
            id: bloomEffect
            anchors.centerIn: indicator
            width: indicator.width
            height: indicator.height
            source: indicator
            z: 0

            autoPaddingEnabled: true
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            brightness: 0.5
        }

        LockIndicator {
            id: indicator
            anchors.centerIn: parent
            radius: 100
            thickness: 5
            z: 1

            insideColor: "#00000000"
            ringColor: "#00000000"
            keyHlColor: "#c3c3c3"
            bsHlColor: "#e8875b"
            ringVerColor: "#c3c3c3"
            ringWrongColor: "#ff0000"
            ringClearColor: "#c3c3c3"

            verifying: root.unlocking
            wrong: root.authState === "fail" || root.authState === "error"
        }
    }

    TextInput {
        id: passwordInput
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        enabled: !root.unlocking

        onTextChanged: {
            if (!root.testMode)
                root.passwordBuffer = text;
        }

        onAccepted: {
            if (root.testMode) {
                indicator.verifying = true;
                testAuthTimer.restart();
                return;
            }
            root.submitPassword();
        }

        Keys.onPressed: event => {
            if (root.unlocking) {
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Backspace) {
                if (passwordInput.text.length > 0)
                    indicator.flash(true);
            } else if (event.text !== "" && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Tab) {
                indicator.flash(false);
            }
        }

        Component.onCompleted: forceActiveFocus()

        onActiveFocusChanged: {
            if (!activeFocus && !bottomLeftHover.hovered && !bottomRightHover.hovered) {
                Qt.callLater(() => {
                    if (passwordInput) passwordInput.forceActiveFocus();
                });
            }
        }
    }

    Timer {
        id: testAuthTimer
        interval: 1500
        onTriggered: {
            indicator.verifying = false;
            indicator.wrong = true;
            passwordInput.text = "";
            testFailResetTimer.restart();
        }
    }

    Timer {
        id: testFailResetTimer
        interval: 3000
        onTriggered: indicator.wrong = false
    }

    // Bottom-left corner hover zone - Power
    Item {
        id: bottomLeftZone
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 200
        height: 120

        HoverHandler {
            id: bottomLeftHover
        }
    }

    Row {
        id: powerRow
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12
        opacity: bottomLeftHover.hovered || rebootBtnHover.hovered || poweroffBtnHover.hovered ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            width: 48
            height: 48
            radius: 24
            color: rebootArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.6)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            HoverHandler { id: rebootBtnHover }

            Text {
                anchors.fill: parent
                text: "↻"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: rebootArea.containsMouse ? "#ffb74d" : "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                id: rebootArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.testMode)
                        rebootProcess.running = true;
                }
            }
        }

        Rectangle {
            width: 48
            height: 48
            radius: 24
            color: poweroffArea.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : Qt.rgba(0, 0, 0, 0.6)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            HoverHandler { id: poweroffBtnHover }

            Text {
                anchors.fill: parent
                text: "⏻"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: poweroffArea.containsMouse ? "#ff6b6b" : "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                id: poweroffArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.testMode)
                        poweroffProcess.running = true;
                }
            }
        }
    }

    Process {
        id: rebootProcess
        running: false
        command: ["systemctl", "reboot"]
    }

    Process {
        id: poweroffProcess
        running: false
        command: ["systemctl", "poweroff"]
    }

    // Bottom-right corner hover zone - Session switcher
    Item {
        id: bottomRightZone
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 200
        height: 120

        HoverHandler {
            id: bottomRightHover
        }
    }

    Row {
        id: sessionRow
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12
        opacity: (bottomRightHover.hovered || sessionRowHover.hovered) && root.sessions.length > 1 ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        HoverHandler { id: sessionRowHover }

        Repeater {
            model: root.sessions

            Rectangle {
                required property var modelData
                required property int index

                width: sessionMetrics.width + 32
                height: 48
                radius: 24
                color: {
                    if (index === root.currentSessionIndex)
                        return Qt.rgba(1, 1, 1, 0.2);
                    if (sessionBtnArea.containsMouse)
                        return Qt.rgba(1, 1, 1, 0.1);
                    return Qt.rgba(0, 0, 0, 0.6);
                }
                border.color: index === root.currentSessionIndex ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                TextMetrics {
                    id: sessionMetrics
                    text: modelData.name
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Text {
                    anchors.fill: parent
                    text: modelData.name
                    font.pixelSize: 14
                    font.weight: index === root.currentSessionIndex ? Font.Bold : Font.Normal
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: sessionBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentSessionIndex = index
                }
            }
        }
    }

    // Greetd connections
    Connections {
        target: Greetd
        enabled: root.isPrimaryScreen && !root.testMode

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                root.pendingResponse = true;
                if (root.pendingSubmit && root.passwordBuffer) {
                    root.doRespond();
                }
            } else {
                Greetd.respond("");
            }
        }

        function onReadyToLaunch() {
            root.unlocking = true;
            root.authState = "";
            root.pendingSubmit = false;
            root.pendingResponse = false;
            root.saveMemory();
            const session = root.sessions[root.currentSessionIndex];
            const cmd = session ? session.exec : "niri-session";
            Greetd.launch(cmd.split(" "), ["XDG_SESSION_TYPE=wayland"]);
        }

        function onAuthFailure(message) {
            root.unlocking = false;
            root.authState = "fail";
            root.passwordBuffer = "";
            root.pendingSubmit = false;
            root.pendingResponse = false;
            passwordInput.text = "";
            authResetTimer.restart();
            Greetd.cancelSession();
        }

        function onError(error) {
            root.unlocking = false;
            root.authState = "error";
            root.passwordBuffer = "";
            root.pendingSubmit = false;
            root.pendingResponse = false;
            passwordInput.text = "";
            authResetTimer.restart();
            Greetd.cancelSession();
        }
    }

    Timer {
        id: authResetTimer
        interval: 3000
        onTriggered: root.authState = ""
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: passwordInput.forceActiveFocus()
    }
}
