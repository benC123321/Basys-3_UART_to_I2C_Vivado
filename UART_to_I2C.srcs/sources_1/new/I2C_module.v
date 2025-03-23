`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2025 01:23:25 AM
// Design Name: 
// Module Name: I2C_module
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


module I2C_module(
    input clk, 
    input [7:0] data_bus_in,
    input UART_DATA_READY,
    output I2C_DATA_READY_out,
    output [7:0] data_bus_out,
    output I2C_clk_out_out,
    output I2C_data_out_out,
    output reg [7:0] I2C_to_UART,
    input UART_DONE,
    output reading_bit_output,
    output I2C_DONE,
    input I2C_data_in
    );
    
    //
    // Generic
    //
    reg [20:0] I2C_clock_count_start = 0;
    reg commandReg = 0; // 1 for read, 0 for send
    reg [7:0] addressIC= 'h60;
    reg [7:0] dataByte= 'h96;
    
    reg I2C_clk_out = 0;
    assign I2C_clk_out_out = I2C_clk_out;
    reg I2C_data_out = 0;
    assign I2C_data_out_out = I2C_data_out;
    
    reg I2C_DATA_READY = 0;
    assign I2C_DATA_READY_out = I2C_DATA_READY;
    
    //
    // For sending
    //
    reg [8:0] send_byte_counter = 0;
    reg [4:0] send_bit_counter = 0; // number of sent bits
    reg sending_bit = 0;  // currently sending when bit == 1
    
    //
    // For reading
    //
    reg I2C_done_bit = 0;
    reg reading_bit = 0;
    reg [8:0] read_byte_counter = 0;
    reg [7:0] read_byte_counter_max = 0;
    
    assign reading_bit_output = reading_bit;
    assign I2C_DONE = I2C_done_bit;
    //
    // Send Data to I2C target
    //
    always @(posedge clk)
    begin
        I2C_clock_count_start <= I2C_clock_count_start +1;
        if((sending_bit==1) & (reading_bit==0))begin
            if(send_byte_counter==2)begin  // first address byte
                if(I2C_clock_count_start==5000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==10000)begin
                    if(send_bit_counter==8)begin
                        I2C_data_out <= 0;  // ACK bit
                    end
                    if(send_bit_counter==7)begin
                        I2C_data_out <= 1;    // always start with write bit
                    end
                    else begin
                        I2C_data_out <= ~addressIC[send_bit_counter+1];  //6-send_bit_counter
                    end 
                end
                if(I2C_clock_count_start==15000)begin
                    I2C_clk_out <= 0;  // rising clk edge
                    send_bit_counter<=send_bit_counter+1;
                end
                if(I2C_clock_count_start==20000)begin
                    I2C_clock_count_start<=0;
                    if(send_bit_counter==9)begin
                        I2C_data_out <= 0;  // ACK bit
                        sending_bit<=0;
                        I2C_DATA_READY<=1;  
                    end
                end
            end
            else begin  // other bytes
                if(I2C_clock_count_start==5000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==10000)begin
                    if(send_bit_counter==8)begin
//                        if(send_byte_counter!=5)begin
                        if(UART_DONE|commandReg)begin
                        I2C_data_out <= 1;  // ACK bit, stop condition
                        end
                        else begin
                        I2C_data_out <= 0;  // ACK bit
                        end
                    end
                    else begin
                        I2C_data_out <= ~data_bus_in[send_bit_counter];
                    end 
                end
                if(I2C_clock_count_start==15000)begin
                    I2C_clk_out <= 0;  // rising clk edge
                    send_bit_counter<=send_bit_counter+1;
                end
                if(I2C_clock_count_start==20000)begin
//                    if(send_byte_counter!=5)begin
                    if((UART_DONE==0)&(commandReg==0))begin
                        I2C_clock_count_start<=0;
                        if(send_bit_counter==9)begin
                            sending_bit<=0;
                            I2C_DATA_READY<=1;
                        end
                    end
                    else begin
                        if(send_bit_counter!=9)begin
                            I2C_clock_count_start<=0;
                        end
                        else if(commandReg==1 & send_byte_counter<4) begin
                            I2C_clock_count_start<=0;
                            sending_bit<=0;
                            I2C_DATA_READY<=1;
                        end
                    end
                end
                if(I2C_clock_count_start==25000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==30000)begin
                // repeat start condition for read
                    if (commandReg==1) begin
                        I2C_data_out <= 0;  // rising data edge
                    end
                end
                if(I2C_clock_count_start==35000)begin
                    I2C_clk_out <= 0;  // rising clk edge
                end
                if(I2C_clock_count_start==40000)begin
                    if (commandReg==1) begin
                        reading_bit <= 1;  // go to 'reading' sequence
                        I2C_data_out <= 1;  // falling data edge, for start condition
                    end
                    else begin
                        I2C_data_out <= 0;  // rising edge
//                        send_byte_counter<=0;
                    end              
                    send_byte_counter<=0;
                    I2C_DATA_READY<=1;
                    sending_bit<=0;   
                end
            end
        end
        
        
        /// DOOOOO READ
        else if((sending_bit==1) & (reading_bit==1))begin
            if(read_byte_counter==0)begin  // first address byte
                if(I2C_clock_count_start==5000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==10000)begin
                    if(send_bit_counter==8)begin
                        I2C_data_out <= 0;  // ACK bit
                    end
                    if(send_bit_counter==7)begin
                        I2C_data_out <= 0;    // always do read bit
                    end
                    else begin
                        I2C_data_out <= ~addressIC[send_bit_counter+1];  //6-send_bit_counter
                    end 
                end
                if(I2C_clock_count_start==15000)begin
                    I2C_clk_out <= 0;  // rising clk edge
                    send_bit_counter<=send_bit_counter+1;
                end
                if(I2C_clock_count_start==20000)begin
                    I2C_clock_count_start<=0;
                    if(send_bit_counter==9)begin
                        I2C_data_out <= 0;  // ACK bit
                        read_byte_counter <= 1;   // go to real read now 
                        send_bit_counter<=0;
//                        sending_bit<=0;
//                        I2C_DATA_READY<=1;  // straight to real read
                    end
                end
            end
            else begin  // other bytes
                if(I2C_clock_count_start==5000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==10000)begin          // make data ready
                    if(send_bit_counter==8)begin
                        if (read_byte_counter<read_byte_counter_max)begin
//                        if (read_byte_counter<4)begin
                            I2C_data_out <= 1;  //ACK bit
                        end
                        else begin
                            I2C_data_out <= 0;  // NO ACK bit, do stop condition later
                        end
                    end
                    else begin
                        I2C_data_out <= 0;  // read, don't write    
                    end
                end
                if(I2C_clock_count_start==15000)begin
                    if(send_bit_counter<8)begin
                        I2C_to_UART[0] <= I2C_data_in;   // not FOR ACK BIT
                    end             
                    I2C_clk_out <= 0;  // rising clk edge
                end
                if(I2C_clock_count_start==16000)begin
                    send_bit_counter<=send_bit_counter+1;
                end
                
                if(I2C_clock_count_start==20000)begin    // done after ack when bit counter == 9
                    if(send_bit_counter==9)begin
                        if (read_byte_counter<read_byte_counter_max)begin
//                        if (read_byte_counter<4)begin
                            sending_bit<=0;
                            I2C_DATA_READY<=1;
                            I2C_clock_count_start<=0;
                        end
                    end
                    else begin
                        I2C_clock_count_start<=0;
                        if(send_bit_counter!=8)begin
                            I2C_to_UART = I2C_to_UART<<1;
                        end
                    end
                end
                
                if(I2C_clock_count_start==25000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                    I2C_data_out<=1; //start stop condition
                end
                if(I2C_clock_count_start==35000)begin
                    I2C_clk_out <= 0;  // rising clk edge
                end
                if(I2C_clock_count_start==40000)begin
                    I2C_data_out <= 0;  // rising edge, end of stop condition             
                    send_byte_counter<=0;
                    read_byte_counter<=0;
                    I2C_DATA_READY<=1;
                    sending_bit<=0;   
                    reading_bit <=0;
                    I2C_done_bit <= 1;
                end
            end
        end
        
        
        
        else if(UART_DATA_READY&(I2C_DATA_READY==0))begin
            if((send_byte_counter==0)&(reading_bit==0))begin
                commandReg<=data_bus_in[0];
                I2C_DATA_READY<=1;    // ready  for next byte
                send_byte_counter<=send_byte_counter+1;  // keep track of input byte number 
                I2C_clk_out <= 0;   //  make sure that outputs are cleared
                I2C_data_out <= 0;  // 
                reading_bit <= 0;  // make sure that reading bit is cleared
                I2C_done_bit<=0;
            end
            else if (reading_bit==0) begin  //read_byte_counter_max
                if (send_byte_counter==1) begin
                    addressIC <= data_bus_in;
                end
                sending_bit <=1;   // active I2C comms
                send_bit_counter <= 0;
                I2C_clock_count_start <=0;
                I2C_data_out <= 1;            // start sequence
                send_byte_counter<=send_byte_counter+1;
            end
            else if(I2C_done_bit==0)begin  //read_byte_counter_max
                if (read_byte_counter==0) begin
                    read_byte_counter_max[0] <= data_bus_in[7];
                    read_byte_counter_max[1] <= data_bus_in[6];
                    read_byte_counter_max[2] <= data_bus_in[5];
                    read_byte_counter_max[3] <= data_bus_in[4];
                    read_byte_counter_max[4] <= data_bus_in[3];
                    read_byte_counter_max[5] <= data_bus_in[2];
                    read_byte_counter_max[6] <= data_bus_in[1];
                    read_byte_counter_max[7] <= data_bus_in[0];                    
                end
                else begin
                    read_byte_counter<=read_byte_counter+1;
                end            
                sending_bit <=1;   // active I2C comms
                send_bit_counter <= 0;
                I2C_clock_count_start <=0;
                I2C_data_out <= 1;            // start sequence
            end
        end
        
        
        
        else if(I2C_DATA_READY&(UART_DATA_READY==0))begin
            I2C_DATA_READY<=0;
            if(reading_bit==0)begin
                I2C_data_out <= 0;  // clear, do stop condition
            end
        end
    
    end
    
    
endmodule
