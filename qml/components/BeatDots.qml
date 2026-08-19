import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// The bar, and the only accent control there is.
//
// Each dot is one beat. Its size and weight show what that beat does:
// strong, medium, plain, silent. Tapping a dot cycles it, which is how you
// get 6/8 as 3+3, 7/8 as 2+2+3, or a deliberately silent beat to practise
// against -- without a single extra control on the screen.
//
// The dot is drawn as a Rectangle with radius width/2 rather than as a
// glyph. Unicode bullets are not reliably in the device font; a drawn circle
// is round everywhere.
//
// Touch targets: each dot owns its full slot width and the row's full
// height, so the tappable area is far larger than the visible dot. At twelve
// beats a slot is still narrow -- that is the price of showing a whole bar
// on one line, and twelve is rare.

Item {
    id: dots

    property QtObject cor
    property bool interactive: true
    property real dotSize: Theme.paddingLarge

    height: Theme.itemSizeExtraSmall

    // Slots are capped, so four beats read as a bar rather than as four dots
    // stranded at the corners of the card. Twelve beats fall back to an even
    // division of the available width.
    readonly property real slotWidth:
        Math.min(Theme.itemSizeExtraSmall,
                 width / Math.max(1, cor ? cor.beatsPerBar : 1))

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
        }

        Repeater {
            model: dots.cor ? dots.cor.beatsPerBar : 0

            Item {
                id: slot
                width: dots.slotWidth
                height: dots.height

                // Read every dependency directly in the binding. Values
                // reached only inside a called function are invisible to
                // QML's dependency tracking and the dot would quietly go
                // stale -- the most expensive trap in this codebase.
                property int level: (dots.cor.accentPattern,
                                     dots.cor.beatsPerBar,
                                     dots.cor.levelAt(index))
                property bool here: dots.cor.running && dots.cor.beatInBar === index

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width: dots.dotSize * FiatCorTheme.beatScale(slot.level)
                    height: width
                    radius: width / 2
                    color: slot.level === 0 ? "transparent" : FiatCorTheme.beatColor(slot.level)
                    border.width: slot.level === 0 ? 1 : 0
                    border.color: FiatCorTheme.dotIdle
                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Where we are in the bar, shown as a ring rather than by
                // brightening the dot -- brightness already means weight.
                Rectangle {
                    anchors.centerIn: parent
                    // Capped against the slot so the ring does not run into
                    // its neighbours at twelve beats to the bar.
                    width: Math.min(dots.dotSize * 1.75, dots.slotWidth * 0.9)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: FiatCorTheme.accent
                    opacity: slot.here ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: dots.interactive
                    onClicked: dots.cor.cycleLevel(index)
                }
            }
        }
    }
}
