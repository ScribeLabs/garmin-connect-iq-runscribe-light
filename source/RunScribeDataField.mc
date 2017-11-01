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
    
    hidden var mMetric1Type; // 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time
    hidden var mMetric2Type; // 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time
    hidden var mMetric3Type; // 0 - None, 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time
    hidden var mMetric4Type; // 0 - None, 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time

    hidden var mMetricCount;
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
    hidden var mCurrentBGFieldLeft;
    hidden var mCurrentIGFieldLeft;
    hidden var mCurrentFSFieldLeft;
    hidden var mCurrentPronationFieldLeft;
    hidden var mCurrentFlightFieldLeft;
    hidden var mCurrentGCTFieldLeft;

    hidden var mCurrentBGFieldRight;
    hidden var mCurrentIGFieldRight;
    hidden var mCurrentFSFieldRight;
    hidden var mCurrentPronationFieldRight;
    hidden var mCurrentFlightFieldRight;
    hidden var mCurrentGCTFieldRight;    

    hidden var mCurrentPowerField;
    
    // Constructor
    function initialize(sensorL, sensorR, screenShape, screenHeight, storedChannelCount) {
        DataField.initialize();
        
        mScreenShape = screenShape;
        mScreenHeight = screenHeight;
        
        onSettingsChanged();
        
        mSensorLeft = sensorL;
        mSensorRight = sensorR;

        var d = {};
        var units = "units";

        var offset = 0;

        if (storedChannelCount == 2) {
	        mCurrentFSFieldRight = createField("", 8, Fit.DATA_TYPE_SINT8, d);
        } else {
            offset = 12;
        }	

        mCurrentFSFieldLeft = createField("", 2 + offset, Fit.DATA_TYPE_SINT8, d);

        d[units] = "G";
        
        if (storedChannelCount == 2) {         
	        mCurrentBGFieldRight = createField("", 6, Fit.DATA_TYPE_FLOAT, d);
	        mCurrentIGFieldRight = createField("", 7, Fit.DATA_TYPE_FLOAT, d);
        }	

        mCurrentBGFieldLeft = createField("", 0 + offset, Fit.DATA_TYPE_FLOAT, d);
        mCurrentIGFieldLeft = createField("", 1 + offset, Fit.DATA_TYPE_FLOAT, d);
        
        d[units] = "D";
        
        if (storedChannelCount == 2) {         
	        mCurrentPronationFieldRight = createField("", 9, Fit.DATA_TYPE_SINT16, d);
        }
        
        mCurrentPronationFieldLeft = createField("", 3 + offset, Fit.DATA_TYPE_SINT16, d);
	    
	    d[units] = "%";
	    if (storedChannelCount == 2) {
	        mCurrentFlightFieldRight = createField("", 10, Fit.DATA_TYPE_SINT8, d);
		}

        mCurrentFlightFieldLeft = createField("", 4 + offset, Fit.DATA_TYPE_SINT8, d);
	   
	    d[units] = "ms";
        if (storedChannelCount == 2) {
	        mCurrentGCTFieldRight = createField("", 11, Fit.DATA_TYPE_SINT16, d);
        } 

        mCurrentGCTFieldLeft = createField("", 5 + offset, Fit.DATA_TYPE_SINT16, d);
        
        d[units] = "W";
        mCurrentPowerField = createField("", 18, Fit.DATA_TYPE_SINT16, d);
    }
    
    function onSettingsChanged() {
        var app = App.getApp();
        
        var name = "typeMetric";
        mMetric1Type = app.getProperty(name + "1");
        mMetric2Type = app.getProperty(name + "2");
        mMetric3Type = app.getProperty(name + "3");
        mMetric4Type = app.getProperty(name + "4");

        // Remove empty metrics from between
        if (mMetric2Type == 0) {
            if (mMetric3Type == 0) {
                mMetric2Type = mMetric4Type;
                mMetric4Type = 0;
            } else {
                mMetric2Type = mMetric3Type;
                mMetric3Type = mMetric4Type;
                mMetric4Type = 0;
            }
        } else if (mMetric3Type == 0) {
            mMetric3Type = mMetric4Type;
            mMetric4Type = 0;
        }
        
        if (mMetric4Type != 0) {
            mMetricCount = 4; 
        } else if (mMetric3Type != 0) {
            mMetricCount = 3;
        } else if (mMetric2Type != 0) {
            mMetricCount = 2;
        } else {
            mMetricCount = 1;
        }
        
        mUpdateLayout = 1;
    }
    
    function compute(info) {
        if (mSensorLeft != null)  {
            // Average L/R for combined metric
            mCurrentBGFieldLeft.setData(mSensorLeft.braking_gs);
            mCurrentIGFieldLeft.setData(mSensorLeft.impact_gs);
            mCurrentFSFieldLeft.setData(mSensorLeft.footstrike_type);
            mCurrentPronationFieldLeft.setData(mSensorLeft.pronation_excursion_fs_mp);
            mCurrentFlightFieldLeft.setData(mSensorLeft.flight_ratio);
            mCurrentGCTFieldLeft.setData(mSensorLeft.contact_time);
            if (mSensorRight != null) {
                mCurrentPowerField.setData((mSensorLeft.power + mSensorRight.power) * 0.5);
            }
        }
        
        if (mSensorRight != null) {
            mCurrentBGFieldRight.setData(mSensorRight.braking_gs);
            mCurrentIGFieldRight.setData(mSensorRight.impact_gs);
            mCurrentFSFieldRight.setData(mSensorRight.footstrike_type);
            mCurrentPronationFieldRight.setData(mSensorRight.pronation_excursion_fs_mp);
            mCurrentFlightFieldRight.setData(mSensorRight.flight_ratio);
            mCurrentGCTFieldRight.setData(mSensorRight.contact_time);
        }
    }

    function onLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        if (height < mScreenHeight) {
            mVisibleMetricCount = 1;
        } else {
            mVisibleMetricCount = mMetricCount;
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

        mDataFont = selectFont(dc, width * 0.45, height - metricNameFontHeight, "00.0--00.0");
            
        mDataFontHeight = dc.getFontHeight(mDataFont);    
            
        mMetricTitleY = -(mDataFontHeight + metricNameFontHeight) * 0.5;
        if (mScreenShape == System.SCREEN_SHAPE_ROUND) {
            mMetricTitleY *= 1.1;
        } 
        
        mMetricValueY = mMetricTitleY + metricNameFontHeight;
        
        mUpdateLayout = 0;
    }
    
    hidden function selectFont(dc, width, height, testString) {
        var fontIdx;
        var dimensions;
        
        var fonts = [Gfx.FONT_XTINY, Gfx.FONT_TINY, Gfx.FONT_SMALL, Gfx.FONT_MEDIUM, Gfx.FONT_LARGE,
                    Gfx.FONT_NUMBER_MILD, Gfx.FONT_NUMBER_MEDIUM, Gfx.FONT_NUMBER_HOT, Gfx.FONT_NUMBER_THAI_HOT];
                     
        //Search through fonts from biggest to smallest
        for (fontIdx = fonts.size() - 1; fontIdx > 0; --fontIdx) {
            dimensions = dc.getTextDimensions(testString, fonts[fontIdx]);
            if ((dimensions[0] <= width) && (dimensions[1] <= height)) {
                // If this font fits, it is the biggest one that does
                break;
            }
        }
        
        return fonts[fontIdx];
    }
    
    hidden function getMetricName(metricType) {
        if (metricType == 1) {
            return "Impact Gs";
        } 
        if (metricType == 2) {
            return "Braking Gs";
        } 
        if (metricType == 3) {
            return "Footstrike";
        } 
        if (metricType == 4) {
            return "Pronation";
        } 
        if (metricType == 5) {
            return "Flight (%)";
        } 
        if (metricType == 6) {
            return "GCT (ms)";
        } 
        if (metricType == 7) {
            return "Power (W)";
        }
        
        return null;
    }
        
    hidden function getMetric(metricType, sensor) {
        var floatFormat = "%.1f";
        if (sensor != null) {
            if (metricType == 1) {
                return sensor.impact_gs.format(floatFormat);
            } 
            if (metricType == 2) {
                return sensor.braking_gs.format(floatFormat);
            } 
            if (metricType == 3) {
                return sensor.footstrike_type.format("%d");
            } 
            if (metricType == 4) {
                return sensor.pronation_excursion_fs_mp.format(floatFormat);
            } 
            if (metricType == 5) {
                return sensor.flight_ratio.format(floatFormat);
            } 
            if (metricType == 6) {
                return sensor.contact_time.format("%d");
            }
        }
        return "0";
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
        if (mSensorLeft != null && mSensorRight != null && (mSensorRight.searching == 0 || mSensorLeft.searching == 0)) {
            
            mSensorLeft.execute = 1;
            mSensorRight.execute = 1;
            
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
            
                if (mVisibleMetricCount == 3) {
                    met3x = xCenter;
                    met3y = yCenter + yOffset;  
                } else {
                    met3x = met1x;
                    met3y = yCenter + yOffset;  
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
            
            drawMetricOffset(dc, met1x, met1y, mMetric1Type);         
            if (mVisibleMetricCount >= 2) {
                drawMetricOffset(dc, met2x, met2y, mMetric2Type);
	            if (mVisibleMetricCount >= 3) {
	                drawMetricOffset(dc, met3x, met3y, mMetric3Type);
		            if (mVisibleMetricCount == 4) {
		                drawMetricOffset(dc, met4x, met4y, mMetric4Type);
		            } 
	            } 
            }
        } else {
            var message = "Searching...";
            if (mSensorLeft == null || mSensorRight == null) {
                message = "No Channel!";
            }
            
            dc.drawText(xCenter, yCenter - dc.getFontHeight(Gfx.FONT_MEDIUM) / 2, Gfx.FONT_MEDIUM, message, Gfx.TEXT_JUSTIFY_CENTER);
        }        
    }

    hidden function drawMetricOffset(dc, x, y, metricType) {
    
        var metricLeft = getMetric(metricType, mSensorLeft);
        var metricRight = getMetric(metricType, mSensorRight);
        
        if (metricType == 7) {
            metricLeft = ((mSensorLeft.power + mSensorRight.power) / 2).format("%d");
        }
         
        dc.drawText(x, y + mMetricTitleY, Gfx.FONT_XTINY, getMetricName(metricType), Gfx.TEXT_JUSTIFY_CENTER);

        if (metricType == 7) {
            // Power metric presents a single value
            dc.drawText(x, y + mMetricValueY, mDataFont, metricLeft, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x - mMetricValueOffsetX, y + mMetricValueY, mDataFont, metricLeft, Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(x + mMetricValueOffsetX, y + mMetricValueY, mDataFont, metricRight, Gfx.TEXT_JUSTIFY_LEFT);
            
            // Draw line
            dc.drawLine(x, y + mMetricValueY, x, y + mMetricValueY + mDataFontHeight);
        }    
    }
}
