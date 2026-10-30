#pragma once

#include <QAbstractVideoSurface>
#include <QList>
#include <QPointer>

// Surface video unique donnee au lecteur, qui redistribue chaque image aux
// surfaces des VideoOutput (une par ecran). Les QVideoFrame sont partagees
// par compteur de references : pas de copie de l'image decodee.
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
