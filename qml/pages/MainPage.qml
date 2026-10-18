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
    readonly property string sceneVersion: "sfos-2.0"
    readonly property int stageSeconds: 10    // a timed stage, measured
    readonly property int gapSeconds: 2      // between stages

    // Every stage draws into the same number of pixels, the C2's 720 x 1600,
    // in the screen's own shape, and is scaled up to the panel: a phone with
    // more pixels gets no more work (mo, 2026-10-18).
    readonly property real renderPixels: 720 * 1600
    readonly property real screenAspect: Screen.width / Screen.height
    readonly property int renderWidth: Math.round(Math.sqrt(renderPixels * screenAspect))
    readonly property int renderHeight: Math.round(renderPixels / renderWidth)

    // A stage with a `ladder` of loads finds its step on the first run: from
    // the lightest up, one second to settle and one to measure each, to the
    // first step under rampFps. The step is kept per scene, so later runs
    // measure the same 10 seconds right away (mo, 2026-10-18). The score is
    // fps x load, so it compares whatever step a device chose. Under 25 fps:
    // near 40 the fixed cost of a frame ate a fifth of the score (XA2,
    // Overdraw: 1393 layers/s at 36 layers, 1670 at 72, 1728 at 144).
    readonly property int rampFps: 25
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
        "OVERDRAW", "CASCADE", "ICONS", "SCALE", "RERASTER"]
    readonly property bool needsCalibration: {
        var c = calibration()
        return stages.some(function (st) {
            return isOn(st.key) && calibratingKeys.indexOf(st.key) >= 0
                   && c[groupOf[st.key] || st.key] === undefined })
    }
    property var recalibrateNext: []   // keys whose step ran too light in this run
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
        //% "Benchy light"
        { name: qsTrId("id-stage-benchy-light"), key: "BENCHY-LIGHT", file: "BenchyLow",
          //% "Two 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. Scores boats per second."
          about: qsTrId("id-about-benchy-light"),
          //% "Boats drawn per second, two large ones on screen"
          score: qsTrId("id-score-benchy-light") },
        //% "Benchy heavy"
        { name: qsTrId("id-stage-benchy-heavy"), key: "BENCHY-HEAVY", file: "BenchyHigh",
          //% "Six boats, each drawn many times: much more geometry than the picture shows. Scores boats per second."
          about: qsTrId("id-about-benchy-heavy"),
          //% "Boats drawn per second, six smaller ones on screen"
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
        //% "Text scale"
        { name: qsTrId("id-stage-scale"), key: "SCALE", file: "Scale",
          //% "Numbers growing and shrinking by a scale transform: text drawn once and only resized, the cheap way. Scores texts per second."
          about: qsTrId("id-about-scale"),
          //% "Texts scaled per second"
          score: qsTrId("id-score-scale") },
        //% "Text reraster"
        { name: qsTrId("id-stage-reraster"), key: "RERASTER", file: "Reraster",
          //% "The same picture made by changing the font size, so every glyph is drawn anew each frame: what animated text size costs. Scores texts per second."
          about: qsTrId("id-about-reraster"),
          //% "Texts redrawn per second"
          score: qsTrId("id-score-reraster") },
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
        pageStack.push(Qt.resolvedUrl("SettingsPage.qml"),
                       { details: resultsPane.view.detailList(), stageInfo: stageInfo,
                         currentStarted: currentRun && currentRun.started ? currentRun.started : "",
                         startTab: tab === 1 ? 1 : 0 })
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
    property int lastFps: 0
    property int loops: 0
    property var samples: []      // this stage
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
    Component.onDestruction: restoreDisplay()
    Timer {
        interval: 1000
        repeat: true
        running: page.view === "run"
        onTriggered: {
            var s = Math.round((Date.now() - page.runStarted) / 1000)
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
        plan = p
        temps = []
        batts = []
        clocks = []
        calibratedNow = []
        recalibrateNext = []
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
        lastFps = 0
        stageLoader.setSource(Qt.resolvedUrl("../stages/" + stages[current].file + ".qml"),
                              { areaTop: areaTop, areaBottom: areaBottom,
                                renderWidth: renderWidth, renderHeight: renderHeight })
        var item = stageLoader.item
        ramping = false
        rampConfirm = false
        reramped = false
        if (item && item.ladder !== undefined) {
            var saved = savedStep(calibKey(item, stages[current].key))
            rampStep = saved >= 0 ? Math.min(saved, item.ladder.length - 1) : 0
            ramping = saved < 0
            item.load = item.ladder[rampStep]
        }
        FrameCounter.take()
        FrameCounter.takeWorstMs()
        sampledAt = Date.now()
    }

    function record(key, row) {
        var r = results
        r[key] = row
        results = r
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
                record(rows[j].key, { name: rows[j].name, system: true,
                                      value: rows[j].value, unit: rows[j].unit })
            return
        }
        if (samples.length === 0) return
        var sum = 0, min = 1e9, worst = 0
        for (var i = 0; i < samples.length; i++) {
            sum += samples[i].fps
            min = Math.min(min, samples[i].fps)
            worst = Math.max(worst, samples[i].worst)
        }
        var st = stages[current]
        var row = { name: st.name, system: false, avg: Math.round(sum / samples.length),
                    min: min, worst: worst, seconds: samples.length }
        if (item.ladder !== undefined) {
            // per pixel work counts in millions of rendered pixels
            var avg = sum / samples.length
            row.load = item.load
            row.step = item.ladder.indexOf(item.load)
            row.unit = item.unit
            row.score = avg * item.load * (item.perPixel ? renderPixels / 1e6 : 1)
            // A saved step that now runs far over the mark (calibrated hot or
            // busy, or a faster driver since) nears the refresh rate, where
            // the score bends: the next run calibrates the stage again.
            // A group's step suits its slowest member, so the others may run
            // faster by right: they only count from four times the mark.
            var limit = item.calibrationGroup !== undefined ? 4 * rampFps : 2 * rampFps
            if (avg > limit && row.step < item.ladder.length - 1) {
                saveStep(calibKey(item, st.key), -1)
                var rn = recalibrateNext
                rn.push(st.key)
                recalibrateNext = rn
            }
        }
        record(st.key, row)
    }

    // atHour: the hour ran out mid-stage; a stage that has a full result
    // from an earlier round keeps it rather than the cut one
    function stop(atHour) {
        if (view !== "run") return
        hourTimer.stop()
        var cut = atHour === true && current >= 0 && results[stages[current].key] !== undefined
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

    // once a second: the frames presented, and the longest frame
    Timer {
        interval: 1000
        repeat: true
        running: page.view === "run" && !page.inGap && Qt.application.active
        onTriggered: {
            // The timer runs on the GUI thread, which a heavy stage delays, so
            // a "second" can be longer: divide by the time that passed, not by
            // the second asked for (the watch version's v0.6 fix).
            var now = Date.now()
            var frames = FrameCounter.take()
            var fps = Math.round(frames * 1000 / Math.max(1, now - page.sampledAt))
            page.sampledAt = now
            var worst = FrameCounter.takeWorstMs()
            if (stageLoader.status !== Loader.Ready) return
            if (!page.warm) { page.warm = true; return }
            page.lastFps = fps
            var item = stageLoader.item
            if (page.ramping) {
                var top = page.rampStep >= item.ladder.length - 1
                if (fps < page.rampFps && !page.rampConfirm && !top) {
                    // under the mark once: the same step is measured again
                    page.rampConfirm = true
                } else if (fps < page.rampFps || top) {
                    // under the mark twice, or the heaviest: keep it, then measure
                    page.ramping = false
                    page.rampConfirm = false
                    page.saveStep(page.calibKey(item, page.stages[page.current].key), page.rampStep)
                    var cn = page.calibratedNow
                    if (cn.indexOf(page.stages[page.current].key) < 0) cn.push(page.stages[page.current].key)
                    page.calibratedNow = cn
                } else {
                    page.rampConfirm = false
                    page.rampStep++
                    item.load = item.ladder[page.rampStep]
                }
                page.warm = false   // the next second settles
                return
            }
            var s = page.samples
            s.push({ fps: fps, worst: worst })
            page.samples = s
            page.elapsed++
            // Three seconds far over the mark: the step is too light for this
            // device now (calibrated hot, or a slow second kept it), and the
            // score would bend at the refresh rate. The step is found again
            // right away from the next one up, and the stage measured anew,
            // once per stage (Michał's Pad 6, 2026-10-19). A group's step
            // suits its slowest member, so the others count from four times.
            if (item.ladder !== undefined && !page.reramped && s.length >= 3) {
                var sum = 0
                for (var i = 0; i < s.length; i++) sum += s[i].fps
                var limit = item.calibrationGroup !== undefined ? 4 * page.rampFps : 2 * page.rampFps
                var at = item.ladder.indexOf(item.load)
                if (sum / s.length > limit && at >= 0 && at < item.ladder.length - 1) {
                    page.reramped = true
                    page.ramping = true
                    page.rampConfirm = false
                    page.rampStep = at + 1
                    item.load = item.ladder[page.rampStep]
                    page.samples = []
                    page.elapsed = 0
                    page.warm = false
                    return
                }
            }
            if (!(item && item.selfTimed) && page.elapsed >= page.stageSeconds)
                page.next()
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

    function writeLog() {
        var phases = []
        for (var i = 0; i < order.length; i++) {
            var r = results[order[i]]
            if (r.unsupported)
                phases.push({ phase: order[i], name: r.name, unsupported: r.unsupported })
            else if (r.system)
                phases.push({ phase: order[i], name: r.name, value: r.value, unit: r.unit })
            else
                phases.push({ phase: order[i], name: r.name, avg: r.avg, min: r.min, worst_tick_ms: r.worst,
                              samples: r.seconds, load: r.load, load_step: r.step,
                              score: r.score !== undefined ? Math.round(r.score * 10) / 10 : undefined,
                              unit: r.unit, calibrated_now: r.score !== undefined
                                      ? calibratedNow.indexOf(order[i]) >= 0 : undefined })
        }
        // no GPU clock all run: what the app finds where one may sit
        var gpuSeen = clocks.some(function (c) { return c[2] !== null })
        var run = {
            scene: sceneVersion,
            version: appVersion,
            started: new Date(runStarted).toISOString(),
            finished: new Date(runEnded).toISOString(),
            runtime_seconds: Math.round((runEnded - runStarted) / 1000),
            resolution: Screen.width + "x" + Screen.height,
            render_size: renderWidth + "x" + renderHeight,
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
            gpu_probe: gpuSeen ? undefined : log.gpuProbe(),
            phases: phases
        }
        var json = JSON.stringify(run, null, 1)
        log.write(json)
        // kept as its own file, named by its start (newest first in the list)
        log.saveRun("run-" + Qt.formatDateTime(new Date(runStarted), "yyyyMMdd-hhmmss") + ".json", json)
        currentRun = JSON.parse(json)
    }

    BenchLog { id: log }
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
    onElapsedChanged: if (selftestSeconds > 0 && elapsed >= selftestSeconds) stop()
    Timer {
        interval: 1500
        running: typeof selftestRun !== "undefined" && selftestRun !== -1
        onTriggered: {
            if (selftestRun >= 0) {
                page.plan = [selftestRun]
                page.results = ({}); page.order = []; page.loops = 0
                page.view = "run"; page.runStarted = Date.now()
                page.beginStep(0)
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
    Rectangle {
        anchors.fill: parent
        visible: page.view === "select"
        color: "black"
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
                onClicked: page.openSettings(0)
            }
            MenuItem {
                //% "Saved results"
                text: qsTrId("id-saved-results")
                onClicked: page.openSettings(1)
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
                        // white, not the ambience tint: it floats over the dimmed Benchy
                        color: "white"
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

    Loader {
        id: stageLoader
        anchors.fill: parent
        // drawn at the fixed render size, then scaled to the panel
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
            color: "white"
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
                  : !page.warm ? "–"
                  : page.lastFps + " fps"
                    + "  ·  " + Math.max(0, page.stageSeconds - page.elapsed) + " s"
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
    ResultsPane {
        id: resultsPane
        anchors.fill: parent
        visible: page.view === "results"
        run: page.currentRun
        stageInfo: page.stageInfo
        onSettingsClicked: page.openSettings(0)
        onSavedClicked: page.openSettings(1)
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
