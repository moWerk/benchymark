/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef WIREFRAME_H
#define WIREFRAME_H

#include <QQuickItem>

// SailfishOS: the 3DBenchy wireframe. On the watch QML projects the mesh
// and QtQuick.Shapes strokes it; Qt 5.6 has no Shapes, so this item does
// the same rotate -> project in C++ and hands the scene graph one line
// geometry per frame. `copies` boats in a grid, each turned a little
// further than the one before, so the load is the line count.
class Wireframe : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(qreal angle READ angle WRITE setAngle NOTIFY angleChanged)   // degrees
    Q_PROPERTY(int copies READ copies WRITE setCopies NOTIFY copiesChanged)
    Q_PROPERTY(qreal fill READ fill WRITE setFill NOTIFY fillChanged)       // boat size in its cell
    // boats drawn on top of each other in every cell, each projected on its
    // own: load the picture does not show
    Q_PROPERTY(int stack READ stack WRITE setStack NOTIFY stackChanged)
    // every other cell turns the other way
    Q_PROPERTY(bool counterRotate READ counterRotate WRITE setCounterRotate NOTIFY counterRotateChanged)

public:
    explicit Wireframe(QQuickItem *parent = nullptr);

    qreal angle() const { return m_angle; }
    void setAngle(qreal a);
    int copies() const { return m_copies; }
    void setCopies(int c);
    qreal fill() const { return m_fill; }
    void setFill(qreal f);
    int stack() const { return m_stack; }
    void setStack(int s);
    bool counterRotate() const { return m_counter; }
    void setCounterRotate(bool c);

signals:
    void angleChanged();
    void copiesChanged();
    void fillChanged();
    void stackChanged();
    void counterRotateChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *) override;

private:
    qreal m_angle = 0.0;
    int m_copies = 1;
    qreal m_fill = 1.0;
    int m_stack = 1;
    bool m_counter = false;
};

#endif // WIREFRAME_H
