# benchymark

A GPU/UI benchmark for [AsteroidOS](https://asteroidos.org/) watches. It runs a
fixed scene through eleven phases, each isolating **one** rendering cost path,
shows the live frame rate on the watch, and writes a machine-readable result to
disk so a host tool can collect it.

The point is not a score. It is to make a number mean something: *this* watch,
on *this* image, is slow at *this specific thing* — and to be able to prove it
again next week.

<img src="benchymark.svg" width="96" align="right" alt="benchymark icon">

## Why an app and not a watchface

It began as a watchface, on the reasoning that the launcher is already a
running QML engine and a watchface is just a file it loads — no tooling to
install. That failed for two structural reasons:

1. **A watchface cannot hold the screen awake.** `Nemo.KeepAlive`'s declarative
   `DisplayBlanking` is ignored inside the compositor. The identical code works
   in `asteroid-flashlight`, which is a client app. The panel blanked mid-run.
2. **A watchface has nowhere to put results.** Everything had to be read off
   the screen by eye.

An app fixes both: it holds its own screen and writes
`~/.local/share/benchymark/last-run.json`.

## The phases

Fixed order, fixed duration, deterministic, with a quiet second between each so
one phase's backlog does not bleed into the next.

| # | phase | what it isolates |
|---|---|---|
| 0 | `IDLE` | nothing — the sanity floor. Should be flat 60. |
| 1 | `SCALE` | a `scale` transform on distance-field text |
| 2 | `RERASTER` | the **same visual**, animating `font.pixelSize` instead |
| 3 | `ORBIT` | a travelling numeral with a pulsing drop shadow |
| 4 | `OVERDRAW` | stacked translucent full-screen fills — pure fill rate |
| 5 | `DRAWCALLS` | many `org.asteroid.controls` `Icon`s in motion |
| 6 | `SHAPES` | a Qt Quick `Shape` path re-tessellated every frame |
| 7 | `CASCADE` | a `scale` animation on an `Item` with many children |
| 8 | `SHADER` | a doubly domain-warped fBm `ShaderEffect` — fragment-bound |
| 9 | `BENCHYLITE` | 3DBenchy as a wireframe, 438 vertices / 1545 segments |
| 10 | `BENCHY` | the same boat at 1118 vertices / 3720 segments |

**Phases 1 and 2 are the centrepiece.** They look *identical on screen* and
differ only in which code path they take: animating a `scale` transform does not
touch the glyph cache, animating `font.pixelSize` churns it — CPU rasterisation
plus a texture upload per new size. Their FPS ratio therefore measures the glyph
path directly, on real hardware, instead of by argument.

Phase 8 is the only honestly GPU-bound one: ~28 noise lookups per fragment,
every frame, so its cost scales with **pixels**, not scene complexity. A
480×480 panel does 2.25× the work of a 320×320 one, which is why raw FPS and
Mpix/s both matter.

Phases 9 and 10 render 3DBenchy by hand — QtQuick3D is absent on these images
(checked), so the QML *is* the renderer: every frame it rotates the vertices,
projects them through a perspective divide, and hands the point arrays to
`PathPolyline`s. Deliberately the heaviest thing here.

## Measuring the frames

Version-agnostic and window-free: an infinite `NumberAnimation` drives a dummy
property and its change handler counts ticks. An animation ticks once per
**rendered** frame, so dropped frames simply do not tick. A 1 s timer turns that
into FPS. No access to `QQuickWindow` required.

The live figure travels the screen rim with a trail of older readings behind it,
so the history is the display — no separate graph. Trail numerals turn red below
45 fps, which makes a bad phase visible from across a room.

## Results

```json
{
 "scene": "0.1",
 "finished": "2026-07-28T23:11:04.000Z",
 "resolution": "320x300",
 "phases": [ { "phase": "IDLE", "avg": 60.0, "min": 59.0, "max": 60.0 }, ... ]
}
```

Written once, when the last phase closes — one complete run per file, so a
collector never has to guess whether it is reading a partial result.

## Building

An ordinary AsteroidOS app; build it the way you build the others.

```sh
devtool modify benchymark /path/to/this/checkout   # or: devtool add
devtool build benchymark
bitbake -c package_write_ipk benchymark            # devtool build does NOT write the package
```

Two things that cost real time when this was first packaged, in case they save
you the same:

- `asteroid-generate-desktop` needs **both** `benchymark.desktop.template` and
  `i18n/benchymark.desktop.h`. Without the header it exits 2, no `.desktop` is
  produced, and the build fails much later in `do_install` with an anonymous
  `cmake_install.cmake:NN (file): No such file or directory`. Nothing points at
  the real cause.
- That generator runs at CMake **configure** time, so a fix to those inputs
  only takes effect once `do_configure` re-runs. A plain rebuild reuses the
  cached configure and reproduces the *identical* error, which reads as "the fix
  did nothing" when the fix never executed. `bitbake -c cleansstate benchymark`
  first.

Install:

```sh
opkg install benchymark_1.0-r0_*.ipk --force-reinstall --force-depends
```

## Comparability

Numbers are worth keeping only under stated conditions:

- **Version-stamp everything.** The scene version shows during the countdown and
  is written into every result. Change the scene → old numbers are void.
- **Resolution is not fairness.** Fill-rate phases do proportionally more work on
  a bigger panel. That is real hardware truth, so report raw FPS and Mpix/s side
  by side.
- **One Qt.** Qt6 only — `MultiEffect`, never `Qt5Compat.GraphicalEffects`, so
  there are not two effect paths producing incomparable numbers.
- **Never `layer.samples`** — a confirmed no-op on AsteroidOS hardware that only
  logs a warning.
- **Gate every animation** on its phase being active. Rendering is not animation:
  a hidden item stops rendering, but a running animation keeps consuming, which
  would leak one phase's cost into the next.

## Using it to settle environment-variable questions

AsteroidOS ships per-device Qt/GL workarounds in
`/var/lib/environment/compositor/default.env`. Several are old and unrevisited,
and the usual test is "drop it and see if the UI renders fine" — a judgement
call that is hard to compare across watches or to repeat.

These phases map onto those flags closely enough to replace the eyeball with a
measurement:

| variable | phases that would move if it matters |
|---|---|
| `QT_ENABLE_GLYPH_CACHE_WORKAROUND` | `SCALE` vs `RERASTER` — literally the glyph-cache probe |
| `QT_OPENGL_NO_BGRA` | `DRAWCALLS`, `OVERDRAW` (texture upload path) |
| `QPA_HWC_FORCE_GLES` | `OVERDRAW`, `SHADER` (compositing and fill rate) |
| GPU frequency pinning | `SHADER` above all — the fragment-bound phase |

Run it once with the flag, once without, on the same watch, and the answer is a
pair of numbers rather than an impression.

## Known side effect

Watches have been observed dropping off ADB during the wireframe phases with the
screen lit, returning only after a port power cycle. The kernel log puts the
origin on the watch side — the USB gadget loses its session, with no OOM kill,
no adbd crash and no segfault. Because results are written to disk as the run
proceeds, a link that drops costs the *reading*, not the *run*: reconnect and
read the file.

## Status

Honest state, since a benchmark that overstates itself is worse than none:

- Builds clean; package payload verified by unpacking the ipk.
- Installed and run end-to-end on **medaka**, with results read back.
- The phase design, the comparability rules and the ADB-drop note come from
  real observation on hardware.
- **Not** yet run across enough of the fleet to publish a cross-device table,
  and the per-phase tuning targets are provisional.

## Credits and licence

3DBenchy entered the **public domain** on 2025-02-14 (NTI Group), so it can be
decimated, wireframed and shipped. Attribution is not required; credit to
Creative Tools / NTI Group is offered as good manners. The mesh here was
decimated from the original and converted to strips by a host-side script, so
the watch only pays for rotate → project → stroke per frame.

The layout is derived from `digital-nutty-null` by moWerk.

Licensed **GPL-3.0-or-later**, matching the other AsteroidOS apps. See
[LICENSE](LICENSE).
