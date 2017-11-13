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

	const LEFT = 1;
	const RIGHT = 0;
    
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
    
    var mSensor;
    
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
    
    hidden var mMesgPeriod;
    
    var power;
    
    // Constructor
    function initialize(screenShape, screenHeight, storedChannelCount) {
        DataField.initialize();
        
        mScreenShape = screenShape;
        mScreenHeight = screenHeight;
        
        onSettingsChanged(); 
        
        mSensor = new RunScribeSensor(10, 63, 2048);       
        //mSensor = new RunScribeSensor(10, 63, mMesgPeriod);       

        var d = {};
        var units = "units";

        var offset = 0;
        var extensionRight = "_R";
        var extensionLeft = "_L";

        if (storedChannelCount == 2) {
            mCurrentFSFieldRight = createField("FS" + extensionRight, 8, Fit.DATA_TYPE_SINT8, d);
        } else {
            offset = 12;
            extensionLeft = "";
        }            

        mCurrentFSFieldLeft = createField("FS" + extensionLeft, 2 + offset, Fit.DATA_TYPE_SINT8, d);

        d[units] = "G";       
        if (storedChannelCount == 2) {         
            mCurrentBGFieldRight = createField("BG" + extensionRight, 6, Fit.DATA_TYPE_FLOAT, d);
            mCurrentIGFieldRight = createField("IG" + extensionRight, 7, Fit.DATA_TYPE_FLOAT, d);
        }
        
        mCurrentBGFieldLeft = createField("BG" + extensionLeft, 0 + offset, Fit.DATA_TYPE_FLOAT, d);
        mCurrentIGFieldLeft = createField("IG" + extensionLeft, 1 + offset, Fit.DATA_TYPE_FLOAT, d);
        
        d[units] = "D";        
        if (storedChannelCount == 2) {         
            mCurrentPronationFieldRight = createField("P" + extensionRight, 9, Fit.DATA_TYPE_SINT16, d);
        }
        
        mCurrentPronationFieldLeft = createField("P" + extensionLeft, 3 + offset, Fit.DATA_TYPE_SINT16, d);
        
        d[units] = "%";
        if (storedChannelCount == 2) {
            mCurrentFlightFieldRight = createField("FR" + extensionRight, 10, Fit.DATA_TYPE_SINT8, d);
        }
        
        mCurrentFlightFieldLeft = createField("FR" + extensionLeft, 4 + offset, Fit.DATA_TYPE_SINT8, d);
       
        d[units] = "ms";
        if (storedChannelCount == 2) {
            mCurrentGCTFieldRight = createField("GCT" + extensionRight, 11, Fit.DATA_TYPE_SINT16, d);
        }
        
        mCurrentGCTFieldLeft = createField("GCT" + extensionLeft, 5 + offset, Fit.DATA_TYPE_SINT16, d);
        
        d[units] = "W";
        mCurrentPowerField = createField("Power", 18, Fit.DATA_TYPE_SINT16, d);
    }
    
    function onSettingsChanged() {
        var app = App.getApp();
        
        var antRate = app.getProperty("antRate");
        mMesgPeriod = 8192 >> antRate;        
        
        mMetric1Type = app.getProperty("tM1");
        mMetric2Type = app.getProperty("tM2");
        mMetric3Type = app.getProperty("tM3");
        mMetric4Type = app.getProperty("tM4");

        // Remove empty metrics from between
        if (mMetric2Type == 0) {
            if (mMetric3Type == 0) {
                mMetric2Type = mMetric4Type;
            } else {
                mMetric2Type = mMetric3Type;
                mMetric3Type = mMetric4Type;
            }
            mMetric4Type = 0;
        } else if (mMetric3Type == 0) {
            mMetric3Type = mMetric4Type;
            mMetric4Type = 0;
        }

        mMetricCount = 1;
        
        if (mMetric4Type != 0) {
            mMetricCount = 4; 
        } else if (mMetric3Type != 0) {
            mMetricCount = 3;
        } else if (mMetric2Type != 0) {
            mMetricCount = 2;
        }
        
        mUpdateLayout = 1;
    }
    
    function compute(info) {
    
        if (mSensor == null || !mSensor.isChannelOpen) {
            if (mSensor != null) {
                mSensor = null;
            } else {
	            try {
	                mSensor = new RunScribeSensor(10, 63, mMesgPeriod);
	            } catch(e) {
	                mSensor = null;
	            }
	       }
        } else {

            ++mSensor.idleTime;
            if (mSensor.idleTime > 30) {
                    mSensor.closeChannel();
                    mSensor.openChannel();
            }
        
            var braking = 0;
            var impact = 0;
            var footstrike = 0;
            var pronation = 0;
            var flight = 0;
            var contact = 0;
            
            power = 0;

			// Be Smart about average w/ single-channel recording!
			if ((mSensor.footstrike_type[LEFT]) != 0 && (mSensor.footstrike_type[RIGHT] == 0)) {
				// Left Data / No Right Data
	            braking = mSensor.braking_gs[LEFT];
    	   			impact = mSensor.impact_gs[LEFT];
            		footstrike = mSensor.footstrike_type[LEFT];
            		pronation = mSensor.pronation_excursion_fs_mp[LEFT];
            		flight = mSensor.flight_ratio[LEFT];
            		contact = mSensor.contact_time[RIGHT];
            		power = mSensor.power[LEFT];
            	} else if ((mSensor.footstrike_type[RIGHT]) != 0 && (mSensor.footstrike_type[LEFT] == 0) && (mCurrentBGFieldRight == null)) {
				// Right Data / No Left Data / Average Recording
	            braking = mSensor.braking_gs[RIGHT];
    	   			impact = mSensor.impact_gs[RIGHT];
            		footstrike = mSensor.footstrike_type[RIGHT];
            		pronation = mSensor.pronation_excursion_fs_mp[RIGHT];
            		flight = mSensor.flight_ratio[RIGHT];
            		contact = mSensor.contact_time[RIGHT];
            		power = mSensor.power[RIGHT];
            	} else if ((mSensor.footstrike_type[LEFT]) != 0 && (mSensor.footstrike_type[RIGHT] != 0) && (mCurrentBGFieldRight == null)) {
				// Left Data / Right Data / Average Recording
                braking = (mSensor.braking_gs[LEFT] + mSensor.braking_gs[RIGHT]) * 0.5;
                impact = (mSensor.impact_gs[LEFT] + mSensor.impact_gs[RIGHT]) * 0.5;
                footstrike = (mSensor.footstrike_type[LEFT] + mSensor.footstrike_type[RIGHT]) * 0.5;
                pronation = (mSensor.pronation_excursion_fs_mp[LEFT] + mSensor.pronation_excursion_fs_mp[RIGHT]) * 0.5;
                flight = (mSensor.flight_ratio[LEFT] + mSensor.flight_ratio[RIGHT]) * 0.5;
                contact = (mSensor.contact_time[LEFT] + mSensor.contact_time[RIGHT]) * 0.5;
                power = (mSensor.power[LEFT] + mSensor.power[RIGHT]) * 0.5;
			}	 

            mCurrentBGFieldLeft.setData(braking);
            mCurrentIGFieldLeft.setData(impact);
            mCurrentFSFieldLeft.setData(footstrike);
            mCurrentPronationFieldLeft.setData(pronation);
            mCurrentFlightFieldLeft.setData(flight);
            mCurrentGCTFieldLeft.setData(contact);            
            mCurrentPowerField.setData(power);
            
            if (mCurrentBGFieldRight != null) {
                // Separate left / right recording
                mCurrentBGFieldRight.setData(mSensor.braking_gs[RIGHT]);
                mCurrentIGFieldRight.setData(mSensor.impact_gs[RIGHT]);
                mCurrentFSFieldRight.setData(mSensor.footstrike_type[RIGHT]);
                mCurrentPronationFieldRight.setData(mSensor.pronation_excursion_fs_mp[RIGHT]);
                mCurrentFlightFieldRight.setData(mSensor.flight_ratio[RIGHT]);
                mCurrentGCTFieldRight.setData(mSensor.contact_time[RIGHT]);
           }           
        }
        
    }

    function onLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        mVisibleMetricCount = mMetricCount;
        
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

        mDataFont = selectFont(dc, width * 0.2225, height - metricNameFontHeight, "00.0-");
            
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
        for (fontIdx = 8; fontIdx > 0; --fontIdx) {
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
        
    hidden function getMetric(metricType, LR) {
        var floatFormat = "%.1f";
        if (mSensor != null) {
            if (metricType == 1) {
                return mSensor.impact_gs[LR].format(floatFormat);
            } 
            if (metricType == 2) {
                return mSensor.braking_gs[LR].format(floatFormat);
            } 
            if (metricType == 3) {
                return mSensor.footstrike_type[LR].format("%d");
            } 
            if (metricType == 4) {
                return mSensor.pronation_excursion_fs_mp[LR].format(floatFormat);
            } 
            if (metricType == 5) {
                return mSensor.flight_ratio[LR].format(floatFormat);
            } 
            if (metricType == 6) {
                return mSensor.contact_time[LR].format("%d");
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
        if ((mSensor != null) && (mSensor.searching == 0)) {
            
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
            var message = "Searching(2.0)...";
            if (mSensor == null) {
                message = "No Channel!";
            }
            
            dc.drawText(xCenter, yCenter - dc.getFontHeight(Gfx.FONT_MEDIUM) / 2, Gfx.FONT_MEDIUM, message, Gfx.TEXT_JUSTIFY_CENTER);
        }        
    }

    hidden function drawMetricOffset(dc, x, y, metricType) {
    
        var metricLeft = getMetric(metricType, LEFT);
        var metricRight = getMetric(metricType, RIGHT);
        
        if (metricType == 7) {
            metricLeft = power.format("%d");
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
