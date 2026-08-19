# Fiat Cor

A metronome for Sailfish OS. *Cor* is Latin for heart — heart → pulse → beat,
the involuntary timekeeper. Part of the Fiat family alongside **Fiat Lux**
(light meter), **Fiat Vox** (tuner) and **Fiat Mos** (habits).

Same stack as the others: QML/Silica, qmake, SQLite through `LocalStorage`,
sound through `SoundEffect`.

---

## Quick start

```bash
cd ~/Projects/FiatCor
python3 tools/check.py          # syntax, ids, icon names, hex, DISTFILES, house rules
node tools/timing-sim.js        # proves the pulse does not drift
python3 tools/make_preview.py   # builds fiat-cor-preview.html to open in a browser
```

Build and deploy as usual in Qt Creator (**aarch64** kit for the phone,
**i486** for the emulator). After any change to the `.pro` or any new file:
**Build → Clean All → Run qmake → Build**.

---

## What it does

| # | Feature | |
|---|---|---|
| 1 | Drift-free pulse, visual heartbeat, click, start/stop | done |
| 2 | BPM slider 30–250, ±1 with auto-repeat, tap tempo | done |
| 3 | Time signature: 1–12 beats, note value 2/4/8/16 | done |
| 4 | Per-beat accents: strong / medium / plain / silent | done |
| 5 | Subdivision: none / eighths / triplets / sixteenths | done |
| 6 | Presets: save, load, delete — accents travel with them | done |
| 7 | Cover page beats in the background | done |
| 8 | Haptic feedback as an alternative to sound | done |

Settings survive a restart (`Nemo.Configuration`), the tempo term
(Largo…Prestissimo) sits under the BPM, and the heart keeps breathing
slowly while the metronome is stopped.

Deliberately not built: the Psalmprojektet link, the practice ramp,
polyrhythm.

---

## The time signature, and what the denominator actually does

This is worth being precise about, because it is easy to build something
that looks right and does nothing.

**The denominator on its own changes no sound.** 6/8 at 180 and 6/4 at 180
produce the identical click train. What the denominator genuinely buys you
is two things:

1. **The tempo mark means what the score means.** BPM counts the chosen
   note value, so a piece marked in 6/8 at 180 eighths is the same speed as
   4/4 at 90 quarters. The term under the number is computed from the
   quarter-note equivalent (`bpm * 4 / noteValue`), which is why 6/8 at 90
   reads *Largo* and not *Andante*.
2. **A sensible default grouping.** A denominator of 8 or 16 with a beat
   count divisible by three is compound time, so 6/8 comes out as 3+3 and
   12/8 as 3+3+3+3 without you touching anything.

Everything beyond that lives in the accents.

### The bar is the accent control

The row of dots under the heart is not a readout. **Tap a dot to cycle that
beat: strong → medium → plain → silent.** That is the whole feature — 7/8
as 2+2+3, a silent beat to practise against, a bar with no downbeat at all.
No extra control on the screen, and the dot sizes mean the pattern is
readable at a glance with the sound off.

Changing the beat count or the note value **resets the accents** to the
default for that metre. Predictable beats clever: a hand-built 7/8 grouping
means nothing once it is 4/4. "Reset accents" is in the pull-down menu.

---

## Architecture

```
qml/
├── qmldir                   # makes FiatCorTheme a singleton — see below
├── FiatCor.qml              # ApplicationWindow: creates Cor, applies the palette
├── Cor.qml                  # the pulse engine — timing, sound, haptics, persistence
├── FiatCorTheme.qml         # Fiat colours: the family standard, garnet accent
├── Storage.js               # LocalStorage, schema_version, migrations
├── components/              # PageHead, DialogHead, EmptyNote, MunkstolenMark,
│                            # Pill, WideButton, SectionLabel, BeatDots, PulseHeart
├── cover/CoverPage.qml
├── pages/                   # MetronomePage, PresetsPage, SavePresetDialog, AboutPage
└── sounds/                  # four synthesised clicks
```

**`qml/qmldir` is not optional.** It is what makes `FiatCorTheme` a singleton,
and it also has to list `Cor` — a directory containing a qmldir stops
resolving its own `.qml` files implicitly, so anything added at `qml/` root
must be listed there too. A missing qmldir does not produce an error. It
produces a completely white screen, because `!FiatCorTheme.ambient` on an
undefined singleton is `true` and the gradient colours behind it are
undefined.

