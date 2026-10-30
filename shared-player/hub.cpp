#include "hub.h"
#include "fanoutsurface.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>

Hub *Hub::instance()
{
    static Hub *hub = new Hub(QCoreApplication::instance());
    return hub;
}

Hub::Hub(QObject *parent)
    : QObject(parent)
    , m_player(new QMediaPlayer(this))
    , m_fanout(new FanoutSurface(this))
{
    m_player->setMuted(true);
    m_player->setVolume(0);
    m_player->setVideoOutput(m_fanout);

    m_retry.setSingleShot(true);
    m_retry.setInterval(5000);
    connect(&m_retry, &QTimer::timeout, this, &Hub::reload);

    connect(m_player, QOverload<QMediaPlayer::Error>::of(&QMediaPlayer::error), this,
            [this](QMediaPlayer::Error) {
                scheduleReload(QStringLiteral("error ") + m_player->errorString());
            });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
            [this](QMediaPlayer::MediaStatus status) {
                if (status == QMediaPlayer::EndOfMedia || status == QMediaPlayer::InvalidMedia) {
                    scheduleReload(QStringLiteral("end of stream"));
                }
            });

    // Watchdog: reload when the position stops moving
    m_watchdog.setInterval(30000);
    connect(&m_watchdog, &QTimer::timeout, this, [this]() {
        const qint64 position = m_player->position();
        if (!m_locked && m_fanout->sinkCount() > 0 && position == m_lastPosition) {
            scheduleReload(QStringLiteral("frozen stream"));
        }
        m_lastPosition = position;
    });
    m_watchdog.start();

    // Session lock: the screen locker of KDE announces it on the session bus
    const QString service = QStringLiteral("org.freedesktop.ScreenSaver");
    const QString path = QStringLiteral("/ScreenSaver");
    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.connect(service, path, service, QStringLiteral("ActiveChanged"),
                this, SLOT(onLockChanged(bool)));
    QDBusInterface screenSaver(service, path, service, bus);
    const QDBusReply<bool> active = screenSaver.call(QStringLiteral("GetActive"));
    m_locked = active.isValid() && active.value();
}

void Hub::onLockChanged(bool locked)
{
    if (locked == m_locked) {
        return;
    }
    m_locked = locked;
    qWarning() << "isslive-shared: session" << (locked ? "locked, playback stopped" : "unlocked");
    if (locked) {
        m_retry.stop();
        m_player->stop();
        m_player->setMedia(QMediaContent());
    } else {
        m_retry.stop();
        reload();
    }
}

void Hub::setUrl(const QUrl &url)
{
    if (url == m_url) {
        return;
    }
    m_url = url;
    scheduleReload(QStringLiteral("url ") + url.toString());
}

void Hub::addSink(QAbstractVideoSurface *sink)
{
    const bool wasEmpty = m_fanout->sinkCount() == 0;
    m_fanout->addSink(sink);
    qWarning() << "isslive-shared: screen added, total" << m_fanout->sinkCount();
    if (wasEmpty) {
        scheduleReload(QStringLiteral("first screen"));
    }
}

void Hub::removeSink(QAbstractVideoSurface *sink)
{
    m_fanout->removeSink(sink);
    qWarning() << "isslive-shared: screen removed, total" << m_fanout->sinkCount();
    if (m_fanout->sinkCount() == 0) {
        m_retry.stop();
        m_player->stop();
    }
}

void Hub::scheduleReload(const QString &reason)
{
    qWarning() << "isslive-shared: reload in 5 s:" << reason;
    // Merges close requests (several screens starting at once)
    m_retry.start();
}

void Hub::reload()
{
    m_lastPosition = -1;
    m_player->stop();
    m_player->setMedia(QMediaContent());
    if (m_url.isValid() && m_fanout->sinkCount() > 0 && !m_locked) {
        m_player->setMedia(m_url);
        m_player->play();
    }
}
