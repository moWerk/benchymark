#!/usr/bin/env python3
# SailfishOS: the launcher icon. A low-poly side view of 3DBenchy, its
# proportions taken from the app's mesh (side projection traced in a 600 px
# frame, then straightened by hand), in the SailfishOS leaf shape: the boat
# sits on the inner background and runs under the ring on the left, as if it
# came out of it. Behind the boat a layer that says speed.
# usage: tools/benchy_icon.py [gauge|streaks|grid] [out.svg]
# The PNGs: rsvg-convert -w N -h N icons/harbour-benchymark.svg -o icons/NxN/...
import math, sys

variant = sys.argv[1] if len(sys.argv) > 1 else "grid"
out = sys.argv[2] if len(sys.argv) > 2 else "icons/harbour-benchymark.svg"

# clockwise from the aft deck; the stern itself is cut: deck and keel run
# straight out to the left under the ring (mo, 2026-10-17)
OFF = 5     # ends inside the ring, which covers it
outline = [
    (OFF, 442), (130, 442), (130, 408), (216, 350),
    (216, 200), (230, 199), (230, 110), (284, 110), (284, 193),
    (414, 184), (410, 343), (574, 298), (566, 362), (540, 432),
    (420, 548), (OFF, 548),
]

# placement from the full boat (stern at x 28), so the cut keeps the size:
# the same margin to the inner leaf at the top, bottom and right
INNER0, INNER1 = 58, 454
XMIN, XMAX, YMIN, YMAX = 28, 574, 110, 548
s = 352 / (XMAX - XMIN)
margin = ((INNER1 - INNER0) - (YMAX - YMIN) * s) / 2
right = INNER1 - margin
X = lambda x: right - (XMAX - x) * s
Y = lambda y: INNER0 + margin + (y - YMIN) * s
pts = lambda ps: " ".join("%.1f,%.1f" % (X(p[0]), Y(p[1])) for p in ps)

def leaf(x0, y0, x1, y1, big, small):
    """The SailfishOS leaf: top left and bottom right rounded wide, the
    other two corners only a little."""
    return ("M%.1f %.1f H%.1f A%.1f %.1f 0 0 1 %.1f %.1f V%.1f A%.1f %.1f 0 0 1 %.1f %.1f "
            "H%.1f A%.1f %.1f 0 0 1 %.1f %.1f V%.1f A%.1f %.1f 0 0 1 %.1f %.1f Z") % (
        x0 + big, y0, x1 - small, small, small, x1, y0 + small,
        y1 - big, big, big, x1 - big, y1,
        x0 + small, small, small, x0, y1 - small,
        y0 + big, big, big, x0 + big, y0)

OUTER = leaf(2, 2, 510, 510, 190, 26)
INNER = leaf(INNER0, INNER0, INNER1, INNER1, 140, 14)

defs = ""
layer = ""
if variant == "gauge":
    # a speedometer arc behind the boat, the needle high in the red
    cx, cy, r = 268, 300, 168
    a0, a1 = math.radians(200), math.radians(-20)   # sweep, left to right over the top
    def P(a, rr): return (cx + rr * math.cos(a), cy - rr * math.sin(a))
    sx, sy = P(a0, r); ex, ey = P(a1, r)
    defs += '<linearGradient id="arc" gradientUnits="userSpaceOnUse" x1="100" y1="0" x2="436" y2="0"><stop offset="0" stop-color="#58a6ff" stop-opacity="0.15"/><stop offset="0.6" stop-color="#f0c30e" stop-opacity="0.7"/><stop offset="1" stop-color="#e54b3a"/></linearGradient>'
    defs += '<radialGradient id="glow" cx="%d" cy="%d" r="%d" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#3d6bc0" stop-opacity="0.6"/><stop offset="1" stop-color="#3d6bc0" stop-opacity="0"/></radialGradient>' % (cx, cy, r + 40)
    layer += '<circle cx="%d" cy="%d" r="%d" fill="url(#glow)"/>' % (cx, cy, r + 40)
    layer += '<path d="M%.1f %.1f A%d %d 0 1 1 %.1f %.1f" fill="none" stroke="url(#arc)" stroke-width="18" stroke-linecap="round"/>' % (sx, sy, r, r, ex, ey)
    for i in range(12):
        a = a0 + (a1 - a0) * i / 11
        x1, y1 = P(a, r - 26); x2, y2 = P(a, r - (44 if i % 2 == 0 else 36))
        layer += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#a5d6ff" stroke-opacity="%.2f" stroke-width="7" stroke-linecap="round"/>' % (x1, y1, x2, y2, 0.25 + 0.6 * i / 11)
    na = a0 + (a1 - a0) * 0.88
    nx, ny = P(na, r - 30)
    layer += '<line x1="%d" y1="%d" x2="%.1f" y2="%.1f" stroke="#e54b3a" stroke-width="10" stroke-linecap="round"/>' % (cx, cy, nx, ny)
    layer += '<circle cx="%d" cy="%d" r="14" fill="#e54b3a"/>' % (cx, cy)
