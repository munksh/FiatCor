#!/usr/bin/env python3
"""
Pre-build sanity check for Fiat Cor.

Not a substitute for a real QML parser, but it catches the mistakes that
actually creep into a QML project before you have even started the
emulator:

  * unbalanced braces / parens (comments and strings ignored)
  * ids referenced but never declared in the file
  * theme icon names not on the confirmed list
  * hardcoded hex outside FiatCorTheme.qml
  * a page-filling Rectangle that is not guarded by !FiatCorTheme.ambient
  * a property bound to itself, and duplicate signal handlers
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
    "harbour",
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


SELF_BIND_RE = re.compile(r"^\s*([a-z][A-Za-z0-9_]*)\s*:\s*\1\s*$", re.M)


def check_self_binding(path, src):
    """
    `cor: cor` binds a property to itself and evaluates to null forever.

    QML resolves an unqualified name in a binding against the *scope
    object* — the object the binding belongs to — before it looks at the
    file's ids. If the target object has a property of that name, the id
    of the same name is shadowed and never seen. No error, no warning:
    the page simply comes up with everything null.

    This cost a second deploy. Qualify the right-hand side, or give the
    id a different name from the property.
    """
    code = strip_comments_and_strings(src)
    for m in SELF_BIND_RE.finditer(code):
        line = code[:m.start()].count("\n") + 1
        errors.append("%s:%d '%s: %s' binds a property to itself — the id is "
                      "shadowed by the property and this is null at runtime"
                      % (path, line, m.group(1), m.group(1)))


HANDLER_RE = re.compile(r"(?<![\w\.])(on[A-Z][A-Za-z0-9_]*)\s*:")


def check_duplicate_handlers(path, src):
    """
    QML allows exactly one handler per signal per object. A second
    onXxxChanged is not a warning you can live with — it is
    "Property value set multiple times", the type fails to load, and the
    use site reports "Type Cor unavailable" with no hint as to why.

    This cost a deploy. The two handlers were forty lines apart, each
    sitting next to the code it belonged to, and both looked right.
    """
    code = strip_comments_and_strings(src)
    seen = {}
    path_stack = []
    i = 0
    n = len(code)
    while i < n:
        ch = code[i]
        if ch == "{":
            path_stack.append(i)
        elif ch == "}":
            if path_stack:
                path_stack.pop()
        else:
            m = HANDLER_RE.match(code, i)
            if m:
                key = (tuple(path_stack), m.group(1))
                line = code[:i].count("\n") + 1
                if key in seen:
                    errors.append(
                        "%s:%d '%s' is declared twice on the same object "
                        "(first at line %d) — the whole type will fail to load"
                        % (path, line, m.group(1), seen[key]))
                else:
                    seen[key] = line
                i = m.end()
                continue
        i += 1


def check_icons(path, src):
    for m in re.finditer(r"image://theme/([A-Za-z0-9\-_]+)", src):
        if m.group(1) not in KNOWN_ICONS:
            errors.append("%s: unconfirmed icon name '%s'" % (path, m.group(1)))


def check_hex(path, src):
    """
    Fiat colours live in exactly one file. Everywhere else a hex literal is
    how ambient mode breaks in one corner without anyone noticing.
    """
    if path.endswith("FiatCorTheme.qml"):
        return
    for i, raw in enumerate(src.splitlines(), 1):
        if raw.strip().startswith(("*", "//", "/*")):
            continue
        if re.search(r"[\"']#[0-9A-Fa-f]{3,8}[\"']", raw):
            errors.append("%s:%d hardcoded hex — Fiat colours live in FiatCorTheme.qml only" % (path, i))


def _block_at(code, brace_index):
    """Returns the text of the {...} block that opens at brace_index."""
    depth = 0
    for j in range(brace_index, len(code)):
        if code[j] == "{":
            depth += 1
        elif code[j] == "}":
            depth -= 1
            if depth == 0:
                return code[brace_index:j + 1]
    return code[brace_index:]


def check_page_background(path, src):
    """
    Under an ambience the wallpaper IS the background, and a Rectangle
    filling a page cancels it. Under Fiat colours the same Rectangle is
    required, because the app paints its own paper.

    So the rule is not "no fill" but "no UNGUARDED fill": every page-filling
    Rectangle must carry visible: !FiatCorTheme.ambient. Wrong in one
    direction it is a slab over the user's wallpaper; wrong in the other it
    is light text on a light wallpaper.

    Brace-counted rather than matched with a regex. The first version used
    one, and the nested Gradient/GradientStop blocks meant it never matched
    anything at all -- a rule that passes everything, which is worse than no
    rule because it looks like a rule.
    """
    if not (path.startswith("qml/pages/") or path.startswith("qml/cover/")):
        return
    code = strip_comments_and_strings(src)
    for m in re.finditer(r"\bRectangle\s*\{", code):
        brace = code.index("{", m.start())
        block = _block_at(code, brace)
        if not re.search(r"anchors\.fill\s*:\s*parent", block):
            continue
        if "FiatCorTheme.ambient" in block:
            continue
        line = code[:m.start()].count("\n") + 1
        errors.append("%s:%d page-filling Rectangle without "
                      "visible: !FiatCorTheme.ambient" % (path, line))


def check_sql(path, src):
    if not path.endswith("Storage.js"):
        return
    for i, raw in enumerate(src.splitlines(), 1):
        if "executeSql(" in raw and raw.count('"') % 2 != 0:
            errors.append("%s:%d SQL string broken across a line end" % (path, i))


def check_distfiles():
    pro = open(os.path.join(ROOT, "harbour-fiatcor.pro"), encoding="utf-8").read()
    listed = set(re.findall(r"(qml/[A-Za-z0-9_/\.\-]+)", pro))
    on_disk = set()
    for dirpath, _dirnames, filenames in os.walk(os.path.join(ROOT, "qml")):
        for f in filenames:
            rel = os.path.relpath(os.path.join(dirpath, f), ROOT).replace(os.sep, "/")
            on_disk.add(rel)
    for m in sorted(on_disk - listed):
        errors.append("harbour-fiatcor.pro: %s missing from DISTFILES (will not deploy)" % m)
    for s in sorted(listed - on_disk):
        warnings.append("harbour-fiatcor.pro: %s is in DISTFILES but does not exist" % s)


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
            check_duplicate_handlers(rel, src)
            check_self_binding(rel, src)
            check_icons(rel, src)
            check_hex(rel, src)
            check_page_background(rel, src)
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
