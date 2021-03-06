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
import com.windriver.wrscompositor 1.0
import "hmi-interface.js" as Interface

Image {
    id: background
    width: parent.width
    height: parent.height

    source: "resources/wallpaper.svg"

    function eventHandler(event, object) {
        switch(event) {
            case Interface.COMPOSITOR_EVENT.ADD_WINDOW:
                console.log("BackGround, eventHandler receive ADD_WINDOW Event");
                break;
            case Interface.COMPOSITOR_EVENT.REMOVE_WINDOW:
                console.log("BackGround, eventHandler receive REMOVE_WINDOW Event");
                break;
            default:
                return;
        }
    }

    Component.onCompleted: {
        /* hmi-interface.js's API: each QML for HMI should register object id and event handler */
        Interface.registerComponent(background, "BackGround");
        Interface.registerNotifyEventHandler(background.eventHandler);
    }
}
