// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// CPU SINGLE CORE: the CPU prime stage on one thread, so the per core speed
// shows next to the all core figure (asked for on the forum, 2026-10-17).
import QtQuick 2.6

CpuPrime {
    threadsWanted: 1
    resultKey: "CPU-SINGLE"
    resultName: qsTrId("id-stage-cpu-single")
}
