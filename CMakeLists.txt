# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Timo Könnecke (moWerk) <mo@mowerk.net>
cmake_minimum_required(VERSION 3.6.0)

project(
	benchymark
	VERSION 0.1
	DESCRIPTION "The AsteroidOS rendering benchmark"
)

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp6 REQUIRED)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

include(FeatureSummary)
include(GNUInstallDirs)
include(ECMFindQmlModule)
include(Asteroid6CMakeSettings)
include(Asteroid6Translations)

# The whole reason this is an app rather than a watchface: DisplayBlanking is
# honoured for client apps and ignored inside the compositor, so only here can
# a run hold the screen for exactly its own duration.
ecm_find_qmlmodule(Nemo.KeepAlive 1.1)

configure_file(
	${CMAKE_CURRENT_SOURCE_DIR}/benchymark.in
	${CMAKE_BINARY_DIR}/benchymark
	@ONLY
)

install(
	PROGRAMS ${CMAKE_BINARY_DIR}/benchymark
	DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# The compiled shader is loaded by URL at runtime rather than from qrc, so it
# is installed as a plain file; the .frag source ships beside it so the phase
# can be rebuilt and audited instead of trusted as a binary.
install(
	FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/benchy-shader.frag.qsb
	      ${CMAKE_CURRENT_SOURCE_DIR}/src/benchy-shader.frag
	      ${CMAKE_CURRENT_SOURCE_DIR}/src/cloud-mid.frag.qsb
	      ${CMAKE_CURRENT_SOURCE_DIR}/src/cloud-mid.frag
	DESTINATION ${CMAKE_INSTALL_DATADIR}/benchymark
)

install(
	FILES ${CMAKE_CURRENT_SOURCE_DIR}/benchymark.svg
	DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/asteroid
)

build_translations(i18n)
add_subdirectory(src)

generate_desktop(${CMAKE_SOURCE_DIR} benchymark)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
