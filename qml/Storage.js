/*
 * Storage.js — saved tempos in SQLite via QML LocalStorage.
 *
 * Two rules that cost time in Fiat Lux and apply here too:
 *   1. This file MUST be listed under DISTFILES in harbour-fiatcor.pro, or it is
 *      not deployed and the app starts with empty storage.
 *   2. Every SQL string in tx.executeSql() sits on ONE line. Multi-line
 *      JavaScript strings do not work there.
 *
 * Migrations are additive and version-driven through schema_version.
 * No destructive changes, no DROP, no redefined column. The next
 * migration is one more if-block at the bottom.
 */

.import QtQuick.LocalStorage 2.0 as LS

var SCHEMA_VERSION = 2

function _db() {
    return LS.LocalStorage.openDatabaseSync("FiatCor", "", "Fiat Cor", 1000000)
}

function init() {
    _db().transaction(function (tx) {
        tx.executeSql("CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL DEFAULT (datetime('now')))")

        var v = 0
        var rs = tx.executeSql("SELECT MAX(version) AS v FROM schema_version")
        if (rs.rows.length > 0 && rs.rows.item(0).v !== null)
            v = rs.rows.item(0).v

        if (v < 1) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS preset (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, bpm INTEGER NOT NULL, beats_per_bar INTEGER NOT NULL DEFAULT 4, subdivision TEXT NOT NULL DEFAULT 'none' CHECK (subdivision IN ('none','eighth','triplet','sixteenth')), created_at TEXT NOT NULL DEFAULT (datetime('now')))")
            tx.executeSql("INSERT INTO schema_version (version) VALUES (1)")
            v = 1
        }

        // v2 — the beat unit and the accent weights. Additive, so anyone
        // who already installed the first build keeps their presets and
        // gets 4 as the note value and a default accent pattern.
        if (v < 2) {
            tx.executeSql("ALTER TABLE preset ADD COLUMN note_value INTEGER NOT NULL DEFAULT 4")
            tx.executeSql("ALTER TABLE preset ADD COLUMN accent_pattern TEXT")
            tx.executeSql("INSERT INTO schema_version (version) VALUES (2)")
            v = 2
        }

        // v3 — the Psalmprojektet link, when it goes in. Also additive:
        //
        // if (v < 3) {
        //     tx.executeSql("ALTER TABLE preset ADD COLUMN psalm_number INTEGER")
        //     tx.executeSql("INSERT INTO schema_version (version) VALUES (3)")
        //     v = 3
        // }
    })
}

function savePreset(name, bpm, beatsPerBar, noteValue, subdivision, accentPattern) {
    var newId = -1
    _db().transaction(function (tx) {
        var rs = tx.executeSql("INSERT INTO preset (name, bpm, beats_per_bar, note_value, subdivision, accent_pattern) VALUES (?, ?, ?, ?, ?, ?)",
                               [name, bpm, beatsPerBar, noteValue, subdivision, accentPattern])
        newId = rs.insertId
    })
    return newId
}

function updatePreset(id, name, bpm, beatsPerBar, noteValue, subdivision, accentPattern) {
    _db().transaction(function (tx) {
        tx.executeSql("UPDATE preset SET name = ?, bpm = ?, beats_per_bar = ?, note_value = ?, subdivision = ?, accent_pattern = ? WHERE id = ?",
                      [name, bpm, beatsPerBar, noteValue, subdivision, accentPattern, id])
    })
}

function loadPresets(model) {
    model.clear()
    _db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT id, name, bpm, beats_per_bar, note_value, subdivision, accent_pattern FROM preset ORDER BY name COLLATE NOCASE ASC")
        for (var i = 0; i < rs.rows.length; i++) {
            var r = rs.rows.item(i)
            model.append({
                "presetId": r.id,
                "name": r.name,
                "bpm": r.bpm,
                "beatsPerBar": r.beats_per_bar,
                "noteValue": r.note_value,
                "subdivision": r.subdivision,
                "accentPattern": r.accent_pattern === null ? "" : r.accent_pattern
            })
        }
    })
}

function deletePreset(id) {
    _db().transaction(function (tx) {
        tx.executeSql("DELETE FROM preset WHERE id = ?", [id])
    })
}

function presetCount() {
    var n = 0
    _db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT COUNT(*) AS n FROM preset")
        if (rs.rows.length > 0)
            n = rs.rows.item(0).n
    })
    return n
}
