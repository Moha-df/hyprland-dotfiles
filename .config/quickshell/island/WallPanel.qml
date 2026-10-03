import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Io

FocusScope {
    id: root
    focus: true
    NumberAnimation on opacity { from: 0; to: 1; duration: 300 }

    property string filter: "all"
    readonly property var stillF: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    readonly property var liveF: ["*.gif", "*.mp4", "*.webm"]

    FolderListModel {
        id: folder
        folder: "file://" + Theme.wallDir
        nameFilters: root.filter === "still" ? root.stillF : root.filter === "live" ? root.liveF : root.stillF.concat(root.liveF)
        showDirs: false
        sortField: FolderListModel.Name
    }

    property string res: ""
    readonly property string curPath: list.currentIndex >= 0 && folder.count > 0 ? folder.get(list.currentIndex, "filePath") : ""
    onCurPathChanged: { res = ""; if (curPath) { ident.running = false; ident.running = true } }
    Process {
        id: ident
        command: ["identify", "-format", "%wx%h", root.curPath + "[0]"]
        stdout: StdioCollector { onStreamFinished: root.res = text.trim() }
    }

    Keys.onLeftPressed: list.decrementCurrentIndex()
    Keys.onRightPressed: list.incrementCurrentIndex()
    Keys.onReturnPressed: if (curPath) Sys.applyWall(curPath)
    Keys.onEscapePressed: Sys.closeAll()

    // header
    Lbl { x: Theme.s(24); y: Theme.s(14); text: Theme.wallDir; color: Theme.sub; font.pixelSize: Theme.fs(11); width: parent.width * 0.45 }
    Row {
        anchors { right: parent.right; rightMargin: Theme.s(20); top: parent.top; topMargin: Theme.s(10) }
        spacing: Theme.s(8)
        Rectangle {
            height: Theme.s(26); width: chips.width + Theme.s(8); radius: height / 2; color: Theme.surface
            Row {
                id: chips; anchors.centerIn: parent; spacing: Theme.s(2)
                Repeater {
                    model: ["all", "still", "live"]
                    Btn {
                        width: cl.implicitWidth + Theme.s(18); height: Theme.s(20); radius: height / 2
                        base: "transparent"; active: root.filter === modelData
                        activeColor: Theme.accent
                        onClicked: root.filter = modelData
                        Lbl { id: cl; anchors.centerIn: parent; text: modelData; font.pixelSize: Theme.fs(11); font.bold: true
                              color: parent.active ? Theme.onAccent : Theme.sub }
                    }
                }
            }
        }
        Btn { width: Theme.s(26); height: width; radius: width / 2; onClicked: Sys.applyWall(root.curPath)
              Ico { anchors.centerIn: parent; n: "refresh"; font.pixelSize: Theme.s(13); color: Theme.sub } }
        Btn { width: Theme.s(26); height: width; radius: width / 2; onClicked: Sys.closeAll()
              Ico { anchors.centerIn: parent; n: "close"; font.pixelSize: Theme.s(13); color: Theme.sub } }
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Theme.s(46) }
        height: Theme.s(150)
        orientation: ListView.Horizontal
        model: folder
        spacing: Theme.s(12)
        clip: true
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - Theme.s(130)
        preferredHighlightEnd: width / 2 + Theme.s(130)
        highlightMoveDuration: 280
        cacheBuffer: 2000
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: 0

        delegate: Item {
            id: dl
            readonly property bool cur: ListView.isCurrentItem
            readonly property bool video: /\.(mp4|webm|mkv)$/i.test(fileName)
            width: cur ? Theme.s(260) : Theme.s(150)
            height: list.height
            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Rectangle {
                anchors { fill: parent; topMargin: dl.cur ? 0 : Theme.s(18); bottomMargin: dl.cur ? 0 : Theme.s(18) }
                radius: Theme.s(14); color: Theme.surface
                border.color: dl.cur ? Theme.accent : "transparent"; border.width: 2
                clip: true
                Behavior on anchors.topMargin { NumberAnimation { duration: 260 } }
                Image {
                    anchors.fill: parent; anchors.margins: 2
                    visible: !dl.video
                    source: dl.video ? "" : "file://" + filePath
                    sourceSize.width: 480; sourceSize.height: 270
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: dl.cur ? 1 : 0.55
                }
                Column {
                    visible: dl.video; anchors.centerIn: parent; spacing: Theme.s(4)
                    Ico { n: "play"; color: Theme.accent; font.pixelSize: Theme.s(28); anchors.horizontalCenter: parent.horizontalCenter }
                    Lbl { text: fileName; font.pixelSize: Theme.fs(10); color: Theme.sub; width: Theme.s(120); horizontalAlignment: Text.AlignHCenter }
                }
                Rectangle {
                    visible: dl.cur && root.res !== ""
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.s(8) }
                    height: Theme.s(20); width: rl.implicitWidth + Theme.s(16); radius: height / 2; color: "#cc000000"
                    Lbl { id: rl; anchors.centerIn: parent; text: root.res; color: "#fff"; font.pixelSize: Theme.fs(10); font.bold: true }
                }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { if (dl.cur) Sys.applyWall(filePath); else list.currentIndex = index }
            }
        }
        WheelHandler { onWheel: e => e.angleDelta.y < 0 || e.angleDelta.x < 0 ? list.incrementCurrentIndex() : list.decrementCurrentIndex() }
    }

    Btn { anchors { left: parent.left; leftMargin: Theme.s(8); verticalCenter: list.verticalCenter } width: Theme.s(28); height: width; radius: width / 2
          onClicked: list.decrementCurrentIndex(); Ico { anchors.centerIn: parent; n: "back"; font.pixelSize: Theme.s(14) } }
    Btn { anchors { right: parent.right; rightMargin: Theme.s(8); verticalCenter: list.verticalCenter } width: Theme.s(28); height: width; radius: width / 2
          onClicked: list.incrementCurrentIndex(); Ico { anchors.centerIn: parent; n: "next"; font.pixelSize: Theme.s(14) } }

    Lbl {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.s(10) }
        text: folder.count + " wallpapers · click or Enter to apply · ← → to browse"
        color: Theme.sub; font.pixelSize: Theme.fs(10)
    }
}
