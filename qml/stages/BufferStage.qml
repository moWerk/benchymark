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

    BufferRead {
        id: reader
        anchors.fill: parent
        lookups: 16
        NumberAnimation on t {
            from: 0; to: 10000; duration: 10000000
            loops: Animation.Infinite
            running: reader.visible
        }
    }
}
