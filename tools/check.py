#!/usr/bin/env python3
"""
Pre-build sanity check for Fiat Cor.

Not a substitute for a real QML parser, but it catches the mistakes that
actually creep into a QML project before you have even started the
emulator:

  * unbalanced braces / parens (comments and strings ignored)
  * ids referenced but never declared in the file
  * theme icon names not on the confirmed list
  * hardcoded hex anywhere under qml/ — the app is ambience first
  * a page-level background rectangle, which cancels the ambience
  * multi-line SQL in tx.executeSql()
  * files under qml/ missing from DISTFILES

Run:  python3 tools/check.py
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Theme icons confirmed to exist. Several icon-s-* names do not; do not add
# anything here without having seen it on the device.
KNOWN_ICONS = {
    "icon-m-edit", "icon-m-add", "icon-m-delete", "icon-m-accept",
    "icon-m-acknowledge", "icon-s-secure",
    "icon-cover-play", "icon-cover-pause", "icon-cover-next",
}

errors = []
warnings = []


def strip_comments_and_strings(src):
    """Replaces comments and string contents with spaces."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                out.append(" ")
                i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            while i < n and not (src[i] == "*" and i + 1 < n and src[i + 1] == "/"):
                out.append("\n" if src[i] == "\n" else " ")
                i += 1
            out.append("  ")
            i += 2
        elif c in "\"'":
            quote = c
            out.append(" ")
            i += 1
            while i < n and src[i] != quote:
                if src[i] == "\\":
                    out.append(" ")
                    i += 1
                if i < n:
                    out.append("\n" if src[i] == "\n" else " ")
                    i += 1
            out.append(" ")
            i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def check_balance(path, src):
    code = strip_comments_and_strings(src)
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    line = 1
    for ch in code:
        if ch == "\n":
            line += 1
        elif ch in "([{":
            stack.append((ch, line))
        elif ch in ")]}":
            if not stack:
                errors.append("%s:%d unbalanced '%s'" % (path, line, ch))
                return
            open_ch, open_line = stack.pop()
            if open_ch != pairs[ch]:
                errors.append("%s:%d '%s' closes '%s' opened on line %d"
                              % (path, line, ch, open_ch, open_line))
                return
    if stack:
        open_ch, open_line = stack[-1]
        errors.append("%s: '%s' on line %d is never closed" % (path, open_ch, open_line))


# Names that exist without being declared in the file: QML/JS globals,
# Silica enums, grouped properties and context properties injected by
# delegates and the page stack.
GLOBALS = {
    "Qt", "Math", "Date", "JSON", "Number", "String", "Object", "Array",
    "console", "parseInt", "parseFloat", "isNaN", "undefined", "null",
    "Theme", "Screen", "Orientation", "PageStatus", "DialogResult",
    "Easing", "Animation", "Text", "TextInput", "TruncationMode", "Font",
    "Component", "LocalStorage", "LS", "Storage",
    "parent", "pageStack", "index", "modelData", "model", "item",
    "this", "arguments", "e", "tx", "rs", "r", "v", "n", "i", "s", "p",
    # grouped properties are written with a dot but are not ids
    "anchors", "font", "border", "easing", "gradient", "layer",
    "inputMethodHints", "textFormat", "EnterKey",
}

# The type token must not be allowed to cross a newline. An earlier version
# used \s+ there, which let one match swallow the next declaration whole —
# so the checker reported ids that were declared two lines up.
DECL_RE = re.compile(
    r"\bid\s*:\s*([A-Za-z_][A-Za-z0-9_]*)"
    r"|\bproperty[ \t]+(?:alias[ \t]+)?[A-Za-z_][A-Za-z0-9_<>\.]*[ \t]+([A-Za-z_][A-Za-z0-9_]*)"
    r"|\bfunction[ \t]+([A-Za-z_][A-Za-z0-9_]*)"
    r"|\bsignal[ \t]+([A-Za-z_][A-Za-z0-9_]*)"
    r"|\bvar[ \t]+([A-Za-z_][A-Za-z0-9_]*)")

# Function parameters are declarations too.
PARAM_RE = re.compile(r"\bfunction[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]*\(([^)]*)\)")

