// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// MEMORY: memcpy between two 32 MB buffers in a thread (sysbench's memory
// test). A bar grows down from the top along an axis, the amount copied.
// Score: MB/s.
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

    MemoryEngine { id: engine }

    property double t0: 0
    property double copied: 0          // MB
    property double axisMax: 0         // MB, fixed after the first second
    Component.onCompleted: { engine.start(); t0 = Date.now() }
    Component.onDestruction: engine.stop()

    // a round number of GB (or MB) at or above v
    function nice(v) {
        var steps = [1, 2, 2.5, 5, 10]
        var p = Math.pow(10, Math.floor(Math.log(v) / Math.LN10))
        for (var i = 0; i < steps.length; i++)
            if (steps[i] * p >= v) return steps[i] * p
        return 10 * p
    }
    function label(mb) {
        return mb >= 1024 ? (mb / 1024).toFixed(mb % 1024 ? 1 : 0) + " GB" : Math.round(mb) + " MB"
    }

    Timer {
        interval: 33; repeat: true; running: true
        property double lastMb: 0
        property double lastT: 0
        onTriggered: {
            stage.copied = engine.copied() / 1048576
            var now = Date.now()
            if (stage.axisMax === 0 && now - stage.t0 > 1000)
                // ten seconds at the first second's pace, and some room
                stage.axisMax = stage.nice(stage.copied / ((now - stage.t0) / 1000) * 11)
            if (now - lastT >= 1000) {
                stage.live = Math.round((stage.copied - lastMb) / ((now - lastT) / 1000)) + " MB/s"
                lastMb = stage.copied
                lastT = now
            }
        }
    }

    // not `top`: every Item has that (an anchor line), declaring it again
    // stopped the stage from loading
    readonly property real barTop: areaTop
    readonly property real span: areaBottom - areaTop
    readonly property real fill: axisMax > 0 ? Math.min(1, copied / axisMax) : 0

    // the axis: a line with two marks, half and full
    Rectangle {
        x: stage.width * 0.3
        y: stage.barTop
        width: 2
        height: stage.span
        color: "white"
        opacity: 0.4
    }
    Repeater {
        model: [0.5, 1.0]
        Item {
            y: stage.barTop + stage.span * modelData
            Rectangle { x: stage.width * 0.3 - 12; width: 24; height: 2; color: "white"; opacity: 0.6 }
            Text {
                anchors.right: parent.left
                anchors.rightMargin: 0
                x: stage.width * 0.3 - 24 - width
                y: -height / 2
                text: stage.axisMax > 0 ? stage.label(stage.axisMax * modelData) : ""
                color: "white"
                opacity: 0.8
                font.pixelSize: stage.width * 0.045
            }
        }
    }

    // the bar, down from the top
    Rectangle {
        x: stage.width * 0.3 + 12
        y: stage.barTop
        width: stage.width * 0.45
        height: stage.span * stage.fill
        gradient: Gradient {
            GradientStop { position: 0.0; color: Ramp.colors[8] }
            GradientStop { position: 1.0; color: Ramp.colors[0] }
        }
    }
    Text {
        x: stage.width * 0.3 + 12 + stage.width * 0.45 + 12
        y: stage.barTop + stage.span * stage.fill - height / 2
        text: stage.label(stage.copied)
        color: "#f0c30e"
        font.pixelSize: stage.width * 0.045
    }

    function results() {
        var s = (Date.now() - t0) / 1000
        return [{ key: "MEMORY", name: qsTrId("id-stage-memory"),
                  value: Math.round(engine.copied() / 1048576 / s), unit: "MB/s" }]
    }
}
