/*
 * Fiat Cor — metronom för Sailfish OS.
 *
 * Standard Sailfish-boilerplate. SailfishApp::main() letar upp
 * qml/FiatCor.qml utifrån binärens namn (TARGET i FiatCor.pro),
 * så filnamnen måste fortsätta matcha varandra.
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>

int main(int argc, char *argv[])
{
    return SailfishApp::main(argc, argv);
}
