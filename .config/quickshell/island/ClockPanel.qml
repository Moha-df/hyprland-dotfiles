import QtQuick

Item {
    id: root
    NumberAnimation on opacity { from: 0; to: 1; duration: 300 }

    readonly property date monday: {
        const d = new Date(Sys.now);
        d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
        return d;
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.s(20)
        spacing: Theme.s(10)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.s(9); height: width; radius: width / 2
            color: Sys.recording ? "#ff4d5a" : Theme.accent
        }
        Lbl {
            text: Sys.timeText
            font.pixelSize: Theme.fs(34)
            font.bold: true
            color: Theme.accent
        }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.s(80)
        spacing: Theme.s(14)
        Repeater {
            model: 7
            Column {
                readonly property date d: new Date(root.monday.getFullYear(), root.monday.getMonth(), root.monday.getDate() + index)
                readonly property bool today: d.toDateString() === Sys.now.toDateString()
                readonly property bool weekend: index >= 5
                width: Theme.s(26)
                spacing: Theme.s(3)
                Lbl {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale("en_US").dayName(d.getDay() === 0 ? 0 : d.getDay(), Locale.NarrowFormat)
                    font.pixelSize: Theme.fs(10); font.bold: true
                    color: today ? Theme.accent : weekend ? Theme.danger : Theme.sub
                }
                Lbl {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: d.getDate()
                    font.pixelSize: Theme.fs(15); font.bold: today
                    color: today ? Theme.text : weekend ? Theme.danger : Theme.text
                    opacity: today ? 1 : 0.75
                }
            }
        }
    }
    Ico {
        anchors { right: parent.right; bottom: parent.bottom; margins: Theme.s(10) }
        n: "down"; color: Theme.sub; font.pixelSize: Theme.s(16)
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Sys.setIsland("calendar") }
    }
    MouseArea {
        anchors.fill: parent; z: -1
        onClicked: Sys.closeAll()
    }
}
