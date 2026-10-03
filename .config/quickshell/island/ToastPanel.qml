import QtQuick

Item {
    id: root
    NumberAnimation on opacity { from: 0; to: 1; duration: 250 }
    readonly property var t: Sys.toastData

    Rectangle {
        x: Theme.s(20); y: Theme.s(14)
        height: Theme.s(24); width: appLbl.implicitWidth + Theme.s(24); radius: height / 2
        color: Theme.accent
        Lbl { id: appLbl; anchors.centerIn: parent; text: root.t.app; color: Theme.onAccent; font.bold: true; font.pixelSize: Theme.fs(11) }
    }
    Ico { n: "dnd"; anchors { right: parent.right; rightMargin: Theme.s(70); top: parent.top; topMargin: Theme.s(14) } color: Theme.sub; font.pixelSize: Theme.s(14) }
    Lbl { anchors { right: parent.right; rightMargin: Theme.s(20); top: parent.top; topMargin: Theme.s(14) } text: "now"; color: Theme.sub; font.pixelSize: Theme.fs(11) }
    Lbl { x: Theme.s(20); y: Theme.s(44); width: parent.width - Theme.s(40); text: root.t.title; font.bold: true; font.pixelSize: Theme.fs(14) }
    Lbl { x: Theme.s(20); y: Theme.s(64); width: parent.width - Theme.s(40); text: root.t.body; color: Theme.sub; font.pixelSize: Theme.fs(12) }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const n = root.t.notif;
            try { if (n && n.actions.length) n.actions[0].invoke() } catch (e) {}
            Sys.closeAll();
        }
    }
}