USE_RE = re.compile(r"(?<![\w\.\"'])([a-z_][A-Za-z0-9_]*)\s*\.")


def check_ids(path, src):
    """
    An id that is referenced but never declared throws at runtime and the
    element falls back to its default appearance — that is exactly how the
    white bar in Fiat Lux happened, silently and with no error dialog.
    """
    code = strip_comments_and_strings(src)
    declared = set()
    for m in DECL_RE.finditer(code):
        for g in m.groups():
            if g:
                declared.add(g)
    for m in PARAM_RE.finditer(code):
        for arg in m.group(1).split(","):
            arg = arg.strip()
            if arg:
                declared.add(arg)

    for m in USE_RE.finditer(code):
        name = m.group(1)
        if name in declared or name in GLOBALS:
            continue
        line = code[:m.start()].count("\n") + 1
        errors.append("%s:%d '%s' is referenced but not declared in this file"
                      % (path, line, name))


def check_icons(path, src):
    for m in re.finditer(r"image://theme/([A-Za-z0-9\-_]+)", src):
        if m.group(1) not in KNOWN_ICONS:
            errors.append("%s: unconfirmed icon name '%s'" % (path, m.group(1)))


def check_hex(path, src):
    """
    Fiat Cor is ambience first and has no palette of its own. Only meaning
    may be hardcoded, and this app's accent levels are degrees of one
    scale, so nothing here qualifies. Zero hex under qml/.
    """
    for i, raw in enumerate(src.splitlines(), 1):
        if raw.strip().startswith(("*", "//", "/*")):
            continue
        if re.search(r"[\"']#[0-9A-Fa-f]{3,8}[\"']", raw):
            errors.append("%s:%d hardcoded hex — go through Theme/Palette" % (path, i))


BG_RE = re.compile(r"Rectangle\s*\{[^}]{0,200}?anchors\.fill\s*:\s*parent", re.S)


def check_no_page_background(path, src):
    """
    The ambience wallpaper is the background. A Rectangle filling a page or
    the cover cancels it. Cards and internal fills live in components/,
    which is why this only looks at pages/ and cover/.
    """
    if not (path.startswith("qml/pages/") or path.startswith("qml/cover/")):
        return
    code = strip_comments_and_strings(src)
    for m in BG_RE.finditer(code):
        line = code[:m.start()].count("\n") + 1
        errors.append("%s:%d Rectangle filling the page — this cancels the ambience"
                      % (path, line))


def check_sql(path, src):
    if not path.endswith("Storage.js"):
        return
    for i, raw in enumerate(src.splitlines(), 1):
        if "executeSql(" in raw and raw.count('"') % 2 != 0:
            errors.append("%s:%d SQL string broken across a line end" % (path, i))


def check_distfiles():
    pro = open(os.path.join(ROOT, "FiatCor.pro"), encoding="utf-8").read()
    listed = set(re.findall(r"(qml/[A-Za-z0-9_/\.\-]+)", pro))
    on_disk = set()
    for dirpath, _dirnames, filenames in os.walk(os.path.join(ROOT, "qml")):
        for f in filenames:
            rel = os.path.relpath(os.path.join(dirpath, f), ROOT).replace(os.sep, "/")
            on_disk.add(rel)
    for m in sorted(on_disk - listed):
        errors.append("FiatCor.pro: %s missing from DISTFILES (will not deploy)" % m)
    for s in sorted(listed - on_disk):
        warnings.append("FiatCor.pro: %s is in DISTFILES but does not exist" % s)


def main():
    for dirpath, _dirnames, filenames in os.walk(os.path.join(ROOT, "qml")):
        for f in sorted(filenames):
            if not (f.endswith(".qml") or f.endswith(".js")):
                continue
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, ROOT).replace(os.sep, "/")
            src = open(full, encoding="utf-8").read()
            check_balance(rel, src)
            check_ids(rel, src)
            check_icons(rel, src)
            check_hex(rel, src)
            check_no_page_background(rel, src)
            check_sql(rel, src)

    check_distfiles()

    for w in warnings:
        print("WARN  " + w)
    for e in errors:
        print("FAIL  " + e)
    if not errors:
        print("OK — nothing found")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
