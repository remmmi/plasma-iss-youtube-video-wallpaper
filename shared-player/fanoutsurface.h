#pragma once

#include <QAbstractVideoSurface>
#include <QList>
#include <QPointer>

// Single video surface given to the player, which forwards every frame to the
// surfaces of the VideoOutput items (one per screen). QVideoFrame objects are
// reference counted: the decoded picture is never copied.
class FanoutSurface : public QAbstractVideoSurface
{
    Q_OBJECT
public:
    explicit FanoutSurface(QObject *parent = nullptr);

    QList<QVideoFrame::PixelFormat> supportedPixelFormats(
        QAbstractVideoBuffer::HandleType type = QAbstractVideoBuffer::NoHandle) const override;
    bool start(const QVideoSurfaceFormat &format) override;
    void stop() override;
    bool present(const QVideoFrame &frame) override;

    void addSink(QAbstractVideoSurface *sink);
    void removeSink(QAbstractVideoSurface *sink);
    int sinkCount() const;

private:
    QList<QPointer<QAbstractVideoSurface>> m_sinks;
};
