import QtQuick
import Quickshell

Item {
    id: root
    readonly property var dc: Sys.dc
    readonly property var ch: Sys.inVoice ? dc.channel : null
    property int tick: 0
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.tick++ }
    function dur(s) { s = Math.max(0, Math.floor(s)); const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = s % 60; return (h ? h + ":" : "") + (m < 10 && h ? "0" : "") + m + ":" + (x < 10 ? "0" : "") + x }

    PageHeader { width: parent.width; title: root.ch ? root.ch.name : "Discord"; sub: root.ch ? root.ch.members.length + " in voice · " + (root.tick, dur(Date.now() / 1000 - root.ch.joined)) : (dc.connected ? "not in a call" : "not connected"); onBack: Sys.panel = "home" }
    Column {
        x: Theme.s(14); y: Theme.s(58); width: parent.width - Theme.s(28); spacing: Theme.s(8)
        Row {
            spacing: Theme.s(8)
            Tile { width: (parent.parent.width - Theme.s(16)) / 3; icon: dc.mute || dc.deaf ? "micoff" : "mic"; label: "Mic"; active: dc.mute || dc.deaf; activeColor: "#33ec5f6a"; onClicked: Sys.dcSend("mute") }
            Tile { width: (parent.parent.width - Theme.s(16)) / 3; icon: dc.deaf ? "headoff" : "head"; label: "Deafen"; active: dc.deaf; activeColor: "#33ec5f6a"; onClicked: Sys.dcSend("deafen") }
            Tile { width: (parent.parent.width - Theme.s(16)) / 3; icon: "logout"; label: "Leave"; onClicked: Sys.dcSend("leave") }
        }
        Row {
            spacing: Theme.s(8)
            Tile { width: (parent.parent.width - Theme.s(8)) / 2; icon: "discord"; label: "Open / Stream"; sub: "Go Live inside Discord"
                   onClicked: { Sys.closeAll(); Quickshell.execDetached(["sh", "-c", "hyprctl dispatch focuswindow 'class:(?i)^(discord|vesktop)$' || discord"]) } }
            Tile { width: (parent.parent.width - Theme.s(8)) / 2; icon: "vol"; label: "Audio"; sub: "pavucontrol"; onClicked: { Sys.closeAll(); Quickshell.execDetached(["pavucontrol"]) } }
        }
        Item {
            width: parent.width; height: Theme.s(44)
            Row { spacing: Theme.s(8); Ico { n: "mic"; color: Theme.accent; font.pixelSize: Theme.s(15) } Lbl { text: "Input volume"; font.bold: true } }
            Lbl { anchors.right: parent.right; text: Math.round(dc.in_vol || 0) + "%"; font.bold: true; font.pixelSize: Theme.fs(12) }
            Slid { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } value: dc.in_vol || 0; to: 100; onMoved: v => Sys.dcSend("in_vol " + Math.round(v)) }
        }
        Item {
            width: parent.width; height: Theme.s(44)
            Row { spacing: Theme.s(8); Ico { n: "vol"; color: Theme.accent; font.pixelSize: Theme.s(15) } Lbl { text: "Output volume"; font.bold: true } }
            Lbl { anchors.right: parent.right; text: Math.round(dc.out_vol || 0) + "%"; font.bold: true; font.pixelSize: Theme.fs(12) }
            Slid { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } value: dc.out_vol || 0; to: 200; onMoved: v => Sys.dcSend("out_vol " + Math.round(v)) }
        }
        Lbl { visible: !!root.ch; text: "MEMBERS"; color: Theme.sub; font.bold: true; font.pixelSize: Theme.fs(10) }
        Repeater {
            model: root.ch ? root.ch.members : []
            Rectangle {
                width: parent.width; height: Theme.s(36); radius: Theme.s(10)
                color: modelData.speaking ? Qt.rgba(0.48, 0.85, 0.56, 0.16) : Theme.surface
                Rectangle { x: Theme.s(12); anchors.verticalCenter: parent.verticalCenter; width: Theme.s(8); height: width; radius: width / 2; color: modelData.speaking ? Theme.good : Theme.surface2 }
                Lbl { x: Theme.s(30); anchors.verticalCenter: parent.verticalCenter; width: parent.width - Theme.s(80); text: modelData.name; font.bold: modelData.speaking; color: modelData.speaking ? Theme.good : Theme.text }
                Row { anchors { right: parent.right; rightMargin: Theme.s(10); verticalCenter: parent.verticalCenter } spacing: Theme.s(6)
                    Ico { visible: modelData.mute; n: "micoff"; color: Theme.danger; font.pixelSize: Theme.s(13) }
                    Ico { visible: modelData.deaf; n: "headoff"; color: Theme.danger; font.pixelSize: Theme.s(13) } }
            }
        }
    }
}
