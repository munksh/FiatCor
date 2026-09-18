#include "AudioPulse.h"

#include "QAudioDeviceInfo"
#include "QMutexLocker"
#include "QtGlobal"

#include "cmath"
#include "cstring"

namespace
{
const double Pi = 3.14159265358979323846;
}

AudioPulse::AudioPulse(QObject *parent)
    : QIODevice(parent)
    , m_output(0)
    , m_sampleRate(48000)
    , m_bpm(90)
    , m_beatsPerBar(4)
    , m_subdivisionCount(1)
    , m_soundEnabled(true)
    , m_frame(0)
    , m_nextTickFrame(0.0)
    , m_beatIndex(0)
    , m_subdivisionIndex(0)
    , m_clickPosition(-1)
    , m_clickLength(0)
    , m_clickLevel(0)
    , m_noiseState(0x6714a53du)
{
    m_pattern << 3 << 1 << 1 << 1;

    m_format.setSampleRate(m_sampleRate);
    m_format.setChannelCount(1);
    m_format.setSampleSize(16);
    m_format.setCodec("audio/pcm");
    m_format.setByteOrder(QAudioFormat::LittleEndian);
    m_format.setSampleType(QAudioFormat::SignedInt);
}

AudioPulse::~AudioPulse()
{
    stop();
}

bool AudioPulse::start()
{
    stop();

    QAudioDeviceInfo device =
        QAudioDeviceInfo::defaultOutputDevice();

    if (device.isNull()) {
        QMutexLocker locker(&m_mutex);
        m_error = "No audio output device is available";
        emit audioError(m_error);
        return false;
    }

    if (!device.isFormatSupported(m_format)) {
        QMutexLocker locker(&m_mutex);
        m_error =
            "The audio device does not support 48 kHz mono 16-bit PCM";
        emit audioError(m_error);
        return false;
    }

    {
        QMutexLocker locker(&m_mutex);
        resetTransport();
        m_error.clear();
    }

    if (!open(QIODevice::ReadOnly)) {
        QMutexLocker locker(&m_mutex);
        m_error = "Could not open the metronome PCM generator";
        emit audioError(m_error);
        return false;
    }

    m_output = new QAudioOutput(device, m_format, this);

    /*
     * Keep enough buffered audio to survive ordinary UI work without
     * introducing a very large response delay. The backend may choose
     * another actual size; QAudioOutput documents that setBufferSize()
     * is a request rather than a guarantee.
     */
    const int bytesPerFrame = 2;
    const int requestedFrames = m_sampleRate / 20;  // about 50 ms
    m_output->setBufferSize(requestedFrames * bytesPerFrame);
    m_output->setNotifyInterval(20);

    connect(
        m_output,
        SIGNAL(stateChanged(QAudio::State)),
        this,
        SLOT(handleAudioState(QAudio::State))
    );

    m_output->start(this);

    if (m_output->error() != QAudio::NoError) {
        QMutexLocker locker(&m_mutex);
        m_error = "QAudioOutput could not start";
        emit audioError(m_error);
        return false;
    }

    return true;
}

void AudioPulse::stop()
{
    if (m_output) {
        m_output->stop();
        delete m_output;
        m_output = 0;
    }

    if (isOpen())
        close();

    QMutexLocker locker(&m_mutex);
    resetTransport();
}

void AudioPulse::configure(
    int bpm,
    int beatsPerBar,
    int subdivisionCount,
    const QString &accentPattern,
    bool soundEnabled)
{
    QMutexLocker locker(&m_mutex);

    m_bpm = qBound(30, bpm, 250);
    m_beatsPerBar = qBound(1, beatsPerBar, 12);
    m_subdivisionCount = qBound(1, subdivisionCount, 4);
    m_soundEnabled = soundEnabled;

    const QVector<int> parsed =
        parsePattern(accentPattern, m_beatsPerBar);

    if (parsed.size() == m_beatsPerBar)
        m_pattern = parsed;
}

QString AudioPulse::errorString() const
{
    QMutexLocker locker(&m_mutex);
    return m_error;
}

bool AudioPulse::isSequential() const
{
    return true;
}

qint64 AudioPulse::bytesAvailable() const
{
    return 8192 + QIODevice::bytesAvailable();
}

