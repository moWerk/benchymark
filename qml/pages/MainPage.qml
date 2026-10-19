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

    // Stamped into every result; runs of another scene do not compare.
    // sfos-2.0: a fixed render size and calibrated loads with a score
    // (resolution point by Mister Magister, 2026-10-18), not comparable to 1.x.
    // sfos-2.2: every graphics stage drawn off screen on one 720 x 1600
    // canvas, with the same fixed load on every device, as fast as the
    // device can draw (rework of 2026-10-19). On screen the frame rate
    // carried the refresh cap and a fixed 12-25 ms per frame for compositing
    // and scaling, and the scores bent around both (night audit).
    readonly property string sceneVersion: "sfos-2.2"
    readonly property int stageSeconds: 10    // a system stage, measured
    // A graphics stage: two seconds not measured while clocks and caches
    // settle, then six measured; how far its two halves' scores lie apart
    // is the measurement's own spread.
    // with "Show stages moving", two seconds on screen at the display's own
    // pace before that, for the eye only: not measured (mo, 2026-10-19)
    readonly property int introSeconds: 2
    ConfigurationValue {
        id: showMotion
        key: "/apps/harbour-benchymark/showMotion"
        defaultValue: true
    }
    readonly property bool motion: showMotion.value === true || showMotion.value === "true"
    property bool intro: false   // a graphics stage on screen before it is measured
    readonly property int warmupSeconds: 2
    readonly property int measureSeconds: 6
    readonly property int gapSeconds: 2      // between stages

    // Every stage draws on the C2's 720 x 1600: a phone with more pixels or
    // another shape gets exactly the same work (mo, 2026-10-18; the shape
    // since the night audit, 2026-10-19).
    readonly property int renderWidth: 720
    readonly property int renderHeight: 1600
    readonly property real renderPixels: renderWidth * renderHeight
    readonly property real refreshHz: FrameCounter.refreshRate > 0 ? FrameCounter.refreshRate : 60
    // the stages drawn off screen; the system stages run on screen
    readonly property var graphicsKeys: ["BENCHY-LIGHT", "BENCHY-HEAVY", "BENCHY-GLOW",
        "SHADER-LIGHT", "SHADER-HEAVY", "BUFFER-UBO", "BUFFER-SSBO", "BUFFER-TEXTURE",
        "OVERDRAW", "CASCADE", "ICONS"]

    // In the order that reads best: the bright graphics first, text last,
    // then the system stages, storage at the very end (mo, 2026-10-17).
    // `about` is the one-sentence manual shown under the name on a tap.
    // A graphics stage scores its work per second (2.2: a fixed load, off
    // screen); a system stage its own figure.
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
    property int elapsed: 0       // measured seconds of a system stage
    property bool warm: false     // its first second is not measured
    property int stageLeft: 0     // the stage's seconds left, for the run's line
    property int lastFps: 0       // a graphics stage's frames per second so far
    property int previewSerial: 0 // the newest copy of its frames for the screen
    property int loops: 0
    property var passes: []       // every finished stage of the run, per pass
    property int interruptions: 0 // stages restarted after the app was in the background
    property int savedAt: 0       // seconds into the run of the last save on the way
    property var results: ({})    // key -> row
    property var order: []        // keys in the order they finished
    property double runStarted: 0
    property double runEnded: 0    // with runStarted the exact runtime, for drain per hour

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
        lastFps = 0
        previewSerial = 0
        intro = false
        introTimer.stop()
        introClock.stop()
        // in the background nothing runs: the stage starts when the app is
        // back (onActiveChanged below)
        if (!Qt.application.active) { stageLoader.source = ""; offscreen.unload(); return }
        var st = stages[current]
        var props = { areaTop: Math.max(0, (areaTop - stageLoader.y) / stageScale),
                      areaBottom: Math.min(renderHeight, (areaBottom - stageLoader.y) / stageScale),
                      renderWidth: renderWidth, renderHeight: renderHeight }
        if (graphicsKeys.indexOf(st.key) >= 0 && motion) {
            // first on screen, moving in real time; then measured
            intro = true
            stageLoader.setSource(Qt.resolvedUrl("../stages/" + st.file + ".qml"), props)
            stageLeft = introSeconds + warmupSeconds + measureSeconds
            introClock.restart()
            introTimer.restart()
        } else if (graphicsKeys.indexOf(st.key) >= 0) {
            measureGraphics()
        } else {
            stageLoader.setSource(Qt.resolvedUrl("../stages/" + st.file + ".qml"), props)
            stageLeft = stageSeconds + 1
            fpsTimer.restart()
        }
    }
    // the stage's time on screen, as off screen: seconds at 60 frames each
    NumberAnimation {
        id: introClock
        target: stageLoader.item
        property: "t"
        from: 0; to: page.introSeconds
        duration: page.introSeconds * 1000
    }
    Timer {
        id: introTimer
        interval: page.introSeconds * 1000
        onTriggered: page.measureGraphics()
    }
    // the countdown during the two seconds on screen
    Timer {
        interval: 1000
        repeat: true
        running: page.intro && introTimer.running
        onTriggered: page.stageLeft = Math.max(0, page.stageLeft - 1)
    }
    function measureGraphics() {
        var st = stages[current]
        intro = false
        introClock.stop()
        stageLoader.source = ""
        var props = { areaTop: Math.max(0, (areaTop - stageLoader.y) / stageScale),
                      areaBottom: Math.min(renderHeight, (areaBottom - stageLoader.y) / stageScale),
                      renderWidth: renderWidth, renderHeight: renderHeight }
        var err = offscreen.load(Qt.resolvedUrl("../stages/" + st.file + ".qml"), props,
                                 renderWidth, renderHeight)
        if (err !== "") {
            console.warn("Benchymark: " + st.key + ": " + err)
            //% "could not be loaded"
            record(st.key, { name: st.name, system: false, unsupported: qsTrId("id-stage-load-error") })
            next()
            return
        }
        stageLeft = warmupSeconds + measureSeconds
        offscreen.measure(warmupSeconds * 1000, measureSeconds * 1000)
    }
    // The app went to the background mid-stage (cover, a call, the lock
    // screen): the stage stops, its threads too, and starts over when the
    // app is back; the run notes it.
    Connections {
        target: Qt.application
        onActiveChanged: {
            if (page.view !== "run" || page.inGap || page.step < 0) return
            if (!Qt.application.active) {
                if (stageLoader.source != "" || offscreen.running) {
                    page.interruptions++
                    introTimer.stop()
                    introClock.stop()
                    page.intro = false
                    offscreen.stop()
                    offscreen.unload()
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

    // a system stage's rows, or why it could not run
    function finishStage() {
        var item = stageLoader.item
        // nothing loaded: a graphics stage, or already recorded
        if (!item) return
        if (item.unsupported !== undefined && item.unsupported !== "") {
            record(stages[current].key, { name: stages[current].name, system: false,
                                          unsupported: item.unsupported })
            return
        }
        if (!item.system) return
        var rows = item.results()   // [{ key, name, value, unit }]
        for (var j = 0; j < rows.length; j++)
            if (rows[j].unsupported)
                record(rows[j].key, { name: rows[j].name, system: false, unsupported: rows[j].unsupported })
            else
                record(rows[j].key, { name: rows[j].name, system: true, value: rows[j].value,
                                      unit: rows[j].unit, threads: rows[j].threads, detail: rows[j].detail })
    }

    // A graphics stage's row: the work it drew over the time it took. Per
    // pixel work counts in millions of rendered pixels.
    function graphicsRow(st, item, frames, ms, halfFrames, halfMs, partial) {
        var k = item.perPixel ? renderPixels / 1e6 : 1
        var row = { name: st.name, system: false, load: item.load, unit: item.unit,
                    frames: frames, ms: Math.round(ms), fps: Math.round(frames * 10000 / ms) / 10,
                    score: frames * item.load * k * 1000 / ms, partial: partial }
        // the two halves' scores apart, each from their mean: marked past 10 %
        if (halfFrames > 0 && frames > halfFrames && ms > halfMs) {
            var a = halfFrames / halfMs, b = (frames - halfFrames) / (ms - halfMs)
            row.spreadPct = Math.round(Math.abs(a - b) / (a + b) * 1000) / 10
            row.noisy = row.spreadPct > 10
        }
        return row
    }
    function graphicsDone(frames, ms, halfFrames, halfMs) {
        var st = stages[current]
        var item = offscreen.item
        if (item && item.unsupported !== undefined && item.unsupported !== "")
            record(st.key, { name: st.name, system: false, unsupported: item.unsupported })
        else if (item && frames > 0 && ms > 0)
            record(st.key, graphicsRow(st, item, frames, ms, halfFrames, halfMs, false))
        next()
    }
    OffscreenRun {
        id: offscreen
        previewMs: 500
        onFinished: page.graphicsDone(frames, ms, halfFrames, halfMs)
        onPreview: page.previewSerial = serial
        onQuitting: if (page.view === "run") page.stop()
        onProgress: {
            page.stageLeft = Math.max(0, Math.ceil((measuring ? page.measureSeconds
                                       : page.warmupSeconds + page.measureSeconds) - ms / 1000))
            page.lastFps = measuring && ms > 0 ? Math.round(frames * 1000 / ms) : 0
            if (measuring && page.selftestSeconds > 0 && ms / 1000 >= page.selftestSeconds) page.stop()
        }
        onFailed: {
            console.warn("Benchymark: " + why)
            page.record(page.stages[page.current].key, { name: page.stages[page.current].name,
                        system: false, unsupported: qsTrId("id-stage-load-error") })
            page.next()
        }
    }
    // a GPU that cannot run a table stage says so on its first frames
    Connections {
        target: offscreen.item && offscreen.item.unsupported !== undefined ? offscreen.item : null
        ignoreUnknownSignals: true
        // the reason comes in the middle of a frame: the stage goes after it
        onUnsupportedChanged: if (offscreen.item.unsupported !== "" && offscreen.running) unsupportedTimer.start()
    }
    Timer {
        id: unsupportedTimer
        interval: 0
        onTriggered: {
            if (!offscreen.running) return
            offscreen.stop()
            page.graphicsDone(0, 0, -1, 0)
        }
    }

    // atHour: the hour ran out mid-stage; a stage that has a full result
    // from an earlier round keeps it rather than the cut one
    function stop(atHour) {
        if (view !== "run") return
        hourTimer.stop()
        // a stage cut short keeps the full row of an earlier pass, if any
        var cut = current >= 0 && results[stages[current].key] !== undefined
        if (!inGap && current >= 0) {
            if (offscreen.running) {
                var at = offscreen.stop()
                // a second measured at least, marked as cut short
                if (!cut && offscreen.item && at.frames > 0 && at.ms >= 1000)
                    record(stages[current].key, graphicsRow(stages[current], offscreen.item,
                                                            at.frames, at.ms, -1, 0, true))
            } else if (!cut) {
                finishStage()
            }
        }
        introTimer.stop()
        introClock.stop()
        intro = false
        if (brightnessSet) restoreDisplay()
        offscreen.unload()
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
        offscreen.unload()
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

    // a system stage's seconds
    Timer {
        id: fpsTimer
        interval: 1000
        repeat: true
        running: page.view === "run" && !page.inGap && Qt.application.active && stageLoader.source != "" && !page.intro
        onTriggered: {
            // a stage that fails to load would stall the run
            if (stageLoader.status === Loader.Error) {
                page.record(page.stages[page.current].key, { name: page.stages[page.current].name,
                            system: false, unsupported: qsTrId("id-stage-load-error") })
                page.next()
                return
            }
            if (stageLoader.status !== Loader.Ready) return
            if (!page.warm) { page.warm = true; return }
            page.elapsed++
            page.stageLeft = Math.max(0, page.stageSeconds - page.elapsed)
            if (page.selftestSeconds > 0 && page.elapsed >= page.selftestSeconds) { page.stop(); return }
            var item = stageLoader.item
            if (!(item && item.selfTimed) && page.elapsed >= page.stageSeconds) page.next()
        }
    }

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
                phases.push({ phase: order[i], name: r.name, load: r.load, frames: r.frames, ms: r.ms,
                              fps: r.fps, score: r.score !== undefined ? Math.round(r.score * 10) / 10 : undefined,
                              unit: r.unit, spread_pct: r.spreadPct, noisy: r.noisy || undefined,
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
            // graphics stages: drawn off screen, warm-up and measured seconds
            method: "offscreen",
            warmup_seconds: warmupSeconds,
            measure_seconds: measureSeconds,
            // the two seconds on screen before, not measured
            intro_seconds: motion ? introSeconds : 0,
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
                visible: showHints.value === true || showHints.value === "true"
                text: page.modeHints[page.mode]
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

    // A graphics stage draws off screen; a copy of its frames shows here
    // while it warms up, then holds still while it is measured, at the same
    // place and size as a stage on screen.
    Image {
        width: page.renderWidth
        height: page.renderHeight
        x: stageLoader.x
        y: stageLoader.y
        transformOrigin: Item.TopLeft
        scale: page.stageScale
        smooth: true
        cache: false
        visible: page.view === "run" && !page.inGap && page.previewSerial > 0
        source: page.previewSerial > 0 ? "image://offscreen/" + page.previewSerial : ""
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
                  : (page.lastFps > 0 ? page.lastFps + " fps" : "–") + "  ·  " + page.stageLeft + " s"
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
