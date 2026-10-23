/*
 * SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * SailfishOS: the VULKAN stage. It computes Shader heavy's field through
 * Vulkan, without a window, into an image in memory, and counts its own
 * frames: the window never sees that work, so the page samples the engine
 * instead of FrameCounter (`frameSource` in MainPage.qml).
 *
 * libvulkan is opened at run time, never linked. On a device without
 * libhybris-libvulkan the app must still start, and the stage simply reports
 * that there is no Vulkan here.
 */
#ifndef VULKANBENCH_H
#define VULKANBENCH_H

#include <QAtomicInt>
#include <QImage>
#include <QMutex>
#include <QObject>
#include <QPointer>
#include <QQuickPaintedItem>
#include <QString>

#include "SystemBench.h"   // FunctionThread

// Shows what an offscreen stage drew. The worker thread hands over an image
// once a second; painting happens on the GUI thread.
class OffscreenView : public QQuickPaintedItem
{
    Q_OBJECT
public:
    explicit OffscreenView(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;
    // callable from any thread
    void setPicture(const QImage &picture);
    // Every nth pixel instead of a smooth scale: QImage::scaled with
    // SmoothTransformation costs over a hundred milliseconds on 1.8 Mpix and
    // would show up as the stage's worst frame. A preview only has to show
    // that something is being drawn.
    static QImage shrink(const uchar *pixels, int w, int h, int step, bool flip);
private:
    mutable QMutex m_lock;
    QImage m_picture;
};

class VulkanEngine : public QObject
{
    Q_OBJECT
    // -1 no Vulkan, 0 idle, 2 running, 3 done
    Q_PROPERTY(int phase READ phase NOTIFY changed)
    Q_PROPERTY(QString device READ device NOTIFY changed)
    Q_PROPERTY(QString api READ api NOTIFY changed)
    // why it does not work, in one line
    Q_PROPERTY(QString reason READ reason NOTIFY changed)
    Q_PROPERTY(OffscreenView *view READ view WRITE setView)
public:
    explicit VulkanEngine(QObject *parent = nullptr);
    ~VulkanEngine() override;

    int phase() const { QMutexLocker l(&m_lock); return m_phase; }
    QString device() const { QMutexLocker l(&m_lock); return m_device; }
    QString api() const { QMutexLocker l(&m_lock); return m_api; }
    QString reason() const { QMutexLocker l(&m_lock); return m_reason; }
    OffscreenView *view() const { return m_view; }
    void setView(OffscreenView *v) { m_view = v; }

    // Draws until stop(); the page ends the stage like any other.
    Q_INVOKABLE void start(int w, int h);
    Q_INVOKABLE void stop();

    // The same two questions FrameCounter answers: frames since the last
    // call, and the longest of them in ms.
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
    QString m_device, m_api, m_reason;
};

#endif // VULKANBENCH_H
