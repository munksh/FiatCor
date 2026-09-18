/*
 * Fiat Cor — metronome for Sailfish OS.
 */

#ifdef QT_QML_DEBUG
#include "QtQuick"
#endif

#include "QtQml"
#include "sailfishapp.h"

#include "AudioPulse.h"
#include "PrecisePulse.h"

int main(int argc, char *argv[])
{
    qmlRegisterType<PrecisePulse>(
        "harbour.fiatcor", 1, 0, "PrecisePulse"
    );

    qmlRegisterType<AudioPulse>(
        "harbour.fiatcor", 1, 0, "AudioPulse"
    );

    return SailfishApp::main(argc, argv);
}
