import QtQuick

Item {
    id: sl
    property real value: 0
    property real from: 0
    property real to: 100
    property color fill: Theme.accent
    signal moved(real v)
    height: Theme.s(22)

    readonly property real shown: ma.pressed ? ma.dragV : value
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.s(8)
        radius: height / 2
        color: Theme.surface2
        Rectangle {
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, (sl.shown - sl.from) / (sl.to - sl.from))))
            height: parent.height
            radius: height / 2
            color: sl.fill
        }
    }
    MouseArea {
        id: ma
        property real dragV: 0
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function upd(x) {
            dragV = sl.from + (sl.to - sl.from) * Math.max(0, Math.min(1, x / width));
            sl.moved(dragV);
        }
        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x) }
    }
}
