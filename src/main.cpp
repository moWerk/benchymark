/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <asteroidapp.h>
#include <QtQml>

#include "benchlog.h"

int main(int argc, char *argv[])
{
    // Registered before the app starts: QML type registration is global, so the
    // scene can instantiate BenchLog even though AsteroidApp owns the engine.
    qmlRegisterType<BenchLog>("Benchymark", 1, 0, "BenchLog");

    return AsteroidApp::main(argc, argv);
}
