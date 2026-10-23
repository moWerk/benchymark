// SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// GLES 2: the same stage with an ES 2 context and GLSL ES 1.00 — the road
// QtQuick takes on Qt 5.6, but without a window and without the scene graph
// on top.
import QtQuick 2.6

Gles3 {
    wantedVersion: 2
    resultKey: "GLES-2"
    resultName: qsTrId("id-stage-gles2")

    //% "GLES 2 shader"
    readonly property string _name2: qsTrId("id-stage-gles2")
}
