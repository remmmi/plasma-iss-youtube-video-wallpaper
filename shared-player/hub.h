#pragma once

#include <QMediaPlayer>
#include <QObject>
#include <QTimer>
#include <QUrl>

class FanoutSurface;
class QAbstractVideoSurface;

// Lecteur unique du processus. Gere la lecture, la reconnexion apres erreur
// et le chien de garde (flux fige). Les ecrans s'y branchent par addSink.
class Hub : public QObject
{
    Q_OBJECT
public:
    static Hub *instance();

    void setUrl(const QUrl &url);
    void addSink(QAbstractVideoSurface *sink);
    void removeSink(QAbstractVideoSurface *sink);

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
};
