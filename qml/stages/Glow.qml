// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY GLOW: the Benchy with a pulsing gold halo, a blur over the whole screen
// every frame. SailfishOS: stands in for the watch's ORBIT, whose halo is a
// Qt 6 MultiEffect; here QtGraphicalEffects' Glow does the blur.
import QtQuick 2.6
import QtGraphicalEffects 1.0
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the load is the number of glows stacked, each a blur over the whole
    // picture; the score counts rendered pixels x glows
    readonly property var ladder: [1, 2, 4, 8, 16, 32]
    property int load: 1
    readonly property bool perPixel: true
    //% "Mpx/s"
    readonly property string unit: qsTrId("id-unit-mpx")

    Wireframe {
        id: boat
        anchors.fill: parent
        visible: false
        NumberAnimation on angle {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
        }
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
        SequentialAnimation on spread {
            loops: Animation.Infinite
            NumberAnimation { from: 0.1; to: 0.45; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.45; to: 0.1; duration: 500; easing.type: Easing.InOutSine }
        }
    }
    }

    // the boat itself on top of its halo
    Wireframe {
        anchors.fill: parent
        angle: boat.angle
    }
}
