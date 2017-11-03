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
    var mScreenHeight;
    
    function initialize() {
        AppBase.initialize();
        var settings = System.getDeviceSettings();
        mScreenShape = settings.screenShape;
        mScreenHeight = settings.screenHeight;
    }
    
    function getInitialView() {
        var sensorLeft;
        var sensorRight;
        
        try {
            /*
            var freq = "Freq";
            var period = getProperty("period");
            
            sensorLeft = new RunScribeSensor(11, getProperty("l" + freq), period);
            sensorRight = new RunScribeSensor(12, getProperty("r" + freq), period);
            */
            
            sensorLeft = new RunScribeSensor(11, 62, 2048);
            sensorRight = new RunScribeSensor(12, 64, 2048);
            sensorLeft.open();
            sensorRight.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            sensorLeft = null;
            sensorRight = null;
        }
        
        var lrRecording = getProperty("lrmetrics");
        var recordedChannelCount = 1;
        if (lrRecording == true) {
            recordedChannelCount = 2;
        }

        mDataField = new RunScribeDataField(sensorLeft, sensorRight, mScreenShape, mScreenHeight, recordedChannelCount);
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
