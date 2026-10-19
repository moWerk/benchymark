// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// ONE MILLION: JavaScript counts to one million, over and over, in a worker
// thread, one million per request (the author's 2016 bash counting loop). The counter races, and
// below it random dots fill the area, their colour moving on with every
// million, so new dots show over the old ones. Score: millions per second.
import QtQuick 2.6
import Benchymark 1.0
import "Ramp.js" as Ramp

Item {
    id: stage
    anchors.fill: parent

    property real areaTop: 0
    property real areaBottom: height
    readonly property bool system: true
    property string live: ""

    property int count: 0
    property int laps: 0
    property double t0: 0
    property double counted: 0    // steps counted, all millions
    property double countMs: 0    // the worker's own time for them

    readonly property real margin: Math.min(width, height) * 0.05
    readonly property real fieldTop: counterText.y + counterText.height + margin

    Text {
        id: counterText
        anchors.horizontalCenter: parent.horizontalCenter
        y: stage.areaTop
        text: stage.count.toLocaleString(Qt.locale(), "f", 0)
        color: "white"
        font.pixelSize: stage.width * 0.16
        font.bold: true
    }

    Dots {
        id: dots
        anchors.fill: parent
        dotSize: Math.max(3, stage.width / 120)
        capacity: 60000
    }

    // the colour of the current million: around the ramp and the blues
    readonly property var palette: Ramp.colors.concat(["#a5d6ff", "#79c0ff", "#58a6ff", "#b040ff", "#ff5090"])

    WorkerScript {
        id: worker
        source: "counter.js"
        onMessage: {
            stage.count = messageObject.count
            stage.laps = messageObject.lap
            stage.counted += 20000
            stage.countMs += messageObject.ms
            var xy = messageObject.xy
            var fw = stage.width - 2 * stage.margin
            var fh = stage.areaBottom - stage.fieldTop
            var pts = []
            for (var i = 0; i + 1 < xy.length; i += 2)
                pts.push(stage.margin + xy[i] * fw, stage.fieldTop + xy[i + 1] * fh)
            dots.addPoints(pts, stage.palette[messageObject.lap % stage.palette.length])
            // the next million, as long as the stage is on
            if (messageObject.done && stage.running)
                worker.sendMessage({ lap: messageObject.lap + 1 })
        }
    }

    property bool running: true
    Component.onCompleted: { t0 = Date.now(); worker.sendMessage({ lap: 0 }) }
    Component.onDestruction: running = false

    Timer {
        interval: 1000; repeat: true; running: true
        property double last: 0
        onTriggered: {
            var total = stage.laps * 1000000 + stage.count
            stage.live = ((total - last) / 1000000).toFixed(2) + " M/s"
            last = total
        }
    }

    // steps per second of the worker's own counting time; a run of 20000
    // can read 0 ms on a fast phone, so the sum over all runs counts
    function results() {
        var v = stage.countMs > 0 ? stage.counted / 1000 / stage.countMs : 0
        // the stage's wall time too, to check the worker's ms timing
        var wall = stage.counted / 1000 / Math.max(1, Date.now() - stage.t0)
        return [{ key: "ONE-MILLION", name: qsTrId("id-stage-million"),
                  value: Math.round(v * 100) / 100, unit: "M/s",
                  detail: { wall_m_per_s: Math.round(wall * 100) / 100, counted: stage.counted, count_ms: stage.countMs } }]
    }
}
