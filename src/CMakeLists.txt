# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Timo Könnecke (moWerk) <mo@mowerk.net>
set(CMAKE_AUTOMOC ON)

add_library(benchymark main.cpp benchlog.h)
set_target_properties(benchymark PROPERTIES PREFIX "")

asteroid_app_qml_module(benchymark
	main.qml
	benchy-mesh.js
	benchy-mesh-lite.js
	phases/Benchy.qml
	phases/Cascade.qml
	phases/CloudHeavy.qml
	phases/CloudMid.qml
	phases/Drawcalls.qml
	phases/Drawfont.qml
	phases/Idle.qml
	phases/Orbit.qml
	phases/Overdraw.qml
	phases/Reraster.qml
	phases/Scale.qml
	phases/Shapes.qml
)

target_link_libraries(
	benchymark
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS benchymark
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
