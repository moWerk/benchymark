// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// A saved run, opened from the Results tab; back returns to the list.
import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: resultsPage
    allowedOrientations: Orientation.Portrait
    property var run: null
    property var stageInfo: ({})

    ResultsPane {
        anchors.fill: parent
        run: resultsPage.run
        stageInfo: resultsPage.stageInfo
        showSettings: false
        showBack: false
    }
}
