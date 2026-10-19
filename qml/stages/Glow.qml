// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY GLOW: the Benchy with a pulsing gold halo, a blur over the whole screen
// every frame. SailfishOS: stands in for the watch's ORBIT, whose halo is a
// Qt 6 MultiEffect; here QtGraphicalEffects' Glow does the blur.
import QtQuick 2.6
import QtGraphicalEffects 1.0
import Benchymark 1.0
import "Motion.js" as Motion

Item {
    id: stage
    anchors.fill: parent

    // the glows stacked, each a blur over the whole picture, the same on
    // every device (2.2); the score counts rendered pixels x glows
    property int load: 2
    property real t: 0
    readonly property bool perPixel: true
    //% "Mpx/s"
    readonly property string unit: qsTrId("id-unit-mpx")

    Wireframe {
        id: boat
        anchors.fill: parent
        visible: false
        angle: 360 * Motion.cycle(stage.t, 4)
    }

    Repeater {
        model: stage.load
    Glow {
        width: boat.width
        height: boat.height
        source: boat
        color: "#f0c30e"
        // A fixed radius, the halo pulses through its spread instead: an
        // animated radius rebuilt the blur shader (its weights are baked in)
        // and resized two textures per glow every frame, a cost that did not
        // grow with the load and differed per driver (night audit, 2026-10-19).
        // Radius 22 with 45 samples is the blur's own fast path.
        radius: 22
        samples: 45
        spread: Motion.swing(stage.t, 0.1, 0.45, 0.5)
    }
    }

    // the boat itself on top of its halo
    Wireframe {
        anchors.fill: parent
        angle: boat.angle
    }
}
