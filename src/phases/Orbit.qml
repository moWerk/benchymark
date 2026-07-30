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
        // fill: parent, NOT bench.rotorItem. The rotator lives outside this
        // Loader, so it is neither parent nor sibling — QML refuses such an
        // anchor, the effect collapsed to zero size and the halo simply never
        // appeared. Both items fill the root, so parent is the same rectangle.
        anchors.fill: parent
        transformOrigin: Item.Center

        // MultiEffect captures its source in the SOURCE's own coordinates, so
        // the ring's own rotation is not in the texture: the halo sat still
        // while the numerals orbited past it (moWerk). The same Animator, with
        // the same parameters, puts them back in step — and being an Animator
        // it runs on the render thread, so the two cannot drift apart under
        // load the way a binding would.
        RotationAnimator on rotation {
            from: 180
            to: 720
            duration: (bench.running ? bench.phases[bench.phase].dur : 10) * 1000
            loops: Animation.Infinite
            running: bench.running && bench.sceneReady && !bench.inGap
        }
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
