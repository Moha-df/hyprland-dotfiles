pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/quickshell/island"

    // ---- persisted settings (edited from the Appearance panel) ----
    property alias hour24: ad.hour24
    property alias clockSeconds: ad.clockSeconds
    property alias glyphs: ad.glyphs
    property alias visualizer: ad.visualizer
    property alias mode: ad.mode
    property alias manualAccent: ad.accent
    property alias wallDir: ad.wallDir
    property alias uiScale: ad.uiScale
    property alias barGap: ad.barGap
    property alias fontFamily: ad.font
    property alias fontDelta: ad.fontSize
    property alias monitor: ad.monitor
    property alias currentWall: ad.currentWall

    FileView {
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: ad
            property bool hour24: true
            property bool clockSeconds: false
            property bool glyphs: true
            property bool visualizer: true
            property string mode: "manual"      // light | dark | dynamic | manual
            property string accent: "#d9c64c"
            property string wallDir: root.home + "/Pictures/wallpapers"
            property real uiScale: 1.0
            property int barGap: 0
            property string font: "Open Sans"
            property int fontSize: 0
            property string monitor: "DP-3"
            property string currentWall: ""
        }
    }

    // ---- dynamic accent: average colour of the current wallpaper ----
    property color dynAccent: "#d9c64c"
    Process {
        id: dyn
        running: ad.mode === "dynamic" && ad.currentWall !== ""
        command: ["magick", ad.currentWall + "[0]", "-resize", "64x64!", "-modulate", "100,300", "-resize", "1x1", "-format", "%[hex:p{0,0}]", "info:"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim().slice(0, 6);
                if (t.length === 6) {
                    const c = Qt.color("#" + t);
                    root.dynAccent = Qt.hsla(c.hslHue, Math.max(0.55, c.hslSaturation), 0.64, 1);
                }
            }
        }
    }
    onCurrentWallChanged: if (mode === "dynamic") { dyn.running = false; dyn.running = true }
    onModeChanged: if (mode === "dynamic") { dyn.running = false; dyn.running = true }

    // ---- palette ----
    readonly property bool light: mode === "light"
    readonly property color accent: mode === "dynamic" ? dynAccent : Qt.color(manualAccent)
    readonly property color onAccent: accent.hslLightness > 0.55 ? "#17170f" : "#ffffff"
    readonly property color bg: light ? "#f4f2ec" : "#151515"
    readonly property color surface: light ? "#e7e4db" : "#232323"
    readonly property color surface2: light ? "#d9d6cb" : "#2e2e2e"
    readonly property color border: light ? "#20000000" : "#22ffffff"
    readonly property color text: light ? "#1b1b1b" : "#f3f3f3"
    readonly property color sub: light ? "#6e6b62" : "#8e8e8e"
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    readonly property color danger: "#ec5f6a"
    readonly property color good: "#7bd88f"

    // ---- metrics / fonts ----
    function s(n) { return Math.round(n * uiScale) }
    function fs(n) { return Math.max(8, Math.round((n + fontDelta) * uiScale)) }
    readonly property string font: fontFamily
    readonly property string iconFont: "0xProto Nerd Font"
    readonly property int gap: 6 + barGap

    readonly property var icons: ({
        music: 0xF075A, mic: 0xF036C, micoff: 0xF036D, head: 0xF02CB, headoff: 0xF07CE, discord: 0xF066F,
        wifi: 0xF05A9, bt: 0xF00AF, apps: 0xF003B, image: 0xF02E9, clip: 0xF0147, moon: 0xF0594,
        vol: 0xF057E, volmute: 0xF0581, rec: 0xF044A, cam: 0xF0100, cog: 0xF0493, power: 0xF0425,
        user: 0xF0004, dnd: 0xF009B, back: 0xF0141, next: 0xF0142, down: 0xF0140, close: 0xF0156,
        play: 0xF040A, pause: 0xF03E4, skipn: 0xF04AD, skipp: 0xF04AE, monitor: 0xF0379, window: 0xF08C6,
        area: 0xF0489, folder: 0xF024B, trash: 0xF01B4, palette: 0xF03D8, search: 0xF0349, sun: 0xF05A8,
        cloud: 0xF0590, rain: 0xF0597, cal: 0xF00ED, lock: 0xF033E, logout: 0xF0343, restart: 0xF0709,
        sleep: 0xF04B2, stop: 0xF04DB, refresh: 0xF0450, dash: 0xF056E, drop: 0xF058C, dot: 0xF0765, star: 0xF04CE, file: 0xF0214
    })
    function glyph(n) { return icons[n] ? String.fromCodePoint(icons[n]) : "?" }
}
