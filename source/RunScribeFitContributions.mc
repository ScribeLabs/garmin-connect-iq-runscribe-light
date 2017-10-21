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

using Toybox.FitContributor as Fit;

class RunScribeFitContributor {

    // FIT Contributions variables
    hidden var mCurrentBGField;
    hidden var mCurrentIGField;
    hidden var mCurrentFSField;
    hidden var mCurrentPronationField;
    hidden var mCurrentFlightField;
    hidden var mCurrentGCTField;
    hidden var mCurrentPowerField;

    // Constructor
    function initialize(dataField) {
    	var g = { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"G" };
        mCurrentBGField = dataField.createField("currBrakingGs", 0, Fit.DATA_TYPE_FLOAT, g);
        mCurrentIGField = dataField.createField("currImpactGs", 1, Fit.DATA_TYPE_FLOAT, g);
        
        mCurrentFSField = dataField.createField("currFSType", 2, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_RECORD });
        mCurrentPronationField = dataField.createField("currPronation", 3, Fit.DATA_TYPE_DOUBLE, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"D" });
        mCurrentFlightField = dataField.createField("currFlightRatio", 4, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"%" });
        mCurrentGCTField = dataField.createField("currContactTime", 5, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"ms" });
        mCurrentPowerField = dataField.createField("currPower", 6, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"W" });
        
        mCurrentBGField.setData(0);
        mCurrentIGField.setData(0);
        mCurrentFSField.setData(0);
        mCurrentPronationField.setData(0);
        mCurrentFlightField.setData(0);
        mCurrentGCTField.setData(0);
        mCurrentPowerField.setData(0);
    }

    function compute(sensorL, sensorR) {
        if (sensorL != null && sensorR != null && sensorL.data != null && sensorR.data != null) {
        	// Average L/R for combined metric
            mCurrentBGField.setData((sensorL.data.braking_gs + sensorR.data.braking_gs) * 0.5);
            mCurrentIGField.setData((sensorL.data.impact_gs + sensorR.data.impact_gs) * 0.5);
            mCurrentFSField.setData((sensorL.data.footstrike_type + sensorR.data.footstrike_type) * 0.5);
            mCurrentPronationField.setData((sensorL.data.pronation_excursion_fs_mp + sensorR.data.pronation_excursion_fs_mp) * 0.5);
            mCurrentFlightField.setData((sensorL.data.flight_ratio + sensorR.data.flight_ratio) * 0.5);
            mCurrentGCTField.setData((sensorL.data.contact_time + sensorR.data.contact_time) * 0.5);
            mCurrentPowerField.setData((sensorL.data.power + sensorR.data.power) * 0.5);
        }
    }
}