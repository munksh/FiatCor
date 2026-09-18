/*
 * Cor — the pulse engine.
 *
 * Lives in ApplicationWindow rather than on MetronomePage, for two
 * reasons: the pulse has to survive navigating to the presets and back,
 * and the cover page has to keep beating while the app is minimised.
 *
 *
 * TIMING — why it looks like this
 * ------------------------------------------------------------------
 * A QML Timer with a fixed interval = 60000/bpm drifts. Each individual
 * timeout carries its own small error and they accumulate: after ten
 * minutes of practice the pulse is audibly wrong. tools/timing-sim.js
 * measures 14.3 seconds of drift over ten minutes at every tempo.
 *
 * The fix is to never count in intervals, only in absolute instants.
 * `_beatTime` is the *ideal* time of the beat we are standing on, and it
 * advances by exactly one beat at a time regardless of when the timer
 * actually fired. Each new timeout is computed against _clock.now(), so a
 * beat that arrived 4 ms late makes the next beat 4 ms shorter instead
 * of pushing the whole grid forward. The error stays where it happened.
 *
 * The difference from the sketch in the brief (startTime + beatCount *
 * interval) is that `_beatTime` accumulates instead of multiplying. Same
 * freedom from drift, but it also survives dragging the BPM slider
 * mid-session: a tempo change takes effect at the next beat boundary
 * rather than retroactively rewriting the grid.
 *
 * Subdivisions hang off the inside of the beat (`_beatTime + k *
 * beatMs/sc`) rather than forming their own chain, so the main beats
 * stay on the grid even if the subdivision is changed mid-bar.
 *
 *
 * PRECISION — the two-stage schedule
 * ------------------------------------------------------------------
 * Qt treats timers as Qt::CoarseTimer and allows up to 5% error — at
 * 120 BPM that is 25 ms, which is audible. The exception is timeouts
 * under 20 ms, which Qt runs precisely.
 *
 * So `_arm()` first aims coarsely, stopping short of the target, then
 * re-arms with a short precise timeout for the last stretch. Each round
 * closes most of the remaining distance, so it converges immediately and
 * the final leg is always the precise one.
 *
 * The margin on the coarse leg is 6%, not a flat 15 ms. Qt's slack is
 * proportional: a 1000 ms coarse timer may fire 50 ms late. The first
 * version used a flat margin, overshot the target at slow tempi and put
 * the beat 34 ms out. The simulator caught it.
 */

import QtQuick 2.0
import QtMultimedia 5.0
import Nemo.Configuration 1.0
import harbour.fiatcor 1.0

