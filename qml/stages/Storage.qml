// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// STORAGE: 256 MB in 16 KB blocks, written and read back with O_DIRECT (the
// author's dd test), in the app's data directory, then deleted. Every block
// group of four is a cell of the grid: blue when written, gold when read. Ends when the
// read is through. Score: write and read MB/s.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    property real areaTop: 0
    property real areaBottom: height
    readonly property bool system: true
    readonly property bool selfTimed: true
    property string live: ""
    signal finished()

    readonly property int blocks: 16384    // 256 MB
    // four 16 KB blocks to a cell, so the cells are big enough to see (mo)
    readonly property int group: 4
    readonly property int cells: blocks / group
    readonly property real margin: Math.min(width, height) * 0.05
    // nine tenths of the free area, centred (mo, 2026-10-17)
    readonly property real w: (width - 2 * margin) * 0.9
    readonly property real h: (areaBottom - areaTop) * 0.9
    readonly property int cols: Math.max(1, Math.round(Math.sqrt(cells * w / h)))
    readonly property int rows: Math.ceil(cells / cols)
    readonly property real cell: Math.min(w / cols, h / rows)
    readonly property real x0: (width - cols * cell) / 2
    readonly property real y0: areaTop + (h - rows * cell) / 2

    Dots {
        id: dots
        anchors.fill: parent
        // the blocks meet, half a pixel over: a one pixel gap came out one
        // or two pixels wide once the fixed render size is scaled (mo)
        dotSize: stage.cell + 0.5
        capacity: 2 * stage.cells
    }

    StorageEngine {
        id: engine
        onPhaseChanged: if (phase === 3 || phase === -1) stage.finished()
    }

    Component.onCompleted: engine.start(blocks)
    Component.onDestruction: engine.stop()

    property int shown: 0
    property int shownPhase: 0
    Timer {
        interval: 33; repeat: true; running: true
        property int lastDone: 0
        property double lastT: Date.now()
        onTriggered: {
            var p = engine.phase
            if (p !== stage.shownPhase) { stage.shownPhase = p; stage.shown = 0; lastDone = 0 }
            if (p !== 1 && p !== 2) return
            var d = engine.done()
            // a cell lights when all its blocks are through
            var c = Math.floor(d / stage.group)
            var xy = []
            for (var i = stage.shown; i < c; i++)
                xy.push(stage.x0 + (i % stage.cols + 0.5) * stage.cell,
                        stage.y0 + (Math.floor(i / stage.cols) + 0.5) * stage.cell)
            if (xy.length) dots.addPoints(xy, p === 1 ? "#58a6ff" : "#f0c30e")
            stage.shown = c
            var now = Date.now()
            if (now - lastT >= 1000) {
                stage.live = (p === 1 ? qsTrId("id-writing") : qsTrId("id-reading")) + " · "
                        + Math.round((d - lastDone) * 16 / 1024 / ((now - lastT) / 1000)) + " MB/s"
                lastDone = d
                lastT = now
            }
        }
    }
    //% "Writing"
    readonly property string _w: qsTrId("id-writing")
    //% "Reading"
    readonly property string _r: qsTrId("id-reading")

    // one row, read / write (mo, 2026-10-17)
    function results() {
        var tag = engine.direct ? "" : " *"
        return [{ key: "STORAGE", name: qsTrId("id-stage-storage-rw"),
                  value: Math.round(engine.readMBs) + "/" + Math.round(engine.writeMBs),
                  unit: "MB/s" + tag }]
    }
    //% "Storage R/W"
    readonly property string _rw: qsTrId("id-stage-storage-rw")
}
