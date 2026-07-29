// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// BENCHY: 3DBenchy as a rotating wireframe, projected in QML.
//
// QtQuick3D is absent on these images (checked), so this file IS the
// renderer: every frame it rotates the vertices about the model's own
// vertical axis, projects them through a perspective divide, and hands six
// point arrays to six PathPolylines. The mesh arrives pre-welded and chained
// into strips by tools/stl_to_qml_mesh.py, so the watch pays only for
// rotate → project → stroke.
//
// ONE file serves both phases: `lite` picks the 438-vertex mesh over the
// 1118-vertex one. Same code path, so the pair measures how frame time scales
// with segment count and nothing else.
//
// 3DBenchy is public domain (NTI Group, 2025-02-14); credit to Creative
// Tools / NTI.

import QtQuick
import QtQuick.Shapes
import "../benchy-mesh.js" as Mesh
import "../benchy-mesh-lite.js" as MeshLite

Item {
    id: phase

    property var bench
    // Which boat: the decimated one, or the whole hull.
    property bool lite: false
    // How many of the six strips to draw — the dial for how brutal this is.
    // Lower it if the phase is a slideshow rather than a rotation.
    property int strips: 6
    property real angle: 0

    anchors.fill: parent

    onAngleChanged: phase.project()

    function project() {
        var M = phase.lite ? MeshLite : Mesh;
        var V = M.V, S = M.S;
        var a = phase.angle * Math.PI / 180;
        var ca = Math.cos(a), sa = Math.sin(a);
        var tilt = 0.42, ct = Math.cos(tilt), st = Math.sin(tilt);
        var cx = bench.width / 2, cy = bench.height / 2;
        var k = bench.maxSize * 0.00042;          // the +/-1000 cube to screen
        var dist = 2800;                          // perspective distance
        // pl* carry the points; bp* carry the start coordinate. A ShapePath
        // starts at startX/startY, so without setting it every strip would
        // trail a stray line back to the top-left corner.
        var lines = [pl0, pl1, pl2, pl3, pl4, pl5];
        var paths = [bp0, bp1, bp2, bp3, bp4, bp5];
        for (var s = 0; s < lines.length; s++) {
            if (s >= phase.strips || s >= S.length) {
                lines[s].path = [];
                continue;
            }
            var idx = S[s], pts = [];
            for (var i = 0; i < idx.length; i++) {
                var o = idx[i] * 3;
                var x = V[o], y = V[o + 1], z = V[o + 2];
                // spin about the model's own vertical axis (Z up, print-bed
                // frame), then tilt the camera down onto it
                var rx = x * ca - y * sa;
                var ry = x * sa + y * ca;
                var depth = ry * ct - z * st;
                var up = ry * st + z * ct;
                var f = dist / (dist + depth);
                pts.push(Qt.point(cx + rx * k * f, cy - up * k * f));
            }
            lines[s].path = pts;
            if (pts.length) {
                paths[s].startX = pts[0].x;
                paths[s].startY = pts[0].y;
            }
        }
    }

    Shape {
        id: benchyShape

        anchors.fill: parent
        visible: (bench.activePhase === 12 || bench.activePhase === 13) && bench.awake
        onVisibleChanged: if (visible) bench.projectBenchy()

        ShapePath { id: bp0; fillColor: "#2258a6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#58a6ff"; strokeWidth: 1; PathPolyline { id: pl0 } }
        ShapePath { id: bp1; fillColor: "#2258a6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#58a6ff"; strokeWidth: 1; PathPolyline { id: pl1 } }
        ShapePath { id: bp2; fillColor: "#1e79c0ff"; fillRule: ShapePath.WindingFill; strokeColor: "#79c0ff"; strokeWidth: 1; PathPolyline { id: pl2 } }
        ShapePath { id: bp3; fillColor: "#1e79c0ff"; fillRule: ShapePath.WindingFill; strokeColor: "#79c0ff"; strokeWidth: 1; PathPolyline { id: pl3 } }
        ShapePath { id: bp4; fillColor: "#1aa5d6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#a5d6ff"; strokeWidth: 1; PathPolyline { id: pl4 } }
        ShapePath { id: bp5; fillColor: "#1aa5d6ff"; fillRule: ShapePath.WindingFill; strokeColor: "#a5d6ff"; strokeWidth: 1; PathPolyline { id: pl5 } }

        NumberAnimation on rotationDriver {
            from: 0
            to: 360
            duration: phase.lite ? 4000 : 6000
            loops: Animation.Infinite
            running: bench.awake
        }

        property real rotationDriver: 0

        onRotationDriverChanged: phase.angle = rotationDriver
    }
}
