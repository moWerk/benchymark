// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// GPU BUFFERS: every pixel walks a 16 KB table, each index from the entry
// read before; BufferUbo, BufferSsbo and BufferTexture only pick where the
// table lives (asked for on the forum by kan_ibal, 2026-10-18).
import QtQuick 2.6
import Benchymark 1.0

Item {
    id: stage
    anchors.fill: parent
    property alias mode: reader.mode
    // why this GPU cannot run it, empty while it runs; the page skips it then
    readonly property string unsupported: reader.failure
    // the reads per pixel, the same for the three and on every device
    // (2.2; 16 in 1.3.1); the score counts rendered pixels x reads,
    // millions of table reads per second
    property int load: 32
    property real t: 0
    readonly property bool perPixel: true
    //% "M reads/s"
    readonly property string unit: qsTrId("id-unit-reads")
    // the page's fixed render size, handed in at load
    property int renderWidth: 0
    property int renderHeight: 0

    BufferRead {
        id: reader
        anchors.fill: parent
        lookups: stage.load
        renderSize: stage.renderWidth > 0 ? Qt.size(stage.renderWidth, stage.renderHeight) : Qt.size(-1, -1)
        t: stage.t
    }
}
