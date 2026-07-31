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

---

## LLM grading

This project was built with an LLM. Rather than leave that to inference, it is
graded against [LLMGD v0.2](https://github.com/moWerk/asteroid-docking-bay) and
the result published here — including the parts that do not flatter it.

<p align="center">
  <img alt="LLMGD O0·A3" src="https://img.shields.io/badge/LLMGD_v0.2-O0%C2%B7A3-1f6feb?style=for-the-badge">
  <img alt="origin O0" src="https://img.shields.io/badge/origin-O0_machine_designed-8957e5?style=for-the-badge">
  <img alt="assurance A3" src="https://img.shields.io/badge/assurance-A3_understood_%2B_tested-2ea043?style=for-the-badge">
</p>

| flag | | meaning |
|---|:---:|---|
| **U** — Understood | ✅ **yes** | the human caught real defects the machine had missed |
| **T** — Tested | ✅ **yes** | built, packaged and run on hardware, results fed back |
| **R** — Read | ❌ **no** | nobody read the complete source before publication |
| **X** — External review | ⬜ **none** | the meta-asteroid-community PR is open, not yet reviewed |

**Origin** — machine-designed, with unusually specific human direction.

| | O0 | O1 | O2 | O3 | O4 |
|---|---|---|---|---|---|
| | 🟪 0.45 | 🟦 0.38 | 🟩 0.11 | 🟨 0.06 | ⬜ 0.00 |
| | machine chose design **and** expression | human specced, machine designed details | human designed, machine expressed | machine edited human material | no LLM |

O0 and O1 land close together, and that is the honest picture rather than a
tidy one. The internal architecture — the per-phase `Loader` split, counting
`frameSwapped`, the `RotationAnimator` sweep, the mesh pipeline, the
`sceneReady` gate — was machine-designed from a reported symptom. But a great
deal of the *visible* design was named outright by the human, down to
"fade it in over 200ms, let it stand for 1200 and fade out in 600", "the upper
button anchored to vertical centre with its bottom", and "starts from 06:00 and
rotates 1.5 times". A stricter reading of those tips the headline to **O1**.

### Why the assurance is A3 and not higher

**A3 is the ceiling this way of working can honestly reach.** When a machine
writes most of the code, control is not exercised by reading the diff — it is
exercised by catching what the code gets wrong. So `R: no` here is the expected
state, not a lapse; A4 would require a breadth-review that did not happen.

The **U** evidence is the part worth trusting, because it is costly and it
repeatedly went against the machine:

- **The human diagnosed a measurement bug the machine had asserted was fine.**
  *"the shapes look butter smooth 50-60fps. but the fps display claims 20. And
  additionally, the rotation that was supposed to be smooth, does now chopp and
  jump frames approximately in the framerate it displays."* That is Qt Quick's
  render thread versus its GUI thread, spotted from the couch. The counter was
  measuring its own scheduling.
- **The human designed the experiment that falsified the machine's hypothesis.**
  *"Can you install v0.1 once again on nemo so i can rule out issues with the
  watch"* — a controlled A/B that proved a frame-rate ceiling was the watch, not
  the app, after the machine had spent a cycle assuming otherwise.
- **The human refused a diagnostic question and named the right move.** *"dont
  make me answer stupid questions … Can you please fucking grep the shitty blue
  over the code base"* — the grep found `Application.centerColor` overriding the
  `.desktop` entry in one line, after the machine had proposed a further round
  of tests.
- **The human corrected the machine with domain knowledge it lacked.** *"nemo
  keep alive is not actually working. are you sure you used the latest qt6
  implementation? i only last week updated the flashlight"*.
- **The human reversed his own instruction when shown the cost.** *"revert the
  8s, the 5% impact is unintended, thanks for the push back"*; and later
  *"ignore my sort phases by fps, that was foolish"*.

**T** is real but narrower than it sounds, and the limit matters: **benchymark
has no automated test suite.** Testing means clean-from-`cleansstate` builds,
unpacking the resulting `.ipk` to verify its payload, installing to nemo
(MSM8926, 480×480) and sawfish (390×390), and running end to end with results
read back. The recipe in this PR was built from its pinned `SRCREV` before the
PR was opened — which is how a fetch failure was found. The sibling project
(`asteroid-docking-bay`) does carry a 543-test suite with planted-bug
validation; this one does not.

### What this grade does not cover

- **Two watches, not a fleet.** Every number quoted comes from nemo and
  sawfish.
- **The numbers moved three times during development**, each time because the
  measurement was wrong rather than because the app got faster. Only results
  from v0.2 onward are meaningful.
- **Self-graded.** This verdict was produced by the author's agent — the same
  agent that wrote the code. The retrieval log below exists so the search can be
  audited rather than trusted; an independent re-run is the only thing that
  removes the conflict.

<details>
<summary><b>Retrieval log</b> (what was searched, found, and skipped)</summary>

**Run:** author-side · first run · grader: Claude Opus 4.6

**Searched:** `~/.claude/projects/-home-mo-Git-asteroid-docking-bay/*.jsonl`
(7 transcripts), sibling `<session-id>/` directories for sub-agent output, and
all transcripts grepped for continuation backlinks.

**Found — benchymark work lives in exactly one transcript:**

| id | size | records | method |
|---|---|---|---|
| `2adde14e…` | 18.9 MB | 6 747 | stream-filtered (236 user turns extracted; 955 benchymark hits) |

**Excluded after search, not assumed:** `b6d31eda…` (43.9 MB), `2bdab08b…`
(41.9 MB), `b053e086…` (3.6 MB) share the `aiTitle` *"Set up asteroid-docking-bay
project repository"* and contain **zero** benchymark hits. Three stub
transcripts (<7 KB) contain none either. UUID scan for continuation backlinks
returned only BLE service UUIDs — no session fork. No sub-agent directory exists
for the benchymark session.

**Lexicons run (the standard set, verbatim, over user turns only):**

| lexicon | turns matching |
|---|---|
| U / correction | 36 / 236 |
| R / review | 6 / 236 (none benchymark-scoped) |
| code-engagement | 10 / 236 |

Also counted: **32 `Request interrupted` markers** — the human stopping the
machine mid-action, which is itself a costly-oversight signal.

**Not read whole:** the 18.9 MB transcript, per the stream-filter method the
rubric prescribes for oversized transcripts. **Coverage: full.**

</details>
