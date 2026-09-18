import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// The house page header. Right-aligned title, optional line under it.
//
// Not Silica's PageHeader, which draws its title in Theme.highlightColor --
// light text on light paper under Fiat colours plus a dark ambience.
//
// The title HANGS FROM THE TOP of the band, it is not centred in it and it is
// not aligned from the bottom. That matters more than it sounds: with bottom
// alignment a page that has a second line pushes its title up, so History and
// Library and the log page all sat at different heights. Anchored to the top,
// every title in the app is on the same line whether or not anything follows
// it, and the header is only as tall as what it holds.
//
// The title is also width-capped and fades, so a long habit name runs out of
// room before it can grow leftwards into the notch.

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool leftAligned: false

    width: parent ? parent.width : 0
    height: FiatCorTheme.headerTopInset + col.height + Theme.paddingLarge

    Column {
        id: col
        anchors.left: root.leftAligned ? parent.left : undefined
        anchors.right: root.leftAligned ? undefined : parent.right
        anchors.leftMargin: root.leftAligned ? Theme.horizontalPageMargin : 0
        anchors.rightMargin: root.leftAligned ? 0 : Theme.horizontalPageMargin
        anchors.top: parent.top
        anchors.topMargin: FiatCorTheme.headerTopInset
        width: parent.width - Theme.horizontalPageMargin * 2

        Label {
            width: parent.width
            horizontalAlignment: root.leftAligned
                                 ? Text.AlignLeft
                                 : Text.AlignRight
            truncationMode: TruncationMode.Fade
            text: root.title
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatCorTheme.serif
            color: FiatCorTheme.primaryText
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            horizontalAlignment: root.leftAligned
                                 ? Text.AlignLeft
                                 : Text.AlignRight
            truncationMode: TruncationMode.Fade
            text: root.subtitle
            font.pixelSize: Theme.fontSizeExtraSmall
            color: FiatCorTheme.secondaryText
        }
    }
}
