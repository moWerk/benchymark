// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Settings, from the start page's pulley (mo, 2026-10-18): whether the
// start page explains, and whether the results say what each score counts.
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: settingsPage
    allowedOrientations: Orientation.Portrait

    ConfigurationValue {
        id: showHints
        key: "/apps/harbour-benchymark/showHints"
        defaultValue: true
    }
    ConfigurationValue {
        id: showScoreAbout
        key: "/apps/harbour-benchymark/showScoreAbout"
        defaultValue: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "Settings"
                title: qsTrId("id-settings")
            }

            TextSwitch {
                //% "Show hints on the start page"
                text: qsTrId("id-setting-hints")
                //% "A stage's description on a tap of its name, and what the chosen run mode is for."
                description: qsTrId("id-setting-hints-about")
                checked: showHints.value === true || showHints.value === "true"
                automaticCheck: false
                onClicked: showHints.value = !checked
            }

            TextSwitch {
                //% "Show score descriptions in the results"
                text: qsTrId("id-setting-score-about")
                //% "A line under each stage that says what its score counts."
                description: qsTrId("id-setting-score-about-about")
                checked: showScoreAbout.value === true || showScoreAbout.value === "true"
                automaticCheck: false
                onClicked: showScoreAbout.value = !checked
            }
        }

        VerticalScrollDecorator { }
    }
}
