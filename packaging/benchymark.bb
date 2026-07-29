# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Timo Könnecke (moWerk) <mo@mowerk.net>
#
# Reference recipe. Build against a checkout of this repo:
#
#     devtool add benchymark /path/to/benchymark
#     devtool build benchymark
#     bitbake -c package_write_ipk benchymark
#
# Note the last line: `devtool build` stops after do_packagedata, reports
# success, and writes no package at all.

SUMMARY = "The AsteroidOS rendering benchmark"
HOMEPAGE = "https://github.com/moWerk/benchymark"
# Set explicitly: without it the distro-wide default lands in the ipk's
# control file and misattributes the package to another maintainer.
MAINTAINER = "Timo Könnecke (moWerk) <mo@mowerk.net>"
LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

SRC_URI = ""

# Same shape as every other AsteroidOS app (see asteroid-app.inc).
inherit qt6-cmake

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native"

# The app library, the installed shader pair and the icon are not covered by
# the default packaging globs.
FILES:${PN} += "/usr/share/translations/ ${libdir}/${PN}.so \
                 ${datadir}/benchymark ${datadir}/icons/asteroid"
