/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef OFFSCREEN_H
#define OFFSCREEN_H

#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVariantMap>
#include <QElapsedTimer>
#include <QImage>
#include <QMutex>
#include <QQuickImageProvider>

class QQuickRenderControl;
class QQuickWindow;
class QQuickItem;
class QOffscreenSurface;
class QOpenGLContext;
class QOpenGLFramebufferObject;
class QQmlEngine;
class QQmlComponent;

// The last frame a stage drew off screen, for the page: image://offscreen/<n>
class OffscreenImages : public QQuickImageProvider
{
public:
    OffscreenImages() : QQuickImageProvider(QQuickImageProvider::Image) { }
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override;
    void set(const QImage &image);
private:
    QMutex m_lock;
    QImage m_image;
};

// A graphics stage measured off screen (2.2): drawn into a framebuffer of
// the render size as fast as the device can, no vsync, no compositor, no
// scaling to the panel. On screen, the frame rate of a composited window
// carried the refresh cap and a fixed cost of 12-25 ms per frame, and the
// scores bent around both (night audit, 2026-10-19). The stage's picture
// is a function of its frame number (its property t, seconds at 60 frames
// per second), so every device draws the same frames.
class OffscreenRun : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QObject *item READ item NOTIFY itemChanged)
    // the screen's copy of the frames while warming up, every so many ms
    // (0: none), and one of the last frame
    Q_PROPERTY(int previewMs READ previewMs WRITE setPreviewMs NOTIFY previewMsChanged)
public:
    explicit OffscreenRun(QObject *parent = nullptr);
    ~OffscreenRun();

    static OffscreenImages *images();
    void setEngine(QQmlEngine *engine) { m_engine = engine; }
    bool running() const { return m_running; }
    QObject *item() const;
    int previewMs() const { return m_previewMs; }
    void setPreviewMs(int ms);

    // The frame the stage starts at, the same with or without the page's
    // two seconds on screen before (which end there): every device draws
    // the same frames either way.
    static const int firstFrame = 120;
    // builds the stage; "" when it stands, else why not
    Q_INVOKABLE QString load(const QUrl &source, const QVariantMap &properties,
                             int width = 720, int height = 1600);
    Q_INVOKABLE void unload();
    // frames for warmupMs uncounted, then frames for measureMs counted
    Q_INVOKABLE void measure(int warmupMs, int measureMs);
    // ends a measurement; what was measured so far, for a row cut short
    Q_INVOKABLE QVariantMap stop();
    // everything off screen gone, the GL context too
    Q_INVOKABLE void release();

signals:
    void runningChanged();
    void itemChanged();
    void previewMsChanged();
    // the measured frames and time, and the first half's
    void finished(int frames, double ms, int halfFrames, double halfMs);
    void failed(const QString &why);
    // a new copy of the frames for the screen, and where the stage stands
    void preview(int serial);
    void progress(bool measuring, double ms, int frames);
    // the app quits: last chance to save, then everything goes
    void quitting();

private slots:
    void slice();

private:
    bool ensureGl(int width, int height);
    void renderFrame();
    void finishGpu();
    double phaseMs() const;
    void grabPreview();

    QQmlEngine *m_engine = nullptr;
    QQuickRenderControl *m_control = nullptr;
    QQuickWindow *m_window = nullptr;
    QOffscreenSurface *m_surface = nullptr;
    QOpenGLContext *m_context = nullptr;
    QOpenGLFramebufferObject *m_fbo = nullptr;
    QQmlComponent *m_component = nullptr;
    QPointer<QQuickItem> m_item;

    bool m_running = false;
    bool m_measuring = false;
    int m_warmupMs = 0;
    int m_measureMs = 0;
    int m_previewMs = 1000;
    int m_serial = 0;
    qint64 m_frameNo = 0;      // the frame drawn next: the stage's time
    int m_frames = 0;          // frames counted in the measured time
    int m_halfFrames = -1;     // and at its half
    double m_halfMs = 0;
    QElapsedTimer m_phase;     // since warm-up or measuring began
    qint64 m_pausedNs = 0;     // of that, the screen's copies: not measured
    qint64 m_lastPreview = 0;
    void *m_fences[3] = { nullptr, nullptr, nullptr };
};

// Test hook SFOS_OFFSCREEN_TEST=<stage file>:<load>,<load>,...[:warm ms:measure ms]:
// each load off screen, the frames and the work per second in the log,
// then the app quits.
class OffscreenSelftest : public QObject
{
    Q_OBJECT
public:
    OffscreenSelftest(QQmlEngine *engine, const QString &spec, QObject *parent = nullptr);
    void start();
private slots:
    void next();
    void done(int frames, double ms, int halfFrames, double halfMs);
    void fail(const QString &why);
private:
    OffscreenRun *m_run;
    QString m_stage;
    QList<int> m_loads;
    int m_at = -1;
    int m_warm = 2000;
    int m_measure = 6000;
};

#endif
