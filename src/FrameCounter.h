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

// SailfishOS: counts the frames the window actually presented. On the watch
// QML connects to Window.frameSwapped; Qt 5.6 QML has no Window attached
// property, so main.cpp connects the view's frameSwapped here (directly, on
// the render thread). QML takes the count once a second.
class FrameCounter : public QObject
{
    Q_OBJECT
    // the GPU as the GL driver names it, read once on the render thread
    Q_PROPERTY(QString gpu READ gpu NOTIFY gpuChanged)
public:
    QString gpu() const { QMutexLocker lock(&m_lock); return m_gpu; }

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

signals:
    void gpuChanged();

public slots:
    // connected to sceneGraphInitialized, on the render thread with the
    // GL context current
    void readGpu()
    {
        QOpenGLContext *ctx = QOpenGLContext::currentContext();
        if (!ctx) return;
        const GLubyte *r = ctx->functions()->glGetString(GL_RENDERER);
        {
            QMutexLocker lock(&m_lock);
            m_gpu = r ? QString::fromLatin1(reinterpret_cast<const char *>(r)) : QString();
        }
        QMetaObject::invokeMethod(this, "gpuChanged", Qt::QueuedConnection);
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
    QElapsedTimer m_clock;
    qint64 m_last = 0;
    qint64 m_worstNs = 0;
};

#endif // FRAMECOUNTER_H
