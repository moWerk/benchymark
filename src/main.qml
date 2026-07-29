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
import QtQuick.Effects
import QtQuick.Shapes
import org.asteroid.controls
import "benchy-mesh.js" as Mesh
import "benchy-mesh-lite.js" as MeshLite
import Nemo.Configuration
import Nemo.KeepAlive
import Benchymark 1.0

Application {
    id: root

    centerColor: "#58A6FF"
    outerColor: "#0B1B2E"

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
    // An animation ticks once per RENDERED frame, so dropped frames simply do
    // not tick. Window-free and Qt-version agnostic; no QQuickWindow needed.
    property real frameTick: 0
    property int frameCount: 0
    property int fps: 0
    property var fpsHistory: []
    readonly property int trailCount: 5

    onFrameTickChanged: root.frameCount++

    // ── phase machine ─────────────────────────────────────────────────────
    readonly property var phases: [
        { name: "IDLE",       dur: 10 },  // the sanity floor: must be flat 60
        { name: "SCALE",      dur: 10 },  // distance-field text, scale transform
        { name: "RERASTER",   dur: 10 },  // same visual, animated pixelSize
        { name: "ORBIT",      dur: 10 },  // rim numeral + pulsing shadow
        { name: "OVERDRAW",   dur: 10 },  // stacked translucent full-screen fills
        { name: "DRAWCALLS",  dur: 10 },  // unbatchable SVG Icons in motion
        { name: "DRAWFONT",   dur: 10 },  // the same count as COLOUR GLYPHS
        { name: "SHAPES",     dur: 10 },  // re-tessellated Shape path
        { name: "CASCADE",    dur: 10 },  // scale on Items with many children
        { name: "CLOUDLITE",  dur: 10 },  // GPU baseline: 12 hashes/fragment
        { name: "CLOUDMID",   dur: 10 },  // one domain warp: 48 hashes/fragment
        { name: "CLOUDHEAVY", dur: 10 },  // the beast: 140 sin-hashes/fragment
        { name: "BENCHYLITE", dur: 10 },  // the boat at 438 vertices / 1545 segments
        { name: "BENCHY",     dur: 10 }   // the boat at 1118 vertices / 3720 segments
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
    // True while phase `n` should EXIST: the phase itself, or the one about
    // to start while we sit in the gap. Building one phase ahead is what lets
    // a heavy scene be ready before its clock starts.
    function wants(n) {
        return phase === n || (inGap && phase + 1 === n);
    }
    // The gap holds until the next scene is actually built. A fixed gap that
    // expires mid-construction hands the next phase a stall to measure, which
    // shows up as a bad number for a phase that was merely still loading.
    readonly property bool nextBuilt: !inGap || phase + 1 >= phases.length
                                      || sceneBuilt
    // The heavy phases are the ones worth waiting for; everything else is
    // ready as soon as it is asked for.
    readonly property bool sceneBuilt: {
        var n = phase + 1;
        if (n === 5)
            return iconRep.count === 96;
        if (n === 6)
            return glyphRep.count === 96;
        if (n === 8)
            return cascRep.count === 160 && cascBRep.count === 160;
        return true;
    }

    // Workloads keep rendering through a 400 ms fade, then switch off. Without
    // this a phase cuts to black and the next cuts in — the gap reads as a
    // glitch rather than as a pause (moWerk).
    property real workOpacity: 1
    property bool fadedOut: false

    Behavior on workOpacity {
        NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }

    onInGapChanged: {
        if (inGap) {
            workOpacity = 0;
            fadeOut.restart();
        } else {
            fadedOut = false;
            workOpacity = 1;
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
                _cur = [];
            }
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
    onPhaseChanged: phaseBeacon.value = (phase < 0 ? "countdown"
                                        : (done ? "done" : phases[phase].name))
                                        + " loop" + loopCount

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
    NumberAnimation on frameTick {
        from: 0
        to: 1000000
        duration: 16000000
        loops: Animation.Infinite
        running: !displayAmbient
    }

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
            if (root.running) {
                var c = root._cur.slice();
                c.push(root.fps);
                root._cur = c;
            }
            root.tickSecond();
        }
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
    Item {
        anchors.fill: parent
        visible: root.activePhase === 4 && root.awake
        opacity: root.workOpacity

        Repeater {
            model: 24

            delegate: Rectangle {
                anchors.fill: parent
                color: index % 2 ? "#2000a0ff" : "#20ff5090"

                SequentialAnimation on opacity {
                    running: root.activePhase === 4 && parent.visible && root.awake
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.35; to: 0.9; duration: 600 + index * 90 }
                    NumberAnimation { from: 0.9; to: 0.35; duration: 600 + index * 90 }
                }

            }

        }

    }

    // ── DRAWCALLS: org.asteroid.controls Icon is a QQuickPaintedItem — each
    // icon is its own scene-graph texture and cannot batch with its siblings,
    // so this measures draw-call/state overhead rather than fill rate.
    Item {
        id: iconStorm

        anchors.fill: parent
        visible: root.activePhase === 5 && root.awake
        opacity: root.workOpacity

        Repeater {
            id: iconRep

            model: root.wants(5) ? 96 : 0

            delegate: Icon {
                readonly property real a: index / 96 * 2 * Math.PI * 3
                readonly property real rad: root.rootRadius * (0.18 + (index % 7) * 0.13)

                name: "ios-flash"
                width: root.maxSize * 0.09
                height: width
                x: root.width / 2 + rad * Math.cos(a + iconStorm.spin) - width / 2
                y: root.height / 2 + rad * Math.sin(a + iconStorm.spin) - height / 2
            }

        }

        property real spin: 0

        NumberAnimation on spin {
            from: 0
            to: 2 * Math.PI
            duration: 3000
            loops: Animation.Infinite
            running: iconStorm.visible && root.awake
        }

    }

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
    Item {
        id: glyphStorm

        anchors.fill: parent
        visible: root.activePhase === 6 && root.awake
        opacity: root.workOpacity

        Repeater {
            id: glyphRep

            model: root.wants(6) ? 96 : 0

            delegate: Text {
                readonly property real a: index / 96 * 2 * Math.PI * 3
                readonly property real rad: root.rootRadius * (0.18 + (index % 7) * 0.13)

                text: "\uD83D\uDE80"                 // 🚀
                font.pixelSize: root.maxSize * 0.075
                x: root.width / 2 + rad * Math.cos(a + glyphStorm.spin) - width / 2
                y: root.height / 2 + rad * Math.sin(a + glyphStorm.spin) - height / 2
            }

        }

        property real spin: 0

        NumberAnimation on spin {
            from: 0
            to: 2 * Math.PI
            duration: 5200
            loops: Animation.Infinite
            running: glyphStorm.visible && root.awake
        }

    }

    Shape {
        id: spiro

        property real t: 0

        anchors.fill: parent
        visible: root.activePhase === 7 && root.awake
        opacity: root.workOpacity
        preferredRendererType: Shape.CurveRenderer

        NumberAnimation on t {
            from: 0
            to: 2 * Math.PI
            duration: 4000
            loops: Animation.Infinite
            running: spiro.visible && root.awake
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: "#7ee787"
            strokeWidth: root.maxSize * 0.02
            capStyle: ShapePath.RoundCap
            startX: root.width / 2
            startY: root.height / 2 - root.rootRadius

            PathCubic {
                x: root.width / 2 + root.rootRadius * Math.cos(spiro.t)
                y: root.height / 2 + root.rootRadius * Math.sin(spiro.t)
                control1X: root.width / 2 + root.rootRadius * 1.6 * Math.cos(spiro.t * 2)
                control1Y: root.height / 2 - root.rootRadius * 1.6 * Math.sin(spiro.t * 3)
                control2X: root.width / 2 - root.rootRadius * 1.6 * Math.sin(spiro.t * 3)
                control2Y: root.height / 2 + root.rootRadius * 1.6 * Math.cos(spiro.t * 2)
            }

            // Added control points: the phase held a flat 60 everywhere, so it
            // was measuring nothing (moWerk). More cubics per lobe multiply the
            // per-frame tessellation without widening the figure — the extra
            // points ride the same radius, so the silhouette barely changes.
            PathCubic {
                x: root.width / 2 + root.rootRadius * 0.95 * Math.cos(spiro.t * 3 + 2)
                y: root.height / 2 + root.rootRadius * 0.95 * Math.sin(spiro.t * 5 + 2)
                control1X: root.width / 2 + root.rootRadius * 1.15 * Math.sin(spiro.t * 5)
                control1Y: root.height / 2 - root.rootRadius * 1.15 * Math.cos(spiro.t * 3)
                control2X: root.width / 2 - root.rootRadius * 1.15 * Math.cos(spiro.t * 3)
                control2Y: root.height / 2 + root.rootRadius * 1.15 * Math.sin(spiro.t * 5)
            }

            PathCubic {
                x: root.width / 2 + root.rootRadius * 0.95 * Math.cos(spiro.t * 5 - 2)
                y: root.height / 2 - root.rootRadius * 0.95 * Math.sin(spiro.t * 3 - 2)
                control1X: root.width / 2 - root.rootRadius * 1.15 * Math.sin(spiro.t * 3)
                control1Y: root.height / 2 + root.rootRadius * 1.15 * Math.cos(spiro.t * 5)
                control2X: root.width / 2 + root.rootRadius * 1.15 * Math.cos(spiro.t * 5)
                control2Y: root.height / 2 - root.rootRadius * 1.15 * Math.sin(spiro.t * 3)
            }

            PathCubic {
                x: root.width / 2
                y: root.height / 2 - root.rootRadius
                control1X: root.width / 2 - root.rootRadius * 1.4 * Math.cos(spiro.t * 3)
                control1Y: root.height / 2 + root.rootRadius * 1.4 * Math.sin(spiro.t * 2)
                control2X: root.width / 2 + root.rootRadius * 1.4 * Math.sin(spiro.t * 2)
                control2Y: root.height / 2 - root.rootRadius * 1.4 * Math.cos(spiro.t * 3)
            }

        }

        // Four more lobes at different harmonics — same geometry pipeline,
        // several times the tessellation per frame.
        ShapePath {
            fillColor: "transparent"
            strokeColor: "#56d364"
            strokeWidth: root.maxSize * 0.014
            capStyle: ShapePath.RoundCap
            startX: root.width / 2
            startY: root.height / 2 + root.rootRadius

            PathCubic {
                x: root.width / 2 + root.rootRadius * Math.sin(spiro.t * 1.5)
                y: root.height / 2 + root.rootRadius * Math.cos(spiro.t * 2.5)
                control1X: root.width / 2 - root.rootRadius * 1.7 * Math.cos(spiro.t * 4)
                control1Y: root.height / 2 + root.rootRadius * 1.7 * Math.sin(spiro.t * 2)
                control2X: root.width / 2 + root.rootRadius * 1.7 * Math.sin(spiro.t * 2)
                control2Y: root.height / 2 - root.rootRadius * 1.7 * Math.cos(spiro.t * 4)
            }

            // Added control points: the phase held a flat 60 everywhere, so it
            // was measuring nothing (moWerk). More cubics per lobe multiply the
            // per-frame tessellation without widening the figure — the extra
            // points ride the same radius, so the silhouette barely changes.
            PathCubic {
                x: root.width / 2 + root.rootRadius * 1.1 * Math.cos(spiro.t * 2 + 1)
                y: root.height / 2 + root.rootRadius * 1.1 * Math.sin(spiro.t * 3 + 1)
                control1X: root.width / 2 + root.rootRadius * 0.9 * Math.sin(spiro.t * 3)
                control1Y: root.height / 2 - root.rootRadius * 0.9 * Math.cos(spiro.t * 2)
                control2X: root.width / 2 - root.rootRadius * 0.9 * Math.cos(spiro.t * 2)
                control2Y: root.height / 2 + root.rootRadius * 0.9 * Math.sin(spiro.t * 3)
            }

            PathCubic {
                x: root.width / 2 + root.rootRadius * 1.1 * Math.cos(spiro.t * 3 - 1)
                y: root.height / 2 - root.rootRadius * 1.1 * Math.sin(spiro.t * 2 - 1)
                control1X: root.width / 2 - root.rootRadius * 0.9 * Math.sin(spiro.t * 2)
                control1Y: root.height / 2 + root.rootRadius * 0.9 * Math.cos(spiro.t * 3)
                control2X: root.width / 2 + root.rootRadius * 0.9 * Math.cos(spiro.t * 3)
                control2Y: root.height / 2 - root.rootRadius * 0.9 * Math.sin(spiro.t * 2)
            }

            PathCubic {
                x: root.width / 2
                y: root.height / 2 + root.rootRadius
                control1X: root.width / 2 + root.rootRadius * 1.5 * Math.sin(spiro.t * 5)
                control1Y: root.height / 2 - root.rootRadius * 1.5 * Math.cos(spiro.t * 3)
                control2X: root.width / 2 - root.rootRadius * 1.5 * Math.cos(spiro.t * 3)
                control2Y: root.height / 2 + root.rootRadius * 1.5 * Math.sin(spiro.t * 5)
            }

        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: "#3fb950"
            strokeWidth: root.maxSize * 0.01
            capStyle: ShapePath.RoundCap
            startX: root.width / 2 - root.rootRadius
            startY: root.height / 2

            PathCubic {
                x: root.width / 2 + root.rootRadius * Math.cos(spiro.t * 3)
                y: root.height / 2 - root.rootRadius * Math.sin(spiro.t * 1.5)
                control1X: root.width / 2 + root.rootRadius * 1.9 * Math.sin(spiro.t)
                control1Y: root.height / 2 + root.rootRadius * 1.9 * Math.cos(spiro.t * 5)
                control2X: root.width / 2 - root.rootRadius * 1.9 * Math.cos(spiro.t * 5)
                control2Y: root.height / 2 - root.rootRadius * 1.9 * Math.sin(spiro.t)
            }

            PathCubic {
                x: root.width / 2 - root.rootRadius
                y: root.height / 2
                control1X: root.width / 2 - root.rootRadius * 1.3 * Math.sin(spiro.t * 4)
                control1Y: root.height / 2 - root.rootRadius * 1.3 * Math.cos(spiro.t * 2)
                control2X: root.width / 2 + root.rootRadius * 1.3 * Math.cos(spiro.t * 2)
                control2Y: root.height / 2 + root.rootRadius * 1.3 * Math.sin(spiro.t * 4)
            }

        }

    }

    // ── CASCADE: scale on an Item with many children forces a transform
    // recalculation for every child on every frame (RAG expensive_operations).
    Item {
        id: cascade

        anchors.fill: parent
        visible: root.activePhase === 8 && root.awake
        opacity: root.workOpacity
        transformOrigin: Item.Center

        Repeater {
            id: cascRep

            model: root.wants(8) ? 160 : 0

            delegate: Rectangle {
                readonly property real a: index / 160 * 2 * Math.PI * 5

                width: root.maxSize * 0.06
                height: width
                radius: width * 0.3
                antialiasing: true
                color: root.ramp[index % root.ramp.length]
                opacity: 0.75
                x: root.width / 2 + root.rootRadius * (0.3 + (index % 5) * 0.16) * Math.cos(a) - width / 2
                y: root.height / 2 + root.rootRadius * (0.3 + (index % 5) * 0.16) * Math.sin(a) - height / 2
                rotation: index * 9
            }

        }

        SequentialAnimation on scale {
            running: cascade.visible && root.awake
            loops: Animation.Infinite
            NumberAnimation { from: 0.55; to: 1.25; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.25; to: 0.55; duration: 800; easing.type: Easing.InOutSine }
        }

    }

    // A SECOND cascade, counter-phase and counter-rotating. One cascade held a
    // flat 60 on every watch tried (moWerk), so the phase was measuring
    // nothing: two independent transform trees double the per-frame
    // recalculation without making the picture look busier, because this one
    // turns the other way and breathes on the opposite beat.
    Item {
        id: cascadeB

        anchors.fill: parent
        visible: root.activePhase === 8 && root.awake
        opacity: root.workOpacity
        transformOrigin: Item.Center

        Repeater {
            id: cascBRep

            model: root.wants(8) ? 160 : 0

            delegate: Rectangle {
                readonly property real a: -index / 160 * 2 * Math.PI * 4

                width: root.maxSize * 0.045
                height: width
                radius: width * 0.5
                antialiasing: true
                color: root.ramp[(index + 4) % root.ramp.length]
                opacity: 0.55
                x: root.width / 2 + root.rootRadius * (0.22 + (index % 6) * 0.14) * Math.cos(a) - width / 2
                y: root.height / 2 + root.rootRadius * (0.22 + (index % 6) * 0.14) * Math.sin(a) - height / 2
                rotation: -index * 7
            }

        }

        SequentialAnimation on scale {
            running: cascadeB.visible && root.awake
            loops: Animation.Infinite
            NumberAnimation { from: 1.2; to: 0.5; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.5; to: 1.2; duration: 800; easing.type: Easing.InOutSine }
        }

        NumberAnimation on rotation {
            running: cascadeB.visible && root.awake
            from: 0
            to: -360
            duration: 9000
            loops: Animation.Infinite
        }

    }

    // ── THE CLOUD LADDER ──────────────────────────────────────────────────
    // Three renderings of one scene, separating the three things that make a
    // procedural cloud expensive. Per fragment, in lattice-hash evaluations:
    //
    //   CLOUDLITE   12   cheap fract hash, 3 octaves, NO domain warp
    //   CLOUDMID    48   same hash, 4 octaves, ONE warp (a SERIAL dependency)
    //   CLOUDHEAVY 140   sin() hash, 7 octaves, TWO warps
    //
    // So LITE vs MID isolates warp cost, and MID vs HEAVY isolates the
    // transcendental hash. LITE is the GPU baseline — what IDLE is for the
    // whole app, LITE is for the GPU alone: if it is not near 60, nothing
    // above it will be. It is also the candidate stock wallpaper, which is why
    // it carries centerColor/outerColor with FlatMesh's exact property names.
    ShaderEffect {
        id: cloudLite

        anchors.fill: parent
        visible: root.activePhase === 9 && root.awake
        opacity: root.workOpacity
        fragmentShader: "file:///usr/share/benchymark/cloud-frugal.frag.qsb"

        property real t: 0
        property color centerColor: "#58a6ff"
        property color outerColor: "#0b1b2e"

        NumberAnimation on t {
            from: 0
            to: 10000
            duration: 10000000
            loops: Animation.Infinite
            running: cloudLite.visible
        }

    }

    ShaderEffect {
        id: cloudMid

        anchors.fill: parent
        visible: root.activePhase === 10 && root.awake
        opacity: root.workOpacity
        fragmentShader: "file:///usr/share/benchymark/cloud-mid.frag.qsb"

        property real t: 0
        property color centerColor: "#58a6ff"
        property color outerColor: "#0b1b2e"

        NumberAnimation on t {
            from: 0
            to: 10000
            duration: 10000000
            loops: Animation.Infinite
            running: cloudMid.visible
        }

    }

    // ── CLOUDHEAVY: the one phase that is purely fragment-bound ───────────
    // Everything else here is CPU, geometry or draw-call work; this is the GPU
    // doing 35 noise lookups (140 sin-based hashes) per pixel per frame, so
    // it scales with PANEL
    // AREA rather than scene complexity — the phase that most needs Mpix/s
    // reported beside raw FPS. Qt6 loads the pre-compiled .qsb (inline GLSL
    // crashes it); the .frag source ships beside it so this can be rebuilt.
    ShaderEffect {
        id: shaderPhase

        anchors.fill: parent
        visible: root.activePhase === 11 && root.awake
        opacity: root.workOpacity
        fragmentShader: "file:///usr/share/benchymark/benchy-shader.frag.qsb"

        property real t: 0

        NumberAnimation on t {
            from: 0
            to: 10000
            duration: 10000000
            loops: Animation.Infinite
            running: shaderPhase.visible
        }

    }

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
    property real benchyAngle: 0
    // How many of the six strips to draw — the dial for how brutal this is.
    // Lower it if the phase is a slideshow rather than a rotation.
    property int benchyStrips: 6

    onBenchyAngleChanged: if (benchyShape.visible) root.projectBenchy()

    // BENCHYLITE (phase 8) runs the same boat decimated to 438 vertices /
    // 1545 segments; BENCHY (phase 9) is the full 1118 / 3720. Same code path,
    // so the pair measures how frame time scales with segment count.
    function projectBenchy() {
        var M = root.activePhase === 12 ? MeshLite : Mesh;
        var V = M.V, S = M.S;
        var a = root.benchyAngle * Math.PI / 180;
        var ca = Math.cos(a), sa = Math.sin(a);
        var tilt = 0.42, ct = Math.cos(tilt), st = Math.sin(tilt);
        var cx = root.width / 2, cy = root.height / 2;
        var k = root.maxSize * 0.00042;          // the +/-1000 cube to screen
        var dist = 2800;                          // perspective distance
        // pl* carry the points; bp* carry the start coordinate. A ShapePath
        // starts at startX/startY, so without setting it every strip would
        // trail a stray line back to the top-left corner.
        var lines = [pl0, pl1, pl2, pl3, pl4, pl5];
        var paths = [bp0, bp1, bp2, bp3, bp4, bp5];
        for (var s = 0; s < lines.length; s++) {
            if (s >= root.benchyStrips || s >= S.length) {
                lines[s].path = [];
                continue;
            }
            var idx = S[s], pts = [];
            for (var i = 0; i < idx.length; i++) {
                var o = idx[i] * 3;
                var x = V[o], y = V[o + 1], z = V[o + 2];
                // spin about the model's own vertical axis (Z up, print-bed
                // frame), then tilt the camera down onto it
                var rx = x * ca - y * sa;
                var ry = x * sa + y * ca;
                var depth = ry * ct - z * st;
                var up = ry * st + z * ct;
                var f = dist / (dist + depth);
                pts.push(Qt.point(cx + rx * k * f, cy - up * k * f));
            }
            lines[s].path = pts;
            if (pts.length) {
                paths[s].startX = pts[0].x;
                paths[s].startY = pts[0].y;
            }
        }
    }

    Shape {
        id: benchyShape

        anchors.fill: parent
        visible: (root.activePhase === 12 || root.activePhase === 13) && root.awake
        onVisibleChanged: if (visible) root.projectBenchy()

        ShapePath { id: bp0; fillColor: "#2258a6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#58a6ff"; strokeWidth: 1; PathPolyline { id: pl0 } }
        ShapePath { id: bp1; fillColor: "#2258a6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#58a6ff"; strokeWidth: 1; PathPolyline { id: pl1 } }
        ShapePath { id: bp2; fillColor: "#1e79c0ff"; fillRule: ShapePath.WindingFill; strokeColor: "#79c0ff"; strokeWidth: 1; PathPolyline { id: pl2 } }
        ShapePath { id: bp3; fillColor: "#1e79c0ff"; fillRule: ShapePath.WindingFill; strokeColor: "#79c0ff"; strokeWidth: 1; PathPolyline { id: pl3 } }
        ShapePath { id: bp4; fillColor: "#1aa5d6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#a5d6ff"; strokeWidth: 1; PathPolyline { id: pl4 } }
        ShapePath { id: bp5; fillColor: "#1aa5d6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#a5d6ff"; strokeWidth: 1; PathPolyline { id: pl5 } }

        NumberAnimation on rotationDriver {
            from: 0
            to: 360
            duration: root.activePhase === 12 ? 4000 : 6000
            loops: Animation.Infinite
            running: benchyShape.visible && root.awake
        }

        property real rotationDriver: 0

        onRotationDriverChanged: root.benchyAngle = rotationDriver
    }

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
    readonly property real baseGlyph: maxSize * 0.28
    readonly property real glyphPeak: 1.8

    // Both text phases drive a RING of glyphs as well as the centre one: a
    // single Text barely troubled any watch (moWerk). The ring uses the same
    // route as the centre glyph in each phase, so the SCALE:RERASTER ratio
    // still isolates the glyph-cache path — only the magnitude changed.
    Repeater {
        model: root.wants(1) || root.wants(2) ? 10 : 0

        delegate: Text {
            readonly property real a: index / 10 * 2 * Math.PI
            readonly property bool ring: root.activePhase === 1 || root.activePhase === 2

            visible: ring
            text: root.mmStr
            color: root.fg
            opacity: 0.5
            renderType: root.activePhase === 2 ? Text.NativeRendering : Text.QtRendering
            x: root.width / 2 + root.rootRadius * 0.62 * Math.cos(a) - width / 2
            y: root.height / 2 + root.rootRadius * 0.62 * Math.sin(a) - height / 2
            font.family: "Inter Tight"
            font.weight: Font.Light
            font.pixelSize: root.maxSize * 0.13

            SequentialAnimation on scale {
                running: root.activePhase === 1 && parent.visible && root.awake
                loops: Animation.Infinite
                NumberAnimation { from: 0.7; to: 2.1; duration: 800 + index * 40; easing.type: Easing.InOutSine }
                NumberAnimation { from: 2.1; to: 0.7; duration: 800 + index * 40; easing.type: Easing.InOutSine }
            }

            SequentialAnimation on font.pixelSize {
                running: root.activePhase === 2 && parent.visible && root.awake
                loops: Animation.Infinite
                NumberAnimation { from: root.maxSize * 0.09; to: root.maxSize * 0.27; duration: 800 + index * 40; easing.type: Easing.InOutSine }
                NumberAnimation { from: root.maxSize * 0.27; to: root.maxSize * 0.09; duration: 800 + index * 40; easing.type: Easing.InOutSine }
            }

        }

    }

    Text {
        id: centreText

        readonly property bool scaling: root.activePhase === 1
        readonly property bool rerastering: root.activePhase === 2

        text: root.countdown > 0 ? root.countdown : root.mmStr
        visible: !root.done
        color: root.countdown > 0 ? root.hot : root.fg
        anchors.centerIn: parent
        renderType: rerastering ? Text.NativeRendering : Text.QtRendering
        font.family: "Inter Tight"
        // Light, not Black: moWerk wants this beautiful first and expensive
        // second — Nutty Null's thin elegance survives the benchmark.
        font.weight: Font.Light
        font.letterSpacing: -root.maxSize * 0.02
        font.pixelSize: root.baseGlyph

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

    property real rotorAngle: 0

    NumberAnimation on rotorAngle {
        from: 0
        to: 360
        duration: root.activePhase === 3 ? 2200 : 6000     // ORBIT sweeps faster
        loops: Animation.Infinite
        running: !displayAmbient
    }

    Item {
        id: rotor

        anchors.fill: parent
        // Nothing to report during the countdown, and a 0 sitting on the rim
        // reads as a measurement rather than as an absence. It arrives when
        // IDLE does.
        opacity: root.running || root.done ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }

        Repeater {
            model: root.trailCount + 1

            delegate: Text {
                readonly property bool head: index === 0
                // Trailing numerals lag the head; the gap widens down the tail.
                readonly property real ang: (root.rotorAngle - index * 13 - 90) * Math.PI / 180
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
            }

        }

    }

    // ORBIT's cost: a pulsing shadow recomputed every frame over the rotor.
    MultiEffect {
        source: rotor
        anchors.fill: rotor
        visible: root.activePhase === 3
        opacity: root.workOpacity
        shadowEnabled: true
        shadowColor: "#e0f0c30e"
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0

        blurEnabled: true
        blurMax: 72          // a heavier halo: the glow IS the phase

        SequentialAnimation on shadowBlur {
            running: root.activePhase === 3 && root.awake
            loops: Animation.Infinite
            NumberAnimation { from: 0.5; to: 1; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0.5; duration: 500; easing.type: Easing.InOutSine }
        }

        // A pulsing blur on top of the shadow: the effect is recomputed over
        // the whole rotor every frame, which is the point of this phase.
        SequentialAnimation on blur {
            running: root.activePhase === 3 && root.awake
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 0.6; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.6; to: 0; duration: 500; easing.type: Easing.InOutSine }
        }

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

        Column {
            anchors.centerIn: parent
            spacing: root.maxSize * 0.045

            Text {
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
                width: root.maxSize * 0.62
                height: root.maxSize * 0.155
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
                    font.pixelSize: root.maxSize * 0.058
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
                width: root.maxSize * 0.62
                height: root.maxSize * 0.155
                radius: height / 2
                color: root.gold
                opacity: 0.92

                Text {
                    anchors.centerIn: parent
                    text: "phase control"
                    color: "#101418"
                    font.family: "Inter Tight"
                    font.weight: Font.DemiBold
                    font.pixelSize: root.maxSize * 0.055
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

        Text {
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
            text: root.countdown > 0 ? "GET TO THE RIG"
                                     : (root.done ? "BENCH COMPLETE" : root.phaseName)
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
