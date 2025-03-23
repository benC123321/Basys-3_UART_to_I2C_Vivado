`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2025 08:30:24 PM
// Design Name: 
// Module Name: Led_Blink
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_module(
    input clk,
    input RxD,
    output reg TxD,
    output reg [7:0] data,
    output UART_data_ready_out,
    input I2C_data_ready,
    input [7:0] I2C_to_UART,
    output reg UART_DONE,
    input reading_bit_input,
    input I2C_DONE
    );
    
    //
    // Send to I2C stuff
    //
    reg transmit_state = 0;
    reg [7:0] receiveBitCountTotalCopy;
    reg doOnce = 0;
    reg [20:0] count = 0; 
    
    
    //
    // Rx Stuff
    //
    reg receiveSendOnce =0;
    reg [799:0] inputBuffer;   // 1 char // 100 character max
    reg [14:0] UartRxCount = 0;
    reg receiveState = 0;  // not receiving
    reg [4:0] receiveBitCount = 0;
    reg [7:0] receiveBitCountTotal = 0;
    reg [7:0] mostRecentByte = 0;
    reg [3:0] byteCounter=0;
    reg haveReceived = 0;  // not receiving
    reg UART_data_ready = 0; 
    
    //
    // Tx Stuff
    //
    reg [79:0] outputBuffer;
    reg ignoreFirstRead = 0;
    reg needToTransmit = 0;
    reg doneTransmit = 0;
    
    assign UART_data_ready_out = UART_data_ready;
    
    assign haveReceived_out = haveReceived;
    
    always @(posedge clk)
    begin
    end
    
    
    //
    // Send Data to I2C
    //
    always @(posedge clk)
    begin
        count<=count+1;
        if(transmit_state) begin
            if (I2C_data_ready==0)begin       // we start with I2C_data_ready==0 and UART_data_ready==0
                if(count==10000)begin 
                    UART_data_ready<=1;   // tell I2C module that data is ready
                    byteCounter<=byteCounter+1; 
                    outputBuffer = outputBuffer<<8;
                end
            end
            else if(I2C_data_ready&UART_data_ready)begin           // This state happens after I2C has sent the data, or I2C has data for UART module to read
                if((reading_bit_input|I2C_DONE) & ignoreFirstRead)begin 
                    count<=0;
                    outputBuffer[0] <= I2C_to_UART[0];
                    outputBuffer[1] <= I2C_to_UART[1];
                    outputBuffer[2] <= I2C_to_UART[2];
                    outputBuffer[3] <= I2C_to_UART[3];
                    outputBuffer[4] <= I2C_to_UART[4];
                    outputBuffer[5] <= I2C_to_UART[5];
                    outputBuffer[6] <= I2C_to_UART[6];
                    outputBuffer[7] <= I2C_to_UART[7];
                end
                else if(reading_bit_input)begin//during first 'read', no data to receive
                    count<=0;
                    ignoreFirstRead<=1;
                    transmit_state<=0;  // stay in transmit state when reading
                end
                else begin
                    transmit_state<=0;  // stay in transmit state when reading
                end
                UART_data_ready<=0;    

                if(UART_DONE | I2C_DONE)begin
                    byteCounter<=0;
                    doOnce<=1;  // resets UART listening
                    transmit_state<=0;
                    if(I2C_DONE)begin
                        needToTransmit<=1;
                    end          
                end
                else if(receiveBitCountTotalCopy>39)begin
                    receiveBitCountTotalCopy <= receiveBitCountTotalCopy - 16;
                end
                else begin
                    doOnce<=1;  // resets UART listening
                end
            end
        end
        else if(haveReceived &(doOnce==0)) begin
            transmit_state<=1;
            data[7]<=inputBuffer[receiveBitCountTotalCopy-1];
            data[6]<=inputBuffer[receiveBitCountTotalCopy];
            data[5]<=inputBuffer[receiveBitCountTotalCopy+1];
            data[4]<=inputBuffer[receiveBitCountTotalCopy+2];
            data[3]<=inputBuffer[receiveBitCountTotalCopy+7];
            data[2]<=inputBuffer[receiveBitCountTotalCopy+8];
            data[1]<=inputBuffer[receiveBitCountTotalCopy+9];
            data[0]<=inputBuffer[receiveBitCountTotalCopy+10];
            count<=0;
            if((receiveBitCountTotalCopy<40)&(reading_bit_input==0))begin
                UART_DONE <=1;
            end
        end
        else if(byteCounter==0) begin
            ignoreFirstRead<=0;
            UART_DONE <=0; 
            receiveBitCountTotalCopy<=receiveBitCountTotal;
        end 
        if ((doOnce==1)&(haveReceived==0))begin
            doOnce<=0;
        end
        if (doneTransmit)begin
            needToTransmit<=0;
        end
    end
    
    
    
    always @(posedge clk)begin
        mostRecentByte <= inputBuffer [22:15];
        if(receiveState==1)begin
            UartRxCount<=UartRxCount+1;
            if(UartRxCount==10410)begin   // increase bit count for this byte
                receiveBitCount<=receiveBitCount+1;
            end
            else if(UartRxCount==10412)begin        
                 if(receiveBitCount==10)begin  // STOP bit   //SHOULD BE 11
                    if(RxD)begin
                    // STOP COMMS
                        UartRxCount<=0;
                        receiveState<=0;
                        receiveBitCount<=0;
                        inputBuffer = inputBuffer<<15;
                        receiveSendOnce<=0;
                    end
//                    else begin
//                    // START ANOTHER BYTE, receiving start bit
//                        receiveBitCount<=1;
//                        inputBuffer = inputBuffer<<8;
//                    end
                end
                else if((receiveBitCount<10)&(receiveBitCount>1))begin  // first bit is start bit, save next 8     /// ERROR HAS TO BE HERE
                    inputBuffer[7] <= RxD;
                    receiveBitCountTotal <= receiveBitCountTotal +1;
                end
            end
            else if(UartRxCount==10416)begin
                if((receiveBitCount<9)&(receiveBitCount>1))begin  // first bit is start bit, save next 8
                    inputBuffer<=inputBuffer>>1;
                end
                UartRxCount<=0;
            end        
        end
        else begin
            if(RxD==0)begin
                UartRxCount<= 5208; //10416 by 2
                receiveState<=1; 
//                receiveBitCountTotal<=0;      /// ONLY 1 BYTE
            end
            if(mostRecentByte=='h5A)begin
                if((doOnce==0))begin
                    if(receiveSendOnce==0)begin
                        haveReceived<=1;      /// ONLY 1 BYTE
                        receiveSendOnce<=1;
                    end
                end
                else begin
                    haveReceived<=0;      /// ONLY 1 BYTE
                    receiveBitCountTotal<=0;
                end
            end
        end
    end
    
    
    //
    // TX stuff
    //
    reg [20:0] TXcount = 0;
    reg [14:0] UARTcount = 0; 
    reg [7:0] sendTotalByteCount;
//    reg [4:0] byteCounter = 0;
    reg [7:0] bitTracker = 0;
    reg transmit_state_TX = 0;
    reg [4:0] transmitted_bits = 0;
    reg [7:0] data_TX; 
    
    reg [7:0] countBytes_TX = 0;
    reg [7:0] numBits = 0;
    reg doneCounting = 0;
    
    
    always @(posedge clk)
    begin
        //clk_out<=RxD;
        if(transmit_state_TX) begin
            UARTcount<=UARTcount+1;   // no need for UART clock when not sending
            if(UARTcount==10416)begin
                transmitted_bits <= transmitted_bits+1;
                TxD <= data_TX[0];
            end
            else if(UARTcount==10417)begin
                UARTcount<=0;
                data_TX <= data_TX>>1;
                if(transmitted_bits==9)begin
                    transmit_state_TX<=0;
                    TxD<=1;
                    TXcount<=0;
                    if(numBits>7)begin        /// ???????????????????????????????????
                        numBits <= numBits - 4;
                    end
                    else begin
                        doneTransmit<=1;
                        numBits <=0;
                    end
                end
            end
        end
//        else if(count>100_000_000)begin
        else if(needToTransmit &(doneTransmit==0)) begin
            TXcount<=TXcount+1;
            if(sendTotalByteCount>0)begin
                sendTotalByteCount <= sendTotalByteCount-1;
                numBits <= numBits+8;
            end
            else if(TXcount>10000)begin //was 10000
                TxD<=0;   // send start bit
                TXcount<=0;
                UARTcount<=0;
                transmit_state_TX<=1;
                data_TX[7]<=0;
                data_TX[6]<=0;
                data_TX[5]<=0;
                data_TX[4]<=0;
                data_TX[3]<=outputBuffer[numBits-1];
                data_TX[2]<=outputBuffer[numBits-2];
                data_TX[1]<=outputBuffer[numBits-3];
                data_TX[0]<=outputBuffer[numBits-4];
                transmitted_bits<=0;
    //            doOnce<=1;
            end
        end
        else if ((doneTransmit==1)&(needToTransmit==0))begin
            doneTransmit<=0;
            countBytes_TX<=0;
            bitTracker<=0;
            TXcount<=0;
        end
        else begin
            sendTotalByteCount[0] <= data[7];
            sendTotalByteCount[1] <= data[6];
            sendTotalByteCount[2] <= data[5];
            sendTotalByteCount[3] <= data[4];
            sendTotalByteCount[4] <= data[3];
            sendTotalByteCount[5] <= data[2];
            sendTotalByteCount[6] <= data[1];
            sendTotalByteCount[7] <= data[0];
            TXcount<=0;   
        end 
//        end
    end
    
    
    
    
    
    
    
endmodule
