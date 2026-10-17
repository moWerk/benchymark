/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * QML cannot write files, so the finished results are handed here. One
 * complete run per file, written whole.
 */
#ifndef BENCHLOG_H
#define BENCHLOG_H

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QObject>
#include <QStandardPaths>
#include <QRegExp>
#include <QTextStream>

class BenchLog : public QObject
{
    Q_OBJECT
public:
    explicit BenchLog(QObject *parent = nullptr) : QObject(parent) {}

    // SailfishOS: the app's own data directory, the one place sailjail lets
    // it write: ~/.local/share/net.mowerk/harbour-benchymark/last-run.json
    Q_INVOKABLE QString path() const
    {
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
               + QStringLiteral("/last-run.json");
    }

    Q_INVOKABLE bool write(const QString &json) const
    {
        const QString target = path();
        QDir().mkpath(QFileInfo(target).absolutePath());
        QFile f(target);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
            return false;
        QTextStream out(&f);
        out << json << "\n";
        return true;
    }

    // the SoC as the kernel's device tree names it, else /proc/cpuinfo
    Q_INVOKABLE QString socName() const
    {
        QFile dt(QStringLiteral("/proc/device-tree/model"));
        if (dt.open(QIODevice::ReadOnly)) {
            const QString m = QString::fromUtf8(dt.readAll()).remove(QChar(0)).trimmed();
            if (!m.isEmpty()) return m;
        }
        const QString hw = releaseValue(QStringLiteral("/proc/cpuinfo"), QStringLiteral("Hardware"));
        return hw;
    }

    // a line from /etc/*-release, for the result header
    Q_INVOKABLE QString releaseValue(const QString &file, const QString &key) const
    {
        QFile f(file);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
            return QString();
        while (!f.atEnd()) {
            const QString line = QString::fromUtf8(f.readLine()).trimmed();
            const int sep = line.indexOf(QRegExp(QStringLiteral("[=:]")));
            if (sep > 0 && line.left(sep).trimmed() == key) {
                QString v = line.mid(sep + 1).trimmed();
                if (v.startsWith(QLatin1Char('"')) && v.endsWith(QLatin1Char('"')))
                    v = v.mid(1, v.size() - 2);
                return v;
            }
        }
        return QString();
    }
};

#endif // BENCHLOG_H
