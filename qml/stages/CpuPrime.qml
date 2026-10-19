// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// CPU PRIME: every core runs sysbench's cpu event (the primes up to 10000 by
// trial division), one event per cell of an Ulam spiral; a cell whose number
// is prime lights up, one colour per core. Full spiral: the next pass paints
// it again, brighter. Score: events per second, as sysbench reports it.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    property real areaTop: 0
    property real areaBottom: height
    readonly property bool system: true
    property string live: ""
    // 0: every core; the single core stage sets 1
    property int threadsWanted: 0
    property string resultKey: "CPU-PRIME"
    property string resultName: qsTrId("id-stage-cpu")

    readonly property real margin: Math.min(width, height) * 0.05
    readonly property real cell: Math.max(2, Math.round(Math.min(width - 2 * margin, areaBottom - areaTop) / 230))
    readonly property int side: Math.floor(Math.min(width - 2 * margin, areaBottom - areaTop) / cell) | 1

    Dots {
        id: dots
        anchors.fill: parent
        dotSize: stage.cell
        capacity: 60000
    }

    PrimeEngine { id: engine; target: dots; threadCount: stage.threadsWanted }

    property double t0: 0
    property double e0: 0
    Component.onCompleted: {
        engine.start(width / 2, (areaTop + areaBottom) / 2, cell, side)
        t0 = Date.now()
    }
    Component.onDestruction: engine.stop()

    Timer {
        interval: 1000; repeat: true; running: true
        property double last: 0
        onTriggered: {
            var e = engine.events()
            stage.live = Math.round(e - last) + " events/s · " + engine.threads
                         + (engine.threads === 1 ? " thread" : " threads")
            last = e
            // counted from the first second on: thread start and the clock
            // ramp stay out (night audit)
            if (stage.e0 === 0) { stage.e0 = Math.max(1, e); stage.t1 = Date.now() }
        }
    }
    property double t1: 0

    function results() {
        var now = Date.now()
        var e = engine.events()
        // stopped within the first second: from the start
        var rate = stage.t1 > 0 && now - stage.t1 > 500 ? (e - stage.e0) * 1000 / (now - stage.t1)
                                                         : e * 1000 / Math.max(1, now - stage.t0)
        return [{ key: stage.resultKey, name: stage.resultName,
                  value: Math.round(rate), unit: "events/s", threads: engine.threads }]
    }
}
