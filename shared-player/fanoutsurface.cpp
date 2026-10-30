#include "fanoutsurface.h"

#include <QVideoSurfaceFormat>

FanoutSurface::FanoutSurface(QObject *parent)
    : QAbstractVideoSurface(parent)
{
}

QList<QVideoFrame::PixelFormat> FanoutSurface::supportedPixelFormats(
    QAbstractVideoBuffer::HandleType type) const
{
    // Images en memoire systeme seulement : une texture GL appartiendrait au
    // contexte d'une seule fenetre et ne servirait pas aux autres ecrans.
    if (type != QAbstractVideoBuffer::NoHandle) {
        return {};
    }
    QList<QVideoFrame::PixelFormat> formats;
    bool first = true;
    for (const auto &sink : m_sinks) {
        if (!sink) {
            continue;
        }
        const auto sinkFormats = sink->supportedPixelFormats(QAbstractVideoBuffer::NoHandle);
        if (first) {
            formats = sinkFormats;
            first = false;
        } else {
            QList<QVideoFrame::PixelFormat> common;
            for (auto f : formats) {
                if (sinkFormats.contains(f)) {
                    common.append(f);
                }
            }
            formats = common;
        }
    }
    if (first) {
        formats = {QVideoFrame::Format_YUV420P, QVideoFrame::Format_NV12,
                   QVideoFrame::Format_YV12, QVideoFrame::Format_RGB32,
                   QVideoFrame::Format_ARGB32, QVideoFrame::Format_BGR32};
    }
    return formats;
}

bool FanoutSurface::start(const QVideoSurfaceFormat &format)
{
    for (const auto &sink : m_sinks) {
        if (!sink) {
            continue;
        }
        if (sink->isActive()) {
            sink->stop();
        }
        sink->start(format);
    }
    return QAbstractVideoSurface::start(format);
}

void FanoutSurface::stop()
{
    for (const auto &sink : m_sinks) {
        if (sink && sink->isActive()) {
            sink->stop();
        }
    }
    QAbstractVideoSurface::stop();
}

bool FanoutSurface::present(const QVideoFrame &frame)
{
    for (const auto &sink : m_sinks) {
        if (sink && sink->isActive()) {
            sink->present(frame);
        }
    }
    return true;
}

void FanoutSurface::addSink(QAbstractVideoSurface *sink)
{
    if (!sink || m_sinks.contains(sink)) {
        return;
    }
    m_sinks.append(sink);
    // Un ecran ajoute en cours de lecture demarre avec le format courant
    if (isActive()) {
        sink->start(surfaceFormat());
    }
}

void FanoutSurface::removeSink(QAbstractVideoSurface *sink)
{
    m_sinks.removeAll(sink);
    m_sinks.removeAll(nullptr);
    if (sink && sink->isActive()) {
        sink->stop();
    }
}

int FanoutSurface::sinkCount() const
{
    int n = 0;
    for (const auto &sink : m_sinks) {
        if (sink) {
            n++;
        }
    }
    return n;
}
