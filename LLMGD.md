# Benchymark for SailfishOS: LLM disclosure

**AIRating V.** Benchymark for SailfishOS was written by an LLM (Claude), directed by its
author, mosen (moWerk), who decided what it measures, how it looks and what is released, and
who tested every release on his own devices. He has not read the code line by line. This page
says what happened inside the V, graded with [LLMGD](https://github.com/moWerk/llmgd-specs)
(v0.3), so a reviewer knows what to trust and where to look.

## Current release: 2.2.0

```
Disclosure: LLMGD-2 · origin O1 (audit, method change and fixes by the LLM; the author's call to rework for good and his design calls; tested on three devices; self-graded)
LLMGD: v0.3; assurance=A2; flags=T; origin={O0:.2,O1:.8}; origin_headline=O1; scope=release(code+packaging+docs); graded-by=claude-opus-5-5; retrieval=author-side
```

- **T, tested:** two full runs back to back on a Sony Xperia XA2 (4.4, armv7hl), the Jolla
  Tablet (4.6, i486) and the Jolla C2 (5.1, aarch64), within ±1 % on nearly every stage;
  also a run closed mid-stage, a stage sent to the background, Run one hour closed early,
  a GPU without OpenGL ES 3.1, the Settings, Results and Compare pages, Share image, a
  storage run.
- **U, understood: not claimed for 2.2.0.** The audit that found the measuring flaw and
  the new method came from the LLM; the author's part was the call to rework for good
  rather than patch, and the design calls. Earlier releases, where he caught errors
  himself, were graded A3 (below). The first verdict is the published one.
- **R, read: no.** The expected state for machine-written code; control was exercised by
  testing and by the author's corrections, not by reading the diff.
- **X, external review: none yet.**

## Earlier releases, as published

| Release | Label | Origin | Flags |
|---|---|---|---|
| 2.1.0 | LLMGD-3 | O1 | U, T |
| 2.0.1 | LLMGD-0 | O1 | none (built from files a tester shared, not run on MediaTek) |
| 2.0.0 | LLMGD-3 | O1 | U, T |
| 1.3.0 | LLMGD-3 | O1 | U, T |
| 1.2.1 | LLMGD-2 | O1 | U (not run on an affected device) |
| 1.2.0 | LLMGD-3 | O1 | U, T |
| 1.1.0 | LLMGD-3 | O1 | U, T |
| 1.0.0 | LLMGD-3 | O1 | U, T |

All labels are self-graded by the same LLM that wrote the code (author-side). An
independent grading is the only thing that removes that conflict.

## What was not checked

A MediaTek device, the Xiaomi Pad 6 (hybris), 90/120 Hz panels, light ambiences, a full
disk, a loop run longer than five minutes with the 2.2 measuring. The code has no
automated tests; testing means builds and runs on the three devices above.

## Review readiness

What of the [practice](https://github.com/moWerk/llmgd-specs/blob/main/PRACTICE.md) this
branch follows, so a review spends its time on the code:

- **Commits:** all 56 commits of the `sailfishos` branch since the port began end with an
  LLMGD line, and most say what was tested, e.g.
  [5230d96](https://github.com/moWerk/benchymark/commit/5230d96). Only a few name what
  was *not* checked.
- **Releases:** each [release](https://github.com/moWerk/benchymark/releases) lists its
  RPMs per architecture, what was tested on which devices and versions, what was not,
  and its label.
- **README:** the [SailfishOS section](https://github.com/moWerk/benchymark/tree/sailfishos#sailfishos)
  says who did what and carries the port's label; the run files behind its result table
  are in [`results/mosen/`](https://github.com/moWerk/benchymark/tree/sailfishos/results/mosen).
- **Not yet:** a `review-and-architecture-hints.md` (the reviewer's entry point), a
  "What was checked, and what was not" section in the README, "Superseded by" links on
  older releases. The history has not been refactored (PRACTICE §10).

Where to start reading: off-screen measuring in `src/Offscreen.cpp`, the system stages in
`src/SystemBench.cpp`, the boat in `src/Wireframe.cpp`, stages and pages in `qml/`.
