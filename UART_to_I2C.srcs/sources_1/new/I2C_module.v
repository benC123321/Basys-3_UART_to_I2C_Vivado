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
    output I2C_data_out_out
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
    // Send Data to I2C target
    //
    always @(posedge clk)
    begin
        I2C_clock_count_start <= I2C_clock_count_start +1;
        if(sending_bit)begin
            if(send_byte_counter==2)begin  // first address byte
                if(I2C_clock_count_start==5000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==10000)begin
                    if(send_bit_counter==8)begin
                        I2C_data_out <= 0;  // ACK bit
                    end
                    if(send_bit_counter==7)begin
                        I2C_data_out <= ~commandReg;
                    end
                    else begin
                        I2C_data_out <= ~addressIC[6-send_bit_counter];
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
                        if(send_byte_counter!=5)begin
                        I2C_data_out <= 0;  // ACK bit
                        end
                        else begin
                        I2C_data_out <= 1;  // ACK bit, stop condition
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
                    if(send_byte_counter!=5)begin
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
                    end
                end
                if(I2C_clock_count_start==25000)begin
                    I2C_clk_out <= 1;  // falling clk edge
                end
                if(I2C_clock_count_start==35000)begin
                    I2C_clk_out <= 0;  // rising clk edge
                end
                if(I2C_clock_count_start==37000)begin
                    I2C_data_out <= 0;  // rising edge
                    send_byte_counter<=0;
                    I2C_DATA_READY<=1;
                    sending_bit<=0;
                end
            end
        end
        else if(UART_DATA_READY&(I2C_DATA_READY==0))begin
            if(send_byte_counter==0)begin
                commandReg<=data_bus_in[0];
                I2C_DATA_READY<=1;
                send_byte_counter<=send_byte_counter+1;
                I2C_clk_out <= 0;
                I2C_data_out <= 0;
            end
            else begin
//                if (send_byte_counter==1) begin
//                    addressIC <= data_bus_in;
//                end
                sending_bit <=1;
                send_bit_counter <= 0;
                I2C_clock_count_start <=0;
                I2C_data_out <= 1;
                send_byte_counter<=send_byte_counter+1;
            end
        end
        else if(I2C_DATA_READY&(UART_DATA_READY==0))begin
            I2C_DATA_READY<=0;
            I2C_data_out <= 0;  // clear stop condition
        end
    
    end
    
    
endmodule
