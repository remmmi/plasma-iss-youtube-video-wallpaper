#include "hub.h"
#include "fanoutsurface.h"

#include <QCoreApplication>
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
                scheduleReload(QStringLiteral("erreur ") + m_player->errorString());
            });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
            [this](QMediaPlayer::MediaStatus status) {
                if (status == QMediaPlayer::EndOfMedia || status == QMediaPlayer::InvalidMedia) {
                    scheduleReload(QStringLiteral("fin de flux"));
                }
            });

    // Chien de garde : relance si la position n'avance plus
    m_watchdog.setInterval(30000);
    connect(&m_watchdog, &QTimer::timeout, this, [this]() {
        const qint64 position = m_player->position();
        if (m_fanout->sinkCount() > 0 && position == m_lastPosition) {
            scheduleReload(QStringLiteral("flux fige"));
        }
        m_lastPosition = position;
    });
    m_watchdog.start();
}

void Hub::setUrl(const QUrl &url)
{
    if (url == m_url) {
        return;
    }
    m_url = url;
    scheduleReload(QStringLiteral("adresse ") + url.toString());
}

void Hub::addSink(QAbstractVideoSurface *sink)
{
    const bool wasEmpty = m_fanout->sinkCount() == 0;
    m_fanout->addSink(sink);
    qWarning() << "isslive-shared: ecran ajoute, total" << m_fanout->sinkCount();
    if (wasEmpty) {
        scheduleReload(QStringLiteral("premier ecran"));
    }
}

void Hub::removeSink(QAbstractVideoSurface *sink)
{
    m_fanout->removeSink(sink);
    qWarning() << "isslive-shared: ecran retire, total" << m_fanout->sinkCount();
    if (m_fanout->sinkCount() == 0) {
        m_retry.stop();
        m_player->stop();
    }
}

void Hub::scheduleReload(const QString &reason)
{
    qWarning() << "isslive-shared: relance dans 5 s :" << reason;
    // Regroupe les demandes rapprochees (demarrage de plusieurs ecrans)
    m_retry.start();
}

void Hub::reload()
{
    m_lastPosition = -1;
    m_player->stop();
    m_player->setMedia(QMediaContent());
    if (m_url.isValid() && m_fanout->sinkCount() > 0) {
        m_player->setMedia(m_url);
        m_player->play();
    }
}
