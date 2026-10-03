import QtQuick

Item {
    id: root
    NumberAnimation on opacity { from: 0; to: 1; duration: 250 }

    Row {
        anchors.centerIn: parent
        spacing: Theme.s(9)
        Rectangle {
            id: d1
            width: Theme.s(8); height: width; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Sys.recording ? "#ff4d5a" : Theme.sub
            SequentialAnimation on opacity {
                running: Sys.recording; loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 600 }
                NumberAnimation { to: 1; duration: 600 }
            }
        }
        Rectangle {
            width: Theme.s(8); height: width; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Sys.dcSpeaking ? Theme.good : Sys.inVoice ? (Sys.dc.deaf || Sys.dc.mute ? Theme.danger : Theme.accent) : Theme.sub
        }
        Lbl {
            anchors.verticalCenter: parent.verticalCenter
            text: Sys.recording ? Sys.recTime : Sys.timeText
            color: Sys.recording ? "#ff7782" : Theme.text
            font.bold: true
            font.pixelSize: Theme.fs(13)
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? Sys.toggleRecording() : Sys.setIsland("clock")
    }
}
