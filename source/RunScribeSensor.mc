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

using Toybox.Ant as Ant;

class RunScribeSensor extends Ant.GenericChannel {

    var searching;

    //  Page 0 - Efficiency
    //  FS                      Encoded         1       FS Type         8 bits  [b7/b6 = FS Num % 4, b5=L/R, b4=H/L, b3-b0=FS Type]
    //  Stride Rate             0 to 255        1       steps/min       8 bits
    //  Stride Pace             0 to 10.24      1/100   meters/sec      10 bits
    //  Stride Length           0 to 3.996      1/256   meters          10 bits
    //  Contact Time            0 to 1023       1       msec            10 bits
    //  Flight Ratio          -64 to 63.875     1/8     %               10 bits
    //                                                                  56 bits
    
    //  Page 1 - Shock/Motion/Power
    //  Impact Gs                 0 to 15.9375      1/16    Gs          8 bits
    //  Braking Gs                0 to 15.9375      1/16    Gs          8 bits
    //  Power                     0 to 1023         1       watts       10 bits
    //  Pronation Excursion   -51.2 to +51.1        1/10    deg         10 bits
    //  Stance Excursion MP-TO    0 to 127.875      1/8     deg         10 bits
    //  Max Pronation Velocity    0 to 2046         2       deg/sec     10 bits
    //                                                                  56 bits

    var contact_time = 0;
    var flight_ratio = 0.0;
    var footstrike_type = 0;
    var impact_gs = 0.0;
    var braking_gs = 0.0;
    var power = 0;
    var pronation_excursion_fs_mp = 0.0;
        
    
    function initialize(deviceType, rsFreq, rsMesgPeriod) {
        
        // Get the channel
        var chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PUBLIC);
        GenericChannel.initialize(method(:onMessage), chanAssign);
        
        // Set the configuration
        var deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => 0,                 //Wildcard our search
            :deviceType => deviceType,
            :transmissionType => 1,
            :messagePeriod => rsMesgPeriod,
            :radioFrequency => rsFreq,          //ANT RS Frequency
            :searchTimeoutLowPriority => 10,    //Timeout in 25s
            :searchThreshold => 0} );           //Pair to all transmitting sensors
        GenericChannel.setDeviceConfig(deviceCfg);
    }
    
    function open() {
        // Open the channel
        GenericChannel.open();
        searching = 1;
    }
    
    function closeSensor() {
        GenericChannel.close();
    }
    
    function onMessage(msg) {
        // Parse the payload
        var payload = msg.getPayload();
        
        if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {
            // Were we searching?
            if (searching == 1) {
                searching = 0;
            }
            
            if (0x00 == (payload[0].toNumber() & 0xFF) ) {
                parse_page_0(payload);
            } else if (0x01 == (payload[0].toNumber() & 0xFF)) {
                parse_page_1(payload);
            }
        } else if (Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
                    // Channel closed, re-open
                    open();
                }
            }
        }
    }
    
    hidden function parse_page_0(payload) {
        footstrike_type = payload[1] & 0x0F;
        contact_time = ((payload[7] & 0x30) << 4) + payload[5];
        flight_ratio = decode_bits( (((payload[7] & 0xC0) << 2) + payload[6]), -28.0, 8.0 );
    }
    
    hidden function parse_page_1(payload) {
        impact_gs = payload[1] / 16.0;
        braking_gs = payload[2] / 16.0;
        power = ((payload[7] & 0x03) << 8) + payload[3];
        pronation_excursion_fs_mp = decode_bits( (((payload[7] & 0x0C) << 6) + payload[4]), -51.2, 10.0 );
    }
    
    hidden function decode_bits(x, min_val, scale_factor)   { 
        return ((x + min_val*scale_factor) / scale_factor);
    }
    
}