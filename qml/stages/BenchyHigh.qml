// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY SMALL (key BENCHY-HEAVY): six 3DBenchy wireframes in a 2 x 3 grid, each turned a little
// further, each drawn `stack` times on the same spot.
// SailfishOS: projected in C++ (Wireframe), drawn as line geometry.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the boats drawn per frame are the load (120 in 1.x), the score boats per second
    readonly property var ladder: [30, 60, 120, 240, 480, 960, 1920, 3840]
    property int load: 120
    readonly property bool perPixel: false
    //% "boats/s"
    readonly property string unit: qsTrId("id-unit-boats")

    Wireframe {
        id: boat
        anchors.fill: parent
        copies: 6
        stack: Math.max(1, stage.load / 6)
        NumberAnimation on angle {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
            running: boat.visible
        }
    }
}
