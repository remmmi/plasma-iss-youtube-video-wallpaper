# QML module local.isslive.shared: a single video player shared by all the
# ISS wallpapers of plasmashell (one decode for all screens).
TEMPLATE = lib
TARGET = sharedplayerplugin
CONFIG += plugin c++17 release
QT += qml quick multimedia

SOURCES += plugin.cpp hub.cpp fanoutsurface.cpp sharedvideosource.cpp
HEADERS += hub.h fanoutsurface.h sharedvideosource.h

DESTDIR = build
OBJECTS_DIR = build/obj
MOC_DIR = build/moc

target.path = $$(HOME)/.local/lib/qml/local/isslive/shared
qmldir.files = qmldir
qmldir.path = $$target.path
INSTALLS += target qmldir
