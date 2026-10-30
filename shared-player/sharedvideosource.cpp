#include "sharedvideosource.h"
#include "hub.h"

SharedVideoSource::SharedVideoSource(QObject *parent)
    : QObject(parent)
{
}

SharedVideoSource::~SharedVideoSource()
{
    if (m_surface) {
        Hub::instance()->removeSink(m_surface);
    }
}

QUrl SharedVideoSource::url() const
{
    return m_url;
}

void SharedVideoSource::setUrl(const QUrl &url)
{
    if (url == m_url) {
        return;
    }
    m_url = url;
    Hub::instance()->setUrl(url);
    Q_EMIT urlChanged();
}

QAbstractVideoSurface *SharedVideoSource::videoSurface() const
{
    return m_surface;
}

void SharedVideoSource::setVideoSurface(QAbstractVideoSurface *surface)
{
    if (surface == m_surface) {
        return;
    }
    if (m_surface) {
        Hub::instance()->removeSink(m_surface);
    }
    m_surface = surface;
    if (m_surface) {
        Hub::instance()->addSink(m_surface);
    }
}
