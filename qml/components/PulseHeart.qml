/*
 * PulseHeart — the app's signature.
 *
 * Not a training wheel for the sound but the point of the thing: it has
 * to be possible to hold the beat on sight alone, in a quiet church or
 * late at night with the sound off.
 *
 * The movement is deliberately not a symmetrical breath. A beat goes out
 * fast (systole), rebounds part of the way, then sinks slowly home
 * (diastole). Three stages instead of two — that is the difference
 * between a pulsing circle and a heart.
 *
 * Every duration scales against the beat interval and is capped, so the
 * movement never catches up with itself at 250 BPM.
 *
 * Beat weight drives amplitude and brightness together: a strong beat
 * moves further and flashes harder than a medium one. A silent beat
 * still shows a faint ring, so the bar stays readable when you have
 * muted a beat on purpose.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Item {
    id: root

    property QtObject cor

    property real coreSize: Math.min(width, height) * 0.56
    property bool showRipple: true

    signal clicked

    function _beatMs() {
        return 60000.0 / Math.max(1, root.cor ? root.cor.bpm : 90)
    }

    function beatPulse(level) {
        if (level <= 0) {
            // Silent beat: the ring alone, so you can still see where the
            // bar is without hearing or feeling anything.
            subPulse()
            return
        }

        var beatMs = _beatMs()
        var amp = level === 3 ? 0.30 : (level === 2 ? 0.21 : 0.14)
        var flashTo = level === 3 ? 0.95 : (level === 2 ? 0.66 : 0.40)

        beatAnim.stop()
        upAnim.to = 1.0 + amp
        upAnim.duration = Math.max(40, Math.min(75, beatMs * 0.13))
        recoilAnim.to = 1.0 + amp * 0.34
        recoilAnim.duration = Math.max(50, Math.min(100, beatMs * 0.17))
        settleAnim.duration = Math.max(90, Math.min(300, beatMs * 0.46))
        beatAnim.start()

        flash.opacity = flashTo
        flashAnim.duration = Math.max(100, Math.min(340, beatMs * 0.58))
        flashAnim.restart()

        if (root.showRipple) {
            ripple.scale = 1.0
            ripple.opacity = level === 3 ? 0.5 : (level === 2 ? 0.32 : 0.18)
            rippleAnim.pulseMs = Math.max(180, Math.min(560, beatMs * 0.9))
            rippleAnim.restart()
        }
    }

    function subPulse() {
        subRing.opacity = 0.45
        subAnim.restart()
    }

    function reset() {
        beatAnim.stop()
        flashAnim.stop()
        rippleAnim.stop()
        subAnim.stop()
        body.scale = 1.0
        flash.opacity = 0.0
        ripple.opacity = 0.0
        subRing.opacity = 0.0
    }

    // ---- the ring that spreads outward ------------------------------

    Rectangle {
        id: ripple
        anchors.centerIn: parent
        width: root.coreSize
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: FiatCorTheme.ripple
        opacity: 0.0
    }

    // ---- the subdivision ring ---------------------------------------

    Rectangle {
        id: subRing
        anchors.centerIn: parent
        width: root.coreSize * 1.22
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: FiatCorTheme.subRing
        opacity: 0.0
    }

    // ---- the heart itself -------------------------------------------

    Item {
        id: body
        anchors.centerIn: parent
        width: root.coreSize
        height: width

        Rectangle {
            id: core
            anchors.fill: parent
            radius: width / 2
            color: FiatCorTheme.heartResting
            border.width: 1
            border.color: FiatCorTheme.heartRim
        }

        Rectangle {
            id: flash
            anchors.fill: parent
            radius: width / 2
            color: FiatCorTheme.heartBeat
            opacity: 0.0
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    // ---- animations --------------------------------------------------

    SequentialAnimation {
        id: beatAnim
        NumberAnimation {
            id: upAnim
            target: body; property: "scale"
            duration: 60; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: recoilAnim
            target: body; property: "scale"
            duration: 80; easing.type: Easing.OutQuad
        }
        NumberAnimation {
            id: settleAnim
            target: body; property: "scale"; to: 1.0
            duration: 220; easing.type: Easing.InOutQuad
        }
    }

    NumberAnimation {
        id: flashAnim
        target: flash; property: "opacity"; to: 0.0
        duration: 200; easing.type: Easing.OutQuad
    }

    ParallelAnimation {
        id: rippleAnim
        property int pulseMs: 520
        NumberAnimation {
            target: ripple; property: "scale"; to: 1.9
            duration: rippleAnim.pulseMs; easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: ripple; property: "opacity"; to: 0.0
            duration: rippleAnim.pulseMs; easing.type: Easing.OutQuad
        }
    }

    NumberAnimation {
        id: subAnim
        target: subRing; property: "opacity"; to: 0.0
        duration: 140; easing.type: Easing.OutQuad
    }

    // Resting pulse. The metronome is stopped; the heart never is.
    // Roughly forty a minute, slower than anything you could play.
    SequentialAnimation {
        id: idleAnim
        running: root.cor !== null && root.cor !== undefined && !root.cor.running
        loops: Animation.Infinite
        NumberAnimation {
            target: body; property: "scale"
            from: 1.0; to: 1.04; duration: 620; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: body; property: "scale"; to: 1.0
            duration: 880; easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 100 }
        onStopped: body.scale = 1.0
    }

    Connections {
        target: root.cor
        onBeat: root.beatPulse(level)
        onSubBeat: root.subPulse()
        onRunningChanged: if (root.cor && !root.cor.running) root.reset()
    }
}
