TARGET = harbour-fiatcor

CONFIG += sailfishapp
QT += multimedia

SOURCES += \
    src/harbour-fiatcor.cpp \
    src/PrecisePulse.cpp \
    src/AudioPulse.cpp

HEADERS += \
    src/PrecisePulse.h \
    src/AudioPulse.h

DISTFILES += \
    qml/harbour-fiatcor.qml \
    qml/Cor.qml \
    qml/FiatCorTheme.qml \
    qml/Storage.js \
    qml/qmldir \
    qml/components/BeatDots.qml \
    qml/components/DialogHead.qml \
    qml/components/EmptyNote.qml \
    qml/components/MunkstolenMark.qml \
    qml/components/PageHead.qml \
    qml/components/Pill.qml \
    qml/components/PulseHeart.qml \
    qml/components/SectionLabel.qml \
    qml/components/WideButton.qml \
    qml/cover/CoverPage.qml \
    qml/images/family/harbour-fiatagenda.png \
    qml/images/family/harbour-fiatmargo.png \
    qml/images/family/harbour-fiatglossa.png \
    qml/images/family/harbour-fiatvox.png \
    qml/images/family/harbour-fiatpons.png \
    qml/images/family/harbour-fiatlux.png \
    qml/images/family/harbour-fiatcor.png \
    qml/images/family/harbour-fiatpassus.png \
    qml/images/family/harbour-fiatmos.png \
    qml/pages/AboutPage.qml \
    qml/pages/MetronomePage.qml \
    qml/pages/PresetsPage.qml \
    qml/pages/SavePresetDialog.qml \
    qml/sounds/click-strong.wav \
    qml/sounds/click-medium.wav \
    qml/sounds/click-normal.wav \
    qml/sounds/click-sub.wav \
    rpm/harbour-fiatcor.spec \
    harbour-fiatcor.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

VERSION = 1.0.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
