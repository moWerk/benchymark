// SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// GLES 3: the same field as Shader heavy, but in a context of its own and
// without a window, drawn into a framebuffer in memory and timed with
// GL_EXT_disjoint_timer_query. Together with Shader heavy (QtQuick, on
// screen) and VULKAN that makes four figures for one and the same sum.
//
// Counts its own frames like the Vulkan stage, so avg, min and worst come
// out as everywhere else.
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent

    property real areaTop: 0
    property real areaBottom: height
    property string live: ""
    property int wantedVersion: 3
    property string resultKey: "GLES-3"
    property string resultName: qsTrId("id-stage-gles3")
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
        width: stage.width * 0.9
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: engine.phase === -1 ? engine.reason : engine.glVersion
        color: "white"
        opacity: 0.85
        font.pixelSize: stage.width * 0.04
    }

    GlesEngine {
        id: engine
        view: picture
        wanted: stage.wantedVersion
        onChanged: if (phase === -1) {
            stage.live = engine.reason
            stage.finished()
        }
    }

    Component.onCompleted: engine.start(Math.round(width),
                                        Math.round(areaBottom - areaTop))
    Component.onDestruction: engine.stop()

    // only for the case where this context is not to be had
    function results() {
        return [{ key: stage.resultKey, name: stage.resultName,
                  value: "–", unit: engine.reason }]
    }

    //% "GLES 3 shader"
    readonly property string _name3: qsTrId("id-stage-gles3")
}
