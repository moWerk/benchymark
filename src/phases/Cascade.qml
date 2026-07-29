// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// CASCADE: two counter-rotating trees, each a scale animation over many
// children, so every child's transform is recalculated every frame. One tree
// held a flat 60 everywhere and measured nothing.
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
        id: cascade

        anchors.fill: parent
        transformOrigin: Item.Center

        Repeater {
            id: cascRep

            model: 160

            delegate: Rectangle {
                readonly property real a: index / 160 * 2 * Math.PI * 5

                width: bench.maxSize * 0.06
                height: width
                radius: width * 0.3
                antialiasing: true
                color: bench.ramp[index % bench.ramp.length]
                opacity: 0.75
                x: bench.width / 2 + bench.rootRadius * (0.3 + (index % 5) * 0.16) * Math.cos(a) - width / 2
                y: bench.height / 2 + bench.rootRadius * (0.3 + (index % 5) * 0.16) * Math.sin(a) - height / 2
                rotation: index * 9
            }

        }

        SequentialAnimation on scale {
            running: bench.awake
            loops: Animation.Infinite
            NumberAnimation { from: 0.55; to: 1.25; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.25; to: 0.55; duration: 800; easing.type: Easing.InOutSine }
        }

    }

    Item {
        id: cascadeB

        anchors.fill: parent
        transformOrigin: Item.Center

        Repeater {
            id: cascBRep

            model: 160

            delegate: Rectangle {
                readonly property real a: -index / 160 * 2 * Math.PI * 4

                width: bench.maxSize * 0.045
                height: width
                radius: width * 0.5
                antialiasing: true
                color: bench.ramp[(index + 4) % bench.ramp.length]
                opacity: 0.55
                x: bench.width / 2 + bench.rootRadius * (0.22 + (index % 6) * 0.14) * Math.cos(a) - width / 2
                y: bench.height / 2 + bench.rootRadius * (0.22 + (index % 6) * 0.14) * Math.sin(a) - height / 2
                rotation: -index * 7
            }

        }

        SequentialAnimation on scale {
            running: bench.awake
            loops: Animation.Infinite
            NumberAnimation { from: 1.2; to: 0.5; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.5; to: 1.2; duration: 800; easing.type: Easing.InOutSine }
        }

        NumberAnimation on rotation {
            running: bench.awake
            from: 0
            to: -360
            duration: 9000
            loops: Animation.Infinite
        }

    }
}
