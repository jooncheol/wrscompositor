/*
 * Copyright © 2016 Wind River Systems, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "config.h"
#include "wrscompositor.h"
#include "reardisplay.h"
#include <QGuiApplication>
#include <QScreen>
#include <QSettings>

RearDisplay::RearDisplay(QWindow *parent)
    : QQuickView(parent)
{
    setTitle(QLatin1String("Wind River WrsCompositor Rear Display Example"));
    QUrl programUrl = QUrl("qrc:///rearmain.qml");
    if(qApp->arguments().contains("--debug"))
        programUrl = QUrl("hmi/" WRSCOMPOSITOR_HMI_PROFILE "/rearmain.qml");
    setSource(programUrl);
    setResizeMode(QQuickView::SizeRootObjectToView);

    QScreen *screen = QGuiApplication::primaryScreen();
    if(QGuiApplication::screens().count() > 1) {
        screen = QGuiApplication::screens().at(2); // third
        setScreen(screen);
    }
    setGeometry(screen->availableGeometry());
    QObject::connect(this, SIGNAL(windowSwapped(QVariant)), rootObject(), SLOT(windowSwapped(QVariant)));
    QObject::connect(this, SIGNAL(windowCloned(QVariant)), rootObject(), SLOT(windowCloned(QVariant)));
    QObject::connect(this, SIGNAL(windowCloneClosed(QVariant)), rootObject(), SLOT(windowCloneClosed(QVariant)));
    QObject::connect(rootObject(), SIGNAL(swappedWindowRestoreRequested(QVariant)), this, SLOT(slotSwappedWindowRestore(QVariant)));
    //QObject::connect(rootObject(), SIGNAL(clonedWindowRestoreRequested(QVariant)), this, SLOT(slotClonedWindowRestore(QVariant)));
    QObject::connect(rootObject(), SIGNAL(clonedSurfaceItemDestroyed(QVariant)), this, SLOT(slotClonedSurfaceDestroy(QVariant)));
}

RearDisplay::~RearDisplay() {
}
void RearDisplay::addSwappedWindow(QQuickItem *windowFrame) {
    emit windowSwapped(QVariant::fromValue(windowFrame));
}
void RearDisplay::addClonedWindow(QWaylandSurfaceItem *item) {
    emit windowCloned(QVariant::fromValue(item));
}
void RearDisplay::closeClonedWindow(QWaylandQuickSurface *surface) {
    emit windowCloneClosed(QVariant::fromValue(surface));
}

void RearDisplay::slotSwappedWindowRestore(const QVariant &v) {
    QWaylandSurfaceItem *surfaceItem = qobject_cast<QWaylandSurfaceItem*>(v.value<QObject*>());
    //QWaylandQuickSurface *surface = qobject_cast<QWaylandQuickSurface*>(surfaceItem->surface());
    //surface->setMainOutput(mMainOutput);
    /*
    QWaylandSurfaceLeaveEvent *le = new QWaylandSurfaceLeaveEvent(mMainOutput);
    QWaylandSurfaceEnterEvent *ee = new QWaylandSurfaceEnterEvent(mRearOutput);
    qApp->sendEvent(surface, le);
    qApp->sendEvent(surface, ee);
    qApp->flush();
    mRearDisplay->update();
    */
    qobject_cast<WrsCompositor*>(mMainDisplay)->restoreSwappedWindow(surfaceItem);
    surfaceItem->deleteLater();
}

void RearDisplay::slotClonedSurfaceDestroy(const QVariant &v) {
    QWaylandSurfaceItem *surfaceItem = qobject_cast<QWaylandSurfaceItem*>(v.value<QObject*>());
    surfaceItem->deleteLater();
}
