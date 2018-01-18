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

using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.FitContributor as Fit;

class RunScribeDataField extends Ui.DataField {

    hidden var mMetricTypes = [-1, -1, -1, -1];  // 0 - Impact GS, 1 - Braking GS, 2 - FS Type, 3 - Pronation, 4 - Flight Ratio, 5 - Contact Time, 6 - Power

    hidden var mMetricCount = 0;
    hidden var mVisibleMetrics;

    hidden var mVisibleMetricCount;

    // Common
    hidden var mMetricTitleY;
    hidden var mMetricValueY;
    hidden var mMetricValueOffsetX;
        
    // Font values
    hidden var mDataFont;
    hidden var mDataFontHeight;
    
    var mSensorLeft;
    var mSensorRight;
    
    hidden var mScreenShape;
    hidden var mScreenHeight;
    
    hidden var xCenter;
    hidden var yCenter;
    
    hidden var mUpdateLayout = 0;
    
    // FIT Contributions variables
    hidden var mMetricContributorsLeft = [null, null, null, null];
    hidden var mMetricContributorsRight = [null, null, null, null];

    hidden var mPowerContributor;
    
    // Constructor
    function initialize(sensorL, sensorR, screenShape, screenHeight) {
        DataField.initialize();
        
        mScreenShape = screenShape;
        mScreenHeight = screenHeight;
        
        // Reads what metrics chosen and removes duplicate metrics
        onSettingsChanged();
        
        mSensorLeft = sensorL;
        mSensorRight = sensorR;

        var d = {};
        var units = "units";

        var hasPower = 0;
        
        for (var i = 0; i < 4; ++i) {
	        if (mMetricTypes[i] >= 0) {
	            d[units] = getMetricUnit(mMetricTypes[i]);
	            if (mMetricTypes[i] < 6) {
		            mMetricContributorsLeft[i] = createField("", mMetricTypes[i], Fit.DATA_TYPE_FLOAT, d);
		            mMetricContributorsRight[i] = createField("", mMetricTypes[i] + 6, Fit.DATA_TYPE_FLOAT, d);
		       } else {
		           hasPower = 1;
		       }
	        }
        }

        if (hasPower > 0) {
            d[units] = getMetricUnit(6);
            mPowerContributor = createField("", 12, Fit.DATA_TYPE_FLOAT, d);
        }
    }
    
    function onSettingsChanged() {
        var app = App.getApp();
        
        if (mMetricCount == 0) {
            var name = "tM";
            for (var i = 0; i < 4; ++i) {
                mMetricTypes[i] = app.getProperty(name + (i + 1));
                // Remove duplicatate metrics
                for (var j = 0; j < i; ++j) {
                    if (mMetricTypes[i] == mMetricTypes[j]) {
                        mMetricTypes[i] = -1;
                    }
                }
            }
            
            if (mMetricTypes[1] < 0) {
                if (mMetricTypes[2] < 0) {
                    mMetricTypes[1] = mMetricTypes[3];
                } else {
                    mMetricTypes[1] = mMetricTypes[2];
                    mMetricTypes[2] = mMetricTypes[3];
                }
                mMetricTypes[3] = -1;
            } else if (mMetricTypes[2] < 0) {
                mMetricTypes[2] = mMetricTypes[3];
                mMetricTypes[3] = -1;
            }
    
            for (var i = 0; i < 4; ++i) {
                if (mMetricTypes[i] >= 0) {
                    mMetricCount = i + 1;
                }        
            }
        }
        
        mVisibleMetrics = app.getProperty("visibleMetrics");
        if (mMetricCount < mVisibleMetrics) {
            mVisibleMetrics = mMetricCount;
        }
        
        mUpdateLayout = 1;
    }
    
    function updateMetrics(sensor, contributors) {
        if (!sensor.isChannelOpen) {
            sensor.openChannel();
        }
       
        sensor.idleTime++;
        if (sensor.idleTime > 30) {
            sensor.closeChannel();
        }
    
        for (var i = 0; i < 4; ++i) {
	        if (contributors[i] != null) {
	            contributors[i].setData(sensor.data[mMetricTypes[i]]);
	        }
        }            
    }
    
