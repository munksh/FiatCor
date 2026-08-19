/*
 * Pill — the house toggle for a selectable value.
 *
 * Never TextSwitch: with twelve beat counts to choose from it stacks
 * into a wall. Pills wrap in a Flow and reflow to the content width.
 *
 * Selected state swaps primaryColor for highlightColor, exactly as in
 * Fiat Lux and Fiat Vox. No colours of its own.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

MouseArea {
    id: pill

    property alias text: label.text
    property bool selected: false
    property QtObject pal

    implicitHeight: label.height + Theme.paddingSmall * 3
    implicitWidth: Math.max(Theme.itemSizeExtraSmall,
                            label.width + Theme.paddingLarge * 2)
    height: implicitHeight
    width: implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: pill.selected ? pill.pal.pillFillActive : pill.pal.pillFill
        border.color: pill.selected ? pill.pal.pillBorderActive : pill.pal.pillBorder
        border.width: 1
        opacity: pill.pressed ? 0.6 : 1.0
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Label {
        id: label
        anchors.centerIn: parent
        color: pill.selected ? pill.pal.pillTextActive : pill.pal.pillText
        font.pixelSize: Theme.fontSizeExtraSmall
        font.weight: Font.Bold
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
