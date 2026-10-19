/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "Offscreen.h"

#include <QQuickRenderControl>
#include <QQuickWindow>
#include <QQuickItem>
#include <QOffscreenSurface>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>
#include <QOpenGLExtraFunctions>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QStringList>
#include <QTimer>
#include <QDebug>

#ifndef GL_SYNC_GPU_COMMANDS_COMPLETE
#define GL_SYNC_GPU_COMMANDS_COMPLETE 0x9117
#endif
#ifndef GL_SYNC_FLUSH_COMMANDS_BIT
#define GL_SYNC_FLUSH_COMMANDS_BIT 0x00000001
#endif

QImage OffscreenImages::requestImage(const QString &, QSize *size, const QSize &)
{
    QMutexLocker lock(&m_lock);
    if (size) *size = m_image.size();
    return m_image;
}

void OffscreenImages::set(const QImage &image)
{
    QMutexLocker lock(&m_lock);
    m_image = image;
}

OffscreenImages *OffscreenRun::images()
{
    // owned by the engine it is added to
    static OffscreenImages *provider = new OffscreenImages;
    return provider;
}

OffscreenRun::OffscreenRun(QObject *parent)
    : QObject(parent)
{
    // torn down while the QML engine still stands: from the engine's own
    // teardown the stage's item went first and the app crashed on quit (C2)
    connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit, this, [this]() {
        emit quitting();   // the page saves the run while the stage still stands
        release();
    });
}

OffscreenRun::~OffscreenRun()
{
    release();
}

void OffscreenRun::release()
{
    stop();
    unload();
    if (m_context && m_surface) m_context->makeCurrent(m_surface);
    delete m_control;
    m_control = nullptr;
    delete m_window;
    m_window = nullptr;
    delete m_fbo;
    m_fbo = nullptr;
    if (m_context) m_context->doneCurrent();
    delete m_surface;
    m_surface = nullptr;
    delete m_context;
    m_context = nullptr;
}

QObject *OffscreenRun::item() const
{
    return m_item.data();
}

void OffscreenRun::setPreviewMs(int ms)
{
    if (ms == m_previewMs) return;
    m_previewMs = ms;
    emit previewMsChanged();
}

bool OffscreenRun::ensureGl(int width, int height)
{
    if (!m_context) {
        // ES 3 where the driver has it: fences keep the GPU's queue short
        QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
        fmt.setDepthBufferSize(24);
        fmt.setStencilBufferSize(8);
        fmt.setMajorVersion(3);
        fmt.setMinorVersion(0);
        m_context = new QOpenGLContext;
        m_context->setFormat(fmt);
        if (!m_context->create()) {
            fmt.setMajorVersion(2);
            m_context->setFormat(fmt);
            if (!m_context->create()) {
                delete m_context;
                m_context = nullptr;
                return false;
            }
        }
        // On Wayland this is a window that is never shown; frames go to
        // the framebuffer below, never to it.
        m_surface = new QOffscreenSurface;
        m_surface->setFormat(m_context->format());
        m_surface->create();
        if (!m_context->makeCurrent(m_surface)) return false;
        m_control = new QQuickRenderControl;
        m_window = new QQuickWindow(m_control);
        m_window->setColor(Qt::black);
        m_control->initialize(m_context);
    }
    if (!m_context->makeCurrent(m_surface)) return false;
    if (!m_fbo || m_fbo->size() != QSize(width, height)) {
        delete m_fbo;
        m_fbo = new QOpenGLFramebufferObject(QSize(width, height),
                                             QOpenGLFramebufferObject::CombinedDepthStencil);
        m_window->setRenderTarget(m_fbo);
    }
    m_window->setGeometry(0, 0, width, height);
    m_window->contentItem()->setSize(QSizeF(width, height));
    return true;
}

QString OffscreenRun::load(const QUrl &source, const QVariantMap &properties, int width, int height)
{
    if (!m_engine) m_engine = qmlEngine(this);
    if (!m_engine) return QStringLiteral("no QML engine");
    stop();
    unload();
    if (!ensureGl(width, height)) return QStringLiteral("no OpenGL context off screen");
    m_component = new QQmlComponent(m_engine, source);
    if (m_component->isError()) return m_component->errorString();
    QObject *o = m_component->beginCreate(m_engine->rootContext());
    if (!o) return m_component->errorString();
    for (auto it = properties.constBegin(); it != properties.constEnd(); ++it)
        o->setProperty(it.key().toUtf8().constData(), it.value());
    m_component->completeCreate();
    m_item = qobject_cast<QQuickItem *>(o);
    if (!m_item) {
        delete o;
        return QStringLiteral("not an item");
    }
    m_item->setParentItem(m_window->contentItem());
    m_item->setSize(QSizeF(width, height));
    m_frameNo = firstFrame;
    emit itemChanged();
    return QString();
}

