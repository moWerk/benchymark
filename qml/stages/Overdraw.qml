// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// OVERDRAW: big translucent layers stacked, each pulsing and turning at its
// own pace: raw fill rate, most pixels blended once per layer.
import QtQuick 2.6
import "Motion.js" as Motion

Item {
    id: stage
    anchors.fill: parent
    // the layers, the same on every device (2.2; the C2 ran 72 in 1.x);
    // the score counts layers drawn per second
    property int load: 72
    property real t: 0
    property int layers: load
    readonly property bool perPixel: false
    //% "layers/s"
    readonly property string unit: qsTrId("id-unit-layers")

    // SailfishOS: the watch's layers each covered the whole panel, which on
    // the phone read as one flat violet; here every layer is a big rounded
    // square of its own size and turn, so the blending shows (mo, 2026-10-17)
    Repeater {
        model: stage.layers
        Rectangle {
            readonly property real side: stage.height * (0.45 + (index % 9) * 0.11)
            width: side
            height: side
            radius: side * 0.12
            x: (stage.width - side) / 2
            y: (stage.height - side) / 2
            // five colours, stronger than the watch's, so the layers read
            color: ["#4000a0ff", "#40ff5090", "#4030e070", "#40f0c30e", "#40b040ff"][index % 5]
            opacity: Motion.bounce(stage.t, 0.15, 1.0, 0.6 + index * 0.09)
            rotation: (index % 2 ? 360 : -360) * Motion.cycle(stage.t, 6 + index * 0.17)
        }
    }
}
