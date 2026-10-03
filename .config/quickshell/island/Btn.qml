import QtQuick

Rectangle {
    id: b
    property bool active: false
    property color base: Theme.surface
    property color activeColor: Theme.accentSoft
    property alias hovered: ma.containsMouse
    property alias pressed: ma.pressed
    signal clicked()
    signal rightClicked()

    radius: Theme.s(16)
    color: active ? activeColor : ma.containsMouse ? Theme.surface2 : base
    scale: ma.pressed ? 0.97 : 1
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? b.rightClicked() : b.clicked()
    }
}
