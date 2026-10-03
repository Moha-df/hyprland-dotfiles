import QtQuick

Rectangle {
    id: p
    readonly property var dims: ({
        home: [380, Sys.homeH], record: [380, 560], capture: [380, 280],
        appearance: [380, 610], discord: [380, Sys.inVoice ? 560 : 330], power: [380, 420], perf: [380, 700], keys: [400, 640]
    })
    readonly property bool open: Sys.panel !== ""
    readonly property string shown: open ? Sys.panel : last
    property string last: "home"
    onShownChanged: if (open) last = Sys.panel

    // closed = the 34px round button, open = the panel: same shape, it just grows
    width: open ? Theme.s(dims[shown][0]) : Theme.s(34)
    height: open ? Theme.s(dims[shown][1]) : Theme.s(34)
    radius: Math.min(height / 2, Theme.s(26))
    color: !open && hover.containsMouse ? Theme.surface : Theme.bg
    border.color: !open && Sys.recording ? "#ff4d5a" : Theme.border
    clip: true

    visible: opacity > 0
    opacity: open || Sys.barShown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 220 } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }

    // the button icon, pinned to the top-right corner
    Ico {
        x: p.width - Theme.s(34); y: 0
        width: Theme.s(34); height: Theme.s(34)
        n: "dash"; font.pixelSize: Theme.s(15)
        color: Sys.recording ? "#ff4d5a" : Theme.accent
        opacity: p.open ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: p.open ? 80 : 260 } }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        enabled: !p.open
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { Sys.closeAll(); Sys.panel = "home" }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: p.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: p.open ? 300 : 90 } }
        Repeater {
            model: [["home", "HomePage.qml"], ["record", "RecordPage.qml"], ["capture", "CapturePage.qml"],
                    ["appearance", "AppearancePage.qml"], ["discord", "DiscordPage.qml"], ["power", "PowerPage.qml"], ["perf", "PerfPage.qml"], ["keys", "KeysPage.qml"]]
            Loader {
                anchors.fill: parent
                active: Sys.panel === modelData[0]
                source: modelData[1]
            }
        }
    }
}