void OffscreenRun::unload()
{
    if (m_context && m_surface) m_context->makeCurrent(m_surface);
    delete m_item.data();
    m_item.clear();
    delete m_component;
    m_component = nullptr;
    emit itemChanged();
}

void OffscreenRun::renderFrame()
{
    QOpenGLExtraFunctions *f = m_context->extraFunctions();
    const bool es3 = m_context->format().majorVersion() >= 3;
    // at most two frames queued: wait for the one before the last
    const int slot = int(m_frameNo % 3);
    if (es3 && m_fences[slot]) {
        f->glClientWaitSync(static_cast<GLsync>(m_fences[slot]), GL_SYNC_FLUSH_COMMANDS_BIT,
                            GLuint64(5000000000LL));
        f->glDeleteSync(static_cast<GLsync>(m_fences[slot]));
        m_fences[slot] = nullptr;
    }
    if (m_item) m_item->setProperty("t", double(m_frameNo) / 60.0);
    m_control->polishItems();
    m_control->sync();
    m_control->render();
    if (es3) m_fences[slot] = f->glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    f->glFlush();
    if (!es3 && m_frameNo % 2 == 1) f->glFinish();
    ++m_frameNo;
}

void OffscreenRun::finishGpu()
{
    QOpenGLExtraFunctions *f = m_context->extraFunctions();
    f->glFinish();
    if (m_context->format().majorVersion() < 3) return;
    for (void *&s : m_fences) {
        if (s) f->glDeleteSync(static_cast<GLsync>(s));
        s = nullptr;
    }
}

double OffscreenRun::phaseMs() const
{
    return (m_phase.nsecsElapsed() - m_pausedNs) / 1e6;
}

// The copy for the screen: the GPU drained first, which is measured work,
// then the read back and handing over, which is not.
void OffscreenRun::grabPreview()
{
    finishGpu();
    QElapsedTimer pause;
    pause.start();
    images()->set(m_fbo->toImage());
    emit preview(++m_serial);
    m_pausedNs += pause.nsecsElapsed();
    m_lastPreview = m_phase.elapsed();
}

void OffscreenRun::measure(int warmupMs, int measureMs)
{
    if (!m_item || !m_control) {
        emit failed(QStringLiteral("nothing loaded"));
        return;
    }
    m_warmupMs = warmupMs;
    m_measureMs = measureMs;
    m_measuring = false;
    m_frames = 0;
    m_halfFrames = -1;
    m_halfMs = 0;
    m_pausedNs = 0;
    m_lastPreview = -m_previewMs;
    m_running = true;
    emit runningChanged();
    m_phase.start();
    QTimer::singleShot(0, this, SLOT(slice()));
}

QVariantMap OffscreenRun::stop()
{
    QVariantMap at;
    if (!m_running) return at;
    m_running = false;
    if (m_context && m_surface && m_context->makeCurrent(m_surface)) finishGpu();
    if (m_measuring) {
        at.insert(QStringLiteral("frames"), m_frames);
        at.insert(QStringLiteral("ms"), phaseMs());
    }
    emit runningChanged();
    return at;
}

