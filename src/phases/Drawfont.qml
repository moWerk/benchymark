// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// DRAWFONT: the same storm as COLOUR GLYPHS. Text normally batches through a
// glyph atlas; colour emoji carry their own bitmap/COLR data instead, so this
// sits between DRAWCALLS' per-item textures and ordinary batched text.
//
// Loaded only while its phase runs, so nothing here exists — or is even
// parsed — until the phase arrives. `bench` is the run: geometry, palette,
// the awake flag and the clock. Set as an initial property by the Loader, so
// it is never null while bindings evaluate.

import QtQuick
Item {
    id: phase

    property var bench

    anchors.fill: parent

    Item {
        id: glyphStorm

        anchors.fill: parent

        Repeater {
            id: glyphRep

            model: 96

            delegate: Text {
                readonly property real a: index / 96 * 2 * Math.PI * 3
                readonly property real rad: bench.rootRadius * (0.18 + (index % 7) * 0.13)

                text: "\uD83D\uDE80"                 // 🚀
                font.pixelSize: bench.maxSize * 0.075
                x: bench.width / 2 + rad * Math.cos(a + glyphStorm.spin) - width / 2
                y: bench.height / 2 + rad * Math.sin(a + glyphStorm.spin) - height / 2
            }

        }

        property real spin: 0

        NumberAnimation on spin {
            from: 0
            to: 2 * Math.PI
            duration: 5200
            loops: Animation.Infinite
            running: bench.awake
        }

    }
}
