/*
 * Fiat Cor — metronome for Sailfish OS.
 */

#include <QtQuick>
#include <QtQml>
#include <sailfishapp.h>

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

    // The long form rather than SailfishApp::main(): appVersion has to reach
    // QML before the QML is loaded, and main() gives no hook between the two.
    // Everything below is what main() would have done.
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // The About page reads this as appVersion. Without it the page's guard
    // falls through to "unknown" -- correctly, because appVersion really is
    // undefined until someone hands it over.
    //
    // fromUtf8 rather than QStringLiteral(APP_VERSION): APP_VERSION only
    // exists once qmake substitutes it in, and a QStringLiteral redefined to
    // route through a custom operator""_i18n does not recognise a literal
    // that arrives through another macro. fromUtf8 is a plain runtime call
    // and never touches that machinery.
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"), QString::fromUtf8(APP_VERSION));

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