// Frames in slices of about 40 ms, so the app's own events (a tap to stop,
// the system asking whether the app still lives) get through in between.
void OffscreenRun::slice()
{
    if (!m_running) return;
    if (!m_context->makeCurrent(m_surface)) {
        m_running = false;
        emit runningChanged();
        emit failed(QStringLiteral("the off-screen context was lost"));
        return;
    }
    QElapsedTimer slice;
    slice.start();
    while (slice.elapsed() < 40) {
        renderFrame();
        // stopped from a handler of the frame (a stage that cannot run)
        if (!m_running) return;
        if (m_measuring) {
            ++m_frames;
            // the halves' scores apart are the measurement's own spread
            if (m_halfFrames < 0 && phaseMs() >= m_measureMs / 2.0) {
                finishGpu();
                m_halfFrames = m_frames;
                m_halfMs = phaseMs();
            }
            if (phaseMs() >= m_measureMs) {
                finishGpu();
                const double ms = phaseMs();
                m_running = false;
                if (m_previewMs > 0) grabPreview();
                emit runningChanged();
                emit finished(m_frames, ms, m_halfFrames, m_halfMs);
                return;
            }
        } else if (phaseMs() >= m_warmupMs) {
            // the warm-up's frames done before the clock starts
            finishGpu();
            m_measuring = true;
            m_frames = 0;
            m_pausedNs = 0;
            m_phase.start();
            m_lastPreview = 0;
        }
    }
    // the screen's copies only while warming up: the C2's GPU lost 5 % of a
    // measurement to them, so the measured seconds keep the last one still
    if (m_previewMs > 0 && !m_measuring && m_phase.elapsed() - m_lastPreview >= m_previewMs) grabPreview();
    emit progress(m_measuring, phaseMs(), m_frames);
    QTimer::singleShot(0, this, SLOT(slice()));
}

OffscreenSelftest::OffscreenSelftest(QQmlEngine *engine, const QString &spec, QObject *parent)
    : QObject(parent), m_run(new OffscreenRun(this))
{
    m_run->setEngine(engine);
    m_run->setPreviewMs(qEnvironmentVariableIsSet("SFOS_OFFSCREEN_PREVIEW")
                        ? qEnvironmentVariableIntValue("SFOS_OFFSCREEN_PREVIEW") : 0);
    const QStringList parts = spec.split(QLatin1Char(':'));
    m_stage = parts.value(0);
    for (const QString &l : parts.value(1).split(QLatin1Char(','), QString::SkipEmptyParts))
        m_loads << l.toInt();
    if (parts.size() > 2) m_warm = parts.at(2).toInt();
    if (parts.size() > 3) m_measure = parts.at(3).toInt();
    connect(m_run, &OffscreenRun::finished, this, &OffscreenSelftest::done);
    connect(m_run, &OffscreenRun::failed, this, &OffscreenSelftest::fail);
}

void OffscreenSelftest::start()
{
    QVariantMap props;
    props.insert(QStringLiteral("renderWidth"), 720);
    props.insert(QStringLiteral("renderHeight"), 1600);
    props.insert(QStringLiteral("areaTop"), 0);
    props.insert(QStringLiteral("areaBottom"), 1600);
    const QString err = m_run->load(QUrl::fromLocalFile(QStringLiteral("/usr/share/harbour-benchymark/qml/stages/")
                                                        + m_stage + QStringLiteral(".qml")), props);
    if (!err.isEmpty()) { fail(err); return; }
    next();
}

void OffscreenSelftest::next()
{
    if (++m_at >= m_loads.size()) {
        qInfo().noquote() << "OFFSCREEN done";
        QCoreApplication::quit();
        return;
    }
    if (m_run->item()) m_run->item()->setProperty("load", m_loads.at(m_at));
    m_run->measure(m_warm, m_measure);
}

void OffscreenSelftest::done(int frames, double ms, int halfFrames, double halfMs)
{
    const int load = m_loads.at(m_at);
    const double fps = frames * 1000.0 / ms;
    const double a = halfFrames * 1000.0 / halfMs;
    const double b = (frames - halfFrames) * 1000.0 / (ms - halfMs);
    QString why;
    if (m_run->item()) why = m_run->item()->property("unsupported").toString();
    qInfo().noquote() << QStringLiteral("OFFSCREEN %1 load %2 frames %3 ms %4 fps %5 work/s %6 halves %7 %8%9")
                         .arg(m_stage).arg(load).arg(frames).arg(ms, 0, 'f', 0).arg(fps, 0, 'f', 2)
                         .arg(fps * load, 0, 'f', 1).arg(a, 0, 'f', 2).arg(b, 0, 'f', 2)
                         .arg(why.isEmpty() ? QString() : QStringLiteral(" unsupported: ") + why);
    QTimer::singleShot(0, this, SLOT(next()));
}

void OffscreenSelftest::fail(const QString &why)
{
    qInfo().noquote() << "OFFSCREEN failed" << why;
    QCoreApplication::quit();
}
