import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// The main view.

Page {
    id: page

    property QtObject cor

    allowedOrientations: Orientation.All

    // Fiat colours paint their own paper. Under an ambience there is no
    // background at all -- the wallpaper is the background.
    Rectangle {
        anchors.fill: parent
        visible: !FiatCorTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatCorTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatCorTheme.backgroundLow }
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge * 2

        PullDownMenu {
            highlightColor: FiatCorTheme.chromeAccent

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: FiatCorTheme.ambient ? qsTr("Fiat colours") : qsTr("Follow ambience")
                onClicked: FiatCorTheme.setAmbient(!FiatCorTheme.ambient)
            }
            MenuItem {
                text: qsTr("Reset accents")
                onClicked: page.cor.resetAccents()
            }
            MenuItem {
                text: qsTr("Save as preset")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("SavePresetDialog.qml"),
                                                  { cor: page.cor })
            }
            MenuItem {
                text: qsTr("Saved tempos")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("PresetsPage.qml"),
                                                  { cor: page.cor })
            }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge

            PageHead {
                title: "fiat cor"
                subtitle: page.cor.presetName !== ""
                          ? page.cor.presetName
                          : qsTr("metronome")
                leftAligned: true
            }

            // ---- the instrument ----------------------------------------

            Rectangle {
                id: card
                x: Theme.horizontalPageMargin
                width: page.width - Theme.horizontalPageMargin * 2
                height: cardColumn.height + Theme.paddingLarge * 2
                radius: FiatCorTheme.cardRadius
                color: FiatCorTheme.card
                border.color: FiatCorTheme.cardBorder
                border.width: FiatCorTheme.cardBorderWidth

                Column {
                    id: cardColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        leftMargin: Theme.paddingLarge
                        rightMargin: Theme.paddingLarge
                    }
                    spacing: Theme.paddingMedium

                    PulseHeart {
                        id: heart
                        cor: page.cor
                        width: parent.width
                        height: parent.width * 0.60
                        // 1.9 x coreSize is how far the ripple travels; keep
                        // it inside the card or it spills over the border.
                        coreSize: Math.min(width, height) * 0.50
                        onClicked: page.cor.toggle()
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.paddingSmall

                        Label {
                            text: page.cor.bpm
                            color: FiatCorTheme.primaryText
                            font.family: FiatCorTheme.serif
                            font.pixelSize: Theme.fontSizeHuge
                        }

                        Label {
                            anchors.baseline: parent.children[0].baseline
                            text: "BPM"
                            color: FiatCorTheme.secondaryText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        // Read bpm and noteValue here in the binding, not only
                        // inside tempoTerm(), or this never refreshes.
                        text: (page.cor.bpm, page.cor.noteValue,
                               page.cor.timeSignature + " · " + page.cor.tempoTerm())
                        color: FiatCorTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            // ---- tempo --------------------------------------------------

            Slider {
                id: bpmSlider
                width: parent.width
                minimumValue: page.cor.minBpm
                maximumValue: page.cor.maxBpm
                stepSize: 1
                handleVisible: true
                value: page.cor.bpm
                // The guard breaks the loop: the binding above writes here,
                // this writes back, and without the comparison they bounce.
                onValueChanged: {
                    var v = Math.round(value)
                    if (v !== page.cor.bpm)
                        page.cor.setBpm(v)
                }
            }

            Item {
                width: parent.width
                height: tapRow.height

                Row {
                    id: tapRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingMedium

                    property real sideWidth: Theme.itemSizeLarge
                    property real totalWidth: page.width - Theme.horizontalPageMargin * 2

                    WideButton {
                        id: minusBtn
                        width: tapRow.sideWidth
                        text: "−"
                        onClicked: page.cor.nudgeBpm(-1)
                    }

                    WideButton {
                        id: tapBtn
                        width: tapRow.totalWidth - tapRow.sideWidth * 2 - tapRow.spacing * 2
                        text: qsTr("Tap")
                        filled: tapBtn.pressed
                        onClicked: page.cor.tap()
                    }

                    WideButton {
                        id: plusBtn
                        width: tapRow.sideWidth
                        text: "+"
                        onClicked: page.cor.nudgeBpm(1)
                    }
                }
            }

            // Auto-repeat on press and hold. Four empty ticks (~360 ms)
            // before it engages, or every ordinary tap would double-step.
            Timer {
                running: minusBtn.pressed
                interval: 90
                repeat: true
                triggeredOnStart: false
                property int ticks: 0
                onRunningChanged: ticks = 0
                onTriggered: { ticks++; if (ticks > 4) page.cor.nudgeBpm(-1) }
            }

            Timer {
                running: plusBtn.pressed
                interval: 90
                repeat: true
                triggeredOnStart: false
                property int ticks: 0
                onRunningChanged: ticks = 0
                onTriggered: { ticks++; if (ticks > 4) page.cor.nudgeBpm(1) }
            }

            Item {
                width: parent.width
                height: startBtn.height

                WideButton {
                    id: startBtn
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: page.width - Theme.horizontalPageMargin * 2
                    text: page.cor.running ? qsTr("Stop") : qsTr("Start")
                    filled: page.cor.running
                    onClicked: page.cor.toggle()
                }
            }

            // ---- metre ---------------------------------------------------

            Slider {
                id: beatsSlider
                width: parent.width
                minimumValue: 1
                maximumValue: page.cor.maxBeatsPerBar
                stepSize: 1
                value: page.cor.beatsPerBar
                label: qsTr("Beats per bar — tap the bar above to set accents")
                valueText: Math.round(value)

                onValueChanged: {
                    var beats = Math.round(value)
                    if (beats !== page.cor.beatsPerBar)
                        page.cor.beatsPerBar = beats
                }
            }

            SectionLabel { text: qsTr("Subdivision") }

            Flow {
                x: Theme.horizontalPageMargin
                width: page.width - Theme.horizontalPageMargin * 2
                spacing: Theme.paddingMedium

                Repeater {
                    model: ListModel {
                        ListElement { subLabel: QT_TR_NOOP("None"); subKey: "none" }
                        ListElement { subLabel: QT_TR_NOOP("Eighths"); subKey: "eighth" }
                        ListElement { subLabel: QT_TR_NOOP("Triplets"); subKey: "triplet" }
                        ListElement { subLabel: QT_TR_NOOP("Sixteenths"); subKey: "sixteenth" }
                    }

                    Pill {
                        text: qsTr(subLabel)
                        selected: page.cor.subdivision === subKey
                        onClicked: page.cor.subdivision = subKey
                    }
                }
            }

            SectionLabel { text: qsTr("Sound") }

            Flow {
                x: Theme.horizontalPageMargin
                width: page.width - Theme.horizontalPageMargin * 2
                spacing: Theme.paddingMedium

                Pill {
                    text: page.cor.soundEnabled
                          ? qsTr("Sound on")
                          : qsTr("Sound off")
                    selected: page.cor.soundEnabled
                    onClicked: page.cor.soundEnabled = !page.cor.soundEnabled
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }
}
