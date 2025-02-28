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


module Led_Blink(
    input clk,
    input RxD,
    input [7:0] data_in,
    output reg TxD,
    output reg [7:0] data,
    output UART_data_ready_out,
    input I2C_data_ready
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
            if (I2C_data_ready==0)begin
                if(count==10000)begin 
                    UART_data_ready<=1;
                    byteCounter<=byteCounter+1; 
                end
            end
            else if(I2C_data_ready&UART_data_ready)begin
                UART_data_ready<=0;
                transmit_state<=0;
                if (byteCounter==5)begin
                    byteCounter<=0;
                    doOnce<=1;  // resets UART listening
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
        end
        else if(byteCounter==0) begin
            receiveBitCountTotalCopy<=receiveBitCountTotal;
        end 
        if ((doOnce==1)&(haveReceived==0))begin
            doOnce<=0;
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
    
    
    
endmodule
