# SailfishOS port of Benchymark (the AsteroidOS rendering benchmark).
# Native: the frame counter and the wireframe renderer are C++.
TARGET = harbour-benchymark

# the version from the spec (%qmake5 VERSION=...), shown in the page header
isEmpty(VERSION): VERSION = 1.0.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

CONFIG += sailfishapp sailfishapp_i18n sailfishapp_i18n_idbased sailfishapp_i18n_unfinished

SOURCES += src/main.cpp \
    src/Wireframe.cpp \
    src/Dots.cpp \
    src/SystemBench.cpp \
    src/VulkanBench.cpp \
    src/GlesBench.cpp

HEADERS += src/Wireframe.h \
    src/Dots.h \
    src/SystemBench.h \
    src/VulkanBench.h \
    src/GlesBench.h \
    src/vulkan-spv.h \
    src/FrameCounter.h \
    src/BenchLog.h \
    src/benchymesh.h

# libvulkan is opened at run time, so it is not linked here.
LIBS += -lEGL -lGLESv2

DISTFILES += src/vulkan-full.vert \
    src/vulkan-cloud.frag \
    qml/harbour-benchymark.qml \
    qml/pages/*.qml \
    qml/stages/*.qml \
    qml/stages/*.js \
    qml/images/* \
    rpm/harbour-benchymark.spec \
    harbour-benchymark.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

TRANSLATIONS += translations/harbour-benchymark.ts
