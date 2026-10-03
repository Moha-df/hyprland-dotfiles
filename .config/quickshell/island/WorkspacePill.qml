import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root
    readonly property int count: {
        let m = 5;
        for (const w of Hyprland.workspaces.values) if (w.id > m) m = w.id;
        return Math.min(m, 10);
    }
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    property var activeSpecials: ({})
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name !== "activespecial") return;
            const p = e.data.split(",");
            const m = Object.assign({}, root.activeSpecials);
            m[p[1]] = p[0];
            root.activeSpecials = m;
        }
    }
    readonly property var shownSpecials: Object.values(activeSpecials)

    width: row.width + Theme.s(16)
    height: Theme.s(34)
    radius: height / 2
    color: Theme.bg
    border.color: Theme.border
    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s(4)
        Repeater {
            model: root.count
            Rectangle {
                readonly property int wid: index + 1
                readonly property bool focused: wid === root.focusedId
                readonly property bool used: Hyprland.workspaces.values.some(w => w.id === wid)
                width: focused ? Theme.s(26) : Theme.s(20)
                height: Theme.s(20)
                radius: height / 2
                color: focused ? Theme.accent : ma.containsMouse ? Theme.surface2 : "transparent"
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Lbl {
                    anchors.centerIn: parent
                    text: parent.wid
                    font.pixelSize: Theme.fs(11)
                    font.bold: parent.focused
                    color: parent.focused ? Theme.onAccent : parent.used ? Theme.text : Theme.sub
                    opacity: parent.used || parent.focused ? 1 : 0.5
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + parent.wid)
                }
            }
        }
        Rectangle { width: 1; height: Theme.s(14); color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
        Repeater {
            model: [["magic", ""], ["magic2", "2"]]
            Rectangle {
                readonly property string sname: "special:" + modelData[0]
                readonly property var ws: Hyprland.workspaces.values.find(w => w.name === sname)
                readonly property bool shown: root.shownSpecials.includes(sname)
                readonly property bool used: !!ws
                width: Theme.s(modelData[1] ? 34 : 26)
                height: Theme.s(20)
                radius: height / 2
                color: shown ? Theme.accent : sma.containsMouse ? Theme.surface2 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Row {
                    anchors.centerIn: parent
                    spacing: 1
                    Ico { n: "star"; font.pixelSize: Theme.s(12); color: parent.parent.shown ? Theme.onAccent : parent.parent.used ? Theme.accent : Theme.sub }
                    Lbl { visible: modelData[1] !== ""; text: modelData[1]; font.pixelSize: Theme.fs(10); font.bold: true
                          color: parent.parent.shown ? Theme.onAccent : parent.parent.used ? Theme.text : Theme.sub }
                }
                MouseArea {
                    id: sma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("togglespecialworkspace " + modelData[0])
                }
            }
        }
    }
}
