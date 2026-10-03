import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: outer
    readonly property bool open: Sys.mediaOpen
    readonly property real fullW: Theme.s(360)
    readonly property real fullH: Theme.s(236)

    // closed = the 34px round music button, open = the player: same shape, it just grows
    width: open ? fullW : Theme.s(34)
    height: open ? fullH : Theme.s(34)
    radius: Math.min(height / 2, Theme.s(26))
    color: !open && hover.containsMouse ? Theme.surface : Theme.bg
    border.color: "transparent"   // the visible border is the overlay below (children would paint over this one)

    visible: opacity > 0
    opacity: open || Sys.barShown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 220 } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }

    // ---- closed state: icon / mini visualizer ----
    Item {
        width: Theme.s(34); height: Theme.s(34)
        opacity: outer.open ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: outer.open ? 80 : 260 } }
        Ico { anchors.centerIn: parent; n: "music"; visible: !(Theme.visualizer && root.playing); font.pixelSize: Theme.s(15)
              color: Sys.player ? Theme.accent : Theme.sub }
        Row {
            anchors.centerIn: parent; spacing: 2; visible: Theme.visualizer && root.playing
            Repeater {
                model: 4
                Rectangle {
                    width: 3; radius: 1.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    SequentialAnimation on height {
                        running: parent.visible && outer.visible; loops: Animation.Infinite
                        NumberAnimation { to: 6 + (index * 5 % 11); duration: 260 + index * 70 }
                        NumberAnimation { to: 18 - (index * 3 % 9); duration: 300 + index * 50 }
                    }
                }
            }
        }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        enabled: !outer.open
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { Sys.closeAll(); Sys.mediaOpen = true }
    }

    // ---- open state: fixed-size player, revealed by the growing shape ----
    // QML `clip` ignores the corner radius, so the content is masked with a rounded rectangle instead.
    Item {
        id: clipper
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: roundMask
        }
        Item {
            id: root
            width: outer.fullW; height: outer.fullH
            opacity: outer.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: outer.open ? 300 : 90 } }
            readonly property var p: Sys.player
        readonly property bool playing: !!(p && p.isPlaying)
        function fmt(sec) {
            sec = Math.max(0, Math.floor(sec || 0));
            const m = Math.floor(sec / 60), s = sec % 60;
            return m + ":" + (s < 10 ? "0" : "") + s;
        }


            // ---- blurred cover as ambient background ----
            Image {
                id: bgArt
                anchors.fill: parent
                source: root.p ? root.p.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: bgArt
                visible: bgArt.status === Image.Ready
                blurEnabled: true; blur: 1.0; blurMax: 64
                saturation: 0.4
                opacity: 0.5
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.55) }
                    GradientStop { position: 1.0; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92) }
                }
            }

            // ---- header: player chip + now playing ----
            Rectangle {
                x: Theme.s(18); y: Theme.s(14)
                height: Theme.s(22); width: chipRow.width + Theme.s(20); radius: height / 2
                color: Theme.accentSoft
                Row {
                    id: chipRow; anchors.centerIn: parent; spacing: Theme.s(6)
                    Ico { n: "music"; font.pixelSize: Theme.s(11); color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Lbl { text: root.p ? root.p.identity : "No player"; font.pixelSize: Theme.fs(10); font.bold: true; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Sys.cyclePlayer() }
            }
            Lbl {
                anchors { right: parent.right; rightMargin: Theme.s(18); top: parent.top; topMargin: Theme.s(14) }
                height: Theme.s(22)
                text: root.playing ? "NOW PLAYING" : "PAUSED"
                font.pixelSize: Theme.fs(9); font.bold: true; font.letterSpacing: 1.5
                color: root.playing ? Theme.accent : Theme.sub
            }

            // ---- liquid cover ----
            Item {
                id: cover
                x: Theme.s(14); y: Theme.s(44); width: Theme.s(92); height: width

                readonly property int n: 96
                property var pts: []
                property var sm: []
                property real energy: 0
                readonly property real cx: width / 2
                readonly property real base: width * 0.37

                FrameAnimation {
                    running: outer.open
                    onTriggered: {
                        const bars = Sys.bars, nb = Math.max(bars.length, 1);
                        const t = Date.now() / 1000;
                        if (cover.sm.length !== nb) cover.sm = new Array(nb).fill(0);
                        let e = 0;
                        for (let i = 0; i < nb; i++) {
                            const target = bars.length ? Math.min(1, bars[i] * 1.15) : 0;
                            const cur = cover.sm[i];
                            cover.sm[i] = target > cur ? cur + (target - cur) * 0.55 : cur + (target - cur) * 0.12;
                            e += cover.sm[i];
                        }
                        cover.energy = cover.energy + ((e / nb) - cover.energy) * 0.2;
                        const out = [];
                        for (let k = 0; k <= cover.n; k++) {
                            const a = (k % cover.n) / cover.n * Math.PI * 2;
                            const u = a / Math.PI, m = u <= 1 ? u : 2 - u;
                            const pos = m * (nb - 1), i0 = Math.floor(pos), f = pos - i0;
                            const v = cover.sm[i0] * (1 - f) + cover.sm[Math.min(i0 + 1, nb - 1)] * f;
                            const wob = (Math.sin(a * 3 + t * 2.1) + Math.sin(a * 5 - t * 1.6) * 0.6) * (0.012 + cover.energy * 0.05) * cover.width;
                            const r = cover.base + v * cover.width * 0.13 + wob + (root.playing ? 0 : Math.sin(a * 2 + t) * 0.6);
                            out.push(Qt.point(cover.cx + Math.cos(a) * r, cover.cx + Math.sin(a) * r));
                        }
                        cover.pts = out;
                    }
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: root.p ? root.p.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    layer.enabled: true
                }
                Shape {
                    id: blobMask
                    anchors.fill: parent; visible: false; layer.enabled: true; layer.samples: 4
                    ShapePath { fillColor: "white"; strokeColor: "transparent"; PathPolyline { path: cover.pts } }
                }
                MultiEffect {
                    anchors.fill: parent; source: art; maskEnabled: true; maskSource: blobMask
                    maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
                    visible: art.status === Image.Ready
                }
                Shape {
                    anchors.fill: parent; visible: art.status !== Image.Ready; layer.enabled: true; layer.samples: 4
                    ShapePath { fillColor: Theme.surface; strokeColor: "transparent"; PathPolyline { path: cover.pts } }
                }
                Ico { anchors.centerIn: parent; n: "music"; color: Theme.sub; visible: art.status !== Image.Ready; font.pixelSize: Theme.s(24) }
                Shape {
                    anchors.fill: parent; layer.enabled: true; layer.samples: 4
                    ShapePath { fillColor: "transparent"; strokeColor: Theme.accent; strokeWidth: 2; PathPolyline { path: cover.pts } }
                }
            }

            // ---- title / artist / album ----
            Column {
                x: Theme.s(118); y: Theme.s(52); width: parent.width - Theme.s(118) - Theme.s(18); spacing: Theme.s(2)
                Lbl { width: parent.width; text: root.p ? (root.p.trackTitle || "Unknown title") : "Nothing playing"; font.bold: true; font.pixelSize: Theme.fs(16) }
                Lbl { width: parent.width; text: root.p ? (root.p.trackArtist || "Unknown artist") : "Start a player"; color: Theme.text; opacity: 0.8; font.pixelSize: Theme.fs(12) }
                Lbl { width: parent.width; visible: !!(root.p && root.p.trackAlbum); text: root.p ? root.p.trackAlbum : ""; color: Theme.sub; font.pixelSize: Theme.fs(10) }
            }

            // ---- progress ----
            Item {
                x: Theme.s(18); y: Theme.s(146); width: parent.width - Theme.s(36); height: Theme.s(30)
                Slid {
                    id: seek
                    width: parent.width; y: 0
                    to: root.p && root.p.length > 0 ? root.p.length : 1
                    value: root.p ? root.p.position : 0
                    enabled: !!(root.p && root.p.canSeek)
                    onMoved: v => { if (root.p && root.p.canSeek) root.p.position = v }
                }
                Lbl { y: Theme.s(16); text: root.fmt(root.p ? root.p.position : 0); color: Theme.sub; font.pixelSize: Theme.fs(10) }
                Lbl { y: Theme.s(16); anchors.right: parent.right; text: root.fmt(root.p ? root.p.length : 0); color: Theme.sub; font.pixelSize: Theme.fs(10) }
            }

            // ---- controls ----
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.s(184) }
                spacing: Theme.s(14)
                Btn {
                    width: Theme.s(30); height: width; radius: width / 2; base: "transparent"
                    active: !!(root.p && root.p.shuffle); visible: !!(root.p && root.p.shuffleSupported)
                    onClicked: root.p.shuffle = !root.p.shuffle
                    Ico { anchors.centerIn: parent; n: "refresh"; font.pixelSize: Theme.s(14); color: parent.active ? Theme.accent : Theme.sub }
                }
                Btn { width: Theme.s(36); height: width; radius: width / 2; onClicked: root.p && root.p.canGoPrevious && root.p.previous()
                      Ico { anchors.centerIn: parent; n: "skipp"; font.pixelSize: Theme.s(16) } }
                Btn {
                    width: Theme.s(46); height: width; radius: width / 2; base: Theme.accent; activeColor: Theme.accent
                    onClicked: root.p && root.p.togglePlaying()
                    Ico { anchors.centerIn: parent; n: root.playing ? "pause" : "play"; font.pixelSize: Theme.s(20); color: Theme.onAccent }
                }
                Btn { width: Theme.s(36); height: width; radius: width / 2; onClicked: root.p && root.p.canGoNext && root.p.next()
                      Ico { anchors.centerIn: parent; n: "skipn"; font.pixelSize: Theme.s(16) } }
                Btn {
                    width: Theme.s(30); height: width; radius: width / 2; base: "transparent"
                    active: !!(root.p && root.p.loopState !== MprisLoopState.None); visible: !!(root.p && root.p.loopSupported)
                    onClicked: root.p.loopState = root.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                               : root.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                    Ico { anchors.centerIn: parent; n: "restart"; font.pixelSize: Theme.s(14); color: parent.active ? Theme.accent : Theme.sub }
                    Lbl { visible: !!(root.p && root.p.loopState === MprisLoopState.Track); text: "1"; font.pixelSize: Theme.fs(8); font.bold: true
                          color: Theme.accent; anchors { right: parent.right; rightMargin: Theme.s(4); top: parent.top; topMargin: Theme.s(2) } }
                }
            }

            Timer { running: root.playing && outer.open; interval: 500; repeat: true; onTriggered: root.p.positionChanged() }
        }
    }
    Rectangle {
        id: roundMask
        anchors.fill: parent
        radius: outer.radius
        visible: false
        layer.enabled: true
        layer.samples: 4
    }

    // border drawn above everything
    Rectangle {
        anchors.fill: parent
        radius: outer.radius
        color: "transparent"
        border.width: outer.open ? 2 : 1
        border.color: outer.open ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.7) : Theme.border
        Behavior on border.width { NumberAnimation { duration: 200 } }
    }
}