**`Cor` lives in the ApplicationWindow, not on the page.** Two reasons: the
pulse has to survive navigating to the presets and back, and the cover has
to keep beating while the app is minimised. It is handed to the pages as an
initial property; the theme is a singleton and needs no threading.

Its id is `corEngine` and not `cor`, deliberately. It was `cor` first,
matching the property name on the pages, and every page came up null: in a
binding QML resolves an unqualified name against the object the binding sits
on before it looks at the file's ids, so `cor: cor` bound the page's own
property to itself. Do not tidy it back.

`components/` is not in the original project sketch. It exists because
`MetronomePage.qml` would otherwise be unmanageable, and because the cover
uses exactly the same pulse and bar components as the main view.

---

## Timing — the part that matters

A `Timer` with a fixed `interval = 60000/bpm` drifts. The simulation in
`tools/timing-sim.js` measures **14.3 seconds of drift over ten minutes** at
every tempo — each individual timeout carries its own small error and they
accumulate.

`Cor` counts in absolute instants instead. `_beatTime` is the *ideal*
instant of the beat you are standing on and advances by exactly one beat at
a time, regardless of when the timer actually fired. A beat that arrived
four milliseconds late makes the next beat four milliseconds shorter rather
than pushing the whole grid forward. The error stays where it happened.

The difference from the sketch in the brief (`startTime + beatCount *
interval`) is that `_beatTime` **accumulates** instead of multiplying. Same
freedom from drift, but it also survives dragging the BPM slider mid-session:
the tempo change takes effect at the next beat boundary instead of
retroactively rewriting history. Subdivisions hang off the inside of the
beat rather than forming their own chain, so the main beats stay on the grid
even if you change subdivision mid-bar.

**Two-stage scheduling** was the second thing needed. Qt runs timers as
`Qt::CoarseTimer` and allows 5% error — at 120 BPM that is 25 ms, which is
audible. The exception is timeouts under 20 ms, which run precisely. So
`_arm()` aims coarsely at a point short of the target, then re-arms with a
short precise timeout for the last stretch.

The margin on the coarse leg is **6%, not a flat 15 ms**. Qt's slack is
proportional: a 1000 ms coarse timer may fire 50 ms late. The first version
used a flat margin, overshot at slow tempi and put the beat 34 ms out. The
simulation caught it.

Ten minutes, same jitter model:

| | 60 BPM | 120 BPM | 250 BPM |
|---|---|---|---|
| naive Timer | 14349 ms out | 14334 ms | 14532 ms |
| Cor | **2.0 ms** | **2.0 ms** | **2.0 ms** |

Run `node tools/timing-sim.js` after any change to the engine.

**Still open, and worth being honest about.** Those numbers are a
*simulation* of the scheduler, and a simulation validates arithmetic, not a
system. It models Qt's coarse-timer slack and nothing else — not event-loop
blocking, and not the audio path. On the device the pulse can still be heard
to sway, and neither of those two is measured yet.

Two things have been done about it so far. A tick now runs in the order
**sound → schedule → visuals**: because the timer is armed against an
absolute instant, doing the animation work after re-arming means it cannot
push the next beat late. And `Cor.logTiming` prints the scheduler's own error
every 32 ticks, so it can be told apart from what happens downstream.

If the log is tight and it still sways, the sway is in the audio path, and
the real fix is a different architecture: synthesise a continuous stream and
write the clicks at exact sample offsets, so the sound card's clock is the
metronome and the UI follows it. That is a C++ `QIODevice` feeding
`QAudioOutput` — the mirror image of what Fiat Vox already does for input.

---

## Sound

Four synthesised clicks — no sample library, no licensing questions.
`tools/make_clicks.py` generates them: a fast-decaying tone with a little
harmonic body plus a noise transient on the first few milliseconds. The
transient is what makes the ear hear an attack rather than a beep.

