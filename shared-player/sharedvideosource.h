#pragma once

#include <QAbstractVideoSurface>
#include <QObject>
#include <QPointer>
#include <QUrl>

// Source a donner a un VideoOutput (VideoOutput { source: ... }). Le
// VideoOutput lui confie sa surface par la propriete videoSurface ; elle est
// branchee sur le lecteur unique du processus.
class SharedVideoSource : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QAbstractVideoSurface *videoSurface READ videoSurface WRITE setVideoSurface)
public:
    explicit SharedVideoSource(QObject *parent = nullptr);
    ~SharedVideoSource() override;

    QUrl url() const;
    void setUrl(const QUrl &url);
    QAbstractVideoSurface *videoSurface() const;
    void setVideoSurface(QAbstractVideoSurface *surface);

Q_SIGNALS:
    void urlChanged();

private:
    QUrl m_url;
    QPointer<QAbstractVideoSurface> m_surface;
};
