/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "SystemBench.h"
#include "Dots.h"

#include <QColor>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QStandardPaths>
#include <QVector>
#include <cerrno>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>

// ── primes ───────────────────────────────────────────────────────────────────

// one colour per thread, from the AsteroidOS ramp and the Benchy blues
static const QRgb kThreadColor[] = {
    0xf0c30e, 0x58a6ff, 0xe54b3a, 0x30e070, 0xb040ff, 0xf19a11, 0xa5d6ff, 0xff5090,
};

static bool isPrime(qint64 n)
{
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    for (qint64 d = 3; d * d <= n; d += 2)
        if (n % d == 0) return false;
    return true;
}

// sysbench's cpu event: count the primes up to max by trial division
static int sysbenchEvent(int max)
{
    int n = 0;
    for (int c = 3; c < max; ++c) {
        const int t = int(std::sqrt(double(c)));
        int l = 2;
        for (; l <= t; ++l)
            if (c % l == 0) break;
        if (l > t) ++n;
    }
    return n;
}

// Ulam spiral: 1 in the centre, then outward anticlockwise
static void spiral(qint64 n, int &x, int &y)
{
    if (n <= 1) { x = y = 0; return; }
    const qint64 k = qint64(std::ceil((std::sqrt(double(n)) - 1) / 2));
    qint64 t = 2 * k + 1;
    const qint64 m = t * t;
    t -= 1;
    if (n >= m - t) { x = int(k - (m - n)); y = int(-k); return; }
    qint64 m2 = m - t;
    if (n >= m2 - t) { x = int(-k); y = int(-k + (m2 - n)); return; }
    m2 -= t;
    if (n >= m2 - t) { x = int(-k + (m2 - n)); y = int(k); return; }
    x = int(k); y = int(k - (m2 - n - t));
}

PrimeEngine::PrimeEngine(QObject *parent) : QObject(parent) {}
PrimeEngine::~PrimeEngine() { stop(); }

int PrimeEngine::threads() const { return qMax(1, QThread::idealThreadCount()); }

void PrimeEngine::start(qreal cx, qreal cy, qreal cell, int side)
{
    stop();
    m_cx = cx; m_cy = cy; m_cell = cell;
    m_limit = qint64(side) * side;
    m_next.store(0);
    m_done.store(0);
    m_stop.store(0);
    for (int i = 0; i < threads(); ++i) {
        FunctionThread *t = new FunctionThread([this, i]() { work(i); });
        m_threads << t;
        t->start();
    }
}

void PrimeEngine::stop()
{
    m_stop.store(1);
    for (FunctionThread *t : m_threads) { t->wait(); delete t; }
    m_threads.clear();
}

void PrimeEngine::work(int id)
{
    static const int kChunk = 16;
    QVector<Dots::Dot> batch;
    volatile int sink = 0;
    while (!m_stop.load()) {
        const qint64 first = m_next.fetchAndAddRelaxed(kChunk);
        for (qint64 i = first; i < first + kChunk && !m_stop.load(); ++i) {
            sink += sysbenchEvent(kMaxPrime);
            m_done.fetchAndAddRelaxed(1);
            const qint64 pass = i / m_limit;
            const qint64 n = i % m_limit + 1;
            if (!isPrime(n)) continue;
            int x, y;
            spiral(n, x, y);
            // each pass a little brighter, so the next one shows over the last
            QColor c(kThreadColor[id % 8]);
            c = c.lighter(100 + int(pass % 4) * 25);
            batch.append({ float(m_cx + x * m_cell), float(m_cy + y * m_cell),
                           quint8(c.red()), quint8(c.green()), quint8(c.blue()) });
        }
        if (batch.size() >= 32 && m_target) {
            m_target->addMany(batch);
            batch.clear();
        }
    }
}

// ── memory ───────────────────────────────────────────────────────────────────

