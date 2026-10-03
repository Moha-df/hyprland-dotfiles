import QtQuick
import Quickshell

Rectangle {
    id: root
    readonly property var p: Sys.player
    width: Theme.s(300); height: Theme.s(112)
    radius: Theme.s(22); color: Theme.bg; border.color: Theme.border
    clip: true

    Rectangle {
        x: Theme.s(14); y: Theme.s(14); width: Theme.s(60); height: width; radius: Theme.s(12); color: Theme.surface; clip: true
        Image { anchors.fill: parent; source: root.p ? root.p.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        Ico { anchors.centerIn: parent; n: "music"; color: Theme.sub; visible: !root.p || root.p.trackArtUrl === "" }
    }
    Column {
        x: Theme.s(86); y: Theme.s(16); width: parent.width - Theme.s(100)
        Lbl { width: parent.width; text: root.p ? (root.p.trackTitle || "Unknown") : "Nothing playing"; font.bold: true; font.pixelSize: Theme.fs(14) }
        Lbl { width: parent.width; text: root.p ? (root.p.trackArtist || root.p.identity) : "Start a player"; color: Theme.sub; font.pixelSize: Theme.fs(11) }
    }
    Row {
        x: Theme.s(86); y: Theme.s(60); spacing: Theme.s(10)
        Repeater {
            model: [["skipp", () => root.p && root.p.previous()], [root.p && root.p.isPlaying ? "pause" : "play", () => root.p && root.p.togglePlaying()], ["skipn", () => root.p && root.p.next()]]
            Btn { width: Theme.s(32); height: width; radius: width / 2; onClicked: modelData[1]()
                  Ico { anchors.centerIn: parent; n: modelData[0]; font.pixelSize: Theme.s(15) } }
        }
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.s(14); bottomMargin: Theme.s(10) }
        height: Theme.s(4); radius: 2; color: Theme.surface2
        Rectangle { height: parent.height; radius: 2; color: Theme.accent
                    width: root.p && root.p.length > 0 ? parent.width * Math.min(1, root.p.position / root.p.length) : 0 }
    }
    Timer { running: !!(root.p && root.p.isPlaying) && root.visible; interval: 1000; repeat: true; onTriggered: root.p.positionChanged() }
}
