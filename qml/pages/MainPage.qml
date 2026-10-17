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
import Sailfish.Share 1.0

Page {
    id: page
    allowedOrientations: Orientation.Portrait

    // Stamped into every result. Different loads on a different renderer
    // than the watch's scene 0.6, so the numbers are not comparable.
    readonly property string sceneVersion: "sfos-1.0"
    readonly property int stageSeconds: 10    // a timed stage, measured
    readonly property int gapSeconds: 2      // between stages

    // In the order that reads best: the bright graphics first, text last,
    // then the system stages, storage at the very end (mo, 2026-10-17).
    // `about` is the one-sentence manual shown under the name on a tap.
    readonly property var stages: [
        //% "Benchy light"
        { name: qsTrId("id-stage-benchy-light"), key: "BENCHY-LIGHT", file: "BenchyLow",
          //% "Two 3DBenchy wireframes turning, each drawn ten times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU."
          about: qsTrId("id-about-benchy-light") },
        //% "Benchy heavy"
        { name: qsTrId("id-stage-benchy-heavy"), key: "BENCHY-HEAVY", file: "BenchyHigh",
          //% "Six boats, each drawn twenty times: 120 wireframes every frame, much more geometry than the picture shows."
          about: qsTrId("id-about-benchy-heavy") },
        //% "Benchy glow"
        { name: qsTrId("id-stage-glow"), key: "BENCHY-GLOW", file: "Glow",
          //% "A Benchy with a pulsing golden halo: a blur over the whole screen every frame, the cost of soft effects."
          about: qsTrId("id-about-glow") },
        //% "Shader light"
        { name: qsTrId("id-stage-shader-light"), key: "SHADER-LIGHT", file: "ShaderLow",
          //% "A drifting noise field computed for every pixel: GPU arithmetic that grows with the screen size."
          about: qsTrId("id-about-shader-light") },
        //% "Shader heavy"
        { name: qsTrId("id-stage-shader-heavy"), key: "SHADER-HEAVY", file: "ShaderHigh",
          //% "The same idea warped twice over, about thirty noise lookups per pixel: the heaviest GPU load here."
          about: qsTrId("id-about-shader-heavy") },
        //% "Overdraw"
        { name: qsTrId("id-stage-overdraw"), key: "OVERDRAW", file: "Overdraw",
          //% "72 large translucent squares stacked and turning: every pixel is blended many times, raw fill rate."
          about: qsTrId("id-about-overdraw") },
        //% "Cascade"
        { name: qsTrId("id-stage-cascade"), key: "CASCADE", file: "Cascade",
          //% "A thousand rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents."
          about: qsTrId("id-about-cascade") },
        //% "Icon storm"
        { name: qsTrId("id-stage-icons"), key: "ICONS", file: "Icons",
          //% "Rockets and flashes on spiral arms, each icon drawn three times: many small images moving every frame."
          about: qsTrId("id-about-icons") },
        //% "Text scale"
        { name: qsTrId("id-stage-scale"), key: "SCALE", file: "Scale",
          //% "Numbers growing and shrinking by a scale transform: text drawn once and only resized, the cheap way."
          about: qsTrId("id-about-scale") },
        //% "Text reraster"
        { name: qsTrId("id-stage-reraster"), key: "RERASTER", file: "Reraster",
          //% "The same picture made by changing the font size, so every glyph is drawn anew each frame: what animated text size costs."
          about: qsTrId("id-about-reraster") },
        //% "CPU prime"
        { name: qsTrId("id-stage-cpu"), key: "CPU-PRIME", file: "CpuPrime",
          //% "All cores count primes as sysbench does; every finished count lights a cell of an Ulam spiral if its number is prime."
          about: qsTrId("id-about-cpu") },
        //% "CPU single core"
        { name: qsTrId("id-stage-cpu-single"), key: "CPU-SINGLE", file: "CpuPrimeSingle",
          //% "The same prime counting on one core only: next to the all core figure it shows what a single core does."
          about: qsTrId("id-about-cpu-single") },
        //% "Memory throughput"
        { name: qsTrId("id-stage-memory"), key: "MEMORY", file: "Memory",
          //% "Copies memory between two 32 MB buffers as fast as it can: how quickly the phone moves data in RAM."
          about: qsTrId("id-about-memory") },
        //% "One million"
        { name: qsTrId("id-stage-million"), key: "ONE-MILLION", file: "OneMillion",
          //% "JavaScript counts to one million, over and over: how fast the app's script engine runs a plain loop."
          about: qsTrId("id-about-million") },
        // last: off at first, an unticked switch among ticked ones looked odd
        //% "Storage performance"
        { name: qsTrId("id-stage-storage"), key: "STORAGE", file: "Storage",
          //% "Writes 256 MB in small blocks past the cache and reads it back. Off by default: it wears the flash a little every run."
          about: qsTrId("id-about-storage") }
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
    readonly property bool loop: loopConfig.value === true || loopConfig.value === "true"

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
    property double sampledAt: 0   // when the frame count was last taken

    DisplayBlanking { preventBlanking: page.view === "run" }

    // The temperature over the run, once a second, pauses included: with Run
    // in loop it is the thermal test (asked for on the forum, 2026-10-17).
    property var temps: []        // [seconds since start, degrees C]
    Timer {
        interval: 1000
        repeat: true
        running: page.view === "run"
        onTriggered: {
            var c = log.temperature()
            if (isNaN(c)) return
            var t = page.temps
            t.push([Math.round((Date.now() - page.runStarted) / 1000), Math.round(c * 10) / 10])
            page.temps = t
        }
    }

    function start() {
        var p = []
        for (var i = 0; i < stages.length; i++)
            if (isOn(stages[i].key)) p.push(i)
        if (p.length === 0) return
        plan = p
        temps = []
        results = ({})
        order = []
        loops = 0
        view = "run"
        runStarted = Date.now()
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
                              { areaTop: areaTop, areaBottom: areaBottom })
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
        record(st.key, { name: st.name, system: false, avg: Math.round(sum / samples.length),
                         min: min, worst: worst, seconds: samples.length })
    }

    function stop() {
        if (view !== "run") return
        if (!inGap) finishStage()
        stageLoader.source = ""
        step = -1
        inGap = false
        gapTimer.stop()
        gapEndTimer.stop()
        view = "results"
        writeLog()
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
            var s = page.samples
            s.push({ fps: fps, worst: worst })
            page.samples = s
            page.elapsed++
            var item = stageLoader.item
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

    function writeLog() {
        var phases = []
        for (var i = 0; i < order.length; i++) {
            var r = results[order[i]]
            if (r.system)
                phases.push({ phase: order[i], value: r.value, unit: r.unit })
            else
                phases.push({ phase: order[i], avg: r.avg, min: r.min, worst_tick_ms: r.worst,
                              samples: r.seconds })
        }
        log.write(JSON.stringify({
            scene: sceneVersion,
            version: appVersion,
            finished: new Date().toISOString(),
            resolution: Screen.width + "x" + Screen.height,
            device: deviceName,
            os: osName,
            soc: socName !== "" ? socName : undefined,
            gpu: FrameCounter.gpu,
            loop: loop,
            loops: loops,
            temperature: temps,
            phases: phases
        }, null, 1))
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
                    BackgroundItem {
                        id: nameArea
                        anchors.left: sw.right
                        anchors.right: parent.right
                        height: Math.max(sw.height, nameLabel.height + 2 * Theme.paddingSmall)
                        onClicked: page.openAbout = row.open ? -1 : index
                        Label {
                            id: nameLabel
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.horizontalPageMargin
                            text: modelData.name
                            color: nameArea.highlighted || row.open ? Theme.highlightColor : Theme.primaryColor
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
                text: page.loop
                      //% "Run in loop"
                      ? qsTrId("id-run-loop")
                      //% "Run once"
                      : qsTrId("id-run-once")
                color: loopArea.pressed ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                MouseArea {
                    id: loopArea
                    anchors.fill: parent
                    anchors.margins: -Theme.paddingLarge
                    onClicked: loopConfig.value = !page.loop
                }
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
        text: qsTrId("id-tap-to-stop")
        color: "white"
        opacity: 0.6
    }

    MouseArea {
        anchors.fill: parent
        enabled: page.view === "run"
        onClicked: page.stop()
    }

    // ── results ───────────────────────────────────────────────────────────────
    SilicaFlickable {
        anchors.fill: parent
        visible: page.view === "results"
        contentHeight: resultCapture.height + buttons.height + Theme.paddingLarge * 4

        // what Share saves as a picture: everything but the buttons, on a dark
        // ground so the PNG is not transparent
        Item {
            id: resultCapture
            width: parent.width
            height: resultColumn.height + Theme.paddingLarge
            Rectangle {
                anchors.fill: parent
                color: "#0d1426"
                visible: page.capturing
            }

        Column {
            id: resultColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Benchymark"
                description: "v" + appVersion
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                // model and OS version, resolution and GPU, date (mo, 2026-10-17)
                text: page.deviceName + "  ·  v" + page.osName.replace(/^Sailfish OS\s*/, "") + "\n"
                      + Screen.width + " × " + Screen.height + "  ·  " + FrameCounter.gpu + "\n"
                      + Qt.formatDateTime(new Date(page.runStarted), "yyyy-MM-dd hh:mm")
                      //% "loop"
                      + (page.loops > 0 ? "  ·  " + qsTrId("id-loop-short") + " × " + page.loops : "")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Item { width: 1; height: Theme.paddingLarge }

            // graphics: frames per second
            Repeater {
                // the header only when there is a graphics row under it
                readonly property var rows: page.order.filter(function (k) { return !page.results[k].system })
                model: rows.length > 0 ? [{ head: true }].concat(rows) : []
                Row {
                    x: Theme.horizontalPageMargin
                    readonly property var r: modelData.head ? null : page.results[modelData]
                    readonly property real col: (page.width - 2 * Theme.horizontalPageMargin) / 7
                    Label {
                        width: parent.col * 3
                        //% "Stage"
                        text: parent.r ? parent.r.name : qsTrId("id-col-stage")
                        color: parent.r ? Theme.primaryColor : Theme.secondaryHighlightColor
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.col * 4 / 3
                        horizontalAlignment: Text.AlignRight
                        //% "avg"
                        text: parent.r ? parent.r.avg : qsTrId("id-col-avg")
                        color: parent.r ? Theme.highlightColor : Theme.secondaryHighlightColor
                    }
                    Label {
                        width: parent.col * 4 / 3
                        horizontalAlignment: Text.AlignRight
                        //% "min"
                        text: parent.r ? parent.r.min : qsTrId("id-col-min")
                        color: parent.r ? Theme.primaryColor : Theme.secondaryHighlightColor
                    }
                    Label {
                        width: parent.col * 4 / 3
                        horizontalAlignment: Text.AlignRight
                        //% "worst ms"
                        text: parent.r ? parent.r.worst : qsTrId("id-col-worst")
                        color: parent.r ? Theme.primaryColor : Theme.secondaryHighlightColor
                        font.pixelSize: parent.r ? Theme.fontSizeMedium : Theme.fontSizeExtraSmall
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
                visible: systemRows.count > 0
            }

            // system: a value and its unit
            Repeater {
                id: systemRows
                model: page.order.filter(function (k) { return page.results[k].system })
                Row {
                    x: Theme.horizontalPageMargin
                    readonly property var r: page.results[modelData]
                    readonly property real col: (page.width - 2 * Theme.horizontalPageMargin) / 7
                    Label {
                        width: parent.col * 4
                        text: parent.r.name
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.col * 3
                        horizontalAlignment: Text.AlignRight
                        text: parent.r.value + " " + parent.r.unit
                        color: Theme.highlightColor
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                visible: page.order.some(function (k) { return String(page.results[k].unit).indexOf("*") >= 0 })
                wrapMode: Text.Wrap
                //% "* without O_DIRECT: the read may come from the cache"
                text: qsTrId("id-no-direct")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            // the temperature over the run
            Item {
                width: parent.width
                height: tempGraph.visible ? tempHead.height + tempGraph.height + Theme.paddingLarge : 0
                visible: page.temps.length > 1
                Label {
                    id: tempHead
                    x: Theme.horizontalPageMargin
                    y: Theme.paddingLarge
                    //% "Temperature"
                    text: qsTrId("id-temperature") + "  " + page.tempSummary
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                Canvas {
                    id: tempGraph
                    anchors.top: tempHead.bottom
                    anchors.topMargin: Theme.paddingSmall
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    height: Theme.itemSizeHuge
                    visible: page.temps.length > 1
                    onVisibleChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var t = page.temps
                        if (t.length < 2) return
                        var lo = 1e9, hi = -1e9
                        for (var i = 0; i < t.length; i++) { lo = Math.min(lo, t[i][1]); hi = Math.max(hi, t[i][1]) }
                        lo = Math.floor(lo - 1); hi = Math.ceil(hi + 1)
                        var span = t[t.length - 1][0] - t[0][0] || 1
                        var X = function (s) { return (s - t[0][0]) / span * width }
                        var Y = function (c) { return height - (c - lo) / (hi - lo) * height }
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.15)
                        ctx.lineWidth = 1
                        ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
                        // each segment coloured by its temperature, blue when cool,
                        // red when hot (a gradient stroke came out grey on Qt 5.6)
                        ctx.lineWidth = Math.max(3, Theme.paddingSmall * 0.6)
                        ctx.lineCap = "round"
                        for (var j = 1; j < t.length; j++) {
                            var f = ((t[j - 1][1] + t[j][1]) / 2 - lo) / (hi - lo)
                            ctx.strokeStyle = Qt.rgba(0.35 + 0.55 * f, 0.65 - 0.36 * f, 1.0 - 0.77 * f, 1)
                            ctx.beginPath()
                            ctx.moveTo(X(t[j - 1][0]), Y(t[j - 1][1]))
                            ctx.lineTo(X(t[j][0]), Y(t[j][1]))
                            ctx.stroke()
                        }
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.6)
                        ctx.font = Math.round(Theme.fontSizeExtraSmall) + "px sans-serif"
                        ctx.fillText(hi + " °C", 6, Theme.fontSizeExtraSmall + 2)
                        ctx.fillText(lo + " °C", 6, height - 6)
                    }
                    Connections { target: page; onViewChanged: tempGraph.requestPaint() }
                }
            }
        }
        }

        Row {
            id: buttons
            anchors.top: resultCapture.bottom
            anchors.topMargin: Theme.paddingLarge * 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingLarge
            Button {
                //% "Share"
                text: qsTrId("id-share")
                onClicked: page.shareResults()
            }
            Button {
                //% "Back"
                text: qsTrId("id-back")
                onClicked: page.view = "select"
            }
        }
    }

    // Share: the results as a picture in Pictures, then the share menu with it
    property bool capturing: false
    ShareAction {
        id: shareAction
        //% "Share results"
        title: qsTrId("id-share-results")
    }
    function shareResults() {
        capturing = true
        resultCapture.grabToImage(function (result) {
            capturing = false
            var file = StandardPaths.pictures + "/benchymark-"
                    + Qt.formatDateTime(new Date(runStarted), "yyyyMMdd-hhmmss") + ".png"
            if (!result.saveToFile(file)) {
                console.warn("Benchymark: could not save " + file)
                return
            }
            shareAction.resources = [file]
            shareAction.mimeType = "image/png"
            shareAction.trigger()
        })
    }

    readonly property string tempSummary: {
        if (temps.length < 2) return ""
        var peak = -1e9
        for (var i = 0; i < temps.length; i++) peak = Math.max(peak, temps[i][1])
        return temps[0][1] + " → " + temps[temps.length - 1][1] + " °C, "
                //% "peak"
                + qsTrId("id-peak") + " " + peak + " °C"
    }
}
