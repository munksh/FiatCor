/*
 * timing-sim.js — proves the pulse engine does not drift.
 *
 * Run:  node tools/timing-sim.js
 *
 * Simulates a virtual clock where every timeout fires late the way
 * Qt::CoarseTimer does in reality (up to 5% over 20 ms, a millisecond or
 * so under). The same practice session then runs through two engines:
 *
 *   naive  — a Timer with a fixed interval = 60000/bpm, restarted each beat
 *   cor    — the algorithm in qml/Cor.qml: absolute _beatTime, plus
 *            two-stage scheduling so the last leg is a precise timer
 *
 * The measure is the gap between when beat N actually sounded and when it
 * should have. The naive engine drifts linearly; Cor does not.
 */

function makeJitter(seed) {
    // deterministic pseudo-random so runs are comparable
    var s = seed
    return function () {
        s = (s * 1103515245 + 12345) & 0x7fffffff
        return s / 0x7fffffff
    }
}

/*
 * Qt treats timeouts >= 20 ms as Qt::CoarseTimer and allows up to 5%
 * error. Under 20 ms they run precisely. Timers never fire early, only
 * late.
 */
function fireTime(now, interval, rnd) {
    if (interval >= 20)
        return now + interval + interval * 0.05 * rnd()
    return now + interval + 1.5 * rnd()
}

function runNaive(bpm, minutes, seed) {
    var rnd = makeJitter(seed)
    var interval = 60000 / bpm
    var endAt = minutes * 60000
    var now = 0
    var beat = 0
    var worst = 0
    var last = 0
    while (now < endAt) {
        var err = now - beat * interval
        if (Math.abs(err) > Math.abs(worst)) worst = err
        last = err
        now = fireTime(now, interval, rnd)
        beat++
    }
    return { beats: beat, worst: worst, final: last }
}

function runCor(bpm, minutes, seed, subCount) {
    var rnd = makeJitter(seed)
    var beatMs = 60000 / bpm
    var sc = subCount || 1
    var endAt = minutes * 60000

    var now = 0
    var beatTime = 0        // ideal instant of the current main beat
    var nextTick = 0
    var subIndex = 0
    var beatNo = 0
    var worst = 0
    var last = 0

    function arm(delay) {
        // coarse leg with a 6% margin (Qt's slack is 5% and proportional),
        // then a precise leg under 20 ms
        return delay > 18
            ? Math.round(delay - Math.max(15, delay * 0.06))
            : Math.max(0, Math.round(delay))
    }

    while (now < endAt) {
        if (subIndex === 0) {
            var err = now - beatNo * beatMs
            if (Math.abs(err) > Math.abs(worst)) worst = err
            last = err
        }

        // _advanceAndSchedule
        subIndex++
        if (subIndex >= sc) {
            subIndex = 0
            beatTime += beatMs
            beatNo++
        }
        nextTick = beatTime + subIndex * (beatMs / sc)

        // the _onTimeout loop: re-arm until we are there
        var guard = 0
        for (;;) {
            var remaining = nextTick - now
            if (remaining <= 2) break
            now = fireTime(now, arm(remaining), rnd)
            if (++guard > 50) throw new Error("does not converge")
        }
    }
    return { beats: beatNo, worst: worst, final: last }
}

function report(label, r) {
    console.log(
        "  %s  beats: %d   worst error: %s ms   at the end: %s ms",
        label.padEnd(6),
        r.beats,
        r.worst.toFixed(1).padStart(9),
        r.final.toFixed(1).padStart(9))
}

var minutes = 10
var failures = 0

;[60, 90, 120, 208, 250].forEach(function (bpm) {
    console.log("\n" + bpm + " BPM, a " + minutes + " minute practice session")
    var naive = runNaive(bpm, minutes, 7)
    var cor = runCor(bpm, minutes, 7, 1)
    var cor16 = runCor(bpm, minutes, 7, 4)
    report("naive", naive)
    report("cor", cor)
    report("cor/16", cor16)

    // The requirement: main beats never more than 5 ms out, however long
    // the session runs. Below that you cannot hear it.
    if (Math.abs(cor.worst) > 5) { console.log("  ** FAIL: cor drifts **"); failures++ }
    if (Math.abs(cor16.worst) > 5) { console.log("  ** FAIL: cor/16 drifts **"); failures++ }
    if (Math.abs(naive.final) < 50) { console.log("  ** FAIL: naive did not drift, the simulation is measuring the wrong thing **"); failures++ }
})

console.log("\n" + (failures === 0 ? "OK — the engine holds the pulse" : failures + " failures"))
process.exit(failures === 0 ? 0 : 1)
