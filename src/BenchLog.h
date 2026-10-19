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
#include <QHash>
#include <QFile>
#include <QFileInfo>
#include <QObject>
#include <QStandardPaths>
#include <QSysInfo>
#include <QVariantMap>
#include <QRegExp>
#include <QtNumeric>
#include <QTextStream>
#include <QStringList>
#include <algorithm>

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

    // Every run is kept as its own file, named by its start, newest first
    // in the list (asked for on the forum, 2026-10-19).
    Q_INVOKABLE QString runsPath() const
    {
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
               + QStringLiteral("/runs");
    }
    Q_INVOKABLE bool saveRun(const QString &name, const QString &json) const
    {
        QDir().mkpath(runsPath());
        QFile f(runsPath() + QLatin1Char('/') + QFileInfo(name).fileName());
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
            return false;
        QTextStream out(&f);
        out << json << "\n";
        return true;
    }
    // the folder exists from 2.1.0 on, even when every run was deleted
    Q_INVOKABLE bool hasRunsFolder() const { return QDir(runsPath()).exists(); }
    Q_INVOKABLE QStringList runs() const
    {
        QStringList l = QDir(runsPath()).entryList(QStringList() << QStringLiteral("run-*.json"),
                                                   QDir::Files, QDir::Name);
        std::reverse(l.begin(), l.end());
        return l;
    }
    Q_INVOKABLE QString readRun(const QString &name) const
    {
        return readText(runsPath() + QLatin1Char('/') + QFileInfo(name).fileName());
    }
    Q_INVOKABLE bool deleteRun(const QString &name) const
    {
        return QFile::remove(runsPath() + QLatin1Char('/') + QFileInfo(name).fileName());
    }
    // Share pictures go where the stock screenshot feature puts its own,
    // Pictures/Screenshots (mo, 2026-10-19); saveToFile makes no folders.
    // Pictures itself if the folder cannot be made.
    Q_INVOKABLE QString screenshotsDir() const
    {
        const QString pics = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        const QString dir = pics + QStringLiteral("/Screenshots");
        return QDir().mkpath(dir) ? dir : pics;
    }

    // the single last run of 2.0 and before, to carry it into the list
    Q_INVOKABLE QString readLast() const { return readText(path()); }

    // When no GPU clock is found: each place a GPU clock may sit, with what
    // the app reads there or why it cannot, so one shared JSON shows whether
    // the sandbox blocks it or the format is new (the Jolla Phone, 2.0.1).
    Q_INVOKABLE QVariantMap gpuProbe() const
    {
        QVariantMap m;
        QStringList paths;
        const QDir dev(QStringLiteral("/sys/class/devfreq"));
        for (const QString &d : dev.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
            paths << dev.filePath(d) + QStringLiteral("/cur_freq") << dev.filePath(d) + QStringLiteral("/max_freq");
        paths << QStringLiteral("/sys/kernel/ged/hal/current_freqency")
              << QStringLiteral("/sys/kernel/ged/hal/total_gpu_freq_level_count")
              << QStringLiteral("/proc/gpufreqv2/gpu_working_opp_table")
              << QStringLiteral("/proc/gpufreqv2/gpufreq_status")
              << QStringLiteral("/sys/class/misc/mali0/device/cur_freq")
              << QStringLiteral("/sys/class/misc/mali0/device/max_freq")
              << QStringLiteral("/sys/class/kgsl/kgsl-3d0/gpuclk")
              << QStringLiteral("/sys/class/kgsl/kgsl-3d0/max_gpuclk");
        // a QStringList inside the map reaches QML as {}: a plain list
        QVariantList devs;
        for (const QString &d : dev.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) devs << d;
        m.insert(QStringLiteral("devfreq"), devs);
        m.insert(QStringLiteral("ged_dir_listable"), QDir(QStringLiteral("/sys/kernel/ged/hal")).exists());
        for (const QString &p : paths) {
            QFile f(p);
            if (!f.exists()) { m.insert(p, QStringLiteral("missing")); continue; }
            if (!f.open(QIODevice::ReadOnly)) { m.insert(p, QStringLiteral("unreadable: ") + f.errorString()); continue; }
            m.insert(p, QString::fromLatin1(f.read(240)).trimmed());
        }
        return m;
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

    // The hottest CPU, SoC or GPU sensor in degrees Celsius, NaN if none is
    // readable. Zone names differ per device (C2: soc-thmzone, cputop0-tzone0,
    // gpu-thmzone; the tablet: SoC_DTS0); battery, charger, PMIC, board and
    // skin sensors are left out.
    Q_INVOKABLE double temperature() const
    {
        double hottest = -1000, anyHottest = -1000;
        const QDir dir(QStringLiteral("/sys/class/thermal"));
        for (const QString &z : dir.entryList(QStringList() << QStringLiteral("thermal_zone*"))) {
            QFile tf(dir.filePath(z + QStringLiteral("/temp")));
            QFile ty(dir.filePath(z + QStringLiteral("/type")));
            if (!tf.open(QIODevice::ReadOnly)) continue;
            bool ok = false;
            const double raw = QString::fromLatin1(tf.readAll()).trimmed().toDouble(&ok);
            // a sensor that is off reads 0; old kernels report whole degrees
            // (3.4, Moto G 2nd gen) or tenths (Qualcomm tsens on 4.4, Xperia
            // XA2: 398 is 39.8) instead of millidegrees, mixed on one phone
            if (!ok || raw == 0) continue;
            QString type;
            if (ty.open(QIODevice::ReadOnly)) type = QString::fromLatin1(ty.readAll()).trimmed().toLower();
            // battery state-of-charge zones read 0-100 but are no temperature
            if (type.startsWith(QLatin1String("socd")) || type.contains(QLatin1String("bcl"))
                    || type.contains(QLatin1String("vbat")) || type.contains(QLatin1String("ibat")))
                continue;
            // The unit per zone from its first trip point when it has one
            // (millidegrees >= 10000, tenths >= 300, else degrees): by value
            // alone a tenths sensor under 15.0 C read as 100-149 C (night
            // audit, 2026-10-19).
            double div = qAbs(raw) < 200 ? 1 : qAbs(raw) < 1500 ? 10 : 1000;
            bool okTrip = false;
            const double trip = sysValue(dir.filePath(z + QStringLiteral("/trip_point_0_temp"))).toDouble(&okTrip);
            if (okTrip && trip > 0)
                div = trip >= 10000 ? 1000 : trip >= 300 ? 10 : 1;
            const double c = raw / div;
            if (c < -40 || c > 150) continue;
            anyHottest = qMax(anyHottest, c);
            if (type.contains(QLatin1String("cpu")) || type.contains(QLatin1String("soc"))
                    || type.contains(QLatin1String("gpu")) || type.contains(QLatin1String("tsens")))
                hottest = qMax(hottest, c);
        }
        if (hottest > -1000) return hottest;
        return anyHottest > -1000 ? anyHottest : qQNaN();
    }

    // the running kernel, from uname(), e.g. "5.4.233-android12-9-g9c3a5d5b97e3"
    Q_INVOKABLE QString kernel() const { return QSysInfo::kernelVersion(); }

    // The phone's own battery: percent, status and the power in watts, an
    // empty map if there is none. The sign of current_now differs between
    // kernels (negative on the C2 and the tablet when discharging), so the
    // watts are unsigned and the status says which way they flow.
    Q_INVOKABLE QVariantMap battery() const
    {
        const QDir dir(QStringLiteral("/sys/class/power_supply"));
        for (const QString &d : dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            const QString base = dir.filePath(d) + QLatin1Char('/');
            if (sysValue(base + QStringLiteral("type")) != QLatin1String("Battery")) continue;
            // a headset or stylus battery says scope Device
            if (sysValue(base + QStringLiteral("scope")) == QLatin1String("Device")) continue;
            if (sysValue(base + QStringLiteral("present")) == QLatin1String("0")) continue;
            bool ok = false;
            const int capacity = sysValue(base + QStringLiteral("capacity")).toInt(&ok);
            if (!ok) continue;
            QVariantMap m;
            m.insert(QStringLiteral("capacity"), capacity);
            m.insert(QStringLiteral("status"), sysValue(base + QStringLiteral("status")));
            bool okP = false, okI = false, okV = false;
            const double p = sysValue(base + QStringLiteral("power_now")).toDouble(&okP);
            const double i = sysValue(base + QStringLiteral("current_now")).toDouble(&okI);
            const double v = sysValue(base + QStringLiteral("voltage_now")).toDouble(&okV);
            double w = -1;
            if (okP && p != 0)
                w = qAbs(p) / 1e6;
            else if (okI && okV)
                w = qAbs(i) * qAbs(v) / 1e12;
            // old kernels give mA instead of uA: a phone draws 0.01-30 W
            if (w > 0 && w < 0.005) w *= 1000;
            if (w > 0 && w <= 30) m.insert(QStringLiteral("watts"), w);
            return m;
        }
        return QVariantMap();
    }

    // What the kernel does against heat, read each second (the user cannot
    // read the journal, and the sandbox even less, so the state itself):
    //  cpu      the fastest cluster's clock in percent of its maximum
    //  gpu      the GPU's clock in percent of its maximum (devfreq), if any
    //  cooling  the cooling devices in use (thermal-cpufreq, devfreq, cpu
    //           hotplug with cur_state above 0); above 0 the kernel throttles
    //  capped   a cluster's allowed maximum is below its hardware maximum
    Q_INVOKABLE QVariantMap throttle() const
    {
        QVariantMap m;
        const QDir cpu(QStringLiteral("/sys/devices/system/cpu/cpufreq"));
        double cpuPct = -1;
        bool capped = false;
        QList<int> clusterMax;
        // kernels before 4.3 (the Jolla Tablet's 3.10) have no policy*
        // directories, only each core's own cpu*/cpufreq
        QStringList bases;
        for (const QString &p : cpu.entryList(QStringList() << QStringLiteral("policy*"), QDir::Dirs))
            bases << cpu.filePath(p) + QLatin1Char('/');
        if (bases.isEmpty()) {
            const QDir cores(QStringLiteral("/sys/devices/system/cpu"));
            for (const QString &c : cores.entryList(QStringList() << QStringLiteral("cpu[0-9]*"), QDir::Dirs))
                if (QFileInfo::exists(cores.filePath(c) + QStringLiteral("/cpufreq/cpuinfo_max_freq")))
                    bases << cores.filePath(c) + QStringLiteral("/cpufreq/");
        }
        for (const QString &base : bases) {
            const double cur = sysValue(base + QStringLiteral("scaling_cur_freq")).toDouble();
            const double max = sysValue(base + QStringLiteral("cpuinfo_max_freq")).toDouble();
            const double allowed = sysValue(base + QStringLiteral("scaling_max_freq")).toDouble();
            if (max <= 0) continue;
            clusterMax << int(max);
            cpuPct = qMax(cpuPct, cur / max * 100);
            // Capped only when the allowed maximum fell during the run: many
            // kernels hold it under the hardware maximum from boot (boost
            // steps, vendor limits), which flagged every second as throttled
            // (night audit). The baseline is the first reading of a run.
            if (allowed > 0) {
                if (!m_allowedStart.contains(base)) m_allowedStart.insert(base, allowed);
                if (allowed < m_allowedStart.value(base)) capped = true;
            }
        }
        if (cpuPct >= 0) {
            m.insert(QStringLiteral("cpu"), qRound(cpuPct));
            m.insert(QStringLiteral("capped"), capped);
        }
        const QDir dev(QStringLiteral("/sys/class/devfreq"));
        for (const QString &d : dev.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            if (!d.contains(QLatin1String("gpu"), Qt::CaseInsensitive)
                    && !d.contains(QLatin1String("mali"), Qt::CaseInsensitive)
                    && !d.contains(QLatin1String("kgsl"), Qt::CaseInsensitive)) continue;
            // Qualcomm's gpubw and kgsl-busmon are bus bandwidth, not the GPU
            if (d.contains(QLatin1String("bw"), Qt::CaseInsensitive)
                    || d.contains(QLatin1String("busmon"), Qt::CaseInsensitive)) continue;
            const QString base = dev.filePath(d) + QLatin1Char('/');
            const double cur = sysValue(base + QStringLiteral("cur_freq")).toDouble();
            const double max = sysValue(base + QStringLiteral("max_freq")).toDouble();
            if (max > 0) { m.insert(QStringLiteral("gpu"), qRound(cur / max * 100)); break; }
        }
        // MediaTek (the Jolla Phone's Mali-G610) has no GPU devfreq: its GED
        // driver gives "<step> <kHz>", e.g. "22 385000". The maximum comes from
        // the step table if it reads as kHz, else it is the fastest clock seen.
        if (!m.contains(QStringLiteral("gpu"))) {
            const QStringList ged = sysValue(QStringLiteral("/sys/kernel/ged/hal/current_freqency"))
                                        .split(QLatin1Char(' '), QString::SkipEmptyParts);
            bool ok = false;
            const double cur = ged.size() >= 2 ? ged.at(1).toDouble(&ok) : 0;
            if (ok && cur > 0) {
                // the step table can be unreadable at first: asked again
                if (m_gpuTableMax <= 0 && m_gpuTableTries < 5) { m_gpuTableMax = mtkTableMax(); m_gpuTableTries++; }
                // Without the table the fastest clock seen read as 100 % from
                // the first second and hid any throttling (night audit): only
                // a known maximum gives a percentage.
                if (m_gpuTableMax > 0)
                    m.insert(QStringLiteral("gpu"), qRound(cur / m_gpuTableMax * 100));
            }
        }
        const QDir cool(QStringLiteral("/sys/class/thermal"));
        int cooling = 0;
        bool anyCooling = false;
        for (const QString &c : cool.entryList(QStringList() << QStringLiteral("cooling_device*"))) {
            const QString base = cool.filePath(c) + QLatin1Char('/');
            const QString type = sysValue(base + QStringLiteral("type")).toLower();
            if (!type.contains(QLatin1String("cpu")) && !type.contains(QLatin1String("gpu"))
                    && !type.contains(QLatin1String("devfreq")) && !type.contains(QLatin1String("processor")))
                continue;
            bool ok = false, okMax = false;
            const int state = sysValue(base + QStringLiteral("cur_state")).toInt(&ok);
            const int maxState = sysValue(base + QStringLiteral("max_state")).toInt(&okMax);
            if (!ok) continue;
            anyCooling = true;
            // Qualcomm's 4.4 kernels (Xperia XA2) put the allowed clock in kHz
            // into cur_state, not a step: throttled when that clock is no
            // cluster's maximum
            if (okMax && state > maxState) {
                if (!clusterMax.contains(state)) cooling++;
            } else if (state > 0) {
                cooling++;
            }
        }
        if (anyCooling) m.insert(QStringLiteral("cooling"), cooling);
        return m;
    }

    // a new run: the throttle baseline is read again
    Q_INVOKABLE void resetRun() const { m_allowedStart.clear(); }

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

private:
    mutable double m_gpuTableMax = -1;
    mutable int m_gpuTableTries = 0;
    // each cpufreq policy's allowed maximum at the run's first reading
    mutable QHash<QString, double> m_allowedStart;

    // the fastest step in MediaTek's GPU step table, 0 if it is unreadable or
    // not between 100 MHz and 3 GHz in kHz
    static double mtkTableMax()
    {
        const QString t = sysValue(QStringLiteral("/proc/gpufreqv2/gpu_working_opp_table"));
        QRegExp re(QStringLiteral("freq[^0-9]{0,8}(\\d+)"), Qt::CaseInsensitive);
        double max = 0;
        for (int pos = 0; (pos = re.indexIn(t, pos)) >= 0; pos += re.matchedLength())
            max = qMax(max, re.cap(1).toDouble());
        return max >= 100000 && max <= 3000000 ? max : 0;
    }

    static QString readText(const QString &file)
    {
        QFile f(file);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();
        return QString::fromUtf8(f.readAll());
    }

    static QString sysValue(const QString &file)
    {
        QFile f(file);
        if (!f.open(QIODevice::ReadOnly)) return QString();
        return QString::fromLatin1(f.readAll()).trimmed();
    }
};

#endif // BENCHLOG_H