QtObject {
    id: cor

    // ---- beat weights --------------------------------------------------
    // 3 strong (the one), 2 medium (secondary accent), 1 plain, 0 silent.

    readonly property int levelSilent: 0
    readonly property int levelNormal: 1
    readonly property int levelMedium: 2
    readonly property int levelStrong: 3

    // ---- settings ------------------------------------------------------

    property int bpm: 90
    property int beatsPerBar: 4
    property int noteValue: 4               // 2, 4, 8 or 16 — the beat unit
    property string subdivision: "none"     // none | eighth | triplet | sixteenth
    property bool soundEnabled: true
    property string presetName: ""

    // One weight per beat. Length always tracks beatsPerBar.
    property var accentPattern: [3, 1, 1, 1]

    readonly property int minBpm: 30
    readonly property int maxBpm: 250
    readonly property int maxBeatsPerBar: 12

    readonly property int subCount:
        subdivision === "eighth" ? 2 :
        subdivision === "triplet" ? 3 :
        subdivision === "sixteenth" ? 4 : 1

    readonly property string timeSignature: beatsPerBar + "/" + noteValue

    // ---- running state -------------------------------------------------

    property bool running: false
    property int beatInBar: 0               // zero-based, 0 is the one
    property int barCount: 0

    signal beat(int indexInBar, int level)
    signal subBeat(int indexInBar, int subIndex)

    // Internal timekeeping. Do not touch from outside.
    property real _beatTime: 0              // monotonic ideal beat instant
    property real _nextTick: 0              // monotonic ideal next click
    property int _subIndex: 0
    property var _taps: []

    property PrecisePulse _clock: PrecisePulse {
        onTriggered: cor._onTimeout(errorMs)
    }

    property AudioPulse _audio: AudioPulse {
        onAudioError: console.log("Fiat Cor audio:", message)
    }

    function _syncAudio() {
        // Compute this directly from subdivision. During
        // onSubdivisionChanged, the derived subCount binding may still
        // contain the previous value.
        var audioSubCount =
            subdivision === "eighth" ? 2 :
            subdivision === "triplet" ? 3 :
            subdivision === "sixteenth" ? 4 : 1

        _audio.configure(
            bpm,
            beatsPerBar,
            audioSubCount,
            patternToString(accentPattern),
            soundEnabled
        )
    }

    // ---- accents -------------------------------------------------------

    /*
     * The default pattern. A denominator of 8 or 16 with a beat count
     * divisible by three is compound time, so 6/8 comes out as 3+3 and
     * 12/8 as 3+3+3+3 without the user touching anything. Everything else
     * gets one strong beat and plain beats after it.
     *
     * Anything irregular — 7/8 as 2+2+3, a deliberately silent beat to
     * practise against — is a few taps on the bar indicator away.
     */
    function defaultPattern(beats, nv) {
        var compound = (nv === 8 || nv === 16) && beats >= 6 && beats % 3 === 0
        var p = []
        for (var i = 0; i < beats; i++) {
            if (i === 0) p.push(levelStrong)
            else if (compound && i % 3 === 0) p.push(levelMedium)
            else p.push(levelNormal)
        }
        return p
    }

    function levelAt(index) {
        if (!accentPattern || index < 0 || index >= accentPattern.length)
            return levelNormal
        return accentPattern[index]
    }

    // Tapping a beat cycles strong → medium → plain → silent → strong.
    function cycleLevel(index) {
        if (!accentPattern || index < 0 || index >= accentPattern.length)
            return
        var p = accentPattern.slice()
        p[index] = (p[index] + 3) % 4       // step down, wrapping silent → strong
        accentPattern = p
    }

    function resetAccents() {
        accentPattern = defaultPattern(beatsPerBar, noteValue)
    }

    // ---- public control ------------------------------------------------

    function start() {
        if (running) return

        _syncAudio()
        if (!_audio.start())
            console.log("Fiat Cor audio start failed:", _audio.errorString())

        running = true
        beatInBar = 0
        barCount = 0
        _subIndex = 0
        _beatTime = _clock.now()
        _nextTick = _beatTime
        _logReset()

        // AudioPulse produces the first audible click immediately from
        // sample frame 0. Let the normal timeout path show that same
        // logical beat instead of advancing once during start().
        _arm(_nextTick)
    }

    function stop() {
        running = false
        _clock.cancel()
        _audio.stop()
    }

    function toggle() {
        if (running) stop(); else start()
    }

    function setBpm(v) {
        bpm = Math.max(minBpm, Math.min(maxBpm, Math.round(v)))
    }

    function nudgeBpm(d) {
        setBpm(bpm + d)
    }

    /*
     * Tap tempo. Averages the intervals between the most recent taps
     * (five taps, so four intervals). A gap longer than 2.5 s starts a
     * fresh series — otherwise the old tempo lingers and drags the
     * answer down.
     */
    function tap() {
        var now = _clock.now()
        var taps = _taps.slice()

        if (taps.length > 0 && now - taps[taps.length - 1] > 2500)
            taps = []

        taps.push(now)
        while (taps.length > 5)
            taps.shift()
        _taps = taps

        if (taps.length < 2)
            return

        var sum = 0
        for (var i = 1; i < taps.length; i++)
            sum += taps[i] - taps[i - 1]
        var avg = sum / (taps.length - 1)
        if (avg <= 0)
            return

        setBpm(60000 / avg)
    }

    function clearTaps() {
        _taps = []
    }

    function applyPreset(name, presetBpm, presetBeats, presetNoteValue,
                         presetSubdivision, presetPattern) {
        // Order matters: beatsPerBar and noteValue reset the pattern, so
        // the stored pattern has to be applied after them.
        beatsPerBar = presetBeats
        noteValue = 4
        setBpm(presetBpm)
        subdivision = presetSubdivision
        if (presetPattern && presetPattern.length === presetBeats)
            accentPattern = presetPattern
        presetName = name
    }

    /*
     * Tempo terms are defined against the quarter note, so a piece
     * notated in 6/8 at 180 eighths is Andante, the same as 4/4 at 90.
     * Convert before naming it.
     */
    function quarterBpm() {
        return bpm * 4.0 / Math.max(1, noteValue)
    }

    function tempoTerm() {
        var v = quarterBpm()
        if (v < 60) return "Largo"
        if (v < 66) return "Larghetto"
        if (v < 76) return "Adagio"
        if (v < 108) return "Andante"
        if (v < 120) return "Moderato"
        if (v < 156) return "Allegro"
        if (v < 176) return "Vivace"
        if (v < 200) return "Presto"
        return "Prestissimo"
    }

    // ---- the engine ----------------------------------------------------

    /*
     * A tick is split into three steps that must happen in this order:
     *
     *   1. _sound()   — the click. This is the thing being judged, so it
     *                   goes first and nothing is allowed in front of it.
     *   2. _advanceAndSchedule() — arm the next timer. Because the timer
     *                   is armed against an absolute instant, doing this
     *                   before the visual work means the visual work
     *                   cannot push the next beat late.
     *   3. _notify()  — signals to the UI, and the haptics.
     *
     * The first version did 1, 3, 2. Every beat then restarted three
     * animations and flipped two dot opacities on the main thread
     * *before* the next timeout was set, so a slow frame arrived as a
     * late beat. Rearranging costs nothing and removes a whole class of
     * jitter. It does not touch the audio path, which is the other and
     * probably larger half of the problem.
     */

    function _sound() {
        // AudioPulse generates the audible click on the audio sample
        // clock. This function now supplies only visual/haptic weight.
        if (_subIndex === 0)
            return levelAt(beatInBar)
        return -1
    }

    function _notify(indexInBar, subIndex, level) {
        if (subIndex === 0) {
            beat(indexInBar, level)
        } else {
            subBeat(indexInBar, subIndex)
        }
    }

    function _advanceAndSchedule() {
        if (!running) return

        var beatMs = 60000.0 / Math.max(1, bpm)
        var sc = Math.max(1, subCount)

        _subIndex++
        if (_subIndex >= sc) {
            _subIndex = 0
            _beatTime += beatMs
            beatInBar = (beatInBar + 1) % Math.max(1, beatsPerBar)
            if (beatInBar === 0)
                barCount++
        }

        _nextTick = _beatTime + _subIndex * (beatMs / sc)

        var now = _clock.now()
        // The app may have been throttled or suspended. Do not replay the
        // lost beats in a burst — reset the grid from here.
        if (now - _nextTick > 4 * beatMs) {
            _beatTime = now
            _subIndex = 0
            _nextTick = now
        }

        _arm(_nextTick)
    }

    function _arm(targetTime) {
        _clock.scheduleAt(targetTime)
    }

    function _onTimeout(timerError) {
        if (!running) return

        var now = _clock.now()
        var error = now - _nextTick

        // PrecisePulse normally emits on or after the deadline. Keep this
        // guard in case a platform timer reports unusually early.
        if (error < -0.25) {
            _arm(_nextTick)
            return
        }

        _logTick(error)

        // AudioPulse owns audible timing. Keep the public beatInBar value
        // on the beat being shown until the UI has been notified.
        var level = _sound()
        var idx = beatInBar
        var sub = _subIndex
        _notify(idx, sub, level)
        _advanceAndSchedule()
    }

    /*
     * Timing diagnostics. Off by default and one comparison per tick when
     * off, so it costs nothing to leave in.
     *
     * What it prints is the error of the *scheduler*: how far each tick
     * fired from its ideal instant. It says nothing about how long the
     * audio path then took, which is deliberate — if these numbers are
     * tight and the metronome still sways, the sway is downstream of QML
     * and no amount of timer work will fix it.
     */
    property bool logTiming: false

    property int _logCount: 0
    property real _logSum: 0
    property real _logMin: 0
    property real _logMax: 0
    property real _logStart: 0

    function _logReset() {
        _logCount = 0
        _logSum = 0
        _logMin = 9999
        _logMax = -9999
        _logStart = _clock.now()
    }

    function _logTick(err) {
        if (!logTiming) return
        _logCount++
        _logSum += err
        if (err < _logMin) _logMin = err
        if (err > _logMax) _logMax = err

        // Report once per 32 ticks, so it is a few lines a minute.
        if (_logCount % 32 !== 0) return
        var elapsed = _clock.now() - _logStart
        var expected = _logCount * (60000.0 / Math.max(1, bpm)) / Math.max(1, subCount)
        console.log("Fiat Cor timing: ticks=" + _logCount
                    + " mean=" + (_logSum / _logCount).toFixed(2) + "ms"
                    + " min=" + _logMin.toFixed(1) + "ms"
                    + " max=" + _logMax.toFixed(1) + "ms"
                    + " cumulative=" + (elapsed - expected).toFixed(1) + "ms")
        _logMin = 9999
        _logMax = -9999
    }

    // Audible timing is generated by AudioPulse.

    // ---- persistence ---------------------------------------------------
    // Settings are read once at startup and written on every change.
    // No two-way binding — that would loop.

    property QtObject _cfgBpm: ConfigurationValue { key: "/apps/fiatcor/bpm"; defaultValue: 90 }
    property QtObject _cfgBeats: ConfigurationValue { key: "/apps/fiatcor/beatsPerBar"; defaultValue: 4 }
    property QtObject _cfgNoteValue: ConfigurationValue { key: "/apps/fiatcor/noteValue"; defaultValue: 4 }
    property QtObject _cfgSub: ConfigurationValue { key: "/apps/fiatcor/subdivision"; defaultValue: "none" }
    property QtObject _cfgSound: ConfigurationValue { key: "/apps/fiatcor/sound"; defaultValue: true }
    property QtObject _cfgPattern: ConfigurationValue { key: "/apps/fiatcor/accentPattern"; defaultValue: "3,1,1,1" }

    /*
     * One handler per signal per object. QML rejects a second
     * onXxxChanged on the same object outright — "Property value set
     * multiple times" — and the whole type then fails to load, which
     * shows up at the use site as "Type Cor unavailable". So the accent
     * reset and the config write share a handler rather than living next
     * to the code they belong to.
     *
     * Changing the time signature resets the accents. Predictable beats
     * clever: a hand-built 7/8 grouping means nothing once it is 4/4.
     */
    onBpmChanged: {
        _cfgBpm.value = bpm
        _syncAudio()
    }
    onSubdivisionChanged: {
        _cfgSub.value = subdivision
        _syncAudio()
    }

    onBeatsPerBarChanged: {
        resetAccents()
        _cfgBeats.value = beatsPerBar
        _syncAudio()
    }

    onNoteValueChanged: {
        resetAccents()
        _cfgNoteValue.value = noteValue
        _syncAudio()
    }

    onSoundEnabledChanged: {
        _cfgSound.value = soundEnabled
        _syncAudio()
    }
    onAccentPatternChanged: {
        _cfgPattern.value = patternToString(accentPattern)
        _syncAudio()
    }

    function patternToString(p) {
        return p ? p.join(",") : ""
    }

    function patternFromString(s, beats) {
        var parts = String(s).split(",")
        if (parts.length !== beats)
            return null
        var p = []
        for (var i = 0; i < parts.length; i++) {
            var n = parseInt(parts[i], 10)
            if (isNaN(n) || n < 0 || n > 3)
                return null
            p.push(n)
        }
        return p
    }

    Component.onCompleted: {
        bpm = Math.max(minBpm, Math.min(maxBpm, _cfgBpm.value))
        noteValue = 4
        beatsPerBar = Math.max(1, Math.min(maxBeatsPerBar, _cfgBeats.value))
        var s = _cfgSub.value
        subdivision = (s === "eighth" || s === "triplet" || s === "sixteenth") ? s : "none"
        soundEnabled = _cfgSound.value === true

        // Restore the saved accents last: setting beatsPerBar and noteValue
        // above already reset the pattern to the default for that meter.
        var stored = patternFromString(_cfgPattern.value, beatsPerBar)
        accentPattern = stored !== null ? stored : defaultPattern(beatsPerBar, noteValue)

        _syncAudio()
    }
}
