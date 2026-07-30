// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-FileCopyrightText: 2019 Florent Revest <revestflo@gmail.com>
//   (app structure derived from asteroid-flashlight)
// SPDX-License-Identifier: GPL-3.0-or-later
// benchymark — the AsteroidOS rendering benchmark.
//
// This is the watchface scene (nutty-benchy, wearing Nutty Null's layout)
// carried into a real app, because a watchface runs inside the compositor and
// its Nemo.KeepAlive request is ignored there — only a client app can hold the
// screen for the length of a run, which the measurement depends on.
//
// Layout is Nutty Null's and stays fixed: one huge glyph dead-centre, a
// travelling numeral on the inner rim, one whisper line below. What changed:
//   • the centre glyph carries the workload and is Black weight, not Thin —
//     heavier coverage means more glyph bitmap to rasterise and upload, which
//     is the point here rather than a stylistic one;
//   • the hour numeral and its fading neighbours become the FPS ROTATOR: the
//     live FPS travels the rim, and the trail FOLLOWS it, each trailing
//     numeral holding an older reading — an FPS history pushed through the
//     tail as the head advances;
//   • the whisper line names the phase.
//
// It opens with a 5→0 countdown so you can reach the rig and find the watch.
//
// Qt6 only (moWerk, 2026-07): MultiEffect, never Qt5Compat.GraphicalEffects.
// No layer.samples anywhere — a confirmed no-op on all AsteroidOS hardware
// that only logs a warning (RAG qml_patterns layer_msaa_unsupported).
// Every phase animation is gated `running: active && visible` — rendering is
// not animation, and an ungated phase would leak its cost into the next one.
//
//
// KNOWN SIDE EFFECT — some watches drop off ADB during the heavy phases.
// Observed repeatedly on beluga while the wireframe phases run with the screen
// on. The host kernel log shows the disconnect originating on the WATCH side:
//   android_work: sent uevent USB_STATE=DISCONNECTED
//   msm_otg 78d9000.usb: USB in low power mode
// with no OOM kill, no adbd crash and no segfault anywhere in the journal —
// the gadget simply loses its session, and a port power cycle brings it back
// (phy_reset -> CONNECTED -> CONFIGURED). WHY that happens is a watch-side
// question and moWerk's call; from the host all that can be said is that it
// coincides with maximum sustained load plus a lit panel.
// Consequences: the host's kernel-FPS sampling may end early on such a watch,
// so the ON-SCREEN rotator is the authoritative reading; and bench.run's
// restore step may fail while the watch is away, which is why the saved
// watchface is persisted to config and bench.restore exists.
//
// Font: Inter Tight (SIL OFL 1.1)

import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import org.asteroid.controls
import Nemo.Configuration
import Nemo.KeepAlive
import Benchymark 1.0

