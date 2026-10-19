// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY LARGE (key BENCHY-LIGHT): two 3DBenchy wireframes one above the other, turning
// opposite ways, each drawn 10 times on the same spot.
// SailfishOS: projected in C++ (Wireframe), drawn as line geometry.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the boats drawn per frame are the load (20 in 1.x), the score boats per second
    readonly property var ladder: [10, 20, 40, 80, 160, 320, 640, 1280]
    property int load: 20
    readonly property bool perPixel: false
    //% "boats/s"
    readonly property string unit: qsTrId("id-unit-boats")

    Wireframe {
        id: boat
        anchors.fill: parent
        copies: 2
        stack: Math.max(1, stage.load / 2)
        counterRotate: true
        NumberAnimation on angle {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
            running: boat.visible
        }
    }
}
