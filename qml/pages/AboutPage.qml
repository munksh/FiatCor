import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    function paint() { FiatCorTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections {
        target: FiatCorTheme
        onAmbientChanged: page.paint()
    }

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

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatCorTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingMedium }

            Column {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
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

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: FiatCorTheme.secondaryText
                    text: "Caesar Prometheus, 2026"
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatCorTheme.innerBorder
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

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The fiat family")
            }

            Repeater {
                model: [
                    { name: "fiat agenda", what: qsTr("let there be doing — a task list"), icon: "images/family/harbour-fiatagenda.png", url: "https://openrepos.net/content/munkstolen/fiat-agenda-task-list" },
                    { name: "fiat margo", what: qsTr("let there be edge — keeps edges"), icon: "images/family/harbour-fiatmargo.png", url: "https://openrepos.net/content/munkstolen/fiat-margo-keeps-edges" },
                    { name: "fiat glossa", what: qsTr("let there be tongue — a translator"), icon: "images/family/harbour-fiatglossa.png", url: "https://openrepos.net/content/munkstolen/fiat-glossa-a-deepl-translator" },
                    { name: "fiat vox", what: qsTr("let there be voice — a chromatic tuner"), icon: "images/family/harbour-fiatvox.png", url: "https://openrepos.net/content/munkstolen/fiat-vox-chromatic-tuner" },
                    { name: "fiat pons", what: qsTr("let there be bridge — a native Qobuz client"), icon: "images/family/harbour-fiatpons.png", url: "https://openrepos.net/content/munkstolen/fiat-pons-native-qobuz-client" },
                    { name: "fiat lux", what: qsTr("let there be light — a light meter for film"), icon: "images/family/harbour-fiatlux.png", url: "https://openrepos.net/content/munkstolen/fiat-lux-lightmeter-film-photography" },
                    { name: "fiat cor", what: qsTr("let there be heart — this one"), icon: "images/family/harbour-fiatcor.png", url: "" },
                    { name: "fiat passus", what: qsTr("let there be step — a step counter - Coming soon"), icon: "images/family/harbour-fiatpassus.png", url: "" },
                    { name: "fiat mos", what: qsTr("let there be habit — a habit tracker"), icon: "images/family/harbour-fiatmos.png", url: "https://openrepos.net/content/munkstolen/fiat-mos-habit-tracker" },
                    { name: "fiat imago", what: qsTr("let there be image — a raw editor"), icon: "images/family/harbour-fiatimago.png", url: "https://openrepos.net/content/munkstolen/fiat-imago-raw-editor" },
                    { name: "fiat ratio", what: qsTr("let there be reckoning — a budget tool"), icon: "images/family/harbour-fiatratio.png", url: "https://openrepos.net/content/munkstolen/fiat-ratio-budget-tool" }
                ]

                // A full-size icon in a row of its own height, rather than an
                // icon shrunk to the height of two lines of text. The icon is
                // the app's face; it should be readable.
                delegate: BackgroundItem {
                    width: content.width
                    height: Theme.itemSizeMedium
                    enabled: modelData.url !== ""
                    highlightedColor: FiatCorTheme.highlightWash
                    onClicked: Qt.openUrlExternally(modelData.url)

                    Image {
                        id: familyIcon
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.itemSizeSmall
                        height: Theme.itemSizeSmall
                        sourceSize.width: Theme.itemSizeSmall
                        sourceSize.height: Theme.itemSizeSmall
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: Qt.resolvedUrl(modelData.icon)
                    }

                    Column {
                        anchors.left: familyIcon.right
                        anchors.leftMargin: Theme.paddingLarge
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: FiatCorTheme.serif
                            color: modelData.url !== "" ? FiatCorTheme.accent : FiatCorTheme.primaryText
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
            }

            Item { width: 1; height: Theme.paddingMedium }

            // -- Version ---------------------------------------------------
            //
            // Last, because it is support and not identity. The number comes
            // from the rpm spec by way of qmake, so it is the one the package
            // was actually built with rather than one written down twice.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Version")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeSmall
                color: FiatCorTheme.primaryText
                text: typeof appVersion !== "undefined" ? appVersion : qsTr("unknown")
            }

            // -- Colophon --------------------------------------------------

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
