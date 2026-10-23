/*
 * SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * SailfishOS: the GLES 3 and GLES 2 stages. Same field as Shader heavy, but
 * in a context of their own and without a window, so the figure next to
 * QtQuick's and Vulkan's is that of plain GLES, once on ES 3 and once on ES 2.
 *
 * The context is its own (nothing is shared with Qt's render thread), the EGL
 * display however is the app's: never call eglTerminate() here, it would pull
 * the display out from under Qt.
 */
#ifndef GLESBENCH_H
#define GLESBENCH_H

#include <QAtomicInt>
#include <QMutex>
#include <QObject>
#include <QPointer>
#include <QString>

#include "SystemBench.h"   // FunctionThread
#include "VulkanBench.h"   // OffscreenView

class GlesEngine : public QObject
{
    Q_OBJECT
    // -1 not available, 0 idle, 2 running, 3 done
    Q_PROPERTY(int phase READ phase NOTIFY changed)
    // 2 or 3; what the driver actually gave is in glVersion
    Q_PROPERTY(int wanted READ wanted WRITE setWanted NOTIFY changed)
    Q_PROPERTY(QString glVersion READ glVersion NOTIFY changed)
    Q_PROPERTY(QString reason READ reason NOTIFY changed)
    Q_PROPERTY(OffscreenView *view READ view WRITE setView)
public:
    explicit GlesEngine(QObject *parent = nullptr);
    ~GlesEngine() override;

    int phase() const { QMutexLocker l(&m_lock); return m_phase; }
    int wanted() const { return m_wanted; }
    void setWanted(int v) { m_wanted = v; }
    QString glVersion() const { QMutexLocker l(&m_lock); return m_glVersion; }
    QString reason() const { QMutexLocker l(&m_lock); return m_reason; }
    OffscreenView *view() const { return m_view; }
    void setView(OffscreenView *v) { m_view = v; }

    Q_INVOKABLE void start(int w, int h);
    Q_INVOKABLE void stop();

    // as FrameCounter: frames since the last call, longest of them in ms
    Q_INVOKABLE int take() { return m_since.fetchAndStoreRelaxed(0); }
    Q_INVOKABLE int takeWorstMs()
    {
        QMutexLocker lock(&m_lock);
        const int w = int(m_worstNs / 1000000);
        m_worstNs = 0;
        return w;
    }

signals:
    void changed();

private:
    void work(int w, int h);
    void report(int phase, const QString &reason = QString());

    mutable QMutex m_lock;
    FunctionThread *m_thread = nullptr;
    QAtomicInt m_stop;
    QAtomicInt m_since;
    QPointer<OffscreenView> m_view;
    qint64 m_worstNs = 0;
    int m_phase = 0;
    int m_wanted = 3;
    QString m_glVersion, m_reason;
};

#endif // GLESBENCH_H
