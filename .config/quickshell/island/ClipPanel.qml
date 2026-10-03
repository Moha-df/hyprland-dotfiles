import QtQuick
import Quickshell

FocusScope {
    id: root
    focus: true
    NumberAnimation on opacity { from: 0; to: 1; duration: 250 }

    property string query: ""
    readonly property var items: {
        const q = query.toLowerCase();
        return q === "" ? Sys.clips : Sys.clips.filter(c => c.toLowerCase().includes(q));
    }

    Component.onCompleted: focusTimer.start()
    Timer { id: focusTimer; interval: 120; repeat: true; property int n: 0
            onTriggered: { input.forceActiveFocus(); if (input.activeFocus || ++n > 15) stop() } }

    function pick(i) {
        const t = items[i];
        if (t === undefined) return;
        Sys.copyClip(t);
        Sys.closeAll();
    }
    function preview(t) { return t.replace(/\s*\n\s*/g, " ⏎ ").trim() }

    Row {
        x: Theme.s(22); y: Theme.s(14); spacing: Theme.s(8)
        Ico { n: "clip"; color: Theme.accent; font.pixelSize: Theme.s(16) }
        Lbl { text: "CLIPBOARD"; font.bold: true; font.pixelSize: Theme.fs(12); font.letterSpacing: 1; anchors.verticalCenter: parent.verticalCenter }
    }
    Lbl {
        anchors { right: parent.right; rightMargin: Theme.s(22); top: parent.top; topMargin: Theme.s(14) }
        text: "Clear all"; color: Theme.danger; font.bold: true; font.pixelSize: Theme.fs(11)
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Sys.clearClips() }
    }

    Item {
        x: Theme.s(22); y: Theme.s(46); width: parent.width - Theme.s(44); height: Theme.s(30)
        Ico { n: "search"; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
        TextInput {
            id: input
            anchors { left: parent.left; leftMargin: Theme.s(30); right: cnt.left; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            color: Theme.text; selectionColor: Theme.accent; selectedTextColor: Theme.onAccent
            font.family: Theme.font; font.pixelSize: Theme.fs(14)
            clip: true
            onTextChanged: { root.query = text; lv.currentIndex = 0 }
            Keys.onDownPressed: lv.incrementCurrentIndex()
            Keys.onUpPressed: lv.decrementCurrentIndex()
            Keys.onReturnPressed: root.pick(lv.currentIndex)
            Keys.onEscapePressed: Sys.closeAll()
            Lbl { visible: input.text === ""; text: "Search history"; color: Theme.sub; font.pixelSize: Theme.fs(14) }
        }
        Lbl { id: cnt; anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              text: root.items.length + " / " + Sys.clips.length; color: Theme.sub; font.pixelSize: Theme.fs(11) }
    }
    Rectangle { x: Theme.s(22); y: Theme.s(80); width: parent.width - Theme.s(44); height: 1; color: Theme.border }

    Lbl {
        visible: root.items.length === 0
        anchors.centerIn: parent
        text: Sys.clips.length === 0 ? "Nothing copied yet — copy some text" : "No match"
        color: Theme.sub
    }

    ListView {
        id: lv
        x: Theme.s(14); y: Theme.s(88); width: parent.width - Theme.s(28); height: parent.height - Theme.s(98)
        clip: true; model: root.items; currentIndex: 0; spacing: Theme.s(2)
        highlightMoveDuration: 100
        delegate: Rectangle {
            id: row
            width: lv.width; height: Theme.s(44); radius: Theme.s(12)
            color: ListView.isCurrentItem || ma.containsMouse ? Theme.surface : "transparent"
            border.color: ListView.isCurrentItem ? Theme.border : "transparent"
            Column {
                x: Theme.s(14); anchors.verticalCenter: parent.verticalCenter; width: parent.width - Theme.s(54)
                Lbl { width: parent.width; text: root.preview(modelData); font.pixelSize: Theme.fs(13) }
                Lbl { width: parent.width; font.pixelSize: Theme.fs(9); color: Theme.sub
                      text: modelData.length + " chars" + (modelData.split("\n").length > 1 ? " · " + modelData.split("\n").length + " lines" : "") }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(index); onEntered: lv.currentIndex = index }
            Ico { anchors { right: parent.right; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
                  n: "close"; color: Theme.sub; font.pixelSize: Theme.s(13); visible: ma.containsMouse
                  MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Sys.removeClip(modelData) } }
        }
    }
}
