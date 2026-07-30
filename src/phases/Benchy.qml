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
// ONE mesh. The 1118-vertex version was dropped — barely distinguishable from
// the decimated one and so slow to instantiate that its phase expired before
// it drew (moWerk) — and carrying it unused cost 30 KB in the package plus the
// parse on every load.
//
// The STL itself is never shipped: tools/stl_to_qml_mesh.py reads it once on
// the host and emits the integer coordinate table below it.
//
// 3DBenchy is public domain (NTI Group, 2025-02-14); credit to Creative
// Tools / NTI.

import QtQuick
import QtQuick.Shapes
import "../benchy-mesh.js" as Mesh

Item {
    id: phase

    property var bench
    // How many of the six strips to draw — the dial for how brutal this is.
    // Lower it if the phase is a slideshow rather than a rotation.
    property int strips: 6
    property real angle: 0

    anchors.fill: parent

    onAngleChanged: phase.project()

    function project() {
        var M = Mesh;
        var V = M.V, S = M.S;
        var a = phase.angle * Math.PI / 180;
        var ca = Math.cos(a), sa = Math.sin(a);
        var tilt = 0.42, ct = Math.cos(tilt), st = Math.sin(tilt);
        var cx = bench.width / 2, cy = bench.height / 2;
        var k = bench.maxSize * 0.00042;          // the +/-1000 cube to screen
        var dist = 2800;                          // perspective distance
        var lines = [pl0, pl1, pl2, pl3, pl4, pl5];
        for (var b = 0; b < lines.length; b++) {
            if (b >= phase.strips || b >= S.length) {
                lines[b].paths = [];
                continue;
            }
            // S[bucket][chain][vertex]: the chains stay SEPARATE. Concatenated
            // into one polyline they forced a stroke from the end of each to
            // the start of the next, and on this geometry those joins crossed
            // the whole model. PathMultiline draws independent polylines in one
            // path, so the joins do not exist to be minimised.
            var bucket = S[b], out = [];
            for (var c = 0; c < bucket.length; c++) {
                var idx = bucket[c], pts = [];
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
                if (pts.length > 1)
                    out.push(pts);
            }
            lines[b].paths = out;
        }
    }

    Shape {
        id: benchyShape

        anchors.fill: parent
        onVisibleChanged: if (visible) phase.project()

        ShapePath { fillColor: "transparent"; strokeColor: "#58a6ff"; strokeWidth: 1; PathMultiline { id: pl0 } }
        ShapePath { fillColor: "transparent"; strokeColor: "#58a6ff"; strokeWidth: 1; PathMultiline { id: pl1 } }
        ShapePath { fillColor: "transparent"; strokeColor: "#79c0ff"; strokeWidth: 1; PathMultiline { id: pl2 } }
        ShapePath { fillColor: "transparent"; strokeColor: "#79c0ff"; strokeWidth: 1; PathMultiline { id: pl3 } }
        ShapePath { fillColor: "transparent"; strokeColor: "#a5d6ff"; strokeWidth: 1; PathMultiline { id: pl4 } }
        ShapePath { fillColor: "transparent"; strokeColor: "#a5d6ff"; strokeWidth: 1; PathMultiline { id: pl5 } }

        NumberAnimation on rotationDriver {
            from: 0
            to: 360
            duration: 4000
            loops: Animation.Infinite
            running: bench.awake
        }

        property real rotationDriver: 0

        onRotationDriverChanged: phase.angle = rotationDriver
    }
}
