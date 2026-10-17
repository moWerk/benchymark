/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <sailfishapp.h>
#include <QGuiApplication>
#include <QFile>
#include <QQuickView>
#include <QStandardPaths>
#include <QScopedPointer>
#include <QtQml>

#include "BenchLog.h"
#include "FrameCounter.h"
#include "Wireframe.h"
#include "Dots.h"
#include "SystemBench.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName(QStringLiteral("net.mowerk"));
    app->setApplicationName(QStringLiteral("harbour-benchymark"));
    // a storage test cut short (app killed) leaves its file; not for long
    QFile::remove(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                  + QStringLiteral("/storage-test.bin"));

    qmlRegisterType<Wireframe>("Benchymark", 1, 0, "Wireframe");
    qmlRegisterType<BenchLog>("Benchymark", 1, 0, "BenchLog");
    qmlRegisterType<Dots>("Benchymark", 1, 0, "Dots");
    qmlRegisterType<PrimeEngine>("Benchymark", 1, 0, "PrimeEngine");
    qmlRegisterType<MemoryEngine>("Benchymark", 1, 0, "MemoryEngine");
    qmlRegisterType<StorageEngine>("Benchymark", 1, 0, "StorageEngine");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    // frames as presented, counted on the render thread
    FrameCounter *frames = new FrameCounter(view.data());
    QObject::connect(view.data(), &QQuickWindow::frameSwapped,
                     frames, &FrameCounter::frameSwapped, Qt::DirectConnection);
    QObject::connect(view.data(), &QQuickWindow::sceneGraphInitialized,
                     frames, &FrameCounter::readGpu, Qt::DirectConnection);
    view->rootContext()->setContextProperty(QStringLiteral("FrameCounter"), frames);
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"), QStringLiteral(APP_VERSION));
    // Test hook: SFOS_SELFTEST_RUN=<mode> starts that run at once (0 full
    // sequence, 1 loop all, 2+ one stage); the result lands in last-run.json.
    view->rootContext()->setContextProperty(QStringLiteral("selftestRun"),
            qEnvironmentVariableIsSet("SFOS_SELFTEST_RUN") ? qgetenv("SFOS_SELFTEST_RUN").toInt() : -1);
    // with SFOS_SELFTEST_STOP=<s> a single stage ends after that many seconds
    view->rootContext()->setContextProperty(QStringLiteral("selftestStop"),
            qEnvironmentVariableIsSet("SFOS_SELFTEST_STOP") ? qgetenv("SFOS_SELFTEST_STOP").toInt() : 0);
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}
