`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2023 07:49:20 PM
// Design Name: 
// Module Name: Uart_top
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


module Uart_top #(
        parameter BITS_d = 8,     // # data bits
                   N_TICK  = 16  // # stop bit ticks                  
     )     
    (
        input clk, reset,
        
        // receiver port
        output [BITS_d - 1: 0] r_data,
        input rd_uart,
        output rx_empty,
        input rx,
        
        // transmitter port
        input [BITS_d - 1: 0] w_data,
        input wr_uart,
        output tx_full,
        output tx,
        
        
        input [10: 0] TIMER_FINAL_VALUE
    );
    
    // Timer as baud rate generator
    wire tick;
    timer #(.BITS(11))baud_rate_generator (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .FINAL_VALUE(TIMER_FINAL_VALUE),
        .done(tick)
    );
    
    // Receiver
    wire rx_done_tick;
    wire [BITS_d - 1: 0] rx_dout;
    Uart #(.BITS_d(BITS_d), . N_TICK ( N_TICK )) receiver(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .s_tick(tick),
        .rx_done_tick(rx_done_tick),
        .rx_dout(rx_dout)
    );
    
    fifo_generator_0 rx_FIFO (
        .clk(clk),          // input wire clk
        .srst(reset),    // input wire srst
        .din(rx_dout),      // input wire [7 : 0] din
        .wr_en(rx_done_tick),  // input wire wr_en
        .rd_en(rd_uart),    // input wire rd_en
        .dout(r_data),      // output wire [7 : 0] dout
        .full(),            // output wire full
        .empty(rx_empty)    // output wire empty
    );

    // Transmitter
    wire tx_fifo_empty, tx_done_tick;
    wire [BITS_d - 1: 0] tx_din;
    Uart_tx #(.BITS_d(BITS_d), . N_TICK ( N_TICK )) transmitter(
        .clk(clk),
        .reset(reset),
        .tx_start(~tx_fifo_empty),
        .s_tick(tick),
        .tx_din(tx_din),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );
    
    fifo_generator_0 tx_FIFO (
        .clk(clk),          // input wire clk
        .srst(reset),    // input wire srst
        .din(w_data),      // input wire [7 : 0] din
        .wr_en(wr_uart),  // input wire wr_en
        .rd_en(tx_done_tick),    // input wire rd_en
        .dout(tx_din),      // output wire [7 : 0] dout
        .full(tx_full),            // output wire full
        .empty(tx_fifo_empty)    // output wire empty
    );    
endmodule
