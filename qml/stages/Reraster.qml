// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// RERASTER: the same picture as SCALE, resized by animating
// font.pixelSize with native text rendering, so every size is rasterised
// again. SCALE against RERASTER is what animating text size costs. Every
// stacked copy has its own size, so each one is rasterised anew.
import QtQuick 2.6

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the texts drawn are the load, the score texts per second.
    // sfos-2.2: the whole picture, the ring of 100 and the six big numbers,
    // is stacked, so every step draws the same mix: a fixed ring made the
    // work per counted text 0.37 at the lightest step and 0.98 at the
    // heaviest (night audit, 2026-10-19). 106 texts per picture.
    readonly property var ladder: [106, 212, 424, 848, 1696, 3392, 6784]
    property int load: 212
    readonly property bool perPixel: false
    //% "texts/s"
    readonly property string unit: qsTrId("id-unit-texts")

    readonly property bool reraster: true
    readonly property real size: Math.min(width, height)
    readonly property real radius: size * 0.41
    readonly property real baseGlyph: size * 0.336
    readonly property real peak: 1.8
    property real k: 1
    readonly property real cell: Math.min(width / 2, height / 3)
    // fixed digits: the clock's minute changed the glyphs, and with them the
    // work, from run to run (night audit; it was the watch's minute)
    readonly property string mm: "42"

    // Each stacked copy a few pixels larger than the one before: the glyph
    // cache keeps one rasterisation per size, so copies of one size were
    // rasterised once for all, and the work did not grow with the load (night
    // audit, 2026-10-19: four times the texts, 14 % more frame time on the
    // XA2). 64 sizes, up to a fifth larger.
    function copySize(c) { return 1 + (c % 64) * 0.003 }

    // `stack` copies of the picture, each drawn on the same spots
    readonly property int stack: Math.max(1, Math.round(load / 106))
    Repeater {
        model: 100 * stage.stack
        Text {
            readonly property real a: (index % 100) / 100 * 2 * Math.PI
            text: stage.mm
            color: "white"
            opacity: 0.5
            renderType: stage.reraster ? Text.NativeRendering : Text.QtRendering
            font.bold: true
            font.pixelSize: stage.reraster ? stage.baseGlyph * 0.42 * stage.k * stage.copySize(Math.floor(index / 100))
                                           : stage.baseGlyph * 0.42
            scale: stage.reraster ? 1 : stage.k
            x: stage.width / 2 + stage.radius * 0.72 * Math.cos(a) - width / 2
            y: stage.height / 2 + stage.radius * 0.72 * Math.sin(a) - height / 2
        }
    }

    // six big numbers in a 2 x 3 grid, each drawn `stack` times on the same
    // spot (mo, 2026-10-17: more text to resize than the picture shows)
    Repeater {
        model: 6 * stage.stack
        Text {
            readonly property int spot: index % 6
            // square cells as for the Benchy: gaps equal both ways (mo)
            x: stage.width / 2 + (spot % 2 ? 0.5 : -0.5) * stage.cell - width / 2
            y: stage.height / 2 + (Math.floor(spot / 2) - 1) * stage.cell - height / 2
            text: stage.mm
            color: "#f0c30e"
            renderType: stage.reraster ? Text.NativeRendering : Text.QtRendering
            font.bold: true
            font.pixelSize: stage.reraster ? stage.baseGlyph * stage.k * stage.copySize(Math.floor(index / 6))
                                           : stage.baseGlyph
            scale: stage.reraster ? 1 : stage.k
        }
    }

    SequentialAnimation on k {
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: stage.peak; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { from: stage.peak; to: 1; duration: 900; easing.type: Easing.InOutSine }
    }
}
