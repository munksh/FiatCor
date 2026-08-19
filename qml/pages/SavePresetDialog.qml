import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"
import "../Storage.js" as Storage

// Name and store the tempo you are on.
//
// The accent pattern travels with the preset, so a hand-built 7/8 as 2+2+3
// comes back exactly as you left it.
//
// DialogHead rather than Silica's DialogHeader, which draws both actions in
// Theme.highlightColor -- light on light under Fiat colours plus a dark
// ambience. The drag-to-accept flourish goes with it; back-swipe still
// cancels.

Dialog {
    id: dialog

    property QtObject cor

    // Set when the dialog is opened to overwrite an existing preset.
    property int presetId: -1

    canAccept: nameField.text.trim().length > 0

    function _subLabel(key) {
        if (key === "eighth") return qsTr("eighths")
        if (key === "triplet") return qsTr("triplets")
        if (key === "sixteenth") return qsTr("sixteenths")
        return qsTr("no subdivision")
    }

    onAccepted: {
        var n = nameField.text.trim()
        var pattern = cor.patternToString(cor.accentPattern)
        if (presetId >= 0)
            Storage.updatePreset(presetId, n, cor.bpm, cor.beatsPerBar,
                                 cor.noteValue, cor.subdivision, pattern)
        else
            Storage.savePreset(n, cor.bpm, cor.beatsPerBar,
                               cor.noteValue, cor.subdivision, pattern)
        cor.presetName = n
    }

    Rectangle {
        anchors.fill: parent
        visible: !FiatCorTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatCorTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatCorTheme.backgroundLow }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHead {
            title: qsTr("preset")
            acceptText: dialog.presetId >= 0 ? qsTr("Update") : qsTr("Save")
            acceptEnabled: dialog.canAccept
            onCancelled: dialog.reject()
            onAccepted: if (dialog.canAccept) dialog.accept()
        }

        TextField {
            id: nameField
            width: parent.width
            label: qsTr("Name")
            placeholderText: qsTr("e.g. Hymn 248, verse")
            text: dialog.cor && dialog.cor.presetName !== "" ? dialog.cor.presetName : ""
            color: FiatCorTheme.primaryText
            inputMethodHints: Qt.ImhNoPredictiveText
            EnterKey.onClicked: focus = false
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin * 2
            wrapMode: Text.Wrap
            color: FiatCorTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
            text: dialog.cor
                  ? dialog.cor.bpm + " BPM · " + dialog.cor.timeSignature + " · "
                    + dialog._subLabel(dialog.cor.subdivision)
                    + "\n" + qsTr("accents") + " " + dialog.cor.patternToString(dialog.cor.accentPattern)
                  : ""
        }
    }
}
