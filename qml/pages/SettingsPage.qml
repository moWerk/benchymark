// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Settings, from the start and the results page's pulley (mo, 2026-10-18):
// whether the start page explains, whether the results say what each score
// counts, and which system details the results show.
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: settingsPage
    allowedOrientations: Orientation.Portrait

    // [{ key, title, value }] from the main page, the value as shown now
    property var details: []

    ConfigurationValue {
        id: showHints
        key: "/apps/harbour-benchymark/showHints"
        defaultValue: true
    }
    ConfigurationValue {
        id: hiddenDetails
        key: "/apps/harbour-benchymark/hiddenDetails"
        defaultValue: "[]"
    }
    readonly property var hidden: {
        try { return JSON.parse(hiddenDetails.value) } catch (e) { return [] }
    }
    function setShown(key, on) {
        var h = hidden.filter(function (k) { return k !== key })
        if (!on) h.push(key)
        hiddenDetails.value = JSON.stringify(h)
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

            SectionHeader {
                //% "Show system details in the results"
                text: qsTrId("id-setting-details")
            }

            // all or none at once; the text lights on a press, as SailfishOS does
            Row {
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingLarge * 2
                Repeater {
                    //% "All"
                    model: [{ label: qsTrId("id-details-all"), all: true },
                            //% "None"
                            { label: qsTrId("id-details-none"), all: false }]
                    Label {
                        text: modelData.label
                        color: allArea.pressed && allArea.containsMouse ? Theme.highlightColor : Theme.primaryColor
                        MouseArea {
                            id: allArea
                            anchors.fill: parent
                            anchors.margins: -Theme.paddingMedium
                            onClicked: hiddenDetails.value = modelData.all ? "[]"
                                       : JSON.stringify(settingsPage.details.map(function (d) { return d.key }))
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingSmall }

            // each line with what it shows now
            Repeater {
                model: settingsPage.details
                TextSwitch {
                    text: modelData.title
                    description: modelData.value
                    checked: settingsPage.hidden.indexOf(modelData.key) < 0
                    automaticCheck: false
                    onClicked: settingsPage.setShown(modelData.key, !checked)
                }
            }
        }

        VerticalScrollDecorator { }
    }
}
