import QtQuick
import Quickshell

Item {
    id: root
    readonly property real cw: width - Theme.s(28)
    readonly property real t3: (cw - Theme.s(16)) / 3
    readonly property real t2: (cw - Theme.s(8)) / 2

    Binding { target: Sys; property: "homeH"; value: (col.height + Theme.s(28)) / Theme.uiScale }
    Column {
        id: col
        x: Theme.s(14); y: Theme.s(14); width: root.cw; spacing: Theme.s(8)

        Row {
            spacing: Theme.s(8)
            Tile { wide: true; width: root.t2; icon: "wifi"; label: "Wi-Fi"; sub: Sys.netName ? Sys.netName + " · " + Sys.netDev : "Disconnected"
                   active: Sys.netName !== ""; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
            Tile { wide: true; width: root.t2; icon: "bt"; label: "Bluetooth"; sub: "Unavailable"; active: false }
        }
        Row {
            spacing: Theme.s(8)
            Tile { width: root.t3; icon: "apps"; label: "Apps"; onClicked: Sys.setIsland("launcher") }
            Tile { width: root.t3; icon: "image"; label: "Wall"; onClicked: Sys.setIsland("wall") }
            Tile { width: root.t3; icon: "clip"; label: "Clip"; onClicked: Sys.setIsland("clip") }
        }
        Row {
            spacing: Theme.s(8)
            Tile { width: root.t3; icon: "moon"; label: "Night"; active: Sys.night; onClicked: Sys.toggleNight() }
            Tile { width: root.t3; icon: "dash"; label: "Mixer"; onClicked: Sys.setIsland("mixer") }
            Tile { width: root.t3; icon: "rec"; label: Sys.recording ? Sys.recTime : "Record"; active: Sys.recording
                   activeColor: "#33ff4d5a"; iconColor: Sys.recording ? "#ff4d5a" : Theme.sub
                   onClicked: Sys.panel = "record" }
        }
        Row {
            spacing: Theme.s(8)
            Tile { width: root.t3; icon: "cam"; label: "Shot"; onClicked: Sys.panel = "capture" }
            Tile { width: root.t3; icon: "cog"; label: "Config"; onClicked: Sys.panel = "appearance" }
            Tile { width: root.t3; icon: "dnd"; label: "DND"; active: Sys.dnd; onClicked: Sys.dnd = !Sys.dnd }
        }
        Row {
            spacing: Theme.s(8)
            Tile { width: root.t3; icon: "power"; label: "Power"; onClicked: Sys.panel = "power" }
            Tile { width: root.t3; icon: "discord"; label: "Discord"; active: Sys.inVoice; onClicked: Sys.panel = "discord" }
            Tile { width: root.t3; icon: "music"; label: "Music"; active: Sys.player && Sys.player.isPlaying; onClicked: { Sys.panel = ""; Sys.mediaOpen = true } }
        }

        Row {
            spacing: Theme.s(8)
            Tile { width: root.t2; icon: "chip"; label: "Performance"; sub: "CPU · RAM · GPU"; onClicked: Sys.panel = "perf" }
            Tile { width: root.t2; icon: "keyboard"; label: "Shortcuts"; sub: "view & edit"; onClicked: Sys.panel = "keys" }
        }

        // sound
        Item {
            width: parent.width; height: Theme.s(44)
            Row { spacing: Theme.s(8); Ico { n: Sys.volMuted ? "volmute" : "vol"; color: Theme.accent; font.pixelSize: Theme.s(15)
                    MouseArea { anchors.fill: parent; onClicked: Sys.toggleVolMute() } }
                  Lbl { text: "Sound"; font.bold: true } }
            Lbl { anchors.right: pct.left; anchors.rightMargin: Theme.s(10); width: Theme.s(150); horizontalAlignment: Text.AlignRight
                  text: Sys.sinkDesc; color: Theme.sub; font.pixelSize: Theme.fs(10) }
            Lbl { id: pct; anchors.right: parent.right; text: Sys.vol + "%"; font.bold: true; font.pixelSize: Theme.fs(12) }
            Slid { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } value: Sys.vol; onMoved: v => Sys.setVol(v) }
        }
        Item {
            width: parent.width; height: Theme.s(44)
            Row { spacing: Theme.s(8); Ico { n: Sys.micMuted ? "micoff" : "mic"; color: Theme.accent; font.pixelSize: Theme.s(15)
                    MouseArea { anchors.fill: parent; onClicked: Sys.toggleMicMute() } }
                  Lbl { text: "Microphone"; font.bold: true } }
            Lbl { anchors.right: pct2.left; anchors.rightMargin: Theme.s(10); width: Theme.s(150); horizontalAlignment: Text.AlignRight
                  text: Sys.sourceDesc; color: Theme.sub; font.pixelSize: Theme.fs(10) }
            Lbl { id: pct2; anchors.right: parent.right; text: Sys.micVol + "%"; font.bold: true; font.pixelSize: Theme.fs(12) }
            Slid { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } value: Sys.micVol; onMoved: v => Sys.setMic(v) }
        }

        // notifications
        Item {
            width: parent.width; height: Theme.s(22)
            Lbl { text: "Notifications"; font.bold: true }
            Lbl { anchors.right: parent.right; text: "Clear all"; color: Theme.accent; font.bold: true; font.pixelSize: Theme.fs(11)
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Sys.history.clear() } }
        }
        Lbl { visible: Sys.history.count === 0; text: "No notifications"; color: Theme.sub; font.pixelSize: Theme.fs(11) }
        ListView {
            width: parent.width; height: Math.min(contentHeight, Theme.s(150)); clip: true
            model: Sys.history; interactive: contentHeight > height
            delegate: Item {
                width: ListView.view.width; height: Theme.s(50)
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; width: parent.width - Theme.s(30)
                    Lbl { text: app; color: Theme.sub; font.pixelSize: Theme.fs(9); width: parent.width }
                    Lbl { text: summary; font.bold: true; font.pixelSize: Theme.fs(12); width: parent.width }
                    Lbl { text: body; color: Theme.sub; font.pixelSize: Theme.fs(10); width: parent.width }
                }
                Ico { anchors { right: parent.right; verticalCenter: parent.verticalCenter } n: "close"; color: Theme.sub; font.pixelSize: Theme.s(13)
                      MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: Sys.history.remove(index) } }
            }
        }
    }
}
