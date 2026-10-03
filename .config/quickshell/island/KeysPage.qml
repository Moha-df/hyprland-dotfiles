import QtQuick

Item {
    id: root
    property string query: ""
    property int editing: -1          // hyprland.conf line being edited, -2 = new bind, -1 = none
    property bool pendingClose: false

    Component.onCompleted: Sys.loadBinds()

    readonly property var filtered: {
        const q = query.toLowerCase().trim();
        if (!q) return Sys.binds;
        return Sys.binds.filter(b => (b.shown + " " + b.key + " " + b.disp + " " + b.arg + " " + b.comment).toLowerCase().includes(q));
    }

    Connections {
        target: Sys
        function onBindsChanged() { if (root.pendingClose && Sys.bindMsg === "") { root.editing = -1; root.pendingClose = false } }
        function onBindMsgChanged() { if (Sys.bindMsg !== "") root.pendingClose = false }
    }

    // friendly text for the action column
    function action(b) {
        if (b.disp === "exec") {
            const m = /ipc call island (\w+)/.exec(b.arg);
            if (m) return "island · " + m[1];
            return b.arg.replace(/^sh -c\s+/, "").replace(/^['"]|['"]$/g, "");
        }
        return b.disp + (b.arg ? " " + b.arg : "");
    }
    function keyName(e) {
        const k = e.key;
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1);
        const map = {};
        map[Qt.Key_Return] = "RETURN"; map[Qt.Key_Enter] = "RETURN"; map[Qt.Key_Escape] = "ESCAPE"; map[Qt.Key_Tab] = "TAB";
        map[Qt.Key_Space] = "SPACE"; map[Qt.Key_Backspace] = "BACKSPACE"; map[Qt.Key_Delete] = "DELETE";
        map[Qt.Key_Left] = "left"; map[Qt.Key_Right] = "right"; map[Qt.Key_Up] = "up"; map[Qt.Key_Down] = "down";
        map[Qt.Key_Print] = "Print"; map[Qt.Key_QuoteLeft] = "grave"; map[Qt.Key_Minus] = "minus"; map[Qt.Key_Equal] = "equal";
        map[Qt.Key_Comma] = "comma"; map[Qt.Key_Period] = "period"; map[Qt.Key_Slash] = "slash"; map[Qt.Key_Semicolon] = "semicolon";
        map[Qt.Key_Apostrophe] = "apostrophe"; map[Qt.Key_BracketLeft] = "bracketleft"; map[Qt.Key_BracketRight] = "bracketright";
        map[Qt.Key_Backslash] = "backslash"; map[Qt.Key_Home] = "Home"; map[Qt.Key_End] = "End"; map[Qt.Key_PageUp] = "Prior"; map[Qt.Key_PageDown] = "Next";
        return map[k] || (e.text || "").toUpperCase();
    }

    PageHeader { id: hd; width: parent.width; title: "SHORTCUTS"; jp: "鍵"; sub: Sys.binds.length + " binds · click one to edit"; onBack: Sys.panel = "home" }
    Btn {
        anchors { right: parent.right; rightMargin: Theme.s(16); verticalCenter: hd.verticalCenter }
        width: addRow.width + Theme.s(22); height: Theme.s(28); radius: height / 2
        base: Theme.accent; activeColor: Theme.accent
        onClicked: { root.editing = root.editing === -2 ? -1 : -2; Sys.bindMsg = "" }
        Row { id: addRow; anchors.centerIn: parent; spacing: Theme.s(5)
            Ico { n: "plus"; color: Theme.onAccent; font.pixelSize: Theme.s(13) }
            Lbl { text: "New"; color: Theme.onAccent; font.bold: true; font.pixelSize: Theme.fs(11) } }
    }

    // search
    Rectangle {
        id: search
        x: Theme.s(14); y: Theme.s(52); width: parent.width - Theme.s(28); height: Theme.s(32); radius: Theme.s(12); color: Theme.surface
        Ico { n: "search"; x: Theme.s(10); anchors.verticalCenter: parent.verticalCenter; color: Theme.sub; font.pixelSize: Theme.s(14) }
        TextInput {
            anchors { fill: parent; leftMargin: Theme.s(34); rightMargin: Theme.s(10) }
            verticalAlignment: TextInput.AlignVCenter; clip: true
            color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fs(13); selectByMouse: true
            onTextChanged: root.query = text
            Lbl { visible: parent.text === ""; text: "Filter shortcuts"; color: Theme.sub; font.pixelSize: Theme.fs(13); anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---- editor (shared by "edit" and "new") ----
    component Editor: Rectangle {
        id: ed
        property var b: ({ flag: "bind", mods: "$mainMod", key: "", disp: "exec", arg: "", line: -2 })
        property bool armed: false
        width: parent ? parent.width : 0
        height: edCol.height + Theme.s(20)
        radius: Theme.s(14); color: Theme.surface; border.color: Theme.accent; border.width: 1

        Column {
            id: edCol
            x: Theme.s(12); y: Theme.s(10); width: parent.width - Theme.s(24); spacing: Theme.s(8)

            Rectangle {   // press-to-record
                id: rec
                width: parent.width; height: Theme.s(34); radius: Theme.s(10)
                color: recScope.activeFocus ? Theme.accentSoft : Theme.surface2
                border.color: recScope.activeFocus ? Theme.accent : "transparent"
                FocusScope {
                    id: recScope
                    anchors.fill: parent
                    Keys.onPressed: e => {
                        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_AltGr].includes(e.key)) return;
                        const m = [];
                        if (e.modifiers & Qt.MetaModifier) m.push("$mainMod");
                        if (e.modifiers & Qt.ShiftModifier) m.push("SHIFT");
                        if (e.modifiers & Qt.ControlModifier) m.push("CTRL");
                        if (e.modifiers & Qt.AltModifier) m.push("ALT");
                        modsIn.text = m.join(" ");
                        keyIn.text = root.keyName(e);
                        e.accepted = true;
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: recScope.forceActiveFocus() }
                }
                Row { anchors.centerIn: parent; spacing: Theme.s(8)
                    Ico { n: "keyboard"; color: recScope.activeFocus ? Theme.accent : Theme.sub; font.pixelSize: Theme.s(14) }
                    Lbl { text: recScope.activeFocus ? "Press the new key combo…" : "Click here, then press a key combo"
                          color: recScope.activeFocus ? Theme.accent : Theme.sub; font.pixelSize: Theme.fs(11); font.bold: true } }
            }
            Row {
                spacing: Theme.s(8); width: parent.width
                Column { width: (parent.width - Theme.s(8)) * 0.6; spacing: 2
                    Lbl { text: "MODIFIERS"; color: Theme.sub; font.pixelSize: Theme.fs(9); font.bold: true }
                    Rectangle { width: parent.width; height: Theme.s(30); radius: Theme.s(8); color: Theme.bg
                        TextInput { id: modsIn; anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) } verticalAlignment: TextInput.AlignVCenter; clip: true
                                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fs(12); selectByMouse: true; text: ed.b.mods } } }
                Column { width: (parent.width - Theme.s(8)) * 0.4; spacing: 2
                    Lbl { text: "KEY"; color: Theme.sub; font.pixelSize: Theme.fs(9); font.bold: true }
                    Rectangle { width: parent.width; height: Theme.s(30); radius: Theme.s(8); color: Theme.bg
                        TextInput { id: keyIn; anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) } verticalAlignment: TextInput.AlignVCenter; clip: true
                                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fs(12); selectByMouse: true; text: ed.b.key } } }
            }
            Row {
                spacing: Theme.s(8); width: parent.width
                Column { width: (parent.width - Theme.s(8)) * 0.35; spacing: 2
                    Lbl { text: "ACTION"; color: Theme.sub; font.pixelSize: Theme.fs(9); font.bold: true }
                    Rectangle { width: parent.width; height: Theme.s(30); radius: Theme.s(8); color: Theme.bg
                        TextInput { id: dispIn; anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) } verticalAlignment: TextInput.AlignVCenter; clip: true
                                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fs(12); selectByMouse: true; text: ed.b.disp } } }
                Column { width: (parent.width - Theme.s(8)) * 0.65; spacing: 2
                    Lbl { text: "ARGUMENT / COMMAND"; color: Theme.sub; font.pixelSize: Theme.fs(9); font.bold: true }
                    Rectangle { width: parent.width; height: Theme.s(30); radius: Theme.s(8); color: Theme.bg
                        TextInput { id: argIn; anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) } verticalAlignment: TextInput.AlignVCenter; clip: true
                                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fs(12); selectByMouse: true; text: ed.b.arg } } }
            }
            Lbl { visible: Sys.bindMsg !== ""; width: parent.width; text: Sys.bindMsg; color: Theme.danger; font.pixelSize: Theme.fs(10); wrapMode: Text.Wrap; elide: Text.ElideNone }
            Row {
                spacing: Theme.s(8)
                Btn { width: Theme.s(90); height: Theme.s(30); radius: height / 2; base: Theme.accent; activeColor: Theme.accent
                      onClicked: {
                          const flag = ed.b.flag || "bind";
                          root.pendingClose = true;
                          if (ed.b.line === -2) Sys.bindOp(["add", flag, modsIn.text.trim(), keyIn.text.trim(), dispIn.text.trim(), argIn.text.trim()]);
                          else Sys.bindOp(["set", String(ed.b.line), flag, modsIn.text.trim(), keyIn.text.trim(), dispIn.text.trim(), argIn.text.trim()]);
                      }
                      Row { anchors.centerIn: parent; spacing: Theme.s(5)
                          Ico { n: "save"; color: Theme.onAccent; font.pixelSize: Theme.s(13) }
                          Lbl { text: "Save"; color: Theme.onAccent; font.bold: true; font.pixelSize: Theme.fs(11) } } }
                Btn { width: Theme.s(80); height: Theme.s(30); radius: height / 2; onClicked: { root.editing = -1; Sys.bindMsg = "" }
                      Lbl { anchors.centerIn: parent; text: "Cancel"; font.bold: true; color: Theme.sub; font.pixelSize: Theme.fs(11) } }
                Btn { visible: ed.b.line !== -2; width: Theme.s(100); height: Theme.s(30); radius: height / 2
                      base: ed.armed ? Theme.danger : Theme.surface2
                      onClicked: { if (!ed.armed) { ed.armed = true; return } root.pendingClose = true; Sys.bindOp(["del", String(ed.b.line)]) }
                      Lbl { anchors.centerIn: parent; text: ed.armed ? "Sure?" : "Delete"; font.bold: true; font.pixelSize: Theme.fs(11)
                            color: ed.armed ? "#fff" : Theme.danger } }
            }
        }
    }

    Column {
        id: top
        x: Theme.s(14); y: Theme.s(92); width: parent.width - Theme.s(28)
        Loader { active: root.editing === -2; width: parent.width; sourceComponent: Component { Editor { } } }
    }

    ListView {
        x: Theme.s(14); y: Theme.s(96) + (root.editing === -2 ? top.height + Theme.s(8) : 0)
        width: parent.width - Theme.s(28); height: parent.height - y - Theme.s(10)
        clip: true; spacing: Theme.s(4); boundsBehavior: Flickable.StopAtBounds
        model: root.filtered
        delegate: Column {
            width: ListView.view.width
            spacing: Theme.s(4)
            readonly property bool open: root.editing === modelData.line
            Rectangle {
                width: parent.width; height: Theme.s(42); radius: Theme.s(12)
                color: open ? Theme.accentSoft : rma.containsMouse ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Row {
                    x: Theme.s(10); anchors.verticalCenter: parent.verticalCenter; spacing: Theme.s(4)
                    Repeater {
                        model: (modelData.shown ? modelData.shown.split(/\s+/) : []).concat([modelData.key]).filter(x => x)
                        Rectangle {
                            height: Theme.s(22); width: kl.implicitWidth + Theme.s(14); radius: Theme.s(7)
                            color: Theme.surface2; border.color: Theme.border
                            Lbl { id: kl; anchors.centerIn: parent; text: modelData; font.pixelSize: Theme.fs(10); font.bold: true }
                        }
                    }
                }
                Lbl {
                    anchors { right: parent.right; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
                    width: parent.width * 0.42; horizontalAlignment: Text.AlignRight
                    text: root.action(modelData); color: Theme.sub; font.pixelSize: Theme.fs(10)
                }
                MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { Sys.bindMsg = ""; root.editing = open ? -1 : modelData.line } }
            }
            Loader {
                active: open; width: parent.width
                sourceComponent: Component { Editor { b: modelData } }
            }
        }
    }
}
