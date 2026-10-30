#pragma once

#include <QMediaPlayer>
#include <QObject>
#include <QTimer>
#include <QUrl>

class FanoutSurface;
class QAbstractVideoSurface;

// Single player of the process. Handles playback, reconnection after an error
// and the watchdog (frozen stream). Screens plug into it with addSink.
// Playback stops while the session is locked, to save the decoding CPU.
class Hub : public QObject
{
    Q_OBJECT
public:
    static Hub *instance();

    void setUrl(const QUrl &url);
    void addSink(QAbstractVideoSurface *sink);
    void removeSink(QAbstractVideoSurface *sink);

private Q_SLOTS:
    void onLockChanged(bool locked);

private:
    explicit Hub(QObject *parent = nullptr);
    void reload();
    void scheduleReload(const QString &reason);

    QMediaPlayer *m_player;
    FanoutSurface *m_fanout;
    QTimer m_retry;
    QTimer m_watchdog;
    QUrl m_url;
    qint64 m_lastPosition = -1;
    bool m_locked = false;
};