    function compute(info) {
    
        var power = 0.0;
        var sensorCount = 0;
    
        if (mSensorLeft != null) {
            updateMetrics(mSensorLeft, mMetricContributorsLeft);
            power = mSensorLeft.data[6];
            ++sensorCount;
        }

        if (mSensorRight != null) {
            updateMetrics(mSensorRight, mMetricContributorsRight);
            power += mSensorRight.data[6];
            ++sensorCount;
        }
                
        if (mPowerContributor != null && sensorCount > 0) {
            mPowerContributor.setData(power / sensorCount);
        }
    }

    function onLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        mVisibleMetricCount = mVisibleMetrics;
        
        if (height < mScreenHeight) {
            mVisibleMetricCount = 1;
        }
        
        xCenter = width / 2;
        yCenter = height / 2;
                
        mMetricValueOffsetX = dc.getTextWidthInPixels(" ", Gfx.FONT_XTINY) + 2;

        // Compute data width/height for horizintal layouts
        var metricNameFontHeight = dc.getFontHeight(Gfx.FONT_XTINY) + 2;
        if (mVisibleMetricCount == 2) {
            width *= 1.6;
        } else if (mVisibleMetricCount == 1) {
            width *= 2.0;
        }

        var fontIdx;
        var fonts = [Gfx.FONT_XTINY, Gfx.FONT_TINY, Gfx.FONT_SMALL, Gfx.FONT_MEDIUM, Gfx.FONT_LARGE,
                    Gfx.FONT_NUMBER_MILD, Gfx.FONT_NUMBER_MEDIUM, Gfx.FONT_NUMBER_HOT, Gfx.FONT_NUMBER_THAI_HOT];
                     
        //Search through fonts from biggest to smallest
        for (fontIdx = 8; fontIdx > 0; --fontIdx) {
            if ((dc.getTextWidthInPixels("00.0-", fonts[fontIdx]) <= width * 0.225)) {
                // If this font fits, it is the biggest one that does
                break;
            }
        }
        
        mDataFont = fonts[fontIdx];       
            
        mDataFontHeight = dc.getFontHeight(mDataFont);    
            
        mMetricTitleY = -(mDataFontHeight + metricNameFontHeight) * 0.5;
        if (mScreenShape == System.SCREEN_SHAPE_ROUND) {
            mMetricTitleY *= 1.1;
        } 
        
        mMetricValueY = mMetricTitleY + metricNameFontHeight;
        
