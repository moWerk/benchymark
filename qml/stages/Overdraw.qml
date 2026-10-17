// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// OVERDRAW: big translucent layers stacked, each pulsing and turning at its
// own pace: raw fill rate, most pixels blended once per layer.
import QtQuick 2.6

Item {
    id: stage
    anchors.fill: parent
    property int layers: 72

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
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.15; to: 1.0; duration: 600 + index * 90 }
                NumberAnimation { from: 1.0; to: 0.15; duration: 600 + index * 90 }
            }
            RotationAnimator on rotation {
                from: 0
                to: index % 2 ? 360 : -360
                duration: 6000 + index * 170
                loops: Animation.Infinite
            }
        }
    }
}
