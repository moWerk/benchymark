/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The bridge that lets a run outlive itself: QML cannot write files, so the
 * finished results are handed here and land in the XDG data directory, where
 * asteroid-docking-bay reads them back over adb or ssh. Without this a run
 * exists only on the watch's screen and has to be transcribed by eye.
 */

#ifndef BENCHLOG_H
#define BENCHLOG_H

#include <QDir>
#include <QFile>
#include <QObject>
#include <QStandardPaths>
#include <QTextStream>

class BenchLog : public QObject
{
    Q_OBJECT

public:
    explicit BenchLog(QObject *parent = nullptr) : QObject(parent) {}

    // ~/.local/share/benchymark/last-run.json — XDG, per user, no root needed.
    Q_INVOKABLE QString path() const
    {
        return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
               + QStringLiteral("/benchymark/last-run.json");
    }

    // Written whole, not appended: the file always holds ONE complete run, so a
    // reader never has to guess where the last one starts or whether it is
    // truncated. Returns false rather than throwing; the app keeps running.
    Q_INVOKABLE bool write(const QString &json) const
    {
        const QString target = path();
        QDir().mkpath(QFileInfo(target).absolutePath());
        QFile f(target);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
            return false;
        QTextStream out(&f);
        out << json << Qt::endl;
        f.close();
        return true;
    }
};

#endif // BENCHLOG_H
