// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Two saved runs side by side, stage by stage, with the second as a
// multiple of the first: before and after an update, cold against hot,
// one load against another (night audit feature, 2026-10-19).
import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: comparePage
    allowedOrientations: Orientation.Portrait

    property var runA: null    // the run picked first
    property var runB: null
    property var stageInfo: ({})

    function when(r) {
        return r && r.started ? Qt.formatDateTime(new Date(Date.parse(r.started)), "yyyy-MM-dd hh:mm") : ""
    }
    // a number to compare: the score, or a system stage's value
    function num(p) {
        if (!p) return NaN
        if (p.score !== undefined) return Number(p.score)
        if (p.value !== undefined && String(p.value).indexOf("/") < 0) return Number(p.value)
        return NaN
    }
    function shown(p) {
        if (!p) return "–"
        if (p.unsupported) return "–"
        if (p.score !== undefined) return p.score >= 100 ? String(Math.round(p.score)) : Number(p.score).toFixed(1)
        if (p.value !== undefined) return String(p.value)
        return "–"
    }
    readonly property var rows: {
        var a = runA && runA.phases ? runA.phases : []
        var b = runB && runB.phases ? runB.phases : []
        var byKey = {}
        for (var j = 0; j < b.length; j++) byKey[b[j].phase] = b[j]
        var out = []
        for (var i = 0; i < a.length; i++) {
            var pa = a[i], pb = byKey[pa.phase]
            var x = num(pa), y = num(pb)
            var info = stageInfo[pa.phase]
            out.push({ name: pa.name || (info ? info.name : pa.phase),
                       a: shown(pa), b: shown(pb), unit: pa.unit || (pb ? pb.unit : "") || "",
                       ratio: isFinite(x) && isFinite(y) && x > 0 ? y / x : NaN })
        }
        return out
    }
    readonly property bool sameScene: runA && runB && runA.scene === runB.scene

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingSmall

            PageHeader {
                //% "Compare"
                title: qsTrId("id-compare")
            }

            // which run is which, and whether they compare at all
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                //% "A: %1"
                text: qsTrId("id-compare-a").arg(comparePage.when(comparePage.runA)
                                                 + (comparePage.runA && comparePage.runA.device ? "  ·  " + comparePage.runA.device : ""))
                      //% "B: %1"
                      + "\n" + qsTrId("id-compare-b").arg(comparePage.when(comparePage.runB)
                                                 + (comparePage.runB && comparePage.runB.device ? "  ·  " + comparePage.runB.device : ""))
                      //% "Different scenes: these scores do not compare."
                      + (comparePage.sameScene ? "" : "\n" + qsTrId("id-compare-scenes"))
            }

            Item { width: 1; height: Theme.paddingMedium }

            Repeater {
                model: [{ head: true }].concat(comparePage.rows)
                Item {
                    x: Theme.horizontalPageMargin
                    width: comparePage.width - 2 * Theme.horizontalPageMargin
                    height: nameLabel.height + Theme.paddingSmall
                    readonly property bool head: modelData.head === true
                    readonly property real col: width / 7
                    Label {
                        id: nameLabel
                        width: parent.col * 2.9
                        //% "Stage"
                        text: parent.head ? qsTrId("id-col-stage") : modelData.name
                        color: parent.head ? Theme.secondaryHighlightColor : Theme.primaryColor
                        font.pixelSize: parent.head ? Theme.fontSizeSmall : Theme.fontSizeMedium
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        x: parent.col * 2.9
                        width: parent.col * 1.4
                        y: nameLabel.baselineOffset - baselineOffset
                        horizontalAlignment: Text.AlignRight
                        text: parent.head ? "A" : modelData.a
                        color: parent.head ? Theme.secondaryHighlightColor : Theme.highlightColor
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        x: parent.col * 4.3
                        width: parent.col * 1.4
                        y: nameLabel.baselineOffset - baselineOffset
                        horizontalAlignment: Text.AlignRight
                        text: parent.head ? "B" : modelData.b
                        color: parent.head ? Theme.secondaryHighlightColor : Theme.highlightColor
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeExtraSmall
                    }
                    // B as a multiple of A, brighter the further from even
                    Label {
                        x: parent.col * 5.7
                        width: parent.col * 1.3
                        y: nameLabel.baselineOffset - baselineOffset
                        horizontalAlignment: Text.AlignRight
                        text: parent.head ? "B/A" : isFinite(modelData.ratio) ? "×" + modelData.ratio.toFixed(2) : ""
                        color: parent.head ? Theme.secondaryHighlightColor
                               : isFinite(modelData.ratio) && Math.abs(modelData.ratio - 1) >= 0.05
                               ? Theme.primaryColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        VerticalScrollDecorator { }
    }
}
