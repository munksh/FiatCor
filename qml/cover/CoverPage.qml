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

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: FiatCorTheme.coverSideMargin
        anchors.rightMargin: FiatCorTheme.coverSideMargin
        anchors.topMargin: cover.height * FiatCorTheme.coverFigureFractionShape
        spacing: Theme.paddingMedium

        PulseHeart {
            id: heart
            anchors.horizontalCenter: parent.horizontalCenter
            cor: cover.cor
            width: cover.width * FiatCorTheme.coverArtFraction
            height: width
            coreSize: width * 0.42
        }

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