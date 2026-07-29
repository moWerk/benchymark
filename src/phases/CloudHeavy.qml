// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// CLOUDHEAVY: two domain warps, seven octaves, sin()-based hash — 140 hashes
// per fragment. Purely fragment-bound, so it scales with PANEL AREA.
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

    ShaderEffect {
        id: shaderPhase

        anchors.fill: parent
        fragmentShader: "file:///usr/share/benchymark/benchy-shader.frag.qsb"

        property real t: 0

        NumberAnimation on t {
            from: 0
            to: 10000
            duration: 10000000
            loops: Animation.Infinite
            running: shaderPhase.visible
        }

    }
}