void MemoryEngine::start()
{
    stop();
    m_bytes.store(0);
    m_stop.store(0);
    m_thread = new FunctionThread([this]() {
        const size_t size = 32 * 1024 * 1024;
        char *a = static_cast<char *>(std::malloc(size));
        char *b = static_cast<char *>(std::malloc(size));
        if (!a || !b) { std::free(a); std::free(b); return; }
        std::memset(a, 1, size);
        std::memset(b, 2, size);
        while (!m_stop.load()) {
            // 1 MB at a time, so stop() is quick
            for (size_t off = 0; off < size && !m_stop.load(); off += 1024 * 1024) {
                std::memcpy(b + off, a + off, 1024 * 1024);
                m_bytes.fetchAndAddRelaxed(1024 * 1024);
            }
            std::swap(a, b);
        }
        std::free(a);
        std::free(b);
    });
    m_thread->start();
}

void MemoryEngine::stop()
{
    m_stop.store(1);
    if (m_thread) { m_thread->wait(); delete m_thread; m_thread = nullptr; }
}

// ── storage ──────────────────────────────────────────────────────────────────

StorageEngine::~StorageEngine() { stop(); }

void StorageEngine::setPhase(int p)
{
    m_phase.store(p);
    QMetaObject::invokeMethod(this, "phaseChanged", Qt::QueuedConnection);
}

void StorageEngine::start(int blocks)
{
    stop();
    m_done.store(0);
    m_stop.store(0);
    m_writeMBs = m_readMBs = 0;
    m_error.clear();
    m_thread = new FunctionThread([this, blocks]() { work(blocks); });
    m_thread->start();
}

void StorageEngine::stop()
{
    m_stop.store(1);
    if (m_thread) { m_thread->wait(); delete m_thread; m_thread = nullptr; }
}

void StorageEngine::work(int blocks)
{
    const size_t bs = 16 * 1024;
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    const QByteArray path = QFile::encodeName(dir + QStringLiteral("/storage-test.bin"));
    void *buf = nullptr;
    if (posix_memalign(&buf, 4096, bs) != 0) { m_error = QStringLiteral("no memory"); setPhase(-1); return; }
    std::memset(buf, 0x5a, bs);

    // write
    m_direct = true;
    int fd = ::open(path.constData(), O_WRONLY | O_CREAT | O_TRUNC | O_DIRECT, 0600);
    if (fd < 0 && errno == EINVAL) {
        // a file system without O_DIRECT: plain writes, flushed at the end
        m_direct = false;
        fd = ::open(path.constData(), O_WRONLY | O_CREAT | O_TRUNC, 0600);
    }
    if (fd < 0) { m_error = QString::fromLocal8Bit(strerror(errno)); std::free(buf); setPhase(-1); return; }
    m_done.store(0);
    setPhase(1);
    QElapsedTimer t;
    t.start();
    int i = 0;
    for (; i < blocks && !m_stop.load(); ++i) {
        if (::write(fd, buf, bs) != ssize_t(bs)) break;
        m_done.store(i + 1);
    }
    ::fdatasync(fd);
    ::close(fd);
    const qint64 wms = qMax<qint64>(1, t.elapsed());
    m_writeMBs = double(i) * bs / (1024.0 * 1024.0) / (wms / 1000.0);

    // read; without O_DIRECT drop nothing from the cache we cannot drop, so
    // the read may come from RAM: the result says so (direct = false)
    fd = ::open(path.constData(), O_RDONLY | (m_direct ? O_DIRECT : 0));
    if (fd >= 0 && !m_stop.load()) {
        m_done.store(0);
        setPhase(2);
        t.restart();
        int r = 0;
        for (; r < i && !m_stop.load(); ++r) {
            if (::read(fd, buf, bs) != ssize_t(bs)) break;
            m_done.store(r + 1);
        }
        const qint64 rms = qMax<qint64>(1, t.elapsed());
        m_readMBs = double(r) * bs / (1024.0 * 1024.0) / (rms / 1000.0);
    }
    if (fd >= 0) ::close(fd);
    ::unlink(path.constData());
    std::free(buf);
    setPhase(m_stop.load() ? 0 : 3);
}
