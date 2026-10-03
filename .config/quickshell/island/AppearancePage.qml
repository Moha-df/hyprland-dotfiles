import QtQuick

Item {
    id: root
    PageHeader { id: hd; width: parent.width; title: "APPEARANCE"; jp: "相"; onBack: Sys.panel = "home" }

    component Row2: Item {
        property string icon
        property string label
        width: parent ? parent.width : 0
        height: Theme.s(34)
        Ico { id: ri; n: parent.icon; color: Theme.sub; font.pixelSize: Theme.s(15); anchors.verticalCenter: parent.verticalCenter }
        Lbl { x: Theme.s(28); anchors.verticalCenter: parent.verticalCenter; text: parent.label }
    }
    component Seg: Row {
        id: sg
        property var items: []
        property var current
        signal picked(var v)
        spacing: Theme.s(4)
        Repeater {
            model: sg.items
            Btn {
                width: sl.implicitWidth + Theme.s(16); height: Theme.s(24); radius: Theme.s(8)
                base: "transparent"; active: sg.current === modelData[0]; activeColor: Theme.surface2
                onClicked: sg.picked(modelData[0])
                Lbl { id: sl; anchors.centerIn: parent; text: modelData[1]; font.pixelSize: Theme.fs(11); font.bold: parent.active
                      color: parent.active ? Theme.accent : Theme.sub }
            }
        }
    }
    component Toggle: Rectangle {
        id: tg
        property bool on
        signal flipped()
        width: Theme.s(40); height: Theme.s(22); radius: height / 2
        color: on ? Theme.accent : Theme.surface2
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle { width: parent.height - 6; height: width; radius: width / 2; y: 3; x: tg.on ? parent.width - width - 3 : 3; color: tg.on ? Theme.onAccent : Theme.text
                    Behavior on x { NumberAnimation { duration: 150 } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.flipped() }
    }

    Flickable {
        anchors { top: hd.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.s(14); topMargin: Theme.s(4) }
        contentHeight: col.height; clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col; width: parent.width; spacing: Theme.s(2)

            Row2 { icon: "cal"; label: "Time format"
                   Seg { anchors { right: parent.right; verticalCenter: parent.verticalCenter } items: [[true, "24H"], [false, "12H"]]; current: Theme.hour24; onPicked: v => Theme.hour24 = v } }
            Row2 { icon: "refresh"; label: "Clock seconds"
                   Toggle { anchors { right: parent.right; verticalCenter: parent.verticalCenter } on: Theme.clockSeconds; onFlipped: Theme.clockSeconds = !Theme.clockSeconds } }
            Row2 { icon: "play"; label: "Japanese glyphs"
                   Toggle { anchors { right: parent.right; verticalCenter: parent.verticalCenter } on: Theme.glyphs; onFlipped: Theme.glyphs = !Theme.glyphs } }
            Row2 { icon: "music"; label: "Music visualizer"
                   Toggle { anchors { right: parent.right; verticalCenter: parent.verticalCenter } on: Theme.visualizer; onFlipped: Theme.visualizer = !Theme.visualizer } }
            Row2 { icon: "palette"; label: "Theme"
                   Seg { anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                         items: [["light", "Light"], ["dark", "Dark"], ["dynamic", "Dynamic"], ["manual", "Manual"]]; current: Theme.mode; onPicked: v => Theme.mode = v } }

            // hue
            Item {
                width: parent.width; height: Theme.s(30)
                Rectangle {
                    id: hue; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter } height: Theme.s(10); radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ff0000" } GradientStop { position: 0.17; color: "#ffff00" }
                        GradientStop { position: 0.33; color: "#00ff00" } GradientStop { position: 0.5; color: "#00ffff" }
                        GradientStop { position: 0.67; color: "#0000ff" } GradientStop { position: 0.83; color: "#ff00ff" }
                        GradientStop { position: 1.0; color: "#ff0000" }
                    }
                    Rectangle { width: Theme.s(16); height: width; radius: width / 2; color: Theme.accent; border.color: "#fff"; border.width: 2
                                anchors.verticalCenter: parent.verticalCenter; x: Theme.accent.hslHue * (parent.width - width) }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        function upd(x) {
                            const h = Math.max(0, Math.min(1, x / width));
                            Theme.manualAccent = Qt.hsla(h, 0.62, 0.62, 1).toString();
                            Theme.mode = "manual";
                        }
                        onPressed: m => upd(m.x); onPositionChanged: m => { if (pressed) upd(m.x) }
                    }
                }
            }
            Row {
                spacing: Theme.s(12); height: Theme.s(46)
                Rectangle { width: Theme.s(40); height: width; radius: Theme.s(10); color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Column { anchors.verticalCenter: parent.verticalCenter
                    Lbl { text: "Accent hue"; font.bold: true }
                    Lbl { text: Theme.accent.toString().toUpperCase() + " · " + Theme.mode; color: Theme.sub; font.pixelSize: Theme.fs(10) } }
            }
            Rectangle {
                width: parent.width; height: Theme.s(34); radius: Theme.s(10); color: Theme.surface
                Lbl { x: Theme.s(12); anchors.verticalCenter: parent.verticalCenter; text: "#"; color: Theme.sub }
                TextInput {
                    anchors { fill: parent; leftMargin: Theme.s(28); rightMargin: Theme.s(10) }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text; font.family: Theme.font; font.bold: true; font.pixelSize: Theme.fs(13); selectByMouse: true
                    maximumLength: 6
                    text: Theme.manualAccent.replace("#", "").toUpperCase()
                    onEditingFinished: if (/^[0-9a-fA-F]{6}$/.test(text)) { Theme.manualAccent = "#" + text; Theme.mode = "manual" }
                }
            }
            Item { width: 1; height: Theme.s(6) }
            Row2 { icon: "image"; label: "Wallpaper folder" }
            Rectangle {
                width: parent.width; height: Theme.s(34); radius: Theme.s(10); color: Theme.surface
                TextInput {
                    anchors { fill: parent; leftMargin: Theme.s(12); rightMargin: Theme.s(10) }
                    verticalAlignment: TextInput.AlignVCenter; clip: true
                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fs(12); selectByMouse: true
                    text: Theme.wallDir
                    onEditingFinished: Theme.wallDir = text.replace(/^~/, Theme.home)
                }
            }
            Item { width: 1; height: Theme.s(6) }
            Row2 { icon: "area"; label: "UI scale"
                   Seg { anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                         items: [[0.9, "90%"], [1.0, "100%"], [1.1, "110%"], [1.25, "125%"]]; current: Theme.uiScale; onPicked: v => Theme.uiScale = v } }
            Item { width: parent.width; height: Theme.s(40)
                Lbl { anchors.top: parent.top; text: "Bar gap" }
                Lbl { anchors { right: parent.right; top: parent.top } text: Theme.barGap + "px"; color: Theme.accent; font.bold: true }
                Slid { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } value: Theme.barGap; to: 24; onMoved: v => Theme.barGap = Math.round(v) } }
            Row2 { icon: "dash"; label: "Font"
                   Rectangle {
                       anchors { right: parent.right; verticalCenter: parent.verticalCenter } width: Theme.s(150); height: Theme.s(26); radius: Theme.s(8); color: Theme.surface
                       TextInput { anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) } verticalAlignment: TextInput.AlignVCenter; clip: true
                                   color: Theme.accent; font.family: Theme.font; font.bold: true; font.pixelSize: Theme.fs(12); selectByMouse: true
                                   text: Theme.fontFamily; onEditingFinished: if (text.trim()) Theme.fontFamily = text.trim() }
                   } }
            Item { width: parent.width; height: Theme.s(40)
                Lbl { anchors.top: parent.top; text: "Font size" }
                Lbl { anchors { right: parent.right; top: parent.top } text: (Theme.fontDelta >= 0 ? "+" : "") + Theme.fontDelta + "px"; color: Theme.accent; font.bold: true }
                Slid { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } value: Theme.fontDelta; from: -3; to: 5; onMoved: v => Theme.fontDelta = Math.round(v) } }
        }
    }
}
