import QtQuick
import Quickshell

Item {
    id: root
    NumberAnimation on opacity { from: 0; to: 1; duration: 300 }

    Row {
        x: Theme.s(20); y: Theme.s(14)
        spacing: Theme.s(8)
        Ico { n: "dash"; color: Theme.accent; font.pixelSize: Theme.s(16) }
        Lbl { text: "MIXER"; font.bold: true; font.pixelSize: Theme.fs(13); anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        anchors { right: parent.right; rightMargin: Theme.s(16); top: parent.top; topMargin: Theme.s(10) }
        spacing: Theme.s(6)
        Repeater {
            model: [["vol", () => !Sys.volMuted, () => Sys.toggleVolMute()], ["mic", () => !Sys.micMuted, () => Sys.toggleMicMute()],
                    ["moon", () => Sys.night, () => Sys.toggleNight()], ["dnd", () => Sys.dnd, () => Sys.dnd = !Sys.dnd]]
            Btn {
                width: Theme.s(30); height: width; radius: width / 2
                active: modelData[1]()
                onClicked: modelData[2]()
                Ico { anchors.centerIn: parent; n: modelData[0]; font.pixelSize: Theme.s(14); color: parent.active ? Theme.accent : Theme.sub }
            }
        }
    }
    Rectangle { x: Theme.s(14); y: Theme.s(48); width: parent.width - Theme.s(28); height: 1; color: Theme.border }

    // one row: icon / label / slider / percent / mute
    component VolRow: Item {
        id: vr
        property string label
        property string sub: ""
        property real value
        property real maxv: 100
        property bool muted: false
        property string glyph: "vol"
        property string iconName: ""
        signal moved(real v)
        signal muteClicked()
        width: parent ? parent.width : 0
        height: Theme.s(44)

        Btn {
            id: ib
            x: 0; anchors.verticalCenter: parent.verticalCenter
            width: Theme.s(32); height: width; radius: width / 2
            active: !vr.muted; onClicked: vr.muteClicked()
            Image {
                id: appIcon
                anchors.centerIn: parent; width: Theme.s(20); height: width; sourceSize: Qt.size(40, 40)
                source: vr.iconName ? Quickshell.iconPath(vr.iconName, true) : ""
                visible: status === Image.Ready; opacity: vr.muted ? 0.4 : 1
            }
            Ico { anchors.centerIn: parent; visible: !appIcon.visible; n: vr.muted ? "volmute" : vr.glyph; font.pixelSize: Theme.s(14)
                  color: vr.muted ? Theme.sub : Theme.accent }
        }
        Column {
            x: Theme.s(44); anchors.verticalCenter: parent.verticalCenter; width: Theme.s(110)
            Lbl { width: parent.width; text: vr.label; font.bold: true; font.pixelSize: Theme.fs(12) }
            Lbl { visible: vr.sub !== ""; width: parent.width; text: vr.sub; color: Theme.sub; font.pixelSize: Theme.fs(9) }
        }
        Slid {
            x: Theme.s(164); anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.s(164) - Theme.s(48)
            value: vr.value; to: vr.maxv
            fill: vr.muted ? Theme.sub : Theme.accent
            onMoved: v => vr.moved(v)
        }
        Lbl { anchors { right: parent.right; verticalCenter: parent.verticalCenter } width: Theme.s(40); horizontalAlignment: Text.AlignRight
              text: Math.round(vr.value) + "%"; font.bold: true; font.pixelSize: Theme.fs(11); color: vr.muted ? Theme.sub : Theme.text }
    }

    Column {
        x: Theme.s(20); y: Theme.s(58); width: parent.width - Theme.s(40); spacing: Theme.s(2)
        VolRow { label: "Volume"; sub: Sys.sinkDesc; glyph: "vol"; value: Sys.vol; maxv: 150; muted: Sys.volMuted
                 onMoved: v => Sys.setVol(v); onMuteClicked: Sys.toggleVolMute() }
        VolRow { label: "Microphone"; sub: Sys.sourceDesc; glyph: "mic"; value: Sys.micVol; muted: Sys.micMuted
                 onMoved: v => Sys.setMic(v); onMuteClicked: Sys.toggleMicMute() }

        Lbl { text: "APPLICATIONS"; color: Theme.sub; font.bold: true; font.pixelSize: Theme.fs(10); font.letterSpacing: 1; topPadding: Theme.s(8); bottomPadding: Theme.s(2) }
        Lbl { visible: Sys.apps.length === 0; text: "No app is playing sound"; color: Theme.sub; font.pixelSize: Theme.fs(11); topPadding: Theme.s(6) }

        ListView {
            width: parent.width
            height: Math.min(contentHeight, Theme.s(46) * 6)
            visible: Sys.apps.length > 0
            clip: true; interactive: contentHeight > height; spacing: Theme.s(2)
            model: Sys.apps
            delegate: VolRow {
                width: ListView.view.width
                label: modelData.name
                sub: modelData.media
                value: modelData.vol
                maxv: 150
                muted: modelData.mute
                iconName: modelData.icon
                onMoved: v => Sys.setAppVol(modelData.id, v)
                onMuteClicked: Sys.toggleAppMute(modelData.id)
            }
        }
    }
}
