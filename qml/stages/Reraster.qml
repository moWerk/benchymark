// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// RERASTER: the same picture as SCALE, resized by animating
// font.pixelSize with native text rendering, so every size is rasterised
// again. SCALE against RERASTER is what animating text size costs.
import QtQuick 2.6

Item {
    id: stage
    anchors.fill: parent

    readonly property bool reraster: true
    readonly property real size: Math.min(width, height)
    readonly property real radius: size * 0.41
    readonly property real baseGlyph: size * 0.336
    readonly property real peak: 1.8
    property real k: 1
    readonly property real cell: Math.min(width / 2, height / 3)
    property string mm: Qt.formatDateTime(new Date(), "mm")

    Repeater {
        model: 100
        Text {
            readonly property real a: index / 100 * 2 * Math.PI
            text: stage.mm
            color: "white"
            opacity: 0.5
            renderType: stage.reraster ? Text.NativeRendering : Text.QtRendering
            font.bold: true
            font.pixelSize: stage.reraster ? stage.baseGlyph * 0.42 * stage.k : stage.baseGlyph * 0.42
            scale: stage.reraster ? 1 : stage.k
            x: stage.width / 2 + stage.radius * 0.72 * Math.cos(a) - width / 2
            y: stage.height / 2 + stage.radius * 0.72 * Math.sin(a) - height / 2
        }
    }

    // six big numbers in a 2 x 3 grid, each drawn `stack` times on the same
    // spot (mo, 2026-10-17: more text to resize than the picture shows)
    property int stack: 20
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
            font.pixelSize: stage.reraster ? stage.baseGlyph * stage.k : stage.baseGlyph
            scale: stage.reraster ? 1 : stage.k
        }
    }

    SequentialAnimation on k {
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: stage.peak; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { from: stage.peak; to: 1; duration: 900; easing.type: Easing.InOutSine }
    }
}