| file | pitch | length | level |
|---|---|---|---|
| `click-strong.wav` | 1568 Hz (G6) | 55 ms | 0.92 |
| `click-medium.wav` | 1318 Hz (E6) | 50 ms | 0.80 |
| `click-normal.wav` | 1046 Hz (C6) | 55 ms | 0.62 |
| `click-sub.wav` | 1046 Hz, drier | 35 ms | 0.30 |

The four form a pitch and level hierarchy, so a bar reads as a shape rather
than a row of identical taps. The level differences live in the files, not in
`volume` — to rebalance, edit `VOICES` in `make_clicks.py` and re-run.

`SoundEffect` and not `MediaPlayer`: short latency, no pipeline to spin up.
The files are short enough not to queue on sixteenths at 250 BPM (60 ms
between clicks, longest file 55 ms).

---

## Design — Fiat colours

Fiat Cor implements the family standard: **two palettes behind one set of
names, switched by a single boolean** that is remembered between runs.

- `ambient = true` (the default) — everything comes from the user's ambience
  through `Theme.*`. No background is painted anywhere; the wallpaper *is*
  the background.
- `ambient = false` — Fiat colours. The app paints its own light paper and
  uses the family palette.

Toggled from the pull-down menu. The shared paper (`#F2EFE8` to `#D8D2C6`)
is what makes the four apps recognisable as a set on a home screen.

**The accent is the only thing that differs between apps**, and Fiat Cor's is
**garnet `#9E3B4E`** — a heart colour that is not an alarm. Fiat Lux has
burnt amber, Fiat Vox ink blue, Fiat Mos moss.

The family rule is that an accent must not collide with the app's own
semantic colours. A red accent would be a problem in an app that also uses
red to mean *wrong*. Fiat Cor does not, and cannot: **it has no verdicts at
all.** A metronome never tells you that you are wrong. Its four beat weights
are degrees of one emphasis, so they are all drawn from the accent and
nothing here means anything.

Everything lives in `qml/FiatCorTheme.qml`, and there is **not one hex
literal anywhere else under `qml/`**. `tools/check.py` fails the build if one
appears.

`FiatCorTheme.applyPalette()` is called once on the ApplicationWindow.
Silica's own chrome — menus, pull-down drawers, TextField underlines,
sliders — reads `Theme.*` directly and ignores anything set on individual
items; the palette hangs off the window and is inherited, so that one call is
what makes the drawers obey Fiat colours.

The house components (`PageHead`, `DialogHead`, `EmptyNote`,
`MunkstolenMark`) are shared with Fiat Mos verbatim apart from the theme
identifier. They exist because Silica's own `PageHeader`, `DialogHeader` and
`ViewPlaceholder` all draw in `Theme.highlightColor`, which is light text on
light paper under Fiat colours plus a dark ambience.

### The pulse

The movement is deliberately not a symmetrical breath. A beat goes out fast
(systole), rebounds part of the way, then sinks slowly home (diastole) —
three stages instead of two. That is the difference between a pulsing circle
and a heart.

Every duration scales against the beat interval and is capped, so it never
catches up with itself at 250 BPM. Beat weight drives amplitude and
brightness together. A silent beat still shows a faint ring, so the bar stays
readable when you have muted a beat on purpose. Stopped, the heart breathes
at about forty a minute.

The ripple travels to 1.9 × the core, which is why `coreSize` is set to half
the smaller dimension on the card — any larger and the ring spills over the
card border.

## Data model

```sql
CREATE TABLE schema_version (
    version    INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE preset (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT NOT NULL,
    bpm            INTEGER NOT NULL,
    beats_per_bar  INTEGER NOT NULL DEFAULT 4,
    note_value     INTEGER NOT NULL DEFAULT 4,     -- v2
    accent_pattern TEXT,                           -- v2, e.g. "3,1,1,2,1,1"
    subdivision    TEXT NOT NULL DEFAULT 'none'
                   CHECK (subdivision IN ('none','eighth','triplet','sixteenth')),
    created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);
```

`note_value` and `accent_pattern` arrived as **migration v2**, an additive
`ALTER TABLE`. Anyone who installed the first build keeps their presets and
gets sensible defaults. That is the whole migration principle working in
practice rather than in theory.

`psalm_number` is still out. The v3 migration sits ready as a comment in
`Storage.js` — two lines when you want it.

