// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// CASCADE: two trees of rounded, antialiased squares, one breathing, one
// counter-rotating: many moving children under transformed parents.
import QtQuick 2.6
import "Ramp.js" as Ramp

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the squares are the load (1000 in 1.x, two rings of half), the score
    // squares per second
    readonly property var ladder: [250, 500, 1000, 2000, 4000, 8000, 16000]
    property int load: 1000
    readonly property bool perPixel: false
    //% "squares/s"
    readonly property string unit: qsTrId("id-unit-squares")
    property int count: load / 2
    readonly property real size: Math.min(width, height)
    readonly property real radius: size * 0.41

    Item {
        anchors.fill: parent
        Repeater {
            model: stage.count
            Rectangle {
                readonly property real a: index / stage.count * 2 * Math.PI * 5
                width: stage.size * 0.06
                height: width
                radius: width * 0.3
                antialiasing: true
                color: Ramp.colors[index % Ramp.colors.length]
                opacity: 0.75
                x: stage.width / 2 + stage.radius * (0.3 + (index % 5) * 0.16) * Math.cos(a) - width / 2
                y: stage.height / 2 + stage.radius * (0.3 + (index % 5) * 0.16) * Math.sin(a) - height / 2
                rotation: index * 9
            }
        }
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 0.55; to: 1.25; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.25; to: 0.55; duration: 800; easing.type: Easing.InOutSine }
        }
    }

    Item {
        anchors.fill: parent
        Repeater {
            model: stage.count
            Rectangle {
                readonly property real a: -index / stage.count * 2 * Math.PI * 4
                width: stage.size * 0.045
                height: width
                radius: width * 0.5
                antialiasing: true
                color: Ramp.colors[(index + 4) % Ramp.colors.length]
                opacity: 0.55
                x: stage.width / 2 + stage.radius * (0.22 + (index % 6) * 0.14) * Math.cos(a) - width / 2
                y: stage.height / 2 + stage.radius * (0.22 + (index % 6) * 0.14) * Math.sin(a) - height / 2
                rotation: -index * 7
            }
        }
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 1.2; to: 0.5; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.5; to: 1.2; duration: 800; easing.type: Easing.InOutSine }
        }
        NumberAnimation on rotation {
            from: 0; to: -360; duration: 9000
            loops: Animation.Infinite
        }
    }
}
