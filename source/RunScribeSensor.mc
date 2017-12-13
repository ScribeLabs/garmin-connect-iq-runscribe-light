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

    //  Page 0
    //  Footstrike              Encoded             1       FS Type     8 bits  [b7/b6 = FS Num % 4, b5=L/R, b4=H/L, b3-b0=FS Type]
    //  Impact Gs               0 to 15.9375        1/16    Gs          8 bits
    //  Braking Gs              0 to 15.9375        1/16    Gs          8 bits
    //  Contact Time            0 to 1023           1       msec        10 bits
    //  Flight Ratio            -64 to 63.875       1/8     %           10 bits
    //  Power                   0 to 1023           1       watts       10 bits
    //  Pronation Excursion     -51.2 to +51.1      1/10    deg         10 bits

    
    var data = [0, 0, 0, 0, 0, 0, 0];

    // Ant channel & states
    var searching = 1;
    var isChannelOpen = false;
    var idleTime = 0;
    
    function initialize(deviceType, rsFreq, rsMesgPeriod) {
        // Get the channel
        GenericChannel.initialize(method(:onMessage), new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PUBLIC));
        
        // Set the configuration
        setDeviceConfig(new Ant.DeviceConfig( {
            :deviceNumber => 0,               // Wildcard our search - Not setting enables wildcard
            :deviceType => deviceType,
            :transmissionType => 1,
            :messagePeriod => rsMesgPeriod,
            :radioFrequency => rsFreq,          // ANT RS Frequency
            :searchTimeoutLowPriority => 10,    // Timeout in 25s
            :searchThreshold => 0} )           // Pair to all transmitting sensors
            );
    }
    
    function openChannel() {
        if (!isChannelOpen) {
            isChannelOpen = open();
        }
    }
    
    function closeChannel() {
        if (isChannelOpen) {
            close();

            searching = 1;
            isChannelOpen = false;
            idleTime = 0;
        }        
    }
    
    function onMessage(msg) {
        // Parse the payload
        var payload = msg.getPayload();
        
        if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {
            searching = 0;
            
            if (idleTime >= 0) {
                var page = (payload[0] & 0xFF);
                if (page > 0x0F) {
                    var extra = payload[7];
                
                    data[0] = payload[2] / 16.0; // Braking
			        data[1] = payload[1] / 16.0; // Impact
                    data[2] = payload[0] & 0x0F + 1; // Footstrike
                    data[3] = ((((extra & 0xC0) << 2) + payload[6]) - 512.0) / 10.0; // Pronation
                    data[4] = ((((extra & 0x0C) << 6) + payload[4]) - 224.0) / 8.0; // Flight ratio
			        data[5] = ((extra & 0x03) << 8) + payload[3]; // Contact time
                    data[6] = ((extra & 0x30) << 4) + payload[5]; // Power

                    idleTime = -1;
	            }
	        }
        } else if (Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
                    closeChannel();
                	} else if (Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT == (payload[1] & 0xFF)) {
                    closeChannel();
                	} else if (Ant.MSG_ID_LOW_PRIORITY_SEARCH_TIMEOUT == (payload[1] & 0xFF)) {
                    closeChannel();
				}
            }
        }
    }
    
}