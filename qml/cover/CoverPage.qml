import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// The heart keeps beating while the app is in the background.
//
// The engine lives in ApplicationWindow and keeps ticking as long as the
// process is alive, so the cover needs no timekeeping of its own -- it
// listens to the same signals as the main page.
//
// CoverBackground follows the ambience by itself. Under Fiat colours it has
// to be given the paper like every other surface.

CoverBackground {
    id: cover

    property QtObject cor

    Rectangle {
        anchors.fill: parent
        visible: !FiatCorTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatCorTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatCorTheme.backgroundLow }
        }
    }

    PulseHeart {
        id: heart
        cor: cover.cor
        anchors {
            top: parent.top
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        width: cover.width * 0.72
        height: width
        coreSize: width * 0.42
    }

    BeatDots {
        id: dots
        cor: cover.cor
        interactive: false
        dotSize: Theme.paddingSmall * 1.6
        anchors {
            top: heart.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: cover.width * 0.8
    }

    Column {
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.itemSizeSmall
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 0

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: cover.cor ? cover.cor.bpm : ""
            font.family: FiatCorTheme.serif
            font.pixelSize: Theme.fontSizeLarge
            color: FiatCorTheme.primaryText
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: cover.cor ? "BPM · " + cover.cor.timeSignature : ""
            font.pixelSize: Theme.fontSizeTiny
            color: FiatCorTheme.secondaryText
        }
    }

    CoverActionList {
        id: actions

        CoverAction {
            iconSource: cover.cor && cover.cor.running
                        ? "image://theme/icon-cover-pause"
                        : "image://theme/icon-cover-play"
            onTriggered: if (cover.cor) cover.cor.toggle()
        }
    }
}
