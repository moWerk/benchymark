// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY SMALL (key BENCHY-HEAVY): six 3DBenchy wireframes in a 2 x 3 grid, each turned a little
// further, each drawn `stack` times on the same spot.
// SailfishOS: projected in C++ (Wireframe), drawn as line geometry.
import QtQuick 2.6
import Benchymark 1.0
import "Motion.js" as Motion

Item {
    id: stage
    anchors.fill: parent

    // the boats drawn per frame, the same on every device (2.2); the score
    // boats per second
    property int load: 640
    property real t: 0
    readonly property bool perPixel: false
    //% "boats/s"
    readonly property string unit: qsTrId("id-unit-boats")

    Wireframe {
        id: boat
        anchors.fill: parent
        copies: 6
        stack: Math.max(1, stage.load / 6)
        angle: 360 * Motion.cycle(stage.t, 4)
    }
}
