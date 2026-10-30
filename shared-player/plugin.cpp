#include "sharedvideosource.h"

#include <QQmlExtensionPlugin>
#include <QtQml>

class SharedPlayerPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<SharedVideoSource>(uri, 1, 0, "SharedVideoSource");
    }
};

#include "plugin.moc"
