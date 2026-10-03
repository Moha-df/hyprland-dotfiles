import QtQuick

Item {
    id: root
    NumberAnimation on opacity { from: 0; to: 1; duration: 300 }

    property date view: new Date(Sys.now.getFullYear(), Sys.now.getMonth(), 1)
    readonly property int offset: (view.getDay() + 6) % 7
    readonly property int days: new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate()
    readonly property var w: Sys.weather
    readonly property var cc: w ? w.current_condition[0] : null

    function wIcon(desc) {
        const d = (desc || "").toLowerCase();
        return /rain|drizzle|shower/.test(d) ? "rain" : /cloud|overcast|mist|fog|haze|smoke/.test(d) ? "cloud" : "sun";
    }

    // ---- weather ----
    Item {
        x: Theme.s(22); y: Theme.s(20); width: Theme.s(210); height: parent.height - Theme.s(40)
        Row {
            spacing: Theme.s(12)
            Ico { n: root.wIcon(root.cc ? root.cc.weatherDesc[0].value : ""); color: Theme.accent; font.pixelSize: Theme.s(34) }
            Column {
                Lbl { text: root.cc ? root.cc.temp_C + "°" : "--"; font.pixelSize: Theme.fs(28); font.bold: true }
                Lbl { text: root.cc ? root.cc.weatherDesc[0].value : "Loading…"; color: Theme.sub; font.pixelSize: Theme.fs(12); width: Theme.s(150) }
            }
        }
        Rectangle { y: Theme.s(76); width: parent.width; height: 1; color: Theme.border }
        Row {
            y: Theme.s(86); width: parent.width
            Lbl {
                width: parent.width - Theme.s(60)
                text: root.w ? root.w.nearest_area[0].areaName[0].value.toUpperCase() : ""
                font.pixelSize: Theme.fs(11); font.bold: true; color: Theme.sub
            }
            Lbl { text: root.cc ? "󰖎 " + root.cc.humidity + "%" : ""; font.family: Theme.iconFont; font.pixelSize: Theme.fs(11); color: Theme.sub }
        }
        Row {
            y: Theme.s(130); spacing: Theme.s(26)
            Repeater {
                model: root.w ? [1, 2] : []
                Column {
                    spacing: Theme.s(3)
                    readonly property var day: root.w.weather[modelData]
                    Lbl { text: Qt.formatDate(new Date(day.date), "ddd").toUpperCase(); font.pixelSize: Theme.fs(10); font.bold: true; color: Theme.sub }
                    Ico { n: root.wIcon(day.hourly[4].weatherDesc[0].value); color: Theme.accent; font.pixelSize: Theme.s(18); anchors.horizontalCenter: parent.horizontalCenter }
                    Lbl { text: day.maxtempC + "°"; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }
    }

    // ---- month ----
    Item {
        x: Theme.s(260); y: Theme.s(16); width: parent.width - Theme.s(282); height: parent.height - Theme.s(24)
        Row {
            width: parent.width; height: Theme.s(26)
            Ico { n: "cal"; font.pixelSize: Theme.s(14); color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
            Lbl {
                width: parent.width - Theme.s(90); leftPadding: Theme.s(8)
                text: Qt.formatDate(root.view, "MMMM yyyy").toUpperCase()
                font.pixelSize: Theme.fs(12); font.bold: true; color: Theme.sub
                anchors.verticalCenter: parent.verticalCenter
            }
            Ico { n: "back"; color: Theme.sub; font.pixelSize: Theme.s(16)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.view = new Date(root.view.getFullYear(), root.view.getMonth() - 1, 1) } }
            Ico { n: "next"; color: Theme.sub; font.pixelSize: Theme.s(16)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.view = new Date(root.view.getFullYear(), root.view.getMonth() + 1, 1) } }
        }
        Grid {
            y: Theme.s(34); columns: 7
            readonly property real cw: parent.width / 7
            readonly property real ch: Theme.s(26)
            Repeater {
                model: 7 + 42
                Item {
                    width: parent.cw; height: parent.ch
                    readonly property int cell: index - 7 - root.offset + 1
                    readonly property bool head: index < 7
                    readonly property bool inMonth: !head && cell >= 1 && cell <= root.days
                    readonly property bool today: inMonth && root.view.getMonth() === Sys.now.getMonth()
                        && root.view.getFullYear() === Sys.now.getFullYear() && cell === Sys.now.getDate()
                    readonly property bool weekend: index % 7 >= 5
                    Rectangle {
                        anchors.centerIn: parent; width: Theme.s(24); height: width; radius: width / 2
                        visible: today; color: "transparent"; border.color: Theme.danger; border.width: 2
                    }
                    Lbl {
                        anchors.centerIn: parent
                        visible: head || inMonth
                        text: head ? ["M", "T", "W", "T", "F", "S", "S"][index] : cell
                        font.pixelSize: Theme.fs(head ? 10 : 12); font.bold: head || today
                        color: weekend ? Theme.danger : head ? Theme.sub : Theme.text
                    }
                }
            }
        }
    }
    MouseArea { anchors.fill: parent; z: -1; onClicked: Sys.setIsland("clock") }
}
