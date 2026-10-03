import QtQuick
import Quickshell

Item {
    id: root
    property string armed: ""
    PageHeader { width: parent.width; title: "POWER"; jp: "電"; onBack: Sys.panel = "home" }
    Column {
        x: Theme.s(14); y: Theme.s(58); width: parent.width - Theme.s(28); spacing: Theme.s(8)
        Repeater {
            model: [["lock", "Lock", ["loginctl", "lock-session"], false], ["logout", "Log out", ["hyprctl", "dispatch", "exit"], true],
                    ["sleep", "Suspend", ["systemctl", "suspend"], false], ["restart", "Reboot", ["systemctl", "reboot"], true],
                    ["power", "Shut down", ["systemctl", "poweroff"], true]]
            Tile {
                wide: true; width: parent.width; icon: modelData[0]
                label: root.armed === modelData[0] ? "Click again to confirm" : modelData[1]
                active: root.armed === modelData[0]; activeColor: "#33ec5f6a"
                onClicked: {
                    if (modelData[3] && root.armed !== modelData[0]) { root.armed = modelData[0]; return }
                    Quickshell.execDetached(modelData[2]); Sys.closeAll();
                }
            }
        }
    }
}
