import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// A small heading above a group of pills.

Item {
    id: section

    property string text

    width: parent ? parent.width : 0
    height: label.height + Theme.paddingMedium

    Label {
        id: label
        x: Theme.horizontalPageMargin
        anchors.bottom: parent.bottom
        text: section.text
        font.pixelSize: Theme.fontSizeExtraSmall
        color: FiatCorTheme.secondaryText
    }
}
