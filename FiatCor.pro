# Fiat Cor — a metronome for Sailfish OS
#
# qmake, not CMake. Build in Qt Creator, or:
#   ~/SailfishOS/bin/sfdk -c target=SailfishOS-5.0.0.62-aarch64 build
#
# NOTE: everything under qml/ must be listed in DISTFILES or it is not
# deployed. That includes Storage.js and the wav files.
#
# Any change to this file, or any new source file:
#   Build → Clean All → Run qmake → Build

TARGET = FiatCor

CONFIG += sailfishapp

SOURCES += src/FiatCor.cpp

DISTFILES += \
    qml/FiatCor.qml \
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
    qml/sounds/click-strong.wav \
    qml/sounds/click-medium.wav \
    qml/sounds/click-normal.wav \
    qml/sounds/click-sub.wav \
    rpm/FiatCor.spec \
    FiatCor.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
