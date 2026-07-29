// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// RERASTER: the SAME visual span as SCALE, by the expensive route —
// animating font.pixelSize on native-rendered text, so every size churns the
// glyph cache with a CPU rasterisation and a texture upload. The ratio
// between the two IS the measurement.

import QtQuick

Item {
    id: phase

    property var bench

    anchors.fill: parent

    readonly property bool reraster: true
    property real k: 1

    // The ghost ring. Both text phases drive TEN glyphs as well as the centre
    // one, because a single Text barely troubled any watch (moWerk). The ring
    // takes the same route as the centre glyph, so the SCALE:RERASTER ratio
    // still isolates the glyph-cache path — only the magnitude changed.
    Repeater {
        model: 10

        delegate: Text {
            readonly property real a: index / 10 * 2 * Math.PI

            text: bench.mmStr
            color: bench.dim
            opacity: 0.5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // NativeRendering is what makes a size change cost: distance-field
            // text scales a texture, native text re-rasterises the glyph.
            renderType: phase.reraster ? Text.NativeRendering : Text.QtRendering
            font.family: "Inter Tight"
            font.weight: Font.Black
            font.pixelSize: phase.reraster ? bench.baseGlyph * 0.42 * phase.k
                                           : bench.baseGlyph * 0.42
            scale: phase.reraster ? 1 : phase.k
            x: bench.width / 2 + bench.rootRadius * 0.72 * Math.cos(a) - width / 2
            y: bench.height / 2 + bench.rootRadius * 0.72 * Math.sin(a) - height / 2
        }

    }

    // The single driver for both routes: one animated number, applied either
    // to `scale` (cheap) or to `font.pixelSize` (the glyph-cache churn).
    SequentialAnimation on k {
        running: bench.awake
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: bench.glyphPeak; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { from: bench.glyphPeak; to: 1; duration: 900; easing.type: Easing.InOutSine }
    }

    // main.qml owns the clock; the phase only says how to drive it.
    Component.onCompleted: bench.glyphMode = phase.reraster ? "reraster" : "scale"
    Component.onDestruction: bench.glyphMode = "idle"
}
