import QtQuick

Text {
    property string n
    text: Theme.glyph(n)
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: Theme.s(18)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
