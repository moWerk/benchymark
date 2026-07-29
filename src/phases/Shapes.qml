// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// SHAPES: a vector path re-tessellated every frame.
//
// Loaded only while its phase runs, so nothing here exists — or is even
// parsed — until the phase arrives. `bench` is the run: geometry, palette,
// the awake flag and the clock. Set as an initial property by the Loader, so
// it is never null while bindings evaluate.

import QtQuick
import QtQuick.Shapes
Item {
    id: phase

    property var bench

    anchors.fill: parent

    Shape {
        id: spiro

        property real t: 0

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        NumberAnimation on t {
            from: 0
            to: 2 * Math.PI
            duration: 4000
            loops: Animation.Infinite
            running: bench.awake
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: "#7ee787"
            strokeWidth: bench.maxSize * 0.02
            capStyle: ShapePath.RoundCap
            startX: bench.width / 2
            startY: bench.height / 2 - bench.rootRadius

            PathCubic {
                x: bench.width / 2 + bench.rootRadius * Math.cos(spiro.t)
                y: bench.height / 2 + bench.rootRadius * Math.sin(spiro.t)
                control1X: bench.width / 2 + bench.rootRadius * 1.6 * Math.cos(spiro.t * 2)
                control1Y: bench.height / 2 - bench.rootRadius * 1.6 * Math.sin(spiro.t * 3)
                control2X: bench.width / 2 - bench.rootRadius * 1.6 * Math.sin(spiro.t * 3)
                control2Y: bench.height / 2 + bench.rootRadius * 1.6 * Math.cos(spiro.t * 2)
            }

            // Added control points: the phase held a flat 60 everywhere, so it
            // was measuring nothing (moWerk). More cubics per lobe multiply the
            // per-frame tessellation without widening the figure — the extra
            // points ride the same radius, so the silhouette barely changes.
            PathCubic {
                x: bench.width / 2 + bench.rootRadius * 0.95 * Math.cos(spiro.t * 3 + 2)
                y: bench.height / 2 + bench.rootRadius * 0.95 * Math.sin(spiro.t * 5 + 2)
                control1X: bench.width / 2 + bench.rootRadius * 1.15 * Math.sin(spiro.t * 5)
                control1Y: bench.height / 2 - bench.rootRadius * 1.15 * Math.cos(spiro.t * 3)
                control2X: bench.width / 2 - bench.rootRadius * 1.15 * Math.cos(spiro.t * 3)
                control2Y: bench.height / 2 + bench.rootRadius * 1.15 * Math.sin(spiro.t * 5)
            }

            PathCubic {
                x: bench.width / 2 + bench.rootRadius * 0.95 * Math.cos(spiro.t * 5 - 2)
                y: bench.height / 2 - bench.rootRadius * 0.95 * Math.sin(spiro.t * 3 - 2)
                control1X: bench.width / 2 - bench.rootRadius * 1.15 * Math.sin(spiro.t * 3)
                control1Y: bench.height / 2 + bench.rootRadius * 1.15 * Math.cos(spiro.t * 5)
                control2X: bench.width / 2 + bench.rootRadius * 1.15 * Math.cos(spiro.t * 5)
                control2Y: bench.height / 2 - bench.rootRadius * 1.15 * Math.sin(spiro.t * 3)
            }

            PathCubic {
                x: bench.width / 2
                y: bench.height / 2 - bench.rootRadius
                control1X: bench.width / 2 - bench.rootRadius * 1.4 * Math.cos(spiro.t * 3)
                control1Y: bench.height / 2 + bench.rootRadius * 1.4 * Math.sin(spiro.t * 2)
                control2X: bench.width / 2 + bench.rootRadius * 1.4 * Math.sin(spiro.t * 2)
                control2Y: bench.height / 2 - bench.rootRadius * 1.4 * Math.cos(spiro.t * 3)
            }

        }

        // Four more lobes at different harmonics — same geometry pipeline,
        // several times the tessellation per frame.
        ShapePath {
            fillColor: "transparent"
            strokeColor: "#56d364"
            strokeWidth: bench.maxSize * 0.014
            capStyle: ShapePath.RoundCap
            startX: bench.width / 2
            startY: bench.height / 2 + bench.rootRadius

            PathCubic {
                x: bench.width / 2 + bench.rootRadius * Math.sin(spiro.t * 1.5)
                y: bench.height / 2 + bench.rootRadius * Math.cos(spiro.t * 2.5)
                control1X: bench.width / 2 - bench.rootRadius * 1.7 * Math.cos(spiro.t * 4)
                control1Y: bench.height / 2 + bench.rootRadius * 1.7 * Math.sin(spiro.t * 2)
                control2X: bench.width / 2 + bench.rootRadius * 1.7 * Math.sin(spiro.t * 2)
                control2Y: bench.height / 2 - bench.rootRadius * 1.7 * Math.cos(spiro.t * 4)
            }

            // Added control points: the phase held a flat 60 everywhere, so it
            // was measuring nothing (moWerk). More cubics per lobe multiply the
            // per-frame tessellation without widening the figure — the extra
            // points ride the same radius, so the silhouette barely changes.
            PathCubic {
                x: bench.width / 2 + bench.rootRadius * 1.1 * Math.cos(spiro.t * 2 + 1)
                y: bench.height / 2 + bench.rootRadius * 1.1 * Math.sin(spiro.t * 3 + 1)
                control1X: bench.width / 2 + bench.rootRadius * 0.9 * Math.sin(spiro.t * 3)
                control1Y: bench.height / 2 - bench.rootRadius * 0.9 * Math.cos(spiro.t * 2)
                control2X: bench.width / 2 - bench.rootRadius * 0.9 * Math.cos(spiro.t * 2)
                control2Y: bench.height / 2 + bench.rootRadius * 0.9 * Math.sin(spiro.t * 3)
            }

            PathCubic {
                x: bench.width / 2 + bench.rootRadius * 1.1 * Math.cos(spiro.t * 3 - 1)
                y: bench.height / 2 - bench.rootRadius * 1.1 * Math.sin(spiro.t * 2 - 1)
                control1X: bench.width / 2 - bench.rootRadius * 0.9 * Math.sin(spiro.t * 2)
                control1Y: bench.height / 2 + bench.rootRadius * 0.9 * Math.cos(spiro.t * 3)
                control2X: bench.width / 2 + bench.rootRadius * 0.9 * Math.cos(spiro.t * 3)
                control2Y: bench.height / 2 - bench.rootRadius * 0.9 * Math.sin(spiro.t * 2)
            }

            PathCubic {
                x: bench.width / 2
                y: bench.height / 2 + bench.rootRadius
                control1X: bench.width / 2 + bench.rootRadius * 1.5 * Math.sin(spiro.t * 5)
                control1Y: bench.height / 2 - bench.rootRadius * 1.5 * Math.cos(spiro.t * 3)
                control2X: bench.width / 2 - bench.rootRadius * 1.5 * Math.cos(spiro.t * 3)
                control2Y: bench.height / 2 + bench.rootRadius * 1.5 * Math.sin(spiro.t * 5)
            }

        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: "#3fb950"
            strokeWidth: bench.maxSize * 0.01
            capStyle: ShapePath.RoundCap
            startX: bench.width / 2 - bench.rootRadius
            startY: bench.height / 2

            PathCubic {
                x: bench.width / 2 + bench.rootRadius * Math.cos(spiro.t * 3)
                y: bench.height / 2 - bench.rootRadius * Math.sin(spiro.t * 1.5)
                control1X: bench.width / 2 + bench.rootRadius * 1.9 * Math.sin(spiro.t)
                control1Y: bench.height / 2 + bench.rootRadius * 1.9 * Math.cos(spiro.t * 5)
                control2X: bench.width / 2 - bench.rootRadius * 1.9 * Math.cos(spiro.t * 5)
                control2Y: bench.height / 2 - bench.rootRadius * 1.9 * Math.sin(spiro.t)
            }

            PathCubic {
                x: bench.width / 2 - bench.rootRadius
                y: bench.height / 2
                control1X: bench.width / 2 - bench.rootRadius * 1.3 * Math.sin(spiro.t * 4)
                control1Y: bench.height / 2 - bench.rootRadius * 1.3 * Math.cos(spiro.t * 2)
                control2X: bench.width / 2 + bench.rootRadius * 1.3 * Math.cos(spiro.t * 2)
                control2Y: bench.height / 2 + bench.rootRadius * 1.3 * Math.sin(spiro.t * 4)
            }

        }

    }
}
