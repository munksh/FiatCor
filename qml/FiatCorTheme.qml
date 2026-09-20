pragma Singleton

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

// Fiat colours — the family standard. Two palettes behind one set of names,
// switched by a single boolean that is remembered between runs.
//
//   ambient = true   the user's ambience via Theme.*. No background is
//                    painted anywhere; the wallpaper is the background.
//   ambient = false  Fiat colours. The app paints its own light background
//                    and uses the family palette.
//
// Semantic colours ignore both. Fiat Cor has none — see the note by the
// beat weights below.

QtObject {
    id: t

    // ---- the switch, remembered between runs ----
    property ConfigurationValue ambientConfig: ConfigurationValue {
        key: "/apps/fiatcor/ambient"
        defaultValue: true
    }
    readonly property bool ambient: ambientConfig.value
    function setAmbient(on) { ambientConfig.value = on }

    // Fiat colours are a light scheme, so dark is false there.
    readonly property bool dark: ambient ? (Theme.colorScheme === Theme.LightOnDark) : false

    readonly property string serif: "Georgia"

    // ---- the notch ----
    //
    // Silica's own PageHeader clears the cutout. Ours do not, because they are
    // ours -- and on the Jolla Phone (2026) that puts the top of a capital
    // letter, and the left end of a long right-aligned title, straight into the
    // hole. So every header in this app starts this far down.
    //
    // Read from the platform when the platform will say. The property is not
    // guaranteed to exist, and asking a QObject for a property it does not have
    // returns undefined rather than throwing, so the probe is safe -- but it
    // does mean the fallback has to be a real number, not a hope.
    function cutoutHeight() {
        if (typeof Screen === "undefined" || Screen === null) return -1
        var c = Screen.topCutout
        if (c === undefined || c === null) return -1
        if (typeof c === "number") return c
        if (c.height !== undefined) return c.height
        return -1
    }

    readonly property real headerTopInsetFallback: Theme.paddingLarge * 1.5

    readonly property real headerTopInset: {
        var c = cutoutHeight()
        return c >= 0 ? c + Theme.paddingMedium : headerTopInsetFallback
    }

    // Where the system's own indicators sit. Anything of ours that belongs on
    // that line is centred on it rather than given a top margin.
    readonly property real statusRowCenter: Theme.itemSizeLarge / 2

    // ---- text and accent ----
    readonly property color primaryText:   ambient ? Theme.primaryColor   : "#1A1A1A"
    readonly property color secondaryText: ambient ? Theme.secondaryColor : Qt.rgba(0.10, 0.10, 0.10, 0.55)

    // Fiat Cor's accent: garnet. A heart colour that is not an alarm.
    //
    // The family rule is that an accent must not collide with the app's own
    // semantic colours. A red accent would be a problem in an app that also
    // uses red to mean "wrong" — Fiat Cor does not, and cannot: it has no
    // verdicts at all. A metronome never tells you that you are wrong. Its
    // four beat weights are degrees of one emphasis, so they are all drawn
    // from this accent and nothing here means anything.
    readonly property color accent: ambient ? Theme.highlightColor : "#8054AD"

    function mixColor(a, b, t) {
        return Qt.rgba(
            a.r * (1.0 - t) + b.r * t,
            a.g * (1.0 - t) + b.g * t,
            a.b * (1.0 - t) + b.b * t,
            1.0
        )
    }

    // A muted variant of the accent, for the Silica chrome that draws with
    // palette.highlightColor directly -- the pull-down menu's revealed label
    // chief among them. Found on Fiat Mos: a saturated accent used raw there
    // reads far louder as a large glowing fill than it does as a button or a
    // mark. This mutes only that role; everything the app draws itself still
    // uses the full accent above.
    readonly property color chromeAccent: mixColor(accent, primaryText, 0.35)

    // ---- the shared paper ----
    readonly property color backgroundHigh: "#F2EFE8"
    readonly property color backgroundLow:  "#D8D2C6"

    readonly property color card: ambient
        ? (dark ? Qt.rgba(0.08, 0.08, 0.08, 1.0) : Qt.rgba(0.96, 0.96, 0.96, 1.0))
        : "#F5F5F5"
    readonly property color surface: card
    readonly property color cardBorder:   Theme.rgba(primaryText, 0.45)
    readonly property color innerBorder:  Theme.rgba(primaryText, 0.22)
    readonly property color recessFill:   Theme.rgba(primaryText, 0.05)
    readonly property color recessBorder: Theme.rgba(primaryText, 0.16)
    readonly property real cardRadius: Theme.paddingLarge * 2
    readonly property int cardBorderWidth: 2

    // ---- pills ----
    readonly property color pillFill:         Theme.rgba(primaryText, 0.15)
    readonly property color pillBorder:       Theme.rgba(primaryText, 0.55)
    readonly property color pillFillActive:   Theme.rgba(accent, 0.20)
    readonly property color pillBorderActive: accent
    readonly property color pillText:         primaryText
    readonly property color pillTextActive:   accent

    // Unfilled dots, ring tracks, anything absent.
    readonly property color dotIdle: Theme.rgba(primaryText, 0.22)

    // ---- the beat ----
    //
    // Four weights: strong, medium, plain, silent. Degrees of one scale and
    // not four colours, which is why none of them is semantic and all of them
    // come from the accent or the text colour.
    function beatColor(level) {
        if (level === 3) return accent
        if (level === 2) return Theme.rgba(accent, 0.60)
        if (level === 1) return Theme.rgba(primaryText, 0.45)
        return dotIdle
    }

    // Relative dot size per weight, so a bar can be read by shape alone with
    // the sound off.
    function beatScale(level) {
        if (level === 3) return 1.0
        if (level === 2) return 0.82
        if (level === 1) return 0.62
        return 0.52
    }

    // The heart. The resting fill is deliberately faint: what carries the
    // pulse is the change, not the steady state.
    readonly property color heartResting: Theme.rgba(primaryText, 0.10)
    readonly property color heartRim: innerBorder
    readonly property color heartBeat: accent
    readonly property color ripple: accent
    readonly property color subRing: Theme.rgba(primaryText, 0.45)

    // Readable mark drawn on top of an accent fill. Measure the accent's
    // luminance rather than guessing from the colour scheme — an ambience can
    // pair a light scheme with a dark highlight or the other way round.
    // A function, not a chain of readonly bindings: the chained version came
    // out undefined on the device, and an undefined colour does not shout, it
    // silently renders black.
    function markOn(c) {
        if (c === undefined || c === null) return "#F5F5F5"
        return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.55 ? "#1A1A1A" : "#F5F5F5"
    }

    readonly property color onAccent: markOn(accent)

    // ---- the maker's mark ----
    //
    // Taupe, and a FIXED value: this one deliberately does not follow the
    // ambience, for the same reason the launcher icon does not. It is
    // Munkstolen's colour, not the app's.
    readonly property color makerMark: "#7E7566"

    // The wash under a pressed row or menu item.
    readonly property color highlightWash: Theme.rgba(accent, 0.15)

    // ---- Silica's own chrome ----
    //
    // Menus, pull-down drawers, TextField labels and underlines, sliders,
    // selection: none of these takes a colour from us. They read Theme.*
    // directly, which is the ambience, which is why they stay
    // ambience-coloured under Fiat colours however many `color:` lines are
    // added to individual items.
    //
    // Silica's answer is `palette` — colour roles that hang off an item and
    // are inherited by its children. Set it once on the ApplicationWindow.
    //
    // Written defensively on purpose. `palette` and its roles are not
    // guaranteed to exist on every Silica version, and a missing property
    // assigned in a QML binding is a load-time error — the whole page dies.
    // Assigned from JavaScript instead, a missing property is a no-op.
    function applyPalette(item) {
        if (item === null || item === undefined) return
        var p = item.palette
        if (p === undefined || p === null) return
        try { p.colorScheme = ambient ? Theme.colorScheme : Theme.DarkOnLight } catch (e) { }
        try { p.primaryColor = primaryText } catch (e) { }
        try { p.secondaryColor = secondaryText } catch (e) { }
        try { p.highlightColor = chromeAccent } catch (e) { }
        try { p.secondaryHighlightColor = Theme.rgba(chromeAccent, 0.6) } catch (e) { }
        // A neutral wash for in-app selection/highlight surfaces. NOT the
        // virtual keyboard -- that turned out to be a separate surface
        // (Maliit/FutoKeyboard) that reads Theme.*, the system ambience,
        // directly. It cannot be reached from an app's palette at all, so
        // this project does not try; it follows the ambience.
        try { p.highlightBackgroundColor = Theme.rgba(primaryText, 0.12) } catch (e) { }
        try { p.highlightDimmerColor = ambient ? Theme.highlightDimmerColor : backgroundLow } catch (e) { }
        try { p.overlayBackgroundColor = ambient ? Theme.overlayBackgroundColor : backgroundHigh } catch (e) { }
    }

    // Cover layout
    readonly property real coverWordmarkTop: Theme.paddingLarge
    readonly property real coverSideMargin: Theme.paddingLarge

    // The tempo is the figure now, not the heart, so Cor sits on the family's
    // text line -- the same 0.28 as Mos's count and Vox's letter. The shape
    // line (0.20) the old cover used is gone with it.
    readonly property real coverFigureFraction: 0.28
    readonly property int coverFigureSize: Theme.fontSizeHuge

    // The family maximum: nothing on a cover is wider than half of it.
    readonly property real coverArtFraction: 0.5

    // The heart hangs under the number, so it is deliberately below that
    // maximum. At a full 0.5 it reads as a second figure competing with the
    // tempo rather than as the tempo's pulse. Raise it to coverArtFraction if
    // the small one looks weak on the device.
    readonly property real coverHeartFraction: 0.38
}
