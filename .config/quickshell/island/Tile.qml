import QtQuick

Btn {
    id: t
    property string icon
    property string label
    property string sub: ""
    property bool wide: false
    property color iconColor: active ? Theme.accent : Theme.sub
    property color activeColor: Theme.accentSoft
    height: Theme.s(wide ? 62 : 46)
    radius: Theme.s(wide ? 20 : 16)
    border.color: active ? Theme.accent : "transparent"
    border.width: active && wide ? 1 : 0

    Rectangle {
        visible: t.wide
        x: Theme.s(12); anchors.verticalCenter: parent.verticalCenter
        width: Theme.s(38); height: width; radius: width / 2
        color: t.active ? Theme.accent : Theme.surface2
        Ico { anchors.centerIn: parent; n: t.icon; color: t.active ? Theme.onAccent : Theme.sub }
    }
    Ico { visible: !t.wide; x: Theme.s(12); anchors.verticalCenter: parent.verticalCenter; n: t.icon; color: t.iconColor; font.pixelSize: Theme.s(16) }
    Column {
        x: t.wide ? Theme.s(60) : Theme.s(40)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - Theme.s(8)
        Lbl { width: parent.width; text: t.label; font.bold: true; font.pixelSize: Theme.fs(13); color: t.active && t.wide ? Theme.accent : Theme.text }
        Lbl { visible: t.sub !== ""; width: parent.width; text: t.sub; color: Theme.sub; font.pixelSize: Theme.fs(10) }
    }
}
