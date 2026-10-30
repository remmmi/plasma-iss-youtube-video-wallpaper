#pragma once

#include <QAbstractVideoSurface>
#include <QObject>
#include <QPointer>
#include <QUrl>

// Source for a VideoOutput (VideoOutput { source: ... }). The VideoOutput
// hands over its surface through the videoSurface property; that surface is
// plugged into the single player of the process.
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
