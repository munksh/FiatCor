import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"
import "../Storage.js" as Storage

// Saved tempos.
//
// Tap a row to load it and go back to the metronome. Press and hold for the
// context menu, as in the camera list in Fiat Lux. Pull down to save
// whatever you are currently on.

Page {
    id: page

    property QtObject cor

    allowedOrientations: Orientation.All

    function reload() {
        Storage.loadPresets(presetModel)
    }

    function subLabel(key) {
        if (key === "eighth") return qsTr("eighths")
        if (key === "triplet") return qsTr("triplets")
        if (key === "sixteenth") return qsTr("sixteenths")
        return qsTr("straight")
    }

    // Reloaded whenever the page becomes active, so a preset saved through
    // the dialog is there when you come back.
    onStatusChanged: if (status === PageStatus.Active) reload()

    Component.onCompleted: reload()

    ListModel { id: presetModel }

    Rectangle {
        anchors.fill: parent
        visible: !FiatCorTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatCorTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatCorTheme.backgroundLow }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: presetModel

        header: PageHead {
            title: qsTr("saved tempos")
            subtitle: presetModel.count === 1 ? qsTr("1 preset")
                                              : presetModel.count + qsTr(" presets")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Save current tempo")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("SavePresetDialog.qml"),
                                                  { cor: page.cor })
            }
        }

        delegate: ListItem {
            id: item
            contentHeight: Theme.itemSizeMedium
            highlightedColor: FiatCorTheme.highlightWash

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: item.remorseAction(qsTr("Deleting"), function () {
                        Storage.deletePreset(presetId)
                        page.reload()
                    })
                }
            }

            onClicked: {
                page.cor.applyPreset(name, bpm, beatsPerBar, noteValue, subdivision,
                                     page.cor.patternFromString(accentPattern, beatsPerBar))
                pageStack.pop()
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: 0

                Label {
                    width: parent.width
                    text: name
                    color: item.highlighted ? FiatCorTheme.accent : FiatCorTheme.primaryText
                    truncationMode: TruncationMode.Fade
                }

                Label {
                    width: parent.width
                    text: bpm + " BPM · " + beatsPerBar + "/" + noteValue
                          + " · " + page.subLabel(subdivision)
                    color: FiatCorTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        EmptyNote {
            enabled: presetModel.count === 0
            text: qsTr("No saved tempos")
            hintText: qsTr("Pull down to save the one you are on")
        }

        VerticalScrollDecorator {}
    }
}
