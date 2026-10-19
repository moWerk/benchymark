// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// The whole app: tick the stages, run them once or in a loop, show the
// results. One page, three states (the author's design).
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.KeepAlive 1.2
import Nemo.Configuration 1.0
import Benchymark 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: page
    allowedOrientations: Orientation.Portrait

    // Stamped into every result. Different loads on a different renderer
    // than the watch's scene 0.6, so the numbers are not comparable.
    // sfos-2.0: a fixed render size and calibrated loads with a score
    // (resolution point by Mister Magister, 2026-10-18), not comparable to 1.x
    // sfos-2.2: every stage on one fixed 720 x 1600 canvas, laid out and
    // drawn at that size on every device and scaled to fit, so blurs, glyphs
    // and sizes do the same work everywhere (Michał, 2026-10-19; night audit:
    // the screen's shape still changed five stages); the score from all
    // frames over all measured time; scores capped near the refresh or past
    // the mark found again in the run
    readonly property string sceneVersion: "sfos-2.2"
    readonly property int stageSeconds: 10    // a timed stage, measured
    // A graphics stage is measured at two loads, its calibrated step and the
    // next, this many seconds each: the score is the extra work over the
    // extra frame time, so the fixed cost every frame carries (compositing,
    // the scaling to the panel, vsync) drops out. Measured at one load, the
    // score rose 20-60 % per step on the XA2 and the tablet, so it depended
    // on where a device's calibration landed (night audit, 2026-10-19).
    // The two loads take turns, A B A B, three seconds each: measured one
    // after the other, the first ran while the CPU clock was still rising
    // and a slope came out 40 % high (XA2 Cascade, night audit).
    readonly property int pointSeconds: 3
    readonly property int pointWindows: 4
    // After a load change the frame rate can climb for seconds while the
    // clocks follow (C2 Overdraw: 9.2, 12.1, 12.5 fps): seconds are dropped
    // until two in a row agree within 5 %, three at most, the first always.
    readonly property int settleMax: 3
    readonly property real settleTolerance: 0.05
    readonly property int gapSeconds: 2      // between stages

    // Every stage draws on the C2's 720 x 1600 and is scaled to fit the
    // panel, with black bars on other shapes: a phone with more pixels or
    // another shape gets exactly the same work (mo, 2026-10-18; the shape
    // since the night audit, 2026-10-19).
    readonly property int renderWidth: 720
    readonly property int renderHeight: 1600
    readonly property real renderPixels: renderWidth * renderHeight

    // A stage with a `ladder` of loads finds its step on the first run: from
    // the lightest up, one second to settle and one to measure each, to the
    // first step under rampFps. The step is kept per scene, so later runs
    // measure the same 10 seconds right away (mo, 2026-10-18). The score is
    // fps x load, so it compares whatever step a device chose. Under 25 fps:
    // near 40 the fixed cost of a frame ate a fifth of the score (XA2,
    // Overdraw: 1393 layers/s at 36 layers, 1670 at 72, 1728 at 144).
    readonly property int rampFps: 25
    // A stage measured over this runs too light: its fixed cost per frame and
    // the refresh bend the score (XA2 Overdraw read 20 % low at 39 fps), so
    // its step is found again at once. Never above 80 % of the refresh.
    readonly property real refreshHz: FrameCounter.refreshRate > 0 ? FrameCounter.refreshRate : 60
    readonly property real tooLightFps: Math.min(1.3 * rampFps, 0.8 * refreshHz)
    ConfigurationValue {
        id: calibConfig
        key: "/apps/harbour-benchymark/calibration"
        defaultValue: "{}"
    }
    function calibration() {
        try { var c = JSON.parse(calibConfig.value); return c[sceneVersion] || {} } catch (e) { return {} }
    }
    function savedStep(key) {
        var s = calibration()[key]
        return s === undefined ? -1 : s
    }
    // stages of one calibration group keep one step under the group's name
    function calibKey(item, key) {
        return item && item.calibrationGroup !== undefined ? item.calibrationGroup : key
    }
    readonly property var groupOf: ({ "BUFFER-UBO": "BUFFER", "BUFFER-SSBO": "BUFFER", "BUFFER-TEXTURE": "BUFFER" })
    // a step of -1 forgets the stage, its next run calibrates it again
    function saveStep(key, step) {
        var all = {}
        try { all = JSON.parse(calibConfig.value) } catch (e) { }
        var c = all[sceneVersion] || {}
        if (step < 0) delete c[key]
        else c[key] = step
        all[sceneVersion] = c
        calibConfig.value = JSON.stringify(all)
    }
    // the stages with a ladder, for the start page's hint
    readonly property var calibratingKeys: ["BENCHY-LIGHT", "BENCHY-HEAVY", "BENCHY-GLOW",
        "SHADER-LIGHT", "SHADER-HEAVY", "BUFFER-UBO", "BUFFER-SSBO", "BUFFER-TEXTURE",
        "OVERDRAW", "CASCADE", "ICONS"]
    // Set, not bound: as a binding it was evaluated again and again while
    // the page stack built the page, 18 binding loop warnings per start.
    property bool needsCalibration: false
    function updateNeedsCalibration() {
        var c = calibration()
        needsCalibration = stages.some(function (st) {
            return isOn(st.key) && calibratingKeys.indexOf(st.key) >= 0
                   && c[groupOf[st.key] || st.key] === undefined })
    }
    Connections {
        target: calibConfig
        onValueChanged: page.updateNeedsCalibration()
    }
    onSkippedChanged: updateNeedsCalibration()
    property var recalibrateNext: []   // keys whose step ran too light in this run
    property var recalibrateHeavy: []  // and too heavy
    property bool ramping: false
    property int rampStep: 0
    // A step counts only after two seconds under the mark in a row: the
    // first stage's first second fell under it while the run was starting,
    // and a Pad 6 kept the lightest step (Michał, 2026-10-19).
    property bool rampConfirm: false
    property bool reramped: false    // this stage found its step again already
    property var calibratedNow: []   // keys calibrated in this run

    // In the order that reads best: the bright graphics first, text last,
    // then the system stages, storage at the very end (mo, 2026-10-17).
    // `about` is the one-sentence manual shown under the name on a tap.
    // sfos-2.0: a graphics stage draws as much as this device needs to fall
    // under 25 fps, found on its first run, and scores the work per second.
    readonly property var stages: [
        //% "Benchy large"
        { name: qsTrId("id-stage-benchy-light"), key: "BENCHY-LIGHT", file: "BenchyLow",
          //% "Two large 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. A large boat has twice the lines' length of a small one to draw, so fewer of them fit in a second. Scores boats per second."
          about: qsTrId("id-about-benchy-light"),
          //% "Boats drawn per second, two large ones on screen"
          score: qsTrId("id-score-benchy-light") },
        //% "Benchy small"
        { name: qsTrId("id-stage-benchy-heavy"), key: "BENCHY-HEAVY", file: "BenchyHigh",
          //% "Six small boats, each drawn many times: the same work per boat on the CPU, half the lines' length for the GPU. Scores boats per second."
          about: qsTrId("id-about-benchy-heavy"),
          //% "Boats drawn per second, six small ones on screen"
          score: qsTrId("id-score-benchy-heavy") },
        //% "Benchy glow"
        { name: qsTrId("id-stage-glow"), key: "BENCHY-GLOW", file: "Glow",
          //% "A Benchy with a pulsing golden halo, the glow stacked several times: a blur over the whole picture each, the cost of soft effects. Scores megapixels per second."
          about: qsTrId("id-about-glow"),
          //% "Megapixels blurred per second"
          score: qsTrId("id-score-glow") },
        //% "Shader light"
        { name: qsTrId("id-stage-shader-light"), key: "SHADER-LIGHT", file: "ShaderLow",
          //% "A drifting noise field computed for every pixel, several times over: GPU arithmetic. Scores megapixels per second."
          about: qsTrId("id-about-shader-light"),
          //% "Megapixels of noise field per second"
          score: qsTrId("id-score-shader-light") },
        //% "Shader heavy"
        { name: qsTrId("id-stage-shader-heavy"), key: "SHADER-HEAVY", file: "ShaderHigh",
          //% "The same idea warped twice over, about thirty noise lookups per pixel and field: the heaviest GPU arithmetic here. Scores megapixels per second."
          about: qsTrId("id-about-shader-heavy"),
          //% "Megapixels of warped field per second"
          score: qsTrId("id-score-shader-heavy") },
        // the same table walk from three kinds of GPU memory (kan_ibal, forum)
        //% "Table from UBO"
        { name: qsTrId("id-stage-buffer-ubo"), key: "BUFFER-UBO", file: "BufferUbo",
          //% "Every pixel walks a 16 KB table, each index taken from the entry before, here from a uniform buffer (UBO). Scores million table reads per second. Needs OpenGL ES 3.0."
          about: qsTrId("id-about-buffer-ubo"),
          //% "Million table reads per second from a uniform buffer"
          score: qsTrId("id-score-buffer-ubo") },
        //% "Table from SSBO"
        { name: qsTrId("id-stage-buffer-ssbo"), key: "BUFFER-SSBO", file: "BufferSsbo",
          //% "The same table walk from a shader storage buffer (SSBO). Needs OpenGL ES 3.1 and a driver that allows them in fragment shaders."
          about: qsTrId("id-about-buffer-ssbo"),
          //% "Million table reads per second from a storage buffer"
          score: qsTrId("id-score-buffer-ssbo") },
        //% "Table from texture"
        { name: qsTrId("id-stage-buffer-texture"), key: "BUFFER-TEXTURE", file: "BufferTexture",
          //% "The same table walk from a float texture, the classic way and the baseline for the two buffers. Needs OpenGL ES 3.0."
          about: qsTrId("id-about-buffer-texture"),
          //% "Million table reads per second from a texture"
          score: qsTrId("id-score-buffer-texture") },
        //% "Overdraw"
        { name: qsTrId("id-stage-overdraw"), key: "OVERDRAW", file: "Overdraw",
          //% "Large translucent squares stacked and turning: every pixel is blended many times, raw fill rate. Scores layers per second."
          about: qsTrId("id-about-overdraw"),
          //% "Translucent layers blended per second"
          score: qsTrId("id-score-overdraw") },
        //% "Cascade"
        { name: qsTrId("id-stage-cascade"), key: "CASCADE", file: "Cascade",
          //% "Thousands of rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents. Scores squares per second."
          about: qsTrId("id-about-cascade"),
          //% "Squares moved per second"
          score: qsTrId("id-score-cascade") },
        //% "Icon storm"
        { name: qsTrId("id-stage-icons"), key: "ICONS", file: "Icons",
          //% "Rockets and flashes on spiral arms, stacked: many small images moving every frame. Scores icons per second."
          about: qsTrId("id-about-icons"),
          //% "Icons drawn per second"
          score: qsTrId("id-score-icons") },
        //% "CPU prime"
        { name: qsTrId("id-stage-cpu"), key: "CPU-PRIME", file: "CpuPrime",
          //% "All cores count primes as sysbench does; every finished count lights a cell of an Ulam spiral if its number is prime."
          about: qsTrId("id-about-cpu"),
          //% "Prime counts per second on all cores"
          score: qsTrId("id-score-cpu") },
        //% "CPU single core"
        { name: qsTrId("id-stage-cpu-single"), key: "CPU-SINGLE", file: "CpuPrimeSingle",
          //% "The same prime counting on one core only: next to the all core figure it shows what a single core does."
          about: qsTrId("id-about-cpu-single"),
          //% "Prime counts per second on one core"
          score: qsTrId("id-score-cpu-single") },
        //% "Memory throughput"
        { name: qsTrId("id-stage-memory"), key: "MEMORY", file: "Memory",
          //% "Copies memory between two 32 MB buffers as fast as it can: how quickly the phone moves data in RAM."
          about: qsTrId("id-about-memory"),
          //% "Megabytes copied per second"
          score: qsTrId("id-score-memory") },
        //% "One million"
        { name: qsTrId("id-stage-million"), key: "ONE-MILLION", file: "OneMillion",
          //% "JavaScript counts to one million, over and over: how fast the app's script engine runs a plain loop."
          about: qsTrId("id-about-million"),
          //% "Million loop steps per second in JavaScript"
          score: qsTrId("id-score-million") },
        // last: off at first, an unticked switch among ticked ones looked odd
        //% "Storage performance"
        { name: qsTrId("id-stage-storage"), key: "STORAGE", file: "Storage",
          //% "Writes 256 MB in small blocks past the cache and reads it back. Off by default: it wears the flash a little every run."
          about: qsTrId("id-about-storage"),
          //% "Megabytes read and written per second"
          score: qsTrId("id-score-storage") }
    ]

    // The stages left out, by key, so new stages start ticked. Storage is
    // left out at first: it writes 256 MB to the flash every run.
    ConfigurationValue {
        id: skippedConfig
        key: "/apps/harbour-benchymark/skipped"
        defaultValue: "[\"STORAGE\"]"
    }
    property var skipped: {
        try { return JSON.parse(skippedConfig.value) } catch (e) { return [] }
    }
    function isOn(key) { return skipped.indexOf(key) < 0 }
    function setOn(key, on) {
        var s = skipped.filter(function (k) { return k !== key })
        if (!on) s.push(key)
        skippedConfig.value = JSON.stringify(s)
    }
    ConfigurationValue {
        id: loopConfig
        key: "/apps/harbour-benchymark/loop"
        defaultValue: false
    }
    // once, hour or loop (mo, 2026-10-18); the old loop switch carries over
    ConfigurationValue {
        id: modeConfig
        key: "/apps/harbour-benchymark/mode"
        defaultValue: ""
    }
    readonly property var modes: ["once", "hour", "loop"]
    readonly property string mode: modes.indexOf(modeConfig.value) >= 0 ? modeConfig.value
            : (loopConfig.value === true || loopConfig.value === "true") ? "loop" : "once"
    readonly property bool loop: mode !== "once"
    readonly property int hourSeconds: 3600

    // the start page's hints, switchable in the settings (mo, 2026-10-18)
    ConfigurationValue {
        id: showHints
        key: "/apps/harbour-benchymark/showHints"
        defaultValue: true
    }
    // Settings and the saved runs, as tabs; a saved run opens on top
    function openSettings(tab) {
        return pageStack.push(Qt.resolvedUrl("SettingsPage.qml"),
                       { details: resultsPane.view.detailList(), stageInfo: stageInfo,
                         currentStarted: currentRun && currentRun.started ? currentRun.started : "",
                         startTab: tab === 1 ? 1 : 0 })
    }
    Timer {
        interval: 1500
        running: typeof selftestPage !== "undefined" && selftestPage !== ""
        onTriggered: {
            if (selftestPage === "settings") page.openSettings(0)
            else if (selftestPage === "runs") page.openSettings(1)
            else if (selftestPage === "compare") {
                var names = log.runs()
                if (names.length < 2) return
                pageStack.push(Qt.resolvedUrl("ComparePage.qml"),
                               { runA: JSON.parse(log.readRun(names[1])), runB: JSON.parse(log.readRun(names[0])),
                                 stageInfo: page.stageInfo })
            }
        }
    }

    // key -> { name, score }, for the results' rows and what each counts
    readonly property var stageInfo: {
        var m = {}
        for (var i = 0; i < stages.length; i++)
            m[stages[i].key] = { name: stages[i].name, score: stages[i].score }
        return m
    }

    property string view: "select"   // select, run, results
    property int openAbout: -1        // the stage whose sentence is open

    // ── run state ──
    property var plan: []         // stage indices to run, in order
    property int step: -1         // position in plan
    readonly property int current: step >= 0 && step < plan.length ? plan[step] : -1
    property bool inGap: false
    property int elapsed: 0       // measured seconds in this stage
    property bool warm: false     // the first second after a load is discarded
    property bool settled: false  // and the next ones until the rate holds
    property real settlePrev: 0   // the last dropped second's fps
    property int settleSeconds: 0 // seconds dropped in this window
    property int lastFps: 0
    property int loops: 0
    property var samples: []      // this stage: { frames, ms, worst } per second
    property double frameSum: 0   // this stage's measured frames
    property double msSum: 0      // and the time they took
    property var rampLog: []      // this stage's ramp: [step, fps] per second
    property int measurePhase: 0  // the window: even the first load, odd the second
    property var pointA: null     // the first load's windows so far
    property var pointB: null     // the second load's
    property var windows: []      // every window: { load, frames, ms }, in turn
    property var passes: []       // every finished stage of the run, per pass
    property int interruptions: 0 // stages restarted after the app was in the background
    property int savedAt: 0       // seconds into the run of the last save on the way
    property var results: ({})    // key -> row
    property var order: []        // keys in the order they finished
    property double runStarted: 0
    property double runEnded: 0    // with runStarted the exact runtime, for drain per hour
    property double sampledAt: 0   // when the frame count was last taken

    DisplayBlanking { preventBlanking: page.view === "run" }

    // The temperature over the run, once a second, pauses included: with Run
    // in loop it is the thermal test (asked for on the forum, 2026-10-17).
    // The battery alongside, for the drain test (asked for on the forum,
    // 2026-10-18), and the brightness at the start, which drives the drain.
    property var temps: []        // [seconds since start, degrees C]
    property var batts: []        // [seconds since start, percent, watts, status]
    property var clocks: []       // [seconds since start, cpu %, gpu % or null, throttled]
    property int brightnessAtStart: -1   // percent of the maximum
    property bool brightnessSet: false   // the run set it (Run one hour)
    DisplaySettings {
        id: displaySettings
        // a run that was killed before it could put the display back
        onPopulatedChanged: page.restoreDisplay()
    }

    // Run one hour runs the display at 50 % with automatic brightness off,
    // so drains compare (mo, 2026-10-18). The user's values are kept in the
    // settings until they are back, so a killed run restores them at the
    // next start.
    readonly property int hourBrightness: 50
    ConfigurationValue {
        id: savedDisplay
        key: "/apps/harbour-benchymark/savedDisplay"
        defaultValue: ""
    }
    function setDisplayForHour() {
        if (!displaySettings.populated || displaySettings.maximumBrightness <= 0) return false
        if (savedDisplay.value === "")
            savedDisplay.value = JSON.stringify({
                brightness: displaySettings.brightness,
                auto: displaySettings.autoBrightnessEnabled,
                als: displaySettings.ambientLightSensorEnabled })
        displaySettings.autoBrightnessEnabled = false
        displaySettings.ambientLightSensorEnabled = false
        displaySettings.brightness = Math.max(1, Math.round(displaySettings.maximumBrightness * hourBrightness / 100))
        return true
    }
    function restoreDisplay() {
        if (savedDisplay.value === "" || !displaySettings.populated) return
        try {
            var d = JSON.parse(savedDisplay.value)
            displaySettings.ambientLightSensorEnabled = d.als
            displaySettings.autoBrightnessEnabled = d.auto
            displaySettings.brightness = d.brightness
        } catch (e) {
            console.warn("Benchymark: saved display settings unreadable: " + e)
        }
        savedDisplay.value = ""
    }
    // Closed mid-run (from the cover, or the system ending the app): the run
    // so far is saved, as a tap would (night audit: a long run was lost)
    Component.onDestruction: {
        if (view === "run") stop()
        restoreDisplay()
    }
    Timer {
        interval: 1000
        repeat: true
        running: page.view === "run"
        onTriggered: {
            var s = Math.round((Date.now() - page.runStarted) / 1000)
            // a long run is saved every five minutes on the way, so a dead
            // battery or a killed app keeps it up to there
            if (page.mode !== "once" && s - page.savedAt >= 300) { page.savedAt = s; page.writeLog(true) }
            var c = log.temperature()
            if (!isNaN(c)) {
                var t = page.temps
                t.push([s, Math.round(c * 10) / 10])
                page.temps = t
            }
            var b = log.battery()
            if (b.capacity !== undefined) {
                var bs = page.batts
                bs.push([s, b.capacity, b.watts !== undefined ? Math.round(b.watts * 100) / 100 : null, b.status])
                page.batts = bs
            }
            var th = log.throttle()
            if (th.cpu !== undefined) {
                var cl = page.clocks
                cl.push([s, th.cpu, th.gpu !== undefined ? th.gpu : null,
                         (th.cooling || 0) > 0 || th.capped === true])
                page.clocks = cl
            }
        }
    }

    // Run one hour: ends at exactly 1:00:00, wherever the sequence is
    Timer {
        id: hourTimer
        interval: page.hourSeconds * 1000
        onTriggered: page.stop(true)
    }

    function start() {
        var p = []
        for (var i = 0; i < stages.length; i++)
            if (isOn(stages[i].key)) p.push(i)
        if (p.length === 0) return
        resetRun(p)
    }
    // one place for a run's start, the test hook's too
    function resetRun(p) {
        plan = p
        temps = []
        batts = []
        clocks = []
        calibratedNow = []
        recalibrateNext = []
        recalibrateHeavy = []
        passes = []
        interruptions = 0
        savedAt = 0
        log.resetRun()
        brightnessSet = mode === "hour" && setDisplayForHour()
        brightnessAtStart = brightnessSet ? hourBrightness
                : displaySettings.maximumBrightness > 0
                ? Math.round(displaySettings.brightness * 100 / displaySettings.maximumBrightness) : -1
        results = ({})
        order = []
        loops = 0
        view = "run"
        runStarted = Date.now()
        if (mode === "hour") hourTimer.restart()
        beginStep(0)
    }

    // The free area for a stage, between the stage name above and "Tap to
    // stop" below, with a margin to both.
    // From the font sizes, not the labels: at load time the labels can
    // still be empty, and the area came out too high (storage clipped).
    readonly property real areaTop: Theme.paddingLarge * 2 + Theme.fontSizeLarge * 1.3
                                    + Theme.fontSizeMedium * 1.3 + Theme.paddingLarge * 2
    readonly property real areaBottom: tapLabel.y - Theme.paddingLarge * 2

    function beginStep(s) {
        step = s
        inGap = false
        elapsed = 0
        warm = false
        samples = []
        frameSum = 0
        msSum = 0
        rampLog = []
        measurePhase = 0
        stageMeasured = 0
        pointA = null
        pointB = null
        windows = []
        lastFps = 0
        ramping = false
        rampConfirm = false
        reramped = false
        // in the background nothing is drawn: the stage loads when the app
        // is back (onActiveChanged below)
        if (!Qt.application.active) { stageLoader.source = ""; return }
        stageLoader.setSource(Qt.resolvedUrl("../stages/" + stages[current].file + ".qml"),
                              { areaTop: Math.max(0, (areaTop - stageLoader.y) / stageScale),
                                areaBottom: Math.min(renderHeight, (areaBottom - stageLoader.y) / stageScale),
                                renderWidth: renderWidth, renderHeight: renderHeight })
        var item = stageLoader.item
        if (item && item.ladder !== undefined) {
            var saved = savedStep(calibKey(item, stages[current].key))
            rampStep = saved >= 0 ? Math.min(saved, item.ladder.length - 1) : 0
            ramping = saved < 0
            item.load = item.ladder[rampStep]
        }
        openWindow()
    }
    // A new measuring window from now, its first second discarded: after a
    // stage is built, after a load change and after a pause, so the build
    // time and the gap never count as frames or seconds (night audit).
    function openWindow() {
        FrameCounter.reset()
        sampledAt = Date.now()
        warm = false
        settled = false
        settlePrev = 0
        settleSeconds = 0
        fpsTimer.restart()
    }
    // The app went to the background mid-stage (cover, a call, the lock
    // screen): the stage stops, its threads too, and starts over when the
    // app is back; the run notes it.
    Connections {
        target: Qt.application
        onActiveChanged: {
            if (page.view !== "run" || page.inGap || page.step < 0) return
            if (!Qt.application.active) {
                if (stageLoader.source != "") {
                    page.interruptions++
                    stageLoader.source = ""
                }
            } else {
                page.beginStep(page.step)
            }
        }
    }

    function record(key, row) {
        var r = results
        r[key] = row
        results = r
        // every pass of a loop or an hour, not only the last (night audit)
        var ps = passes
        ps.push({ pass: loops, phase: key, t: Math.round((Date.now() - runStarted) / 1000),
                  score: row.score !== undefined ? Math.round(row.score * 10) / 10 : undefined,
                  value: row.value, avg: row.avg, load: row.load, partial: row.partial })
        passes = ps
        if (order.indexOf(key) < 0) {
            var o = order
            o.push(key)
            order = o
        }
    }

    function finishStage() {
        var item = stageLoader.item
        // nothing loaded: already recorded (stop() after a last stage)
        if (!item) return
        // the GPU or driver cannot run it: a dash, and why, not the idle fps
        if (item.unsupported !== undefined && item.unsupported !== "") {
            record(stages[current].key, { name: stages[current].name, system: false,
                                          unsupported: item.unsupported })
            return
        }
        if (item.system) {
            var rows = item.results()   // [{ key, name, value, unit }]
            for (var j = 0; j < rows.length; j++)
                if (rows[j].unsupported)
                    record(rows[j].key, { name: rows[j].name, system: false, unsupported: rows[j].unsupported })
                else
                    record(rows[j].key, { name: rows[j].name, system: true, value: rows[j].value,
                                          unit: rows[j].unit, threads: rows[j].threads, detail: rows[j].detail })
            return
        }
        // the first load's window, and the second's if it was reached
        // the window running at the stop counts too
        bankWindow(item)
        var a = pointA
        var b = pointB
        if (a === null) return
        if (a.samples.length === 0 || a.ms <= 0 || a.frames <= 0) return
        var fpsOf = function (w) { return w.frames * 1000 / w.ms }
        var listOf = function (w) {
            return w.samples.map(function (x) { return x.ms > 0 ? Math.round(x.frames * 10000 / x.ms) / 10 : 0 })
        }
        var avg = fpsOf(a)
        var min = 1e9, worst = 0
        for (var i = 0; i < a.samples.length; i++) {
            min = Math.min(min, a.samples[i].ms > 0 ? a.samples[i].frames * 1000 / a.samples[i].ms : 0)
            worst = Math.max(worst, a.samples[i].worst)
        }
        var st = stages[current]
        var row = { name: st.name, system: false, avg: Math.round(avg * 10) / 10,
                    min: Math.round(min * 10) / 10, worst: Math.round(worst), seconds: a.samples.length,
                    fps: listOf(a), partial: a.samples.length < pointSeconds * pointWindows / 2 }
        if (item.ladder !== undefined) {
            // per pixel work counts in millions of rendered pixels
            var k = item.perPixel ? renderPixels / 1e6 : 1
            row.load = a.load
            row.step = item.ladder.indexOf(a.load)
            row.steps = item.ladder.length
            row.unit = item.unit
            row.scoreSingle = avg * a.load * k
            row.score = row.scoreSingle
            row.ramp = rampLog
            row.reramped = reramped
            // The second load: the work it adds over the frame time it adds.
            // Kept only when both loads are clear of the refresh and the
            // frame time grew with the work; else the one-load score, marked.
            var ta = a.ms / a.frames
            // the seconds each window dropped before the rate held
            row.settle = windows.map(function (w) { return w.settle })
            if (b !== null && b.frames > 0 && b.samples.length >= 3) {
                var tb = b.ms / b.frames
                var fb = fpsOf(b)
                row.load2 = b.load
                row.fps2 = listOf(b)
                row.msPerFrame = Math.round(ta * 100) / 100
                row.msPerFrame2 = Math.round(tb * 100) / 100
                var dl = b.load - a.load, dt = tb - ta
                var clear = avg < 0.9 * refreshHz && fb < 0.9 * refreshHz
                if (clear && dl !== 0 && dt / dl > 0) {
                    row.score = dl * k / (dt / 1000)
                    // what every frame costs besides the work: compositing,
                    // the scaling to the panel, vsync
                    row.overheadMs = Math.round((ta - a.load * dt / dl) * 10) / 10
                    // Overhead below zero: the frame time grew faster than the
                    // work (caches overflowing: the C2's Text scale at -32 ms,
                    // a stage since dropped), so the
                    // slope prices the load wrong; the one-load score, marked.
                    // A little below zero is noise: past a tenth of the frame.
                    if (row.overheadMs < -0.1 * ta) {
                        row.score = row.scoreSingle
                        row.superlinear = true
                    }
                    // The two A-B pairs give two scores of their own; how far
                    // they lie apart is the score's own uncertainty, marked
                    // past 10 % (night audit: CPU-bound stages on the XA2)
                    var pair = function (w1, w2) {
                        var d = w2.ms / w2.frames - w1.ms / w1.frames
                        return w1.frames > 0 && w2.frames > 0 && d / (w2.load - w1.load) > 0
                               ? (w2.load - w1.load) * k / (d / 1000) : NaN
                    }
                    if (windows.length >= 4) {
                        var s1 = pair(windows[0], windows[1]), s2 = pair(windows[2], windows[3])
                        row.spreadPct = isFinite(s1) && isFinite(s2)
                                ? Math.round(Math.abs(s1 - s2) / (s1 + s2) * 1000) / 10 : undefined
                        row.noisy = row.spreadPct === undefined || row.spreadPct > 10
                    }
                } else {
                    row.slopeFailed = true
                }
                if (b.samples.length < pointSeconds * pointWindows / 2) row.partial = true
            } else {
                row.slopeFailed = row.steps > 1
                row.partial = row.steps > 1 || row.partial
            }
            // the heaviest load and still fast: the score is a lower bound
            row.topped = row.step === item.ladder.length - 1 && avg > rampFps
            // near the panel's refresh the frame rate cannot rise: capped
            row.capped = avg >= 0.9 * refreshHz
            // Still too light after the run's own new ramp, or far too heavy
            // (calibrated cold, now hot): the next run finds the step again.
            // A short row (stopped) says too little to judge.
            // Too heavy: under a third of the mark, out of the band a ramp
            // lands in (12.5-25 fps). Not for a group: its slower members run
            // under the mark by design.
            var tooLight = avg > tooLightFps && row.step < item.ladder.length - 1
            var tooHeavy = avg < rampFps / 3 && row.step > 0 && item.calibrationGroup === undefined
            if (a.samples.length >= 3 && (tooLight || tooHeavy) && !(typeof selftestFixed !== "undefined" && selftestFixed)) {
                saveStep(calibKey(item, st.key), -1)
                if (tooLight) {
                    var rn = recalibrateNext
                    if (rn.indexOf(st.key) < 0) rn.push(st.key)
                    recalibrateNext = rn
                } else {
                    var rh = recalibrateHeavy
                    if (rh.indexOf(st.key) < 0) rh.push(st.key)
                    recalibrateHeavy = rh
                }
            }
        }
        record(st.key, row)
    }

    // atHour: the hour ran out mid-stage; a stage that has a full result
    // from an earlier round keeps it rather than the cut one
    function stop(atHour) {
        if (view !== "run") return
        hourTimer.stop()
        // a stage cut short keeps the full row of an earlier pass, if any
        var cut = current >= 0 && results[stages[current].key] !== undefined
        if (!inGap && !cut) finishStage()
        if (brightnessSet) restoreDisplay()
        stageLoader.source = ""
        step = -1
        inGap = false
        gapTimer.stop()
        gapEndTimer.stop()
        runEnded = Date.now()
        view = "results"
        writeLog()
        if (typeof selftestShare !== "undefined" && selftestShare) resultsPane.shareImage(true)
    }

    function next() {
        finishStage()
        stageLoader.source = ""
        if (step + 1 < plan.length || loop) {
            if (step + 1 >= plan.length) loops++
            inGap = true
            gapTimer.restart()
            gapEndTimer.restart()
            gapProgress.restart()
        } else {
            stop()
        }
    }

    readonly property int nextStage: plan.length > 0 ? plan[(step + 1) % plan.length] : 0

    Timer {
        id: gapTimer
        interval: page.gapSeconds * 1000
        onTriggered: { page.gapEnding = false; page.beginStep((page.step + 1) % page.plan.length) }
    }

    // once a second: the frames presented, the exact time, the longest frame
    Timer {
        id: fpsTimer
        interval: 1000
        repeat: true
        running: page.view === "run" && !page.inGap && Qt.application.active
        onTriggered: {
            // The timer runs on the GUI thread, which a heavy stage delays, so
            // a "second" can be longer: the counter measures the exact time
            // that passed (the watch version's v0.6 fix, now monotonic).
            var smp = FrameCounter.sample()
            page.sampledAt = Date.now()
            // a stage that fails to load would stall the run
            if (stageLoader.status === Loader.Error) {
                page.record(page.stages[page.current].key, { name: page.stages[page.current].name,
                            //% "could not be loaded"
                            system: false, unsupported: qsTrId("id-stage-load-error") })
                page.next()
                return
            }
            if (stageLoader.status !== Loader.Ready) return
            var fps = smp.ms > 0 ? smp.frames * 1000 / smp.ms : 0
            if (!page.warm) { page.warm = true; page.settlePrev = fps; page.settleSeconds = 1; return }
            page.lastFps = Math.round(fps)
            var item = stageLoader.item
            if (page.ramping) {
                var rl = page.rampLog
                rl.push([page.rampStep, Math.round(fps * 10) / 10])
                page.rampLog = rl
                var top = page.rampStep >= item.ladder.length - 1
                var key = page.calibKey(item, page.stages[page.current].key)
                if (fps < page.rampFps && !page.rampConfirm && !top) {
                    // under the mark once: the same step is measured again
                    page.rampConfirm = true
                    return
                } else if (fps < page.rampFps || top) {
                    // under the mark twice, or the heaviest: keep it, then
                    // measure. A group keeps the heaviest step any member
                    // needed, so it suits its fastest member and none runs
                    // too light (night audit: it was whichever ran first).
                    page.ramping = false
                    page.rampConfirm = false
                    page.saveStep(key, item.calibrationGroup !== undefined
                                  ? Math.max(page.savedStep(key), page.rampStep) : page.rampStep)
                    var cn = page.calibratedNow
                    if (cn.indexOf(page.stages[page.current].key) < 0) cn.push(page.stages[page.current].key)
                    page.calibratedNow = cn
                } else {
                    page.rampConfirm = false
                    page.rampStep++
                    item.load = item.ladder[page.rampStep]
                }
                page.openWindow()   // the next second settles
                return
            }
            if (item.ladder !== undefined && !page.settled) {
                var holds = page.settlePrev > 0
                        && Math.abs(fps - page.settlePrev) <= page.settleTolerance * page.settlePrev
                if (!holds && page.settleSeconds < page.settleMax) {
                    page.settleSeconds++
                    page.settlePrev = fps
                    return
                }
                page.settled = true
            }
            var s = page.samples
            s.push({ frames: smp.frames, ms: smp.ms, worst: smp.worstMs })
            page.samples = s
            page.frameSum += smp.frames
            page.msSum += smp.ms
            page.elapsed++
            page.stageMeasured++
            // Three seconds over the mark (32 fps): the step is too light for
            // this device now (calibrated hot, or a slow second kept it), and
            // fixed cost and refresh bend the score. The step is found again
            // right away from the next one up and the stage measured anew,
            // once per stage (Michał's Pad 6, 2026-10-19; mark tightened from
            // 50 fps in the night audit).
            var fixed = typeof selftestFixed !== "undefined" && selftestFixed
            if (item.ladder !== undefined && page.measurePhase === 0 && !page.reramped && !fixed && s.length >= 3) {
                var at = item.ladder.indexOf(item.load)
                if (page.frameSum * 1000 / page.msSum > page.tooLightFps && at >= 0 && at < item.ladder.length - 1) {
                    page.reramped = true
                    page.ramping = true
                    page.rampConfirm = false
                    page.rampStep = at + 1
                    item.load = item.ladder[page.rampStep]
                    page.samples = []
                    page.frameSum = 0
                    page.msSum = 0
                    page.elapsed = 0
                    page.openWindow()
                    return
                }
            }
            if (item.ladder !== undefined) {
                if (page.elapsed >= page.pointSeconds) {
                    if (page.measurePhase + 1 < page.pointWindows && page.nextWindow(item)) return
                    page.next()
                }
            } else if (!(item && item.selfTimed) && page.elapsed >= page.stageSeconds) {
                page.next()
            }
        }
    }
    // the window's seconds into the load they were measured at
    function bankWindow(item) {
        if (samples.length === 0) return
        var odd = measurePhase % 2 === 1
        var acc = odd ? pointB : pointA
        if (acc === null) acc = { samples: [], frames: 0, ms: 0, load: item.load,
                                  step: item.ladder !== undefined ? item.ladder.indexOf(item.load) : -1 }
        acc.samples = acc.samples.concat(samples)
        acc.frames += frameSum
        acc.ms += msSum
        if (odd) pointB = acc
        else pointA = acc
        var ws = windows
        ws.push({ load: item.load, frames: frameSum, ms: msSum, settle: settleSeconds })
        windows = ws
        samples = []
        frameSum = 0
        msSum = 0
    }
    // the other load: the next step up, at the top the one below
    function nextWindow(item) {
        var at = item.ladder.indexOf(item.load)
        if (at < 0) return false
        var other
        if (measurePhase % 2 === 0) {
            other = at + 1 < item.ladder.length ? at + 1 : at - 1
            if (other < 0) return false
        } else {
            other = pointA !== null ? pointA.step : at
        }
        bankWindow(item)
        measurePhase++
        elapsed = 0
        item.load = item.ladder[other]
        openWindow()
        return true
    }
    // Always the next step, never further: a second load two steps up gave
    // the CPU-bound stages (Benchy light, Cascade) 50-90 % higher scores,
    // their cost per item still falling with the load, while one step
    // repeated within 2-9 % (XA2, night audit)

    // a stage that times itself (storage) says when it is through
    Connections {
        target: stageLoader.item && stageLoader.item.selfTimed ? stageLoader.item : null
        ignoreUnknownSignals: true
        onFinished: page.next()
    }
    // a stage that cannot run on this GPU moves on at once
    Connections {
        target: stageLoader.item && stageLoader.item.unsupported !== undefined ? stageLoader.item : null
        ignoreUnknownSignals: true
        onUnsupportedChanged: if (stageLoader.item.unsupported !== "") page.next()
    }

    // checkpoint: a long run saved on the way, still running
    function writeLog(checkpoint) {
        var ended = checkpoint === true ? Date.now() : runEnded
        var phases = []
        for (var i = 0; i < order.length; i++) {
            var r = results[order[i]]
            if (r.unsupported)
                phases.push({ phase: order[i], name: r.name, unsupported: r.unsupported })
            else if (r.system)
                phases.push({ phase: order[i], name: r.name, value: r.value, unit: r.unit, threads: r.threads,
                              detail: r.detail })
            else
                phases.push({ phase: order[i], name: r.name, avg: r.avg, min: r.min, worst_tick_ms: r.worst,
                              samples: r.seconds, fps: r.fps, load: r.load, load_step: r.step, load_steps: r.steps,
                              score: r.score !== undefined ? Math.round(r.score * 10) / 10 : undefined,
                              unit: r.unit, calibrated_now: r.score !== undefined
                                      ? calibratedNow.indexOf(order[i]) >= 0 : undefined,
                              reramped: r.reramped || undefined, ramp: r.ramp && r.ramp.length ? r.ramp : undefined,
                              load2: r.load2, fps2: r.fps2, ms_per_frame: r.msPerFrame, ms_per_frame2: r.msPerFrame2,
                              score_single: r.scoreSingle !== undefined ? Math.round(r.scoreSingle * 10) / 10 : undefined,
                              overhead_ms: r.overheadMs, noisy: r.noisy || undefined, spread_pct: r.spreadPct,
                              settle_s: r.settle,
                              slope_failed: r.slopeFailed || undefined, superlinear: r.superlinear || undefined,
                              topped: r.topped || undefined, capped: r.capped || undefined,
                              partial: r.partial || undefined })
        }
        // no GPU clock all run: what the app finds where one may sit
        var gpuSeen = clocks.some(function (c) { return c[2] !== null })
        var run = {
            scene: sceneVersion,
            version: appVersion,
            started: new Date(runStarted).toISOString(),
            finished: new Date(ended).toISOString(),
            runtime_seconds: Math.round((ended - runStarted) / 1000),
            in_progress: checkpoint === true ? true : undefined,
            resolution: Screen.width + "x" + Screen.height,
            render_size: renderWidth + "x" + renderHeight,
            refresh_hz: Math.round(refreshHz * 10) / 10,
            build_arch: typeof buildArch !== "undefined" ? buildArch : undefined,
            cpu_arch: typeof cpuArch !== "undefined" ? cpuArch : undefined,
            ramp_fps: rampFps,
            too_light_fps: Math.round(tooLightFps * 10) / 10,
            stage_seconds: stageSeconds,
            interruptions: interruptions > 0 ? interruptions : undefined,
            device: deviceName,
            os: osName,
            soc: socName !== "" ? socName : undefined,
            kernel: kernelName,
            gpu: FrameCounter.gpu,
            gl_version: FrameCounter.glVersion,
            glsl_version: FrameCounter.glslVersion,
            loop: loop,
            mode: mode,
            loops: loops,
            temperature: temps,
            battery: batts,
            clocks: clocks,
            brightness_percent: brightnessAtStart >= 0 ? brightnessAtStart : undefined,
            brightness_set_by_run: brightnessSet,
            recalibrate_next: recalibrateNext.length > 0 ? recalibrateNext : undefined,
            recalibrate_heavy: recalibrateHeavy.length > 0 ? recalibrateHeavy : undefined,
            gpu_probe: gpuSeen ? undefined : log.gpuProbe(),
            passes: loops > 0 ? passes : undefined,
            phases: phases
        }
        // compact on disk (an hour of curves is large); Share JSON indents
        var json = JSON.stringify(run)
        // a run stopped before any stage finished is not kept
        if (phases.length > 0) {
            log.write(json)
            // kept as its own file, named by its start (newest first in the list)
            log.saveRun("run-" + Qt.formatDateTime(new Date(runStarted), "yyyyMMdd-hhmmss") + ".json", json)
        }
        if (checkpoint !== true) currentRun = JSON.parse(json)
    }

    BenchLog { id: log }
    // The single last run of 2.0 and before joins the saved runs once, at
    // the first start, before a new run overwrites it. Only once: in 2.1.0
    // an emptied list took last-run.json in again at every start, so the
    // newest run came back after it was deleted (ahjolinna, 2026-10-19).
    ConfigurationValue {
        id: runsImported
        key: "/apps/harbour-benchymark/runsImported"
        defaultValue: false
    }
    Component.onCompleted: {
        updateNeedsCalibration()
        importLast()
        loadNewest()
    }
    function importLast() {
        if (runsImported.value === true || runsImported.value === "true") return
        runsImported.value = true
        if (log.hasRunsFolder()) return
        try {
            var last = JSON.parse(log.readLast())
            if (last.started)
                log.saveRun("run-" + Qt.formatDateTime(new Date(Date.parse(last.started)), "yyyyMMdd-hhmmss")
                            + ".json", JSON.stringify(last, null, 1))
        } catch (e) { }
    }
    // The name without the vendor in front: "Reeder Jolla C2" is a Jolla C2,
    // "Jolla Jolla Phone" a Jolla Phone; "Jolla Tablet" keeps its first word.
    readonly property string deviceName: {
        var name = log.releaseValue("/etc/hw-release", "NAME")
        var vendor = log.releaseValue("/etc/hw-release", "MER_HA_VENDOR")
        var words = name.split(" ")
        if (vendor !== "" && words.length > 2 && words[0].toLowerCase() === vendor.toLowerCase())
            return words.slice(1).join(" ")
        return name
    }
    readonly property string osName: log.releaseValue("/etc/os-release", "PRETTY_NAME")
    readonly property string socName: log.socName()
    readonly property string kernelName: log.kernel()
    // test hooks from main.cpp: SFOS_SELFTEST_RUN=<stage index> runs only that
    // stage (-2 all ticked ones); SFOS_SELFTEST_STOP=<s> ends it after s seconds
    readonly property int selftestSeconds: typeof selftestStop !== "undefined" ? selftestStop : 0
    // the stage's measured seconds over all its windows (elapsed restarts
    // with each window of the two loads)
    property int stageMeasured: 0
    // The seconds left in the stage, counting only down: the window running
    // and those to come at one dropped second each; a second dropped beyond
    // that holds the count instead of adding to it.
    readonly property int stageLeft: {
        var item = stageLoader.item
        var cur = (warm ? 0 : 1)
        if (item && item.ladder !== undefined)
            return Math.max(0, cur + pointSeconds - elapsed
                               + (pointWindows - 1 - measurePhase) * (pointSeconds + 1))
        return Math.max(0, cur + stageSeconds - elapsed)
    }
    onStageMeasuredChanged: if (selftestSeconds > 0 && stageMeasured >= selftestSeconds) stop()
    Timer {
        interval: 1500
        running: typeof selftestRun !== "undefined" && selftestRun !== -1
        onTriggered: {
            if (selftestRun >= 0) {
                page.resetRun([selftestRun])
            } else {
                page.start()
            }
        }
    }

    // ── select ────────────────────────────────────────────────────────────────
    // The Benchy turns slowly behind the controls.
    Wireframe {
        id: backdrop
        anchors.fill: parent
        visible: page.view === "select"
        opacity: 0.6
        NumberAnimation on angle {
            from: 0; to: 360; duration: 20000
            loops: Animation.Infinite
            running: backdrop.visible && Qt.application.active
        }
    }

    // A description open: the Benchy dims, so the white text reads over it.
    // dark on a dark ambience, light on a light one, so the names read
    Rectangle {
        anchors.fill: parent
        visible: page.view === "select"
        color: Theme.colorScheme === Theme.LightOnDark ? "black" : "white"
        opacity: page.openAbout >= 0 ? 0.65 : 0
        Behavior on opacity { FadeAnimation { } }
    }

    // One page that scrolls, as SailfishOS does it: the stages, the loop
    // toggle and Start one under the other, an open description pushes the
    // rest down (mo, 2026-10-17; a fixed list area cut the descriptions off).
    SilicaFlickable {
        anchors.fill: parent
        visible: page.view === "select"
        contentHeight: selectColumn.height + Theme.paddingLarge * 3

        // the nearest to the finger last: Deselect all, the quickest way to
        // run only one or a few stages (mo, 2026-10-18)
        PullDownMenu {
            MenuItem {
                //% "Settings"
                text: qsTrId("id-settings")
                onClicked: page.openSettings()
            }
            MenuItem {
                //% "Select all"
                text: qsTrId("id-select-all")
                onClicked: skippedConfig.value = "[]"
            }
            MenuItem {
                //% "Deselect all"
                text: qsTrId("id-deselect-all")
                onClicked: skippedConfig.value = JSON.stringify(page.stages.map(function (st) { return st.key }))
            }
        }

        Column {
            id: selectColumn
            width: parent.width

            PageHeader {
                title: "Benchymark"
                description: "v" + appVersion
            }

            // The switch ticks the stage; a tap on the name opens one
            // sentence about it below, one at a time.
            Repeater {
                model: page.stages
                Item {
                    id: row
                    width: selectColumn.width
                    height: Math.max(sw.height, nameArea.height) + (open ? about.height + Theme.paddingMedium : 0)
                    readonly property bool open: page.openAbout === index
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                    clip: true

                    Switch {
                        id: sw
                        // twice the page margin: easier to hit than at the edge (mo)
                        x: Theme.horizontalPageMargin * 2 - Theme.paddingLarge
                        checked: page.isOn(modelData.key)
                        automaticCheck: false
                        onClicked: page.setOn(modelData.key, !checked)
                    }
                    // SailfishOS lights the text on a press, no bar behind it (mo,
                    // 2026-10-18: the bar came from the AsteroidOS port)
                    MouseArea {
                        id: nameArea
                        anchors.left: sw.right
                        anchors.right: parent.right
                        height: Math.max(sw.height, nameLabel.height + 2 * Theme.paddingSmall)
                        // hints on: a tap opens the description; off: the whole row
                        // ticks the stage (mo, 2026-10-18)
                        onClicked: {
                            if (showHints.value === true || showHints.value === "true")
                                page.openAbout = row.open ? -1 : index
                            else
                                page.setOn(modelData.key, !page.isOn(modelData.key))
                        }
                        Label {
                            id: nameLabel
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.horizontalPageMargin
                            text: modelData.name
                            color: (nameArea.pressed && nameArea.containsMouse) || row.open
                                   ? Theme.highlightColor : Theme.primaryColor
                            wrapMode: Text.Wrap
                        }
                    }
                    Label {
                        id: about
                        anchors.top: nameArea.bottom
                        anchors.left: nameArea.left
                        width: nameLabel.width
                        text: modelData.about
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                        // the strongest text colour: it floats over the dimmed Benchy
                        color: Theme.primaryColor
                        opacity: row.open ? 1 : 0
                        Behavior on opacity { FadeAnimation { } }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge * 2 }

            // once or in a loop
            Label {
                id: loopToggle
                anchors.horizontalCenter: parent.horizontalCenter
                // "run": a sequence is run (mo, 2026-10-17)
                text: page.modeNames[page.mode]
                color: loopArea.pressed ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                MouseArea {
                    id: loopArea
                    anchors.fill: parent
                    anchors.margins: -Theme.paddingLarge
                    onClicked: modeConfig.value = page.modes[(page.modes.indexOf(page.mode) + 1) % page.modes.length]
                }
            }

            // what the chosen mode is for, only that one (mo, 2026-10-18)
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                // the hints can be switched off; why the first run is longer stays
                readonly property bool calibrateNote: page.mode === "once" && page.needsCalibration
                visible: showHints.value || calibrateNote
                text: (showHints.value ? page.modeHints[page.mode] : "")
                      + (showHints.value && calibrateNote ? " " : "")
                      //% "The first run also finds each graphics stage's load, a few seconds per stage."
                      + (calibrateNote ? qsTrId("id-hint-calibrate") : "")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }

            Item { width: 1; height: Theme.paddingLarge * 2 }

            Button {
                id: startButton
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: page.stages.some(function (s) { return page.isOn(s.key) })
                //% "Start"
                text: qsTrId("id-start")
                onClicked: introFade.start()
            }
        }

        VerticalScrollDecorator { }
    }

    // Start fades the page to black over a second, then the first stage
    // comes (mo, 2026-10-17: it cut straight over)
    Rectangle {
        id: introCover
        anchors.fill: parent
        color: "black"
        opacity: 0
        visible: opacity > 0
        z: 100
        NumberAnimation on opacity {
            id: introFade
            from: 0; to: 1; duration: 1000
            running: false
            onStopped: { page.start(); introCover.opacity = 0 }
        }
    }

    // ── run ───────────────────────────────────────────────────────────────────
    // Black behind the stages, so the ambience does not change the result;
    // between stages it fades out and the progress bar shows on the ambience,
    // and fades back in before the next stage loads (mo, 2026-10-17).
    readonly property int fadeMs: 300
    property bool gapEnding: false
    Rectangle {
        anchors.fill: parent
        color: "black"
        visible: page.view === "run"
        opacity: page.inGap && !page.gapEnding ? 0 : 1
        Behavior on opacity { FadeAnimation { duration: page.fadeMs } }
    }
    Timer {
        id: gapEndTimer
        interval: page.gapSeconds * 1000 - page.fadeMs
        onTriggered: page.gapEnding = true
    }

    // The stage is laid out at the render size itself, drawn into a texture
    // of that size and scaled up to the panel as a whole. Only drawing it
    // smaller let blurs and glyphs inside still work at the screen's size: a
    // Pad 6 blurred 5.2 million pixels per glow and drew its reraster glyphs
    // 2.5 times larger (Michał, 2026-10-19). The C2's screen is the render
    // size, so it draws as before.
    readonly property real stageScale: Math.min(width / renderWidth, height / renderHeight)
    Loader {
        id: stageLoader
        width: page.renderWidth
        height: page.renderHeight
        // centred, black bars on the sides (or top and bottom) of other shapes
        x: (page.width - page.renderWidth * page.stageScale) / 2
        y: (page.height - page.renderHeight * page.stageScale) / 2
        transformOrigin: Item.TopLeft
        scale: page.stageScale
        layer.enabled: page.view === "run"
        layer.textureSize: Qt.size(page.renderWidth, page.renderHeight)
        layer.smooth: true
        visible: page.view === "run" && !page.inGap
    }

    // Between stages: the next stage's name and a bar over the pause.
    Column {
        visible: page.view === "run" && page.inGap
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingLarge

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            //% "Next: %1"
            text: qsTrId("id-next").arg(page.stages[page.nextStage].name)
            font.pixelSize: Theme.fontSizeLarge
            // between stages the ambience shows through
            color: Theme.primaryColor
        }
        ProgressBar {
            width: parent.width
            minimumValue: 0
            maximumValue: 1
            NumberAnimation on value {
                id: gapProgress
                from: 0; to: 1
                duration: page.gapSeconds * 1000
                running: false
            }
        }
    }

    Column {
        id: hud
        visible: page.view === "run" && !page.inGap
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.paddingLarge * 2
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: page.current >= 0 ? page.stages[page.current].name : ""
            font.pixelSize: Theme.fontSizeLarge
            color: "white"
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property var item: stageLoader.item
            text: item && item.system ? (item.live !== "" ? item.live : "–")
                  //% "calibrating"
                  : page.ramping ? qsTrId("id-calibrating") + "  ·  " + page.lastFps + " fps"
                  : !page.warm ? "–  ·  " + page.stageLeft + " s"
                  : page.lastFps + " fps" + "  ·  " + page.stageLeft + " s"
            font.pixelSize: Theme.fontSizeMedium
            color: "white"
            opacity: 0.8
        }
    }

    Label {
        id: tapLabel
        visible: page.view === "run"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge * 2
        //% "Tap to stop"
        text: qsTrId("id-tap-to-stop") + (page.mode === "hour" ? "  ·  " + page.hourLeft : "")
        color: "white"
        opacity: 0.6
    }
    // the hour's countdown under the run, once a second
    property string hourLeft: ""
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: page.view === "run" && page.mode === "hour"
        onTriggered: page.hourLeft = page.clockText(page.hourSeconds - (Date.now() - page.runStarted) / 1000)
    }

    MouseArea {
        anchors.fill: parent
        enabled: page.view === "run"
        onClicked: page.stop()
    }

    // ── results ──────────────────────────────────────────────────────────────
    // the run that just ended, from the JSON it was saved as
    property var currentRun: null
    // before a run, the newest saved one: the settings show real values
    property var newestRun: null
    function loadNewest() {
        var names = log.runs()
        if (names.length === 0) return
        try { newestRun = JSON.parse(log.readRun(names[0])) } catch (e) { }
    }
    ResultsPane {
        id: resultsPane
        anchors.fill: parent
        visible: page.view === "results"
        run: page.currentRun !== null ? page.currentRun : page.newestRun
        stageInfo: page.stageInfo
        onSettingsClicked: page.openSettings()
        onBackClicked: page.view = "select"
    }

    function clockText(seconds) {
        var t = Math.max(0, Math.round(seconds))
        var two = function (n) { return (n < 10 ? "0" : "") + n }
        return Math.floor(t / 3600) + ":" + two(Math.floor(t / 60) % 60) + ":" + two(t % 60)
    }

    readonly property var modeNames: ({
        //% "Run once"
        once: qsTrId("id-run-once"),
        //% "Run one hour"
        hour: qsTrId("id-run-hour"),
        //% "Run in loop"
        loop: qsTrId("id-run-loop")
    })
    readonly property var modeHints: ({
        //% "For comparable results"
        once: qsTrId("id-hint-once"),
        //% "A defined battery and temperature test, ends at 1:00:00. The display runs at 50 % brightness with automatic brightness off, and is set back afterwards."
        hour: qsTrId("id-hint-hour"),
        //% "Until you tap: overheating and throttling diagnosis"
        loop: qsTrId("id-hint-loop")
    })
}
