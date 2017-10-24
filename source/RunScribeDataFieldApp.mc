//
// MIT License
//
// Copyright (c) 2017 Scribe Labs Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

using Toybox.Application as App;

class RunScribeDataFieldApp extends App.AppBase {
    
    var mDataField;
    var mScreenShape;
    
    function initialize() {
        AppBase.initialize();
        mScreenShape = System.getDeviceSettings().screenShape;
    }
    
    function onStart(state) {
    }
    
    function getInitialView() {
        var sensorLeft;
        var sensorRight;
        
        try {
            sensorLeft = new RunScribeSensor(11, 51, 2048);
            sensorLeft.open();
            sensorRight = new RunScribeSensor(12, 63, 2048);
            sensorRight.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            sensorLeft = null;
            sensorRight = null;
        }
        
        mDataField = new RunScribeDataField(sensorLeft, sensorRight, mScreenShape);
        
        return [mDataField];
    }
    
    function onStop(state) {
        if (mDataField.mSensorLeft != null) {
            mDataField.mSensorLeft.closeSensor();
            mDataField.mSensorRight.closeSensor();
        }
        return false;
    }
    
    function onSettingsChanged() {
        mDataField.onSettingsChanged();
    }
}