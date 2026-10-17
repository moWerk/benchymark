// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY LIGHT: two 3DBenchy wireframes one above the other, turning
// opposite ways, each drawn 10 times on the same spot.
// SailfishOS: projected in C++ (Wireframe), drawn as line geometry.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    Wireframe {
        id: boat
        anchors.fill: parent
        copies: 2
        stack: 10
        counterRotate: true
        NumberAnimation on angle {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
            running: boat.visible
        }
    }
}
