// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    id: app
    allowedOrientations: Orientation.Portrait
    initialPage: Component { MainPage { } }
    cover: Component {
        CoverBackground {
            Label {
                anchors.centerIn: parent
                text: "Benchymark"
                color: Theme.highlightColor
            }
        }
    }
}
