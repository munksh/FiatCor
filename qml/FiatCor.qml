import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "pages"
import "cover"
import "Storage.js" as Storage

// Fiat Cor — a metronome for Sailfish OS.
//
// Cor is Latin for heart. Heart → pulse → beat: the involuntary timekeeper.
// Sibling to Fiat Lux, Fiat Vox and Fiat Mos.
//
// The pulse engine is created here rather than on the page, so that the
// pulse survives navigating to the presets and back, and so the cover can
// keep beating while the app is minimised.
//
//
// WHY THE ID IS corEngine AND NOT cor
// ------------------------------------------------------------------
// It was `cor` first, matching the property name on the pages, and every
// page came up with it null.
//
// In a binding, QML resolves an unqualified name against the *scope object*
// -- the object the binding belongs to -- before it looks at the file's ids.
// MetronomePage has its own property called `cor`, so `cor: cor` inside it
// resolved to the page's own (still undefined) property and bound it to
// itself. Silent, legal, and null forever. Do not "tidy" it back.

ApplicationWindow {
    id: app

    Cor { id: corEngine }

    initialPage: Component {
        MetronomePage { cor: corEngine }
    }

    cover: Component {
        CoverPage { cor: corEngine }
    }

    allowedOrientations: defaultAllowedOrientations

    // Silica's own chrome -- menus, pull-down drawers, TextField underlines,
    // sliders -- reads Theme.* directly and ignores anything we set on
    // individual items. The palette hangs off this window and is inherited
    // by everything below it, so this one call is what makes the drawers and
    // the fields obey Fiat colours.
    Component.onCompleted: {
        FiatCorTheme.applyPalette(app)
        Storage.init()
    }

    Connections {
        target: FiatCorTheme
        onAmbientChanged: FiatCorTheme.applyPalette(app)
    }
}
