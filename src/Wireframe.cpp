/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "Wireframe.h"
#include "benchymesh.h"

#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>
#include <cmath>

// the watch's three blues, two strips each
static const unsigned char kStripColor[6][3] = {
    { 0x58, 0xa6, 0xff }, { 0x58, 0xa6, 0xff },
    { 0x79, 0xc0, 0xff }, { 0x79, 0xc0, 0xff },
    { 0xa5, 0xd6, 0xff }, { 0xa5, 0xd6, 0xff },
};

Wireframe::Wireframe(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void Wireframe::setAngle(qreal a)
{
    if (a == m_angle) return;
    m_angle = a;
    emit angleChanged();
    update();
}

void Wireframe::setCopies(int c)
{
    c = qBound(1, c, 400);
    if (c == m_copies) return;
    m_copies = c;
    emit copiesChanged();
    update();
}

void Wireframe::setFill(qreal f)
{
    if (f == m_fill) return;
    m_fill = f;
    emit fillChanged();
    update();
}

void Wireframe::setStack(int s)
{
    s = qBound(1, s, 1000);
    if (s == m_stack) return;
    m_stack = s;
    emit stackChanged();
    update();
}

void Wireframe::setCounterRotate(bool c)
{
    if (c == m_counter) return;
    m_counter = c;
    emit counterRotateChanged();
    update();
}

// The scene graph merges geometry with 16 bit indices, so one node can hold
// at most 65535 vertices; past that the rest of the boats silently vanished.
// The boats are spread over several nodes of at most kBoatsPerNode each.
static const int kBoatsPerNode = 40;   // 40 x 630 segments x 2 = 50400 vertices

QSGNode *Wireframe::updatePaintNode(QSGNode *old, UpdatePaintNodeData *)
{
    QSGNode *root = old ? old : new QSGNode;
    const int boats = m_copies * m_stack;
    const int nodes = (boats + kBoatsPerNode - 1) / kBoatsPerNode;

    // as many child nodes as needed, each with its own line geometry
    while (root->childCount() > nodes) {
        QSGNode *n = root->lastChild();
        root->removeChildNode(n);
        delete n;
    }
    while (root->childCount() < nodes) {
        QSGGeometryNode *node = new QSGGeometryNode;
        QSGGeometry *g = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
        g->setDrawingMode(GL_LINES);
        g->setLineWidth(1);
        node->setGeometry(g);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(new QSGVertexColorMaterial);
        node->setFlag(QSGNode::OwnsMaterial);
        root->appendChildNode(node);
    }

    // the copies on a grid of SQUARE cells, centred, so the gap between the
    // boats is the gap to the edges (mo, 2026-10-17: the taller cells of a
    // portrait screen doubled the vertical gaps)
    const qreal w = width(), h = height();
    int cols = qMax(1, int(std::ceil(std::sqrt(m_copies * w / qMax(qreal(1), h)))));
    int rows = (m_copies + cols - 1) / cols;
    const qreal cell = qMin(w / cols, h / rows);
    const qreal x0 = (w - cols * cell) / 2, y0 = (h - rows * cell) / 2;
    // the watch: the +/-1000 cube to 0.42 of the panel size, perspective 2800
    const qreal k = cell * 0.00042 * m_fill;
    const qreal dist = 2800.0;
    const qreal tilt = 0.42, ct = std::cos(tilt), st = std::sin(tilt);

    float px[kBenchyVertexCount], py[kBenchyVertexCount];
    int n = 0;
    for (QSGNode *child = root->firstChild(); child; child = child->nextSibling()) {
        QSGGeometryNode *node = static_cast<QSGGeometryNode *>(child);
        const int count = qMin(kBoatsPerNode, boats - n);
        QSGGeometry *g = node->geometry();
        if (g->vertexCount() != count * kBenchySegmentCount * 2)
            g->allocate(count * kBenchySegmentCount * 2);
        QSGGeometry::ColoredPoint2D *v = g->vertexDataAsColoredPoint2D();

        for (int b = 0; b < count; ++b, ++n) {
            const int c = n / m_stack;       // the cell; the rest of the stack lies on it
            const qreal cx = x0 + (c % cols + 0.5) * cell;
            const qreal cy = y0 + (c / cols + 0.5) * cell;
            // each cell a little further round, so a grid is not one picture;
            // with counterRotate every other cell turns back
            const qreal turn = (m_counter && (c % 2)) ? -m_angle : m_angle;
            const qreal a = (turn + c * 360.0 / qMax(1, m_copies) * 0.618) * M_PI / 180.0;
            const qreal ca = std::cos(a), sa = std::sin(a);
            for (int i = 0; i < kBenchyVertexCount; ++i) {
                const qreal x = kBenchyVertices[i * 3], y = kBenchyVertices[i * 3 + 1],
                            z = kBenchyVertices[i * 3 + 2];
                const qreal rx = x * ca - y * sa;
                const qreal ry = x * sa + y * ca;
                const qreal depth = ry * ct - z * st;
                const qreal up = ry * st + z * ct;
                const qreal f = dist / (dist + depth);
                px[i] = float(cx + rx * k * f);
                py[i] = float(cy - up * k * f);
            }
            for (int s = 0; s < kBenchySegmentCount; ++s) {
                const unsigned char *seg = kBenchySegments[s];
                const unsigned char *col = kStripColor[seg[2] % 6];
                for (int e = 0; e < 2; ++e) {
                    v->set(px[seg[e]], py[seg[e]], col[0], col[1], col[2], 255);
                    ++v;
                }
            }
        }
        node->markDirty(QSGNode::DirtyGeometry);
    }
    return root;
}
