/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <sailfishapp.h>
#include <QGuiApplication>
#include <QFile>
#include <QQuickView>
#include <QStandardPaths>
#include <QSysInfo>
#include <QSocketNotifier>
#include <csignal>
#include <cstring>
#include <sys/socket.h>
#include <unistd.h>
#include <QScopedPointer>
#include <QtQml>

#include "BenchLog.h"
#include "FrameCounter.h"
#include "Wireframe.h"
#include "Dots.h"
#include "SystemBench.h"
#include "BufferRead.h"

// SIGTERM (the system ending the app, a shutdown) quits through Qt, so the
// page's teardown saves a run in progress; the handler only writes to a
// pipe, the quit happens in the event loop (night audit, 2026-10-19)
static int sigtermFd[2];
static void onSigterm(int)
{
    const char c = 1;
    if (::write(sigtermFd[1], &c, 1) < 0) { }
}

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
    qmlRegisterType<BufferRead>("Benchymark", 1, 0, "BufferRead");

    if (::socketpair(AF_UNIX, SOCK_STREAM, 0, sigtermFd) == 0) {
        QSocketNotifier *sn = new QSocketNotifier(sigtermFd[0], QSocketNotifier::Read, app.data());
        QObject::connect(sn, &QSocketNotifier::activated, app.data(), &QCoreApplication::quit);
        struct sigaction sa;
        std::memset(&sa, 0, sizeof(sa));
        sa.sa_handler = onSigterm;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART;
        ::sigaction(SIGTERM, &sa, nullptr);
    }

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    // frames as presented, counted on the render thread
    FrameCounter *frames = new FrameCounter(view.data());
    QObject::connect(view.data(), &QQuickWindow::frameSwapped,
                     frames, &FrameCounter::frameSwapped, Qt::DirectConnection);
    QObject::connect(view.data(), &QQuickWindow::sceneGraphInitialized,
                     frames, &FrameCounter::readGpu, Qt::DirectConnection);
    frames->watch(view.data());
    view->rootContext()->setContextProperty(QStringLiteral("FrameCounter"), frames);
    // the build's and the device's CPU architecture, for comparing CPU scores
    // (an armv7hl build on an ARMv8 core is a different program)
    view->rootContext()->setContextProperty(QStringLiteral("buildArch"), QSysInfo::buildCpuArchitecture());
    view->rootContext()->setContextProperty(QStringLiteral("cpuArch"), QSysInfo::currentCpuArchitecture());
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"), QStringLiteral(APP_VERSION));
    // Test hook: SFOS_SELFTEST_RUN=<n> runs stage n alone at once, -2 all
    // ticked stages; the result lands in last-run.json and the saved runs.
    // a value that is not a number counts as unset
    bool ok = false;
    const int run = qEnvironmentVariableIntValue("SFOS_SELFTEST_RUN", &ok);
    view->rootContext()->setContextProperty(QStringLiteral("selftestRun"), ok ? run : -1);
    // with SFOS_SELFTEST_STOP=<s> a single stage ends after that many seconds
    const int stopAfter = qEnvironmentVariableIntValue("SFOS_SELFTEST_STOP", &ok);
    view->rootContext()->setContextProperty(QStringLiteral("selftestStop"), ok ? stopAfter : 0);
    // with SFOS_SELFTEST_SHARE=1 the run's end makes the share picture into
    // the app's data directory (share-test.png), no share menu
    view->rootContext()->setContextProperty(QStringLiteral("selftestShare"),
            qEnvironmentVariableIntValue("SFOS_SELFTEST_SHARE") == 1);
    // with SFOS_SELFTEST_FIXED=1 a stage measures its saved step as it is,
    // no ramp, no new ramp: the linearity check of the night audit
    view->rootContext()->setContextProperty(QStringLiteral("selftestFixed"),
            qEnvironmentVariableIntValue("SFOS_SELFTEST_FIXED") == 1);
    // with SFOS_SELFTEST_PAGE=settings|runs|compare that page opens at
    // start, for screenshots of pages a smashed screen cannot reach
    view->rootContext()->setContextProperty(QStringLiteral("selftestPage"),
            QString::fromLatin1(qgetenv("SFOS_SELFTEST_PAGE")));
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}
