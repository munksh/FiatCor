/*
 * The heart keeps beating while the app is in the background.
 *
 * The engine lives in ApplicationWindow and ticks as long as the process is
 * alive, so the cover keeps no time of its own — it listens to the same
 * signals as the main page.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

CoverBackground {
    id: cover

    // ---- state ----

    property QtObject cor

    // ---- paper ----

    Rectangle {
        anchors.fill: parent
        visible: !FiatCorTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatCorTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatCorTheme.backgroundLow }
        }
    }

    // ---- wordmark ----

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: FiatCorTheme.coverWordmarkTop
        text: "fiat cor"
        color: FiatCorTheme.secondaryText
        font.pixelSize: Theme.fontSizeTiny
        font.family: FiatCorTheme.serif
        font.italic: true
    }

    // ---- figure ----
    //
    // The tempo leads and the heart hangs under it, so the number lands on the
    // same line as Mos's count and Vox's letter. The heart is then the proof
    // that the number is live rather than the figure itself.

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: FiatCorTheme.coverSideMargin
        anchors.rightMargin: FiatCorTheme.coverSideMargin
        anchors.topMargin: cover.height * FiatCorTheme.coverFigureFraction
        spacing: Theme.paddingMedium

        // No "BPM" beside it. On a metronome's cover the number is the tempo;
        // nothing else it could be.
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: cover.cor ? cover.cor.bpm : ""
            color: FiatCorTheme.accent
            font.pixelSize: FiatCorTheme.coverFigureSize
            font.family: FiatCorTheme.serif
        }

        PulseHeart {
            id: heart
            anchors.horizontalCenter: parent.horizontalCenter
            cor: cover.cor
            width: cover.width * FiatCorTheme.coverHeartFraction
            height: width
            coreSize: width * 0.42
        }
    }

    // ---- cover actions ----

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
