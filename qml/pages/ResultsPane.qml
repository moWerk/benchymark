// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// A run's results with their pulley and Share, for the run that just ended
// and for a saved one alike.
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Share 1.0
import Benchymark 1.0

Item {
    id: pane
    property var run: null
    property var stageInfo: ({})
    property bool showSettings: true
    property bool showBack: true
    readonly property alias view: resultView
    signal settingsClicked()
    signal backClicked()

    BenchLog { id: log }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: resultView.height + Theme.paddingLarge * 2

        // SailfishOS pulls instead of buttons; the nearest to the finger last
        PullDownMenu {
            // hardest to reach: the details and descriptions, without
            // leaving the results (mo, 2026-10-18)
            MenuItem {
                visible: pane.showSettings
                //% "Settings"
                text: qsTrId("id-settings")
                onClicked: pane.settingsClicked()
            }
            MenuItem {
                visible: pane.showBack
                //% "Back to stages"
                text: qsTrId("id-back-to-stages")
                onClicked: pane.backClicked()
            }
            MenuItem {
                //% "Share JSON"
                text: qsTrId("id-share-json")
                onClicked: pane.shareJson()
            }
            MenuItem {
                //% "Share image"
                text: qsTrId("id-share-image")
                onClicked: pane.shareImage()
            }
        }

        ResultsView {
            id: resultView
            width: parent.width
            run: pane.run
            stageInfo: pane.stageInfo
        }

        VerticalScrollDecorator { }
    }
    // a new run starts at its top, with no row open
    onRunChanged: { flick.contentY = 0; resultView.openResult = "" }

    // Share's copy: off screen, full height, drawn only while sharing
    Loader {
        id: shareLoader
        active: false
        x: pane.width * 2
        width: pane.width
        sourceComponent: ResultsView {
            stageInfo: pane.stageInfo
            shareMode: true
        }
        // the run set after creation, as on the page (the binding loop)
        onLoaded: item.run = pane.run
    }
    // the picture takes a moment: the page dims to half black and says so
    // (mo, 2026-10-18)
    // Then it says where the picture went, or that it could not be saved,
    // before the share menu opens: the save was silent (Michał, 2026-10-19).
    // The note on the dimmed page fades in, pulses twice and fades out,
    // 1.5 s at least however quick the picture is, so it can be read; then
    // where the picture went fades in (mo, 2026-10-19: the texts cut in).
    property string shareNote: ""
    property bool shareSaved: false
    property bool shareBusy: false       // from Share image to the share menu
    property bool assemblingShown: false // the note's 1.5 s are through
    property bool shareDone: false       // the picture is saved, or failed
    Rectangle {
        anchors.fill: parent
        visible: opacity > 0
        opacity: pane.shareBusy ? 1 : 0
        Behavior on opacity { FadeAnimation { duration: 250 } }
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 50
        MouseArea { anchors.fill: parent }   // no taps through while it works
        Label {
            id: assemblingLabel
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            horizontalAlignment: Text.AlignHCenter
            //% "Assembling screenshot…"
            text: qsTrId("id-share-assembling").split(" ").join("\n")
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge * 1.5
            opacity: 0
        }
        Label {
            id: savedLabel
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: pane.shareNote
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            opacity: 0
        }
    }
    SequentialAnimation {
        id: assemblingAnim
        NumberAnimation { target: assemblingLabel; property: "opacity"; from: 0; to: 1; duration: 250 }
        SequentialAnimation {
            loops: 2
            NumberAnimation { target: assemblingLabel; property: "opacity"; from: 1; to: 0.75; duration: 250 }
            NumberAnimation { target: assemblingLabel; property: "opacity"; from: 0.75; to: 1; duration: 250 }
        }
        NumberAnimation { target: assemblingLabel; property: "opacity"; from: 1; to: 0; duration: 250 }
        ScriptAction { script: { pane.assemblingShown = true; pane.showSaved() } }
    }
    SequentialAnimation {
        id: savedAnim
        NumberAnimation { target: savedLabel; property: "opacity"; from: 0; to: 1; duration: 250 }
        PauseAnimation { duration: 1500 }
        NumberAnimation { target: savedLabel; property: "opacity"; from: 1; to: 0; duration: 250 }
        ScriptAction {
            script: {
                pane.shareBusy = false
                pane.shareNote = ""
                if (pane.shareSaved && !pane.shareTest) shareAction.trigger()
            }
        }
    }
    // once both the note's time and the picture are through
    function showSaved() {
        if (assemblingShown && shareDone && !savedAnim.running) savedAnim.start()
    }
    // the graphs are Canvases: give them a moment to draw before the grab
    Timer {
        id: shareGrabTimer
        interval: 700
        onTriggered: pane.grabShare()
    }

    // Share: the results as a picture in Pictures, then the share menu with it
    ShareAction {
        id: shareAction
        //% "Share results"
        title: qsTrId("id-share-results")
    }
    property bool shareTest: false
    readonly property string stamp: run && run.started
            ? Qt.formatDateTime(new Date(Date.parse(run.started)), "yyyyMMdd-hhmmss") : "run"
    function shareImage(test) {
        if (shareBusy) return
        shareTest = test === true
        shareBusy = true
        assemblingShown = false
        shareDone = false
        assemblingLabel.opacity = 0
        savedLabel.opacity = 0
        assemblingAnim.restart()
        shareLoader.active = true
        shareGrabTimer.restart()
    }
    function grabShare() {
        var item = shareLoader.item
        if (!item) { shareDone = true; showSaved(); return }
        item.grabToImage(function (result) {
            // the test hook keeps it in the app's data directory instead
            var file = pane.shareTest ? log.path().replace("last-run.json", "share-test.png")
                     : log.screenshotsDir() + "/benchymark-" + pane.stamp + ".png"
            var saved = result.saveToFile(file)
            shareLoader.active = false
            pane.shareSaved = saved
            //% "Saved to %1"
            pane.shareNote = saved ? qsTrId("id-share-saved-in").arg(file.replace(/^.*\/(Pictures\/)/, "$1"))
                           //% "Could not save the picture"
                           : qsTrId("id-share-not-saved")
            pane.shareDone = true
            pane.showSaved()
            if (!saved) {
                console.warn("Benchymark: could not save " + file)
                return
            }
            if (pane.shareTest) {
                // the real path once too, so the folder making is tested
                var real = log.screenshotsDir() + "/benchymark-selftest.png"
                console.log("Benchymark: share picture " + file + ", copy " + real + " " + result.saveToFile(real))
                return
            }
            shareAction.resources = [file]
            shareAction.mimeType = "image/png"
        })
    }

    // The JSON of the run, handed to the share menu as content (as Jolla
    // Notes does with text), so no file has to leave the sandbox.
    function shareJson() {
        shareAction.resources = [{ "name": "benchymark-" + stamp + ".json",
                                   "data": JSON.stringify(run, null, 1), "type": "application/json" }]
        shareAction.mimeType = "application/json"
        shareAction.trigger()
    }
}
