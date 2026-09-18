#ifndef AUDIOPULSE_H
#define AUDIOPULSE_H

#include "QAudioOutput"
#include "QIODevice"
#include "QMutex"
#include "QVector"

class AudioPulse : public QIODevice
{
    Q_OBJECT

public:
    explicit AudioPulse(QObject *parent = 0);
    ~AudioPulse();

    Q_INVOKABLE bool start();
    Q_INVOKABLE void stop();

    Q_INVOKABLE void configure(
        int bpm,
        int beatsPerBar,
        int subdivisionCount,
        const QString &accentPattern,
        bool soundEnabled
    );

    Q_INVOKABLE QString errorString() const;

    bool isSequential() const;
    qint64 bytesAvailable() const;

signals:
    void audioError(const QString &message);

protected:
    qint64 readData(char *data, qint64 maxSize);
    qint64 writeData(const char *data, qint64 maxSize);

private slots:
    void handleAudioState(QAudio::State state);

private:
    void beginTick();
    qint16 renderClick();
    void resetTransport();
    QVector<int> parsePattern(
        const QString &value,
        int beats
    ) const;

    mutable QMutex m_mutex;

    QAudioOutput *m_output;
    QAudioFormat m_format;

    int m_sampleRate;
    int m_bpm;
    int m_beatsPerBar;
    int m_subdivisionCount;
    QVector<int> m_pattern;
    bool m_soundEnabled;

    qint64 m_frame;
    double m_nextTickFrame;

    int m_beatIndex;
    int m_subdivisionIndex;

    int m_clickPosition;
    int m_clickLength;
    int m_clickLevel;

    quint32 m_noiseState;
    QString m_error;
};

#endif
