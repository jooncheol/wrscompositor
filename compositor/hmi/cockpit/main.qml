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

import QtQuick 2.1
import QtMultimedia 5.0
import "compositor.js" as CompositorLogic
import "config.js" as Conf
import "sprintf.js" as SPrintf
import com.windriver.automotive 1.0
import com.windriver.genivi 1.0

Item {
    id: root

    height: windowHeight
    width: windowWidth

    property variant currentWindow: null
    property variant waitProcess: null
    property alias background: helixCockpitView.background
    property alias mainmenu: helixCockpitView.mainmenu
    property alias statusBar: helixCockpitView.statusBar
    property alias dockBar: helixCockpitView.dockBar
    property alias sidePanel: helixCockpitView.sidePanel
    property alias inputPanel: helixCockpitView.inputPanel
    property variant selectedWindow: null
    property bool hasFullscreenWindow: typeof compositor != "undefined" && compositor.fullscreenSurface !== null

    signal swapWindowRequested(var anObject)
    signal cloneWindowRequested(var anObject)
    signal closeClonedWindowRequested(var anObject)

    onHasFullscreenWindowChanged: {
        console.log("has fullscreen window: " + hasFullscreenWindow);
    }

    ProjectionMode {
        id: projectionMode

        signal flipCockpitSurface()
        signal flipProjectionViewSurface(var who)

        property int androidAuto: 0
        property int appleCarPlay: 1
        property string androidAutoStatus: "none"
        property string appleCarPlayStatus: "none"
        property bool androidAutoProjected: false
        property bool appleCarPlayProjected: false
        property variant androidAutoProjectionContainer: null
        property variant appleCarPlayProjectionContainer: null

        onAndroidAutoStatusChanged: {
            console.log("received onAndroidAutoStatusChanged signal");
            if (projectionMode.androidAutoStatus == "disconnected" && projectionMode.androidAutoProjected) {
                console.log("onAndroidAutoStatusChanged, try to flip helix-cockpit");
                projectionMode.flipCockpitSurface();
            }
        }

        onAppleCarPlayStatusChanged: {
            console.log("onAppleCarPlayStatusChanged, projectionStatus is changed");
            if (projectionMode.appleCarPlayStatus == "disconnected" && projectionMode.appleCarPlayProjected) {
                console.log("onAppleCarPlayStatusChanged, try to flip helix-cockpit");
                projectionMode.flipCockpitSurface();
            }
        }

        onReturnToHomeRequested: {
            console.log('return to home !!!');
            projectionMode.flipCockpitSurface();
        }
    }

    Flipable {
        id: windowFrameFlip
        width: parent.width
        height: parent.height
        property bool flipped: false
        property int who: -1

        front: CockpitView {
            id: helixCockpitView
            root: root
            visible: !projectionMode.androidAutoProjected && !projectionMode.appleCarPlayProjected
        }
        back: Item {
            id: projectionViewList
            width: parent.width
            height: parent.height

            ConnectivityProjectionView { 
                id: androidAutoProjectionView 
                visible: !projectionMode.appleCarPlayProjected
                Component.onCompleted: {
                    projectionMode.androidAutoProjectionContainer = androidAutoProjectionView.projectionView
                }
            }
            ConnectivityProjectionView { 
                id: appleCarPlayPrjectionView 
                visible: !projectionMode.androidAutoProjected 
                Component.onCompleted: {
                    projectionMode.appleCarPlayProjectionContainer = appleCarPlayPrjectionView.projectionView
                }
            }
            MultiPointTouchArea {
                id: projectionViewTouchArea
                anchors.fill: parent
                mouseEnabled: true
                minimumTouchPoints: 1
                maximumTouchPoints: 4

                onPressed: {
                    for (var touch in touchPoints) {
                        projectionMode.sendMousePressed(touchPoints[touch].pointId, touchPoints[touch].x, touchPoints[touch].y);
                    }
                }
                onReleased: {
                    for (var touch in touchPoints) {
                        projectionMode.sendMouseReleased(touchPoints[touch].pointId, touchPoints[touch].x, touchPoints[touch].y);
                    }
                }

                onTouchUpdated: {
                    for (var touch in touchPoints) {
                        projectionMode.sendMouseMove(touchPoints[touch].pointId, touchPoints[touch].x, touchPoints[touch].y);
                    }
                }
            }
        }
        transform: Rotation {
            id: rotation
            origin.x: windowFrameFlip.width/2
            origin.y: windowFrameFlip.height/2
            axis.x: 0; axis.y: 1; axis.z: 0     // set axis.y to 1 to rotate around y-axis
            angle: 0    // the default angle
        }
        states: State {
            name: "back"
            PropertyChanges { target: rotation; angle: 180 } 
            when: windowFrameFlip.flipped
        }
        transitions: Transition {
            NumberAnimation { target: rotation; property: "angle"; duration: 500 }
        }

        onSideChanged: {
            if(side==Flipable.Front) {
                console.log('onSideChanged(front), focused window is helix-cockpit');
                projectionMode.androidAutoProjected = false;
                projectionMode.appleCarPlayProjected = false;
                projectionMode.sendVideoFocus(projectionMode.androidAuto, false);
                projectionMode.sendVideoFocus(projectionMode.appleCarPlay, false);
            } 
            else {
                console.log('onSideChanged(back), focused window is projectionView');
                var whoHasFlipped = windowFrameFlip.who;
                projectionMode.androidAutoProjected = (whoHasFlipped==projectionMode.androidAuto) ? true : false;
                projectionMode.appleCarPlayProjected = (whoHasFlipped==projectionMode.appleCarPlay) ? true : false; 
                projectionMode.sendVideoFocus(whoHasFlipped, true);

            }
        }
        Component.onCompleted: {
            projectionMode.flipProjectionViewSurface.connect(function(who) {
                console.log("Recevied flipProjectionViewSurface signal");
                windowFrameFlip.flipped = true; 
                windowFrameFlip.who = who;
            })

            projectionMode.flipCockpitSurface.connect(function() {
                console.log("Recevied flipCockpitSurface signal");
                windowFrameFlip.flipped = false; 
                windowFrameFlip.who = -1;
            })

            statusBar.switchNextWindow.connect(function() {
                console.log("Recevied switchNextWindow signal");
                if (!statusBar.mainMenuActivated && !statusBar.fullscreenViewed && root.currentWindow) {
                    var nextWindow = CompositorLogic.switchNextWindow(root.currentWindow);
                    if (nextWindow != null)
                        root.currentWindow = nextWindow
                }
            })

            statusBar.resizeCurrentWindow.connect(function() {
                console.log("Recevied resizeCurrentWindow signal");
                if (!statusBar.mainMenuActivated && root.currentWindow) {
                    statusBar.fullscreenViewed =! statusBar.fullscreenViewed;
                    if (statusBar.fullscreenViewed)  {
                        console.log("hide both sidePanel and dockBar to make current window fullscreen");
                        sidePanel.hide();
                        if (!inputPanel.active)
                            dockBar.hide();
                    } else {
                        console.log("show both sidePanel and dockBar to make current window defaultscreen");
                        sidePanel.show();
                        if (!inputPanel.active)
                            dockBar.show();
                    }

                    CompositorLogic.resizedCurrentWindow(
                        root.currentWindow,
                        statusBar.fullscreenViewed? helixCockpitView.fullScreenWidth : helixCockpitView.defaultScreenWidth,
                        statusBar.fullscreenViewed? helixCockpitView.fullScreenHeight : helixCockpitView.defaultScreenHeight);
                }
            })
        }
    }

    function raiseWindow(window) {
        if(root.currentWindow != null)
            root.currentWindow.hide();
        root.currentWindow = window
        root.currentWindow.show();
        if(mainmenu.visible)
            mainmenu.hide();
    }

    function raiseWindowByProcessId(pid) {
        var window = CompositorLogic.findByProcessId(pid);
        if (window != null) {
            console.log("find window for pid, try to raise window again");
            root.raiseWindow(window);
        }
    }

    function swappedWindowRestored(surfaceItem) {
        if(!Conf.useMultiWaylandDisplayFeature)
            return;
        console.log("swappedWindowRestored: "+surfaceItem);

        var windowFrame = CompositorLogic.findBySurface(surfaceItem.surface);
        console.log(windowFrame);
        root.raiseWindow(windowFrame);
    }
    function windowDestroyed(surface) {
        console.log('surface destroyed '+surface);
        console.log('surface destroyed title:'+surface.title);

        var windowFrame = CompositorLogic.findBySurface(surface);
        if(!windowFrame)
            return;

        if(root.currentWindow == windowFrame)
            root.currentWindow = null;

        if (surface.title == 'OpenGL Renderer' && windowFrame.projectionConnectivityStatus) {
            if (windowFrame.projectionName == Conf.aapName) {
                console.log("android-auto is disconnected");
                projectionMode.androidAutoStatus = "disconnected";
            } else if (windowFrame.projectionName == Conf.carplayName) {
                console.log("apple-carplay is disconnected");
                projectionMode.appleCarPlayStatus = "disconnected";
            } else {
                console.log('cannot get valid projection name for disconnecting projectionMode');
                return;
            }
        }

        var layer = iviScene.mainScreen.layerById(1000); // application layer
        layer.removeSurface(windowFrame.ivi_surface);
        console.log('position '+windowFrame.position);
        if(Conf.useMultiWaylandDisplayFeature && (windowFrame.cloned || windowFrame.position != 'main')) {
            root.closeClonedWindowRequested(windowFrame.surfaceItem);
        }
        windowFrame.destroy();
        CompositorLogic.removeWindow(windowFrame);
        if(Conf.useMultiWindowFeature)
            CompositorLogic.relayoutForMultiWindow(background.width, background.height);

    }

    function windowAdded(surface) {
        console.log('surface added '+surface);
        console.log('surface added title:'+surface.title);
        console.log('surface added className:'+surface.className);
        console.log('surface added client: '+surface.client);
        console.log('surface added pid: '+surface.client.processId);
        console.log(iviScene.mainScreen);
        console.log(iviScene.mainScreen.layerCount());
        console.log(iviScene.mainScreen.layer(0));
        console.log(iviScene.mainScreen.layer(0).visibility);

        //TODO - get surface Role using iviScene.getSurfaceRole() - this should return a generic role based on cmd-line, UID, GID, ivi-surface3-id

        var layer = iviScene.mainScreen.layerById(1000); // application layer
        var windowContainerComponent = Qt.createComponent("WindowFrame.qml");
        var windowFrame;
        if (surface.title == 'OpenGL Renderer') { 
            var projectionName = util.getCmdForPid(surface.client.processId);
             // gstreamer-0.1: gsteglgles
            if (projectionName == Conf.aapName) {
                console.log("android-auto is connected");
                projectionMode.androidAutoStatus = "connected";
                windowFrame = windowContainerComponent.createObject(projectionMode.androidAutoProjectionContainer);
            } else if (projectionName == Conf.carplayName) {
                console.log("apple-carplay is connected");
                projectionMode.appleCarPlayStatus = "connected";
                windowFrame = windowContainerComponent.createObject(projectionMode.appleCarPlayProjectionContainer);   
            } else {
                console.log('cannot get valid projection name for connecting projectionMode');
                return;
            }
            windowFrame.projectionName = projectionName;
            windowFrame.projectionConnectivityStatus = true;
            windowFrame.z = -1;
            windowFrame.scaledWidth = Conf.displayWidth/surface.size.width;
            windowFrame.scaledHeight = Conf.displayHeight/surface.size.height;
        } else {
            windowFrame = windowContainerComponent.createObject(background);
            windowFrame.projectionConnectivityStatus = false;
            windowFrame.z = 50;   
            windowFrame.scaledWidth = background.width/surface.size.width;
            windowFrame.scaledHeight = background.height/surface.size.height;
            windowFrame.rootBackground = background
        }

        windowFrame.width = surface.size.width;
        windowFrame.height = surface.size.height;
        windowFrame.surface = surface;
        windowFrame.surfaceItem = compositor.item(surface);
        windowFrame.surfaceItem.parent = windowFrame;
        windowFrame.surfaceItem.touchEventsEnabled = true;
        windowFrame.processId = surface.client.processId;
        windowFrame.targetX = 0;
        windowFrame.targetY = 0;
        windowFrame.targetWidth = surface.size.width;
        windowFrame.targetHeight = surface.size.height;
        windowFrame.ivi_surface = layer.createSurface(0, 0, surface.size.width, surface.size.height, windowFrame);
        windowFrame.ivi_surface.id = surface.client.processId;
        layer.addSurface(windowFrame.ivi_surface);

        if (root.waitProcess && root.waitProcess.pid == surface.client.processId) {
            root.waitProcess.setWindow(windowFrame);
            root.waitProcess = null;
        }

        if (!Conf.useMultiWindowFeature) {
            // XXX scale to fit into main area
            CompositorLogic.addWindow(windowFrame);
        } else { // for multi surface feature enabled mode
            // stretch to maximum size as default
            windowFrame.scaledWidth = background.width/surface.size.width;
            windowFrame.scaledHeight = background.height/surface.size.height;
            console.log("oscaleds "+ background.height/surface.size.height);

            // add surface and relayout for multi surface feature
            CompositorLogic.addMultiWindow(windowFrame,
                                    background.width, background.height);
        }

        windowFrame.opacity = 1

        if(!windowFrame.projectionConnectivityStatus) {
            if(!Conf.useMultiWindowFeature) 
                CompositorLogic.hideWithout(windowFrame);
            root.currentWindow = windowFrame
            root.currentWindow.show();

            if(mainmenu.visible)
                mainmenu.hide();
        }
    }

    function windowResized(surface) {
        console.log('surface resized '+surface);
        surface.width = surface.surface.size.width;
        surface.height = surface.surface.size.height;
    }

    Keys.onPressed: {
        console.log('key on main: '+event.key);
        if (event.key == Qt.Key_F1) {
            if(mainmenu.visible)
                mainmenu.hide()
            else
                mainmenu.show()
        } else if (event.key == Qt.Key_Backspace) {
            console.log('backspace');
            if(mainmenu.visible)
                mainmenu.hide();
        }
    }
    onWidthChanged: {
        Conf.displayWidth = width;
    }
    onHeightChanged: {
        Conf.displayHeight = height;
    }
    Component.onCompleted: {
        if(!Conf.useMultiWaylandDisplayFeature)
            return;
        statusBar.swapWindow.connect(function() {
            console.log("swap button clicked");
            console.log(root.currentWindow);
            if(root.currentWindow.cloned)
                return;
            root.currentWindow.position = "rear";
            root.swapWindowRequested(root.currentWindow);
            root.currentWindow.hide();
        });
        statusBar.cloneWindow.connect(function() {
            console.log("clone button clicked");
            if(root.currentWindow.cloned) {
                root.closeClonedWindowRequested(root.currentWindow.surfaceItem);
                root.currentWindow.cloned = false;
            } else {
                root.cloneWindowRequested(root.currentWindow);
                root.currentWindow.cloned = true;
            }
        });
    }
}
