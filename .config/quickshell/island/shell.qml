//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Theme.monitor) ?? Quickshell.screens[0]
        anchors { top: true; left: true; right: true }
        implicitHeight: kbMode ? (screen ? screen.height : Theme.s(760)) : Theme.s(760)
        exclusiveZone: Sys.barShown ? Theme.s(44) + Theme.barGap : 0
        color: "transparent"
        WlrLayershell.namespace: "island"
        WlrLayershell.keyboardFocus: kbMode ? WlrKeyboardFocus.Exclusive
                                      : Sys.panel === "appearance" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        // launcher / wallpaper picker need real keyboard focus (pointer-follows-focus would steal it from a focus grab)
        readonly property bool kbMode: Sys.island === "launcher" || Sys.island === "wall" || Sys.island === "clip"

        // Only visible elements may catch input: a zero-size region lets clicks through to the windows below.
        component Rg: Region {
            id: rg
            property Item it
            property bool on: it ? it.visible : false
            x: it ? it.x : 0
            y: it ? it.y : 0
            width: on && it ? it.width : 0
            height: on && it ? it.height : 0
        }
        mask: Region {
            Rg { it: catcher; on: win.kbMode }
            Rg { it: leftBtn }
            Rg { it: workspaces }
            Rg { it: island }
            Rg { it: kbPill }
            Rg { it: panel }
            Rg { it: media }
        }

        HyprlandFocusGrab {
            windows: [win]
            active: Sys.anyOpen && !win.kbMode
            onCleared: Sys.closeAll()
        }

        // click outside closes the keyboard-driven pickers
        MouseArea {
            id: catcher
            anchors.fill: parent
            enabled: win.kbMode
            onClicked: Sys.closeAll()
        }

        // ---- left: music ----
        Rectangle {
            id: leftBtn
            opacity: Sys.barShown ? 1 : 0; visible: opacity > 0; scale: Sys.barShown ? 1 : 0.7
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
            x: Theme.s(12); y: Theme.gap
            width: Theme.s(34); height: width; radius: width / 2
            color: Sys.mediaOpen ? Theme.accentSoft : Theme.bg
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: 150 } }
            Ico { anchors.centerIn: parent; n: "music"; visible: !(Theme.visualizer && Sys.player && Sys.player.isPlaying); font.pixelSize: Theme.s(15)
                  color: Sys.player ? Theme.accent : Theme.sub }
            Row {
                anchors.centerIn: parent; spacing: 2; visible: Theme.visualizer && Sys.player && Sys.player.isPlaying
                Repeater {
                    model: 4
                    Rectangle {
                        width: 3; radius: 1.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                        height: 8
                        SequentialAnimation on height {
                            running: parent.visible; loops: Animation.Infinite
                            NumberAnimation { to: 6 + (index * 5 % 11); duration: 260 + index * 70 }
                            NumberAnimation { to: 18 - (index * 3 % 9); duration: 300 + index * 50 }
                        }
                    }
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { const o = !Sys.mediaOpen; Sys.closeAll(); Sys.mediaOpen = o } }
        }
        MediaPop {
            id: media
            x: leftBtn.x; y: leftBtn.y + leftBtn.height + Theme.s(8)
            visible: opacity > 0
            opacity: Sys.mediaOpen ? 1 : 0
            scale: Sys.mediaOpen ? 1 : 0.9
            transformOrigin: Item.TopLeft
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        }

        // ---- workspaces ----
        WorkspacePill {
            id: workspaces
            opacity: Sys.barShown ? 1 : 0; visible: opacity > 0; scale: Sys.barShown ? 1 : 0.7
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
            x: leftBtn.x + leftBtn.width + Theme.s(8)
            y: Theme.gap
        }

        // ---- center island ----
        Island {
            id: island
            x: (win.width - width) / 2
            y: Theme.gap
        }

        // ---- right: control center (the round button itself grows into the panel) ----
        Rectangle {
            id: kbPill
            opacity: Sys.barShown ? 1 : 0; visible: opacity > 0; scale: Sys.barShown ? 1 : 0.7
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
            x: win.width - Theme.s(12) - Theme.s(34) - Theme.s(8) - width
            y: Theme.gap
            height: Theme.s(34)
            width: kbLbl.implicitWidth + Theme.s(24)
            radius: height / 2
            color: Theme.bg
            border.color: Theme.border
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Row {
                anchors.centerIn: parent
                spacing: Theme.s(7)
                Lbl { id: kbLbl; text: Sys.kbLabel; font.bold: true; font.pixelSize: Theme.fs(12); font.letterSpacing: 1 }
            }
        }
        Panel {
            id: panel
            x: win.width - width - Theme.s(12)
            y: Theme.gap
        }
    }

    IpcHandler {
        target: "island"
        function launcher(): void { Sys.setIsland("launcher") }
        function clip(): void { Sys.setIsland("clip") }
        function wall(): void { Sys.setIsland("wall") }
        function calendar(): void { Sys.setIsland("calendar") }
        function mixer(): void { Sys.setIsland("mixer") }
        function clock(): void { Sys.setIsland("clock") }
        function panel(): void { Sys.togglePanel() }
        function page(name: string): void { Sys.island = "idle"; Sys.panel = name }
        function notify(msg: string): void { Sys.toast("test", "Hello", msg) }
        function record(): void { Sys.toggleRecording() }
        function recordfull(): void { Sys.recMode = "full"; Sys.toggleRecording() }
        function close(): void { Sys.closeAll() }
        function bar(): void { Sys.barShown = !Sys.barShown }
        function showbar(): void { Sys.barShown = true }
        function hidebar(): void { Sys.barShown = false }
    }
}
