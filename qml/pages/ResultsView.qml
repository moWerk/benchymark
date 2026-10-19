// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// One run's results, drawn from its JSON: the run that just ended and every
// saved one look the same (saved runs asked for on the forum, 2026-10-19).
// Shown on the page, and once more off screen for Share: the shared copy
// shows every system detail and no open description, whatever this viewer
// switched (mo, 2026-10-18), on a dark ground so the PNG is not transparent.
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Item {
    id: view
    property var run: null        // the run's JSON, parsed
    property bool shareMode: false
    // key -> { name, score }: the stage names and what each score counts
    property var stageInfo: ({})
    property string openResult: ""   // the row whose score line is open
    // this version's scene, to mark older runs (as MainPage's sceneVersion)
    property string currentScene: "sfos-2.2"

    width: parent ? parent.width : Screen.width
    height: resultColumn.height + Theme.paddingLarge

    ConfigurationValue {
        id: showScoreAbout
        key: "/apps/harbour-benchymark/showScoreAbout"
        defaultValue: true
    }
    // The system details, each one switchable in the settings (mo,
    // 2026-10-18), so a shared picture shows only what its owner wants.
    ConfigurationValue {
        id: hiddenDetails
        key: "/apps/harbour-benchymark/hiddenDetails"
        defaultValue: "[]"
    }
    readonly property var hiddenDetailKeys: {
        try { return JSON.parse(hiddenDetails.value) } catch (e) { return [] }
    }
    function showDetail(key) { return hiddenDetailKeys.indexOf(key) < 0 }

    // ── the run, unpacked ──
    readonly property var phases: run && run.phases ? run.phases : []
    readonly property var order: phases.map(function (p) { return p.phase })
    readonly property var results: {
        var r = {}
        for (var i = 0; i < phases.length; i++) {
            var p = phases[i]
            var info = stageInfo[p.phase]
            // runs of 1.x have fps, no score: shown as fps
            var oldFps = p.score === undefined && p.value === undefined && p.avg !== undefined && !p.unsupported
            r[p.phase] = { name: p.name || (info ? info.name : p.phase),
                           system: p.value !== undefined, value: p.value,
                           unit: oldFps ? "fps" : p.unit,
                           score: oldFps ? p.avg : p.score, unsupported: p.unsupported,
                           topped: p.topped === true, capped: p.capped === true,
                           partial: p.partial === true, slopeFailed: p.slope_failed === true,
                           noisy: p.noisy === true, overhead: p.overhead_ms }
        }
        return r
    }
    readonly property var temps: run && run.temperature ? run.temperature : []
    readonly property var batts: run && run.battery ? run.battery : []
    readonly property var clocks: run && run.clocks ? run.clocks : []
    readonly property var calibratedNow: phases.filter(function (p) { return p.calibrated_now === true })
                                               .map(function (p) { return p.phase })
    readonly property var recalibrateNext: run && run.recalibrate_next ? run.recalibrate_next : []
    readonly property var recalibrateHeavy: run && run.recalibrate_heavy ? run.recalibrate_heavy : []
    function flagged(f) { return order.filter(function (k) { return results[k] && results[k][f] }) }
    readonly property var cappedKeys: flagged("capped")
    readonly property var toppedKeys: flagged("topped")
    readonly property var partialKeys: flagged("partial")
    readonly property var singleKeys: flagged("slopeFailed")
    readonly property var noisyKeys: flagged("noisy")
    // the median of the stages' frame overhead, ms
    readonly property real overheadMs: {
        var v = order.map(function (k) { return results[k] ? results[k].overhead : undefined })
                     .filter(function (x) { return x !== undefined && x !== null && isFinite(x) })
                     .sort(function (x, y) { return x - y })
        return v.length ? v[Math.floor(v.length / 2)] : NaN
    }
    readonly property double runStarted: run && run.started ? Date.parse(run.started) : 0
    readonly property double runEnded: run && run.finished ? Date.parse(run.finished) : 0
    readonly property int brightnessAtStart: run && run.brightness_percent !== undefined ? run.brightness_percent : -1
    readonly property bool brightnessSet: run ? run.brightness_set_by_run === true : false

    readonly property var detailKeys: ["kernel", "device", "time", "os", "gpu", "resolution", "render", "gl", "mode"]
    readonly property var detailTitles: ({
        //% "Kernel"
        kernel: qsTrId("id-detail-kernel"),
        //% "Device"
        device: qsTrId("id-detail-device"),
        //% "Date and runtime"
        time: qsTrId("id-detail-time"),
        //% "SailfishOS version"
        os: qsTrId("id-detail-os"),
        //% "GPU"
        gpu: qsTrId("id-detail-gpu"),
        //% "Screen resolution"
        resolution: qsTrId("id-detail-resolution"),
        //% "Render size"
        render: qsTrId("id-detail-render"),
        //% "OpenGL version"
        gl: qsTrId("id-detail-gl"),
        //% "Run mode"
        mode: qsTrId("id-detail-mode")
    })
    function modeName(m) {
        //% "Run one hour"
        return m === "hour" ? qsTrId("id-run-hour")
                //% "Run in loop"
                : m === "loop" ? qsTrId("id-run-loop")
                //% "Run once"
                : qsTrId("id-run-once")
    }
    function detailText(key) {
        if (!run) return ""
        switch (key) {
        // without its build tag: 5.4.233, not 5.4.233-android12-9-g9c…
        case "kernel": return run.kernel ? "Linux " + String(run.kernel).split("-")[0] : ""
        case "device": return run.device || ""
        case "time": return runStarted > 0 ? Qt.formatDateTime(new Date(runStarted), "yyyy-MM-dd hh:mm")
                                             + "  ·  " + clockText((runEnded - runStarted) / 1000) : ""
        case "os": return run.os || ""
        case "gpu": return run.gpu || ""
        case "resolution": return run.resolution ? String(run.resolution).replace("x", " × ") : ""
        //% "drawn at %1 × %2"
        case "render": return run.render_size ? qsTrId("id-render-size").arg(String(run.render_size).split("x")[0])
                                                                       .arg(String(run.render_size).split("x")[1]) : ""
        case "gl": return glText()
        //% "loop"
        case "mode": return !run.mode || run.mode === "once" ? "" : modeName(run.mode)
                            + (run.loops > 0 ? "  ·  " + qsTrId("id-loop-short") + " × " + run.loops : "")
        }
        return ""
    }
    // for the settings page: each detail with what it shows now
    function detailList() {
        return detailKeys.map(function (k) {
            var v = detailText(k)
            return { key: k, title: detailTitles[k],
                     //% "of the last run"
                     value: v !== "" ? v : k === "time" ? qsTrId("id-detail-last-run")
                            //% "only when not Run once"
                            : k === "mode" ? qsTrId("id-detail-mode-once") : "" }
        })
    }
    // "OpenGL ES 3.2  ·  GLSL ES 3.20" without the driver's build string.
    // Functions, not bindings: the share copy, made with its run already
    // set, read these bindings while they were still pending and warned of
    // a binding loop (night audit).
    function glText() {
        if (!run || !run.gl_version) return ""
        var gl = String(run.gl_version).match(/OpenGL ES \d+\.\d+/)
        var sl = String(run.glsl_version || "").match(/GLSL ES \d+\.\d+/)
        return (gl ? gl[0] : run.gl_version) + "  ·  " + (sl ? sl[0] : (run.glsl_version || ""))
    }
    readonly property string infoText: {
        var lines = []
        var d = function (k) { return shareMode || showDetail(k) ? detailText(k) : "" }
        if (d("os") !== "") lines.push(d("os"))
        var gpuLine = [d("gpu"), d("resolution")].filter(function (t) { return t !== "" })
        if (gpuLine.length) lines.push(gpuLine.join("  ·  "))
        ;["render", "gl", "mode"].forEach(function (k) { if (d(k) !== "") lines.push(d(k)) })
        return lines.join("\n")
    }
    function scoreText(v) { return v >= 100 ? String(Math.round(v)) : v.toFixed(1) }
    function clockText(seconds) {
        var t = Math.max(0, Math.round(seconds))
        var two = function (n) { return (n < 10 ? "0" : "") + n }
        return Math.floor(t / 3600) + ":" + two(Math.floor(t / 60) % 60) + ":" + two(t % 60)
    }
    function scoreAboutOf(key) { return stageInfo[key] ? stageInfo[key].score : "" }

    // The shared picture always has a dark ground, so on a light ambience
    // it takes fixed light colours; on the page the theme's colours, and the
    // graphs' frames and labels follow them (night audit: white on light).
    readonly property bool fixedColours: shareMode && Theme.colorScheme !== Theme.LightOnDark
    readonly property color cPrimary: fixedColours ? "#ffffff" : Theme.primaryColor
    readonly property color cSecondary: fixedColours ? "#b3ffffff" : Theme.secondaryColor
    readonly property color cHighlight: fixedColours ? "#ffd27a" : Theme.highlightColor
    readonly property color cSecHighlight: fixedColours ? "#c8ffd27a" : Theme.secondaryHighlightColor
    function lineColor(alpha) { return Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, alpha) }

    Rectangle {
        anchors.fill: parent
        color: "#0d1426"
        visible: view.shareMode
    }

    Column {
        id: resultColumn
        width: parent.width
        spacing: Theme.paddingMedium

        PageHeader {
            id: resultHeader
            title: "Benchymark"
            titleColor: view.cHighlight
            description: view.run && view.run.version ? "v" + view.run.version : ""

            // the free space left of the title: the kernel, always short,
            // the device, the time of the run (mo, 2026-10-18)
            Column {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                // up to the title, measured: a fixed share ran under it on
                // the XA2's larger font (seen in a shared picture)
                width: parent.width - titleMetrics.width - 3 * Theme.horizontalPageMargin
                TextMetrics {
                    id: titleMetrics
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: Theme.fontFamilyHeading
                    text: "Benchymark"
                }
                Repeater {
                    // when the run was taken, and how long it ran, last
                    model: ["kernel", "device", "time"]
                    Label {
                        width: parent.width
                        visible: (view.shareMode || view.showDetail(modelData)) && text !== ""
                        text: view.detailText(modelData)
                        color: view.cSecondary
                        // a long device name or the runtime shrinks to fit
                        // before it fades (the XA2's larger font)
                        font.pixelSize: Theme.fontSizeSmall
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeTiny
                        truncationMode: TruncationMode.Fade
                    }
                }
            }
        }
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
            // one fact a line, named, so the OS version is not read as the
            // kernel's (a reader on Telegram, 2026-10-18): OS, GPU and
            // resolution, GL, date; kernel and device sit in the header
            // GPU and screen resolution share a line when both are shown
            visible: view.infoText !== ""
            text: view.infoText
            color: view.cSecondary
            font.pixelSize: Theme.fontSizeSmall
        }

        Item { width: 1; height: Theme.paddingLarge }

        // One table: the stage (and what its score counts, if switched on)
        // and the score with its unit (mo, 2026-10-18).
        // Graphics rows first, then a gap, then the system rows.
        Repeater {
            readonly property var gfx: view.order.filter(function (k) { return view.results[k] && !view.results[k].system })
            readonly property var sys: view.order.filter(function (k) { return view.results[k] && view.results[k].system })
            model: view.order.length === 0 ? []
                   : [{ head: true }].concat(gfx, gfx.length > 0 && sys.length > 0 ? [{ gap: true }] : [], sys)
            Item {
                id: tableRow
                x: Theme.horizontalPageMargin
                width: view.width - 2 * Theme.horizontalPageMargin
                height: modelData.gap ? Theme.paddingLarge : nameColumn.height + Theme.paddingSmall
                readonly property bool head: modelData.head === true
                readonly property var r: head || modelData.gap ? null : view.results[modelData] || null
                readonly property real col: width / 7
                readonly property string about: r ? view.scoreAboutOf(modelData) : ""
                // as on the start page: a tap opens what the score counts,
                // one row at a time (mo, 2026-10-18: all at once cluttered)
                readonly property bool open: r !== null && !view.shareMode && view.openResult === modelData
                readonly property bool canOpen: r !== null && about !== ""
                        && (showScoreAbout.value === true || showScoreAbout.value === "true")
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                clip: true
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    enabled: tableRow.canOpen
                    onClicked: view.openResult = tableRow.open ? "" : modelData
                }
                Column {
                    id: nameColumn
                    visible: !modelData.gap
                    width: tableRow.col * 3.8
                    Label {
                        id: nameLabel
                        width: parent.width
                        //% "Stage"
                        text: tableRow.r ? tableRow.r.name : qsTrId("id-col-stage")
                        // a long name shrinks a little before it fades (the XA2)
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeSmall
                        color: !tableRow.r ? view.cSecHighlight
                               : (rowArea.pressed && rowArea.containsMouse) || tableRow.open
                               ? view.cHighlight : view.cPrimary
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        visible: tableRow.open && tableRow.canOpen
                        text: tableRow.about
                        wrapMode: Text.Wrap
                        color: view.cSecondary
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
                // the score, and its unit apart and dimmed (mo, 2026-10-18)
                Label {
                    visible: !modelData.gap
                    x: tableRow.col * 3.8
                    y: nameLabel.baselineOffset - baselineOffset
                    width: tableRow.col * 1.4
                    horizontalAlignment: Text.AlignRight
                    // seven digits or "1234/567" shrink rather than run left
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: Theme.fontSizeExtraSmall
                    //% "score"
                    text: tableRow.head ? qsTrId("id-col-score")
                          : !tableRow.r ? ""
                          : tableRow.r.system ? tableRow.r.value
                          : tableRow.r.score === undefined ? "–"
                          : view.scoreText(tableRow.r.score)
                    color: tableRow.head ? view.cSecHighlight : view.cHighlight
                    font.pixelSize: tableRow.head ? Theme.fontSizeSmall : Theme.fontSizeMedium
                }
                Label {
                    visible: !modelData.gap && !tableRow.head
                    x: tableRow.col * 5.2 + Theme.paddingSmall
                    y: nameLabel.baselineOffset - baselineOffset
                    width: tableRow.col * 1.8 - Theme.paddingSmall
                    text: tableRow.r && tableRow.r.unit ? tableRow.r.unit : ""
                    color: view.cSecondary
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            visible: view.order.some(function (k) { return view.results[k] && String(view.results[k].unit).indexOf("*") >= 0 })
            wrapMode: Text.Wrap
            //% "* without O_DIRECT: the read may come from the cache"
            text: qsTrId("id-no-direct")
            color: view.cSecondary
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        // which loads this run found, and which it found too light
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            function names(keys) {
                return keys.map(function (k) { return view.results[k] ? view.results[k].name : k }).join(", ")
            }
            // what each mark says, one line each; the marks make a score
            // checkable before it is compared (night audit)
            readonly property var lines: {
                var l = []
                //% "Load found in this run: %1"
                if (view.calibratedNow.length) l.push(qsTrId("id-calibrated-now").arg(names(view.calibratedNow)))
                //% "Ran too light, found again next run: %1"
                if (view.recalibrateNext.length) l.push(qsTrId("id-recalibrate-next").arg(names(view.recalibrateNext)))
                //% "Ran too heavy, found again next run: %1"
                if (view.recalibrateHeavy.length) l.push(qsTrId("id-recalibrate-heavy").arg(names(view.recalibrateHeavy)))
                //% "Near the display's refresh rate, the score may be capped: %1"
                if (view.cappedKeys.length) l.push(qsTrId("id-flag-capped").arg(names(view.cappedKeys)))
                //% "At the heaviest load and still fast, the score is a lower bound: %1"
                if (view.toppedKeys.length) l.push(qsTrId("id-flag-topped").arg(names(view.toppedKeys)))
                //% "Stopped early, fewer seconds measured: %1"
                if (view.partialKeys.length) l.push(qsTrId("id-flag-partial").arg(names(view.partialKeys)))
                //% "Measured at one load only, the frame's own cost is in the score: %1"
                if (view.singleKeys.length) l.push(qsTrId("id-flag-single").arg(names(view.singleKeys)))
                //% "Mostly frame overhead, the score is less certain: %1"
                if (view.noisyKeys.length) l.push(qsTrId("id-flag-noisy").arg(names(view.noisyKeys)))
                //% "Every frame costs %1 ms besides the work (compositing, scaling to the screen); the scores leave it out"
                if (isFinite(view.overheadMs)) l.push(qsTrId("id-overhead").arg(view.overheadMs.toFixed(1)))
                //% "Scene %1: these scores do not compare with %2"
                if (view.run && view.run.scene && view.run.scene !== view.currentScene)
                    l.push(qsTrId("id-flag-scene").arg(view.run.scene).arg(view.currentScene))
                return l
            }
            visible: lines.length > 0
            wrapMode: Text.Wrap
            text: lines.join("\n")
            color: view.cSecondary
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        // why a GPU buffer stage shows a dash
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            readonly property var why: view.order.filter(function (k) { return view.results[k] && view.results[k].unsupported })
                                                 .map(function (k) { return view.results[k].name + ": " + view.results[k].unsupported })
            visible: why.length > 0
            wrapMode: Text.Wrap
            //% "– cannot run on this GPU or driver"
            text: qsTrId("id-unsupported") + "\n" + why.join("\n")
            color: view.cSecondary
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        // the temperature over the run
        Item {
            width: parent.width
            height: tempGraph.visible ? tempHead.height + tempGraph.height + Theme.paddingLarge : 0
            visible: view.temps.length > 1
            // a title as the stages have, the figures below it
            Column {
                id: tempHead
                x: Theme.horizontalPageMargin
                y: Theme.paddingLarge
                width: parent.width - 2 * x
                Label {
                    //% "Temperature"
                    text: qsTrId("id-temperature")
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: view.tempSummary
                    color: view.cSecHighlight
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            Canvas {
                id: tempGraph
                anchors.top: tempHead.bottom
                anchors.topMargin: Theme.paddingSmall
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Theme.itemSizeHuge
                visible: view.temps.length > 1
                onVisibleChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var t = view.temps
                    if (t.length < 2) return
                    var lo = 1e9, hi = -1e9
                    for (var i = 0; i < t.length; i++) { lo = Math.min(lo, t[i][1]); hi = Math.max(hi, t[i][1]) }
                    lo = Math.floor(lo - 1); hi = Math.ceil(hi + 1)
                    var span = t[t.length - 1][0] - t[0][0] || 1
                    var X = function (s) { return (s - t[0][0]) / span * width }
                    var Y = function (c) { return height - (c - lo) / (hi - lo) * height }
                    ctx.strokeStyle = view.lineColor(0.15)
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
                    ctx.fillStyle = view.lineColor(0.6)
                    ctx.font = Math.round(Theme.fontSizeExtraSmall) + "px sans-serif"
                    ctx.fillText(hi + " °C", 6, Theme.fontSizeExtraSmall + 2)
                    ctx.fillText(lo + " °C", 6, height - 6)
                }
                Connections { target: view; onRunChanged: tempGraph.requestPaint() }
            }
        }

        // the battery over the run: the charge, and the power drawn under it
        Item {
            width: parent.width
            height: battGraph.visible ? battHead.height + battGraph.height + Theme.paddingLarge : 0
            visible: view.batts.length > 1
            Column {
                id: battHead
                x: Theme.horizontalPageMargin
                y: Theme.paddingLarge
                width: parent.width - 2 * x
                Label {
                    //% "Battery"
                    text: qsTrId("id-battery")
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: view.battSummary
                    color: view.cSecHighlight
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            Canvas {
                id: battGraph
                anchors.top: battHead.bottom
                anchors.topMargin: Theme.paddingSmall
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Theme.itemSizeHuge
                visible: view.batts.length > 1
                onVisibleChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var b = view.batts
                    if (b.length < 2) return
                    var lo = 100, hi = 0, wMax = 0
                    for (var i = 0; i < b.length; i++) {
                        lo = Math.min(lo, b[i][1]); hi = Math.max(hi, b[i][1])
                        if (b[i][2] !== null) wMax = Math.max(wMax, b[i][2])
                    }
                    lo = Math.max(0, lo - 1); hi = Math.min(100, hi + 1)
                    wMax = Math.ceil(wMax) || 1
                    var span = b[b.length - 1][0] - b[0][0] || 1
                    var X = function (s) { return (s - b[0][0]) / span * width }
                    ctx.strokeStyle = view.lineColor(0.15)
                    ctx.lineWidth = 1
                    ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
                    // the power, thin and amber, scaled to its own maximum
                    ctx.strokeStyle = Qt.rgba(1.0, 0.7, 0.25, 0.55)
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    var started = false
                    for (var k = 0; k < b.length; k++) {
                        if (b[k][2] === null) continue
                        var wy = height - b[k][2] / wMax * height
                        if (started) ctx.lineTo(X(b[k][0]), wy)
                        else { ctx.moveTo(X(b[k][0]), wy); started = true }
                    }
                    ctx.stroke()
                    // the charge, thick and green
                    ctx.strokeStyle = Qt.rgba(0.45, 0.85, 0.45, 1)
                    ctx.lineWidth = Math.max(3, Theme.paddingSmall * 0.6)
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    for (var j = 0; j < b.length; j++) {
                        var y = height - (b[j][1] - lo) / (hi - lo) * height
                        if (j === 0) ctx.moveTo(X(b[j][0]), y)
                        else ctx.lineTo(X(b[j][0]), y)
                    }
                    ctx.stroke()
                    ctx.font = Math.round(Theme.fontSizeExtraSmall) + "px sans-serif"
                    ctx.fillStyle = view.lineColor(0.6)
                    ctx.fillText(hi + " %", 6, Theme.fontSizeExtraSmall + 2)
                    ctx.fillText(lo + " %", 6, height - 6)
                    ctx.fillStyle = Qt.rgba(1.0, 0.7, 0.25, 0.8)
                    ctx.textAlign = "right"
                    ctx.fillText(wMax + " W", width - 6, Theme.fontSizeExtraSmall + 2)
                    ctx.fillText("0 W", width - 6, height - 6)
                }
                Connections { target: view; onRunChanged: battGraph.requestPaint() }
            }
        }

        // the clocks over the run, red where the kernel throttled
        Item {
            width: parent.width
            height: clockGraph.visible ? clockHead.height + clockGraph.height + Theme.paddingLarge : 0
            visible: view.clocks.length > 1
            Column {
                id: clockHead
                x: Theme.horizontalPageMargin
                y: Theme.paddingLarge
                width: parent.width - 2 * x
                Label {
                    //% "Clocks"
                    text: qsTrId("id-clocks")
                }
                // the legend in the lines' colours, then the verdict (mo,
                // 2026-10-18: on the graph it sat on the data)
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    textFormat: Text.StyledText
                    text: "<font color=\"#66bfff\">CPU</font>"
                          + (view.clocks.some(function (r) { return r[2] !== null })
                             ? "  ·  <font color=\"#bf8cff\">GPU</font>" : "")
                          + "  ·  " + view.clockSummary
                    color: view.cSecHighlight
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            Canvas {
                id: clockGraph
                anchors.top: clockHead.bottom
                anchors.topMargin: Theme.paddingSmall
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Theme.itemSizeHuge
                visible: view.clocks.length > 1
                onVisibleChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var c = view.clocks
                    if (c.length < 2) return
                    var span = c[c.length - 1][0] - c[0][0] || 1
                    var X = function (s) { return (s - c[0][0]) / span * width }
                    var Y = function (p) { return height - Math.min(100, p) / 100 * height }
                    // throttled seconds as red bands behind the lines
                    ctx.fillStyle = Qt.rgba(0.9, 0.2, 0.2, 0.3)
                    for (var i = 1; i < c.length; i++)
                        if (c[i][3]) ctx.fillRect(X(c[i - 1][0]), 0, Math.max(1, X(c[i][0]) - X(c[i - 1][0])), height)
                    ctx.strokeStyle = view.lineColor(0.15)
                    ctx.lineWidth = 1
                    ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
                    var line = function (col, color, w) {
                        ctx.strokeStyle = color
                        ctx.lineWidth = w
                        ctx.beginPath()
                        var started = false
                        for (var j = 0; j < c.length; j++) {
                            if (c[j][col] === null) continue
                            if (started) ctx.lineTo(X(c[j][0]), Y(c[j][col]))
                            else { ctx.moveTo(X(c[j][0]), Y(c[j][col])); started = true }
                        }
                        ctx.stroke()
                    }
                    line(2, Qt.rgba(0.75, 0.55, 1.0, 0.7), 1.5)   // GPU, thin violet
                    line(1, Qt.rgba(0.4, 0.75, 1.0, 1), Math.max(3, Theme.paddingSmall * 0.6))   // CPU
                    ctx.font = Math.round(Theme.fontSizeExtraSmall) + "px sans-serif"
                    ctx.fillStyle = view.lineColor(0.6)
                    ctx.fillText("100 %", 6, Theme.fontSizeExtraSmall + 2)
                    ctx.fillText("0 %", 6, height - 6)
                }
                Connections { target: view; onRunChanged: clockGraph.requestPaint() }
            }
        }
    }

    // "58 → 55 %, 1.42 W avg, 0.30 Wh, −18 %/h, brightness 48 %", plus "charging" when
    // the charger was in at any point; %/h only from ten minutes on, below
    // that whole percent steps say little
    readonly property string battSummary: {
        if (batts.length < 2) return ""
        var first = batts[0], last = batts[batts.length - 1]
        var wSum = 0, wN = 0, charging = false
        for (var i = 0; i < batts.length; i++) {
            if (batts[i][2] !== null) { wSum += batts[i][2]; wN++ }
            if (batts[i][3] === "Charging" || batts[i][3] === "Full") charging = true
        }
        // the energy drawn: the power summed over the seconds between samples
        var wh = 0
        for (var k = 1; k < batts.length; k++)
            if (batts[k][2] !== null && batts[k - 1][2] !== null)
                wh += (batts[k][2] + batts[k - 1][2]) / 2 * (batts[k][0] - batts[k - 1][0]) / 3600
        var parts = [first[1] + " → " + last[1] + " %"]
        //% "avg"
        if (wN > 0) parts.push((wSum / wN).toFixed(2) + " W " + qsTrId("id-col-avg"))
        if (wN > 1) parts.push(wh.toFixed(2) + " Wh")
        var span = last[0] - first[0]
        if (span >= 600 && !charging)
            parts.push((Math.round((last[1] - first[1]) * 36000 / span) / 10).toString().replace("-", "−") + " %/h")
        //% "brightness"
        if (brightnessAtStart >= 0) parts.push(qsTrId("id-brightness") + " " + brightnessAtStart + " %"
                //% "set by the run"
                + (brightnessSet ? " (" + qsTrId("id-set-by-run") + ")" : ""))
        //% "charging"
        if (charging) parts.push(qsTrId("id-charging"))
        return parts.join(", ")
    }

    // "throttled 14 % of the run, first at 0:03:42" or "not throttled"
    readonly property string clockSummary: {
        if (clocks.length < 2) return ""
        var n = 0, first = -1
        for (var i = 0; i < clocks.length; i++)
            if (clocks[i][3]) { n++; if (first < 0) first = clocks[i][0] }
        //% "not throttled"
        if (n === 0) return qsTrId("id-not-throttled")
        //% "throttled %1 % of the run, first at %2"
        return qsTrId("id-throttled").arg(Math.round(n * 100 / clocks.length)).arg(clockText(first))
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
