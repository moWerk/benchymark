// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// CLOUDMID: one domain warp and four octaves — 48 hashes per fragment. The
// warp is a SERIAL dependency, so it costs more than its instruction count.
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
        id: cloudMid

        anchors.fill: parent
        fragmentShader: "file:///usr/share/benchymark/cloud-mid.frag.qsb"

        property real t: 0
        property color centerColor: "#58a6ff"
        property color outerColor: "#0b1b2e"

        NumberAnimation on t {
            from: 0
            to: 10000
            duration: 10000000
            loops: Animation.Infinite
            running: cloudMid.visible
        }

    }
}
