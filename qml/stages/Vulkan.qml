// SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// VULKAN: Shader heavy's field on another road. The shader is carried over
// to Vulkan GLSL character for character (src/vulkan-cloud.frag), drawn
// without a window into an image in memory and timed by the GPU itself.
// It stands right behind Shader heavy: same work, same pixels, other road,
// and the GPU is already warm from the stage before.
//
// The stage counts its own frames (`frameSource`), because the window sees
// nothing of that work. The page samples it once a second as it does with
// any drawn stage, so this stage gets avg, min and worst like the rest.
//
// Nothing is presented, so there is no vsync: the figure says what the GPU
// would manage for that frame, not what a display would show.
//
// Without libvulkan the stage says so in one line and ends itself; it is a
// system stage then, not an fps one.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    property real areaTop: 0
    property real areaBottom: height
    property string live: ""
    signal finished()

    readonly property bool system: engine.phase === -1
    readonly property bool selfTimed: engine.phase === -1
    readonly property var frameSource: engine

    OffscreenView {
        id: picture
        x: 0
        y: stage.areaTop
        width: stage.width
        height: stage.areaBottom - stage.areaTop
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: stage.areaTop + stage.width * 0.06
        text: engine.phase === -1 ? qsTrId("id-vulkan-missing")
                                  : engine.device + " · Vulkan " + engine.api
        color: "white"
        opacity: 0.85
        font.pixelSize: stage.width * 0.045
    }

    VulkanEngine {
        id: engine
        view: picture
        onChanged: if (phase === -1) {
            stage.live = qsTrId("id-vulkan-missing") + " · " + reason
            stage.finished()
        }
    }

    Component.onCompleted: engine.start(Math.round(width),
                                        Math.round(areaBottom - areaTop))
    Component.onDestruction: engine.stop()

    // only for the case without Vulkan: one line instead of fps
    function results() {
        return [{ key: "VULKAN", name: qsTrId("id-stage-vulkan"),
                  value: "–", unit: engine.reason }]
    }

    //% "Vulkan shader"
    readonly property string _name: qsTrId("id-stage-vulkan")
    //% "no Vulkan here"
    readonly property string _missing: qsTrId("id-vulkan-missing")
}
