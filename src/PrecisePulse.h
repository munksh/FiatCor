#ifndef PRECISEPULSE_H
#define PRECISEPULSE_H

#include "QObject"
#include "QElapsedTimer"
#include "QTimer"

class PrecisePulse : public QObject
{
    Q_OBJECT

public:
    explicit PrecisePulse(QObject *parent = 0);

    Q_INVOKABLE double now() const;
    Q_INVOKABLE void scheduleAt(double deadlineMs);
    Q_INVOKABLE void cancel();

signals:
    void triggered(double errorMs);

private slots:
    void onTimer();

private:
    void arm();

    QElapsedTimer m_clock;
    QTimer m_timer;
    qint64 m_deadlineNs;
    bool m_scheduled;
};

#endif
