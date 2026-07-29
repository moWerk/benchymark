// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// OVERDRAW: stacked translucent full-screen fills. The compositor blends
// every one of them every frame — pure fill rate, scaling with panel pixels,
// which is why results are also reported per megapixel.
//
// Loaded only while its phase runs, so nothing here exists — or is even
// parsed — until the phase arrives. `bench` is the run: geometry, palette and
// the awake flag, set as an initial property by the Loader so it is never
// null while bindings evaluate.

import QtQuick

Item {
    id: phase

    property var bench

    anchors.fill: parent

    Item {
        anchors.fill: parent

        Repeater {
            model: 24

            delegate: Rectangle {
                anchors.fill: parent
                color: index % 2 ? "#2000a0ff" : "#20ff5090"

                SequentialAnimation on opacity {
                    running: bench.awake
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.35; to: 0.9; duration: 600 + index * 90 }
                    NumberAnimation { from: 0.9; to: 0.35; duration: 600 + index * 90 }
                }

            }

        }

    }
}
