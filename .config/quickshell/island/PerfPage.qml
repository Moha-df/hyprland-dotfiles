import QtQuick
import QtQuick.Shapes

Item {
    id: root
    readonly property var d: Sys.perf
    readonly property bool ready: d.cpu !== undefined

    function gb(b) { return (b / 1073741824).toFixed(1) }
    function rate(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : (b / 1024).toFixed(0) + " KB/s" }
    function dur(s) { const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return (d ? d + "d " : "") + h + "h " + m + "m" }
    function heat(p) { return p > 85 ? Theme.danger : p > 60 ? "#f0b95a" : Theme.accent }

    // sparkline
    component Spark: Item {
        id: sp
        property var vals: []
        property real maxv: 100
        property color col: Theme.accent
        height: Theme.s(34)
        Shape {
            anchors.fill: parent; layer.enabled: true; layer.samples: 4
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: sp.height
                    GradientStop { position: 0; color: Qt.rgba(sp.col.r, sp.col.g, sp.col.b, 0.35) }
                    GradientStop { position: 1; color: Qt.rgba(sp.col.r, sp.col.g, sp.col.b, 0.02) }
                }
                PathPolyline { path: sp.area }
            }
            ShapePath { fillColor: "transparent"; strokeColor: sp.col; strokeWidth: 1.6; joinStyle: ShapePath.RoundJoin; PathPolyline { path: sp.line } }
        }
        readonly property var line: {
            const n = vals.length; if (n < 2) return [];
            return vals.map((v, i) => Qt.point(i / (60 - 1) * width + (width - (n - 1) / 59 * width), height - Math.min(1, v / maxv) * (height - 3) - 1.5));
        }
        readonly property var area: line.length ? [Qt.point(line[0].x, height)].concat(line, [Qt.point(line[line.length - 1].x, height)]) : []
    }
    component Card: Rectangle {
        radius: Theme.s(16); color: Theme.surface
    }
    component Bar: Item {
        property real frac: 0
        property color col: Theme.accent
        height: Theme.s(6)
        Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.surface2 }
        Rectangle { width: Math.max(parent.height, parent.width * Math.min(1, parent.frac)); height: parent.height; radius: height / 2; color: parent.col
                    Behavior on width { NumberAnimation { duration: 400 } } }
    }

    PageHeader { id: hd; width: parent.width; title: "PERFORMANCE"; jp: "性"; sub: root.ready ? "up " + root.dur(d.uptime) + " · load " + d.load.map(x => x.toFixed(2)).join(" ") : "reading…"; onBack: Sys.panel = "home" }

    Flickable {
        anchors { top: hd.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.s(14); topMargin: Theme.s(4) }
        contentHeight: col.height; clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col; width: parent.width; spacing: Theme.s(8)

            // CPU
            Card {
                width: parent.width; height: Theme.s(112)
                Row { x: Theme.s(14); y: Theme.s(10); spacing: Theme.s(8)
                    Ico { n: "chip"; color: Theme.accent; font.pixelSize: Theme.s(15) }
                    Lbl { text: "CPU"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                Lbl { anchors { right: parent.right; rightMargin: Theme.s(14); top: parent.top; topMargin: Theme.s(8) }
                      text: root.ready ? Math.round(d.cpu) + "%" : "--"; font.bold: true; font.pixelSize: Theme.fs(20); color: root.heat(d.cpu || 0) }
                Lbl { x: Theme.s(14); y: Theme.s(32); color: Theme.sub; font.pixelSize: Theme.fs(10)
                      text: root.ready ? (d.cores.length + " threads" + (d.cpu_mhz ? " · " + (d.cpu_mhz / 1000).toFixed(2) + " GHz" : "") + (d.cpu_temp ? " · " + Math.round(d.cpu_temp) + "°C" : "")) : "" }
                Spark { x: Theme.s(14); y: Theme.s(52); width: parent.width - Theme.s(28); vals: Sys.cpuHist; col: root.heat(d.cpu || 0) }
                // per-core mini bars
                Row { x: Theme.s(14); y: Theme.s(92); spacing: Theme.s(3)
                    Repeater { model: root.ready ? d.cores : []
                        Rectangle { width: (parent.parent.width - Theme.s(28) - (d.cores.length - 1) * Theme.s(3)) / d.cores.length; height: Theme.s(12); radius: 3; color: Theme.surface2
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * Math.min(1, modelData / 100)); radius: 3; color: root.heat(modelData) } } } }
            }

            // RAM
            Card {
                width: parent.width; height: Theme.s(70)
                Row { x: Theme.s(14); y: Theme.s(10); spacing: Theme.s(8)
                    Ico { n: "dash"; color: Theme.accent; font.pixelSize: Theme.s(15) }
                    Lbl { text: "Memory"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                Lbl { anchors { right: parent.right; rightMargin: Theme.s(14); top: parent.top; topMargin: Theme.s(10) }
                      text: root.ready ? root.gb(d.mem_used) + " / " + root.gb(d.mem_total) + " GB" : "--"; font.bold: true; font.pixelSize: Theme.fs(12) }
                Bar { x: Theme.s(14); y: Theme.s(36); width: parent.width - Theme.s(28); frac: root.ready ? d.mem_used / d.mem_total : 0; col: root.heat(root.ready ? 100 * d.mem_used / d.mem_total : 0) }
                Lbl { x: Theme.s(14); y: Theme.s(48); color: Theme.sub; font.pixelSize: Theme.fs(10)
                      text: root.ready ? (d.swap_total > 0 ? "swap " + root.gb(d.swap_used) + " / " + root.gb(d.swap_total) + " GB" : "no swap") : "" }
            }

            // GPU
            Card {
                visible: root.ready && !!d.gpu
                width: parent.width; height: visible ? Theme.s(128) : 0
                Row { x: Theme.s(14); y: Theme.s(10); spacing: Theme.s(8)
                    Ico { n: "monitor"; color: Theme.accent; font.pixelSize: Theme.s(15) }
                    Lbl { text: "GPU"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                Lbl { anchors { right: parent.right; rightMargin: Theme.s(14); top: parent.top; topMargin: Theme.s(8) }
                      text: d.gpu && d.gpu.util !== null ? Math.round(d.gpu.util) + "%" : "--"; font.bold: true; font.pixelSize: Theme.fs(20); color: root.heat(d.gpu ? d.gpu.util : 0) }
                Lbl { x: Theme.s(14); y: Theme.s(32); width: parent.width - Theme.s(28); color: Theme.sub; font.pixelSize: Theme.fs(10)
                      text: d.gpu ? d.gpu.name.replace("NVIDIA GeForce ", "") + (d.gpu.temp !== null ? " · " + Math.round(d.gpu.temp) + "°C" : "") + (d.gpu.power !== null ? " · " + Math.round(d.gpu.power) + " W" : "") : "" }
                Spark { x: Theme.s(14); y: Theme.s(50); width: parent.width - Theme.s(28); vals: Sys.gpuHist; col: root.heat(d.gpu ? d.gpu.util : 0) }
                Bar { x: Theme.s(14); y: Theme.s(94); width: parent.width - Theme.s(28); frac: d.gpu && d.gpu.mem_total ? d.gpu.mem_used / d.gpu.mem_total : 0 }
                Lbl { x: Theme.s(14); y: Theme.s(105); color: Theme.sub; font.pixelSize: Theme.fs(10)
                      text: d.gpu && d.gpu.mem_total ? "VRAM " + (d.gpu.mem_used / 1024).toFixed(1) + " / " + (d.gpu.mem_total / 1024).toFixed(1) + " GB" : "" }
            }

            // Network + disk
            Card {
                width: parent.width; height: Theme.s(64)
                Row { x: Theme.s(14); y: Theme.s(10); spacing: Theme.s(8)
                    Ico { n: "wifi"; color: Theme.accent; font.pixelSize: Theme.s(15) }
                    Lbl { text: "Network"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                Lbl { x: Theme.s(14); y: Theme.s(36); font.pixelSize: Theme.fs(12); font.bold: true
                      text: root.ready ? "↓ " + root.rate(d.net_down) + "     ↑ " + root.rate(d.net_up) : "" }
                Spark { anchors { right: parent.right; rightMargin: Theme.s(14); top: parent.top; topMargin: Theme.s(14) } width: Theme.s(130); height: Theme.s(36)
                        vals: Sys.netHist; maxv: Math.max(1048576, Math.max.apply(null, Sys.netHist.concat([1]))); col: Theme.good }
            }
            Card {
                width: parent.width; height: Theme.s(28) + (root.ready ? d.disks.length : 1) * Theme.s(34)
                Row { x: Theme.s(14); y: Theme.s(8); spacing: Theme.s(8)
                    Ico { n: "folder"; color: Theme.accent; font.pixelSize: Theme.s(15) }
                    Lbl { text: "Storage"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                Column { x: Theme.s(14); y: Theme.s(34); width: parent.width - Theme.s(28); spacing: Theme.s(6)
                    Repeater { model: root.ready ? d.disks : []
                        Item { width: parent.width; height: Theme.s(28)
                            Lbl { text: modelData.path; font.pixelSize: Theme.fs(11); font.bold: true }
                            Lbl { anchors.right: parent.right; text: root.gb(modelData.used) + " / " + root.gb(modelData.total) + " GB"; color: Theme.sub; font.pixelSize: Theme.fs(10) }
                            Bar { y: Theme.s(18); width: parent.width; frac: modelData.used / modelData.total; col: root.heat(100 * modelData.used / modelData.total) } } } }
            }

            // top processes
            Card {
                width: parent.width; height: Theme.s(34) + (root.ready ? d.top.length : 0) * Theme.s(26) + Theme.s(8)
                Row { x: Theme.s(14); y: Theme.s(8); spacing: Theme.s(8)
                    Ico { n: "dash"; color: Theme.accent; font.pixelSize: Theme.s(15) }
                    Lbl { text: "Top processes"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                Column { x: Theme.s(14); y: Theme.s(34); width: parent.width - Theme.s(28)
                    Repeater { model: root.ready ? d.top : []
                        Item { width: parent.width; height: Theme.s(26)
                            Lbl { width: parent.width - Theme.s(120); anchors.verticalCenter: parent.verticalCenter; text: modelData.name; font.pixelSize: Theme.fs(11) }
                            Lbl { x: parent.width - Theme.s(115); width: Theme.s(55); horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                                  text: modelData.cpu.toFixed(1) + "%"; font.bold: true; font.pixelSize: Theme.fs(11); color: root.heat(modelData.cpu) }
                            Lbl { x: parent.width - Theme.s(55); width: Theme.s(55); horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                                  text: root.gb(modelData.mem) + " GB"; color: Theme.sub; font.pixelSize: Theme.fs(10) } } } }
            }
        }
    }
}
