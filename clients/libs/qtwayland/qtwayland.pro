QT += gui-private quick qml
QT += waylandclient-private
CONFIG += wayland-scanner staticlib
TARGET = WrsQtWayland
TEMPLATE = lib

!contains(QT_CONFIG, no-pkg-config) {
    PKGCONFIG += wayland-client wayland-cursor
    CONFIG += link_pkgconfig
} else {
    LIBS += -lwayland-client -lwayland-cursor
}

WAYLANDCLIENTSOURCES += \
    ../protocol/ivi-application.xml \
    ../protocol/ivi-controller.xml \
    ../protocol/input-method.xml \
    ../protocol/text.xml

LOCAL_SOURCES = qwayland-common.cpp qwaylandinputmethod.cpp
LOCAL_HEADERS = qwayland-common.h qwaylandinputmethod.h

SOURCES += $$LOCAL_SOURCES
HEADERS += $$LOCAL_HEADERS