All SQL is on one line. Multi-line JavaScript strings do not work in
`tx.executeSql()`. `Storage.js` is in `DISTFILES`; without that it is not
deployed and the app starts with empty storage.

---

## Tools

| | |
|---|---|
| `tools/make_clicks.py` | generates the four wav files |
| `tools/check.py` | unbalanced braces, undeclared ids, self-bound properties, duplicate signal handlers, unconfirmed icon names, hardcoded hex outside `FiatCorTheme.qml`, unguarded page-filling rectangles, multi-line SQL, files missing from `DISTFILES` |
| `tools/timing-sim.js` | drift simulation, naive engine against Cor |
| `tools/make_preview.py` | builds the web preview |

`check.py` keeps a list of **confirmed working icon names**. Several
`icon-s-*` names do not exist on Sailfish. Do not add a name without having
seen it on the device.

Three of its rules exist because the mistake was made first, and each of
them is verified by deliberately breaking a file and confirming the rule
fires:

- **duplicate signal handlers.** Two `onBeatsPerBarChanged` on one object is
  not a warning — the type fails to load and the use site reports *Type Cor
  unavailable* with no hint as to why.
- **self-bound properties.** `cor: cor` binds a property to itself. QML
  resolves the right-hand name against the object the binding sits on before
  it looks at the file's ids, so the id is shadowed and the value is null
  forever. Silent, legal, and fatal.
- **unguarded page-filling rectangles.** Under an ambience a fill cancels the
  wallpaper; under Fiat colours it is required. So the rule is not *no fill*
  but *no fill without* `visible: !FiatCorTheme.ambient`.

Two bugs in the checker itself are worth remembering. The property regex used
`\s+` for the type token, which let one match swallow the next declaration
across the newline, so it reported ids declared two lines above. And the
first background rule was a regex that could not cope with the nested
`Gradient`/`GradientStop` blocks, so it never matched anything and passed
everything — a rule that looks like a rule and is not. It counts braces now.
A checker that lies is worse than no checker.

The two cover icons (`icon-cover-play`, `icon-cover-pause`) are standard
names but **not verified on this device** — check them on first deploy.

---

## SDK notes (shared with Fiat Lux and Fiat Vox)

- **Not Docker for the build engine.** It cannot reach the VirtualBox
  emulator. VirtualBox.
- VirtualBox 7.0+ host-only network has to be created by hand:

```bash
sudo mkdir -p /etc/vbox
echo "* 10.220.220.0/24" | sudo tee /etc/vbox/networks.conf
sudo VBoxManage hostonlyif create
sudo VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.220.220.1 --netmask 255.255.255.0
```

- **No `Requires:` line** for QtMultimedia, QtFeedback or Nemo.Configuration
  in `rpm/FiatCor.spec` — all three ship with the OS. Check with
  `ls /usr/lib64/qt5/qml/QtMultimedia/` before adding anything; a package
  that does not exist fails the install with *Paketet hittades ej*.
- `QT += multimedia` is **not** in the `.pro` either. The QML module loads at
  runtime from the import, so the `-devel` package is not needed in the build
  target.
- The `[X-Sailjail]` block in `FiatCor.desktop` is **commented out** for
  sideloading. Uncomment it and change `Exec` before submitting to Chum or
  the Store.
- **Open Application Output when running on the device.** QML binding errors
  print there with line numbers.

---

## What to look at on first deploy

1. **Haptics.** `QtFeedback` is created with `Qt.createQmlObject` and falls
   back to silence if the module is missing. The log says *"Fiat Cor:
   haptics unavailable"* if so.
2. **Click latency.** `SoundEffect` should be a few milliseconds, but check
   against a known metronome. The drift is measured; a constant offset
   between the flash and the click is not.
3. **The beat dots at twelve beats.** A slot is about 37 px wide there. The
   touch target is the full slot and the full row height, but it is the one
   place in the app where the target is genuinely small.
4. **The cover pulse.** Sailfish may throttle animations on the cover. The
   engine ticks regardless, but the movement may be choppy.
5. **The `_arm()` margin on real hardware.** The simulation assumes Qt's
   documented 5%. If the pulse sounds uneven at slow tempi on the device,
   that is the first place to look.
