/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "Wireframe.h"
#include "benchymesh.h"

#include <QSGGeometryNode>
#include <QSGMaterial>
#include <QOpenGLShaderProgram>
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
    // copies x stack bounded: 640 x 1000 boats would ask for gigabytes
    s = qBound(1, s, qMax(1, 8000 / qMax(1, m_copies)));
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

// The boat is projected on the GPU (2.3): each node holds its boats' model
// coordinates, uploaded once, and a material that turns, tilts and projects
// them in the vertex shader. Until 2.2 the CPU projected every vertex each
// frame and the scene graph uploaded it all again; the driver then waited
// for the GPU before the upload, and the GPU waited for the next frame's
// projection, so it never got busy enough for its governor to clock up
// (Pro1-X: 465-745 of 950 MHz in Benchy small).

namespace {

struct BoatVertex {
    float x, y, z;
    unsigned char r, g, b, a;
};

const QSGGeometry::AttributeSet &boatAttributes()
{
    // no attribute marked as the position: the renderer cannot read screen
    // bounds from model coordinates, so it treats the boats as overlapping
    // everything and keeps the drawing order
    static QSGGeometry::Attribute attr[] = {
        QSGGeometry::Attribute::create(0, 3, GL_FLOAT, false),
        QSGGeometry::Attribute::create(1, 4, GL_UNSIGNED_BYTE, false),
    };
    static QSGGeometry::AttributeSet set = { 2, sizeof(BoatVertex), attr };
    return set;
}

class BoatMaterial : public QSGMaterial
{
public:
    BoatMaterial() { setFlag(Blending, true); }
    QSGMaterialType *type() const override { static QSGMaterialType t; return &t; }
    QSGMaterialShader *createShader() const override;
    int compare(const QSGMaterial *other) const override
    {
        // never merged: every cell has its own place and turn
        return this == other ? 0 : (this < other ? -1 : 1);
    }

    float cx = 0, cy = 0, k = 0, ca = 1, sa = 0;
};

class BoatShader : public QSGMaterialShader
{
public:
    const char *vertexShader() const override
    {
        // the same rotate -> tilt -> perspective as 2.2 did on the CPU
        return "attribute highp vec4 pos;\n"
               "attribute lowp vec4 col;\n"
               "uniform highp mat4 qt_Matrix;\n"
               "uniform highp vec3 place;\n"      // cell centre x, y; scale
               "uniform highp vec2 turn;\n"       // cos, sin of the turn
               "uniform lowp float opacity;\n"
               "varying lowp vec4 color;\n"
               "void main() {\n"
               "    highp float rx = pos.x * turn.x - pos.y * turn.y;\n"
               "    highp float ry = pos.x * turn.y + pos.y * turn.x;\n"
               "    highp float depth = ry * 0.913089 - pos.z * 0.407760;\n"   // tilt 0.42
               "    highp float up = ry * 0.407760 + pos.z * 0.913089;\n"
               "    highp float f = place.z * 2800.0 / (2800.0 + depth);\n"
               "    color = col * opacity;\n"
               "    gl_Position = qt_Matrix * vec4(place.x + rx * f, place.y - up * f, 0.0, 1.0);\n"
               "}\n";
    }
    const char *fragmentShader() const override
    {
        return "varying lowp vec4 color;\n"
               "void main() { gl_FragColor = color; }\n";
    }
    char const *const *attributeNames() const override
    {
        static const char *const names[] = { "pos", "col", nullptr };
        return names;
    }
    void initialize() override
    {
        m_matrix = program()->uniformLocation("qt_Matrix");
        m_opacity = program()->uniformLocation("opacity");
        m_place = program()->uniformLocation("place");
        m_turn = program()->uniformLocation("turn");
    }
    void updateState(const RenderState &state, QSGMaterial *newMaterial, QSGMaterial *) override
    {
        if (state.isMatrixDirty()) program()->setUniformValue(m_matrix, state.combinedMatrix());
        if (state.isOpacityDirty()) program()->setUniformValue(m_opacity, state.opacity());
        const BoatMaterial *m = static_cast<BoatMaterial *>(newMaterial);
        program()->setUniformValue(m_place, m->cx, m->cy, m->k);
        program()->setUniformValue(m_turn, m->ca, m->sa);
    }

private:
    int m_matrix = -1, m_opacity = -1, m_place = -1, m_turn = -1;
};

QSGMaterialShader *BoatMaterial::createShader() const { return new BoatShader; }

} // namespace

// The scene graph indexes geometry with 16 bits, so one node holds at most
// 65535 vertices; a cell's stack is spread over nodes of kBoatsPerNode boats.
static const int kBoatsPerNode = 40;   // 40 x 630 segments x 2 = 50400 vertices

QSGNode *Wireframe::updatePaintNode(QSGNode *old, UpdatePaintNodeData *)
{
    QSGNode *root = old ? old : new QSGNode;
    const int perCell = (m_stack + kBoatsPerNode - 1) / kBoatsPerNode;
    const int nodes = m_copies * perCell;

    while (root->childCount() > nodes) {
        QSGNode *n = root->lastChild();
        root->removeChildNode(n);
        delete n;
    }
    while (root->childCount() < nodes) {
        QSGGeometryNode *node = new QSGGeometryNode;
        QSGGeometry *g = new QSGGeometry(boatAttributes(), 0);
        g->setDrawingMode(GL_LINES);
        g->setLineWidth(1);
        g->setVertexDataPattern(QSGGeometry::StaticPattern);
        node->setGeometry(g);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(new BoatMaterial);
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

    int i = 0;
    for (QSGNode *child = root->firstChild(); child; child = child->nextSibling(), ++i) {
        QSGGeometryNode *node = static_cast<QSGGeometryNode *>(child);
        const int c = i / perCell;   // the cell; its stack lies on one spot
        const int count = qMin(kBoatsPerNode, m_stack - (i % perCell) * kBoatsPerNode);

        // the model, once: count boats on top of each other
        QSGGeometry *g = node->geometry();
        if (g->vertexCount() != count * kBenchySegmentCount * 2) {
            g->allocate(count * kBenchySegmentCount * 2);
            BoatVertex *v = static_cast<BoatVertex *>(g->vertexData());
            for (int b = 0; b < count; ++b) {
                for (int s = 0; s < kBenchySegmentCount; ++s) {
                    const unsigned char *seg = kBenchySegments[s];
                    const unsigned char *col = kStripColor[seg[2] % 6];
                    for (int e = 0; e < 2; ++e, ++v) {
                        const short *p = kBenchyVertices + seg[e] * 3;
                        *v = { float(p[0]), float(p[1]), float(p[2]), col[0], col[1], col[2], 255 };
                    }
                }
            }
            node->markDirty(QSGNode::DirtyGeometry);
        }

        // each cell a little further round, so a grid is not one picture;
        // with counterRotate every other cell turns back
        const qreal turn = (m_counter && (c % 2)) ? -m_angle : m_angle;
        const qreal a = (turn + c * 360.0 / qMax(1, m_copies) * 0.618) * M_PI / 180.0;
        BoatMaterial *m = static_cast<BoatMaterial *>(node->material());
        m->cx = float(x0 + (c % cols + 0.5) * cell);
        m->cy = float(y0 + (c / cols + 0.5) * cell);
        m->k = float(k);
        m->ca = float(std::cos(a));
        m->sa = float(std::sin(a));
        node->markDirty(QSGNode::DirtyMaterial);
    }
    return root;
}
