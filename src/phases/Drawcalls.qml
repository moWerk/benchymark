// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// DRAWCALLS: unbatchable SVG icons in motion. Each Icon is a
// QQuickPaintedItem with its own texture, so they cannot batch — the cost is
// draw calls and state changes, not pixels.
//
// Loaded only while its phase runs, so nothing here exists — or is even
// parsed — until the phase arrives. `bench` is the run: geometry, palette,
// the awake flag and the clock. Set as an initial property by the Loader, so
// it is never null while bindings evaluate.

import QtQuick
import org.asteroid.controls
Item {
    id: phase

    property var bench

    anchors.fill: parent

    Item {
        id: iconStorm

        anchors.fill: parent

        Repeater {
            id: iconRep

            model: 96

            delegate: Icon {
                readonly property real a: index / 96 * 2 * Math.PI * 3
                readonly property real rad: bench.rootRadius * (0.18 + (index % 7) * 0.13)

                name: "ios-flash"
                width: bench.maxSize * 0.09
                height: width
                x: bench.width / 2 + rad * Math.cos(a + iconStorm.spin) - width / 2
                y: bench.height / 2 + rad * Math.sin(a + iconStorm.spin) - height / 2
            }

        }

        property real spin: 0

        NumberAnimation on spin {
            from: 0
            to: 2 * Math.PI
            duration: 3000
            loops: Animation.Infinite
            running: bench.awake
        }

    }
}