Application {
    id: root

    // These set the FlatMesh the launcher draws behind the app AT RUNTIME,
    // and they OVERRIDE the .desktop entry — which is why changing
    // X-Asteroid-Center-Color achieved nothing at all. Stock FlatMesh grey,
    // two tones down, so every phase is read against the same neutral
    // nothing (moWerk). Keep this in step with benchymark.desktop.template.
    centerColor: "#666666"
    outerColor: "#000000"

    // The launcher hands a watchface `wallClock` and `displayAmbient`; an app
    // gets neither, so the clock is local and "awake" is simply true — the app
    // is only on screen when it IS awake, and it holds the screen itself.
    property date now: new Date()
    readonly property bool displayAmbient: false

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    DisplayBlanking { preventBlanking: root.holding }

    // ── the scene version. CHANGE THIS whenever the workload changes: results
    // are only comparable within one version (see docs/FPS_BENCH.md).
    // Shown during the countdown so a screenshot or a spoken result can be
    // tied to an exact scene. Starts at 0.1 and steps by 0.01 per change
    // (moWerk) — results only compare within one version.
    readonly property string sceneVersion: "0.2"
    // The run holds the screen itself — same mechanism asteroid-flashlight
    // uses to stay lit only while a feature is active (moWerk). Held through
    // the countdown, because that exists so you can reach the rig, and dropped
    // the moment the last phase ends so the watch dims on its own.
    readonly property bool holding: countdown > 0 || running
    // THE gate for every workload. rendering != animation: a blanked panel
    // stops rendering but a running Animation keeps consuming, and because the
    // phase CLOCK is gated on the same flag while the workloads were not, a
    // watch that blanked during the wireframe ground it forever in the dark —
    // full CPU, no picture, until something gave way (moWerk, 2026-07-28).
    // Awake means the panel is genuinely on: displayAmbient covers AoD, and
    // MceDisplay covers a plain blank on watches that never enter ambient.
    readonly property bool awake: true
    property int loopCount: 0
    // The minute, shared by the centre glyph and the SCALE/RERASTER ring.
    readonly property string mmStr: Qt.formatDateTime(root.now, "mm")

    readonly property real maxSize: Math.min(width, height)
    readonly property real rootRadius: Math.min(width, height) * 0.41
    readonly property color fg: Qt.rgba(1, 1, 1, 1)
    readonly property color dim: Qt.rgba(1, 1, 1, 0.7)
    // ── the surface a phase sees ──────────────────────────────────────────
    // Everything below is what a phase file may reach through its `bench`
    // property. Keeping it to one place means a phase cannot quietly grow a
    // dependency on the run's internals.
    property Item rotorItem: rotor
    // SCALE and RERASTER own the CENTRE glyph as well as their own ring, but
    // the glyph is the clock and belongs to the run, so the phase only
    // declares which route to drive it by.
    property string glyphMode: "idle"

    readonly property color hot: "#f85149"
    // The AsteroidOS logo ramp (visual_design_guide.json, color_system).
    // Used wherever this app invents colour of its own, so the benchmark
    // looks like it belongs to the OS rather than to a test harness.
    readonly property var ramp: ["#be3729", "#dc2919", "#e54b3a", "#e56934",
                                 "#e57c21", "#e58a21", "#f19a11", "#f0ae0e",
                                 "#f0c30e"]
    // The gold end of the ramp: pairs with the Benchy wireframe's cyan
    // without competing with the red the rotator turns below 45 fps.
    readonly property color gold: "#f0c30e"

    // ── frame counting ────────────────────────────────────────────────────
    // frameSwapped fires once per PRESENTED frame, from the render thread.
    //
    // The previous counter incremented on an animation's value change, which
    // sounded equivalent and is not: Qt Quick renders on one thread and runs
    // JS, timers and property updates on another. A phase that loads the GUI
    // thread — SHAPES re-tessellating its path is the clearest case — leaves
    // the render thread presenting a comfortable 60 while everything
    // JS-driven crawls. The old counter lived on the starved thread, so it
    // reported 20 for a phase that visibly ran smooth (moWerk), and the sweep
    // that was meant to be smooth stuttered at the same wrong rate.
    //
    // Counting presented frames measures what the eye sees. GUI-thread
    // starvation is a real cost too, but it is a different number and must
    // not be reported as this one.
    property int frameCount: 0
    property int fps: 0
    property var fpsHistory: []
    readonly property int trailCount: 5

    Connections {
        target: root.Window.window
        function onFrameSwapped() { root.frameCount++; }
    }

    // ── phase machine ─────────────────────────────────────────────────────
    // name, duration, and the file that renders it. One file per phase: a
    // Loader with a `source` defers the PARSE as well as the instantiation, so
    // a phase costs nothing at all — not even compile time — until it runs.
    readonly property var phases: [
        { name: "IDLE",       dur: 10, file: "Idle" },
        { name: "SCALE",      dur: 10, file: "Scale" },
        { name: "RERASTER",   dur: 10, file: "Reraster" },
        { name: "ORBIT",      dur: 10, file: "Orbit" },
        { name: "OVERDRAW",   dur: 10, file: "Overdraw" },
        { name: "DRAWCALLS",  dur: 10, file: "Drawcalls" },
        { name: "DRAWFONT",   dur: 10, file: "Drawfont" },
        { name: "SHAPES",     dur: 10, file: "Shapes" },
        { name: "CASCADE",    dur: 10, file: "Cascade" },
        { name: "CLOUDLIGHT", dur: 10, file: "CloudLight" },
        { name: "CLOUDHEAVY", dur: 10, file: "CloudHeavy" },
        { name: "BENCHY",     dur: 10, file: "Benchy" }
    ]
    // A quiet TWO seconds between phases: watches enter a phase carrying the
    // previous one's backlog, and the frame rate is still falling when a short
    // phase ends, so the number recorded is a blend of two workloads rather
    // than a measurement of one (moWerk). Nothing animates during the gap; it
    // shows the NAME of the phase about to start.
    readonly property int gapSeconds: 2
    property bool inGap: false
    property int gapLeft: 0
    // Workloads compare against THIS, not `phase`: during a gap it matches
    // nothing, so every animation and every visible item switches off without
    // needing its own gap condition.
    // expires mid-construction hands the next phase a stall to measure, which
    // shows up as a bad number for a phase that was merely still loading.
    // The gap holds until the next scene is PARSED AND BUILT. A gap that
    // expires mid-construction hands the following phase a stall to measure
    // and reports it as a bad number for that phase.
    readonly property bool nextBuilt: !inGap || phase + 1 >= phases.length
                                      || preloader.status === Loader.Ready
    // The heavy phases are the ones worth waiting for; everything else is
    // ready as soon as it is asked for.

    // Workloads keep rendering through a 400 ms fade, then switch off. Without
    // this a phase cuts to black and the next cuts in — the gap reads as a
    // glitch rather than as a pause (moWerk).
    property bool fadedOut: false

    onInGapChanged: {
        if (inGap) {
            fadeOut.restart();
            root.preloadNext();
        } else {
            fadedOut = false;
        }
    }

    Timer {
        id: fadeOut

        interval: 420
        onTriggered: root.fadedOut = true
    }

    readonly property int activePhase: fadedOut ? -2 : phase
    readonly property string nextName: (phase + 1) < phases.length
                                       ? phases[phase + 1].name : "DONE"
    // ── run modes ─────────────────────────────────────────────────────────
    // AUTO is the default: countdown, then every phase back to back. Tapping
    // during the countdown does not switch mode by itself — it PAUSES and
    // offers the choice, so a mis-tap has a way back (moWerk). MANUAL holds a
    // phase indefinitely and advances only when told, which is how you reach
    // one specific test without sitting through the run before it.
    property bool manual: false
    property bool choosing: false
    property int countdown: 5
    property int phase: -1                         // -1 = counting down
    property int phaseElapsed: 0
    readonly property bool running: phase >= 0 && phase < phases.length
    readonly property bool done: phase >= phases.length
    readonly property string phaseName: running ? phases[phase].name : (done ? "DONE" : "READY")
    // Per-phase results, harvested by a-d-b from the watch (and mirrored by the
    // host's own kernel-side sampling): [{phase, min, avg, samples}]
    property var results: []
    property var _cur: []
    // The phase is only "running" for measurement purposes once its scene has
    // been built. A phase that never becomes ready is capped rather than
    // hanging the run: it reports zero samples, which reads as a failure
    // instead of as a fast phase.
    readonly property bool sceneReady: sceneLoader.status === Loader.Ready
    property int waitedForScene: 0
    readonly property int sceneWaitCap: 15

    BenchLog { id: benchLog }

    // Written once, when the last phase closes: one complete run per file, so
    // a-d-b never has to guess whether it is reading a partial result.
    function writeResults() {
        var payload = {
            "scene": root.sceneVersion,
            "finished": new Date().toISOString(),
            "resolution": root.width + "x" + root.height,
            "phases": []
        };
        for (var i = 0; i < results.length; i++)
            payload.phases.push(results[i]);
        if (!benchLog.write(JSON.stringify(payload, null, 1)))
            console.warn("benchymark: could not write", benchLog.path());
    }

    function restartRun() {
        results = [];
        loopCount++;
        countdown = 3;              // shorter on a rerun; you are already here
        phase = -1;
    }

    function tickSecond() {
        if (done)
            return;                 // parked on the results until the next wake
        if (choosing)
            return;                 // the countdown is held while you decide
        if (countdown > 0) {
            countdown--;
            return;
        }
        if (countdown === 0 && phase === -1) {
            phase = 0;
            phaseElapsed = 0;
            _cur = [];
            return;
        }
        if (!running)
            return;
        if (inGap) {
            gapLeft--;
            // Never shorter than gapSeconds, but longer if the next scene is
            // still coming up.
            if (gapLeft <= 0 && nextBuilt) {
                inGap = false;
                phase++;
                phaseElapsed = 0;
                waitedForScene = 0;
                _cur = [];
            }
            return;
        }
        // Hold the clock until the scene is up. Without this the phase spent
        // its first seconds measuring an empty screen at 60.
        if (!sceneReady) {
            waitedForScene++;
            if (waitedForScene < sceneWaitCap)
                return;
        }
        phaseElapsed++;
        // In manual mode the clock still counts (the label needs it) but the
        // phase never closes on its own — only advancePhase() ends it.
        if (!manual && phaseElapsed >= phases[phase].dur) {
            var s = _cur.slice();
            var sum = 0, mn = 999;
            for (var i = 0; i < s.length; i++) {
                sum += s[i];
                if (s[i] < mn)
                    mn = s[i];
            }
            var r = results.slice();
            r.push({
                "phase": phases[phase].name,
                "avg": s.length ? Math.round(sum / s.length) : 0,
                "min": s.length ? mn : 0,
                "samples": s.length
            });
            results = r;
            if (phase + 1 >= phases.length)
                root.writeResults();   // last phase closed — persist the run
            inGap = true;              // settle before the next phase starts
            gapLeft = gapSeconds;
        }
    }

    // Close the current phase and move on. The clock calls this in auto mode;
    // the tap target calls it in manual mode. Skip and Next are the SAME
    // action — they differ only in when you press, so there is one code path
    // and one button, and the label reads whichever the moment deserves.
    function advancePhase() {
        if (!running || inGap)
            return;
        var s2 = _cur.slice();
        var sum = 0, mn = 999;
        for (var i = 0; i < s2.length; i++) {
            sum += s2[i];
            if (s2[i] < mn)
                mn = s2[i];
        }
        var r = results.slice();
        r.push({
            "phase": phases[phase].name,
            "avg": s2.length ? Math.round(sum / s2.length) : 0,
            "min": s2.length ? mn : 0,
            "samples": s2.length,
            // A manually-cut phase is NOT comparable with a full 10 s window,
            // and a result file that hid that would be worse than no file.
            "manual": root.manual
        });
        results = r;
        if (phase + 1 >= phases.length)
            root.writeResults();
        inGap = true;
        gapLeft = gapSeconds;
    }

    anchors.fill: parent
    // An `Animation on opacity` leaves the property where it stopped, so the
    // countdown's pulse could strand the clock at a third of its opacity for
    // the whole run — the same trap as the scale and pixelSize animations.
    onCountdownChanged: if (countdown <= 0) centreText.opacity = 1

    onPhaseChanged: {
        root.loadPhase();
        phaseBeacon.value = (phase < 0 ? "countdown"
                             : (done ? "done" : phases[phase].name))
                            + " loop" + loopCount;
    }

    // Written on every phase change and left there: when a watch drops off the
    // link mid-run this is the last thing it recorded, so reading it after
    // recovery names the phase that was live at the moment it went.
    ConfigurationValue {
        id: phaseBeacon

        key: "/desktop/asteroid/benchphase"
        defaultValue: ""
    }

    // The frame-tick driver. Long duration, infinite loops — the value itself
    // is meaningless, only the per-frame notification matters.
    // One second: harvest the frame count into fps + the trail history, and
    // drive the countdown / phase machine.
    Timer {
        interval: 1000
        repeat: true
        running: !displayAmbient
        onTriggered: {
            root.fps = root.frameCount;
            root.frameCount = 0;
            var h = root.fpsHistory.slice();
            h.unshift(root.fps);
            while (h.length > root.trailCount)
                h.pop();
            root.fpsHistory = h;
            // Only count once the scene is actually UP. setSource() has to
            // instantiate the phase, and until it does the screen is empty and
            // the counter honestly reads 60 — so the average was measuring
            // load time, not the workload. That is what made every phase
            // report 60 while the rotator visibly dipped, and what let BENCHY
            // expire before it had finished building (moWerk).
            // Drop the phase's FIRST second. It straddles the gap-end
            // transition and the scene's first frames, so it mixes idle
            // frames into the workload — 60s leaking into a phase that is
            // nowhere near 60 (moWerk). Every phase runs a second longer than
            // it measures, which is the honest trade.
            if (root.running && root.sceneReady && root.phaseElapsed >= 1) {
                var c = root._cur.slice();
                c.push(root.fps);
                root._cur = c;
            }
            root.tickSecond();
        }
    }

    // ── the phase, BELOW the clock ────────────────────────────────────────
    // Declaration order is paint order, and this must come before the centre
    // glyph and the rotator: the tests run behind the thing that tells the
    // time, like a wallpaper. The refactor put the Loader after both, so every
    // phase painted over the clock instead.

    // ORBIT's cost: a pulsing shadow recomputed every frame over the rotor.

    // ── the phase itself ──────────────────────────────────────────────────
    // One Loader carries whichever phase is running. setSource() rather than a
    // `source` binding, because it passes `bench` as an INITIAL property — the
    // phase is constructed with it already set, so no binding inside a phase
    // ever evaluates against a null bench.
    Loader {
        id: sceneLoader

        anchors.fill: parent
        // A BINDING, not an assignment. The imperative version did not take,
        // so a phase sat at full opacity through the gap and the next one cut
        // straight over it. Bound to inGap it reliably fades out before the
        // gap and back in with the phase that follows.
        opacity: root.inGap ? 0 : 1
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }
    }

    // Parses the NEXT phase during the gap, so the switch costs nothing at the
    // moment the clock starts. Asynchronous: the point is to keep the
    // compile off the frame that has to render.
    Loader {
        id: preloader

        asynchronous: true
        active: false
        visible: false
    }

    // The glyph's own geometry, on ROOT: the wrapper below is a fade, not a
    // scope. Left inside it these read as undefined through root.* here AND
    // through bench.* in the Scale and Reraster phases.
    readonly property real baseGlyph: maxSize * 0.336   // +20% (moWerk)
    readonly property real glyphPeak: 1.8

    // ── centre glyph, with the gap fade on a WRAPPER ──────────────────────
    // The fade cannot live on the Text itself: its countdown pulse is an
    // `Animation on opacity`, which owns that property outright and would
    // fight any binding. A parent Item carries the gap fade instead, so both
    // work and neither knows about the other. During a gap the clock steps
    // aside too, leaving only the phase title (moWerk).
    Item {
        anchors.fill: parent
        opacity: root.inGap ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }

        // ── centre glyph ──────────────────────────────────────────────────────
        // The workload carrier. Black weight (moWerk): more coverage per glyph, so
        // a cache miss costs more — exactly what RERASTER is meant to expose.
        // SCALE and RERASTER show the SAME visual span by two different routes:
        // SCALE animates a transform on distance-field text (the pattern the RAG
        // recommends), RERASTER animates font.pixelSize on native-rendered text
        // (the anti-pattern it warns about — every size churns the glyph cache
        // with a CPU rasterisation and a texture upload). Their ratio IS the
        // measurement.
        // ── OVERDRAW: stacked translucent full-screen fills, the compositor must
        // blend every one of them every frame. Pure fill rate; scales with panel
        // pixels, which is why results are also reported per megapixel.

        // ── DRAWCALLS: org.asteroid.controls Icon is a QQuickPaintedItem — each
        // icon is its own scene-graph texture and cannot batch with its siblings,
        // so this measures draw-call/state overhead rather than fill rate.

        // ── SHAPES: a stroked path whose geometry changes every frame, so it is
        // re-tessellated continuously — the geometry pipeline, not fill or glyphs.
        // ── DRAWFONT: the same storm rendered as COLOUR GLYPHS ────────────────
        // Not a second draw-call phase, and the difference is the finding. Text
        // batches: Qt packs glyphs into an atlas and draws many in one call, which
        // is exactly why DRAWCALLS uses Icons (each a QQuickPaintedItem with its
        // own texture, unbatchable). Colour-emoji glyphs sit between the two —
        // they carry their own bitmap/COLR data rather than joining the
        // distance-field atlas, so this measures coloured-glyph upload against
        // DRAWCALLS' per-item textures at an identical item count and motion.


        // ── CASCADE: scale on an Item with many children forces a transform
        // recalculation for every child on every frame (RAG expensive_operations).

        // A SECOND cascade, counter-phase and counter-rotating. One cascade held a
        // flat 60 on every watch tried (moWerk), so the phase was measuring
        // nothing: two independent transform trees double the per-frame
        // recalculation without making the picture look busier, because this one
        // turns the other way and breathes on the opposite beat.

        // ── THE CLOUD PAIR ────────────────────────────────────────────────────
        // One scene at two costs. Per fragment, in lattice-hash evaluations:
        //
        //   CLOUDLIGHT  24   cheap fract hash, 3 octaves, ONE scalar warp
        //   CLOUDHEAVY 140   sin() hash, 7 octaves, TWO warps
        //
        // The pair prices the two things that make a procedural cloud
        // expensive: the transcendental hash, and the domain warp — which is a
        // SERIAL dependency, so it costs more than its instruction count
        // suggests and the GPU cannot hide it behind latency. Measured 13
        // against 5 on nemo.
        //
        // A third, warp-free rung existed briefly as a GPU baseline and as a
        // candidate stock wallpaper. It was never going to reach FlatMesh's
        // frugality, and that job went to people who write shaders for a
        // living; git holds it.


        // ── CLOUDHEAVY: the one phase that is purely fragment-bound ───────────
        // Everything else here is CPU, geometry or draw-call work; this is the GPU
        // doing 35 noise lookups (140 sin-based hashes) per pixel per frame, so
        // it scales with PANEL
        // AREA rather than scene complexity — the phase that most needs Mpix/s
        // reported beside raw FPS. Qt6 loads the pre-compiled .qsb (inline GLSL
        // crashes it); the .frag source ships beside it so this can be rebuilt.

        // ── BENCHY: 3DBenchy as a rotating wireframe, projected in QML ────────
        // There is no 3D engine on these images (QtQuick3D is absent — checked on
        // catfish), so the watchface IS the renderer: every frame it rotates 1118
        // vertices, projects them with a perspective divide, and hands six point
        // arrays to six PathPolylines. The model arrives pre-welded and chained
        // into strips by tools/stl_to_qml_mesh.py, so the watch pays only for
        // rotate → project → stroke. This is deliberately the heaviest phase and
        // the finale: JS arithmetic and Shape re-tessellation at once.
        //
        // 3DBenchy is public domain (NTI Group, 2025-02-14); credit to Creative
        // Tools / NTI.
        // How many of the six strips to draw — the dial for how brutal this is.
        // Lower it if the phase is a slideshow rather than a rotation.


        // BENCHYLITE (phase 8) runs the same boat decimated to 438 vertices /
        // 1545 segments; BENCHY (phase 9) is the full 1118 / 3720. Same code path,
        // so the pair measures how frame time scales with segment count.


        // ── FPS rotator: head + following trail ───────────────────────────
        // DECLARED LAST of the visuals on purpose (moWerk): declaration order
        // IS paint order in QML, so this sits above every workload layer —
        // the readout must stay legible through overdraw, icons and the
        // wireframe. Never fix this with z: (RAG paint_order rule).
        // ── head + following trail ───────────────────────────────
        // Nutty Null's hour numeral and its fading neighbours, repurposed. The
        // head shows the live FPS at the leading rim position; each trail numeral
        // sits BEHIND it holding an older reading, so values push backwards
        // through the tail as the head sweeps on.
        // ── the clock, moved ABOVE every workload ─────────────────────────────
        // Declaration order is paint order. The tests now run BEHIND the thing
        // that tells the time, like a wallpaper (moWerk) — which also means the
        // glyph never disappears under a phase, so the watch stays a watch while
        // it is being tortured. It is still a test subject itself: SCALE and
        // RERASTER drive this very glyph.

        // Both text phases drive a RING of glyphs as well as the centre one: a
        // single Text barely troubled any watch (moWerk). The ring uses the same
        // route as the centre glyph in each phase, so the SCALE:RERASTER ratio
        // still isolates the glyph-cache path — only the magnitude changed.

        Text {
            id: centreText

            readonly property bool scaling: root.glyphMode === "scale"
            readonly property bool rerastering: root.glyphMode === "reraster"

            text: root.countdown > 0 ? root.countdown : root.mmStr
            visible: !root.done
            color: root.countdown > 0 ? root.hot : root.fg
            anchors.centerIn: parent
            renderType: rerastering ? Text.NativeRendering : Text.QtRendering
            font.family: "Inter Tight"
            // Light, not Black: moWerk wants this beautiful first and expensive
            // second — Nutty Null's thin elegance survives the benchmark. The
            // countdown is the exception: it has to read across a room, so it
            // takes a step up the weight ramp.
            font.weight: root.countdown > 0 ? Font.Normal : Font.Light
            font.letterSpacing: -root.maxSize * 0.02
            font.pixelSize: root.baseGlyph

            // Both animations below own their property while running and LEAVE IT
            // WHERE THEY STOPPED when they end — which is why the clock stayed
            // blown up to full screen for every phase after RERASTER. Putting it
            // back is not automatic; these two handlers do it.
            onScalingChanged: if (!scaling) scale = 1
            onRerasteringChanged: if (!rerastering) font.pixelSize = root.baseGlyph

            SequentialAnimation on scale {
                running: centreText.scaling && centreText.visible && root.awake
                loops: Animation.Infinite
                alwaysRunToEnd: false
                NumberAnimation { from: 1; to: root.glyphPeak; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: root.glyphPeak; to: 1; duration: 900; easing.type: Easing.InOutSine }
            }

            SequentialAnimation on font.pixelSize {
                running: centreText.rerastering && centreText.visible && root.awake
                loops: Animation.Infinite
                NumberAnimation { from: root.baseGlyph; to: root.baseGlyph * root.glyphPeak; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: root.baseGlyph * root.glyphPeak; to: root.baseGlyph; duration: 900; easing.type: Easing.InOutSine }
            }

            // The countdown reads as a pulse so it is obvious across the room.
            SequentialAnimation on opacity {
                running: root.countdown > 0 && root.awake
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.35; duration: 500 }
                NumberAnimation { from: 0.35; to: 1; duration: 500 }
            }

        }

    }

    readonly property bool orbitPhase: root.activePhase === 3

    Item {
        id: rotor

        anchors.fill: parent
        transformOrigin: Item.Center

        // RotationAnimator, not a binding or a Timer: Animators run on the
        // RENDER thread, so the sweep keeps its pace even while a phase has
        // the GUI thread pinned. One lap per phase; ORBIT takes one and a
        // half and starts from six o'clock.
        RotationAnimator on rotation {
            from: root.orbitPhase ? 180 : 0
            to: (root.orbitPhase ? 180 : 0) + (root.orbitPhase ? 540 : 360)
            duration: (root.running ? root.phases[root.phase].dur : 10) * 1000
            loops: Animation.Infinite
            running: root.running && root.sceneReady && !root.inGap && !root.displayAmbient
        }
        // Nothing to report during the countdown, and a 0 sitting on the rim
        // reads as a measurement rather than as an absence. It arrives when
        // IDLE does — and leaves with the last phase. Left up on the end
        // screen it kept reporting, so the final phase's number sat there
        // twitching over a screen that is doing nothing (moWerk): a reading
        // that belongs to a workload no longer on display.
        opacity: root.running ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }

        Repeater {
            model: root.trailCount + 1

            delegate: Text {
                readonly property bool head: index === 0
                // A STATIC angle now: the ring itself turns. Positions used to
                // be recomputed in JS from an animated angle, which pinned the
                // sweep to the GUI thread — so on a phase that loads that
                // thread the needle stuttered at the loaded rate while the
                // scene behind it ran smooth (moWerk).
                readonly property real ang: (-index * 13 - 90) * Math.PI / 180
                readonly property int shown: head ? root.fps
                                                  : (root.fpsHistory.length > index ? root.fpsHistory[index] : -1)

                text: shown >= 0 ? shown : ""
                visible: shown >= 0
                color: shown >= 0 && shown < 45 ? root.hot : root.fg
                opacity: head ? 1 : Math.max(0.12, 0.62 - (index - 1) * 0.13)
                x: root.width / 2 + root.rootRadius * Math.cos(ang) - width / 2
                y: root.height / 2 + root.rootRadius * Math.sin(ang) - height / 2
                font.family: "Inter Tight"
                font.weight: head ? Font.Bold : Font.Light
                font.pixelSize: root.maxSize * (head ? 0.13 : 0.1)

                // Equal and opposite, so a numeral stays upright while the
                // ring carries it round. Also an Animator, so both halves live
                // on the render thread and cannot drift apart under load.
                RotationAnimator on rotation {
                    from: root.orbitPhase ? -180 : 0
                    to: (root.orbitPhase ? -180 : 0) - (root.orbitPhase ? 540 : 360)
                    duration: (root.running ? root.phases[root.phase].dur : 10) * 1000
                    loops: Animation.Infinite
                    running: root.running && root.sceneReady && !root.inGap && !root.displayAmbient
                }
            }

        }

    }

    function loadPhase() {
        // Guard on the INDEX, never on `running`: `running` is a derived
        // binding and may not have re-evaluated at the moment this handler
        // fires. When it had not, phases[phase] came back undefined, the
        // handler threw reading .file, and the scene was never unloaded — the
        // last phase then ran forever with nothing able to stop it.
        if (phase < 0 || phase >= phases.length) {
            sceneLoader.setSource("");
            return;
        }
        var ph = phases[phase];
        sceneLoader.setSource("phases/" + ph.file + ".qml",
                              { "bench": root });
    }

    function preloadNext() {
        var n = phase + 1;
        if (n >= phases.length) {
            preloader.active = false;
            return;
        }
        preloader.setSource("phases/" + phases[n].file + ".qml",
                            { "bench": root });
        preloader.active = true;
    }

    // ── tap to take control ───────────────────────────────────────────────
    // Covers the screen only while counting down. Tapping opens the choice
    // below rather than switching mode outright: the whole point is that a
    // stray tap costs nothing.
    MouseArea {
        anchors.fill: parent
        enabled: root.countdown > 0 && !root.choosing
        onClicked: root.choosing = true
    }

    // Advancing in manual mode. Declared BEFORE the readouts so it can never
    // sit over the numbers, and enabled only while a manual phase is live.
    MouseArea {
        anchors.fill: parent
        enabled: root.manual && root.running && !root.inGap
        onClicked: root.advancePhase()
    }

    // ── the choice ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: root.choosing

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.72
        }

        // Anchored AROUND the vertical centre rather than stacked in a Column
        // (moWerk): the upper button's bottom sits on the centre line, the
        // lower button's top sits on it, and equal margins push them apart —
        // so the pair is symmetric about the middle of the panel whatever the
        // panel is. Everything here is 20% larger than the first cut, and the
        // gap between the buttons is double.
        Item {
            anchors.fill: parent

            readonly property real btnW: root.maxSize * 0.744
            readonly property real btnH: root.maxSize * 0.186
            readonly property real gap: root.maxSize * 0.045

            Text {
                id: pausedLabel

                anchors.bottom: continueBtn.top
                anchors.bottomMargin: parent.gap
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PAUSED"
                color: root.dim
                font.family: "Inter Tight"
                font.weight: Font.Medium
                font.pixelSize: root.maxSize * 0.06
                font.letterSpacing: root.maxSize * 0.01
            }

            // Continue standard — the remorse path for a mis-tap.
            Rectangle {
                id: continueBtn

                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: parent.gap
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.btnW
                height: parent.btnH
                radius: height / 2
                color: "#1f2733"
                border.color: root.dim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "continue"
                    color: root.fg
                    font.family: "Inter Tight"
                    font.weight: Font.Medium
                    font.pixelSize: root.maxSize * 0.070
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.manual = false;
                        root.choosing = false;
                    }
                }

            }

            // Phase control — indefinite phases, advanced by tapping.
            Rectangle {
                id: manualBtn

                anchors.top: parent.verticalCenter
                anchors.topMargin: parent.gap
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.btnW
                height: parent.btnH
                radius: height / 2
                color: root.gold
                opacity: 0.92

                Text {
                    anchors.centerIn: parent
                    text: "phase control"
                    color: "#101418"
                    font.family: "Inter Tight"
                    font.weight: Font.DemiBold
                    font.pixelSize: root.maxSize * 0.066
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.manual = true;
                        root.choosing = false;
                        root.countdown = 0;      // straight in; you are here
                    }
                }

            }

        }

    }

    // ── end screen ────────────────────────────────────────────────────────
    // The run finishes HERE rather than looping: a plain Restart target that
    // says what it does (moWerk). The MouseArea exists only while the run is
    // finished, so it can never eat a gesture mid-run, and it takes clicks
    // only — a drag still reaches the launcher, so the screen can be swiped
    // away like any other watchface.
    Item {
        anchors.fill: parent
        visible: root.done

        // Mirrors RESTART exactly: the same 0.2 offset from the centre line,
        // measured the other way, so the glyph sits evenly between them. The
        // version is already on the whisper line below — saying it twice on
        // one screen is noise (moWerk).
        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.verticalCenter
                bottomMargin: root.maxSize * 0.2
            }
            text: "COMPLETE"
            color: root.dim
            font.family: "Inter Tight"
            font.weight: Font.Medium
            font.pixelSize: root.maxSize * 0.06
            font.letterSpacing: root.maxSize * 0.01
        }

        Text {
            id: restartGlyph

            anchors.centerIn: parent
            text: "\u21BB"                      // ↻
            color: root.fg
            font.family: "Inter Tight"
            font.weight: Font.Light
            font.pixelSize: root.maxSize * 0.34
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.verticalCenter
                topMargin: root.maxSize * 0.2
            }
            text: "RESTART"
            color: root.dim
            font.family: "Inter Tight"
            font.weight: Font.Light
            font.pixelSize: root.maxSize * 0.07
            font.letterSpacing: root.maxSize * 0.016
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.restartRun()
        }

    }

    // ── whisper line: phase name and progress (Nutty Null's date slot) ────
    // Two lines, not one: at arm's length the single line was too slim to
    // register at all, and a long phase name wrapped into itself (moWerk).
    // The counter moved to its own line so the name never has to compete with
    // it for width, and the separator dot went with it.
    Column {
        // Out of the way while the pause buttons are up (moWerk).
        visible: !root.choosing

        anchors {
            bottom: parent.bottom
            bottomMargin: parent.height * 0.15
            horizontalCenter: parent.horizontalCenter
        }
        width: parent.width * 0.86
        spacing: root.maxSize * 0.012

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            // Wrapped lines used to clip into one another; distance-field text
            // needs the leading set explicitly at this weight.
            lineHeight: 1.25
            text: root.countdown > 0 ? "GET TO THE RIG" : root.phaseName
            visible: !root.done
            color: root.dim
            font.family: "Inter Tight"
            font.weight: Font.Medium
            font.pixelSize: root.maxSize * 0.054
            font.letterSpacing: root.maxSize * 0.010
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.running ? (root.phase + 1) + "/" + root.phases.length
                                 + (root.manual ? "  \u00b7  phase control" : "")
                               : "v" + root.sceneVersion
            color: root.dim
            opacity: 0.75
            font.family: "Inter Tight"
            font.weight: Font.Normal
            font.pixelSize: root.maxSize * 0.042
            font.letterSpacing: root.maxSize * 0.008
        }

    }

    // ── phase name: announced in the GAPS only ────────────────────────────
    // It used to stand through the whole phase, which duplicated the line at
    // the bottom — invisible as a duplicate only because that line was too
    // slim to read from arm's length (moWerk). Now it does one job: announce
    // what is about to run, during the quiet gap, then get out of the way.
    //
    // The fade fills the 2 s gap exactly: 200 in, 1200 held, 600 out. Gold
    // from the logo ramp, which reads against the Benchy wireframe's cyan
    // without competing with the red the rotator turns below 45 fps.
    //
    // Declared LAST so nothing can cover it — declaration order is paint
    // order, and the minute glyph now sits above every workload.
    Text {
        id: gapTitle

        anchors.centerIn: parent
        text: root.inGap ? root.nextName
                         : (root.manual && root.running ? root.phaseName : "")
        color: root.gold
        // In manual mode the phase never ends by itself, so the announcement
        // has nothing to announce — it holds the CURRENT name instead, dimmed,
        // as the label for the tap target.
        opacity: root.manual && !root.inGap ? 0.30 : 0
        visible: opacity > 0.01
        font.family: "Inter Tight"
        font.weight: Font.DemiBold
        font.pixelSize: root.maxSize * 0.1
        font.letterSpacing: root.maxSize * 0.008

        SequentialAnimation on opacity {
            running: root.inGap && root.awake
            NumberAnimation { to: 0.95; duration: 200; easing.type: Easing.OutQuad }
            PauseAnimation { duration: 1200 }
            NumberAnimation { to: 0; duration: 600; easing.type: Easing.InQuad }
        }

    }

}
