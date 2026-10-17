/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * SailfishOS: the system stages' work, in threads so the drawing does not
 * set their pace. The console tests of the author's 2016 Sailfish device
 * benchmark (sysbench cpu and memory, dd), rebuilt inside the app: the
 * sandbox runs no outside tools.
 */
#ifndef SYSTEMBENCH_H
#define SYSTEMBENCH_H

#include <QAtomicInteger>
#include <QObject>
#include <QPointer>
#include <QThread>
#include <functional>

#include "Dots.h"

class FunctionThread : public QThread
{
public:
    explicit FunctionThread(std::function<void()> f) : m_f(f) {}
protected:
    void run() override { m_f(); }
private:
    std::function<void()> m_f;
};

// CPU: every core runs sysbench's cpu event (count the primes up to
// kMaxPrime by trial division), one event per cell of an Ulam spiral on
// `target`; a cell whose number is prime lights up, so the spiral's
// diagonals appear as the work goes. When the spiral is full the next pass
// paints it again in brighter colours.
class PrimeEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Dots *target READ target WRITE setTarget)
    Q_PROPERTY(int threads READ threads NOTIFY threadsChanged)
    // 0: every core; 1 for the single core stage
    Q_PROPERTY(int threadCount READ threadCount WRITE setThreadCount NOTIFY threadsChanged)
public:
    explicit PrimeEngine(QObject *parent = nullptr);
    ~PrimeEngine() override;
    Dots *target() const { return m_target; }
    void setTarget(Dots *d) { m_target = d; }
    int threads() const;
    int threadCount() const { return m_threadCount; }
    void setThreadCount(int n) { if (n != m_threadCount) { m_threadCount = n; emit threadsChanged(); } }

    // spiral: centre and cell size in target coordinates, `side` cells across
    Q_INVOKABLE void start(qreal cx, qreal cy, qreal cell, int side);
    Q_INVOKABLE void stop();
    // events done so far
    Q_INVOKABLE double events() const { return double(m_done.load()); }
    static const int kMaxPrime = 10000;   // sysbench's default

signals:
    void threadsChanged();

private:
    void work(int id);
    QPointer<Dots> m_target;
    QList<FunctionThread *> m_threads;
    QAtomicInteger<qint64> m_next;
    QAtomicInteger<qint64> m_done;
    QAtomicInt m_stop;
    qreal m_cx = 0, m_cy = 0, m_cell = 2;
    qint64 m_limit = 1;
    int m_threadCount = 0;
};

// Memory: memcpy between two 32 MB buffers, as sysbench's memory test.
class MemoryEngine : public QObject
{
    Q_OBJECT
public:
    explicit MemoryEngine(QObject *parent = nullptr) : QObject(parent) {}
    ~MemoryEngine() override { stop(); }
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    // bytes copied so far
    Q_INVOKABLE double copied() const { return double(m_bytes.load()); }
private:
    FunctionThread *m_thread = nullptr;
    QAtomicInteger<qint64> m_bytes;
    QAtomicInt m_stop;
};

// Storage: a file of `blocks` 16 KB blocks in the app's data directory,
// written and read back with O_DIRECT (the author's dd test), then deleted.
class StorageEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int phase READ phase NOTIFY phaseChanged)   // 0 idle, 1 write, 2 read, 3 done, -1 error
    Q_PROPERTY(qreal writeMBs READ writeMBs NOTIFY phaseChanged)
    Q_PROPERTY(qreal readMBs READ readMBs NOTIFY phaseChanged)
    Q_PROPERTY(bool direct READ direct NOTIFY phaseChanged)
    Q_PROPERTY(QString error READ error NOTIFY phaseChanged)
public:
    explicit StorageEngine(QObject *parent = nullptr) : QObject(parent) {}
    ~StorageEngine() override;
    int phase() const { return m_phase.load(); }
    qreal writeMBs() const { return m_writeMBs; }
    qreal readMBs() const { return m_readMBs; }
    bool direct() const { return m_direct; }
    QString error() const { return m_error; }
    Q_INVOKABLE void start(int blocks);
    Q_INVOKABLE void stop();
    // blocks done in the current phase
    Q_INVOKABLE int done() const { return m_done.load(); }
signals:
    void phaseChanged();
private:
    void work(int blocks);
    void setPhase(int p);
    FunctionThread *m_thread = nullptr;
    QAtomicInt m_phase;
    QAtomicInt m_done;
    QAtomicInt m_stop;
    qreal m_writeMBs = 0, m_readMBs = 0;
    bool m_direct = true;
    QString m_error;
};

#endif // SYSTEMBENCH_H
