// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// ORBIT: a pulsing halo recomputed over the FPS rotator every frame.
//
// The rotator itself lives in main.qml — it is the readout, present in every
// phase — so this phase takes it as an effect SOURCE through `bench`. That is
// the one place a phase reaches back into the run, and it is why bench
// publishes rotorItem.

import QtQuick
import QtQuick.Effects

Item {
    id: phase

    property var bench

    anchors.fill: parent

    MultiEffect {
        source: bench.rotorItem
        anchors.fill: bench.rotorItem
        shadowEnabled: true
        shadowColor: "#e0f0c30e"
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0

        blurEnabled: true
        blurMax: 72          // a heavier halo: the glow IS the phase

        SequentialAnimation on shadowBlur {
            running: bench.awake
            loops: Animation.Infinite
            NumberAnimation { from: 0.5; to: 1; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0.5; duration: 500; easing.type: Easing.InOutSine }
        }

        // A pulsing blur on top of the shadow: the effect is recomputed over
        // the whole rotor every frame, which is the point of this phase.
        SequentialAnimation on blur {
            running: bench.awake
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 0.6; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.6; to: 0; duration: 500; easing.type: Easing.InOutSine }
        }

    }
}
