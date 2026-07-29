// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// IDLE: the sanity floor. Deliberately EMPTY.
//
// The clock, the FPS rotator and the phase titles live in main.qml and run
// throughout, so this phase measures the app's own resting cost and nothing
// else. If IDLE is not flat 60, no number above it means anything — read it
// first, and if it is low, stop and find out why before trusting the rest.

import QtQuick

Item {
    id: phase

    property var bench

    anchors.fill: parent
}