qint64 AudioPulse::readData(char *data, qint64 maxSize)
{
    if (!data || maxSize <= 0)
        return 0;

    /*
     * Mono signed 16-bit little-endian PCM. QAudioOutput may request an
     * odd byte count, so only return complete frames.
     */
    const qint64 frameCount = maxSize / 2;
    const qint64 byteCount = frameCount * 2;

    if (frameCount <= 0)
        return 0;

    QMutexLocker locker(&m_mutex);

    for (qint64 i = 0; i < frameCount; ++i) {
        /*
         * Tick positions are fractional. Keeping the next position as a
         * double avoids accumulating whole-frame rounding error.
         */
        if (double(m_frame) + 0.000001 >= m_nextTickFrame) {
            beginTick();

            const double framesPerBeat =
                double(m_sampleRate) * 60.0 / double(m_bpm);

            const double framesPerTick =
                framesPerBeat / double(m_subdivisionCount);

            m_nextTickFrame += framesPerTick;
        }

        const qint16 sample = renderClick();
        const quint16 encoded = quint16(sample);

        data[i * 2] = char(encoded & 0xffu);
        data[i * 2 + 1] = char((encoded >> 8) & 0xffu);
        ++m_frame;
    }

    return byteCount;
}

qint64 AudioPulse::writeData(const char *, qint64)
{
    return -1;
}

void AudioPulse::beginTick()
{
    int level = 0;

    if (m_subdivisionIndex == 0) {
        if (m_beatIndex >= 0 && m_beatIndex < m_pattern.size())
            level = m_pattern.at(m_beatIndex);
        else
            level = 1;
    } else {
        level = 4; // subdivision click
    }

    if (m_soundEnabled && level > 0) {
        m_clickLevel = level;
        m_clickPosition = 0;

        if (level == 4)
            m_clickLength = int(m_sampleRate * 0.014);
        else if (level == 3)
            m_clickLength = int(m_sampleRate * 0.035);
        else if (level == 2)
            m_clickLength = int(m_sampleRate * 0.029);
        else
            m_clickLength = int(m_sampleRate * 0.023);
    }

    ++m_subdivisionIndex;

    if (m_subdivisionIndex >= m_subdivisionCount) {
        m_subdivisionIndex = 0;
        ++m_beatIndex;

        if (m_beatIndex >= m_beatsPerBar)
            m_beatIndex = 0;
    }
}

qint16 AudioPulse::renderClick()
{
    if (m_clickPosition < 0 ||
        m_clickPosition >= m_clickLength ||
        m_clickLevel <= 0) {
        return 0;
    }

    const double position =
        double(m_clickPosition) / double(m_sampleRate);

    double frequency = 1200.0;
    double amplitude = 0.38;
    double decay = 150.0;

    if (m_clickLevel == 3) {
        frequency = 1850.0;
        amplitude = 0.92;
        decay = 105.0;
    } else if (m_clickLevel == 2) {
        frequency = 1520.0;
        amplitude = 0.67;
        decay = 125.0;
    } else if (m_clickLevel == 4) {
        frequency = 2550.0;
        amplitude = 0.25;
        decay = 230.0;
    }

    const double envelope = std::exp(-decay * position);

    /*
     * Deterministic noise gives the transient a wooden click rather than
     * a pure electronic beep. It remains deterministic between runs.
     */
    m_noiseState =
        m_noiseState * 1664525u + 1013904223u;

    const double noise =
        (double((m_noiseState >> 8) & 0xffffu) / 32767.5) - 1.0;

    const double fundamental =
        std::sin(2.0 * Pi * frequency * position);

    const double overtone =
        std::sin(2.0 * Pi * frequency * 1.91 * position);

    double value =
        amplitude * envelope *
        (0.66 * fundamental +
         0.20 * overtone +
         0.14 * noise);

    if (value > 1.0)
        value = 1.0;
    else if (value < -1.0)
        value = -1.0;

    ++m_clickPosition;

    if (m_clickPosition >= m_clickLength)
        m_clickPosition = -1;

    return qint16(value * 32767.0);
}

void AudioPulse::resetTransport()
{
    m_frame = 0;
    m_nextTickFrame = 0.0;
    m_beatIndex = 0;
    m_subdivisionIndex = 0;
    m_clickPosition = -1;
    m_clickLength = 0;
    m_clickLevel = 0;
}

QVector<int> AudioPulse::parsePattern(
    const QString &value,
    int beats) const
{
    QVector<int> result;
    const QStringList parts = value.split(',');

    if (parts.size() != beats)
        return result;

    for (int i = 0; i < parts.size(); ++i) {
        bool ok = false;
        const int level = parts.at(i).toInt(&ok);

        if (!ok || level < 0 || level > 3) {
            result.clear();
            return result;
        }

        result.append(level);
    }

    return result;
}

void AudioPulse::handleAudioState(QAudio::State state)
{
    if (!m_output)
        return;

    if (state == QAudio::StoppedState &&
        m_output->error() != QAudio::NoError) {
        QMutexLocker locker(&m_mutex);
        m_error =
            QString("Audio stopped with error code %1")
            .arg(int(m_output->error()));

        emit audioError(m_error);
    }
}
