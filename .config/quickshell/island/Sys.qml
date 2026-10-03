pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Singleton {
    id: root

    // ================= ui state =================
    property string island: "idle"   // idle clock calendar wall launcher mixer toast
    property string panel: ""        // "" home record capture appearance discord power
    property bool mediaOpen: false
    property real homeH: 600   // unscaled height of the control-center home page, set by HomePage
    property bool barShown: false   // hidden by default, toggled with the keybind
    readonly property bool anyOpen: (island !== "idle" && island !== "toast") || panel !== "" || mediaOpen

    function setIsland(m) { toastTimer.stop(); island = (island === m ? "idle" : m); mediaOpen = false }
    function togglePanel() { panel = panel === "" ? "home" : ""; mediaOpen = false }
    function closeAll() { toastTimer.stop(); island = "idle"; panel = ""; mediaOpen = false }

    // ================= app usage (launcher ordering) =================
    property var usage: ({})
    FileView {
        id: usageFile
        path: Theme.dir + "/usage.json"
        onLoaded: { try { Sys.usage = JSON.parse(text()) } catch (e) {} }
    }
    function markUsed(id) {
        const u = Object.assign({}, usage);
        const o = u[id] || { count: 0, last: 0 };
        u[id] = { count: o.count + 1, last: Date.now() };
        usage = u;
        usageFile.setText(JSON.stringify(u));
    }

    // ================= clipboard history (text) =================
    property var clips: []
    FileView {
        id: clipFile
        path: Theme.dir + "/clipboard.json"
        onLoaded: { try { Sys.clips = JSON.parse(text()) } catch (e) {} }
    }
    function saveClips() { clipFile.setText(JSON.stringify(clips)) }
    function addClip(t) {
        if (!t || !t.trim() || t.length > 20000) return;
        const l = clips.filter(c => c !== t);
        l.unshift(t);
        clips = l.slice(0, 60);
        saveClips();
    }
    function removeClip(t) { clips = clips.filter(c => c !== t); saveClips() }
    function clearClips() { clips = []; saveClips() }
    function copyClip(t) { Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "sh", t]) }
    Process {
        running: true
        command: ["wl-paste", "-t", "text", "--watch", "sh", "-c", "jq -Rsc ."]
        stdout: SplitParser { onRead: line => { try { Sys.addClip(JSON.parse(line)) } catch (e) {} } }
    }

    // ================= clock =================
    SystemClock { id: clk; precision: SystemClock.Seconds }
    readonly property date now: clk.date
    readonly property string timeText: Qt.formatDateTime(now, Theme.hour24
        ? (Theme.clockSeconds ? "HH:mm:ss" : "HH:mm")
        : (Theme.clockSeconds ? "h:mm:ss AP" : "h:mm AP"))

    // ================= toast / notifications =================
    property var toastData: ({ app: "", title: "", body: "", notif: null })
    function toast(app, title, body, notif) {
        if (island !== "idle" && island !== "toast") return;
        toastData = { app: app, title: title, body: body, notif: notif || null };
        island = "toast";
        toastTimer.restart();
    }
    Timer { id: toastTimer; interval: 4500; onTriggered: if (root.island === "toast") root.island = "idle" }

    property bool dnd: false
    property alias history: history
    ListModel { id: history }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: n => {
            n.tracked = true;
            history.insert(0, { app: n.appName, summary: n.summary, body: n.body, time: Qt.formatDateTime(new Date(), "HH:mm") });
            while (history.count > 30) history.remove(history.count - 1);
            if (!root.dnd) root.toast(n.appName, n.summary, n.body, n);
        }
    }

    // ================= audio (pactl) =================
    property int vol: 0
    property bool volMuted: false
    property int micVol: 0
    property bool micMuted: false
    property string sinkName: ""
    property string sourceName: ""
    property string sinkDesc: ""
    property string sourceDesc: ""

    function setVol(v) { vol = Math.round(v); Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", vol + "%"]) }
    function setMic(v) { micVol = Math.round(v); Quickshell.execDetached(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", micVol + "%"]) }
    function toggleVolMute() { volMuted = !volMuted; Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]) }
    function toggleMicMute() { micMuted = !micMuted; Quickshell.execDetached(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]) }

    Process {
        id: audioProc
        command: [Theme.dir + "/scripts/audio.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                const pct = s => { const m = /(\d+)%/.exec(s || ""); return m ? parseInt(m[1]) : 0 };
                root.vol = pct(l[0]);
                root.volMuted = /yes/.test(l[1] || "");
                root.micVol = pct(l[2]);
                root.micMuted = /yes/.test(l[3] || "");
                root.sinkName = l[4] || "";
                root.sourceName = l[5] || "";
                root.sinkDesc = l[6] || l[4] || "";
                root.sourceDesc = l[7] || l[5] || "";
            }
        }
    }
    Timer { id: audioDebounce; interval: 120; onTriggered: { audioProc.running = true; appsProc.running = true } }

    // ---- per-application volume (pulse sink inputs) ----
    property var apps: []
    function setAppVol(id, v) {
        apps = apps.map(a => a.id === id ? Object.assign({}, a, { vol: Math.round(v) }) : a);
        Quickshell.execDetached(["pactl", "set-sink-input-volume", String(id), Math.round(v) + "%"]);
    }
    function toggleAppMute(id) {
        apps = apps.map(a => a.id === id ? Object.assign({}, a, { mute: !a.mute }) : a);
        Quickshell.execDetached(["pactl", "set-sink-input-mute", String(id), "toggle"]);
    }
    Process {
        id: appsProc
        command: ["pactl", "--format=json", "list", "sink-inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = JSON.parse(text).map(i => {
                        const p = i.properties || {};
                        const ch = Object.values(i.volume || {})[0];
                        return {
                            id: i.index,
                            mute: !!i.mute,
                            vol: ch ? parseInt(ch.value_percent) : 0,
                            name: p["application.name"] || p["application.process.binary"] || "Unknown",
                            media: p["media.name"] || "",
                            icon: p["application.icon_name"] || (p["application.process.binary"] || "").toLowerCase()
                        };
                    });
                } catch (e) {}
            }
        }
    }
    Timer { interval: 2000; running: root.island === "mixer"; repeat: true; triggeredOnStart: true; onTriggered: appsProc.running = true }
    Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser { onRead: line => { if (/on (sink|source|sink-input) #|on server/.test(line)) audioDebounce.restart() } }
    }
    Component.onCompleted: { audioProc.running = true; netProc.running = true; weatherProc.running = true }

    // ================= network =================
    property string netName: ""
    property string netDev: ""
    property string netType: ""
    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = false;
                for (const ln of text.split("\n")) {
                    const p = ln.split(":");
                    if ((p[0] === "wifi" || p[0] === "ethernet") && p[1] === "connected") {
                        root.netType = p[0]; root.netName = p[2]; root.netDev = p[3]; found = true; break;
                    }
                }
                if (!found) { root.netName = ""; root.netDev = ""; root.netType = "" }
            }
        }
    }
    Timer { interval: 8000; running: true; repeat: true; onTriggered: netProc.running = true }

    // ================= weather =================
    property var weather: null
    Process {
        id: weatherProc
        command: ["curl", "-s", "-m", "10", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.weather = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: weatherProc.running = true }

    // ================= toggles =================
    property bool night: false
    function toggleNight() {
        night = !night;
        if (night) Quickshell.execDetached(["gammastep", "-O", "3800"]);
        else Quickshell.execDetached(["pkill", "-x", "gammastep"]);
    }

    // ================= keyboard layout =================
    property string kbName: ""
    readonly property string kbLabel: /french|fr/i.test(kbName) ? "AZERTY" : kbName ? "QWERTY" : ""
    Process {
        id: kbProc
        running: true
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[]|select(.main)|.active_keymap'"]
        stdout: StdioCollector { onStreamFinished: root.kbName = text.trim() }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name === "activelayout") root.kbName = e.data.split(",").slice(1).join(",");
        }
    }

    // ================= media =================
    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }

    // ================= recording =================
    property bool recording: false
    property string recMode: "area"      // area | full
    property string recAudio: "desktop"  // desktop | mic | none
    property int recSecs: 0
    property string recFile: ""
    property string recGeo: ""
    property double recCutoff: 0
    readonly property string recDir: Theme.home + "/Videos/Recordings"
    readonly property string recTime: {
        const m = Math.floor(recSecs / 60), s = recSecs % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function startRecording() {
        if (recording) return;
        if (recMode === "area") slurpProc.running = true;
        else launchRec("");
    }
    function stopRecording() {
        Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]);
        killTimer.restart();
    }
    function toggleRecording() {
        if (slurpProc.running) { Quickshell.execDetached(["pkill", "-x", "slurp"]); return }
        recording ? stopRecording() : startRecording();
    }
    function launchRec(geo) {
        recGeo = geo;
        recFile = recDir + "/recording_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
        const dev = recAudio === "desktop" ? sinkName + ".monitor" : recAudio === "mic" ? sourceName : "-";
        recProc.command = [Theme.dir + "/scripts/rec.sh", recFile, geo || "-", dev || "-"];
        recProc.running = true;
    }
    // wf-recorder normally stops on SIGINT; if it is still alive after 4s, escalate.
    Timer {
        id: killTimer
        interval: 4000
        onTriggered: {
            if (root.recording) {
                Quickshell.execDetached(["pkill", "-TERM", "-x", "wf-recorder"]);
                forceTimer.restart();
            }
        }
    }
    Timer {
        id: forceTimer
        interval: 2000
        onTriggered: if (root.recording) { Quickshell.execDetached(["pkill", "-KILL", "-x", "wf-recorder"]); root.recording = false }
    }
    Process {
        id: slurpProc
        command: ["slurp"]
        stdout: StdioCollector { onStreamFinished: { const g = text.trim(); if (g) root.launchRec(g) } }
    }
    Process {
        id: recProc
        onStarted: { root.recSecs = 0; root.recording = true }
        onExited: (code, status) => {
            killTimer.stop(); forceTimer.stop();
            root.recording = false;
            if (code === 0) root.toast("recorder", "Recording saved", root.recFile.split("/").pop());
            else root.toast("recorder", "Recording failed", "wf-recorder exited with code " + code);
        }
    }
    Timer { interval: 1000; running: root.recording; repeat: true; onTriggered: root.recSecs++ }

    FolderListModel {
        id: recFolder
        folder: "file://" + root.recDir
        nameFilters: ["*.mp4"]
        sortField: FolderListModel.Time
        sortReversed: false
        showDirs: false
    }
    property alias recents: recFolder

    // ================= screenshot =================
    property string shotMode: "area"
    function takeShot() {
        shotProc.command = [Theme.dir + "/scripts/shot.sh", shotMode];
        closeAll();
        shotDelay.restart();
    }
    Timer { id: shotDelay; interval: 350; onTriggered: shotProc.running = true }
    Process {
        id: shotProc
        stdout: StdioCollector {
            onStreamFinished: { const p = text.trim(); if (p) root.toast("grim", "Screenshot saved", p.split("/").pop() + " · copied") }
        }
    }

    // ================= wallpaper =================
    function applyWall(path) {
        const live = /\.(mp4|webm|mkv)$/i.test(path);
        Quickshell.execDetached(["pkill", "-x", "mpvpaper"]);
        if (live) {
            Quickshell.execDetached(["sh", "-c", 'mpvpaper -o "no-audio loop" "*" "$1"', "sh", path]);
        } else {
            Quickshell.execDetached(["awww", "img", path, "--transition-type", "grow", "--transition-pos", "0.5,0.05",
                                     "--transition-duration", "1.4", "--transition-fps", "144"]);
        }
        Theme.currentWall = path;
        toast("notify-send", "Theme Applied", "Wallpaper set to " + path.split("/").pop());
    }

    // ================= discord =================
    property var dc: ({ connected: false })
    readonly property string dcState: Quickshell.env("XDG_RUNTIME_DIR") + "/waybar-discord-state.json"
    function dcSend(word) { Quickshell.execDetached(["python3", Theme.dir + "/scripts/discord_rpc.py", word]) }
    Process {
        running: true
        command: ["python3", "-u", Theme.dir + "/scripts/discord_rpc.py"]
        stdout: SplitParser { onRead: () => {} }
    }
    FileView {
        id: dcFile
        path: root.dcState
        onLoaded: { try { root.dc = JSON.parse(text()) } catch (e) {} }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: dcFile.reload() }
    readonly property bool inVoice: !!(dc.connected && dc.channel)
    readonly property bool dcSpeaking: inVoice && dc.channel.members.some(m => m.speaking)
}
