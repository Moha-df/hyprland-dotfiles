import QtQuick

Rectangle {
    id: isl
    readonly property var sz: ({
        idle: [(Sys.recording || Sys.inVoice) ? 190 : 128, 34],
        clock: [270, 152], calendar: [610, 252], wall: [840, 240],
        launcher: [480, 410], clip: [480, 420], mixer: [470, 200 + 46 * Math.max(Math.min(Sys.apps.length, 6), 1) - (Sys.apps.length === 0 ? 20 : 0)], toast: [470, 106]
    })
    readonly property var cur: sz[Sys.island] ?? sz.idle

    width: Theme.s(cur[0])
    height: Theme.s(cur[1])
    radius: Math.min(height / 2, Theme.s(28))
    color: Theme.bg
    border.color: Theme.border
    border.width: 1
    clip: true
    readonly property bool shown: Sys.barShown || Sys.island !== "idle"
    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 220 } }

    Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }

    Repeater {
        model: [["idle", "IdlePill.qml"], ["clock", "ClockPanel.qml"], ["calendar", "CalendarPanel.qml"],
                ["wall", "WallPanel.qml"], ["launcher", "LauncherPanel.qml"], ["clip", "ClipPanel.qml"], ["mixer", "MixerPanel.qml"],
                ["toast", "ToastPanel.qml"]]
        Loader {
            anchors.fill: isl
            active: Sys.island === modelData[0]
            source: modelData[1]
            focus: true
        }
    }
}
