import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 1180; height: 740
    minimumWidth: 1020; minimumHeight: 700
    visible: true; color: "#080b10"
    title: "Yeah, Science | Project Altair Ground Control"
    palette.button: "#16202c"
    palette.buttonText: "#dce5ef"
    palette.highlight: "#f3c623"
    palette.text: "#dce5ef"
    palette.base: "#0f151d"
    font.family: "Segoe UI"
    onActiveChanged: if (!active) station.stop()

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 18; spacing: 12
                focus: true
        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: function(event) {
            if (settings.opened || !station.armed)
                return

            if ([Qt.Key_W, Qt.Key_Up, Qt.Key_S, Qt.Key_Down,
                 Qt.Key_A, Qt.Key_Left, Qt.Key_D, Qt.Key_Right].includes(event.key)) {
                if (!event.isAutoRepeat)
                    station.setKeyboardKey(event.key, true)

                event.accepted = true
            }
        }

        Keys.onReleased: function(event) {
            if ([Qt.Key_W, Qt.Key_Up, Qt.Key_S, Qt.Key_Down,
                 Qt.Key_A, Qt.Key_Left, Qt.Key_D, Qt.Key_Right].includes(event.key)) {
                if (!event.isAutoRepeat)
                    station.setKeyboardKey(event.key, false)

                event.accepted = true
            }
        }
        RowLayout {
            spacing: 12
            RowLayout {
                spacing: 6
                // Periodic Table Element Badge: Y (Yttrium 39)
                Rectangle {
                    width: 38; height: 38; radius: 4
                    color: "#121b26"
                    border.color: "#f3c623"; border.width: 1.5
                    Column {
                        anchors.centerIn: parent; spacing: -2
                        Label { text: "39"; color: "#f3c623"; font.pixelSize: 8; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; anchors.horizontalCenter: parent.horizontalCenter }
                        Label { text: "Y"; color: "#f3c623"; font.pixelSize: 18; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
                // Periodic Table Element Badge: Se (Selenium 34)
                Rectangle {
                    width: 38; height: 38; radius: 4
                    color: "#121b26"
                    border.color: "#00e676"; border.width: 1.5
                    Column {
                        anchors.centerIn: parent; spacing: -2
                        Label { text: "34"; color: "#00e676"; font.pixelSize: 8; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; anchors.horizontalCenter: parent.horizontalCenter }
                        Label { text: "Se"; color: "#00e676"; font.pixelSize: 18; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }

            ColumnLayout {
                spacing: 0
                Label { text: "// PROJECT ALTAIR // LAB GCS v2.4"; color: "#7a8b9e"; font.pixelSize: 10; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; font.letterSpacing: 1.5 }
                Label { text: "Yeah, Science."; color: "#f3c623"; font.pixelSize: 26; font.bold: true }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: station.connected ? "#00e676" : "#4a5568"
                    Layout.alignment: Qt.AlignVCenter
                }
                ColumnLayout {
                    spacing: 1
                    Label { text: station.connected ? "CONNECTED" : "DISCONNECTED"; color: station.connected ? "#00e676" : "#7a8b9e"; font.pixelSize: 11; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace" }
                    Label { text: station.endpoint; color: "#485b70"; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; font.pixelSize: 10 }
                }
            }

            Button {
                objectName: "connectButton"
                text: station.connected ? "Disconnect" : "Connect Link"
                onClicked: station.connected ? station.disconnectLink() : station.connectLink()
            }
            Button { text: "Session Notes"; onClicked: settings.open() }
        }

        RowLayout {
            spacing: 12
            Metric { Layout.fillWidth: true; metricIndex: 1; label: "BATTERY VOLTAGE"; value: station.telemetryData.battery.toFixed(2); unit: "V" }
            Metric { Layout.fillWidth: true; metricIndex: 2; label: "ROVER HEADING"; value: (station.telemetryData.heading * 180 / Math.PI).toFixed(0); unit: "deg" }
            Metric { Layout.fillWidth: true; metricIndex: 3; label: "LEFT WHEEL SPD"; value: station.telemetryData.left.toFixed(2); unit: "m/s" }
            Metric { Layout.fillWidth: true; metricIndex: 4; label: "RIGHT WHEEL SPD"; value: station.telemetryData.right.toFixed(2); unit: "m/s" }
        }

        RowLayout {
            Layout.fillHeight: true; spacing: 12
            RoverView { Layout.fillWidth: true; Layout.fillHeight: true }
            Panel {
                Layout.preferredWidth: 320; Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    RowLayout {
                        Label { text: "// DRIVE DECK"; color: "#00e676"; font.pixelSize: 10; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; font.letterSpacing: 1.2 }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 76; height: 18; radius: 2
                            color: station.armed ? "#0d2618" : "#241416"
                            border.color: station.armed ? "#00e676" : "#e63946"
                            Label {
                                anchors.centerIn: parent
                                text: station.armed ? "[ ARMED ]" : "[ DISARMED ]"
                                color: station.armed ? "#00e676" : "#e63946"
                                font.pixelSize: 9; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
                            }
                        }
                    }
                    Button {
                        objectName: "armButton"
                        Layout.fillWidth: true
                        text: station.armed ? "Disable Drive Link" : "Enable Drive Link"
                        enabled: station.connected
                        onClicked: station.toggleArm()
                    }
                    DrivePad { Layout.fillWidth: true }
                    Item { Layout.fillHeight: true }
                    Label {
                        text: "Watchdog: " + (station.telemetryData.failsafe ? "holding stop" : "receiving commands")
                        color: "#485b70"
                        font.pixelSize: 10
                        font.bold: true
                        font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
                    }
                }
            }
        }

        EventLog { Layout.fillWidth: true; Layout.preferredHeight: 120 }

        RowLayout {
            Label { text: "// LOCAL TEST BENCH :: UDP LOOPBACK ACTIVE"; color: "#485b70"; font.pixelSize: 9; font.bold: true; font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"; font.letterSpacing: 1.2 }
            Item { Layout.fillWidth: true }
            Label {
                text: "RX: " + station.rxBytes + " B  |  TX: " + station.txBytes + " B  |  REJECTED: " + station.invalidPackets
                color: "#7a8b9e"
                font.pixelSize: 10
                font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
            }
        }
    }

    SettingsPanel { id: settings }
}
