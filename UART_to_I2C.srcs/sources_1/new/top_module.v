`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2025 01:19:14 AM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input clk,
    input RxD,
    output TxD,
    output I2C_clk_out,
    output I2C_data_out,
    //output UART_DATA_READY,
    input I2C_data_in,
    output debugRxD
    );
    
//    assign debug_output_TxD = TxD;
//    assign debug_output_RxD = RxD;
    wire [7:0] UART_to_I2C;
    wire [7:0] I2C_to_UART;
    
    assign debugRxD = TxD; 
    
    UART_module UART(clk,RxD,TxD,UART_to_I2C[7:0],UART_DATA_READY,I2C_DATA_READY,I2C_to_UART[7:0],UART_DONE,reading_bit_output,I2C_DONE);
    I2C_module I2C(clk,UART_to_I2C[7:0],UART_DATA_READY,I2C_DATA_READY,I2C_to_UART, I2C_clk_out,I2C_data_out,I2C_to_UART[7:0],UART_DONE,reading_bit_output,I2C_DONE,I2C_data_in);
    
endmodule
