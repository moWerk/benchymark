// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY HEAVY: six 3DBenchy wireframes in a 2 x 3 grid, each turned a little
// further, each drawn `stack` times on the same spot.
// SailfishOS: projected in C++ (Wireframe), drawn as line geometry.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    Wireframe {
        id: boat
        anchors.fill: parent
        copies: 6
        stack: 20
        NumberAnimation on angle {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
            running: boat.visible
        }
    }
}
