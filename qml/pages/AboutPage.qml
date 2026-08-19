import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// Who made this, what it does with your data, and where it came from.
//
// Same four questions in the same order as Fiat Mos, and nothing else. No
// changelog -- that belongs in the store listing and the repository, where
// it can be corrected. No donation button. Two links.
//
// The lead is three examples rather than a summary. "A metronome with a
// flexible accent model" is accurate and says nothing; a hymn in 6/8, a
// silent beat and a 7/8 grouping say the same thing and can be heard.

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
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHead {
                title: qsTr("about")
                subtitle: "fiat cor"
            }

            // -- What it is -----------------------------------------------

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatCorTheme.serif
                color: FiatCorTheme.primaryText
                text: qsTr("A hymn in 6/8 wants three and three. A bar in 7/8 wants two, two and three. Sometimes you want the one to stay silent and see whether you still land on it.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatCorTheme.secondaryText
                text: qsTr("Most metronomes give you one accent on the first beat and nothing else. Fiat Cor puts the whole bar on screen as a row of dots, and every dot is yours: tap it for strong, medium, plain or silent. The pattern is the instrument, not a setting buried behind it.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatCorTheme.secondaryText
                text: qsTr("The pulse is drawn as a heartbeat rather than a swinging arm, and it is meant to be usable on sight alone — in a church, late at night, with the sound off.")
            }

            // -- The name --------------------------------------------------

            SectionLabel { text: qsTr("The name") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatCorTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>fiat</b> — Latin, <i>let there be</i>. From <i>fiat lux</i> in the Vulgate: let there be light, and there was light. The first app took the phrase. The rest of the family kept the verb.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatCorTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>cor</b> — Latin, <i>heart</i>. It is where <i>courage</i> comes from, by way of French. <i>Tactus</i> was the other candidate and it is the more technical word, but a metronome is not a measuring stick. It is the beat you cannot help keeping.")
            }

            // -- The motto -------------------------------------------------
            //
            // Attributed and dated on purpose. An unattributed line in this
            // position reads as borrowed wisdom; a signed one reads as a
            // maker's mark, which is what it is. Fiat Mos quotes Ovid. This
            // one quotes the person who wrote the app. Both are honest as
            // long as neither pretends to be the other.

            Item { width: 1; height: Theme.paddingMedium }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                height: mottoColumn.height + Theme.paddingLarge * 2
                radius: FiatCorTheme.cardRadius
                color: FiatCorTheme.card
                border.color: FiatCorTheme.cardBorder
                border.width: FiatCorTheme.cardBorderWidth

                Column {
                    id: mottoColumn
                    anchors.centerIn: parent
                    width: parent.width - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatCorTheme.serif
                        font.italic: true
                        color: FiatCorTheme.primaryText
                        text: "Rytm är vårt universums hjärtslag;\ndet första vi hör i moderlivet,\noch det sista vi lämnar bakom oss"
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatCorTheme.secondaryText
                        text: qsTr("Rhythm is the heartbeat of our universe; the first thing we hear in the womb, and the last thing we leave behind.")
                    }

                    Item { width: 1; height: Theme.paddingSmall }

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeTiny
                        color: FiatCorTheme.secondaryText
                        text: "Caesar Prometheus, 2026"
                    }
                }
            }

            // -- Privacy ---------------------------------------------------

            SectionLabel { text: qsTr("Your data") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatCorTheme.secondaryText
                text: qsTr("Your saved tempos stay on this phone, in one file. There is no account, no network access, and nothing is measured or reported. Fiat Cor asks for one thing: permission to make a sound.")
            }

            // -- Who ---------------------------------------------------------

            SectionLabel { text: qsTr("Made by") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatCorTheme.serif
                color: FiatCorTheme.primaryText
                text: "Munkstolen"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatCorTheme.secondaryText
                text: "Caesar Prometheus Ivarsson"
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatCorTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://munkstolen.se")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatCorTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "munkstolen.se"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatCorTheme.secondaryText
                        text: qsTr("Everything else I make")
                    }
                }
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatCorTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://github.com/munksh/FiatCor")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatCorTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "github.com/munksh/FiatCor"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatCorTheme.secondaryText
                        text: qsTr("Source and issues · MIT licence")
                    }
                }
            }

            // -- The family ---------------------------------------------------
            //
            // Every name translates itself, and the translation explains the
            // app. That is worth more than a tagline.

            SectionLabel { text: qsTr("The Fiat family") }

            Repeater {
                model: [
                    { name: "fiat lux", what: qsTr("let there be light — a light meter for film") },
                    { name: "fiat vox", what: qsTr("let there be voice — a chromatic tuner") },
                    { name: "fiat cor", what: qsTr("let there be heart — this one") },
                    { name: "fiat mos", what: qsTr("let there be habit — a habit tracker") }
                ]

                Column {
                    x: Theme.horizontalPageMargin
                    width: content.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatCorTheme.serif
                        color: FiatCorTheme.primaryText
                        text: modelData.name
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatCorTheme.secondaryText
                        text: modelData.what
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeTiny
                color: FiatCorTheme.secondaryText
                text: qsTr("Four instruments that measure something you would otherwise guess at. They share a look, a palette and a stubbornness about staying on your own phone.")
            }

            // -- Version ---------------------------------------------------
            //
            // Last, because it is support and not identity. The guard means
            // the page still renders before appVersion is wired up from the
            // rpm spec by way of qmake.

            SectionLabel { text: qsTr("Version") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeSmall
                color: FiatCorTheme.primaryText
                text: typeof appVersion !== "undefined" ? appVersion : qsTr("unknown")
            }

            // -- Colophon --------------------------------------------------
            //
            // A printer's mark at the end of a book: a short rule, the mark,
            // the wordmark. Nothing here is tappable -- the links are up under
            // "made by". This is the signature, not a button.

            Item { width: 1; height: Theme.itemSizeExtraSmall }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatCorTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingLarge }

            MunkstolenMark {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeMedium
                frame: "ring"
                color: FiatCorTheme.makerMark
            }

            Item { width: 1; height: Theme.paddingSmall }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "munkstolen"
                font.pixelSize: Theme.fontSizeSmall
                font.family: FiatCorTheme.serif
                font.italic: true
                color: FiatCorTheme.makerMark
            }
        }

        VerticalScrollDecorator { }
    }
}
