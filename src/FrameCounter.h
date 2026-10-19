/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef FRAMECOUNTER_H
#define FRAMECOUNTER_H

#include <QAtomicInt>
#include <QElapsedTimer>
#include <QMutex>
#include <QObject>
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QScreen>
#include <QVariantMap>
#include <QWindow>

// SailfishOS: counts the frames the window actually presented. On the watch
// QML connects to Window.frameSwapped; Qt 5.6 QML has no Window attached
// property, so main.cpp connects the view's frameSwapped here (directly, on
// the render thread). QML takes the count once a second.
class FrameCounter : public QObject
{
    Q_OBJECT
    // the GPU as the GL driver names it, read once on the render thread
    Q_PROPERTY(QString gpu READ gpu NOTIFY gpuChanged)
    // the context's GL and GLSL version strings, e.g. "OpenGL ES 3.2 v1.r32p1"
    // and "OpenGL ES GLSL ES 3.20": which buffer types a device can run
    Q_PROPERTY(QString glVersion READ glVersion NOTIFY gpuChanged)
    Q_PROPERTY(QString glslVersion READ glslVersion NOTIFY gpuChanged)
    // the panel's refresh rate as the platform reports it (Qt falls back to
    // 60 when it does not know), to flag scores capped by vsync
    Q_PROPERTY(qreal refreshRate READ refreshRate NOTIFY refreshRateChanged)
public:
    QString gpu() const { QMutexLocker lock(&m_lock); return m_gpu; }
    QString glVersion() const { QMutexLocker lock(&m_lock); return m_glVersion; }
    QString glslVersion() const { QMutexLocker lock(&m_lock); return m_glslVersion; }

    explicit FrameCounter(QObject *parent = nullptr) : QObject(parent) { m_clock.start(); }

    // frames since the last call, and the longest gap between two of them in ms
    Q_INVOKABLE int take() { return m_frames.fetchAndStoreRelaxed(0); }
    Q_INVOKABLE int takeWorstMs()
    {
        QMutexLocker lock(&m_lock);
        const int w = int(m_worstNs / 1000000);
        m_worstNs = 0;
        return w;
    }
    // One measuring window: the frames since the last sample() or reset(),
    // the exact time that passed on a monotonic clock, and the longest frame.
    // The score sums frames and time over a stage instead of averaging
    // rounded fps (audit 2026-10-19).
    Q_INVOKABLE QVariantMap sample()
    {
        QVariantMap m;
        QMutexLocker lock(&m_lock);
        const qint64 now = m_clock.nsecsElapsed();
        m.insert(QStringLiteral("frames"), m_frames.fetchAndStoreRelaxed(0));
        m.insert(QStringLiteral("ms"), double(now - m_windowStart) / 1e6);
        m.insert(QStringLiteral("worstMs"), double(m_worstNs) / 1e6);
        m_windowStart = now;
        m_worstNs = 0;
        return m;
    }
    // A new window from now: after a load change, a stage start or a pause,
    // so build time and the gap are never counted as a frame or a second.
    Q_INVOKABLE void reset()
    {
        QMutexLocker lock(&m_lock);
        m_frames.fetchAndStoreRelaxed(0);
        m_windowStart = m_clock.nsecsElapsed();
        m_worstNs = 0;
        m_last = 0;
    }

    qreal refreshRate() const { return m_refresh; }
    void watch(QWindow *w)
    {
        if (!w) return;
        auto bind = [this](QScreen *s) {
            if (!s) return;
            setRefresh(s->refreshRate());
            connect(s, &QScreen::refreshRateChanged, this, &FrameCounter::setRefresh, Qt::UniqueConnection);
        };
        bind(w->screen());
        connect(w, &QWindow::screenChanged, this, bind);
    }

signals:
    void gpuChanged();
    void refreshRateChanged();

public slots:
    // connected to sceneGraphInitialized, on the render thread with the
    // GL context current
    void readGpu()
    {
        QOpenGLContext *ctx = QOpenGLContext::currentContext();
        if (!ctx) return;
        QOpenGLFunctions *f = ctx->functions();
        const auto str = [f](GLenum name) {
            const GLubyte *v = f->glGetString(name);
            return v ? QString::fromLatin1(reinterpret_cast<const char *>(v)) : QString();
        };
        {
            QMutexLocker lock(&m_lock);
            m_gpu = str(GL_RENDERER);
            m_glVersion = str(GL_VERSION);
            m_glslVersion = str(GL_SHADING_LANGUAGE_VERSION);
        }
        QMetaObject::invokeMethod(this, "gpuChanged", Qt::QueuedConnection);
    }

    void setRefresh(qreal hz)
    {
        if (qFuzzyCompare(hz, m_refresh)) return;
        m_refresh = hz;
        emit refreshRateChanged();
    }

    void frameSwapped()
    {
        m_frames.ref();
        QMutexLocker lock(&m_lock);
        const qint64 now = m_clock.nsecsElapsed();
        if (m_last > 0 && now - m_last > m_worstNs)
            m_worstNs = now - m_last;
        m_last = now;
    }

private:
    QAtomicInt m_frames;
    mutable QMutex m_lock;
    QString m_gpu;
    QString m_glVersion;
    QString m_glslVersion;
    QElapsedTimer m_clock;
    qint64 m_last = 0;
    qint64 m_worstNs = 0;
    qint64 m_windowStart = 0;
    qreal m_refresh = 0;
};

#endif // FRAMECOUNTER_H
