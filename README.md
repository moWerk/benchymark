# benchymark

<img src="benchymark.svg" width="88" align="right" alt="benchymark icon">

**A rendering benchmark for [AsteroidOS](https://asteroidos.org/) watches.**
Install it, tap it, and twelve fixed phases tell you what your watch is actually
good and bad at — with the frame rate live on the screen and a result file you
can keep.

https://github.com/user-attachments/assets/adec3f6d-6174-4b50-b96d-a8a980a92be8

## The loop

3DBenchy exists to benchmark **3D printers**. This community 3D-prints
**custom docks** for its watches, and posts finished ones to members who have no
printer. So the little boat that certifies the printer, that makes the dock,
that holds the watch — now certifies the watch as well.

That is not decoration. Because QtQuick3D is absent on these images, nothing
here *loads* a model: the QML **is** the renderer, rotating the hull and
projecting it through a perspective divide every single frame. Your watch is
drawing, by arithmetic, the object that certified the printer that made its own
cradle.

## What you see

1. A **countdown**, so you can get to the watch before it starts.
2. **Twelve phases**, back to back, with a quiet two seconds between them. The
   name of the phase about to run fades up in the middle of that gap.
3. The **live FPS travels the screen rim**, trailing older readings behind it —
   the trail *is* the history, no graph needed. One lap per phase, so it starts
   and finishes at the top. Numerals drop to **red below 45 fps**.
4. A **COMPLETE** screen. Tap to run it again.

The whole run takes about three minutes and holds the screen awake by itself.

**Or take control.** Tap during the countdown and it pauses, offering two
buttons: **continue** (for a mis-tap) or **phase control**. In phase control the
current phase runs *indefinitely* and a tap moves to the next one — so you can
park on the one test you actually care about instead of waiting for it to come
round. Results from a manually-cut phase are marked `"manual": true`, because a
window you ended by hand is not comparable with a full one.

## Install

Grab the `.ipk` from [Releases](../../releases), then on the watch as root:

```sh
opkg install benchymark_*.ipk --force-reinstall --force-depends
```

It appears in the launcher as **Benchymark**. Building from source is in
[packaging/benchymark.bb](packaging/benchymark.bb).

## What it measures

Each phase isolates **one** cost path, so a result points at a cause instead of
handing you a score:

| phase | what it leans on |
|---|---|
| `IDLE` | nothing — the sanity floor. Should sit at a flat 60. |
| `SCALE` | scaling text with a transform |
| `RERASTER` | the **same picture**, resized the expensive way |
| `ORBIT` | a moving element with a pulsing halo |
| `OVERDRAW` | stacked translucent layers — raw fill rate |
| `DRAWCALLS` | many separate SVG icons in motion |
| `DRAWFONT` | the same storm as colour emoji glyphs |
| `SHAPES` | a vector path rebuilt every frame |
| `CASCADE` | two counter-rotating trees of moving children |
| `CLOUDLIGHT` | a domain-warped cloud, cheaply |
| `CLOUDHEAVY` | the same cloud, built to hurt |
| `BENCHY` | the boat, as a rotating wireframe |

**`SCALE` and `RERASTER` are the centrepiece.** They look *identical on screen*
and differ only in how the resize is done — a `scale` transform versus animating
`font.pixelSize`. Their ratio is the most transferable number in the run: on
nemo it is 55 against 21, which is what animating text size really costs.

The two **clouds** are one scene at two costs — 24 against 140 hash evaluations
per pixel — so the pair prices the domain warp and the `sin()`-based hash
together. `CLOUDHEAVY` is the deliberate worst case.

## Results

Each completed run is written to
`~/.local/share/benchymark/last-run.json`:

```json
{
 "scene": "0.2",
 "finished": "2026-07-31T20:14:03.000Z",
 "resolution": "480x480",
 "phases": [ { "phase": "IDLE", "avg": 60, "min": 59, "samples": 9 } ]
}
```

One complete run per file, written when the last phase closes — so a tool
collecting these never reads a half-finished result. Fleet managers such as
[asteroid-docking-bay](https://github.com/moWerk/asteroid-docking-bay) can
install, launch and read it back over ADB or SSH.

## Comparing numbers honestly

- The **scene version** shows during the countdown and is stamped into every
  result. If the scene changes, old numbers are void.
- **Bigger panels do more work** in the fill-rate phases. That is real, so
  compare like with like, or report Mpix/s alongside FPS.
- Every phase runs ten seconds and **measures nine** — the first is discarded,
  because it straddles the gap and the scene's opening frames.
- Watches have been seen **dropping off ADB** during the wireframe phase with
  the screen lit. The run itself does not need ADB; only reading the result does.

Full technical detail — architecture, how the frames are actually counted, the
mesh pipeline, and the meta-asteroid cleanup this was built to serve — is in the
[latest release notes](../../releases/latest).

## Credits

**3DBenchy** entered the public domain on 2025-02-14 (NTI Group). Credit to
Creative Tools / NTI Group is offered as good manners rather than obligation.
The mesh ships as a small coordinate table; the model itself is not in this
repository.

The layout comes from **digital-nutty-null**; the app structure derives from
**asteroid-flashlight** by Florent Revest.

Licensed **GPL-3.0-or-later**, matching the other AsteroidOS apps.
