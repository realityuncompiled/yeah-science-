import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 8

    RowLayout {
        spacing: 6
        Rectangle {
            width: 3; height: 10; color: "#f3c623"; radius: 1
        }
        Label {
            text: "// TELEOPERATIONS COMMAND DECK"
            color: "#00e676"
            font.letterSpacing: 1.5
            font.pixelSize: 10
            font.bold: true
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
        }
    }

    Label {
        text: "Hold control pad button to command drive"
        color: "#dce5ef"
        font.pixelSize: 13
        font.bold: true
    }

    GridLayout {
        columns: 3
        rowSpacing: 6; columnSpacing: 6

        Item { Layout.preferredWidth: 72 }
        Button {
            objectName: "forwardButton"
            text: "▲ W  FWD"
            Layout.preferredWidth: 96
            enabled: station.armed
            onPressed: station.setDrive(1, 1)
            onReleased: station.releaseMouse()
            onCanceled: station.releaseMouse()
        }
        Item { Layout.preferredWidth: 72 }

        Button {
            text: "◀ A  LEFT"
            Layout.preferredWidth: 84
            enabled: station.armed
            onPressed: station.setDrive(-1, 1)
            onReleased: station.releaseMouse()
            onCanceled: station.releaseMouse()
        }
        Button {
            text: "✖ STOP"
            Layout.preferredWidth: 96
            palette.button: "#e63946"
            palette.buttonText: "#ffffff"
            onClicked: station.stop()
        }
        Button {
            text: "RIGHT  D ▶"
            Layout.preferredWidth: 84
            enabled: station.armed
            onPressed: station.setDrive(1, -1)
            onReleased: station.releaseMouse()
            onCanceled: station.releaseMouse()
        }

        Item { Layout.preferredWidth: 72 }
        Button {
            text: "▼ S  REV"
            Layout.preferredWidth: 96
            enabled: station.armed
            onPressed: station.setDrive(-1, -1)
            onReleased: station.releaseMouse()
            onCanceled: station.releaseMouse()
        }
        Item { Layout.preferredWidth: 72 }
    }

    RowLayout {
        spacing: 8
        Label {
            text: "THROTTLE:"
            color: "#7a8b9e"
            font.pixelSize: 10
            font.bold: true
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
        }
        Slider {
            Layout.fillWidth: true
            from: 0.1; to: 1.0; value: station.speed
            onMoved: station.setSpeed(value)
        }
        Label {
            text: Math.round(station.speed * 100) + "%"
            color: "#f3c623"
            font.bold: true
            font.pixelSize: 12
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 26
        color: "#0a0e13"
        radius: 3
        border.color: "#182330"
        Label {
            anchors.centerIn: parent
            text: "CMD_SPEED: L=" + station.leftCommand.toFixed(2) + " | R=" + station.rightCommand.toFixed(2)
            color: "#00e676"
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
            font.pixelSize: 11
            font.bold: true
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 22
        color: "#1d170b"
        radius: 2
        border.color: "#f3c623"
        border.width: 1
        Label {
            anchors.centerIn: parent
            text: "[ TASK ] KEYBOARD TELEOP: AWAITING IMPLEMENTATION"
            color: "#f3c623"
            font.pixelSize: 9
            font.bold: true
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
            font.letterSpacing: 0.5
        }
    }
}
