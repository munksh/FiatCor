#!/usr/bin/env python3
"""
Builds the standalone web preview of MetronomePage.

Run:  python3 tools/make_preview.py
Writes fiat-cor-preview.html in the project root.

The point: judge layout, pulse movement, accent patterns and the click
sounds in a browser without starting the emulator — and see the app take
on three different simulated ambiences, which is the thing that is hard
to picture from code.

The timing code in the preview is the same algorithm as qml/Cor.qml and
the wav files are the same files, inlined as data URLs.

The preview is a judgement tool, not a second implementation. If you
change the layout or the idiom in QML, update the template too, or they
start to drift apart.
"""

import base64
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, "tools", "preview.template.html")
OUT = os.path.join(ROOT, "fiat-cor-preview.html")

SOUNDS = {
    "__STRONG__": "click-strong.wav",
    "__MEDIUM__": "click-medium.wav",
    "__NORMAL__": "click-normal.wav",
    "__SUB__": "click-sub.wav",
}


def main():
    html = open(TEMPLATE, encoding="utf-8").read()
    for token, name in SOUNDS.items():
        path = os.path.join(ROOT, "qml", "sounds", name)
        with open(path, "rb") as fh:
            html = html.replace(token, base64.b64encode(fh.read()).decode("ascii"))
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(html)
    print("wrote %s (%d kB)" % (os.path.relpath(OUT, ROOT), len(html) // 1024))


if __name__ == "__main__":
    main()
