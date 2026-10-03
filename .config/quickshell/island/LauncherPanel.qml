import QtQuick
import Quickshell
import Quickshell.Io

FocusScope {
    id: root
    focus: true
    NumberAnimation on opacity { from: 0; to: 1; duration: 250 }

    Component.onCompleted: focusTimer.start()
    Timer { id: focusTimer; interval: 120; repeat: true; property int n: 0
            onTriggered: { input.forceActiveFocus(); if (input.activeFocus || ++n > 15) stop() } }

    property string tab: "apps"
    onTabChanged: { lv.currentIndex = 0; if (tab === "files") deb.restart() }
    property string query: ""
    property var fileResults: []

    readonly property var apps: {
        const q = query.toLowerCase().trim();
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const u = Sys.usage;
        const list = q === "" ? all : all.filter(a => (a.name + " " + (a.genericName || "") + " " + (a.comment || "")).toLowerCase().includes(q));
        const score = a => {
            let sc = 0;
            const n = a.name.toLowerCase();
            if (q !== "") sc += n === q ? 3e15 : n.startsWith(q) ? 2e15 : n.includes(q) ? 1e15 : 0;
            return sc + ((u[a.id] || {}).last || 0);
        };
        return list.sort((a, b) => score(b) - score(a) || a.name.localeCompare(b.name));
    }
    readonly property var results: tab === "apps" ? apps : fileResults

    Timer { id: deb; interval: 180; onTriggered: { fproc.running = false; if (root.query.trim().length > 1) fproc.running = true; else root.fileResults = [] } }
    Process {
        id: fproc
        command: ["sh", "-c", 'fd -i -H -I -E .git -E .wine -E .var -E .rustup -E .cargo -E .npm -E .steam --max-depth 7 --max-results 80 -E node_modules -E .cache -E .local/share/Steam -- "$1" "$HOME" 2>/dev/null', "sh", root.query.trim()]
        stdout: StdioCollector {
            onStreamFinished: {
                const q = root.query.trim().toLowerCase();
                const base = p => p.replace(/\/$/, "").split("/").pop().toLowerCase();
                const rank = p => (base(p) === q ? 0 : base(p).startsWith(q) ? 1 : 2) * 1000 + p.length;
                root.fileResults = text.split("\n").filter(l => l).sort((a, b) => rank(a) - rank(b));
            }
        }
    }

    function launch(i) {
        const r = results[i];
        if (!r) return;
        if (tab === "apps") { Sys.markUsed(r.id); r.execute() } else Quickshell.execDetached([r.endsWith("/") ? "nemo" : "xdg-open", r]);
        Sys.closeAll();
    }

    // tabs
    Row {
        anchors.horizontalCenter: parent.horizontalCenter; y: Theme.s(12); spacing: Theme.s(8)
        Repeater {
            model: [["apps", "Apps"], ["files", "Files"]]
            Btn {
                width: Theme.s(78); height: Theme.s(26); radius: height / 2
                active: root.tab === modelData[0]; onClicked: { root.tab = modelData[0]; input.forceActiveFocus() }
                Lbl { anchors.centerIn: parent; text: modelData[1]; font.bold: true; font.pixelSize: Theme.fs(12); color: parent.active ? Theme.accent : Theme.sub }
            }
        }
    }
    // search
    Item {
        x: Theme.s(22); y: Theme.s(52); width: parent.width - Theme.s(44); height: Theme.s(30)
        Lbl { id: gl; text: Theme.glyphs ? "探" : ""; color: Theme.sub; font.pixelSize: Theme.fs(18); anchors.verticalCenter: parent.verticalCenter; visible: Theme.glyphs }
        Ico { n: "search"; visible: !Theme.glyphs; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
        TextInput {
            id: input
            anchors { left: parent.left; leftMargin: Theme.s(30); right: cnt.left; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            color: Theme.text; selectionColor: Theme.accent; selectedTextColor: Theme.onAccent
            font.family: Theme.font; font.pixelSize: Theme.fs(15)
            focus: true
            onTextChanged: { root.query = text; lv.currentIndex = 0; if (root.tab === "files") deb.restart() }
            Keys.onDownPressed: lv.incrementCurrentIndex()
            Keys.onUpPressed: lv.decrementCurrentIndex()
            Keys.onReturnPressed: root.launch(lv.currentIndex)
            Keys.onEscapePressed: Sys.closeAll()
            Keys.onPressed: e => {
                if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_1) { root.tab = "apps"; e.accepted = true }
                if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_2) { root.tab = "files"; deb.restart(); e.accepted = true }
            }
            Lbl { visible: input.text === ""; text: root.tab === "apps" ? "Search apps" : "Search files"; color: Theme.sub; font.pixelSize: Theme.fs(15) }
        }
        Lbl { id: cnt; anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              text: root.results.length + (root.tab === "apps" ? " / " + DesktopEntries.applications.values.length : ""); color: Theme.sub; font.pixelSize: Theme.fs(11) }
    }
    Rectangle { x: Theme.s(22); y: Theme.s(86); width: parent.width - Theme.s(44); height: 1; color: Theme.border }

    ListView {
        id: lv
        x: Theme.s(14); y: Theme.s(94); width: parent.width - Theme.s(28); height: parent.height - Theme.s(104)
        clip: true; model: root.results; currentIndex: 0; spacing: Theme.s(2)
        highlightMoveDuration: 100
        delegate: Rectangle {
            width: lv.width; height: Theme.s(50); radius: Theme.s(12)
            color: ListView.isCurrentItem ? Theme.surface : ma.containsMouse ? Theme.surface : "transparent"
            border.color: ListView.isCurrentItem ? Theme.border : "transparent"
            readonly property bool isApp: root.tab === "apps"
            Image {
                visible: isApp; x: Theme.s(10); anchors.verticalCenter: parent.verticalCenter
                width: Theme.s(30); height: width; sourceSize: Qt.size(64, 64)
                source: isApp ? Quickshell.iconPath(modelData.icon, true) : ""
            }
            Ico { visible: !isApp; x: Theme.s(10); width: Theme.s(30); anchors.verticalCenter: parent.verticalCenter
                  n: !isApp && modelData.endsWith("/") ? "folder" : "file"; color: Theme.accent }
            Column {
                x: Theme.s(52); anchors.verticalCenter: parent.verticalCenter; width: parent.width - Theme.s(64)
                Lbl { width: parent.width; text: isApp ? modelData.name : modelData.replace(/\/$/, "").split("/").pop(); font.pixelSize: Theme.fs(14); font.bold: true }
                Lbl { width: parent.width; text: isApp ? (modelData.comment || modelData.genericName || "") : modelData.replace(Theme.home, "~"); color: Theme.sub; font.pixelSize: Theme.fs(11) }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(index); onEntered: lv.currentIndex = index }
        }
    }
}