        mUpdateLayout = 0;
    }
    
    hidden function getMetricName(metricType) {
        if (metricType == 0) {
            return "Impact Gs";
        } 
        if (metricType == 1) {
            return "Braking Gs";
        } 
        if (metricType == 2) {
            return "Footstrike";
        } 
        if (metricType == 3) {
            return "Pronation";
        } 
        if (metricType == 4) {
            return "Flight (%)";
        } 
        if (metricType == 5) {
            return "GCT (ms)";
        } 
        if (metricType == 6) {
            return "Power (W)";
        }
        
        return null;
    }
    
    hidden function getMetricUnit(metricType) {
        if (metricType == 0 || metricType == 1) {
            return "G";
        } 
        if (metricType == 2) {
            return "";
        } 
        if (metricType == 3) {
            return "°";
        } 
        if (metricType == 4) {
            return "%";
        } 
        if (metricType == 5) {
            return "ms";
        } 
        if (metricType == 6) {
            return "W";
        }
        
        return null;
    }
    
        
    hidden function getMetric(metricType, sensor) {
        var data = sensor.data[metricType];
        
        if (metricType == 2 || metricType == 5) {
            return data.format("%d");
        }
        
        return data.format("%.1f");
    }
    
    
    // Handle the update event
    function onUpdate(dc) {
        var bgColor = getBackgroundColor();
        var fgColor = Gfx.COLOR_WHITE;
        
        if (bgColor == Gfx.COLOR_WHITE) {
            fgColor = Gfx.COLOR_BLACK;
        }
        
        dc.setColor(fgColor, bgColor);
        dc.clear();
        
        dc.setColor(fgColor, Gfx.COLOR_TRANSPARENT);
        
        if (mUpdateLayout != 0) {
            onLayout(dc);
        }

        // Update status
        if ((mSensorLeft != null && mSensorRight != null) && (mSensorRight.searching == 0 || mSensorLeft.searching == 0)) {
            
            var met1x, met1y, met2x = 0, met2y = 0, met3x = 0, met3y = 0, met4x = 0, met4y = 0;
            
            var yOffset = yCenter * 0.55;
            var xOffset = xCenter * 0.45;
        
            if (mScreenShape == System.SCREEN_SHAPE_SEMI_ROUND) {
                yOffset *= 1.15;
            }
        
            if (mVisibleMetricCount == 1) {
                met1x = xCenter;
                met1y = yCenter;
            }
            else if (mVisibleMetricCount == 2) {
                met1x = xCenter;
                met2x = met1x;
                if (mScreenShape == System.SCREEN_SHAPE_RECTANGLE) {
                    yOffset *= 1.35;
                }
                met1y = yCenter - yOffset * 0.6;
                met2y = yCenter + yOffset * 0.6;
            } else if (mScreenShape == System.SCREEN_SHAPE_RECTANGLE) {
                yOffset *= 0.8;
                met1x = xCenter - xOffset;
                met1y = yCenter - yOffset;
                met2x = xCenter + xOffset;
                met2y = met1y;
                met3y = yCenter + yOffset;  
            
                if (mVisibleMetricCount == 3) {
                    met3x = xCenter;
                } else {
                    met3x = met1x;
                    met4x = met2x;
                    met4y = met3y;  
                }
            }
            else {
                met1x = xCenter;
                met1y = yCenter - yOffset;
                met2y = yCenter;
                 
                if (mVisibleMetricCount == 3) {
                    met2x = met1x;
                    met3x = met1x;
                    met3y = yCenter + yOffset;
                } else {
                    met2x = xCenter - xOffset;
                    met3x = xCenter + xOffset;
                    met3y = met2y;
                    met4x = met1x;
                    met4y = yCenter + yOffset;
                }
            }
            
            drawMetricOffset(dc, met1x, met1y, mMetricTypes[0]);         
            if (mVisibleMetricCount >= 2) {
                drawMetricOffset(dc, met2x, met2y, mMetricTypes[1]);
                if (mVisibleMetricCount >= 3) {
                    drawMetricOffset(dc, met3x, met3y, mMetricTypes[2]);
                    if (mVisibleMetricCount == 4) {
                        drawMetricOffset(dc, met4x, met4y, mMetricTypes[3]);
                    } 
                } 
            }
        } else {
            var message = "Searching(2.1)...";
            if (mSensorLeft == null || mSensorRight == null) {
                message = "No Channel!";
            }
            
            dc.drawText(xCenter, yCenter - dc.getFontHeight(Gfx.FONT_MEDIUM) / 2, Gfx.FONT_MEDIUM, message, Gfx.TEXT_JUSTIFY_CENTER);
        }        
    }

    hidden function drawMetricOffset(dc, x, y, metricType) {
    
        var metricLeft = getMetric(metricType, mSensorLeft);
        var metricRight = getMetric(metricType, mSensorRight);
        
        dc.drawText(x, y + mMetricTitleY, Gfx.FONT_XTINY, getMetricName(metricType), Gfx.TEXT_JUSTIFY_CENTER);

        if (metricType == 6) {
            // Power metric presents a single value
            dc.drawText(x, y + mMetricValueY, mDataFont, ((mSensorLeft.data[6] + mSensorRight.data[6]) / 2).format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x - mMetricValueOffsetX, y + mMetricValueY, mDataFont, metricLeft, Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(x + mMetricValueOffsetX, y + mMetricValueY, mDataFont, metricRight, Gfx.TEXT_JUSTIFY_LEFT);
            
            // Draw line
            dc.drawLine(x, y + mMetricValueY, x, y + mMetricValueY + mDataFontHeight);
        }    
    }
}
