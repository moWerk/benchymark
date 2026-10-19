// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY LARGE (key BENCHY-LIGHT): two 3DBenchy wireframes one above the other, turning
// opposite ways, each drawn 10 times on the same spot.
// SailfishOS: projected in C++ (Wireframe), drawn as line geometry.
import QtQuick 2.6
import Benchymark 1.0
import "Motion.js" as Motion

Item {
    id: stage
    anchors.fill: parent

    // the boats drawn per frame, the same on every device (2.2); the score
    // boats per second
    property int load: 320
    property real t: 0
    readonly property bool perPixel: false
    //% "boats/s"
    readonly property string unit: qsTrId("id-unit-boats")

    Wireframe {
        id: boat
        anchors.fill: parent
        copies: 2
        stack: Math.max(1, stage.load / 2)
        counterRotate: true
        angle: 360 * Motion.cycle(stage.t, 4)
    }
}
