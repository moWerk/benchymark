// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Settings, from the start and the results page's pulley (mo, 2026-10-18):
// whether the start page explains, whether the results say what each score
// counts, and which system details the results show. The saved runs are
// the second tab, newest first; a tap opens one (asked for on the forum,
// mo's design, 2026-10-19). Tabs as in BeatFork and Jolla Clock: TabView is
// private Silica API (fine for Chum, not for the store).
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.Configuration 1.0
import Benchymark 1.0

Page {
    id: settingsPage
    allowedOrientations: Orientation.Portrait

    // [{ key, title, value }] from the main page, the value as shown now
    property var details: []
    property var stageInfo: ({})
    property string currentStarted: ""   // the run on the main page, marked
    property int startTab: 0

    BenchLog { id: log }

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
        id: showMotion
        key: "/apps/harbour-benchymark/showMotion"
        defaultValue: true
    }
    ConfigurationValue {
        id: showScoreAbout
        key: "/apps/harbour-benchymark/showScoreAbout"
        defaultValue: true
    }

    readonly property var modeNames: ({
        //% "Run once"
        once: qsTrId("id-run-once"),
        //% "Run one hour"
        hour: qsTrId("id-run-hour"),
        //% "Run in loop"
        loop: qsTrId("id-run-loop")
    })
    function clockText(seconds) {
        var t = Math.max(0, Math.round(seconds))
        var two = function (n) { return (n < 10 ? "0" : "") + n }
        return Math.floor(t / 3600) + ":" + two(Math.floor(t / 60) % 60) + ":" + two(t % 60)
    }

    // the saved runs, newest first
    ListModel { id: runsModel }
    function loadRuns() {
        var list = log.runSummaries()
        runsModel.clear()
        for (var i = 0; i < list.length; i++) {
            var r = list[i]
            runsModel.append({
                file: r.file,
                started: r.started,
                when: r.started ? Qt.formatDateTime(new Date(Date.parse(r.started)), "yyyy-MM-dd hh:mm") : r.file,
                runtime: r.runtime >= 0 ? clockText(r.runtime) : "",
                //% "Stages: %1"
                about: [modeNames[r.mode] || "", qsTrId("id-stages-count").arg(r.stages),
                        r.version ? "v" + r.version : "",
                        // an older scene's scores do not compare with this one's
                        r.scene && r.scene !== "sfos-2.2" ? r.scene : ""]
                       .filter(function (x) { return x !== "" }).join("  ·  ")
            })
        }
    }
    Component.onCompleted: loadRuns()

    function openRun(file) {
        var r
        try { r = JSON.parse(log.readRun(file)) } catch (e) { return }
        pageStack.push(Qt.resolvedUrl("ResultsPage.qml"), { run: r, stageInfo: stageInfo })
    }
    // Compare: a long press picks run A, the next tap picks B
    property string compareFrom: ""
    property string compareFromWhen: ""
    function openCompare(fileB) {
        var a, b
        try { a = JSON.parse(log.readRun(compareFrom)); b = JSON.parse(log.readRun(fileB)) } catch (e) { return }
        compareFrom = ""
        pageStack.push(Qt.resolvedUrl("ComparePage.qml"), { runA: a, runB: b, stageInfo: stageInfo })
    }

    TabView {
        id: tabs
        anchors.fill: parent
        currentIndex: settingsPage.startTab
        header: TabBar {
            model: ListModel {
                ListElement {
                    //% "Settings"
                    title: qsTrId("id-settings")
                }
                ListElement {
                    //% "Results"
                    title: qsTrId("id-tab-results")
                }
            }
        }
        model: [settingsTab, runsTab]
    }

    Component {
        id: settingsTab
        TabItem {
            // the tab view sizes each tab by its implicit size
            implicitWidth: tabs.width
            implicitHeight: tabs.height - tabs.tabBarHeight
            flickable: settingsFlick

            SilicaFlickable {
                id: settingsFlick
                anchors.fill: parent
                contentHeight: column.height + Theme.paddingLarge

                Column {
                    id: column
                    width: parent.width

                    SectionHeader {
                        //% "Running"
                        text: qsTrId("id-setting-section-running")
                    }
                    TextSwitch {
                        //% "Show stages moving"
                        text: qsTrId("id-setting-motion")
                        //% "Each graphics stage plays two seconds on screen before it is measured off screen, where only its first frames show. Off: measuring only, two seconds shorter per stage. The scores are the same either way."
                        description: qsTrId("id-setting-motion-about")
                        checked: showMotion.value === true || showMotion.value === "true"
                        automaticCheck: false
                        onClicked: showMotion.value = !checked
                    }

                    SectionHeader {
                        //% "Display hints and descriptions"
                        text: qsTrId("id-setting-section-hints")
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
                        //% "Score descriptions in the results"
                        text: qsTrId("id-setting-score-about")
                        //% "A tap on a stage in the results says what its score counts and what that shows, as on the start page."
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
    }

    Component {
        id: runsTab
        TabItem {
            implicitWidth: tabs.width
            implicitHeight: tabs.height - tabs.tabBarHeight
            flickable: runsList

            SilicaListView {
                id: runsList
                anchors.fill: parent
                model: runsModel

                // while a run waits for its partner: what to do next
                header: Label {
                    x: Theme.horizontalPageMargin
                    width: runsList.width - 2 * x
                    height: settingsPage.compareFrom !== "" ? implicitHeight + Theme.paddingLarge : 0
                    visible: settingsPage.compareFrom !== ""
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    //% "Tap a run to compare with %1, or tap it again to cancel"
                    text: qsTrId("id-compare-pick").arg(settingsPage.compareFromWhen)
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                }

                ViewPlaceholder {
                    enabled: runsList.count === 0
                    //% "No saved runs yet"
                    text: qsTrId("id-no-runs")
                    //% "Every run is kept here, the newest first."
                    hintText: qsTrId("id-no-runs-hint")
                }

                // a long press deletes, with the usual few seconds to undo
                delegate: ListItem {
                    id: runItem
                    contentHeight: Theme.itemSizeMedium
                    onClicked: {
                        if (settingsPage.compareFrom === "") settingsPage.openRun(model.file)
                        else if (settingsPage.compareFrom === model.file) settingsPage.compareFrom = ""
                        else settingsPage.openCompare(model.file)
                    }
                    // the picked run A stays lit until B is tapped
                    highlighted: down || menuOpen || settingsPage.compareFrom === model.file
                    menu: ContextMenu {
                        MenuItem {
                            //% "Compare with…"
                            text: qsTrId("id-compare-with")
                            onClicked: {
                                settingsPage.compareFrom = model.file
                                settingsPage.compareFromWhen = model.when
                            }
                        }
                        MenuItem {
                            //% "Delete"
                            text: qsTrId("id-delete")
                            // the file as it was at the tap, the row found by it
                            onClicked: {
                                var f = model.file
                                runItem.remorseDelete(function () {
                                    log.deleteRun(f)
                                    for (var i = 0; i < runsModel.count; i++)
                                        if (runsModel.get(i).file === f) { runsModel.remove(i); break }
                                })
                            }
                        }
                    }

                    Label {
                        id: whenLabel
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingSmall
                        //% "this run"
                        text: model.when + (model.started !== "" && model.started === settingsPage.currentStarted
                                            ? "  ·  " + qsTrId("id-this-run") : "")
                        color: runItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.baseline: whenLabel.baseline
                        text: model.runtime
                        color: runItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        anchors.top: whenLabel.bottom
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        text: model.about
                        color: runItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                    }
                }

                VerticalScrollDecorator { }
            }
        }
    }
}
