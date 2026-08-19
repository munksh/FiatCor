import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// A wide action in the thumb zone.
//
// The pill idiom at a size you can hit without looking. Filled while the
// metronome is running, so the state of the app is legible from across the
// room.

MouseArea {
    id: btn

    property alias text: label.text
    property bool filled: false

    height: Theme.itemSizeMedium * 0.82

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: btn.filled ? FiatCorTheme.pillFillActive : FiatCorTheme.pillFill
        border.color: btn.filled ? FiatCorTheme.pillBorderActive : FiatCorTheme.pillBorder
        border.width: 1
        opacity: btn.pressed ? 0.6 : 1.0
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Label {
        id: label
        anchors.centerIn: parent
        color: btn.filled ? FiatCorTheme.accent : FiatCorTheme.primaryText
        font.pixelSize: Theme.fontSizeLarge
        Behavior on color { ColorAnimation { duration: 140 } }
    }
}
