/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef DOTS_H
#define DOTS_H

#include <QAtomicInt>
#include <QColor>
#include <QMutex>
#include <QQuickItem>
#include <QVector>

// SailfishOS: a field of small square dots, the canvas of the system stages
// (the prime spiral, the storage grid, the counter's random dots). Dots are
// only ever added; a new one is drawn over the older ones. Positions are in
// item coordinates. add() may be called from any thread.
class Dots : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(qreal dotSize READ dotSize WRITE setDotSize NOTIFY dotSizeChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    // the oldest dots are dropped past this many
    Q_PROPERTY(int capacity READ capacity WRITE setCapacity NOTIFY capacityChanged)

public:
    struct Dot { float x, y; quint8 r, g, b; };

    explicit Dots(QQuickItem *parent = nullptr);

    qreal dotSize() const { return m_size; }
    void setDotSize(qreal s);
    int capacity() const { return m_capacity.load(); }
    void setCapacity(int c);
    int count() const;

    // thread safe; the picture updates on the next frame
    void add(float x, float y, const QColor &c);
    void addMany(const QVector<Dot> &dots);
    Q_INVOKABLE void addDot(qreal x, qreal y, const QColor &c) { add(float(x), float(y), c); }
    // flat [x, y, x, y, ...] in one colour, for QML batches
    Q_INVOKABLE void addPoints(const QVariantList &xy, const QColor &c);
    Q_INVOKABLE void clear();

signals:
    void dotSizeChanged();
    void countChanged();
    void capacityChanged();
    void updateRequested();   // queued to the GUI thread

protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *) override;

private:
    void scheduleUpdate();
    void doUpdate();

    // Workers only append to m_pending under the lock, which the render
    // thread swaps out at once: the CPU stages' threads no longer wait while
    // a frame's vertices are written, and a full field no longer moves its
    // dots in memory on every add (night audit, 2026-10-19). The render
    // thread keeps the shown dots in a ring and rewrites only changed nodes.
    mutable QMutex m_lock;
    QVector<Dot> m_pending;
    bool m_clearPending = false;
    QAtomicInt m_added;          // dots added since the last clear
    qreal m_size = 3.0;
    QAtomicInt m_capacity { 120000 };
    // render thread only
    QVector<Dot> m_ring;
    qint64 m_written = 0;
    float m_shownSize = -1;
    QAtomicInt m_updateQueued;
};

#endif // DOTS_H
