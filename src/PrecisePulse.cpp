#include "PrecisePulse.h"

#include "QtGlobal"
#include "cmath"
#include "limits"

PrecisePulse::PrecisePulse(QObject *parent)
    : QObject(parent)
    , m_deadlineNs(0)
    , m_scheduled(false)
{
    m_clock.start();

    m_timer.setSingleShot(true);
    m_timer.setTimerType(Qt::PreciseTimer);

    connect(&m_timer, SIGNAL(timeout()),
            this, SLOT(onTimer()));
}

double PrecisePulse::now() const
{
    return double(m_clock.nsecsElapsed()) / 1000000.0;
}

void PrecisePulse::scheduleAt(double deadlineMs)
{
    if (!std::isfinite(deadlineMs))
        return;

    m_deadlineNs = qint64(
        std::llround(deadlineMs * 1000000.0)
    );

    m_scheduled = true;
    arm();
}

void PrecisePulse::cancel()
{
    m_scheduled = false;
    m_timer.stop();
}

void PrecisePulse::arm()
{
    if (!m_scheduled)
        return;

    m_timer.stop();

    const qint64 remainingNs =
        m_deadlineNs - m_clock.nsecsElapsed();

    if (remainingNs <= 0) {
        m_timer.start(0);
        return;
    }

    qint64 intervalMs =
        (remainingNs + 999999) / 1000000;

    if (intervalMs < 1)
        intervalMs = 1;

    const qint64 maximumInterval =
        qint64(std::numeric_limits<int>::max());

    if (intervalMs > maximumInterval)
        intervalMs = maximumInterval;

    m_timer.start(int(intervalMs));
}

void PrecisePulse::onTimer()
{
    if (!m_scheduled)
        return;

    const qint64 currentNs = m_clock.nsecsElapsed();
    const qint64 remainingNs = m_deadlineNs - currentNs;

    if (remainingNs > 0) {
        arm();
        return;
    }

    m_scheduled = false;

    const double errorMs =
        double(currentNs - m_deadlineNs) / 1000000.0;

    emit triggered(errorMs);
}
