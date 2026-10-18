/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef BUFFERREAD_H
#define BUFFERREAD_H

#include <QQuickFramebufferObject>
#include <QSize>

// SailfishOS: the GPU buffer stages (asked for on the forum by kan_ibal,
// 2026-10-18). Every pixel walks a 16 KB table of 1024 vec4, each index taken
// from the entry read before, so no read can be hoisted or shared. The same
// shader reads the table from a uniform buffer (UBO), a shader storage buffer
// (SSBO) or a float texture; only the read differs. Raw OpenGL ES 3.x: Qt
// 5.6's ShaderEffect cannot bind buffers.
//
// A GPU or driver that cannot run a mode says why in `failure`; the stage is
// then skipped and its row shows a dash.
class BufferRead : public QQuickFramebufferObject
{
    Q_OBJECT
    // "ubo", "ssbo" or "texture"
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    // table reads per pixel and frame
    Q_PROPERTY(int lookups READ lookups WRITE setLookups NOTIFY lookupsChanged)
    // seconds, drives the picture
    Q_PROPERTY(qreal t READ t WRITE setT NOTIFY tChanged)
    // sfos-2.0: the framebuffer's size in pixels, the page's fixed render
    // size; empty follows the item (an FBO ignores the stage's layer size)
    Q_PROPERTY(QSize renderSize READ renderSize WRITE setRenderSize NOTIFY renderSizeChanged)
    // empty while it runs, else why it cannot
    Q_PROPERTY(QString failure READ failure NOTIFY failureChanged)

public:
    explicit BufferRead(QQuickItem *parent = nullptr);
    Renderer *createRenderer() const override;

    QString mode() const { return m_mode; }
    void setMode(const QString &m);
    int lookups() const { return m_lookups; }
    void setLookups(int n);
    qreal t() const { return m_t; }
    void setT(qreal t);
    QString failure() const { return m_failure; }
    QSize renderSize() const { return m_renderSize; }
    void setRenderSize(const QSize &s);

    // from the render thread, queued
    Q_INVOKABLE void setFailure(const QString &why);

signals:
    void modeChanged();
    void lookupsChanged();
    void tChanged();
    void failureChanged();
    void renderSizeChanged();

private:
    QString m_mode = QStringLiteral("ubo");
    int m_lookups = 16;
    qreal m_t = 0;
    QString m_failure;
    QSize m_renderSize;
};

#endif // BUFFERREAD_H