elif variant == "streaks":
    # light streaks out to the left, a wake under the hull
    defs += '<linearGradient id="streak" gradientUnits="userSpaceOnUse" x1="40" y1="0" x2="330" y2="0"><stop offset="0" stop-color="#79c0ff" stop-opacity="0"/><stop offset="1" stop-color="#a5d6ff" stop-opacity="0.85"/></linearGradient>'
    for (y, x2, w) in [(150, 330, 7), (205, 300, 10), (262, 250, 7), (318, 210, 9), (392, 380, 12), (420, 300, 7)]:
        layer += '<line x1="40" y1="%d" x2="%d" y2="%d" stroke="url(#streak)" stroke-width="%d" stroke-linecap="round"/>' % (y, x2, y, w)
    defs += '<linearGradient id="wake" gradientUnits="userSpaceOnUse" x1="40" y1="0" x2="400" y2="0"><stop offset="0" stop-color="#58a6ff" stop-opacity="0"/><stop offset="1" stop-color="#58a6ff" stop-opacity="0.55"/></linearGradient>'
    layer += '<path d="M40 %.1f Q 250 %.1f %.1f %.1f L %.1f %.1f Q 250 %.1f 40 %.1f Z" fill="url(#wake)"/>' % (Y(560), Y(548), X(430), Y(552), X(420), Y(575), Y(600), Y(600))
elif variant == "grid":
    # a perspective floor running to a glowing sun inside the boat's body,
    # zoomed in: few, thick lines and a strong sun (mo, 2026-10-17)
    vx, hy = 256, 300            # vanishing point, the boat's middle
    defs += ('<radialGradient id="sun" cx="%d" cy="%d" r="230" gradientUnits="userSpaceOnUse">'
             '<stop offset="0" stop-color="#ffd84a" stop-opacity="0.95"/>'
             '<stop offset="0.25" stop-color="#f0a30e" stop-opacity="0.7"/>'
             '<stop offset="0.6" stop-color="#e54b3a" stop-opacity="0.3"/>'
             '<stop offset="1" stop-color="#e54b3a" stop-opacity="0"/></radialGradient>') % (vx, hy)
    defs += ('<linearGradient id="floor" gradientUnits="userSpaceOnUse" x1="0" y1="%d" x2="0" y2="470">'
             '<stop offset="0" stop-color="#79c0ff" stop-opacity="0.1"/>'
             '<stop offset="1" stop-color="#79c0ff" stop-opacity="0.75"/></linearGradient>') % hy
    layer += '<rect x="0" y="0" width="512" height="%d" fill="url(#sun)"/>' % hy
    layer += '<rect x="0" y="%d" width="512" height="%d" fill="url(#sun)" opacity="0.35"/>' % (hy, 512 - hy)
    g = '<g stroke="url(#floor)" stroke-width="9" fill="none" stroke-linecap="round">'
    for i in range(-4, 5):
        g += '<line x1="%d" y1="%d" x2="%d" y2="560"/>' % (vx, hy, vx + i * 150)
    for k in range(1, 5):
        y = hy + (470 - hy) * (k / 4) ** 1.7
        g += '<line x1="0" y1="%.1f" x2="512" y2="%.1f"/>' % (y, y)
    layer += g + '</g>'

svg = """<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<!-- Launcher icon for SailfishOS: the leaf shape of the stock icons (top left
     and bottom right rounded), an outer ring with a diagonal gradient around
     an inner leaf, as the author's tool apps do it with rings; 3DBenchy
     (public domain, NTI Group; credit to Creative Tools / NTI) in profile,
     coming out from under the ring on the left; behind it: %s.
     From tools/benchy_icon.py. -->
<defs>
<linearGradient id="rim" gradientUnits="userSpaceOnUse" x1="0" y1="512" x2="512" y2="0"><stop offset="0" stop-color="#0d1a36"/><stop offset="1" stop-color="#4f86d9"/></linearGradient>
<radialGradient id="inner" cx="236" cy="236" r="260" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#25427a"/><stop offset="1" stop-color="#070b18"/></radialGradient>
<clipPath id="innerClip"><path d="%s"/></clipPath>
%s
</defs>
<path d="%s" fill="url(#inner)"/>
<g clip-path="url(#innerClip)">%s</g>
<polygon points="%s" fill="none" stroke="#79c0ff" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>
<path d="%s %s" fill="url(#rim)" fill-rule="evenodd"/>
</svg>
""" % (variant, INNER, defs, OUTER, layer, pts(outline), OUTER, INNER)
open(out, "w").write(svg)
