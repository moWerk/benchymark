/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "Dots.h"

#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>

// two triangles per dot; the scene graph merges with 16 bit indices, so one
// node stays below 65535 vertices (see Wireframe)
static const int kDotsPerNode = 10000;

Dots::Dots(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    // Qt 5.6 cannot queue a lambda with invokeMethod; a queued signal can
    connect(this, &Dots::updateRequested, this, &Dots::doUpdate, Qt::QueuedConnection);
}

void Dots::setDotSize(qreal s)
{
    if (s == m_size) return;
    m_size = s;
    emit dotSizeChanged();
    update();
}

void Dots::setCapacity(int c)
{
    c = qMax(1, c);
    if (c == m_capacity.load()) return;
    m_capacity.store(c);
    emit capacityChanged();
}

int Dots::count() const
{
    return qMin(m_added.load(), m_capacity.load());
}

void Dots::scheduleUpdate()
{
    // from any thread: update() must run on the GUI thread
    if (m_updateQueued.testAndSetOrdered(0, 1))
        emit updateRequested();
}

void Dots::doUpdate()
{
    m_updateQueued.store(0);
    update();
    emit countChanged();
}

void Dots::add(float x, float y, const QColor &c)
{
    {
        QMutexLocker lock(&m_lock);
        m_pending.append({ x, y, quint8(c.red()), quint8(c.green()), quint8(c.blue()) });
    }
    m_added.ref();
    scheduleUpdate();
}

void Dots::addMany(const QVector<Dot> &dots)
{
    if (dots.isEmpty()) return;
    {
        QMutexLocker lock(&m_lock);
        m_pending += dots;
    }
    m_added.fetchAndAddOrdered(dots.size());
    scheduleUpdate();
}

void Dots::addPoints(const QVariantList &xy, const QColor &c)
{
    QVector<Dot> batch;
    batch.reserve(xy.size() / 2);
    for (int i = 0; i + 1 < xy.size(); i += 2)
        batch.append({ xy.at(i).toFloat(), xy.at(i + 1).toFloat(),
                       quint8(c.red()), quint8(c.green()), quint8(c.blue()) });
    addMany(batch);
}

void Dots::clear()
{
    {
        QMutexLocker lock(&m_lock);
        m_pending.clear();
        m_clearPending = true;
    }
    m_added.store(0);
    scheduleUpdate();
}

QSGNode *Dots::updatePaintNode(QSGNode *old, UpdatePaintNodeData *)
{
    QSGNode *root = old ? old : new QSGNode;
    QVector<Dot> fresh;
    bool cleared = false;
    {
        QMutexLocker lock(&m_lock);
        fresh.swap(m_pending);
        cleared = m_clearPending;
        m_clearPending = false;
    }
    const int cap = m_capacity.load();
    const float s = float(m_size);
    // a cleared field, a new dot size or a new capacity draws everything anew
    const bool all = cleared || s != m_shownSize || (m_ring.size() > cap);
    if (cleared || m_ring.size() > cap) { m_ring.clear(); m_written = 0; }
    m_shownSize = s;

    // new dots take the oldest slots once the ring is full
    QVector<char> dirty;
    const int nodesBefore = root->childCount();
    for (const Dot &d : fresh) {
        const int slot = int(m_written % cap);
        if (slot < m_ring.size()) m_ring[slot] = d;
        else m_ring.append(d);
        ++m_written;
        const int node = slot / kDotsPerNode;
        if (node >= dirty.size()) dirty.resize(node + 1);
        dirty[node] = 1;
    }
    const int used = m_ring.size();
    const int nodes = (used + kDotsPerNode - 1) / kDotsPerNode;
    while (root->childCount() > nodes) {
        QSGNode *n = root->lastChild();
        root->removeChildNode(n);
        delete n;
    }
    while (root->childCount() < nodes) {
        QSGGeometryNode *node = new QSGGeometryNode;
        QSGGeometry *g = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
        g->setDrawingMode(GL_TRIANGLES);
        node->setGeometry(g);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(new QSGVertexColorMaterial);
        node->setFlag(QSGNode::OwnsMaterial);
        root->appendChildNode(node);
    }
    int j = 0;
    for (QSGNode *child = root->firstChild(); child; child = child->nextSibling(), ++j) {
        const bool touched = all || j >= nodesBefore || (j < dirty.size() && dirty[j]);
        if (!touched) continue;
        QSGGeometryNode *node = static_cast<QSGGeometryNode *>(child);
        const int first = j * kDotsPerNode;
        const int n = qMin(kDotsPerNode, used - first);
        QSGGeometry *g = node->geometry();
        if (g->vertexCount() != n * 6)
            g->allocate(n * 6);
        QSGGeometry::ColoredPoint2D *v = g->vertexDataAsColoredPoint2D();
        for (int k = 0; k < n; ++k) {
            const Dot &d = m_ring.at(first + k);
            const float x0 = d.x - s / 2, y0 = d.y - s / 2, x1 = x0 + s, y1 = y0 + s;
            v[0].set(x0, y0, d.r, d.g, d.b, 255);
            v[1].set(x1, y0, d.r, d.g, d.b, 255);
            v[2].set(x0, y1, d.r, d.g, d.b, 255);
            v[3].set(x1, y0, d.r, d.g, d.b, 255);
            v[4].set(x1, y1, d.r, d.g, d.b, 255);
            v[5].set(x0, y1, d.r, d.g, d.b, 255);
            v += 6;
        }
        node->markDirty(QSGNode::DirtyGeometry);
    }
    return root;
}
