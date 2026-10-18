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
        samples: 45
        spread: 0.3
        // a wide halo, easy to see; 12-32 cost the C2 3 fps, so a bit narrower (mo)
        SequentialAnimation on radius {
            loops: Animation.Infinite
            NumberAnimation { from: 9; to: 22; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 22; to: 9; duration: 500; easing.type: Easing.InOutSine }
        }
    }
    }

    // the boat itself on top of its halo
    Wireframe {
        anchors.fill: parent
        angle: boat.angle
    }
}
