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

# Each of these fails silently when it is missing: a white screen, or
# "FiatCorTheme is not a type" on every page. Stop the build instead.
REQUIRED_FILES = \
    $${TARGET}.desktop \
    qml/$${TARGET}.qml \
    qml/qmldir \
    qml/Storage.js \
    LICENSE

for(f, REQUIRED_FILES) {
    !exists($$PWD/$$f): error("Missing $$f -- expected it at $$PWD/$$f")
}

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
    qml/pages/AboutPage.qml \
    qml/pages/MetronomePage.qml \
    qml/pages/PresetsPage.qml \
    qml/pages/SavePresetDialog.qml \
    qml/pages/images/family/harbour-fiatagenda.png \
    qml/pages/images/family/harbour-fiatcor.png \
    qml/pages/images/family/harbour-fiatglossa.png \
    qml/pages/images/family/harbour-fiatimago.png \
    qml/pages/images/family/harbour-fiatlux.png \
    qml/pages/images/family/harbour-fiatmargo.png \
    qml/pages/images/family/harbour-fiatmos.png \
    qml/pages/images/family/harbour-fiatpassus.png \
    qml/pages/images/family/harbour-fiatpenus.png \
    qml/pages/images/family/harbour-fiatpons.png \
    qml/pages/images/family/harbour-fiatratio.png \
    qml/pages/images/family/harbour-fiattessera.png \
    qml/pages/images/family/harbour-fiatvox.png \
    qml/sounds/click-strong.wav \
    qml/sounds/click-medium.wav \
    qml/sounds/click-normal.wav \
    qml/sounds/click-sub.wav \
    rpm/harbour-fiatcor.spec \
    harbour-fiatcor.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# The version is written once, in rpm/harbour-fiatcor.spec, and arrives here
# through %qmake5 APP_VERSION=%{version}. A build that skips the spec says so.
isEmpty(APP_VERSION) {
    APP_VERSION = 0.0.0-dev
}
DEFINES += APP_VERSION=\\\"$$APP_VERSION\\\"
