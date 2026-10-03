import QtQuick

Item {
    id: root
    PageHeader { width: parent.width; title: "Capture"; sub: "Screen capture"; onBack: Sys.panel = "home" }
    Row {
        anchors { right: parent.right; rightMargin: Theme.s(16); top: parent.top; topMargin: Theme.s(10) }
        spacing: Theme.s(8)
        Btn { width: Theme.s(70); height: Theme.s(28); radius: height / 2; active: true; Lbl { anchors.centerIn: parent; text: "Still"; font.bold: true; color: Theme.accent } }
        Btn { width: Theme.s(78); height: Theme.s(28); radius: height / 2; onClicked: Sys.panel = "record"; Lbl { anchors.centerIn: parent; text: "Record"; font.bold: true; color: Theme.sub } }
    }
    Row {
        x: Theme.s(14); y: Theme.s(60); spacing: Theme.s(10)
        Column {
            spacing: Theme.s(8)
            Repeater {
                model: [["display", "Display", "monitor"], ["window", "Window", "window"], ["area", "Area", "area"]]
                Tile { width: Theme.s(110); icon: modelData[2]; label: modelData[1]; active: Sys.shotMode === modelData[0]; onClicked: Sys.shotMode = modelData[0] }
            }
        }
        Rectangle {
            width: root.width - Theme.s(28) - Theme.s(120); height: Theme.s(158); radius: Theme.s(14); color: Theme.surface
            Column {
                anchors.centerIn: parent; spacing: Theme.s(10)
                Ico { n: Sys.shotMode === "display" ? "monitor" : Sys.shotMode === "window" ? "window" : "area"; color: Theme.accent; font.pixelSize: Theme.s(34); anchors.horizontalCenter: parent.horizontalCenter }
                Lbl { text: Sys.shotMode === "display" ? "Whole focused display" : Sys.shotMode === "window" ? "Pick an open window" : "Select a region"; color: Theme.sub; font.pixelSize: Theme.fs(11) }
                Btn { width: Theme.s(120); height: Theme.s(32); radius: height / 2; base: Theme.accent; onClicked: Sys.takeShot()
                      Lbl { anchors.centerIn: parent; text: "Capture"; color: Theme.onAccent; font.bold: true } }
            }
        }
    }
    Row {
        x: Theme.s(16); y: Theme.s(240); spacing: Theme.s(8)
        Ico { n: "cam"; color: Theme.sub; font.pixelSize: Theme.s(14) }
        Lbl { text: "~/Pictures/Screenshots · copied to clipboard"; color: Theme.sub; font.pixelSize: Theme.fs(11) }
    }
}
