import QtQuick
import Quickshell

Item {
    id: root
    PageHeader { id: hd; width: parent.width; title: "RECORD"; jp: "録"; onBack: Sys.panel = "home" }
    Rectangle {
        anchors { right: parent.right; rightMargin: Theme.s(16); verticalCenter: hd.verticalCenter }
        height: Theme.s(26); width: rl.implicitWidth + Theme.s(26); radius: height / 2
        color: Sys.recording ? "#33ff4d5a" : Theme.surface; border.color: Sys.recording ? "#ff4d5a" : "transparent"
        Lbl { id: rl; anchors.centerIn: parent; text: "● " + (Sys.recording ? "REC " + Sys.recTime : "IDLE"); font.bold: true; font.pixelSize: Theme.fs(11); color: Sys.recording ? "#ff7782" : Theme.sub }
    }

    Column {
        x: Theme.s(14); y: Theme.s(54); width: parent.width - Theme.s(28); spacing: Theme.s(10)
        Rectangle {
            width: parent.width; height: Theme.s(58); radius: Theme.s(14); color: Theme.surface
            Column { x: Theme.s(14); anchors.verticalCenter: parent.verticalCenter
                Lbl { text: "Screen recorder"; font.bold: true }
                Lbl { text: "60 fps · wf-recorder · mp4"; color: Theme.sub; font.pixelSize: Theme.fs(10) } }
        }
        Row {
            spacing: Theme.s(8)
            Tile { width: (parent.parent.width - Theme.s(8)) / 2; icon: "monitor"; label: "Fullscreen"; active: Sys.recMode === "full"; onClicked: Sys.recMode = "full" }
            Tile { width: (parent.parent.width - Theme.s(8)) / 2; icon: "area"; label: "Record area"; active: Sys.recMode === "area"; onClicked: Sys.recMode = "area" }
        }
        Row {
            spacing: Theme.s(8)
            Repeater {
                model: [["desktop", "Desktop"], ["mic", "Mic"], ["none", "No audio"]]
                Tile { width: (root.width - Theme.s(44)) / 3; icon: modelData[0] === "mic" ? "mic" : modelData[0] === "none" ? "micoff" : "vol"
                       label: modelData[1]; active: Sys.recAudio === modelData[0]; onClicked: Sys.recAudio = modelData[0] }
            }
        }
        Btn {
            width: parent.width; height: Theme.s(52); radius: Theme.s(26)
            base: "#33ff4d5a"; activeColor: "#55ff4d5a"; active: Sys.recording
            border.color: "#ff4d5a"; border.width: 1
            onClicked: Sys.toggleRecording()
            Row { anchors.centerIn: parent; spacing: Theme.s(10)
                Rectangle { width: Theme.s(14); height: width; radius: Sys.recording ? 3 : width / 2; color: "#ff4d5a"; anchors.verticalCenter: parent.verticalCenter }
                Lbl { text: Sys.recording ? "Stop recording (" + Sys.recTime + ")" : "Start recording"; font.bold: true; color: "#ff8d96" } }
        }
        Item {
            width: parent.width; height: Theme.s(34)
            Row { spacing: Theme.s(8); anchors.verticalCenter: parent.verticalCenter
                Ico { n: "folder"; color: Theme.sub; font.pixelSize: Theme.s(15) }
                Lbl { text: "SAVE TO"; color: Theme.sub; font.pixelSize: Theme.fs(10); font.bold: true }
                Lbl { text: "~/Videos/Recordings"; font.pixelSize: Theme.fs(12) } }
            Lbl { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "OPEN"; color: Theme.accent; font.bold: true; font.pixelSize: Theme.fs(11)
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && exec nemo "$1"', "sh", Sys.recDir]) } }
        }
        Row {
            width: parent.width
            Lbl { text: "RECENT"; font.bold: true; color: Theme.sub; font.pixelSize: Theme.fs(10); width: parent.width - clr.width }
            Lbl { id: clr; text: "CLEAR"; color: Theme.danger; font.bold: true; font.pixelSize: Theme.fs(10)
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Sys.recCutoff = Date.now() } }
        }
        Repeater {
            model: Math.min(Sys.recents.count, 4)
            Rectangle {
                readonly property int idx: Sys.recents.count - 1 - index
                readonly property var mod: Sys.recents.get(idx, "fileModified")
                visible: mod && mod.getTime() > Sys.recCutoff
                width: parent.width; height: visible ? Theme.s(48) : 0; radius: Theme.s(12); color: Theme.surface
                Btn { x: Theme.s(8); anchors.verticalCenter: parent.verticalCenter; width: Theme.s(32); height: width; radius: Theme.s(10); base: Theme.bg
                      onClicked: Quickshell.execDetached(["xdg-open", Sys.recents.get(parent.idx, "filePath")])
                      Ico { anchors.centerIn: parent; n: "play"; color: Theme.accent; font.pixelSize: Theme.s(14) } }
                Column { x: Theme.s(50); anchors.verticalCenter: parent.verticalCenter; width: parent.width - Theme.s(60)
                    Lbl { width: parent.width; text: Sys.recents.get(parent.parent.idx, "fileName"); font.pixelSize: Theme.fs(11); font.bold: true }
                    Lbl { text: Qt.formatDateTime(parent.parent.mod, "MM-dd HH:mm") + " · " + (Sys.recents.get(parent.parent.idx, "fileSize") / 1048576).toFixed(1) + " MB"
                          color: Theme.sub; font.pixelSize: Theme.fs(10) } }
            }
        }
    }
}
