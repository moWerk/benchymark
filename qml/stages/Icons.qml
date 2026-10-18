// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// ICON STORM (the watch's DRAWCALLS): many SVG icons on spiral orbits, all
// moving every frame: gold flashes, and Twemoji rockets behind them.
import QtQuick 2.6

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the icons drawn are the load (1440 in 1.x, 2 x 240 x 3), the score
    // icons per second
    readonly property var ladder: [480, 960, 1920, 3840, 7680, 15360]
    property int load: 1920
    readonly property bool perPixel: false
    //% "icons/s"
    readonly property string unit: qsTrId("id-unit-icons")
    // spirals out past the screen edge (mo, 2026-10-17): more arms, more icons
    property int count: 240
    // every icon drawn `stack` times on its spot: load the picture does not show
    property int stack: Math.max(1, load / 480)
    readonly property int arms: 6
    readonly property real reach: Math.sqrt(width * width + height * height) / 2
    readonly property real size: Math.min(width, height)
    readonly property real radius: size * 0.41
    property real spin: 0

    // behind the stars: Twemoji rockets, circling faster
    property real rocketSpin: 0
    Repeater {
        model: stage.count * stage.stack
        Image {
            // six spiral arms from the centre out past the screen edge
            readonly property int i: index % stage.count
            readonly property int arm: i % stage.arms
            readonly property real t: Math.floor(i / stage.arms) / (stage.count / stage.arms)
            readonly property real a: t * 2 * Math.PI * 1.5 + arm * 2 * Math.PI / stage.arms + 0.3
            readonly property real rad: stage.reach * (0.05 + 0.95 * t)
            source: "../images/rocket.svg"
            width: stage.size * 0.08
            height: width
            sourceSize { width: width; height: height }
            x: stage.width / 2 + rad * Math.cos(a + stage.rocketSpin) - width / 2
            y: stage.height / 2 + rad * Math.sin(a + stage.rocketSpin) - height / 2
        }
    }
    NumberAnimation on rocketSpin {
        from: 0; to: 2 * Math.PI; duration: 3500
        loops: Animation.Infinite
    }

    Repeater {
        model: stage.count * stage.stack
        Image {
            // six spiral arms from the centre out past the screen edge
            readonly property int i: index % stage.count
            readonly property int arm: i % stage.arms
            readonly property real t: Math.floor(i / stage.arms) / (stage.count / stage.arms)
            readonly property real a: t * 2 * Math.PI * 1.5 + arm * 2 * Math.PI / stage.arms + 0
            readonly property real rad: stage.reach * (0.05 + 0.95 * t)
            source: "../images/flash-gold.svg"
            width: stage.size * 0.09
            height: width
            sourceSize { width: width; height: height }
            x: stage.width / 2 + rad * Math.cos(a - stage.spin) - width / 2
            y: stage.height / 2 + rad * Math.sin(a - stage.spin) - height / 2
        }
    }

    NumberAnimation on spin {
        from: 0; to: 2 * Math.PI; duration: 5000
        loops: Animation.Infinite
    }
}
