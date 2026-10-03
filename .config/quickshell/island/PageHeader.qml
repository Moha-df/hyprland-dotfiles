import QtQuick

Item {
    id: h
    property string title
    property string jp: ""
    property string sub: ""
    signal back()
    height: Theme.s(48)
    Row {
        x: Theme.s(16); anchors.verticalCenter: parent.verticalCenter; spacing: Theme.s(10)
        Ico { n: "back"; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.s(20)
              MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: h.back() } }
        Lbl { visible: Theme.glyphs && h.jp !== ""; text: h.jp; color: Theme.sub; font.pixelSize: Theme.fs(18); anchors.verticalCenter: parent.verticalCenter }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Lbl { text: h.title; font.bold: true; font.pixelSize: Theme.fs(15); font.letterSpacing: 1 }
            Lbl { visible: h.sub !== ""; text: h.sub; color: Theme.sub; font.pixelSize: Theme.fs(10) }
        }
    }
}
