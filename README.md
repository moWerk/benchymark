# benchymark

<img src="benchymark.svg" width="88" align="right" alt="benchymark icon">

**A rendering benchmark for [AsteroidOS](https://asteroidos.org/) watches.**
Install it, tap it, and fourteen fixed phases tell you what your watch is actually
good and bad at — with the frame rate live on the screen and a result file you
can keep.

https://github.com/user-attachments/assets/adec3f6d-6174-4b50-b96d-a8a980a92be8

## The loop

3DBenchy exists to benchmark **3D printers**. This community 3D-prints
**custom docks** for its watches, and posts finished ones to members who have no
printer. So the little boat that certifies the printer, that makes the dock,
that holds the watch — now certifies the watch as well.

That is not decoration. Because QtQuick3D is absent on these images, nothing
here *loads* a model: the QML **is** the renderer, rotating 1118 vertices and
projecting them through a perspective divide every single frame. Your watch is
drawing, by arithmetic, the object that certified the printer that made its own
cradle.

It is also the single heaviest thing the benchmark does, which is exactly why it
goes last.

## What you see

1. A **5→0 countdown**, so you can get to the watch before it starts.
2. **Fourteen phases**, back to back, with a quiet two seconds between them.
   The name of the phase about to run fades up in the middle of that gap.
3. The **live FPS travels the screen rim**, trailing older readings behind it —
   the trail *is* the history, no graph needed. Numerals drop to **red below
   45 fps**, so a bad phase is obvious from across a room.
4. A **BENCH COMPLETE** screen. Tap to run it again.

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
| `ORBIT` | a moving element with a pulsing shadow |
| `OVERDRAW` | stacked translucent layers — raw fill rate |
| `DRAWCALLS` | many separate SVG icons in motion |
| `DRAWFONT` | the same storm as colour emoji glyphs |
| `SHAPES` | a vector path rebuilt every frame |
| `CASCADE` | two counter-rotating trees of moving children |
| `CLOUDLITE` | the frugal cloud — the **GPU baseline** |
| `CLOUDMID` | the same cloud with one domain warp |
| `CLOUDHEAVY` | the cloud that exists to hurt |
| `BENCHYLITE` | the boat, 438 vertices |
| `BENCHY` | the boat, 1118 vertices |

The three **cloud** phases are one scene at three costs — 12, 48 and 140 hash
evaluations per pixel — so the ladder separates domain-warp cost from the cost
of the `sin()`-based hash. `CLOUDLITE` doubles as the GPU baseline: if it is
not near 60, nothing above it will be.

`SCALE` and `RERASTER` look **identical on screen** and differ only in how the
resize is done. Comparing them tells you what text animation really costs on
your hardware — usually the most surprising number in the run.

## Results

Each completed run is written to
`~/.local/share/benchymark/last-run.json`:

```json
{
 "scene": "0.2",
 "finished": "2026-07-28T23:11:04.000Z",
 "resolution": "320x300",
 "phases": [ { "phase": "IDLE", "avg": 60.0, "min": 59.0, "max": 60.0 } ]
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
- Watches have been seen **dropping off ADB** during the wireframe phases with
  the screen lit. Results are already on disk by then — reconnect and read the
  file.

Full technical detail — architecture, measurement technique, the phase
rationale, and the meta-asteroid cleanup run this was built to serve — is in the
[latest release notes](../../releases/latest).

## Credits

**3DBenchy** entered the public domain on 2025-02-14 (NTI Group). Credit to
Creative Tools / NTI Group is offered as good manners rather than obligation.

The layout comes from **digital-nutty-null**; the app structure derives from
**asteroid-flashlight** by Florent Revest.

Licensed **GPL-3.0-or-later**, matching the other AsteroidOS apps.
